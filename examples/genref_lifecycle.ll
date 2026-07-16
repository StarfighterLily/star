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
  %t35 = alloca %Entity
  %t65 = alloca %Entity
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
  %t36 = getelementptr inbounds %GenRef, %GenRef* %t25, i32 0, i32 0
  %t37 = load i32, i32* %t36
  %t38 = getelementptr inbounds %GenRef, %GenRef* %t25, i32 0, i32 1
  %t39 = load i32, i32* %t38
  %t40 = sext i32 %t37 to i64
  %t41 = icmp ult i64 %t40, 1024
  br i1 %t41, label %genref_check_11, label %genref_stale_13
genref_check_11:
  %t42 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t40
  %t43 = load i32, i32* %t42
  %t44 = icmp eq i32 %t39, %t43
  %t45 = and i32 %t43, 1
  %t46 = icmp eq i32 %t45, 1
  %t47 = and i1 %t44, %t46
  br i1 %t47, label %genref_ok_12, label %genref_stale_13
genref_ok_12:
  %t48 = load %Entity*, %Entity** @arena.Entities.data
  %t49 = getelementptr inbounds %Entity, %Entity* %t48, i64 %t40
  %t50 = load %Entity, %Entity* %t49
  br label %genref_end_14
genref_stale_13:
  br label %genref_end_14
genref_end_14:
  %t51 = phi %Entity [ %t50, %genref_ok_12 ], [ zeroinitializer, %genref_stale_13 ]
  store %Entity %t51, %Entity* %t35
  %t52 = getelementptr inbounds %Entity, %Entity* %t35, i32 0, i32 0
  %t53 = load i32, i32* %t52
  %t54 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t54, i32 %t53)
  %t55 = sext i32 0 to i64
  %t56 = icmp ult i64 %t55, 1024
  br i1 %t56, label %despawn_do_15, label %despawn_end_16
despawn_do_15:
  %t57 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t55
  %t58 = load i32, i32* %t57
  %t59 = and i32 %t58, 1
  %t60 = icmp eq i32 %t59, 1
  br i1 %t60, label %despawn_live_17, label %despawn_end_16
despawn_live_17:
  %t61 = add i32 %t58, 1
  store i32 %t61, i32* %t57
  %t62 = load i64, i64* @arena.Entities.free_top
  %t63 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t62
  store i64 %t55, i64* %t63
  %t64 = add i64 %t62, 1
  store i64 %t64, i64* @arena.Entities.free_top
  br label %despawn_end_16
despawn_end_16:
  %t66 = getelementptr inbounds %GenRef, %GenRef* %t25, i32 0, i32 0
  %t67 = load i32, i32* %t66
  %t68 = getelementptr inbounds %GenRef, %GenRef* %t25, i32 0, i32 1
  %t69 = load i32, i32* %t68
  %t70 = sext i32 %t67 to i64
  %t71 = icmp ult i64 %t70, 1024
  br i1 %t71, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t72 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t70
  %t73 = load i32, i32* %t72
  %t74 = icmp eq i32 %t69, %t73
  %t75 = and i32 %t73, 1
  %t76 = icmp eq i32 %t75, 1
  %t77 = and i1 %t74, %t76
  br i1 %t77, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t78 = load %Entity*, %Entity** @arena.Entities.data
  %t79 = getelementptr inbounds %Entity, %Entity* %t78, i64 %t70
  %t80 = load %Entity, %Entity* %t79
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t81 = phi %Entity [ %t80, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Entity %t81, %Entity* %t65
  %t82 = getelementptr inbounds %Entity, %Entity* %t65, i32 0, i32 0
  %t83 = load i32, i32* %t82
  %t84 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t84, i32 %t83)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [12 x i8] c"before: %d\0A\00"
@.str.2 = private unnamed_addr constant [11 x i8] c"after: %d\0A\00"
