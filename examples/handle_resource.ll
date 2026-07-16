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

%Texture = type { i32, i32 }
%Textures = type { %Texture*, i64 }
@arena.Textures.data = global %Texture* null
@arena.Textures.count = global i64 0
@arena.Textures.gen = global [1024 x i32] zeroinitializer
@arena.Textures.free = global [1024 x i64] zeroinitializer
@arena.Textures.free_top = global i64 0

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t18 = alloca %Texture
  %t26 = alloca %GenRef
  %t32 = alloca %GenRef
  %t36 = alloca %Texture
  %t68 = alloca %Texture
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = load %Texture*, %Texture** @arena.Textures.data
  %t1 = icmp eq %Texture* %t0, null
  br i1 %t1, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t2 = getelementptr %Texture, %Texture* null, i32 1
  %t3 = ptrtoint %Texture* %t2 to i64
  %t4 = mul i64 %t3, 1024
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to %Texture*
  store %Texture* %t6, %Texture** @arena.Textures.data
  br label %spawn_ready_1
spawn_ready_1:
  %t7 = load %Texture*, %Texture** @arena.Textures.data
  %t8 = load i64, i64* @arena.Textures.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Textures.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_4
spawn_grow_3:
  %t13 = load i64, i64* @arena.Textures.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t15 = getelementptr inbounds [86 x i8], [86 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t15)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t16 = add i64 %t13, 1
  store i64 %t16, i64* @arena.Textures.count
  br label %spawn_store_4
spawn_store_4:
  %t17 = phi i64 [ %t12, %spawn_reuse_2 ], [ %t13, %spawn_grow_ok_6 ]
  %t19 = getelementptr inbounds %Texture, %Texture* %t18, i32 0, i32 0
  store i32 256, i32* %t19
  %t20 = getelementptr inbounds %Texture, %Texture* %t18, i32 0, i32 1
  store i32 256, i32* %t20
  %t21 = load %Texture, %Texture* %t18
  %t22 = getelementptr inbounds %Texture, %Texture* %t7, i64 %t17
  store %Texture %t21, %Texture* %t22
  %t23 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Textures.gen, i64 0, i64 %t17
  %t24 = load i32, i32* %t23
  %t25 = add i32 %t24, 1
  store i32 %t25, i32* %t23
  br label %spawn_end_5
spawn_end_5:
  %t27 = sext i32 0 to i64
  %t28 = icmp ult i64 %t27, 1024
  br i1 %t28, label %genref_create_ok_8, label %genref_create_oob_9
genref_create_ok_8:
  %t29 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Textures.gen, i64 0, i64 %t27
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
  %t43 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Textures.gen, i64 0, i64 %t41
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t40, %t44
  %t46 = and i32 %t44, 1
  %t47 = icmp eq i32 %t46, 1
  %t48 = and i1 %t45, %t47
  br i1 %t48, label %genref_ok_12, label %genref_stale_13
genref_ok_12:
  %t49 = load %Texture*, %Texture** @arena.Textures.data
  %t50 = getelementptr inbounds %Texture, %Texture* %t49, i64 %t41
  %t51 = load %Texture, %Texture* %t50
  br label %genref_end_14
genref_stale_13:
  br label %genref_end_14
genref_end_14:
  %t52 = phi %Texture [ %t51, %genref_ok_12 ], [ zeroinitializer, %genref_stale_13 ]
  store %Texture %t52, %Texture* %t36
  %t53 = getelementptr inbounds %Texture, %Texture* %t36, i32 0, i32 0
  %t54 = load i32, i32* %t53
  %t55 = getelementptr inbounds %Texture, %Texture* %t36, i32 0, i32 1
  %t56 = load i32, i32* %t55
  %t57 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t57, i32 %t54, i32 %t56)
  %t58 = sext i32 0 to i64
  %t59 = icmp ult i64 %t58, 1024
  br i1 %t59, label %despawn_do_15, label %despawn_end_16
despawn_do_15:
  %t60 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Textures.gen, i64 0, i64 %t58
  %t61 = load i32, i32* %t60
  %t62 = and i32 %t61, 1
  %t63 = icmp eq i32 %t62, 1
  br i1 %t63, label %despawn_live_17, label %despawn_end_16
despawn_live_17:
  %t64 = add i32 %t61, 1
  store i32 %t64, i32* %t60
  %t65 = load i64, i64* @arena.Textures.free_top
  %t66 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Textures.free, i64 0, i64 %t65
  store i64 %t58, i64* %t66
  %t67 = add i64 %t65, 1
  store i64 %t67, i64* @arena.Textures.free_top
  br label %despawn_end_16
despawn_end_16:
  %t69 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 0
  %t70 = load i32, i32* %t69
  %t71 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 1
  %t72 = load i32, i32* %t71
  %t73 = sext i32 %t70 to i64
  %t74 = icmp ult i64 %t73, 1024
  br i1 %t74, label %genref_check_18, label %genref_stale_20
genref_check_18:
  %t75 = getelementptr inbounds [1024 x i32], [1024 x i32]* @arena.Textures.gen, i64 0, i64 %t73
  %t76 = load i32, i32* %t75
  %t77 = icmp eq i32 %t72, %t76
  %t78 = and i32 %t76, 1
  %t79 = icmp eq i32 %t78, 1
  %t80 = and i1 %t77, %t79
  br i1 %t80, label %genref_ok_19, label %genref_stale_20
genref_ok_19:
  %t81 = load %Texture*, %Texture** @arena.Textures.data
  %t82 = getelementptr inbounds %Texture, %Texture* %t81, i64 %t73
  %t83 = load %Texture, %Texture* %t82
  br label %genref_end_21
genref_stale_20:
  br label %genref_end_21
genref_end_21:
  %t84 = phi %Texture [ %t83, %genref_ok_19 ], [ zeroinitializer, %genref_stale_20 ]
  store %Texture %t84, %Texture* %t68
  %t85 = getelementptr inbounds %Texture, %Texture* %t68, i32 0, i32 0
  %t86 = load i32, i32* %t85
  %t87 = getelementptr inbounds %Texture, %Texture* %t68, i32 0, i32 1
  %t88 = load i32, i32* %t87
  %t89 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t89, i32 %t86, i32 %t88)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [86 x i8] c"star runtime warning: arena `Textures` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [22 x i8] c"before unload: %dx%d\0A\00"
@.str.2 = private unnamed_addr constant [21 x i8] c"after unload: %dx%d\0A\00"
