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
  %t22 = alloca %GenRef
  %t23 = sext i32 0 to i64
  %t24 = icmp ult i64 %t23, 1024
  br i1 %t24, label %genref_create_ok_8, label %genref_create_oob_9
genref_create_ok_8:
  %t25 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t23
  %t26 = load i32, i32* %t25
  br label %genref_create_end_10
genref_create_oob_9:
  br label %genref_create_end_10
genref_create_end_10:
  %t27 = phi i32 [ %t26, %genref_create_ok_8 ], [ 0, %genref_create_oob_9 ]
  %t28 = alloca %GenRef
  %t29 = getelementptr inbounds %GenRef, %GenRef* %t28, i32 0, i32 0
  store i32 0, i32* %t29
  %t30 = getelementptr inbounds %GenRef, %GenRef* %t28, i32 0, i32 1
  store i32 %t27, i32* %t30
  %t31 = load %GenRef, %GenRef* %t28
  store %GenRef %t31, %GenRef* %t22
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
  %t64 = alloca %GenRef
  %t65 = sext i32 0 to i64
  %t66 = icmp ult i64 %t65, 1024
  br i1 %t66, label %genref_create_ok_22, label %genref_create_oob_23
genref_create_ok_22:
  %t67 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t65
  %t68 = load i32, i32* %t67
  br label %genref_create_end_24
genref_create_oob_23:
  br label %genref_create_end_24
genref_create_end_24:
  %t69 = phi i32 [ %t68, %genref_create_ok_22 ], [ 0, %genref_create_oob_23 ]
  %t70 = alloca %GenRef
  %t71 = getelementptr inbounds %GenRef, %GenRef* %t70, i32 0, i32 0
  store i32 0, i32* %t71
  %t72 = getelementptr inbounds %GenRef, %GenRef* %t70, i32 0, i32 1
  store i32 %t69, i32* %t72
  %t73 = load %GenRef, %GenRef* %t70
  store %GenRef %t73, %GenRef* %t64
  %t74 = alloca %Entity
  %t75 = getelementptr inbounds %GenRef, %GenRef* %t22, i32 0, i32 0
  %t76 = load i32, i32* %t75
  %t77 = getelementptr inbounds %GenRef, %GenRef* %t22, i32 0, i32 1
  %t78 = load i32, i32* %t77
  %t79 = sext i32 %t76 to i64
  %t80 = icmp ult i64 %t79, 1024
  br i1 %t80, label %genref_check_25, label %genref_stale_27
genref_check_25:
  %t81 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t79
  %t82 = load i32, i32* %t81
  %t83 = icmp eq i32 %t78, %t82
  %t84 = and i32 %t82, 1
  %t85 = icmp eq i32 %t84, 1
  %t86 = and i1 %t83, %t85
  br i1 %t86, label %genref_ok_26, label %genref_stale_27
genref_ok_26:
  %t87 = load %Entity*, %Entity** @arena.Entities.data
  %t88 = getelementptr inbounds %Entity, %Entity* %t87, i64 %t79
  %t89 = load %Entity, %Entity* %t88
  br label %genref_end_28
genref_stale_27:
  br label %genref_end_28
genref_end_28:
  %t90 = phi %Entity [ %t89, %genref_ok_26 ], [ zeroinitializer, %genref_stale_27 ]
  store %Entity %t90, %Entity* %t74
  %t91 = alloca %Entity
  %t92 = getelementptr inbounds %GenRef, %GenRef* %t64, i32 0, i32 0
  %t93 = load i32, i32* %t92
  %t94 = getelementptr inbounds %GenRef, %GenRef* %t64, i32 0, i32 1
  %t95 = load i32, i32* %t94
  %t96 = sext i32 %t93 to i64
  %t97 = icmp ult i64 %t96, 1024
  br i1 %t97, label %genref_check_29, label %genref_stale_31
genref_check_29:
  %t98 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t96
  %t99 = load i32, i32* %t98
  %t100 = icmp eq i32 %t95, %t99
  %t101 = and i32 %t99, 1
  %t102 = icmp eq i32 %t101, 1
  %t103 = and i1 %t100, %t102
  br i1 %t103, label %genref_ok_30, label %genref_stale_31
genref_ok_30:
  %t104 = load %Entity*, %Entity** @arena.Entities.data
  %t105 = getelementptr inbounds %Entity, %Entity* %t104, i64 %t96
  %t106 = load %Entity, %Entity* %t105
  br label %genref_end_32
genref_stale_31:
  br label %genref_end_32
genref_end_32:
  %t107 = phi %Entity [ %t106, %genref_ok_30 ], [ zeroinitializer, %genref_stale_31 ]
  store %Entity %t107, %Entity* %t91
  %t108 = getelementptr inbounds %Entity, %Entity* %t74, i32 0, i32 0
  %t109 = load i32, i32* %t108
  %t110 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t110, i32 %t109)
  %t111 = getelementptr inbounds %Entity, %Entity* %t91, i32 0, i32 0
  %t112 = load i32, i32* %t111
  %t113 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t113, i32 %t112)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [13 x i8] c"via_old: %d\0A\00"
@.str.3 = private unnamed_addr constant [13 x i8] c"via_new: %d\0A\00"
