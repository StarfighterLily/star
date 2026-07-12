; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i32 @getchar()
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
declare i8* @fopen(i8*, i8*)
declare i32 @fclose(i8*)
declare i64 @fread(i8*, i64, i64, i8*)
declare i64 @fwrite(i8*, i64, i64, i8*)
declare i32 @fseek(i8*, i32, i32)
declare i32 @ftell(i8*)
declare i32 @fgetc(i8*)
declare i8* @getenv(i8*)
declare i32 @_putenv(i8*)
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
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t1 = icmp eq %Enemy* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = call i8* @malloc(i64 4096)
  %t3 = bitcast i8* %t2 to %Enemy*
  store %Enemy* %t3, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t4 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t5 = load i64, i64* @arena.Enemies.free_top
  %t6 = icmp sgt i64 %t5, 0
  br i1 %t6, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t7 = sub i64 %t5, 1
  store i64 %t7, i64* @arena.Enemies.free_top
  %t8 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t7
  %t9 = load i64, i64* %t8
  br label %spawn_store_4
spawn_grow_3:
  %t10 = load i64, i64* @arena.Enemies.count
  %t11 = icmp slt i64 %t10, 1024
  br i1 %t11, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t12 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t12)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t13 = add i64 %t10, 1
  store i64 %t13, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t14 = phi i64 [ %t9, %spawn_reuse_2 ], [ %t10, %spawn_grow_ok_6 ]
  %t15 = alloca %Enemy
  %t16 = getelementptr inbounds %Enemy, %Enemy* %t15, i32 0, i32 0
  store i32 10, i32* %t16
  %t17 = load %Enemy, %Enemy* %t15
  %t18 = getelementptr inbounds %Enemy, %Enemy* %t4, i64 %t14
  store %Enemy %t17, %Enemy* %t18
  %t19 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t14
  %t20 = load i32, i32* %t19
  %t21 = add i32 %t20, 1
  store i32 %t21, i32* %t19
  br label %spawn_end_5
spawn_end_5:
  %t22 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t23 = icmp eq %Enemy* %t22, null
  br i1 %t23, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t24 = call i8* @malloc(i64 4096)
  %t25 = bitcast i8* %t24 to %Enemy*
  store %Enemy* %t25, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t26 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t27 = load i64, i64* @arena.Enemies.free_top
  %t28 = icmp sgt i64 %t27, 0
  br i1 %t28, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t29 = sub i64 %t27, 1
  store i64 %t29, i64* @arena.Enemies.free_top
  %t30 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t29
  %t31 = load i64, i64* %t30
  br label %spawn_store_12
spawn_grow_11:
  %t32 = load i64, i64* @arena.Enemies.count
  %t33 = icmp slt i64 %t32, 1024
  br i1 %t33, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t34 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t34)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t35 = add i64 %t32, 1
  store i64 %t35, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t36 = phi i64 [ %t31, %spawn_reuse_10 ], [ %t32, %spawn_grow_ok_14 ]
  %t37 = alloca %Enemy
  %t38 = getelementptr inbounds %Enemy, %Enemy* %t37, i32 0, i32 0
  store i32 10, i32* %t38
  %t39 = load %Enemy, %Enemy* %t37
  %t40 = getelementptr inbounds %Enemy, %Enemy* %t26, i64 %t36
  store %Enemy %t39, %Enemy* %t40
  %t41 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t36
  %t42 = load i32, i32* %t41
  %t43 = add i32 %t42, 1
  store i32 %t43, i32* %t41
  br label %spawn_end_13
spawn_end_13:
  %t44 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t45 = icmp eq %Enemy* %t44, null
  br i1 %t45, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t46 = call i8* @malloc(i64 4096)
  %t47 = bitcast i8* %t46 to %Enemy*
  store %Enemy* %t47, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t48 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t49 = load i64, i64* @arena.Enemies.free_top
  %t50 = icmp sgt i64 %t49, 0
  br i1 %t50, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t51 = sub i64 %t49, 1
  store i64 %t51, i64* @arena.Enemies.free_top
  %t52 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t51
  %t53 = load i64, i64* %t52
  br label %spawn_store_20
spawn_grow_19:
  %t54 = load i64, i64* @arena.Enemies.count
  %t55 = icmp slt i64 %t54, 1024
  br i1 %t55, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t56 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t56)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t57 = add i64 %t54, 1
  store i64 %t57, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t58 = phi i64 [ %t53, %spawn_reuse_18 ], [ %t54, %spawn_grow_ok_22 ]
  %t59 = alloca %Enemy
  %t60 = getelementptr inbounds %Enemy, %Enemy* %t59, i32 0, i32 0
  store i32 10, i32* %t60
  %t61 = load %Enemy, %Enemy* %t59
  %t62 = getelementptr inbounds %Enemy, %Enemy* %t48, i64 %t58
  store %Enemy %t61, %Enemy* %t62
  %t63 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t58
  %t64 = load i32, i32* %t63
  %t65 = add i32 %t64, 1
  store i32 %t65, i32* %t63
  br label %spawn_end_21
spawn_end_21:
  %t66 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t67 = icmp eq %Bullet* %t66, null
  br i1 %t67, label %spawn_init_24, label %spawn_ready_25
spawn_init_24:
  %t68 = call i8* @malloc(i64 4096)
  %t69 = bitcast i8* %t68 to %Bullet*
  store %Bullet* %t69, %Bullet** @arena.Bullets.data
  br label %spawn_ready_25
spawn_ready_25:
  %t70 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t71 = load i64, i64* @arena.Bullets.free_top
  %t72 = icmp sgt i64 %t71, 0
  br i1 %t72, label %spawn_reuse_26, label %spawn_grow_27
spawn_reuse_26:
  %t73 = sub i64 %t71, 1
  store i64 %t73, i64* @arena.Bullets.free_top
  %t74 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t73
  %t75 = load i64, i64* %t74
  br label %spawn_store_28
spawn_grow_27:
  %t76 = load i64, i64* @arena.Bullets.count
  %t77 = icmp slt i64 %t76, 1024
  br i1 %t77, label %spawn_grow_ok_30, label %spawn_capacity_warn_31
spawn_capacity_warn_31:
  %t78 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t78)
  br label %spawn_end_29
spawn_grow_ok_30:
  %t79 = add i64 %t76, 1
  store i64 %t79, i64* @arena.Bullets.count
  br label %spawn_store_28
spawn_store_28:
  %t80 = phi i64 [ %t75, %spawn_reuse_26 ], [ %t76, %spawn_grow_ok_30 ]
  %t81 = alloca %Bullet
  %t82 = getelementptr inbounds %Bullet, %Bullet* %t81, i32 0, i32 0
  store i32 0, i32* %t82
  %t83 = load %Bullet, %Bullet* %t81
  %t84 = getelementptr inbounds %Bullet, %Bullet* %t70, i64 %t80
  store %Bullet %t83, %Bullet* %t84
  %t85 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t80
  %t86 = load i32, i32* %t85
  %t87 = add i32 %t86, 1
  store i32 %t87, i32* %t85
  br label %spawn_end_29
spawn_end_29:
  %t88 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t89 = icmp eq %Bullet* %t88, null
  br i1 %t89, label %spawn_init_32, label %spawn_ready_33
spawn_init_32:
  %t90 = call i8* @malloc(i64 4096)
  %t91 = bitcast i8* %t90 to %Bullet*
  store %Bullet* %t91, %Bullet** @arena.Bullets.data
  br label %spawn_ready_33
spawn_ready_33:
  %t92 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t93 = load i64, i64* @arena.Bullets.free_top
  %t94 = icmp sgt i64 %t93, 0
  br i1 %t94, label %spawn_reuse_34, label %spawn_grow_35
spawn_reuse_34:
  %t95 = sub i64 %t93, 1
  store i64 %t95, i64* @arena.Bullets.free_top
  %t96 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t95
  %t97 = load i64, i64* %t96
  br label %spawn_store_36
spawn_grow_35:
  %t98 = load i64, i64* @arena.Bullets.count
  %t99 = icmp slt i64 %t98, 1024
  br i1 %t99, label %spawn_grow_ok_38, label %spawn_capacity_warn_39
spawn_capacity_warn_39:
  %t100 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t100)
  br label %spawn_end_37
spawn_grow_ok_38:
  %t101 = add i64 %t98, 1
  store i64 %t101, i64* @arena.Bullets.count
  br label %spawn_store_36
spawn_store_36:
  %t102 = phi i64 [ %t97, %spawn_reuse_34 ], [ %t98, %spawn_grow_ok_38 ]
  %t103 = alloca %Bullet
  %t104 = getelementptr inbounds %Bullet, %Bullet* %t103, i32 0, i32 0
  store i32 0, i32* %t104
  %t105 = load %Bullet, %Bullet* %t103
  %t106 = getelementptr inbounds %Bullet, %Bullet* %t92, i64 %t102
  store %Bullet %t105, %Bullet* %t106
  %t107 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t102
  %t108 = load i32, i32* %t107
  %t109 = add i32 %t108, 1
  store i32 %t109, i32* %t107
  br label %spawn_end_37
spawn_end_37:
  %t110 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t111 = icmp eq %Bullet* %t110, null
  br i1 %t111, label %spawn_init_40, label %spawn_ready_41
spawn_init_40:
  %t112 = call i8* @malloc(i64 4096)
  %t113 = bitcast i8* %t112 to %Bullet*
  store %Bullet* %t113, %Bullet** @arena.Bullets.data
  br label %spawn_ready_41
spawn_ready_41:
  %t114 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t115 = load i64, i64* @arena.Bullets.free_top
  %t116 = icmp sgt i64 %t115, 0
  br i1 %t116, label %spawn_reuse_42, label %spawn_grow_43
spawn_reuse_42:
  %t117 = sub i64 %t115, 1
  store i64 %t117, i64* @arena.Bullets.free_top
  %t118 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t117
  %t119 = load i64, i64* %t118
  br label %spawn_store_44
spawn_grow_43:
  %t120 = load i64, i64* @arena.Bullets.count
  %t121 = icmp slt i64 %t120, 1024
  br i1 %t121, label %spawn_grow_ok_46, label %spawn_capacity_warn_47
spawn_capacity_warn_47:
  %t122 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t122)
  br label %spawn_end_45
spawn_grow_ok_46:
  %t123 = add i64 %t120, 1
  store i64 %t123, i64* @arena.Bullets.count
  br label %spawn_store_44
spawn_store_44:
  %t124 = phi i64 [ %t119, %spawn_reuse_42 ], [ %t120, %spawn_grow_ok_46 ]
  %t125 = alloca %Bullet
  %t126 = getelementptr inbounds %Bullet, %Bullet* %t125, i32 0, i32 0
  store i32 0, i32* %t126
  %t127 = load %Bullet, %Bullet* %t125
  %t128 = getelementptr inbounds %Bullet, %Bullet* %t114, i64 %t124
  store %Bullet %t127, %Bullet* %t128
  %t129 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t124
  %t130 = load i32, i32* %t129
  %t131 = add i32 %t130, 1
  store i32 %t131, i32* %t129
  br label %spawn_end_45
spawn_end_45:
  %t132 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t133 = icmp eq %Bullet* %t132, null
  br i1 %t133, label %spawn_init_48, label %spawn_ready_49
spawn_init_48:
  %t134 = call i8* @malloc(i64 4096)
  %t135 = bitcast i8* %t134 to %Bullet*
  store %Bullet* %t135, %Bullet** @arena.Bullets.data
  br label %spawn_ready_49
spawn_ready_49:
  %t136 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t137 = load i64, i64* @arena.Bullets.free_top
  %t138 = icmp sgt i64 %t137, 0
  br i1 %t138, label %spawn_reuse_50, label %spawn_grow_51
spawn_reuse_50:
  %t139 = sub i64 %t137, 1
  store i64 %t139, i64* @arena.Bullets.free_top
  %t140 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t139
  %t141 = load i64, i64* %t140
  br label %spawn_store_52
spawn_grow_51:
  %t142 = load i64, i64* @arena.Bullets.count
  %t143 = icmp slt i64 %t142, 1024
  br i1 %t143, label %spawn_grow_ok_54, label %spawn_capacity_warn_55
spawn_capacity_warn_55:
  %t144 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t144)
  br label %spawn_end_53
spawn_grow_ok_54:
  %t145 = add i64 %t142, 1
  store i64 %t145, i64* @arena.Bullets.count
  br label %spawn_store_52
spawn_store_52:
  %t146 = phi i64 [ %t141, %spawn_reuse_50 ], [ %t142, %spawn_grow_ok_54 ]
  %t147 = alloca %Bullet
  %t148 = getelementptr inbounds %Bullet, %Bullet* %t147, i32 0, i32 0
  store i32 0, i32* %t148
  %t149 = load %Bullet, %Bullet* %t147
  %t150 = getelementptr inbounds %Bullet, %Bullet* %t136, i64 %t146
  store %Bullet %t149, %Bullet* %t150
  %t151 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t146
  %t152 = load i32, i32* %t151
  %t153 = add i32 %t152, 1
  store i32 %t153, i32* %t151
  br label %spawn_end_53
spawn_end_53:
  call void @par.pool.ensure_init()
  %t327 = call i32 @GetCurrentThreadId()
  %t328 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t329 = load i32, i32* %t328
  %t330 = icmp eq i32 %t327, %t329
  %t331 = select i1 %t330, i32 0, i32 -1
  %t332 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t333 = load i32, i32* %t332
  %t334 = icmp eq i32 %t327, %t333
  %t335 = select i1 %t334, i32 1, i32 %t331
  %t336 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t337 = load i32, i32* %t336
  %t338 = icmp eq i32 %t327, %t337
  %t339 = select i1 %t338, i32 2, i32 %t335
  %t340 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t341 = load i32, i32* %t340
  %t342 = icmp eq i32 %t327, %t341
  %t343 = select i1 %t342, i32 3, i32 %t339
  %t344 = icmp sge i32 %t343, 0
  br i1 %t344, label %par_serial_75, label %par_pooled_74
par_pooled_74:
  %t345 = load i64, i64* @arena.Enemies.count
  %t346 = mul i64 %t345, 0
  %t347 = sdiv i64 %t346, 4
  %t348 = mul i64 %t345, 1
  %t349 = sdiv i64 %t348, 4
  %t350 = alloca { i64, i64 }
  %t351 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t350, i32 0, i32 0
  store i64 %t347, i64* %t351
  %t352 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t350, i32 0, i32 1
  store i64 %t349, i64* %t352
  %t353 = bitcast { i64, i64 }* %t350 to i8*
  %t354 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t353, i8** %t354
  %t355 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t355
  %t356 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t357 = load i8*, i8** %t356
  %t358 = call i32 @ReleaseSemaphore(i8* %t357, i32 1, i32* null)
  %t359 = mul i64 %t345, 1
  %t360 = sdiv i64 %t359, 4
  %t361 = mul i64 %t345, 2
  %t362 = sdiv i64 %t361, 4
  %t363 = alloca { i64, i64 }
  %t364 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t363, i32 0, i32 0
  store i64 %t360, i64* %t364
  %t365 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t363, i32 0, i32 1
  store i64 %t362, i64* %t365
  %t366 = bitcast { i64, i64 }* %t363 to i8*
  %t367 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t366, i8** %t367
  %t368 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t368
  %t369 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t370 = load i8*, i8** %t369
  %t371 = call i32 @ReleaseSemaphore(i8* %t370, i32 1, i32* null)
  %t372 = mul i64 %t345, 2
  %t373 = sdiv i64 %t372, 4
  %t374 = mul i64 %t345, 3
  %t375 = sdiv i64 %t374, 4
  %t376 = alloca { i64, i64 }
  %t377 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t376, i32 0, i32 0
  store i64 %t373, i64* %t377
  %t378 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t376, i32 0, i32 1
  store i64 %t375, i64* %t378
  %t379 = bitcast { i64, i64 }* %t376 to i8*
  %t380 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t379, i8** %t380
  %t381 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t381
  %t382 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t383 = load i8*, i8** %t382
  %t384 = call i32 @ReleaseSemaphore(i8* %t383, i32 1, i32* null)
  %t385 = mul i64 %t345, 3
  %t386 = sdiv i64 %t385, 4
  %t387 = mul i64 %t345, 4
  %t388 = sdiv i64 %t387, 4
  %t389 = alloca { i64, i64 }
  %t390 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t389, i32 0, i32 0
  store i64 %t386, i64* %t390
  %t391 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t389, i32 0, i32 1
  store i64 %t388, i64* %t391
  %t392 = bitcast { i64, i64 }* %t389 to i8*
  %t393 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t392, i8** %t393
  %t394 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t394
  %t395 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t396 = load i8*, i8** %t395
  %t397 = call i32 @ReleaseSemaphore(i8* %t396, i32 1, i32* null)
  %t398 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t399 = load i8*, i8** %t398
  %t400 = call i32 @WaitForSingleObject(i8* %t399, i32 -1)
  %t401 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t402 = load i8*, i8** %t401
  %t403 = call i32 @WaitForSingleObject(i8* %t402, i32 -1)
  %t404 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t405 = load i8*, i8** %t404
  %t406 = call i32 @WaitForSingleObject(i8* %t405, i32 -1)
  %t407 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t408 = load i8*, i8** %t407
  %t409 = call i32 @WaitForSingleObject(i8* %t408, i32 -1)
  br label %par_join_79
par_serial_75:
  %t410 = load i32, i32* @par.pool.serial_owner
  %t411 = icmp eq i32 %t410, %t343
  br i1 %t411, label %par_run_77, label %par_acquire_76
par_acquire_76:
  %t412 = load i8*, i8** @par.pool.serial_lock
  %t413 = call i32 @WaitForSingleObject(i8* %t412, i32 -1)
  store i32 %t343, i32* @par.pool.serial_owner
  br label %par_run_77
par_run_77:
  %t414 = load i64, i64* @arena.Enemies.count
  %t415 = alloca { i64, i64 }
  %t416 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t415, i32 0, i32 0
  store i64 0, i64* %t416
  %t417 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t415, i32 0, i32 1
  store i64 %t414, i64* %t417
  %t418 = bitcast { i64, i64 }* %t415 to i8*
  %t419 = call i32 @par_worker_56(i8* %t418)
  br i1 %t411, label %par_join_79, label %par_release_78
par_release_78:
  store i32 -1, i32* @par.pool.serial_owner
  %t420 = load i8*, i8** @par.pool.serial_lock
  %t421 = call i32 @ReleaseSemaphore(i8* %t420, i32 1, i32* null)
  br label %par_join_79
par_join_79:
  call void @par.pool.ensure_init()
  %t440 = call i32 @GetCurrentThreadId()
  %t441 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t442 = load i32, i32* %t441
  %t443 = icmp eq i32 %t440, %t442
  %t444 = select i1 %t443, i32 0, i32 -1
  %t445 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t446 = load i32, i32* %t445
  %t447 = icmp eq i32 %t440, %t446
  %t448 = select i1 %t447, i32 1, i32 %t444
  %t449 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t450 = load i32, i32* %t449
  %t451 = icmp eq i32 %t440, %t450
  %t452 = select i1 %t451, i32 2, i32 %t448
  %t453 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t454 = load i32, i32* %t453
  %t455 = icmp eq i32 %t440, %t454
  %t456 = select i1 %t455, i32 3, i32 %t452
  %t457 = icmp sge i32 %t456, 0
  br i1 %t457, label %par_serial_87, label %par_pooled_86
par_pooled_86:
  %t458 = load i64, i64* @arena.Bullets.count
  %t459 = mul i64 %t458, 0
  %t460 = sdiv i64 %t459, 4
  %t461 = mul i64 %t458, 1
  %t462 = sdiv i64 %t461, 4
  %t463 = alloca { i64, i64 }
  %t464 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t463, i32 0, i32 0
  store i64 %t460, i64* %t464
  %t465 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t463, i32 0, i32 1
  store i64 %t462, i64* %t465
  %t466 = bitcast { i64, i64 }* %t463 to i8*
  %t467 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t466, i8** %t467
  %t468 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t468
  %t469 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t470 = load i8*, i8** %t469
  %t471 = call i32 @ReleaseSemaphore(i8* %t470, i32 1, i32* null)
  %t472 = mul i64 %t458, 1
  %t473 = sdiv i64 %t472, 4
  %t474 = mul i64 %t458, 2
  %t475 = sdiv i64 %t474, 4
  %t476 = alloca { i64, i64 }
  %t477 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t476, i32 0, i32 0
  store i64 %t473, i64* %t477
  %t478 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t476, i32 0, i32 1
  store i64 %t475, i64* %t478
  %t479 = bitcast { i64, i64 }* %t476 to i8*
  %t480 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t479, i8** %t480
  %t481 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t481
  %t482 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t483 = load i8*, i8** %t482
  %t484 = call i32 @ReleaseSemaphore(i8* %t483, i32 1, i32* null)
  %t485 = mul i64 %t458, 2
  %t486 = sdiv i64 %t485, 4
  %t487 = mul i64 %t458, 3
  %t488 = sdiv i64 %t487, 4
  %t489 = alloca { i64, i64 }
  %t490 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t489, i32 0, i32 0
  store i64 %t486, i64* %t490
  %t491 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t489, i32 0, i32 1
  store i64 %t488, i64* %t491
  %t492 = bitcast { i64, i64 }* %t489 to i8*
  %t493 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t492, i8** %t493
  %t494 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t494
  %t495 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t496 = load i8*, i8** %t495
  %t497 = call i32 @ReleaseSemaphore(i8* %t496, i32 1, i32* null)
  %t498 = mul i64 %t458, 3
  %t499 = sdiv i64 %t498, 4
  %t500 = mul i64 %t458, 4
  %t501 = sdiv i64 %t500, 4
  %t502 = alloca { i64, i64 }
  %t503 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t502, i32 0, i32 0
  store i64 %t499, i64* %t503
  %t504 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t502, i32 0, i32 1
  store i64 %t501, i64* %t504
  %t505 = bitcast { i64, i64 }* %t502 to i8*
  %t506 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t505, i8** %t506
  %t507 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t507
  %t508 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t509 = load i8*, i8** %t508
  %t510 = call i32 @ReleaseSemaphore(i8* %t509, i32 1, i32* null)
  %t511 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t512 = load i8*, i8** %t511
  %t513 = call i32 @WaitForSingleObject(i8* %t512, i32 -1)
  %t514 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t515 = load i8*, i8** %t514
  %t516 = call i32 @WaitForSingleObject(i8* %t515, i32 -1)
  %t517 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t518 = load i8*, i8** %t517
  %t519 = call i32 @WaitForSingleObject(i8* %t518, i32 -1)
  %t520 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t521 = load i8*, i8** %t520
  %t522 = call i32 @WaitForSingleObject(i8* %t521, i32 -1)
  br label %par_join_91
par_serial_87:
  %t523 = load i32, i32* @par.pool.serial_owner
  %t524 = icmp eq i32 %t523, %t456
  br i1 %t524, label %par_run_89, label %par_acquire_88
par_acquire_88:
  %t525 = load i8*, i8** @par.pool.serial_lock
  %t526 = call i32 @WaitForSingleObject(i8* %t525, i32 -1)
  store i32 %t456, i32* @par.pool.serial_owner
  br label %par_run_89
par_run_89:
  %t527 = load i64, i64* @arena.Bullets.count
  %t528 = alloca { i64, i64 }
  %t529 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t528, i32 0, i32 0
  store i64 0, i64* %t529
  %t530 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t528, i32 0, i32 1
  store i64 %t527, i64* %t530
  %t531 = bitcast { i64, i64 }* %t528 to i8*
  %t532 = call i32 @par_worker_80(i8* %t531)
  br i1 %t524, label %par_join_91, label %par_release_90
par_release_90:
  store i32 -1, i32* @par.pool.serial_owner
  %t533 = load i8*, i8** @par.pool.serial_lock
  %t534 = call i32 @ReleaseSemaphore(i8* %t533, i32 1, i32* null)
  br label %par_join_91
par_join_91:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_62(i8* %argp) {
entry:
  %t168 = bitcast i8* %argp to { i64, i64, %Enemy* }*
  %t169 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t168, i32 0, i32 0
  %t170 = load i64, i64* %t169
  %t171 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t168, i32 0, i32 1
  %t172 = load i64, i64* %t171
  %t173 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t168, i32 0, i32 2
  %t174 = load %Enemy*, %Enemy** %t173
  %t175 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t176 = alloca i64
  store i64 %t170, i64* %t176
  br label %par_cond_63
par_cond_63:
  %t177 = load i64, i64* %t176
  %t178 = icmp slt i64 %t177, %t172
  br i1 %t178, label %par_body_64, label %par_end_67
par_body_64:
  %t179 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t177
  %t180 = load i32, i32* %t179
  %t181 = and i32 %t180, 1
  %t182 = icmp eq i32 %t181, 1
  br i1 %t182, label %par_live_65, label %par_incr_66
par_live_65:
  %t183 = getelementptr inbounds %Bullet, %Bullet* %t175, i64 %t177
  %t184 = getelementptr inbounds %Bullet, %Bullet* %t183, i32 0, i32 0
  %t185 = load i32, i32* %t184
  %t186 = add i32 %t185, 1
  %t187 = getelementptr inbounds %Bullet, %Bullet* %t183, i32 0, i32 0
  store i32 %t186, i32* %t187
  br label %par_incr_66
par_incr_66:
  %t188 = add i64 %t177, 1
  store i64 %t188, i64* %t176
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
  %t189 = ptrtoint i8* %idx_arg to i64
  %t190 = trunc i64 %t189 to i32
  %t191 = call i32 @GetCurrentThreadId()
  %t192 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t190
  store i32 %t191, i32* %t192
  br label %loop
loop:
  %t193 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t190
  %t194 = load i8*, i8** %t193
  %t195 = call i32 @WaitForSingleObject(i8* %t194, i32 -1)
  %t196 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t190
  %t197 = load i32 (i8*)*, i32 (i8*)** %t196
  %t198 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t190
  %t199 = load i8*, i8** %t198
  %t200 = call i32 %t197(i8* %t199)
  %t201 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t190
  %t202 = load i8*, i8** %t201
  %t203 = call i32 @ReleaseSemaphore(i8* %t202, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t204 = load i1, i1* @par.pool.inited
  br i1 %t204, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t205 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t205, i8** @par.pool.serial_lock
  %t206 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t207 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t206, i8** %t207
  %t208 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t209 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t208, i8** %t209
  %t210 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t211 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t212 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t211, i8** %t212
  %t213 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t214 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t213, i8** %t214
  %t215 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t216 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t217 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t216, i8** %t217
  %t218 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t219 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t218, i8** %t219
  %t220 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t221 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t222 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t221, i8** %t222
  %t223 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t224 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t223, i8** %t224
  %t225 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_56(i8* %argp) {
entry:
  %t154 = bitcast i8* %argp to { i64, i64 }*
  %t155 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t154, i32 0, i32 0
  %t156 = load i64, i64* %t155
  %t157 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t154, i32 0, i32 1
  %t158 = load i64, i64* %t157
  %t159 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t160 = alloca i64
  store i64 %t156, i64* %t160
  br label %par_cond_57
par_cond_57:
  %t161 = load i64, i64* %t160
  %t162 = icmp slt i64 %t161, %t158
  br i1 %t162, label %par_body_58, label %par_end_61
par_body_58:
  %t163 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Enemies.gen, i64 0, i64 %t161
  %t164 = load i32, i32* %t163
  %t165 = and i32 %t164, 1
  %t166 = icmp eq i32 %t165, 1
  br i1 %t166, label %par_live_59, label %par_incr_60
par_live_59:
  %t167 = getelementptr inbounds %Enemy, %Enemy* %t159, i64 %t161
  call void @par.pool.ensure_init()
  %t226 = call i32 @GetCurrentThreadId()
  %t227 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t228 = load i32, i32* %t227
  %t229 = icmp eq i32 %t226, %t228
  %t230 = select i1 %t229, i32 0, i32 -1
  %t231 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t232 = load i32, i32* %t231
  %t233 = icmp eq i32 %t226, %t232
  %t234 = select i1 %t233, i32 1, i32 %t230
  %t235 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t236 = load i32, i32* %t235
  %t237 = icmp eq i32 %t226, %t236
  %t238 = select i1 %t237, i32 2, i32 %t234
  %t239 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t240 = load i32, i32* %t239
  %t241 = icmp eq i32 %t226, %t240
  %t242 = select i1 %t241, i32 3, i32 %t238
  %t243 = icmp sge i32 %t242, 0
  br i1 %t243, label %par_serial_69, label %par_pooled_68
par_pooled_68:
  %t244 = load i64, i64* @arena.Bullets.count
  %t245 = mul i64 %t244, 0
  %t246 = sdiv i64 %t245, 4
  %t247 = mul i64 %t244, 1
  %t248 = sdiv i64 %t247, 4
  %t249 = alloca { i64, i64, %Enemy* }
  %t250 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t249, i32 0, i32 0
  store i64 %t246, i64* %t250
  %t251 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t249, i32 0, i32 1
  store i64 %t248, i64* %t251
  %t252 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t249, i32 0, i32 2
  store %Enemy* %t167, %Enemy** %t252
  %t253 = bitcast { i64, i64, %Enemy* }* %t249 to i8*
  %t254 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t253, i8** %t254
  %t255 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t255
  %t256 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t257 = load i8*, i8** %t256
  %t258 = call i32 @ReleaseSemaphore(i8* %t257, i32 1, i32* null)
  %t259 = mul i64 %t244, 1
  %t260 = sdiv i64 %t259, 4
  %t261 = mul i64 %t244, 2
  %t262 = sdiv i64 %t261, 4
  %t263 = alloca { i64, i64, %Enemy* }
  %t264 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t263, i32 0, i32 0
  store i64 %t260, i64* %t264
  %t265 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t263, i32 0, i32 1
  store i64 %t262, i64* %t265
  %t266 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t263, i32 0, i32 2
  store %Enemy* %t167, %Enemy** %t266
  %t267 = bitcast { i64, i64, %Enemy* }* %t263 to i8*
  %t268 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t267, i8** %t268
  %t269 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t269
  %t270 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t271 = load i8*, i8** %t270
  %t272 = call i32 @ReleaseSemaphore(i8* %t271, i32 1, i32* null)
  %t273 = mul i64 %t244, 2
  %t274 = sdiv i64 %t273, 4
  %t275 = mul i64 %t244, 3
  %t276 = sdiv i64 %t275, 4
  %t277 = alloca { i64, i64, %Enemy* }
  %t278 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t277, i32 0, i32 0
  store i64 %t274, i64* %t278
  %t279 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t277, i32 0, i32 1
  store i64 %t276, i64* %t279
  %t280 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t277, i32 0, i32 2
  store %Enemy* %t167, %Enemy** %t280
  %t281 = bitcast { i64, i64, %Enemy* }* %t277 to i8*
  %t282 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t281, i8** %t282
  %t283 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t283
  %t284 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t285 = load i8*, i8** %t284
  %t286 = call i32 @ReleaseSemaphore(i8* %t285, i32 1, i32* null)
  %t287 = mul i64 %t244, 3
  %t288 = sdiv i64 %t287, 4
  %t289 = mul i64 %t244, 4
  %t290 = sdiv i64 %t289, 4
  %t291 = alloca { i64, i64, %Enemy* }
  %t292 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t291, i32 0, i32 0
  store i64 %t288, i64* %t292
  %t293 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t291, i32 0, i32 1
  store i64 %t290, i64* %t293
  %t294 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t291, i32 0, i32 2
  store %Enemy* %t167, %Enemy** %t294
  %t295 = bitcast { i64, i64, %Enemy* }* %t291 to i8*
  %t296 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t295, i8** %t296
  %t297 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t297
  %t298 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t299 = load i8*, i8** %t298
  %t300 = call i32 @ReleaseSemaphore(i8* %t299, i32 1, i32* null)
  %t301 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t302 = load i8*, i8** %t301
  %t303 = call i32 @WaitForSingleObject(i8* %t302, i32 -1)
  %t304 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t305 = load i8*, i8** %t304
  %t306 = call i32 @WaitForSingleObject(i8* %t305, i32 -1)
  %t307 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t308 = load i8*, i8** %t307
  %t309 = call i32 @WaitForSingleObject(i8* %t308, i32 -1)
  %t310 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t311 = load i8*, i8** %t310
  %t312 = call i32 @WaitForSingleObject(i8* %t311, i32 -1)
  br label %par_join_73
par_serial_69:
  %t313 = load i32, i32* @par.pool.serial_owner
  %t314 = icmp eq i32 %t313, %t242
  br i1 %t314, label %par_run_71, label %par_acquire_70
par_acquire_70:
  %t315 = load i8*, i8** @par.pool.serial_lock
  %t316 = call i32 @WaitForSingleObject(i8* %t315, i32 -1)
  store i32 %t242, i32* @par.pool.serial_owner
  br label %par_run_71
par_run_71:
  %t317 = load i64, i64* @arena.Bullets.count
  %t318 = alloca { i64, i64, %Enemy* }
  %t319 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t318, i32 0, i32 0
  store i64 0, i64* %t319
  %t320 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t318, i32 0, i32 1
  store i64 %t317, i64* %t320
  %t321 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t318, i32 0, i32 2
  store %Enemy* %t167, %Enemy** %t321
  %t322 = bitcast { i64, i64, %Enemy* }* %t318 to i8*
  %t323 = call i32 @par_worker_62(i8* %t322)
  br i1 %t314, label %par_join_73, label %par_release_72
par_release_72:
  store i32 -1, i32* @par.pool.serial_owner
  %t324 = load i8*, i8** @par.pool.serial_lock
  %t325 = call i32 @ReleaseSemaphore(i8* %t324, i32 1, i32* null)
  br label %par_join_73
par_join_73:
  br label %par_incr_60
par_incr_60:
  %t326 = add i64 %t161, 1
  store i64 %t326, i64* %t160
  br label %par_cond_57
par_end_61:
  ret i32 0
}


define i32 @par_worker_80(i8* %argp) {
entry:
  %t422 = bitcast i8* %argp to { i64, i64 }*
  %t423 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t422, i32 0, i32 0
  %t424 = load i64, i64* %t423
  %t425 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t422, i32 0, i32 1
  %t426 = load i64, i64* %t425
  %t427 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t428 = alloca i64
  store i64 %t424, i64* %t428
  br label %par_cond_81
par_cond_81:
  %t429 = load i64, i64* %t428
  %t430 = icmp slt i64 %t429, %t426
  br i1 %t430, label %par_body_82, label %par_end_85
par_body_82:
  %t431 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Bullets.gen, i64 0, i64 %t429
  %t432 = load i32, i32* %t431
  %t433 = and i32 %t432, 1
  %t434 = icmp eq i32 %t433, 1
  br i1 %t434, label %par_live_83, label %par_incr_84
par_live_83:
  %t435 = getelementptr inbounds %Bullet, %Bullet* %t427, i64 %t429
  %t436 = getelementptr inbounds %Bullet, %Bullet* %t435, i32 0, i32 0
  %t437 = load i32, i32* %t436
  %t438 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t438, i32 %t437)
  br label %par_incr_84
par_incr_84:
  %t439 = add i64 %t429, 1
  store i64 %t439, i64* %t428
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
