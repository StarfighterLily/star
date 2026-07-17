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

%Entity = type { i32 }
%Entities = type { %Entity*, i64 }
@arena.Entities.data = global %Entity* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t19 = alloca %Entity
  %t64 = alloca %Entity
  %t89 = alloca %Entity
  %t96 = alloca %GenRef
  %t102 = alloca %GenRef
  %t106 = alloca %GenRef
  %t112 = alloca %GenRef
  %t130 = alloca %Entity
  %t149 = alloca %Entity
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = load %Entity*, %Entity** @arena.Entities.data
  %t2 = icmp eq %Entity* %t1, null
  br i1 %t2, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t3 = getelementptr %Entity, %Entity* null, i32 1
  %t4 = ptrtoint %Entity* %t3 to i64
  %t5 = mul i64 %t4, 1024
  %t6 = call i8* @malloc(i64 %t5)
  %t7 = bitcast i8* %t6 to %Entity*
  store %Entity* %t7, %Entity** @arena.Entities.data
  br label %spawn_ready_1
spawn_ready_1:
  %t8 = load %Entity*, %Entity** @arena.Entities.data
  %t9 = load i64, i64* @arena.Entities.free_top
  %t10 = icmp sgt i64 %t9, 0
  br i1 %t10, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t11 = sub i64 %t9, 1
  store i64 %t11, i64* @arena.Entities.free_top
  %t12 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t11
  %t13 = load i64, i64* %t12
  br label %spawn_store_4
spawn_grow_3:
  %t14 = load i64, i64* @arena.Entities.count
  %t15 = icmp slt i64 %t14, 1024
  br i1 %t15, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t16 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t16)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t17 = add i64 %t14, 1
  store i64 %t17, i64* @arena.Entities.count
  br label %spawn_store_4
spawn_store_4:
  %t18 = phi i64 [ %t13, %spawn_reuse_2 ], [ %t14, %spawn_grow_ok_6 ]
  %t20 = getelementptr inbounds %Entity, %Entity* %t19, i32 0, i32 0
  store i32 100, i32* %t20
  %t21 = load %Entity, %Entity* %t19
  %t22 = getelementptr inbounds %Entity, %Entity* %t8, i64 %t18
  store %Entity %t21, %Entity* %t22
  %t23 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t18
  %t24 = load i32, i32* %t23
  %t25 = add i32 %t24, 1
  store i32 %t25, i32* %t23
  br label %spawn_end_5
spawn_end_5:
  %t26 = sext i32 0 to i64
  %t27 = icmp ult i64 %t26, 1024
  br i1 %t27, label %despawn_do_8, label %despawn_end_9
despawn_do_8:
  %t28 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t26
  %t29 = load i32, i32* %t28
  %t30 = and i32 %t29, 1
  %t31 = icmp eq i32 %t30, 1
  br i1 %t31, label %despawn_live_10, label %despawn_end_9
despawn_live_10:
  %t32 = add i32 %t29, 1
  store i32 %t32, i32* %t28
  %t33 = load i64, i64* @arena.Entities.free_top
  %t34 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t33
  store i64 %t26, i64* %t34
  %t35 = add i64 %t33, 1
  store i64 %t35, i64* @arena.Entities.free_top
  br label %despawn_end_9
despawn_end_9:
  %t36 = sext i32 0 to i64
  %t37 = icmp ult i64 %t36, 1024
  br i1 %t37, label %despawn_do_11, label %despawn_end_12
despawn_do_11:
  %t38 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t36
  %t39 = load i32, i32* %t38
  %t40 = and i32 %t39, 1
  %t41 = icmp eq i32 %t40, 1
  br i1 %t41, label %despawn_live_13, label %despawn_end_12
despawn_live_13:
  %t42 = add i32 %t39, 1
  store i32 %t42, i32* %t38
  %t43 = load i64, i64* @arena.Entities.free_top
  %t44 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t43
  store i64 %t36, i64* %t44
  %t45 = add i64 %t43, 1
  store i64 %t45, i64* @arena.Entities.free_top
  br label %despawn_end_12
despawn_end_12:
  %t46 = load %Entity*, %Entity** @arena.Entities.data
  %t47 = icmp eq %Entity* %t46, null
  br i1 %t47, label %spawn_init_14, label %spawn_ready_15
spawn_init_14:
  %t48 = getelementptr %Entity, %Entity* null, i32 1
  %t49 = ptrtoint %Entity* %t48 to i64
  %t50 = mul i64 %t49, 1024
  %t51 = call i8* @malloc(i64 %t50)
  %t52 = bitcast i8* %t51 to %Entity*
  store %Entity* %t52, %Entity** @arena.Entities.data
  br label %spawn_ready_15
spawn_ready_15:
  %t53 = load %Entity*, %Entity** @arena.Entities.data
  %t54 = load i64, i64* @arena.Entities.free_top
  %t55 = icmp sgt i64 %t54, 0
  br i1 %t55, label %spawn_reuse_16, label %spawn_grow_17
spawn_reuse_16:
  %t56 = sub i64 %t54, 1
  store i64 %t56, i64* @arena.Entities.free_top
  %t57 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t56
  %t58 = load i64, i64* %t57
  br label %spawn_store_18
spawn_grow_17:
  %t59 = load i64, i64* @arena.Entities.count
  %t60 = icmp slt i64 %t59, 1024
  br i1 %t60, label %spawn_grow_ok_20, label %spawn_capacity_warn_21
spawn_capacity_warn_21:
  %t61 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t61)
  br label %spawn_end_19
spawn_grow_ok_20:
  %t62 = add i64 %t59, 1
  store i64 %t62, i64* @arena.Entities.count
  br label %spawn_store_18
spawn_store_18:
  %t63 = phi i64 [ %t58, %spawn_reuse_16 ], [ %t59, %spawn_grow_ok_20 ]
  %t65 = getelementptr inbounds %Entity, %Entity* %t64, i32 0, i32 0
  store i32 200, i32* %t65
  %t66 = load %Entity, %Entity* %t64
  %t67 = getelementptr inbounds %Entity, %Entity* %t53, i64 %t63
  store %Entity %t66, %Entity* %t67
  %t68 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t63
  %t69 = load i32, i32* %t68
  %t70 = add i32 %t69, 1
  store i32 %t70, i32* %t68
  br label %spawn_end_19
spawn_end_19:
  %t71 = load %Entity*, %Entity** @arena.Entities.data
  %t72 = icmp eq %Entity* %t71, null
  br i1 %t72, label %spawn_init_22, label %spawn_ready_23
spawn_init_22:
  %t73 = getelementptr %Entity, %Entity* null, i32 1
  %t74 = ptrtoint %Entity* %t73 to i64
  %t75 = mul i64 %t74, 1024
  %t76 = call i8* @malloc(i64 %t75)
  %t77 = bitcast i8* %t76 to %Entity*
  store %Entity* %t77, %Entity** @arena.Entities.data
  br label %spawn_ready_23
spawn_ready_23:
  %t78 = load %Entity*, %Entity** @arena.Entities.data
  %t79 = load i64, i64* @arena.Entities.free_top
  %t80 = icmp sgt i64 %t79, 0
  br i1 %t80, label %spawn_reuse_24, label %spawn_grow_25
spawn_reuse_24:
  %t81 = sub i64 %t79, 1
  store i64 %t81, i64* @arena.Entities.free_top
  %t82 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t81
  %t83 = load i64, i64* %t82
  br label %spawn_store_26
spawn_grow_25:
  %t84 = load i64, i64* @arena.Entities.count
  %t85 = icmp slt i64 %t84, 1024
  br i1 %t85, label %spawn_grow_ok_28, label %spawn_capacity_warn_29
spawn_capacity_warn_29:
  %t86 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t86)
  br label %spawn_end_27
spawn_grow_ok_28:
  %t87 = add i64 %t84, 1
  store i64 %t87, i64* @arena.Entities.count
  br label %spawn_store_26
spawn_store_26:
  %t88 = phi i64 [ %t83, %spawn_reuse_24 ], [ %t84, %spawn_grow_ok_28 ]
  %t90 = getelementptr inbounds %Entity, %Entity* %t89, i32 0, i32 0
  store i32 300, i32* %t90
  %t91 = load %Entity, %Entity* %t89
  %t92 = getelementptr inbounds %Entity, %Entity* %t78, i64 %t88
  store %Entity %t91, %Entity* %t92
  %t93 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t88
  %t94 = load i32, i32* %t93
  %t95 = add i32 %t94, 1
  store i32 %t95, i32* %t93
  br label %spawn_end_27
spawn_end_27:
  %t97 = sext i32 0 to i64
  %t98 = icmp ult i64 %t97, 1024
  br i1 %t98, label %genref_create_ok_30, label %genref_create_oob_31
genref_create_ok_30:
  %t99 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t97
  %t100 = load i32, i32* %t99
  br label %genref_create_end_32
genref_create_oob_31:
  br label %genref_create_end_32
genref_create_end_32:
  %t101 = phi i32 [ %t100, %genref_create_ok_30 ], [ 0, %genref_create_oob_31 ]
  %t103 = getelementptr inbounds %GenRef, %GenRef* %t102, i32 0, i32 0
  store i32 0, i32* %t103
  %t104 = getelementptr inbounds %GenRef, %GenRef* %t102, i32 0, i32 1
  store i32 %t101, i32* %t104
  %t105 = load %GenRef, %GenRef* %t102
  store %GenRef %t105, %GenRef* %t96
  %t107 = sext i32 1 to i64
  %t108 = icmp ult i64 %t107, 1024
  br i1 %t108, label %genref_create_ok_33, label %genref_create_oob_34
genref_create_ok_33:
  %t109 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t107
  %t110 = load i32, i32* %t109
  br label %genref_create_end_35
genref_create_oob_34:
  br label %genref_create_end_35
genref_create_end_35:
  %t111 = phi i32 [ %t110, %genref_create_ok_33 ], [ 0, %genref_create_oob_34 ]
  %t113 = getelementptr inbounds %GenRef, %GenRef* %t112, i32 0, i32 0
  store i32 1, i32* %t113
  %t114 = getelementptr inbounds %GenRef, %GenRef* %t112, i32 0, i32 1
  store i32 %t111, i32* %t114
  %t115 = load %GenRef, %GenRef* %t112
  store %GenRef %t115, %GenRef* %t106
  %t116 = getelementptr inbounds %GenRef, %GenRef* %t96, i32 0, i32 0
  %t117 = load i32, i32* %t116
  %t118 = getelementptr inbounds %GenRef, %GenRef* %t96, i32 0, i32 1
  %t119 = load i32, i32* %t118
  %t120 = sext i32 %t117 to i64
  %t121 = icmp ult i64 %t120, 1024
  br i1 %t121, label %genref_place_check_36, label %genref_place_stale_38
genref_place_check_36:
  %t122 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t120
  %t123 = load i32, i32* %t122
  %t124 = icmp eq i32 %t119, %t123
  %t125 = and i32 %t123, 1
  %t126 = icmp eq i32 %t125, 1
  %t127 = and i1 %t124, %t126
  br i1 %t127, label %genref_place_ok_37, label %genref_place_stale_38
genref_place_ok_37:
  %t128 = load %Entity*, %Entity** @arena.Entities.data
  %t129 = getelementptr inbounds %Entity, %Entity* %t128, i64 %t120
  br label %genref_place_end_39
genref_place_stale_38:
  store %Entity zeroinitializer, %Entity* %t130
  br label %genref_place_end_39
genref_place_end_39:
  %t131 = phi %Entity* [ %t129, %genref_place_ok_37 ], [ %t130, %genref_place_stale_38 ]
  %t132 = getelementptr inbounds %Entity, %Entity* %t131, i32 0, i32 0
  %t133 = load i32, i32* %t132
  %t134 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t134, i32 %t133)
  %t135 = getelementptr inbounds %GenRef, %GenRef* %t106, i32 0, i32 0
  %t136 = load i32, i32* %t135
  %t137 = getelementptr inbounds %GenRef, %GenRef* %t106, i32 0, i32 1
  %t138 = load i32, i32* %t137
  %t139 = sext i32 %t136 to i64
  %t140 = icmp ult i64 %t139, 1024
  br i1 %t140, label %genref_place_check_40, label %genref_place_stale_42
genref_place_check_40:
  %t141 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t139
  %t142 = load i32, i32* %t141
  %t143 = icmp eq i32 %t138, %t142
  %t144 = and i32 %t142, 1
  %t145 = icmp eq i32 %t144, 1
  %t146 = and i1 %t143, %t145
  br i1 %t146, label %genref_place_ok_41, label %genref_place_stale_42
genref_place_ok_41:
  %t147 = load %Entity*, %Entity** @arena.Entities.data
  %t148 = getelementptr inbounds %Entity, %Entity* %t147, i64 %t139
  br label %genref_place_end_43
genref_place_stale_42:
  store %Entity zeroinitializer, %Entity* %t149
  br label %genref_place_end_43
genref_place_end_43:
  %t150 = phi %Entity* [ %t148, %genref_place_ok_41 ], [ %t149, %genref_place_stale_42 ]
  %t151 = getelementptr inbounds %Entity, %Entity* %t150, i32 0, i32 0
  %t152 = load i32, i32* %t151
  %t153 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t153, i32 %t152)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [11 x i8] c"slot0: %d\0A\00"
@.str.4 = private unnamed_addr constant [11 x i8] c"slot1: %d\0A\00"
