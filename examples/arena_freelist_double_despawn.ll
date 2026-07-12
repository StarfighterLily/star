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

%Entity = type { i32 }
%Entities = type { %Entity*, i64 }
@arena.Entities.data = global %Entity* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = load %Entity*, %Entity** @arena.Entities.data
  %t1 = icmp eq %Entity* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = call i8* @malloc(i64 4096)
  %t3 = bitcast i8* %t2 to %Entity*
  store %Entity* %t3, %Entity** @arena.Entities.data
  br label %spawn_ready_1
spawn_ready_1:
  %t4 = load %Entity*, %Entity** @arena.Entities.data
  %t5 = load i64, i64* @arena.Entities.free_top
  %t6 = icmp sgt i64 %t5, 0
  br i1 %t6, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t7 = sub i64 %t5, 1
  store i64 %t7, i64* @arena.Entities.free_top
  %t8 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t7
  %t9 = load i64, i64* %t8
  br label %spawn_store_4
spawn_grow_3:
  %t10 = load i64, i64* @arena.Entities.count
  %t11 = icmp slt i64 %t10, 1024
  br i1 %t11, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t12 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t12)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t13 = add i64 %t10, 1
  store i64 %t13, i64* @arena.Entities.count
  br label %spawn_store_4
spawn_store_4:
  %t14 = phi i64 [ %t9, %spawn_reuse_2 ], [ %t10, %spawn_grow_ok_6 ]
  %t15 = alloca %Entity
  %t16 = getelementptr inbounds %Entity, %Entity* %t15, i32 0, i32 0
  store i32 100, i32* %t16
  %t17 = load %Entity, %Entity* %t15
  %t18 = getelementptr inbounds %Entity, %Entity* %t4, i64 %t14
  store %Entity %t17, %Entity* %t18
  %t19 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t14
  %t20 = load i32, i32* %t19
  %t21 = add i32 %t20, 1
  store i32 %t21, i32* %t19
  br label %spawn_end_5
spawn_end_5:
  %t22 = sext i32 0 to i64
  %t23 = icmp ult i64 %t22, 1024
  br i1 %t23, label %despawn_do_8, label %despawn_end_9
despawn_do_8:
  %t24 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t22
  %t25 = load i32, i32* %t24
  %t26 = and i32 %t25, 1
  %t27 = icmp eq i32 %t26, 1
  br i1 %t27, label %despawn_live_10, label %despawn_end_9
despawn_live_10:
  %t28 = add i32 %t25, 1
  store i32 %t28, i32* %t24
  %t29 = load i64, i64* @arena.Entities.free_top
  %t30 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t29
  store i64 %t22, i64* %t30
  %t31 = add i64 %t29, 1
  store i64 %t31, i64* @arena.Entities.free_top
  br label %despawn_end_9
despawn_end_9:
  %t32 = sext i32 0 to i64
  %t33 = icmp ult i64 %t32, 1024
  br i1 %t33, label %despawn_do_11, label %despawn_end_12
despawn_do_11:
  %t34 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t32
  %t35 = load i32, i32* %t34
  %t36 = and i32 %t35, 1
  %t37 = icmp eq i32 %t36, 1
  br i1 %t37, label %despawn_live_13, label %despawn_end_12
despawn_live_13:
  %t38 = add i32 %t35, 1
  store i32 %t38, i32* %t34
  %t39 = load i64, i64* @arena.Entities.free_top
  %t40 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t39
  store i64 %t32, i64* %t40
  %t41 = add i64 %t39, 1
  store i64 %t41, i64* @arena.Entities.free_top
  br label %despawn_end_12
despawn_end_12:
  %t42 = load %Entity*, %Entity** @arena.Entities.data
  %t43 = icmp eq %Entity* %t42, null
  br i1 %t43, label %spawn_init_14, label %spawn_ready_15
spawn_init_14:
  %t44 = call i8* @malloc(i64 4096)
  %t45 = bitcast i8* %t44 to %Entity*
  store %Entity* %t45, %Entity** @arena.Entities.data
  br label %spawn_ready_15
spawn_ready_15:
  %t46 = load %Entity*, %Entity** @arena.Entities.data
  %t47 = load i64, i64* @arena.Entities.free_top
  %t48 = icmp sgt i64 %t47, 0
  br i1 %t48, label %spawn_reuse_16, label %spawn_grow_17
spawn_reuse_16:
  %t49 = sub i64 %t47, 1
  store i64 %t49, i64* @arena.Entities.free_top
  %t50 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t49
  %t51 = load i64, i64* %t50
  br label %spawn_store_18
spawn_grow_17:
  %t52 = load i64, i64* @arena.Entities.count
  %t53 = icmp slt i64 %t52, 1024
  br i1 %t53, label %spawn_grow_ok_20, label %spawn_capacity_warn_21
spawn_capacity_warn_21:
  %t54 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t54)
  br label %spawn_end_19
spawn_grow_ok_20:
  %t55 = add i64 %t52, 1
  store i64 %t55, i64* @arena.Entities.count
  br label %spawn_store_18
spawn_store_18:
  %t56 = phi i64 [ %t51, %spawn_reuse_16 ], [ %t52, %spawn_grow_ok_20 ]
  %t57 = alloca %Entity
  %t58 = getelementptr inbounds %Entity, %Entity* %t57, i32 0, i32 0
  store i32 200, i32* %t58
  %t59 = load %Entity, %Entity* %t57
  %t60 = getelementptr inbounds %Entity, %Entity* %t46, i64 %t56
  store %Entity %t59, %Entity* %t60
  %t61 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t56
  %t62 = load i32, i32* %t61
  %t63 = add i32 %t62, 1
  store i32 %t63, i32* %t61
  br label %spawn_end_19
spawn_end_19:
  %t64 = load %Entity*, %Entity** @arena.Entities.data
  %t65 = icmp eq %Entity* %t64, null
  br i1 %t65, label %spawn_init_22, label %spawn_ready_23
spawn_init_22:
  %t66 = call i8* @malloc(i64 4096)
  %t67 = bitcast i8* %t66 to %Entity*
  store %Entity* %t67, %Entity** @arena.Entities.data
  br label %spawn_ready_23
spawn_ready_23:
  %t68 = load %Entity*, %Entity** @arena.Entities.data
  %t69 = load i64, i64* @arena.Entities.free_top
  %t70 = icmp sgt i64 %t69, 0
  br i1 %t70, label %spawn_reuse_24, label %spawn_grow_25
spawn_reuse_24:
  %t71 = sub i64 %t69, 1
  store i64 %t71, i64* @arena.Entities.free_top
  %t72 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t71
  %t73 = load i64, i64* %t72
  br label %spawn_store_26
spawn_grow_25:
  %t74 = load i64, i64* @arena.Entities.count
  %t75 = icmp slt i64 %t74, 1024
  br i1 %t75, label %spawn_grow_ok_28, label %spawn_capacity_warn_29
spawn_capacity_warn_29:
  %t76 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t76)
  br label %spawn_end_27
spawn_grow_ok_28:
  %t77 = add i64 %t74, 1
  store i64 %t77, i64* @arena.Entities.count
  br label %spawn_store_26
spawn_store_26:
  %t78 = phi i64 [ %t73, %spawn_reuse_24 ], [ %t74, %spawn_grow_ok_28 ]
  %t79 = alloca %Entity
  %t80 = getelementptr inbounds %Entity, %Entity* %t79, i32 0, i32 0
  store i32 300, i32* %t80
  %t81 = load %Entity, %Entity* %t79
  %t82 = getelementptr inbounds %Entity, %Entity* %t68, i64 %t78
  store %Entity %t81, %Entity* %t82
  %t83 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t78
  %t84 = load i32, i32* %t83
  %t85 = add i32 %t84, 1
  store i32 %t85, i32* %t83
  br label %spawn_end_27
spawn_end_27:
  %t86 = alloca %GenRef
  %t87 = sext i32 0 to i64
  %t88 = icmp ult i64 %t87, 1024
  br i1 %t88, label %genref_create_ok_30, label %genref_create_oob_31
genref_create_ok_30:
  %t89 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t87
  %t90 = load i32, i32* %t89
  br label %genref_create_end_32
genref_create_oob_31:
  br label %genref_create_end_32
genref_create_end_32:
  %t91 = phi i32 [ %t90, %genref_create_ok_30 ], [ 0, %genref_create_oob_31 ]
  %t92 = alloca %GenRef
  %t93 = getelementptr inbounds %GenRef, %GenRef* %t92, i32 0, i32 0
  store i32 0, i32* %t93
  %t94 = getelementptr inbounds %GenRef, %GenRef* %t92, i32 0, i32 1
  store i32 %t91, i32* %t94
  %t95 = load %GenRef, %GenRef* %t92
  store %GenRef %t95, %GenRef* %t86
  %t96 = alloca %GenRef
  %t97 = sext i32 1 to i64
  %t98 = icmp ult i64 %t97, 1024
  br i1 %t98, label %genref_create_ok_33, label %genref_create_oob_34
genref_create_ok_33:
  %t99 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t97
  %t100 = load i32, i32* %t99
  br label %genref_create_end_35
genref_create_oob_34:
  br label %genref_create_end_35
genref_create_end_35:
  %t101 = phi i32 [ %t100, %genref_create_ok_33 ], [ 0, %genref_create_oob_34 ]
  %t102 = alloca %GenRef
  %t103 = getelementptr inbounds %GenRef, %GenRef* %t102, i32 0, i32 0
  store i32 1, i32* %t103
  %t104 = getelementptr inbounds %GenRef, %GenRef* %t102, i32 0, i32 1
  store i32 %t101, i32* %t104
  %t105 = load %GenRef, %GenRef* %t102
  store %GenRef %t105, %GenRef* %t96
  %t106 = getelementptr inbounds %GenRef, %GenRef* %t86, i32 0, i32 0
  %t107 = load i32, i32* %t106
  %t108 = getelementptr inbounds %GenRef, %GenRef* %t86, i32 0, i32 1
  %t109 = load i32, i32* %t108
  %t110 = sext i32 %t107 to i64
  %t111 = icmp ult i64 %t110, 1024
  br i1 %t111, label %genref_place_check_36, label %genref_place_stale_38
genref_place_check_36:
  %t112 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t110
  %t113 = load i32, i32* %t112
  %t114 = icmp eq i32 %t109, %t113
  %t115 = and i32 %t113, 1
  %t116 = icmp eq i32 %t115, 1
  %t117 = and i1 %t114, %t116
  br i1 %t117, label %genref_place_ok_37, label %genref_place_stale_38
genref_place_ok_37:
  %t118 = load %Entity*, %Entity** @arena.Entities.data
  %t119 = getelementptr inbounds %Entity, %Entity* %t118, i64 %t110
  br label %genref_place_end_39
genref_place_stale_38:
  %t120 = alloca %Entity
  store %Entity zeroinitializer, %Entity* %t120
  br label %genref_place_end_39
genref_place_end_39:
  %t121 = phi %Entity* [ %t119, %genref_place_ok_37 ], [ %t120, %genref_place_stale_38 ]
  %t122 = getelementptr inbounds %Entity, %Entity* %t121, i32 0, i32 0
  %t123 = load i32, i32* %t122
  %t124 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t124, i32 %t123)
  %t125 = getelementptr inbounds %GenRef, %GenRef* %t96, i32 0, i32 0
  %t126 = load i32, i32* %t125
  %t127 = getelementptr inbounds %GenRef, %GenRef* %t96, i32 0, i32 1
  %t128 = load i32, i32* %t127
  %t129 = sext i32 %t126 to i64
  %t130 = icmp ult i64 %t129, 1024
  br i1 %t130, label %genref_place_check_40, label %genref_place_stale_42
genref_place_check_40:
  %t131 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t129
  %t132 = load i32, i32* %t131
  %t133 = icmp eq i32 %t128, %t132
  %t134 = and i32 %t132, 1
  %t135 = icmp eq i32 %t134, 1
  %t136 = and i1 %t133, %t135
  br i1 %t136, label %genref_place_ok_41, label %genref_place_stale_42
genref_place_ok_41:
  %t137 = load %Entity*, %Entity** @arena.Entities.data
  %t138 = getelementptr inbounds %Entity, %Entity* %t137, i64 %t129
  br label %genref_place_end_43
genref_place_stale_42:
  %t139 = alloca %Entity
  store %Entity zeroinitializer, %Entity* %t139
  br label %genref_place_end_43
genref_place_end_43:
  %t140 = phi %Entity* [ %t138, %genref_place_ok_41 ], [ %t139, %genref_place_stale_42 ]
  %t141 = getelementptr inbounds %Entity, %Entity* %t140, i32 0, i32 0
  %t142 = load i32, i32* %t141
  %t143 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t143, i32 %t142)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [11 x i8] c"slot0: %d\0A\00"
@.str.4 = private unnamed_addr constant [11 x i8] c"slot1: %d\0A\00"
