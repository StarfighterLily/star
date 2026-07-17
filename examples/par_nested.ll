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
  %t19 = alloca %Enemy
  %t44 = alloca %Enemy
  %t69 = alloca %Enemy
  %t94 = alloca %Bullet
  %t119 = alloca %Bullet
  %t144 = alloca %Bullet
  %t169 = alloca %Bullet
  %t372 = alloca { i64, i64 }
  %t385 = alloca { i64, i64 }
  %t398 = alloca { i64, i64 }
  %t411 = alloca { i64, i64 }
  %t437 = alloca { i64, i64 }
  %t485 = alloca { i64, i64 }
  %t498 = alloca { i64, i64 }
  %t511 = alloca { i64, i64 }
  %t524 = alloca { i64, i64 }
  %t550 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t2 = icmp eq %Enemy* %t1, null
  br i1 %t2, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t3 = getelementptr %Enemy, %Enemy* null, i32 1
  %t4 = ptrtoint %Enemy* %t3 to i64
  %t5 = mul i64 %t4, 1024
  %t6 = call i8* @malloc(i64 %t5)
  %t7 = bitcast i8* %t6 to %Enemy*
  store %Enemy* %t7, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t8 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t9 = load i64, i64* @arena.Enemies.free_top
  %t10 = icmp sgt i64 %t9, 0
  br i1 %t10, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t11 = sub i64 %t9, 1
  store i64 %t11, i64* @arena.Enemies.free_top
  %t12 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t11
  %t13 = load i64, i64* %t12
  br label %spawn_store_4
spawn_grow_3:
  %t14 = load i64, i64* @arena.Enemies.count
  %t15 = icmp slt i64 %t14, 1024
  br i1 %t15, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t16 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t16)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t17 = add i64 %t14, 1
  store i64 %t17, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t18 = phi i64 [ %t13, %spawn_reuse_2 ], [ %t14, %spawn_grow_ok_6 ]
  %t20 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  store i32 10, i32* %t20
  %t21 = load %Enemy, %Enemy* %t19
  %t22 = getelementptr inbounds %Enemy, %Enemy* %t8, i64 %t18
  store %Enemy %t21, %Enemy* %t22
  %t23 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t18
  %t24 = load i32, i32* %t23
  %t25 = add i32 %t24, 1
  store i32 %t25, i32* %t23
  br label %spawn_end_5
spawn_end_5:
  %t26 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t27 = icmp eq %Enemy* %t26, null
  br i1 %t27, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t28 = getelementptr %Enemy, %Enemy* null, i32 1
  %t29 = ptrtoint %Enemy* %t28 to i64
  %t30 = mul i64 %t29, 1024
  %t31 = call i8* @malloc(i64 %t30)
  %t32 = bitcast i8* %t31 to %Enemy*
  store %Enemy* %t32, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t33 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t34 = load i64, i64* @arena.Enemies.free_top
  %t35 = icmp sgt i64 %t34, 0
  br i1 %t35, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t36 = sub i64 %t34, 1
  store i64 %t36, i64* @arena.Enemies.free_top
  %t37 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t36
  %t38 = load i64, i64* %t37
  br label %spawn_store_12
spawn_grow_11:
  %t39 = load i64, i64* @arena.Enemies.count
  %t40 = icmp slt i64 %t39, 1024
  br i1 %t40, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t41 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t41)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t42 = add i64 %t39, 1
  store i64 %t42, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t43 = phi i64 [ %t38, %spawn_reuse_10 ], [ %t39, %spawn_grow_ok_14 ]
  %t45 = getelementptr inbounds %Enemy, %Enemy* %t44, i32 0, i32 0
  store i32 10, i32* %t45
  %t46 = load %Enemy, %Enemy* %t44
  %t47 = getelementptr inbounds %Enemy, %Enemy* %t33, i64 %t43
  store %Enemy %t46, %Enemy* %t47
  %t48 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t43
  %t49 = load i32, i32* %t48
  %t50 = add i32 %t49, 1
  store i32 %t50, i32* %t48
  br label %spawn_end_13
spawn_end_13:
  %t51 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t52 = icmp eq %Enemy* %t51, null
  br i1 %t52, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t53 = getelementptr %Enemy, %Enemy* null, i32 1
  %t54 = ptrtoint %Enemy* %t53 to i64
  %t55 = mul i64 %t54, 1024
  %t56 = call i8* @malloc(i64 %t55)
  %t57 = bitcast i8* %t56 to %Enemy*
  store %Enemy* %t57, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t58 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t59 = load i64, i64* @arena.Enemies.free_top
  %t60 = icmp sgt i64 %t59, 0
  br i1 %t60, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t61 = sub i64 %t59, 1
  store i64 %t61, i64* @arena.Enemies.free_top
  %t62 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t61
  %t63 = load i64, i64* %t62
  br label %spawn_store_20
spawn_grow_19:
  %t64 = load i64, i64* @arena.Enemies.count
  %t65 = icmp slt i64 %t64, 1024
  br i1 %t65, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t66 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t66)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t67 = add i64 %t64, 1
  store i64 %t67, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t68 = phi i64 [ %t63, %spawn_reuse_18 ], [ %t64, %spawn_grow_ok_22 ]
  %t70 = getelementptr inbounds %Enemy, %Enemy* %t69, i32 0, i32 0
  store i32 10, i32* %t70
  %t71 = load %Enemy, %Enemy* %t69
  %t72 = getelementptr inbounds %Enemy, %Enemy* %t58, i64 %t68
  store %Enemy %t71, %Enemy* %t72
  %t73 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t68
  %t74 = load i32, i32* %t73
  %t75 = add i32 %t74, 1
  store i32 %t75, i32* %t73
  br label %spawn_end_21
spawn_end_21:
  %t76 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t77 = icmp eq %Bullet* %t76, null
  br i1 %t77, label %spawn_init_24, label %spawn_ready_25
spawn_init_24:
  %t78 = getelementptr %Bullet, %Bullet* null, i32 1
  %t79 = ptrtoint %Bullet* %t78 to i64
  %t80 = mul i64 %t79, 1024
  %t81 = call i8* @malloc(i64 %t80)
  %t82 = bitcast i8* %t81 to %Bullet*
  store %Bullet* %t82, %Bullet** @arena.Bullets.data
  br label %spawn_ready_25
spawn_ready_25:
  %t83 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t84 = load i64, i64* @arena.Bullets.free_top
  %t85 = icmp sgt i64 %t84, 0
  br i1 %t85, label %spawn_reuse_26, label %spawn_grow_27
spawn_reuse_26:
  %t86 = sub i64 %t84, 1
  store i64 %t86, i64* @arena.Bullets.free_top
  %t87 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t86
  %t88 = load i64, i64* %t87
  br label %spawn_store_28
spawn_grow_27:
  %t89 = load i64, i64* @arena.Bullets.count
  %t90 = icmp slt i64 %t89, 1024
  br i1 %t90, label %spawn_grow_ok_30, label %spawn_capacity_warn_31
spawn_capacity_warn_31:
  %t91 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t91)
  br label %spawn_end_29
spawn_grow_ok_30:
  %t92 = add i64 %t89, 1
  store i64 %t92, i64* @arena.Bullets.count
  br label %spawn_store_28
spawn_store_28:
  %t93 = phi i64 [ %t88, %spawn_reuse_26 ], [ %t89, %spawn_grow_ok_30 ]
  %t95 = getelementptr inbounds %Bullet, %Bullet* %t94, i32 0, i32 0
  store i32 0, i32* %t95
  %t96 = load %Bullet, %Bullet* %t94
  %t97 = getelementptr inbounds %Bullet, %Bullet* %t83, i64 %t93
  store %Bullet %t96, %Bullet* %t97
  %t98 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t93
  %t99 = load i32, i32* %t98
  %t100 = add i32 %t99, 1
  store i32 %t100, i32* %t98
  br label %spawn_end_29
spawn_end_29:
  %t101 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t102 = icmp eq %Bullet* %t101, null
  br i1 %t102, label %spawn_init_32, label %spawn_ready_33
spawn_init_32:
  %t103 = getelementptr %Bullet, %Bullet* null, i32 1
  %t104 = ptrtoint %Bullet* %t103 to i64
  %t105 = mul i64 %t104, 1024
  %t106 = call i8* @malloc(i64 %t105)
  %t107 = bitcast i8* %t106 to %Bullet*
  store %Bullet* %t107, %Bullet** @arena.Bullets.data
  br label %spawn_ready_33
spawn_ready_33:
  %t108 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t109 = load i64, i64* @arena.Bullets.free_top
  %t110 = icmp sgt i64 %t109, 0
  br i1 %t110, label %spawn_reuse_34, label %spawn_grow_35
spawn_reuse_34:
  %t111 = sub i64 %t109, 1
  store i64 %t111, i64* @arena.Bullets.free_top
  %t112 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t111
  %t113 = load i64, i64* %t112
  br label %spawn_store_36
spawn_grow_35:
  %t114 = load i64, i64* @arena.Bullets.count
  %t115 = icmp slt i64 %t114, 1024
  br i1 %t115, label %spawn_grow_ok_38, label %spawn_capacity_warn_39
spawn_capacity_warn_39:
  %t116 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t116)
  br label %spawn_end_37
spawn_grow_ok_38:
  %t117 = add i64 %t114, 1
  store i64 %t117, i64* @arena.Bullets.count
  br label %spawn_store_36
spawn_store_36:
  %t118 = phi i64 [ %t113, %spawn_reuse_34 ], [ %t114, %spawn_grow_ok_38 ]
  %t120 = getelementptr inbounds %Bullet, %Bullet* %t119, i32 0, i32 0
  store i32 0, i32* %t120
  %t121 = load %Bullet, %Bullet* %t119
  %t122 = getelementptr inbounds %Bullet, %Bullet* %t108, i64 %t118
  store %Bullet %t121, %Bullet* %t122
  %t123 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t118
  %t124 = load i32, i32* %t123
  %t125 = add i32 %t124, 1
  store i32 %t125, i32* %t123
  br label %spawn_end_37
spawn_end_37:
  %t126 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t127 = icmp eq %Bullet* %t126, null
  br i1 %t127, label %spawn_init_40, label %spawn_ready_41
spawn_init_40:
  %t128 = getelementptr %Bullet, %Bullet* null, i32 1
  %t129 = ptrtoint %Bullet* %t128 to i64
  %t130 = mul i64 %t129, 1024
  %t131 = call i8* @malloc(i64 %t130)
  %t132 = bitcast i8* %t131 to %Bullet*
  store %Bullet* %t132, %Bullet** @arena.Bullets.data
  br label %spawn_ready_41
spawn_ready_41:
  %t133 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t134 = load i64, i64* @arena.Bullets.free_top
  %t135 = icmp sgt i64 %t134, 0
  br i1 %t135, label %spawn_reuse_42, label %spawn_grow_43
spawn_reuse_42:
  %t136 = sub i64 %t134, 1
  store i64 %t136, i64* @arena.Bullets.free_top
  %t137 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t136
  %t138 = load i64, i64* %t137
  br label %spawn_store_44
spawn_grow_43:
  %t139 = load i64, i64* @arena.Bullets.count
  %t140 = icmp slt i64 %t139, 1024
  br i1 %t140, label %spawn_grow_ok_46, label %spawn_capacity_warn_47
spawn_capacity_warn_47:
  %t141 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t141)
  br label %spawn_end_45
spawn_grow_ok_46:
  %t142 = add i64 %t139, 1
  store i64 %t142, i64* @arena.Bullets.count
  br label %spawn_store_44
spawn_store_44:
  %t143 = phi i64 [ %t138, %spawn_reuse_42 ], [ %t139, %spawn_grow_ok_46 ]
  %t145 = getelementptr inbounds %Bullet, %Bullet* %t144, i32 0, i32 0
  store i32 0, i32* %t145
  %t146 = load %Bullet, %Bullet* %t144
  %t147 = getelementptr inbounds %Bullet, %Bullet* %t133, i64 %t143
  store %Bullet %t146, %Bullet* %t147
  %t148 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t143
  %t149 = load i32, i32* %t148
  %t150 = add i32 %t149, 1
  store i32 %t150, i32* %t148
  br label %spawn_end_45
spawn_end_45:
  %t151 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t152 = icmp eq %Bullet* %t151, null
  br i1 %t152, label %spawn_init_48, label %spawn_ready_49
spawn_init_48:
  %t153 = getelementptr %Bullet, %Bullet* null, i32 1
  %t154 = ptrtoint %Bullet* %t153 to i64
  %t155 = mul i64 %t154, 1024
  %t156 = call i8* @malloc(i64 %t155)
  %t157 = bitcast i8* %t156 to %Bullet*
  store %Bullet* %t157, %Bullet** @arena.Bullets.data
  br label %spawn_ready_49
spawn_ready_49:
  %t158 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t159 = load i64, i64* @arena.Bullets.free_top
  %t160 = icmp sgt i64 %t159, 0
  br i1 %t160, label %spawn_reuse_50, label %spawn_grow_51
spawn_reuse_50:
  %t161 = sub i64 %t159, 1
  store i64 %t161, i64* @arena.Bullets.free_top
  %t162 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t161
  %t163 = load i64, i64* %t162
  br label %spawn_store_52
spawn_grow_51:
  %t164 = load i64, i64* @arena.Bullets.count
  %t165 = icmp slt i64 %t164, 1024
  br i1 %t165, label %spawn_grow_ok_54, label %spawn_capacity_warn_55
spawn_capacity_warn_55:
  %t166 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t166)
  br label %spawn_end_53
spawn_grow_ok_54:
  %t167 = add i64 %t164, 1
  store i64 %t167, i64* @arena.Bullets.count
  br label %spawn_store_52
spawn_store_52:
  %t168 = phi i64 [ %t163, %spawn_reuse_50 ], [ %t164, %spawn_grow_ok_54 ]
  %t170 = getelementptr inbounds %Bullet, %Bullet* %t169, i32 0, i32 0
  store i32 0, i32* %t170
  %t171 = load %Bullet, %Bullet* %t169
  %t172 = getelementptr inbounds %Bullet, %Bullet* %t158, i64 %t168
  store %Bullet %t171, %Bullet* %t172
  %t173 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t168
  %t174 = load i32, i32* %t173
  %t175 = add i32 %t174, 1
  store i32 %t175, i32* %t173
  br label %spawn_end_53
spawn_end_53:
  call void @par.pool.ensure_init()
  %t349 = call i32 @GetCurrentThreadId()
  %t350 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t351 = load i32, i32* %t350
  %t352 = icmp eq i32 %t349, %t351
  %t353 = select i1 %t352, i32 0, i32 -1
  %t354 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t355 = load i32, i32* %t354
  %t356 = icmp eq i32 %t349, %t355
  %t357 = select i1 %t356, i32 1, i32 %t353
  %t358 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t359 = load i32, i32* %t358
  %t360 = icmp eq i32 %t349, %t359
  %t361 = select i1 %t360, i32 2, i32 %t357
  %t362 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t363 = load i32, i32* %t362
  %t364 = icmp eq i32 %t349, %t363
  %t365 = select i1 %t364, i32 3, i32 %t361
  %t366 = icmp sge i32 %t365, 0
  br i1 %t366, label %par_serial_75, label %par_pooled_74
par_pooled_74:
  %t367 = load i64, i64* @arena.Enemies.count
  %t368 = mul i64 %t367, 0
  %t369 = sdiv i64 %t368, 4
  %t370 = mul i64 %t367, 1
  %t371 = sdiv i64 %t370, 4
  %t373 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t372, i32 0, i32 0
  store i64 %t369, i64* %t373
  %t374 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t372, i32 0, i32 1
  store i64 %t371, i64* %t374
  %t375 = bitcast { i64, i64 }* %t372 to i8*
  %t376 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t375, i8** %t376
  %t377 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t377
  %t378 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t379 = load i8*, i8** %t378
  %t380 = call i32 @ReleaseSemaphore(i8* %t379, i32 1, i32* null)
  %t381 = mul i64 %t367, 1
  %t382 = sdiv i64 %t381, 4
  %t383 = mul i64 %t367, 2
  %t384 = sdiv i64 %t383, 4
  %t386 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t385, i32 0, i32 0
  store i64 %t382, i64* %t386
  %t387 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t385, i32 0, i32 1
  store i64 %t384, i64* %t387
  %t388 = bitcast { i64, i64 }* %t385 to i8*
  %t389 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t388, i8** %t389
  %t390 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t390
  %t391 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t392 = load i8*, i8** %t391
  %t393 = call i32 @ReleaseSemaphore(i8* %t392, i32 1, i32* null)
  %t394 = mul i64 %t367, 2
  %t395 = sdiv i64 %t394, 4
  %t396 = mul i64 %t367, 3
  %t397 = sdiv i64 %t396, 4
  %t399 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t398, i32 0, i32 0
  store i64 %t395, i64* %t399
  %t400 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t398, i32 0, i32 1
  store i64 %t397, i64* %t400
  %t401 = bitcast { i64, i64 }* %t398 to i8*
  %t402 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t401, i8** %t402
  %t403 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t403
  %t404 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t405 = load i8*, i8** %t404
  %t406 = call i32 @ReleaseSemaphore(i8* %t405, i32 1, i32* null)
  %t407 = mul i64 %t367, 3
  %t408 = sdiv i64 %t407, 4
  %t409 = mul i64 %t367, 4
  %t410 = sdiv i64 %t409, 4
  %t412 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t411, i32 0, i32 0
  store i64 %t408, i64* %t412
  %t413 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t411, i32 0, i32 1
  store i64 %t410, i64* %t413
  %t414 = bitcast { i64, i64 }* %t411 to i8*
  %t415 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t414, i8** %t415
  %t416 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t416
  %t417 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t418 = load i8*, i8** %t417
  %t419 = call i32 @ReleaseSemaphore(i8* %t418, i32 1, i32* null)
  %t420 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t421 = load i8*, i8** %t420
  %t422 = call i32 @WaitForSingleObject(i8* %t421, i32 -1)
  %t423 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t424 = load i8*, i8** %t423
  %t425 = call i32 @WaitForSingleObject(i8* %t424, i32 -1)
  %t426 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t427 = load i8*, i8** %t426
  %t428 = call i32 @WaitForSingleObject(i8* %t427, i32 -1)
  %t429 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t430 = load i8*, i8** %t429
  %t431 = call i32 @WaitForSingleObject(i8* %t430, i32 -1)
  br label %par_join_79
par_serial_75:
  %t432 = load i32, i32* @par.pool.serial_owner
  %t433 = icmp eq i32 %t432, %t365
  br i1 %t433, label %par_run_77, label %par_acquire_76
par_acquire_76:
  %t434 = load i8*, i8** @par.pool.serial_lock
  %t435 = call i32 @WaitForSingleObject(i8* %t434, i32 -1)
  store i32 %t365, i32* @par.pool.serial_owner
  br label %par_run_77
par_run_77:
  %t436 = load i64, i64* @arena.Enemies.count
  %t438 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t437, i32 0, i32 0
  store i64 0, i64* %t438
  %t439 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t437, i32 0, i32 1
  store i64 %t436, i64* %t439
  %t440 = bitcast { i64, i64 }* %t437 to i8*
  %t441 = call i32 @par_worker_56(i8* %t440)
  br i1 %t433, label %par_join_79, label %par_release_78
par_release_78:
  store i32 -1, i32* @par.pool.serial_owner
  %t442 = load i8*, i8** @par.pool.serial_lock
  %t443 = call i32 @ReleaseSemaphore(i8* %t442, i32 1, i32* null)
  br label %par_join_79
par_join_79:
  call void @par.pool.ensure_init()
  %t462 = call i32 @GetCurrentThreadId()
  %t463 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t464 = load i32, i32* %t463
  %t465 = icmp eq i32 %t462, %t464
  %t466 = select i1 %t465, i32 0, i32 -1
  %t467 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t468 = load i32, i32* %t467
  %t469 = icmp eq i32 %t462, %t468
  %t470 = select i1 %t469, i32 1, i32 %t466
  %t471 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t472 = load i32, i32* %t471
  %t473 = icmp eq i32 %t462, %t472
  %t474 = select i1 %t473, i32 2, i32 %t470
  %t475 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t476 = load i32, i32* %t475
  %t477 = icmp eq i32 %t462, %t476
  %t478 = select i1 %t477, i32 3, i32 %t474
  %t479 = icmp sge i32 %t478, 0
  br i1 %t479, label %par_serial_87, label %par_pooled_86
par_pooled_86:
  %t480 = load i64, i64* @arena.Bullets.count
  %t481 = mul i64 %t480, 0
  %t482 = sdiv i64 %t481, 4
  %t483 = mul i64 %t480, 1
  %t484 = sdiv i64 %t483, 4
  %t486 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t485, i32 0, i32 0
  store i64 %t482, i64* %t486
  %t487 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t485, i32 0, i32 1
  store i64 %t484, i64* %t487
  %t488 = bitcast { i64, i64 }* %t485 to i8*
  %t489 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t488, i8** %t489
  %t490 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t490
  %t491 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t492 = load i8*, i8** %t491
  %t493 = call i32 @ReleaseSemaphore(i8* %t492, i32 1, i32* null)
  %t494 = mul i64 %t480, 1
  %t495 = sdiv i64 %t494, 4
  %t496 = mul i64 %t480, 2
  %t497 = sdiv i64 %t496, 4
  %t499 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t498, i32 0, i32 0
  store i64 %t495, i64* %t499
  %t500 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t498, i32 0, i32 1
  store i64 %t497, i64* %t500
  %t501 = bitcast { i64, i64 }* %t498 to i8*
  %t502 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t501, i8** %t502
  %t503 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t503
  %t504 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t505 = load i8*, i8** %t504
  %t506 = call i32 @ReleaseSemaphore(i8* %t505, i32 1, i32* null)
  %t507 = mul i64 %t480, 2
  %t508 = sdiv i64 %t507, 4
  %t509 = mul i64 %t480, 3
  %t510 = sdiv i64 %t509, 4
  %t512 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t511, i32 0, i32 0
  store i64 %t508, i64* %t512
  %t513 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t511, i32 0, i32 1
  store i64 %t510, i64* %t513
  %t514 = bitcast { i64, i64 }* %t511 to i8*
  %t515 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t514, i8** %t515
  %t516 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t516
  %t517 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t518 = load i8*, i8** %t517
  %t519 = call i32 @ReleaseSemaphore(i8* %t518, i32 1, i32* null)
  %t520 = mul i64 %t480, 3
  %t521 = sdiv i64 %t520, 4
  %t522 = mul i64 %t480, 4
  %t523 = sdiv i64 %t522, 4
  %t525 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t524, i32 0, i32 0
  store i64 %t521, i64* %t525
  %t526 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t524, i32 0, i32 1
  store i64 %t523, i64* %t526
  %t527 = bitcast { i64, i64 }* %t524 to i8*
  %t528 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t527, i8** %t528
  %t529 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t529
  %t530 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t531 = load i8*, i8** %t530
  %t532 = call i32 @ReleaseSemaphore(i8* %t531, i32 1, i32* null)
  %t533 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t534 = load i8*, i8** %t533
  %t535 = call i32 @WaitForSingleObject(i8* %t534, i32 -1)
  %t536 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t537 = load i8*, i8** %t536
  %t538 = call i32 @WaitForSingleObject(i8* %t537, i32 -1)
  %t539 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t540 = load i8*, i8** %t539
  %t541 = call i32 @WaitForSingleObject(i8* %t540, i32 -1)
  %t542 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t543 = load i8*, i8** %t542
  %t544 = call i32 @WaitForSingleObject(i8* %t543, i32 -1)
  br label %par_join_91
par_serial_87:
  %t545 = load i32, i32* @par.pool.serial_owner
  %t546 = icmp eq i32 %t545, %t478
  br i1 %t546, label %par_run_89, label %par_acquire_88
par_acquire_88:
  %t547 = load i8*, i8** @par.pool.serial_lock
  %t548 = call i32 @WaitForSingleObject(i8* %t547, i32 -1)
  store i32 %t478, i32* @par.pool.serial_owner
  br label %par_run_89
par_run_89:
  %t549 = load i64, i64* @arena.Bullets.count
  %t551 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t550, i32 0, i32 0
  store i64 0, i64* %t551
  %t552 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t550, i32 0, i32 1
  store i64 %t549, i64* %t552
  %t553 = bitcast { i64, i64 }* %t550 to i8*
  %t554 = call i32 @par_worker_80(i8* %t553)
  br i1 %t546, label %par_join_91, label %par_release_90
par_release_90:
  store i32 -1, i32* @par.pool.serial_owner
  %t555 = load i8*, i8** @par.pool.serial_lock
  %t556 = call i32 @ReleaseSemaphore(i8* %t555, i32 1, i32* null)
  br label %par_join_91
par_join_91:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_62(i8* %argp) {
entry:
  %t198 = alloca i64
  %t190 = bitcast i8* %argp to { i64, i64, %Enemy* }*
  %t191 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t190, i32 0, i32 0
  %t192 = load i64, i64* %t191
  %t193 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t190, i32 0, i32 1
  %t194 = load i64, i64* %t193
  %t195 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t190, i32 0, i32 2
  %t196 = load %Enemy*, %Enemy** %t195
  %t197 = load %Bullet*, %Bullet** @arena.Bullets.data
  store i64 %t192, i64* %t198
  br label %par_cond_63
par_cond_63:
  %t199 = load i64, i64* %t198
  %t200 = icmp slt i64 %t199, %t194
  br i1 %t200, label %par_body_64, label %par_end_67
par_body_64:
  %t201 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t199
  %t202 = load i32, i32* %t201
  %t203 = and i32 %t202, 1
  %t204 = icmp eq i32 %t203, 1
  br i1 %t204, label %par_live_65, label %par_incr_66
par_live_65:
  %t205 = getelementptr inbounds %Bullet, %Bullet* %t197, i64 %t199
  %t206 = getelementptr inbounds %Bullet, %Bullet* %t205, i32 0, i32 0
  %t207 = load i32, i32* %t206
  %t208 = add i32 %t207, 1
  %t209 = getelementptr inbounds %Bullet, %Bullet* %t205, i32 0, i32 0
  store i32 %t208, i32* %t209
  br label %par_incr_66
par_incr_66:
  %t210 = add i64 %t199, 1
  store i64 %t210, i64* %t198
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
  %t211 = ptrtoint i8* %idx_arg to i64
  %t212 = trunc i64 %t211 to i32
  %t213 = call i32 @GetCurrentThreadId()
  %t214 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t212
  store i32 %t213, i32* %t214
  br label %loop
loop:
  %t215 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t212
  %t216 = load i8*, i8** %t215
  %t217 = call i32 @WaitForSingleObject(i8* %t216, i32 -1)
  %t218 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t212
  %t219 = load i32 (i8*)*, i32 (i8*)** %t218
  %t220 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t212
  %t221 = load i8*, i8** %t220
  %t222 = call i32 %t219(i8* %t221)
  %t223 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t212
  %t224 = load i8*, i8** %t223
  %t225 = call i32 @ReleaseSemaphore(i8* %t224, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t226 = load i1, i1* @par.pool.inited
  br i1 %t226, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t227 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t227, i8** @par.pool.serial_lock
  %t228 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t229 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t228, i8** %t229
  %t230 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t231 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t230, i8** %t231
  %t232 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t233 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t234 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t233, i8** %t234
  %t235 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t236 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t235, i8** %t236
  %t237 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t238 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t239 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t238, i8** %t239
  %t240 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t241 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t240, i8** %t241
  %t242 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t243 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t244 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t243, i8** %t244
  %t245 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t246 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t245, i8** %t246
  %t247 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_56(i8* %argp) {
entry:
  %t182 = alloca i64
  %t271 = alloca { i64, i64, %Enemy* }
  %t285 = alloca { i64, i64, %Enemy* }
  %t299 = alloca { i64, i64, %Enemy* }
  %t313 = alloca { i64, i64, %Enemy* }
  %t340 = alloca { i64, i64, %Enemy* }
  %t176 = bitcast i8* %argp to { i64, i64 }*
  %t177 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t176, i32 0, i32 0
  %t178 = load i64, i64* %t177
  %t179 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t176, i32 0, i32 1
  %t180 = load i64, i64* %t179
  %t181 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t178, i64* %t182
  br label %par_cond_57
par_cond_57:
  %t183 = load i64, i64* %t182
  %t184 = icmp slt i64 %t183, %t180
  br i1 %t184, label %par_body_58, label %par_end_61
par_body_58:
  %t185 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t183
  %t186 = load i32, i32* %t185
  %t187 = and i32 %t186, 1
  %t188 = icmp eq i32 %t187, 1
  br i1 %t188, label %par_live_59, label %par_incr_60
par_live_59:
  %t189 = getelementptr inbounds %Enemy, %Enemy* %t181, i64 %t183
  call void @par.pool.ensure_init()
  %t248 = call i32 @GetCurrentThreadId()
  %t249 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t250 = load i32, i32* %t249
  %t251 = icmp eq i32 %t248, %t250
  %t252 = select i1 %t251, i32 0, i32 -1
  %t253 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t254 = load i32, i32* %t253
  %t255 = icmp eq i32 %t248, %t254
  %t256 = select i1 %t255, i32 1, i32 %t252
  %t257 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t258 = load i32, i32* %t257
  %t259 = icmp eq i32 %t248, %t258
  %t260 = select i1 %t259, i32 2, i32 %t256
  %t261 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t262 = load i32, i32* %t261
  %t263 = icmp eq i32 %t248, %t262
  %t264 = select i1 %t263, i32 3, i32 %t260
  %t265 = icmp sge i32 %t264, 0
  br i1 %t265, label %par_serial_69, label %par_pooled_68
par_pooled_68:
  %t266 = load i64, i64* @arena.Bullets.count
  %t267 = mul i64 %t266, 0
  %t268 = sdiv i64 %t267, 4
  %t269 = mul i64 %t266, 1
  %t270 = sdiv i64 %t269, 4
  %t272 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t271, i32 0, i32 0
  store i64 %t268, i64* %t272
  %t273 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t271, i32 0, i32 1
  store i64 %t270, i64* %t273
  %t274 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t271, i32 0, i32 2
  store %Enemy* %t189, %Enemy** %t274
  %t275 = bitcast { i64, i64, %Enemy* }* %t271 to i8*
  %t276 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t275, i8** %t276
  %t277 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t277
  %t278 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t279 = load i8*, i8** %t278
  %t280 = call i32 @ReleaseSemaphore(i8* %t279, i32 1, i32* null)
  %t281 = mul i64 %t266, 1
  %t282 = sdiv i64 %t281, 4
  %t283 = mul i64 %t266, 2
  %t284 = sdiv i64 %t283, 4
  %t286 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t285, i32 0, i32 0
  store i64 %t282, i64* %t286
  %t287 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t285, i32 0, i32 1
  store i64 %t284, i64* %t287
  %t288 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t285, i32 0, i32 2
  store %Enemy* %t189, %Enemy** %t288
  %t289 = bitcast { i64, i64, %Enemy* }* %t285 to i8*
  %t290 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t289, i8** %t290
  %t291 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t291
  %t292 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t293 = load i8*, i8** %t292
  %t294 = call i32 @ReleaseSemaphore(i8* %t293, i32 1, i32* null)
  %t295 = mul i64 %t266, 2
  %t296 = sdiv i64 %t295, 4
  %t297 = mul i64 %t266, 3
  %t298 = sdiv i64 %t297, 4
  %t300 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t299, i32 0, i32 0
  store i64 %t296, i64* %t300
  %t301 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t299, i32 0, i32 1
  store i64 %t298, i64* %t301
  %t302 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t299, i32 0, i32 2
  store %Enemy* %t189, %Enemy** %t302
  %t303 = bitcast { i64, i64, %Enemy* }* %t299 to i8*
  %t304 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t303, i8** %t304
  %t305 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t305
  %t306 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t307 = load i8*, i8** %t306
  %t308 = call i32 @ReleaseSemaphore(i8* %t307, i32 1, i32* null)
  %t309 = mul i64 %t266, 3
  %t310 = sdiv i64 %t309, 4
  %t311 = mul i64 %t266, 4
  %t312 = sdiv i64 %t311, 4
  %t314 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t313, i32 0, i32 0
  store i64 %t310, i64* %t314
  %t315 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t313, i32 0, i32 1
  store i64 %t312, i64* %t315
  %t316 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t313, i32 0, i32 2
  store %Enemy* %t189, %Enemy** %t316
  %t317 = bitcast { i64, i64, %Enemy* }* %t313 to i8*
  %t318 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t317, i8** %t318
  %t319 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t319
  %t320 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t321 = load i8*, i8** %t320
  %t322 = call i32 @ReleaseSemaphore(i8* %t321, i32 1, i32* null)
  %t323 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t324 = load i8*, i8** %t323
  %t325 = call i32 @WaitForSingleObject(i8* %t324, i32 -1)
  %t326 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t327 = load i8*, i8** %t326
  %t328 = call i32 @WaitForSingleObject(i8* %t327, i32 -1)
  %t329 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t330 = load i8*, i8** %t329
  %t331 = call i32 @WaitForSingleObject(i8* %t330, i32 -1)
  %t332 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t333 = load i8*, i8** %t332
  %t334 = call i32 @WaitForSingleObject(i8* %t333, i32 -1)
  br label %par_join_73
par_serial_69:
  %t335 = load i32, i32* @par.pool.serial_owner
  %t336 = icmp eq i32 %t335, %t264
  br i1 %t336, label %par_run_71, label %par_acquire_70
par_acquire_70:
  %t337 = load i8*, i8** @par.pool.serial_lock
  %t338 = call i32 @WaitForSingleObject(i8* %t337, i32 -1)
  store i32 %t264, i32* @par.pool.serial_owner
  br label %par_run_71
par_run_71:
  %t339 = load i64, i64* @arena.Bullets.count
  %t341 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t340, i32 0, i32 0
  store i64 0, i64* %t341
  %t342 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t340, i32 0, i32 1
  store i64 %t339, i64* %t342
  %t343 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t340, i32 0, i32 2
  store %Enemy* %t189, %Enemy** %t343
  %t344 = bitcast { i64, i64, %Enemy* }* %t340 to i8*
  %t345 = call i32 @par_worker_62(i8* %t344)
  br i1 %t336, label %par_join_73, label %par_release_72
par_release_72:
  store i32 -1, i32* @par.pool.serial_owner
  %t346 = load i8*, i8** @par.pool.serial_lock
  %t347 = call i32 @ReleaseSemaphore(i8* %t346, i32 1, i32* null)
  br label %par_join_73
par_join_73:
  br label %par_incr_60
par_incr_60:
  %t348 = add i64 %t183, 1
  store i64 %t348, i64* %t182
  br label %par_cond_57
par_end_61:
  ret i32 0
}


define i32 @par_worker_80(i8* %argp) {
entry:
  %t450 = alloca i64
  %t444 = bitcast i8* %argp to { i64, i64 }*
  %t445 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t444, i32 0, i32 0
  %t446 = load i64, i64* %t445
  %t447 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t444, i32 0, i32 1
  %t448 = load i64, i64* %t447
  %t449 = load %Bullet*, %Bullet** @arena.Bullets.data
  store i64 %t446, i64* %t450
  br label %par_cond_81
par_cond_81:
  %t451 = load i64, i64* %t450
  %t452 = icmp slt i64 %t451, %t448
  br i1 %t452, label %par_body_82, label %par_end_85
par_body_82:
  %t453 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t451
  %t454 = load i32, i32* %t453
  %t455 = and i32 %t454, 1
  %t456 = icmp eq i32 %t455, 1
  br i1 %t456, label %par_live_83, label %par_incr_84
par_live_83:
  %t457 = getelementptr inbounds %Bullet, %Bullet* %t449, i64 %t451
  %t458 = getelementptr inbounds %Bullet, %Bullet* %t457, i32 0, i32 0
  %t459 = load i32, i32* %t458
  %t460 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t460, i32 %t459)
  br label %par_incr_84
par_incr_84:
  %t461 = add i64 %t451, 1
  store i64 %t461, i64* %t450
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
