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

%Player = type { i8*, i32 }
%Snapshot = type { i32, { [3 x i32], i64, i64 }, { [2 x %Player], i64, i64 } }
%Bag = type { { [2 x i8*], i64, i64 }, i32 }
%Item = type { i32 }
define %Snapshot @make_snapshot() {
entry:
  %t0 = alloca { [3 x i32], i64, i64 }
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
  %t27 = alloca { [2 x %Player], i64, i64 }
  store { [2 x %Player], i64, i64 } zeroinitializer, { [2 x %Player], i64, i64 }* %t27
  %t28 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27, i32 0, i32 0
  %t29 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27, i32 0, i32 1
  %t30 = load i64, i64* %t29
  %t31 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t27, i32 0, i32 2
  %t32 = load i64, i64* %t31
  %t33 = alloca %Player
  %t34 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t35 = getelementptr inbounds %Player, %Player* %t33, i32 0, i32 0
  store i8* %t34, i8** %t35
  %t36 = getelementptr inbounds %Player, %Player* %t33, i32 0, i32 1
  store i32 100, i32* %t36
  %t37 = load %Player, %Player* %t33
  %t38 = icmp sge i64 %t32, 2
  br i1 %t38, label %ring_push_full_6, label %ring_push_grow_7
ring_push_grow_7:
  %t39 = add i64 %t30, %t32
  %t40 = urem i64 %t39, 2
  %t41 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t28, i32 0, i64 %t40
  store %Player %t37, %Player* %t41
  %t42 = add i64 %t32, 1
  store i64 %t42, i64* %t31
  br label %ring_push_done_8
ring_push_full_6:
  %t43 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t28, i32 0, i64 %t30
  %t44 = getelementptr inbounds %Player, %Player* %t43, i32 0, i32 0
  %t45 = load i8*, i8** %t44
  call void @star_rc_release(i8* %t45)
  store %Player %t37, %Player* %t43
  %t46 = add i64 %t30, 1
  %t47 = urem i64 %t46, 2
  store i64 %t47, i64* %t29
  br label %ring_push_done_8
ring_push_done_8:
  %t48 = alloca %Snapshot
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
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca %Snapshot
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
  %t18 = icmp ult i64 %t17, %t16
  br i1 %t18, label %ring_rplace_ok_9, label %ring_rplace_oob_10
ring_rplace_ok_9:
  %t19 = add i64 %t14, %t17
  %t20 = urem i64 %t19, 3
  %t21 = getelementptr inbounds [3 x i32], [3 x i32]* %t12, i32 0, i64 %t20
  br label %ring_rplace_end_11
ring_rplace_oob_10:
  %t22 = alloca i32
  store i32 0, i32* %t22
  br label %ring_rplace_end_11
ring_rplace_end_11:
  %t23 = phi i32* [ %t21, %ring_rplace_ok_9 ], [ %t22, %ring_rplace_oob_10 ]
  %t24 = load i32, i32* %t23
  %t25 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t26 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t25, i32 0, i32 0
  %t27 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t25, i32 0, i32 1
  %t28 = load i64, i64* %t27
  %t29 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t25, i32 0, i32 2
  %t30 = load i64, i64* %t29
  %t31 = sext i32 1 to i64
  %t32 = icmp ult i64 %t31, %t30
  br i1 %t32, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t33 = add i64 %t28, %t31
  %t34 = urem i64 %t33, 3
  %t35 = getelementptr inbounds [3 x i32], [3 x i32]* %t26, i32 0, i64 %t34
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  %t36 = alloca i32
  store i32 0, i32* %t36
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t37 = phi i32* [ %t35, %ring_rplace_ok_12 ], [ %t36, %ring_rplace_oob_13 ]
  %t38 = load i32, i32* %t37
  %t39 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t39, i32 %t3, i32 %t10, i32 %t24, i32 %t38)
  %t40 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t41 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t40, i32 0, i32 0
  %t42 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t40, i32 0, i32 1
  %t43 = load i64, i64* %t42
  %t44 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t40, i32 0, i32 2
  %t45 = load i64, i64* %t44
  %t46 = trunc i64 %t45 to i32
  %t47 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t48 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t47, i32 0, i32 0
  %t49 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t47, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t47, i32 0, i32 2
  %t52 = load i64, i64* %t51
  %t53 = sext i32 0 to i64
  %t54 = icmp ult i64 %t53, %t52
  br i1 %t54, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t55 = add i64 %t50, %t53
  %t56 = urem i64 %t55, 2
  %t57 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t48, i32 0, i64 %t56
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  %t58 = alloca %Player
  store %Player zeroinitializer, %Player* %t58
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t59 = phi %Player* [ %t57, %ring_rplace_ok_15 ], [ %t58, %ring_rplace_oob_16 ]
  %t60 = getelementptr inbounds %Player, %Player* %t59, i32 0, i32 0
  %t61 = load i8*, i8** %t60
  %t62 = load i8*, i8** %t60
  call void @star_rc_retain(i8* %t62)
  call void @star_rc_release(i8* %t61)
  %t63 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t64 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t63, i32 0, i32 0
  %t65 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t63, i32 0, i32 1
  %t66 = load i64, i64* %t65
  %t67 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t63, i32 0, i32 2
  %t68 = load i64, i64* %t67
  %t69 = sext i32 0 to i64
  %t70 = icmp ult i64 %t69, %t68
  br i1 %t70, label %ring_rplace_ok_18, label %ring_rplace_oob_19
ring_rplace_ok_18:
  %t71 = add i64 %t66, %t69
  %t72 = urem i64 %t71, 2
  %t73 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t64, i32 0, i64 %t72
  br label %ring_rplace_end_20
ring_rplace_oob_19:
  %t74 = alloca %Player
  store %Player zeroinitializer, %Player* %t74
  br label %ring_rplace_end_20
ring_rplace_end_20:
  %t75 = phi %Player* [ %t73, %ring_rplace_ok_18 ], [ %t74, %ring_rplace_oob_19 ]
  %t76 = getelementptr inbounds %Player, %Player* %t75, i32 0, i32 1
  %t77 = load i32, i32* %t76
  %t78 = getelementptr inbounds [35 x i8], [35 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t78, i32 %t46, i8* %t61, i32 %t77)
  %t79 = alloca %Snapshot
  %t80 = load %Snapshot, %Snapshot* %t0
  %t81 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t82 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t81, i32 0, i32 0
  %t83 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t82, i32 0, i64 0
  %t84 = getelementptr inbounds %Player, %Player* %t83, i32 0, i32 0
  %t85 = load i8*, i8** %t84
  call void @star_rc_retain(i8* %t85)
  %t86 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t82, i32 0, i64 1
  %t87 = getelementptr inbounds %Player, %Player* %t86, i32 0, i32 0
  %t88 = load i8*, i8** %t87
  call void @star_rc_retain(i8* %t88)
  store %Snapshot %t80, %Snapshot* %t79
  %t89 = getelementptr inbounds %Snapshot, %Snapshot* %t79, i32 0, i32 1
  %t90 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t89, i32 0, i32 0
  %t91 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t89, i32 0, i32 1
  %t92 = load i64, i64* %t91
  %t93 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t89, i32 0, i32 2
  %t94 = load i64, i64* %t93
  %t95 = icmp sge i64 %t94, 3
  br i1 %t95, label %ring_push_full_21, label %ring_push_grow_22
ring_push_grow_22:
  %t96 = add i64 %t92, %t94
  %t97 = urem i64 %t96, 3
  %t98 = getelementptr inbounds [3 x i32], [3 x i32]* %t90, i32 0, i64 %t97
  store i32 3, i32* %t98
  %t99 = add i64 %t94, 1
  store i64 %t99, i64* %t93
  br label %ring_push_done_23
ring_push_full_21:
  %t100 = getelementptr inbounds [3 x i32], [3 x i32]* %t90, i32 0, i64 %t92
  store i32 3, i32* %t100
  %t101 = add i64 %t92, 1
  %t102 = urem i64 %t101, 3
  store i64 %t102, i64* %t91
  br label %ring_push_done_23
ring_push_done_23:
  %t103 = getelementptr inbounds %Snapshot, %Snapshot* %t79, i32 0, i32 1
  %t104 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t103, i32 0, i32 0
  %t105 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t103, i32 0, i32 1
  %t106 = load i64, i64* %t105
  %t107 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t103, i32 0, i32 2
  %t108 = load i64, i64* %t107
  %t109 = icmp sge i64 %t108, 3
  br i1 %t109, label %ring_push_full_24, label %ring_push_grow_25
ring_push_grow_25:
  %t110 = add i64 %t106, %t108
  %t111 = urem i64 %t110, 3
  %t112 = getelementptr inbounds [3 x i32], [3 x i32]* %t104, i32 0, i64 %t111
  store i32 4, i32* %t112
  %t113 = add i64 %t108, 1
  store i64 %t113, i64* %t107
  br label %ring_push_done_26
ring_push_full_24:
  %t114 = getelementptr inbounds [3 x i32], [3 x i32]* %t104, i32 0, i64 %t106
  store i32 4, i32* %t114
  %t115 = add i64 %t106, 1
  %t116 = urem i64 %t115, 3
  store i64 %t116, i64* %t105
  br label %ring_push_done_26
ring_push_done_26:
  %t117 = getelementptr inbounds %Snapshot, %Snapshot* %t79, i32 0, i32 1
  %t118 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t117, i32 0, i32 0
  %t119 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t117, i32 0, i32 1
  %t120 = load i64, i64* %t119
  %t121 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t117, i32 0, i32 2
  %t122 = load i64, i64* %t121
  %t123 = trunc i64 %t122 to i32
  %t124 = getelementptr inbounds %Snapshot, %Snapshot* %t79, i32 0, i32 1
  %t125 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t124, i32 0, i32 0
  %t126 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t124, i32 0, i32 1
  %t127 = load i64, i64* %t126
  %t128 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t124, i32 0, i32 2
  %t129 = load i64, i64* %t128
  %t130 = sext i32 0 to i64
  %t131 = icmp ult i64 %t130, %t129
  br i1 %t131, label %ring_rplace_ok_27, label %ring_rplace_oob_28
ring_rplace_ok_27:
  %t132 = add i64 %t127, %t130
  %t133 = urem i64 %t132, 3
  %t134 = getelementptr inbounds [3 x i32], [3 x i32]* %t125, i32 0, i64 %t133
  br label %ring_rplace_end_29
ring_rplace_oob_28:
  %t135 = alloca i32
  store i32 0, i32* %t135
  br label %ring_rplace_end_29
ring_rplace_end_29:
  %t136 = phi i32* [ %t134, %ring_rplace_ok_27 ], [ %t135, %ring_rplace_oob_28 ]
  %t137 = load i32, i32* %t136
  %t138 = getelementptr inbounds %Snapshot, %Snapshot* %t79, i32 0, i32 1
  %t139 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t138, i32 0, i32 0
  %t140 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t138, i32 0, i32 1
  %t141 = load i64, i64* %t140
  %t142 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t138, i32 0, i32 2
  %t143 = load i64, i64* %t142
  %t144 = sext i32 1 to i64
  %t145 = icmp ult i64 %t144, %t143
  br i1 %t145, label %ring_rplace_ok_30, label %ring_rplace_oob_31
ring_rplace_ok_30:
  %t146 = add i64 %t141, %t144
  %t147 = urem i64 %t146, 3
  %t148 = getelementptr inbounds [3 x i32], [3 x i32]* %t139, i32 0, i64 %t147
  br label %ring_rplace_end_32
ring_rplace_oob_31:
  %t149 = alloca i32
  store i32 0, i32* %t149
  br label %ring_rplace_end_32
ring_rplace_end_32:
  %t150 = phi i32* [ %t148, %ring_rplace_ok_30 ], [ %t149, %ring_rplace_oob_31 ]
  %t151 = load i32, i32* %t150
  %t152 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t152, i32 %t123, i32 %t137, i32 %t151)
  %t153 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t154 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t153, i32 0, i32 0
  %t155 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t153, i32 0, i32 1
  %t156 = load i64, i64* %t155
  %t157 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t153, i32 0, i32 2
  %t158 = load i64, i64* %t157
  %t159 = trunc i64 %t158 to i32
  %t160 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t161 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t160, i32 0, i32 0
  %t162 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t160, i32 0, i32 1
  %t163 = load i64, i64* %t162
  %t164 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t160, i32 0, i32 2
  %t165 = load i64, i64* %t164
  %t166 = sext i32 0 to i64
  %t167 = icmp ult i64 %t166, %t165
  br i1 %t167, label %ring_rplace_ok_33, label %ring_rplace_oob_34
ring_rplace_ok_33:
  %t168 = add i64 %t163, %t166
  %t169 = urem i64 %t168, 3
  %t170 = getelementptr inbounds [3 x i32], [3 x i32]* %t161, i32 0, i64 %t169
  br label %ring_rplace_end_35
ring_rplace_oob_34:
  %t171 = alloca i32
  store i32 0, i32* %t171
  br label %ring_rplace_end_35
ring_rplace_end_35:
  %t172 = phi i32* [ %t170, %ring_rplace_ok_33 ], [ %t171, %ring_rplace_oob_34 ]
  %t173 = load i32, i32* %t172
  %t174 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 1
  %t175 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t174, i32 0, i32 0
  %t176 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t174, i32 0, i32 1
  %t177 = load i64, i64* %t176
  %t178 = getelementptr inbounds { [3 x i32], i64, i64 }, { [3 x i32], i64, i64 }* %t174, i32 0, i32 2
  %t179 = load i64, i64* %t178
  %t180 = sext i32 1 to i64
  %t181 = icmp ult i64 %t180, %t179
  br i1 %t181, label %ring_rplace_ok_36, label %ring_rplace_oob_37
ring_rplace_ok_36:
  %t182 = add i64 %t177, %t180
  %t183 = urem i64 %t182, 3
  %t184 = getelementptr inbounds [3 x i32], [3 x i32]* %t175, i32 0, i64 %t183
  br label %ring_rplace_end_38
ring_rplace_oob_37:
  %t185 = alloca i32
  store i32 0, i32* %t185
  br label %ring_rplace_end_38
ring_rplace_end_38:
  %t186 = phi i32* [ %t184, %ring_rplace_ok_36 ], [ %t185, %ring_rplace_oob_37 ]
  %t187 = load i32, i32* %t186
  %t188 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t188, i32 %t159, i32 %t173, i32 %t187)
  %t189 = alloca i8*
  store i8* null, i8** %t189
  %t190 = alloca { [2 x i8*], i64, i64 }
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t190
  %t191 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190, i32 0, i32 0
  %t192 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190, i32 0, i32 1
  %t193 = load i64, i64* %t192
  %t194 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190, i32 0, i32 2
  %t195 = load i64, i64* %t194
  %t196 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t197 = icmp sge i64 %t195, 2
  br i1 %t197, label %ring_push_full_39, label %ring_push_grow_40
ring_push_grow_40:
  %t198 = add i64 %t193, %t195
  %t199 = urem i64 %t198, 2
  %t200 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t191, i32 0, i64 %t199
  store i8* %t196, i8** %t200
  %t201 = add i64 %t195, 1
  store i64 %t201, i64* %t194
  br label %ring_push_done_41
ring_push_full_39:
  %t202 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t191, i32 0, i64 %t193
  %t203 = load i8*, i8** %t202
  call void @star_rc_release(i8* %t203)
  store i8* %t196, i8** %t202
  %t204 = add i64 %t193, 1
  %t205 = urem i64 %t204, 2
  store i64 %t205, i64* %t192
  br label %ring_push_done_41
ring_push_done_41:
  %t206 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190, i32 0, i32 0
  %t207 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190, i32 0, i32 1
  %t208 = load i64, i64* %t207
  %t209 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190, i32 0, i32 2
  %t210 = load i64, i64* %t209
  %t211 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t212 = icmp sge i64 %t210, 2
  br i1 %t212, label %ring_push_full_42, label %ring_push_grow_43
ring_push_grow_43:
  %t213 = add i64 %t208, %t210
  %t214 = urem i64 %t213, 2
  %t215 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t206, i32 0, i64 %t214
  store i8* %t211, i8** %t215
  %t216 = add i64 %t210, 1
  store i64 %t216, i64* %t209
  br label %ring_push_done_44
ring_push_full_42:
  %t217 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t206, i32 0, i64 %t208
  %t218 = load i8*, i8** %t217
  call void @star_rc_release(i8* %t218)
  store i8* %t211, i8** %t217
  %t219 = add i64 %t208, 1
  %t220 = urem i64 %t219, 2
  store i64 %t220, i64* %t207
  br label %ring_push_done_44
ring_push_done_44:
  %t221 = load i8*, i8** %t189
  %t222 = icmp eq i8* %t221, null
  br i1 %t222, label %table_cow_alloc_45, label %table_cow_check_46
table_cow_alloc_45:
  %t242 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t243 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t244 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t243 to i64
  %t245 = call i8* @star_rc_alloc(i64 %t244, i8* %t242)
  %t246 = bitcast i8* %t245 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t247 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t246, i32 0, i32 0
  store i64 0, i64* %t247
  %t248 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t246, i32 0, i32 1
  store i64 0, i64* %t248
  %t249 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t246, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t249
  %t250 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t246, i32 0, i32 3
  store i32* null, i32** %t250
  store i8* %t245, i8** %t189
  br label %table_cow_done_47
table_cow_check_46:
  %t251 = getelementptr inbounds i8, i8* %t221, i64 -16
  %t252 = bitcast i8* %t251 to i64*
  %t253 = load atomic i64, i64* %t252 seq_cst, align 8
  %t254 = icmp eq i64 %t253, 1
  br i1 %t254, label %table_cow_done_47, label %table_cow_clone_51
table_cow_clone_51:
  %t255 = bitcast i8* %t221 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t256 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t255, i32 0, i32 0
  %t257 = load i64, i64* %t256
  %t258 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t255, i32 0, i32 1
  %t259 = load i64, i64* %t258
  %t260 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t261 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t262 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t261 to i64
  %t263 = call i8* @star_rc_alloc(i64 %t262, i8* %t260)
  %t264 = bitcast i8* %t263 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t265 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t264, i32 0, i32 0
  store i64 %t257, i64* %t265
  %t266 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t264, i32 0, i32 1
  store i64 %t259, i64* %t266
  %t267 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t268 = ptrtoint { [2 x i8*], i64, i64 }* %t267 to i64
  %t269 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t255, i32 0, i32 2
  %t270 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t269
  %t271 = mul i64 %t259, %t268
  %t272 = call i8* @malloc(i64 %t271)
  %t273 = bitcast i8* %t272 to { [2 x i8*], i64, i64 }*
  %t274 = icmp sgt i64 %t257, 0
  br i1 %t274, label %table_cow_copy_52, label %table_cow_after_copy_53
table_cow_copy_52:
  %t275 = mul i64 %t257, %t268
  %t276 = bitcast { [2 x i8*], i64, i64 }* %t270 to i8*
  call i8* @memcpy(i8* %t272, i8* %t276, i64 %t275)
  %t277 = alloca i64
  store i64 0, i64* %t277
  br label %table_cow_retain_cond_54
table_cow_retain_cond_54:
  %t278 = load i64, i64* %t277
  %t279 = icmp slt i64 %t278, %t257
  br i1 %t279, label %table_cow_retain_body_55, label %table_cow_retain_end_56
table_cow_retain_body_55:
  %t280 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t273, i64 %t278
  %t281 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t280, i32 0, i32 0
  %t282 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t281, i32 0, i64 0
  %t283 = load i8*, i8** %t282
  call void @star_rc_retain(i8* %t283)
  %t284 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t281, i32 0, i64 1
  %t285 = load i8*, i8** %t284
  call void @star_rc_retain(i8* %t285)
  %t286 = add i64 %t278, 1
  store i64 %t286, i64* %t277
  br label %table_cow_retain_cond_54
table_cow_retain_end_56:
  br label %table_cow_after_copy_53
table_cow_after_copy_53:
  %t287 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t264, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t273, { [2 x i8*], i64, i64 }** %t287
  %t288 = getelementptr i32, i32* null, i32 1
  %t289 = ptrtoint i32* %t288 to i64
  %t290 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t255, i32 0, i32 3
  %t291 = load i32*, i32** %t290
  %t292 = mul i64 %t259, %t289
  %t293 = call i8* @malloc(i64 %t292)
  %t294 = bitcast i8* %t293 to i32*
  %t295 = icmp sgt i64 %t257, 0
  br i1 %t295, label %table_cow_copy_57, label %table_cow_after_copy_58
table_cow_copy_57:
  %t296 = mul i64 %t257, %t289
  %t297 = bitcast i32* %t291 to i8*
  call i8* @memcpy(i8* %t293, i8* %t297, i64 %t296)
  br label %table_cow_after_copy_58
table_cow_after_copy_58:
  %t298 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t264, i32 0, i32 3
  store i32* %t294, i32** %t298
  call void @star_rc_release(i8* %t221)
  store i8* %t263, i8** %t189
  br label %table_cow_done_47
table_cow_done_47:
  %t299 = load i8*, i8** %t189
  %t300 = bitcast i8* %t299 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t301 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t300, i32 0, i32 0
  %t302 = load i64, i64* %t301
  %t303 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t300, i32 0, i32 1
  %t304 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t300, i32 0, i32 2
  %t305 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t304
  %t306 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t300, i32 0, i32 3
  %t307 = load i32*, i32** %t306
  %t308 = alloca %Bag
  %t309 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190
  %t310 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190, i32 0, i32 0
  %t311 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t310, i32 0, i64 0
  %t312 = load i8*, i8** %t311
  call void @star_rc_retain(i8* %t312)
  %t313 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t310, i32 0, i64 1
  %t314 = load i8*, i8** %t313
  call void @star_rc_retain(i8* %t314)
  %t315 = getelementptr inbounds %Bag, %Bag* %t308, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t309, { [2 x i8*], i64, i64 }* %t315
  %t316 = getelementptr inbounds %Bag, %Bag* %t308, i32 0, i32 1
  store i32 1, i32* %t316
  %t317 = load %Bag, %Bag* %t308
  %t318 = load i64, i64* %t303
  %t319 = icmp sge i64 %t302, %t318
  br i1 %t319, label %table_push_grow_59, label %table_push_store_60
table_push_grow_59:
  %t320 = mul i64 %t318, 2
  %t321 = icmp sgt i64 %t320, 0
  %t322 = select i1 %t321, i64 %t320, i64 1
  %t323 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t324 = ptrtoint { [2 x i8*], i64, i64 }* %t323 to i64
  %t325 = mul i64 %t322, %t324
  %t326 = call i8* @malloc(i64 %t325)
  %t327 = bitcast i8* %t326 to { [2 x i8*], i64, i64 }*
  %t328 = icmp sgt i64 %t318, 0
  br i1 %t328, label %table_push_copy_61, label %table_push_after_copy_62
table_push_copy_61:
  %t329 = mul i64 %t302, %t324
  %t330 = bitcast { [2 x i8*], i64, i64 }* %t305 to i8*
  call i8* @memcpy(i8* %t326, i8* %t330, i64 %t329)
  call void @free(i8* %t330)
  br label %table_push_after_copy_62
table_push_after_copy_62:
  store { [2 x i8*], i64, i64 }* %t327, { [2 x i8*], i64, i64 }** %t304
  %t331 = getelementptr i32, i32* null, i32 1
  %t332 = ptrtoint i32* %t331 to i64
  %t333 = mul i64 %t322, %t332
  %t334 = call i8* @malloc(i64 %t333)
  %t335 = bitcast i8* %t334 to i32*
  %t336 = icmp sgt i64 %t318, 0
  br i1 %t336, label %table_push_copy_63, label %table_push_after_copy_64
table_push_copy_63:
  %t337 = mul i64 %t302, %t332
  %t338 = bitcast i32* %t307 to i8*
  call i8* @memcpy(i8* %t334, i8* %t338, i64 %t337)
  call void @free(i8* %t338)
  br label %table_push_after_copy_64
table_push_after_copy_64:
  store i32* %t335, i32** %t306
  store i64 %t322, i64* %t303
  br label %table_push_store_60
table_push_store_60:
  %t339 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t304
  %t340 = extractvalue %Bag %t317, 0
  %t341 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t339, i64 %t302
  store { [2 x i8*], i64, i64 } %t340, { [2 x i8*], i64, i64 }* %t341
  %t342 = load i32*, i32** %t306
  %t343 = extractvalue %Bag %t317, 1
  %t344 = getelementptr inbounds i32, i32* %t342, i64 %t302
  store i32 %t343, i32* %t344
  %t345 = add i64 %t302, 1
  store i64 %t345, i64* %t301
  %t346 = alloca { [2 x i8*], i64, i64 }
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t346
  %t347 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t346, i32 0, i32 0
  %t348 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t346, i32 0, i32 1
  %t349 = load i64, i64* %t348
  %t350 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t346, i32 0, i32 2
  %t351 = load i64, i64* %t350
  %t352 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t353 = icmp sge i64 %t351, 2
  br i1 %t353, label %ring_push_full_65, label %ring_push_grow_66
ring_push_grow_66:
  %t354 = add i64 %t349, %t351
  %t355 = urem i64 %t354, 2
  %t356 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t347, i32 0, i64 %t355
  store i8* %t352, i8** %t356
  %t357 = add i64 %t351, 1
  store i64 %t357, i64* %t350
  br label %ring_push_done_67
ring_push_full_65:
  %t358 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t347, i32 0, i64 %t349
  %t359 = load i8*, i8** %t358
  call void @star_rc_release(i8* %t359)
  store i8* %t352, i8** %t358
  %t360 = add i64 %t349, 1
  %t361 = urem i64 %t360, 2
  store i64 %t361, i64* %t348
  br label %ring_push_done_67
ring_push_done_67:
  %t362 = load i8*, i8** %t189
  %t363 = icmp eq i8* %t362, null
  br i1 %t363, label %table_cow_alloc_68, label %table_cow_check_69
table_cow_alloc_68:
  %t364 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t365 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t366 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t365 to i64
  %t367 = call i8* @star_rc_alloc(i64 %t366, i8* %t364)
  %t368 = bitcast i8* %t367 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t369 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t368, i32 0, i32 0
  store i64 0, i64* %t369
  %t370 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t368, i32 0, i32 1
  store i64 0, i64* %t370
  %t371 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t368, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t371
  %t372 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t368, i32 0, i32 3
  store i32* null, i32** %t372
  store i8* %t367, i8** %t189
  br label %table_cow_done_70
table_cow_check_69:
  %t373 = getelementptr inbounds i8, i8* %t362, i64 -16
  %t374 = bitcast i8* %t373 to i64*
  %t375 = load atomic i64, i64* %t374 seq_cst, align 8
  %t376 = icmp eq i64 %t375, 1
  br i1 %t376, label %table_cow_done_70, label %table_cow_clone_71
table_cow_clone_71:
  %t377 = bitcast i8* %t362 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t378 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t377, i32 0, i32 0
  %t379 = load i64, i64* %t378
  %t380 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t377, i32 0, i32 1
  %t381 = load i64, i64* %t380
  %t382 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t383 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t384 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t383 to i64
  %t385 = call i8* @star_rc_alloc(i64 %t384, i8* %t382)
  %t386 = bitcast i8* %t385 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t387 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t386, i32 0, i32 0
  store i64 %t379, i64* %t387
  %t388 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t386, i32 0, i32 1
  store i64 %t381, i64* %t388
  %t389 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t390 = ptrtoint { [2 x i8*], i64, i64 }* %t389 to i64
  %t391 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t377, i32 0, i32 2
  %t392 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t391
  %t393 = mul i64 %t381, %t390
  %t394 = call i8* @malloc(i64 %t393)
  %t395 = bitcast i8* %t394 to { [2 x i8*], i64, i64 }*
  %t396 = icmp sgt i64 %t379, 0
  br i1 %t396, label %table_cow_copy_72, label %table_cow_after_copy_73
table_cow_copy_72:
  %t397 = mul i64 %t379, %t390
  %t398 = bitcast { [2 x i8*], i64, i64 }* %t392 to i8*
  call i8* @memcpy(i8* %t394, i8* %t398, i64 %t397)
  %t399 = alloca i64
  store i64 0, i64* %t399
  br label %table_cow_retain_cond_74
table_cow_retain_cond_74:
  %t400 = load i64, i64* %t399
  %t401 = icmp slt i64 %t400, %t379
  br i1 %t401, label %table_cow_retain_body_75, label %table_cow_retain_end_76
table_cow_retain_body_75:
  %t402 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t395, i64 %t400
  %t403 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t402, i32 0, i32 0
  %t404 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t403, i32 0, i64 0
  %t405 = load i8*, i8** %t404
  call void @star_rc_retain(i8* %t405)
  %t406 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t403, i32 0, i64 1
  %t407 = load i8*, i8** %t406
  call void @star_rc_retain(i8* %t407)
  %t408 = add i64 %t400, 1
  store i64 %t408, i64* %t399
  br label %table_cow_retain_cond_74
table_cow_retain_end_76:
  br label %table_cow_after_copy_73
table_cow_after_copy_73:
  %t409 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t386, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t395, { [2 x i8*], i64, i64 }** %t409
  %t410 = getelementptr i32, i32* null, i32 1
  %t411 = ptrtoint i32* %t410 to i64
  %t412 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t377, i32 0, i32 3
  %t413 = load i32*, i32** %t412
  %t414 = mul i64 %t381, %t411
  %t415 = call i8* @malloc(i64 %t414)
  %t416 = bitcast i8* %t415 to i32*
  %t417 = icmp sgt i64 %t379, 0
  br i1 %t417, label %table_cow_copy_77, label %table_cow_after_copy_78
table_cow_copy_77:
  %t418 = mul i64 %t379, %t411
  %t419 = bitcast i32* %t413 to i8*
  call i8* @memcpy(i8* %t415, i8* %t419, i64 %t418)
  br label %table_cow_after_copy_78
table_cow_after_copy_78:
  %t420 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t386, i32 0, i32 3
  store i32* %t416, i32** %t420
  call void @star_rc_release(i8* %t362)
  store i8* %t385, i8** %t189
  br label %table_cow_done_70
table_cow_done_70:
  %t421 = load i8*, i8** %t189
  %t422 = bitcast i8* %t421 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t423 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t422, i32 0, i32 0
  %t424 = load i64, i64* %t423
  %t425 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t422, i32 0, i32 1
  %t426 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t422, i32 0, i32 2
  %t427 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t426
  %t428 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t422, i32 0, i32 3
  %t429 = load i32*, i32** %t428
  %t430 = alloca %Bag
  %t431 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t346
  %t432 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t346, i32 0, i32 0
  %t433 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t432, i32 0, i64 0
  %t434 = load i8*, i8** %t433
  call void @star_rc_retain(i8* %t434)
  %t435 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t432, i32 0, i64 1
  %t436 = load i8*, i8** %t435
  call void @star_rc_retain(i8* %t436)
  %t437 = getelementptr inbounds %Bag, %Bag* %t430, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t431, { [2 x i8*], i64, i64 }* %t437
  %t438 = getelementptr inbounds %Bag, %Bag* %t430, i32 0, i32 1
  store i32 2, i32* %t438
  %t439 = load %Bag, %Bag* %t430
  %t440 = load i64, i64* %t425
  %t441 = icmp sge i64 %t424, %t440
  br i1 %t441, label %table_push_grow_79, label %table_push_store_80
table_push_grow_79:
  %t442 = mul i64 %t440, 2
  %t443 = icmp sgt i64 %t442, 0
  %t444 = select i1 %t443, i64 %t442, i64 1
  %t445 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t446 = ptrtoint { [2 x i8*], i64, i64 }* %t445 to i64
  %t447 = mul i64 %t444, %t446
  %t448 = call i8* @malloc(i64 %t447)
  %t449 = bitcast i8* %t448 to { [2 x i8*], i64, i64 }*
  %t450 = icmp sgt i64 %t440, 0
  br i1 %t450, label %table_push_copy_81, label %table_push_after_copy_82
table_push_copy_81:
  %t451 = mul i64 %t424, %t446
  %t452 = bitcast { [2 x i8*], i64, i64 }* %t427 to i8*
  call i8* @memcpy(i8* %t448, i8* %t452, i64 %t451)
  call void @free(i8* %t452)
  br label %table_push_after_copy_82
table_push_after_copy_82:
  store { [2 x i8*], i64, i64 }* %t449, { [2 x i8*], i64, i64 }** %t426
  %t453 = getelementptr i32, i32* null, i32 1
  %t454 = ptrtoint i32* %t453 to i64
  %t455 = mul i64 %t444, %t454
  %t456 = call i8* @malloc(i64 %t455)
  %t457 = bitcast i8* %t456 to i32*
  %t458 = icmp sgt i64 %t440, 0
  br i1 %t458, label %table_push_copy_83, label %table_push_after_copy_84
table_push_copy_83:
  %t459 = mul i64 %t424, %t454
  %t460 = bitcast i32* %t429 to i8*
  call i8* @memcpy(i8* %t456, i8* %t460, i64 %t459)
  call void @free(i8* %t460)
  br label %table_push_after_copy_84
table_push_after_copy_84:
  store i32* %t457, i32** %t428
  store i64 %t444, i64* %t425
  br label %table_push_store_80
table_push_store_80:
  %t461 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t426
  %t462 = extractvalue %Bag %t439, 0
  %t463 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t461, i64 %t424
  store { [2 x i8*], i64, i64 } %t462, { [2 x i8*], i64, i64 }* %t463
  %t464 = load i32*, i32** %t428
  %t465 = extractvalue %Bag %t439, 1
  %t466 = getelementptr inbounds i32, i32* %t464, i64 %t424
  store i32 %t465, i32* %t466
  %t467 = add i64 %t424, 1
  store i64 %t467, i64* %t423
  %t468 = load i8*, i8** %t189
  %t469 = icmp eq i8* %t468, null
  br i1 %t469, label %table_read_null_85, label %table_read_real_86
table_read_null_85:
  br label %table_read_end_87
table_read_real_86:
  %t470 = bitcast i8* %t468 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t471 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t470, i32 0, i32 0
  %t472 = load i64, i64* %t471
  %t473 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t470, i32 0, i32 2
  %t474 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t473
  %t475 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t470, i32 0, i32 3
  %t476 = load i32*, i32** %t475
  br label %table_read_end_87
table_read_end_87:
  %t477 = phi i64 [ 0, %table_read_null_85 ], [ %t472, %table_read_real_86 ]
  %t478 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_85 ], [ %t474, %table_read_real_86 ]
  %t479 = phi i32* [ null, %table_read_null_85 ], [ %t476, %table_read_real_86 ]
  %t480 = trunc i64 %t477 to i32
  %t481 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t481, i32 %t480)
  %t482 = load i8*, i8** %t189
  %t483 = icmp eq i8* %t482, null
  br i1 %t483, label %table_read_null_88, label %table_read_real_89
table_read_null_88:
  br label %table_read_end_90
table_read_real_89:
  %t484 = bitcast i8* %t482 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t485 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t484, i32 0, i32 0
  %t486 = load i64, i64* %t485
  %t487 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t484, i32 0, i32 2
  %t488 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t487
  %t489 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t484, i32 0, i32 3
  %t490 = load i32*, i32** %t489
  br label %table_read_end_90
table_read_end_90:
  %t491 = phi i64 [ 0, %table_read_null_88 ], [ %t486, %table_read_real_89 ]
  %t492 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_88 ], [ %t488, %table_read_real_89 ]
  %t493 = phi i32* [ null, %table_read_null_88 ], [ %t490, %table_read_real_89 ]
  %t494 = sext i32 0 to i64
  %t495 = alloca %Bag
  %t496 = icmp ult i64 %t494, %t491
  br i1 %t496, label %table_idx_ok_91, label %table_idx_oob_92
table_idx_ok_91:
  %t497 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t492, i64 %t494
  %t498 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t497, i32 0, i32 0
  %t499 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t498, i32 0, i64 0
  %t500 = load i8*, i8** %t499
  call void @star_rc_retain(i8* %t500)
  %t501 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t498, i32 0, i64 1
  %t502 = load i8*, i8** %t501
  call void @star_rc_retain(i8* %t502)
  %t503 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t497
  %t504 = getelementptr inbounds %Bag, %Bag* %t495, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t503, { [2 x i8*], i64, i64 }* %t504
  %t505 = getelementptr inbounds i32, i32* %t493, i64 %t494
  %t506 = load i32, i32* %t505
  %t507 = getelementptr inbounds %Bag, %Bag* %t495, i32 0, i32 1
  store i32 %t506, i32* %t507
  br label %table_idx_end_93
table_idx_oob_92:
  store %Bag zeroinitializer, %Bag* %t495
  br label %table_idx_end_93
table_idx_end_93:
  %t508 = load %Bag, %Bag* %t495
  %t509 = alloca %Bag
  store %Bag %t508, %Bag* %t509
  %t510 = getelementptr inbounds %Bag, %Bag* %t509, i32 0, i32 1
  %t511 = load i32, i32* %t510
  %t512 = load i8*, i8** %t189
  %t513 = icmp eq i8* %t512, null
  br i1 %t513, label %table_read_null_94, label %table_read_real_95
table_read_null_94:
  br label %table_read_end_96
table_read_real_95:
  %t514 = bitcast i8* %t512 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t515 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t514, i32 0, i32 0
  %t516 = load i64, i64* %t515
  %t517 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t514, i32 0, i32 2
  %t518 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t517
  %t519 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t514, i32 0, i32 3
  %t520 = load i32*, i32** %t519
  br label %table_read_end_96
table_read_end_96:
  %t521 = phi i64 [ 0, %table_read_null_94 ], [ %t516, %table_read_real_95 ]
  %t522 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_94 ], [ %t518, %table_read_real_95 ]
  %t523 = phi i32* [ null, %table_read_null_94 ], [ %t520, %table_read_real_95 ]
  %t524 = sext i32 0 to i64
  %t525 = alloca %Bag
  %t526 = icmp ult i64 %t524, %t521
  br i1 %t526, label %table_idx_ok_97, label %table_idx_oob_98
table_idx_ok_97:
  %t527 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t522, i64 %t524
  %t528 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t527, i32 0, i32 0
  %t529 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t528, i32 0, i64 0
  %t530 = load i8*, i8** %t529
  call void @star_rc_retain(i8* %t530)
  %t531 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t528, i32 0, i64 1
  %t532 = load i8*, i8** %t531
  call void @star_rc_retain(i8* %t532)
  %t533 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t527
  %t534 = getelementptr inbounds %Bag, %Bag* %t525, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t533, { [2 x i8*], i64, i64 }* %t534
  %t535 = getelementptr inbounds i32, i32* %t523, i64 %t524
  %t536 = load i32, i32* %t535
  %t537 = getelementptr inbounds %Bag, %Bag* %t525, i32 0, i32 1
  store i32 %t536, i32* %t537
  br label %table_idx_end_99
table_idx_oob_98:
  store %Bag zeroinitializer, %Bag* %t525
  br label %table_idx_end_99
table_idx_end_99:
  %t538 = load %Bag, %Bag* %t525
  %t539 = alloca %Bag
  store %Bag %t538, %Bag* %t539
  %t540 = getelementptr inbounds %Bag, %Bag* %t539, i32 0, i32 0
  %t541 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t540, i32 0, i32 0
  %t542 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t540, i32 0, i32 1
  %t543 = load i64, i64* %t542
  %t544 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t540, i32 0, i32 2
  %t545 = load i64, i64* %t544
  %t546 = trunc i64 %t545 to i32
  %t547 = load i8*, i8** %t189
  %t548 = icmp eq i8* %t547, null
  br i1 %t548, label %table_read_null_100, label %table_read_real_101
table_read_null_100:
  br label %table_read_end_102
table_read_real_101:
  %t549 = bitcast i8* %t547 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t550 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t549, i32 0, i32 0
  %t551 = load i64, i64* %t550
  %t552 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t549, i32 0, i32 2
  %t553 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t552
  %t554 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t549, i32 0, i32 3
  %t555 = load i32*, i32** %t554
  br label %table_read_end_102
table_read_end_102:
  %t556 = phi i64 [ 0, %table_read_null_100 ], [ %t551, %table_read_real_101 ]
  %t557 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_100 ], [ %t553, %table_read_real_101 ]
  %t558 = phi i32* [ null, %table_read_null_100 ], [ %t555, %table_read_real_101 ]
  %t559 = sext i32 0 to i64
  %t560 = alloca %Bag
  %t561 = icmp ult i64 %t559, %t556
  br i1 %t561, label %table_idx_ok_103, label %table_idx_oob_104
table_idx_ok_103:
  %t562 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t557, i64 %t559
  %t563 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t562, i32 0, i32 0
  %t564 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t563, i32 0, i64 0
  %t565 = load i8*, i8** %t564
  call void @star_rc_retain(i8* %t565)
  %t566 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t563, i32 0, i64 1
  %t567 = load i8*, i8** %t566
  call void @star_rc_retain(i8* %t567)
  %t568 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t562
  %t569 = getelementptr inbounds %Bag, %Bag* %t560, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t568, { [2 x i8*], i64, i64 }* %t569
  %t570 = getelementptr inbounds i32, i32* %t558, i64 %t559
  %t571 = load i32, i32* %t570
  %t572 = getelementptr inbounds %Bag, %Bag* %t560, i32 0, i32 1
  store i32 %t571, i32* %t572
  br label %table_idx_end_105
table_idx_oob_104:
  store %Bag zeroinitializer, %Bag* %t560
  br label %table_idx_end_105
table_idx_end_105:
  %t573 = load %Bag, %Bag* %t560
  %t574 = alloca %Bag
  store %Bag %t573, %Bag* %t574
  %t575 = getelementptr inbounds %Bag, %Bag* %t574, i32 0, i32 0
  %t576 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t575, i32 0, i32 0
  %t577 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t575, i32 0, i32 1
  %t578 = load i64, i64* %t577
  %t579 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t575, i32 0, i32 2
  %t580 = load i64, i64* %t579
  %t581 = sext i32 0 to i64
  %t582 = icmp ult i64 %t581, %t580
  br i1 %t582, label %ring_rplace_ok_106, label %ring_rplace_oob_107
ring_rplace_ok_106:
  %t583 = add i64 %t578, %t581
  %t584 = urem i64 %t583, 2
  %t585 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t576, i32 0, i64 %t584
  br label %ring_rplace_end_108
ring_rplace_oob_107:
  %t586 = alloca i8*
  store i8* null, i8** %t586
  br label %ring_rplace_end_108
ring_rplace_end_108:
  %t587 = phi i8** [ %t585, %ring_rplace_ok_106 ], [ %t586, %ring_rplace_oob_107 ]
  %t588 = load i8*, i8** %t587
  %t589 = load i8*, i8** %t587
  call void @star_rc_retain(i8* %t589)
  %t590 = load i8*, i8** %t189
  %t591 = icmp eq i8* %t590, null
  br i1 %t591, label %table_read_null_109, label %table_read_real_110
table_read_null_109:
  br label %table_read_end_111
table_read_real_110:
  %t592 = bitcast i8* %t590 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t593 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t592, i32 0, i32 0
  %t594 = load i64, i64* %t593
  %t595 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t592, i32 0, i32 2
  %t596 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t595
  %t597 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t592, i32 0, i32 3
  %t598 = load i32*, i32** %t597
  br label %table_read_end_111
table_read_end_111:
  %t599 = phi i64 [ 0, %table_read_null_109 ], [ %t594, %table_read_real_110 ]
  %t600 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_109 ], [ %t596, %table_read_real_110 ]
  %t601 = phi i32* [ null, %table_read_null_109 ], [ %t598, %table_read_real_110 ]
  %t602 = sext i32 0 to i64
  %t603 = alloca %Bag
  %t604 = icmp ult i64 %t602, %t599
  br i1 %t604, label %table_idx_ok_112, label %table_idx_oob_113
table_idx_ok_112:
  %t605 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t600, i64 %t602
  %t606 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t605, i32 0, i32 0
  %t607 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t606, i32 0, i64 0
  %t608 = load i8*, i8** %t607
  call void @star_rc_retain(i8* %t608)
  %t609 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t606, i32 0, i64 1
  %t610 = load i8*, i8** %t609
  call void @star_rc_retain(i8* %t610)
  %t611 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t605
  %t612 = getelementptr inbounds %Bag, %Bag* %t603, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t611, { [2 x i8*], i64, i64 }* %t612
  %t613 = getelementptr inbounds i32, i32* %t601, i64 %t602
  %t614 = load i32, i32* %t613
  %t615 = getelementptr inbounds %Bag, %Bag* %t603, i32 0, i32 1
  store i32 %t614, i32* %t615
  br label %table_idx_end_114
table_idx_oob_113:
  store %Bag zeroinitializer, %Bag* %t603
  br label %table_idx_end_114
table_idx_end_114:
  %t616 = load %Bag, %Bag* %t603
  %t617 = alloca %Bag
  store %Bag %t616, %Bag* %t617
  %t618 = getelementptr inbounds %Bag, %Bag* %t617, i32 0, i32 0
  %t619 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t618, i32 0, i32 0
  %t620 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t618, i32 0, i32 1
  %t621 = load i64, i64* %t620
  %t622 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t618, i32 0, i32 2
  %t623 = load i64, i64* %t622
  %t624 = sext i32 1 to i64
  %t625 = icmp ult i64 %t624, %t623
  br i1 %t625, label %ring_rplace_ok_115, label %ring_rplace_oob_116
ring_rplace_ok_115:
  %t626 = add i64 %t621, %t624
  %t627 = urem i64 %t626, 2
  %t628 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t619, i32 0, i64 %t627
  br label %ring_rplace_end_117
ring_rplace_oob_116:
  %t629 = alloca i8*
  store i8* null, i8** %t629
  br label %ring_rplace_end_117
ring_rplace_end_117:
  %t630 = phi i8** [ %t628, %ring_rplace_ok_115 ], [ %t629, %ring_rplace_oob_116 ]
  %t631 = load i8*, i8** %t630
  %t632 = load i8*, i8** %t630
  call void @star_rc_retain(i8* %t632)
  %t633 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t633, i32 %t511, i32 %t546, i8* %t588, i8* %t631)
  %t634 = load i8*, i8** %t189
  %t635 = icmp eq i8* %t634, null
  br i1 %t635, label %table_read_null_118, label %table_read_real_119
table_read_null_118:
  br label %table_read_end_120
table_read_real_119:
  %t636 = bitcast i8* %t634 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t637 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t636, i32 0, i32 0
  %t638 = load i64, i64* %t637
  %t639 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t636, i32 0, i32 2
  %t640 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t639
  %t641 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t636, i32 0, i32 3
  %t642 = load i32*, i32** %t641
  br label %table_read_end_120
table_read_end_120:
  %t643 = phi i64 [ 0, %table_read_null_118 ], [ %t638, %table_read_real_119 ]
  %t644 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_118 ], [ %t640, %table_read_real_119 ]
  %t645 = phi i32* [ null, %table_read_null_118 ], [ %t642, %table_read_real_119 ]
  %t646 = sext i32 1 to i64
  %t647 = alloca %Bag
  %t648 = icmp ult i64 %t646, %t643
  br i1 %t648, label %table_idx_ok_121, label %table_idx_oob_122
table_idx_ok_121:
  %t649 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t644, i64 %t646
  %t650 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t649, i32 0, i32 0
  %t651 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t650, i32 0, i64 0
  %t652 = load i8*, i8** %t651
  call void @star_rc_retain(i8* %t652)
  %t653 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t650, i32 0, i64 1
  %t654 = load i8*, i8** %t653
  call void @star_rc_retain(i8* %t654)
  %t655 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t649
  %t656 = getelementptr inbounds %Bag, %Bag* %t647, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t655, { [2 x i8*], i64, i64 }* %t656
  %t657 = getelementptr inbounds i32, i32* %t645, i64 %t646
  %t658 = load i32, i32* %t657
  %t659 = getelementptr inbounds %Bag, %Bag* %t647, i32 0, i32 1
  store i32 %t658, i32* %t659
  br label %table_idx_end_123
table_idx_oob_122:
  store %Bag zeroinitializer, %Bag* %t647
  br label %table_idx_end_123
table_idx_end_123:
  %t660 = load %Bag, %Bag* %t647
  %t661 = alloca %Bag
  store %Bag %t660, %Bag* %t661
  %t662 = getelementptr inbounds %Bag, %Bag* %t661, i32 0, i32 1
  %t663 = load i32, i32* %t662
  %t664 = load i8*, i8** %t189
  %t665 = icmp eq i8* %t664, null
  br i1 %t665, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t666 = bitcast i8* %t664 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t667 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t666, i32 0, i32 0
  %t668 = load i64, i64* %t667
  %t669 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t666, i32 0, i32 2
  %t670 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t669
  %t671 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t666, i32 0, i32 3
  %t672 = load i32*, i32** %t671
  br label %table_read_end_126
table_read_end_126:
  %t673 = phi i64 [ 0, %table_read_null_124 ], [ %t668, %table_read_real_125 ]
  %t674 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_124 ], [ %t670, %table_read_real_125 ]
  %t675 = phi i32* [ null, %table_read_null_124 ], [ %t672, %table_read_real_125 ]
  %t676 = sext i32 1 to i64
  %t677 = alloca %Bag
  %t678 = icmp ult i64 %t676, %t673
  br i1 %t678, label %table_idx_ok_127, label %table_idx_oob_128
table_idx_ok_127:
  %t679 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t674, i64 %t676
  %t680 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t679, i32 0, i32 0
  %t681 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t680, i32 0, i64 0
  %t682 = load i8*, i8** %t681
  call void @star_rc_retain(i8* %t682)
  %t683 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t680, i32 0, i64 1
  %t684 = load i8*, i8** %t683
  call void @star_rc_retain(i8* %t684)
  %t685 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t679
  %t686 = getelementptr inbounds %Bag, %Bag* %t677, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t685, { [2 x i8*], i64, i64 }* %t686
  %t687 = getelementptr inbounds i32, i32* %t675, i64 %t676
  %t688 = load i32, i32* %t687
  %t689 = getelementptr inbounds %Bag, %Bag* %t677, i32 0, i32 1
  store i32 %t688, i32* %t689
  br label %table_idx_end_129
table_idx_oob_128:
  store %Bag zeroinitializer, %Bag* %t677
  br label %table_idx_end_129
table_idx_end_129:
  %t690 = load %Bag, %Bag* %t677
  %t691 = alloca %Bag
  store %Bag %t690, %Bag* %t691
  %t692 = getelementptr inbounds %Bag, %Bag* %t691, i32 0, i32 0
  %t693 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t692, i32 0, i32 0
  %t694 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t692, i32 0, i32 1
  %t695 = load i64, i64* %t694
  %t696 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t692, i32 0, i32 2
  %t697 = load i64, i64* %t696
  %t698 = trunc i64 %t697 to i32
  %t699 = load i8*, i8** %t189
  %t700 = icmp eq i8* %t699, null
  br i1 %t700, label %table_read_null_130, label %table_read_real_131
table_read_null_130:
  br label %table_read_end_132
table_read_real_131:
  %t701 = bitcast i8* %t699 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t702 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t701, i32 0, i32 0
  %t703 = load i64, i64* %t702
  %t704 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t701, i32 0, i32 2
  %t705 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t704
  %t706 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t701, i32 0, i32 3
  %t707 = load i32*, i32** %t706
  br label %table_read_end_132
table_read_end_132:
  %t708 = phi i64 [ 0, %table_read_null_130 ], [ %t703, %table_read_real_131 ]
  %t709 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_130 ], [ %t705, %table_read_real_131 ]
  %t710 = phi i32* [ null, %table_read_null_130 ], [ %t707, %table_read_real_131 ]
  %t711 = sext i32 1 to i64
  %t712 = alloca %Bag
  %t713 = icmp ult i64 %t711, %t708
  br i1 %t713, label %table_idx_ok_133, label %table_idx_oob_134
table_idx_ok_133:
  %t714 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t709, i64 %t711
  %t715 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t714, i32 0, i32 0
  %t716 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t715, i32 0, i64 0
  %t717 = load i8*, i8** %t716
  call void @star_rc_retain(i8* %t717)
  %t718 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t715, i32 0, i64 1
  %t719 = load i8*, i8** %t718
  call void @star_rc_retain(i8* %t719)
  %t720 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t714
  %t721 = getelementptr inbounds %Bag, %Bag* %t712, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t720, { [2 x i8*], i64, i64 }* %t721
  %t722 = getelementptr inbounds i32, i32* %t710, i64 %t711
  %t723 = load i32, i32* %t722
  %t724 = getelementptr inbounds %Bag, %Bag* %t712, i32 0, i32 1
  store i32 %t723, i32* %t724
  br label %table_idx_end_135
table_idx_oob_134:
  store %Bag zeroinitializer, %Bag* %t712
  br label %table_idx_end_135
table_idx_end_135:
  %t725 = load %Bag, %Bag* %t712
  %t726 = alloca %Bag
  store %Bag %t725, %Bag* %t726
  %t727 = getelementptr inbounds %Bag, %Bag* %t726, i32 0, i32 0
  %t728 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t727, i32 0, i32 0
  %t729 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t727, i32 0, i32 1
  %t730 = load i64, i64* %t729
  %t731 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t727, i32 0, i32 2
  %t732 = load i64, i64* %t731
  %t733 = sext i32 0 to i64
  %t734 = icmp ult i64 %t733, %t732
  br i1 %t734, label %ring_rplace_ok_136, label %ring_rplace_oob_137
ring_rplace_ok_136:
  %t735 = add i64 %t730, %t733
  %t736 = urem i64 %t735, 2
  %t737 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t728, i32 0, i64 %t736
  br label %ring_rplace_end_138
ring_rplace_oob_137:
  %t738 = alloca i8*
  store i8* null, i8** %t738
  br label %ring_rplace_end_138
ring_rplace_end_138:
  %t739 = phi i8** [ %t737, %ring_rplace_ok_136 ], [ %t738, %ring_rplace_oob_137 ]
  %t740 = load i8*, i8** %t739
  %t741 = load i8*, i8** %t739
  call void @star_rc_retain(i8* %t741)
  %t742 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t742, i32 %t663, i32 %t698, i8* %t740)
  %t743 = alloca i8*
  %t744 = load i8*, i8** %t189
  %t745 = load i8*, i8** %t189
  call void @star_rc_retain(i8* %t745)
  store i8* %t744, i8** %t743
  %t746 = load i8*, i8** %t189
  %t747 = icmp eq i8* %t746, null
  br i1 %t747, label %table_cow_alloc_139, label %table_cow_check_140
table_cow_alloc_139:
  %t748 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t749 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t750 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t749 to i64
  %t751 = call i8* @star_rc_alloc(i64 %t750, i8* %t748)
  %t752 = bitcast i8* %t751 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t753 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t752, i32 0, i32 0
  store i64 0, i64* %t753
  %t754 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t752, i32 0, i32 1
  store i64 0, i64* %t754
  %t755 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t752, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t755
  %t756 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t752, i32 0, i32 3
  store i32* null, i32** %t756
  store i8* %t751, i8** %t189
  br label %table_cow_done_141
table_cow_check_140:
  %t757 = getelementptr inbounds i8, i8* %t746, i64 -16
  %t758 = bitcast i8* %t757 to i64*
  %t759 = load atomic i64, i64* %t758 seq_cst, align 8
  %t760 = icmp eq i64 %t759, 1
  br i1 %t760, label %table_cow_done_141, label %table_cow_clone_142
table_cow_clone_142:
  %t761 = bitcast i8* %t746 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t762 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t761, i32 0, i32 0
  %t763 = load i64, i64* %t762
  %t764 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t761, i32 0, i32 1
  %t765 = load i64, i64* %t764
  %t766 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t767 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t768 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t767 to i64
  %t769 = call i8* @star_rc_alloc(i64 %t768, i8* %t766)
  %t770 = bitcast i8* %t769 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t771 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t770, i32 0, i32 0
  store i64 %t763, i64* %t771
  %t772 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t770, i32 0, i32 1
  store i64 %t765, i64* %t772
  %t773 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t774 = ptrtoint { [2 x i8*], i64, i64 }* %t773 to i64
  %t775 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t761, i32 0, i32 2
  %t776 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t775
  %t777 = mul i64 %t765, %t774
  %t778 = call i8* @malloc(i64 %t777)
  %t779 = bitcast i8* %t778 to { [2 x i8*], i64, i64 }*
  %t780 = icmp sgt i64 %t763, 0
  br i1 %t780, label %table_cow_copy_143, label %table_cow_after_copy_144
table_cow_copy_143:
  %t781 = mul i64 %t763, %t774
  %t782 = bitcast { [2 x i8*], i64, i64 }* %t776 to i8*
  call i8* @memcpy(i8* %t778, i8* %t782, i64 %t781)
  %t783 = alloca i64
  store i64 0, i64* %t783
  br label %table_cow_retain_cond_145
table_cow_retain_cond_145:
  %t784 = load i64, i64* %t783
  %t785 = icmp slt i64 %t784, %t763
  br i1 %t785, label %table_cow_retain_body_146, label %table_cow_retain_end_147
table_cow_retain_body_146:
  %t786 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t779, i64 %t784
  %t787 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t786, i32 0, i32 0
  %t788 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t787, i32 0, i64 0
  %t789 = load i8*, i8** %t788
  call void @star_rc_retain(i8* %t789)
  %t790 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t787, i32 0, i64 1
  %t791 = load i8*, i8** %t790
  call void @star_rc_retain(i8* %t791)
  %t792 = add i64 %t784, 1
  store i64 %t792, i64* %t783
  br label %table_cow_retain_cond_145
table_cow_retain_end_147:
  br label %table_cow_after_copy_144
table_cow_after_copy_144:
  %t793 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t770, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t779, { [2 x i8*], i64, i64 }** %t793
  %t794 = getelementptr i32, i32* null, i32 1
  %t795 = ptrtoint i32* %t794 to i64
  %t796 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t761, i32 0, i32 3
  %t797 = load i32*, i32** %t796
  %t798 = mul i64 %t765, %t795
  %t799 = call i8* @malloc(i64 %t798)
  %t800 = bitcast i8* %t799 to i32*
  %t801 = icmp sgt i64 %t763, 0
  br i1 %t801, label %table_cow_copy_148, label %table_cow_after_copy_149
table_cow_copy_148:
  %t802 = mul i64 %t763, %t795
  %t803 = bitcast i32* %t797 to i8*
  call i8* @memcpy(i8* %t799, i8* %t803, i64 %t802)
  br label %table_cow_after_copy_149
table_cow_after_copy_149:
  %t804 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t770, i32 0, i32 3
  store i32* %t800, i32** %t804
  call void @star_rc_release(i8* %t746)
  store i8* %t769, i8** %t189
  br label %table_cow_done_141
table_cow_done_141:
  %t805 = load i8*, i8** %t189
  %t806 = bitcast i8* %t805 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t807 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t806, i32 0, i32 0
  %t808 = load i64, i64* %t807
  %t809 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t806, i32 0, i32 1
  %t810 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t806, i32 0, i32 2
  %t811 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t810
  %t812 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t806, i32 0, i32 3
  %t813 = load i32*, i32** %t812
  %t814 = alloca %Bag
  %t815 = getelementptr inbounds %Bag, %Bag* %t814, i32 0, i32 0
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t815
  %t816 = getelementptr inbounds %Bag, %Bag* %t814, i32 0, i32 1
  store i32 3, i32* %t816
  %t817 = load %Bag, %Bag* %t814
  %t818 = load i64, i64* %t809
  %t819 = icmp sge i64 %t808, %t818
  br i1 %t819, label %table_push_grow_150, label %table_push_store_151
table_push_grow_150:
  %t820 = mul i64 %t818, 2
  %t821 = icmp sgt i64 %t820, 0
  %t822 = select i1 %t821, i64 %t820, i64 1
  %t823 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t824 = ptrtoint { [2 x i8*], i64, i64 }* %t823 to i64
  %t825 = mul i64 %t822, %t824
  %t826 = call i8* @malloc(i64 %t825)
  %t827 = bitcast i8* %t826 to { [2 x i8*], i64, i64 }*
  %t828 = icmp sgt i64 %t818, 0
  br i1 %t828, label %table_push_copy_152, label %table_push_after_copy_153
table_push_copy_152:
  %t829 = mul i64 %t808, %t824
  %t830 = bitcast { [2 x i8*], i64, i64 }* %t811 to i8*
  call i8* @memcpy(i8* %t826, i8* %t830, i64 %t829)
  call void @free(i8* %t830)
  br label %table_push_after_copy_153
table_push_after_copy_153:
  store { [2 x i8*], i64, i64 }* %t827, { [2 x i8*], i64, i64 }** %t810
  %t831 = getelementptr i32, i32* null, i32 1
  %t832 = ptrtoint i32* %t831 to i64
  %t833 = mul i64 %t822, %t832
  %t834 = call i8* @malloc(i64 %t833)
  %t835 = bitcast i8* %t834 to i32*
  %t836 = icmp sgt i64 %t818, 0
  br i1 %t836, label %table_push_copy_154, label %table_push_after_copy_155
table_push_copy_154:
  %t837 = mul i64 %t808, %t832
  %t838 = bitcast i32* %t813 to i8*
  call i8* @memcpy(i8* %t834, i8* %t838, i64 %t837)
  call void @free(i8* %t838)
  br label %table_push_after_copy_155
table_push_after_copy_155:
  store i32* %t835, i32** %t812
  store i64 %t822, i64* %t809
  br label %table_push_store_151
table_push_store_151:
  %t839 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t810
  %t840 = extractvalue %Bag %t817, 0
  %t841 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t839, i64 %t808
  store { [2 x i8*], i64, i64 } %t840, { [2 x i8*], i64, i64 }* %t841
  %t842 = load i32*, i32** %t812
  %t843 = extractvalue %Bag %t817, 1
  %t844 = getelementptr inbounds i32, i32* %t842, i64 %t808
  store i32 %t843, i32* %t844
  %t845 = add i64 %t808, 1
  store i64 %t845, i64* %t807
  %t846 = load i8*, i8** %t189
  %t847 = icmp eq i8* %t846, null
  br i1 %t847, label %table_read_null_156, label %table_read_real_157
table_read_null_156:
  br label %table_read_end_158
table_read_real_157:
  %t848 = bitcast i8* %t846 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t849 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t848, i32 0, i32 0
  %t850 = load i64, i64* %t849
  %t851 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t848, i32 0, i32 2
  %t852 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t851
  %t853 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t848, i32 0, i32 3
  %t854 = load i32*, i32** %t853
  br label %table_read_end_158
table_read_end_158:
  %t855 = phi i64 [ 0, %table_read_null_156 ], [ %t850, %table_read_real_157 ]
  %t856 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_156 ], [ %t852, %table_read_real_157 ]
  %t857 = phi i32* [ null, %table_read_null_156 ], [ %t854, %table_read_real_157 ]
  %t858 = trunc i64 %t855 to i32
  %t859 = load i8*, i8** %t743
  %t860 = icmp eq i8* %t859, null
  br i1 %t860, label %table_read_null_159, label %table_read_real_160
table_read_null_159:
  br label %table_read_end_161
table_read_real_160:
  %t861 = bitcast i8* %t859 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t862 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t861, i32 0, i32 0
  %t863 = load i64, i64* %t862
  %t864 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t861, i32 0, i32 2
  %t865 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t864
  %t866 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t861, i32 0, i32 3
  %t867 = load i32*, i32** %t866
  br label %table_read_end_161
table_read_end_161:
  %t868 = phi i64 [ 0, %table_read_null_159 ], [ %t863, %table_read_real_160 ]
  %t869 = phi { [2 x i8*], i64, i64 }* [ null, %table_read_null_159 ], [ %t865, %table_read_real_160 ]
  %t870 = phi i32* [ null, %table_read_null_159 ], [ %t867, %table_read_real_160 ]
  %t871 = trunc i64 %t868 to i32
  %t872 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t872, i32 %t858, i32 %t871)
  %t873 = alloca %Bag
  %t874 = load i8*, i8** %t189
  %t875 = icmp eq i8* %t874, null
  br i1 %t875, label %table_cow_alloc_162, label %table_cow_check_163
table_cow_alloc_162:
  %t876 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t877 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t878 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t877 to i64
  %t879 = call i8* @star_rc_alloc(i64 %t878, i8* %t876)
  %t880 = bitcast i8* %t879 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t881 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t880, i32 0, i32 0
  store i64 0, i64* %t881
  %t882 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t880, i32 0, i32 1
  store i64 0, i64* %t882
  %t883 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t880, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* null, { [2 x i8*], i64, i64 }** %t883
  %t884 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t880, i32 0, i32 3
  store i32* null, i32** %t884
  store i8* %t879, i8** %t189
  br label %table_cow_done_164
table_cow_check_163:
  %t885 = getelementptr inbounds i8, i8* %t874, i64 -16
  %t886 = bitcast i8* %t885 to i64*
  %t887 = load atomic i64, i64* %t886 seq_cst, align 8
  %t888 = icmp eq i64 %t887, 1
  br i1 %t888, label %table_cow_done_164, label %table_cow_clone_165
table_cow_clone_165:
  %t889 = bitcast i8* %t874 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t890 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t889, i32 0, i32 0
  %t891 = load i64, i64* %t890
  %t892 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t889, i32 0, i32 1
  %t893 = load i64, i64* %t892
  %t894 = bitcast void (i8*)* @table_release_s_Bag to i8*
  %t895 = getelementptr { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* null, i32 1
  %t896 = ptrtoint { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t895 to i64
  %t897 = call i8* @star_rc_alloc(i64 %t896, i8* %t894)
  %t898 = bitcast i8* %t897 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t899 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t898, i32 0, i32 0
  store i64 %t891, i64* %t899
  %t900 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t898, i32 0, i32 1
  store i64 %t893, i64* %t900
  %t901 = getelementptr { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* null, i32 1
  %t902 = ptrtoint { [2 x i8*], i64, i64 }* %t901 to i64
  %t903 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t889, i32 0, i32 2
  %t904 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t903
  %t905 = mul i64 %t893, %t902
  %t906 = call i8* @malloc(i64 %t905)
  %t907 = bitcast i8* %t906 to { [2 x i8*], i64, i64 }*
  %t908 = icmp sgt i64 %t891, 0
  br i1 %t908, label %table_cow_copy_166, label %table_cow_after_copy_167
table_cow_copy_166:
  %t909 = mul i64 %t891, %t902
  %t910 = bitcast { [2 x i8*], i64, i64 }* %t904 to i8*
  call i8* @memcpy(i8* %t906, i8* %t910, i64 %t909)
  %t911 = alloca i64
  store i64 0, i64* %t911
  br label %table_cow_retain_cond_168
table_cow_retain_cond_168:
  %t912 = load i64, i64* %t911
  %t913 = icmp slt i64 %t912, %t891
  br i1 %t913, label %table_cow_retain_body_169, label %table_cow_retain_end_170
table_cow_retain_body_169:
  %t914 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t907, i64 %t912
  %t915 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t914, i32 0, i32 0
  %t916 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t915, i32 0, i64 0
  %t917 = load i8*, i8** %t916
  call void @star_rc_retain(i8* %t917)
  %t918 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t915, i32 0, i64 1
  %t919 = load i8*, i8** %t918
  call void @star_rc_retain(i8* %t919)
  %t920 = add i64 %t912, 1
  store i64 %t920, i64* %t911
  br label %table_cow_retain_cond_168
table_cow_retain_end_170:
  br label %table_cow_after_copy_167
table_cow_after_copy_167:
  %t921 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t898, i32 0, i32 2
  store { [2 x i8*], i64, i64 }* %t907, { [2 x i8*], i64, i64 }** %t921
  %t922 = getelementptr i32, i32* null, i32 1
  %t923 = ptrtoint i32* %t922 to i64
  %t924 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t889, i32 0, i32 3
  %t925 = load i32*, i32** %t924
  %t926 = mul i64 %t893, %t923
  %t927 = call i8* @malloc(i64 %t926)
  %t928 = bitcast i8* %t927 to i32*
  %t929 = icmp sgt i64 %t891, 0
  br i1 %t929, label %table_cow_copy_171, label %table_cow_after_copy_172
table_cow_copy_171:
  %t930 = mul i64 %t891, %t923
  %t931 = bitcast i32* %t925 to i8*
  call i8* @memcpy(i8* %t927, i8* %t931, i64 %t930)
  br label %table_cow_after_copy_172
table_cow_after_copy_172:
  %t932 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t898, i32 0, i32 3
  store i32* %t928, i32** %t932
  call void @star_rc_release(i8* %t874)
  store i8* %t897, i8** %t189
  br label %table_cow_done_164
table_cow_done_164:
  %t933 = load i8*, i8** %t189
  %t934 = bitcast i8* %t933 to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t935 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t934, i32 0, i32 0
  %t936 = load i64, i64* %t935
  %t937 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t934, i32 0, i32 1
  %t938 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t934, i32 0, i32 2
  %t939 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t938
  %t940 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t934, i32 0, i32 3
  %t941 = load i32*, i32** %t940
  %t942 = alloca %Bag
  %t943 = icmp eq i64 %t936, 0
  br i1 %t943, label %table_pop_empty_173, label %table_pop_nonempty_174
table_pop_nonempty_174:
  %t944 = sub i64 %t936, 1
  store i64 %t944, i64* %t935
  %t945 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t939, i64 %t944
  %t946 = load { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t945
  %t947 = getelementptr inbounds %Bag, %Bag* %t942, i32 0, i32 0
  store { [2 x i8*], i64, i64 } %t946, { [2 x i8*], i64, i64 }* %t947
  %t948 = getelementptr inbounds i32, i32* %t941, i64 %t944
  %t949 = load i32, i32* %t948
  %t950 = getelementptr inbounds %Bag, %Bag* %t942, i32 0, i32 1
  store i32 %t949, i32* %t950
  br label %table_pop_end_175
table_pop_empty_173:
  store %Bag zeroinitializer, %Bag* %t942
  br label %table_pop_end_175
table_pop_end_175:
  %t951 = load %Bag, %Bag* %t942
  store %Bag %t951, %Bag* %t873
  %t952 = getelementptr inbounds %Bag, %Bag* %t873, i32 0, i32 1
  %t953 = load i32, i32* %t952
  %t954 = getelementptr inbounds %Bag, %Bag* %t873, i32 0, i32 0
  %t955 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t954, i32 0, i32 0
  %t956 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t954, i32 0, i32 1
  %t957 = load i64, i64* %t956
  %t958 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t954, i32 0, i32 2
  %t959 = load i64, i64* %t958
  %t960 = trunc i64 %t959 to i32
  %t961 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t961, i32 %t953, i32 %t960)
  %t962 = alloca { [2 x i8*], i64, i64 }
  store { [2 x i8*], i64, i64 } zeroinitializer, { [2 x i8*], i64, i64 }* %t962
  %t963 = alloca i8*
  store i8* null, i8** %t963
  %t964 = load i8*, i8** %t963
  %t965 = icmp eq i8* %t964, null
  br i1 %t965, label %table_cow_alloc_176, label %table_cow_check_177
table_cow_alloc_176:
  %t972 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t973 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t974 = ptrtoint { i64, i64, i32* }* %t973 to i64
  %t975 = call i8* @star_rc_alloc(i64 %t974, i8* %t972)
  %t976 = bitcast i8* %t975 to { i64, i64, i32* }*
  %t977 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t976, i32 0, i32 0
  store i64 0, i64* %t977
  %t978 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t976, i32 0, i32 1
  store i64 0, i64* %t978
  %t979 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t976, i32 0, i32 2
  store i32* null, i32** %t979
  store i8* %t975, i8** %t963
  br label %table_cow_done_178
table_cow_check_177:
  %t980 = getelementptr inbounds i8, i8* %t964, i64 -16
  %t981 = bitcast i8* %t980 to i64*
  %t982 = load atomic i64, i64* %t981 seq_cst, align 8
  %t983 = icmp eq i64 %t982, 1
  br i1 %t983, label %table_cow_done_178, label %table_cow_clone_179
table_cow_clone_179:
  %t984 = bitcast i8* %t964 to { i64, i64, i32* }*
  %t985 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t984, i32 0, i32 0
  %t986 = load i64, i64* %t985
  %t987 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t984, i32 0, i32 1
  %t988 = load i64, i64* %t987
  %t989 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t990 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t991 = ptrtoint { i64, i64, i32* }* %t990 to i64
  %t992 = call i8* @star_rc_alloc(i64 %t991, i8* %t989)
  %t993 = bitcast i8* %t992 to { i64, i64, i32* }*
  %t994 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t993, i32 0, i32 0
  store i64 %t986, i64* %t994
  %t995 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t993, i32 0, i32 1
  store i64 %t988, i64* %t995
  %t996 = getelementptr i32, i32* null, i32 1
  %t997 = ptrtoint i32* %t996 to i64
  %t998 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t984, i32 0, i32 2
  %t999 = load i32*, i32** %t998
  %t1000 = mul i64 %t988, %t997
  %t1001 = call i8* @malloc(i64 %t1000)
  %t1002 = bitcast i8* %t1001 to i32*
  %t1003 = icmp sgt i64 %t986, 0
  br i1 %t1003, label %table_cow_copy_180, label %table_cow_after_copy_181
table_cow_copy_180:
  %t1004 = mul i64 %t986, %t997
  %t1005 = bitcast i32* %t999 to i8*
  call i8* @memcpy(i8* %t1001, i8* %t1005, i64 %t1004)
  br label %table_cow_after_copy_181
table_cow_after_copy_181:
  %t1006 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t993, i32 0, i32 2
  store i32* %t1002, i32** %t1006
  call void @star_rc_release(i8* %t964)
  store i8* %t992, i8** %t963
  br label %table_cow_done_178
table_cow_done_178:
  %t1007 = load i8*, i8** %t963
  %t1008 = bitcast i8* %t1007 to { i64, i64, i32* }*
  %t1009 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1008, i32 0, i32 0
  %t1010 = load i64, i64* %t1009
  %t1011 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1008, i32 0, i32 1
  %t1012 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1008, i32 0, i32 2
  %t1013 = load i32*, i32** %t1012
  %t1014 = alloca %Item
  %t1015 = getelementptr inbounds %Item, %Item* %t1014, i32 0, i32 0
  store i32 1, i32* %t1015
  %t1016 = load %Item, %Item* %t1014
  %t1017 = load i64, i64* %t1011
  %t1018 = icmp sge i64 %t1010, %t1017
  br i1 %t1018, label %table_push_grow_182, label %table_push_store_183
table_push_grow_182:
  %t1019 = mul i64 %t1017, 2
  %t1020 = icmp sgt i64 %t1019, 0
  %t1021 = select i1 %t1020, i64 %t1019, i64 1
  %t1022 = getelementptr i32, i32* null, i32 1
  %t1023 = ptrtoint i32* %t1022 to i64
  %t1024 = mul i64 %t1021, %t1023
  %t1025 = call i8* @malloc(i64 %t1024)
  %t1026 = bitcast i8* %t1025 to i32*
  %t1027 = icmp sgt i64 %t1017, 0
  br i1 %t1027, label %table_push_copy_184, label %table_push_after_copy_185
table_push_copy_184:
  %t1028 = mul i64 %t1010, %t1023
  %t1029 = bitcast i32* %t1013 to i8*
  call i8* @memcpy(i8* %t1025, i8* %t1029, i64 %t1028)
  call void @free(i8* %t1029)
  br label %table_push_after_copy_185
table_push_after_copy_185:
  store i32* %t1026, i32** %t1012
  store i64 %t1021, i64* %t1011
  br label %table_push_store_183
table_push_store_183:
  %t1030 = load i32*, i32** %t1012
  %t1031 = extractvalue %Item %t1016, 0
  %t1032 = getelementptr inbounds i32, i32* %t1030, i64 %t1010
  store i32 %t1031, i32* %t1032
  %t1033 = add i64 %t1010, 1
  store i64 %t1033, i64* %t1009
  %t1034 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1035 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1036 = load i64, i64* %t1035
  %t1037 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1038 = load i64, i64* %t1037
  %t1039 = load i8*, i8** %t963
  %t1040 = load i8*, i8** %t963
  call void @star_rc_retain(i8* %t1040)
  %t1041 = icmp sge i64 %t1038, 2
  br i1 %t1041, label %ring_push_full_186, label %ring_push_grow_187
ring_push_grow_187:
  %t1042 = add i64 %t1036, %t1038
  %t1043 = urem i64 %t1042, 2
  %t1044 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1034, i32 0, i64 %t1043
  store i8* %t1039, i8** %t1044
  %t1045 = add i64 %t1038, 1
  store i64 %t1045, i64* %t1037
  br label %ring_push_done_188
ring_push_full_186:
  %t1046 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1034, i32 0, i64 %t1036
  %t1047 = load i8*, i8** %t1046
  call void @star_rc_release(i8* %t1047)
  store i8* %t1039, i8** %t1046
  %t1048 = add i64 %t1036, 1
  %t1049 = urem i64 %t1048, 2
  store i64 %t1049, i64* %t1035
  br label %ring_push_done_188
ring_push_done_188:
  %t1050 = alloca i8*
  store i8* null, i8** %t1050
  %t1051 = load i8*, i8** %t1050
  %t1052 = icmp eq i8* %t1051, null
  br i1 %t1052, label %table_cow_alloc_189, label %table_cow_check_190
table_cow_alloc_189:
  %t1053 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1054 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1055 = ptrtoint { i64, i64, i32* }* %t1054 to i64
  %t1056 = call i8* @star_rc_alloc(i64 %t1055, i8* %t1053)
  %t1057 = bitcast i8* %t1056 to { i64, i64, i32* }*
  %t1058 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1057, i32 0, i32 0
  store i64 0, i64* %t1058
  %t1059 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1057, i32 0, i32 1
  store i64 0, i64* %t1059
  %t1060 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1057, i32 0, i32 2
  store i32* null, i32** %t1060
  store i8* %t1056, i8** %t1050
  br label %table_cow_done_191
table_cow_check_190:
  %t1061 = getelementptr inbounds i8, i8* %t1051, i64 -16
  %t1062 = bitcast i8* %t1061 to i64*
  %t1063 = load atomic i64, i64* %t1062 seq_cst, align 8
  %t1064 = icmp eq i64 %t1063, 1
  br i1 %t1064, label %table_cow_done_191, label %table_cow_clone_192
table_cow_clone_192:
  %t1065 = bitcast i8* %t1051 to { i64, i64, i32* }*
  %t1066 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1065, i32 0, i32 0
  %t1067 = load i64, i64* %t1066
  %t1068 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1065, i32 0, i32 1
  %t1069 = load i64, i64* %t1068
  %t1070 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1071 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1072 = ptrtoint { i64, i64, i32* }* %t1071 to i64
  %t1073 = call i8* @star_rc_alloc(i64 %t1072, i8* %t1070)
  %t1074 = bitcast i8* %t1073 to { i64, i64, i32* }*
  %t1075 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1074, i32 0, i32 0
  store i64 %t1067, i64* %t1075
  %t1076 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1074, i32 0, i32 1
  store i64 %t1069, i64* %t1076
  %t1077 = getelementptr i32, i32* null, i32 1
  %t1078 = ptrtoint i32* %t1077 to i64
  %t1079 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1065, i32 0, i32 2
  %t1080 = load i32*, i32** %t1079
  %t1081 = mul i64 %t1069, %t1078
  %t1082 = call i8* @malloc(i64 %t1081)
  %t1083 = bitcast i8* %t1082 to i32*
  %t1084 = icmp sgt i64 %t1067, 0
  br i1 %t1084, label %table_cow_copy_193, label %table_cow_after_copy_194
table_cow_copy_193:
  %t1085 = mul i64 %t1067, %t1078
  %t1086 = bitcast i32* %t1080 to i8*
  call i8* @memcpy(i8* %t1082, i8* %t1086, i64 %t1085)
  br label %table_cow_after_copy_194
table_cow_after_copy_194:
  %t1087 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1074, i32 0, i32 2
  store i32* %t1083, i32** %t1087
  call void @star_rc_release(i8* %t1051)
  store i8* %t1073, i8** %t1050
  br label %table_cow_done_191
table_cow_done_191:
  %t1088 = load i8*, i8** %t1050
  %t1089 = bitcast i8* %t1088 to { i64, i64, i32* }*
  %t1090 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1089, i32 0, i32 0
  %t1091 = load i64, i64* %t1090
  %t1092 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1089, i32 0, i32 1
  %t1093 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1089, i32 0, i32 2
  %t1094 = load i32*, i32** %t1093
  %t1095 = alloca %Item
  %t1096 = getelementptr inbounds %Item, %Item* %t1095, i32 0, i32 0
  store i32 2, i32* %t1096
  %t1097 = load %Item, %Item* %t1095
  %t1098 = load i64, i64* %t1092
  %t1099 = icmp sge i64 %t1091, %t1098
  br i1 %t1099, label %table_push_grow_195, label %table_push_store_196
table_push_grow_195:
  %t1100 = mul i64 %t1098, 2
  %t1101 = icmp sgt i64 %t1100, 0
  %t1102 = select i1 %t1101, i64 %t1100, i64 1
  %t1103 = getelementptr i32, i32* null, i32 1
  %t1104 = ptrtoint i32* %t1103 to i64
  %t1105 = mul i64 %t1102, %t1104
  %t1106 = call i8* @malloc(i64 %t1105)
  %t1107 = bitcast i8* %t1106 to i32*
  %t1108 = icmp sgt i64 %t1098, 0
  br i1 %t1108, label %table_push_copy_197, label %table_push_after_copy_198
table_push_copy_197:
  %t1109 = mul i64 %t1091, %t1104
  %t1110 = bitcast i32* %t1094 to i8*
  call i8* @memcpy(i8* %t1106, i8* %t1110, i64 %t1109)
  call void @free(i8* %t1110)
  br label %table_push_after_copy_198
table_push_after_copy_198:
  store i32* %t1107, i32** %t1093
  store i64 %t1102, i64* %t1092
  br label %table_push_store_196
table_push_store_196:
  %t1111 = load i32*, i32** %t1093
  %t1112 = extractvalue %Item %t1097, 0
  %t1113 = getelementptr inbounds i32, i32* %t1111, i64 %t1091
  store i32 %t1112, i32* %t1113
  %t1114 = add i64 %t1091, 1
  store i64 %t1114, i64* %t1090
  %t1115 = load i8*, i8** %t1050
  %t1116 = icmp eq i8* %t1115, null
  br i1 %t1116, label %table_cow_alloc_199, label %table_cow_check_200
table_cow_alloc_199:
  %t1117 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1118 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1119 = ptrtoint { i64, i64, i32* }* %t1118 to i64
  %t1120 = call i8* @star_rc_alloc(i64 %t1119, i8* %t1117)
  %t1121 = bitcast i8* %t1120 to { i64, i64, i32* }*
  %t1122 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1121, i32 0, i32 0
  store i64 0, i64* %t1122
  %t1123 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1121, i32 0, i32 1
  store i64 0, i64* %t1123
  %t1124 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1121, i32 0, i32 2
  store i32* null, i32** %t1124
  store i8* %t1120, i8** %t1050
  br label %table_cow_done_201
table_cow_check_200:
  %t1125 = getelementptr inbounds i8, i8* %t1115, i64 -16
  %t1126 = bitcast i8* %t1125 to i64*
  %t1127 = load atomic i64, i64* %t1126 seq_cst, align 8
  %t1128 = icmp eq i64 %t1127, 1
  br i1 %t1128, label %table_cow_done_201, label %table_cow_clone_202
table_cow_clone_202:
  %t1129 = bitcast i8* %t1115 to { i64, i64, i32* }*
  %t1130 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1129, i32 0, i32 0
  %t1131 = load i64, i64* %t1130
  %t1132 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1129, i32 0, i32 1
  %t1133 = load i64, i64* %t1132
  %t1134 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1135 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1136 = ptrtoint { i64, i64, i32* }* %t1135 to i64
  %t1137 = call i8* @star_rc_alloc(i64 %t1136, i8* %t1134)
  %t1138 = bitcast i8* %t1137 to { i64, i64, i32* }*
  %t1139 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1138, i32 0, i32 0
  store i64 %t1131, i64* %t1139
  %t1140 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1138, i32 0, i32 1
  store i64 %t1133, i64* %t1140
  %t1141 = getelementptr i32, i32* null, i32 1
  %t1142 = ptrtoint i32* %t1141 to i64
  %t1143 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1129, i32 0, i32 2
  %t1144 = load i32*, i32** %t1143
  %t1145 = mul i64 %t1133, %t1142
  %t1146 = call i8* @malloc(i64 %t1145)
  %t1147 = bitcast i8* %t1146 to i32*
  %t1148 = icmp sgt i64 %t1131, 0
  br i1 %t1148, label %table_cow_copy_203, label %table_cow_after_copy_204
table_cow_copy_203:
  %t1149 = mul i64 %t1131, %t1142
  %t1150 = bitcast i32* %t1144 to i8*
  call i8* @memcpy(i8* %t1146, i8* %t1150, i64 %t1149)
  br label %table_cow_after_copy_204
table_cow_after_copy_204:
  %t1151 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1138, i32 0, i32 2
  store i32* %t1147, i32** %t1151
  call void @star_rc_release(i8* %t1115)
  store i8* %t1137, i8** %t1050
  br label %table_cow_done_201
table_cow_done_201:
  %t1152 = load i8*, i8** %t1050
  %t1153 = bitcast i8* %t1152 to { i64, i64, i32* }*
  %t1154 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1153, i32 0, i32 0
  %t1155 = load i64, i64* %t1154
  %t1156 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1153, i32 0, i32 1
  %t1157 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1153, i32 0, i32 2
  %t1158 = load i32*, i32** %t1157
  %t1159 = alloca %Item
  %t1160 = getelementptr inbounds %Item, %Item* %t1159, i32 0, i32 0
  store i32 3, i32* %t1160
  %t1161 = load %Item, %Item* %t1159
  %t1162 = load i64, i64* %t1156
  %t1163 = icmp sge i64 %t1155, %t1162
  br i1 %t1163, label %table_push_grow_205, label %table_push_store_206
table_push_grow_205:
  %t1164 = mul i64 %t1162, 2
  %t1165 = icmp sgt i64 %t1164, 0
  %t1166 = select i1 %t1165, i64 %t1164, i64 1
  %t1167 = getelementptr i32, i32* null, i32 1
  %t1168 = ptrtoint i32* %t1167 to i64
  %t1169 = mul i64 %t1166, %t1168
  %t1170 = call i8* @malloc(i64 %t1169)
  %t1171 = bitcast i8* %t1170 to i32*
  %t1172 = icmp sgt i64 %t1162, 0
  br i1 %t1172, label %table_push_copy_207, label %table_push_after_copy_208
table_push_copy_207:
  %t1173 = mul i64 %t1155, %t1168
  %t1174 = bitcast i32* %t1158 to i8*
  call i8* @memcpy(i8* %t1170, i8* %t1174, i64 %t1173)
  call void @free(i8* %t1174)
  br label %table_push_after_copy_208
table_push_after_copy_208:
  store i32* %t1171, i32** %t1157
  store i64 %t1166, i64* %t1156
  br label %table_push_store_206
table_push_store_206:
  %t1175 = load i32*, i32** %t1157
  %t1176 = extractvalue %Item %t1161, 0
  %t1177 = getelementptr inbounds i32, i32* %t1175, i64 %t1155
  store i32 %t1176, i32* %t1177
  %t1178 = add i64 %t1155, 1
  store i64 %t1178, i64* %t1154
  %t1179 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1180 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1181 = load i64, i64* %t1180
  %t1182 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1183 = load i64, i64* %t1182
  %t1184 = load i8*, i8** %t1050
  %t1185 = load i8*, i8** %t1050
  call void @star_rc_retain(i8* %t1185)
  %t1186 = icmp sge i64 %t1183, 2
  br i1 %t1186, label %ring_push_full_209, label %ring_push_grow_210
ring_push_grow_210:
  %t1187 = add i64 %t1181, %t1183
  %t1188 = urem i64 %t1187, 2
  %t1189 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1179, i32 0, i64 %t1188
  store i8* %t1184, i8** %t1189
  %t1190 = add i64 %t1183, 1
  store i64 %t1190, i64* %t1182
  br label %ring_push_done_211
ring_push_full_209:
  %t1191 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1179, i32 0, i64 %t1181
  %t1192 = load i8*, i8** %t1191
  call void @star_rc_release(i8* %t1192)
  store i8* %t1184, i8** %t1191
  %t1193 = add i64 %t1181, 1
  %t1194 = urem i64 %t1193, 2
  store i64 %t1194, i64* %t1180
  br label %ring_push_done_211
ring_push_done_211:
  %t1195 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1196 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1197 = load i64, i64* %t1196
  %t1198 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1199 = load i64, i64* %t1198
  %t1200 = trunc i64 %t1199 to i32
  %t1201 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1202 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1203 = load i64, i64* %t1202
  %t1204 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1205 = load i64, i64* %t1204
  %t1206 = sext i32 0 to i64
  %t1207 = icmp ult i64 %t1206, %t1205
  br i1 %t1207, label %ring_rplace_ok_212, label %ring_rplace_oob_213
ring_rplace_ok_212:
  %t1208 = add i64 %t1203, %t1206
  %t1209 = urem i64 %t1208, 2
  %t1210 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1201, i32 0, i64 %t1209
  br label %ring_rplace_end_214
ring_rplace_oob_213:
  %t1211 = alloca i8*
  store i8* null, i8** %t1211
  br label %ring_rplace_end_214
ring_rplace_end_214:
  %t1212 = phi i8** [ %t1210, %ring_rplace_ok_212 ], [ %t1211, %ring_rplace_oob_213 ]
  %t1213 = load i8*, i8** %t1212
  %t1214 = icmp eq i8* %t1213, null
  br i1 %t1214, label %table_read_null_215, label %table_read_real_216
table_read_null_215:
  br label %table_read_end_217
table_read_real_216:
  %t1215 = bitcast i8* %t1213 to { i64, i64, i32* }*
  %t1216 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1215, i32 0, i32 0
  %t1217 = load i64, i64* %t1216
  %t1218 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1215, i32 0, i32 2
  %t1219 = load i32*, i32** %t1218
  br label %table_read_end_217
table_read_end_217:
  %t1220 = phi i64 [ 0, %table_read_null_215 ], [ %t1217, %table_read_real_216 ]
  %t1221 = phi i32* [ null, %table_read_null_215 ], [ %t1219, %table_read_real_216 ]
  %t1222 = trunc i64 %t1220 to i32
  %t1223 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1224 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1225 = load i64, i64* %t1224
  %t1226 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1227 = load i64, i64* %t1226
  %t1228 = sext i32 0 to i64
  %t1229 = icmp ult i64 %t1228, %t1227
  br i1 %t1229, label %ring_rplace_ok_218, label %ring_rplace_oob_219
ring_rplace_ok_218:
  %t1230 = add i64 %t1225, %t1228
  %t1231 = urem i64 %t1230, 2
  %t1232 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1223, i32 0, i64 %t1231
  br label %ring_rplace_end_220
ring_rplace_oob_219:
  %t1233 = alloca i8*
  store i8* null, i8** %t1233
  br label %ring_rplace_end_220
ring_rplace_end_220:
  %t1234 = phi i8** [ %t1232, %ring_rplace_ok_218 ], [ %t1233, %ring_rplace_oob_219 ]
  %t1235 = load i8*, i8** %t1234
  %t1236 = icmp eq i8* %t1235, null
  br i1 %t1236, label %table_read_null_221, label %table_read_real_222
table_read_null_221:
  br label %table_read_end_223
table_read_real_222:
  %t1237 = bitcast i8* %t1235 to { i64, i64, i32* }*
  %t1238 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1237, i32 0, i32 0
  %t1239 = load i64, i64* %t1238
  %t1240 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1237, i32 0, i32 2
  %t1241 = load i32*, i32** %t1240
  br label %table_read_end_223
table_read_end_223:
  %t1242 = phi i64 [ 0, %table_read_null_221 ], [ %t1239, %table_read_real_222 ]
  %t1243 = phi i32* [ null, %table_read_null_221 ], [ %t1241, %table_read_real_222 ]
  %t1244 = sext i32 0 to i64
  %t1245 = alloca %Item
  %t1246 = icmp ult i64 %t1244, %t1242
  br i1 %t1246, label %table_idx_ok_224, label %table_idx_oob_225
table_idx_ok_224:
  %t1247 = getelementptr inbounds i32, i32* %t1243, i64 %t1244
  %t1248 = load i32, i32* %t1247
  %t1249 = getelementptr inbounds %Item, %Item* %t1245, i32 0, i32 0
  store i32 %t1248, i32* %t1249
  br label %table_idx_end_226
table_idx_oob_225:
  store %Item zeroinitializer, %Item* %t1245
  br label %table_idx_end_226
table_idx_end_226:
  %t1250 = load %Item, %Item* %t1245
  %t1251 = alloca %Item
  store %Item %t1250, %Item* %t1251
  %t1252 = getelementptr inbounds %Item, %Item* %t1251, i32 0, i32 0
  %t1253 = load i32, i32* %t1252
  %t1254 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1254, i32 %t1200, i32 %t1222, i32 %t1253)
  %t1255 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1256 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1257 = load i64, i64* %t1256
  %t1258 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1259 = load i64, i64* %t1258
  %t1260 = sext i32 1 to i64
  %t1261 = icmp ult i64 %t1260, %t1259
  br i1 %t1261, label %ring_rplace_ok_227, label %ring_rplace_oob_228
ring_rplace_ok_227:
  %t1262 = add i64 %t1257, %t1260
  %t1263 = urem i64 %t1262, 2
  %t1264 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1255, i32 0, i64 %t1263
  br label %ring_rplace_end_229
ring_rplace_oob_228:
  %t1265 = alloca i8*
  store i8* null, i8** %t1265
  br label %ring_rplace_end_229
ring_rplace_end_229:
  %t1266 = phi i8** [ %t1264, %ring_rplace_ok_227 ], [ %t1265, %ring_rplace_oob_228 ]
  %t1267 = load i8*, i8** %t1266
  %t1268 = icmp eq i8* %t1267, null
  br i1 %t1268, label %table_read_null_230, label %table_read_real_231
table_read_null_230:
  br label %table_read_end_232
table_read_real_231:
  %t1269 = bitcast i8* %t1267 to { i64, i64, i32* }*
  %t1270 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1269, i32 0, i32 0
  %t1271 = load i64, i64* %t1270
  %t1272 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1269, i32 0, i32 2
  %t1273 = load i32*, i32** %t1272
  br label %table_read_end_232
table_read_end_232:
  %t1274 = phi i64 [ 0, %table_read_null_230 ], [ %t1271, %table_read_real_231 ]
  %t1275 = phi i32* [ null, %table_read_null_230 ], [ %t1273, %table_read_real_231 ]
  %t1276 = trunc i64 %t1274 to i32
  %t1277 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1278 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1279 = load i64, i64* %t1278
  %t1280 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1281 = load i64, i64* %t1280
  %t1282 = sext i32 1 to i64
  %t1283 = icmp ult i64 %t1282, %t1281
  br i1 %t1283, label %ring_rplace_ok_233, label %ring_rplace_oob_234
ring_rplace_ok_233:
  %t1284 = add i64 %t1279, %t1282
  %t1285 = urem i64 %t1284, 2
  %t1286 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1277, i32 0, i64 %t1285
  br label %ring_rplace_end_235
ring_rplace_oob_234:
  %t1287 = alloca i8*
  store i8* null, i8** %t1287
  br label %ring_rplace_end_235
ring_rplace_end_235:
  %t1288 = phi i8** [ %t1286, %ring_rplace_ok_233 ], [ %t1287, %ring_rplace_oob_234 ]
  %t1289 = load i8*, i8** %t1288
  %t1290 = icmp eq i8* %t1289, null
  br i1 %t1290, label %table_read_null_236, label %table_read_real_237
table_read_null_236:
  br label %table_read_end_238
table_read_real_237:
  %t1291 = bitcast i8* %t1289 to { i64, i64, i32* }*
  %t1292 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1291, i32 0, i32 0
  %t1293 = load i64, i64* %t1292
  %t1294 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1291, i32 0, i32 2
  %t1295 = load i32*, i32** %t1294
  br label %table_read_end_238
table_read_end_238:
  %t1296 = phi i64 [ 0, %table_read_null_236 ], [ %t1293, %table_read_real_237 ]
  %t1297 = phi i32* [ null, %table_read_null_236 ], [ %t1295, %table_read_real_237 ]
  %t1298 = sext i32 0 to i64
  %t1299 = alloca %Item
  %t1300 = icmp ult i64 %t1298, %t1296
  br i1 %t1300, label %table_idx_ok_239, label %table_idx_oob_240
table_idx_ok_239:
  %t1301 = getelementptr inbounds i32, i32* %t1297, i64 %t1298
  %t1302 = load i32, i32* %t1301
  %t1303 = getelementptr inbounds %Item, %Item* %t1299, i32 0, i32 0
  store i32 %t1302, i32* %t1303
  br label %table_idx_end_241
table_idx_oob_240:
  store %Item zeroinitializer, %Item* %t1299
  br label %table_idx_end_241
table_idx_end_241:
  %t1304 = load %Item, %Item* %t1299
  %t1305 = alloca %Item
  store %Item %t1304, %Item* %t1305
  %t1306 = getelementptr inbounds %Item, %Item* %t1305, i32 0, i32 0
  %t1307 = load i32, i32* %t1306
  %t1308 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1309 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1310 = load i64, i64* %t1309
  %t1311 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1312 = load i64, i64* %t1311
  %t1313 = sext i32 1 to i64
  %t1314 = icmp ult i64 %t1313, %t1312
  br i1 %t1314, label %ring_rplace_ok_242, label %ring_rplace_oob_243
ring_rplace_ok_242:
  %t1315 = add i64 %t1310, %t1313
  %t1316 = urem i64 %t1315, 2
  %t1317 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1308, i32 0, i64 %t1316
  br label %ring_rplace_end_244
ring_rplace_oob_243:
  %t1318 = alloca i8*
  store i8* null, i8** %t1318
  br label %ring_rplace_end_244
ring_rplace_end_244:
  %t1319 = phi i8** [ %t1317, %ring_rplace_ok_242 ], [ %t1318, %ring_rplace_oob_243 ]
  %t1320 = load i8*, i8** %t1319
  %t1321 = icmp eq i8* %t1320, null
  br i1 %t1321, label %table_read_null_245, label %table_read_real_246
table_read_null_245:
  br label %table_read_end_247
table_read_real_246:
  %t1322 = bitcast i8* %t1320 to { i64, i64, i32* }*
  %t1323 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1322, i32 0, i32 0
  %t1324 = load i64, i64* %t1323
  %t1325 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1322, i32 0, i32 2
  %t1326 = load i32*, i32** %t1325
  br label %table_read_end_247
table_read_end_247:
  %t1327 = phi i64 [ 0, %table_read_null_245 ], [ %t1324, %table_read_real_246 ]
  %t1328 = phi i32* [ null, %table_read_null_245 ], [ %t1326, %table_read_real_246 ]
  %t1329 = sext i32 1 to i64
  %t1330 = alloca %Item
  %t1331 = icmp ult i64 %t1329, %t1327
  br i1 %t1331, label %table_idx_ok_248, label %table_idx_oob_249
table_idx_ok_248:
  %t1332 = getelementptr inbounds i32, i32* %t1328, i64 %t1329
  %t1333 = load i32, i32* %t1332
  %t1334 = getelementptr inbounds %Item, %Item* %t1330, i32 0, i32 0
  store i32 %t1333, i32* %t1334
  br label %table_idx_end_250
table_idx_oob_249:
  store %Item zeroinitializer, %Item* %t1330
  br label %table_idx_end_250
table_idx_end_250:
  %t1335 = load %Item, %Item* %t1330
  %t1336 = alloca %Item
  store %Item %t1335, %Item* %t1336
  %t1337 = getelementptr inbounds %Item, %Item* %t1336, i32 0, i32 0
  %t1338 = load i32, i32* %t1337
  %t1339 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1339, i32 %t1276, i32 %t1307, i32 %t1338)
  %t1340 = alloca i8*
  store i8* null, i8** %t1340
  %t1341 = load i8*, i8** %t1340
  %t1342 = icmp eq i8* %t1341, null
  br i1 %t1342, label %table_cow_alloc_251, label %table_cow_check_252
table_cow_alloc_251:
  %t1343 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1344 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1345 = ptrtoint { i64, i64, i32* }* %t1344 to i64
  %t1346 = call i8* @star_rc_alloc(i64 %t1345, i8* %t1343)
  %t1347 = bitcast i8* %t1346 to { i64, i64, i32* }*
  %t1348 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1347, i32 0, i32 0
  store i64 0, i64* %t1348
  %t1349 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1347, i32 0, i32 1
  store i64 0, i64* %t1349
  %t1350 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1347, i32 0, i32 2
  store i32* null, i32** %t1350
  store i8* %t1346, i8** %t1340
  br label %table_cow_done_253
table_cow_check_252:
  %t1351 = getelementptr inbounds i8, i8* %t1341, i64 -16
  %t1352 = bitcast i8* %t1351 to i64*
  %t1353 = load atomic i64, i64* %t1352 seq_cst, align 8
  %t1354 = icmp eq i64 %t1353, 1
  br i1 %t1354, label %table_cow_done_253, label %table_cow_clone_254
table_cow_clone_254:
  %t1355 = bitcast i8* %t1341 to { i64, i64, i32* }*
  %t1356 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1355, i32 0, i32 0
  %t1357 = load i64, i64* %t1356
  %t1358 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1355, i32 0, i32 1
  %t1359 = load i64, i64* %t1358
  %t1360 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t1361 = getelementptr { i64, i64, i32* }, { i64, i64, i32* }* null, i32 1
  %t1362 = ptrtoint { i64, i64, i32* }* %t1361 to i64
  %t1363 = call i8* @star_rc_alloc(i64 %t1362, i8* %t1360)
  %t1364 = bitcast i8* %t1363 to { i64, i64, i32* }*
  %t1365 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1364, i32 0, i32 0
  store i64 %t1357, i64* %t1365
  %t1366 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1364, i32 0, i32 1
  store i64 %t1359, i64* %t1366
  %t1367 = getelementptr i32, i32* null, i32 1
  %t1368 = ptrtoint i32* %t1367 to i64
  %t1369 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1355, i32 0, i32 2
  %t1370 = load i32*, i32** %t1369
  %t1371 = mul i64 %t1359, %t1368
  %t1372 = call i8* @malloc(i64 %t1371)
  %t1373 = bitcast i8* %t1372 to i32*
  %t1374 = icmp sgt i64 %t1357, 0
  br i1 %t1374, label %table_cow_copy_255, label %table_cow_after_copy_256
table_cow_copy_255:
  %t1375 = mul i64 %t1357, %t1368
  %t1376 = bitcast i32* %t1370 to i8*
  call i8* @memcpy(i8* %t1372, i8* %t1376, i64 %t1375)
  br label %table_cow_after_copy_256
table_cow_after_copy_256:
  %t1377 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1364, i32 0, i32 2
  store i32* %t1373, i32** %t1377
  call void @star_rc_release(i8* %t1341)
  store i8* %t1363, i8** %t1340
  br label %table_cow_done_253
table_cow_done_253:
  %t1378 = load i8*, i8** %t1340
  %t1379 = bitcast i8* %t1378 to { i64, i64, i32* }*
  %t1380 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1379, i32 0, i32 0
  %t1381 = load i64, i64* %t1380
  %t1382 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1379, i32 0, i32 1
  %t1383 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1379, i32 0, i32 2
  %t1384 = load i32*, i32** %t1383
  %t1385 = alloca %Item
  %t1386 = getelementptr inbounds %Item, %Item* %t1385, i32 0, i32 0
  store i32 9, i32* %t1386
  %t1387 = load %Item, %Item* %t1385
  %t1388 = load i64, i64* %t1382
  %t1389 = icmp sge i64 %t1381, %t1388
  br i1 %t1389, label %table_push_grow_257, label %table_push_store_258
table_push_grow_257:
  %t1390 = mul i64 %t1388, 2
  %t1391 = icmp sgt i64 %t1390, 0
  %t1392 = select i1 %t1391, i64 %t1390, i64 1
  %t1393 = getelementptr i32, i32* null, i32 1
  %t1394 = ptrtoint i32* %t1393 to i64
  %t1395 = mul i64 %t1392, %t1394
  %t1396 = call i8* @malloc(i64 %t1395)
  %t1397 = bitcast i8* %t1396 to i32*
  %t1398 = icmp sgt i64 %t1388, 0
  br i1 %t1398, label %table_push_copy_259, label %table_push_after_copy_260
table_push_copy_259:
  %t1399 = mul i64 %t1381, %t1394
  %t1400 = bitcast i32* %t1384 to i8*
  call i8* @memcpy(i8* %t1396, i8* %t1400, i64 %t1399)
  call void @free(i8* %t1400)
  br label %table_push_after_copy_260
table_push_after_copy_260:
  store i32* %t1397, i32** %t1383
  store i64 %t1392, i64* %t1382
  br label %table_push_store_258
table_push_store_258:
  %t1401 = load i32*, i32** %t1383
  %t1402 = extractvalue %Item %t1387, 0
  %t1403 = getelementptr inbounds i32, i32* %t1401, i64 %t1381
  store i32 %t1402, i32* %t1403
  %t1404 = add i64 %t1381, 1
  store i64 %t1404, i64* %t1380
  %t1405 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1406 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1407 = load i64, i64* %t1406
  %t1408 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1409 = load i64, i64* %t1408
  %t1410 = load i8*, i8** %t1340
  %t1411 = load i8*, i8** %t1340
  call void @star_rc_retain(i8* %t1411)
  %t1412 = icmp sge i64 %t1409, 2
  br i1 %t1412, label %ring_push_full_261, label %ring_push_grow_262
ring_push_grow_262:
  %t1413 = add i64 %t1407, %t1409
  %t1414 = urem i64 %t1413, 2
  %t1415 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1405, i32 0, i64 %t1414
  store i8* %t1410, i8** %t1415
  %t1416 = add i64 %t1409, 1
  store i64 %t1416, i64* %t1408
  br label %ring_push_done_263
ring_push_full_261:
  %t1417 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1405, i32 0, i64 %t1407
  %t1418 = load i8*, i8** %t1417
  call void @star_rc_release(i8* %t1418)
  store i8* %t1410, i8** %t1417
  %t1419 = add i64 %t1407, 1
  %t1420 = urem i64 %t1419, 2
  store i64 %t1420, i64* %t1406
  br label %ring_push_done_263
ring_push_done_263:
  %t1421 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1422 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1423 = load i64, i64* %t1422
  %t1424 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1425 = load i64, i64* %t1424
  %t1426 = trunc i64 %t1425 to i32
  %t1427 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1428 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1429 = load i64, i64* %t1428
  %t1430 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1431 = load i64, i64* %t1430
  %t1432 = sext i32 0 to i64
  %t1433 = icmp ult i64 %t1432, %t1431
  br i1 %t1433, label %ring_rplace_ok_264, label %ring_rplace_oob_265
ring_rplace_ok_264:
  %t1434 = add i64 %t1429, %t1432
  %t1435 = urem i64 %t1434, 2
  %t1436 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1427, i32 0, i64 %t1435
  br label %ring_rplace_end_266
ring_rplace_oob_265:
  %t1437 = alloca i8*
  store i8* null, i8** %t1437
  br label %ring_rplace_end_266
ring_rplace_end_266:
  %t1438 = phi i8** [ %t1436, %ring_rplace_ok_264 ], [ %t1437, %ring_rplace_oob_265 ]
  %t1439 = load i8*, i8** %t1438
  %t1440 = icmp eq i8* %t1439, null
  br i1 %t1440, label %table_read_null_267, label %table_read_real_268
table_read_null_267:
  br label %table_read_end_269
table_read_real_268:
  %t1441 = bitcast i8* %t1439 to { i64, i64, i32* }*
  %t1442 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1441, i32 0, i32 0
  %t1443 = load i64, i64* %t1442
  %t1444 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1441, i32 0, i32 2
  %t1445 = load i32*, i32** %t1444
  br label %table_read_end_269
table_read_end_269:
  %t1446 = phi i64 [ 0, %table_read_null_267 ], [ %t1443, %table_read_real_268 ]
  %t1447 = phi i32* [ null, %table_read_null_267 ], [ %t1445, %table_read_real_268 ]
  %t1448 = trunc i64 %t1446 to i32
  %t1449 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1450 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 1
  %t1451 = load i64, i64* %t1450
  %t1452 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 2
  %t1453 = load i64, i64* %t1452
  %t1454 = sext i32 0 to i64
  %t1455 = icmp ult i64 %t1454, %t1453
  br i1 %t1455, label %ring_rplace_ok_270, label %ring_rplace_oob_271
ring_rplace_ok_270:
  %t1456 = add i64 %t1451, %t1454
  %t1457 = urem i64 %t1456, 2
  %t1458 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1449, i32 0, i64 %t1457
  br label %ring_rplace_end_272
ring_rplace_oob_271:
  %t1459 = alloca i8*
  store i8* null, i8** %t1459
  br label %ring_rplace_end_272
ring_rplace_end_272:
  %t1460 = phi i8** [ %t1458, %ring_rplace_ok_270 ], [ %t1459, %ring_rplace_oob_271 ]
  %t1461 = load i8*, i8** %t1460
  %t1462 = icmp eq i8* %t1461, null
  br i1 %t1462, label %table_read_null_273, label %table_read_real_274
table_read_null_273:
  br label %table_read_end_275
table_read_real_274:
  %t1463 = bitcast i8* %t1461 to { i64, i64, i32* }*
  %t1464 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1463, i32 0, i32 0
  %t1465 = load i64, i64* %t1464
  %t1466 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t1463, i32 0, i32 2
  %t1467 = load i32*, i32** %t1466
  br label %table_read_end_275
table_read_end_275:
  %t1468 = phi i64 [ 0, %table_read_null_273 ], [ %t1465, %table_read_real_274 ]
  %t1469 = phi i32* [ null, %table_read_null_273 ], [ %t1467, %table_read_real_274 ]
  %t1470 = sext i32 0 to i64
  %t1471 = alloca %Item
  %t1472 = icmp ult i64 %t1470, %t1468
  br i1 %t1472, label %table_idx_ok_276, label %table_idx_oob_277
table_idx_ok_276:
  %t1473 = getelementptr inbounds i32, i32* %t1469, i64 %t1470
  %t1474 = load i32, i32* %t1473
  %t1475 = getelementptr inbounds %Item, %Item* %t1471, i32 0, i32 0
  store i32 %t1474, i32* %t1475
  br label %table_idx_end_278
table_idx_oob_277:
  store %Item zeroinitializer, %Item* %t1471
  br label %table_idx_end_278
table_idx_end_278:
  %t1476 = load %Item, %Item* %t1471
  %t1477 = alloca %Item
  store %Item %t1476, %Item* %t1477
  %t1478 = getelementptr inbounds %Item, %Item* %t1477, i32 0, i32 0
  %t1479 = load i32, i32* %t1478
  %t1480 = getelementptr inbounds [45 x i8], [45 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1480, i32 %t1426, i32 %t1448, i32 %t1479)
  %t1481 = load i8*, i8** %t1340
  call void @star_rc_release(i8* %t1481)
  %t1482 = load i8*, i8** %t1050
  call void @star_rc_release(i8* %t1482)
  %t1483 = load i8*, i8** %t963
  call void @star_rc_release(i8* %t1483)
  %t1484 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t962, i32 0, i32 0
  %t1485 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1484, i32 0, i64 0
  %t1486 = load i8*, i8** %t1485
  call void @star_rc_release(i8* %t1486)
  %t1487 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1484, i32 0, i64 1
  %t1488 = load i8*, i8** %t1487
  call void @star_rc_release(i8* %t1488)
  %t1489 = getelementptr inbounds %Bag, %Bag* %t873, i32 0, i32 0
  %t1490 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t1489, i32 0, i32 0
  %t1491 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1490, i32 0, i64 0
  %t1492 = load i8*, i8** %t1491
  call void @star_rc_release(i8* %t1492)
  %t1493 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1490, i32 0, i64 1
  %t1494 = load i8*, i8** %t1493
  call void @star_rc_release(i8* %t1494)
  %t1495 = load i8*, i8** %t743
  call void @star_rc_release(i8* %t1495)
  %t1496 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t346, i32 0, i32 0
  %t1497 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1496, i32 0, i64 0
  %t1498 = load i8*, i8** %t1497
  call void @star_rc_release(i8* %t1498)
  %t1499 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1496, i32 0, i64 1
  %t1500 = load i8*, i8** %t1499
  call void @star_rc_release(i8* %t1500)
  %t1501 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t190, i32 0, i32 0
  %t1502 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1501, i32 0, i64 0
  %t1503 = load i8*, i8** %t1502
  call void @star_rc_release(i8* %t1503)
  %t1504 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t1501, i32 0, i64 1
  %t1505 = load i8*, i8** %t1504
  call void @star_rc_release(i8* %t1505)
  %t1506 = load i8*, i8** %t189
  call void @star_rc_release(i8* %t1506)
  %t1507 = getelementptr inbounds %Snapshot, %Snapshot* %t79, i32 0, i32 2
  %t1508 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1507, i32 0, i32 0
  %t1509 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1508, i32 0, i64 0
  %t1510 = getelementptr inbounds %Player, %Player* %t1509, i32 0, i32 0
  %t1511 = load i8*, i8** %t1510
  call void @star_rc_release(i8* %t1511)
  %t1512 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1508, i32 0, i64 1
  %t1513 = getelementptr inbounds %Player, %Player* %t1512, i32 0, i32 0
  %t1514 = load i8*, i8** %t1513
  call void @star_rc_release(i8* %t1514)
  %t1515 = getelementptr inbounds %Snapshot, %Snapshot* %t0, i32 0, i32 2
  %t1516 = getelementptr inbounds { [2 x %Player], i64, i64 }, { [2 x %Player], i64, i64 }* %t1515, i32 0, i32 0
  %t1517 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1516, i32 0, i64 0
  %t1518 = getelementptr inbounds %Player, %Player* %t1517, i32 0, i32 0
  %t1519 = load i8*, i8** %t1518
  call void @star_rc_release(i8* %t1519)
  %t1520 = getelementptr inbounds [2 x %Player], [2 x %Player]* %t1516, i32 0, i64 1
  %t1521 = getelementptr inbounds %Player, %Player* %t1520, i32 0, i32 0
  %t1522 = load i8*, i8** %t1521
  call void @star_rc_release(i8* %t1522)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Bag(i8* %objp) {
entry:
  %t223 = bitcast i8* %objp to { i64, i64, { [2 x i8*], i64, i64 }*, i32* }*
  %t224 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t223, i32 0, i32 0
  %t225 = load i64, i64* %t224
  %t226 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t223, i32 0, i32 2
  %t227 = load { [2 x i8*], i64, i64 }*, { [2 x i8*], i64, i64 }** %t226
  %t228 = alloca i64
  store i64 0, i64* %t228
  br label %table_release_cond_48
table_release_cond_48:
  %t229 = load i64, i64* %t228
  %t230 = icmp slt i64 %t229, %t225
  br i1 %t230, label %table_release_body_49, label %table_release_end_50
table_release_body_49:
  %t231 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t227, i64 %t229
  %t232 = getelementptr inbounds { [2 x i8*], i64, i64 }, { [2 x i8*], i64, i64 }* %t231, i32 0, i32 0
  %t233 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t232, i32 0, i64 0
  %t234 = load i8*, i8** %t233
  call void @star_rc_release(i8* %t234)
  %t235 = getelementptr inbounds [2 x i8*], [2 x i8*]* %t232, i32 0, i64 1
  %t236 = load i8*, i8** %t235
  call void @star_rc_release(i8* %t236)
  %t237 = add i64 %t229, 1
  store i64 %t237, i64* %t228
  br label %table_release_cond_48
table_release_end_50:
  %t238 = bitcast { [2 x i8*], i64, i64 }* %t227 to i8*
  call void @free(i8* %t238)
  %t239 = getelementptr inbounds { i64, i64, { [2 x i8*], i64, i64 }*, i32* }, { i64, i64, { [2 x i8*], i64, i64 }*, i32* }* %t223, i32 0, i32 3
  %t240 = load i32*, i32** %t239
  %t241 = bitcast i32* %t240 to i8*
  call void @free(i8* %t241)
  ret void
}


define void @table_release_s_Item(i8* %objp) {
entry:
  %t966 = bitcast i8* %objp to { i64, i64, i32* }*
  %t967 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t966, i32 0, i32 0
  %t968 = load i64, i64* %t967
  %t969 = getelementptr inbounds { i64, i64, i32* }, { i64, i64, i32* }* %t966, i32 0, i32 2
  %t970 = load i32*, i32** %t969
  %t971 = bitcast i32* %t970 to i8*
  call void @free(i8* %t971)
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

