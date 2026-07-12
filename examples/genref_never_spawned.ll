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

%Point = type { i32, i32 }
%Entities = type { %Point*, i64 }
@arena.Entities.data = global %Point* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = alloca %GenRef
  %t1 = sext i32 0 to i64
  %t2 = icmp ult i64 %t1, 1024
  br i1 %t2, label %genref_create_ok_0, label %genref_create_oob_1
genref_create_ok_0:
  %t3 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t1
  %t4 = load i32, i32* %t3
  br label %genref_create_end_2
genref_create_oob_1:
  br label %genref_create_end_2
genref_create_end_2:
  %t5 = phi i32 [ %t4, %genref_create_ok_0 ], [ 0, %genref_create_oob_1 ]
  %t6 = alloca %GenRef
  %t7 = getelementptr inbounds %GenRef, %GenRef* %t6, i32 0, i32 0
  store i32 0, i32* %t7
  %t8 = getelementptr inbounds %GenRef, %GenRef* %t6, i32 0, i32 1
  store i32 %t5, i32* %t8
  %t9 = load %GenRef, %GenRef* %t6
  store %GenRef %t9, %GenRef* %t0
  %t10 = alloca %Point
  %t11 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 0
  %t12 = load i32, i32* %t11
  %t13 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 1
  %t14 = load i32, i32* %t13
  %t15 = sext i32 %t12 to i64
  %t16 = icmp ult i64 %t15, 1024
  br i1 %t16, label %genref_check_3, label %genref_stale_5
genref_check_3:
  %t17 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t15
  %t18 = load i32, i32* %t17
  %t19 = icmp eq i32 %t14, %t18
  %t20 = and i32 %t18, 1
  %t21 = icmp eq i32 %t20, 1
  %t22 = and i1 %t19, %t21
  br i1 %t22, label %genref_ok_4, label %genref_stale_5
genref_ok_4:
  %t23 = load %Point*, %Point** @arena.Entities.data
  %t24 = getelementptr inbounds %Point, %Point* %t23, i64 %t15
  %t25 = load %Point, %Point* %t24
  br label %genref_end_6
genref_stale_5:
  br label %genref_end_6
genref_end_6:
  %t26 = phi %Point [ %t25, %genref_ok_4 ], [ zeroinitializer, %genref_stale_5 ]
  store %Point %t26, %Point* %t10
  %t27 = getelementptr inbounds %Point, %Point* %t10, i32 0, i32 0
  %t28 = load i32, i32* %t27
  %t29 = getelementptr inbounds %Point, %Point* %t10, i32 0, i32 1
  %t30 = load i32, i32* %t29
  %t31 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t31, i32 %t28, i32 %t30)
  %t32 = load %Point*, %Point** @arena.Entities.data
  %t33 = icmp eq %Point* %t32, null
  br i1 %t33, label %spawn_init_7, label %spawn_ready_8
spawn_init_7:
  %t34 = getelementptr %Point, %Point* null, i32 1
  %t35 = ptrtoint %Point* %t34 to i64
  %t36 = mul i64 %t35, 1024
  %t37 = call i8* @malloc(i64 %t36)
  %t38 = bitcast i8* %t37 to %Point*
  store %Point* %t38, %Point** @arena.Entities.data
  br label %spawn_ready_8
spawn_ready_8:
  %t39 = load %Point*, %Point** @arena.Entities.data
  %t40 = load i64, i64* @arena.Entities.free_top
  %t41 = icmp sgt i64 %t40, 0
  br i1 %t41, label %spawn_reuse_9, label %spawn_grow_10
spawn_reuse_9:
  %t42 = sub i64 %t40, 1
  store i64 %t42, i64* @arena.Entities.free_top
  %t43 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t42
  %t44 = load i64, i64* %t43
  br label %spawn_store_11
spawn_grow_10:
  %t45 = load i64, i64* @arena.Entities.count
  %t46 = icmp slt i64 %t45, 1024
  br i1 %t46, label %spawn_grow_ok_13, label %spawn_capacity_warn_14
spawn_capacity_warn_14:
  %t47 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t47)
  br label %spawn_end_12
spawn_grow_ok_13:
  %t48 = add i64 %t45, 1
  store i64 %t48, i64* @arena.Entities.count
  br label %spawn_store_11
spawn_store_11:
  %t49 = phi i64 [ %t44, %spawn_reuse_9 ], [ %t45, %spawn_grow_ok_13 ]
  %t50 = alloca %Point
  %t51 = getelementptr inbounds %Point, %Point* %t50, i32 0, i32 0
  store i32 999, i32* %t51
  %t52 = getelementptr inbounds %Point, %Point* %t50, i32 0, i32 1
  store i32 999, i32* %t52
  %t53 = load %Point, %Point* %t50
  %t54 = getelementptr inbounds %Point, %Point* %t39, i64 %t49
  store %Point %t53, %Point* %t54
  %t55 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t49
  %t56 = load i32, i32* %t55
  %t57 = add i32 %t56, 1
  store i32 %t57, i32* %t55
  br label %spawn_end_12
spawn_end_12:
  %t58 = alloca %GenRef
  %t59 = sext i32 5 to i64
  %t60 = icmp ult i64 %t59, 1024
  br i1 %t60, label %genref_create_ok_15, label %genref_create_oob_16
genref_create_ok_15:
  %t61 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t59
  %t62 = load i32, i32* %t61
  br label %genref_create_end_17
genref_create_oob_16:
  br label %genref_create_end_17
genref_create_end_17:
  %t63 = phi i32 [ %t62, %genref_create_ok_15 ], [ 0, %genref_create_oob_16 ]
  %t64 = alloca %GenRef
  %t65 = getelementptr inbounds %GenRef, %GenRef* %t64, i32 0, i32 0
  store i32 5, i32* %t65
  %t66 = getelementptr inbounds %GenRef, %GenRef* %t64, i32 0, i32 1
  store i32 %t63, i32* %t66
  %t67 = load %GenRef, %GenRef* %t64
  store %GenRef %t67, %GenRef* %t58
  %t68 = alloca %Point
  %t69 = getelementptr inbounds %GenRef, %GenRef* %t58, i32 0, i32 0
  %t70 = load i32, i32* %t69
  %t71 = getelementptr inbounds %GenRef, %GenRef* %t58, i32 0, i32 1
  %t72 = load i32, i32* %t71
  %t73 = sext i32 %t70 to i64
  %t74 = icmp ult i64 %t73, 1024
  br i1 %t74, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t75 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t73
  %t76 = load i32, i32* %t75
  %t77 = icmp eq i32 %t72, %t76
  %t78 = and i32 %t76, 1
  %t79 = icmp eq i32 %t78, 1
  %t80 = and i1 %t77, %t79
  br i1 %t80, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t81 = load %Point*, %Point** @arena.Entities.data
  %t82 = getelementptr inbounds %Point, %Point* %t81, i64 %t73
  %t83 = load %Point, %Point* %t82
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t84 = phi %Point [ %t83, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Point %t84, %Point* %t68
  %t85 = getelementptr inbounds %Point, %Point* %t68, i32 0, i32 0
  %t86 = load i32, i32* %t85
  %t87 = getelementptr inbounds %Point, %Point* %t68, i32 0, i32 1
  %t88 = load i32, i32* %t87
  %t89 = getelementptr inbounds [53 x i8], [53 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t89, i32 %t86, i32 %t88)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [29 x i8] c"before any spawn: x=%d y=%d\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [53 x i8] c"other slot live, this slot never spawned: x=%d y=%d\0A\00"
