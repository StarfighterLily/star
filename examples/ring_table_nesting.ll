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
  %t627 = alloca %Bag
  %t641 = alloca %Bag
  %t655 = alloca i8*
  %t673 = alloca %Bag
  %t687 = alloca %Bag
  %t703 = alloca %Bag
  %t717 = alloca %Bag
  %t738 = alloca %Bag
  %t752 = alloca %Bag
  %t766 = alloca i8*
  %t771 = alloca i8*
  %t811 = alloca i64
  %t842 = alloca %Bag
  %t904 = alloca %Bag
  %t942 = alloca i64
  %t973 = alloca %Bag
  %t993 = alloca { [2 x i8*], i64, i64 }
  %t994 = alloca i8*
  %t1045 = alloca %Item
  %t1083 = alloca i8*
  %t1128 = alloca %Item
  %t1194 = alloca %Item
  %t1250 = alloca i8*
  %t1275 = alloca i8*
  %t1286 = alloca %Item
  %t1292 = alloca %Item
  %t1308 = alloca i8*
  %t1333 = alloca i8*
  %t1344 = alloca %Item
  %t1350 = alloca %Item
  %t1366 = alloca i8*
  %t1377 = alloca %Item
  %t1383 = alloca %Item
  %t1387 = alloca i8*
  %t1432 = alloca %Item
  %t1488 = alloca i8*
  %t1513 = alloca i8*
  %t1524 = alloca %Item
  %t1530 = alloca %Item
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
  %t613 = load i8*, i8** %t611
  call void @star_rc_retain(i8* %t613)
  %t614 = sext i32 0 to i64
  %t615 = load i8*, i8** %t205
  %t616 = icmp eq i8* %t615, null
  br i1 %t616, label %table_read_null_109, label %table_read_real_110
table_read_null_109:
  br label %table_read_end_111
table_read_real_110:
  %t617 = bitcast i8* %t615 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t618 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t617, i32 0, i32 0
  %t619 = load i64, i64* %t618
  %t620 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t617, i32 0, i32 2
  %t621 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t620
  %t622 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t617, i32 0, i32 3
  %t623 = load i32*, i32** %t622
  br label %table_read_end_111
table_read_end_111:
  %t624 = phi i64 [ 0, %table_read_null_109 ], [ %t619, %table_read_real_110 ]
  %t625 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_109 ], [ %t621, %table_read_real_110 ]
  %t626 = phi i32* [ null, %table_read_null_109 ], [ %t623, %table_read_real_110 ]
  %t628 = icmp ult i64 %t614, %t624
  br i1 %t628, label %table_idx_ok_112, label %table_idx_oob_113
table_idx_ok_112:
  %t629 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t625, i64 %t614
  %t630 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t629, i32 0, i32 0
  %t631 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t630, i32 0, i64 0
  %t632 = load i8*, i8** %t631
  call void @star_rc_retain(i8* %t632)
  %t633 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t630, i32 0, i64 1
  %t634 = load i8*, i8** %t633
  call void @star_rc_retain(i8* %t634)
  %t635 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t629
  %t636 = getelementptr inbounds %Bag, %Bag* %t627, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t635, { [2 x i8*], i64, i64 }* %t636
  %t637 = getelementptr inbounds i32, i32* %t626, i64 %t614
  %t638 = load i32, i32* %t637
  %t639 = getelementptr inbounds %Bag, %Bag* %t627, i32 0, i32 1
  store i32 %t638, i32* %t639
  br label %table_idx_end_114
table_idx_oob_113:
  store %Bag zeroinitializer, %Bag* %t627
  br label %table_idx_end_114
table_idx_end_114:
  %t640 = load %Bag, %Bag* %t627
  store %Bag %t640, %Bag* %t641
  %t642 = getelementptr inbounds %Bag, %Bag* %t641, i32 0, i32 0
  %t643 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t642, i32 0, i32 0
  %t644 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t642, i32 0, i32 1
  %t645 = load i64, i64* %t644
  %t646 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t642, i32 0, i32 2
  %t647 = load i64, i64* %t646
  %t648 = sext i32 1 to i64
  %t649 = load i64, i64* %t644
  %t650 = load i64, i64* %t646
  %t651 = icmp ult i64 %t648, %t650
  br i1 %t651, label %ring_rplace_ok_115, label %ring_rplace_oob_116
ring_rplace_ok_115:
  %t652 = add i64 %t649, %t648
  %t653 = urem i64 %t652, 2
  %t654 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t643, i32 0, i64 %t653
  br label %ring_rplace_end_117
ring_rplace_oob_116:
  store i8* null, i8** %t655
  br label %ring_rplace_end_117
ring_rplace_end_117:
  %t656 = phi i8** [ %t654, %ring_rplace_ok_115 ], [ %t655, %ring_rplace_oob_116 ]
  %t657 = load i8*, i8** %t656
  %t658 = load i8*, i8** %t656
  call void @star_rc_retain(i8* %t658)
  %t659 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t659, i32 %t533, i32 %t568, i8* %t612, i8* %t657)
  %t660 = sext i32 1 to i64
  %t661 = load i8*, i8** %t205
  %t662 = icmp eq i8* %t661, null
  br i1 %t662, label %table_read_null_118, label %table_read_real_119
table_read_null_118:
  br label %table_read_end_120
table_read_real_119:
  %t663 = bitcast i8* %t661 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t664 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t663, i32 0, i32 0
  %t665 = load i64, i64* %t664
  %t666 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t663, i32 0, i32 2
  %t667 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t666
  %t668 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t663, i32 0, i32 3
  %t669 = load i32*, i32** %t668
  br label %table_read_end_120
table_read_end_120:
  %t670 = phi i64 [ 0, %table_read_null_118 ], [ %t665, %table_read_real_119 ]
  %t671 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_118 ], [ %t667, %table_read_real_119 ]
  %t672 = phi i32* [ null, %table_read_null_118 ], [ %t669, %table_read_real_119 ]
  %t674 = icmp ult i64 %t660, %t670
  br i1 %t674, label %table_idx_ok_121, label %table_idx_oob_122
table_idx_ok_121:
  %t675 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t671, i64 %t660
  %t676 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t675, i32 0, i32 0
  %t677 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t676, i32 0, i64 0
  %t678 = load i8*, i8** %t677
  call void @star_rc_retain(i8* %t678)
  %t679 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t676, i32 0, i64 1
  %t680 = load i8*, i8** %t679
  call void @star_rc_retain(i8* %t680)
  %t681 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t675
  %t682 = getelementptr inbounds %Bag, %Bag* %t673, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t681, { [2 x i8*], i64, i64 }* %t682
  %t683 = getelementptr inbounds i32, i32* %t672, i64 %t660
  %t684 = load i32, i32* %t683
  %t685 = getelementptr inbounds %Bag, %Bag* %t673, i32 0, i32 1
  store i32 %t684, i32* %t685
  br label %table_idx_end_123
table_idx_oob_122:
  store %Bag zeroinitializer, %Bag* %t673
  br label %table_idx_end_123
table_idx_end_123:
  %t686 = load %Bag, %Bag* %t673
  store %Bag %t686, %Bag* %t687
  %t688 = getelementptr inbounds %Bag, %Bag* %t687, i32 0, i32 1
  %t689 = load i32, i32* %t688
  %t690 = sext i32 1 to i64
  %t691 = load i8*, i8** %t205
  %t692 = icmp eq i8* %t691, null
  br i1 %t692, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t693 = bitcast i8* %t691 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t694 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t693, i32 0, i32 0
  %t695 = load i64, i64* %t694
  %t696 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t693, i32 0, i32 2
  %t697 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t696
  %t698 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t693, i32 0, i32 3
  %t699 = load i32*, i32** %t698
  br label %table_read_end_126
table_read_end_126:
  %t700 = phi i64 [ 0, %table_read_null_124 ], [ %t695, %table_read_real_125 ]
  %t701 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_124 ], [ %t697, %table_read_real_125 ]
  %t702 = phi i32* [ null, %table_read_null_124 ], [ %t699, %table_read_real_125 ]
  %t704 = icmp ult i64 %t690, %t700
  br i1 %t704, label %table_idx_ok_127, label %table_idx_oob_128
table_idx_ok_127:
  %t705 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t701, i64 %t690
  %t706 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t705, i32 0, i32 0
  %t707 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t706, i32 0, i64 0
  %t708 = load i8*, i8** %t707
  call void @star_rc_retain(i8* %t708)
  %t709 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t706, i32 0, i64 1
  %t710 = load i8*, i8** %t709
  call void @star_rc_retain(i8* %t710)
  %t711 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t705
  %t712 = getelementptr inbounds %Bag, %Bag* %t703, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t711, { [2 x i8*], i64, i64 }* %t712
  %t713 = getelementptr inbounds i32, i32* %t702, i64 %t690
  %t714 = load i32, i32* %t713
  %t715 = getelementptr inbounds %Bag, %Bag* %t703, i32 0, i32 1
  store i32 %t714, i32* %t715
  br label %table_idx_end_129
table_idx_oob_128:
  store %Bag zeroinitializer, %Bag* %t703
  br label %table_idx_end_129
table_idx_end_129:
  %t716 = load %Bag, %Bag* %t703
  store %Bag %t716, %Bag* %t717
  %t718 = getelementptr inbounds %Bag, %Bag* %t717, i32 0, i32 0
  %t719 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t718, i32 0, i32 0
  %t720 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t718, i32 0, i32 1
  %t721 = load i64, i64* %t720
  %t722 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t718, i32 0, i32 2
  %t723 = load i64, i64* %t722
  %t724 = trunc i64 %t723 to i32
  %t725 = sext i32 1 to i64
  %t726 = load i8*, i8** %t205
  %t727 = icmp eq i8* %t726, null
  br i1 %t727, label %table_read_null_130, label %table_read_real_131
table_read_null_130:
  br label %table_read_end_132
table_read_real_131:
  %t728 = bitcast i8* %t726 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t729 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t728, i32 0, i32 0
  %t730 = load i64, i64* %t729
  %t731 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t728, i32 0, i32 2
  %t732 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t731
  %t733 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t728, i32 0, i32 3
  %t734 = load i32*, i32** %t733
  br label %table_read_end_132
table_read_end_132:
  %t735 = phi i64 [ 0, %table_read_null_130 ], [ %t730, %table_read_real_131 ]
  %t736 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_130 ], [ %t732, %table_read_real_131 ]
  %t737 = phi i32* [ null, %table_read_null_130 ], [ %t734, %table_read_real_131 ]
  %t739 = icmp ult i64 %t725, %t735
  br i1 %t739, label %table_idx_ok_133, label %table_idx_oob_134
table_idx_ok_133:
  %t740 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t736, i64 %t725
  %t741 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t740, i32 0, i32 0
  %t742 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t741, i32 0, i64 0
  %t743 = load i8*, i8** %t742
  call void @star_rc_retain(i8* %t743)
  %t744 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t741, i32 0, i64 1
  %t745 = load i8*, i8** %t744
  call void @star_rc_retain(i8* %t745)
  %t746 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t740
  %t747 = getelementptr inbounds %Bag, %Bag* %t738, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t746, { [2 x i8*], i64, i64 }* %t747
  %t748 = getelementptr inbounds i32, i32* %t737, i64 %t725
  %t749 = load i32, i32* %t748
  %t750 = getelementptr inbounds %Bag, %Bag* %t738, i32 0, i32 1
  store i32 %t749, i32* %t750
  br label %table_idx_end_135
table_idx_oob_134:
  store %Bag zeroinitializer, %Bag* %t738
  br label %table_idx_end_135
table_idx_end_135:
  %t751 = load %Bag, %Bag* %t738
  store %Bag %t751, %Bag* %t752
  %t753 = getelementptr inbounds %Bag, %Bag* %t752, i32 0, i32 0
  %t754 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t753, i32 0, i32 0
  %t755 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t753, i32 0, i32 1
  %t756 = load i64, i64* %t755
  %t757 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t753, i32 0, i32 2
  %t758 = load i64, i64* %t757
  %t759 = sext i32 0 to i64
  %t760 = load i64, i64* %t755
  %t761 = load i64, i64* %t757
  %t762 = icmp ult i64 %t759, %t761
  br i1 %t762, label %ring_rplace_ok_136, label %ring_rplace_oob_137
ring_rplace_ok_136:
  %t763 = add i64 %t760, %t759
  %t764 = urem i64 %t763, 2
  %t765 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t754, i32 0, i64 %t764
  br label %ring_rplace_end_138
ring_rplace_oob_137:
  store i8* null, i8** %t766
  br label %ring_rplace_end_138
ring_rplace_end_138:
  %t767 = phi i8** [ %t765, %ring_rplace_ok_136 ], [ %t766, %ring_rplace_oob_137 ]
  %t768 = load i8*, i8** %t767
  %t769 = load i8*, i8** %t767
  call void @star_rc_retain(i8* %t769)
  %t770 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t770, i32 %t689, i32 %t724, i8* %t768)
  %t772 = load i8*, i8** %t205
  %t773 = load i8*, i8** %t205
  call void @star_rc_retain(i8* %t773)
  store i8* %t772, i8** %t771
  %t774 = load i8*, i8** %t205
  %t775 = icmp eq i8* %t774, null
  br i1 %t775, label %table_cow_alloc_139, label %table_cow_check_140
table_cow_alloc_139:
  %t776 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t777 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t778 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t777 to i64
  %t779 = call i8* @star_rc_alloc(i64 %t778, i8* %t776)
  %t780 = bitcast i8* %t779 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t781 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t780, i32 0, i32 0
  store i64 0, i64* %t781
  %t782 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t780, i32 0, i32 1
  store i64 0, i64* %t782
  %t783 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t780, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t783
  %t784 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t780, i32 0, i32 3
  store i32* null, i32** %t784
  store i8* %t779, i8** %t205
  br label %table_cow_done_141
table_cow_check_140:
  %t785 = getelementptr inbounds i8, i8* %t774, i64 -16
  %t786 = bitcast i8* %t785 to i64*
  %t787 = load atomic i64, i64* %t786 seq_cst, align 8
  %t788 = icmp eq i64 %t787, 1
  br i1 %t788, label %table_cow_done_141, label %table_cow_clone_142
table_cow_clone_142:
  %t789 = bitcast i8* %t774 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t790 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t789, i32 0, i32 0
  %t791 = load i64, i64* %t790
  %t792 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t789, i32 0, i32 1
  %t793 = load i64, i64* %t792
  %t794 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t795 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t796 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t795 to i64
  %t797 = call i8* @star_rc_alloc(i64 %t796, i8* %t794)
  %t798 = bitcast i8* %t797 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t799 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t798, i32 0, i32 0
  store i64 %t791, i64* %t799
  %t800 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t798, i32 0, i32 1
  store i64 %t793, i64* %t800
  %t801 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t802 = ptrtoint { [2 x i8*], i64, i64 }* %t801 to i64
  %t803 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t789, i32 0, i32 2
  %t804 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t803
  %t805 = mul i64 %t793, %t802
  %t806 = call i8* @malloc(i64 %t805)
  %t807 = bitcast i8* %t806 to { [2 x i8*], i64, i64 }*
  %t808 = icmp sgt i64 %t791, 0
  br i1 %t808, label %table_cow_copy_143, label %table_cow_after_copy_144
table_cow_copy_143:
  %t809 = mul i64 %t791, %t802
  %t810 = bitcast { [2 x i8*], i64, i64 }* %t804 to i8*
  call i8* @memcpy(i8* %t806, i8* %t810, i64 %t809)
  store i64 0, i64* %t811
  br label %table_cow_retain_cond_145
table_cow_retain_cond_145:
  %t812 = load i64, i64* %t811
  %t813 = icmp slt i64 %t812, %t791
  br i1 %t813, label %table_cow_retain_body_146, label %table_cow_retain_end_147
table_cow_retain_body_146:
  %t814 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t807, i64 %t812
  %t815 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t814, i32 0, i32 0
  %t816 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t815, i32 0, i64 0
  %t817 = load i8*, i8** %t816
  call void @star_rc_retain(i8* %t817)
  %t818 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t815, i32 0, i64 1
  %t819 = load i8*, i8** %t818
  call void @star_rc_retain(i8* %t819)
  %t820 = add i64 %t812, 1
  store i64 %t820, i64* %t811
  br label %table_cow_retain_cond_145
table_cow_retain_end_147:
  br label %table_cow_after_copy_144
table_cow_after_copy_144:
  %t821 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t798, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t807, { [2 x i8*], i64, i64 }** %t821
  %t822 = getelementptr i32, i32* null, i32 1
  %t823 = ptrtoint i32* %t822 to i64
  %t824 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t789, i32 0, i32 3
  %t825 = load i32*, i32** %t824
  %t826 = mul i64 %t793, %t823
  %t827 = call i8* @malloc(i64 %t826)
  %t828 = bitcast i8* %t827 to i32*
  %t829 = icmp sgt i64 %t791, 0
  br i1 %t829, label %table_cow_copy_148, label %table_cow_after_copy_149
table_cow_copy_148:
  %t830 = mul i64 %t791, %t823
  %t831 = bitcast i32* %t825 to i8*
  call i8* @memcpy(i8* %t827, i8* %t831, i64 %t830)
  br label %table_cow_after_copy_149
table_cow_after_copy_149:
  %t832 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t798, i32 0, i32 3
  store i32* %t828, i32** %t832
  call void @star_rc_release(i8* %t774)
  store i8* %t797, i8** %t205
  br label %table_cow_done_141
table_cow_done_141:
  %t833 = load i8*, i8** %t205
  %t834 = bitcast i8* %t833 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t835 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t834, i32 0, i32 0
  %t836 = load i64, i64* %t835
  %t837 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t834, i32 0, i32 1
  %t838 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t834, i32 0, i32 2
  %t839 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t838
  %t840 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t834, i32 0, i32 3
  %t841 = load i32*, i32** %t840
  %t843 = getelementptr inbounds %Bag, %Bag* %t842, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t843
  %t844 = getelementptr inbounds %Bag, %Bag* %t842, i32 0, i32 1
  store i32 3, i32* %t844
  %t845 = load %Bag, %Bag* %t842
  %t846 = load i64, i64* %t837
  %t847 = load i64, i64* %t835
  %t848 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t838
  %t849 = load i32*, i32** %t840
  %t850 = icmp sge i64 %t847, %t846
  br i1 %t850, label %table_push_grow_150, label %table_push_store_151
table_push_grow_150:
  %t851 = mul i64 %t846, 2
  %t852 = icmp sgt i64 %t851, 0
  %t853 = select i1 %t852, i64 %t851, i64 1
  %t854 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t855 = ptrtoint { [2 x i8*], i64, i64 }* %t854 to i64
  %t856 = mul i64 %t853, %t855
  %t857 = call i8* @malloc(i64 %t856)
  %t858 = bitcast i8* %t857 to { [2 x i8*], i64, i64 }*
  %t859 = icmp sgt i64 %t846, 0
  br i1 %t859, label %table_push_copy_152, label %table_push_after_copy_153
table_push_copy_152:
  %t860 = mul i64 %t847, %t855
  %t861 = bitcast { [2 x i8*], i64, i64 }* %t848 to i8*
  call i8* @memcpy(i8* %t857, i8* %t861, i64 %t860)
  call void @free(i8* %t861)
  br label %table_push_after_copy_153
table_push_after_copy_153:
  store { [2 x i8*], i64, i64 }* %t858, { [2 x i8*], i64, i64 }** %t838
  %t862 = getelementptr i32, i32* null, i32 1
  %t863 = ptrtoint i32* %t862 to i64
  %t864 = mul i64 %t853, %t863
  %t865 = call i8* @malloc(i64 %t864)
  %t866 = bitcast i8* %t865 to i32*
  %t867 = icmp sgt i64 %t846, 0
  br i1 %t867, label %table_push_copy_154, label %table_push_after_copy_155
table_push_copy_154:
  %t868 = mul i64 %t847, %t863
  %t869 = bitcast i32* %t849 to i8*
  call i8* @memcpy(i8* %t865, i8* %t869, i64 %t868)
  call void @free(i8* %t869)
  br label %table_push_after_copy_155
table_push_after_copy_155:
  store i32* %t866, i32** %t840
  store i64 %t853, i64* %t837
  br label %table_push_store_151
table_push_store_151:
  %t870 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t838
  %t871 = extractvalue %Bag %t845, 0
  %t872 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t870, i64 %t847
  store { [2 x i8*], i64, i64 } %t871, { [2 x i8*], i64, i64 }* %t872
  %t873 = load i32*, i32** %t840
  %t874 = extractvalue %Bag %t845, 1
  %t875 = getelementptr inbounds i32, i32* %t873, i64 %t847
  store i32 %t874, i32* %t875
  %t876 = add i64 %t847, 1
  store i64 %t876, i64* %t835
  %t877 = load i8*, i8** %t205
  %t878 = icmp eq i8* %t877, null
  br i1 %t878, label %table_read_null_156, label %table_read_real_157
table_read_null_156:
  br label %table_read_end_158
table_read_real_157:
  %t879 = bitcast i8* %t877 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t880 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t879, i32 0, i32 0
  %t881 = load i64, i64* %t880
  %t882 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t879, i32 0, i32 2
  %t883 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t882
  %t884 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t879, i32 0, i32 3
  %t885 = load i32*, i32** %t884
  br label %table_read_end_158
table_read_end_158:
  %t886 = phi i64 [ 0, %table_read_null_156 ], [ %t881, %table_read_real_157 ]
  %t887 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_156 ], [ %t883, %table_read_real_157 ]
  %t888 = phi i32* [ null, %table_read_null_156 ], [ %t885, %table_read_real_157 ]
  %t889 = trunc i64 %t886 to i32
  %t890 = load i8*, i8** %t771
  %t891 = icmp eq i8* %t890, null
  br i1 %t891, label %table_read_null_159, label %table_read_real_160
table_read_null_159:
  br label %table_read_end_161
table_read_real_160:
  %t892 = bitcast i8* %t890 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t893 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t892, i32 0, i32 0
  %t894 = load i64, i64* %t893
  %t895 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t892, i32 0, i32 2
  %t896 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t895
  %t897 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t892, i32 0, i32 3
  %t898 = load i32*, i32** %t897
  br label %table_read_end_161
table_read_end_161:
  %t899 = phi i64 [ 0, %table_read_null_159 ], [ %t894, %table_read_real_160 ]
  %t900 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_159 ], [ %t896, %table_read_real_160 ]
  %t901 = phi i32* [ null, %table_read_null_159 ], [ %t898, %table_read_real_160 ]
  %t902 = trunc i64 %t899 to i32
  %t903 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t903, i32 %t889, i32 %t902)
  %t905 = load i8*, i8** %t205
  %t906 = icmp eq i8* %t905, null
  br i1 %t906, label %table_cow_alloc_162, label %table_cow_check_163
table_cow_alloc_162:
  %t907 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t908 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t909 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t908 to i64
  %t910 = call i8* @star_rc_alloc(i64 %t909, i8* %t907)
  %t911 = bitcast i8* %t910 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t912 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t911, i32 0, i32 0
  store i64 0, i64* %t912
  %t913 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t911, i32 0, i32 1
  store i64 0, i64* %t913
  %t914 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t911, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t914
  %t915 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t911, i32 0, i32 3
  store i32* null, i32** %t915
  store i8* %t910, i8** %t205
  br label %table_cow_done_164
table_cow_check_163:
  %t916 = getelementptr inbounds i8, i8* %t905, i64 -16
  %t917 = bitcast i8* %t916 to i64*
  %t918 = load atomic i64, i64* %t917 seq_cst, align 8
  %t919 = icmp eq i64 %t918, 1
  br i1 %t919, label %table_cow_done_164, label %table_cow_clone_165
table_cow_clone_165:
  %t920 = bitcast i8* %t905 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t921 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t920, i32 0, i32 0
  %t922 = load i64, i64* %t921
  %t923 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t920, i32 0, i32 1
  %t924 = load i64, i64* %t923
  %t925 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t926 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t927 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t926 to i64
  %t928 = call i8* @star_rc_alloc(i64 %t927, i8* %t925)
  %t929 = bitcast i8* %t928 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t930 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t929, i32 0, i32 0
  store i64 %t922, i64* %t930
  %t931 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t929, i32 0, i32 1
  store i64 %t924, i64* %t931
  %t932 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t933 = ptrtoint { [2 x i8*], i64, i64 }* %t932 to i64
  %t934 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t920, i32 0, i32 2
  %t935 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t934
  %t936 = mul i64 %t924, %t933
  %t937 = call i8* @malloc(i64 %t936)
  %t938 = bitcast i8* %t937 to { [2 x i8*], i64, i64 }*
  %t939 = icmp sgt i64 %t922, 0
  br i1 %t939, label %table_cow_copy_166, label %table_cow_after_copy_167
table_cow_copy_166:
  %t940 = mul i64 %t922, %t933
  %t941 = bitcast { [2 x i8*], i64, i64 }* %t935 to i8*
  call i8* @memcpy(i8* %t937, i8* %t941, i64 %t940)
  store i64 0, i64* %t942
  br label %table_cow_retain_cond_168
table_cow_retain_cond_168:
  %t943 = load i64, i64* %t942
  %t944 = icmp slt i64 %t943, %t922
  br i1 %t944, label %table_cow_retain_body_169, label %table_cow_retain_end_170
table_cow_retain_body_169:
  %t945 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t938, i64 %t943
  %t946 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t945, i32 0, i32 0
  %t947 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t946, i32 0, i64 0
  %t948 = load i8*, i8** %t947
  call void @star_rc_retain(i8* %t948)
  %t949 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t946, i32 0, i64 1
  %t950 = load i8*, i8** %t949
  call void @star_rc_retain(i8* %t950)
  %t951 = add i64 %t943, 1
  store i64 %t951, i64* %t942
  br label %table_cow_retain_cond_168
table_cow_retain_end_170:
  br label %table_cow_after_copy_167
table_cow_after_copy_167:
  %t952 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t929, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t938, { [2 x i8*], i64, i64 }** %t952
  %t953 = getelementptr i32, i32* null, i32 1
  %t954 = ptrtoint i32* %t953 to i64
  %t955 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t920, i32 0, i32 3
  %t956 = load i32*, i32** %t955
  %t957 = mul i64 %t924, %t954
  %t958 = call i8* @malloc(i64 %t957)
  %t959 = bitcast i8* %t958 to i32*
  %t960 = icmp sgt i64 %t922, 0
  br i1 %t960, label %table_cow_copy_171, label %table_cow_after_copy_172
table_cow_copy_171:
  %t961 = mul i64 %t922, %t954
  %t962 = bitcast i32* %t956 to i8*
  call i8* @memcpy(i8* %t958, i8* %t962, i64 %t961)
  br label %table_cow_after_copy_172
table_cow_after_copy_172:
  %t963 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t929, i32 0, i32 3
  store i32* %t959, i32** %t963
  call void @star_rc_release(i8* %t905)
  store i8* %t928, i8** %t205
  br label %table_cow_done_164
table_cow_done_164:
  %t964 = load i8*, i8** %t205
  %t965 = bitcast i8* %t964 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t966 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t965, i32 0, i32 0
  %t967 = load i64, i64* %t966
  %t968 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t965, i32 0, i32 1
  %t969 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t965, i32 0, i32 2
  %t970 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t969
  %t971 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t965, i32 0, i32 3
  %t972 = load i32*, i32** %t971
  %t974 = icmp eq i64 %t967, 0
  br i1 %t974, label %table_pop_empty_173, label %table_pop_nonempty_174
table_pop_nonempty_174:
  %t975 = sub i64 %t967, 1
  store i64 %t975, i64* %t966
  %t976 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t970, i64 %t975
  %t977 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t976
  %t978 = getelementptr inbounds %Bag, %Bag* %t973, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t977, { [2 x i8*], i64, i64 }* %t978
  %t979 = getelementptr inbounds i32, i32* %t972, i64 %t975
  %t980 = load i32, i32* %t979
  %t981 = getelementptr inbounds %Bag, %Bag* %t973, i32 0, i32 1
  store i32 %t980, i32* %t981
  br label %table_pop_end_175
table_pop_empty_173:
  store %Bag zeroinitializer, %Bag* %t973
  br label %table_pop_end_175
table_pop_end_175:
  %t982 = load %Bag, %Bag* %t973
  store %Bag %t982, %Bag* %t904
  %t983 = getelementptr inbounds %Bag, %Bag* %t904, i32 0, i32 1
  %t984 = load i32, i32* %t983
  %t985 = getelementptr inbounds %Bag, %Bag* %t904, i32 0, i32 0
  %t986 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t985, i32 0, i32 0
  %t987 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t985, i32 0, i32 1
  %t988 = load i64, i64* %t987
  %t989 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t985, i32 0, i32 2
  %t990 = load i64, i64* %t989
  %t991 = trunc i64 %t990 to i32
  %t992 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t992, i32 %t984, i32 %t991)
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t993
  store i8* null, i8** %t994
  %t995 = load i8*, i8** %t994
  %t996 = icmp eq i8* %t995, null
  br i1 %t996, label %table_cow_alloc_176, label %table_cow_check_177
table_cow_alloc_176:
  %t1003 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1004 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1005 = ptrtoint { i64, i64, i32* }* %t1004 to i64
  %t1006 = call i8* @star_rc_alloc(i64 %t1005, i8* %t1003)
  %t1007 = bitcast i8* %t1006 to { i64, i64, i32* }*
  %t1008 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1007, i32 0, i32 0
  store i64 0, i64* %t1008
  %t1009 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1007, i32 0, i32 1
  store i64 0, i64* %t1009
  %t1010 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1007, i32 0, i32 2
  store i32* null, i32** %t1010
  store i8* %t1006, i8** %t994
  br label %table_cow_done_178
table_cow_check_177:
  %t1011 = getelementptr inbounds i8, i8* %t995, i64 -16
  %t1012 = bitcast i8* %t1011 to i64*
  %t1013 = load atomic i64, i64* %t1012 seq_cst, align 8
  %t1014 = icmp eq i64 %t1013, 1
  br i1 %t1014, label %table_cow_done_178, label %table_cow_clone_179
table_cow_clone_179:
  %t1015 = bitcast i8* %t995 to { i64, i64, i32* }*
  %t1016 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1015, i32 0, i32 0
  %t1017 = load i64, i64* %t1016
  %t1018 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1015, i32 0, i32 1
  %t1019 = load i64, i64* %t1018
  %t1020 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1021 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1022 = ptrtoint { i64, i64, i32* }* %t1021 to i64
  %t1023 = call i8* @star_rc_alloc(i64 %t1022, i8* %t1020)
  %t1024 = bitcast i8* %t1023 to { i64, i64, i32* }*
  %t1025 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1024, i32 0, i32 0
  store i64 %t1017, i64* %t1025
  %t1026 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1024, i32 0, i32 1
  store i64 %t1019, i64* %t1026
  %t1027 = getelementptr i32, i32* null, i32 1
  %t1028 = ptrtoint i32* %t1027 to i64
  %t1029 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1015, i32 0, i32 2
  %t1030 = load i32*, i32** %t1029
  %t1031 = mul i64 %t1019, %t1028
  %t1032 = call i8* @malloc(i64 %t1031)
  %t1033 = bitcast i8* %t1032 to i32*
  %t1034 = icmp sgt i64 %t1017, 0
  br i1 %t1034, label %table_cow_copy_180, label %table_cow_after_copy_181
table_cow_copy_180:
  %t1035 = mul i64 %t1017, %t1028
  %t1036 = bitcast i32* %t1030 to i8*
  call i8* @memcpy(i8* %t1032, i8* %t1036, i64 %t1035)
  br label %table_cow_after_copy_181
table_cow_after_copy_181:
  %t1037 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1024, i32 0, i32 2
  store i32* %t1033, i32** %t1037
  call void @star_rc_release(i8* %t995)
  store i8* %t1023, i8** %t994
  br label %table_cow_done_178
table_cow_done_178:
  %t1038 = load i8*, i8** %t994
  %t1039 = bitcast i8* %t1038 to { i64, i64, i32* }*
  %t1040 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1039, i32 0, i32 0
  %t1041 = load i64, i64* %t1040
  %t1042 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1039, i32 0, i32 1
  %t1043 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1039, i32 0, i32 2
  %t1044 = load i32*, i32** %t1043
  %t1046 = getelementptr inbounds %Item, %Item* %t1045, i32 0, i32 0
  store i32 1, i32* %t1046
  %t1047 = load %Item, %Item* %t1045
  %t1048 = load i64, i64* %t1042
  %t1049 = load i64, i64* %t1040
  %t1050 = load i32*, i32** %t1043
  %t1051 = icmp sge i64 %t1049, %t1048
  br i1 %t1051, label %table_push_grow_182, label %table_push_store_183
table_push_grow_182:
  %t1052 = mul i64 %t1048, 2
  %t1053 = icmp sgt i64 %t1052, 0
  %t1054 = select i1 %t1053, i64 %t1052, i64 1
  %t1055 = getelementptr i32, i32* null, i32 1
  %t1056 = ptrtoint i32* %t1055 to i64
  %t1057 = mul i64 %t1054, %t1056
  %t1058 = call i8* @malloc(i64 %t1057)
  %t1059 = bitcast i8* %t1058 to i32*
  %t1060 = icmp sgt i64 %t1048, 0
  br i1 %t1060, label %table_push_copy_184, label %table_push_after_copy_185
table_push_copy_184:
  %t1061 = mul i64 %t1049, %t1056
  %t1062 = bitcast i32* %t1050 to i8*
  call i8* @memcpy(i8* %t1058, i8* %t1062, i64 %t1061)
  call void @free(i8* %t1062)
  br label %table_push_after_copy_185
table_push_after_copy_185:
  store i32* %t1059, i32** %t1043
  store i64 %t1054, i64* %t1042
  br label %table_push_store_183
table_push_store_183:
  %t1063 = load i32*, i32** %t1043
  %t1064 = extractvalue %Item %t1047, 0
  %t1065 = getelementptr inbounds i32, i32* %t1063, i64 %t1049
  store i32 %t1064, i32* %t1065
  %t1066 = add i64 %t1049, 1
  store i64 %t1066, i64* %t1040
  %t1067 = load i8*, i8** %t994
  %t1068 = load i8*, i8** %t994
  call void @star_rc_retain(i8* %t1068)
  %t1069 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1070 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1071 = load i64, i64* %t1070
  %t1072 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1073 = load i64, i64* %t1072
  %t1074 = icmp sge i64 %t1073, 2
  br i1 %t1074, label %ring_push_full_186, label %ring_push_grow_187
ring_push_grow_187:
  %t1075 = add i64 %t1071, %t1073
  %t1076 = urem i64 %t1075, 2
  %t1077 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1069, i32 0, i64 %t1076
  store i8* %t1067, i8** %t1077
  %t1078 = add i64 %t1073, 1
  store i64 %t1078, i64* %t1072
  br label %ring_push_done_188
ring_push_full_186:
  %t1079 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1069, i32 0, i64 %t1071
  %t1080 = load i8*, i8** %t1079
  call void @star_rc_release(i8* %t1080)
  store i8* %t1067, i8** %t1079
  %t1081 = add i64 %t1071, 1
  %t1082 = urem i64 %t1081, 2
  store i64 %t1082, i64* %t1070
  br label %ring_push_done_188
ring_push_done_188:
  store i8* null, i8** %t1083
  %t1084 = load i8*, i8** %t1083
  %t1085 = icmp eq i8* %t1084, null
  br i1 %t1085, label %table_cow_alloc_189, label %table_cow_check_190
table_cow_alloc_189:
  %t1086 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1087 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1088 = ptrtoint { i64, i64, i32* }* %t1087 to i64
  %t1089 = call i8* @star_rc_alloc(i64 %t1088, i8* %t1086)
  %t1090 = bitcast i8* %t1089 to { i64, i64, i32* }*
  %t1091 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1090, i32 0, i32 0
  store i64 0, i64* %t1091
  %t1092 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1090, i32 0, i32 1
  store i64 0, i64* %t1092
  %t1093 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1090, i32 0, i32 2
  store i32* null, i32** %t1093
  store i8* %t1089, i8** %t1083
  br label %table_cow_done_191
table_cow_check_190:
  %t1094 = getelementptr inbounds i8, i8* %t1084, i64 -16
  %t1095 = bitcast i8* %t1094 to i64*
  %t1096 = load atomic i64, i64* %t1095 seq_cst, align 8
  %t1097 = icmp eq i64 %t1096, 1
  br i1 %t1097, label %table_cow_done_191, label %table_cow_clone_192
table_cow_clone_192:
  %t1098 = bitcast i8* %t1084 to { i64, i64, i32* }*
  %t1099 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1098, i32 0, i32 0
  %t1100 = load i64, i64* %t1099
  %t1101 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1098, i32 0, i32 1
  %t1102 = load i64, i64* %t1101
  %t1103 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1104 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1105 = ptrtoint { i64, i64, i32* }* %t1104 to i64
  %t1106 = call i8* @star_rc_alloc(i64 %t1105, i8* %t1103)
  %t1107 = bitcast i8* %t1106 to { i64, i64, i32* }*
  %t1108 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1107, i32 0, i32 0
  store i64 %t1100, i64* %t1108
  %t1109 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1107, i32 0, i32 1
  store i64 %t1102, i64* %t1109
  %t1110 = getelementptr i32, i32* null, i32 1
  %t1111 = ptrtoint i32* %t1110 to i64
  %t1112 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1098, i32 0, i32 2
  %t1113 = load i32*, i32** %t1112
  %t1114 = mul i64 %t1102, %t1111
  %t1115 = call i8* @malloc(i64 %t1114)
  %t1116 = bitcast i8* %t1115 to i32*
  %t1117 = icmp sgt i64 %t1100, 0
  br i1 %t1117, label %table_cow_copy_193, label %table_cow_after_copy_194
table_cow_copy_193:
  %t1118 = mul i64 %t1100, %t1111
  %t1119 = bitcast i32* %t1113 to i8*
  call i8* @memcpy(i8* %t1115, i8* %t1119, i64 %t1118)
  br label %table_cow_after_copy_194
table_cow_after_copy_194:
  %t1120 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1107, i32 0, i32 2
  store i32* %t1116, i32** %t1120
  call void @star_rc_release(i8* %t1084)
  store i8* %t1106, i8** %t1083
  br label %table_cow_done_191
table_cow_done_191:
  %t1121 = load i8*, i8** %t1083
  %t1122 = bitcast i8* %t1121 to { i64, i64, i32* }*
  %t1123 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1122, i32 0, i32 0
  %t1124 = load i64, i64* %t1123
  %t1125 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1122, i32 0, i32 1
  %t1126 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1122, i32 0, i32 2
  %t1127 = load i32*, i32** %t1126
  %t1129 = getelementptr inbounds %Item, %Item* %t1128, i32 0, i32 0
  store i32 2, i32* %t1129
  %t1130 = load %Item, %Item* %t1128
  %t1131 = load i64, i64* %t1125
  %t1132 = load i64, i64* %t1123
  %t1133 = load i32*, i32** %t1126
  %t1134 = icmp sge i64 %t1132, %t1131
  br i1 %t1134, label %table_push_grow_195, label %table_push_store_196
table_push_grow_195:
  %t1135 = mul i64 %t1131, 2
  %t1136 = icmp sgt i64 %t1135, 0
  %t1137 = select i1 %t1136, i64 %t1135, i64 1
  %t1138 = getelementptr i32, i32* null, i32 1
  %t1139 = ptrtoint i32* %t1138 to i64
  %t1140 = mul i64 %t1137, %t1139
  %t1141 = call i8* @malloc(i64 %t1140)
  %t1142 = bitcast i8* %t1141 to i32*
  %t1143 = icmp sgt i64 %t1131, 0
  br i1 %t1143, label %table_push_copy_197, label %table_push_after_copy_198
table_push_copy_197:
  %t1144 = mul i64 %t1132, %t1139
  %t1145 = bitcast i32* %t1133 to i8*
  call i8* @memcpy(i8* %t1141, i8* %t1145, i64 %t1144)
  call void @free(i8* %t1145)
  br label %table_push_after_copy_198
table_push_after_copy_198:
  store i32* %t1142, i32** %t1126
  store i64 %t1137, i64* %t1125
  br label %table_push_store_196
table_push_store_196:
  %t1146 = load i32*, i32** %t1126
  %t1147 = extractvalue %Item %t1130, 0
  %t1148 = getelementptr inbounds i32, i32* %t1146, i64 %t1132
  store i32 %t1147, i32* %t1148
  %t1149 = add i64 %t1132, 1
  store i64 %t1149, i64* %t1123
  %t1150 = load i8*, i8** %t1083
  %t1151 = icmp eq i8* %t1150, null
  br i1 %t1151, label %table_cow_alloc_199, label %table_cow_check_200
table_cow_alloc_199:
  %t1152 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1153 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1154 = ptrtoint { i64, i64, i32* }* %t1153 to i64
  %t1155 = call i8* @star_rc_alloc(i64 %t1154, i8* %t1152)
  %t1156 = bitcast i8* %t1155 to { i64, i64, i32* }*
  %t1157 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1156, i32 0, i32 0
  store i64 0, i64* %t1157
  %t1158 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1156, i32 0, i32 1
  store i64 0, i64* %t1158
  %t1159 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1156, i32 0, i32 2
  store i32* null, i32** %t1159
  store i8* %t1155, i8** %t1083
  br label %table_cow_done_201
table_cow_check_200:
  %t1160 = getelementptr inbounds i8, i8* %t1150, i64 -16
  %t1161 = bitcast i8* %t1160 to i64*
  %t1162 = load atomic i64, i64* %t1161 seq_cst, align 8
  %t1163 = icmp eq i64 %t1162, 1
  br i1 %t1163, label %table_cow_done_201, label %table_cow_clone_202
table_cow_clone_202:
  %t1164 = bitcast i8* %t1150 to { i64, i64, i32* }*
  %t1165 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1164, i32 0, i32 0
  %t1166 = load i64, i64* %t1165
  %t1167 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1164, i32 0, i32 1
  %t1168 = load i64, i64* %t1167
  %t1169 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1170 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1171 = ptrtoint { i64, i64, i32* }* %t1170 to i64
  %t1172 = call i8* @star_rc_alloc(i64 %t1171, i8* %t1169)
  %t1173 = bitcast i8* %t1172 to { i64, i64, i32* }*
  %t1174 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1173, i32 0, i32 0
  store i64 %t1166, i64* %t1174
  %t1175 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1173, i32 0, i32 1
  store i64 %t1168, i64* %t1175
  %t1176 = getelementptr i32, i32* null, i32 1
  %t1177 = ptrtoint i32* %t1176 to i64
  %t1178 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1164, i32 0, i32 2
  %t1179 = load i32*, i32** %t1178
  %t1180 = mul i64 %t1168, %t1177
  %t1181 = call i8* @malloc(i64 %t1180)
  %t1182 = bitcast i8* %t1181 to i32*
  %t1183 = icmp sgt i64 %t1166, 0
  br i1 %t1183, label %table_cow_copy_203, label %table_cow_after_copy_204
table_cow_copy_203:
  %t1184 = mul i64 %t1166, %t1177
  %t1185 = bitcast i32* %t1179 to i8*
  call i8* @memcpy(i8* %t1181, i8* %t1185, i64 %t1184)
  br label %table_cow_after_copy_204
table_cow_after_copy_204:
  %t1186 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1173, i32 0, i32 2
  store i32* %t1182, i32** %t1186
  call void @star_rc_release(i8* %t1150)
  store i8* %t1172, i8** %t1083
  br label %table_cow_done_201
table_cow_done_201:
  %t1187 = load i8*, i8** %t1083
  %t1188 = bitcast i8* %t1187 to { i64, i64, i32* }*
  %t1189 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1188, i32 0, i32 0
  %t1190 = load i64, i64* %t1189
  %t1191 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1188, i32 0, i32 1
  %t1192 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1188, i32 0, i32 2
  %t1193 = load i32*, i32** %t1192
  %t1195 = getelementptr inbounds %Item, %Item* %t1194, i32 0, i32 0
  store i32 3, i32* %t1195
  %t1196 = load %Item, %Item* %t1194
  %t1197 = load i64, i64* %t1191
  %t1198 = load i64, i64* %t1189
  %t1199 = load i32*, i32** %t1192
  %t1200 = icmp sge i64 %t1198, %t1197
  br i1 %t1200, label %table_push_grow_205, label %table_push_store_206
table_push_grow_205:
  %t1201 = mul i64 %t1197, 2
  %t1202 = icmp sgt i64 %t1201, 0
  %t1203 = select i1 %t1202, i64 %t1201, i64 1
  %t1204 = getelementptr i32, i32* null, i32 1
  %t1205 = ptrtoint i32* %t1204 to i64
  %t1206 = mul i64 %t1203, %t1205
  %t1207 = call i8* @malloc(i64 %t1206)
  %t1208 = bitcast i8* %t1207 to i32*
  %t1209 = icmp sgt i64 %t1197, 0
  br i1 %t1209, label %table_push_copy_207, label %table_push_after_copy_208
table_push_copy_207:
  %t1210 = mul i64 %t1198, %t1205
  %t1211 = bitcast i32* %t1199 to i8*
  call i8* @memcpy(i8* %t1207, i8* %t1211, i64 %t1210)
  call void @free(i8* %t1211)
  br label %table_push_after_copy_208
table_push_after_copy_208:
  store i32* %t1208, i32** %t1192
  store i64 %t1203, i64* %t1191
  br label %table_push_store_206
table_push_store_206:
  %t1212 = load i32*, i32** %t1192
  %t1213 = extractvalue %Item %t1196, 0
  %t1214 = getelementptr inbounds i32, i32* %t1212, i64 %t1198
  store i32 %t1213, i32* %t1214
  %t1215 = add i64 %t1198, 1
  store i64 %t1215, i64* %t1189
  %t1216 = load i8*, i8** %t1083
  %t1217 = load i8*, i8** %t1083
  call void @star_rc_retain(i8* %t1217)
  %t1218 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1219 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1220 = load i64, i64* %t1219
  %t1221 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1222 = load i64, i64* %t1221
  %t1223 = icmp sge i64 %t1222, 2
  br i1 %t1223, label %ring_push_full_209, label %ring_push_grow_210
ring_push_grow_210:
  %t1224 = add i64 %t1220, %t1222
  %t1225 = urem i64 %t1224, 2
  %t1226 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1218, i32 0, i64 %t1225
  store i8* %t1216, i8** %t1226
  %t1227 = add i64 %t1222, 1
  store i64 %t1227, i64* %t1221
  br label %ring_push_done_211
ring_push_full_209:
  %t1228 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1218, i32 0, i64 %t1220
  %t1229 = load i8*, i8** %t1228
  call void @star_rc_release(i8* %t1229)
  store i8* %t1216, i8** %t1228
  %t1230 = add i64 %t1220, 1
  %t1231 = urem i64 %t1230, 2
  store i64 %t1231, i64* %t1219
  br label %ring_push_done_211
ring_push_done_211:
  %t1232 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1233 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1234 = load i64, i64* %t1233
  %t1235 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1236 = load i64, i64* %t1235
  %t1237 = trunc i64 %t1236 to i32
  %t1238 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1239 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1240 = load i64, i64* %t1239
  %t1241 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1242 = load i64, i64* %t1241
  %t1243 = sext i32 0 to i64
  %t1244 = load i64, i64* %t1239
  %t1245 = load i64, i64* %t1241
  %t1246 = icmp ult i64 %t1243, %t1245
  br i1 %t1246, label %ring_rplace_ok_212, label %ring_rplace_oob_213
ring_rplace_ok_212:
  %t1247 = add i64 %t1244, %t1243
  %t1248 = urem i64 %t1247, 2
  %t1249 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1238, i32 0, i64 %t1248
  br label %ring_rplace_end_214
ring_rplace_oob_213:
  store i8* null, i8** %t1250
  br label %ring_rplace_end_214
ring_rplace_end_214:
  %t1251 = phi i8** [ %t1249, %ring_rplace_ok_212 ], [ %t1250, %ring_rplace_oob_213 ]
  %t1252 = load i8*, i8** %t1251
  %t1253 = icmp eq i8* %t1252, null
  br i1 %t1253, label %table_read_null_215, label %table_read_real_216
table_read_null_215:
  br label %table_read_end_217
table_read_real_216:
  %t1254 = bitcast i8* %t1252 to { i64, i64, i32* }*
  %t1255 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1254, i32 0, i32 0
  %t1256 = load i64, i64* %t1255
  %t1257 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1254, i32 0, i32 2
  %t1258 = load i32*, i32** %t1257
  br label %table_read_end_217
table_read_end_217:
  %t1259 = phi i64 [ 0, %table_read_null_215 ], [ %t1256, %table_read_real_216 ]
  %t1260 = phi i32* [ null, %table_read_null_215 ], [ %t1258, %table_read_real_216 ]
  %t1261 = trunc i64 %t1259 to i32
  %t1262 = sext i32 0 to i64
  %t1263 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1264 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1265 = load i64, i64* %t1264
  %t1266 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1267 = load i64, i64* %t1266
  %t1268 = sext i32 0 to i64
  %t1269 = load i64, i64* %t1264
  %t1270 = load i64, i64* %t1266
  %t1271 = icmp ult i64 %t1268, %t1270
  br i1 %t1271, label %ring_rplace_ok_218, label %ring_rplace_oob_219
ring_rplace_ok_218:
  %t1272 = add i64 %t1269, %t1268
  %t1273 = urem i64 %t1272, 2
  %t1274 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1263, i32 0, i64 %t1273
  br label %ring_rplace_end_220
ring_rplace_oob_219:
  store i8* null, i8** %t1275
  br label %ring_rplace_end_220
ring_rplace_end_220:
  %t1276 = phi i8** [ %t1274, %ring_rplace_ok_218 ], [ %t1275, %ring_rplace_oob_219 ]
  %t1277 = load i8*, i8** %t1276
  %t1278 = icmp eq i8* %t1277, null
  br i1 %t1278, label %table_read_null_221, label %table_read_real_222
table_read_null_221:
  br label %table_read_end_223
table_read_real_222:
  %t1279 = bitcast i8* %t1277 to { i64, i64, i32* }*
  %t1280 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1279, i32 0, i32 0
  %t1281 = load i64, i64* %t1280
  %t1282 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1279, i32 0, i32 2
  %t1283 = load i32*, i32** %t1282
  br label %table_read_end_223
table_read_end_223:
  %t1284 = phi i64 [ 0, %table_read_null_221 ], [ %t1281, %table_read_real_222 ]
  %t1285 = phi i32* [ null, %table_read_null_221 ], [ %t1283, %table_read_real_222 ]
  %t1287 = icmp ult i64 %t1262, %t1284
  br i1 %t1287, label %table_idx_ok_224, label %table_idx_oob_225
table_idx_ok_224:
  %t1288 = getelementptr inbounds i32, i32* %t1285, i64 %t1262
  %t1289 = load i32, i32* %t1288
  %t1290 = getelementptr inbounds %Item, %Item* %t1286, i32 0, i32 0
  store i32 %t1289, i32* %t1290
  br label %table_idx_end_226
table_idx_oob_225:
  store %Item zeroinitializer, %Item* %t1286
  br label %table_idx_end_226
table_idx_end_226:
  %t1291 = load %Item, %Item* %t1286
  store %Item %t1291, %Item* %t1292
  %t1293 = getelementptr inbounds %Item, %Item* %t1292, i32 0, i32 0
  %t1294 = load i32, i32* %t1293
  %t1295 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1295, i32 %t1237, i32 %t1261, i32 %t1294)
  %t1296 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1297 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1298 = load i64, i64* %t1297
  %t1299 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1300 = load i64, i64* %t1299
  %t1301 = sext i32 1 to i64
  %t1302 = load i64, i64* %t1297
  %t1303 = load i64, i64* %t1299
  %t1304 = icmp ult i64 %t1301, %t1303
  br i1 %t1304, label %ring_rplace_ok_227, label %ring_rplace_oob_228
ring_rplace_ok_227:
  %t1305 = add i64 %t1302, %t1301
  %t1306 = urem i64 %t1305, 2
  %t1307 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1296, i32 0, i64 %t1306
  br label %ring_rplace_end_229
ring_rplace_oob_228:
  store i8* null, i8** %t1308
  br label %ring_rplace_end_229
ring_rplace_end_229:
  %t1309 = phi i8** [ %t1307, %ring_rplace_ok_227 ], [ %t1308, %ring_rplace_oob_228 ]
  %t1310 = load i8*, i8** %t1309
  %t1311 = icmp eq i8* %t1310, null
  br i1 %t1311, label %table_read_null_230, label %table_read_real_231
table_read_null_230:
  br label %table_read_end_232
table_read_real_231:
  %t1312 = bitcast i8* %t1310 to { i64, i64, i32* }*
  %t1313 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1312, i32 0, i32 0
  %t1314 = load i64, i64* %t1313
  %t1315 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1312, i32 0, i32 2
  %t1316 = load i32*, i32** %t1315
  br label %table_read_end_232
table_read_end_232:
  %t1317 = phi i64 [ 0, %table_read_null_230 ], [ %t1314, %table_read_real_231 ]
  %t1318 = phi i32* [ null, %table_read_null_230 ], [ %t1316, %table_read_real_231 ]
  %t1319 = trunc i64 %t1317 to i32
  %t1320 = sext i32 0 to i64
  %t1321 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1322 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1323 = load i64, i64* %t1322
  %t1324 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1325 = load i64, i64* %t1324
  %t1326 = sext i32 1 to i64
  %t1327 = load i64, i64* %t1322
  %t1328 = load i64, i64* %t1324
  %t1329 = icmp ult i64 %t1326, %t1328
  br i1 %t1329, label %ring_rplace_ok_233, label %ring_rplace_oob_234
ring_rplace_ok_233:
  %t1330 = add i64 %t1327, %t1326
  %t1331 = urem i64 %t1330, 2
  %t1332 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1321, i32 0, i64 %t1331
  br label %ring_rplace_end_235
ring_rplace_oob_234:
  store i8* null, i8** %t1333
  br label %ring_rplace_end_235
ring_rplace_end_235:
  %t1334 = phi i8** [ %t1332, %ring_rplace_ok_233 ], [ %t1333, %ring_rplace_oob_234 ]
  %t1335 = load i8*, i8** %t1334
  %t1336 = icmp eq i8* %t1335, null
  br i1 %t1336, label %table_read_null_236, label %table_read_real_237
table_read_null_236:
  br label %table_read_end_238
table_read_real_237:
  %t1337 = bitcast i8* %t1335 to { i64, i64, i32* }*
  %t1338 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1337, i32 0, i32 0
  %t1339 = load i64, i64* %t1338
  %t1340 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1337, i32 0, i32 2
  %t1341 = load i32*, i32** %t1340
  br label %table_read_end_238
table_read_end_238:
  %t1342 = phi i64 [ 0, %table_read_null_236 ], [ %t1339, %table_read_real_237 ]
  %t1343 = phi i32* [ null, %table_read_null_236 ], [ %t1341, %table_read_real_237 ]
  %t1345 = icmp ult i64 %t1320, %t1342
  br i1 %t1345, label %table_idx_ok_239, label %table_idx_oob_240
table_idx_ok_239:
  %t1346 = getelementptr inbounds i32, i32* %t1343, i64 %t1320
  %t1347 = load i32, i32* %t1346
  %t1348 = getelementptr inbounds %Item, %Item* %t1344, i32 0, i32 0
  store i32 %t1347, i32* %t1348
  br label %table_idx_end_241
table_idx_oob_240:
  store %Item zeroinitializer, %Item* %t1344
  br label %table_idx_end_241
table_idx_end_241:
  %t1349 = load %Item, %Item* %t1344
  store %Item %t1349, %Item* %t1350
  %t1351 = getelementptr inbounds %Item, %Item* %t1350, i32 0, i32 0
  %t1352 = load i32, i32* %t1351
  %t1353 = sext i32 1 to i64
  %t1354 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1355 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1356 = load i64, i64* %t1355
  %t1357 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1358 = load i64, i64* %t1357
  %t1359 = sext i32 1 to i64
  %t1360 = load i64, i64* %t1355
  %t1361 = load i64, i64* %t1357
  %t1362 = icmp ult i64 %t1359, %t1361
  br i1 %t1362, label %ring_rplace_ok_242, label %ring_rplace_oob_243
ring_rplace_ok_242:
  %t1363 = add i64 %t1360, %t1359
  %t1364 = urem i64 %t1363, 2
  %t1365 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1354, i32 0, i64 %t1364
  br label %ring_rplace_end_244
ring_rplace_oob_243:
  store i8* null, i8** %t1366
  br label %ring_rplace_end_244
ring_rplace_end_244:
  %t1367 = phi i8** [ %t1365, %ring_rplace_ok_242 ], [ %t1366, %ring_rplace_oob_243 ]
  %t1368 = load i8*, i8** %t1367
  %t1369 = icmp eq i8* %t1368, null
  br i1 %t1369, label %table_read_null_245, label %table_read_real_246
table_read_null_245:
  br label %table_read_end_247
table_read_real_246:
  %t1370 = bitcast i8* %t1368 to { i64, i64, i32* }*
  %t1371 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1370, i32 0, i32 0
  %t1372 = load i64, i64* %t1371
  %t1373 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1370, i32 0, i32 2
  %t1374 = load i32*, i32** %t1373
  br label %table_read_end_247
table_read_end_247:
  %t1375 = phi i64 [ 0, %table_read_null_245 ], [ %t1372, %table_read_real_246 ]
  %t1376 = phi i32* [ null, %table_read_null_245 ], [ %t1374, %table_read_real_246 ]
  %t1378 = icmp ult i64 %t1353, %t1375
  br i1 %t1378, label %table_idx_ok_248, label %table_idx_oob_249
table_idx_ok_248:
  %t1379 = getelementptr inbounds i32, i32* %t1376, i64 %t1353
  %t1380 = load i32, i32* %t1379
  %t1381 = getelementptr inbounds %Item, %Item* %t1377, i32 0, i32 0
  store i32 %t1380, i32* %t1381
  br label %table_idx_end_250
table_idx_oob_249:
  store %Item zeroinitializer, %Item* %t1377
  br label %table_idx_end_250
table_idx_end_250:
  %t1382 = load %Item, %Item* %t1377
  store %Item %t1382, %Item* %t1383
  %t1384 = getelementptr inbounds %Item, %Item* %t1383, i32 0, i32 0
  %t1385 = load i32, i32* %t1384
  %t1386 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1386, i32 %t1319, i32 %t1352, i32 %t1385)
  store i8* null, i8** %t1387
  %t1388 = load i8*, i8** %t1387
  %t1389 = icmp eq i8* %t1388, null
  br i1 %t1389, label %table_cow_alloc_251, label %table_cow_check_252
table_cow_alloc_251:
  %t1390 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1391 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1392 = ptrtoint { i64, i64, i32* }* %t1391 to i64
  %t1393 = call i8* @star_rc_alloc(i64 %t1392, i8* %t1390)
  %t1394 = bitcast i8* %t1393 to { i64, i64, i32* }*
  %t1395 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1394, i32 0, i32 0
  store i64 0, i64* %t1395
  %t1396 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1394, i32 0, i32 1
  store i64 0, i64* %t1396
  %t1397 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1394, i32 0, i32 2
  store i32* null, i32** %t1397
  store i8* %t1393, i8** %t1387
  br label %table_cow_done_253
table_cow_check_252:
  %t1398 = getelementptr inbounds i8, i8* %t1388, i64 -16
  %t1399 = bitcast i8* %t1398 to i64*
  %t1400 = load atomic i64, i64* %t1399 seq_cst, align 8
  %t1401 = icmp eq i64 %t1400, 1
  br i1 %t1401, label %table_cow_done_253, label %table_cow_clone_254
table_cow_clone_254:
  %t1402 = bitcast i8* %t1388 to { i64, i64, i32* }*
  %t1403 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1402, i32 0, i32 0
  %t1404 = load i64, i64* %t1403
  %t1405 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1402, i32 0, i32 1
  %t1406 = load i64, i64* %t1405
  %t1407 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1408 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1409 = ptrtoint { i64, i64, i32* }* %t1408 to i64
  %t1410 = call i8* @star_rc_alloc(i64 %t1409, i8* %t1407)
  %t1411 = bitcast i8* %t1410 to { i64, i64, i32* }*
  %t1412 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1411, i32 0, i32 0
  store i64 %t1404, i64* %t1412
  %t1413 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1411, i32 0, i32 1
  store i64 %t1406, i64* %t1413
  %t1414 = getelementptr i32, i32* null, i32 1
  %t1415 = ptrtoint i32* %t1414 to i64
  %t1416 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1402, i32 0, i32 2
  %t1417 = load i32*, i32** %t1416
  %t1418 = mul i64 %t1406, %t1415
  %t1419 = call i8* @malloc(i64 %t1418)
  %t1420 = bitcast i8* %t1419 to i32*
  %t1421 = icmp sgt i64 %t1404, 0
  br i1 %t1421, label %table_cow_copy_255, label %table_cow_after_copy_256
table_cow_copy_255:
  %t1422 = mul i64 %t1404, %t1415
  %t1423 = bitcast i32* %t1417 to i8*
  call i8* @memcpy(i8* %t1419, i8* %t1423, i64 %t1422)
  br label %table_cow_after_copy_256
table_cow_after_copy_256:
  %t1424 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1411, i32 0, i32 2
  store i32* %t1420, i32** %t1424
  call void @star_rc_release(i8* %t1388)
  store i8* %t1410, i8** %t1387
  br label %table_cow_done_253
table_cow_done_253:
  %t1425 = load i8*, i8** %t1387
  %t1426 = bitcast i8* %t1425 to { i64, i64, i32* }*
  %t1427 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1426, i32 0, i32 0
  %t1428 = load i64, i64* %t1427
  %t1429 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1426, i32 0, i32 1
  %t1430 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1426, i32 0, i32 2
  %t1431 = load i32*, i32** %t1430
  %t1433 = getelementptr inbounds %Item, %Item* %t1432, i32 0, i32 0
  store i32 9, i32* %t1433
  %t1434 = load %Item, %Item* %t1432
  %t1435 = load i64, i64* %t1429
  %t1436 = load i64, i64* %t1427
  %t1437 = load i32*, i32** %t1430
  %t1438 = icmp sge i64 %t1436, %t1435
  br i1 %t1438, label %table_push_grow_257, label %table_push_store_258
table_push_grow_257:
  %t1439 = mul i64 %t1435, 2
  %t1440 = icmp sgt i64 %t1439, 0
  %t1441 = select i1 %t1440, i64 %t1439, i64 1
  %t1442 = getelementptr i32, i32* null, i32 1
  %t1443 = ptrtoint i32* %t1442 to i64
  %t1444 = mul i64 %t1441, %t1443
  %t1445 = call i8* @malloc(i64 %t1444)
  %t1446 = bitcast i8* %t1445 to i32*
  %t1447 = icmp sgt i64 %t1435, 0
  br i1 %t1447, label %table_push_copy_259, label %table_push_after_copy_260
table_push_copy_259:
  %t1448 = mul i64 %t1436, %t1443
  %t1449 = bitcast i32* %t1437 to i8*
  call i8* @memcpy(i8* %t1445, i8* %t1449, i64 %t1448)
  call void @free(i8* %t1449)
  br label %table_push_after_copy_260
table_push_after_copy_260:
  store i32* %t1446, i32** %t1430
  store i64 %t1441, i64* %t1429
  br label %table_push_store_258
table_push_store_258:
  %t1450 = load i32*, i32** %t1430
  %t1451 = extractvalue %Item %t1434, 0
  %t1452 = getelementptr inbounds i32, i32* %t1450, i64 %t1436
  store i32 %t1451, i32* %t1452
  %t1453 = add i64 %t1436, 1
  store i64 %t1453, i64* %t1427
  %t1454 = load i8*, i8** %t1387
  %t1455 = load i8*, i8** %t1387
  call void @star_rc_retain(i8* %t1455)
  %t1456 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1457 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1458 = load i64, i64* %t1457
  %t1459 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1460 = load i64, i64* %t1459
  %t1461 = icmp sge i64 %t1460, 2
  br i1 %t1461, label %ring_push_full_261, label %ring_push_grow_262
ring_push_grow_262:
  %t1462 = add i64 %t1458, %t1460
  %t1463 = urem i64 %t1462, 2
  %t1464 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1456, i32 0, i64 %t1463
  store i8* %t1454, i8** %t1464
  %t1465 = add i64 %t1460, 1
  store i64 %t1465, i64* %t1459
  br label %ring_push_done_263
ring_push_full_261:
  %t1466 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1456, i32 0, i64 %t1458
  %t1467 = load i8*, i8** %t1466
  call void @star_rc_release(i8* %t1467)
  store i8* %t1454, i8** %t1466
  %t1468 = add i64 %t1458, 1
  %t1469 = urem i64 %t1468, 2
  store i64 %t1469, i64* %t1457
  br label %ring_push_done_263
ring_push_done_263:
  %t1470 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1471 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1472 = load i64, i64* %t1471
  %t1473 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1474 = load i64, i64* %t1473
  %t1475 = trunc i64 %t1474 to i32
  %t1476 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1477 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1478 = load i64, i64* %t1477
  %t1479 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1480 = load i64, i64* %t1479
  %t1481 = sext i32 0 to i64
  %t1482 = load i64, i64* %t1477
  %t1483 = load i64, i64* %t1479
  %t1484 = icmp ult i64 %t1481, %t1483
  br i1 %t1484, label %ring_rplace_ok_264, label %ring_rplace_oob_265
ring_rplace_ok_264:
  %t1485 = add i64 %t1482, %t1481
  %t1486 = urem i64 %t1485, 2
  %t1487 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1476, i32 0, i64 %t1486
  br label %ring_rplace_end_266
ring_rplace_oob_265:
  store i8* null, i8** %t1488
  br label %ring_rplace_end_266
ring_rplace_end_266:
  %t1489 = phi i8** [ %t1487, %ring_rplace_ok_264 ], [ %t1488, %ring_rplace_oob_265 ]
  %t1490 = load i8*, i8** %t1489
  %t1491 = icmp eq i8* %t1490, null
  br i1 %t1491, label %table_read_null_267, label %table_read_real_268
table_read_null_267:
  br label %table_read_end_269
table_read_real_268:
  %t1492 = bitcast i8* %t1490 to { i64, i64, i32* }*
  %t1493 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1492, i32 0, i32 0
  %t1494 = load i64, i64* %t1493
  %t1495 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1492, i32 0, i32 2
  %t1496 = load i32*, i32** %t1495
  br label %table_read_end_269
table_read_end_269:
  %t1497 = phi i64 [ 0, %table_read_null_267 ], [ %t1494, %table_read_real_268 ]
  %t1498 = phi i32* [ null, %table_read_null_267 ], [ %t1496, %table_read_real_268 ]
  %t1499 = trunc i64 %t1497 to i32
  %t1500 = sext i32 0 to i64
  %t1501 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1502 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 1
  %t1503 = load i64, i64* %t1502
  %t1504 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 2
  %t1505 = load i64, i64* %t1504
  %t1506 = sext i32 0 to i64
  %t1507 = load i64, i64* %t1502
  %t1508 = load i64, i64* %t1504
  %t1509 = icmp ult i64 %t1506, %t1508
  br i1 %t1509, label %ring_rplace_ok_270, label %ring_rplace_oob_271
ring_rplace_ok_270:
  %t1510 = add i64 %t1507, %t1506
  %t1511 = urem i64 %t1510, 2
  %t1512 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1501, i32 0, i64 %t1511
  br label %ring_rplace_end_272
ring_rplace_oob_271:
  store i8* null, i8** %t1513
  br label %ring_rplace_end_272
ring_rplace_end_272:
  %t1514 = phi i8** [ %t1512, %ring_rplace_ok_270 ], [ %t1513, %ring_rplace_oob_271 ]
  %t1515 = load i8*, i8** %t1514
  %t1516 = icmp eq i8* %t1515, null
  br i1 %t1516, label %table_read_null_273, label %table_read_real_274
table_read_null_273:
  br label %table_read_end_275
table_read_real_274:
  %t1517 = bitcast i8* %t1515 to { i64, i64, i32* }*
  %t1518 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1517, i32 0, i32 0
  %t1519 = load i64, i64* %t1518
  %t1520 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1517, i32 0, i32 2
  %t1521 = load i32*, i32** %t1520
  br label %table_read_end_275
table_read_end_275:
  %t1522 = phi i64 [ 0, %table_read_null_273 ], [ %t1519, %table_read_real_274 ]
  %t1523 = phi i32* [ null, %table_read_null_273 ], [ %t1521, %table_read_real_274 ]
  %t1525 = icmp ult i64 %t1500, %t1522
  br i1 %t1525, label %table_idx_ok_276, label %table_idx_oob_277
table_idx_ok_276:
  %t1526 = getelementptr inbounds i32, i32* %t1523, i64 %t1500
  %t1527 = load i32, i32* %t1526
  %t1528 = getelementptr inbounds %Item, %Item* %t1524, i32 0, i32 0
  store i32 %t1527, i32* %t1528
  br label %table_idx_end_278
table_idx_oob_277:
  store %Item zeroinitializer, %Item* %t1524
  br label %table_idx_end_278
table_idx_end_278:
  %t1529 = load %Item, %Item* %t1524
  store %Item %t1529, %Item* %t1530
  %t1531 = getelementptr inbounds %Item, %Item* %t1530, i32 0, i32 0
  %t1532 = load i32, i32* %t1531
  %t1533 = getelementptr inbounds [45 x i8], [45 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1533, i32 %t1475, i32 %t1499, i32 %t1532)
  %t1534 = load i8*, i8** %t1387
  call void @star_rc_release(i8* %t1534)
  %t1535 = load i8*, i8** %t1083
  call void @star_rc_release(i8* %t1535)
  %t1536 = load i8*, i8** %t994
  call void @star_rc_release(i8* %t1536)
  %t1537 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t993, i32 0, i32 0
  %t1538 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1537, i32 0, i64 0
  %t1539 = load i8*, i8** %t1538
  call void @star_rc_release(i8* %t1539)
  %t1540 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1537, i32 0, i64 1
  %t1541 = load i8*, i8** %t1540
  call void @star_rc_release(i8* %t1541)
  %t1542 = getelementptr inbounds %Bag, %Bag* %t904, i32 0, i32 0
  %t1543 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1542, i32 0, i32 0
  %t1544 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1543, i32 0, i64 0
  %t1545 = load i8*, i8** %t1544
  call void @star_rc_release(i8* %t1545)
  %t1546 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1543, i32 0, i64 1
  %t1547 = load i8*, i8** %t1546
  call void @star_rc_release(i8* %t1547)
  %t1548 = load i8*, i8** %t771
  call void @star_rc_release(i8* %t1548)
  %t1549 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t365, i32 0, i32 0
  %t1550 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1549, i32 0, i64 0
  %t1551 = load i8*, i8** %t1550
  call void @star_rc_release(i8* %t1551)
  %t1552 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1549, i32 0, i64 1
  %t1553 = load i8*, i8** %t1552
  call void @star_rc_release(i8* %t1553)
  %t1554 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t206, i32 0, i32 0
  %t1555 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1554, i32 0, i64 0
  %t1556 = load i8*, i8** %t1555
  call void @star_rc_release(i8* %t1556)
  %t1557 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1554, i32 0, i64 1
  %t1558 = load i8*, i8** %t1557
  call void @star_rc_release(i8* %t1558)
  %t1559 = load i8*, i8** %t205
  call void @star_rc_release(i8* %t1559)
  %t1560 = getelementptr inbounds %Snapshot, %Snapshot* %t87, i32 0, i32 2
  %t1561 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1560, i32 0, i32 0
  %t1562 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1561, i32 0, i64 0
  %t1563 = getelementptr inbounds %Player, %Player* %t1562, i32 0, i32 0
  %t1564 = load i8*, i8** %t1563
  call void @star_rc_release(i8* %t1564)
  %t1565 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1561, i32 0, i64 1
  %t1566 = getelementptr inbounds %Player, %Player* %t1565, i32 0, i32 0
  %t1567 = load i8*, i8** %t1566
  call void @star_rc_release(i8* %t1567)
  %t1568 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t1569 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1568, i32 0, i32 0
  %t1570 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1569, i32 0, i64 0
  %t1571 = getelementptr inbounds %Player, %Player* %t1570, i32 0, i32 0
  %t1572 = load i8*, i8** %t1571
  call void @star_rc_release(i8* %t1572)
  %t1573 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1569, i32 0, i64 1
  %t1574 = getelementptr inbounds %Player, %Player* %t1573, i32 0, i32 0
  %t1575 = load i8*, i8** %t1574
  call void @star_rc_release(i8* %t1575)
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
  %t997 = bitcast i8* %objp to { i64, i64, i32* }*
  %t998 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t997, i32 0, i32 0
  %t999 = load i64, i64* %t998
  %t1000 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t997, i32 0, i32 2
  %t1001 = load i32*, i32** %t1000
  %t1002 = bitcast i32* %t1001 to i8*
  call void @free(i8* %t1002)
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
