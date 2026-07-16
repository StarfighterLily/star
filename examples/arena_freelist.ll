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
  %t25 = alloca %GenRef
  %t31 = alloca %GenRef
  %t63 = alloca %Entity
  %t70 = alloca %GenRef
  %t76 = alloca %GenRef
  %t80 = alloca %Entity
  %t97 = alloca %Entity
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
  %t26 = sext i32 0 to i64
  %t27 = icmp ult i64 %t26, 1024
  br i1 %t27, label %genref_create_ok_8, label %genref_create_oob_9
genref_create_ok_8:
  %t28 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t26
  %t29 = load i32, i32* %t28
  br label %genref_create_end_10
genref_create_oob_9:
  br label %genref_create_end_10
genref_create_end_10:
  %t30 = phi i32 [ %t29, %genref_create_ok_8 ], [ 0, %genref_create_oob_9 ]
  %t32 = getelementptr inbounds %GenRef, %GenRef* %t31, i32 0, i32 0
  store i32 0, i32* %t32
  %t33 = getelementptr inbounds %GenRef, %GenRef* %t31, i32 0, i32 1
  store i32 %t30, i32* %t33
  %t34 = load %GenRef, %GenRef* %t31
  store %GenRef %t34, %GenRef* %t25
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
  %t71 = sext i32 0 to i64
  %t72 = icmp ult i64 %t71, 1024
  br i1 %t72, label %genref_create_ok_22, label %genref_create_oob_23
genref_create_ok_22:
  %t73 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t71
  %t74 = load i32, i32* %t73
  br label %genref_create_end_24
genref_create_oob_23:
  br label %genref_create_end_24
genref_create_end_24:
  %t75 = phi i32 [ %t74, %genref_create_ok_22 ], [ 0, %genref_create_oob_23 ]
  %t77 = getelementptr inbounds %GenRef, %GenRef* %t76, i32 0, i32 0
  store i32 0, i32* %t77
  %t78 = getelementptr inbounds %GenRef, %GenRef* %t76, i32 0, i32 1
  store i32 %t75, i32* %t78
  %t79 = load %GenRef, %GenRef* %t76
  store %GenRef %t79, %GenRef* %t70
  %t81 = getelementptr inbounds %GenRef, %GenRef* %t25, i32 0, i32 0
  %t82 = load i32, i32* %t81
  %t83 = getelementptr inbounds %GenRef, %GenRef* %t25, i32 0, i32 1
  %t84 = load i32, i32* %t83
  %t85 = sext i32 %t82 to i64
  %t86 = icmp ult i64 %t85, 1024
  br i1 %t86, label %genref_check_25, label %genref_stale_27
genref_check_25:
  %t87 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t85
  %t88 = load i32, i32* %t87
  %t89 = icmp eq i32 %t84, %t88
  %t90 = and i32 %t88, 1
  %t91 = icmp eq i32 %t90, 1
  %t92 = and i1 %t89, %t91
  br i1 %t92, label %genref_ok_26, label %genref_stale_27
genref_ok_26:
  %t93 = load %Entity*, %Entity** @arena.Entities.data
  %t94 = getelementptr inbounds %Entity, %Entity* %t93, i64 %t85
  %t95 = load %Entity, %Entity* %t94
  br label %genref_end_28
genref_stale_27:
  br label %genref_end_28
genref_end_28:
  %t96 = phi %Entity [ %t95, %genref_ok_26 ], [ zeroinitializer, %genref_stale_27 ]
  store %Entity %t96, %Entity* %t80
  %t98 = getelementptr inbounds %GenRef, %GenRef* %t70, i32 0, i32 0
  %t99 = load i32, i32* %t98
  %t100 = getelementptr inbounds %GenRef, %GenRef* %t70, i32 0, i32 1
  %t101 = load i32, i32* %t100
  %t102 = sext i32 %t99 to i64
  %t103 = icmp ult i64 %t102, 1024
  br i1 %t103, label %genref_check_29, label %genref_stale_31
genref_check_29:
  %t104 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t102
  %t105 = load i32, i32* %t104
  %t106 = icmp eq i32 %t101, %t105
  %t107 = and i32 %t105, 1
  %t108 = icmp eq i32 %t107, 1
  %t109 = and i1 %t106, %t108
  br i1 %t109, label %genref_ok_30, label %genref_stale_31
genref_ok_30:
  %t110 = load %Entity*, %Entity** @arena.Entities.data
  %t111 = getelementptr inbounds %Entity, %Entity* %t110, i64 %t102
  %t112 = load %Entity, %Entity* %t111
  br label %genref_end_32
genref_stale_31:
  br label %genref_end_32
genref_end_32:
  %t113 = phi %Entity [ %t112, %genref_ok_30 ], [ zeroinitializer, %genref_stale_31 ]
  store %Entity %t113, %Entity* %t97
  %t114 = getelementptr inbounds %Entity, %Entity* %t80, i32 0, i32 0
  %t115 = load i32, i32* %t114
  %t116 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t116, i32 %t115)
  %t117 = getelementptr inbounds %Entity, %Entity* %t97, i32 0, i32 0
  %t118 = load i32, i32* %t117
  %t119 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t119, i32 %t118)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [13 x i8] c"via_old: %d\0A\00"
@.str.3 = private unnamed_addr constant [13 x i8] c"via_new: %d\0A\00"
