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

%Entity = type { i32 }
%Entities = type { %Entity*, i64 }
@arena.Entities.data = global %Entity* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i64] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t20 = alloca %Entity
  %t65 = alloca %Entity
  %t90 = alloca %Entity
  %t97 = alloca %GenRef
  %t103 = alloca %GenRef
  %t107 = alloca %GenRef
  %t113 = alloca %GenRef
  %t131 = alloca %Entity
  %t150 = alloca %Entity
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = load %Entity*, %Entity** @arena.Entities.data
  %t3 = icmp eq %Entity* %t2, null
  br i1 %t3, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t4 = getelementptr %Entity, %Entity* null, i32 1
  %t5 = ptrtoint %Entity* %t4 to i64
  %t6 = mul i64 %t5, 1024
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to %Entity*
  store %Entity* %t8, %Entity** @arena.Entities.data
  br label %spawn_ready_1
spawn_ready_1:
  %t9 = load %Entity*, %Entity** @arena.Entities.data
  %t10 = load i64, i64* @arena.Entities.free_top
  %t11 = icmp sgt i64 %t10, 0
  br i1 %t11, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t12 = sub i64 %t10, 1
  store i64 %t12, i64* @arena.Entities.free_top
  %t13 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t12
  %t14 = load i64, i64* %t13
  br label %spawn_store_4
spawn_grow_3:
  %t15 = load i64, i64* @arena.Entities.count
  %t16 = icmp slt i64 %t15, 1024
  br i1 %t16, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t17 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t17)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t18 = add i64 %t15, 1
  store i64 %t18, i64* @arena.Entities.count
  br label %spawn_store_4
spawn_store_4:
  %t19 = phi i64 [ %t14, %spawn_reuse_2 ], [ %t15, %spawn_grow_ok_6 ]
  %t21 = getelementptr inbounds %Entity, %Entity* %t20, i32 0, i32 0
  store i32 100, i32* %t21
  %t22 = load %Entity, %Entity* %t20
  %t23 = getelementptr inbounds %Entity, %Entity* %t9, i64 %t19
  store %Entity %t22, %Entity* %t23
  %t24 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t19
  %t25 = load i64, i64* %t24
  %t26 = add i64 %t25, 1
  store i64 %t26, i64* %t24
  br label %spawn_end_5
spawn_end_5:
  %t27 = sext i32 0 to i64
  %t28 = icmp ult i64 %t27, 1024
  br i1 %t28, label %despawn_do_8, label %despawn_end_9
despawn_do_8:
  %t29 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t27
  %t30 = load i64, i64* %t29
  %t31 = and i64 %t30, 1
  %t32 = icmp eq i64 %t31, 1
  br i1 %t32, label %despawn_live_10, label %despawn_end_9
despawn_live_10:
  %t33 = add i64 %t30, 1
  store i64 %t33, i64* %t29
  %t34 = load i64, i64* @arena.Entities.free_top
  %t35 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t34
  store i64 %t27, i64* %t35
  %t36 = add i64 %t34, 1
  store i64 %t36, i64* @arena.Entities.free_top
  br label %despawn_end_9
despawn_end_9:
  %t37 = sext i32 0 to i64
  %t38 = icmp ult i64 %t37, 1024
  br i1 %t38, label %despawn_do_11, label %despawn_end_12
despawn_do_11:
  %t39 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t37
  %t40 = load i64, i64* %t39
  %t41 = and i64 %t40, 1
  %t42 = icmp eq i64 %t41, 1
  br i1 %t42, label %despawn_live_13, label %despawn_end_12
despawn_live_13:
  %t43 = add i64 %t40, 1
  store i64 %t43, i64* %t39
  %t44 = load i64, i64* @arena.Entities.free_top
  %t45 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t44
  store i64 %t37, i64* %t45
  %t46 = add i64 %t44, 1
  store i64 %t46, i64* @arena.Entities.free_top
  br label %despawn_end_12
despawn_end_12:
  %t47 = load %Entity*, %Entity** @arena.Entities.data
  %t48 = icmp eq %Entity* %t47, null
  br i1 %t48, label %spawn_init_14, label %spawn_ready_15
spawn_init_14:
  %t49 = getelementptr %Entity, %Entity* null, i32 1
  %t50 = ptrtoint %Entity* %t49 to i64
  %t51 = mul i64 %t50, 1024
  %t52 = call i8* @malloc(i64 %t51)
  %t53 = bitcast i8* %t52 to %Entity*
  store %Entity* %t53, %Entity** @arena.Entities.data
  br label %spawn_ready_15
spawn_ready_15:
  %t54 = load %Entity*, %Entity** @arena.Entities.data
  %t55 = load i64, i64* @arena.Entities.free_top
  %t56 = icmp sgt i64 %t55, 0
  br i1 %t56, label %spawn_reuse_16, label %spawn_grow_17
spawn_reuse_16:
  %t57 = sub i64 %t55, 1
  store i64 %t57, i64* @arena.Entities.free_top
  %t58 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t57
  %t59 = load i64, i64* %t58
  br label %spawn_store_18
spawn_grow_17:
  %t60 = load i64, i64* @arena.Entities.count
  %t61 = icmp slt i64 %t60, 1024
  br i1 %t61, label %spawn_grow_ok_20, label %spawn_capacity_warn_21
spawn_capacity_warn_21:
  %t62 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t62)
  br label %spawn_end_19
spawn_grow_ok_20:
  %t63 = add i64 %t60, 1
  store i64 %t63, i64* @arena.Entities.count
  br label %spawn_store_18
spawn_store_18:
  %t64 = phi i64 [ %t59, %spawn_reuse_16 ], [ %t60, %spawn_grow_ok_20 ]
  %t66 = getelementptr inbounds %Entity, %Entity* %t65, i32 0, i32 0
  store i32 200, i32* %t66
  %t67 = load %Entity, %Entity* %t65
  %t68 = getelementptr inbounds %Entity, %Entity* %t54, i64 %t64
  store %Entity %t67, %Entity* %t68
  %t69 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t64
  %t70 = load i64, i64* %t69
  %t71 = add i64 %t70, 1
  store i64 %t71, i64* %t69
  br label %spawn_end_19
spawn_end_19:
  %t72 = load %Entity*, %Entity** @arena.Entities.data
  %t73 = icmp eq %Entity* %t72, null
  br i1 %t73, label %spawn_init_22, label %spawn_ready_23
spawn_init_22:
  %t74 = getelementptr %Entity, %Entity* null, i32 1
  %t75 = ptrtoint %Entity* %t74 to i64
  %t76 = mul i64 %t75, 1024
  %t77 = call i8* @malloc(i64 %t76)
  %t78 = bitcast i8* %t77 to %Entity*
  store %Entity* %t78, %Entity** @arena.Entities.data
  br label %spawn_ready_23
spawn_ready_23:
  %t79 = load %Entity*, %Entity** @arena.Entities.data
  %t80 = load i64, i64* @arena.Entities.free_top
  %t81 = icmp sgt i64 %t80, 0
  br i1 %t81, label %spawn_reuse_24, label %spawn_grow_25
spawn_reuse_24:
  %t82 = sub i64 %t80, 1
  store i64 %t82, i64* @arena.Entities.free_top
  %t83 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t82
  %t84 = load i64, i64* %t83
  br label %spawn_store_26
spawn_grow_25:
  %t85 = load i64, i64* @arena.Entities.count
  %t86 = icmp slt i64 %t85, 1024
  br i1 %t86, label %spawn_grow_ok_28, label %spawn_capacity_warn_29
spawn_capacity_warn_29:
  %t87 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t87)
  br label %spawn_end_27
spawn_grow_ok_28:
  %t88 = add i64 %t85, 1
  store i64 %t88, i64* @arena.Entities.count
  br label %spawn_store_26
spawn_store_26:
  %t89 = phi i64 [ %t84, %spawn_reuse_24 ], [ %t85, %spawn_grow_ok_28 ]
  %t91 = getelementptr inbounds %Entity, %Entity* %t90, i32 0, i32 0
  store i32 300, i32* %t91
  %t92 = load %Entity, %Entity* %t90
  %t93 = getelementptr inbounds %Entity, %Entity* %t79, i64 %t89
  store %Entity %t92, %Entity* %t93
  %t94 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t89
  %t95 = load i64, i64* %t94
  %t96 = add i64 %t95, 1
  store i64 %t96, i64* %t94
  br label %spawn_end_27
spawn_end_27:
  %t98 = sext i32 0 to i64
  %t99 = icmp ult i64 %t98, 1024
  br i1 %t99, label %genref_create_ok_30, label %genref_create_oob_31
genref_create_ok_30:
  %t100 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t98
  %t101 = load i64, i64* %t100
  br label %genref_create_end_32
genref_create_oob_31:
  br label %genref_create_end_32
genref_create_end_32:
  %t102 = phi i64 [ %t101, %genref_create_ok_30 ], [ 0, %genref_create_oob_31 ]
  %t104 = getelementptr inbounds %GenRef, %GenRef* %t103, i32 0, i32 0
  store i32 0, i32* %t104
  %t105 = getelementptr inbounds %GenRef, %GenRef* %t103, i32 0, i32 1
  store i64 %t102, i64* %t105
  %t106 = load %GenRef, %GenRef* %t103
  store %GenRef %t106, %GenRef* %t97
  %t108 = sext i32 1 to i64
  %t109 = icmp ult i64 %t108, 1024
  br i1 %t109, label %genref_create_ok_33, label %genref_create_oob_34
genref_create_ok_33:
  %t110 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t108
  %t111 = load i64, i64* %t110
  br label %genref_create_end_35
genref_create_oob_34:
  br label %genref_create_end_35
genref_create_end_35:
  %t112 = phi i64 [ %t111, %genref_create_ok_33 ], [ 0, %genref_create_oob_34 ]
  %t114 = getelementptr inbounds %GenRef, %GenRef* %t113, i32 0, i32 0
  store i32 1, i32* %t114
  %t115 = getelementptr inbounds %GenRef, %GenRef* %t113, i32 0, i32 1
  store i64 %t112, i64* %t115
  %t116 = load %GenRef, %GenRef* %t113
  store %GenRef %t116, %GenRef* %t107
  %t117 = getelementptr inbounds %GenRef, %GenRef* %t97, i32 0, i32 0
  %t118 = load i32, i32* %t117
  %t119 = getelementptr inbounds %GenRef, %GenRef* %t97, i32 0, i32 1
  %t120 = load i64, i64* %t119
  %t121 = sext i32 %t118 to i64
  %t122 = icmp ult i64 %t121, 1024
  br i1 %t122, label %genref_place_check_36, label %genref_place_stale_38
genref_place_check_36:
  %t123 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t121
  %t124 = load i64, i64* %t123
  %t125 = icmp eq i64 %t120, %t124
  %t126 = and i64 %t124, 1
  %t127 = icmp eq i64 %t126, 1
  %t128 = and i1 %t125, %t127
  br i1 %t128, label %genref_place_ok_37, label %genref_place_stale_38
genref_place_ok_37:
  %t129 = load %Entity*, %Entity** @arena.Entities.data
  %t130 = getelementptr inbounds %Entity, %Entity* %t129, i64 %t121
  br label %genref_place_end_39
genref_place_stale_38:
  store %Entity zeroinitializer, %Entity* %t131
  br label %genref_place_end_39
genref_place_end_39:
  %t132 = phi %Entity* [ %t130, %genref_place_ok_37 ], [ %t131, %genref_place_stale_38 ]
  %t133 = getelementptr inbounds %Entity, %Entity* %t132, i32 0, i32 0
  %t134 = load i32, i32* %t133
  %t135 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t135, i32 %t134)
  %t136 = getelementptr inbounds %GenRef, %GenRef* %t107, i32 0, i32 0
  %t137 = load i32, i32* %t136
  %t138 = getelementptr inbounds %GenRef, %GenRef* %t107, i32 0, i32 1
  %t139 = load i64, i64* %t138
  %t140 = sext i32 %t137 to i64
  %t141 = icmp ult i64 %t140, 1024
  br i1 %t141, label %genref_place_check_40, label %genref_place_stale_42
genref_place_check_40:
  %t142 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t140
  %t143 = load i64, i64* %t142
  %t144 = icmp eq i64 %t139, %t143
  %t145 = and i64 %t143, 1
  %t146 = icmp eq i64 %t145, 1
  %t147 = and i1 %t144, %t146
  br i1 %t147, label %genref_place_ok_41, label %genref_place_stale_42
genref_place_ok_41:
  %t148 = load %Entity*, %Entity** @arena.Entities.data
  %t149 = getelementptr inbounds %Entity, %Entity* %t148, i64 %t140
  br label %genref_place_end_43
genref_place_stale_42:
  store %Entity zeroinitializer, %Entity* %t150
  br label %genref_place_end_43
genref_place_end_43:
  %t151 = phi %Entity* [ %t149, %genref_place_ok_41 ], [ %t150, %genref_place_stale_42 ]
  %t152 = getelementptr inbounds %Entity, %Entity* %t151, i32 0, i32 0
  %t153 = load i32, i32* %t152
  %t154 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t154, i32 %t153)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [11 x i8] c"slot0: %d\0A\00"
@.str.4 = private unnamed_addr constant [11 x i8] c"slot1: %d\0A\00"
