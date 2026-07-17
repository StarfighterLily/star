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
  %t2 = alloca %Snapshot
  %t26 = alloca i32
  %t42 = alloca i32
  %t66 = alloca %Player
  %t84 = alloca %Player
  %t89 = alloca %Snapshot
  %t147 = alloca i32
  %t163 = alloca i32
  %t187 = alloca i32
  %t203 = alloca i32
  %t207 = alloca i8*
  %t208 = alloca { [2 x i8*], i64, i64 }
  %t295 = alloca i64
  %t326 = alloca %Bag
  %t367 = alloca { [2 x i8*], i64, i64 }
  %t420 = alloca i64
  %t451 = alloca %Bag
  %t519 = alloca %Bag
  %t535 = alloca %Bag
  %t551 = alloca %Bag
  %t567 = alloca %Bag
  %t588 = alloca %Bag
  %t604 = alloca %Bag
  %t618 = alloca i8*
  %t636 = alloca %Bag
  %t652 = alloca %Bag
  %t666 = alloca i8*
  %t685 = alloca %Bag
  %t701 = alloca %Bag
  %t717 = alloca %Bag
  %t733 = alloca %Bag
  %t754 = alloca %Bag
  %t770 = alloca %Bag
  %t784 = alloca i8*
  %t790 = alloca i8*
  %t830 = alloca i64
  %t861 = alloca %Bag
  %t923 = alloca %Bag
  %t961 = alloca i64
  %t992 = alloca %Bag
  %t1014 = alloca { [2 x i8*], i64, i64 }
  %t1015 = alloca i8*
  %t1066 = alloca %Item
  %t1104 = alloca i8*
  %t1149 = alloca %Item
  %t1215 = alloca %Item
  %t1271 = alloca i8*
  %t1296 = alloca i8*
  %t1307 = alloca %Item
  %t1314 = alloca %Item
  %t1330 = alloca i8*
  %t1355 = alloca i8*
  %t1366 = alloca %Item
  %t1373 = alloca %Item
  %t1389 = alloca i8*
  %t1400 = alloca %Item
  %t1407 = alloca %Item
  %t1411 = alloca i8*
  %t1456 = alloca %Item
  %t1512 = alloca i8*
  %t1537 = alloca i8*
  %t1548 = alloca %Item
  %t1555 = alloca %Item
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = call %Snapshot @make_snapshot()
  store %Snapshot %t3, %Snapshot* %t2
  %t4 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 1
  %t7 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t6, i32 0, i32 0
  %t8 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t6, i32 0, i32 1
  %t9 = load i64, i64* %t8
  %t10 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t6, i32 0, i32 2
  %t11 = load i64, i64* %t10
  %t12 = trunc i64 %t11 to i32
  %t13 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 1
  %t14 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t13, i32 0, i32 0
  %t15 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t13, i32 0, i32 1
  %t16 = load i64, i64* %t15
  %t17 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t13, i32 0, i32 2
  %t18 = load i64, i64* %t17
  %t19 = sext i32 0 to i64
  %t20 = load i64, i64* %t15
  %t21 = load i64, i64* %t17
  %t22 = icmp ult i64 %t19, %t21
  br i1 %t22, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t23 = add i64 %t20, %t19
  %t24 = urem i64 %t23, 3
  %t25 = getelementptr inbounds [3 x i32], [3 x i32]* %t14, i32 0, i64 %t24
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  store i32 0, i32* %t26
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t27 = phi i32* [ %t25, %ring_rplace_ok_9 ], [ %t26, %ring_rplace_oob_10 ]
  %t28 = load i32, i32* %t27
  %t29 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 1
  %t30 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t29, i32 0, i32 0
  %t31 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t29, i32 0, i32 1
  %t32 = load i64, i64* %t31
  %t33 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t29, i32 0, i32 2
  %t34 = load i64, i64* %t33
  %t35 = sext i32 1 to i64
  %t36 = load i64, i64* %t31
  %t37 = load i64, i64* %t33
  %t38 = icmp ult i64 %t35, %t37
  br i1 %t38, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t39 = add i64 %t36, %t35
  %t40 = urem i64 %t39, 3
  %t41 = getelementptr inbounds [3 x i32], [3 x i32]* %t30, i32 0, i64 %t40
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  store i32 0, i32* %t42
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t43 = phi i32* [ %t41, %ring_rplace_ok_12 ], [ %t42, %ring_rplace_oob_13 ]
  %t44 = load i32, i32* %t43
  %t45 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t45, i32 %t5, i32 %t12, i32 %t28, i32 %t44)
  %t46 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 2
  %t47 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t46, i32 0, i32 0
  %t48 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t46, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t46, i32 0, i32 2
  %t51 = load i64, i64* %t50
  %t52 = trunc i64 %t51 to i32
  %t53 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 2
  %t54 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t53, i32 0, i32 0
  %t55 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t53, i32 0, i32 1
  %t56 = load i64, i64* %t55
  %t57 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t53, i32 0, i32 2
  %t58 = load i64, i64* %t57
  %t59 = sext i32 0 to i64
  %t60 = load i64, i64* %t55
  %t61 = load i64, i64* %t57
  %t62 = icmp ult i64 %t59, %t61
  br i1 %t62, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t63 = add i64 %t60, %t59
  %t64 = urem i64 %t63, 2
  %t65 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t54, i32 0, i64 %t64
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  store %Player zeroinitializer, %Player* %t66
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t67 = phi %Player* [ %t65, %ring_rplace_ok_15 ], [ %t66, %ring_rplace_oob_16 ]
  %t68 = getelementptr inbounds %Player, %Player* %t67, i32 0, i32 0
  %t69 = load i8*, i8** %t68
  %t70 = load i8*, i8** %t68
  call void @star_rc_retain(i8* %t70)
  call void @star_rc_release(i8* %t69)
  %t71 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 2
  %t72 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t71, i32 0, i32 0
  %t73 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t71, i32 0, i32 1
  %t74 = load i64, i64* %t73
  %t75 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t71, i32 0, i32 2
  %t76 = load i64, i64* %t75
  %t77 = sext i32 0 to i64
  %t78 = load i64, i64* %t73
  %t79 = load i64, i64* %t75
  %t80 = icmp ult i64 %t77, %t79
  br i1 %t80, label %ring_rplace_ok_18, label %ring_rplace_oob_19
ring_rplace_ok_18:
  %t81 = add i64 %t78, %t77
  %t82 = urem i64 %t81, 2
  %t83 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t72, i32 0, i64 %t82
  br label %ring_rplace_end_20
ring_rplace_oob_19:
  store %Player zeroinitializer, %Player* %t84
  br label %ring_rplace_end_20
ring_rplace_end_20:
  %t85 = phi %Player* [ %t83, %ring_rplace_ok_18 ], [ %t84, %ring_rplace_oob_19 ]
  %t86 = getelementptr inbounds %Player, %Player* %t85, i32 0, i32 1
  %t87 = load i32, i32* %t86
  %t88 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t88, i32 %t52, i8* %t69, i32 %t87)
  %t90 = load %Snapshot, %Snapshot* %t2
  %t91 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 2
  %t92 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t91, i32 0, i32 0
  %t93 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t92, i32 0, i64 0
  %t94 = getelementptr inbounds %Player, %Player* %t93, i32 0, i32 0
  %t95 = load i8*, i8** %t94
  call void @star_rc_retain(i8* %t95)
  %t96 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t92, i32 0, i64 1
  %t97 = getelementptr inbounds %Player, %Player* %t96, i32 0, i32 0
  %t98 = load i8*, i8** %t97
  call void @star_rc_retain(i8* %t98)
  store %Snapshot %t90, %Snapshot* %t89
  %t99 = getelementptr inbounds %Snapshot, %Snapshot* %t89, i32 0, i32 1
  %t100 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t99, i32 0, i32 0
  %t101 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t99, i32 0, i32 1
  %t102 = load i64, i64* %t101
  %t103 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t99, i32 0, i32 2
  %t104 = load i64, i64* %t103
  %t105 = icmp sge i64 %t104, 3
  br i1 %t105, label %ring_push_full_21, label %ring_push_grow_22
ring_push_grow_22:
  %t106 = add i64 %t102, %t104
  %t107 = urem i64 %t106, 3
  %t108 = getelementptr inbounds [3 x i32], [3 x i32]* %t100, i32 0, i64 %t107
  store i32 3, i32* %t108
  %t109 = add i64 %t104, 1
  store i64 %t109, i64* %t103
  br label %ring_push_done_23
ring_push_full_21:
  %t110 = getelementptr inbounds [3 x i32], [3 x i32]* %t100, i32 0, i64 %t102
  store i32 3, i32* %t110
  %t111 = add i64 %t102, 1
  %t112 = urem i64 %t111, 3
  store i64 %t112, i64* %t101
  br label %ring_push_done_23
ring_push_done_23:
  %t113 = getelementptr inbounds %Snapshot, %Snapshot* %t89, i32 0, i32 1
  %t114 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t113, i32 0, i32 0
  %t115 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t113, i32 0, i32 1
  %t116 = load i64, i64* %t115
  %t117 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t113, i32 0, i32 2
  %t118 = load i64, i64* %t117
  %t119 = icmp sge i64 %t118, 3
  br i1 %t119, label %ring_push_full_24, label %ring_push_grow_25
ring_push_grow_25:
  %t120 = add i64 %t116, %t118
  %t121 = urem i64 %t120, 3
  %t122 = getelementptr inbounds [3 x i32], [3 x i32]* %t114, i32 0, i64 %t121
  store i32 4, i32* %t122
  %t123 = add i64 %t118, 1
  store i64 %t123, i64* %t117
  br label %ring_push_done_26
ring_push_full_24:
  %t124 = getelementptr inbounds [3 x i32], [3 x i32]* %t114, i32 0, i64 %t116
  store i32 4, i32* %t124
  %t125 = add i64 %t116, 1
  %t126 = urem i64 %t125, 3
  store i64 %t126, i64* %t115
  br label %ring_push_done_26
ring_push_done_26:
  %t127 = getelementptr inbounds %Snapshot, %Snapshot* %t89, i32 0, i32 1
  %t128 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t127, i32 0, i32 0
  %t129 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t127, i32 0, i32 1
  %t130 = load i64, i64* %t129
  %t131 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t127, i32 0, i32 2
  %t132 = load i64, i64* %t131
  %t133 = trunc i64 %t132 to i32
  %t134 = getelementptr inbounds %Snapshot, %Snapshot* %t89, i32 0, i32 1
  %t135 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t134, i32 0, i32 0
  %t136 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t134, i32 0, i32 1
  %t137 = load i64, i64* %t136
  %t138 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t134, i32 0, i32 2
  %t139 = load i64, i64* %t138
  %t140 = sext i32 0 to i64
  %t141 = load i64, i64* %t136
  %t142 = load i64, i64* %t138
  %t143 = icmp ult i64 %t140, %t142
  br i1 %t143, label %ring_rplace_ok_27, label %ring_rplace_oob_28
ring_rplace_ok_27:
  %t144 = add i64 %t141, %t140
  %t145 = urem i64 %t144, 3
  %t146 = getelementptr inbounds [3 x i32], [3 x i32]* %t135, i32 0, i64 %t145
  br label %ring_rplace_end_29
ring_rplace_oob_28:
  store i32 0, i32* %t147
  br label %ring_rplace_end_29
ring_rplace_end_29:
  %t148 = phi i32* [ %t146, %ring_rplace_ok_27 ], [ %t147, %ring_rplace_oob_28 ]
  %t149 = load i32, i32* %t148
  %t150 = getelementptr inbounds %Snapshot, %Snapshot* %t89, i32 0, i32 1
  %t151 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t150, i32 0, i32 0
  %t152 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t150, i32 0, i32 1
  %t153 = load i64, i64* %t152
  %t154 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t150, i32 0, i32 2
  %t155 = load i64, i64* %t154
  %t156 = sext i32 1 to i64
  %t157 = load i64, i64* %t152
  %t158 = load i64, i64* %t154
  %t159 = icmp ult i64 %t156, %t158
  br i1 %t159, label %ring_rplace_ok_30, label %ring_rplace_oob_31
ring_rplace_ok_30:
  %t160 = add i64 %t157, %t156
  %t161 = urem i64 %t160, 3
  %t162 = getelementptr inbounds [3 x i32], [3 x i32]* %t151, i32 0, i64 %t161
  br label %ring_rplace_end_32
ring_rplace_oob_31:
  store i32 0, i32* %t163
  br label %ring_rplace_end_32
ring_rplace_end_32:
  %t164 = phi i32* [ %t162, %ring_rplace_ok_30 ], [ %t163, %ring_rplace_oob_31 ]
  %t165 = load i32, i32* %t164
  %t166 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t166, i32 %t133, i32 %t149, i32 %t165)
  %t167 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 1
  %t168 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t167, i32 0, i32 0
  %t169 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t167, i32 0, i32 1
  %t170 = load i64, i64* %t169
  %t171 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t167, i32 0, i32 2
  %t172 = load i64, i64* %t171
  %t173 = trunc i64 %t172 to i32
  %t174 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 1
  %t175 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t174, i32 0, i32 0
  %t176 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t174, i32 0, i32 1
  %t177 = load i64, i64* %t176
  %t178 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t174, i32 0, i32 2
  %t179 = load i64, i64* %t178
  %t180 = sext i32 0 to i64
  %t181 = load i64, i64* %t176
  %t182 = load i64, i64* %t178
  %t183 = icmp ult i64 %t180, %t182
  br i1 %t183, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t184 = add i64 %t181, %t180
  %t185 = urem i64 %t184, 3
  %t186 = getelementptr inbounds [3 x i32], [3 x i32]* %t175, i32 0, i64 %t185
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  store i32 0, i32* %t187
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t188 = phi i32* [ %t186, %ring_rplace_ok_33 ], [ %t187, %ring_rplace_oob_34 ]
  %t189 = load i32, i32* %t188
  %t190 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 1
  %t191 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t190, i32 0, i32 0
  %t192 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t190, i32 0, i32 1
  %t193 = load i64, i64* %t192
  %t194 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t190, i32 0, i32 2
  %t195 = load i64, i64* %t194
  %t196 = sext i32 1 to i64
  %t197 = load i64, i64* %t192
  %t198 = load i64, i64* %t194
  %t199 = icmp ult i64 %t196, %t198
  br i1 %t199, label %ring_rplace_ok_36, label %ring_rplace_oob_37
ring_rplace_ok_36:
  %t200 = add i64 %t197, %t196
  %t201 = urem i64 %t200, 3
  %t202 = getelementptr inbounds [3 x i32], [3 x i32]* %t191, i32 0, i64 %t201
  br label %ring_rplace_end_38
ring_rplace_oob_37:
  store i32 0, i32* %t203
  br label %ring_rplace_end_38
ring_rplace_end_38:
  %t204 = phi i32* [ %t202, %ring_rplace_ok_36 ], [ %t203, %ring_rplace_oob_37 ]
  %t205 = load i32, i32* %t204
  %t206 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t206, i32 %t173, i32 %t189, i32 %t205)
  store i8* null, i8** %t207
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t208
  %t209 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t210 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208, i32 0, i32 0
  %t211 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208, i32 0, i32 1
  %t212 = load i64, i64* %t211
  %t213 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208, i32 0, i32 2
  %t214 = load i64, i64* %t213
  %t215 = icmp sge i64 %t214, 2
  br i1 %t215, label %ring_push_full_39, label %ring_push_grow_40
ring_push_grow_40:
  %t216 = add i64 %t212, %t214
  %t217 = urem i64 %t216, 2
  %t218 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t210, i32 0, i64 %t217
  store i8* %t209, i8** %t218
  %t219 = add i64 %t214, 1
  store i64 %t219, i64* %t213
  br label %ring_push_done_41
ring_push_full_39:
  %t220 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t210, i32 0, i64 %t212
  %t221 = load i8*, i8** %t220
  call void @star_rc_release(i8* %t221)
  store i8* %t209, i8** %t220
  %t222 = add i64 %t212, 1
  %t223 = urem i64 %t222, 2
  store i64 %t223, i64* %t211
  br label %ring_push_done_41
ring_push_done_41:
  %t224 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t225 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208, i32 0, i32 0
  %t226 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208, i32 0, i32 1
  %t227 = load i64, i64* %t226
  %t228 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208, i32 0, i32 2
  %t229 = load i64, i64* %t228
  %t230 = icmp sge i64 %t229, 2
  br i1 %t230, label %ring_push_full_42, label %ring_push_grow_43
ring_push_grow_43:
  %t231 = add i64 %t227, %t229
  %t232 = urem i64 %t231, 2
  %t233 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t225, i32 0, i64 %t232
  store i8* %t224, i8** %t233
  %t234 = add i64 %t229, 1
  store i64 %t234, i64* %t228
  br label %ring_push_done_44
ring_push_full_42:
  %t235 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t225, i32 0, i64 %t227
  %t236 = load i8*, i8** %t235
  call void @star_rc_release(i8* %t236)
  store i8* %t224, i8** %t235
  %t237 = add i64 %t227, 1
  %t238 = urem i64 %t237, 2
  store i64 %t238, i64* %t226
  br label %ring_push_done_44
ring_push_done_44:
  %t239 = load i8*, i8** %t207
  %t240 = icmp eq i8* %t239, null
  br i1 %t240, label %table_cow_alloc_45, label %table_cow_check_46
table_cow_alloc_45:
  %t260 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t261 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t262 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t261 to i64
  %t263 = call i8* @star_rc_alloc(i64 %t262, i8* %t260)
  %t264 = bitcast i8* %t263 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t265 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t264, i32 0, i32 0
  store i64 0, i64* %t265
  %t266 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t264, i32 0, i32 1
  store i64 0, i64* %t266
  %t267 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t264, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t267
  %t268 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t264, i32 0, i32 3
  store i32* null, i32** %t268
  store i8* %t263, i8** %t207
  br label %table_cow_done_47
table_cow_check_46:
  %t269 = getelementptr inbounds i8, i8* %t239, i64 -16
  %t270 = bitcast i8* %t269 to i64*
  %t271 = load atomic i64, i64* %t270 seq_cst, align 8
  %t272 = icmp eq i64 %t271, 1
  br i1 %t272, label %table_cow_done_47, label %table_cow_clone_51
table_cow_clone_51:
  %t273 = bitcast i8* %t239 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t274 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t273, i32 0, i32 0
  %t275 = load i64, i64* %t274
  %t276 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t273, i32 0, i32 1
  %t277 = load i64, i64* %t276
  %t278 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t279 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t280 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t279 to i64
  %t281 = call i8* @star_rc_alloc(i64 %t280, i8* %t278)
  %t282 = bitcast i8* %t281 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t283 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t282, i32 0, i32 0
  store i64 %t275, i64* %t283
  %t284 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t282, i32 0, i32 1
  store i64 %t277, i64* %t284
  %t285 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t286 = ptrtoint { [2 x i8*], i64, i64 }* %t285 to i64
  %t287 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t273, i32 0, i32 2
  %t288 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t287
  %t289 = mul i64 %t277, %t286
  %t290 = call i8* @malloc(i64 %t289)
  %t291 = bitcast i8* %t290 to { [2 x i8*], i64, i64 }*
  %t292 = icmp sgt i64 %t275, 0
  br i1 %t292, label %table_cow_copy_52, label %table_cow_after_copy_53
table_cow_copy_52:
  %t293 = mul i64 %t275, %t286
  %t294 = bitcast { [2 x i8*], i64, i64 }* %t288 to i8*
  call i8* @memcpy(i8* %t290, i8* %t294, i64 %t293)
  store i64 0, i64* %t295
  br label %table_cow_retain_cond_54
table_cow_retain_cond_54:
  %t296 = load i64, i64* %t295
  %t297 = icmp slt i64 %t296, %t275
  br i1 %t297, label %table_cow_retain_body_55, label %table_cow_retain_end_56
table_cow_retain_body_55:
  %t298 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t291, i64 %t296
  %t299 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t298, i32 0, i32 0
  %t300 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t299, i32 0, i64 0
  %t301 = load i8*, i8** %t300
  call void @star_rc_retain(i8* %t301)
  %t302 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t299, i32 0, i64 1
  %t303 = load i8*, i8** %t302
  call void @star_rc_retain(i8* %t303)
  %t304 = add i64 %t296, 1
  store i64 %t304, i64* %t295
  br label %table_cow_retain_cond_54
table_cow_retain_end_56:
  br label %table_cow_after_copy_53
table_cow_after_copy_53:
  %t305 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t282, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t291, { [2 x i8*], i64, i64 }** %t305
  %t306 = getelementptr i32, i32* null, i32 1
  %t307 = ptrtoint i32* %t306 to i64
  %t308 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t273, i32 0, i32 3
  %t309 = load i32*, i32** %t308
  %t310 = mul i64 %t277, %t307
  %t311 = call i8* @malloc(i64 %t310)
  %t312 = bitcast i8* %t311 to i32*
  %t313 = icmp sgt i64 %t275, 0
  br i1 %t313, label %table_cow_copy_57, label %table_cow_after_copy_58
table_cow_copy_57:
  %t314 = mul i64 %t275, %t307
  %t315 = bitcast i32* %t309 to i8*
  call i8* @memcpy(i8* %t311, i8* %t315, i64 %t314)
  br label %table_cow_after_copy_58
table_cow_after_copy_58:
  %t316 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t282, i32 0, i32 3
  store i32* %t312, i32** %t316
  call void @star_rc_release(i8* %t239)
  store i8* %t281, i8** %t207
  br label %table_cow_done_47
table_cow_done_47:
  %t317 = load i8*, i8** %t207
  %t318 = bitcast i8* %t317 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t319 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t318, i32 0, i32 0
  %t320 = load i64, i64* %t319
  %t321 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t318, i32 0, i32 1
  %t322 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t318, i32 0, i32 2
  %t323 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t322
  %t324 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t318, i32 0, i32 3
  %t325 = load i32*, i32** %t324
  %t327 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208
  %t328 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208, i32 0, i32 0
  %t329 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t328, i32 0, i64 0
  %t330 = load i8*, i8** %t329
  call void @star_rc_retain(i8* %t330)
  %t331 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t328, i32 0, i64 1
  %t332 = load i8*, i8** %t331
  call void @star_rc_retain(i8* %t332)
  %t333 = getelementptr inbounds %Bag, %Bag* %t326, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t327, { [2 x i8*], i64, i64 }* %t333
  %t334 = getelementptr inbounds %Bag, %Bag* %t326, i32 0, i32 1
  store i32 1, i32* %t334
  %t335 = load %Bag, %Bag* %t326
  %t336 = load i64, i64* %t321
  %t337 = load i64, i64* %t319
  %t338 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t322
  %t339 = load i32*, i32** %t324
  %t340 = icmp sge i64 %t337, %t336
  br i1 %t340, label %table_push_grow_59, label %table_push_store_60
table_push_grow_59:
  %t341 = mul i64 %t336, 2
  %t342 = icmp sgt i64 %t341, 0
  %t343 = select i1 %t342, i64 %t341, i64 1
  %t344 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t345 = ptrtoint { [2 x i8*], i64, i64 }* %t344 to i64
  %t346 = mul i64 %t343, %t345
  %t347 = call i8* @malloc(i64 %t346)
  %t348 = bitcast i8* %t347 to { [2 x i8*], i64, i64 }*
  %t349 = icmp sgt i64 %t336, 0
  br i1 %t349, label %table_push_copy_61, label %table_push_after_copy_62
table_push_copy_61:
  %t350 = mul i64 %t337, %t345
  %t351 = bitcast { [2 x i8*], i64, i64 }* %t338 to i8*
  call i8* @memcpy(i8* %t347, i8* %t351, i64 %t350)
  call void @free(i8* %t351)
  br label %table_push_after_copy_62
table_push_after_copy_62:
  store { [2 x i8*], i64, i64 }* %t348, { [2 x i8*], i64, i64 }** %t322
  %t352 = getelementptr i32, i32* null, i32 1
  %t353 = ptrtoint i32* %t352 to i64
  %t354 = mul i64 %t343, %t353
  %t355 = call i8* @malloc(i64 %t354)
  %t356 = bitcast i8* %t355 to i32*
  %t357 = icmp sgt i64 %t336, 0
  br i1 %t357, label %table_push_copy_63, label %table_push_after_copy_64
table_push_copy_63:
  %t358 = mul i64 %t337, %t353
  %t359 = bitcast i32* %t339 to i8*
  call i8* @memcpy(i8* %t355, i8* %t359, i64 %t358)
  call void @free(i8* %t359)
  br label %table_push_after_copy_64
table_push_after_copy_64:
  store i32* %t356, i32** %t324
  store i64 %t343, i64* %t321
  br label %table_push_store_60
table_push_store_60:
  %t360 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t322
  %t361 = extractvalue %Bag %t335, 0
  %t362 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t360, i64 %t337
  store { [2 x i8*], i64, i64 } %t361, { [2 x i8*], i64, i64 }* %t362
  %t363 = load i32*, i32** %t324
  %t364 = extractvalue %Bag %t335, 1
  %t365 = getelementptr inbounds i32, i32* %t363, i64 %t337
  store i32 %t364, i32* %t365
  %t366 = add i64 %t337, 1
  store i64 %t366, i64* %t319
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t367
  %t368 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t369 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t367, i32 0, i32 0
  %t370 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t367, i32 0, i32 1
  %t371 = load i64, i64* %t370
  %t372 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t367, i32 0, i32 2
  %t373 = load i64, i64* %t372
  %t374 = icmp sge i64 %t373, 2
  br i1 %t374, label %ring_push_full_65, label %ring_push_grow_66
ring_push_grow_66:
  %t375 = add i64 %t371, %t373
  %t376 = urem i64 %t375, 2
  %t377 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t369, i32 0, i64 %t376
  store i8* %t368, i8** %t377
  %t378 = add i64 %t373, 1
  store i64 %t378, i64* %t372
  br label %ring_push_done_67
ring_push_full_65:
  %t379 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t369, i32 0, i64 %t371
  %t380 = load i8*, i8** %t379
  call void @star_rc_release(i8* %t380)
  store i8* %t368, i8** %t379
  %t381 = add i64 %t371, 1
  %t382 = urem i64 %t381, 2
  store i64 %t382, i64* %t370
  br label %ring_push_done_67
ring_push_done_67:
  %t383 = load i8*, i8** %t207
  %t384 = icmp eq i8* %t383, null
  br i1 %t384, label %table_cow_alloc_68, label %table_cow_check_69
table_cow_alloc_68:
  %t385 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t386 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t387 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t386 to i64
  %t388 = call i8* @star_rc_alloc(i64 %t387, i8* %t385)
  %t389 = bitcast i8* %t388 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t390 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t389, i32 0, i32 0
  store i64 0, i64* %t390
  %t391 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t389, i32 0, i32 1
  store i64 0, i64* %t391
  %t392 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t389, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t392
  %t393 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t389, i32 0, i32 3
  store i32* null, i32** %t393
  store i8* %t388, i8** %t207
  br label %table_cow_done_70
table_cow_check_69:
  %t394 = getelementptr inbounds i8, i8* %t383, i64 -16
  %t395 = bitcast i8* %t394 to i64*
  %t396 = load atomic i64, i64* %t395 seq_cst, align 8
  %t397 = icmp eq i64 %t396, 1
  br i1 %t397, label %table_cow_done_70, label %table_cow_clone_71
table_cow_clone_71:
  %t398 = bitcast i8* %t383 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t399 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t398, i32 0, i32 0
  %t400 = load i64, i64* %t399
  %t401 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t398, i32 0, i32 1
  %t402 = load i64, i64* %t401
  %t403 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t404 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t405 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t404 to i64
  %t406 = call i8* @star_rc_alloc(i64 %t405, i8* %t403)
  %t407 = bitcast i8* %t406 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t408 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t407, i32 0, i32 0
  store i64 %t400, i64* %t408
  %t409 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t407, i32 0, i32 1
  store i64 %t402, i64* %t409
  %t410 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t411 = ptrtoint { [2 x i8*], i64, i64 }* %t410 to i64
  %t412 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t398, i32 0, i32 2
  %t413 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t412
  %t414 = mul i64 %t402, %t411
  %t415 = call i8* @malloc(i64 %t414)
  %t416 = bitcast i8* %t415 to { [2 x i8*], i64, i64 }*
  %t417 = icmp sgt i64 %t400, 0
  br i1 %t417, label %table_cow_copy_72, label %table_cow_after_copy_73
table_cow_copy_72:
  %t418 = mul i64 %t400, %t411
  %t419 = bitcast { [2 x i8*], i64, i64 }* %t413 to i8*
  call i8* @memcpy(i8* %t415, i8* %t419, i64 %t418)
  store i64 0, i64* %t420
  br label %table_cow_retain_cond_74
table_cow_retain_cond_74:
  %t421 = load i64, i64* %t420
  %t422 = icmp slt i64 %t421, %t400
  br i1 %t422, label %table_cow_retain_body_75, label %table_cow_retain_end_76
table_cow_retain_body_75:
  %t423 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t416, i64 %t421
  %t424 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t423, i32 0, i32 0
  %t425 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t424, i32 0, i64 0
  %t426 = load i8*, i8** %t425
  call void @star_rc_retain(i8* %t426)
  %t427 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t424, i32 0, i64 1
  %t428 = load i8*, i8** %t427
  call void @star_rc_retain(i8* %t428)
  %t429 = add i64 %t421, 1
  store i64 %t429, i64* %t420
  br label %table_cow_retain_cond_74
table_cow_retain_end_76:
  br label %table_cow_after_copy_73
table_cow_after_copy_73:
  %t430 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t407, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t416, { [2 x i8*], i64, i64 }** %t430
  %t431 = getelementptr i32, i32* null, i32 1
  %t432 = ptrtoint i32* %t431 to i64
  %t433 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t398, i32 0, i32 3
  %t434 = load i32*, i32** %t433
  %t435 = mul i64 %t402, %t432
  %t436 = call i8* @malloc(i64 %t435)
  %t437 = bitcast i8* %t436 to i32*
  %t438 = icmp sgt i64 %t400, 0
  br i1 %t438, label %table_cow_copy_77, label %table_cow_after_copy_78
table_cow_copy_77:
  %t439 = mul i64 %t400, %t432
  %t440 = bitcast i32* %t434 to i8*
  call i8* @memcpy(i8* %t436, i8* %t440, i64 %t439)
  br label %table_cow_after_copy_78
table_cow_after_copy_78:
  %t441 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t407, i32 0, i32 3
  store i32* %t437, i32** %t441
  call void @star_rc_release(i8* %t383)
  store i8* %t406, i8** %t207
  br label %table_cow_done_70
table_cow_done_70:
  %t442 = load i8*, i8** %t207
  %t443 = bitcast i8* %t442 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t444 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t443, i32 0, i32 0
  %t445 = load i64, i64* %t444
  %t446 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t443, i32 0, i32 1
  %t447 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t443, i32 0, i32 2
  %t448 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t447
  %t449 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t443, i32 0, i32 3
  %t450 = load i32*, i32** %t449
  %t452 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t367
  %t453 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t367, i32 0, i32 0
  %t454 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t453, i32 0, i64 0
  %t455 = load i8*, i8** %t454
  call void @star_rc_retain(i8* %t455)
  %t456 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t453, i32 0, i64 1
  %t457 = load i8*, i8** %t456
  call void @star_rc_retain(i8* %t457)
  %t458 = getelementptr inbounds %Bag, %Bag* %t451, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t452, { [2 x i8*], i64, i64 }* %t458
  %t459 = getelementptr inbounds %Bag, %Bag* %t451, i32 0, i32 1
  store i32 2, i32* %t459
  %t460 = load %Bag, %Bag* %t451
  %t461 = load i64, i64* %t446
  %t462 = load i64, i64* %t444
  %t463 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t447
  %t464 = load i32*, i32** %t449
  %t465 = icmp sge i64 %t462, %t461
  br i1 %t465, label %table_push_grow_79, label %table_push_store_80
table_push_grow_79:
  %t466 = mul i64 %t461, 2
  %t467 = icmp sgt i64 %t466, 0
  %t468 = select i1 %t467, i64 %t466, i64 1
  %t469 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t470 = ptrtoint { [2 x i8*], i64, i64 }* %t469 to i64
  %t471 = mul i64 %t468, %t470
  %t472 = call i8* @malloc(i64 %t471)
  %t473 = bitcast i8* %t472 to { [2 x i8*], i64, i64 }*
  %t474 = icmp sgt i64 %t461, 0
  br i1 %t474, label %table_push_copy_81, label %table_push_after_copy_82
table_push_copy_81:
  %t475 = mul i64 %t462, %t470
  %t476 = bitcast { [2 x i8*], i64, i64 }* %t463 to i8*
  call i8* @memcpy(i8* %t472, i8* %t476, i64 %t475)
  call void @free(i8* %t476)
  br label %table_push_after_copy_82
table_push_after_copy_82:
  store { [2 x i8*], i64, i64 }* %t473, { [2 x i8*], i64, i64 }** %t447
  %t477 = getelementptr i32, i32* null, i32 1
  %t478 = ptrtoint i32* %t477 to i64
  %t479 = mul i64 %t468, %t478
  %t480 = call i8* @malloc(i64 %t479)
  %t481 = bitcast i8* %t480 to i32*
  %t482 = icmp sgt i64 %t461, 0
  br i1 %t482, label %table_push_copy_83, label %table_push_after_copy_84
table_push_copy_83:
  %t483 = mul i64 %t462, %t478
  %t484 = bitcast i32* %t464 to i8*
  call i8* @memcpy(i8* %t480, i8* %t484, i64 %t483)
  call void @free(i8* %t484)
  br label %table_push_after_copy_84
table_push_after_copy_84:
  store i32* %t481, i32** %t449
  store i64 %t468, i64* %t446
  br label %table_push_store_80
table_push_store_80:
  %t485 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t447
  %t486 = extractvalue %Bag %t460, 0
  %t487 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t485, i64 %t462
  store { [2 x i8*], i64, i64 } %t486, { [2 x i8*], i64, i64 }* %t487
  %t488 = load i32*, i32** %t449
  %t489 = extractvalue %Bag %t460, 1
  %t490 = getelementptr inbounds i32, i32* %t488, i64 %t462
  store i32 %t489, i32* %t490
  %t491 = add i64 %t462, 1
  store i64 %t491, i64* %t444
  %t492 = load i8*, i8** %t207
  %t493 = icmp eq i8* %t492, null
  br i1 %t493, label %table_read_null_85, label %table_read_real_86
table_read_null_85:
  br label %table_read_end_87
table_read_real_86:
  %t494 = bitcast i8* %t492 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t495 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t494, i32 0, i32 0
  %t496 = load i64, i64* %t495
  %t497 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t494, i32 0, i32 2
  %t498 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t497
  %t499 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t494, i32 0, i32 3
  %t500 = load i32*, i32** %t499
  br label %table_read_end_87
table_read_end_87:
  %t501 = phi i64 [ 0, %table_read_null_85 ], [ %t496, %table_read_real_86 ]
  %t502 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_85 ], [ %t498, %table_read_real_86 ]
  %t503 = phi i32* [ null, %table_read_null_85 ], [ %t500, %table_read_real_86 ]
  %t504 = trunc i64 %t501 to i32
  %t505 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t505, i32 %t504)
  %t506 = sext i32 0 to i64
  %t507 = load i8*, i8** %t207
  %t508 = icmp eq i8* %t507, null
  br i1 %t508, label %table_read_null_88, label %table_read_real_89
table_read_null_88:
  br label %table_read_end_90
table_read_real_89:
  %t509 = bitcast i8* %t507 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t510 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t509, i32 0, i32 0
  %t511 = load i64, i64* %t510
  %t512 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t509, i32 0, i32 2
  %t513 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t512
  %t514 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t509, i32 0, i32 3
  %t515 = load i32*, i32** %t514
  br label %table_read_end_90
table_read_end_90:
  %t516 = phi i64 [ 0, %table_read_null_88 ], [ %t511, %table_read_real_89 ]
  %t517 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_88 ], [ %t513, %table_read_real_89 ]
  %t518 = phi i32* [ null, %table_read_null_88 ], [ %t515, %table_read_real_89 ]
  %t520 = icmp ult i64 %t506, %t516
  br i1 %t520, label %table_idx_ok_91, label %table_idx_oob_92
table_idx_ok_91:
  %t521 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t517, i64 %t506
  %t522 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t521, i32 0, i32 0
  %t523 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t522, i32 0, i64 0
  %t524 = load i8*, i8** %t523
  call void @star_rc_retain(i8* %t524)
  %t525 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t522, i32 0, i64 1
  %t526 = load i8*, i8** %t525
  call void @star_rc_retain(i8* %t526)
  %t527 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t521
  %t528 = getelementptr inbounds %Bag, %Bag* %t519, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t527, { [2 x i8*], i64, i64 }* %t528
  %t529 = getelementptr inbounds i32, i32* %t518, i64 %t506
  %t530 = load i32, i32* %t529
  %t531 = getelementptr inbounds %Bag, %Bag* %t519, i32 0, i32 1
  store i32 %t530, i32* %t531
  br label %table_idx_end_93
table_idx_oob_92:
  %t532 = getelementptr inbounds %Bag, %Bag* %t519, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t532
  %t533 = getelementptr inbounds %Bag, %Bag* %t519, i32 0, i32 1
  store i32 0, i32* %t533
  br label %table_idx_end_93
table_idx_end_93:
  %t534 = load %Bag, %Bag* %t519
  store %Bag %t534, %Bag* %t535
  %t536 = getelementptr inbounds %Bag, %Bag* %t535, i32 0, i32 1
  %t537 = load i32, i32* %t536
  %t538 = sext i32 0 to i64
  %t539 = load i8*, i8** %t207
  %t540 = icmp eq i8* %t539, null
  br i1 %t540, label %table_read_null_94, label %table_read_real_95
table_read_null_94:
  br label %table_read_end_96
table_read_real_95:
  %t541 = bitcast i8* %t539 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t542 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t541, i32 0, i32 0
  %t543 = load i64, i64* %t542
  %t544 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t541, i32 0, i32 2
  %t545 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t544
  %t546 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t541, i32 0, i32 3
  %t547 = load i32*, i32** %t546
  br label %table_read_end_96
table_read_end_96:
  %t548 = phi i64 [ 0, %table_read_null_94 ], [ %t543, %table_read_real_95 ]
  %t549 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_94 ], [ %t545, %table_read_real_95 ]
  %t550 = phi i32* [ null, %table_read_null_94 ], [ %t547, %table_read_real_95 ]
  %t552 = icmp ult i64 %t538, %t548
  br i1 %t552, label %table_idx_ok_97, label %table_idx_oob_98
table_idx_ok_97:
  %t553 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t549, i64 %t538
  %t554 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t553, i32 0, i32 0
  %t555 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t554, i32 0, i64 0
  %t556 = load i8*, i8** %t555
  call void @star_rc_retain(i8* %t556)
  %t557 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t554, i32 0, i64 1
  %t558 = load i8*, i8** %t557
  call void @star_rc_retain(i8* %t558)
  %t559 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t553
  %t560 = getelementptr inbounds %Bag, %Bag* %t551, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t559, { [2 x i8*], i64, i64 }* %t560
  %t561 = getelementptr inbounds i32, i32* %t550, i64 %t538
  %t562 = load i32, i32* %t561
  %t563 = getelementptr inbounds %Bag, %Bag* %t551, i32 0, i32 1
  store i32 %t562, i32* %t563
  br label %table_idx_end_99
table_idx_oob_98:
  %t564 = getelementptr inbounds %Bag, %Bag* %t551, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t564
  %t565 = getelementptr inbounds %Bag, %Bag* %t551, i32 0, i32 1
  store i32 0, i32* %t565
  br label %table_idx_end_99
table_idx_end_99:
  %t566 = load %Bag, %Bag* %t551
  store %Bag %t566, %Bag* %t567
  %t568 = getelementptr inbounds %Bag, %Bag* %t567, i32 0, i32 0
  %t569 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t568, i32 0, i32 0
  %t570 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t568, i32 0, i32 1
  %t571 = load i64, i64* %t570
  %t572 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t568, i32 0, i32 2
  %t573 = load i64, i64* %t572
  %t574 = trunc i64 %t573 to i32
  %t575 = sext i32 0 to i64
  %t576 = load i8*, i8** %t207
  %t577 = icmp eq i8* %t576, null
  br i1 %t577, label %table_read_null_100, label %table_read_real_101
table_read_null_100:
  br label %table_read_end_102
table_read_real_101:
  %t578 = bitcast i8* %t576 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t579 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t578, i32 0, i32 0
  %t580 = load i64, i64* %t579
  %t581 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t578, i32 0, i32 2
  %t582 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t581
  %t583 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t578, i32 0, i32 3
  %t584 = load i32*, i32** %t583
  br label %table_read_end_102
table_read_end_102:
  %t585 = phi i64 [ 0, %table_read_null_100 ], [ %t580, %table_read_real_101 ]
  %t586 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_100 ], [ %t582, %table_read_real_101 ]
  %t587 = phi i32* [ null, %table_read_null_100 ], [ %t584, %table_read_real_101 ]
  %t589 = icmp ult i64 %t575, %t585
  br i1 %t589, label %table_idx_ok_103, label %table_idx_oob_104
table_idx_ok_103:
  %t590 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t586, i64 %t575
  %t591 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t590, i32 0, i32 0
  %t592 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t591, i32 0, i64 0
  %t593 = load i8*, i8** %t592
  call void @star_rc_retain(i8* %t593)
  %t594 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t591, i32 0, i64 1
  %t595 = load i8*, i8** %t594
  call void @star_rc_retain(i8* %t595)
  %t596 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t590
  %t597 = getelementptr inbounds %Bag, %Bag* %t588, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t596, { [2 x i8*], i64, i64 }* %t597
  %t598 = getelementptr inbounds i32, i32* %t587, i64 %t575
  %t599 = load i32, i32* %t598
  %t600 = getelementptr inbounds %Bag, %Bag* %t588, i32 0, i32 1
  store i32 %t599, i32* %t600
  br label %table_idx_end_105
table_idx_oob_104:
  %t601 = getelementptr inbounds %Bag, %Bag* %t588, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t601
  %t602 = getelementptr inbounds %Bag, %Bag* %t588, i32 0, i32 1
  store i32 0, i32* %t602
  br label %table_idx_end_105
table_idx_end_105:
  %t603 = load %Bag, %Bag* %t588
  store %Bag %t603, %Bag* %t604
  %t605 = getelementptr inbounds %Bag, %Bag* %t604, i32 0, i32 0
  %t606 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t605, i32 0, i32 0
  %t607 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t605, i32 0, i32 1
  %t608 = load i64, i64* %t607
  %t609 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t605, i32 0, i32 2
  %t610 = load i64, i64* %t609
  %t611 = sext i32 0 to i64
  %t612 = load i64, i64* %t607
  %t613 = load i64, i64* %t609
  %t614 = icmp ult i64 %t611, %t613
  br i1 %t614, label %ring_rplace_ok_106, label %ring_rplace_oob_107
ring_rplace_ok_106:
  %t615 = add i64 %t612, %t611
  %t616 = urem i64 %t615, 2
  %t617 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t606, i32 0, i64 %t616
  br label %ring_rplace_end_108
ring_rplace_oob_107:
  %t619 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t619
  store i8* %t619, i8** %t618
  br label %ring_rplace_end_108
ring_rplace_end_108:
  %t620 = phi i8** [ %t617, %ring_rplace_ok_106 ], [ %t618, %ring_rplace_oob_107 ]
  %t621 = load i8*, i8** %t620
  %t622 = load i8*, i8** %t620
  call void @star_rc_retain(i8* %t622)
  call void @star_rc_release(i8* %t621)
  %t623 = sext i32 0 to i64
  %t624 = load i8*, i8** %t207
  %t625 = icmp eq i8* %t624, null
  br i1 %t625, label %table_read_null_109, label %table_read_real_110
table_read_null_109:
  br label %table_read_end_111
table_read_real_110:
  %t626 = bitcast i8* %t624 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t627 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t626, i32 0, i32 0
  %t628 = load i64, i64* %t627
  %t629 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t626, i32 0, i32 2
  %t630 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t629
  %t631 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t626, i32 0, i32 3
  %t632 = load i32*, i32** %t631
  br label %table_read_end_111
table_read_end_111:
  %t633 = phi i64 [ 0, %table_read_null_109 ], [ %t628, %table_read_real_110 ]
  %t634 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_109 ], [ %t630, %table_read_real_110 ]
  %t635 = phi i32* [ null, %table_read_null_109 ], [ %t632, %table_read_real_110 ]
  %t637 = icmp ult i64 %t623, %t633
  br i1 %t637, label %table_idx_ok_112, label %table_idx_oob_113
table_idx_ok_112:
  %t638 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t634, i64 %t623
  %t639 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t638, i32 0, i32 0
  %t640 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t639, i32 0, i64 0
  %t641 = load i8*, i8** %t640
  call void @star_rc_retain(i8* %t641)
  %t642 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t639, i32 0, i64 1
  %t643 = load i8*, i8** %t642
  call void @star_rc_retain(i8* %t643)
  %t644 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t638
  %t645 = getelementptr inbounds %Bag, %Bag* %t636, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t644, { [2 x i8*], i64, i64 }* %t645
  %t646 = getelementptr inbounds i32, i32* %t635, i64 %t623
  %t647 = load i32, i32* %t646
  %t648 = getelementptr inbounds %Bag, %Bag* %t636, i32 0, i32 1
  store i32 %t647, i32* %t648
  br label %table_idx_end_114
table_idx_oob_113:
  %t649 = getelementptr inbounds %Bag, %Bag* %t636, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t649
  %t650 = getelementptr inbounds %Bag, %Bag* %t636, i32 0, i32 1
  store i32 0, i32* %t650
  br label %table_idx_end_114
table_idx_end_114:
  %t651 = load %Bag, %Bag* %t636
  store %Bag %t651, %Bag* %t652
  %t653 = getelementptr inbounds %Bag, %Bag* %t652, i32 0, i32 0
  %t654 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t653, i32 0, i32 0
  %t655 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t653, i32 0, i32 1
  %t656 = load i64, i64* %t655
  %t657 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t653, i32 0, i32 2
  %t658 = load i64, i64* %t657
  %t659 = sext i32 1 to i64
  %t660 = load i64, i64* %t655
  %t661 = load i64, i64* %t657
  %t662 = icmp ult i64 %t659, %t661
  br i1 %t662, label %ring_rplace_ok_115, label %ring_rplace_oob_116
ring_rplace_ok_115:
  %t663 = add i64 %t660, %t659
  %t664 = urem i64 %t663, 2
  %t665 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t654, i32 0, i64 %t664
  br label %ring_rplace_end_117
ring_rplace_oob_116:
  %t667 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t667
  store i8* %t667, i8** %t666
  br label %ring_rplace_end_117
ring_rplace_end_117:
  %t668 = phi i8** [ %t665, %ring_rplace_ok_115 ], [ %t666, %ring_rplace_oob_116 ]
  %t669 = load i8*, i8** %t668
  %t670 = load i8*, i8** %t668
  call void @star_rc_retain(i8* %t670)
  call void @star_rc_release(i8* %t669)
  %t671 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t671, i32 %t537, i32 %t574, i8* %t621, i8* %t669)
  %t672 = sext i32 1 to i64
  %t673 = load i8*, i8** %t207
  %t674 = icmp eq i8* %t673, null
  br i1 %t674, label %table_read_null_118, label %table_read_real_119
table_read_null_118:
  br label %table_read_end_120
table_read_real_119:
  %t675 = bitcast i8* %t673 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t676 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t675, i32 0, i32 0
  %t677 = load i64, i64* %t676
  %t678 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t675, i32 0, i32 2
  %t679 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t678
  %t680 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t675, i32 0, i32 3
  %t681 = load i32*, i32** %t680
  br label %table_read_end_120
table_read_end_120:
  %t682 = phi i64 [ 0, %table_read_null_118 ], [ %t677, %table_read_real_119 ]
  %t683 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_118 ], [ %t679, %table_read_real_119 ]
  %t684 = phi i32* [ null, %table_read_null_118 ], [ %t681, %table_read_real_119 ]
  %t686 = icmp ult i64 %t672, %t682
  br i1 %t686, label %table_idx_ok_121, label %table_idx_oob_122
table_idx_ok_121:
  %t687 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t683, i64 %t672
  %t688 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t687, i32 0, i32 0
  %t689 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t688, i32 0, i64 0
  %t690 = load i8*, i8** %t689
  call void @star_rc_retain(i8* %t690)
  %t691 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t688, i32 0, i64 1
  %t692 = load i8*, i8** %t691
  call void @star_rc_retain(i8* %t692)
  %t693 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t687
  %t694 = getelementptr inbounds %Bag, %Bag* %t685, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t693, { [2 x i8*], i64, i64 }* %t694
  %t695 = getelementptr inbounds i32, i32* %t684, i64 %t672
  %t696 = load i32, i32* %t695
  %t697 = getelementptr inbounds %Bag, %Bag* %t685, i32 0, i32 1
  store i32 %t696, i32* %t697
  br label %table_idx_end_123
table_idx_oob_122:
  %t698 = getelementptr inbounds %Bag, %Bag* %t685, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t698
  %t699 = getelementptr inbounds %Bag, %Bag* %t685, i32 0, i32 1
  store i32 0, i32* %t699
  br label %table_idx_end_123
table_idx_end_123:
  %t700 = load %Bag, %Bag* %t685
  store %Bag %t700, %Bag* %t701
  %t702 = getelementptr inbounds %Bag, %Bag* %t701, i32 0, i32 1
  %t703 = load i32, i32* %t702
  %t704 = sext i32 1 to i64
  %t705 = load i8*, i8** %t207
  %t706 = icmp eq i8* %t705, null
  br i1 %t706, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t707 = bitcast i8* %t705 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t708 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t707, i32 0, i32 0
  %t709 = load i64, i64* %t708
  %t710 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t707, i32 0, i32 2
  %t711 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t710
  %t712 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t707, i32 0, i32 3
  %t713 = load i32*, i32** %t712
  br label %table_read_end_126
table_read_end_126:
  %t714 = phi i64 [ 0, %table_read_null_124 ], [ %t709, %table_read_real_125 ]
  %t715 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_124 ], [ %t711, %table_read_real_125 ]
  %t716 = phi i32* [ null, %table_read_null_124 ], [ %t713, %table_read_real_125 ]
  %t718 = icmp ult i64 %t704, %t714
  br i1 %t718, label %table_idx_ok_127, label %table_idx_oob_128
table_idx_ok_127:
  %t719 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t715, i64 %t704
  %t720 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t719, i32 0, i32 0
  %t721 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t720, i32 0, i64 0
  %t722 = load i8*, i8** %t721
  call void @star_rc_retain(i8* %t722)
  %t723 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t720, i32 0, i64 1
  %t724 = load i8*, i8** %t723
  call void @star_rc_retain(i8* %t724)
  %t725 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t719
  %t726 = getelementptr inbounds %Bag, %Bag* %t717, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t725, { [2 x i8*], i64, i64 }* %t726
  %t727 = getelementptr inbounds i32, i32* %t716, i64 %t704
  %t728 = load i32, i32* %t727
  %t729 = getelementptr inbounds %Bag, %Bag* %t717, i32 0, i32 1
  store i32 %t728, i32* %t729
  br label %table_idx_end_129
table_idx_oob_128:
  %t730 = getelementptr inbounds %Bag, %Bag* %t717, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t730
  %t731 = getelementptr inbounds %Bag, %Bag* %t717, i32 0, i32 1
  store i32 0, i32* %t731
  br label %table_idx_end_129
table_idx_end_129:
  %t732 = load %Bag, %Bag* %t717
  store %Bag %t732, %Bag* %t733
  %t734 = getelementptr inbounds %Bag, %Bag* %t733, i32 0, i32 0
  %t735 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t734, i32 0, i32 0
  %t736 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t734, i32 0, i32 1
  %t737 = load i64, i64* %t736
  %t738 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t734, i32 0, i32 2
  %t739 = load i64, i64* %t738
  %t740 = trunc i64 %t739 to i32
  %t741 = sext i32 1 to i64
  %t742 = load i8*, i8** %t207
  %t743 = icmp eq i8* %t742, null
  br i1 %t743, label %table_read_null_130, label %table_read_real_131
table_read_null_130:
  br label %table_read_end_132
table_read_real_131:
  %t744 = bitcast i8* %t742 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t745 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t744, i32 0, i32 0
  %t746 = load i64, i64* %t745
  %t747 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t744, i32 0, i32 2
  %t748 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t747
  %t749 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t744, i32 0, i32 3
  %t750 = load i32*, i32** %t749
  br label %table_read_end_132
table_read_end_132:
  %t751 = phi i64 [ 0, %table_read_null_130 ], [ %t746, %table_read_real_131 ]
  %t752 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_130 ], [ %t748, %table_read_real_131 ]
  %t753 = phi i32* [ null, %table_read_null_130 ], [ %t750, %table_read_real_131 ]
  %t755 = icmp ult i64 %t741, %t751
  br i1 %t755, label %table_idx_ok_133, label %table_idx_oob_134
table_idx_ok_133:
  %t756 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t752, i64 %t741
  %t757 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t756, i32 0, i32 0
  %t758 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t757, i32 0, i64 0
  %t759 = load i8*, i8** %t758
  call void @star_rc_retain(i8* %t759)
  %t760 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t757, i32 0, i64 1
  %t761 = load i8*, i8** %t760
  call void @star_rc_retain(i8* %t761)
  %t762 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t756
  %t763 = getelementptr inbounds %Bag, %Bag* %t754, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t762, { [2 x i8*], i64, i64 }* %t763
  %t764 = getelementptr inbounds i32, i32* %t753, i64 %t741
  %t765 = load i32, i32* %t764
  %t766 = getelementptr inbounds %Bag, %Bag* %t754, i32 0, i32 1
  store i32 %t765, i32* %t766
  br label %table_idx_end_135
table_idx_oob_134:
  %t767 = getelementptr inbounds %Bag, %Bag* %t754, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t767
  %t768 = getelementptr inbounds %Bag, %Bag* %t754, i32 0, i32 1
  store i32 0, i32* %t768
  br label %table_idx_end_135
table_idx_end_135:
  %t769 = load %Bag, %Bag* %t754
  store %Bag %t769, %Bag* %t770
  %t771 = getelementptr inbounds %Bag, %Bag* %t770, i32 0, i32 0
  %t772 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t771, i32 0, i32 0
  %t773 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t771, i32 0, i32 1
  %t774 = load i64, i64* %t773
  %t775 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t771, i32 0, i32 2
  %t776 = load i64, i64* %t775
  %t777 = sext i32 0 to i64
  %t778 = load i64, i64* %t773
  %t779 = load i64, i64* %t775
  %t780 = icmp ult i64 %t777, %t779
  br i1 %t780, label %ring_rplace_ok_136, label %ring_rplace_oob_137
ring_rplace_ok_136:
  %t781 = add i64 %t778, %t777
  %t782 = urem i64 %t781, 2
  %t783 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t772, i32 0, i64 %t782
  br label %ring_rplace_end_138
ring_rplace_oob_137:
  %t785 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t785
  store i8* %t785, i8** %t784
  br label %ring_rplace_end_138
ring_rplace_end_138:
  %t786 = phi i8** [ %t783, %ring_rplace_ok_136 ], [ %t784, %ring_rplace_oob_137 ]
  %t787 = load i8*, i8** %t786
  %t788 = load i8*, i8** %t786
  call void @star_rc_retain(i8* %t788)
  call void @star_rc_release(i8* %t787)
  %t789 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t789, i32 %t703, i32 %t740, i8* %t787)
  %t791 = load i8*, i8** %t207
  %t792 = load i8*, i8** %t207
  call void @star_rc_retain(i8* %t792)
  store i8* %t791, i8** %t790
  %t793 = load i8*, i8** %t207
  %t794 = icmp eq i8* %t793, null
  br i1 %t794, label %table_cow_alloc_139, label %table_cow_check_140
table_cow_alloc_139:
  %t795 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t796 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t797 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t796 to i64
  %t798 = call i8* @star_rc_alloc(i64 %t797, i8* %t795)
  %t799 = bitcast i8* %t798 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t800 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t799, i32 0, i32 0
  store i64 0, i64* %t800
  %t801 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t799, i32 0, i32 1
  store i64 0, i64* %t801
  %t802 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t799, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t802
  %t803 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t799, i32 0, i32 3
  store i32* null, i32** %t803
  store i8* %t798, i8** %t207
  br label %table_cow_done_141
table_cow_check_140:
  %t804 = getelementptr inbounds i8, i8* %t793, i64 -16
  %t805 = bitcast i8* %t804 to i64*
  %t806 = load atomic i64, i64* %t805 seq_cst, align 8
  %t807 = icmp eq i64 %t806, 1
  br i1 %t807, label %table_cow_done_141, label %table_cow_clone_142
table_cow_clone_142:
  %t808 = bitcast i8* %t793 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t809 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t808, i32 0, i32 0
  %t810 = load i64, i64* %t809
  %t811 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t808, i32 0, i32 1
  %t812 = load i64, i64* %t811
  %t813 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t814 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t815 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t814 to i64
  %t816 = call i8* @star_rc_alloc(i64 %t815, i8* %t813)
  %t817 = bitcast i8* %t816 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t818 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t817, i32 0, i32 0
  store i64 %t810, i64* %t818
  %t819 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t817, i32 0, i32 1
  store i64 %t812, i64* %t819
  %t820 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t821 = ptrtoint { [2 x i8*], i64, i64 }* %t820 to i64
  %t822 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t808, i32 0, i32 2
  %t823 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t822
  %t824 = mul i64 %t812, %t821
  %t825 = call i8* @malloc(i64 %t824)
  %t826 = bitcast i8* %t825 to { [2 x i8*], i64, i64 }*
  %t827 = icmp sgt i64 %t810, 0
  br i1 %t827, label %table_cow_copy_143, label %table_cow_after_copy_144
table_cow_copy_143:
  %t828 = mul i64 %t810, %t821
  %t829 = bitcast { [2 x i8*], i64, i64 }* %t823 to i8*
  call i8* @memcpy(i8* %t825, i8* %t829, i64 %t828)
  store i64 0, i64* %t830
  br label %table_cow_retain_cond_145
table_cow_retain_cond_145:
  %t831 = load i64, i64* %t830
  %t832 = icmp slt i64 %t831, %t810
  br i1 %t832, label %table_cow_retain_body_146, label %table_cow_retain_end_147
table_cow_retain_body_146:
  %t833 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t826, i64 %t831
  %t834 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t833, i32 0, i32 0
  %t835 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t834, i32 0, i64 0
  %t836 = load i8*, i8** %t835
  call void @star_rc_retain(i8* %t836)
  %t837 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t834, i32 0, i64 1
  %t838 = load i8*, i8** %t837
  call void @star_rc_retain(i8* %t838)
  %t839 = add i64 %t831, 1
  store i64 %t839, i64* %t830
  br label %table_cow_retain_cond_145
table_cow_retain_end_147:
  br label %table_cow_after_copy_144
table_cow_after_copy_144:
  %t840 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t817, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t826, { [2 x i8*], i64, i64 }** %t840
  %t841 = getelementptr i32, i32* null, i32 1
  %t842 = ptrtoint i32* %t841 to i64
  %t843 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t808, i32 0, i32 3
  %t844 = load i32*, i32** %t843
  %t845 = mul i64 %t812, %t842
  %t846 = call i8* @malloc(i64 %t845)
  %t847 = bitcast i8* %t846 to i32*
  %t848 = icmp sgt i64 %t810, 0
  br i1 %t848, label %table_cow_copy_148, label %table_cow_after_copy_149
table_cow_copy_148:
  %t849 = mul i64 %t810, %t842
  %t850 = bitcast i32* %t844 to i8*
  call i8* @memcpy(i8* %t846, i8* %t850, i64 %t849)
  br label %table_cow_after_copy_149
table_cow_after_copy_149:
  %t851 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t817, i32 0, i32 3
  store i32* %t847, i32** %t851
  call void @star_rc_release(i8* %t793)
  store i8* %t816, i8** %t207
  br label %table_cow_done_141
table_cow_done_141:
  %t852 = load i8*, i8** %t207
  %t853 = bitcast i8* %t852 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t854 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t853, i32 0, i32 0
  %t855 = load i64, i64* %t854
  %t856 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t853, i32 0, i32 1
  %t857 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t853, i32 0, i32 2
  %t858 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t857
  %t859 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t853, i32 0, i32 3
  %t860 = load i32*, i32** %t859
  %t862 = getelementptr inbounds %Bag, %Bag* %t861, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t862
  %t863 = getelementptr inbounds %Bag, %Bag* %t861, i32 0, i32 1
  store i32 3, i32* %t863
  %t864 = load %Bag, %Bag* %t861
  %t865 = load i64, i64* %t856
  %t866 = load i64, i64* %t854
  %t867 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t857
  %t868 = load i32*, i32** %t859
  %t869 = icmp sge i64 %t866, %t865
  br i1 %t869, label %table_push_grow_150, label %table_push_store_151
table_push_grow_150:
  %t870 = mul i64 %t865, 2
  %t871 = icmp sgt i64 %t870, 0
  %t872 = select i1 %t871, i64 %t870, i64 1
  %t873 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t874 = ptrtoint { [2 x i8*], i64, i64 }* %t873 to i64
  %t875 = mul i64 %t872, %t874
  %t876 = call i8* @malloc(i64 %t875)
  %t877 = bitcast i8* %t876 to { [2 x i8*], i64, i64 }*
  %t878 = icmp sgt i64 %t865, 0
  br i1 %t878, label %table_push_copy_152, label %table_push_after_copy_153
table_push_copy_152:
  %t879 = mul i64 %t866, %t874
  %t880 = bitcast { [2 x i8*], i64, i64 }* %t867 to i8*
  call i8* @memcpy(i8* %t876, i8* %t880, i64 %t879)
  call void @free(i8* %t880)
  br label %table_push_after_copy_153
table_push_after_copy_153:
  store { [2 x i8*], i64, i64 }* %t877, { [2 x i8*], i64, i64 }** %t857
  %t881 = getelementptr i32, i32* null, i32 1
  %t882 = ptrtoint i32* %t881 to i64
  %t883 = mul i64 %t872, %t882
  %t884 = call i8* @malloc(i64 %t883)
  %t885 = bitcast i8* %t884 to i32*
  %t886 = icmp sgt i64 %t865, 0
  br i1 %t886, label %table_push_copy_154, label %table_push_after_copy_155
table_push_copy_154:
  %t887 = mul i64 %t866, %t882
  %t888 = bitcast i32* %t868 to i8*
  call i8* @memcpy(i8* %t884, i8* %t888, i64 %t887)
  call void @free(i8* %t888)
  br label %table_push_after_copy_155
table_push_after_copy_155:
  store i32* %t885, i32** %t859
  store i64 %t872, i64* %t856
  br label %table_push_store_151
table_push_store_151:
  %t889 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t857
  %t890 = extractvalue %Bag %t864, 0
  %t891 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t889, i64 %t866
  store { [2 x i8*], i64, i64 } %t890, { [2 x i8*], i64, i64 }* %t891
  %t892 = load i32*, i32** %t859
  %t893 = extractvalue %Bag %t864, 1
  %t894 = getelementptr inbounds i32, i32* %t892, i64 %t866
  store i32 %t893, i32* %t894
  %t895 = add i64 %t866, 1
  store i64 %t895, i64* %t854
  %t896 = load i8*, i8** %t207
  %t897 = icmp eq i8* %t896, null
  br i1 %t897, label %table_read_null_156, label %table_read_real_157
table_read_null_156:
  br label %table_read_end_158
table_read_real_157:
  %t898 = bitcast i8* %t896 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t899 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t898, i32 0, i32 0
  %t900 = load i64, i64* %t899
  %t901 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t898, i32 0, i32 2
  %t902 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t901
  %t903 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t898, i32 0, i32 3
  %t904 = load i32*, i32** %t903
  br label %table_read_end_158
table_read_end_158:
  %t905 = phi i64 [ 0, %table_read_null_156 ], [ %t900, %table_read_real_157 ]
  %t906 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_156 ], [ %t902, %table_read_real_157 ]
  %t907 = phi i32* [ null, %table_read_null_156 ], [ %t904, %table_read_real_157 ]
  %t908 = trunc i64 %t905 to i32
  %t909 = load i8*, i8** %t790
  %t910 = icmp eq i8* %t909, null
  br i1 %t910, label %table_read_null_159, label %table_read_real_160
table_read_null_159:
  br label %table_read_end_161
table_read_real_160:
  %t911 = bitcast i8* %t909 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t912 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t911, i32 0, i32 0
  %t913 = load i64, i64* %t912
  %t914 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t911, i32 0, i32 2
  %t915 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t914
  %t916 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t911, i32 0, i32 3
  %t917 = load i32*, i32** %t916
  br label %table_read_end_161
table_read_end_161:
  %t918 = phi i64 [ 0, %table_read_null_159 ], [ %t913, %table_read_real_160 ]
  %t919 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_159 ], [ %t915, %table_read_real_160 ]
  %t920 = phi i32* [ null, %table_read_null_159 ], [ %t917, %table_read_real_160 ]
  %t921 = trunc i64 %t918 to i32
  %t922 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t922, i32 %t908, i32 %t921)
  %t924 = load i8*, i8** %t207
  %t925 = icmp eq i8* %t924, null
  br i1 %t925, label %table_cow_alloc_162, label %table_cow_check_163
table_cow_alloc_162:
  %t926 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t927 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t928 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t927 to i64
  %t929 = call i8* @star_rc_alloc(i64 %t928, i8* %t926)
  %t930 = bitcast i8* %t929 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t931 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t930, i32 0, i32 0
  store i64 0, i64* %t931
  %t932 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t930, i32 0, i32 1
  store i64 0, i64* %t932
  %t933 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t930, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t933
  %t934 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t930, i32 0, i32 3
  store i32* null, i32** %t934
  store i8* %t929, i8** %t207
  br label %table_cow_done_164
table_cow_check_163:
  %t935 = getelementptr inbounds i8, i8* %t924, i64 -16
  %t936 = bitcast i8* %t935 to i64*
  %t937 = load atomic i64, i64* %t936 seq_cst, align 8
  %t938 = icmp eq i64 %t937, 1
  br i1 %t938, label %table_cow_done_164, label %table_cow_clone_165
table_cow_clone_165:
  %t939 = bitcast i8* %t924 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t940 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t939, i32 0, i32 0
  %t941 = load i64, i64* %t940
  %t942 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t939, i32 0, i32 1
  %t943 = load i64, i64* %t942
  %t944 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t945 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t946 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t945 to i64
  %t947 = call i8* @star_rc_alloc(i64 %t946, i8* %t944)
  %t948 = bitcast i8* %t947 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t949 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t948, i32 0, i32 0
  store i64 %t941, i64* %t949
  %t950 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t948, i32 0, i32 1
  store i64 %t943, i64* %t950
  %t951 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t952 = ptrtoint { [2 x i8*], i64, i64 }* %t951 to i64
  %t953 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t939, i32 0, i32 2
  %t954 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t953
  %t955 = mul i64 %t943, %t952
  %t956 = call i8* @malloc(i64 %t955)
  %t957 = bitcast i8* %t956 to { [2 x i8*], i64, i64 }*
  %t958 = icmp sgt i64 %t941, 0
  br i1 %t958, label %table_cow_copy_166, label %table_cow_after_copy_167
table_cow_copy_166:
  %t959 = mul i64 %t941, %t952
  %t960 = bitcast { [2 x i8*], i64, i64 }* %t954 to i8*
  call i8* @memcpy(i8* %t956, i8* %t960, i64 %t959)
  store i64 0, i64* %t961
  br label %table_cow_retain_cond_168
table_cow_retain_cond_168:
  %t962 = load i64, i64* %t961
  %t963 = icmp slt i64 %t962, %t941
  br i1 %t963, label %table_cow_retain_body_169, label %table_cow_retain_end_170
table_cow_retain_body_169:
  %t964 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t957, i64 %t962
  %t965 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t964, i32 0, i32 0
  %t966 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t965, i32 0, i64 0
  %t967 = load i8*, i8** %t966
  call void @star_rc_retain(i8* %t967)
  %t968 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t965, i32 0, i64 1
  %t969 = load i8*, i8** %t968
  call void @star_rc_retain(i8* %t969)
  %t970 = add i64 %t962, 1
  store i64 %t970, i64* %t961
  br label %table_cow_retain_cond_168
table_cow_retain_end_170:
  br label %table_cow_after_copy_167
table_cow_after_copy_167:
  %t971 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t948, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t957, { [2 x i8*], i64, i64 }** %t971
  %t972 = getelementptr i32, i32* null, i32 1
  %t973 = ptrtoint i32* %t972 to i64
  %t974 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t939, i32 0, i32 3
  %t975 = load i32*, i32** %t974
  %t976 = mul i64 %t943, %t973
  %t977 = call i8* @malloc(i64 %t976)
  %t978 = bitcast i8* %t977 to i32*
  %t979 = icmp sgt i64 %t941, 0
  br i1 %t979, label %table_cow_copy_171, label %table_cow_after_copy_172
table_cow_copy_171:
  %t980 = mul i64 %t941, %t973
  %t981 = bitcast i32* %t975 to i8*
  call i8* @memcpy(i8* %t977, i8* %t981, i64 %t980)
  br label %table_cow_after_copy_172
table_cow_after_copy_172:
  %t982 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t948, i32 0, i32 3
  store i32* %t978, i32** %t982
  call void @star_rc_release(i8* %t924)
  store i8* %t947, i8** %t207
  br label %table_cow_done_164
table_cow_done_164:
  %t983 = load i8*, i8** %t207
  %t984 = bitcast i8* %t983 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t985 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t984, i32 0, i32 0
  %t986 = load i64, i64* %t985
  %t987 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t984, i32 0, i32 1
  %t988 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t984, i32 0, i32 2
  %t989 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t988
  %t990 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t984, i32 0, i32 3
  %t991 = load i32*, i32** %t990
  %t993 = icmp eq i64 %t986, 0
  br i1 %t993, label %table_pop_empty_173, label %table_pop_nonempty_174
table_pop_nonempty_174:
  %t994 = sub i64 %t986, 1
  store i64 %t994, i64* %t985
  %t995 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t989, i64 %t994
  %t996 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t995
  %t997 = getelementptr inbounds %Bag, %Bag* %t992, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t996, { [2 x i8*], i64, i64 }* %t997
  %t998 = getelementptr inbounds i32, i32* %t991, i64 %t994
  %t999 = load i32, i32* %t998
  %t1000 = getelementptr inbounds %Bag, %Bag* %t992, i32 0, i32 1
  store i32 %t999, i32* %t1000
  br label %table_pop_end_175
table_pop_empty_173:
  %t1001 = getelementptr inbounds %Bag, %Bag* %t992, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t1001
  %t1002 = getelementptr inbounds %Bag, %Bag* %t992, i32 0, i32 1
  store i32 0, i32* %t1002
  br label %table_pop_end_175
table_pop_end_175:
  %t1003 = load %Bag, %Bag* %t992
  store %Bag %t1003, %Bag* %t923
  %t1004 = getelementptr inbounds %Bag, %Bag* %t923, i32 0, i32 1
  %t1005 = load i32, i32* %t1004
  %t1006 = getelementptr inbounds %Bag, %Bag* %t923, i32 0, i32 0
  %t1007 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1006, i32 0, i32 0
  %t1008 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1006, i32 0, i32 1
  %t1009 = load i64, i64* %t1008
  %t1010 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1006, i32 0, i32 2
  %t1011 = load i64, i64* %t1010
  %t1012 = trunc i64 %t1011 to i32
  %t1013 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1013, i32 %t1005, i32 %t1012)
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t1014
  store i8* null, i8** %t1015
  %t1016 = load i8*, i8** %t1015
  %t1017 = icmp eq i8* %t1016, null
  br i1 %t1017, label %table_cow_alloc_176, label %table_cow_check_177
table_cow_alloc_176:
  %t1024 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1025 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1026 = ptrtoint { i64, i64, i32* }* %t1025 to i64
  %t1027 = call i8* @star_rc_alloc(i64 %t1026, i8* %t1024)
  %t1028 = bitcast i8* %t1027 to { i64, i64, i32* }*
  %t1029 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1028, i32 0, i32 0
  store i64 0, i64* %t1029
  %t1030 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1028, i32 0, i32 1
  store i64 0, i64* %t1030
  %t1031 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1028, i32 0, i32 2
  store i32* null, i32** %t1031
  store i8* %t1027, i8** %t1015
  br label %table_cow_done_178
table_cow_check_177:
  %t1032 = getelementptr inbounds i8, i8* %t1016, i64 -16
  %t1033 = bitcast i8* %t1032 to i64*
  %t1034 = load atomic i64, i64* %t1033 seq_cst, align 8
  %t1035 = icmp eq i64 %t1034, 1
  br i1 %t1035, label %table_cow_done_178, label %table_cow_clone_179
table_cow_clone_179:
  %t1036 = bitcast i8* %t1016 to { i64, i64, i32* }*
  %t1037 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1036, i32 0, i32 0
  %t1038 = load i64, i64* %t1037
  %t1039 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1036, i32 0, i32 1
  %t1040 = load i64, i64* %t1039
  %t1041 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1042 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1043 = ptrtoint { i64, i64, i32* }* %t1042 to i64
  %t1044 = call i8* @star_rc_alloc(i64 %t1043, i8* %t1041)
  %t1045 = bitcast i8* %t1044 to { i64, i64, i32* }*
  %t1046 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1045, i32 0, i32 0
  store i64 %t1038, i64* %t1046
  %t1047 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1045, i32 0, i32 1
  store i64 %t1040, i64* %t1047
  %t1048 = getelementptr i32, i32* null, i32 1
  %t1049 = ptrtoint i32* %t1048 to i64
  %t1050 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1036, i32 0, i32 2
  %t1051 = load i32*, i32** %t1050
  %t1052 = mul i64 %t1040, %t1049
  %t1053 = call i8* @malloc(i64 %t1052)
  %t1054 = bitcast i8* %t1053 to i32*
  %t1055 = icmp sgt i64 %t1038, 0
  br i1 %t1055, label %table_cow_copy_180, label %table_cow_after_copy_181
table_cow_copy_180:
  %t1056 = mul i64 %t1038, %t1049
  %t1057 = bitcast i32* %t1051 to i8*
  call i8* @memcpy(i8* %t1053, i8* %t1057, i64 %t1056)
  br label %table_cow_after_copy_181
table_cow_after_copy_181:
  %t1058 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1045, i32 0, i32 2
  store i32* %t1054, i32** %t1058
  call void @star_rc_release(i8* %t1016)
  store i8* %t1044, i8** %t1015
  br label %table_cow_done_178
table_cow_done_178:
  %t1059 = load i8*, i8** %t1015
  %t1060 = bitcast i8* %t1059 to { i64, i64, i32* }*
  %t1061 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1060, i32 0, i32 0
  %t1062 = load i64, i64* %t1061
  %t1063 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1060, i32 0, i32 1
  %t1064 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1060, i32 0, i32 2
  %t1065 = load i32*, i32** %t1064
  %t1067 = getelementptr inbounds %Item, %Item* %t1066, i32 0, i32 0
  store i32 1, i32* %t1067
  %t1068 = load %Item, %Item* %t1066
  %t1069 = load i64, i64* %t1063
  %t1070 = load i64, i64* %t1061
  %t1071 = load i32*, i32** %t1064
  %t1072 = icmp sge i64 %t1070, %t1069
  br i1 %t1072, label %table_push_grow_182, label %table_push_store_183
table_push_grow_182:
  %t1073 = mul i64 %t1069, 2
  %t1074 = icmp sgt i64 %t1073, 0
  %t1075 = select i1 %t1074, i64 %t1073, i64 1
  %t1076 = getelementptr i32, i32* null, i32 1
  %t1077 = ptrtoint i32* %t1076 to i64
  %t1078 = mul i64 %t1075, %t1077
  %t1079 = call i8* @malloc(i64 %t1078)
  %t1080 = bitcast i8* %t1079 to i32*
  %t1081 = icmp sgt i64 %t1069, 0
  br i1 %t1081, label %table_push_copy_184, label %table_push_after_copy_185
table_push_copy_184:
  %t1082 = mul i64 %t1070, %t1077
  %t1083 = bitcast i32* %t1071 to i8*
  call i8* @memcpy(i8* %t1079, i8* %t1083, i64 %t1082)
  call void @free(i8* %t1083)
  br label %table_push_after_copy_185
table_push_after_copy_185:
  store i32* %t1080, i32** %t1064
  store i64 %t1075, i64* %t1063
  br label %table_push_store_183
table_push_store_183:
  %t1084 = load i32*, i32** %t1064
  %t1085 = extractvalue %Item %t1068, 0
  %t1086 = getelementptr inbounds i32, i32* %t1084, i64 %t1070
  store i32 %t1085, i32* %t1086
  %t1087 = add i64 %t1070, 1
  store i64 %t1087, i64* %t1061
  %t1088 = load i8*, i8** %t1015
  %t1089 = load i8*, i8** %t1015
  call void @star_rc_retain(i8* %t1089)
  %t1090 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1091 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1092 = load i64, i64* %t1091
  %t1093 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1094 = load i64, i64* %t1093
  %t1095 = icmp sge i64 %t1094, 2
  br i1 %t1095, label %ring_push_full_186, label %ring_push_grow_187
ring_push_grow_187:
  %t1096 = add i64 %t1092, %t1094
  %t1097 = urem i64 %t1096, 2
  %t1098 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1090, i32 0, i64 %t1097
  store i8* %t1088, i8** %t1098
  %t1099 = add i64 %t1094, 1
  store i64 %t1099, i64* %t1093
  br label %ring_push_done_188
ring_push_full_186:
  %t1100 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1090, i32 0, i64 %t1092
  %t1101 = load i8*, i8** %t1100
  call void @star_rc_release(i8* %t1101)
  store i8* %t1088, i8** %t1100
  %t1102 = add i64 %t1092, 1
  %t1103 = urem i64 %t1102, 2
  store i64 %t1103, i64* %t1091
  br label %ring_push_done_188
ring_push_done_188:
  store i8* null, i8** %t1104
  %t1105 = load i8*, i8** %t1104
  %t1106 = icmp eq i8* %t1105, null
  br i1 %t1106, label %table_cow_alloc_189, label %table_cow_check_190
table_cow_alloc_189:
  %t1107 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1108 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1109 = ptrtoint { i64, i64, i32* }* %t1108 to i64
  %t1110 = call i8* @star_rc_alloc(i64 %t1109, i8* %t1107)
  %t1111 = bitcast i8* %t1110 to { i64, i64, i32* }*
  %t1112 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1111, i32 0, i32 0
  store i64 0, i64* %t1112
  %t1113 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1111, i32 0, i32 1
  store i64 0, i64* %t1113
  %t1114 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1111, i32 0, i32 2
  store i32* null, i32** %t1114
  store i8* %t1110, i8** %t1104
  br label %table_cow_done_191
table_cow_check_190:
  %t1115 = getelementptr inbounds i8, i8* %t1105, i64 -16
  %t1116 = bitcast i8* %t1115 to i64*
  %t1117 = load atomic i64, i64* %t1116 seq_cst, align 8
  %t1118 = icmp eq i64 %t1117, 1
  br i1 %t1118, label %table_cow_done_191, label %table_cow_clone_192
table_cow_clone_192:
  %t1119 = bitcast i8* %t1105 to { i64, i64, i32* }*
  %t1120 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1119, i32 0, i32 0
  %t1121 = load i64, i64* %t1120
  %t1122 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1119, i32 0, i32 1
  %t1123 = load i64, i64* %t1122
  %t1124 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1125 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1126 = ptrtoint { i64, i64, i32* }* %t1125 to i64
  %t1127 = call i8* @star_rc_alloc(i64 %t1126, i8* %t1124)
  %t1128 = bitcast i8* %t1127 to { i64, i64, i32* }*
  %t1129 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1128, i32 0, i32 0
  store i64 %t1121, i64* %t1129
  %t1130 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1128, i32 0, i32 1
  store i64 %t1123, i64* %t1130
  %t1131 = getelementptr i32, i32* null, i32 1
  %t1132 = ptrtoint i32* %t1131 to i64
  %t1133 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1119, i32 0, i32 2
  %t1134 = load i32*, i32** %t1133
  %t1135 = mul i64 %t1123, %t1132
  %t1136 = call i8* @malloc(i64 %t1135)
  %t1137 = bitcast i8* %t1136 to i32*
  %t1138 = icmp sgt i64 %t1121, 0
  br i1 %t1138, label %table_cow_copy_193, label %table_cow_after_copy_194
table_cow_copy_193:
  %t1139 = mul i64 %t1121, %t1132
  %t1140 = bitcast i32* %t1134 to i8*
  call i8* @memcpy(i8* %t1136, i8* %t1140, i64 %t1139)
  br label %table_cow_after_copy_194
table_cow_after_copy_194:
  %t1141 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1128, i32 0, i32 2
  store i32* %t1137, i32** %t1141
  call void @star_rc_release(i8* %t1105)
  store i8* %t1127, i8** %t1104
  br label %table_cow_done_191
table_cow_done_191:
  %t1142 = load i8*, i8** %t1104
  %t1143 = bitcast i8* %t1142 to { i64, i64, i32* }*
  %t1144 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1143, i32 0, i32 0
  %t1145 = load i64, i64* %t1144
  %t1146 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1143, i32 0, i32 1
  %t1147 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1143, i32 0, i32 2
  %t1148 = load i32*, i32** %t1147
  %t1150 = getelementptr inbounds %Item, %Item* %t1149, i32 0, i32 0
  store i32 2, i32* %t1150
  %t1151 = load %Item, %Item* %t1149
  %t1152 = load i64, i64* %t1146
  %t1153 = load i64, i64* %t1144
  %t1154 = load i32*, i32** %t1147
  %t1155 = icmp sge i64 %t1153, %t1152
  br i1 %t1155, label %table_push_grow_195, label %table_push_store_196
table_push_grow_195:
  %t1156 = mul i64 %t1152, 2
  %t1157 = icmp sgt i64 %t1156, 0
  %t1158 = select i1 %t1157, i64 %t1156, i64 1
  %t1159 = getelementptr i32, i32* null, i32 1
  %t1160 = ptrtoint i32* %t1159 to i64
  %t1161 = mul i64 %t1158, %t1160
  %t1162 = call i8* @malloc(i64 %t1161)
  %t1163 = bitcast i8* %t1162 to i32*
  %t1164 = icmp sgt i64 %t1152, 0
  br i1 %t1164, label %table_push_copy_197, label %table_push_after_copy_198
table_push_copy_197:
  %t1165 = mul i64 %t1153, %t1160
  %t1166 = bitcast i32* %t1154 to i8*
  call i8* @memcpy(i8* %t1162, i8* %t1166, i64 %t1165)
  call void @free(i8* %t1166)
  br label %table_push_after_copy_198
table_push_after_copy_198:
  store i32* %t1163, i32** %t1147
  store i64 %t1158, i64* %t1146
  br label %table_push_store_196
table_push_store_196:
  %t1167 = load i32*, i32** %t1147
  %t1168 = extractvalue %Item %t1151, 0
  %t1169 = getelementptr inbounds i32, i32* %t1167, i64 %t1153
  store i32 %t1168, i32* %t1169
  %t1170 = add i64 %t1153, 1
  store i64 %t1170, i64* %t1144
  %t1171 = load i8*, i8** %t1104
  %t1172 = icmp eq i8* %t1171, null
  br i1 %t1172, label %table_cow_alloc_199, label %table_cow_check_200
table_cow_alloc_199:
  %t1173 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1174 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1175 = ptrtoint { i64, i64, i32* }* %t1174 to i64
  %t1176 = call i8* @star_rc_alloc(i64 %t1175, i8* %t1173)
  %t1177 = bitcast i8* %t1176 to { i64, i64, i32* }*
  %t1178 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1177, i32 0, i32 0
  store i64 0, i64* %t1178
  %t1179 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1177, i32 0, i32 1
  store i64 0, i64* %t1179
  %t1180 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1177, i32 0, i32 2
  store i32* null, i32** %t1180
  store i8* %t1176, i8** %t1104
  br label %table_cow_done_201
table_cow_check_200:
  %t1181 = getelementptr inbounds i8, i8* %t1171, i64 -16
  %t1182 = bitcast i8* %t1181 to i64*
  %t1183 = load atomic i64, i64* %t1182 seq_cst, align 8
  %t1184 = icmp eq i64 %t1183, 1
  br i1 %t1184, label %table_cow_done_201, label %table_cow_clone_202
table_cow_clone_202:
  %t1185 = bitcast i8* %t1171 to { i64, i64, i32* }*
  %t1186 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1185, i32 0, i32 0
  %t1187 = load i64, i64* %t1186
  %t1188 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1185, i32 0, i32 1
  %t1189 = load i64, i64* %t1188
  %t1190 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1191 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1192 = ptrtoint { i64, i64, i32* }* %t1191 to i64
  %t1193 = call i8* @star_rc_alloc(i64 %t1192, i8* %t1190)
  %t1194 = bitcast i8* %t1193 to { i64, i64, i32* }*
  %t1195 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1194, i32 0, i32 0
  store i64 %t1187, i64* %t1195
  %t1196 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1194, i32 0, i32 1
  store i64 %t1189, i64* %t1196
  %t1197 = getelementptr i32, i32* null, i32 1
  %t1198 = ptrtoint i32* %t1197 to i64
  %t1199 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1185, i32 0, i32 2
  %t1200 = load i32*, i32** %t1199
  %t1201 = mul i64 %t1189, %t1198
  %t1202 = call i8* @malloc(i64 %t1201)
  %t1203 = bitcast i8* %t1202 to i32*
  %t1204 = icmp sgt i64 %t1187, 0
  br i1 %t1204, label %table_cow_copy_203, label %table_cow_after_copy_204
table_cow_copy_203:
  %t1205 = mul i64 %t1187, %t1198
  %t1206 = bitcast i32* %t1200 to i8*
  call i8* @memcpy(i8* %t1202, i8* %t1206, i64 %t1205)
  br label %table_cow_after_copy_204
table_cow_after_copy_204:
  %t1207 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1194, i32 0, i32 2
  store i32* %t1203, i32** %t1207
  call void @star_rc_release(i8* %t1171)
  store i8* %t1193, i8** %t1104
  br label %table_cow_done_201
table_cow_done_201:
  %t1208 = load i8*, i8** %t1104
  %t1209 = bitcast i8* %t1208 to { i64, i64, i32* }*
  %t1210 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1209, i32 0, i32 0
  %t1211 = load i64, i64* %t1210
  %t1212 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1209, i32 0, i32 1
  %t1213 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1209, i32 0, i32 2
  %t1214 = load i32*, i32** %t1213
  %t1216 = getelementptr inbounds %Item, %Item* %t1215, i32 0, i32 0
  store i32 3, i32* %t1216
  %t1217 = load %Item, %Item* %t1215
  %t1218 = load i64, i64* %t1212
  %t1219 = load i64, i64* %t1210
  %t1220 = load i32*, i32** %t1213
  %t1221 = icmp sge i64 %t1219, %t1218
  br i1 %t1221, label %table_push_grow_205, label %table_push_store_206
table_push_grow_205:
  %t1222 = mul i64 %t1218, 2
  %t1223 = icmp sgt i64 %t1222, 0
  %t1224 = select i1 %t1223, i64 %t1222, i64 1
  %t1225 = getelementptr i32, i32* null, i32 1
  %t1226 = ptrtoint i32* %t1225 to i64
  %t1227 = mul i64 %t1224, %t1226
  %t1228 = call i8* @malloc(i64 %t1227)
  %t1229 = bitcast i8* %t1228 to i32*
  %t1230 = icmp sgt i64 %t1218, 0
  br i1 %t1230, label %table_push_copy_207, label %table_push_after_copy_208
table_push_copy_207:
  %t1231 = mul i64 %t1219, %t1226
  %t1232 = bitcast i32* %t1220 to i8*
  call i8* @memcpy(i8* %t1228, i8* %t1232, i64 %t1231)
  call void @free(i8* %t1232)
  br label %table_push_after_copy_208
table_push_after_copy_208:
  store i32* %t1229, i32** %t1213
  store i64 %t1224, i64* %t1212
  br label %table_push_store_206
table_push_store_206:
  %t1233 = load i32*, i32** %t1213
  %t1234 = extractvalue %Item %t1217, 0
  %t1235 = getelementptr inbounds i32, i32* %t1233, i64 %t1219
  store i32 %t1234, i32* %t1235
  %t1236 = add i64 %t1219, 1
  store i64 %t1236, i64* %t1210
  %t1237 = load i8*, i8** %t1104
  %t1238 = load i8*, i8** %t1104
  call void @star_rc_retain(i8* %t1238)
  %t1239 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1240 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1241 = load i64, i64* %t1240
  %t1242 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1243 = load i64, i64* %t1242
  %t1244 = icmp sge i64 %t1243, 2
  br i1 %t1244, label %ring_push_full_209, label %ring_push_grow_210
ring_push_grow_210:
  %t1245 = add i64 %t1241, %t1243
  %t1246 = urem i64 %t1245, 2
  %t1247 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1239, i32 0, i64 %t1246
  store i8* %t1237, i8** %t1247
  %t1248 = add i64 %t1243, 1
  store i64 %t1248, i64* %t1242
  br label %ring_push_done_211
ring_push_full_209:
  %t1249 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1239, i32 0, i64 %t1241
  %t1250 = load i8*, i8** %t1249
  call void @star_rc_release(i8* %t1250)
  store i8* %t1237, i8** %t1249
  %t1251 = add i64 %t1241, 1
  %t1252 = urem i64 %t1251, 2
  store i64 %t1252, i64* %t1240
  br label %ring_push_done_211
ring_push_done_211:
  %t1253 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1254 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1255 = load i64, i64* %t1254
  %t1256 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1257 = load i64, i64* %t1256
  %t1258 = trunc i64 %t1257 to i32
  %t1259 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1260 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1261 = load i64, i64* %t1260
  %t1262 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1263 = load i64, i64* %t1262
  %t1264 = sext i32 0 to i64
  %t1265 = load i64, i64* %t1260
  %t1266 = load i64, i64* %t1262
  %t1267 = icmp ult i64 %t1264, %t1266
  br i1 %t1267, label %ring_rplace_ok_212, label %ring_rplace_oob_213
ring_rplace_ok_212:
  %t1268 = add i64 %t1265, %t1264
  %t1269 = urem i64 %t1268, 2
  %t1270 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1259, i32 0, i64 %t1269
  br label %ring_rplace_end_214
ring_rplace_oob_213:
  store i8* null, i8** %t1271
  br label %ring_rplace_end_214
ring_rplace_end_214:
  %t1272 = phi i8** [ %t1270, %ring_rplace_ok_212 ], [ %t1271, %ring_rplace_oob_213 ]
  %t1273 = load i8*, i8** %t1272
  %t1274 = icmp eq i8* %t1273, null
  br i1 %t1274, label %table_read_null_215, label %table_read_real_216
table_read_null_215:
  br label %table_read_end_217
table_read_real_216:
  %t1275 = bitcast i8* %t1273 to { i64, i64, i32* }*
  %t1276 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1275, i32 0, i32 0
  %t1277 = load i64, i64* %t1276
  %t1278 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1275, i32 0, i32 2
  %t1279 = load i32*, i32** %t1278
  br label %table_read_end_217
table_read_end_217:
  %t1280 = phi i64 [ 0, %table_read_null_215 ], [ %t1277, %table_read_real_216 ]
  %t1281 = phi i32* [ null, %table_read_null_215 ], [ %t1279, %table_read_real_216 ]
  %t1282 = trunc i64 %t1280 to i32
  %t1283 = sext i32 0 to i64
  %t1284 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1285 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1286 = load i64, i64* %t1285
  %t1287 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1288 = load i64, i64* %t1287
  %t1289 = sext i32 0 to i64
  %t1290 = load i64, i64* %t1285
  %t1291 = load i64, i64* %t1287
  %t1292 = icmp ult i64 %t1289, %t1291
  br i1 %t1292, label %ring_rplace_ok_218, label %ring_rplace_oob_219
ring_rplace_ok_218:
  %t1293 = add i64 %t1290, %t1289
  %t1294 = urem i64 %t1293, 2
  %t1295 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1284, i32 0, i64 %t1294
  br label %ring_rplace_end_220
ring_rplace_oob_219:
  store i8* null, i8** %t1296
  br label %ring_rplace_end_220
ring_rplace_end_220:
  %t1297 = phi i8** [ %t1295, %ring_rplace_ok_218 ], [ %t1296, %ring_rplace_oob_219 ]
  %t1298 = load i8*, i8** %t1297
  %t1299 = icmp eq i8* %t1298, null
  br i1 %t1299, label %table_read_null_221, label %table_read_real_222
table_read_null_221:
  br label %table_read_end_223
table_read_real_222:
  %t1300 = bitcast i8* %t1298 to { i64, i64, i32* }*
  %t1301 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1300, i32 0, i32 0
  %t1302 = load i64, i64* %t1301
  %t1303 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1300, i32 0, i32 2
  %t1304 = load i32*, i32** %t1303
  br label %table_read_end_223
table_read_end_223:
  %t1305 = phi i64 [ 0, %table_read_null_221 ], [ %t1302, %table_read_real_222 ]
  %t1306 = phi i32* [ null, %table_read_null_221 ], [ %t1304, %table_read_real_222 ]
  %t1308 = icmp ult i64 %t1283, %t1305
  br i1 %t1308, label %table_idx_ok_224, label %table_idx_oob_225
table_idx_ok_224:
  %t1309 = getelementptr inbounds i32, i32* %t1306, i64 %t1283
  %t1310 = load i32, i32* %t1309
  %t1311 = getelementptr inbounds %Item, %Item* %t1307, i32 0, i32 0
  store i32 %t1310, i32* %t1311
  br label %table_idx_end_226
table_idx_oob_225:
  %t1312 = getelementptr inbounds %Item, %Item* %t1307, i32 0, i32 0
  store i32 0, i32* %t1312
  br label %table_idx_end_226
table_idx_end_226:
  %t1313 = load %Item, %Item* %t1307
  store %Item %t1313, %Item* %t1314
  %t1315 = getelementptr inbounds %Item, %Item* %t1314, i32 0, i32 0
  %t1316 = load i32, i32* %t1315
  %t1317 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1317, i32 %t1258, i32 %t1282, i32 %t1316)
  %t1318 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1319 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1320 = load i64, i64* %t1319
  %t1321 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1322 = load i64, i64* %t1321
  %t1323 = sext i32 1 to i64
  %t1324 = load i64, i64* %t1319
  %t1325 = load i64, i64* %t1321
  %t1326 = icmp ult i64 %t1323, %t1325
  br i1 %t1326, label %ring_rplace_ok_227, label %ring_rplace_oob_228
ring_rplace_ok_227:
  %t1327 = add i64 %t1324, %t1323
  %t1328 = urem i64 %t1327, 2
  %t1329 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1318, i32 0, i64 %t1328
  br label %ring_rplace_end_229
ring_rplace_oob_228:
  store i8* null, i8** %t1330
  br label %ring_rplace_end_229
ring_rplace_end_229:
  %t1331 = phi i8** [ %t1329, %ring_rplace_ok_227 ], [ %t1330, %ring_rplace_oob_228 ]
  %t1332 = load i8*, i8** %t1331
  %t1333 = icmp eq i8* %t1332, null
  br i1 %t1333, label %table_read_null_230, label %table_read_real_231
table_read_null_230:
  br label %table_read_end_232
table_read_real_231:
  %t1334 = bitcast i8* %t1332 to { i64, i64, i32* }*
  %t1335 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1334, i32 0, i32 0
  %t1336 = load i64, i64* %t1335
  %t1337 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1334, i32 0, i32 2
  %t1338 = load i32*, i32** %t1337
  br label %table_read_end_232
table_read_end_232:
  %t1339 = phi i64 [ 0, %table_read_null_230 ], [ %t1336, %table_read_real_231 ]
  %t1340 = phi i32* [ null, %table_read_null_230 ], [ %t1338, %table_read_real_231 ]
  %t1341 = trunc i64 %t1339 to i32
  %t1342 = sext i32 0 to i64
  %t1343 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1344 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1345 = load i64, i64* %t1344
  %t1346 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1347 = load i64, i64* %t1346
  %t1348 = sext i32 1 to i64
  %t1349 = load i64, i64* %t1344
  %t1350 = load i64, i64* %t1346
  %t1351 = icmp ult i64 %t1348, %t1350
  br i1 %t1351, label %ring_rplace_ok_233, label %ring_rplace_oob_234
ring_rplace_ok_233:
  %t1352 = add i64 %t1349, %t1348
  %t1353 = urem i64 %t1352, 2
  %t1354 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1343, i32 0, i64 %t1353
  br label %ring_rplace_end_235
ring_rplace_oob_234:
  store i8* null, i8** %t1355
  br label %ring_rplace_end_235
ring_rplace_end_235:
  %t1356 = phi i8** [ %t1354, %ring_rplace_ok_233 ], [ %t1355, %ring_rplace_oob_234 ]
  %t1357 = load i8*, i8** %t1356
  %t1358 = icmp eq i8* %t1357, null
  br i1 %t1358, label %table_read_null_236, label %table_read_real_237
table_read_null_236:
  br label %table_read_end_238
table_read_real_237:
  %t1359 = bitcast i8* %t1357 to { i64, i64, i32* }*
  %t1360 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1359, i32 0, i32 0
  %t1361 = load i64, i64* %t1360
  %t1362 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1359, i32 0, i32 2
  %t1363 = load i32*, i32** %t1362
  br label %table_read_end_238
table_read_end_238:
  %t1364 = phi i64 [ 0, %table_read_null_236 ], [ %t1361, %table_read_real_237 ]
  %t1365 = phi i32* [ null, %table_read_null_236 ], [ %t1363, %table_read_real_237 ]
  %t1367 = icmp ult i64 %t1342, %t1364
  br i1 %t1367, label %table_idx_ok_239, label %table_idx_oob_240
table_idx_ok_239:
  %t1368 = getelementptr inbounds i32, i32* %t1365, i64 %t1342
  %t1369 = load i32, i32* %t1368
  %t1370 = getelementptr inbounds %Item, %Item* %t1366, i32 0, i32 0
  store i32 %t1369, i32* %t1370
  br label %table_idx_end_241
table_idx_oob_240:
  %t1371 = getelementptr inbounds %Item, %Item* %t1366, i32 0, i32 0
  store i32 0, i32* %t1371
  br label %table_idx_end_241
table_idx_end_241:
  %t1372 = load %Item, %Item* %t1366
  store %Item %t1372, %Item* %t1373
  %t1374 = getelementptr inbounds %Item, %Item* %t1373, i32 0, i32 0
  %t1375 = load i32, i32* %t1374
  %t1376 = sext i32 1 to i64
  %t1377 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1378 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1379 = load i64, i64* %t1378
  %t1380 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1381 = load i64, i64* %t1380
  %t1382 = sext i32 1 to i64
  %t1383 = load i64, i64* %t1378
  %t1384 = load i64, i64* %t1380
  %t1385 = icmp ult i64 %t1382, %t1384
  br i1 %t1385, label %ring_rplace_ok_242, label %ring_rplace_oob_243
ring_rplace_ok_242:
  %t1386 = add i64 %t1383, %t1382
  %t1387 = urem i64 %t1386, 2
  %t1388 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1377, i32 0, i64 %t1387
  br label %ring_rplace_end_244
ring_rplace_oob_243:
  store i8* null, i8** %t1389
  br label %ring_rplace_end_244
ring_rplace_end_244:
  %t1390 = phi i8** [ %t1388, %ring_rplace_ok_242 ], [ %t1389, %ring_rplace_oob_243 ]
  %t1391 = load i8*, i8** %t1390
  %t1392 = icmp eq i8* %t1391, null
  br i1 %t1392, label %table_read_null_245, label %table_read_real_246
table_read_null_245:
  br label %table_read_end_247
table_read_real_246:
  %t1393 = bitcast i8* %t1391 to { i64, i64, i32* }*
  %t1394 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1393, i32 0, i32 0
  %t1395 = load i64, i64* %t1394
  %t1396 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1393, i32 0, i32 2
  %t1397 = load i32*, i32** %t1396
  br label %table_read_end_247
table_read_end_247:
  %t1398 = phi i64 [ 0, %table_read_null_245 ], [ %t1395, %table_read_real_246 ]
  %t1399 = phi i32* [ null, %table_read_null_245 ], [ %t1397, %table_read_real_246 ]
  %t1401 = icmp ult i64 %t1376, %t1398
  br i1 %t1401, label %table_idx_ok_248, label %table_idx_oob_249
table_idx_ok_248:
  %t1402 = getelementptr inbounds i32, i32* %t1399, i64 %t1376
  %t1403 = load i32, i32* %t1402
  %t1404 = getelementptr inbounds %Item, %Item* %t1400, i32 0, i32 0
  store i32 %t1403, i32* %t1404
  br label %table_idx_end_250
table_idx_oob_249:
  %t1405 = getelementptr inbounds %Item, %Item* %t1400, i32 0, i32 0
  store i32 0, i32* %t1405
  br label %table_idx_end_250
table_idx_end_250:
  %t1406 = load %Item, %Item* %t1400
  store %Item %t1406, %Item* %t1407
  %t1408 = getelementptr inbounds %Item, %Item* %t1407, i32 0, i32 0
  %t1409 = load i32, i32* %t1408
  %t1410 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1410, i32 %t1341, i32 %t1375, i32 %t1409)
  store i8* null, i8** %t1411
  %t1412 = load i8*, i8** %t1411
  %t1413 = icmp eq i8* %t1412, null
  br i1 %t1413, label %table_cow_alloc_251, label %table_cow_check_252
table_cow_alloc_251:
  %t1414 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1415 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1416 = ptrtoint { i64, i64, i32* }* %t1415 to i64
  %t1417 = call i8* @star_rc_alloc(i64 %t1416, i8* %t1414)
  %t1418 = bitcast i8* %t1417 to { i64, i64, i32* }*
  %t1419 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1418, i32 0, i32 0
  store i64 0, i64* %t1419
  %t1420 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1418, i32 0, i32 1
  store i64 0, i64* %t1420
  %t1421 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1418, i32 0, i32 2
  store i32* null, i32** %t1421
  store i8* %t1417, i8** %t1411
  br label %table_cow_done_253
table_cow_check_252:
  %t1422 = getelementptr inbounds i8, i8* %t1412, i64 -16
  %t1423 = bitcast i8* %t1422 to i64*
  %t1424 = load atomic i64, i64* %t1423 seq_cst, align 8
  %t1425 = icmp eq i64 %t1424, 1
  br i1 %t1425, label %table_cow_done_253, label %table_cow_clone_254
table_cow_clone_254:
  %t1426 = bitcast i8* %t1412 to { i64, i64, i32* }*
  %t1427 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1426, i32 0, i32 0
  %t1428 = load i64, i64* %t1427
  %t1429 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1426, i32 0, i32 1
  %t1430 = load i64, i64* %t1429
  %t1431 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1432 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1433 = ptrtoint { i64, i64, i32* }* %t1432 to i64
  %t1434 = call i8* @star_rc_alloc(i64 %t1433, i8* %t1431)
  %t1435 = bitcast i8* %t1434 to { i64, i64, i32* }*
  %t1436 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1435, i32 0, i32 0
  store i64 %t1428, i64* %t1436
  %t1437 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1435, i32 0, i32 1
  store i64 %t1430, i64* %t1437
  %t1438 = getelementptr i32, i32* null, i32 1
  %t1439 = ptrtoint i32* %t1438 to i64
  %t1440 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1426, i32 0, i32 2
  %t1441 = load i32*, i32** %t1440
  %t1442 = mul i64 %t1430, %t1439
  %t1443 = call i8* @malloc(i64 %t1442)
  %t1444 = bitcast i8* %t1443 to i32*
  %t1445 = icmp sgt i64 %t1428, 0
  br i1 %t1445, label %table_cow_copy_255, label %table_cow_after_copy_256
table_cow_copy_255:
  %t1446 = mul i64 %t1428, %t1439
  %t1447 = bitcast i32* %t1441 to i8*
  call i8* @memcpy(i8* %t1443, i8* %t1447, i64 %t1446)
  br label %table_cow_after_copy_256
table_cow_after_copy_256:
  %t1448 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1435, i32 0, i32 2
  store i32* %t1444, i32** %t1448
  call void @star_rc_release(i8* %t1412)
  store i8* %t1434, i8** %t1411
  br label %table_cow_done_253
table_cow_done_253:
  %t1449 = load i8*, i8** %t1411
  %t1450 = bitcast i8* %t1449 to { i64, i64, i32* }*
  %t1451 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1450, i32 0, i32 0
  %t1452 = load i64, i64* %t1451
  %t1453 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1450, i32 0, i32 1
  %t1454 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1450, i32 0, i32 2
  %t1455 = load i32*, i32** %t1454
  %t1457 = getelementptr inbounds %Item, %Item* %t1456, i32 0, i32 0
  store i32 9, i32* %t1457
  %t1458 = load %Item, %Item* %t1456
  %t1459 = load i64, i64* %t1453
  %t1460 = load i64, i64* %t1451
  %t1461 = load i32*, i32** %t1454
  %t1462 = icmp sge i64 %t1460, %t1459
  br i1 %t1462, label %table_push_grow_257, label %table_push_store_258
table_push_grow_257:
  %t1463 = mul i64 %t1459, 2
  %t1464 = icmp sgt i64 %t1463, 0
  %t1465 = select i1 %t1464, i64 %t1463, i64 1
  %t1466 = getelementptr i32, i32* null, i32 1
  %t1467 = ptrtoint i32* %t1466 to i64
  %t1468 = mul i64 %t1465, %t1467
  %t1469 = call i8* @malloc(i64 %t1468)
  %t1470 = bitcast i8* %t1469 to i32*
  %t1471 = icmp sgt i64 %t1459, 0
  br i1 %t1471, label %table_push_copy_259, label %table_push_after_copy_260
table_push_copy_259:
  %t1472 = mul i64 %t1460, %t1467
  %t1473 = bitcast i32* %t1461 to i8*
  call i8* @memcpy(i8* %t1469, i8* %t1473, i64 %t1472)
  call void @free(i8* %t1473)
  br label %table_push_after_copy_260
table_push_after_copy_260:
  store i32* %t1470, i32** %t1454
  store i64 %t1465, i64* %t1453
  br label %table_push_store_258
table_push_store_258:
  %t1474 = load i32*, i32** %t1454
  %t1475 = extractvalue %Item %t1458, 0
  %t1476 = getelementptr inbounds i32, i32* %t1474, i64 %t1460
  store i32 %t1475, i32* %t1476
  %t1477 = add i64 %t1460, 1
  store i64 %t1477, i64* %t1451
  %t1478 = load i8*, i8** %t1411
  %t1479 = load i8*, i8** %t1411
  call void @star_rc_retain(i8* %t1479)
  %t1480 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1481 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1482 = load i64, i64* %t1481
  %t1483 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1484 = load i64, i64* %t1483
  %t1485 = icmp sge i64 %t1484, 2
  br i1 %t1485, label %ring_push_full_261, label %ring_push_grow_262
ring_push_grow_262:
  %t1486 = add i64 %t1482, %t1484
  %t1487 = urem i64 %t1486, 2
  %t1488 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1480, i32 0, i64 %t1487
  store i8* %t1478, i8** %t1488
  %t1489 = add i64 %t1484, 1
  store i64 %t1489, i64* %t1483
  br label %ring_push_done_263
ring_push_full_261:
  %t1490 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1480, i32 0, i64 %t1482
  %t1491 = load i8*, i8** %t1490
  call void @star_rc_release(i8* %t1491)
  store i8* %t1478, i8** %t1490
  %t1492 = add i64 %t1482, 1
  %t1493 = urem i64 %t1492, 2
  store i64 %t1493, i64* %t1481
  br label %ring_push_done_263
ring_push_done_263:
  %t1494 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1495 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1496 = load i64, i64* %t1495
  %t1497 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1498 = load i64, i64* %t1497
  %t1499 = trunc i64 %t1498 to i32
  %t1500 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1501 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1502 = load i64, i64* %t1501
  %t1503 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1504 = load i64, i64* %t1503
  %t1505 = sext i32 0 to i64
  %t1506 = load i64, i64* %t1501
  %t1507 = load i64, i64* %t1503
  %t1508 = icmp ult i64 %t1505, %t1507
  br i1 %t1508, label %ring_rplace_ok_264, label %ring_rplace_oob_265
ring_rplace_ok_264:
  %t1509 = add i64 %t1506, %t1505
  %t1510 = urem i64 %t1509, 2
  %t1511 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1500, i32 0, i64 %t1510
  br label %ring_rplace_end_266
ring_rplace_oob_265:
  store i8* null, i8** %t1512
  br label %ring_rplace_end_266
ring_rplace_end_266:
  %t1513 = phi i8** [ %t1511, %ring_rplace_ok_264 ], [ %t1512, %ring_rplace_oob_265 ]
  %t1514 = load i8*, i8** %t1513
  %t1515 = icmp eq i8* %t1514, null
  br i1 %t1515, label %table_read_null_267, label %table_read_real_268
table_read_null_267:
  br label %table_read_end_269
table_read_real_268:
  %t1516 = bitcast i8* %t1514 to { i64, i64, i32* }*
  %t1517 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1516, i32 0, i32 0
  %t1518 = load i64, i64* %t1517
  %t1519 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1516, i32 0, i32 2
  %t1520 = load i32*, i32** %t1519
  br label %table_read_end_269
table_read_end_269:
  %t1521 = phi i64 [ 0, %table_read_null_267 ], [ %t1518, %table_read_real_268 ]
  %t1522 = phi i32* [ null, %table_read_null_267 ], [ %t1520, %table_read_real_268 ]
  %t1523 = trunc i64 %t1521 to i32
  %t1524 = sext i32 0 to i64
  %t1525 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1526 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 1
  %t1527 = load i64, i64* %t1526
  %t1528 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 2
  %t1529 = load i64, i64* %t1528
  %t1530 = sext i32 0 to i64
  %t1531 = load i64, i64* %t1526
  %t1532 = load i64, i64* %t1528
  %t1533 = icmp ult i64 %t1530, %t1532
  br i1 %t1533, label %ring_rplace_ok_270, label %ring_rplace_oob_271
ring_rplace_ok_270:
  %t1534 = add i64 %t1531, %t1530
  %t1535 = urem i64 %t1534, 2
  %t1536 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1525, i32 0, i64 %t1535
  br label %ring_rplace_end_272
ring_rplace_oob_271:
  store i8* null, i8** %t1537
  br label %ring_rplace_end_272
ring_rplace_end_272:
  %t1538 = phi i8** [ %t1536, %ring_rplace_ok_270 ], [ %t1537, %ring_rplace_oob_271 ]
  %t1539 = load i8*, i8** %t1538
  %t1540 = icmp eq i8* %t1539, null
  br i1 %t1540, label %table_read_null_273, label %table_read_real_274
table_read_null_273:
  br label %table_read_end_275
table_read_real_274:
  %t1541 = bitcast i8* %t1539 to { i64, i64, i32* }*
  %t1542 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1541, i32 0, i32 0
  %t1543 = load i64, i64* %t1542
  %t1544 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1541, i32 0, i32 2
  %t1545 = load i32*, i32** %t1544
  br label %table_read_end_275
table_read_end_275:
  %t1546 = phi i64 [ 0, %table_read_null_273 ], [ %t1543, %table_read_real_274 ]
  %t1547 = phi i32* [ null, %table_read_null_273 ], [ %t1545, %table_read_real_274 ]
  %t1549 = icmp ult i64 %t1524, %t1546
  br i1 %t1549, label %table_idx_ok_276, label %table_idx_oob_277
table_idx_ok_276:
  %t1550 = getelementptr inbounds i32, i32* %t1547, i64 %t1524
  %t1551 = load i32, i32* %t1550
  %t1552 = getelementptr inbounds %Item, %Item* %t1548, i32 0, i32 0
  store i32 %t1551, i32* %t1552
  br label %table_idx_end_278
table_idx_oob_277:
  %t1553 = getelementptr inbounds %Item, %Item* %t1548, i32 0, i32 0
  store i32 0, i32* %t1553
  br label %table_idx_end_278
table_idx_end_278:
  %t1554 = load %Item, %Item* %t1548
  store %Item %t1554, %Item* %t1555
  %t1556 = getelementptr inbounds %Item, %Item* %t1555, i32 0, i32 0
  %t1557 = load i32, i32* %t1556
  %t1558 = getelementptr inbounds [45 x i8], [45 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1558, i32 %t1499, i32 %t1523, i32 %t1557)
  %t1559 = load i8*, i8** %t1411
  call void @star_rc_release(i8* %t1559)
  %t1560 = load i8*, i8** %t1104
  call void @star_rc_release(i8* %t1560)
  %t1561 = load i8*, i8** %t1015
  call void @star_rc_release(i8* %t1561)
  %t1562 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1014, i32 0, i32 0
  %t1563 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1562, i32 0, i64 0
  %t1564 = load i8*, i8** %t1563
  call void @star_rc_release(i8* %t1564)
  %t1565 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1562, i32 0, i64 1
  %t1566 = load i8*, i8** %t1565
  call void @star_rc_release(i8* %t1566)
  %t1567 = getelementptr inbounds %Bag, %Bag* %t923, i32 0, i32 0
  %t1568 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1567, i32 0, i32 0
  %t1569 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1568, i32 0, i64 0
  %t1570 = load i8*, i8** %t1569
  call void @star_rc_release(i8* %t1570)
  %t1571 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1568, i32 0, i64 1
  %t1572 = load i8*, i8** %t1571
  call void @star_rc_release(i8* %t1572)
  %t1573 = load i8*, i8** %t790
  call void @star_rc_release(i8* %t1573)
  %t1574 = getelementptr inbounds %Bag, %Bag* %t770, i32 0, i32 0
  %t1575 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1574, i32 0, i32 0
  %t1576 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1575, i32 0, i64 0
  %t1577 = load i8*, i8** %t1576
  call void @star_rc_release(i8* %t1577)
  %t1578 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1575, i32 0, i64 1
  %t1579 = load i8*, i8** %t1578
  call void @star_rc_release(i8* %t1579)
  %t1580 = getelementptr inbounds %Bag, %Bag* %t733, i32 0, i32 0
  %t1581 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1580, i32 0, i32 0
  %t1582 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1581, i32 0, i64 0
  %t1583 = load i8*, i8** %t1582
  call void @star_rc_release(i8* %t1583)
  %t1584 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1581, i32 0, i64 1
  %t1585 = load i8*, i8** %t1584
  call void @star_rc_release(i8* %t1585)
  %t1586 = getelementptr inbounds %Bag, %Bag* %t701, i32 0, i32 0
  %t1587 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1586, i32 0, i32 0
  %t1588 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1587, i32 0, i64 0
  %t1589 = load i8*, i8** %t1588
  call void @star_rc_release(i8* %t1589)
  %t1590 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1587, i32 0, i64 1
  %t1591 = load i8*, i8** %t1590
  call void @star_rc_release(i8* %t1591)
  %t1592 = getelementptr inbounds %Bag, %Bag* %t652, i32 0, i32 0
  %t1593 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1592, i32 0, i32 0
  %t1594 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1593, i32 0, i64 0
  %t1595 = load i8*, i8** %t1594
  call void @star_rc_release(i8* %t1595)
  %t1596 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1593, i32 0, i64 1
  %t1597 = load i8*, i8** %t1596
  call void @star_rc_release(i8* %t1597)
  %t1598 = getelementptr inbounds %Bag, %Bag* %t604, i32 0, i32 0
  %t1599 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1598, i32 0, i32 0
  %t1600 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1599, i32 0, i64 0
  %t1601 = load i8*, i8** %t1600
  call void @star_rc_release(i8* %t1601)
  %t1602 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1599, i32 0, i64 1
  %t1603 = load i8*, i8** %t1602
  call void @star_rc_release(i8* %t1603)
  %t1604 = getelementptr inbounds %Bag, %Bag* %t567, i32 0, i32 0
  %t1605 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1604, i32 0, i32 0
  %t1606 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1605, i32 0, i64 0
  %t1607 = load i8*, i8** %t1606
  call void @star_rc_release(i8* %t1607)
  %t1608 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1605, i32 0, i64 1
  %t1609 = load i8*, i8** %t1608
  call void @star_rc_release(i8* %t1609)
  %t1610 = getelementptr inbounds %Bag, %Bag* %t535, i32 0, i32 0
  %t1611 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1610, i32 0, i32 0
  %t1612 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1611, i32 0, i64 0
  %t1613 = load i8*, i8** %t1612
  call void @star_rc_release(i8* %t1613)
  %t1614 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1611, i32 0, i64 1
  %t1615 = load i8*, i8** %t1614
  call void @star_rc_release(i8* %t1615)
  %t1616 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t367, i32 0, i32 0
  %t1617 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1616, i32 0, i64 0
  %t1618 = load i8*, i8** %t1617
  call void @star_rc_release(i8* %t1618)
  %t1619 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1616, i32 0, i64 1
  %t1620 = load i8*, i8** %t1619
  call void @star_rc_release(i8* %t1620)
  %t1621 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t208, i32 0, i32 0
  %t1622 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1621, i32 0, i64 0
  %t1623 = load i8*, i8** %t1622
  call void @star_rc_release(i8* %t1623)
  %t1624 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1621, i32 0, i64 1
  %t1625 = load i8*, i8** %t1624
  call void @star_rc_release(i8* %t1625)
  %t1626 = load i8*, i8** %t207
  call void @star_rc_release(i8* %t1626)
  %t1627 = getelementptr inbounds %Snapshot, %Snapshot* %t89, i32 0, i32 2
  %t1628 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1627, i32 0, i32 0
  %t1629 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1628, i32 0, i64 0
  %t1630 = getelementptr inbounds %Player, %Player* %t1629, i32 0, i32 0
  %t1631 = load i8*, i8** %t1630
  call void @star_rc_release(i8* %t1631)
  %t1632 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1628, i32 0, i64 1
  %t1633 = getelementptr inbounds %Player, %Player* %t1632, i32 0, i32 0
  %t1634 = load i8*, i8** %t1633
  call void @star_rc_release(i8* %t1634)
  %t1635 = getelementptr inbounds %Snapshot, %Snapshot* %t2, i32 0, i32 2
  %t1636 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1635, i32 0, i32 0
  %t1637 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1636, i32 0, i64 0
  %t1638 = getelementptr inbounds %Player, %Player* %t1637, i32 0, i32 0
  %t1639 = load i8*, i8** %t1638
  call void @star_rc_release(i8* %t1639)
  %t1640 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1636, i32 0, i64 1
  %t1641 = getelementptr inbounds %Player, %Player* %t1640, i32 0, i32 0
  %t1642 = load i8*, i8** %t1641
  call void @star_rc_release(i8* %t1642)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Bag(i8* %objp) {
entry:
  %t246 = alloca i64
  %t241 = bitcast i8* %objp to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t242 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t241, i32 0, i32 0
  %t243 = load i64, i64* %t242
  %t244 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t241, i32 0, i32 2
  %t245 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t244
  store i64 0, i64* %t246
  br label %table_release_cond_48
table_release_cond_48:
  %t247 = load i64, i64* %t246
  %t248 = icmp slt i64 %t247, %t243
  br i1 %t248, label %table_release_body_49, label %table_release_end_50
table_release_body_49:
  %t249 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t245, i64 %t247
  %t250 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t249, i32 0, i32 0
  %t251 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t250, i32 0, i64 0
  %t252 = load i8*, i8** %t251
  call void @star_rc_release(i8* %t252)
  %t253 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t250, i32 0, i64 1
  %t254 = load i8*, i8** %t253
  call void @star_rc_release(i8* %t254)
  %t255 = add i64 %t247, 1
  store i64 %t255, i64* %t246
  br label %table_release_cond_48
table_release_end_50:
  %t256 = bitcast { [2 x i8*], i64, i64 }* %t245 to i8*
  call void @free(i8* %t256)
  %t257 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t241, i32 0, i32 3
  %t258 = load i32*, i32** %t257
  %t259 = bitcast i32* %t258 to i8*
  call void @free(i8* %t259)
  ret void
}


define void @table_release_s_Item(i8* %objp) {
entry:
  %t1018 = bitcast i8* %objp to { i64, i64, i32* }*
  %t1019 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1018, i32 0, i32 0
  %t1020 = load i64, i64* %t1019
  %t1021 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1018, i32 0, i32 2
  %t1022 = load i32*, i32** %t1021
  %t1023 = bitcast i32* %t1022 to i8*
  call void @free(i8* %t1023)
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
