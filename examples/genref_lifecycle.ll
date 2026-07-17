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
  %t36 = alloca %Entity
  %t66 = alloca %Entity
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
  %t37 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 0
  %t38 = load i32, i32* %t37
  %t39 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 1
  %t40 = load i32, i32* %t39
  %t41 = sext i32 %t38 to i64
  %t42 = icmp ult i64 %t41, 1024
  br i1 %t42, label %genref_check_11, label %genref_stale_13
genref_check_11:
  %t43 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t41
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t40, %t44
  %t46 = and i32 %t44, 1
  %t47 = icmp eq i32 %t46, 1
  %t48 = and i1 %t45, %t47
  br i1 %t48, label %genref_ok_12, label %genref_stale_13
genref_ok_12:
  %t49 = load %Entity*, %Entity** @arena.Entities.data
  %t50 = getelementptr inbounds %Entity, %Entity* %t49, i64 %t41
  %t51 = load %Entity, %Entity* %t50
  br label %genref_end_14
genref_stale_13:
  br label %genref_end_14
genref_end_14:
  %t52 = phi %Entity [ %t51, %genref_ok_12 ], [ zeroinitializer, %genref_stale_13 ]
  store %Entity %t52, %Entity* %t36
  %t53 = getelementptr inbounds %Entity, %Entity* %t36, i32 0, i32 0
  %t54 = load i32, i32* %t53
  %t55 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t55, i32 %t54)
  %t56 = sext i32 0 to i64
  %t57 = icmp ult i64 %t56, 1024
  br i1 %t57, label %despawn_do_15, label %despawn_end_16
despawn_do_15:
  %t58 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t56
  %t59 = load i32, i32* %t58
  %t60 = and i32 %t59, 1
  %t61 = icmp eq i32 %t60, 1
  br i1 %t61, label %despawn_live_17, label %despawn_end_16
despawn_live_17:
  %t62 = add i32 %t59, 1
  store i32 %t62, i32* %t58
  %t63 = load i64, i64* @arena.Entities.free_top
  %t64 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t63
  store i64 %t56, i64* %t64
  %t65 = add i64 %t63, 1
  store i64 %t65, i64* @arena.Entities.free_top
  br label %despawn_end_16
despawn_end_16:
  %t67 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 0
  %t68 = load i32, i32* %t67
  %t69 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 1
  %t70 = load i32, i32* %t69
  %t71 = sext i32 %t68 to i64
  %t72 = icmp ult i64 %t71, 1024
  br i1 %t72, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t73 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t71
  %t74 = load i32, i32* %t73
  %t75 = icmp eq i32 %t70, %t74
  %t76 = and i32 %t74, 1
  %t77 = icmp eq i32 %t76, 1
  %t78 = and i1 %t75, %t77
  br i1 %t78, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t79 = load %Entity*, %Entity** @arena.Entities.data
  %t80 = getelementptr inbounds %Entity, %Entity* %t79, i64 %t71
  %t81 = load %Entity, %Entity* %t80
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t82 = phi %Entity [ %t81, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Entity %t82, %Entity* %t66
  %t83 = getelementptr inbounds %Entity, %Entity* %t66, i32 0, i32 0
  %t84 = load i32, i32* %t83
  %t85 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t85, i32 %t84)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [12 x i8] c"before: %d\0A\00"
@.str.2 = private unnamed_addr constant [11 x i8] c"after: %d\0A\00"
