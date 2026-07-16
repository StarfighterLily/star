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

%Point = type { i32, i32 }
%Projectile = type { i32, i32 }
%EnemyArena = type { %Point*, i64 }
@arena.EnemyArena.data = global %Point* null
@arena.EnemyArena.count = global i64 0
@arena.EnemyArena.gen = global [1024 x i32] zeroinitializer
@arena.EnemyArena.free = global [1024 x i64] zeroinitializer
@arena.EnemyArena.free_top = global i64 0

%ProjectileArena = type { %Projectile*, i64 }
@arena.ProjectileArena.data = global %Projectile* null
@arena.ProjectileArena.count = global i64 0
@arena.ProjectileArena.gen = global [1024 x i32] zeroinitializer
@arena.ProjectileArena.free = global [1024 x i64] zeroinitializer
@arena.ProjectileArena.free_top = global i64 0

define i32 @calculate_path(i32 %start_x, i32 %start_y) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  %t12 = alloca %Point
  %t25 = alloca %Point
  store i32 %start_x, i32* %t0
  store i32 %start_y, i32* %t1
  %t2 = load i64, i64* @frame.off
  %t3 = getelementptr %Point, %Point* null, i32 1
  %t4 = ptrtoint %Point* %t3 to i64
  %t5 = load i64, i64* @frame.off
  %t6 = add i64 %t5, %t4
  %t7 = icmp ugt i64 %t6, 4096
  br i1 %t7, label %frame_alloc_fail_0, label %frame_alloc_ok_1
frame_alloc_fail_0:
  %t8 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t8)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_1:
  store i64 %t6, i64* @frame.off
  %t9 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t10 = getelementptr inbounds i8, i8* %t9, i64 %t5
  %t11 = bitcast i8* %t10 to %Point*
  %t13 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 0
  store i32 0, i32* %t13
  %t14 = getelementptr inbounds %Point, %Point* %t12, i32 0, i32 1
  store i32 0, i32* %t14
  %t15 = load %Point, %Point* %t12
  store %Point %t15, %Point* %t11
  %t16 = getelementptr %Point, %Point* null, i32 1
  %t17 = ptrtoint %Point* %t16 to i64
  %t18 = load i64, i64* @frame.off
  %t19 = add i64 %t18, %t17
  %t20 = icmp ugt i64 %t19, 4096
  br i1 %t20, label %frame_alloc_fail_2, label %frame_alloc_ok_3
frame_alloc_fail_2:
  %t21 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t21)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_3:
  store i64 %t19, i64* @frame.off
  %t22 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t23 = getelementptr inbounds i8, i8* %t22, i64 %t18
  %t24 = bitcast i8* %t23 to %Point*
  %t26 = load i32, i32* %t0
  %t27 = getelementptr inbounds %Point, %Point* %t25, i32 0, i32 0
  store i32 %t26, i32* %t27
  %t28 = load i32, i32* %t1
  %t29 = getelementptr inbounds %Point, %Point* %t25, i32 0, i32 1
  store i32 %t28, i32* %t29
  %t30 = load %Point, %Point* %t25
  store %Point %t30, %Point* %t24
  %t31 = getelementptr inbounds %Point, %Point* %t11, i32 0, i32 0
  %t32 = load i32, i32* %t31
  %t33 = getelementptr inbounds %Point, %Point* %t24, i32 0, i32 1
  %t34 = load i32, i32* %t33
  %t35 = add i32 %t32, %t34
  store i64 %t2, i64* @frame.off
  ret i32 %t35
}

define i32 @spawn_enemy(i32 %x, i32 %y) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  store i32 %x, i32* %t0
  store i32 %y, i32* %t1
  %t2 = load i32, i32* %t0
  ret i32 %t2
}

define i32 @spawn_projectile(i32 %x, i32 %y) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  store i32 %x, i32* %t0
  store i32 %y, i32* %t1
  %t2 = load i32, i32* %t1
  ret i32 %t2
}

define %GenRef @create_entity_reference(i32 %idx) {
entry:
  %t0 = alloca i32
  %t7 = alloca %GenRef
  store i32 %idx, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = sext i32 %t1 to i64
  %t3 = icmp ult i64 %t2, 1024
  br i1 %t3, label %genref_create_ok_4, label %genref_create_oob_5
genref_create_ok_4:
  %t4 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t2
  %t5 = load i32, i32* %t4
  br label %genref_create_end_6
genref_create_oob_5:
  br label %genref_create_end_6
genref_create_end_6:
  %t6 = phi i32 [ %t5, %genref_create_ok_4 ], [ 0, %genref_create_oob_5 ]
  %t8 = getelementptr inbounds %GenRef, %GenRef* %t7, i32 0, i32 0
  store i32 %t1, i32* %t8
  %t9 = getelementptr inbounds %GenRef, %GenRef* %t7, i32 0, i32 1
  store i32 %t6, i32* %t9
  %t10 = load %GenRef, %GenRef* %t7
  ret %GenRef %t10
}

define i32 @follow_reference(%GenRef %gen_ref) {
entry:
  %t0 = alloca %GenRef
  %t15 = alloca %Point
  store %GenRef %gen_ref, %GenRef* %t0
  %t1 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 0
  %t2 = load i32, i32* %t1
  %t3 = getelementptr inbounds %GenRef, %GenRef* %t0, i32 0, i32 1
  %t4 = load i32, i32* %t3
  %t5 = sext i32 %t2 to i64
  %t6 = icmp ult i64 %t5, 1024
  br i1 %t6, label %genref_place_check_7, label %genref_place_stale_9
genref_place_check_7:
  %t7 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t5
  %t8 = load i32, i32* %t7
  %t9 = icmp eq i32 %t4, %t8
  %t10 = and i32 %t8, 1
  %t11 = icmp eq i32 %t10, 1
  %t12 = and i1 %t9, %t11
  br i1 %t12, label %genref_place_ok_8, label %genref_place_stale_9
genref_place_ok_8:
  %t13 = load %Point*, %Point** @arena.EnemyArena.data
  %t14 = getelementptr inbounds %Point, %Point* %t13, i64 %t5
  br label %genref_place_end_10
genref_place_stale_9:
  store %Point zeroinitializer, %Point* %t15
  br label %genref_place_end_10
genref_place_end_10:
  %t16 = phi %Point* [ %t14, %genref_place_ok_8 ], [ %t15, %genref_place_stale_9 ]
  %t17 = getelementptr inbounds %Point, %Point* %t16, i32 0, i32 0
  %t18 = load i32, i32* %t17
  ret i32 %t18
}

define void @game_tick() {
entry:
  %t19 = alloca %Point
  %t0 = load i64, i64* @frame.off
  %t1 = load %Point*, %Point** @arena.EnemyArena.data
  %t2 = icmp eq %Point* %t1, null
  br i1 %t2, label %spawn_init_11, label %spawn_ready_12
spawn_init_11:
  %t3 = getelementptr %Point, %Point* null, i32 1
  %t4 = ptrtoint %Point* %t3 to i64
  %t5 = mul i64 %t4, 1024
  %t6 = call i8* @malloc(i64 %t5)
  %t7 = bitcast i8* %t6 to %Point*
  store %Point* %t7, %Point** @arena.EnemyArena.data
  br label %spawn_ready_12
spawn_ready_12:
  %t8 = load %Point*, %Point** @arena.EnemyArena.data
  %t9 = load i64, i64* @arena.EnemyArena.free_top
  %t10 = icmp sgt i64 %t9, 0
  br i1 %t10, label %spawn_reuse_13, label %spawn_grow_14
spawn_reuse_13:
  %t11 = sub i64 %t9, 1
  store i64 %t11, i64* @arena.EnemyArena.free_top
  %t12 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.EnemyArena.free, i64 0, i64 %t11
  %t13 = load i64, i64* %t12
  br label %spawn_store_15
spawn_grow_14:
  %t14 = load i64, i64* @arena.EnemyArena.count
  %t15 = icmp slt i64 %t14, 1024
  br i1 %t15, label %spawn_grow_ok_17, label %spawn_capacity_warn_18
spawn_capacity_warn_18:
  %t16 = getelementptr inbounds [88 x i8], [88 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t16)
  br label %spawn_end_16
spawn_grow_ok_17:
  %t17 = add i64 %t14, 1
  store i64 %t17, i64* @arena.EnemyArena.count
  br label %spawn_store_15
spawn_store_15:
  %t18 = phi i64 [ %t13, %spawn_reuse_13 ], [ %t14, %spawn_grow_ok_17 ]
  %t20 = getelementptr inbounds %Point, %Point* %t19, i32 0, i32 0
  store i32 42, i32* %t20
  %t21 = getelementptr inbounds %Point, %Point* %t19, i32 0, i32 1
  store i32 0, i32* %t21
  %t22 = load %Point, %Point* %t19
  %t23 = getelementptr inbounds %Point, %Point* %t8, i64 %t18
  store %Point %t22, %Point* %t23
  %t24 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.EnemyArena.gen, i64 0, i64 %t18
  %t25 = load i32, i32* %t24
  %t26 = add i32 %t25, 1
  store i32 %t26, i32* %t24
  br label %spawn_end_16
spawn_end_16:
  %t27 = getelementptr i32, i32* null, i32 1
  %t28 = ptrtoint i32* %t27 to i64
  %t29 = load i64, i64* @frame.off
  %t30 = add i64 %t29, %t28
  %t31 = icmp ugt i64 %t30, 4096
  br i1 %t31, label %frame_alloc_fail_19, label %frame_alloc_ok_20
frame_alloc_fail_19:
  %t32 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t32)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_20:
  store i64 %t30, i64* @frame.off
  %t33 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t34 = getelementptr inbounds i8, i8* %t33, i64 %t29
  %t35 = bitcast i8* %t34 to i32*
  store i32 0, i32* %t35
  %t36 = getelementptr %GenRef, %GenRef* null, i32 1
  %t37 = ptrtoint %GenRef* %t36 to i64
  %t38 = load i64, i64* @frame.off
  %t39 = add i64 %t38, %t37
  %t40 = icmp ugt i64 %t39, 4096
  br i1 %t40, label %frame_alloc_fail_21, label %frame_alloc_ok_22
frame_alloc_fail_21:
  %t41 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t41)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_22:
  store i64 %t39, i64* @frame.off
  %t42 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t43 = getelementptr inbounds i8, i8* %t42, i64 %t38
  %t44 = bitcast i8* %t43 to %GenRef*
  %t45 = call %GenRef @create_entity_reference(i32 0)
  store %GenRef %t45, %GenRef* %t44
  %t46 = load i32, i32* %t35
  %t47 = load %GenRef, %GenRef* %t44
  %t48 = call i32 @follow_reference(%GenRef %t47)
  %t49 = add i32 %t46, %t48
  store i64 %t0, i64* @frame.off
  ret void
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t0 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t1 = call i32 @calculate_path(i32 5, i32 10)
  store i32 %t1, i32* %t0
  %t2 = load i32, i32* %t0
  %t3 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t3, i32 %t2)
  call void @game_tick()
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.1 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.2 = private unnamed_addr constant [88 x i8] c"star runtime warning: arena `EnemyArena` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.4 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.5 = private unnamed_addr constant [29 x i8] c"Path calculation result: %d\0A\00"
