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

%Entity = type { i32 }
%Entities = type { %Entity*, i64 }
@arena.Entities.data = global %Entity* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t18 = alloca %Entity
  %t63 = alloca %Entity
  %t88 = alloca %Entity
  %t95 = alloca %GenRef
  %t101 = alloca %GenRef
  %t105 = alloca %GenRef
  %t111 = alloca %GenRef
  %t129 = alloca %Entity
  %t148 = alloca %Entity
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = load %Entity*, %Entity** @arena.Entities.data
  %t1 = icmp eq %Entity* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = getelementptr %Entity, %Entity* null, i32 1
  %t3 = ptrtoint %Entity* %t2 to i64
  %t4 = mul i64 %t3, 1024
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to %Entity*
  store %Entity* %t6, %Entity** @arena.Entities.data
  br label %spawn_ready_1
spawn_ready_1:
  %t7 = load %Entity*, %Entity** @arena.Entities.data
  %t8 = load i64, i64* @arena.Entities.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Entities.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_4
spawn_grow_3:
  %t13 = load i64, i64* @arena.Entities.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t15 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t15)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t16 = add i64 %t13, 1
  store i64 %t16, i64* @arena.Entities.count
  br label %spawn_store_4
spawn_store_4:
  %t17 = phi i64 [ %t12, %spawn_reuse_2 ], [ %t13, %spawn_grow_ok_6 ]
  %t19 = getelementptr inbounds %Entity, %Entity* %t18, i32 0, i32 0
  store i32 100, i32* %t19
  %t20 = load %Entity, %Entity* %t18
  %t21 = getelementptr inbounds %Entity, %Entity* %t7, i64 %t17
  store %Entity %t20, %Entity* %t21
  %t22 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t17
  %t23 = load i32, i32* %t22
  %t24 = add i32 %t23, 1
  store i32 %t24, i32* %t22
  br label %spawn_end_5
spawn_end_5:
  %t25 = sext i32 0 to i64
  %t26 = icmp ult i64 %t25, 1024
  br i1 %t26, label %despawn_do_8, label %despawn_end_9
despawn_do_8:
  %t27 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t25
  %t28 = load i32, i32* %t27
  %t29 = and i32 %t28, 1
  %t30 = icmp eq i32 %t29, 1
  br i1 %t30, label %despawn_live_10, label %despawn_end_9
despawn_live_10:
  %t31 = add i32 %t28, 1
  store i32 %t31, i32* %t27
  %t32 = load i64, i64* @arena.Entities.free_top
  %t33 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t32
  store i64 %t25, i64* %t33
  %t34 = add i64 %t32, 1
  store i64 %t34, i64* @arena.Entities.free_top
  br label %despawn_end_9
despawn_end_9:
  %t35 = sext i32 0 to i64
  %t36 = icmp ult i64 %t35, 1024
  br i1 %t36, label %despawn_do_11, label %despawn_end_12
despawn_do_11:
  %t37 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t35
  %t38 = load i32, i32* %t37
  %t39 = and i32 %t38, 1
  %t40 = icmp eq i32 %t39, 1
  br i1 %t40, label %despawn_live_13, label %despawn_end_12
despawn_live_13:
  %t41 = add i32 %t38, 1
  store i32 %t41, i32* %t37
  %t42 = load i64, i64* @arena.Entities.free_top
  %t43 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t42
  store i64 %t35, i64* %t43
  %t44 = add i64 %t42, 1
  store i64 %t44, i64* @arena.Entities.free_top
  br label %despawn_end_12
despawn_end_12:
  %t45 = load %Entity*, %Entity** @arena.Entities.data
  %t46 = icmp eq %Entity* %t45, null
  br i1 %t46, label %spawn_init_14, label %spawn_ready_15
spawn_init_14:
  %t47 = getelementptr %Entity, %Entity* null, i32 1
  %t48 = ptrtoint %Entity* %t47 to i64
  %t49 = mul i64 %t48, 1024
  %t50 = call i8* @malloc(i64 %t49)
  %t51 = bitcast i8* %t50 to %Entity*
  store %Entity* %t51, %Entity** @arena.Entities.data
  br label %spawn_ready_15
spawn_ready_15:
  %t52 = load %Entity*, %Entity** @arena.Entities.data
  %t53 = load i64, i64* @arena.Entities.free_top
  %t54 = icmp sgt i64 %t53, 0
  br i1 %t54, label %spawn_reuse_16, label %spawn_grow_17
spawn_reuse_16:
  %t55 = sub i64 %t53, 1
  store i64 %t55, i64* @arena.Entities.free_top
  %t56 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t55
  %t57 = load i64, i64* %t56
  br label %spawn_store_18
spawn_grow_17:
  %t58 = load i64, i64* @arena.Entities.count
  %t59 = icmp slt i64 %t58, 1024
  br i1 %t59, label %spawn_grow_ok_20, label %spawn_capacity_warn_21
spawn_capacity_warn_21:
  %t60 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t60)
  br label %spawn_end_19
spawn_grow_ok_20:
  %t61 = add i64 %t58, 1
  store i64 %t61, i64* @arena.Entities.count
  br label %spawn_store_18
spawn_store_18:
  %t62 = phi i64 [ %t57, %spawn_reuse_16 ], [ %t58, %spawn_grow_ok_20 ]
  %t64 = getelementptr inbounds %Entity, %Entity* %t63, i32 0, i32 0
  store i32 200, i32* %t64
  %t65 = load %Entity, %Entity* %t63
  %t66 = getelementptr inbounds %Entity, %Entity* %t52, i64 %t62
  store %Entity %t65, %Entity* %t66
  %t67 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t62
  %t68 = load i32, i32* %t67
  %t69 = add i32 %t68, 1
  store i32 %t69, i32* %t67
  br label %spawn_end_19
spawn_end_19:
  %t70 = load %Entity*, %Entity** @arena.Entities.data
  %t71 = icmp eq %Entity* %t70, null
  br i1 %t71, label %spawn_init_22, label %spawn_ready_23
spawn_init_22:
  %t72 = getelementptr %Entity, %Entity* null, i32 1
  %t73 = ptrtoint %Entity* %t72 to i64
  %t74 = mul i64 %t73, 1024
  %t75 = call i8* @malloc(i64 %t74)
  %t76 = bitcast i8* %t75 to %Entity*
  store %Entity* %t76, %Entity** @arena.Entities.data
  br label %spawn_ready_23
spawn_ready_23:
  %t77 = load %Entity*, %Entity** @arena.Entities.data
  %t78 = load i64, i64* @arena.Entities.free_top
  %t79 = icmp sgt i64 %t78, 0
  br i1 %t79, label %spawn_reuse_24, label %spawn_grow_25
spawn_reuse_24:
  %t80 = sub i64 %t78, 1
  store i64 %t80, i64* @arena.Entities.free_top
  %t81 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t80
  %t82 = load i64, i64* %t81
  br label %spawn_store_26
spawn_grow_25:
  %t83 = load i64, i64* @arena.Entities.count
  %t84 = icmp slt i64 %t83, 1024
  br i1 %t84, label %spawn_grow_ok_28, label %spawn_capacity_warn_29
spawn_capacity_warn_29:
  %t85 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t85)
  br label %spawn_end_27
spawn_grow_ok_28:
  %t86 = add i64 %t83, 1
  store i64 %t86, i64* @arena.Entities.count
  br label %spawn_store_26
spawn_store_26:
  %t87 = phi i64 [ %t82, %spawn_reuse_24 ], [ %t83, %spawn_grow_ok_28 ]
  %t89 = getelementptr inbounds %Entity, %Entity* %t88, i32 0, i32 0
  store i32 300, i32* %t89
  %t90 = load %Entity, %Entity* %t88
  %t91 = getelementptr inbounds %Entity, %Entity* %t77, i64 %t87
  store %Entity %t90, %Entity* %t91
  %t92 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t87
  %t93 = load i32, i32* %t92
  %t94 = add i32 %t93, 1
  store i32 %t94, i32* %t92
  br label %spawn_end_27
spawn_end_27:
  %t96 = sext i32 0 to i64
  %t97 = icmp ult i64 %t96, 1024
  br i1 %t97, label %genref_create_ok_30, label %genref_create_oob_31
genref_create_ok_30:
  %t98 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t96
  %t99 = load i32, i32* %t98
  br label %genref_create_end_32
genref_create_oob_31:
  br label %genref_create_end_32
genref_create_end_32:
  %t100 = phi i32 [ %t99, %genref_create_ok_30 ], [ 0, %genref_create_oob_31 ]
  %t102 = getelementptr inbounds %GenRef, %GenRef* %t101, i32 0, i32 0
  store i32 0, i32* %t102
  %t103 = getelementptr inbounds %GenRef, %GenRef* %t101, i32 0, i32 1
  store i32 %t100, i32* %t103
  %t104 = load %GenRef, %GenRef* %t101
  store %GenRef %t104, %GenRef* %t95
  %t106 = sext i32 1 to i64
  %t107 = icmp ult i64 %t106, 1024
  br i1 %t107, label %genref_create_ok_33, label %genref_create_oob_34
genref_create_ok_33:
  %t108 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t106
  %t109 = load i32, i32* %t108
  br label %genref_create_end_35
genref_create_oob_34:
  br label %genref_create_end_35
genref_create_end_35:
  %t110 = phi i32 [ %t109, %genref_create_ok_33 ], [ 0, %genref_create_oob_34 ]
  %t112 = getelementptr inbounds %GenRef, %GenRef* %t111, i32 0, i32 0
  store i32 1, i32* %t112
  %t113 = getelementptr inbounds %GenRef, %GenRef* %t111, i32 0, i32 1
  store i32 %t110, i32* %t113
  %t114 = load %GenRef, %GenRef* %t111
  store %GenRef %t114, %GenRef* %t105
  %t115 = getelementptr inbounds %GenRef, %GenRef* %t95, i32 0, i32 0
  %t116 = load i32, i32* %t115
  %t117 = getelementptr inbounds %GenRef, %GenRef* %t95, i32 0, i32 1
  %t118 = load i32, i32* %t117
  %t119 = sext i32 %t116 to i64
  %t120 = icmp ult i64 %t119, 1024
  br i1 %t120, label %genref_place_check_36, label %genref_place_stale_38
genref_place_check_36:
  %t121 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t119
  %t122 = load i32, i32* %t121
  %t123 = icmp eq i32 %t118, %t122
  %t124 = and i32 %t122, 1
  %t125 = icmp eq i32 %t124, 1
  %t126 = and i1 %t123, %t125
  br i1 %t126, label %genref_place_ok_37, label %genref_place_stale_38
genref_place_ok_37:
  %t127 = load %Entity*, %Entity** @arena.Entities.data
  %t128 = getelementptr inbounds %Entity, %Entity* %t127, i64 %t119
  br label %genref_place_end_39
genref_place_stale_38:
  store %Entity zeroinitializer, %Entity* %t129
  br label %genref_place_end_39
genref_place_end_39:
  %t130 = phi %Entity* [ %t128, %genref_place_ok_37 ], [ %t129, %genref_place_stale_38 ]
  %t131 = getelementptr inbounds %Entity, %Entity* %t130, i32 0, i32 0
  %t132 = load i32, i32* %t131
  %t133 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t133, i32 %t132)
  %t134 = getelementptr inbounds %GenRef, %GenRef* %t105, i32 0, i32 0
  %t135 = load i32, i32* %t134
  %t136 = getelementptr inbounds %GenRef, %GenRef* %t105, i32 0, i32 1
  %t137 = load i32, i32* %t136
  %t138 = sext i32 %t135 to i64
  %t139 = icmp ult i64 %t138, 1024
  br i1 %t139, label %genref_place_check_40, label %genref_place_stale_42
genref_place_check_40:
  %t140 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t138
  %t141 = load i32, i32* %t140
  %t142 = icmp eq i32 %t137, %t141
  %t143 = and i32 %t141, 1
  %t144 = icmp eq i32 %t143, 1
  %t145 = and i1 %t142, %t144
  br i1 %t145, label %genref_place_ok_41, label %genref_place_stale_42
genref_place_ok_41:
  %t146 = load %Entity*, %Entity** @arena.Entities.data
  %t147 = getelementptr inbounds %Entity, %Entity* %t146, i64 %t138
  br label %genref_place_end_43
genref_place_stale_42:
  store %Entity zeroinitializer, %Entity* %t148
  br label %genref_place_end_43
genref_place_end_43:
  %t149 = phi %Entity* [ %t147, %genref_place_ok_41 ], [ %t148, %genref_place_stale_42 ]
  %t150 = getelementptr inbounds %Entity, %Entity* %t149, i32 0, i32 0
  %t151 = load i32, i32* %t150
  %t152 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t152, i32 %t151)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [11 x i8] c"slot0: %d\0A\00"
@.str.4 = private unnamed_addr constant [11 x i8] c"slot1: %d\0A\00"
