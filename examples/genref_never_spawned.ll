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

%Point = type { i32, i32 }
%Entities = type { %Point*, i64 }
@arena.Entities.data = global %Point* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i64] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca %GenRef
  %t8 = alloca %GenRef
  %t12 = alloca %Point
  %t52 = alloca %Point
  %t60 = alloca %GenRef
  %t66 = alloca %GenRef
  %t70 = alloca %Point
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = sext i32 0 to i64
  %t4 = icmp ult i64 %t3, 1024
  br i1 %t4, label %genref_create_ok_0, label %genref_create_oob_1
genref_create_ok_0:
  %t5 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t3
  %t6 = load i64, i64* %t5
  br label %genref_create_end_2
genref_create_oob_1:
  br label %genref_create_end_2
genref_create_end_2:
  %t7 = phi i64 [ %t6, %genref_create_ok_0 ], [ 0, %genref_create_oob_1 ]
  %t9 = getelementptr inbounds %GenRef, %GenRef* %t8, i32 0, i32 0
  store i32 0, i32* %t9
  %t10 = getelementptr inbounds %GenRef, %GenRef* %t8, i32 0, i32 1
  store i64 %t7, i64* %t10
  %t11 = load %GenRef, %GenRef* %t8
  store %GenRef %t11, %GenRef* %t2
  %t13 = getelementptr inbounds %GenRef, %GenRef* %t2, i32 0, i32 0
  %t14 = load i32, i32* %t13
  %t15 = getelementptr inbounds %GenRef, %GenRef* %t2, i32 0, i32 1
  %t16 = load i64, i64* %t15
  %t17 = sext i32 %t14 to i64
  %t18 = icmp ult i64 %t17, 1024
  br i1 %t18, label %genref_check_3, label %genref_stale_5
genref_check_3:
  %t19 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t17
  %t20 = load i64, i64* %t19
  %t21 = icmp eq i64 %t16, %t20
  %t22 = and i64 %t20, 1
  %t23 = icmp eq i64 %t22, 1
  %t24 = and i1 %t21, %t23
  br i1 %t24, label %genref_ok_4, label %genref_stale_5
genref_ok_4:
  %t25 = load %Point*, %Point** @arena.Entities.data
  %t26 = getelementptr inbounds %Point, %Point* %t25, i64 %t17
  %t27 = load %Point, %Point* %t26
  br label %genref_end_6
genref_stale_5:
  br label %genref_end_6
genref_end_6:
  %t28 = phi %Point [ %t27, %genref_ok_4 ], [ zeroinitializer, %genref_stale_5 ]
  store %Point %t28, %Point* %t12
  %t29 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 0
  %t30 = load i32, i32* %t29
  %t31 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 1
  %t32 = load i32, i32* %t31
  %t33 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t33, i32 %t30, i32 %t32)
  %t34 = load %Point*, %Point** @arena.Entities.data
  %t35 = icmp eq %Point* %t34, null
  br i1 %t35, label %spawn_init_7, label %spawn_ready_8
spawn_init_7:
  %t36 = getelementptr %Point, %Point* null, i32 1
  %t37 = ptrtoint %Point* %t36 to i64
  %t38 = mul i64 %t37, 1024
  %t39 = call i8* @malloc(i64 %t38)
  %t40 = bitcast i8* %t39 to %Point*
  store %Point* %t40, %Point** @arena.Entities.data
  br label %spawn_ready_8
spawn_ready_8:
  %t41 = load %Point*, %Point** @arena.Entities.data
  %t42 = load i64, i64* @arena.Entities.free_top
  %t43 = icmp sgt i64 %t42, 0
  br i1 %t43, label %spawn_reuse_9, label %spawn_grow_10
spawn_reuse_9:
  %t44 = sub i64 %t42, 1
  store i64 %t44, i64* @arena.Entities.free_top
  %t45 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t44
  %t46 = load i64, i64* %t45
  br label %spawn_store_11
spawn_grow_10:
  %t47 = load i64, i64* @arena.Entities.count
  %t48 = icmp slt i64 %t47, 1024
  br i1 %t48, label %spawn_grow_ok_13, label %spawn_capacity_warn_14
spawn_capacity_warn_14:
  %t49 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t49)
  br label %spawn_end_12
spawn_grow_ok_13:
  %t50 = add i64 %t47, 1
  store i64 %t50, i64* @arena.Entities.count
  br label %spawn_store_11
spawn_store_11:
  %t51 = phi i64 [ %t46, %spawn_reuse_9 ], [ %t47, %spawn_grow_ok_13 ]
  %t53 = getelementptr inbounds %Point, %Point* %t52, i32 0, i32 0
  store i32 999, i32* %t53
  %t54 = getelementptr inbounds %Point, %Point* %t52, i32 0, i32 1
  store i32 999, i32* %t54
  %t55 = load %Point, %Point* %t52
  %t56 = getelementptr inbounds %Point, %Point* %t41, i64 %t51
  store %Point %t55, %Point* %t56
  %t57 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t51
  %t58 = load i64, i64* %t57
  %t59 = add i64 %t58, 1
  store i64 %t59, i64* %t57
  br label %spawn_end_12
spawn_end_12:
  %t61 = sext i32 5 to i64
  %t62 = icmp ult i64 %t61, 1024
  br i1 %t62, label %genref_create_ok_15, label %genref_create_oob_16
genref_create_ok_15:
  %t63 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t61
  %t64 = load i64, i64* %t63
  br label %genref_create_end_17
genref_create_oob_16:
  br label %genref_create_end_17
genref_create_end_17:
  %t65 = phi i64 [ %t64, %genref_create_ok_15 ], [ 0, %genref_create_oob_16 ]
  %t67 = getelementptr inbounds %GenRef, %GenRef* %t66, i32 0, i32 0
  store i32 5, i32* %t67
  %t68 = getelementptr inbounds %GenRef, %GenRef* %t66, i32 0, i32 1
  store i64 %t65, i64* %t68
  %t69 = load %GenRef, %GenRef* %t66
  store %GenRef %t69, %GenRef* %t60
  %t71 = getelementptr inbounds %GenRef, %GenRef* %t60, i32 0, i32 0
  %t72 = load i32, i32* %t71
  %t73 = getelementptr inbounds %GenRef, %GenRef* %t60, i32 0, i32 1
  %t74 = load i64, i64* %t73
  %t75 = sext i32 %t72 to i64
  %t76 = icmp ult i64 %t75, 1024
  br i1 %t76, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t77 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.gen, i64 0, i64 %t75
  %t78 = load i64, i64* %t77
  %t79 = icmp eq i64 %t74, %t78
  %t80 = and i64 %t78, 1
  %t81 = icmp eq i64 %t80, 1
  %t82 = and i1 %t79, %t81
  br i1 %t82, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t83 = load %Point*, %Point** @arena.Entities.data
  %t84 = getelementptr inbounds %Point, %Point* %t83, i64 %t75
  %t85 = load %Point, %Point* %t84
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t86 = phi %Point [ %t85, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Point %t86, %Point* %t70
  %t87 = getelementptr inbounds %Point, %Point* %t70, i32 0, i32 0
  %t88 = load i32, i32* %t87
  %t89 = getelementptr inbounds %Point, %Point* %t70, i32 0, i32 1
  %t90 = load i32, i32* %t89
  %t91 = getelementptr inbounds [53 x i8], [53 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t91, i32 %t88, i32 %t90)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [29 x i8] c"before any spawn: x=%d y=%d\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [53 x i8] c"other slot live, this slot never spawned: x=%d y=%d\0A\00"
