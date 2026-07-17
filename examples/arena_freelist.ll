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
  %t26 = alloca %GenRef
  %t32 = alloca %GenRef
  %t64 = alloca %Entity
  %t71 = alloca %GenRef
  %t77 = alloca %GenRef
  %t81 = alloca %Entity
  %t98 = alloca %Entity
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
  %t27 = sext i32 0 to i64
  %t28 = icmp ult i64 %t27, 1024
  br i1 %t28, label %genref_create_ok_8, label %genref_create_oob_9
genref_create_ok_8:
  %t29 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t27
  %t30 = load i32, i32* %t29
  br label %genref_create_end_10
genref_create_oob_9:
  br label %genref_create_end_10
genref_create_end_10:
  %t31 = phi i32 [ %t30, %genref_create_ok_8 ], [ 0, %genref_create_oob_9 ]
  %t33 = getelementptr inbounds %GenRef, %GenRef* %t32, i32 0, i32 0
  store i32 0, i32* %t33
  %t34 = getelementptr inbounds %GenRef, %GenRef* %t32, i32 0, i32 1
  store i32 %t31, i32* %t34
  %t35 = load %GenRef, %GenRef* %t32
  store %GenRef %t35, %GenRef* %t26
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
  %t72 = sext i32 0 to i64
  %t73 = icmp ult i64 %t72, 1024
  br i1 %t73, label %genref_create_ok_22, label %genref_create_oob_23
genref_create_ok_22:
  %t74 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t72
  %t75 = load i32, i32* %t74
  br label %genref_create_end_24
genref_create_oob_23:
  br label %genref_create_end_24
genref_create_end_24:
  %t76 = phi i32 [ %t75, %genref_create_ok_22 ], [ 0, %genref_create_oob_23 ]
  %t78 = getelementptr inbounds %GenRef, %GenRef* %t77, i32 0, i32 0
  store i32 0, i32* %t78
  %t79 = getelementptr inbounds %GenRef, %GenRef* %t77, i32 0, i32 1
  store i32 %t76, i32* %t79
  %t80 = load %GenRef, %GenRef* %t77
  store %GenRef %t80, %GenRef* %t71
  %t82 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 0
  %t83 = load i32, i32* %t82
  %t84 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 1
  %t85 = load i32, i32* %t84
  %t86 = sext i32 %t83 to i64
  %t87 = icmp ult i64 %t86, 1024
  br i1 %t87, label %genref_check_25, label %genref_stale_27
genref_check_25:
  %t88 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t86
  %t89 = load i32, i32* %t88
  %t90 = icmp eq i32 %t85, %t89
  %t91 = and i32 %t89, 1
  %t92 = icmp eq i32 %t91, 1
  %t93 = and i1 %t90, %t92
  br i1 %t93, label %genref_ok_26, label %genref_stale_27
genref_ok_26:
  %t94 = load %Entity*, %Entity** @arena.Entities.data
  %t95 = getelementptr inbounds %Entity, %Entity* %t94, i64 %t86
  %t96 = load %Entity, %Entity* %t95
  br label %genref_end_28
genref_stale_27:
  br label %genref_end_28
genref_end_28:
  %t97 = phi %Entity [ %t96, %genref_ok_26 ], [ zeroinitializer, %genref_stale_27 ]
  store %Entity %t97, %Entity* %t81
  %t99 = getelementptr inbounds %GenRef, %GenRef* %t71, i32 0, i32 0
  %t100 = load i32, i32* %t99
  %t101 = getelementptr inbounds %GenRef, %GenRef* %t71, i32 0, i32 1
  %t102 = load i32, i32* %t101
  %t103 = sext i32 %t100 to i64
  %t104 = icmp ult i64 %t103, 1024
  br i1 %t104, label %genref_check_29, label %genref_stale_31
genref_check_29:
  %t105 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t103
  %t106 = load i32, i32* %t105
  %t107 = icmp eq i32 %t102, %t106
  %t108 = and i32 %t106, 1
  %t109 = icmp eq i32 %t108, 1
  %t110 = and i1 %t107, %t109
  br i1 %t110, label %genref_ok_30, label %genref_stale_31
genref_ok_30:
  %t111 = load %Entity*, %Entity** @arena.Entities.data
  %t112 = getelementptr inbounds %Entity, %Entity* %t111, i64 %t103
  %t113 = load %Entity, %Entity* %t112
  br label %genref_end_32
genref_stale_31:
  br label %genref_end_32
genref_end_32:
  %t114 = phi %Entity [ %t113, %genref_ok_30 ], [ zeroinitializer, %genref_stale_31 ]
  store %Entity %t114, %Entity* %t98
  %t115 = getelementptr inbounds %Entity, %Entity* %t81, i32 0, i32 0
  %t116 = load i32, i32* %t115
  %t117 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t117, i32 %t116)
  %t118 = getelementptr inbounds %Entity, %Entity* %t98, i32 0, i32 0
  %t119 = load i32, i32* %t118
  %t120 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t120, i32 %t119)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [13 x i8] c"via_old: %d\0A\00"
@.str.3 = private unnamed_addr constant [13 x i8] c"via_new: %d\0A\00"
