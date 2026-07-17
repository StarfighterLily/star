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
  %t1 = alloca %Snapshot
  %t25 = alloca i32
  %t41 = alloca i32
  %t65 = alloca %Player
  %t83 = alloca %Player
  %t88 = alloca %Snapshot
  %t146 = alloca i32
  %t162 = alloca i32
  %t186 = alloca i32
  %t202 = alloca i32
  %t206 = alloca i8*
  %t207 = alloca { [2 x i8*], i64, i64 }
  %t294 = alloca i64
  %t325 = alloca %Bag
  %t366 = alloca { [2 x i8*], i64, i64 }
  %t419 = alloca i64
  %t450 = alloca %Bag
  %t518 = alloca %Bag
  %t532 = alloca %Bag
  %t548 = alloca %Bag
  %t562 = alloca %Bag
  %t583 = alloca %Bag
  %t597 = alloca %Bag
  %t611 = alloca i8*
  %t628 = alloca %Bag
  %t642 = alloca %Bag
  %t656 = alloca i8*
  %t674 = alloca %Bag
  %t688 = alloca %Bag
  %t704 = alloca %Bag
  %t718 = alloca %Bag
  %t739 = alloca %Bag
  %t753 = alloca %Bag
  %t767 = alloca i8*
  %t772 = alloca i8*
  %t812 = alloca i64
  %t843 = alloca %Bag
  %t905 = alloca %Bag
  %t943 = alloca i64
  %t974 = alloca %Bag
  %t994 = alloca { [2 x i8*], i64, i64 }
  %t995 = alloca i8*
  %t1046 = alloca %Item
  %t1084 = alloca i8*
  %t1129 = alloca %Item
  %t1195 = alloca %Item
  %t1251 = alloca i8*
  %t1276 = alloca i8*
  %t1287 = alloca %Item
  %t1293 = alloca %Item
  %t1309 = alloca i8*
  %t1334 = alloca i8*
  %t1345 = alloca %Item
  %t1351 = alloca %Item
  %t1367 = alloca i8*
  %t1378 = alloca %Item
  %t1384 = alloca %Item
  %t1388 = alloca i8*
  %t1433 = alloca %Item
  %t1489 = alloca i8*
  %t1514 = alloca i8*
  %t1525 = alloca %Item
  %t1531 = alloca %Item
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = call %Snapshot @make_snapshot()
  store %Snapshot %t2, %Snapshot* %t1
  %t3 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 0
  %t4 = load i32, i32* %t3
  %t5 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 1
  %t6 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t5, i32 0, i32 0
  %t7 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t5, i32 0, i32 1
  %t8 = load i64, i64* %t7
  %t9 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t5, i32 0, i32 2
  %t10 = load i64, i64* %t9
  %t11 = trunc i64 %t10 to i32
  %t12 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 1
  %t13 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t12, i32 0, i32 0
  %t14 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t12, i32 0, i32 1
  %t15 = load i64, i64* %t14
  %t16 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t12, i32 0, i32 2
  %t17 = load i64, i64* %t16
  %t18 = sext i32 0 to i64
  %t19 = load i64, i64* %t14
  %t20 = load i64, i64* %t16
  %t21 = icmp ult i64 %t18, %t20
  br i1 %t21, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t22 = add i64 %t19, %t18
  %t23 = urem i64 %t22, 3
  %t24 = getelementptr inbounds [3 x i32], [3 x i32]* %t13, i32 0, i64 %t23
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t25
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t26 = phi i32* [ %t24, %ring_rplace_ok_9 ], [ %t25, %ring_rplace_oob_10 ]
  %t27 = load i32, i32* %t26
  %t28 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 1
  %t29 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t28, i32 0, i32 0
  %t30 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t28, i32 0, i32 1
  %t31 = load i64, i64* %t30
  %t32 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t28, i32 0, i32 2
  %t33 = load i64, i64* %t32
  %t34 = sext i32 1 to i64
  %t35 = load i64, i64* %t30
  %t36 = load i64, i64* %t32
  %t37 = icmp ult i64 %t34, %t36
  br i1 %t37, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t38 = add i64 %t35, %t34
  %t39 = urem i64 %t38, 3
  %t40 = getelementptr inbounds [3 x i32], [3 x i32]* %t29, i32 0, i64 %t39
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  store i32 0, i32* %t41
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t42 = phi i32* [ %t40, %ring_rplace_ok_12 ], [ %t41, %ring_rplace_oob_13 ]
  %t43 = load i32, i32* %t42
  %t44 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t44, i32 %t4, i32 %t11, i32 %t27, i32 %t43)
  %t45 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 2
  %t46 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t45, i32 0, i32 0
  %t47 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t45, i32 0, i32 1
  %t48 = load i64, i64* %t47
  %t49 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t45, i32 0, i32 2
  %t50 = load i64, i64* %t49
  %t51 = trunc i64 %t50 to i32
  %t52 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 2
  %t53 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t52, i32 0, i32 0
  %t54 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t52, i32 0, i32 1
  %t55 = load i64, i64* %t54
  %t56 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t52, i32 0, i32 2
  %t57 = load i64, i64* %t56
  %t58 = sext i32 0 to i64
  %t59 = load i64, i64* %t54
  %t60 = load i64, i64* %t56
  %t61 = icmp ult i64 %t58, %t60
  br i1 %t61, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t62 = add i64 %t59, %t58
  %t63 = urem i64 %t62, 2
  %t64 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t53, i32 0, i64 %t63
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  store %Player zeroinitializer, %Player* %t65
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t66 = phi %Player* [ %t64, %ring_rplace_ok_15 ], [ %t65, %ring_rplace_oob_16 ]
  %t67 = getelementptr inbounds %Player, %Player* %t66, i32 0, i32 0
  %t68 = load i8*, i8** %t67
  %t69 = load i8*, i8** %t67
  call void @star_rc_retain(i8* %t69)
  call void @star_rc_release(i8* %t68)
  %t70 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 2
  %t71 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t70, i32 0, i32 0
  %t72 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t70, i32 0, i32 1
  %t73 = load i64, i64* %t72
  %t74 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t70, i32 0, i32 2
  %t75 = load i64, i64* %t74
  %t76 = sext i32 0 to i64
  %t77 = load i64, i64* %t72
  %t78 = load i64, i64* %t74
  %t79 = icmp ult i64 %t76, %t78
  br i1 %t79, label %ring_rplace_ok_18, label %ring_rplace_oob_19
ring_rplace_ok_18:
  %t80 = add i64 %t77, %t76
  %t81 = urem i64 %t80, 2
  %t82 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t71, i32 0, i64 %t81
  br label %ring_rplace_end_20
ring_rplace_oob_19:
  store %Player zeroinitializer, %Player* %t83
  br label %ring_rplace_end_20
ring_rplace_end_20:
  %t84 = phi %Player* [ %t82, %ring_rplace_ok_18 ], [ %t83, %ring_rplace_oob_19 ]
  %t85 = getelementptr inbounds %Player, %Player* %t84, i32 0, i32 1
  %t86 = load i32, i32* %t85
  %t87 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t87, i32 %t51, i8* %t68, i32 %t86)
  %t89 = load %Snapshot, %Snapshot* %t1
  %t90 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 2
  %t91 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t90, i32 0, i32 0
  %t92 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t91, i32 0, i64 0
  %t93 = getelementptr inbounds %Player, %Player* %t92, i32 0, i32 0
  %t94 = load i8*, i8** %t93
  call void @star_rc_retain(i8* %t94)
  %t95 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t91, i32 0, i64 1
  %t96 = getelementptr inbounds %Player, %Player* %t95, i32 0, i32 0
  %t97 = load i8*, i8** %t96
  call void @star_rc_retain(i8* %t97)
  store %Snapshot %t89, %Snapshot* %t88
  %t98 = getelementptr inbounds %Snapshot, %Snapshot* %t88, i32 0, i32 1
  %t99 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t98, i32 0, i32 0
  %t100 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t98, i32 0, i32 1
  %t101 = load i64, i64* %t100
  %t102 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t98, i32 0, i32 2
  %t103 = load i64, i64* %t102
  %t104 = icmp sge i64 %t103, 3
  br i1 %t104, label %ring_push_full_21, label %ring_push_grow_22
ring_push_grow_22:
  %t105 = add i64 %t101, %t103
  %t106 = urem i64 %t105, 3
  %t107 = getelementptr inbounds [3 x i32], [3 x i32]* %t99, i32 0, i64 %t106
  store i32 3, i32* %t107
  %t108 = add i64 %t103, 1
  store i64 %t108, i64* %t102
  br label %ring_push_done_23
ring_push_full_21:
  %t109 = getelementptr inbounds [3 x i32], [3 x i32]* %t99, i32 0, i64 %t101
  store i32 3, i32* %t109
  %t110 = add i64 %t101, 1
  %t111 = urem i64 %t110, 3
  store i64 %t111, i64* %t100
  br label %ring_push_done_23
ring_push_done_23:
  %t112 = getelementptr inbounds %Snapshot, %Snapshot* %t88, i32 0, i32 1
  %t113 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t112, i32 0, i32 0
  %t114 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t112, i32 0, i32 1
  %t115 = load i64, i64* %t114
  %t116 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t112, i32 0, i32 2
  %t117 = load i64, i64* %t116
  %t118 = icmp sge i64 %t117, 3
  br i1 %t118, label %ring_push_full_24, label %ring_push_grow_25
ring_push_grow_25:
  %t119 = add i64 %t115, %t117
  %t120 = urem i64 %t119, 3
  %t121 = getelementptr inbounds [3 x i32], [3 x i32]* %t113, i32 0, i64 %t120
  store i32 4, i32* %t121
  %t122 = add i64 %t117, 1
  store i64 %t122, i64* %t116
  br label %ring_push_done_26
ring_push_full_24:
  %t123 = getelementptr inbounds [3 x i32], [3 x i32]* %t113, i32 0, i64 %t115
  store i32 4, i32* %t123
  %t124 = add i64 %t115, 1
  %t125 = urem i64 %t124, 3
  store i64 %t125, i64* %t114
  br label %ring_push_done_26
ring_push_done_26:
  %t126 = getelementptr inbounds %Snapshot, %Snapshot* %t88, i32 0, i32 1
  %t127 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t126, i32 0, i32 0
  %t128 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t126, i32 0, i32 1
  %t129 = load i64, i64* %t128
  %t130 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t126, i32 0, i32 2
  %t131 = load i64, i64* %t130
  %t132 = trunc i64 %t131 to i32
  %t133 = getelementptr inbounds %Snapshot, %Snapshot* %t88, i32 0, i32 1
  %t134 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t133, i32 0, i32 0
  %t135 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t133, i32 0, i32 1
  %t136 = load i64, i64* %t135
  %t137 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t133, i32 0, i32 2
  %t138 = load i64, i64* %t137
  %t139 = sext i32 0 to i64
  %t140 = load i64, i64* %t135
  %t141 = load i64, i64* %t137
  %t142 = icmp ult i64 %t139, %t141
  br i1 %t142, label %ring_rplace_ok_27, label %ring_rplace_oob_28
ring_rplace_ok_27:
  %t143 = add i64 %t140, %t139
  %t144 = urem i64 %t143, 3
  %t145 = getelementptr inbounds [3 x i32], [3 x i32]* %t134, i32 0, i64 %t144
  br label %ring_rplace_end_29
ring_rplace_oob_28:
  store i32 0, i32* %t146
  br label %ring_rplace_end_29
ring_rplace_end_29:
  %t147 = phi i32* [ %t145, %ring_rplace_ok_27 ], [ %t146, %ring_rplace_oob_28 ]
  %t148 = load i32, i32* %t147
  %t149 = getelementptr inbounds %Snapshot, %Snapshot* %t88, i32 0, i32 1
  %t150 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t149, i32 0, i32 0
  %t151 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t149, i32 0, i32 1
  %t152 = load i64, i64* %t151
  %t153 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t149, i32 0, i32 2
  %t154 = load i64, i64* %t153
  %t155 = sext i32 1 to i64
  %t156 = load i64, i64* %t151
  %t157 = load i64, i64* %t153
  %t158 = icmp ult i64 %t155, %t157
  br i1 %t158, label %ring_rplace_ok_30, label %ring_rplace_oob_31
ring_rplace_ok_30:
  %t159 = add i64 %t156, %t155
  %t160 = urem i64 %t159, 3
  %t161 = getelementptr inbounds [3 x i32], [3 x i32]* %t150, i32 0, i64 %t160
  br label %ring_rplace_end_32
ring_rplace_oob_31:
  store i32 0, i32* %t162
  br label %ring_rplace_end_32
ring_rplace_end_32:
  %t163 = phi i32* [ %t161, %ring_rplace_ok_30 ], [ %t162, %ring_rplace_oob_31 ]
  %t164 = load i32, i32* %t163
  %t165 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t165, i32 %t132, i32 %t148, i32 %t164)
  %t166 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 1
  %t167 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t166, i32 0, i32 0
  %t168 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t166, i32 0, i32 1
  %t169 = load i64, i64* %t168
  %t170 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t166, i32 0, i32 2
  %t171 = load i64, i64* %t170
  %t172 = trunc i64 %t171 to i32
  %t173 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 1
  %t174 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t173, i32 0, i32 0
  %t175 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t173, i32 0, i32 1
  %t176 = load i64, i64* %t175
  %t177 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t173, i32 0, i32 2
  %t178 = load i64, i64* %t177
  %t179 = sext i32 0 to i64
  %t180 = load i64, i64* %t175
  %t181 = load i64, i64* %t177
  %t182 = icmp ult i64 %t179, %t181
  br i1 %t182, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t183 = add i64 %t180, %t179
  %t184 = urem i64 %t183, 3
  %t185 = getelementptr inbounds [3 x i32], [3 x i32]* %t174, i32 0, i64 %t184
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store i32 0, i32* %t186
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t187 = phi i32* [ %t185, %ring_rplace_ok_33 ], [ %t186, %ring_rplace_oob_34 ]
  %t188 = load i32, i32* %t187
  %t189 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 1
  %t190 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t189, i32 0, i32 0
  %t191 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t189, i32 0, i32 1
  %t192 = load i64, i64* %t191
  %t193 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t189, i32 0, i32 2
  %t194 = load i64, i64* %t193
  %t195 = sext i32 1 to i64
  %t196 = load i64, i64* %t191
  %t197 = load i64, i64* %t193
  %t198 = icmp ult i64 %t195, %t197
  br i1 %t198, label %ring_rplace_ok_36, label %ring_rplace_oob_37
ring_rplace_ok_36:
  %t199 = add i64 %t196, %t195
  %t200 = urem i64 %t199, 3
  %t201 = getelementptr inbounds [3 x i32], [3 x i32]* %t190, i32 0, i64 %t200
  br label %ring_rplace_end_38
ring_rplace_oob_37:
  store i32 0, i32* %t202
  br label %ring_rplace_end_38
ring_rplace_end_38:
  %t203 = phi i32* [ %t201, %ring_rplace_ok_36 ], [ %t202, %ring_rplace_oob_37 ]
  %t204 = load i32, i32* %t203
  %t205 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t205, i32 %t172, i32 %t188, i32 %t204)
  store i8* null, i8** %t206
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t207
  %t208 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t209 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207, i32 0, i32 0
  %t210 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207, i32 0, i32 1
  %t211 = load i64, i64* %t210
  %t212 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207, i32 0, i32 2
  %t213 = load i64, i64* %t212
  %t214 = icmp sge i64 %t213, 2
  br i1 %t214, label %ring_push_full_39, label %ring_push_grow_40
ring_push_grow_40:
  %t215 = add i64 %t211, %t213
  %t216 = urem i64 %t215, 2
  %t217 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t209, i32 0, i64 %t216
  store i8* %t208, i8** %t217
  %t218 = add i64 %t213, 1
  store i64 %t218, i64* %t212
  br label %ring_push_done_41
ring_push_full_39:
  %t219 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t209, i32 0, i64 %t211
  %t220 = load i8*, i8** %t219
  call void @star_rc_release(i8* %t220)
  store i8* %t208, i8** %t219
  %t221 = add i64 %t211, 1
  %t222 = urem i64 %t221, 2
  store i64 %t222, i64* %t210
  br label %ring_push_done_41
ring_push_done_41:
  %t223 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t224 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207, i32 0, i32 0
  %t225 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207, i32 0, i32 1
  %t226 = load i64, i64* %t225
  %t227 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207, i32 0, i32 2
  %t228 = load i64, i64* %t227
  %t229 = icmp sge i64 %t228, 2
  br i1 %t229, label %ring_push_full_42, label %ring_push_grow_43
ring_push_grow_43:
  %t230 = add i64 %t226, %t228
  %t231 = urem i64 %t230, 2
  %t232 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t224, i32 0, i64 %t231
  store i8* %t223, i8** %t232
  %t233 = add i64 %t228, 1
  store i64 %t233, i64* %t227
  br label %ring_push_done_44
ring_push_full_42:
  %t234 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t224, i32 0, i64 %t226
  %t235 = load i8*, i8** %t234
  call void @star_rc_release(i8* %t235)
  store i8* %t223, i8** %t234
  %t236 = add i64 %t226, 1
  %t237 = urem i64 %t236, 2
  store i64 %t237, i64* %t225
  br label %ring_push_done_44
ring_push_done_44:
  %t238 = load i8*, i8** %t206
  %t239 = icmp eq i8* %t238, null
  br i1 %t239, label %table_cow_alloc_45, label %table_cow_check_46
table_cow_alloc_45:
  %t259 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t260 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t261 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t260 to i64
  %t262 = call i8* @star_rc_alloc(i64 %t261, i8* %t259)
  %t263 = bitcast i8* %t262 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t264 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t263, i32 0, i32 0
  store i64 0, i64* %t264
  %t265 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t263, i32 0, i32 1
  store i64 0, i64* %t265
  %t266 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t263, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t266
  %t267 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t263, i32 0, i32 3
  store i32* null, i32** %t267
  store i8* %t262, i8** %t206
  br label %table_cow_done_47
table_cow_check_46:
  %t268 = getelementptr inbounds i8, i8* %t238, i64 -16
  %t269 = bitcast i8* %t268 to i64*
  %t270 = load atomic i64, i64* %t269 seq_cst, align 8
  %t271 = icmp eq i64 %t270, 1
  br i1 %t271, label %table_cow_done_47, label %table_cow_clone_51
table_cow_clone_51:
  %t272 = bitcast i8* %t238 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t273 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t272, i32 0, i32 0
  %t274 = load i64, i64* %t273
  %t275 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t272, i32 0, i32 1
  %t276 = load i64, i64* %t275
  %t277 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t278 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t279 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t278 to i64
  %t280 = call i8* @star_rc_alloc(i64 %t279, i8* %t277)
  %t281 = bitcast i8* %t280 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t282 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t281, i32 0, i32 0
  store i64 %t274, i64* %t282
  %t283 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t281, i32 0, i32 1
  store i64 %t276, i64* %t283
  %t284 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t285 = ptrtoint { [2 x i8*], i64, i64 }* %t284 to i64
  %t286 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t272, i32 0, i32 2
  %t287 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t286
  %t288 = mul i64 %t276, %t285
  %t289 = call i8* @malloc(i64 %t288)
  %t290 = bitcast i8* %t289 to { [2 x i8*], i64, i64 }*
  %t291 = icmp sgt i64 %t274, 0
  br i1 %t291, label %table_cow_copy_52, label %table_cow_after_copy_53
table_cow_copy_52:
  %t292 = mul i64 %t274, %t285
  %t293 = bitcast { [2 x i8*], i64, i64 }* %t287 to i8*
  call i8* @memcpy(i8* %t289, i8* %t293, i64 %t292)
  store i64 0, i64* %t294
  br label %table_cow_retain_cond_54
table_cow_retain_cond_54:
  %t295 = load i64, i64* %t294
  %t296 = icmp slt i64 %t295, %t274
  br i1 %t296, label %table_cow_retain_body_55, label %table_cow_retain_end_56
table_cow_retain_body_55:
  %t297 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t290, i64 %t295
  %t298 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t297, i32 0, i32 0
  %t299 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t298, i32 0, i64 0
  %t300 = load i8*, i8** %t299
  call void @star_rc_retain(i8* %t300)
  %t301 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t298, i32 0, i64 1
  %t302 = load i8*, i8** %t301
  call void @star_rc_retain(i8* %t302)
  %t303 = add i64 %t295, 1
  store i64 %t303, i64* %t294
  br label %table_cow_retain_cond_54
table_cow_retain_end_56:
  br label %table_cow_after_copy_53
table_cow_after_copy_53:
  %t304 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t281, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t290, { [2 x i8*], i64, i64 }** %t304
  %t305 = getelementptr i32, i32* null, i32 1
  %t306 = ptrtoint i32* %t305 to i64
  %t307 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t272, i32 0, i32 3
  %t308 = load i32*, i32** %t307
  %t309 = mul i64 %t276, %t306
  %t310 = call i8* @malloc(i64 %t309)
  %t311 = bitcast i8* %t310 to i32*
  %t312 = icmp sgt i64 %t274, 0
  br i1 %t312, label %table_cow_copy_57, label %table_cow_after_copy_58
table_cow_copy_57:
  %t313 = mul i64 %t274, %t306
  %t314 = bitcast i32* %t308 to i8*
  call i8* @memcpy(i8* %t310, i8* %t314, i64 %t313)
  br label %table_cow_after_copy_58
table_cow_after_copy_58:
  %t315 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t281, i32 0, i32 3
  store i32* %t311, i32** %t315
  call void @star_rc_release(i8* %t238)
  store i8* %t280, i8** %t206
  br label %table_cow_done_47
table_cow_done_47:
  %t316 = load i8*, i8** %t206
  %t317 = bitcast i8* %t316 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t318 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t317, i32 0, i32 0
  %t319 = load i64, i64* %t318
  %t320 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t317, i32 0, i32 1
  %t321 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t317, i32 0, i32 2
  %t322 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t321
  %t323 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t317, i32 0, i32 3
  %t324 = load i32*, i32** %t323
  %t326 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207
  %t327 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207, i32 0, i32 0
  %t328 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t327, i32 0, i64 0
  %t329 = load i8*, i8** %t328
  call void @star_rc_retain(i8* %t329)
  %t330 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t327, i32 0, i64 1
  %t331 = load i8*, i8** %t330
  call void @star_rc_retain(i8* %t331)
  %t332 = getelementptr inbounds %Bag, %Bag* %t325, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t326, { [2 x i8*], i64, i64 }* %t332
  %t333 = getelementptr inbounds %Bag, %Bag* %t325, i32 0, i32 1
  store i32 1, i32* %t333
  %t334 = load %Bag, %Bag* %t325
  %t335 = load i64, i64* %t320
  %t336 = load i64, i64* %t318
  %t337 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t321
  %t338 = load i32*, i32** %t323
  %t339 = icmp sge i64 %t336, %t335
  br i1 %t339, label %table_push_grow_59, label %table_push_store_60
table_push_grow_59:
  %t340 = mul i64 %t335, 2
  %t341 = icmp sgt i64 %t340, 0
  %t342 = select i1 %t341, i64 %t340, i64 1
  %t343 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t344 = ptrtoint { [2 x i8*], i64, i64 }* %t343 to i64
  %t345 = mul i64 %t342, %t344
  %t346 = call i8* @malloc(i64 %t345)
  %t347 = bitcast i8* %t346 to { [2 x i8*], i64, i64 }*
  %t348 = icmp sgt i64 %t335, 0
  br i1 %t348, label %table_push_copy_61, label %table_push_after_copy_62
table_push_copy_61:
  %t349 = mul i64 %t336, %t344
  %t350 = bitcast { [2 x i8*], i64, i64 }* %t337 to i8*
  call i8* @memcpy(i8* %t346, i8* %t350, i64 %t349)
  call void @free(i8* %t350)
  br label %table_push_after_copy_62
table_push_after_copy_62:
  store { [2 x i8*], i64, i64 }* %t347, { [2 x i8*], i64, i64 }** %t321
  %t351 = getelementptr i32, i32* null, i32 1
  %t352 = ptrtoint i32* %t351 to i64
  %t353 = mul i64 %t342, %t352
  %t354 = call i8* @malloc(i64 %t353)
  %t355 = bitcast i8* %t354 to i32*
  %t356 = icmp sgt i64 %t335, 0
  br i1 %t356, label %table_push_copy_63, label %table_push_after_copy_64
table_push_copy_63:
  %t357 = mul i64 %t336, %t352
  %t358 = bitcast i32* %t338 to i8*
  call i8* @memcpy(i8* %t354, i8* %t358, i64 %t357)
  call void @free(i8* %t358)
  br label %table_push_after_copy_64
table_push_after_copy_64:
  store i32* %t355, i32** %t323
  store i64 %t342, i64* %t320
  br label %table_push_store_60
table_push_store_60:
  %t359 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t321
  %t360 = extractvalue %Bag %t334, 0
  %t361 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t359, i64 %t336
  store { [2 x i8*], i64, i64 } %t360, { [2 x i8*], i64, i64 }* %t361
  %t362 = load i32*, i32** %t323
  %t363 = extractvalue %Bag %t334, 1
  %t364 = getelementptr inbounds i32, i32* %t362, i64 %t336
  store i32 %t363, i32* %t364
  %t365 = add i64 %t336, 1
  store i64 %t365, i64* %t318
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t366
  %t367 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t368 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t366, i32 0, i32 0
  %t369 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t366, i32 0, i32 1
  %t370 = load i64, i64* %t369
  %t371 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t366, i32 0, i32 2
  %t372 = load i64, i64* %t371
  %t373 = icmp sge i64 %t372, 2
  br i1 %t373, label %ring_push_full_65, label %ring_push_grow_66
ring_push_grow_66:
  %t374 = add i64 %t370, %t372
  %t375 = urem i64 %t374, 2
  %t376 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t368, i32 0, i64 %t375
  store i8* %t367, i8** %t376
  %t377 = add i64 %t372, 1
  store i64 %t377, i64* %t371
  br label %ring_push_done_67
ring_push_full_65:
  %t378 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t368, i32 0, i64 %t370
  %t379 = load i8*, i8** %t378
  call void @star_rc_release(i8* %t379)
  store i8* %t367, i8** %t378
  %t380 = add i64 %t370, 1
  %t381 = urem i64 %t380, 2
  store i64 %t381, i64* %t369
  br label %ring_push_done_67
ring_push_done_67:
  %t382 = load i8*, i8** %t206
  %t383 = icmp eq i8* %t382, null
  br i1 %t383, label %table_cow_alloc_68, label %table_cow_check_69
table_cow_alloc_68:
  %t384 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t385 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t386 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t385 to i64
  %t387 = call i8* @star_rc_alloc(i64 %t386, i8* %t384)
  %t388 = bitcast i8* %t387 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t389 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t388, i32 0, i32 0
  store i64 0, i64* %t389
  %t390 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t388, i32 0, i32 1
  store i64 0, i64* %t390
  %t391 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t388, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t391
  %t392 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t388, i32 0, i32 3
  store i32* null, i32** %t392
  store i8* %t387, i8** %t206
  br label %table_cow_done_70
table_cow_check_69:
  %t393 = getelementptr inbounds i8, i8* %t382, i64 -16
  %t394 = bitcast i8* %t393 to i64*
  %t395 = load atomic i64, i64* %t394 seq_cst, align 8
  %t396 = icmp eq i64 %t395, 1
  br i1 %t396, label %table_cow_done_70, label %table_cow_clone_71
table_cow_clone_71:
  %t397 = bitcast i8* %t382 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t398 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t397, i32 0, i32 0
  %t399 = load i64, i64* %t398
  %t400 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t397, i32 0, i32 1
  %t401 = load i64, i64* %t400
  %t402 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t403 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t404 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t403 to i64
  %t405 = call i8* @star_rc_alloc(i64 %t404, i8* %t402)
  %t406 = bitcast i8* %t405 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t407 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t406, i32 0, i32 0
  store i64 %t399, i64* %t407
  %t408 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t406, i32 0, i32 1
  store i64 %t401, i64* %t408
  %t409 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t410 = ptrtoint { [2 x i8*], i64, i64 }* %t409 to i64
  %t411 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t397, i32 0, i32 2
  %t412 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t411
  %t413 = mul i64 %t401, %t410
  %t414 = call i8* @malloc(i64 %t413)
  %t415 = bitcast i8* %t414 to { [2 x i8*], i64, i64 }*
  %t416 = icmp sgt i64 %t399, 0
  br i1 %t416, label %table_cow_copy_72, label %table_cow_after_copy_73
table_cow_copy_72:
  %t417 = mul i64 %t399, %t410
  %t418 = bitcast { [2 x i8*], i64, i64 }* %t412 to i8*
  call i8* @memcpy(i8* %t414, i8* %t418, i64 %t417)
  store i64 0, i64* %t419
  br label %table_cow_retain_cond_74
table_cow_retain_cond_74:
  %t420 = load i64, i64* %t419
  %t421 = icmp slt i64 %t420, %t399
  br i1 %t421, label %table_cow_retain_body_75, label %table_cow_retain_end_76
table_cow_retain_body_75:
  %t422 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t415, i64 %t420
  %t423 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t422, i32 0, i32 0
  %t424 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t423, i32 0, i64 0
  %t425 = load i8*, i8** %t424
  call void @star_rc_retain(i8* %t425)
  %t426 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t423, i32 0, i64 1
  %t427 = load i8*, i8** %t426
  call void @star_rc_retain(i8* %t427)
  %t428 = add i64 %t420, 1
  store i64 %t428, i64* %t419
  br label %table_cow_retain_cond_74
table_cow_retain_end_76:
  br label %table_cow_after_copy_73
table_cow_after_copy_73:
  %t429 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t406, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t415, { [2 x i8*], i64, i64 }** %t429
  %t430 = getelementptr i32, i32* null, i32 1
  %t431 = ptrtoint i32* %t430 to i64
  %t432 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t397, i32 0, i32 3
  %t433 = load i32*, i32** %t432
  %t434 = mul i64 %t401, %t431
  %t435 = call i8* @malloc(i64 %t434)
  %t436 = bitcast i8* %t435 to i32*
  %t437 = icmp sgt i64 %t399, 0
  br i1 %t437, label %table_cow_copy_77, label %table_cow_after_copy_78
table_cow_copy_77:
  %t438 = mul i64 %t399, %t431
  %t439 = bitcast i32* %t433 to i8*
  call i8* @memcpy(i8* %t435, i8* %t439, i64 %t438)
  br label %table_cow_after_copy_78
table_cow_after_copy_78:
  %t440 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t406, i32 0, i32 3
  store i32* %t436, i32** %t440
  call void @star_rc_release(i8* %t382)
  store i8* %t405, i8** %t206
  br label %table_cow_done_70
table_cow_done_70:
  %t441 = load i8*, i8** %t206
  %t442 = bitcast i8* %t441 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t443 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t442, i32 0, i32 0
  %t444 = load i64, i64* %t443
  %t445 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t442, i32 0, i32 1
  %t446 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t442, i32 0, i32 2
  %t447 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t446
  %t448 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t442, i32 0, i32 3
  %t449 = load i32*, i32** %t448
  %t451 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t366
  %t452 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t366, i32 0, i32 0
  %t453 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t452, i32 0, i64 0
  %t454 = load i8*, i8** %t453
  call void @star_rc_retain(i8* %t454)
  %t455 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t452, i32 0, i64 1
  %t456 = load i8*, i8** %t455
  call void @star_rc_retain(i8* %t456)
  %t457 = getelementptr inbounds %Bag, %Bag* %t450, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t451, { [2 x i8*], i64, i64 }* %t457
  %t458 = getelementptr inbounds %Bag, %Bag* %t450, i32 0, i32 1
  store i32 2, i32* %t458
  %t459 = load %Bag, %Bag* %t450
  %t460 = load i64, i64* %t445
  %t461 = load i64, i64* %t443
  %t462 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t446
  %t463 = load i32*, i32** %t448
  %t464 = icmp sge i64 %t461, %t460
  br i1 %t464, label %table_push_grow_79, label %table_push_store_80
table_push_grow_79:
  %t465 = mul i64 %t460, 2
  %t466 = icmp sgt i64 %t465, 0
  %t467 = select i1 %t466, i64 %t465, i64 1
  %t468 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t469 = ptrtoint { [2 x i8*], i64, i64 }* %t468 to i64
  %t470 = mul i64 %t467, %t469
  %t471 = call i8* @malloc(i64 %t470)
  %t472 = bitcast i8* %t471 to { [2 x i8*], i64, i64 }*
  %t473 = icmp sgt i64 %t460, 0
  br i1 %t473, label %table_push_copy_81, label %table_push_after_copy_82
table_push_copy_81:
  %t474 = mul i64 %t461, %t469
  %t475 = bitcast { [2 x i8*], i64, i64 }* %t462 to i8*
  call i8* @memcpy(i8* %t471, i8* %t475, i64 %t474)
  call void @free(i8* %t475)
  br label %table_push_after_copy_82
table_push_after_copy_82:
  store { [2 x i8*], i64, i64 }* %t472, { [2 x i8*], i64, i64 }** %t446
  %t476 = getelementptr i32, i32* null, i32 1
  %t477 = ptrtoint i32* %t476 to i64
  %t478 = mul i64 %t467, %t477
  %t479 = call i8* @malloc(i64 %t478)
  %t480 = bitcast i8* %t479 to i32*
  %t481 = icmp sgt i64 %t460, 0
  br i1 %t481, label %table_push_copy_83, label %table_push_after_copy_84
table_push_copy_83:
  %t482 = mul i64 %t461, %t477
  %t483 = bitcast i32* %t463 to i8*
  call i8* @memcpy(i8* %t479, i8* %t483, i64 %t482)
  call void @free(i8* %t483)
  br label %table_push_after_copy_84
table_push_after_copy_84:
  store i32* %t480, i32** %t448
  store i64 %t467, i64* %t445
  br label %table_push_store_80
table_push_store_80:
  %t484 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t446
  %t485 = extractvalue %Bag %t459, 0
  %t486 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t484, i64 %t461
  store { [2 x i8*], i64, i64 } %t485, { [2 x i8*], i64, i64 }* %t486
  %t487 = load i32*, i32** %t448
  %t488 = extractvalue %Bag %t459, 1
  %t489 = getelementptr inbounds i32, i32* %t487, i64 %t461
  store i32 %t488, i32* %t489
  %t490 = add i64 %t461, 1
  store i64 %t490, i64* %t443
  %t491 = load i8*, i8** %t206
  %t492 = icmp eq i8* %t491, null
  br i1 %t492, label %table_read_null_85, label %table_read_real_86
table_read_null_85:
  br label %table_read_end_87
table_read_real_86:
  %t493 = bitcast i8* %t491 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t494 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t493, i32 0, i32 0
  %t495 = load i64, i64* %t494
  %t496 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t493, i32 0, i32 2
  %t497 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t496
  %t498 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t493, i32 0, i32 3
  %t499 = load i32*, i32** %t498
  br label %table_read_end_87
table_read_end_87:
  %t500 = phi i64 [ 0, %table_read_null_85 ], [ %t495, %table_read_real_86 ]
  %t501 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_85 ], [ %t497, %table_read_real_86 ]
  %t502 = phi i32* [ null, %table_read_null_85 ], [ %t499, %table_read_real_86 ]
  %t503 = trunc i64 %t500 to i32
  %t504 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t504, i32 %t503)
  %t505 = sext i32 0 to i64
  %t506 = load i8*, i8** %t206
  %t507 = icmp eq i8* %t506, null
  br i1 %t507, label %table_read_null_88, label %table_read_real_89
table_read_null_88:
  br label %table_read_end_90
table_read_real_89:
  %t508 = bitcast i8* %t506 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t509 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t508, i32 0, i32 0
  %t510 = load i64, i64* %t509
  %t511 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t508, i32 0, i32 2
  %t512 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t511
  %t513 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t508, i32 0, i32 3
  %t514 = load i32*, i32** %t513
  br label %table_read_end_90
table_read_end_90:
  %t515 = phi i64 [ 0, %table_read_null_88 ], [ %t510, %table_read_real_89 ]
  %t516 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_88 ], [ %t512, %table_read_real_89 ]
  %t517 = phi i32* [ null, %table_read_null_88 ], [ %t514, %table_read_real_89 ]
  %t519 = icmp ult i64 %t505, %t515
  br i1 %t519, label %table_idx_ok_91, label %table_idx_oob_92
table_idx_ok_91:
  %t520 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t516, i64 %t505
  %t521 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t520, i32 0, i32 0
  %t522 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t521, i32 0, i64 0
  %t523 = load i8*, i8** %t522
  call void @star_rc_retain(i8* %t523)
  %t524 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t521, i32 0, i64 1
  %t525 = load i8*, i8** %t524
  call void @star_rc_retain(i8* %t525)
  %t526 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t520
  %t527 = getelementptr inbounds %Bag, %Bag* %t518, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t526, { [2 x i8*], i64, i64 }* %t527
  %t528 = getelementptr inbounds i32, i32* %t517, i64 %t505
  %t529 = load i32, i32* %t528
  %t530 = getelementptr inbounds %Bag, %Bag* %t518, i32 0, i32 1
  store i32 %t529, i32* %t530
  br label %table_idx_end_93
table_idx_oob_92:
  store %Bag zeroinitializer, %Bag* %t518
  br label %table_idx_end_93
table_idx_end_93:
  %t531 = load %Bag, %Bag* %t518
  store %Bag %t531, %Bag* %t532
  %t533 = getelementptr inbounds %Bag, %Bag* %t532, i32 0, i32 1
  %t534 = load i32, i32* %t533
  %t535 = sext i32 0 to i64
  %t536 = load i8*, i8** %t206
  %t537 = icmp eq i8* %t536, null
  br i1 %t537, label %table_read_null_94, label %table_read_real_95
table_read_null_94:
  br label %table_read_end_96
table_read_real_95:
  %t538 = bitcast i8* %t536 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t539 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t538, i32 0, i32 0
  %t540 = load i64, i64* %t539
  %t541 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t538, i32 0, i32 2
  %t542 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t541
  %t543 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t538, i32 0, i32 3
  %t544 = load i32*, i32** %t543
  br label %table_read_end_96
table_read_end_96:
  %t545 = phi i64 [ 0, %table_read_null_94 ], [ %t540, %table_read_real_95 ]
  %t546 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_94 ], [ %t542, %table_read_real_95 ]
  %t547 = phi i32* [ null, %table_read_null_94 ], [ %t544, %table_read_real_95 ]
  %t549 = icmp ult i64 %t535, %t545
  br i1 %t549, label %table_idx_ok_97, label %table_idx_oob_98
table_idx_ok_97:
  %t550 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t546, i64 %t535
  %t551 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t550, i32 0, i32 0
  %t552 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t551, i32 0, i64 0
  %t553 = load i8*, i8** %t552
  call void @star_rc_retain(i8* %t553)
  %t554 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t551, i32 0, i64 1
  %t555 = load i8*, i8** %t554
  call void @star_rc_retain(i8* %t555)
  %t556 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t550
  %t557 = getelementptr inbounds %Bag, %Bag* %t548, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t556, { [2 x i8*], i64, i64 }* %t557
  %t558 = getelementptr inbounds i32, i32* %t547, i64 %t535
  %t559 = load i32, i32* %t558
  %t560 = getelementptr inbounds %Bag, %Bag* %t548, i32 0, i32 1
  store i32 %t559, i32* %t560
  br label %table_idx_end_99
table_idx_oob_98:
  store %Bag zeroinitializer, %Bag* %t548
  br label %table_idx_end_99
table_idx_end_99:
  %t561 = load %Bag, %Bag* %t548
  store %Bag %t561, %Bag* %t562
  %t563 = getelementptr inbounds %Bag, %Bag* %t562, i32 0, i32 0
  %t564 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t563, i32 0, i32 0
  %t565 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t563, i32 0, i32 1
  %t566 = load i64, i64* %t565
  %t567 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t563, i32 0, i32 2
  %t568 = load i64, i64* %t567
  %t569 = trunc i64 %t568 to i32
  %t570 = sext i32 0 to i64
  %t571 = load i8*, i8** %t206
  %t572 = icmp eq i8* %t571, null
  br i1 %t572, label %table_read_null_100, label %table_read_real_101
table_read_null_100:
  br label %table_read_end_102
table_read_real_101:
  %t573 = bitcast i8* %t571 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t574 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t573, i32 0, i32 0
  %t575 = load i64, i64* %t574
  %t576 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t573, i32 0, i32 2
  %t577 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t576
  %t578 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t573, i32 0, i32 3
  %t579 = load i32*, i32** %t578
  br label %table_read_end_102
table_read_end_102:
  %t580 = phi i64 [ 0, %table_read_null_100 ], [ %t575, %table_read_real_101 ]
  %t581 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_100 ], [ %t577, %table_read_real_101 ]
  %t582 = phi i32* [ null, %table_read_null_100 ], [ %t579, %table_read_real_101 ]
  %t584 = icmp ult i64 %t570, %t580
  br i1 %t584, label %table_idx_ok_103, label %table_idx_oob_104
table_idx_ok_103:
  %t585 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t581, i64 %t570
  %t586 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t585, i32 0, i32 0
  %t587 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t586, i32 0, i64 0
  %t588 = load i8*, i8** %t587
  call void @star_rc_retain(i8* %t588)
  %t589 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t586, i32 0, i64 1
  %t590 = load i8*, i8** %t589
  call void @star_rc_retain(i8* %t590)
  %t591 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t585
  %t592 = getelementptr inbounds %Bag, %Bag* %t583, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t591, { [2 x i8*], i64, i64 }* %t592
  %t593 = getelementptr inbounds i32, i32* %t582, i64 %t570
  %t594 = load i32, i32* %t593
  %t595 = getelementptr inbounds %Bag, %Bag* %t583, i32 0, i32 1
  store i32 %t594, i32* %t595
  br label %table_idx_end_105
table_idx_oob_104:
  store %Bag zeroinitializer, %Bag* %t583
  br label %table_idx_end_105
table_idx_end_105:
  %t596 = load %Bag, %Bag* %t583
  store %Bag %t596, %Bag* %t597
  %t598 = getelementptr inbounds %Bag, %Bag* %t597, i32 0, i32 0
  %t599 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t598, i32 0, i32 0
  %t600 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t598, i32 0, i32 1
  %t601 = load i64, i64* %t600
  %t602 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t598, i32 0, i32 2
  %t603 = load i64, i64* %t602
  %t604 = sext i32 0 to i64
  %t605 = load i64, i64* %t600
  %t606 = load i64, i64* %t602
  %t607 = icmp ult i64 %t604, %t606
  br i1 %t607, label %ring_rplace_ok_106, label %ring_rplace_oob_107
ring_rplace_ok_106:
  %t608 = add i64 %t605, %t604
  %t609 = urem i64 %t608, 2
  %t610 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t599, i32 0, i64 %t609
  br label %ring_rplace_end_108
ring_rplace_oob_107:
  store i8* null, i8** %t611
  br label %ring_rplace_end_108
ring_rplace_end_108:
  %t612 = phi i8** [ %t610, %ring_rplace_ok_106 ], [ %t611, %ring_rplace_oob_107 ]
  %t613 = load i8*, i8** %t612
  %t614 = load i8*, i8** %t612
  call void @star_rc_retain(i8* %t614)
  call void @star_rc_release(i8* %t613)
  %t615 = sext i32 0 to i64
  %t616 = load i8*, i8** %t206
  %t617 = icmp eq i8* %t616, null
  br i1 %t617, label %table_read_null_109, label %table_read_real_110
table_read_null_109:
  br label %table_read_end_111
table_read_real_110:
  %t618 = bitcast i8* %t616 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t619 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t618, i32 0, i32 0
  %t620 = load i64, i64* %t619
  %t621 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t618, i32 0, i32 2
  %t622 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t621
  %t623 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t618, i32 0, i32 3
  %t624 = load i32*, i32** %t623
  br label %table_read_end_111
table_read_end_111:
  %t625 = phi i64 [ 0, %table_read_null_109 ], [ %t620, %table_read_real_110 ]
  %t626 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_109 ], [ %t622, %table_read_real_110 ]
  %t627 = phi i32* [ null, %table_read_null_109 ], [ %t624, %table_read_real_110 ]
  %t629 = icmp ult i64 %t615, %t625
  br i1 %t629, label %table_idx_ok_112, label %table_idx_oob_113
table_idx_ok_112:
  %t630 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t626, i64 %t615
  %t631 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t630, i32 0, i32 0
  %t632 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t631, i32 0, i64 0
  %t633 = load i8*, i8** %t632
  call void @star_rc_retain(i8* %t633)
  %t634 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t631, i32 0, i64 1
  %t635 = load i8*, i8** %t634
  call void @star_rc_retain(i8* %t635)
  %t636 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t630
  %t637 = getelementptr inbounds %Bag, %Bag* %t628, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t636, { [2 x i8*], i64, i64 }* %t637
  %t638 = getelementptr inbounds i32, i32* %t627, i64 %t615
  %t639 = load i32, i32* %t638
  %t640 = getelementptr inbounds %Bag, %Bag* %t628, i32 0, i32 1
  store i32 %t639, i32* %t640
  br label %table_idx_end_114
table_idx_oob_113:
  store %Bag zeroinitializer, %Bag* %t628
  br label %table_idx_end_114
table_idx_end_114:
  %t641 = load %Bag, %Bag* %t628
  store %Bag %t641, %Bag* %t642
  %t643 = getelementptr inbounds %Bag, %Bag* %t642, i32 0, i32 0
  %t644 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t643, i32 0, i32 0
  %t645 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t643, i32 0, i32 1
  %t646 = load i64, i64* %t645
  %t647 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t643, i32 0, i32 2
  %t648 = load i64, i64* %t647
  %t649 = sext i32 1 to i64
  %t650 = load i64, i64* %t645
  %t651 = load i64, i64* %t647
  %t652 = icmp ult i64 %t649, %t651
  br i1 %t652, label %ring_rplace_ok_115, label %ring_rplace_oob_116
ring_rplace_ok_115:
  %t653 = add i64 %t650, %t649
  %t654 = urem i64 %t653, 2
  %t655 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t644, i32 0, i64 %t654
  br label %ring_rplace_end_117
ring_rplace_oob_116:
  store i8* null, i8** %t656
  br label %ring_rplace_end_117
ring_rplace_end_117:
  %t657 = phi i8** [ %t655, %ring_rplace_ok_115 ], [ %t656, %ring_rplace_oob_116 ]
  %t658 = load i8*, i8** %t657
  %t659 = load i8*, i8** %t657
  call void @star_rc_retain(i8* %t659)
  call void @star_rc_release(i8* %t658)
  %t660 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t660, i32 %t534, i32 %t569, i8* %t613, i8* %t658)
  %t661 = sext i32 1 to i64
  %t662 = load i8*, i8** %t206
  %t663 = icmp eq i8* %t662, null
  br i1 %t663, label %table_read_null_118, label %table_read_real_119
table_read_null_118:
  br label %table_read_end_120
table_read_real_119:
  %t664 = bitcast i8* %t662 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t665 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t664, i32 0, i32 0
  %t666 = load i64, i64* %t665
  %t667 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t664, i32 0, i32 2
  %t668 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t667
  %t669 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t664, i32 0, i32 3
  %t670 = load i32*, i32** %t669
  br label %table_read_end_120
table_read_end_120:
  %t671 = phi i64 [ 0, %table_read_null_118 ], [ %t666, %table_read_real_119 ]
  %t672 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_118 ], [ %t668, %table_read_real_119 ]
  %t673 = phi i32* [ null, %table_read_null_118 ], [ %t670, %table_read_real_119 ]
  %t675 = icmp ult i64 %t661, %t671
  br i1 %t675, label %table_idx_ok_121, label %table_idx_oob_122
table_idx_ok_121:
  %t676 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t672, i64 %t661
  %t677 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t676, i32 0, i32 0
  %t678 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t677, i32 0, i64 0
  %t679 = load i8*, i8** %t678
  call void @star_rc_retain(i8* %t679)
  %t680 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t677, i32 0, i64 1
  %t681 = load i8*, i8** %t680
  call void @star_rc_retain(i8* %t681)
  %t682 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t676
  %t683 = getelementptr inbounds %Bag, %Bag* %t674, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t682, { [2 x i8*], i64, i64 }* %t683
  %t684 = getelementptr inbounds i32, i32* %t673, i64 %t661
  %t685 = load i32, i32* %t684
  %t686 = getelementptr inbounds %Bag, %Bag* %t674, i32 0, i32 1
  store i32 %t685, i32* %t686
  br label %table_idx_end_123
table_idx_oob_122:
  store %Bag zeroinitializer, %Bag* %t674
  br label %table_idx_end_123
table_idx_end_123:
  %t687 = load %Bag, %Bag* %t674
  store %Bag %t687, %Bag* %t688
  %t689 = getelementptr inbounds %Bag, %Bag* %t688, i32 0, i32 1
  %t690 = load i32, i32* %t689
  %t691 = sext i32 1 to i64
  %t692 = load i8*, i8** %t206
  %t693 = icmp eq i8* %t692, null
  br i1 %t693, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t694 = bitcast i8* %t692 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t695 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t694, i32 0, i32 0
  %t696 = load i64, i64* %t695
  %t697 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t694, i32 0, i32 2
  %t698 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t697
  %t699 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t694, i32 0, i32 3
  %t700 = load i32*, i32** %t699
  br label %table_read_end_126
table_read_end_126:
  %t701 = phi i64 [ 0, %table_read_null_124 ], [ %t696, %table_read_real_125 ]
  %t702 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_124 ], [ %t698, %table_read_real_125 ]
  %t703 = phi i32* [ null, %table_read_null_124 ], [ %t700, %table_read_real_125 ]
  %t705 = icmp ult i64 %t691, %t701
  br i1 %t705, label %table_idx_ok_127, label %table_idx_oob_128
table_idx_ok_127:
  %t706 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t702, i64 %t691
  %t707 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t706, i32 0, i32 0
  %t708 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t707, i32 0, i64 0
  %t709 = load i8*, i8** %t708
  call void @star_rc_retain(i8* %t709)
  %t710 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t707, i32 0, i64 1
  %t711 = load i8*, i8** %t710
  call void @star_rc_retain(i8* %t711)
  %t712 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t706
  %t713 = getelementptr inbounds %Bag, %Bag* %t704, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t712, { [2 x i8*], i64, i64 }* %t713
  %t714 = getelementptr inbounds i32, i32* %t703, i64 %t691
  %t715 = load i32, i32* %t714
  %t716 = getelementptr inbounds %Bag, %Bag* %t704, i32 0, i32 1
  store i32 %t715, i32* %t716
  br label %table_idx_end_129
table_idx_oob_128:
  store %Bag zeroinitializer, %Bag* %t704
  br label %table_idx_end_129
table_idx_end_129:
  %t717 = load %Bag, %Bag* %t704
  store %Bag %t717, %Bag* %t718
  %t719 = getelementptr inbounds %Bag, %Bag* %t718, i32 0, i32 0
  %t720 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t719, i32 0, i32 0
  %t721 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t719, i32 0, i32 1
  %t722 = load i64, i64* %t721
  %t723 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t719, i32 0, i32 2
  %t724 = load i64, i64* %t723
  %t725 = trunc i64 %t724 to i32
  %t726 = sext i32 1 to i64
  %t727 = load i8*, i8** %t206
  %t728 = icmp eq i8* %t727, null
  br i1 %t728, label %table_read_null_130, label %table_read_real_131
table_read_null_130:
  br label %table_read_end_132
table_read_real_131:
  %t729 = bitcast i8* %t727 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t730 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t729, i32 0, i32 0
  %t731 = load i64, i64* %t730
  %t732 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t729, i32 0, i32 2
  %t733 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t732
  %t734 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t729, i32 0, i32 3
  %t735 = load i32*, i32** %t734
  br label %table_read_end_132
table_read_end_132:
  %t736 = phi i64 [ 0, %table_read_null_130 ], [ %t731, %table_read_real_131 ]
  %t737 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_130 ], [ %t733, %table_read_real_131 ]
  %t738 = phi i32* [ null, %table_read_null_130 ], [ %t735, %table_read_real_131 ]
  %t740 = icmp ult i64 %t726, %t736
  br i1 %t740, label %table_idx_ok_133, label %table_idx_oob_134
table_idx_ok_133:
  %t741 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t737, i64 %t726
  %t742 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t741, i32 0, i32 0
  %t743 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t742, i32 0, i64 0
  %t744 = load i8*, i8** %t743
  call void @star_rc_retain(i8* %t744)
  %t745 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t742, i32 0, i64 1
  %t746 = load i8*, i8** %t745
  call void @star_rc_retain(i8* %t746)
  %t747 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t741
  %t748 = getelementptr inbounds %Bag, %Bag* %t739, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t747, { [2 x i8*], i64, i64 }* %t748
  %t749 = getelementptr inbounds i32, i32* %t738, i64 %t726
  %t750 = load i32, i32* %t749
  %t751 = getelementptr inbounds %Bag, %Bag* %t739, i32 0, i32 1
  store i32 %t750, i32* %t751
  br label %table_idx_end_135
table_idx_oob_134:
  store %Bag zeroinitializer, %Bag* %t739
  br label %table_idx_end_135
table_idx_end_135:
  %t752 = load %Bag, %Bag* %t739
  store %Bag %t752, %Bag* %t753
  %t754 = getelementptr inbounds %Bag, %Bag* %t753, i32 0, i32 0
  %t755 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t754, i32 0, i32 0
  %t756 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t754, i32 0, i32 1
  %t757 = load i64, i64* %t756
  %t758 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t754, i32 0, i32 2
  %t759 = load i64, i64* %t758
  %t760 = sext i32 0 to i64
  %t761 = load i64, i64* %t756
  %t762 = load i64, i64* %t758
  %t763 = icmp ult i64 %t760, %t762
  br i1 %t763, label %ring_rplace_ok_136, label %ring_rplace_oob_137
ring_rplace_ok_136:
  %t764 = add i64 %t761, %t760
  %t765 = urem i64 %t764, 2
  %t766 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t755, i32 0, i64 %t765
  br label %ring_rplace_end_138
ring_rplace_oob_137:
  store i8* null, i8** %t767
  br label %ring_rplace_end_138
ring_rplace_end_138:
  %t768 = phi i8** [ %t766, %ring_rplace_ok_136 ], [ %t767, %ring_rplace_oob_137 ]
  %t769 = load i8*, i8** %t768
  %t770 = load i8*, i8** %t768
  call void @star_rc_retain(i8* %t770)
  call void @star_rc_release(i8* %t769)
  %t771 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t771, i32 %t690, i32 %t725, i8* %t769)
  %t773 = load i8*, i8** %t206
  %t774 = load i8*, i8** %t206
  call void @star_rc_retain(i8* %t774)
  store i8* %t773, i8** %t772
  %t775 = load i8*, i8** %t206
  %t776 = icmp eq i8* %t775, null
  br i1 %t776, label %table_cow_alloc_139, label %table_cow_check_140
table_cow_alloc_139:
  %t777 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t778 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t779 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t778 to i64
  %t780 = call i8* @star_rc_alloc(i64 %t779, i8* %t777)
  %t781 = bitcast i8* %t780 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t782 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t781, i32 0, i32 0
  store i64 0, i64* %t782
  %t783 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t781, i32 0, i32 1
  store i64 0, i64* %t783
  %t784 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t781, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t784
  %t785 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t781, i32 0, i32 3
  store i32* null, i32** %t785
  store i8* %t780, i8** %t206
  br label %table_cow_done_141
table_cow_check_140:
  %t786 = getelementptr inbounds i8, i8* %t775, i64 -16
  %t787 = bitcast i8* %t786 to i64*
  %t788 = load atomic i64, i64* %t787 seq_cst, align 8
  %t789 = icmp eq i64 %t788, 1
  br i1 %t789, label %table_cow_done_141, label %table_cow_clone_142
table_cow_clone_142:
  %t790 = bitcast i8* %t775 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t791 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t790, i32 0, i32 0
  %t792 = load i64, i64* %t791
  %t793 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t790, i32 0, i32 1
  %t794 = load i64, i64* %t793
  %t795 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t796 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t797 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t796 to i64
  %t798 = call i8* @star_rc_alloc(i64 %t797, i8* %t795)
  %t799 = bitcast i8* %t798 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t800 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t799, i32 0, i32 0
  store i64 %t792, i64* %t800
  %t801 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t799, i32 0, i32 1
  store i64 %t794, i64* %t801
  %t802 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t803 = ptrtoint { [2 x i8*], i64, i64 }* %t802 to i64
  %t804 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t790, i32 0, i32 2
  %t805 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t804
  %t806 = mul i64 %t794, %t803
  %t807 = call i8* @malloc(i64 %t806)
  %t808 = bitcast i8* %t807 to { [2 x i8*], i64, i64 }*
  %t809 = icmp sgt i64 %t792, 0
  br i1 %t809, label %table_cow_copy_143, label %table_cow_after_copy_144
table_cow_copy_143:
  %t810 = mul i64 %t792, %t803
  %t811 = bitcast { [2 x i8*], i64, i64 }* %t805 to i8*
  call i8* @memcpy(i8* %t807, i8* %t811, i64 %t810)
  store i64 0, i64* %t812
  br label %table_cow_retain_cond_145
table_cow_retain_cond_145:
  %t813 = load i64, i64* %t812
  %t814 = icmp slt i64 %t813, %t792
  br i1 %t814, label %table_cow_retain_body_146, label %table_cow_retain_end_147
table_cow_retain_body_146:
  %t815 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t808, i64 %t813
  %t816 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t815, i32 0, i32 0
  %t817 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t816, i32 0, i64 0
  %t818 = load i8*, i8** %t817
  call void @star_rc_retain(i8* %t818)
  %t819 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t816, i32 0, i64 1
  %t820 = load i8*, i8** %t819
  call void @star_rc_retain(i8* %t820)
  %t821 = add i64 %t813, 1
  store i64 %t821, i64* %t812
  br label %table_cow_retain_cond_145
table_cow_retain_end_147:
  br label %table_cow_after_copy_144
table_cow_after_copy_144:
  %t822 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t799, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t808, { [2 x i8*], i64, i64 }** %t822
  %t823 = getelementptr i32, i32* null, i32 1
  %t824 = ptrtoint i32* %t823 to i64
  %t825 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t790, i32 0, i32 3
  %t826 = load i32*, i32** %t825
  %t827 = mul i64 %t794, %t824
  %t828 = call i8* @malloc(i64 %t827)
  %t829 = bitcast i8* %t828 to i32*
  %t830 = icmp sgt i64 %t792, 0
  br i1 %t830, label %table_cow_copy_148, label %table_cow_after_copy_149
table_cow_copy_148:
  %t831 = mul i64 %t792, %t824
  %t832 = bitcast i32* %t826 to i8*
  call i8* @memcpy(i8* %t828, i8* %t832, i64 %t831)
  br label %table_cow_after_copy_149
table_cow_after_copy_149:
  %t833 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t799, i32 0, i32 3
  store i32* %t829, i32** %t833
  call void @star_rc_release(i8* %t775)
  store i8* %t798, i8** %t206
  br label %table_cow_done_141
table_cow_done_141:
  %t834 = load i8*, i8** %t206
  %t835 = bitcast i8* %t834 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t836 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t835, i32 0, i32 0
  %t837 = load i64, i64* %t836
  %t838 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t835, i32 0, i32 1
  %t839 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t835, i32 0, i32 2
  %t840 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t839
  %t841 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t835, i32 0, i32 3
  %t842 = load i32*, i32** %t841
  %t844 = getelementptr inbounds %Bag, %Bag* %t843, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t844
  %t845 = getelementptr inbounds %Bag, %Bag* %t843, i32 0, i32 1
  store i32 3, i32* %t845
  %t846 = load %Bag, %Bag* %t843
  %t847 = load i64, i64* %t838
  %t848 = load i64, i64* %t836
  %t849 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t839
  %t850 = load i32*, i32** %t841
  %t851 = icmp sge i64 %t848, %t847
  br i1 %t851, label %table_push_grow_150, label %table_push_store_151
table_push_grow_150:
  %t852 = mul i64 %t847, 2
  %t853 = icmp sgt i64 %t852, 0
  %t854 = select i1 %t853, i64 %t852, i64 1
  %t855 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t856 = ptrtoint { [2 x i8*], i64, i64 }* %t855 to i64
  %t857 = mul i64 %t854, %t856
  %t858 = call i8* @malloc(i64 %t857)
  %t859 = bitcast i8* %t858 to { [2 x i8*], i64, i64 }*
  %t860 = icmp sgt i64 %t847, 0
  br i1 %t860, label %table_push_copy_152, label %table_push_after_copy_153
table_push_copy_152:
  %t861 = mul i64 %t848, %t856
  %t862 = bitcast { [2 x i8*], i64, i64 }* %t849 to i8*
  call i8* @memcpy(i8* %t858, i8* %t862, i64 %t861)
  call void @free(i8* %t862)
  br label %table_push_after_copy_153
table_push_after_copy_153:
  store { [2 x i8*], i64, i64 }* %t859, { [2 x i8*], i64, i64 }** %t839
  %t863 = getelementptr i32, i32* null, i32 1
  %t864 = ptrtoint i32* %t863 to i64
  %t865 = mul i64 %t854, %t864
  %t866 = call i8* @malloc(i64 %t865)
  %t867 = bitcast i8* %t866 to i32*
  %t868 = icmp sgt i64 %t847, 0
  br i1 %t868, label %table_push_copy_154, label %table_push_after_copy_155
table_push_copy_154:
  %t869 = mul i64 %t848, %t864
  %t870 = bitcast i32* %t850 to i8*
  call i8* @memcpy(i8* %t866, i8* %t870, i64 %t869)
  call void @free(i8* %t870)
  br label %table_push_after_copy_155
table_push_after_copy_155:
  store i32* %t867, i32** %t841
  store i64 %t854, i64* %t838
  br label %table_push_store_151
table_push_store_151:
  %t871 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t839
  %t872 = extractvalue %Bag %t846, 0
  %t873 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t871, i64 %t848
  store { [2 x i8*], i64, i64 } %t872, { [2 x i8*], i64, i64 }* %t873
  %t874 = load i32*, i32** %t841
  %t875 = extractvalue %Bag %t846, 1
  %t876 = getelementptr inbounds i32, i32* %t874, i64 %t848
  store i32 %t875, i32* %t876
  %t877 = add i64 %t848, 1
  store i64 %t877, i64* %t836
  %t878 = load i8*, i8** %t206
  %t879 = icmp eq i8* %t878, null
  br i1 %t879, label %table_read_null_156, label %table_read_real_157
table_read_null_156:
  br label %table_read_end_158
table_read_real_157:
  %t880 = bitcast i8* %t878 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t881 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t880, i32 0, i32 0
  %t882 = load i64, i64* %t881
  %t883 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t880, i32 0, i32 2
  %t884 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t883
  %t885 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t880, i32 0, i32 3
  %t886 = load i32*, i32** %t885
  br label %table_read_end_158
table_read_end_158:
  %t887 = phi i64 [ 0, %table_read_null_156 ], [ %t882, %table_read_real_157 ]
  %t888 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_156 ], [ %t884, %table_read_real_157 ]
  %t889 = phi i32* [ null, %table_read_null_156 ], [ %t886, %table_read_real_157 ]
  %t890 = trunc i64 %t887 to i32
  %t891 = load i8*, i8** %t772
  %t892 = icmp eq i8* %t891, null
  br i1 %t892, label %table_read_null_159, label %table_read_real_160
table_read_null_159:
  br label %table_read_end_161
table_read_real_160:
  %t893 = bitcast i8* %t891 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t894 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t893, i32 0, i32 0
  %t895 = load i64, i64* %t894
  %t896 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t893, i32 0, i32 2
  %t897 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t896
  %t898 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t893, i32 0, i32 3
  %t899 = load i32*, i32** %t898
  br label %table_read_end_161
table_read_end_161:
  %t900 = phi i64 [ 0, %table_read_null_159 ], [ %t895, %table_read_real_160 ]
  %t901 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_159 ], [ %t897, %table_read_real_160 ]
  %t902 = phi i32* [ null, %table_read_null_159 ], [ %t899, %table_read_real_160 ]
  %t903 = trunc i64 %t900 to i32
  %t904 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t904, i32 %t890, i32 %t903)
  %t906 = load i8*, i8** %t206
  %t907 = icmp eq i8* %t906, null
  br i1 %t907, label %table_cow_alloc_162, label %table_cow_check_163
table_cow_alloc_162:
  %t908 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t909 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t910 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t909 to i64
  %t911 = call i8* @star_rc_alloc(i64 %t910, i8* %t908)
  %t912 = bitcast i8* %t911 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t913 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t912, i32 0, i32 0
  store i64 0, i64* %t913
  %t914 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t912, i32 0, i32 1
  store i64 0, i64* %t914
  %t915 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t912, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t915
  %t916 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t912, i32 0, i32 3
  store i32* null, i32** %t916
  store i8* %t911, i8** %t206
  br label %table_cow_done_164
table_cow_check_163:
  %t917 = getelementptr inbounds i8, i8* %t906, i64 -16
  %t918 = bitcast i8* %t917 to i64*
  %t919 = load atomic i64, i64* %t918 seq_cst, align 8
  %t920 = icmp eq i64 %t919, 1
  br i1 %t920, label %table_cow_done_164, label %table_cow_clone_165
table_cow_clone_165:
  %t921 = bitcast i8* %t906 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t922 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t921, i32 0, i32 0
  %t923 = load i64, i64* %t922
  %t924 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t921, i32 0, i32 1
  %t925 = load i64, i64* %t924
  %t926 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t927 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t928 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t927 to i64
  %t929 = call i8* @star_rc_alloc(i64 %t928, i8* %t926)
  %t930 = bitcast i8* %t929 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t931 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t930, i32 0, i32 0
  store i64 %t923, i64* %t931
  %t932 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t930, i32 0, i32 1
  store i64 %t925, i64* %t932
  %t933 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t934 = ptrtoint { [2 x i8*], i64, i64 }* %t933 to i64
  %t935 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t921, i32 0, i32 2
  %t936 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t935
  %t937 = mul i64 %t925, %t934
  %t938 = call i8* @malloc(i64 %t937)
  %t939 = bitcast i8* %t938 to { [2 x i8*], i64, i64 }*
  %t940 = icmp sgt i64 %t923, 0
  br i1 %t940, label %table_cow_copy_166, label %table_cow_after_copy_167
table_cow_copy_166:
  %t941 = mul i64 %t923, %t934
  %t942 = bitcast { [2 x i8*], i64, i64 }* %t936 to i8*
  call i8* @memcpy(i8* %t938, i8* %t942, i64 %t941)
  store i64 0, i64* %t943
  br label %table_cow_retain_cond_168
table_cow_retain_cond_168:
  %t944 = load i64, i64* %t943
  %t945 = icmp slt i64 %t944, %t923
  br i1 %t945, label %table_cow_retain_body_169, label %table_cow_retain_end_170
table_cow_retain_body_169:
  %t946 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t939, i64 %t944
  %t947 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t946, i32 0, i32 0
  %t948 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t947, i32 0, i64 0
  %t949 = load i8*, i8** %t948
  call void @star_rc_retain(i8* %t949)
  %t950 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t947, i32 0, i64 1
  %t951 = load i8*, i8** %t950
  call void @star_rc_retain(i8* %t951)
  %t952 = add i64 %t944, 1
  store i64 %t952, i64* %t943
  br label %table_cow_retain_cond_168
table_cow_retain_end_170:
  br label %table_cow_after_copy_167
table_cow_after_copy_167:
  %t953 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t930, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t939, { [2 x i8*], i64, i64 }** %t953
  %t954 = getelementptr i32, i32* null, i32 1
  %t955 = ptrtoint i32* %t954 to i64
  %t956 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t921, i32 0, i32 3
  %t957 = load i32*, i32** %t956
  %t958 = mul i64 %t925, %t955
  %t959 = call i8* @malloc(i64 %t958)
  %t960 = bitcast i8* %t959 to i32*
  %t961 = icmp sgt i64 %t923, 0
  br i1 %t961, label %table_cow_copy_171, label %table_cow_after_copy_172
table_cow_copy_171:
  %t962 = mul i64 %t923, %t955
  %t963 = bitcast i32* %t957 to i8*
  call i8* @memcpy(i8* %t959, i8* %t963, i64 %t962)
  br label %table_cow_after_copy_172
table_cow_after_copy_172:
  %t964 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t930, i32 0, i32 3
  store i32* %t960, i32** %t964
  call void @star_rc_release(i8* %t906)
  store i8* %t929, i8** %t206
  br label %table_cow_done_164
table_cow_done_164:
  %t965 = load i8*, i8** %t206
  %t966 = bitcast i8* %t965 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t967 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t966, i32 0, i32 0
  %t968 = load i64, i64* %t967
  %t969 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t966, i32 0, i32 1
  %t970 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t966, i32 0, i32 2
  %t971 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t970
  %t972 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t966, i32 0, i32 3
  %t973 = load i32*, i32** %t972
  %t975 = icmp eq i64 %t968, 0
  br i1 %t975, label %table_pop_empty_173, label %table_pop_nonempty_174
table_pop_nonempty_174:
  %t976 = sub i64 %t968, 1
  store i64 %t976, i64* %t967
  %t977 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t971, i64 %t976
  %t978 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t977
  %t979 = getelementptr inbounds %Bag, %Bag* %t974, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t978, { [2 x i8*], i64, i64 }* %t979
  %t980 = getelementptr inbounds i32, i32* %t973, i64 %t976
  %t981 = load i32, i32* %t980
  %t982 = getelementptr inbounds %Bag, %Bag* %t974, i32 0, i32 1
  store i32 %t981, i32* %t982
  br label %table_pop_end_175
table_pop_empty_173:
  store %Bag zeroinitializer, %Bag* %t974
  br label %table_pop_end_175
table_pop_end_175:
  %t983 = load %Bag, %Bag* %t974
  store %Bag %t983, %Bag* %t905
  %t984 = getelementptr inbounds %Bag, %Bag* %t905, i32 0, i32 1
  %t985 = load i32, i32* %t984
  %t986 = getelementptr inbounds %Bag, %Bag* %t905, i32 0, i32 0
  %t987 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t986, i32 0, i32 0
  %t988 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t986, i32 0, i32 1
  %t989 = load i64, i64* %t988
  %t990 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t986, i32 0, i32 2
  %t991 = load i64, i64* %t990
  %t992 = trunc i64 %t991 to i32
  %t993 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t993, i32 %t985, i32 %t992)
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t994
  store i8* null, i8** %t995
  %t996 = load i8*, i8** %t995
  %t997 = icmp eq i8* %t996, null
  br i1 %t997, label %table_cow_alloc_176, label %table_cow_check_177
table_cow_alloc_176:
  %t1004 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1005 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1006 = ptrtoint { i64, i64, i32* }* %t1005 to i64
  %t1007 = call i8* @star_rc_alloc(i64 %t1006, i8* %t1004)
  %t1008 = bitcast i8* %t1007 to { i64, i64, i32* }*
  %t1009 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1008, i32 0, i32 0
  store i64 0, i64* %t1009
  %t1010 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1008, i32 0, i32 1
  store i64 0, i64* %t1010
  %t1011 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1008, i32 0, i32 2
  store i32* null, i32** %t1011
  store i8* %t1007, i8** %t995
  br label %table_cow_done_178
table_cow_check_177:
  %t1012 = getelementptr inbounds i8, i8* %t996, i64 -16
  %t1013 = bitcast i8* %t1012 to i64*
  %t1014 = load atomic i64, i64* %t1013 seq_cst, align 8
  %t1015 = icmp eq i64 %t1014, 1
  br i1 %t1015, label %table_cow_done_178, label %table_cow_clone_179
table_cow_clone_179:
  %t1016 = bitcast i8* %t996 to { i64, i64, i32* }*
  %t1017 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1016, i32 0, i32 0
  %t1018 = load i64, i64* %t1017
  %t1019 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1016, i32 0, i32 1
  %t1020 = load i64, i64* %t1019
  %t1021 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1022 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1023 = ptrtoint { i64, i64, i32* }* %t1022 to i64
  %t1024 = call i8* @star_rc_alloc(i64 %t1023, i8* %t1021)
  %t1025 = bitcast i8* %t1024 to { i64, i64, i32* }*
  %t1026 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1025, i32 0, i32 0
  store i64 %t1018, i64* %t1026
  %t1027 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1025, i32 0, i32 1
  store i64 %t1020, i64* %t1027
  %t1028 = getelementptr i32, i32* null, i32 1
  %t1029 = ptrtoint i32* %t1028 to i64
  %t1030 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1016, i32 0, i32 2
  %t1031 = load i32*, i32** %t1030
  %t1032 = mul i64 %t1020, %t1029
  %t1033 = call i8* @malloc(i64 %t1032)
  %t1034 = bitcast i8* %t1033 to i32*
  %t1035 = icmp sgt i64 %t1018, 0
  br i1 %t1035, label %table_cow_copy_180, label %table_cow_after_copy_181
table_cow_copy_180:
  %t1036 = mul i64 %t1018, %t1029
  %t1037 = bitcast i32* %t1031 to i8*
  call i8* @memcpy(i8* %t1033, i8* %t1037, i64 %t1036)
  br label %table_cow_after_copy_181
table_cow_after_copy_181:
  %t1038 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1025, i32 0, i32 2
  store i32* %t1034, i32** %t1038
  call void @star_rc_release(i8* %t996)
  store i8* %t1024, i8** %t995
  br label %table_cow_done_178
table_cow_done_178:
  %t1039 = load i8*, i8** %t995
  %t1040 = bitcast i8* %t1039 to { i64, i64, i32* }*
  %t1041 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1040, i32 0, i32 0
  %t1042 = load i64, i64* %t1041
  %t1043 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1040, i32 0, i32 1
  %t1044 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1040, i32 0, i32 2
  %t1045 = load i32*, i32** %t1044
  %t1047 = getelementptr inbounds %Item, %Item* %t1046, i32 0, i32 0
  store i32 1, i32* %t1047
  %t1048 = load %Item, %Item* %t1046
  %t1049 = load i64, i64* %t1043
  %t1050 = load i64, i64* %t1041
  %t1051 = load i32*, i32** %t1044
  %t1052 = icmp sge i64 %t1050, %t1049
  br i1 %t1052, label %table_push_grow_182, label %table_push_store_183
table_push_grow_182:
  %t1053 = mul i64 %t1049, 2
  %t1054 = icmp sgt i64 %t1053, 0
  %t1055 = select i1 %t1054, i64 %t1053, i64 1
  %t1056 = getelementptr i32, i32* null, i32 1
  %t1057 = ptrtoint i32* %t1056 to i64
  %t1058 = mul i64 %t1055, %t1057
  %t1059 = call i8* @malloc(i64 %t1058)
  %t1060 = bitcast i8* %t1059 to i32*
  %t1061 = icmp sgt i64 %t1049, 0
  br i1 %t1061, label %table_push_copy_184, label %table_push_after_copy_185
table_push_copy_184:
  %t1062 = mul i64 %t1050, %t1057
  %t1063 = bitcast i32* %t1051 to i8*
  call i8* @memcpy(i8* %t1059, i8* %t1063, i64 %t1062)
  call void @free(i8* %t1063)
  br label %table_push_after_copy_185
table_push_after_copy_185:
  store i32* %t1060, i32** %t1044
  store i64 %t1055, i64* %t1043
  br label %table_push_store_183
table_push_store_183:
  %t1064 = load i32*, i32** %t1044
  %t1065 = extractvalue %Item %t1048, 0
  %t1066 = getelementptr inbounds i32, i32* %t1064, i64 %t1050
  store i32 %t1065, i32* %t1066
  %t1067 = add i64 %t1050, 1
  store i64 %t1067, i64* %t1041
  %t1068 = load i8*, i8** %t995
  %t1069 = load i8*, i8** %t995
  call void @star_rc_retain(i8* %t1069)
  %t1070 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1071 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1072 = load i64, i64* %t1071
  %t1073 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1074 = load i64, i64* %t1073
  %t1075 = icmp sge i64 %t1074, 2
  br i1 %t1075, label %ring_push_full_186, label %ring_push_grow_187
ring_push_grow_187:
  %t1076 = add i64 %t1072, %t1074
  %t1077 = urem i64 %t1076, 2
  %t1078 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1070, i32 0, i64 %t1077
  store i8* %t1068, i8** %t1078
  %t1079 = add i64 %t1074, 1
  store i64 %t1079, i64* %t1073
  br label %ring_push_done_188
ring_push_full_186:
  %t1080 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1070, i32 0, i64 %t1072
  %t1081 = load i8*, i8** %t1080
  call void @star_rc_release(i8* %t1081)
  store i8* %t1068, i8** %t1080
  %t1082 = add i64 %t1072, 1
  %t1083 = urem i64 %t1082, 2
  store i64 %t1083, i64* %t1071
  br label %ring_push_done_188
ring_push_done_188:
  store i8* null, i8** %t1084
  %t1085 = load i8*, i8** %t1084
  %t1086 = icmp eq i8* %t1085, null
  br i1 %t1086, label %table_cow_alloc_189, label %table_cow_check_190
table_cow_alloc_189:
  %t1087 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1088 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1089 = ptrtoint { i64, i64, i32* }* %t1088 to i64
  %t1090 = call i8* @star_rc_alloc(i64 %t1089, i8* %t1087)
  %t1091 = bitcast i8* %t1090 to { i64, i64, i32* }*
  %t1092 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1091, i32 0, i32 0
  store i64 0, i64* %t1092
  %t1093 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1091, i32 0, i32 1
  store i64 0, i64* %t1093
  %t1094 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1091, i32 0, i32 2
  store i32* null, i32** %t1094
  store i8* %t1090, i8** %t1084
  br label %table_cow_done_191
table_cow_check_190:
  %t1095 = getelementptr inbounds i8, i8* %t1085, i64 -16
  %t1096 = bitcast i8* %t1095 to i64*
  %t1097 = load atomic i64, i64* %t1096 seq_cst, align 8
  %t1098 = icmp eq i64 %t1097, 1
  br i1 %t1098, label %table_cow_done_191, label %table_cow_clone_192
table_cow_clone_192:
  %t1099 = bitcast i8* %t1085 to { i64, i64, i32* }*
  %t1100 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1099, i32 0, i32 0
  %t1101 = load i64, i64* %t1100
  %t1102 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1099, i32 0, i32 1
  %t1103 = load i64, i64* %t1102
  %t1104 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1105 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1106 = ptrtoint { i64, i64, i32* }* %t1105 to i64
  %t1107 = call i8* @star_rc_alloc(i64 %t1106, i8* %t1104)
  %t1108 = bitcast i8* %t1107 to { i64, i64, i32* }*
  %t1109 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1108, i32 0, i32 0
  store i64 %t1101, i64* %t1109
  %t1110 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1108, i32 0, i32 1
  store i64 %t1103, i64* %t1110
  %t1111 = getelementptr i32, i32* null, i32 1
  %t1112 = ptrtoint i32* %t1111 to i64
  %t1113 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1099, i32 0, i32 2
  %t1114 = load i32*, i32** %t1113
  %t1115 = mul i64 %t1103, %t1112
  %t1116 = call i8* @malloc(i64 %t1115)
  %t1117 = bitcast i8* %t1116 to i32*
  %t1118 = icmp sgt i64 %t1101, 0
  br i1 %t1118, label %table_cow_copy_193, label %table_cow_after_copy_194
table_cow_copy_193:
  %t1119 = mul i64 %t1101, %t1112
  %t1120 = bitcast i32* %t1114 to i8*
  call i8* @memcpy(i8* %t1116, i8* %t1120, i64 %t1119)
  br label %table_cow_after_copy_194
table_cow_after_copy_194:
  %t1121 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1108, i32 0, i32 2
  store i32* %t1117, i32** %t1121
  call void @star_rc_release(i8* %t1085)
  store i8* %t1107, i8** %t1084
  br label %table_cow_done_191
table_cow_done_191:
  %t1122 = load i8*, i8** %t1084
  %t1123 = bitcast i8* %t1122 to { i64, i64, i32* }*
  %t1124 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1123, i32 0, i32 0
  %t1125 = load i64, i64* %t1124
  %t1126 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1123, i32 0, i32 1
  %t1127 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1123, i32 0, i32 2
  %t1128 = load i32*, i32** %t1127
  %t1130 = getelementptr inbounds %Item, %Item* %t1129, i32 0, i32 0
  store i32 2, i32* %t1130
  %t1131 = load %Item, %Item* %t1129
  %t1132 = load i64, i64* %t1126
  %t1133 = load i64, i64* %t1124
  %t1134 = load i32*, i32** %t1127
  %t1135 = icmp sge i64 %t1133, %t1132
  br i1 %t1135, label %table_push_grow_195, label %table_push_store_196
table_push_grow_195:
  %t1136 = mul i64 %t1132, 2
  %t1137 = icmp sgt i64 %t1136, 0
  %t1138 = select i1 %t1137, i64 %t1136, i64 1
  %t1139 = getelementptr i32, i32* null, i32 1
  %t1140 = ptrtoint i32* %t1139 to i64
  %t1141 = mul i64 %t1138, %t1140
  %t1142 = call i8* @malloc(i64 %t1141)
  %t1143 = bitcast i8* %t1142 to i32*
  %t1144 = icmp sgt i64 %t1132, 0
  br i1 %t1144, label %table_push_copy_197, label %table_push_after_copy_198
table_push_copy_197:
  %t1145 = mul i64 %t1133, %t1140
  %t1146 = bitcast i32* %t1134 to i8*
  call i8* @memcpy(i8* %t1142, i8* %t1146, i64 %t1145)
  call void @free(i8* %t1146)
  br label %table_push_after_copy_198
table_push_after_copy_198:
  store i32* %t1143, i32** %t1127
  store i64 %t1138, i64* %t1126
  br label %table_push_store_196
table_push_store_196:
  %t1147 = load i32*, i32** %t1127
  %t1148 = extractvalue %Item %t1131, 0
  %t1149 = getelementptr inbounds i32, i32* %t1147, i64 %t1133
  store i32 %t1148, i32* %t1149
  %t1150 = add i64 %t1133, 1
  store i64 %t1150, i64* %t1124
  %t1151 = load i8*, i8** %t1084
  %t1152 = icmp eq i8* %t1151, null
  br i1 %t1152, label %table_cow_alloc_199, label %table_cow_check_200
table_cow_alloc_199:
  %t1153 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1154 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1155 = ptrtoint { i64, i64, i32* }* %t1154 to i64
  %t1156 = call i8* @star_rc_alloc(i64 %t1155, i8* %t1153)
  %t1157 = bitcast i8* %t1156 to { i64, i64, i32* }*
  %t1158 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1157, i32 0, i32 0
  store i64 0, i64* %t1158
  %t1159 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1157, i32 0, i32 1
  store i64 0, i64* %t1159
  %t1160 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1157, i32 0, i32 2
  store i32* null, i32** %t1160
  store i8* %t1156, i8** %t1084
  br label %table_cow_done_201
table_cow_check_200:
  %t1161 = getelementptr inbounds i8, i8* %t1151, i64 -16
  %t1162 = bitcast i8* %t1161 to i64*
  %t1163 = load atomic i64, i64* %t1162 seq_cst, align 8
  %t1164 = icmp eq i64 %t1163, 1
  br i1 %t1164, label %table_cow_done_201, label %table_cow_clone_202
table_cow_clone_202:
  %t1165 = bitcast i8* %t1151 to { i64, i64, i32* }*
  %t1166 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1165, i32 0, i32 0
  %t1167 = load i64, i64* %t1166
  %t1168 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1165, i32 0, i32 1
  %t1169 = load i64, i64* %t1168
  %t1170 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1171 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1172 = ptrtoint { i64, i64, i32* }* %t1171 to i64
  %t1173 = call i8* @star_rc_alloc(i64 %t1172, i8* %t1170)
  %t1174 = bitcast i8* %t1173 to { i64, i64, i32* }*
  %t1175 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1174, i32 0, i32 0
  store i64 %t1167, i64* %t1175
  %t1176 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1174, i32 0, i32 1
  store i64 %t1169, i64* %t1176
  %t1177 = getelementptr i32, i32* null, i32 1
  %t1178 = ptrtoint i32* %t1177 to i64
  %t1179 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1165, i32 0, i32 2
  %t1180 = load i32*, i32** %t1179
  %t1181 = mul i64 %t1169, %t1178
  %t1182 = call i8* @malloc(i64 %t1181)
  %t1183 = bitcast i8* %t1182 to i32*
  %t1184 = icmp sgt i64 %t1167, 0
  br i1 %t1184, label %table_cow_copy_203, label %table_cow_after_copy_204
table_cow_copy_203:
  %t1185 = mul i64 %t1167, %t1178
  %t1186 = bitcast i32* %t1180 to i8*
  call i8* @memcpy(i8* %t1182, i8* %t1186, i64 %t1185)
  br label %table_cow_after_copy_204
table_cow_after_copy_204:
  %t1187 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1174, i32 0, i32 2
  store i32* %t1183, i32** %t1187
  call void @star_rc_release(i8* %t1151)
  store i8* %t1173, i8** %t1084
  br label %table_cow_done_201
table_cow_done_201:
  %t1188 = load i8*, i8** %t1084
  %t1189 = bitcast i8* %t1188 to { i64, i64, i32* }*
  %t1190 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1189, i32 0, i32 0
  %t1191 = load i64, i64* %t1190
  %t1192 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1189, i32 0, i32 1
  %t1193 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1189, i32 0, i32 2
  %t1194 = load i32*, i32** %t1193
  %t1196 = getelementptr inbounds %Item, %Item* %t1195, i32 0, i32 0
  store i32 3, i32* %t1196
  %t1197 = load %Item, %Item* %t1195
  %t1198 = load i64, i64* %t1192
  %t1199 = load i64, i64* %t1190
  %t1200 = load i32*, i32** %t1193
  %t1201 = icmp sge i64 %t1199, %t1198
  br i1 %t1201, label %table_push_grow_205, label %table_push_store_206
table_push_grow_205:
  %t1202 = mul i64 %t1198, 2
  %t1203 = icmp sgt i64 %t1202, 0
  %t1204 = select i1 %t1203, i64 %t1202, i64 1
  %t1205 = getelementptr i32, i32* null, i32 1
  %t1206 = ptrtoint i32* %t1205 to i64
  %t1207 = mul i64 %t1204, %t1206
  %t1208 = call i8* @malloc(i64 %t1207)
  %t1209 = bitcast i8* %t1208 to i32*
  %t1210 = icmp sgt i64 %t1198, 0
  br i1 %t1210, label %table_push_copy_207, label %table_push_after_copy_208
table_push_copy_207:
  %t1211 = mul i64 %t1199, %t1206
  %t1212 = bitcast i32* %t1200 to i8*
  call i8* @memcpy(i8* %t1208, i8* %t1212, i64 %t1211)
  call void @free(i8* %t1212)
  br label %table_push_after_copy_208
table_push_after_copy_208:
  store i32* %t1209, i32** %t1193
  store i64 %t1204, i64* %t1192
  br label %table_push_store_206
table_push_store_206:
  %t1213 = load i32*, i32** %t1193
  %t1214 = extractvalue %Item %t1197, 0
  %t1215 = getelementptr inbounds i32, i32* %t1213, i64 %t1199
  store i32 %t1214, i32* %t1215
  %t1216 = add i64 %t1199, 1
  store i64 %t1216, i64* %t1190
  %t1217 = load i8*, i8** %t1084
  %t1218 = load i8*, i8** %t1084
  call void @star_rc_retain(i8* %t1218)
  %t1219 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1220 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1221 = load i64, i64* %t1220
  %t1222 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1223 = load i64, i64* %t1222
  %t1224 = icmp sge i64 %t1223, 2
  br i1 %t1224, label %ring_push_full_209, label %ring_push_grow_210
ring_push_grow_210:
  %t1225 = add i64 %t1221, %t1223
  %t1226 = urem i64 %t1225, 2
  %t1227 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1219, i32 0, i64 %t1226
  store i8* %t1217, i8** %t1227
  %t1228 = add i64 %t1223, 1
  store i64 %t1228, i64* %t1222
  br label %ring_push_done_211
ring_push_full_209:
  %t1229 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1219, i32 0, i64 %t1221
  %t1230 = load i8*, i8** %t1229
  call void @star_rc_release(i8* %t1230)
  store i8* %t1217, i8** %t1229
  %t1231 = add i64 %t1221, 1
  %t1232 = urem i64 %t1231, 2
  store i64 %t1232, i64* %t1220
  br label %ring_push_done_211
ring_push_done_211:
  %t1233 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1234 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1235 = load i64, i64* %t1234
  %t1236 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1237 = load i64, i64* %t1236
  %t1238 = trunc i64 %t1237 to i32
  %t1239 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1240 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1241 = load i64, i64* %t1240
  %t1242 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1243 = load i64, i64* %t1242
  %t1244 = sext i32 0 to i64
  %t1245 = load i64, i64* %t1240
  %t1246 = load i64, i64* %t1242
  %t1247 = icmp ult i64 %t1244, %t1246
  br i1 %t1247, label %ring_rplace_ok_212, label %ring_rplace_oob_213
ring_rplace_ok_212:
  %t1248 = add i64 %t1245, %t1244
  %t1249 = urem i64 %t1248, 2
  %t1250 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1239, i32 0, i64 %t1249
  br label %ring_rplace_end_214
ring_rplace_oob_213:
  store i8* null, i8** %t1251
  br label %ring_rplace_end_214
ring_rplace_end_214:
  %t1252 = phi i8** [ %t1250, %ring_rplace_ok_212 ], [ %t1251, %ring_rplace_oob_213 ]
  %t1253 = load i8*, i8** %t1252
  %t1254 = icmp eq i8* %t1253, null
  br i1 %t1254, label %table_read_null_215, label %table_read_real_216
table_read_null_215:
  br label %table_read_end_217
table_read_real_216:
  %t1255 = bitcast i8* %t1253 to { i64, i64, i32* }*
  %t1256 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1255, i32 0, i32 0
  %t1257 = load i64, i64* %t1256
  %t1258 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1255, i32 0, i32 2
  %t1259 = load i32*, i32** %t1258
  br label %table_read_end_217
table_read_end_217:
  %t1260 = phi i64 [ 0, %table_read_null_215 ], [ %t1257, %table_read_real_216 ]
  %t1261 = phi i32* [ null, %table_read_null_215 ], [ %t1259, %table_read_real_216 ]
  %t1262 = trunc i64 %t1260 to i32
  %t1263 = sext i32 0 to i64
  %t1264 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1265 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1266 = load i64, i64* %t1265
  %t1267 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1268 = load i64, i64* %t1267
  %t1269 = sext i32 0 to i64
  %t1270 = load i64, i64* %t1265
  %t1271 = load i64, i64* %t1267
  %t1272 = icmp ult i64 %t1269, %t1271
  br i1 %t1272, label %ring_rplace_ok_218, label %ring_rplace_oob_219
ring_rplace_ok_218:
  %t1273 = add i64 %t1270, %t1269
  %t1274 = urem i64 %t1273, 2
  %t1275 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1264, i32 0, i64 %t1274
  br label %ring_rplace_end_220
ring_rplace_oob_219:
  store i8* null, i8** %t1276
  br label %ring_rplace_end_220
ring_rplace_end_220:
  %t1277 = phi i8** [ %t1275, %ring_rplace_ok_218 ], [ %t1276, %ring_rplace_oob_219 ]
  %t1278 = load i8*, i8** %t1277
  %t1279 = icmp eq i8* %t1278, null
  br i1 %t1279, label %table_read_null_221, label %table_read_real_222
table_read_null_221:
  br label %table_read_end_223
table_read_real_222:
  %t1280 = bitcast i8* %t1278 to { i64, i64, i32* }*
  %t1281 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1280, i32 0, i32 0
  %t1282 = load i64, i64* %t1281
  %t1283 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1280, i32 0, i32 2
  %t1284 = load i32*, i32** %t1283
  br label %table_read_end_223
table_read_end_223:
  %t1285 = phi i64 [ 0, %table_read_null_221 ], [ %t1282, %table_read_real_222 ]
  %t1286 = phi i32* [ null, %table_read_null_221 ], [ %t1284, %table_read_real_222 ]
  %t1288 = icmp ult i64 %t1263, %t1285
  br i1 %t1288, label %table_idx_ok_224, label %table_idx_oob_225
table_idx_ok_224:
  %t1289 = getelementptr inbounds i32, i32* %t1286, i64 %t1263
  %t1290 = load i32, i32* %t1289
  %t1291 = getelementptr inbounds %Item, %Item* %t1287, i32 0, i32 0
  store i32 %t1290, i32* %t1291
  br label %table_idx_end_226
table_idx_oob_225:
  store %Item zeroinitializer, %Item* %t1287
  br label %table_idx_end_226
table_idx_end_226:
  %t1292 = load %Item, %Item* %t1287
  store %Item %t1292, %Item* %t1293
  %t1294 = getelementptr inbounds %Item, %Item* %t1293, i32 0, i32 0
  %t1295 = load i32, i32* %t1294
  %t1296 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1296, i32 %t1238, i32 %t1262, i32 %t1295)
  %t1297 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1298 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1299 = load i64, i64* %t1298
  %t1300 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1301 = load i64, i64* %t1300
  %t1302 = sext i32 1 to i64
  %t1303 = load i64, i64* %t1298
  %t1304 = load i64, i64* %t1300
  %t1305 = icmp ult i64 %t1302, %t1304
  br i1 %t1305, label %ring_rplace_ok_227, label %ring_rplace_oob_228
ring_rplace_ok_227:
  %t1306 = add i64 %t1303, %t1302
  %t1307 = urem i64 %t1306, 2
  %t1308 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1297, i32 0, i64 %t1307
  br label %ring_rplace_end_229
ring_rplace_oob_228:
  store i8* null, i8** %t1309
  br label %ring_rplace_end_229
ring_rplace_end_229:
  %t1310 = phi i8** [ %t1308, %ring_rplace_ok_227 ], [ %t1309, %ring_rplace_oob_228 ]
  %t1311 = load i8*, i8** %t1310
  %t1312 = icmp eq i8* %t1311, null
  br i1 %t1312, label %table_read_null_230, label %table_read_real_231
table_read_null_230:
  br label %table_read_end_232
table_read_real_231:
  %t1313 = bitcast i8* %t1311 to { i64, i64, i32* }*
  %t1314 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1313, i32 0, i32 0
  %t1315 = load i64, i64* %t1314
  %t1316 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1313, i32 0, i32 2
  %t1317 = load i32*, i32** %t1316
  br label %table_read_end_232
table_read_end_232:
  %t1318 = phi i64 [ 0, %table_read_null_230 ], [ %t1315, %table_read_real_231 ]
  %t1319 = phi i32* [ null, %table_read_null_230 ], [ %t1317, %table_read_real_231 ]
  %t1320 = trunc i64 %t1318 to i32
  %t1321 = sext i32 0 to i64
  %t1322 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1323 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1324 = load i64, i64* %t1323
  %t1325 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1326 = load i64, i64* %t1325
  %t1327 = sext i32 1 to i64
  %t1328 = load i64, i64* %t1323
  %t1329 = load i64, i64* %t1325
  %t1330 = icmp ult i64 %t1327, %t1329
  br i1 %t1330, label %ring_rplace_ok_233, label %ring_rplace_oob_234
ring_rplace_ok_233:
  %t1331 = add i64 %t1328, %t1327
  %t1332 = urem i64 %t1331, 2
  %t1333 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1322, i32 0, i64 %t1332
  br label %ring_rplace_end_235
ring_rplace_oob_234:
  store i8* null, i8** %t1334
  br label %ring_rplace_end_235
ring_rplace_end_235:
  %t1335 = phi i8** [ %t1333, %ring_rplace_ok_233 ], [ %t1334, %ring_rplace_oob_234 ]
  %t1336 = load i8*, i8** %t1335
  %t1337 = icmp eq i8* %t1336, null
  br i1 %t1337, label %table_read_null_236, label %table_read_real_237
table_read_null_236:
  br label %table_read_end_238
table_read_real_237:
  %t1338 = bitcast i8* %t1336 to { i64, i64, i32* }*
  %t1339 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1338, i32 0, i32 0
  %t1340 = load i64, i64* %t1339
  %t1341 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1338, i32 0, i32 2
  %t1342 = load i32*, i32** %t1341
  br label %table_read_end_238
table_read_end_238:
  %t1343 = phi i64 [ 0, %table_read_null_236 ], [ %t1340, %table_read_real_237 ]
  %t1344 = phi i32* [ null, %table_read_null_236 ], [ %t1342, %table_read_real_237 ]
  %t1346 = icmp ult i64 %t1321, %t1343
  br i1 %t1346, label %table_idx_ok_239, label %table_idx_oob_240
table_idx_ok_239:
  %t1347 = getelementptr inbounds i32, i32* %t1344, i64 %t1321
  %t1348 = load i32, i32* %t1347
  %t1349 = getelementptr inbounds %Item, %Item* %t1345, i32 0, i32 0
  store i32 %t1348, i32* %t1349
  br label %table_idx_end_241
table_idx_oob_240:
  store %Item zeroinitializer, %Item* %t1345
  br label %table_idx_end_241
table_idx_end_241:
  %t1350 = load %Item, %Item* %t1345
  store %Item %t1350, %Item* %t1351
  %t1352 = getelementptr inbounds %Item, %Item* %t1351, i32 0, i32 0
  %t1353 = load i32, i32* %t1352
  %t1354 = sext i32 1 to i64
  %t1355 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1356 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1357 = load i64, i64* %t1356
  %t1358 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1359 = load i64, i64* %t1358
  %t1360 = sext i32 1 to i64
  %t1361 = load i64, i64* %t1356
  %t1362 = load i64, i64* %t1358
  %t1363 = icmp ult i64 %t1360, %t1362
  br i1 %t1363, label %ring_rplace_ok_242, label %ring_rplace_oob_243
ring_rplace_ok_242:
  %t1364 = add i64 %t1361, %t1360
  %t1365 = urem i64 %t1364, 2
  %t1366 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1355, i32 0, i64 %t1365
  br label %ring_rplace_end_244
ring_rplace_oob_243:
  store i8* null, i8** %t1367
  br label %ring_rplace_end_244
ring_rplace_end_244:
  %t1368 = phi i8** [ %t1366, %ring_rplace_ok_242 ], [ %t1367, %ring_rplace_oob_243 ]
  %t1369 = load i8*, i8** %t1368
  %t1370 = icmp eq i8* %t1369, null
  br i1 %t1370, label %table_read_null_245, label %table_read_real_246
table_read_null_245:
  br label %table_read_end_247
table_read_real_246:
  %t1371 = bitcast i8* %t1369 to { i64, i64, i32* }*
  %t1372 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1371, i32 0, i32 0
  %t1373 = load i64, i64* %t1372
  %t1374 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1371, i32 0, i32 2
  %t1375 = load i32*, i32** %t1374
  br label %table_read_end_247
table_read_end_247:
  %t1376 = phi i64 [ 0, %table_read_null_245 ], [ %t1373, %table_read_real_246 ]
  %t1377 = phi i32* [ null, %table_read_null_245 ], [ %t1375, %table_read_real_246 ]
  %t1379 = icmp ult i64 %t1354, %t1376
  br i1 %t1379, label %table_idx_ok_248, label %table_idx_oob_249
table_idx_ok_248:
  %t1380 = getelementptr inbounds i32, i32* %t1377, i64 %t1354
  %t1381 = load i32, i32* %t1380
  %t1382 = getelementptr inbounds %Item, %Item* %t1378, i32 0, i32 0
  store i32 %t1381, i32* %t1382
  br label %table_idx_end_250
table_idx_oob_249:
  store %Item zeroinitializer, %Item* %t1378
  br label %table_idx_end_250
table_idx_end_250:
  %t1383 = load %Item, %Item* %t1378
  store %Item %t1383, %Item* %t1384
  %t1385 = getelementptr inbounds %Item, %Item* %t1384, i32 0, i32 0
  %t1386 = load i32, i32* %t1385
  %t1387 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1387, i32 %t1320, i32 %t1353, i32 %t1386)
  store i8* null, i8** %t1388
  %t1389 = load i8*, i8** %t1388
  %t1390 = icmp eq i8* %t1389, null
  br i1 %t1390, label %table_cow_alloc_251, label %table_cow_check_252
table_cow_alloc_251:
  %t1391 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1392 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1393 = ptrtoint { i64, i64, i32* }* %t1392 to i64
  %t1394 = call i8* @star_rc_alloc(i64 %t1393, i8* %t1391)
  %t1395 = bitcast i8* %t1394 to { i64, i64, i32* }*
  %t1396 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1395, i32 0, i32 0
  store i64 0, i64* %t1396
  %t1397 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1395, i32 0, i32 1
  store i64 0, i64* %t1397
  %t1398 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1395, i32 0, i32 2
  store i32* null, i32** %t1398
  store i8* %t1394, i8** %t1388
  br label %table_cow_done_253
table_cow_check_252:
  %t1399 = getelementptr inbounds i8, i8* %t1389, i64 -16
  %t1400 = bitcast i8* %t1399 to i64*
  %t1401 = load atomic i64, i64* %t1400 seq_cst, align 8
  %t1402 = icmp eq i64 %t1401, 1
  br i1 %t1402, label %table_cow_done_253, label %table_cow_clone_254
table_cow_clone_254:
  %t1403 = bitcast i8* %t1389 to { i64, i64, i32* }*
  %t1404 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1403, i32 0, i32 0
  %t1405 = load i64, i64* %t1404
  %t1406 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1403, i32 0, i32 1
  %t1407 = load i64, i64* %t1406
  %t1408 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1409 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1410 = ptrtoint { i64, i64, i32* }* %t1409 to i64
  %t1411 = call i8* @star_rc_alloc(i64 %t1410, i8* %t1408)
  %t1412 = bitcast i8* %t1411 to { i64, i64, i32* }*
  %t1413 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1412, i32 0, i32 0
  store i64 %t1405, i64* %t1413
  %t1414 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1412, i32 0, i32 1
  store i64 %t1407, i64* %t1414
  %t1415 = getelementptr i32, i32* null, i32 1
  %t1416 = ptrtoint i32* %t1415 to i64
  %t1417 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1403, i32 0, i32 2
  %t1418 = load i32*, i32** %t1417
  %t1419 = mul i64 %t1407, %t1416
  %t1420 = call i8* @malloc(i64 %t1419)
  %t1421 = bitcast i8* %t1420 to i32*
  %t1422 = icmp sgt i64 %t1405, 0
  br i1 %t1422, label %table_cow_copy_255, label %table_cow_after_copy_256
table_cow_copy_255:
  %t1423 = mul i64 %t1405, %t1416
  %t1424 = bitcast i32* %t1418 to i8*
  call i8* @memcpy(i8* %t1420, i8* %t1424, i64 %t1423)
  br label %table_cow_after_copy_256
table_cow_after_copy_256:
  %t1425 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1412, i32 0, i32 2
  store i32* %t1421, i32** %t1425
  call void @star_rc_release(i8* %t1389)
  store i8* %t1411, i8** %t1388
  br label %table_cow_done_253
table_cow_done_253:
  %t1426 = load i8*, i8** %t1388
  %t1427 = bitcast i8* %t1426 to { i64, i64, i32* }*
  %t1428 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1427, i32 0, i32 0
  %t1429 = load i64, i64* %t1428
  %t1430 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1427, i32 0, i32 1
  %t1431 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1427, i32 0, i32 2
  %t1432 = load i32*, i32** %t1431
  %t1434 = getelementptr inbounds %Item, %Item* %t1433, i32 0, i32 0
  store i32 9, i32* %t1434
  %t1435 = load %Item, %Item* %t1433
  %t1436 = load i64, i64* %t1430
  %t1437 = load i64, i64* %t1428
  %t1438 = load i32*, i32** %t1431
  %t1439 = icmp sge i64 %t1437, %t1436
  br i1 %t1439, label %table_push_grow_257, label %table_push_store_258
table_push_grow_257:
  %t1440 = mul i64 %t1436, 2
  %t1441 = icmp sgt i64 %t1440, 0
  %t1442 = select i1 %t1441, i64 %t1440, i64 1
  %t1443 = getelementptr i32, i32* null, i32 1
  %t1444 = ptrtoint i32* %t1443 to i64
  %t1445 = mul i64 %t1442, %t1444
  %t1446 = call i8* @malloc(i64 %t1445)
  %t1447 = bitcast i8* %t1446 to i32*
  %t1448 = icmp sgt i64 %t1436, 0
  br i1 %t1448, label %table_push_copy_259, label %table_push_after_copy_260
table_push_copy_259:
  %t1449 = mul i64 %t1437, %t1444
  %t1450 = bitcast i32* %t1438 to i8*
  call i8* @memcpy(i8* %t1446, i8* %t1450, i64 %t1449)
  call void @free(i8* %t1450)
  br label %table_push_after_copy_260
table_push_after_copy_260:
  store i32* %t1447, i32** %t1431
  store i64 %t1442, i64* %t1430
  br label %table_push_store_258
table_push_store_258:
  %t1451 = load i32*, i32** %t1431
  %t1452 = extractvalue %Item %t1435, 0
  %t1453 = getelementptr inbounds i32, i32* %t1451, i64 %t1437
  store i32 %t1452, i32* %t1453
  %t1454 = add i64 %t1437, 1
  store i64 %t1454, i64* %t1428
  %t1455 = load i8*, i8** %t1388
  %t1456 = load i8*, i8** %t1388
  call void @star_rc_retain(i8* %t1456)
  %t1457 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1458 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1459 = load i64, i64* %t1458
  %t1460 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1461 = load i64, i64* %t1460
  %t1462 = icmp sge i64 %t1461, 2
  br i1 %t1462, label %ring_push_full_261, label %ring_push_grow_262
ring_push_grow_262:
  %t1463 = add i64 %t1459, %t1461
  %t1464 = urem i64 %t1463, 2
  %t1465 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1457, i32 0, i64 %t1464
  store i8* %t1455, i8** %t1465
  %t1466 = add i64 %t1461, 1
  store i64 %t1466, i64* %t1460
  br label %ring_push_done_263
ring_push_full_261:
  %t1467 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1457, i32 0, i64 %t1459
  %t1468 = load i8*, i8** %t1467
  call void @star_rc_release(i8* %t1468)
  store i8* %t1455, i8** %t1467
  %t1469 = add i64 %t1459, 1
  %t1470 = urem i64 %t1469, 2
  store i64 %t1470, i64* %t1458
  br label %ring_push_done_263
ring_push_done_263:
  %t1471 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1472 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1473 = load i64, i64* %t1472
  %t1474 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1475 = load i64, i64* %t1474
  %t1476 = trunc i64 %t1475 to i32
  %t1477 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1478 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1479 = load i64, i64* %t1478
  %t1480 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1481 = load i64, i64* %t1480
  %t1482 = sext i32 0 to i64
  %t1483 = load i64, i64* %t1478
  %t1484 = load i64, i64* %t1480
  %t1485 = icmp ult i64 %t1482, %t1484
  br i1 %t1485, label %ring_rplace_ok_264, label %ring_rplace_oob_265
ring_rplace_ok_264:
  %t1486 = add i64 %t1483, %t1482
  %t1487 = urem i64 %t1486, 2
  %t1488 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1477, i32 0, i64 %t1487
  br label %ring_rplace_end_266
ring_rplace_oob_265:
  store i8* null, i8** %t1489
  br label %ring_rplace_end_266
ring_rplace_end_266:
  %t1490 = phi i8** [ %t1488, %ring_rplace_ok_264 ], [ %t1489, %ring_rplace_oob_265 ]
  %t1491 = load i8*, i8** %t1490
  %t1492 = icmp eq i8* %t1491, null
  br i1 %t1492, label %table_read_null_267, label %table_read_real_268
table_read_null_267:
  br label %table_read_end_269
table_read_real_268:
  %t1493 = bitcast i8* %t1491 to { i64, i64, i32* }*
  %t1494 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1493, i32 0, i32 0
  %t1495 = load i64, i64* %t1494
  %t1496 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1493, i32 0, i32 2
  %t1497 = load i32*, i32** %t1496
  br label %table_read_end_269
table_read_end_269:
  %t1498 = phi i64 [ 0, %table_read_null_267 ], [ %t1495, %table_read_real_268 ]
  %t1499 = phi i32* [ null, %table_read_null_267 ], [ %t1497, %table_read_real_268 ]
  %t1500 = trunc i64 %t1498 to i32
  %t1501 = sext i32 0 to i64
  %t1502 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1503 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 1
  %t1504 = load i64, i64* %t1503
  %t1505 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 2
  %t1506 = load i64, i64* %t1505
  %t1507 = sext i32 0 to i64
  %t1508 = load i64, i64* %t1503
  %t1509 = load i64, i64* %t1505
  %t1510 = icmp ult i64 %t1507, %t1509
  br i1 %t1510, label %ring_rplace_ok_270, label %ring_rplace_oob_271
ring_rplace_ok_270:
  %t1511 = add i64 %t1508, %t1507
  %t1512 = urem i64 %t1511, 2
  %t1513 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1502, i32 0, i64 %t1512
  br label %ring_rplace_end_272
ring_rplace_oob_271:
  store i8* null, i8** %t1514
  br label %ring_rplace_end_272
ring_rplace_end_272:
  %t1515 = phi i8** [ %t1513, %ring_rplace_ok_270 ], [ %t1514, %ring_rplace_oob_271 ]
  %t1516 = load i8*, i8** %t1515
  %t1517 = icmp eq i8* %t1516, null
  br i1 %t1517, label %table_read_null_273, label %table_read_real_274
table_read_null_273:
  br label %table_read_end_275
table_read_real_274:
  %t1518 = bitcast i8* %t1516 to { i64, i64, i32* }*
  %t1519 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1518, i32 0, i32 0
  %t1520 = load i64, i64* %t1519
  %t1521 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1518, i32 0, i32 2
  %t1522 = load i32*, i32** %t1521
  br label %table_read_end_275
table_read_end_275:
  %t1523 = phi i64 [ 0, %table_read_null_273 ], [ %t1520, %table_read_real_274 ]
  %t1524 = phi i32* [ null, %table_read_null_273 ], [ %t1522, %table_read_real_274 ]
  %t1526 = icmp ult i64 %t1501, %t1523
  br i1 %t1526, label %table_idx_ok_276, label %table_idx_oob_277
table_idx_ok_276:
  %t1527 = getelementptr inbounds i32, i32* %t1524, i64 %t1501
  %t1528 = load i32, i32* %t1527
  %t1529 = getelementptr inbounds %Item, %Item* %t1525, i32 0, i32 0
  store i32 %t1528, i32* %t1529
  br label %table_idx_end_278
table_idx_oob_277:
  store %Item zeroinitializer, %Item* %t1525
  br label %table_idx_end_278
table_idx_end_278:
  %t1530 = load %Item, %Item* %t1525
  store %Item %t1530, %Item* %t1531
  %t1532 = getelementptr inbounds %Item, %Item* %t1531, i32 0, i32 0
  %t1533 = load i32, i32* %t1532
  %t1534 = getelementptr inbounds [45 x i8], [45 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1534, i32 %t1476, i32 %t1500, i32 %t1533)
  %t1535 = load i8*, i8** %t1388
  call void @star_rc_release(i8* %t1535)
  %t1536 = load i8*, i8** %t1084
  call void @star_rc_release(i8* %t1536)
  %t1537 = load i8*, i8** %t995
  call void @star_rc_release(i8* %t1537)
  %t1538 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t994, i32 0, i32 0
  %t1539 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1538, i32 0, i64 0
  %t1540 = load i8*, i8** %t1539
  call void @star_rc_release(i8* %t1540)
  %t1541 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1538, i32 0, i64 1
  %t1542 = load i8*, i8** %t1541
  call void @star_rc_release(i8* %t1542)
  %t1543 = getelementptr inbounds %Bag, %Bag* %t905, i32 0, i32 0
  %t1544 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1543, i32 0, i32 0
  %t1545 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1544, i32 0, i64 0
  %t1546 = load i8*, i8** %t1545
  call void @star_rc_release(i8* %t1546)
  %t1547 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1544, i32 0, i64 1
  %t1548 = load i8*, i8** %t1547
  call void @star_rc_release(i8* %t1548)
  %t1549 = load i8*, i8** %t772
  call void @star_rc_release(i8* %t1549)
  %t1550 = getelementptr inbounds %Bag, %Bag* %t753, i32 0, i32 0
  %t1551 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1550, i32 0, i32 0
  %t1552 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1551, i32 0, i64 0
  %t1553 = load i8*, i8** %t1552
  call void @star_rc_release(i8* %t1553)
  %t1554 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1551, i32 0, i64 1
  %t1555 = load i8*, i8** %t1554
  call void @star_rc_release(i8* %t1555)
  %t1556 = getelementptr inbounds %Bag, %Bag* %t718, i32 0, i32 0
  %t1557 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1556, i32 0, i32 0
  %t1558 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1557, i32 0, i64 0
  %t1559 = load i8*, i8** %t1558
  call void @star_rc_release(i8* %t1559)
  %t1560 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1557, i32 0, i64 1
  %t1561 = load i8*, i8** %t1560
  call void @star_rc_release(i8* %t1561)
  %t1562 = getelementptr inbounds %Bag, %Bag* %t688, i32 0, i32 0
  %t1563 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1562, i32 0, i32 0
  %t1564 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1563, i32 0, i64 0
  %t1565 = load i8*, i8** %t1564
  call void @star_rc_release(i8* %t1565)
  %t1566 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1563, i32 0, i64 1
  %t1567 = load i8*, i8** %t1566
  call void @star_rc_release(i8* %t1567)
  %t1568 = getelementptr inbounds %Bag, %Bag* %t642, i32 0, i32 0
  %t1569 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1568, i32 0, i32 0
  %t1570 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1569, i32 0, i64 0
  %t1571 = load i8*, i8** %t1570
  call void @star_rc_release(i8* %t1571)
  %t1572 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1569, i32 0, i64 1
  %t1573 = load i8*, i8** %t1572
  call void @star_rc_release(i8* %t1573)
  %t1574 = getelementptr inbounds %Bag, %Bag* %t597, i32 0, i32 0
  %t1575 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1574, i32 0, i32 0
  %t1576 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1575, i32 0, i64 0
  %t1577 = load i8*, i8** %t1576
  call void @star_rc_release(i8* %t1577)
  %t1578 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1575, i32 0, i64 1
  %t1579 = load i8*, i8** %t1578
  call void @star_rc_release(i8* %t1579)
  %t1580 = getelementptr inbounds %Bag, %Bag* %t562, i32 0, i32 0
  %t1581 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1580, i32 0, i32 0
  %t1582 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1581, i32 0, i64 0
  %t1583 = load i8*, i8** %t1582
  call void @star_rc_release(i8* %t1583)
  %t1584 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1581, i32 0, i64 1
  %t1585 = load i8*, i8** %t1584
  call void @star_rc_release(i8* %t1585)
  %t1586 = getelementptr inbounds %Bag, %Bag* %t532, i32 0, i32 0
  %t1587 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1586, i32 0, i32 0
  %t1588 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1587, i32 0, i64 0
  %t1589 = load i8*, i8** %t1588
  call void @star_rc_release(i8* %t1589)
  %t1590 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1587, i32 0, i64 1
  %t1591 = load i8*, i8** %t1590
  call void @star_rc_release(i8* %t1591)
  %t1592 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t366, i32 0, i32 0
  %t1593 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1592, i32 0, i64 0
  %t1594 = load i8*, i8** %t1593
  call void @star_rc_release(i8* %t1594)
  %t1595 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1592, i32 0, i64 1
  %t1596 = load i8*, i8** %t1595
  call void @star_rc_release(i8* %t1596)
  %t1597 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t207, i32 0, i32 0
  %t1598 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1597, i32 0, i64 0
  %t1599 = load i8*, i8** %t1598
  call void @star_rc_release(i8* %t1599)
  %t1600 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1597, i32 0, i64 1
  %t1601 = load i8*, i8** %t1600
  call void @star_rc_release(i8* %t1601)
  %t1602 = load i8*, i8** %t206
  call void @star_rc_release(i8* %t1602)
  %t1603 = getelementptr inbounds %Snapshot, %Snapshot* %t88, i32 0, i32 2
  %t1604 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1603, i32 0, i32 0
  %t1605 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1604, i32 0, i64 0
  %t1606 = getelementptr inbounds %Player, %Player* %t1605, i32 0, i32 0
  %t1607 = load i8*, i8** %t1606
  call void @star_rc_release(i8* %t1607)
  %t1608 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1604, i32 0, i64 1
  %t1609 = getelementptr inbounds %Player, %Player* %t1608, i32 0, i32 0
  %t1610 = load i8*, i8** %t1609
  call void @star_rc_release(i8* %t1610)
  %t1611 = getelementptr inbounds %Snapshot, %Snapshot* %t1, i32 0, i32 2
  %t1612 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1611, i32 0, i32 0
  %t1613 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1612, i32 0, i64 0
  %t1614 = getelementptr inbounds %Player, %Player* %t1613, i32 0, i32 0
  %t1615 = load i8*, i8** %t1614
  call void @star_rc_release(i8* %t1615)
  %t1616 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1612, i32 0, i64 1
  %t1617 = getelementptr inbounds %Player, %Player* %t1616, i32 0, i32 0
  %t1618 = load i8*, i8** %t1617
  call void @star_rc_release(i8* %t1618)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Bag(i8* %objp) {
entry:
  %t245 = alloca i64
  %t240 = bitcast i8* %objp to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t241 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t240, i32 0, i32 0
  %t242 = load i64, i64* %t241
  %t243 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t240, i32 0, i32 2
  %t244 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t243
  store i64 0, i64* %t245
  br label %table_release_cond_48
table_release_cond_48:
  %t246 = load i64, i64* %t245
  %t247 = icmp slt i64 %t246, %t242
  br i1 %t247, label %table_release_body_49, label %table_release_end_50
table_release_body_49:
  %t248 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t244, i64 %t246
  %t249 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t248, i32 0, i32 0
  %t250 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t249, i32 0, i64 0
  %t251 = load i8*, i8** %t250
  call void @star_rc_release(i8* %t251)
  %t252 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t249, i32 0, i64 1
  %t253 = load i8*, i8** %t252
  call void @star_rc_release(i8* %t253)
  %t254 = add i64 %t246, 1
  store i64 %t254, i64* %t245
  br label %table_release_cond_48
table_release_end_50:
  %t255 = bitcast { [2 x i8*], i64, i64 }* %t244 to i8*
  call void @free(i8* %t255)
  %t256 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t240, i32 0, i32 3
  %t257 = load i32*, i32** %t256
  %t258 = bitcast i32* %t257 to i8*
  call void @free(i8* %t258)
  ret void
}


define void @table_release_s_Item(i8* %objp) {
entry:
  %t998 = bitcast i8* %objp to { i64, i64, i32* }*
  %t999 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t998, i32 0, i32 0
  %t1000 = load i64, i64* %t999
  %t1001 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t998, i32 0, i32 2
  %t1002 = load i32*, i32** %t1001
  %t1003 = bitcast i32* %t1002 to i8*
  call void @free(i8* %t1003)
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
