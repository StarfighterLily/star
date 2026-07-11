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

%Entity = type { i32 }
%Entities = type { %Entity*, i64 }
@arena.Entities.data = global %Entity* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main() {
entry:
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
  %t32 = alloca %Entity
  %t33 = getelementptr inbounds %GenRef, %GenRef* %t22, i32 0, i32 0
  %t34 = load i32, i32* %t33
  %t35 = getelementptr inbounds %GenRef, %GenRef* %t22, i32 0, i32 1
  %t36 = load i32, i32* %t35
  %t37 = sext i32 %t34 to i64
  %t38 = icmp ult i64 %t37, 1024
  br i1 %t38, label %genref_check_11, label %genref_stale_13
genref_check_11:
  %t39 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t37
  %t40 = load i32, i32* %t39
  %t41 = icmp eq i32 %t36, %t40
  %t42 = and i32 %t40, 1
  %t43 = icmp eq i32 %t42, 1
  %t44 = and i1 %t41, %t43
  br i1 %t44, label %genref_ok_12, label %genref_stale_13
genref_ok_12:
  %t45 = load %Entity*, %Entity** @arena.Entities.data
  %t46 = getelementptr inbounds %Entity, %Entity* %t45, i64 %t37
  %t47 = load %Entity, %Entity* %t46
  br label %genref_end_14
genref_stale_13:
  br label %genref_end_14
genref_end_14:
  %t48 = phi %Entity [ %t47, %genref_ok_12 ], [ zeroinitializer, %genref_stale_13 ]
  store %Entity %t48, %Entity* %t32
  %t49 = getelementptr inbounds %Entity, %Entity* %t32, i32 0, i32 0
  %t50 = load i32, i32* %t49
  %t51 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t51, i32 %t50)
  %t52 = sext i32 0 to i64
  %t53 = icmp ult i64 %t52, 1024
  br i1 %t53, label %despawn_do_15, label %despawn_end_16
despawn_do_15:
  %t54 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t52
  %t55 = load i32, i32* %t54
  %t56 = and i32 %t55, 1
  %t57 = icmp eq i32 %t56, 1
  br i1 %t57, label %despawn_live_17, label %despawn_end_16
despawn_live_17:
  %t58 = add i32 %t55, 1
  store i32 %t58, i32* %t54
  %t59 = load i64, i64* @arena.Entities.free_top
  %t60 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t59
  store i64 %t52, i64* %t60
  %t61 = add i64 %t59, 1
  store i64 %t61, i64* @arena.Entities.free_top
  br label %despawn_end_16
despawn_end_16:
  %t62 = alloca %Entity
  %t63 = getelementptr inbounds %GenRef, %GenRef* %t22, i32 0, i32 0
  %t64 = load i32, i32* %t63
  %t65 = getelementptr inbounds %GenRef, %GenRef* %t22, i32 0, i32 1
  %t66 = load i32, i32* %t65
  %t67 = sext i32 %t64 to i64
  %t68 = icmp ult i64 %t67, 1024
  br i1 %t68, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t69 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t67
  %t70 = load i32, i32* %t69
  %t71 = icmp eq i32 %t66, %t70
  %t72 = and i32 %t70, 1
  %t73 = icmp eq i32 %t72, 1
  %t74 = and i1 %t71, %t73
  br i1 %t74, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t75 = load %Entity*, %Entity** @arena.Entities.data
  %t76 = getelementptr inbounds %Entity, %Entity* %t75, i64 %t67
  %t77 = load %Entity, %Entity* %t76
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t78 = phi %Entity [ %t77, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Entity %t78, %Entity* %t62
  %t79 = getelementptr inbounds %Entity, %Entity* %t62, i32 0, i32 0
  %t80 = load i32, i32* %t79
  %t81 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t81, i32 %t80)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [12 x i8] c"before: %d\0A\00"
@.str.2 = private unnamed_addr constant [11 x i8] c"after: %d\0A\00"
