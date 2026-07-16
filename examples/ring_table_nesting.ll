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

%Player = type { i8*, i32 }
%Snapshot = type { i32, { [3 x i32], i64, i64 }, { [2 x %Player], i64, i64 } }
%Bag = type { { [2 x i8*], i64, i64 }, i32 }
%Item = type { i32 }
define %Snapshot @make_snapshot() {
entry:
  %t0 = alloca { [3 x i32], i64, i64 }
  %t27 = alloca { [2 x %Player], i64, i64 }
  %t28 = alloca %Player
  %t48 = alloca %Snapshot
  store { [3 x i32], i64, i64 } zeroinitializer, { [3 x i32], i64, i64 }* %t0
  %t1 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t2 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t3 = load i64, i64* %t2
  %t4 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t5 = load i64, i64* %t4
  %t6 = icmp sge i64 %t5, 3
  br i1 %t6, label %ring_push_full_0, label %ring_push_grow_1
ring_push_grow_1:
  %t7 = add i64 %t3, %t5
  %t8 = urem i64 %t7, 3
  %t9 = getelementptr inbounds [3 x i32], [3 x i32]* %t1, i32 0, i64 %t8
  store i32 1, i32* %t9
  %t10 = add i64 %t5, 1
  store i64 %t10, i64* %t4
  br label %ring_push_done_2
ring_push_full_0:
  %t11 = getelementptr inbounds [3 x i32], [3 x i32]* %t1, i32 0, i64 %t3
  store i32 1, i32* %t11
  %t12 = add i64 %t3, 1
  %t13 = urem i64 %t12, 3
  store i64 %t13, i64* %t2
  br label %ring_push_done_2
ring_push_done_2:
  %t14 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 0
  %t15 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 1
  %t16 = load i64, i64* %t15
  %t17 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0, i32 0, i32 2
  %t18 = load i64, i64* %t17
  %t19 = icmp sge i64 %t18, 3
  br i1 %t19, label %ring_push_full_3, label %ring_push_grow_4
ring_push_grow_4:
  %t20 = add i64 %t16, %t18
  %t21 = urem i64 %t20, 3
  %t22 = getelementptr inbounds [3 x i32], [3 x i32]* %t14, i32 0, i64 %t21
  store i32 2, i32* %t22
  %t23 = add i64 %t18, 1
  store i64 %t23, i64* %t17
  br label %ring_push_done_5
ring_push_full_3:
  %t24 = getelementptr inbounds [3 x i32], [3 x i32]* %t14, i32 0, i64 %t16
  store i32 2, i32* %t24
  %t25 = add i64 %t16, 1
  %t26 = urem i64 %t25, 3
  store i64 %t26, i64* %t15
  br label %ring_push_done_5
ring_push_done_5:
  store { [2 x %Player], i64, i64 } zeroinitializer, { [2 x %Player], i64, i64 }* %t27
  %t29 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t30 = getelementptr inbounds %Player, %Player* %t28, i32 0, i32 0
  store i8* %t29, i8** %t30
  %t31 = getelementptr inbounds %Player, %Player* %t28, i32 0, i32 1
  store i32 100, i32* %t31
  %t32 = load %Player, %Player* %t28
  %t33 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27, i32 0, i32 0
  %t34 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27, i32 0, i32 1
  %t35 = load i64, i64* %t34
  %t36 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27, i32 0, i32 2
  %t37 = load i64, i64* %t36
  %t38 = icmp sge i64 %t37, 2
  br i1 %t38, label %ring_push_full_6, label %ring_push_grow_7
ring_push_grow_7:
  %t39 = add i64 %t35, %t37
  %t40 = urem i64 %t39, 2
  %t41 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t33, i32 0, i64 %t40
  store %Player %t32, %Player* %t41
  %t42 = add i64 %t37, 1
  store i64 %t42, i64* %t36
  br label %ring_push_done_8
ring_push_full_6:
  %t43 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t33, i32 0, i64 %t35
  %t44 = getelementptr inbounds %Player, %Player* %t43, i32 0, i32 0
  %t45 = load i8*, i8** %t44
  call void @star_rc_release(i8* %t45)
  store %Player %t32, %Player* %t43
  %t46 = add i64 %t35, 1
  %t47 = urem i64 %t46, 2
  store i64 %t47, i64* %t34
  br label %ring_push_done_8
ring_push_done_8:
  %t49 = getelementptr inbounds %Snapshot, %Snapshot* %t48, i32 0, i32 0
  store i32 42, i32* %t49
  %t50 = load { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t0
  %t51 = getelementptr inbounds %Snapshot, %Snapshot* %t48, i32 0, i32 1
  store { [3 x i32], i64, i64 } %t50, { [3 x i32], i64, i64 }* %t51
  %t52 = load { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27
  %t53 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27, i32 0, i32 0
  %t54 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t53, i32 0, i64 0
  %t55 = getelementptr inbounds %Player, %Player* %t54, i32 0, i32 0
  %t56 = load i8*, i8** %t55
  call void @star_rc_retain(i8* %t56)
  %t57 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t53, i32 0, i64 1
  %t58 = getelementptr inbounds %Player, %Player* %t57, i32 0, i32 0
  %t59 = load i8*, i8** %t58
  call void @star_rc_retain(i8* %t59)
  %t60 = getelementptr inbounds %Snapshot, %Snapshot* %t48, i32 0, i32 2
  store { [2 x %Player], i64, i64 } %t52, { [2 x %Player], i64, i64 }* %t60
  %t61 = load %Snapshot, %Snapshot* %t48
  %t62 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27, i32 0, i32 0
  %t63 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t62, i32 0, i64 0
  %t64 = getelementptr inbounds %Player, %Player* %t63, i32 0, i32 0
  %t65 = load i8*, i8** %t64
  call void @star_rc_release(i8* %t65)
  %t66 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t62, i32 0, i64 1
  %t67 = getelementptr inbounds %Player, %Player* %t66, i32 0, i32 0
  %t68 = load i8*, i8** %t67
  call void @star_rc_release(i8* %t68)
  ret %Snapshot %t61
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca %Snapshot
  %t24 = alloca i32
  %t40 = alloca i32
  %t64 = alloca %Player
  %t82 = alloca %Player
  %t87 = alloca %Snapshot
  %t145 = alloca i32
  %t161 = alloca i32
  %t185 = alloca i32
  %t201 = alloca i32
  %t205 = alloca i8*
  %t206 = alloca { [2 x i8*], i64, i64 }
  %t293 = alloca i64
  %t324 = alloca %Bag
  %t365 = alloca { [2 x i8*], i64, i64 }
  %t418 = alloca i64
  %t449 = alloca %Bag
  %t517 = alloca %Bag
  %t531 = alloca %Bag
  %t547 = alloca %Bag
  %t561 = alloca %Bag
  %t582 = alloca %Bag
  %t596 = alloca %Bag
  %t610 = alloca i8*
  %t626 = alloca %Bag
  %t640 = alloca %Bag
  %t654 = alloca i8*
  %t671 = alloca %Bag
  %t685 = alloca %Bag
  %t701 = alloca %Bag
  %t715 = alloca %Bag
  %t736 = alloca %Bag
  %t750 = alloca %Bag
  %t764 = alloca i8*
  %t768 = alloca i8*
  %t808 = alloca i64
  %t839 = alloca %Bag
  %t901 = alloca %Bag
  %t939 = alloca i64
  %t970 = alloca %Bag
  %t990 = alloca { [2 x i8*], i64, i64 }
  %t991 = alloca i8*
  %t1042 = alloca %Item
  %t1080 = alloca i8*
  %t1125 = alloca %Item
  %t1191 = alloca %Item
  %t1247 = alloca i8*
  %t1272 = alloca i8*
  %t1283 = alloca %Item
  %t1289 = alloca %Item
  %t1305 = alloca i8*
  %t1330 = alloca i8*
  %t1341 = alloca %Item
  %t1347 = alloca %Item
  %t1363 = alloca i8*
  %t1374 = alloca %Item
  %t1380 = alloca %Item
  %t1384 = alloca i8*
  %t1429 = alloca %Item
  %t1485 = alloca i8*
  %t1510 = alloca i8*
  %t1521 = alloca %Item
  %t1527 = alloca %Item
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = call %Snapshot @make_snapshot()
  store %Snapshot %t1, %Snapshot* %t0
  %t2 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t5 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t4, i32 0, i32 0
  %t6 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t4, i32 0, i32 1
  %t7 = load i64, i64* %t6
  %t8 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t4, i32 0, i32 2
  %t9 = load i64, i64* %t8
  %t10 = trunc i64 %t9 to i32
  %t11 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t12 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t11, i32 0, i32 0
  %t13 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t11, i32 0, i32 1
  %t14 = load i64, i64* %t13
  %t15 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t11, i32 0, i32 2
  %t16 = load i64, i64* %t15
  %t17 = sext i32 0 to i64
  %t18 = load i64, i64* %t13
  %t19 = load i64, i64* %t15
  %t20 = icmp ult i64 %t17, %t19
  br i1 %t20, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t21 = add i64 %t18, %t17
  %t22 = urem i64 %t21, 3
  %t23 = getelementptr inbounds [3 x i32], [3 x i32]* %t12, i32 0, i64 %t22
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t24
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t25 = phi i32* [ %t23, %ring_rplace_ok_9 ], [ %t24, %ring_rplace_oob_10 ]
  %t26 = load i32, i32* %t25
  %t27 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t28 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t27, i32 0, i32 0
  %t29 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t27, i32 0, i32 1
  %t30 = load i64, i64* %t29
  %t31 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t27, i32 0, i32 2
  %t32 = load i64, i64* %t31
  %t33 = sext i32 1 to i64
  %t34 = load i64, i64* %t29
  %t35 = load i64, i64* %t31
  %t36 = icmp ult i64 %t33, %t35
  br i1 %t36, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t37 = add i64 %t34, %t33
  %t38 = urem i64 %t37, 3
  %t39 = getelementptr inbounds [3 x i32], [3 x i32]* %t28, i32 0, i64 %t38
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  store i32 0, i32* %t40
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t41 = phi i32* [ %t39, %ring_rplace_ok_12 ], [ %t40, %ring_rplace_oob_13 ]
  %t42 = load i32, i32* %t41
  %t43 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t43, i32 %t3, i32 %t10, i32 %t26, i32 %t42)
  %t44 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t45 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t44, i32 0, i32 0
  %t46 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t44, i32 0, i32 1
  %t47 = load i64, i64* %t46
  %t48 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t44, i32 0, i32 2
  %t49 = load i64, i64* %t48
  %t50 = trunc i64 %t49 to i32
  %t51 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t52 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t51, i32 0, i32 0
  %t53 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t51, i32 0, i32 1
  %t54 = load i64, i64* %t53
  %t55 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t51, i32 0, i32 2
  %t56 = load i64, i64* %t55
  %t57 = sext i32 0 to i64
  %t58 = load i64, i64* %t53
  %t59 = load i64, i64* %t55
  %t60 = icmp ult i64 %t57, %t59
  br i1 %t60, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t61 = add i64 %t58, %t57
  %t62 = urem i64 %t61, 2
  %t63 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t52, i32 0, i64 %t62
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  store %Player zeroinitializer, %Player* %t64
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t65 = phi %Player* [ %t63, %ring_rplace_ok_15 ], [ %t64, %ring_rplace_oob_16 ]
  %t66 = getelementptr inbounds %Player, %Player* %t65, i32 0, i32 0
  %t67 = load i8*, i8** %t66
  %t68 = load i8*, i8** %t66
  call void @star_rc_retain(i8* %t68)
  call void @star_rc_release(i8* %t67)
  %t69 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t70 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t69, i32 0, i32 0
  %t71 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t69, i32 0, i32 1
  %t72 = load i64, i64* %t71
  %t73 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t69, i32 0, i32 2
  %t74 = load i64, i64* %t73
  %t75 = sext i32 0 to i64
  %t76 = load i64, i64* %t71
  %t77 = load i64, i64* %t73
  %t78 = icmp ult i64 %t75, %t77
  br i1 %t78, label %ring_rplace_ok_18, label %ring_rplace_oob_19
ring_rplace_ok_18:
  %t79 = add i64 %t76, %t75
  %t80 = urem i64 %t79, 2
  %t81 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t70, i32 0, i64 %t80
  br label %ring_rplace_end_20
ring_rplace_oob_19:
  store %Player zeroinitializer, %Player* %t82
  br label %ring_rplace_end_20
ring_rplace_end_20:
  %t83 = phi %Player* [ %t81, %ring_rplace_ok_18 ], [ %t82, %ring_rplace_oob_19 ]
  %t84 = getelementptr inbounds %Player, %Player* %t83, i32 0, i32 1
  %t85 = load i32, i32* %t84
  %t86 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t86, i32 %t50, i8* %t67, i32 %t85)
  %t88 = load %Snapshot, %Snapshot* %t0
  %t89 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t90 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t89, i32 0, i32 0
  %t91 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t90, i32 0, i64 0
  %t92 = getelementptr inbounds %Player, %Player* %t91, i32 0, i32 0
  %t93 = load i8*, i8** %t92
  call void @star_rc_retain(i8* %t93)
  %t94 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t90, i32 0, i64 1
  %t95 = getelementptr inbounds %Player, %Player* %t94, i32 0, i32 0
  %t96 = load i8*, i8** %t95
  call void @star_rc_retain(i8* %t96)
  store %Snapshot %t88, %Snapshot* %t87
  %t97 = getelementptr inbounds %Snapshot, %Snapshot* %t87, i32 0, i32 1
  %t98 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t97, i32 0, i32 0
  %t99 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t97, i32 0, i32 1
  %t100 = load i64, i64* %t99
  %t101 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t97, i32 0, i32 2
  %t102 = load i64, i64* %t101
  %t103 = icmp sge i64 %t102, 3
  br i1 %t103, label %ring_push_full_21, label %ring_push_grow_22
ring_push_grow_22:
  %t104 = add i64 %t100, %t102
  %t105 = urem i64 %t104, 3
  %t106 = getelementptr inbounds [3 x i32], [3 x i32]* %t98, i32 0, i64 %t105
  store i32 3, i32* %t106
  %t107 = add i64 %t102, 1
  store i64 %t107, i64* %t101
  br label %ring_push_done_23
ring_push_full_21:
  %t108 = getelementptr inbounds [3 x i32], [3 x i32]* %t98, i32 0, i64 %t100
  store i32 3, i32* %t108
  %t109 = add i64 %t100, 1
  %t110 = urem i64 %t109, 3
  store i64 %t110, i64* %t99
  br label %ring_push_done_23
ring_push_done_23:
  %t111 = getelementptr inbounds %Snapshot, %Snapshot* %t87, i32 0, i32 1
  %t112 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t111, i32 0, i32 0
  %t113 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t111, i32 0, i32 1
  %t114 = load i64, i64* %t113
  %t115 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t111, i32 0, i32 2
  %t116 = load i64, i64* %t115
  %t117 = icmp sge i64 %t116, 3
  br i1 %t117, label %ring_push_full_24, label %ring_push_grow_25
ring_push_grow_25:
  %t118 = add i64 %t114, %t116
  %t119 = urem i64 %t118, 3
  %t120 = getelementptr inbounds [3 x i32], [3 x i32]* %t112, i32 0, i64 %t119
  store i32 4, i32* %t120
  %t121 = add i64 %t116, 1
  store i64 %t121, i64* %t115
  br label %ring_push_done_26
ring_push_full_24:
  %t122 = getelementptr inbounds [3 x i32], [3 x i32]* %t112, i32 0, i64 %t114
  store i32 4, i32* %t122
  %t123 = add i64 %t114, 1
  %t124 = urem i64 %t123, 3
  store i64 %t124, i64* %t113
  br label %ring_push_done_26
ring_push_done_26:
  %t125 = getelementptr inbounds %Snapshot, %Snapshot* %t87, i32 0, i32 1
  %t126 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t125, i32 0, i32 0
  %t127 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t125, i32 0, i32 1
  %t128 = load i64, i64* %t127
  %t129 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t125, i32 0, i32 2
  %t130 = load i64, i64* %t129
  %t131 = trunc i64 %t130 to i32
  %t132 = getelementptr inbounds %Snapshot, %Snapshot* %t87, i32 0, i32 1
  %t133 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t132, i32 0, i32 0
  %t134 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t132, i32 0, i32 1
  %t135 = load i64, i64* %t134
  %t136 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t132, i32 0, i32 2
  %t137 = load i64, i64* %t136
  %t138 = sext i32 0 to i64
  %t139 = load i64, i64* %t134
  %t140 = load i64, i64* %t136
  %t141 = icmp ult i64 %t138, %t140
  br i1 %t141, label %ring_rplace_ok_27, label %ring_rplace_oob_28
ring_rplace_ok_27:
  %t142 = add i64 %t139, %t138
  %t143 = urem i64 %t142, 3
  %t144 = getelementptr inbounds [3 x i32], [3 x i32]* %t133, i32 0, i64 %t143
  br label %ring_rplace_end_29
ring_rplace_oob_28:
  store i32 0, i32* %t145
  br label %ring_rplace_end_29
ring_rplace_end_29:
  %t146 = phi i32* [ %t144, %ring_rplace_ok_27 ], [ %t145, %ring_rplace_oob_28 ]
  %t147 = load i32, i32* %t146
  %t148 = getelementptr inbounds %Snapshot, %Snapshot* %t87, i32 0, i32 1
  %t149 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t148, i32 0, i32 0
  %t150 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t148, i32 0, i32 1
  %t151 = load i64, i64* %t150
  %t152 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t148, i32 0, i32 2
  %t153 = load i64, i64* %t152
  %t154 = sext i32 1 to i64
  %t155 = load i64, i64* %t150
  %t156 = load i64, i64* %t152
  %t157 = icmp ult i64 %t154, %t156
  br i1 %t157, label %ring_rplace_ok_30, label %ring_rplace_oob_31
ring_rplace_ok_30:
  %t158 = add i64 %t155, %t154
  %t159 = urem i64 %t158, 3
  %t160 = getelementptr inbounds [3 x i32], [3 x i32]* %t149, i32 0, i64 %t159
  br label %ring_rplace_end_32
ring_rplace_oob_31:
  store i32 0, i32* %t161
  br label %ring_rplace_end_32
ring_rplace_end_32:
  %t162 = phi i32* [ %t160, %ring_rplace_ok_30 ], [ %t161, %ring_rplace_oob_31 ]
  %t163 = load i32, i32* %t162
  %t164 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t164, i32 %t131, i32 %t147, i32 %t163)
  %t165 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t166 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t165, i32 0, i32 0
  %t167 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t165, i32 0, i32 1
  %t168 = load i64, i64* %t167
  %t169 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t165, i32 0, i32 2
  %t170 = load i64, i64* %t169
  %t171 = trunc i64 %t170 to i32
  %t172 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t173 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t172, i32 0, i32 0
  %t174 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t172, i32 0, i32 1
  %t175 = load i64, i64* %t174
  %t176 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t172, i32 0, i32 2
  %t177 = load i64, i64* %t176
  %t178 = sext i32 0 to i64
  %t179 = load i64, i64* %t174
  %t180 = load i64, i64* %t176
  %t181 = icmp ult i64 %t178, %t180
  br i1 %t181, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t182 = add i64 %t179, %t178
  %t183 = urem i64 %t182, 3
  %t184 = getelementptr inbounds [3 x i32], [3 x i32]* %t173, i32 0, i64 %t183
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store i32 0, i32* %t185
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t186 = phi i32* [ %t184, %ring_rplace_ok_33 ], [ %t185, %ring_rplace_oob_34 ]
  %t187 = load i32, i32* %t186
  %t188 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t189 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t188, i32 0, i32 0
  %t190 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t188, i32 0, i32 1
  %t191 = load i64, i64* %t190
  %t192 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t188, i32 0, i32 2
  %t193 = load i64, i64* %t192
  %t194 = sext i32 1 to i64
  %t195 = load i64, i64* %t190
  %t196 = load i64, i64* %t192
  %t197 = icmp ult i64 %t194, %t196
  br i1 %t197, label %ring_rplace_ok_36, label %ring_rplace_oob_37
ring_rplace_ok_36:
  %t198 = add i64 %t195, %t194
  %t199 = urem i64 %t198, 3
  %t200 = getelementptr inbounds [3 x i32], [3 x i32]* %t189, i32 0, i64 %t199
  br label %ring_rplace_end_38
ring_rplace_oob_37:
  store i32 0, i32* %t201
  br label %ring_rplace_end_38
ring_rplace_end_38:
  %t202 = phi i32* [ %t200, %ring_rplace_ok_36 ], [ %t201, %ring_rplace_oob_37 ]
  %t203 = load i32, i32* %t202
  %t204 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t204, i32 %t171, i32 %t187, i32 %t203)
  store i8* null, i8** %t205
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t206
  %t207 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t208 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 0
  %t209 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 1
  %t210 = load i64, i64* %t209
  %t211 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 2
  %t212 = load i64, i64* %t211
  %t213 = icmp sge i64 %t212, 2
  br i1 %t213, label %ring_push_full_39, label %ring_push_grow_40
ring_push_grow_40:
  %t214 = add i64 %t210, %t212
  %t215 = urem i64 %t214, 2
  %t216 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t208, i32 0, i64 %t215
  store i8* %t207, i8** %t216
  %t217 = add i64 %t212, 1
  store i64 %t217, i64* %t211
  br label %ring_push_done_41
ring_push_full_39:
  %t218 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t208, i32 0, i64 %t210
  %t219 = load i8*, i8** %t218
  call void @star_rc_release(i8* %t219)
  store i8* %t207, i8** %t218
  %t220 = add i64 %t210, 1
  %t221 = urem i64 %t220, 2
  store i64 %t221, i64* %t209
  br label %ring_push_done_41
ring_push_done_41:
  %t222 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t223 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 0
  %t224 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 1
  %t225 = load i64, i64* %t224
  %t226 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 2
  %t227 = load i64, i64* %t226
  %t228 = icmp sge i64 %t227, 2
  br i1 %t228, label %ring_push_full_42, label %ring_push_grow_43
ring_push_grow_43:
  %t229 = add i64 %t225, %t227
  %t230 = urem i64 %t229, 2
  %t231 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t223, i32 0, i64 %t230
  store i8* %t222, i8** %t231
  %t232 = add i64 %t227, 1
  store i64 %t232, i64* %t226
  br label %ring_push_done_44
ring_push_full_42:
  %t233 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t223, i32 0, i64 %t225
  %t234 = load i8*, i8** %t233
  call void @star_rc_release(i8* %t234)
  store i8* %t222, i8** %t233
  %t235 = add i64 %t225, 1
  %t236 = urem i64 %t235, 2
  store i64 %t236, i64* %t224
  br label %ring_push_done_44
ring_push_done_44:
  %t237 = load i8*, i8** %t205
  %t238 = icmp eq i8* %t237, null
  br i1 %t238, label %table_cow_alloc_45, label %table_cow_check_46
table_cow_alloc_45:
  %t258 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t259 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t260 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t259 to i64
  %t261 = call i8* @star_rc_alloc(i64 %t260, i8* %t258)
  %t262 = bitcast i8* %t261 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t263 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t262, i32 0, i32 0
  store i64 0, i64* %t263
  %t264 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t262, i32 0, i32 1
  store i64 0, i64* %t264
  %t265 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t262, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t265
  %t266 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t262, i32 0, i32 3
  store i32* null, i32** %t266
  store i8* %t261, i8** %t205
  br label %table_cow_done_47
table_cow_check_46:
  %t267 = getelementptr inbounds i8, i8* %t237, i64 -16
  %t268 = bitcast i8* %t267 to i64*
  %t269 = load atomic i64, i64* %t268 seq_cst, align 8
  %t270 = icmp eq i64 %t269, 1
  br i1 %t270, label %table_cow_done_47, label %table_cow_clone_51
table_cow_clone_51:
  %t271 = bitcast i8* %t237 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t272 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t271, i32 0, i32 0
  %t273 = load i64, i64* %t272
  %t274 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t271, i32 0, i32 1
  %t275 = load i64, i64* %t274
  %t276 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t277 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t278 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t277 to i64
  %t279 = call i8* @star_rc_alloc(i64 %t278, i8* %t276)
  %t280 = bitcast i8* %t279 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t281 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t280, i32 0, i32 0
  store i64 %t273, i64* %t281
  %t282 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t280, i32 0, i32 1
  store i64 %t275, i64* %t282
  %t283 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t284 = ptrtoint { [2 x i8*], i64, i64 }* %t283 to i64
  %t285 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t271, i32 0, i32 2
  %t286 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t285
  %t287 = mul i64 %t275, %t284
  %t288 = call i8* @malloc(i64 %t287)
  %t289 = bitcast i8* %t288 to { [2 x i8*], i64, i64 }*
  %t290 = icmp sgt i64 %t273, 0
  br i1 %t290, label %table_cow_copy_52, label %table_cow_after_copy_53
table_cow_copy_52:
  %t291 = mul i64 %t273, %t284
  %t292 = bitcast { [2 x i8*], i64, i64 }* %t286 to i8*
  call i8* @memcpy(i8* %t288, i8* %t292, i64 %t291)
  store i64 0, i64* %t293
  br label %table_cow_retain_cond_54
table_cow_retain_cond_54:
  %t294 = load i64, i64* %t293
  %t295 = icmp slt i64 %t294, %t273
  br i1 %t295, label %table_cow_retain_body_55, label %table_cow_retain_end_56
table_cow_retain_body_55:
  %t296 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t289, i64 %t294
  %t297 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t296, i32 0, i32 0
  %t298 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t297, i32 0, i64 0
  %t299 = load i8*, i8** %t298
  call void @star_rc_retain(i8* %t299)
  %t300 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t297, i32 0, i64 1
  %t301 = load i8*, i8** %t300
  call void @star_rc_retain(i8* %t301)
  %t302 = add i64 %t294, 1
  store i64 %t302, i64* %t293
  br label %table_cow_retain_cond_54
table_cow_retain_end_56:
  br label %table_cow_after_copy_53
table_cow_after_copy_53:
  %t303 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t280, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t289, { [2 x i8*], i64, i64 }** %t303
  %t304 = getelementptr i32, i32* null, i32 1
  %t305 = ptrtoint i32* %t304 to i64
  %t306 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t271, i32 0, i32 3
  %t307 = load i32*, i32** %t306
  %t308 = mul i64 %t275, %t305
  %t309 = call i8* @malloc(i64 %t308)
  %t310 = bitcast i8* %t309 to i32*
  %t311 = icmp sgt i64 %t273, 0
  br i1 %t311, label %table_cow_copy_57, label %table_cow_after_copy_58
table_cow_copy_57:
  %t312 = mul i64 %t273, %t305
  %t313 = bitcast i32* %t307 to i8*
  call i8* @memcpy(i8* %t309, i8* %t313, i64 %t312)
  br label %table_cow_after_copy_58
table_cow_after_copy_58:
  %t314 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t280, i32 0, i32 3
  store i32* %t310, i32** %t314
  call void @star_rc_release(i8* %t237)
  store i8* %t279, i8** %t205
  br label %table_cow_done_47
table_cow_done_47:
  %t315 = load i8*, i8** %t205
  %t316 = bitcast i8* %t315 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t317 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t316, i32 0, i32 0
  %t318 = load i64, i64* %t317
  %t319 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t316, i32 0, i32 1
  %t320 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t316, i32 0, i32 2
  %t321 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t320
  %t322 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t316, i32 0, i32 3
  %t323 = load i32*, i32** %t322
  %t325 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206
  %t326 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 0
  %t327 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t326, i32 0, i64 0
  %t328 = load i8*, i8** %t327
  call void @star_rc_retain(i8* %t328)
  %t329 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t326, i32 0, i64 1
  %t330 = load i8*, i8** %t329
  call void @star_rc_retain(i8* %t330)
  %t331 = getelementptr inbounds %Bag, %Bag* %t324, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t325, { [2 x i8*], i64, i64 }* %t331
  %t332 = getelementptr inbounds %Bag, %Bag* %t324, i32 0, i32 1
  store i32 1, i32* %t332
  %t333 = load %Bag, %Bag* %t324
  %t334 = load i64, i64* %t319
  %t335 = load i64, i64* %t317
  %t336 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t320
  %t337 = load i32*, i32** %t322
  %t338 = icmp sge i64 %t335, %t334
  br i1 %t338, label %table_push_grow_59, label %table_push_store_60
table_push_grow_59:
  %t339 = mul i64 %t334, 2
  %t340 = icmp sgt i64 %t339, 0
  %t341 = select i1 %t340, i64 %t339, i64 1
  %t342 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t343 = ptrtoint { [2 x i8*], i64, i64 }* %t342 to i64
  %t344 = mul i64 %t341, %t343
  %t345 = call i8* @malloc(i64 %t344)
  %t346 = bitcast i8* %t345 to { [2 x i8*], i64, i64 }*
  %t347 = icmp sgt i64 %t334, 0
  br i1 %t347, label %table_push_copy_61, label %table_push_after_copy_62
table_push_copy_61:
  %t348 = mul i64 %t335, %t343
  %t349 = bitcast { [2 x i8*], i64, i64 }* %t336 to i8*
  call i8* @memcpy(i8* %t345, i8* %t349, i64 %t348)
  call void @free(i8* %t349)
  br label %table_push_after_copy_62
table_push_after_copy_62:
  store { [2 x i8*], i64, i64 }* %t346, { [2 x i8*], i64, i64 }** %t320
  %t350 = getelementptr i32, i32* null, i32 1
  %t351 = ptrtoint i32* %t350 to i64
  %t352 = mul i64 %t341, %t351
  %t353 = call i8* @malloc(i64 %t352)
  %t354 = bitcast i8* %t353 to i32*
  %t355 = icmp sgt i64 %t334, 0
  br i1 %t355, label %table_push_copy_63, label %table_push_after_copy_64
table_push_copy_63:
  %t356 = mul i64 %t335, %t351
  %t357 = bitcast i32* %t337 to i8*
  call i8* @memcpy(i8* %t353, i8* %t357, i64 %t356)
  call void @free(i8* %t357)
  br label %table_push_after_copy_64
table_push_after_copy_64:
  store i32* %t354, i32** %t322
  store i64 %t341, i64* %t319
  br label %table_push_store_60
table_push_store_60:
  %t358 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t320
  %t359 = extractvalue %Bag %t333, 0
  %t360 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t358, i64 %t335
  store { [2 x i8*], i64, i64 } %t359, { [2 x i8*], i64, i64 }* %t360
  %t361 = load i32*, i32** %t322
  %t362 = extractvalue %Bag %t333, 1
  %t363 = getelementptr inbounds i32, i32* %t361, i64 %t335
  store i32 %t362, i32* %t363
  %t364 = add i64 %t335, 1
  store i64 %t364, i64* %t317
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t365
  %t366 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t367 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t365, i32 0, i32 0
  %t368 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t365, i32 0, i32 1
  %t369 = load i64, i64* %t368
  %t370 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t365, i32 0, i32 2
  %t371 = load i64, i64* %t370
  %t372 = icmp sge i64 %t371, 2
  br i1 %t372, label %ring_push_full_65, label %ring_push_grow_66
ring_push_grow_66:
  %t373 = add i64 %t369, %t371
  %t374 = urem i64 %t373, 2
  %t375 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t367, i32 0, i64 %t374
  store i8* %t366, i8** %t375
  %t376 = add i64 %t371, 1
  store i64 %t376, i64* %t370
  br label %ring_push_done_67
ring_push_full_65:
  %t377 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t367, i32 0, i64 %t369
  %t378 = load i8*, i8** %t377
  call void @star_rc_release(i8* %t378)
  store i8* %t366, i8** %t377
  %t379 = add i64 %t369, 1
  %t380 = urem i64 %t379, 2
  store i64 %t380, i64* %t368
  br label %ring_push_done_67
ring_push_done_67:
  %t381 = load i8*, i8** %t205
  %t382 = icmp eq i8* %t381, null
  br i1 %t382, label %table_cow_alloc_68, label %table_cow_check_69
table_cow_alloc_68:
  %t383 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t384 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t385 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t384 to i64
  %t386 = call i8* @star_rc_alloc(i64 %t385, i8* %t383)
  %t387 = bitcast i8* %t386 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t388 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t387, i32 0, i32 0
  store i64 0, i64* %t388
  %t389 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t387, i32 0, i32 1
  store i64 0, i64* %t389
  %t390 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t387, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t390
  %t391 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t387, i32 0, i32 3
  store i32* null, i32** %t391
  store i8* %t386, i8** %t205
  br label %table_cow_done_70
table_cow_check_69:
  %t392 = getelementptr inbounds i8, i8* %t381, i64 -16
  %t393 = bitcast i8* %t392 to i64*
  %t394 = load atomic i64, i64* %t393 seq_cst, align 8
  %t395 = icmp eq i64 %t394, 1
  br i1 %t395, label %table_cow_done_70, label %table_cow_clone_71
table_cow_clone_71:
  %t396 = bitcast i8* %t381 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t397 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t396, i32 0, i32 0
  %t398 = load i64, i64* %t397
  %t399 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t396, i32 0, i32 1
  %t400 = load i64, i64* %t399
  %t401 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t402 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t403 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t402 to i64
  %t404 = call i8* @star_rc_alloc(i64 %t403, i8* %t401)
  %t405 = bitcast i8* %t404 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t406 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t405, i32 0, i32 0
  store i64 %t398, i64* %t406
  %t407 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t405, i32 0, i32 1
  store i64 %t400, i64* %t407
  %t408 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t409 = ptrtoint { [2 x i8*], i64, i64 }* %t408 to i64
  %t410 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t396, i32 0, i32 2
  %t411 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t410
  %t412 = mul i64 %t400, %t409
  %t413 = call i8* @malloc(i64 %t412)
  %t414 = bitcast i8* %t413 to { [2 x i8*], i64, i64 }*
  %t415 = icmp sgt i64 %t398, 0
  br i1 %t415, label %table_cow_copy_72, label %table_cow_after_copy_73
table_cow_copy_72:
  %t416 = mul i64 %t398, %t409
  %t417 = bitcast { [2 x i8*], i64, i64 }* %t411 to i8*
  call i8* @memcpy(i8* %t413, i8* %t417, i64 %t416)
  store i64 0, i64* %t418
  br label %table_cow_retain_cond_74
table_cow_retain_cond_74:
  %t419 = load i64, i64* %t418
  %t420 = icmp slt i64 %t419, %t398
  br i1 %t420, label %table_cow_retain_body_75, label %table_cow_retain_end_76
table_cow_retain_body_75:
  %t421 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t414, i64 %t419
  %t422 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t421, i32 0, i32 0
  %t423 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t422, i32 0, i64 0
  %t424 = load i8*, i8** %t423
  call void @star_rc_retain(i8* %t424)
  %t425 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t422, i32 0, i64 1
  %t426 = load i8*, i8** %t425
  call void @star_rc_retain(i8* %t426)
  %t427 = add i64 %t419, 1
  store i64 %t427, i64* %t418
  br label %table_cow_retain_cond_74
table_cow_retain_end_76:
  br label %table_cow_after_copy_73
table_cow_after_copy_73:
  %t428 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t405, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t414, { [2 x i8*], i64, i64 }** %t428
  %t429 = getelementptr i32, i32* null, i32 1
  %t430 = ptrtoint i32* %t429 to i64
  %t431 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t396, i32 0, i32 3
  %t432 = load i32*, i32** %t431
  %t433 = mul i64 %t400, %t430
  %t434 = call i8* @malloc(i64 %t433)
  %t435 = bitcast i8* %t434 to i32*
  %t436 = icmp sgt i64 %t398, 0
  br i1 %t436, label %table_cow_copy_77, label %table_cow_after_copy_78
table_cow_copy_77:
  %t437 = mul i64 %t398, %t430
  %t438 = bitcast i32* %t432 to i8*
  call i8* @memcpy(i8* %t434, i8* %t438, i64 %t437)
  br label %table_cow_after_copy_78
table_cow_after_copy_78:
  %t439 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t405, i32 0, i32 3
  store i32* %t435, i32** %t439
  call void @star_rc_release(i8* %t381)
  store i8* %t404, i8** %t205
  br label %table_cow_done_70
table_cow_done_70:
  %t440 = load i8*, i8** %t205
  %t441 = bitcast i8* %t440 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t442 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t441, i32 0, i32 0
  %t443 = load i64, i64* %t442
  %t444 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t441, i32 0, i32 1
  %t445 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t441, i32 0, i32 2
  %t446 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t445
  %t447 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t441, i32 0, i32 3
  %t448 = load i32*, i32** %t447
  %t450 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t365
  %t451 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t365, i32 0, i32 0
  %t452 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t451, i32 0, i64 0
  %t453 = load i8*, i8** %t452
  call void @star_rc_retain(i8* %t453)
  %t454 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t451, i32 0, i64 1
  %t455 = load i8*, i8** %t454
  call void @star_rc_retain(i8* %t455)
  %t456 = getelementptr inbounds %Bag, %Bag* %t449, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t450, { [2 x i8*], i64, i64 }* %t456
  %t457 = getelementptr inbounds %Bag, %Bag* %t449, i32 0, i32 1
  store i32 2, i32* %t457
  %t458 = load %Bag, %Bag* %t449
  %t459 = load i64, i64* %t444
  %t460 = load i64, i64* %t442
  %t461 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t445
  %t462 = load i32*, i32** %t447
  %t463 = icmp sge i64 %t460, %t459
  br i1 %t463, label %table_push_grow_79, label %table_push_store_80
table_push_grow_79:
  %t464 = mul i64 %t459, 2
  %t465 = icmp sgt i64 %t464, 0
  %t466 = select i1 %t465, i64 %t464, i64 1
  %t467 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t468 = ptrtoint { [2 x i8*], i64, i64 }* %t467 to i64
  %t469 = mul i64 %t466, %t468
  %t470 = call i8* @malloc(i64 %t469)
  %t471 = bitcast i8* %t470 to { [2 x i8*], i64, i64 }*
  %t472 = icmp sgt i64 %t459, 0
  br i1 %t472, label %table_push_copy_81, label %table_push_after_copy_82
table_push_copy_81:
  %t473 = mul i64 %t460, %t468
  %t474 = bitcast { [2 x i8*], i64, i64 }* %t461 to i8*
  call i8* @memcpy(i8* %t470, i8* %t474, i64 %t473)
  call void @free(i8* %t474)
  br label %table_push_after_copy_82
table_push_after_copy_82:
  store { [2 x i8*], i64, i64 }* %t471, { [2 x i8*], i64, i64 }** %t445
  %t475 = getelementptr i32, i32* null, i32 1
  %t476 = ptrtoint i32* %t475 to i64
  %t477 = mul i64 %t466, %t476
  %t478 = call i8* @malloc(i64 %t477)
  %t479 = bitcast i8* %t478 to i32*
  %t480 = icmp sgt i64 %t459, 0
  br i1 %t480, label %table_push_copy_83, label %table_push_after_copy_84
table_push_copy_83:
  %t481 = mul i64 %t460, %t476
  %t482 = bitcast i32* %t462 to i8*
  call i8* @memcpy(i8* %t478, i8* %t482, i64 %t481)
  call void @free(i8* %t482)
  br label %table_push_after_copy_84
table_push_after_copy_84:
  store i32* %t479, i32** %t447
  store i64 %t466, i64* %t444
  br label %table_push_store_80
table_push_store_80:
  %t483 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t445
  %t484 = extractvalue %Bag %t458, 0
  %t485 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t483, i64 %t460
  store { [2 x i8*], i64, i64 } %t484, { [2 x i8*], i64, i64 }* %t485
  %t486 = load i32*, i32** %t447
  %t487 = extractvalue %Bag %t458, 1
  %t488 = getelementptr inbounds i32, i32* %t486, i64 %t460
  store i32 %t487, i32* %t488
  %t489 = add i64 %t460, 1
  store i64 %t489, i64* %t442
  %t490 = load i8*, i8** %t205
  %t491 = icmp eq i8* %t490, null
  br i1 %t491, label %table_read_null_85, label %table_read_real_86
table_read_null_85:
  br label %table_read_end_87
table_read_real_86:
  %t492 = bitcast i8* %t490 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t493 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t492, i32 0, i32 0
  %t494 = load i64, i64* %t493
  %t495 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t492, i32 0, i32 2
  %t496 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t495
  %t497 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t492, i32 0, i32 3
  %t498 = load i32*, i32** %t497
  br label %table_read_end_87
table_read_end_87:
  %t499 = phi i64 [ 0, %table_read_null_85 ], [ %t494, %table_read_real_86 ]
  %t500 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_85 ], [ %t496, %table_read_real_86 ]
  %t501 = phi i32* [ null, %table_read_null_85 ], [ %t498, %table_read_real_86 ]
  %t502 = trunc i64 %t499 to i32
  %t503 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t503, i32 %t502)
  %t504 = sext i32 0 to i64
  %t505 = load i8*, i8** %t205
  %t506 = icmp eq i8* %t505, null
  br i1 %t506, label %table_read_null_88, label %table_read_real_89
table_read_null_88:
  br label %table_read_end_90
table_read_real_89:
  %t507 = bitcast i8* %t505 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t508 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t507, i32 0, i32 0
  %t509 = load i64, i64* %t508
  %t510 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t507, i32 0, i32 2
  %t511 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t510
  %t512 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t507, i32 0, i32 3
  %t513 = load i32*, i32** %t512
  br label %table_read_end_90
table_read_end_90:
  %t514 = phi i64 [ 0, %table_read_null_88 ], [ %t509, %table_read_real_89 ]
  %t515 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_88 ], [ %t511, %table_read_real_89 ]
  %t516 = phi i32* [ null, %table_read_null_88 ], [ %t513, %table_read_real_89 ]
  %t518 = icmp ult i64 %t504, %t514
  br i1 %t518, label %table_idx_ok_91, label %table_idx_oob_92
table_idx_ok_91:
  %t519 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t515, i64 %t504
  %t520 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t519, i32 0, i32 0
  %t521 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t520, i32 0, i64 0
  %t522 = load i8*, i8** %t521
  call void @star_rc_retain(i8* %t522)
  %t523 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t520, i32 0, i64 1
  %t524 = load i8*, i8** %t523
  call void @star_rc_retain(i8* %t524)
  %t525 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t519
  %t526 = getelementptr inbounds %Bag, %Bag* %t517, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t525, { [2 x i8*], i64, i64 }* %t526
  %t527 = getelementptr inbounds i32, i32* %t516, i64 %t504
  %t528 = load i32, i32* %t527
  %t529 = getelementptr inbounds %Bag, %Bag* %t517, i32 0, i32 1
  store i32 %t528, i32* %t529
  br label %table_idx_end_93
table_idx_oob_92:
  store %Bag zeroinitializer, %Bag* %t517
  br label %table_idx_end_93
table_idx_end_93:
  %t530 = load %Bag, %Bag* %t517
  store %Bag %t530, %Bag* %t531
  %t532 = getelementptr inbounds %Bag, %Bag* %t531, i32 0, i32 1
  %t533 = load i32, i32* %t532
  %t534 = sext i32 0 to i64
  %t535 = load i8*, i8** %t205
  %t536 = icmp eq i8* %t535, null
  br i1 %t536, label %table_read_null_94, label %table_read_real_95
table_read_null_94:
  br label %table_read_end_96
table_read_real_95:
  %t537 = bitcast i8* %t535 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t538 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t537, i32 0, i32 0
  %t539 = load i64, i64* %t538
  %t540 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t537, i32 0, i32 2
  %t541 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t540
  %t542 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t537, i32 0, i32 3
  %t543 = load i32*, i32** %t542
  br label %table_read_end_96
table_read_end_96:
  %t544 = phi i64 [ 0, %table_read_null_94 ], [ %t539, %table_read_real_95 ]
  %t545 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_94 ], [ %t541, %table_read_real_95 ]
  %t546 = phi i32* [ null, %table_read_null_94 ], [ %t543, %table_read_real_95 ]
  %t548 = icmp ult i64 %t534, %t544
  br i1 %t548, label %table_idx_ok_97, label %table_idx_oob_98
table_idx_ok_97:
  %t549 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t545, i64 %t534
  %t550 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t549, i32 0, i32 0
  %t551 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t550, i32 0, i64 0
  %t552 = load i8*, i8** %t551
  call void @star_rc_retain(i8* %t552)
  %t553 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t550, i32 0, i64 1
  %t554 = load i8*, i8** %t553
  call void @star_rc_retain(i8* %t554)
  %t555 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t549
  %t556 = getelementptr inbounds %Bag, %Bag* %t547, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t555, { [2 x i8*], i64, i64 }* %t556
  %t557 = getelementptr inbounds i32, i32* %t546, i64 %t534
  %t558 = load i32, i32* %t557
  %t559 = getelementptr inbounds %Bag, %Bag* %t547, i32 0, i32 1
  store i32 %t558, i32* %t559
  br label %table_idx_end_99
table_idx_oob_98:
  store %Bag zeroinitializer, %Bag* %t547
  br label %table_idx_end_99
table_idx_end_99:
  %t560 = load %Bag, %Bag* %t547
  store %Bag %t560, %Bag* %t561
  %t562 = getelementptr inbounds %Bag, %Bag* %t561, i32 0, i32 0
  %t563 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t562, i32 0, i32 0
  %t564 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t562, i32 0, i32 1
  %t565 = load i64, i64* %t564
  %t566 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t562, i32 0, i32 2
  %t567 = load i64, i64* %t566
  %t568 = trunc i64 %t567 to i32
  %t569 = sext i32 0 to i64
  %t570 = load i8*, i8** %t205
  %t571 = icmp eq i8* %t570, null
  br i1 %t571, label %table_read_null_100, label %table_read_real_101
table_read_null_100:
  br label %table_read_end_102
table_read_real_101:
  %t572 = bitcast i8* %t570 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t573 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t572, i32 0, i32 0
  %t574 = load i64, i64* %t573
  %t575 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t572, i32 0, i32 2
  %t576 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t575
  %t577 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t572, i32 0, i32 3
  %t578 = load i32*, i32** %t577
  br label %table_read_end_102
table_read_end_102:
  %t579 = phi i64 [ 0, %table_read_null_100 ], [ %t574, %table_read_real_101 ]
  %t580 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_100 ], [ %t576, %table_read_real_101 ]
  %t581 = phi i32* [ null, %table_read_null_100 ], [ %t578, %table_read_real_101 ]
  %t583 = icmp ult i64 %t569, %t579
  br i1 %t583, label %table_idx_ok_103, label %table_idx_oob_104
table_idx_ok_103:
  %t584 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t580, i64 %t569
  %t585 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t584, i32 0, i32 0
  %t586 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t585, i32 0, i64 0
  %t587 = load i8*, i8** %t586
  call void @star_rc_retain(i8* %t587)
  %t588 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t585, i32 0, i64 1
  %t589 = load i8*, i8** %t588
  call void @star_rc_retain(i8* %t589)
  %t590 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t584
  %t591 = getelementptr inbounds %Bag, %Bag* %t582, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t590, { [2 x i8*], i64, i64 }* %t591
  %t592 = getelementptr inbounds i32, i32* %t581, i64 %t569
  %t593 = load i32, i32* %t592
  %t594 = getelementptr inbounds %Bag, %Bag* %t582, i32 0, i32 1
  store i32 %t593, i32* %t594
  br label %table_idx_end_105
table_idx_oob_104:
  store %Bag zeroinitializer, %Bag* %t582
  br label %table_idx_end_105
table_idx_end_105:
  %t595 = load %Bag, %Bag* %t582
  store %Bag %t595, %Bag* %t596
  %t597 = getelementptr inbounds %Bag, %Bag* %t596, i32 0, i32 0
  %t598 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t597, i32 0, i32 0
  %t599 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t597, i32 0, i32 1
  %t600 = load i64, i64* %t599
  %t601 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t597, i32 0, i32 2
  %t602 = load i64, i64* %t601
  %t603 = sext i32 0 to i64
  %t604 = load i64, i64* %t599
  %t605 = load i64, i64* %t601
  %t606 = icmp ult i64 %t603, %t605
  br i1 %t606, label %ring_rplace_ok_106, label %ring_rplace_oob_107
ring_rplace_ok_106:
  %t607 = add i64 %t604, %t603
  %t608 = urem i64 %t607, 2
  %t609 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t598, i32 0, i64 %t608
  br label %ring_rplace_end_108
ring_rplace_oob_107:
  store i8* null, i8** %t610
  br label %ring_rplace_end_108
ring_rplace_end_108:
  %t611 = phi i8** [ %t609, %ring_rplace_ok_106 ], [ %t610, %ring_rplace_oob_107 ]
  %t612 = load i8*, i8** %t611
  call void @star_rc_release(i8* %t612)
  %t613 = sext i32 0 to i64
  %t614 = load i8*, i8** %t205
  %t615 = icmp eq i8* %t614, null
  br i1 %t615, label %table_read_null_109, label %table_read_real_110
table_read_null_109:
  br label %table_read_end_111
table_read_real_110:
  %t616 = bitcast i8* %t614 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t617 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t616, i32 0, i32 0
  %t618 = load i64, i64* %t617
  %t619 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t616, i32 0, i32 2
  %t620 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t619
  %t621 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t616, i32 0, i32 3
  %t622 = load i32*, i32** %t621
  br label %table_read_end_111
table_read_end_111:
  %t623 = phi i64 [ 0, %table_read_null_109 ], [ %t618, %table_read_real_110 ]
  %t624 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_109 ], [ %t620, %table_read_real_110 ]
  %t625 = phi i32* [ null, %table_read_null_109 ], [ %t622, %table_read_real_110 ]
  %t627 = icmp ult i64 %t613, %t623
  br i1 %t627, label %table_idx_ok_112, label %table_idx_oob_113
table_idx_ok_112:
  %t628 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t624, i64 %t613
  %t629 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t628, i32 0, i32 0
  %t630 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t629, i32 0, i64 0
  %t631 = load i8*, i8** %t630
  call void @star_rc_retain(i8* %t631)
  %t632 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t629, i32 0, i64 1
  %t633 = load i8*, i8** %t632
  call void @star_rc_retain(i8* %t633)
  %t634 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t628
  %t635 = getelementptr inbounds %Bag, %Bag* %t626, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t634, { [2 x i8*], i64, i64 }* %t635
  %t636 = getelementptr inbounds i32, i32* %t625, i64 %t613
  %t637 = load i32, i32* %t636
  %t638 = getelementptr inbounds %Bag, %Bag* %t626, i32 0, i32 1
  store i32 %t637, i32* %t638
  br label %table_idx_end_114
table_idx_oob_113:
  store %Bag zeroinitializer, %Bag* %t626
  br label %table_idx_end_114
table_idx_end_114:
  %t639 = load %Bag, %Bag* %t626
  store %Bag %t639, %Bag* %t640
  %t641 = getelementptr inbounds %Bag, %Bag* %t640, i32 0, i32 0
  %t642 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t641, i32 0, i32 0
  %t643 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t641, i32 0, i32 1
  %t644 = load i64, i64* %t643
  %t645 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t641, i32 0, i32 2
  %t646 = load i64, i64* %t645
  %t647 = sext i32 1 to i64
  %t648 = load i64, i64* %t643
  %t649 = load i64, i64* %t645
  %t650 = icmp ult i64 %t647, %t649
  br i1 %t650, label %ring_rplace_ok_115, label %ring_rplace_oob_116
ring_rplace_ok_115:
  %t651 = add i64 %t648, %t647
  %t652 = urem i64 %t651, 2
  %t653 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t642, i32 0, i64 %t652
  br label %ring_rplace_end_117
ring_rplace_oob_116:
  store i8* null, i8** %t654
  br label %ring_rplace_end_117
ring_rplace_end_117:
  %t655 = phi i8** [ %t653, %ring_rplace_ok_115 ], [ %t654, %ring_rplace_oob_116 ]
  %t656 = load i8*, i8** %t655
  call void @star_rc_release(i8* %t656)
  %t657 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t657, i32 %t533, i32 %t568, i8* %t612, i8* %t656)
  %t658 = sext i32 1 to i64
  %t659 = load i8*, i8** %t205
  %t660 = icmp eq i8* %t659, null
  br i1 %t660, label %table_read_null_118, label %table_read_real_119
table_read_null_118:
  br label %table_read_end_120
table_read_real_119:
  %t661 = bitcast i8* %t659 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t662 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t661, i32 0, i32 0
  %t663 = load i64, i64* %t662
  %t664 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t661, i32 0, i32 2
  %t665 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t664
  %t666 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t661, i32 0, i32 3
  %t667 = load i32*, i32** %t666
  br label %table_read_end_120
table_read_end_120:
  %t668 = phi i64 [ 0, %table_read_null_118 ], [ %t663, %table_read_real_119 ]
  %t669 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_118 ], [ %t665, %table_read_real_119 ]
  %t670 = phi i32* [ null, %table_read_null_118 ], [ %t667, %table_read_real_119 ]
  %t672 = icmp ult i64 %t658, %t668
  br i1 %t672, label %table_idx_ok_121, label %table_idx_oob_122
table_idx_ok_121:
  %t673 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t669, i64 %t658
  %t674 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t673, i32 0, i32 0
  %t675 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t674, i32 0, i64 0
  %t676 = load i8*, i8** %t675
  call void @star_rc_retain(i8* %t676)
  %t677 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t674, i32 0, i64 1
  %t678 = load i8*, i8** %t677
  call void @star_rc_retain(i8* %t678)
  %t679 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t673
  %t680 = getelementptr inbounds %Bag, %Bag* %t671, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t679, { [2 x i8*], i64, i64 }* %t680
  %t681 = getelementptr inbounds i32, i32* %t670, i64 %t658
  %t682 = load i32, i32* %t681
  %t683 = getelementptr inbounds %Bag, %Bag* %t671, i32 0, i32 1
  store i32 %t682, i32* %t683
  br label %table_idx_end_123
table_idx_oob_122:
  store %Bag zeroinitializer, %Bag* %t671
  br label %table_idx_end_123
table_idx_end_123:
  %t684 = load %Bag, %Bag* %t671
  store %Bag %t684, %Bag* %t685
  %t686 = getelementptr inbounds %Bag, %Bag* %t685, i32 0, i32 1
  %t687 = load i32, i32* %t686
  %t688 = sext i32 1 to i64
  %t689 = load i8*, i8** %t205
  %t690 = icmp eq i8* %t689, null
  br i1 %t690, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t691 = bitcast i8* %t689 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t692 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t691, i32 0, i32 0
  %t693 = load i64, i64* %t692
  %t694 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t691, i32 0, i32 2
  %t695 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t694
  %t696 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t691, i32 0, i32 3
  %t697 = load i32*, i32** %t696
  br label %table_read_end_126
table_read_end_126:
  %t698 = phi i64 [ 0, %table_read_null_124 ], [ %t693, %table_read_real_125 ]
  %t699 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_124 ], [ %t695, %table_read_real_125 ]
  %t700 = phi i32* [ null, %table_read_null_124 ], [ %t697, %table_read_real_125 ]
  %t702 = icmp ult i64 %t688, %t698
  br i1 %t702, label %table_idx_ok_127, label %table_idx_oob_128
table_idx_ok_127:
  %t703 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t699, i64 %t688
  %t704 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t703, i32 0, i32 0
  %t705 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t704, i32 0, i64 0
  %t706 = load i8*, i8** %t705
  call void @star_rc_retain(i8* %t706)
  %t707 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t704, i32 0, i64 1
  %t708 = load i8*, i8** %t707
  call void @star_rc_retain(i8* %t708)
  %t709 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t703
  %t710 = getelementptr inbounds %Bag, %Bag* %t701, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t709, { [2 x i8*], i64, i64 }* %t710
  %t711 = getelementptr inbounds i32, i32* %t700, i64 %t688
  %t712 = load i32, i32* %t711
  %t713 = getelementptr inbounds %Bag, %Bag* %t701, i32 0, i32 1
  store i32 %t712, i32* %t713
  br label %table_idx_end_129
table_idx_oob_128:
  store %Bag zeroinitializer, %Bag* %t701
  br label %table_idx_end_129
table_idx_end_129:
  %t714 = load %Bag, %Bag* %t701
  store %Bag %t714, %Bag* %t715
  %t716 = getelementptr inbounds %Bag, %Bag* %t715, i32 0, i32 0
  %t717 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t716, i32 0, i32 0
  %t718 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t716, i32 0, i32 1
  %t719 = load i64, i64* %t718
  %t720 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t716, i32 0, i32 2
  %t721 = load i64, i64* %t720
  %t722 = trunc i64 %t721 to i32
  %t723 = sext i32 1 to i64
  %t724 = load i8*, i8** %t205
  %t725 = icmp eq i8* %t724, null
  br i1 %t725, label %table_read_null_130, label %table_read_real_131
table_read_null_130:
  br label %table_read_end_132
table_read_real_131:
  %t726 = bitcast i8* %t724 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t727 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t726, i32 0, i32 0
  %t728 = load i64, i64* %t727
  %t729 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t726, i32 0, i32 2
  %t730 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t729
  %t731 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t726, i32 0, i32 3
  %t732 = load i32*, i32** %t731
  br label %table_read_end_132
table_read_end_132:
  %t733 = phi i64 [ 0, %table_read_null_130 ], [ %t728, %table_read_real_131 ]
  %t734 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_130 ], [ %t730, %table_read_real_131 ]
  %t735 = phi i32* [ null, %table_read_null_130 ], [ %t732, %table_read_real_131 ]
  %t737 = icmp ult i64 %t723, %t733
  br i1 %t737, label %table_idx_ok_133, label %table_idx_oob_134
table_idx_ok_133:
  %t738 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t734, i64 %t723
  %t739 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t738, i32 0, i32 0
  %t740 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t739, i32 0, i64 0
  %t741 = load i8*, i8** %t740
  call void @star_rc_retain(i8* %t741)
  %t742 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t739, i32 0, i64 1
  %t743 = load i8*, i8** %t742
  call void @star_rc_retain(i8* %t743)
  %t744 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t738
  %t745 = getelementptr inbounds %Bag, %Bag* %t736, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t744, { [2 x i8*], i64, i64 }* %t745
  %t746 = getelementptr inbounds i32, i32* %t735, i64 %t723
  %t747 = load i32, i32* %t746
  %t748 = getelementptr inbounds %Bag, %Bag* %t736, i32 0, i32 1
  store i32 %t747, i32* %t748
  br label %table_idx_end_135
table_idx_oob_134:
  store %Bag zeroinitializer, %Bag* %t736
  br label %table_idx_end_135
table_idx_end_135:
  %t749 = load %Bag, %Bag* %t736
  store %Bag %t749, %Bag* %t750
  %t751 = getelementptr inbounds %Bag, %Bag* %t750, i32 0, i32 0
  %t752 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t751, i32 0, i32 0
  %t753 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t751, i32 0, i32 1
  %t754 = load i64, i64* %t753
  %t755 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t751, i32 0, i32 2
  %t756 = load i64, i64* %t755
  %t757 = sext i32 0 to i64
  %t758 = load i64, i64* %t753
  %t759 = load i64, i64* %t755
  %t760 = icmp ult i64 %t757, %t759
  br i1 %t760, label %ring_rplace_ok_136, label %ring_rplace_oob_137
ring_rplace_ok_136:
  %t761 = add i64 %t758, %t757
  %t762 = urem i64 %t761, 2
  %t763 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t752, i32 0, i64 %t762
  br label %ring_rplace_end_138
ring_rplace_oob_137:
  store i8* null, i8** %t764
  br label %ring_rplace_end_138
ring_rplace_end_138:
  %t765 = phi i8** [ %t763, %ring_rplace_ok_136 ], [ %t764, %ring_rplace_oob_137 ]
  %t766 = load i8*, i8** %t765
  call void @star_rc_release(i8* %t766)
  %t767 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t767, i32 %t687, i32 %t722, i8* %t766)
  %t769 = load i8*, i8** %t205
  %t770 = load i8*, i8** %t205
  call void @star_rc_retain(i8* %t770)
  store i8* %t769, i8** %t768
  %t771 = load i8*, i8** %t205
  %t772 = icmp eq i8* %t771, null
  br i1 %t772, label %table_cow_alloc_139, label %table_cow_check_140
table_cow_alloc_139:
  %t773 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t774 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t775 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t774 to i64
  %t776 = call i8* @star_rc_alloc(i64 %t775, i8* %t773)
  %t777 = bitcast i8* %t776 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t778 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t777, i32 0, i32 0
  store i64 0, i64* %t778
  %t779 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t777, i32 0, i32 1
  store i64 0, i64* %t779
  %t780 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t777, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t780
  %t781 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t777, i32 0, i32 3
  store i32* null, i32** %t781
  store i8* %t776, i8** %t205
  br label %table_cow_done_141
table_cow_check_140:
  %t782 = getelementptr inbounds i8, i8* %t771, i64 -16
  %t783 = bitcast i8* %t782 to i64*
  %t784 = load atomic i64, i64* %t783 seq_cst, align 8
  %t785 = icmp eq i64 %t784, 1
  br i1 %t785, label %table_cow_done_141, label %table_cow_clone_142
table_cow_clone_142:
  %t786 = bitcast i8* %t771 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t787 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t786, i32 0, i32 0
  %t788 = load i64, i64* %t787
  %t789 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t786, i32 0, i32 1
  %t790 = load i64, i64* %t789
  %t791 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t792 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t793 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t792 to i64
  %t794 = call i8* @star_rc_alloc(i64 %t793, i8* %t791)
  %t795 = bitcast i8* %t794 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t796 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t795, i32 0, i32 0
  store i64 %t788, i64* %t796
  %t797 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t795, i32 0, i32 1
  store i64 %t790, i64* %t797
  %t798 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t799 = ptrtoint { [2 x i8*], i64, i64 }* %t798 to i64
  %t800 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t786, i32 0, i32 2
  %t801 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t800
  %t802 = mul i64 %t790, %t799
  %t803 = call i8* @malloc(i64 %t802)
  %t804 = bitcast i8* %t803 to { [2 x i8*], i64, i64 }*
  %t805 = icmp sgt i64 %t788, 0
  br i1 %t805, label %table_cow_copy_143, label %table_cow_after_copy_144
table_cow_copy_143:
  %t806 = mul i64 %t788, %t799
  %t807 = bitcast { [2 x i8*], i64, i64 }* %t801 to i8*
  call i8* @memcpy(i8* %t803, i8* %t807, i64 %t806)
  store i64 0, i64* %t808
  br label %table_cow_retain_cond_145
table_cow_retain_cond_145:
  %t809 = load i64, i64* %t808
  %t810 = icmp slt i64 %t809, %t788
  br i1 %t810, label %table_cow_retain_body_146, label %table_cow_retain_end_147
table_cow_retain_body_146:
  %t811 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t804, i64 %t809
  %t812 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t811, i32 0, i32 0
  %t813 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t812, i32 0, i64 0
  %t814 = load i8*, i8** %t813
  call void @star_rc_retain(i8* %t814)
  %t815 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t812, i32 0, i64 1
  %t816 = load i8*, i8** %t815
  call void @star_rc_retain(i8* %t816)
  %t817 = add i64 %t809, 1
  store i64 %t817, i64* %t808
  br label %table_cow_retain_cond_145
table_cow_retain_end_147:
  br label %table_cow_after_copy_144
table_cow_after_copy_144:
  %t818 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t795, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t804, { [2 x i8*], i64, i64 }** %t818
  %t819 = getelementptr i32, i32* null, i32 1
  %t820 = ptrtoint i32* %t819 to i64
  %t821 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t786, i32 0, i32 3
  %t822 = load i32*, i32** %t821
  %t823 = mul i64 %t790, %t820
  %t824 = call i8* @malloc(i64 %t823)
  %t825 = bitcast i8* %t824 to i32*
  %t826 = icmp sgt i64 %t788, 0
  br i1 %t826, label %table_cow_copy_148, label %table_cow_after_copy_149
table_cow_copy_148:
  %t827 = mul i64 %t788, %t820
  %t828 = bitcast i32* %t822 to i8*
  call i8* @memcpy(i8* %t824, i8* %t828, i64 %t827)
  br label %table_cow_after_copy_149
table_cow_after_copy_149:
  %t829 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t795, i32 0, i32 3
  store i32* %t825, i32** %t829
  call void @star_rc_release(i8* %t771)
  store i8* %t794, i8** %t205
  br label %table_cow_done_141
table_cow_done_141:
  %t830 = load i8*, i8** %t205
  %t831 = bitcast i8* %t830 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t832 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t831, i32 0, i32 0
  %t833 = load i64, i64* %t832
  %t834 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t831, i32 0, i32 1
  %t835 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t831, i32 0, i32 2
  %t836 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t835
  %t837 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t831, i32 0, i32 3
  %t838 = load i32*, i32** %t837
  %t840 = getelementptr inbounds %Bag, %Bag* %t839, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t840
  %t841 = getelementptr inbounds %Bag, %Bag* %t839, i32 0, i32 1
  store i32 3, i32* %t841
  %t842 = load %Bag, %Bag* %t839
  %t843 = load i64, i64* %t834
  %t844 = load i64, i64* %t832
  %t845 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t835
  %t846 = load i32*, i32** %t837
  %t847 = icmp sge i64 %t844, %t843
  br i1 %t847, label %table_push_grow_150, label %table_push_store_151
table_push_grow_150:
  %t848 = mul i64 %t843, 2
  %t849 = icmp sgt i64 %t848, 0
  %t850 = select i1 %t849, i64 %t848, i64 1
  %t851 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t852 = ptrtoint { [2 x i8*], i64, i64 }* %t851 to i64
  %t853 = mul i64 %t850, %t852
  %t854 = call i8* @malloc(i64 %t853)
  %t855 = bitcast i8* %t854 to { [2 x i8*], i64, i64 }*
  %t856 = icmp sgt i64 %t843, 0
  br i1 %t856, label %table_push_copy_152, label %table_push_after_copy_153
table_push_copy_152:
  %t857 = mul i64 %t844, %t852
  %t858 = bitcast { [2 x i8*], i64, i64 }* %t845 to i8*
  call i8* @memcpy(i8* %t854, i8* %t858, i64 %t857)
  call void @free(i8* %t858)
  br label %table_push_after_copy_153
table_push_after_copy_153:
  store { [2 x i8*], i64, i64 }* %t855, { [2 x i8*], i64, i64 }** %t835
  %t859 = getelementptr i32, i32* null, i32 1
  %t860 = ptrtoint i32* %t859 to i64
  %t861 = mul i64 %t850, %t860
  %t862 = call i8* @malloc(i64 %t861)
  %t863 = bitcast i8* %t862 to i32*
  %t864 = icmp sgt i64 %t843, 0
  br i1 %t864, label %table_push_copy_154, label %table_push_after_copy_155
table_push_copy_154:
  %t865 = mul i64 %t844, %t860
  %t866 = bitcast i32* %t846 to i8*
  call i8* @memcpy(i8* %t862, i8* %t866, i64 %t865)
  call void @free(i8* %t866)
  br label %table_push_after_copy_155
table_push_after_copy_155:
  store i32* %t863, i32** %t837
  store i64 %t850, i64* %t834
  br label %table_push_store_151
table_push_store_151:
  %t867 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t835
  %t868 = extractvalue %Bag %t842, 0
  %t869 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t867, i64 %t844
  store { [2 x i8*], i64, i64 } %t868, { [2 x i8*], i64, i64 }* %t869
  %t870 = load i32*, i32** %t837
  %t871 = extractvalue %Bag %t842, 1
  %t872 = getelementptr inbounds i32, i32* %t870, i64 %t844
  store i32 %t871, i32* %t872
  %t873 = add i64 %t844, 1
  store i64 %t873, i64* %t832
  %t874 = load i8*, i8** %t205
  %t875 = icmp eq i8* %t874, null
  br i1 %t875, label %table_read_null_156, label %table_read_real_157
table_read_null_156:
  br label %table_read_end_158
table_read_real_157:
  %t876 = bitcast i8* %t874 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t877 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t876, i32 0, i32 0
  %t878 = load i64, i64* %t877
  %t879 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t876, i32 0, i32 2
  %t880 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t879
  %t881 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t876, i32 0, i32 3
  %t882 = load i32*, i32** %t881
  br label %table_read_end_158
table_read_end_158:
  %t883 = phi i64 [ 0, %table_read_null_156 ], [ %t878, %table_read_real_157 ]
  %t884 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_156 ], [ %t880, %table_read_real_157 ]
  %t885 = phi i32* [ null, %table_read_null_156 ], [ %t882, %table_read_real_157 ]
  %t886 = trunc i64 %t883 to i32
  %t887 = load i8*, i8** %t768
  %t888 = icmp eq i8* %t887, null
  br i1 %t888, label %table_read_null_159, label %table_read_real_160
table_read_null_159:
  br label %table_read_end_161
table_read_real_160:
  %t889 = bitcast i8* %t887 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t890 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t889, i32 0, i32 0
  %t891 = load i64, i64* %t890
  %t892 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t889, i32 0, i32 2
  %t893 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t892
  %t894 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t889, i32 0, i32 3
  %t895 = load i32*, i32** %t894
  br label %table_read_end_161
table_read_end_161:
  %t896 = phi i64 [ 0, %table_read_null_159 ], [ %t891, %table_read_real_160 ]
  %t897 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_159 ], [ %t893, %table_read_real_160 ]
  %t898 = phi i32* [ null, %table_read_null_159 ], [ %t895, %table_read_real_160 ]
  %t899 = trunc i64 %t896 to i32
  %t900 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t900, i32 %t886, i32 %t899)
  %t902 = load i8*, i8** %t205
  %t903 = icmp eq i8* %t902, null
  br i1 %t903, label %table_cow_alloc_162, label %table_cow_check_163
table_cow_alloc_162:
  %t904 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t905 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t906 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t905 to i64
  %t907 = call i8* @star_rc_alloc(i64 %t906, i8* %t904)
  %t908 = bitcast i8* %t907 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t909 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t908, i32 0, i32 0
  store i64 0, i64* %t909
  %t910 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t908, i32 0, i32 1
  store i64 0, i64* %t910
  %t911 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t908, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t911
  %t912 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t908, i32 0, i32 3
  store i32* null, i32** %t912
  store i8* %t907, i8** %t205
  br label %table_cow_done_164
table_cow_check_163:
  %t913 = getelementptr inbounds i8, i8* %t902, i64 -16
  %t914 = bitcast i8* %t913 to i64*
  %t915 = load atomic i64, i64* %t914 seq_cst, align 8
  %t916 = icmp eq i64 %t915, 1
  br i1 %t916, label %table_cow_done_164, label %table_cow_clone_165
table_cow_clone_165:
  %t917 = bitcast i8* %t902 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t918 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t917, i32 0, i32 0
  %t919 = load i64, i64* %t918
  %t920 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t917, i32 0, i32 1
  %t921 = load i64, i64* %t920
  %t922 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t923 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t924 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t923 to i64
  %t925 = call i8* @star_rc_alloc(i64 %t924, i8* %t922)
  %t926 = bitcast i8* %t925 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t927 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t926, i32 0, i32 0
  store i64 %t919, i64* %t927
  %t928 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t926, i32 0, i32 1
  store i64 %t921, i64* %t928
  %t929 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t930 = ptrtoint { [2 x i8*], i64, i64 }* %t929 to i64
  %t931 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t917, i32 0, i32 2
  %t932 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t931
  %t933 = mul i64 %t921, %t930
  %t934 = call i8* @malloc(i64 %t933)
  %t935 = bitcast i8* %t934 to { [2 x i8*], i64, i64 }*
  %t936 = icmp sgt i64 %t919, 0
  br i1 %t936, label %table_cow_copy_166, label %table_cow_after_copy_167
table_cow_copy_166:
  %t937 = mul i64 %t919, %t930
  %t938 = bitcast { [2 x i8*], i64, i64 }* %t932 to i8*
  call i8* @memcpy(i8* %t934, i8* %t938, i64 %t937)
  store i64 0, i64* %t939
  br label %table_cow_retain_cond_168
table_cow_retain_cond_168:
  %t940 = load i64, i64* %t939
  %t941 = icmp slt i64 %t940, %t919
  br i1 %t941, label %table_cow_retain_body_169, label %table_cow_retain_end_170
table_cow_retain_body_169:
  %t942 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t935, i64 %t940
  %t943 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t942, i32 0, i32 0
  %t944 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t943, i32 0, i64 0
  %t945 = load i8*, i8** %t944
  call void @star_rc_retain(i8* %t945)
  %t946 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t943, i32 0, i64 1
  %t947 = load i8*, i8** %t946
  call void @star_rc_retain(i8* %t947)
  %t948 = add i64 %t940, 1
  store i64 %t948, i64* %t939
  br label %table_cow_retain_cond_168
table_cow_retain_end_170:
  br label %table_cow_after_copy_167
table_cow_after_copy_167:
  %t949 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t926, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t935, { [2 x i8*], i64, i64 }** %t949
  %t950 = getelementptr i32, i32* null, i32 1
  %t951 = ptrtoint i32* %t950 to i64
  %t952 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t917, i32 0, i32 3
  %t953 = load i32*, i32** %t952
  %t954 = mul i64 %t921, %t951
  %t955 = call i8* @malloc(i64 %t954)
  %t956 = bitcast i8* %t955 to i32*
  %t957 = icmp sgt i64 %t919, 0
  br i1 %t957, label %table_cow_copy_171, label %table_cow_after_copy_172
table_cow_copy_171:
  %t958 = mul i64 %t919, %t951
  %t959 = bitcast i32* %t953 to i8*
  call i8* @memcpy(i8* %t955, i8* %t959, i64 %t958)
  br label %table_cow_after_copy_172
table_cow_after_copy_172:
  %t960 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t926, i32 0, i32 3
  store i32* %t956, i32** %t960
  call void @star_rc_release(i8* %t902)
  store i8* %t925, i8** %t205
  br label %table_cow_done_164
table_cow_done_164:
  %t961 = load i8*, i8** %t205
  %t962 = bitcast i8* %t961 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t963 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t962, i32 0, i32 0
  %t964 = load i64, i64* %t963
  %t965 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t962, i32 0, i32 1
  %t966 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t962, i32 0, i32 2
  %t967 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t966
  %t968 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t962, i32 0, i32 3
  %t969 = load i32*, i32** %t968
  %t971 = icmp eq i64 %t964, 0
  br i1 %t971, label %table_pop_empty_173, label %table_pop_nonempty_174
table_pop_nonempty_174:
  %t972 = sub i64 %t964, 1
  store i64 %t972, i64* %t963
  %t973 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t967, i64 %t972
  %t974 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t973
  %t975 = getelementptr inbounds %Bag, %Bag* %t970, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t974, { [2 x i8*], i64, i64 }* %t975
  %t976 = getelementptr inbounds i32, i32* %t969, i64 %t972
  %t977 = load i32, i32* %t976
  %t978 = getelementptr inbounds %Bag, %Bag* %t970, i32 0, i32 1
  store i32 %t977, i32* %t978
  br label %table_pop_end_175
table_pop_empty_173:
  store %Bag zeroinitializer, %Bag* %t970
  br label %table_pop_end_175
table_pop_end_175:
  %t979 = load %Bag, %Bag* %t970
  store %Bag %t979, %Bag* %t901
  %t980 = getelementptr inbounds %Bag, %Bag* %t901, i32 0, i32 1
  %t981 = load i32, i32* %t980
  %t982 = getelementptr inbounds %Bag, %Bag* %t901, i32 0, i32 0
  %t983 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t982, i32 0, i32 0
  %t984 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t982, i32 0, i32 1
  %t985 = load i64, i64* %t984
  %t986 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t982, i32 0, i32 2
  %t987 = load i64, i64* %t986
  %t988 = trunc i64 %t987 to i32
  %t989 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t989, i32 %t981, i32 %t988)
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t990
  store i8* null, i8** %t991
  %t992 = load i8*, i8** %t991
  %t993 = icmp eq i8* %t992, null
  br i1 %t993, label %table_cow_alloc_176, label %table_cow_check_177
table_cow_alloc_176:
  %t1000 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1001 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1002 = ptrtoint { i64, i64, i32* }* %t1001 to i64
  %t1003 = call i8* @star_rc_alloc(i64 %t1002, i8* %t1000)
  %t1004 = bitcast i8* %t1003 to { i64, i64, i32* }*
  %t1005 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1004, i32 0, i32 0
  store i64 0, i64* %t1005
  %t1006 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1004, i32 0, i32 1
  store i64 0, i64* %t1006
  %t1007 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1004, i32 0, i32 2
  store i32* null, i32** %t1007
  store i8* %t1003, i8** %t991
  br label %table_cow_done_178
table_cow_check_177:
  %t1008 = getelementptr inbounds i8, i8* %t992, i64 -16
  %t1009 = bitcast i8* %t1008 to i64*
  %t1010 = load atomic i64, i64* %t1009 seq_cst, align 8
  %t1011 = icmp eq i64 %t1010, 1
  br i1 %t1011, label %table_cow_done_178, label %table_cow_clone_179
table_cow_clone_179:
  %t1012 = bitcast i8* %t992 to { i64, i64, i32* }*
  %t1013 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1012, i32 0, i32 0
  %t1014 = load i64, i64* %t1013
  %t1015 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1012, i32 0, i32 1
  %t1016 = load i64, i64* %t1015
  %t1017 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1018 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1019 = ptrtoint { i64, i64, i32* }* %t1018 to i64
  %t1020 = call i8* @star_rc_alloc(i64 %t1019, i8* %t1017)
  %t1021 = bitcast i8* %t1020 to { i64, i64, i32* }*
  %t1022 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1021, i32 0, i32 0
  store i64 %t1014, i64* %t1022
  %t1023 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1021, i32 0, i32 1
  store i64 %t1016, i64* %t1023
  %t1024 = getelementptr i32, i32* null, i32 1
  %t1025 = ptrtoint i32* %t1024 to i64
  %t1026 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1012, i32 0, i32 2
  %t1027 = load i32*, i32** %t1026
  %t1028 = mul i64 %t1016, %t1025
  %t1029 = call i8* @malloc(i64 %t1028)
  %t1030 = bitcast i8* %t1029 to i32*
  %t1031 = icmp sgt i64 %t1014, 0
  br i1 %t1031, label %table_cow_copy_180, label %table_cow_after_copy_181
table_cow_copy_180:
  %t1032 = mul i64 %t1014, %t1025
  %t1033 = bitcast i32* %t1027 to i8*
  call i8* @memcpy(i8* %t1029, i8* %t1033, i64 %t1032)
  br label %table_cow_after_copy_181
table_cow_after_copy_181:
  %t1034 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1021, i32 0, i32 2
  store i32* %t1030, i32** %t1034
  call void @star_rc_release(i8* %t992)
  store i8* %t1020, i8** %t991
  br label %table_cow_done_178
table_cow_done_178:
  %t1035 = load i8*, i8** %t991
  %t1036 = bitcast i8* %t1035 to { i64, i64, i32* }*
  %t1037 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1036, i32 0, i32 0
  %t1038 = load i64, i64* %t1037
  %t1039 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1036, i32 0, i32 1
  %t1040 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1036, i32 0, i32 2
  %t1041 = load i32*, i32** %t1040
  %t1043 = getelementptr inbounds %Item, %Item* %t1042, i32 0, i32 0
  store i32 1, i32* %t1043
  %t1044 = load %Item, %Item* %t1042
  %t1045 = load i64, i64* %t1039
  %t1046 = load i64, i64* %t1037
  %t1047 = load i32*, i32** %t1040
  %t1048 = icmp sge i64 %t1046, %t1045
  br i1 %t1048, label %table_push_grow_182, label %table_push_store_183
table_push_grow_182:
  %t1049 = mul i64 %t1045, 2
  %t1050 = icmp sgt i64 %t1049, 0
  %t1051 = select i1 %t1050, i64 %t1049, i64 1
  %t1052 = getelementptr i32, i32* null, i32 1
  %t1053 = ptrtoint i32* %t1052 to i64
  %t1054 = mul i64 %t1051, %t1053
  %t1055 = call i8* @malloc(i64 %t1054)
  %t1056 = bitcast i8* %t1055 to i32*
  %t1057 = icmp sgt i64 %t1045, 0
  br i1 %t1057, label %table_push_copy_184, label %table_push_after_copy_185
table_push_copy_184:
  %t1058 = mul i64 %t1046, %t1053
  %t1059 = bitcast i32* %t1047 to i8*
  call i8* @memcpy(i8* %t1055, i8* %t1059, i64 %t1058)
  call void @free(i8* %t1059)
  br label %table_push_after_copy_185
table_push_after_copy_185:
  store i32* %t1056, i32** %t1040
  store i64 %t1051, i64* %t1039
  br label %table_push_store_183
table_push_store_183:
  %t1060 = load i32*, i32** %t1040
  %t1061 = extractvalue %Item %t1044, 0
  %t1062 = getelementptr inbounds i32, i32* %t1060, i64 %t1046
  store i32 %t1061, i32* %t1062
  %t1063 = add i64 %t1046, 1
  store i64 %t1063, i64* %t1037
  %t1064 = load i8*, i8** %t991
  %t1065 = load i8*, i8** %t991
  call void @star_rc_retain(i8* %t1065)
  %t1066 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1067 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1068 = load i64, i64* %t1067
  %t1069 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1070 = load i64, i64* %t1069
  %t1071 = icmp sge i64 %t1070, 2
  br i1 %t1071, label %ring_push_full_186, label %ring_push_grow_187
ring_push_grow_187:
  %t1072 = add i64 %t1068, %t1070
  %t1073 = urem i64 %t1072, 2
  %t1074 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1066, i32 0, i64 %t1073
  store i8* %t1064, i8** %t1074
  %t1075 = add i64 %t1070, 1
  store i64 %t1075, i64* %t1069
  br label %ring_push_done_188
ring_push_full_186:
  %t1076 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1066, i32 0, i64 %t1068
  %t1077 = load i8*, i8** %t1076
  call void @star_rc_release(i8* %t1077)
  store i8* %t1064, i8** %t1076
  %t1078 = add i64 %t1068, 1
  %t1079 = urem i64 %t1078, 2
  store i64 %t1079, i64* %t1067
  br label %ring_push_done_188
ring_push_done_188:
  store i8* null, i8** %t1080
  %t1081 = load i8*, i8** %t1080
  %t1082 = icmp eq i8* %t1081, null
  br i1 %t1082, label %table_cow_alloc_189, label %table_cow_check_190
table_cow_alloc_189:
  %t1083 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1084 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1085 = ptrtoint { i64, i64, i32* }* %t1084 to i64
  %t1086 = call i8* @star_rc_alloc(i64 %t1085, i8* %t1083)
  %t1087 = bitcast i8* %t1086 to { i64, i64, i32* }*
  %t1088 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1087, i32 0, i32 0
  store i64 0, i64* %t1088
  %t1089 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1087, i32 0, i32 1
  store i64 0, i64* %t1089
  %t1090 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1087, i32 0, i32 2
  store i32* null, i32** %t1090
  store i8* %t1086, i8** %t1080
  br label %table_cow_done_191
table_cow_check_190:
  %t1091 = getelementptr inbounds i8, i8* %t1081, i64 -16
  %t1092 = bitcast i8* %t1091 to i64*
  %t1093 = load atomic i64, i64* %t1092 seq_cst, align 8
  %t1094 = icmp eq i64 %t1093, 1
  br i1 %t1094, label %table_cow_done_191, label %table_cow_clone_192
table_cow_clone_192:
  %t1095 = bitcast i8* %t1081 to { i64, i64, i32* }*
  %t1096 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1095, i32 0, i32 0
  %t1097 = load i64, i64* %t1096
  %t1098 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1095, i32 0, i32 1
  %t1099 = load i64, i64* %t1098
  %t1100 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1101 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1102 = ptrtoint { i64, i64, i32* }* %t1101 to i64
  %t1103 = call i8* @star_rc_alloc(i64 %t1102, i8* %t1100)
  %t1104 = bitcast i8* %t1103 to { i64, i64, i32* }*
  %t1105 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1104, i32 0, i32 0
  store i64 %t1097, i64* %t1105
  %t1106 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1104, i32 0, i32 1
  store i64 %t1099, i64* %t1106
  %t1107 = getelementptr i32, i32* null, i32 1
  %t1108 = ptrtoint i32* %t1107 to i64
  %t1109 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1095, i32 0, i32 2
  %t1110 = load i32*, i32** %t1109
  %t1111 = mul i64 %t1099, %t1108
  %t1112 = call i8* @malloc(i64 %t1111)
  %t1113 = bitcast i8* %t1112 to i32*
  %t1114 = icmp sgt i64 %t1097, 0
  br i1 %t1114, label %table_cow_copy_193, label %table_cow_after_copy_194
table_cow_copy_193:
  %t1115 = mul i64 %t1097, %t1108
  %t1116 = bitcast i32* %t1110 to i8*
  call i8* @memcpy(i8* %t1112, i8* %t1116, i64 %t1115)
  br label %table_cow_after_copy_194
table_cow_after_copy_194:
  %t1117 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1104, i32 0, i32 2
  store i32* %t1113, i32** %t1117
  call void @star_rc_release(i8* %t1081)
  store i8* %t1103, i8** %t1080
  br label %table_cow_done_191
table_cow_done_191:
  %t1118 = load i8*, i8** %t1080
  %t1119 = bitcast i8* %t1118 to { i64, i64, i32* }*
  %t1120 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1119, i32 0, i32 0
  %t1121 = load i64, i64* %t1120
  %t1122 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1119, i32 0, i32 1
  %t1123 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1119, i32 0, i32 2
  %t1124 = load i32*, i32** %t1123
  %t1126 = getelementptr inbounds %Item, %Item* %t1125, i32 0, i32 0
  store i32 2, i32* %t1126
  %t1127 = load %Item, %Item* %t1125
  %t1128 = load i64, i64* %t1122
  %t1129 = load i64, i64* %t1120
  %t1130 = load i32*, i32** %t1123
  %t1131 = icmp sge i64 %t1129, %t1128
  br i1 %t1131, label %table_push_grow_195, label %table_push_store_196
table_push_grow_195:
  %t1132 = mul i64 %t1128, 2
  %t1133 = icmp sgt i64 %t1132, 0
  %t1134 = select i1 %t1133, i64 %t1132, i64 1
  %t1135 = getelementptr i32, i32* null, i32 1
  %t1136 = ptrtoint i32* %t1135 to i64
  %t1137 = mul i64 %t1134, %t1136
  %t1138 = call i8* @malloc(i64 %t1137)
  %t1139 = bitcast i8* %t1138 to i32*
  %t1140 = icmp sgt i64 %t1128, 0
  br i1 %t1140, label %table_push_copy_197, label %table_push_after_copy_198
table_push_copy_197:
  %t1141 = mul i64 %t1129, %t1136
  %t1142 = bitcast i32* %t1130 to i8*
  call i8* @memcpy(i8* %t1138, i8* %t1142, i64 %t1141)
  call void @free(i8* %t1142)
  br label %table_push_after_copy_198
table_push_after_copy_198:
  store i32* %t1139, i32** %t1123
  store i64 %t1134, i64* %t1122
  br label %table_push_store_196
table_push_store_196:
  %t1143 = load i32*, i32** %t1123
  %t1144 = extractvalue %Item %t1127, 0
  %t1145 = getelementptr inbounds i32, i32* %t1143, i64 %t1129
  store i32 %t1144, i32* %t1145
  %t1146 = add i64 %t1129, 1
  store i64 %t1146, i64* %t1120
  %t1147 = load i8*, i8** %t1080
  %t1148 = icmp eq i8* %t1147, null
  br i1 %t1148, label %table_cow_alloc_199, label %table_cow_check_200
table_cow_alloc_199:
  %t1149 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1150 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1151 = ptrtoint { i64, i64, i32* }* %t1150 to i64
  %t1152 = call i8* @star_rc_alloc(i64 %t1151, i8* %t1149)
  %t1153 = bitcast i8* %t1152 to { i64, i64, i32* }*
  %t1154 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1153, i32 0, i32 0
  store i64 0, i64* %t1154
  %t1155 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1153, i32 0, i32 1
  store i64 0, i64* %t1155
  %t1156 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1153, i32 0, i32 2
  store i32* null, i32** %t1156
  store i8* %t1152, i8** %t1080
  br label %table_cow_done_201
table_cow_check_200:
  %t1157 = getelementptr inbounds i8, i8* %t1147, i64 -16
  %t1158 = bitcast i8* %t1157 to i64*
  %t1159 = load atomic i64, i64* %t1158 seq_cst, align 8
  %t1160 = icmp eq i64 %t1159, 1
  br i1 %t1160, label %table_cow_done_201, label %table_cow_clone_202
table_cow_clone_202:
  %t1161 = bitcast i8* %t1147 to { i64, i64, i32* }*
  %t1162 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1161, i32 0, i32 0
  %t1163 = load i64, i64* %t1162
  %t1164 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1161, i32 0, i32 1
  %t1165 = load i64, i64* %t1164
  %t1166 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1167 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1168 = ptrtoint { i64, i64, i32* }* %t1167 to i64
  %t1169 = call i8* @star_rc_alloc(i64 %t1168, i8* %t1166)
  %t1170 = bitcast i8* %t1169 to { i64, i64, i32* }*
  %t1171 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1170, i32 0, i32 0
  store i64 %t1163, i64* %t1171
  %t1172 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1170, i32 0, i32 1
  store i64 %t1165, i64* %t1172
  %t1173 = getelementptr i32, i32* null, i32 1
  %t1174 = ptrtoint i32* %t1173 to i64
  %t1175 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1161, i32 0, i32 2
  %t1176 = load i32*, i32** %t1175
  %t1177 = mul i64 %t1165, %t1174
  %t1178 = call i8* @malloc(i64 %t1177)
  %t1179 = bitcast i8* %t1178 to i32*
  %t1180 = icmp sgt i64 %t1163, 0
  br i1 %t1180, label %table_cow_copy_203, label %table_cow_after_copy_204
table_cow_copy_203:
  %t1181 = mul i64 %t1163, %t1174
  %t1182 = bitcast i32* %t1176 to i8*
  call i8* @memcpy(i8* %t1178, i8* %t1182, i64 %t1181)
  br label %table_cow_after_copy_204
table_cow_after_copy_204:
  %t1183 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1170, i32 0, i32 2
  store i32* %t1179, i32** %t1183
  call void @star_rc_release(i8* %t1147)
  store i8* %t1169, i8** %t1080
  br label %table_cow_done_201
table_cow_done_201:
  %t1184 = load i8*, i8** %t1080
  %t1185 = bitcast i8* %t1184 to { i64, i64, i32* }*
  %t1186 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1185, i32 0, i32 0
  %t1187 = load i64, i64* %t1186
  %t1188 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1185, i32 0, i32 1
  %t1189 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1185, i32 0, i32 2
  %t1190 = load i32*, i32** %t1189
  %t1192 = getelementptr inbounds %Item, %Item* %t1191, i32 0, i32 0
  store i32 3, i32* %t1192
  %t1193 = load %Item, %Item* %t1191
  %t1194 = load i64, i64* %t1188
  %t1195 = load i64, i64* %t1186
  %t1196 = load i32*, i32** %t1189
  %t1197 = icmp sge i64 %t1195, %t1194
  br i1 %t1197, label %table_push_grow_205, label %table_push_store_206
table_push_grow_205:
  %t1198 = mul i64 %t1194, 2
  %t1199 = icmp sgt i64 %t1198, 0
  %t1200 = select i1 %t1199, i64 %t1198, i64 1
  %t1201 = getelementptr i32, i32* null, i32 1
  %t1202 = ptrtoint i32* %t1201 to i64
  %t1203 = mul i64 %t1200, %t1202
  %t1204 = call i8* @malloc(i64 %t1203)
  %t1205 = bitcast i8* %t1204 to i32*
  %t1206 = icmp sgt i64 %t1194, 0
  br i1 %t1206, label %table_push_copy_207, label %table_push_after_copy_208
table_push_copy_207:
  %t1207 = mul i64 %t1195, %t1202
  %t1208 = bitcast i32* %t1196 to i8*
  call i8* @memcpy(i8* %t1204, i8* %t1208, i64 %t1207)
  call void @free(i8* %t1208)
  br label %table_push_after_copy_208
table_push_after_copy_208:
  store i32* %t1205, i32** %t1189
  store i64 %t1200, i64* %t1188
  br label %table_push_store_206
table_push_store_206:
  %t1209 = load i32*, i32** %t1189
  %t1210 = extractvalue %Item %t1193, 0
  %t1211 = getelementptr inbounds i32, i32* %t1209, i64 %t1195
  store i32 %t1210, i32* %t1211
  %t1212 = add i64 %t1195, 1
  store i64 %t1212, i64* %t1186
  %t1213 = load i8*, i8** %t1080
  %t1214 = load i8*, i8** %t1080
  call void @star_rc_retain(i8* %t1214)
  %t1215 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1216 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1217 = load i64, i64* %t1216
  %t1218 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1219 = load i64, i64* %t1218
  %t1220 = icmp sge i64 %t1219, 2
  br i1 %t1220, label %ring_push_full_209, label %ring_push_grow_210
ring_push_grow_210:
  %t1221 = add i64 %t1217, %t1219
  %t1222 = urem i64 %t1221, 2
  %t1223 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1215, i32 0, i64 %t1222
  store i8* %t1213, i8** %t1223
  %t1224 = add i64 %t1219, 1
  store i64 %t1224, i64* %t1218
  br label %ring_push_done_211
ring_push_full_209:
  %t1225 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1215, i32 0, i64 %t1217
  %t1226 = load i8*, i8** %t1225
  call void @star_rc_release(i8* %t1226)
  store i8* %t1213, i8** %t1225
  %t1227 = add i64 %t1217, 1
  %t1228 = urem i64 %t1227, 2
  store i64 %t1228, i64* %t1216
  br label %ring_push_done_211
ring_push_done_211:
  %t1229 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1230 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1231 = load i64, i64* %t1230
  %t1232 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1233 = load i64, i64* %t1232
  %t1234 = trunc i64 %t1233 to i32
  %t1235 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1236 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1237 = load i64, i64* %t1236
  %t1238 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1239 = load i64, i64* %t1238
  %t1240 = sext i32 0 to i64
  %t1241 = load i64, i64* %t1236
  %t1242 = load i64, i64* %t1238
  %t1243 = icmp ult i64 %t1240, %t1242
  br i1 %t1243, label %ring_rplace_ok_212, label %ring_rplace_oob_213
ring_rplace_ok_212:
  %t1244 = add i64 %t1241, %t1240
  %t1245 = urem i64 %t1244, 2
  %t1246 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1235, i32 0, i64 %t1245
  br label %ring_rplace_end_214
ring_rplace_oob_213:
  store i8* null, i8** %t1247
  br label %ring_rplace_end_214
ring_rplace_end_214:
  %t1248 = phi i8** [ %t1246, %ring_rplace_ok_212 ], [ %t1247, %ring_rplace_oob_213 ]
  %t1249 = load i8*, i8** %t1248
  %t1250 = icmp eq i8* %t1249, null
  br i1 %t1250, label %table_read_null_215, label %table_read_real_216
table_read_null_215:
  br label %table_read_end_217
table_read_real_216:
  %t1251 = bitcast i8* %t1249 to { i64, i64, i32* }*
  %t1252 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1251, i32 0, i32 0
  %t1253 = load i64, i64* %t1252
  %t1254 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1251, i32 0, i32 2
  %t1255 = load i32*, i32** %t1254
  br label %table_read_end_217
table_read_end_217:
  %t1256 = phi i64 [ 0, %table_read_null_215 ], [ %t1253, %table_read_real_216 ]
  %t1257 = phi i32* [ null, %table_read_null_215 ], [ %t1255, %table_read_real_216 ]
  %t1258 = trunc i64 %t1256 to i32
  %t1259 = sext i32 0 to i64
  %t1260 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1261 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1262 = load i64, i64* %t1261
  %t1263 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1264 = load i64, i64* %t1263
  %t1265 = sext i32 0 to i64
  %t1266 = load i64, i64* %t1261
  %t1267 = load i64, i64* %t1263
  %t1268 = icmp ult i64 %t1265, %t1267
  br i1 %t1268, label %ring_rplace_ok_218, label %ring_rplace_oob_219
ring_rplace_ok_218:
  %t1269 = add i64 %t1266, %t1265
  %t1270 = urem i64 %t1269, 2
  %t1271 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1260, i32 0, i64 %t1270
  br label %ring_rplace_end_220
ring_rplace_oob_219:
  store i8* null, i8** %t1272
  br label %ring_rplace_end_220
ring_rplace_end_220:
  %t1273 = phi i8** [ %t1271, %ring_rplace_ok_218 ], [ %t1272, %ring_rplace_oob_219 ]
  %t1274 = load i8*, i8** %t1273
  %t1275 = icmp eq i8* %t1274, null
  br i1 %t1275, label %table_read_null_221, label %table_read_real_222
table_read_null_221:
  br label %table_read_end_223
table_read_real_222:
  %t1276 = bitcast i8* %t1274 to { i64, i64, i32* }*
  %t1277 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1276, i32 0, i32 0
  %t1278 = load i64, i64* %t1277
  %t1279 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1276, i32 0, i32 2
  %t1280 = load i32*, i32** %t1279
  br label %table_read_end_223
table_read_end_223:
  %t1281 = phi i64 [ 0, %table_read_null_221 ], [ %t1278, %table_read_real_222 ]
  %t1282 = phi i32* [ null, %table_read_null_221 ], [ %t1280, %table_read_real_222 ]
  %t1284 = icmp ult i64 %t1259, %t1281
  br i1 %t1284, label %table_idx_ok_224, label %table_idx_oob_225
table_idx_ok_224:
  %t1285 = getelementptr inbounds i32, i32* %t1282, i64 %t1259
  %t1286 = load i32, i32* %t1285
  %t1287 = getelementptr inbounds %Item, %Item* %t1283, i32 0, i32 0
  store i32 %t1286, i32* %t1287
  br label %table_idx_end_226
table_idx_oob_225:
  store %Item zeroinitializer, %Item* %t1283
  br label %table_idx_end_226
table_idx_end_226:
  %t1288 = load %Item, %Item* %t1283
  store %Item %t1288, %Item* %t1289
  %t1290 = getelementptr inbounds %Item, %Item* %t1289, i32 0, i32 0
  %t1291 = load i32, i32* %t1290
  %t1292 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1292, i32 %t1234, i32 %t1258, i32 %t1291)
  %t1293 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1294 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1295 = load i64, i64* %t1294
  %t1296 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1297 = load i64, i64* %t1296
  %t1298 = sext i32 1 to i64
  %t1299 = load i64, i64* %t1294
  %t1300 = load i64, i64* %t1296
  %t1301 = icmp ult i64 %t1298, %t1300
  br i1 %t1301, label %ring_rplace_ok_227, label %ring_rplace_oob_228
ring_rplace_ok_227:
  %t1302 = add i64 %t1299, %t1298
  %t1303 = urem i64 %t1302, 2
  %t1304 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1293, i32 0, i64 %t1303
  br label %ring_rplace_end_229
ring_rplace_oob_228:
  store i8* null, i8** %t1305
  br label %ring_rplace_end_229
ring_rplace_end_229:
  %t1306 = phi i8** [ %t1304, %ring_rplace_ok_227 ], [ %t1305, %ring_rplace_oob_228 ]
  %t1307 = load i8*, i8** %t1306
  %t1308 = icmp eq i8* %t1307, null
  br i1 %t1308, label %table_read_null_230, label %table_read_real_231
table_read_null_230:
  br label %table_read_end_232
table_read_real_231:
  %t1309 = bitcast i8* %t1307 to { i64, i64, i32* }*
  %t1310 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1309, i32 0, i32 0
  %t1311 = load i64, i64* %t1310
  %t1312 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1309, i32 0, i32 2
  %t1313 = load i32*, i32** %t1312
  br label %table_read_end_232
table_read_end_232:
  %t1314 = phi i64 [ 0, %table_read_null_230 ], [ %t1311, %table_read_real_231 ]
  %t1315 = phi i32* [ null, %table_read_null_230 ], [ %t1313, %table_read_real_231 ]
  %t1316 = trunc i64 %t1314 to i32
  %t1317 = sext i32 0 to i64
  %t1318 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1319 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1320 = load i64, i64* %t1319
  %t1321 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1322 = load i64, i64* %t1321
  %t1323 = sext i32 1 to i64
  %t1324 = load i64, i64* %t1319
  %t1325 = load i64, i64* %t1321
  %t1326 = icmp ult i64 %t1323, %t1325
  br i1 %t1326, label %ring_rplace_ok_233, label %ring_rplace_oob_234
ring_rplace_ok_233:
  %t1327 = add i64 %t1324, %t1323
  %t1328 = urem i64 %t1327, 2
  %t1329 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1318, i32 0, i64 %t1328
  br label %ring_rplace_end_235
ring_rplace_oob_234:
  store i8* null, i8** %t1330
  br label %ring_rplace_end_235
ring_rplace_end_235:
  %t1331 = phi i8** [ %t1329, %ring_rplace_ok_233 ], [ %t1330, %ring_rplace_oob_234 ]
  %t1332 = load i8*, i8** %t1331
  %t1333 = icmp eq i8* %t1332, null
  br i1 %t1333, label %table_read_null_236, label %table_read_real_237
table_read_null_236:
  br label %table_read_end_238
table_read_real_237:
  %t1334 = bitcast i8* %t1332 to { i64, i64, i32* }*
  %t1335 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1334, i32 0, i32 0
  %t1336 = load i64, i64* %t1335
  %t1337 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1334, i32 0, i32 2
  %t1338 = load i32*, i32** %t1337
  br label %table_read_end_238
table_read_end_238:
  %t1339 = phi i64 [ 0, %table_read_null_236 ], [ %t1336, %table_read_real_237 ]
  %t1340 = phi i32* [ null, %table_read_null_236 ], [ %t1338, %table_read_real_237 ]
  %t1342 = icmp ult i64 %t1317, %t1339
  br i1 %t1342, label %table_idx_ok_239, label %table_idx_oob_240
table_idx_ok_239:
  %t1343 = getelementptr inbounds i32, i32* %t1340, i64 %t1317
  %t1344 = load i32, i32* %t1343
  %t1345 = getelementptr inbounds %Item, %Item* %t1341, i32 0, i32 0
  store i32 %t1344, i32* %t1345
  br label %table_idx_end_241
table_idx_oob_240:
  store %Item zeroinitializer, %Item* %t1341
  br label %table_idx_end_241
table_idx_end_241:
  %t1346 = load %Item, %Item* %t1341
  store %Item %t1346, %Item* %t1347
  %t1348 = getelementptr inbounds %Item, %Item* %t1347, i32 0, i32 0
  %t1349 = load i32, i32* %t1348
  %t1350 = sext i32 1 to i64
  %t1351 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1352 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1353 = load i64, i64* %t1352
  %t1354 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1355 = load i64, i64* %t1354
  %t1356 = sext i32 1 to i64
  %t1357 = load i64, i64* %t1352
  %t1358 = load i64, i64* %t1354
  %t1359 = icmp ult i64 %t1356, %t1358
  br i1 %t1359, label %ring_rplace_ok_242, label %ring_rplace_oob_243
ring_rplace_ok_242:
  %t1360 = add i64 %t1357, %t1356
  %t1361 = urem i64 %t1360, 2
  %t1362 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1351, i32 0, i64 %t1361
  br label %ring_rplace_end_244
ring_rplace_oob_243:
  store i8* null, i8** %t1363
  br label %ring_rplace_end_244
ring_rplace_end_244:
  %t1364 = phi i8** [ %t1362, %ring_rplace_ok_242 ], [ %t1363, %ring_rplace_oob_243 ]
  %t1365 = load i8*, i8** %t1364
  %t1366 = icmp eq i8* %t1365, null
  br i1 %t1366, label %table_read_null_245, label %table_read_real_246
table_read_null_245:
  br label %table_read_end_247
table_read_real_246:
  %t1367 = bitcast i8* %t1365 to { i64, i64, i32* }*
  %t1368 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1367, i32 0, i32 0
  %t1369 = load i64, i64* %t1368
  %t1370 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1367, i32 0, i32 2
  %t1371 = load i32*, i32** %t1370
  br label %table_read_end_247
table_read_end_247:
  %t1372 = phi i64 [ 0, %table_read_null_245 ], [ %t1369, %table_read_real_246 ]
  %t1373 = phi i32* [ null, %table_read_null_245 ], [ %t1371, %table_read_real_246 ]
  %t1375 = icmp ult i64 %t1350, %t1372
  br i1 %t1375, label %table_idx_ok_248, label %table_idx_oob_249
table_idx_ok_248:
  %t1376 = getelementptr inbounds i32, i32* %t1373, i64 %t1350
  %t1377 = load i32, i32* %t1376
  %t1378 = getelementptr inbounds %Item, %Item* %t1374, i32 0, i32 0
  store i32 %t1377, i32* %t1378
  br label %table_idx_end_250
table_idx_oob_249:
  store %Item zeroinitializer, %Item* %t1374
  br label %table_idx_end_250
table_idx_end_250:
  %t1379 = load %Item, %Item* %t1374
  store %Item %t1379, %Item* %t1380
  %t1381 = getelementptr inbounds %Item, %Item* %t1380, i32 0, i32 0
  %t1382 = load i32, i32* %t1381
  %t1383 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1383, i32 %t1316, i32 %t1349, i32 %t1382)
  store i8* null, i8** %t1384
  %t1385 = load i8*, i8** %t1384
  %t1386 = icmp eq i8* %t1385, null
  br i1 %t1386, label %table_cow_alloc_251, label %table_cow_check_252
table_cow_alloc_251:
  %t1387 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1388 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1389 = ptrtoint { i64, i64, i32* }* %t1388 to i64
  %t1390 = call i8* @star_rc_alloc(i64 %t1389, i8* %t1387)
  %t1391 = bitcast i8* %t1390 to { i64, i64, i32* }*
  %t1392 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1391, i32 0, i32 0
  store i64 0, i64* %t1392
  %t1393 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1391, i32 0, i32 1
  store i64 0, i64* %t1393
  %t1394 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1391, i32 0, i32 2
  store i32* null, i32** %t1394
  store i8* %t1390, i8** %t1384
  br label %table_cow_done_253
table_cow_check_252:
  %t1395 = getelementptr inbounds i8, i8* %t1385, i64 -16
  %t1396 = bitcast i8* %t1395 to i64*
  %t1397 = load atomic i64, i64* %t1396 seq_cst, align 8
  %t1398 = icmp eq i64 %t1397, 1
  br i1 %t1398, label %table_cow_done_253, label %table_cow_clone_254
table_cow_clone_254:
  %t1399 = bitcast i8* %t1385 to { i64, i64, i32* }*
  %t1400 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1399, i32 0, i32 0
  %t1401 = load i64, i64* %t1400
  %t1402 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1399, i32 0, i32 1
  %t1403 = load i64, i64* %t1402
  %t1404 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1405 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1406 = ptrtoint { i64, i64, i32* }* %t1405 to i64
  %t1407 = call i8* @star_rc_alloc(i64 %t1406, i8* %t1404)
  %t1408 = bitcast i8* %t1407 to { i64, i64, i32* }*
  %t1409 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1408, i32 0, i32 0
  store i64 %t1401, i64* %t1409
  %t1410 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1408, i32 0, i32 1
  store i64 %t1403, i64* %t1410
  %t1411 = getelementptr i32, i32* null, i32 1
  %t1412 = ptrtoint i32* %t1411 to i64
  %t1413 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1399, i32 0, i32 2
  %t1414 = load i32*, i32** %t1413
  %t1415 = mul i64 %t1403, %t1412
  %t1416 = call i8* @malloc(i64 %t1415)
  %t1417 = bitcast i8* %t1416 to i32*
  %t1418 = icmp sgt i64 %t1401, 0
  br i1 %t1418, label %table_cow_copy_255, label %table_cow_after_copy_256
table_cow_copy_255:
  %t1419 = mul i64 %t1401, %t1412
  %t1420 = bitcast i32* %t1414 to i8*
  call i8* @memcpy(i8* %t1416, i8* %t1420, i64 %t1419)
  br label %table_cow_after_copy_256
table_cow_after_copy_256:
  %t1421 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1408, i32 0, i32 2
  store i32* %t1417, i32** %t1421
  call void @star_rc_release(i8* %t1385)
  store i8* %t1407, i8** %t1384
  br label %table_cow_done_253
table_cow_done_253:
  %t1422 = load i8*, i8** %t1384
  %t1423 = bitcast i8* %t1422 to { i64, i64, i32* }*
  %t1424 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1423, i32 0, i32 0
  %t1425 = load i64, i64* %t1424
  %t1426 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1423, i32 0, i32 1
  %t1427 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1423, i32 0, i32 2
  %t1428 = load i32*, i32** %t1427
  %t1430 = getelementptr inbounds %Item, %Item* %t1429, i32 0, i32 0
  store i32 9, i32* %t1430
  %t1431 = load %Item, %Item* %t1429
  %t1432 = load i64, i64* %t1426
  %t1433 = load i64, i64* %t1424
  %t1434 = load i32*, i32** %t1427
  %t1435 = icmp sge i64 %t1433, %t1432
  br i1 %t1435, label %table_push_grow_257, label %table_push_store_258
table_push_grow_257:
  %t1436 = mul i64 %t1432, 2
  %t1437 = icmp sgt i64 %t1436, 0
  %t1438 = select i1 %t1437, i64 %t1436, i64 1
  %t1439 = getelementptr i32, i32* null, i32 1
  %t1440 = ptrtoint i32* %t1439 to i64
  %t1441 = mul i64 %t1438, %t1440
  %t1442 = call i8* @malloc(i64 %t1441)
  %t1443 = bitcast i8* %t1442 to i32*
  %t1444 = icmp sgt i64 %t1432, 0
  br i1 %t1444, label %table_push_copy_259, label %table_push_after_copy_260
table_push_copy_259:
  %t1445 = mul i64 %t1433, %t1440
  %t1446 = bitcast i32* %t1434 to i8*
  call i8* @memcpy(i8* %t1442, i8* %t1446, i64 %t1445)
  call void @free(i8* %t1446)
  br label %table_push_after_copy_260
table_push_after_copy_260:
  store i32* %t1443, i32** %t1427
  store i64 %t1438, i64* %t1426
  br label %table_push_store_258
table_push_store_258:
  %t1447 = load i32*, i32** %t1427
  %t1448 = extractvalue %Item %t1431, 0
  %t1449 = getelementptr inbounds i32, i32* %t1447, i64 %t1433
  store i32 %t1448, i32* %t1449
  %t1450 = add i64 %t1433, 1
  store i64 %t1450, i64* %t1424
  %t1451 = load i8*, i8** %t1384
  %t1452 = load i8*, i8** %t1384
  call void @star_rc_retain(i8* %t1452)
  %t1453 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1454 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1455 = load i64, i64* %t1454
  %t1456 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1457 = load i64, i64* %t1456
  %t1458 = icmp sge i64 %t1457, 2
  br i1 %t1458, label %ring_push_full_261, label %ring_push_grow_262
ring_push_grow_262:
  %t1459 = add i64 %t1455, %t1457
  %t1460 = urem i64 %t1459, 2
  %t1461 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1453, i32 0, i64 %t1460
  store i8* %t1451, i8** %t1461
  %t1462 = add i64 %t1457, 1
  store i64 %t1462, i64* %t1456
  br label %ring_push_done_263
ring_push_full_261:
  %t1463 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1453, i32 0, i64 %t1455
  %t1464 = load i8*, i8** %t1463
  call void @star_rc_release(i8* %t1464)
  store i8* %t1451, i8** %t1463
  %t1465 = add i64 %t1455, 1
  %t1466 = urem i64 %t1465, 2
  store i64 %t1466, i64* %t1454
  br label %ring_push_done_263
ring_push_done_263:
  %t1467 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1468 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1469 = load i64, i64* %t1468
  %t1470 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1471 = load i64, i64* %t1470
  %t1472 = trunc i64 %t1471 to i32
  %t1473 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1474 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1475 = load i64, i64* %t1474
  %t1476 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1477 = load i64, i64* %t1476
  %t1478 = sext i32 0 to i64
  %t1479 = load i64, i64* %t1474
  %t1480 = load i64, i64* %t1476
  %t1481 = icmp ult i64 %t1478, %t1480
  br i1 %t1481, label %ring_rplace_ok_264, label %ring_rplace_oob_265
ring_rplace_ok_264:
  %t1482 = add i64 %t1479, %t1478
  %t1483 = urem i64 %t1482, 2
  %t1484 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1473, i32 0, i64 %t1483
  br label %ring_rplace_end_266
ring_rplace_oob_265:
  store i8* null, i8** %t1485
  br label %ring_rplace_end_266
ring_rplace_end_266:
  %t1486 = phi i8** [ %t1484, %ring_rplace_ok_264 ], [ %t1485, %ring_rplace_oob_265 ]
  %t1487 = load i8*, i8** %t1486
  %t1488 = icmp eq i8* %t1487, null
  br i1 %t1488, label %table_read_null_267, label %table_read_real_268
table_read_null_267:
  br label %table_read_end_269
table_read_real_268:
  %t1489 = bitcast i8* %t1487 to { i64, i64, i32* }*
  %t1490 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1489, i32 0, i32 0
  %t1491 = load i64, i64* %t1490
  %t1492 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1489, i32 0, i32 2
  %t1493 = load i32*, i32** %t1492
  br label %table_read_end_269
table_read_end_269:
  %t1494 = phi i64 [ 0, %table_read_null_267 ], [ %t1491, %table_read_real_268 ]
  %t1495 = phi i32* [ null, %table_read_null_267 ], [ %t1493, %table_read_real_268 ]
  %t1496 = trunc i64 %t1494 to i32
  %t1497 = sext i32 0 to i64
  %t1498 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1499 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 1
  %t1500 = load i64, i64* %t1499
  %t1501 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 2
  %t1502 = load i64, i64* %t1501
  %t1503 = sext i32 0 to i64
  %t1504 = load i64, i64* %t1499
  %t1505 = load i64, i64* %t1501
  %t1506 = icmp ult i64 %t1503, %t1505
  br i1 %t1506, label %ring_rplace_ok_270, label %ring_rplace_oob_271
ring_rplace_ok_270:
  %t1507 = add i64 %t1504, %t1503
  %t1508 = urem i64 %t1507, 2
  %t1509 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1498, i32 0, i64 %t1508
  br label %ring_rplace_end_272
ring_rplace_oob_271:
  store i8* null, i8** %t1510
  br label %ring_rplace_end_272
ring_rplace_end_272:
  %t1511 = phi i8** [ %t1509, %ring_rplace_ok_270 ], [ %t1510, %ring_rplace_oob_271 ]
  %t1512 = load i8*, i8** %t1511
  %t1513 = icmp eq i8* %t1512, null
  br i1 %t1513, label %table_read_null_273, label %table_read_real_274
table_read_null_273:
  br label %table_read_end_275
table_read_real_274:
  %t1514 = bitcast i8* %t1512 to { i64, i64, i32* }*
  %t1515 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1514, i32 0, i32 0
  %t1516 = load i64, i64* %t1515
  %t1517 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1514, i32 0, i32 2
  %t1518 = load i32*, i32** %t1517
  br label %table_read_end_275
table_read_end_275:
  %t1519 = phi i64 [ 0, %table_read_null_273 ], [ %t1516, %table_read_real_274 ]
  %t1520 = phi i32* [ null, %table_read_null_273 ], [ %t1518, %table_read_real_274 ]
  %t1522 = icmp ult i64 %t1497, %t1519
  br i1 %t1522, label %table_idx_ok_276, label %table_idx_oob_277
table_idx_ok_276:
  %t1523 = getelementptr inbounds i32, i32* %t1520, i64 %t1497
  %t1524 = load i32, i32* %t1523
  %t1525 = getelementptr inbounds %Item, %Item* %t1521, i32 0, i32 0
  store i32 %t1524, i32* %t1525
  br label %table_idx_end_278
table_idx_oob_277:
  store %Item zeroinitializer, %Item* %t1521
  br label %table_idx_end_278
table_idx_end_278:
  %t1526 = load %Item, %Item* %t1521
  store %Item %t1526, %Item* %t1527
  %t1528 = getelementptr inbounds %Item, %Item* %t1527, i32 0, i32 0
  %t1529 = load i32, i32* %t1528
  %t1530 = getelementptr inbounds [45 x i8], [45 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1530, i32 %t1472, i32 %t1496, i32 %t1529)
  %t1531 = load i8*, i8** %t1384
  call void @star_rc_release(i8* %t1531)
  %t1532 = load i8*, i8** %t1080
  call void @star_rc_release(i8* %t1532)
  %t1533 = load i8*, i8** %t991
  call void @star_rc_release(i8* %t1533)
  %t1534 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t990, i32 0, i32 0
  %t1535 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1534, i32 0, i64 0
  %t1536 = load i8*, i8** %t1535
  call void @star_rc_release(i8* %t1536)
  %t1537 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1534, i32 0, i64 1
  %t1538 = load i8*, i8** %t1537
  call void @star_rc_release(i8* %t1538)
  %t1539 = getelementptr inbounds %Bag, %Bag* %t901, i32 0, i32 0
  %t1540 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1539, i32 0, i32 0
  %t1541 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1540, i32 0, i64 0
  %t1542 = load i8*, i8** %t1541
  call void @star_rc_release(i8* %t1542)
  %t1543 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1540, i32 0, i64 1
  %t1544 = load i8*, i8** %t1543
  call void @star_rc_release(i8* %t1544)
  %t1545 = load i8*, i8** %t768
  call void @star_rc_release(i8* %t1545)
  %t1546 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t365, i32 0, i32 0
  %t1547 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1546, i32 0, i64 0
  %t1548 = load i8*, i8** %t1547
  call void @star_rc_release(i8* %t1548)
  %t1549 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1546, i32 0, i64 1
  %t1550 = load i8*, i8** %t1549
  call void @star_rc_release(i8* %t1550)
  %t1551 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 0
  %t1552 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1551, i32 0, i64 0
  %t1553 = load i8*, i8** %t1552
  call void @star_rc_release(i8* %t1553)
  %t1554 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1551, i32 0, i64 1
  %t1555 = load i8*, i8** %t1554
  call void @star_rc_release(i8* %t1555)
  %t1556 = load i8*, i8** %t205
  call void @star_rc_release(i8* %t1556)
  %t1557 = getelementptr inbounds %Snapshot, %Snapshot* %t87, i32 0, i32 2
  %t1558 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1557, i32 0, i32 0
  %t1559 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1558, i32 0, i64 0
  %t1560 = getelementptr inbounds %Player, %Player* %t1559, i32 0, i32 0
  %t1561 = load i8*, i8** %t1560
  call void @star_rc_release(i8* %t1561)
  %t1562 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1558, i32 0, i64 1
  %t1563 = getelementptr inbounds %Player, %Player* %t1562, i32 0, i32 0
  %t1564 = load i8*, i8** %t1563
  call void @star_rc_release(i8* %t1564)
  %t1565 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t1566 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1565, i32 0, i32 0
  %t1567 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1566, i32 0, i64 0
  %t1568 = getelementptr inbounds %Player, %Player* %t1567, i32 0, i32 0
  %t1569 = load i8*, i8** %t1568
  call void @star_rc_release(i8* %t1569)
  %t1570 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1566, i32 0, i64 1
  %t1571 = getelementptr inbounds %Player, %Player* %t1570, i32 0, i32 0
  %t1572 = load i8*, i8** %t1571
  call void @star_rc_release(i8* %t1572)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Bag(i8* %objp) {
entry:
  %t244 = alloca i64
  %t239 = bitcast i8* %objp to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t240 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t239, i32 0, i32 0
  %t241 = load i64, i64* %t240
  %t242 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t239, i32 0, i32 2
  %t243 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t242
  store i64 0, i64* %t244
  br label %table_release_cond_48
table_release_cond_48:
  %t245 = load i64, i64* %t244
  %t246 = icmp slt i64 %t245, %t241
  br i1 %t246, label %table_release_body_49, label %table_release_end_50
table_release_body_49:
  %t247 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t243, i64 %t245
  %t248 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t247, i32 0, i32 0
  %t249 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t248, i32 0, i64 0
  %t250 = load i8*, i8** %t249
  call void @star_rc_release(i8* %t250)
  %t251 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t248, i32 0, i64 1
  %t252 = load i8*, i8** %t251
  call void @star_rc_release(i8* %t252)
  %t253 = add i64 %t245, 1
  store i64 %t253, i64* %t244
  br label %table_release_cond_48
table_release_end_50:
  %t254 = bitcast { [2 x i8*], i64, i64 }* %t243 to i8*
  call void @free(i8* %t254)
  %t255 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t239, i32 0, i32 3
  %t256 = load i32*, i32** %t255
  %t257 = bitcast i32* %t256 to i8*
  call void @free(i8* %t257)
  ret void
}


define void @table_release_s_Item(i8* %objp) {
entry:
  %t994 = bitcast i8* %objp to { i64, i64, i32* }*
  %t995 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t994, i32 0, i32 0
  %t996 = load i64, i64* %t995
  %t997 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t994, i32 0, i32 2
  %t998 = load i32*, i32** %t997
  %t999 = bitcast i32* %t998 to i8*
  call void @free(i8* %t999)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Hero\00" }
@.str.1 = private unnamed_addr constant [43 x i8] c"snapshot tag=%d hist_len=%d hist=[%d, %d]\0A\00"
@.str.2 = private unnamed_addr constant [35 x i8] c"snapshot who_len=%d who0=%s hp=%d\0A\00"
@.str.3 = private unnamed_addr constant [26 x i8] c"a hist len=%d a=[%d, %d]\0A\00"
@.str.4 = private unnamed_addr constant [26 x i8] c"s hist len=%d s=[%d, %d]\0A\00"
@.str.5 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"a\00" }
@.str.6 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"b\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"c\00" }
@.str.8 = private unnamed_addr constant [13 x i8] c"bags len=%d\0A\00"
@.str.9 = private unnamed_addr constant [39 x i8] c"bags[0] tag=%d hist_len=%d h=[%s, %s]\0A\00"
@.str.10 = private unnamed_addr constant [34 x i8] c"bags[1] tag=%d hist_len=%d h0=%s\0A\00"
@.str.11 = private unnamed_addr constant [31 x i8] c"bags orig len=%d clone len=%d\0A\00"
@.str.12 = private unnamed_addr constant [27 x i8] c"popped tag=%d hist_len=%d\0A\00"
@.str.13 = private unnamed_addr constant [33 x i8] c"r len=%d r0 len=%d r0[0].tag=%d\0A\00"
@.str.14 = private unnamed_addr constant [37 x i8] c"r1 len=%d r1[0].tag=%d r1[1].tag=%d\0A\00"
@.str.15 = private unnamed_addr constant [45 x i8] c"after evict r len=%d r0 len=%d r0[0].tag=%d\0A\00"
