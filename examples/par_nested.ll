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

%Enemy = type { i32 }
%Bullet = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i32] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

%Bullets = type { %Bullet*, i64 }
@arena.Bullets.data = global %Bullet* null
@arena.Bullets.count = global i64 0
@arena.Bullets.gen = global [1024 x i32] zeroinitializer
@arena.Bullets.free = global [1024 x i64] zeroinitializer
@arena.Bullets.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t18 = alloca %Enemy
  %t43 = alloca %Enemy
  %t68 = alloca %Enemy
  %t93 = alloca %Bullet
  %t118 = alloca %Bullet
  %t143 = alloca %Bullet
  %t168 = alloca %Bullet
  %t371 = alloca { i64, i64 }
  %t384 = alloca { i64, i64 }
  %t397 = alloca { i64, i64 }
  %t410 = alloca { i64, i64 }
  %t436 = alloca { i64, i64 }
  %t484 = alloca { i64, i64 }
  %t497 = alloca { i64, i64 }
  %t510 = alloca { i64, i64 }
  %t523 = alloca { i64, i64 }
  %t549 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t1 = icmp eq %Enemy* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = getelementptr %Enemy, %Enemy* null, i32 1
  %t3 = ptrtoint %Enemy* %t2 to i64
  %t4 = mul i64 %t3, 1024
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to %Enemy*
  store %Enemy* %t6, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t7 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t8 = load i64, i64* @arena.Enemies.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Enemies.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_4
spawn_grow_3:
  %t13 = load i64, i64* @arena.Enemies.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t15 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t15)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t16 = add i64 %t13, 1
  store i64 %t16, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t17 = phi i64 [ %t12, %spawn_reuse_2 ], [ %t13, %spawn_grow_ok_6 ]
  %t19 = getelementptr inbounds %Enemy, %Enemy* %t18, i32 0, i32 0
  store i32 10, i32* %t19
  %t20 = load %Enemy, %Enemy* %t18
  %t21 = getelementptr inbounds %Enemy, %Enemy* %t7, i64 %t17
  store %Enemy %t20, %Enemy* %t21
  %t22 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t17
  %t23 = load i32, i32* %t22
  %t24 = add i32 %t23, 1
  store i32 %t24, i32* %t22
  br label %spawn_end_5
spawn_end_5:
  %t25 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t26 = icmp eq %Enemy* %t25, null
  br i1 %t26, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t27 = getelementptr %Enemy, %Enemy* null, i32 1
  %t28 = ptrtoint %Enemy* %t27 to i64
  %t29 = mul i64 %t28, 1024
  %t30 = call i8* @malloc(i64 %t29)
  %t31 = bitcast i8* %t30 to %Enemy*
  store %Enemy* %t31, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t32 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t33 = load i64, i64* @arena.Enemies.free_top
  %t34 = icmp sgt i64 %t33, 0
  br i1 %t34, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t35 = sub i64 %t33, 1
  store i64 %t35, i64* @arena.Enemies.free_top
  %t36 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t35
  %t37 = load i64, i64* %t36
  br label %spawn_store_12
spawn_grow_11:
  %t38 = load i64, i64* @arena.Enemies.count
  %t39 = icmp slt i64 %t38, 1024
  br i1 %t39, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t40 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t40)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t41 = add i64 %t38, 1
  store i64 %t41, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t42 = phi i64 [ %t37, %spawn_reuse_10 ], [ %t38, %spawn_grow_ok_14 ]
  %t44 = getelementptr inbounds %Enemy, %Enemy* %t43, i32 0, i32 0
  store i32 10, i32* %t44
  %t45 = load %Enemy, %Enemy* %t43
  %t46 = getelementptr inbounds %Enemy, %Enemy* %t32, i64 %t42
  store %Enemy %t45, %Enemy* %t46
  %t47 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t42
  %t48 = load i32, i32* %t47
  %t49 = add i32 %t48, 1
  store i32 %t49, i32* %t47
  br label %spawn_end_13
spawn_end_13:
  %t50 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t51 = icmp eq %Enemy* %t50, null
  br i1 %t51, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t52 = getelementptr %Enemy, %Enemy* null, i32 1
  %t53 = ptrtoint %Enemy* %t52 to i64
  %t54 = mul i64 %t53, 1024
  %t55 = call i8* @malloc(i64 %t54)
  %t56 = bitcast i8* %t55 to %Enemy*
  store %Enemy* %t56, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t57 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t58 = load i64, i64* @arena.Enemies.free_top
  %t59 = icmp sgt i64 %t58, 0
  br i1 %t59, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t60 = sub i64 %t58, 1
  store i64 %t60, i64* @arena.Enemies.free_top
  %t61 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t60
  %t62 = load i64, i64* %t61
  br label %spawn_store_20
spawn_grow_19:
  %t63 = load i64, i64* @arena.Enemies.count
  %t64 = icmp slt i64 %t63, 1024
  br i1 %t64, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t65 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t65)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t66 = add i64 %t63, 1
  store i64 %t66, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t67 = phi i64 [ %t62, %spawn_reuse_18 ], [ %t63, %spawn_grow_ok_22 ]
  %t69 = getelementptr inbounds %Enemy, %Enemy* %t68, i32 0, i32 0
  store i32 10, i32* %t69
  %t70 = load %Enemy, %Enemy* %t68
  %t71 = getelementptr inbounds %Enemy, %Enemy* %t57, i64 %t67
  store %Enemy %t70, %Enemy* %t71
  %t72 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t67
  %t73 = load i32, i32* %t72
  %t74 = add i32 %t73, 1
  store i32 %t74, i32* %t72
  br label %spawn_end_21
spawn_end_21:
  %t75 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t76 = icmp eq %Bullet* %t75, null
  br i1 %t76, label %spawn_init_24, label %spawn_ready_25
spawn_init_24:
  %t77 = getelementptr %Bullet, %Bullet* null, i32 1
  %t78 = ptrtoint %Bullet* %t77 to i64
  %t79 = mul i64 %t78, 1024
  %t80 = call i8* @malloc(i64 %t79)
  %t81 = bitcast i8* %t80 to %Bullet*
  store %Bullet* %t81, %Bullet** @arena.Bullets.data
  br label %spawn_ready_25
spawn_ready_25:
  %t82 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t83 = load i64, i64* @arena.Bullets.free_top
  %t84 = icmp sgt i64 %t83, 0
  br i1 %t84, label %spawn_reuse_26, label %spawn_grow_27
spawn_reuse_26:
  %t85 = sub i64 %t83, 1
  store i64 %t85, i64* @arena.Bullets.free_top
  %t86 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t85
  %t87 = load i64, i64* %t86
  br label %spawn_store_28
spawn_grow_27:
  %t88 = load i64, i64* @arena.Bullets.count
  %t89 = icmp slt i64 %t88, 1024
  br i1 %t89, label %spawn_grow_ok_30, label %spawn_capacity_warn_31
spawn_capacity_warn_31:
  %t90 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t90)
  br label %spawn_end_29
spawn_grow_ok_30:
  %t91 = add i64 %t88, 1
  store i64 %t91, i64* @arena.Bullets.count
  br label %spawn_store_28
spawn_store_28:
  %t92 = phi i64 [ %t87, %spawn_reuse_26 ], [ %t88, %spawn_grow_ok_30 ]
  %t94 = getelementptr inbounds %Bullet, %Bullet* %t93, i32 0, i32 0
  store i32 0, i32* %t94
  %t95 = load %Bullet, %Bullet* %t93
  %t96 = getelementptr inbounds %Bullet, %Bullet* %t82, i64 %t92
  store %Bullet %t95, %Bullet* %t96
  %t97 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t92
  %t98 = load i32, i32* %t97
  %t99 = add i32 %t98, 1
  store i32 %t99, i32* %t97
  br label %spawn_end_29
spawn_end_29:
  %t100 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t101 = icmp eq %Bullet* %t100, null
  br i1 %t101, label %spawn_init_32, label %spawn_ready_33
spawn_init_32:
  %t102 = getelementptr %Bullet, %Bullet* null, i32 1
  %t103 = ptrtoint %Bullet* %t102 to i64
  %t104 = mul i64 %t103, 1024
  %t105 = call i8* @malloc(i64 %t104)
  %t106 = bitcast i8* %t105 to %Bullet*
  store %Bullet* %t106, %Bullet** @arena.Bullets.data
  br label %spawn_ready_33
spawn_ready_33:
  %t107 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t108 = load i64, i64* @arena.Bullets.free_top
  %t109 = icmp sgt i64 %t108, 0
  br i1 %t109, label %spawn_reuse_34, label %spawn_grow_35
spawn_reuse_34:
  %t110 = sub i64 %t108, 1
  store i64 %t110, i64* @arena.Bullets.free_top
  %t111 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t110
  %t112 = load i64, i64* %t111
  br label %spawn_store_36
spawn_grow_35:
  %t113 = load i64, i64* @arena.Bullets.count
  %t114 = icmp slt i64 %t113, 1024
  br i1 %t114, label %spawn_grow_ok_38, label %spawn_capacity_warn_39
spawn_capacity_warn_39:
  %t115 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t115)
  br label %spawn_end_37
spawn_grow_ok_38:
  %t116 = add i64 %t113, 1
  store i64 %t116, i64* @arena.Bullets.count
  br label %spawn_store_36
spawn_store_36:
  %t117 = phi i64 [ %t112, %spawn_reuse_34 ], [ %t113, %spawn_grow_ok_38 ]
  %t119 = getelementptr inbounds %Bullet, %Bullet* %t118, i32 0, i32 0
  store i32 0, i32* %t119
  %t120 = load %Bullet, %Bullet* %t118
  %t121 = getelementptr inbounds %Bullet, %Bullet* %t107, i64 %t117
  store %Bullet %t120, %Bullet* %t121
  %t122 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t117
  %t123 = load i32, i32* %t122
  %t124 = add i32 %t123, 1
  store i32 %t124, i32* %t122
  br label %spawn_end_37
spawn_end_37:
  %t125 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t126 = icmp eq %Bullet* %t125, null
  br i1 %t126, label %spawn_init_40, label %spawn_ready_41
spawn_init_40:
  %t127 = getelementptr %Bullet, %Bullet* null, i32 1
  %t128 = ptrtoint %Bullet* %t127 to i64
  %t129 = mul i64 %t128, 1024
  %t130 = call i8* @malloc(i64 %t129)
  %t131 = bitcast i8* %t130 to %Bullet*
  store %Bullet* %t131, %Bullet** @arena.Bullets.data
  br label %spawn_ready_41
spawn_ready_41:
  %t132 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t133 = load i64, i64* @arena.Bullets.free_top
  %t134 = icmp sgt i64 %t133, 0
  br i1 %t134, label %spawn_reuse_42, label %spawn_grow_43
spawn_reuse_42:
  %t135 = sub i64 %t133, 1
  store i64 %t135, i64* @arena.Bullets.free_top
  %t136 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t135
  %t137 = load i64, i64* %t136
  br label %spawn_store_44
spawn_grow_43:
  %t138 = load i64, i64* @arena.Bullets.count
  %t139 = icmp slt i64 %t138, 1024
  br i1 %t139, label %spawn_grow_ok_46, label %spawn_capacity_warn_47
spawn_capacity_warn_47:
  %t140 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t140)
  br label %spawn_end_45
spawn_grow_ok_46:
  %t141 = add i64 %t138, 1
  store i64 %t141, i64* @arena.Bullets.count
  br label %spawn_store_44
spawn_store_44:
  %t142 = phi i64 [ %t137, %spawn_reuse_42 ], [ %t138, %spawn_grow_ok_46 ]
  %t144 = getelementptr inbounds %Bullet, %Bullet* %t143, i32 0, i32 0
  store i32 0, i32* %t144
  %t145 = load %Bullet, %Bullet* %t143
  %t146 = getelementptr inbounds %Bullet, %Bullet* %t132, i64 %t142
  store %Bullet %t145, %Bullet* %t146
  %t147 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t142
  %t148 = load i32, i32* %t147
  %t149 = add i32 %t148, 1
  store i32 %t149, i32* %t147
  br label %spawn_end_45
spawn_end_45:
  %t150 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t151 = icmp eq %Bullet* %t150, null
  br i1 %t151, label %spawn_init_48, label %spawn_ready_49
spawn_init_48:
  %t152 = getelementptr %Bullet, %Bullet* null, i32 1
  %t153 = ptrtoint %Bullet* %t152 to i64
  %t154 = mul i64 %t153, 1024
  %t155 = call i8* @malloc(i64 %t154)
  %t156 = bitcast i8* %t155 to %Bullet*
  store %Bullet* %t156, %Bullet** @arena.Bullets.data
  br label %spawn_ready_49
spawn_ready_49:
  %t157 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t158 = load i64, i64* @arena.Bullets.free_top
  %t159 = icmp sgt i64 %t158, 0
  br i1 %t159, label %spawn_reuse_50, label %spawn_grow_51
spawn_reuse_50:
  %t160 = sub i64 %t158, 1
  store i64 %t160, i64* @arena.Bullets.free_top
  %t161 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t160
  %t162 = load i64, i64* %t161
  br label %spawn_store_52
spawn_grow_51:
  %t163 = load i64, i64* @arena.Bullets.count
  %t164 = icmp slt i64 %t163, 1024
  br i1 %t164, label %spawn_grow_ok_54, label %spawn_capacity_warn_55
spawn_capacity_warn_55:
  %t165 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t165)
  br label %spawn_end_53
spawn_grow_ok_54:
  %t166 = add i64 %t163, 1
  store i64 %t166, i64* @arena.Bullets.count
  br label %spawn_store_52
spawn_store_52:
  %t167 = phi i64 [ %t162, %spawn_reuse_50 ], [ %t163, %spawn_grow_ok_54 ]
  %t169 = getelementptr inbounds %Bullet, %Bullet* %t168, i32 0, i32 0
  store i32 0, i32* %t169
  %t170 = load %Bullet, %Bullet* %t168
  %t171 = getelementptr inbounds %Bullet, %Bullet* %t157, i64 %t167
  store %Bullet %t170, %Bullet* %t171
  %t172 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t167
  %t173 = load i32, i32* %t172
  %t174 = add i32 %t173, 1
  store i32 %t174, i32* %t172
  br label %spawn_end_53
spawn_end_53:
  call void @par.pool.ensure_init()
  %t348 = call i32 @GetCurrentThreadId()
  %t349 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t350 = load i32, i32* %t349
  %t351 = icmp eq i32 %t348, %t350
  %t352 = select i1 %t351, i32 0, i32 -1
  %t353 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t354 = load i32, i32* %t353
  %t355 = icmp eq i32 %t348, %t354
  %t356 = select i1 %t355, i32 1, i32 %t352
  %t357 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t358 = load i32, i32* %t357
  %t359 = icmp eq i32 %t348, %t358
  %t360 = select i1 %t359, i32 2, i32 %t356
  %t361 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t362 = load i32, i32* %t361
  %t363 = icmp eq i32 %t348, %t362
  %t364 = select i1 %t363, i32 3, i32 %t360
  %t365 = icmp sge i32 %t364, 0
  br i1 %t365, label %par_serial_75, label %par_pooled_74
par_pooled_74:
  %t366 = load i64, i64* @arena.Enemies.count
  %t367 = mul i64 %t366, 0
  %t368 = sdiv i64 %t367, 4
  %t369 = mul i64 %t366, 1
  %t370 = sdiv i64 %t369, 4
  %t372 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t371, i32 0, i32 0
  store i64 %t368, i64* %t372
  %t373 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t371, i32 0, i32 1
  store i64 %t370, i64* %t373
  %t374 = bitcast { i64, i64 }* %t371 to i8*
  %t375 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t374, i8** %t375
  %t376 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t376
  %t377 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t378 = load i8*, i8** %t377
  %t379 = call i32 @ReleaseSemaphore(i8* %t378, i32 1, i32* null)
  %t380 = mul i64 %t366, 1
  %t381 = sdiv i64 %t380, 4
  %t382 = mul i64 %t366, 2
  %t383 = sdiv i64 %t382, 4
  %t385 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t384, i32 0, i32 0
  store i64 %t381, i64* %t385
  %t386 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t384, i32 0, i32 1
  store i64 %t383, i64* %t386
  %t387 = bitcast { i64, i64 }* %t384 to i8*
  %t388 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t387, i8** %t388
  %t389 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t389
  %t390 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t391 = load i8*, i8** %t390
  %t392 = call i32 @ReleaseSemaphore(i8* %t391, i32 1, i32* null)
  %t393 = mul i64 %t366, 2
  %t394 = sdiv i64 %t393, 4
  %t395 = mul i64 %t366, 3
  %t396 = sdiv i64 %t395, 4
  %t398 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t397, i32 0, i32 0
  store i64 %t394, i64* %t398
  %t399 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t397, i32 0, i32 1
  store i64 %t396, i64* %t399
  %t400 = bitcast { i64, i64 }* %t397 to i8*
  %t401 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t400, i8** %t401
  %t402 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t402
  %t403 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t404 = load i8*, i8** %t403
  %t405 = call i32 @ReleaseSemaphore(i8* %t404, i32 1, i32* null)
  %t406 = mul i64 %t366, 3
  %t407 = sdiv i64 %t406, 4
  %t408 = mul i64 %t366, 4
  %t409 = sdiv i64 %t408, 4
  %t411 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t410, i32 0, i32 0
  store i64 %t407, i64* %t411
  %t412 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t410, i32 0, i32 1
  store i64 %t409, i64* %t412
  %t413 = bitcast { i64, i64 }* %t410 to i8*
  %t414 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t413, i8** %t414
  %t415 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t415
  %t416 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t417 = load i8*, i8** %t416
  %t418 = call i32 @ReleaseSemaphore(i8* %t417, i32 1, i32* null)
  %t419 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t420 = load i8*, i8** %t419
  %t421 = call i32 @WaitForSingleObject(i8* %t420, i32 -1)
  %t422 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t423 = load i8*, i8** %t422
  %t424 = call i32 @WaitForSingleObject(i8* %t423, i32 -1)
  %t425 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t426 = load i8*, i8** %t425
  %t427 = call i32 @WaitForSingleObject(i8* %t426, i32 -1)
  %t428 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t429 = load i8*, i8** %t428
  %t430 = call i32 @WaitForSingleObject(i8* %t429, i32 -1)
  br label %par_join_79
par_serial_75:
  %t431 = load i32, i32* @par.pool.serial_owner
  %t432 = icmp eq i32 %t431, %t364
  br i1 %t432, label %par_run_77, label %par_acquire_76
par_acquire_76:
  %t433 = load i8*, i8** @par.pool.serial_lock
  %t434 = call i32 @WaitForSingleObject(i8* %t433, i32 -1)
  store i32 %t364, i32* @par.pool.serial_owner
  br label %par_run_77
par_run_77:
  %t435 = load i64, i64* @arena.Enemies.count
  %t437 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t436, i32 0, i32 0
  store i64 0, i64* %t437
  %t438 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t436, i32 0, i32 1
  store i64 %t435, i64* %t438
  %t439 = bitcast { i64, i64 }* %t436 to i8*
  %t440 = call i32 @par_worker_56(i8* %t439)
  br i1 %t432, label %par_join_79, label %par_release_78
par_release_78:
  store i32 -1, i32* @par.pool.serial_owner
  %t441 = load i8*, i8** @par.pool.serial_lock
  %t442 = call i32 @ReleaseSemaphore(i8* %t441, i32 1, i32* null)
  br label %par_join_79
par_join_79:
  call void @par.pool.ensure_init()
  %t461 = call i32 @GetCurrentThreadId()
  %t462 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t463 = load i32, i32* %t462
  %t464 = icmp eq i32 %t461, %t463
  %t465 = select i1 %t464, i32 0, i32 -1
  %t466 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t467 = load i32, i32* %t466
  %t468 = icmp eq i32 %t461, %t467
  %t469 = select i1 %t468, i32 1, i32 %t465
  %t470 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t471 = load i32, i32* %t470
  %t472 = icmp eq i32 %t461, %t471
  %t473 = select i1 %t472, i32 2, i32 %t469
  %t474 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t475 = load i32, i32* %t474
  %t476 = icmp eq i32 %t461, %t475
  %t477 = select i1 %t476, i32 3, i32 %t473
  %t478 = icmp sge i32 %t477, 0
  br i1 %t478, label %par_serial_87, label %par_pooled_86
par_pooled_86:
  %t479 = load i64, i64* @arena.Bullets.count
  %t480 = mul i64 %t479, 0
  %t481 = sdiv i64 %t480, 4
  %t482 = mul i64 %t479, 1
  %t483 = sdiv i64 %t482, 4
  %t485 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t484, i32 0, i32 0
  store i64 %t481, i64* %t485
  %t486 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t484, i32 0, i32 1
  store i64 %t483, i64* %t486
  %t487 = bitcast { i64, i64 }* %t484 to i8*
  %t488 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t487, i8** %t488
  %t489 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t489
  %t490 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t491 = load i8*, i8** %t490
  %t492 = call i32 @ReleaseSemaphore(i8* %t491, i32 1, i32* null)
  %t493 = mul i64 %t479, 1
  %t494 = sdiv i64 %t493, 4
  %t495 = mul i64 %t479, 2
  %t496 = sdiv i64 %t495, 4
  %t498 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t497, i32 0, i32 0
  store i64 %t494, i64* %t498
  %t499 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t497, i32 0, i32 1
  store i64 %t496, i64* %t499
  %t500 = bitcast { i64, i64 }* %t497 to i8*
  %t501 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t500, i8** %t501
  %t502 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t502
  %t503 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t504 = load i8*, i8** %t503
  %t505 = call i32 @ReleaseSemaphore(i8* %t504, i32 1, i32* null)
  %t506 = mul i64 %t479, 2
  %t507 = sdiv i64 %t506, 4
  %t508 = mul i64 %t479, 3
  %t509 = sdiv i64 %t508, 4
  %t511 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t510, i32 0, i32 0
  store i64 %t507, i64* %t511
  %t512 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t510, i32 0, i32 1
  store i64 %t509, i64* %t512
  %t513 = bitcast { i64, i64 }* %t510 to i8*
  %t514 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t513, i8** %t514
  %t515 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t515
  %t516 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t517 = load i8*, i8** %t516
  %t518 = call i32 @ReleaseSemaphore(i8* %t517, i32 1, i32* null)
  %t519 = mul i64 %t479, 3
  %t520 = sdiv i64 %t519, 4
  %t521 = mul i64 %t479, 4
  %t522 = sdiv i64 %t521, 4
  %t524 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t523, i32 0, i32 0
  store i64 %t520, i64* %t524
  %t525 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t523, i32 0, i32 1
  store i64 %t522, i64* %t525
  %t526 = bitcast { i64, i64 }* %t523 to i8*
  %t527 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t526, i8** %t527
  %t528 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t528
  %t529 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t530 = load i8*, i8** %t529
  %t531 = call i32 @ReleaseSemaphore(i8* %t530, i32 1, i32* null)
  %t532 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t533 = load i8*, i8** %t532
  %t534 = call i32 @WaitForSingleObject(i8* %t533, i32 -1)
  %t535 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t536 = load i8*, i8** %t535
  %t537 = call i32 @WaitForSingleObject(i8* %t536, i32 -1)
  %t538 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t539 = load i8*, i8** %t538
  %t540 = call i32 @WaitForSingleObject(i8* %t539, i32 -1)
  %t541 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t542 = load i8*, i8** %t541
  %t543 = call i32 @WaitForSingleObject(i8* %t542, i32 -1)
  br label %par_join_91
par_serial_87:
  %t544 = load i32, i32* @par.pool.serial_owner
  %t545 = icmp eq i32 %t544, %t477
  br i1 %t545, label %par_run_89, label %par_acquire_88
par_acquire_88:
  %t546 = load i8*, i8** @par.pool.serial_lock
  %t547 = call i32 @WaitForSingleObject(i8* %t546, i32 -1)
  store i32 %t477, i32* @par.pool.serial_owner
  br label %par_run_89
par_run_89:
  %t548 = load i64, i64* @arena.Bullets.count
  %t550 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t549, i32 0, i32 0
  store i64 0, i64* %t550
  %t551 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t549, i32 0, i32 1
  store i64 %t548, i64* %t551
  %t552 = bitcast { i64, i64 }* %t549 to i8*
  %t553 = call i32 @par_worker_80(i8* %t552)
  br i1 %t545, label %par_join_91, label %par_release_90
par_release_90:
  store i32 -1, i32* @par.pool.serial_owner
  %t554 = load i8*, i8** @par.pool.serial_lock
  %t555 = call i32 @ReleaseSemaphore(i8* %t554, i32 1, i32* null)
  br label %par_join_91
par_join_91:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_62(i8* %argp) {
entry:
  %t197 = alloca i64
  %t189 = bitcast i8* %argp to { i64, i64, %Enemy* }*
  %t190 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t189, i32 0, i32 0
  %t191 = load i64, i64* %t190
  %t192 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t189, i32 0, i32 1
  %t193 = load i64, i64* %t192
  %t194 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t189, i32 0, i32 2
  %t195 = load %Enemy*, %Enemy** %t194
  %t196 = load %Bullet*, %Bullet** @arena.Bullets.data
  store i64 %t191, i64* %t197
  br label %par_cond_63
par_cond_63:
  %t198 = load i64, i64* %t197
  %t199 = icmp slt i64 %t198, %t193
  br i1 %t199, label %par_body_64, label %par_end_67
par_body_64:
  %t200 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t198
  %t201 = load i32, i32* %t200
  %t202 = and i32 %t201, 1
  %t203 = icmp eq i32 %t202, 1
  br i1 %t203, label %par_live_65, label %par_incr_66
par_live_65:
  %t204 = getelementptr inbounds %Bullet, %Bullet* %t196, i64 %t198
  %t205 = getelementptr inbounds %Bullet, %Bullet* %t204, i32 0, i32 0
  %t206 = load i32, i32* %t205
  %t207 = add i32 %t206, 1
  %t208 = getelementptr inbounds %Bullet, %Bullet* %t204, i32 0, i32 0
  store i32 %t207, i32* %t208
  br label %par_incr_66
par_incr_66:
  %t209 = add i64 %t198, 1
  store i64 %t209, i64* %t197
  br label %par_cond_63
par_end_67:
  ret i32 0
}


@par.pool.job_fn = global [4 x i32 (i8*)*] zeroinitializer
@par.pool.job_arg = global [4 x i8*] zeroinitializer
@par.pool.start_sem = global [4 x i8*] zeroinitializer
@par.pool.done_sem = global [4 x i8*] zeroinitializer
@par.pool.tid = global [4 x i32] zeroinitializer
@par.pool.inited = global i1 false
@par.pool.serial_lock = global i8* null
@par.pool.serial_owner = global i32 -1

define i32 @par.pool.worker_main(i8* %idx_arg) {
entry:
  %t210 = ptrtoint i8* %idx_arg to i64
  %t211 = trunc i64 %t210 to i32
  %t212 = call i32 @GetCurrentThreadId()
  %t213 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t211
  store i32 %t212, i32* %t213
  br label %loop
loop:
  %t214 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t211
  %t215 = load i8*, i8** %t214
  %t216 = call i32 @WaitForSingleObject(i8* %t215, i32 -1)
  %t217 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t211
  %t218 = load i32 (i8*)*, i32 (i8*)** %t217
  %t219 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t211
  %t220 = load i8*, i8** %t219
  %t221 = call i32 %t218(i8* %t220)
  %t222 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t211
  %t223 = load i8*, i8** %t222
  %t224 = call i32 @ReleaseSemaphore(i8* %t223, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t225 = load i1, i1* @par.pool.inited
  br i1 %t225, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t226 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t226, i8** @par.pool.serial_lock
  %t227 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t228 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t227, i8** %t228
  %t229 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t230 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t229, i8** %t230
  %t231 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t232 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t233 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t232, i8** %t233
  %t234 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t235 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t234, i8** %t235
  %t236 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t237 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t238 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t237, i8** %t238
  %t239 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t240 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t239, i8** %t240
  %t241 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t242 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t243 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t242, i8** %t243
  %t244 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t245 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t244, i8** %t245
  %t246 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_56(i8* %argp) {
entry:
  %t181 = alloca i64
  %t270 = alloca { i64, i64, %Enemy* }
  %t284 = alloca { i64, i64, %Enemy* }
  %t298 = alloca { i64, i64, %Enemy* }
  %t312 = alloca { i64, i64, %Enemy* }
  %t339 = alloca { i64, i64, %Enemy* }
  %t175 = bitcast i8* %argp to { i64, i64 }*
  %t176 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t175, i32 0, i32 0
  %t177 = load i64, i64* %t176
  %t178 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t175, i32 0, i32 1
  %t179 = load i64, i64* %t178
  %t180 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t177, i64* %t181
  br label %par_cond_57
par_cond_57:
  %t182 = load i64, i64* %t181
  %t183 = icmp slt i64 %t182, %t179
  br i1 %t183, label %par_body_58, label %par_end_61
par_body_58:
  %t184 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t182
  %t185 = load i32, i32* %t184
  %t186 = and i32 %t185, 1
  %t187 = icmp eq i32 %t186, 1
  br i1 %t187, label %par_live_59, label %par_incr_60
par_live_59:
  %t188 = getelementptr inbounds %Enemy, %Enemy* %t180, i64 %t182
  call void @par.pool.ensure_init()
  %t247 = call i32 @GetCurrentThreadId()
  %t248 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t249 = load i32, i32* %t248
  %t250 = icmp eq i32 %t247, %t249
  %t251 = select i1 %t250, i32 0, i32 -1
  %t252 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t253 = load i32, i32* %t252
  %t254 = icmp eq i32 %t247, %t253
  %t255 = select i1 %t254, i32 1, i32 %t251
  %t256 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t257 = load i32, i32* %t256
  %t258 = icmp eq i32 %t247, %t257
  %t259 = select i1 %t258, i32 2, i32 %t255
  %t260 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t261 = load i32, i32* %t260
  %t262 = icmp eq i32 %t247, %t261
  %t263 = select i1 %t262, i32 3, i32 %t259
  %t264 = icmp sge i32 %t263, 0
  br i1 %t264, label %par_serial_69, label %par_pooled_68
par_pooled_68:
  %t265 = load i64, i64* @arena.Bullets.count
  %t266 = mul i64 %t265, 0
  %t267 = sdiv i64 %t266, 4
  %t268 = mul i64 %t265, 1
  %t269 = sdiv i64 %t268, 4
  %t271 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t270, i32 0, i32 0
  store i64 %t267, i64* %t271
  %t272 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t270, i32 0, i32 1
  store i64 %t269, i64* %t272
  %t273 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t270, i32 0, i32 2
  store %Enemy* %t188, %Enemy** %t273
  %t274 = bitcast { i64, i64, %Enemy* }* %t270 to i8*
  %t275 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t274, i8** %t275
  %t276 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t276
  %t277 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t278 = load i8*, i8** %t277
  %t279 = call i32 @ReleaseSemaphore(i8* %t278, i32 1, i32* null)
  %t280 = mul i64 %t265, 1
  %t281 = sdiv i64 %t280, 4
  %t282 = mul i64 %t265, 2
  %t283 = sdiv i64 %t282, 4
  %t285 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t284, i32 0, i32 0
  store i64 %t281, i64* %t285
  %t286 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t284, i32 0, i32 1
  store i64 %t283, i64* %t286
  %t287 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t284, i32 0, i32 2
  store %Enemy* %t188, %Enemy** %t287
  %t288 = bitcast { i64, i64, %Enemy* }* %t284 to i8*
  %t289 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t288, i8** %t289
  %t290 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t290
  %t291 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t292 = load i8*, i8** %t291
  %t293 = call i32 @ReleaseSemaphore(i8* %t292, i32 1, i32* null)
  %t294 = mul i64 %t265, 2
  %t295 = sdiv i64 %t294, 4
  %t296 = mul i64 %t265, 3
  %t297 = sdiv i64 %t296, 4
  %t299 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t298, i32 0, i32 0
  store i64 %t295, i64* %t299
  %t300 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t298, i32 0, i32 1
  store i64 %t297, i64* %t300
  %t301 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t298, i32 0, i32 2
  store %Enemy* %t188, %Enemy** %t301
  %t302 = bitcast { i64, i64, %Enemy* }* %t298 to i8*
  %t303 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t302, i8** %t303
  %t304 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t304
  %t305 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t306 = load i8*, i8** %t305
  %t307 = call i32 @ReleaseSemaphore(i8* %t306, i32 1, i32* null)
  %t308 = mul i64 %t265, 3
  %t309 = sdiv i64 %t308, 4
  %t310 = mul i64 %t265, 4
  %t311 = sdiv i64 %t310, 4
  %t313 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t312, i32 0, i32 0
  store i64 %t309, i64* %t313
  %t314 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t312, i32 0, i32 1
  store i64 %t311, i64* %t314
  %t315 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t312, i32 0, i32 2
  store %Enemy* %t188, %Enemy** %t315
  %t316 = bitcast { i64, i64, %Enemy* }* %t312 to i8*
  %t317 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t316, i8** %t317
  %t318 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t318
  %t319 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t320 = load i8*, i8** %t319
  %t321 = call i32 @ReleaseSemaphore(i8* %t320, i32 1, i32* null)
  %t322 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t323 = load i8*, i8** %t322
  %t324 = call i32 @WaitForSingleObject(i8* %t323, i32 -1)
  %t325 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t326 = load i8*, i8** %t325
  %t327 = call i32 @WaitForSingleObject(i8* %t326, i32 -1)
  %t328 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t329 = load i8*, i8** %t328
  %t330 = call i32 @WaitForSingleObject(i8* %t329, i32 -1)
  %t331 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t332 = load i8*, i8** %t331
  %t333 = call i32 @WaitForSingleObject(i8* %t332, i32 -1)
  br label %par_join_73
par_serial_69:
  %t334 = load i32, i32* @par.pool.serial_owner
  %t335 = icmp eq i32 %t334, %t263
  br i1 %t335, label %par_run_71, label %par_acquire_70
par_acquire_70:
  %t336 = load i8*, i8** @par.pool.serial_lock
  %t337 = call i32 @WaitForSingleObject(i8* %t336, i32 -1)
  store i32 %t263, i32* @par.pool.serial_owner
  br label %par_run_71
par_run_71:
  %t338 = load i64, i64* @arena.Bullets.count
  %t340 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t339, i32 0, i32 0
  store i64 0, i64* %t340
  %t341 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t339, i32 0, i32 1
  store i64 %t338, i64* %t341
  %t342 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t339, i32 0, i32 2
  store %Enemy* %t188, %Enemy** %t342
  %t343 = bitcast { i64, i64, %Enemy* }* %t339 to i8*
  %t344 = call i32 @par_worker_62(i8* %t343)
  br i1 %t335, label %par_join_73, label %par_release_72
par_release_72:
  store i32 -1, i32* @par.pool.serial_owner
  %t345 = load i8*, i8** @par.pool.serial_lock
  %t346 = call i32 @ReleaseSemaphore(i8* %t345, i32 1, i32* null)
  br label %par_join_73
par_join_73:
  br label %par_incr_60
par_incr_60:
  %t347 = add i64 %t182, 1
  store i64 %t347, i64* %t181
  br label %par_cond_57
par_end_61:
  ret i32 0
}


define i32 @par_worker_80(i8* %argp) {
entry:
  %t449 = alloca i64
  %t443 = bitcast i8* %argp to { i64, i64 }*
  %t444 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t443, i32 0, i32 0
  %t445 = load i64, i64* %t444
  %t446 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t443, i32 0, i32 1
  %t447 = load i64, i64* %t446
  %t448 = load %Bullet*, %Bullet** @arena.Bullets.data
  store i64 %t445, i64* %t449
  br label %par_cond_81
par_cond_81:
  %t450 = load i64, i64* %t449
  %t451 = icmp slt i64 %t450, %t447
  br i1 %t451, label %par_body_82, label %par_end_85
par_body_82:
  %t452 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t450
  %t453 = load i32, i32* %t452
  %t454 = and i32 %t453, 1
  %t455 = icmp eq i32 %t454, 1
  br i1 %t455, label %par_live_83, label %par_incr_84
par_live_83:
  %t456 = getelementptr inbounds %Bullet, %Bullet* %t448, i64 %t450
  %t457 = getelementptr inbounds %Bullet, %Bullet* %t456, i32 0, i32 0
  %t458 = load i32, i32* %t457
  %t459 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t459, i32 %t458)
  br label %par_incr_84
par_incr_84:
  %t460 = add i64 %t450, 1
  store i64 %t460, i64* %t449
  br label %par_cond_81
par_end_85:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.4 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.5 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.6 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.7 = private unnamed_addr constant [9 x i8] c"dmg: %d\0A\00"
