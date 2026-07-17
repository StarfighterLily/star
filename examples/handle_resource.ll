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

%Texture = type { i32, i32 }
%Textures = type { %Texture*, i64 }
@arena.Textures.data = global %Texture* null
@arena.Textures.count = global i64 0
@arena.Textures.gen = global [1024 x i64] zeroinitializer
@arena.Textures.free = global [1024 x i64] zeroinitializer
@arena.Textures.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t20 = alloca %Texture
  %t28 = alloca %GenRef
  %t34 = alloca %GenRef
  %t38 = alloca %Texture
  %t70 = alloca %Texture
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = load %Texture*, %Texture** @arena.Textures.data
  %t3 = icmp eq %Texture* %t2, null
  br i1 %t3, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t4 = getelementptr %Texture, %Texture* null, i32 1
  %t5 = ptrtoint %Texture* %t4 to i64
  %t6 = mul i64 %t5, 1024
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to %Texture*
  store %Texture* %t8, %Texture** @arena.Textures.data
  br label %spawn_ready_1
spawn_ready_1:
  %t9 = load %Texture*, %Texture** @arena.Textures.data
  %t10 = load i64, i64* @arena.Textures.free_top
  %t11 = icmp sgt i64 %t10, 0
  br i1 %t11, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t12 = sub i64 %t10, 1
  store i64 %t12, i64* @arena.Textures.free_top
  %t13 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.free, i64 0, i64 %t12
  %t14 = load i64, i64* %t13
  br label %spawn_store_4
spawn_grow_3:
  %t15 = load i64, i64* @arena.Textures.count
  %t16 = icmp slt i64 %t15, 1024
  br i1 %t16, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t17 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t17)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t18 = add i64 %t15, 1
  store i64 %t18, i64* @arena.Textures.count
  br label %spawn_store_4
spawn_store_4:
  %t19 = phi i64 [ %t14, %spawn_reuse_2 ], [ %t15, %spawn_grow_ok_6 ]
  %t21 = getelementptr inbounds %Texture, %Texture* %t20, i32 0, i32 0
  store i32 256, i32* %t21
  %t22 = getelementptr inbounds %Texture, %Texture* %t20, i32 0, i32 1
  store i32 256, i32* %t22
  %t23 = load %Texture, %Texture* %t20
  %t24 = getelementptr inbounds %Texture, %Texture* %t9, i64 %t19
  store %Texture %t23, %Texture* %t24
  %t25 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.gen, i64 0, i64 %t19
  %t26 = load i64, i64* %t25
  %t27 = add i64 %t26, 1
  store i64 %t27, i64* %t25
  br label %spawn_end_5
spawn_end_5:
  %t29 = sext i32 0 to i64
  %t30 = icmp ult i64 %t29, 1024
  br i1 %t30, label %genref_create_ok_8, label %genref_create_oob_9
genref_create_ok_8:
  %t31 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.gen, i64 0, i64 %t29
  %t32 = load i64, i64* %t31
  br label %genref_create_end_10
genref_create_oob_9:
  br label %genref_create_end_10
genref_create_end_10:
  %t33 = phi i64 [ %t32, %genref_create_ok_8 ], [ 0, %genref_create_oob_9 ]
  %t35 = getelementptr inbounds %GenRef, %GenRef* %t34, i32 0, i32 0
  store i32 0, i32* %t35
  %t36 = getelementptr inbounds %GenRef, %GenRef* %t34, i32 0, i32 1
  store i64 %t33, i64* %t36
  %t37 = load %GenRef, %GenRef* %t34
  store %GenRef %t37, %GenRef* %t28
  %t39 = getelementptr inbounds %GenRef, %GenRef* %t28, i32 0, i32 0
  %t40 = load i32, i32* %t39
  %t41 = getelementptr inbounds %GenRef, %GenRef* %t28, i32 0, i32 1
  %t42 = load i64, i64* %t41
  %t43 = sext i32 %t40 to i64
  %t44 = icmp ult i64 %t43, 1024
  br i1 %t44, label %genref_check_11, label %genref_stale_13
genref_check_11:
  %t45 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.gen, i64 0, i64 %t43
  %t46 = load i64, i64* %t45
  %t47 = icmp eq i64 %t42, %t46
  %t48 = and i64 %t46, 1
  %t49 = icmp eq i64 %t48, 1
  %t50 = and i1 %t47, %t49
  br i1 %t50, label %genref_ok_12, label %genref_stale_13
genref_ok_12:
  %t51 = load %Texture*, %Texture** @arena.Textures.data
  %t52 = getelementptr inbounds %Texture, %Texture* %t51, i64 %t43
  %t53 = load %Texture, %Texture* %t52
  br label %genref_end_14
genref_stale_13:
  br label %genref_end_14
genref_end_14:
  %t54 = phi %Texture [ %t53, %genref_ok_12 ], [ zeroinitializer, %genref_stale_13 ]
  store %Texture %t54, %Texture* %t38
  %t55 = getelementptr inbounds %Texture, %Texture* %t38, i32 0, i32 0
  %t56 = load i32, i32* %t55
  %t57 = getelementptr inbounds %Texture, %Texture* %t38, i32 0, i32 1
  %t58 = load i32, i32* %t57
  %t59 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t59, i32 %t56, i32 %t58)
  %t60 = sext i32 0 to i64
  %t61 = icmp ult i64 %t60, 1024
  br i1 %t61, label %despawn_do_15, label %despawn_end_16
despawn_do_15:
  %t62 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.gen, i64 0, i64 %t60
  %t63 = load i64, i64* %t62
  %t64 = and i64 %t63, 1
  %t65 = icmp eq i64 %t64, 1
  br i1 %t65, label %despawn_live_17, label %despawn_end_16
despawn_live_17:
  %t66 = add i64 %t63, 1
  store i64 %t66, i64* %t62
  %t67 = load i64, i64* @arena.Textures.free_top
  %t68 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.free, i64 0, i64 %t67
  store i64 %t60, i64* %t68
  %t69 = add i64 %t67, 1
  store i64 %t69, i64* @arena.Textures.free_top
  br label %despawn_end_16
despawn_end_16:
  %t71 = getelementptr inbounds %GenRef, %GenRef* %t28, i32 0, i32 0
  %t72 = load i32, i32* %t71
  %t73 = getelementptr inbounds %GenRef, %GenRef* %t28, i32 0, i32 1
  %t74 = load i64, i64* %t73
  %t75 = sext i32 %t72 to i64
  %t76 = icmp ult i64 %t75, 1024
  br i1 %t76, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t77 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.gen, i64 0, i64 %t75
  %t78 = load i64, i64* %t77
  %t79 = icmp eq i64 %t74, %t78
  %t80 = and i64 %t78, 1
  %t81 = icmp eq i64 %t80, 1
  %t82 = and i1 %t79, %t81
  br i1 %t82, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t83 = load %Texture*, %Texture** @arena.Textures.data
  %t84 = getelementptr inbounds %Texture, %Texture* %t83, i64 %t75
  %t85 = load %Texture, %Texture* %t84
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t86 = phi %Texture [ %t85, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Texture %t86, %Texture* %t70
  %t87 = getelementptr inbounds %Texture, %Texture* %t70, i32 0, i32 0
  %t88 = load i32, i32* %t87
  %t89 = getelementptr inbounds %Texture, %Texture* %t70, i32 0, i32 1
  %t90 = load i32, i32* %t89
  %t91 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t91, i32 %t88, i32 %t90)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Textures` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [22 x i8] c"before unload: %dx%d\0A\00"
@.str.2 = private unnamed_addr constant [21 x i8] c"after unload: %dx%d\0A\00"
