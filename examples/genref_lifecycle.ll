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
  %t27 = alloca %GenRef
  %t33 = alloca %GenRef
  %t37 = alloca %Entity
  %t67 = alloca %Entity
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
  %t28 = sext i32 0 to i64
  %t29 = icmp ult i64 %t28, 1024
  br i1 %t29, label %genref_create_ok_8, label %genref_create_oob_9
genref_create_ok_8:
  %t30 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t28
  %t31 = load i64, i64* %t30
  br label %genref_create_end_10
genref_create_oob_9:
  br label %genref_create_end_10
genref_create_end_10:
  %t32 = phi i64 [ %t31, %genref_create_ok_8 ], [ 0, %genref_create_oob_9 ]
  %t34 = getelementptr inbounds %GenRef, %GenRef* %t33, i32 0, i32 0
  store i32 0, i32* %t34
  %t35 = getelementptr inbounds %GenRef, %GenRef* %t33, i32 0, i32 1
  store i64 %t32, i64* %t35
  %t36 = load %GenRef, %GenRef* %t33
  store %GenRef %t36, %GenRef* %t27
  %t38 = getelementptr inbounds %GenRef, %GenRef* %t27, i32 0, i32 0
  %t39 = load i32, i32* %t38
  %t40 = getelementptr inbounds %GenRef, %GenRef* %t27, i32 0, i32 1
  %t41 = load i64, i64* %t40
  %t42 = sext i32 %t39 to i64
  %t43 = icmp ult i64 %t42, 1024
  br i1 %t43, label %genref_check_11, label %genref_stale_13
genref_check_11:
  %t44 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t42
  %t45 = load i64, i64* %t44
  %t46 = icmp eq i64 %t41, %t45
  %t47 = and i64 %t45, 1
  %t48 = icmp eq i64 %t47, 1
  %t49 = and i1 %t46, %t48
  br i1 %t49, label %genref_ok_12, label %genref_stale_13
genref_ok_12:
  %t50 = load %Entity*, %Entity** @arena.Entities.data
  %t51 = getelementptr inbounds %Entity, %Entity* %t50, i64 %t42
  %t52 = load %Entity, %Entity* %t51
  br label %genref_end_14
genref_stale_13:
  br label %genref_end_14
genref_end_14:
  %t53 = phi %Entity [ %t52, %genref_ok_12 ], [ zeroinitializer, %genref_stale_13 ]
  store %Entity %t53, %Entity* %t37
  %t54 = getelementptr inbounds %Entity, %Entity* %t37, i32 0, i32 0
  %t55 = load i32, i32* %t54
  %t56 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t56, i32 %t55)
  %t57 = sext i32 0 to i64
  %t58 = icmp ult i64 %t57, 1024
  br i1 %t58, label %despawn_do_15, label %despawn_end_16
despawn_do_15:
  %t59 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t57
  %t60 = load i64, i64* %t59
  %t61 = and i64 %t60, 1
  %t62 = icmp eq i64 %t61, 1
  br i1 %t62, label %despawn_live_17, label %despawn_end_16
despawn_live_17:
  %t63 = add i64 %t60, 1
  store i64 %t63, i64* %t59
  %t64 = load i64, i64* @arena.Entities.free_top
  %t65 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t64
  store i64 %t57, i64* %t65
  %t66 = add i64 %t64, 1
  store i64 %t66, i64* @arena.Entities.free_top
  br label %despawn_end_16
despawn_end_16:
  %t68 = getelementptr inbounds %GenRef, %GenRef* %t27, i32 0, i32 0
  %t69 = load i32, i32* %t68
  %t70 = getelementptr inbounds %GenRef, %GenRef* %t27, i32 0, i32 1
  %t71 = load i64, i64* %t70
  %t72 = sext i32 %t69 to i64
  %t73 = icmp ult i64 %t72, 1024
  br i1 %t73, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t74 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t72
  %t75 = load i64, i64* %t74
  %t76 = icmp eq i64 %t71, %t75
  %t77 = and i64 %t75, 1
  %t78 = icmp eq i64 %t77, 1
  %t79 = and i1 %t76, %t78
  br i1 %t79, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t80 = load %Entity*, %Entity** @arena.Entities.data
  %t81 = getelementptr inbounds %Entity, %Entity* %t80, i64 %t72
  %t82 = load %Entity, %Entity* %t81
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t83 = phi %Entity [ %t82, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Entity %t83, %Entity* %t67
  %t84 = getelementptr inbounds %Entity, %Entity* %t67, i32 0, i32 0
  %t85 = load i32, i32* %t84
  %t86 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t86, i32 %t85)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [12 x i8] c"before: %d\0A\00"
@.str.2 = private unnamed_addr constant [11 x i8] c"after: %d\0A\00"
