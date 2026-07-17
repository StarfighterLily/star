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

%Point = type { i32, i32 }
%Entities = type { %Point*, i64 }
@arena.Entities.data = global %Point* null
@arena.Entities.count = global i64 0
@arena.Entities.gen = global [1024 x i32] zeroinitializer
@arena.Entities.free = global [1024 x i64] zeroinitializer
@arena.Entities.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t1 = alloca %GenRef
  %t7 = alloca %GenRef
  %t11 = alloca %Point
  %t51 = alloca %Point
  %t59 = alloca %GenRef
  %t65 = alloca %GenRef
  %t69 = alloca %Point
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t2 = sext i32 0 to i64
  %t3 = icmp ult i64 %t2, 1024
  br i1 %t3, label %genref_create_ok_0, label %genref_create_oob_1
genref_create_ok_0:
  %t4 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t2
  %t5 = load i32, i32* %t4
  br label %genref_create_end_2
genref_create_oob_1:
  br label %genref_create_end_2
genref_create_end_2:
  %t6 = phi i32 [ %t5, %genref_create_ok_0 ], [ 0, %genref_create_oob_1 ]
  %t8 = getelementptr inbounds %GenRef, %GenRef* %t7, i32 0, i32 0
  store i32 0, i32* %t8
  %t9 = getelementptr inbounds %GenRef, %GenRef* %t7, i32 0, i32 1
  store i32 %t6, i32* %t9
  %t10 = load %GenRef, %GenRef* %t7
  store %GenRef %t10, %GenRef* %t1
  %t12 = getelementptr inbounds %GenRef, %GenRef* %t1, i32 0, i32 0
  %t13 = load i32, i32* %t12
  %t14 = getelementptr inbounds %GenRef, %GenRef* %t1, i32 0, i32 1
  %t15 = load i32, i32* %t14
  %t16 = sext i32 %t13 to i64
  %t17 = icmp ult i64 %t16, 1024
  br i1 %t17, label %genref_check_3, label %genref_stale_5
genref_check_3:
  %t18 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t16
  %t19 = load i32, i32* %t18
  %t20 = icmp eq i32 %t15, %t19
  %t21 = and i32 %t19, 1
  %t22 = icmp eq i32 %t21, 1
  %t23 = and i1 %t20, %t22
  br i1 %t23, label %genref_ok_4, label %genref_stale_5
genref_ok_4:
  %t24 = load %Point*, %Point** @arena.Entities.data
  %t25 = getelementptr inbounds %Point, %Point* %t24, i64 %t16
  %t26 = load %Point, %Point* %t25
  br label %genref_end_6
genref_stale_5:
  br label %genref_end_6
genref_end_6:
  %t27 = phi %Point [ %t26, %genref_ok_4 ], [ zeroinitializer, %genref_stale_5 ]
  store %Point %t27, %Point* %t11
  %t28 = getelementptr inbounds %Point, %Point* %t11, i32 0, i32 0
  %t29 = load i32, i32* %t28
  %t30 = getelementptr inbounds %Point, %Point* %t11, i32 0, i32 1
  %t31 = load i32, i32* %t30
  %t32 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t32, i32 %t29, i32 %t31)
  %t33 = load %Point*, %Point** @arena.Entities.data
  %t34 = icmp eq %Point* %t33, null
  br i1 %t34, label %spawn_init_7, label %spawn_ready_8
spawn_init_7:
  %t35 = getelementptr %Point, %Point* null, i32 1
  %t36 = ptrtoint %Point* %t35 to i64
  %t37 = mul i64 %t36, 1024
  %t38 = call i8* @malloc(i64 %t37)
  %t39 = bitcast i8* %t38 to %Point*
  store %Point* %t39, %Point** @arena.Entities.data
  br label %spawn_ready_8
spawn_ready_8:
  %t40 = load %Point*, %Point** @arena.Entities.data
  %t41 = load i64, i64* @arena.Entities.free_top
  %t42 = icmp sgt i64 %t41, 0
  br i1 %t42, label %spawn_reuse_9, label %spawn_grow_10
spawn_reuse_9:
  %t43 = sub i64 %t41, 1
  store i64 %t43, i64* @arena.Entities.free_top
  %t44 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Entities.free, i64 0, i64 %t43
  %t45 = load i64, i64* %t44
  br label %spawn_store_11
spawn_grow_10:
  %t46 = load i64, i64* @arena.Entities.count
  %t47 = icmp slt i64 %t46, 1024
  br i1 %t47, label %spawn_grow_ok_13, label %spawn_capacity_warn_14
spawn_capacity_warn_14:
  %t48 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t48)
  br label %spawn_end_12
spawn_grow_ok_13:
  %t49 = add i64 %t46, 1
  store i64 %t49, i64* @arena.Entities.count
  br label %spawn_store_11
spawn_store_11:
  %t50 = phi i64 [ %t45, %spawn_reuse_9 ], [ %t46, %spawn_grow_ok_13 ]
  %t52 = getelementptr inbounds %Point, %Point* %t51, i32 0, i32 0
  store i32 999, i32* %t52
  %t53 = getelementptr inbounds %Point, %Point* %t51, i32 0, i32 1
  store i32 999, i32* %t53
  %t54 = load %Point, %Point* %t51
  %t55 = getelementptr inbounds %Point, %Point* %t40, i64 %t50
  store %Point %t54, %Point* %t55
  %t56 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t50
  %t57 = load i32, i32* %t56
  %t58 = add i32 %t57, 1
  store i32 %t58, i32* %t56
  br label %spawn_end_12
spawn_end_12:
  %t60 = sext i32 5 to i64
  %t61 = icmp ult i64 %t60, 1024
  br i1 %t61, label %genref_create_ok_15, label %genref_create_oob_16
genref_create_ok_15:
  %t62 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t60
  %t63 = load i32, i32* %t62
  br label %genref_create_end_17
genref_create_oob_16:
  br label %genref_create_end_17
genref_create_end_17:
  %t64 = phi i32 [ %t63, %genref_create_ok_15 ], [ 0, %genref_create_oob_16 ]
  %t66 = getelementptr inbounds %GenRef, %GenRef* %t65, i32 0, i32 0
  store i32 5, i32* %t66
  %t67 = getelementptr inbounds %GenRef, %GenRef* %t65, i32 0, i32 1
  store i32 %t64, i32* %t67
  %t68 = load %GenRef, %GenRef* %t65
  store %GenRef %t68, %GenRef* %t59
  %t70 = getelementptr inbounds %GenRef, %GenRef* %t59, i32 0, i32 0
  %t71 = load i32, i32* %t70
  %t72 = getelementptr inbounds %GenRef, %GenRef* %t59, i32 0, i32 1
  %t73 = load i32, i32* %t72
  %t74 = sext i32 %t71 to i64
  %t75 = icmp ult i64 %t74, 1024
  br i1 %t75, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t76 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Entities.gen, i64 0, i64 %t74
  %t77 = load i32, i32* %t76
  %t78 = icmp eq i32 %t73, %t77
  %t79 = and i32 %t77, 1
  %t80 = icmp eq i32 %t79, 1
  %t81 = and i1 %t78, %t80
  br i1 %t81, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t82 = load %Point*, %Point** @arena.Entities.data
  %t83 = getelementptr inbounds %Point, %Point* %t82, i64 %t74
  %t84 = load %Point, %Point* %t83
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t85 = phi %Point [ %t84, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Point %t85, %Point* %t69
  %t86 = getelementptr inbounds %Point, %Point* %t69, i32 0, i32 0
  %t87 = load i32, i32* %t86
  %t88 = getelementptr inbounds %Point, %Point* %t69, i32 0, i32 1
  %t89 = load i32, i32* %t88
  %t90 = getelementptr inbounds [53 x i8], [53 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t90, i32 %t87, i32 %t89)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [29 x i8] c"before any spawn: x=%d y=%d\0A\00"
@.str.1 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Entities` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [53 x i8] c"other slot live, this slot never spawned: x=%d y=%d\0A\00"
