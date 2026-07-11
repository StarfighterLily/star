; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)
declare i32 @puts(i8*)
declare noalias i8* @malloc(i64)
declare void @free(i8*)
declare void @exit(i32) noreturn
declare i32 @strlen(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare i8* @strcpy(i8*, i8*)
declare i8* @strcat(i8*, i8*)
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

define i32 @main() {
entry:
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
  %t319 = call i32 @GetCurrentThreadId()
  %t320 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t321 = load i32, i32* %t320
  %t322 = icmp eq i32 %t319, %t321
  %t323 = select i1 %t322, i32 0, i32 -1
  %t324 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t325 = load i32, i32* %t324
  %t326 = icmp eq i32 %t319, %t325
  %t327 = select i1 %t326, i32 1, i32 %t323
  %t328 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t329 = load i32, i32* %t328
  %t330 = icmp eq i32 %t319, %t329
  %t331 = select i1 %t330, i32 2, i32 %t327
  %t332 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t333 = load i32, i32* %t332
  %t334 = icmp eq i32 %t319, %t333
  %t335 = select i1 %t334, i32 3, i32 %t331
  %t336 = icmp sge i32 %t335, 0
  br i1 %t336, label %par_serial_71, label %par_pooled_70
par_pooled_70:
  %t337 = load i64, i64* @arena.Enemies.count
  %t338 = mul i64 %t337, 0
  %t339 = sdiv i64 %t338, 4
  %t340 = mul i64 %t337, 1
  %t341 = sdiv i64 %t340, 4
  %t342 = alloca { i64, i64 }
  %t343 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t342, i32 0, i32 0
  store i64 %t339, i64* %t343
  %t344 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t342, i32 0, i32 1
  store i64 %t341, i64* %t344
  %t345 = bitcast { i64, i64 }* %t342 to i8*
  %t346 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t345, i8** %t346
  %t347 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t347
  %t348 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t349 = load i8*, i8** %t348
  %t350 = call i32 @ReleaseSemaphore(i8* %t349, i32 1, i32* null)
  %t351 = mul i64 %t337, 1
  %t352 = sdiv i64 %t351, 4
  %t353 = mul i64 %t337, 2
  %t354 = sdiv i64 %t353, 4
  %t355 = alloca { i64, i64 }
  %t356 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t355, i32 0, i32 0
  store i64 %t352, i64* %t356
  %t357 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t355, i32 0, i32 1
  store i64 %t354, i64* %t357
  %t358 = bitcast { i64, i64 }* %t355 to i8*
  %t359 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t358, i8** %t359
  %t360 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t360
  %t361 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t362 = load i8*, i8** %t361
  %t363 = call i32 @ReleaseSemaphore(i8* %t362, i32 1, i32* null)
  %t364 = mul i64 %t337, 2
  %t365 = sdiv i64 %t364, 4
  %t366 = mul i64 %t337, 3
  %t367 = sdiv i64 %t366, 4
  %t368 = alloca { i64, i64 }
  %t369 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t368, i32 0, i32 0
  store i64 %t365, i64* %t369
  %t370 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t368, i32 0, i32 1
  store i64 %t367, i64* %t370
  %t371 = bitcast { i64, i64 }* %t368 to i8*
  %t372 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t371, i8** %t372
  %t373 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t373
  %t374 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t375 = load i8*, i8** %t374
  %t376 = call i32 @ReleaseSemaphore(i8* %t375, i32 1, i32* null)
  %t377 = mul i64 %t337, 3
  %t378 = sdiv i64 %t377, 4
  %t379 = mul i64 %t337, 4
  %t380 = sdiv i64 %t379, 4
  %t381 = alloca { i64, i64 }
  %t382 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t381, i32 0, i32 0
  store i64 %t378, i64* %t382
  %t383 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t381, i32 0, i32 1
  store i64 %t380, i64* %t383
  %t384 = bitcast { i64, i64 }* %t381 to i8*
  %t385 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t384, i8** %t385
  %t386 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t386
  %t387 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t388 = load i8*, i8** %t387
  %t389 = call i32 @ReleaseSemaphore(i8* %t388, i32 1, i32* null)
  %t390 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t391 = load i8*, i8** %t390
  %t392 = call i32 @WaitForSingleObject(i8* %t391, i32 -1)
  %t393 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t394 = load i8*, i8** %t393
  %t395 = call i32 @WaitForSingleObject(i8* %t394, i32 -1)
  %t396 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t397 = load i8*, i8** %t396
  %t398 = call i32 @WaitForSingleObject(i8* %t397, i32 -1)
  %t399 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t400 = load i8*, i8** %t399
  %t401 = call i32 @WaitForSingleObject(i8* %t400, i32 -1)
  br label %par_join_75
par_serial_71:
  %t402 = load i32, i32* @par.pool.serial_owner
  %t403 = icmp eq i32 %t402, %t335
  br i1 %t403, label %par_run_73, label %par_acquire_72
par_acquire_72:
  %t404 = load i8*, i8** @par.pool.serial_lock
  %t405 = call i32 @WaitForSingleObject(i8* %t404, i32 -1)
  store i32 %t335, i32* @par.pool.serial_owner
  br label %par_run_73
par_run_73:
  %t406 = load i64, i64* @arena.Enemies.count
  %t407 = alloca { i64, i64 }
  %t408 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t407, i32 0, i32 0
  store i64 0, i64* %t408
  %t409 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t407, i32 0, i32 1
  store i64 %t406, i64* %t409
  %t410 = bitcast { i64, i64 }* %t407 to i8*
  %t411 = call i32 @par_worker_56(i8* %t410)
  br i1 %t403, label %par_join_75, label %par_release_74
par_release_74:
  store i32 -1, i32* @par.pool.serial_owner
  %t412 = load i8*, i8** @par.pool.serial_lock
  %t413 = call i32 @ReleaseSemaphore(i8* %t412, i32 1, i32* null)
  br label %par_join_75
par_join_75:
  call void @par.pool.ensure_init()
  %t428 = call i32 @GetCurrentThreadId()
  %t429 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t430 = load i32, i32* %t429
  %t431 = icmp eq i32 %t428, %t430
  %t432 = select i1 %t431, i32 0, i32 -1
  %t433 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t434 = load i32, i32* %t433
  %t435 = icmp eq i32 %t428, %t434
  %t436 = select i1 %t435, i32 1, i32 %t432
  %t437 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t438 = load i32, i32* %t437
  %t439 = icmp eq i32 %t428, %t438
  %t440 = select i1 %t439, i32 2, i32 %t436
  %t441 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t442 = load i32, i32* %t441
  %t443 = icmp eq i32 %t428, %t442
  %t444 = select i1 %t443, i32 3, i32 %t440
  %t445 = icmp sge i32 %t444, 0
  br i1 %t445, label %par_serial_81, label %par_pooled_80
par_pooled_80:
  %t446 = load i64, i64* @arena.Bullets.count
  %t447 = mul i64 %t446, 0
  %t448 = sdiv i64 %t447, 4
  %t449 = mul i64 %t446, 1
  %t450 = sdiv i64 %t449, 4
  %t451 = alloca { i64, i64 }
  %t452 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t451, i32 0, i32 0
  store i64 %t448, i64* %t452
  %t453 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t451, i32 0, i32 1
  store i64 %t450, i64* %t453
  %t454 = bitcast { i64, i64 }* %t451 to i8*
  %t455 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t454, i8** %t455
  %t456 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_76, i32 (i8*)** %t456
  %t457 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t458 = load i8*, i8** %t457
  %t459 = call i32 @ReleaseSemaphore(i8* %t458, i32 1, i32* null)
  %t460 = mul i64 %t446, 1
  %t461 = sdiv i64 %t460, 4
  %t462 = mul i64 %t446, 2
  %t463 = sdiv i64 %t462, 4
  %t464 = alloca { i64, i64 }
  %t465 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t464, i32 0, i32 0
  store i64 %t461, i64* %t465
  %t466 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t464, i32 0, i32 1
  store i64 %t463, i64* %t466
  %t467 = bitcast { i64, i64 }* %t464 to i8*
  %t468 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t467, i8** %t468
  %t469 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_76, i32 (i8*)** %t469
  %t470 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t471 = load i8*, i8** %t470
  %t472 = call i32 @ReleaseSemaphore(i8* %t471, i32 1, i32* null)
  %t473 = mul i64 %t446, 2
  %t474 = sdiv i64 %t473, 4
  %t475 = mul i64 %t446, 3
  %t476 = sdiv i64 %t475, 4
  %t477 = alloca { i64, i64 }
  %t478 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t477, i32 0, i32 0
  store i64 %t474, i64* %t478
  %t479 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t477, i32 0, i32 1
  store i64 %t476, i64* %t479
  %t480 = bitcast { i64, i64 }* %t477 to i8*
  %t481 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t480, i8** %t481
  %t482 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_76, i32 (i8*)** %t482
  %t483 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t484 = load i8*, i8** %t483
  %t485 = call i32 @ReleaseSemaphore(i8* %t484, i32 1, i32* null)
  %t486 = mul i64 %t446, 3
  %t487 = sdiv i64 %t486, 4
  %t488 = mul i64 %t446, 4
  %t489 = sdiv i64 %t488, 4
  %t490 = alloca { i64, i64 }
  %t491 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t490, i32 0, i32 0
  store i64 %t487, i64* %t491
  %t492 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t490, i32 0, i32 1
  store i64 %t489, i64* %t492
  %t493 = bitcast { i64, i64 }* %t490 to i8*
  %t494 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t493, i8** %t494
  %t495 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_76, i32 (i8*)** %t495
  %t496 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t497 = load i8*, i8** %t496
  %t498 = call i32 @ReleaseSemaphore(i8* %t497, i32 1, i32* null)
  %t499 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t500 = load i8*, i8** %t499
  %t501 = call i32 @WaitForSingleObject(i8* %t500, i32 -1)
  %t502 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t503 = load i8*, i8** %t502
  %t504 = call i32 @WaitForSingleObject(i8* %t503, i32 -1)
  %t505 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t506 = load i8*, i8** %t505
  %t507 = call i32 @WaitForSingleObject(i8* %t506, i32 -1)
  %t508 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t509 = load i8*, i8** %t508
  %t510 = call i32 @WaitForSingleObject(i8* %t509, i32 -1)
  br label %par_join_85
par_serial_81:
  %t511 = load i32, i32* @par.pool.serial_owner
  %t512 = icmp eq i32 %t511, %t444
  br i1 %t512, label %par_run_83, label %par_acquire_82
par_acquire_82:
  %t513 = load i8*, i8** @par.pool.serial_lock
  %t514 = call i32 @WaitForSingleObject(i8* %t513, i32 -1)
  store i32 %t444, i32* @par.pool.serial_owner
  br label %par_run_83
par_run_83:
  %t515 = load i64, i64* @arena.Bullets.count
  %t516 = alloca { i64, i64 }
  %t517 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t516, i32 0, i32 0
  store i64 0, i64* %t517
  %t518 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t516, i32 0, i32 1
  store i64 %t515, i64* %t518
  %t519 = bitcast { i64, i64 }* %t516 to i8*
  %t520 = call i32 @par_worker_76(i8* %t519)
  br i1 %t512, label %par_join_85, label %par_release_84
par_release_84:
  store i32 -1, i32* @par.pool.serial_owner
  %t521 = load i8*, i8** @par.pool.serial_lock
  %t522 = call i32 @ReleaseSemaphore(i8* %t521, i32 1, i32* null)
  br label %par_join_85
par_join_85:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_60(i8* %argp) {
entry:
  %t164 = bitcast i8* %argp to { i64, i64, %Enemy* }*
  %t165 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t164, i32 0, i32 0
  %t166 = load i64, i64* %t165
  %t167 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t164, i32 0, i32 1
  %t168 = load i64, i64* %t167
  %t169 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t164, i32 0, i32 2
  %t170 = load %Enemy*, %Enemy** %t169
  %t171 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t172 = alloca i64
  store i64 %t166, i64* %t172
  br label %par_cond_61
par_cond_61:
  %t173 = load i64, i64* %t172
  %t174 = icmp slt i64 %t173, %t168
  br i1 %t174, label %par_body_62, label %par_end_63
par_body_62:
  %t175 = getelementptr inbounds %Bullet, %Bullet* %t171, i64 %t173
  %t176 = getelementptr inbounds %Bullet, %Bullet* %t175, i32 0, i32 0
  %t177 = load i32, i32* %t176
  %t178 = add i32 %t177, 1
  %t179 = getelementptr inbounds %Bullet, %Bullet* %t175, i32 0, i32 0
  store i32 %t178, i32* %t179
  %t180 = add i64 %t173, 1
  store i64 %t180, i64* %t172
  br label %par_cond_61
par_end_63:
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
  %t181 = ptrtoint i8* %idx_arg to i64
  %t182 = trunc i64 %t181 to i32
  %t183 = call i32 @GetCurrentThreadId()
  %t184 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t182
  store i32 %t183, i32* %t184
  br label %loop
loop:
  %t185 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t182
  %t186 = load i8*, i8** %t185
  %t187 = call i32 @WaitForSingleObject(i8* %t186, i32 -1)
  %t188 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t182
  %t189 = load i32 (i8*)*, i32 (i8*)** %t188
  %t190 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t182
  %t191 = load i8*, i8** %t190
  %t192 = call i32 %t189(i8* %t191)
  %t193 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t182
  %t194 = load i8*, i8** %t193
  %t195 = call i32 @ReleaseSemaphore(i8* %t194, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t196 = load i1, i1* @par.pool.inited
  br i1 %t196, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t197 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t197, i8** @par.pool.serial_lock
  %t198 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t199 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t198, i8** %t199
  %t200 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t201 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t200, i8** %t201
  %t202 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t203 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t204 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t203, i8** %t204
  %t205 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t206 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t205, i8** %t206
  %t207 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t208 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t209 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t208, i8** %t209
  %t210 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t211 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t210, i8** %t211
  %t212 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t213 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t214 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t213, i8** %t214
  %t215 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t216 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t215, i8** %t216
  %t217 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
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
  br i1 %t162, label %par_body_58, label %par_end_59
par_body_58:
  %t163 = getelementptr inbounds %Enemy, %Enemy* %t159, i64 %t161
  call void @par.pool.ensure_init()
  %t218 = call i32 @GetCurrentThreadId()
  %t219 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t220 = load i32, i32* %t219
  %t221 = icmp eq i32 %t218, %t220
  %t222 = select i1 %t221, i32 0, i32 -1
  %t223 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t224 = load i32, i32* %t223
  %t225 = icmp eq i32 %t218, %t224
  %t226 = select i1 %t225, i32 1, i32 %t222
  %t227 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t228 = load i32, i32* %t227
  %t229 = icmp eq i32 %t218, %t228
  %t230 = select i1 %t229, i32 2, i32 %t226
  %t231 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t232 = load i32, i32* %t231
  %t233 = icmp eq i32 %t218, %t232
  %t234 = select i1 %t233, i32 3, i32 %t230
  %t235 = icmp sge i32 %t234, 0
  br i1 %t235, label %par_serial_65, label %par_pooled_64
par_pooled_64:
  %t236 = load i64, i64* @arena.Bullets.count
  %t237 = mul i64 %t236, 0
  %t238 = sdiv i64 %t237, 4
  %t239 = mul i64 %t236, 1
  %t240 = sdiv i64 %t239, 4
  %t241 = alloca { i64, i64, %Enemy* }
  %t242 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t241, i32 0, i32 0
  store i64 %t238, i64* %t242
  %t243 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t241, i32 0, i32 1
  store i64 %t240, i64* %t243
  %t244 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t241, i32 0, i32 2
  store %Enemy* %t163, %Enemy** %t244
  %t245 = bitcast { i64, i64, %Enemy* }* %t241 to i8*
  %t246 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t245, i8** %t246
  %t247 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_60, i32 (i8*)** %t247
  %t248 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t249 = load i8*, i8** %t248
  %t250 = call i32 @ReleaseSemaphore(i8* %t249, i32 1, i32* null)
  %t251 = mul i64 %t236, 1
  %t252 = sdiv i64 %t251, 4
  %t253 = mul i64 %t236, 2
  %t254 = sdiv i64 %t253, 4
  %t255 = alloca { i64, i64, %Enemy* }
  %t256 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t255, i32 0, i32 0
  store i64 %t252, i64* %t256
  %t257 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t255, i32 0, i32 1
  store i64 %t254, i64* %t257
  %t258 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t255, i32 0, i32 2
  store %Enemy* %t163, %Enemy** %t258
  %t259 = bitcast { i64, i64, %Enemy* }* %t255 to i8*
  %t260 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t259, i8** %t260
  %t261 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_60, i32 (i8*)** %t261
  %t262 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t263 = load i8*, i8** %t262
  %t264 = call i32 @ReleaseSemaphore(i8* %t263, i32 1, i32* null)
  %t265 = mul i64 %t236, 2
  %t266 = sdiv i64 %t265, 4
  %t267 = mul i64 %t236, 3
  %t268 = sdiv i64 %t267, 4
  %t269 = alloca { i64, i64, %Enemy* }
  %t270 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t269, i32 0, i32 0
  store i64 %t266, i64* %t270
  %t271 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t269, i32 0, i32 1
  store i64 %t268, i64* %t271
  %t272 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t269, i32 0, i32 2
  store %Enemy* %t163, %Enemy** %t272
  %t273 = bitcast { i64, i64, %Enemy* }* %t269 to i8*
  %t274 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t273, i8** %t274
  %t275 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_60, i32 (i8*)** %t275
  %t276 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t277 = load i8*, i8** %t276
  %t278 = call i32 @ReleaseSemaphore(i8* %t277, i32 1, i32* null)
  %t279 = mul i64 %t236, 3
  %t280 = sdiv i64 %t279, 4
  %t281 = mul i64 %t236, 4
  %t282 = sdiv i64 %t281, 4
  %t283 = alloca { i64, i64, %Enemy* }
  %t284 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t283, i32 0, i32 0
  store i64 %t280, i64* %t284
  %t285 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t283, i32 0, i32 1
  store i64 %t282, i64* %t285
  %t286 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t283, i32 0, i32 2
  store %Enemy* %t163, %Enemy** %t286
  %t287 = bitcast { i64, i64, %Enemy* }* %t283 to i8*
  %t288 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t287, i8** %t288
  %t289 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_60, i32 (i8*)** %t289
  %t290 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t291 = load i8*, i8** %t290
  %t292 = call i32 @ReleaseSemaphore(i8* %t291, i32 1, i32* null)
  %t293 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t294 = load i8*, i8** %t293
  %t295 = call i32 @WaitForSingleObject(i8* %t294, i32 -1)
  %t296 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t297 = load i8*, i8** %t296
  %t298 = call i32 @WaitForSingleObject(i8* %t297, i32 -1)
  %t299 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t300 = load i8*, i8** %t299
  %t301 = call i32 @WaitForSingleObject(i8* %t300, i32 -1)
  %t302 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t303 = load i8*, i8** %t302
  %t304 = call i32 @WaitForSingleObject(i8* %t303, i32 -1)
  br label %par_join_69
par_serial_65:
  %t305 = load i32, i32* @par.pool.serial_owner
  %t306 = icmp eq i32 %t305, %t234
  br i1 %t306, label %par_run_67, label %par_acquire_66
par_acquire_66:
  %t307 = load i8*, i8** @par.pool.serial_lock
  %t308 = call i32 @WaitForSingleObject(i8* %t307, i32 -1)
  store i32 %t234, i32* @par.pool.serial_owner
  br label %par_run_67
par_run_67:
  %t309 = load i64, i64* @arena.Bullets.count
  %t310 = alloca { i64, i64, %Enemy* }
  %t311 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t310, i32 0, i32 0
  store i64 0, i64* %t311
  %t312 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t310, i32 0, i32 1
  store i64 %t309, i64* %t312
  %t313 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t310, i32 0, i32 2
  store %Enemy* %t163, %Enemy** %t313
  %t314 = bitcast { i64, i64, %Enemy* }* %t310 to i8*
  %t315 = call i32 @par_worker_60(i8* %t314)
  br i1 %t306, label %par_join_69, label %par_release_68
par_release_68:
  store i32 -1, i32* @par.pool.serial_owner
  %t316 = load i8*, i8** @par.pool.serial_lock
  %t317 = call i32 @ReleaseSemaphore(i8* %t316, i32 1, i32* null)
  br label %par_join_69
par_join_69:
  %t318 = add i64 %t161, 1
  store i64 %t318, i64* %t160
  br label %par_cond_57
par_end_59:
  ret i32 0
}


define i32 @par_worker_76(i8* %argp) {
entry:
  %t414 = bitcast i8* %argp to { i64, i64 }*
  %t415 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t414, i32 0, i32 0
  %t416 = load i64, i64* %t415
  %t417 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t414, i32 0, i32 1
  %t418 = load i64, i64* %t417
  %t419 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t420 = alloca i64
  store i64 %t416, i64* %t420
  br label %par_cond_77
par_cond_77:
  %t421 = load i64, i64* %t420
  %t422 = icmp slt i64 %t421, %t418
  br i1 %t422, label %par_body_78, label %par_end_79
par_body_78:
  %t423 = getelementptr inbounds %Bullet, %Bullet* %t419, i64 %t421
  %t424 = getelementptr inbounds %Bullet, %Bullet* %t423, i32 0, i32 0
  %t425 = load i32, i32* %t424
  %t426 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t426, i32 %t425)
  %t427 = add i64 %t421, 1
  store i64 %t427, i64* %t420
  br label %par_cond_77
par_end_79:
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
