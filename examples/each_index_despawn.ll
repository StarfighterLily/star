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
declare i8* @strstr(i8*, i8*)
declare i32 @strncmp(i8*, i8*, i64)
@str.empty = private unnamed_addr constant [1 x i8] c"\00"
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
declare i32 @SDL_Init(i32)
declare i8* @SDL_CreateWindow(i8*, i32, i32, i32, i32, i32)
declare i8* @SDL_CreateRenderer(i8*, i32, i32)
declare i8* @SDL_GetRenderer(i8*)
declare void @SDL_DestroyRenderer(i8*)
declare void @SDL_DestroyWindow(i8*)
declare i32 @SDL_SetRenderDrawColor(i8*, i8, i8, i8, i8)
declare i32 @SDL_RenderClear(i8*)
declare i32 @SDL_RenderDrawPoint(i8*, i32, i32)
declare i32 @SDL_RenderFillRect(i8*, i8*)
declare i32 @SDL_RenderDrawLine(i8*, i32, i32, i32, i32)
declare void @SDL_RenderPresent(i8*)
declare i32 @SDL_PollEvent(i8*)
declare i8* @SDL_GetKeyboardState(i32*)
declare i32 @SDL_GetMouseState(i32*, i32*)
declare void @SDL_Delay(i32)
declare i32 @SDL_GetTicks()
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
declare float @llvm.sin.f32(float)
declare float @llvm.cos.f32(float)
declare float @llvm.tan.f32(float)
declare float @llvm.asin.f32(float)
declare float @llvm.acos.f32(float)
declare float @llvm.atan.f32(float)
declare float @llvm.atan2.f32(float, float)
declare float @llvm.exp.f32(float)
declare float @llvm.exp2.f32(float)
declare float @llvm.log.f32(float)
declare float @llvm.log2.f32(float)
declare float @llvm.log10.f32(float)
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

%Particle = type { i32, i1 }
%Particles = type { %Particle*, i64 }
@arena.Particles.data = global %Particle* null
@arena.Particles.count = global i64 0
@arena.Particles.gen = global [1024 x i64] zeroinitializer
@arena.Particles.free = global [1024 x i64] zeroinitializer
@arena.Particles.free_top = global i64 0
@arena.Particles.warned = global i1 0

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t21 = alloca %Particle
  %t48 = alloca %Particle
  %t75 = alloca %Particle
  %t102 = alloca %Particle
  %t112 = alloca i64
  %t121 = alloca i32
  %t133 = alloca i64
  %t142 = alloca i32
  %t160 = alloca i64
  %t169 = alloca i32
  %t194 = alloca %Particle
  %t205 = alloca i64
  %t214 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = load %Particle*, %Particle** @arena.Particles.data
  %t3 = icmp eq %Particle* %t2, null
  br i1 %t3, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t4 = getelementptr %Particle, %Particle* null, i32 1
  %t5 = ptrtoint %Particle* %t4 to i64
  %t6 = mul i64 %t5, 1024
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to %Particle*
  store %Particle* %t8, %Particle** @arena.Particles.data
  br label %spawn_ready_1
spawn_ready_1:
  %t9 = load %Particle*, %Particle** @arena.Particles.data
  %t10 = load i64, i64* @arena.Particles.free_top
  %t11 = icmp sgt i64 %t10, 0
  br i1 %t11, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t12 = sub i64 %t10, 1
  store i64 %t12, i64* @arena.Particles.free_top
  %t13 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t12
  %t14 = load i64, i64* %t13
  br label %spawn_store_4
spawn_grow_3:
  %t15 = load i64, i64* @arena.Particles.count
  %t16 = icmp slt i64 %t15, 1024
  br i1 %t16, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t17 = load i1, i1* @arena.Particles.warned
  br i1 %t17, label %spawn_end_5, label %spawn_warn_print_8
spawn_warn_print_8:
  store i1 1, i1* @arena.Particles.warned
  %t18 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t18)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* @arena.Particles.count
  br label %spawn_store_4
spawn_store_4:
  %t20 = phi i64 [ %t14, %spawn_reuse_2 ], [ %t15, %spawn_grow_ok_6 ]
  %t22 = getelementptr inbounds %Particle, %Particle* %t21, i32 0, i32 0
  store i32 1, i32* %t22
  %t23 = getelementptr inbounds %Particle, %Particle* %t21, i32 0, i32 1
  store i1 false, i1* %t23
  %t24 = load %Particle, %Particle* %t21
  %t25 = getelementptr inbounds %Particle, %Particle* %t9, i64 %t20
  store %Particle %t24, %Particle* %t25
  %t26 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t20
  %t27 = load i64, i64* %t26
  %t28 = add i64 %t27, 1
  store i64 %t28, i64* %t26
  br label %spawn_end_5
spawn_end_5:
  %t29 = load %Particle*, %Particle** @arena.Particles.data
  %t30 = icmp eq %Particle* %t29, null
  br i1 %t30, label %spawn_init_9, label %spawn_ready_10
spawn_init_9:
  %t31 = getelementptr %Particle, %Particle* null, i32 1
  %t32 = ptrtoint %Particle* %t31 to i64
  %t33 = mul i64 %t32, 1024
  %t34 = call i8* @malloc(i64 %t33)
  %t35 = bitcast i8* %t34 to %Particle*
  store %Particle* %t35, %Particle** @arena.Particles.data
  br label %spawn_ready_10
spawn_ready_10:
  %t36 = load %Particle*, %Particle** @arena.Particles.data
  %t37 = load i64, i64* @arena.Particles.free_top
  %t38 = icmp sgt i64 %t37, 0
  br i1 %t38, label %spawn_reuse_11, label %spawn_grow_12
spawn_reuse_11:
  %t39 = sub i64 %t37, 1
  store i64 %t39, i64* @arena.Particles.free_top
  %t40 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t39
  %t41 = load i64, i64* %t40
  br label %spawn_store_13
spawn_grow_12:
  %t42 = load i64, i64* @arena.Particles.count
  %t43 = icmp slt i64 %t42, 1024
  br i1 %t43, label %spawn_grow_ok_15, label %spawn_capacity_warn_16
spawn_capacity_warn_16:
  %t44 = load i1, i1* @arena.Particles.warned
  br i1 %t44, label %spawn_end_14, label %spawn_warn_print_17
spawn_warn_print_17:
  store i1 1, i1* @arena.Particles.warned
  %t45 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t45)
  br label %spawn_end_14
spawn_grow_ok_15:
  %t46 = add i64 %t42, 1
  store i64 %t46, i64* @arena.Particles.count
  br label %spawn_store_13
spawn_store_13:
  %t47 = phi i64 [ %t41, %spawn_reuse_11 ], [ %t42, %spawn_grow_ok_15 ]
  %t49 = getelementptr inbounds %Particle, %Particle* %t48, i32 0, i32 0
  store i32 2, i32* %t49
  %t50 = getelementptr inbounds %Particle, %Particle* %t48, i32 0, i32 1
  store i1 false, i1* %t50
  %t51 = load %Particle, %Particle* %t48
  %t52 = getelementptr inbounds %Particle, %Particle* %t36, i64 %t47
  store %Particle %t51, %Particle* %t52
  %t53 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t47
  %t54 = load i64, i64* %t53
  %t55 = add i64 %t54, 1
  store i64 %t55, i64* %t53
  br label %spawn_end_14
spawn_end_14:
  %t56 = load %Particle*, %Particle** @arena.Particles.data
  %t57 = icmp eq %Particle* %t56, null
  br i1 %t57, label %spawn_init_18, label %spawn_ready_19
spawn_init_18:
  %t58 = getelementptr %Particle, %Particle* null, i32 1
  %t59 = ptrtoint %Particle* %t58 to i64
  %t60 = mul i64 %t59, 1024
  %t61 = call i8* @malloc(i64 %t60)
  %t62 = bitcast i8* %t61 to %Particle*
  store %Particle* %t62, %Particle** @arena.Particles.data
  br label %spawn_ready_19
spawn_ready_19:
  %t63 = load %Particle*, %Particle** @arena.Particles.data
  %t64 = load i64, i64* @arena.Particles.free_top
  %t65 = icmp sgt i64 %t64, 0
  br i1 %t65, label %spawn_reuse_20, label %spawn_grow_21
spawn_reuse_20:
  %t66 = sub i64 %t64, 1
  store i64 %t66, i64* @arena.Particles.free_top
  %t67 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t66
  %t68 = load i64, i64* %t67
  br label %spawn_store_22
spawn_grow_21:
  %t69 = load i64, i64* @arena.Particles.count
  %t70 = icmp slt i64 %t69, 1024
  br i1 %t70, label %spawn_grow_ok_24, label %spawn_capacity_warn_25
spawn_capacity_warn_25:
  %t71 = load i1, i1* @arena.Particles.warned
  br i1 %t71, label %spawn_end_23, label %spawn_warn_print_26
spawn_warn_print_26:
  store i1 1, i1* @arena.Particles.warned
  %t72 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t72)
  br label %spawn_end_23
spawn_grow_ok_24:
  %t73 = add i64 %t69, 1
  store i64 %t73, i64* @arena.Particles.count
  br label %spawn_store_22
spawn_store_22:
  %t74 = phi i64 [ %t68, %spawn_reuse_20 ], [ %t69, %spawn_grow_ok_24 ]
  %t76 = getelementptr inbounds %Particle, %Particle* %t75, i32 0, i32 0
  store i32 3, i32* %t76
  %t77 = getelementptr inbounds %Particle, %Particle* %t75, i32 0, i32 1
  store i1 false, i1* %t77
  %t78 = load %Particle, %Particle* %t75
  %t79 = getelementptr inbounds %Particle, %Particle* %t63, i64 %t74
  store %Particle %t78, %Particle* %t79
  %t80 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t74
  %t81 = load i64, i64* %t80
  %t82 = add i64 %t81, 1
  store i64 %t82, i64* %t80
  br label %spawn_end_23
spawn_end_23:
  %t83 = load %Particle*, %Particle** @arena.Particles.data
  %t84 = icmp eq %Particle* %t83, null
  br i1 %t84, label %spawn_init_27, label %spawn_ready_28
spawn_init_27:
  %t85 = getelementptr %Particle, %Particle* null, i32 1
  %t86 = ptrtoint %Particle* %t85 to i64
  %t87 = mul i64 %t86, 1024
  %t88 = call i8* @malloc(i64 %t87)
  %t89 = bitcast i8* %t88 to %Particle*
  store %Particle* %t89, %Particle** @arena.Particles.data
  br label %spawn_ready_28
spawn_ready_28:
  %t90 = load %Particle*, %Particle** @arena.Particles.data
  %t91 = load i64, i64* @arena.Particles.free_top
  %t92 = icmp sgt i64 %t91, 0
  br i1 %t92, label %spawn_reuse_29, label %spawn_grow_30
spawn_reuse_29:
  %t93 = sub i64 %t91, 1
  store i64 %t93, i64* @arena.Particles.free_top
  %t94 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t93
  %t95 = load i64, i64* %t94
  br label %spawn_store_31
spawn_grow_30:
  %t96 = load i64, i64* @arena.Particles.count
  %t97 = icmp slt i64 %t96, 1024
  br i1 %t97, label %spawn_grow_ok_33, label %spawn_capacity_warn_34
spawn_capacity_warn_34:
  %t98 = load i1, i1* @arena.Particles.warned
  br i1 %t98, label %spawn_end_32, label %spawn_warn_print_35
spawn_warn_print_35:
  store i1 1, i1* @arena.Particles.warned
  %t99 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t99)
  br label %spawn_end_32
spawn_grow_ok_33:
  %t100 = add i64 %t96, 1
  store i64 %t100, i64* @arena.Particles.count
  br label %spawn_store_31
spawn_store_31:
  %t101 = phi i64 [ %t95, %spawn_reuse_29 ], [ %t96, %spawn_grow_ok_33 ]
  %t103 = getelementptr inbounds %Particle, %Particle* %t102, i32 0, i32 0
  store i32 4, i32* %t103
  %t104 = getelementptr inbounds %Particle, %Particle* %t102, i32 0, i32 1
  store i1 false, i1* %t104
  %t105 = load %Particle, %Particle* %t102
  %t106 = getelementptr inbounds %Particle, %Particle* %t90, i64 %t101
  store %Particle %t105, %Particle* %t106
  %t107 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t101
  %t108 = load i64, i64* %t107
  %t109 = add i64 %t108, 1
  store i64 %t109, i64* %t107
  br label %spawn_end_32
spawn_end_32:
  %t110 = load %Particle*, %Particle** @arena.Particles.data
  %t111 = load i64, i64* @arena.Particles.count
  store i64 0, i64* %t112
  br label %each_cond_36
each_cond_36:
  %t113 = load i64, i64* %t112
  %t114 = icmp slt i64 %t113, %t111
  br i1 %t114, label %each_body_37, label %each_end_40
each_body_37:
  %t115 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t113
  %t116 = load i64, i64* %t115
  %t117 = and i64 %t116, 1
  %t118 = icmp eq i64 %t117, 1
  br i1 %t118, label %each_live_38, label %each_step_39
each_live_38:
  %t119 = getelementptr inbounds %Particle, %Particle* %t110, i64 %t113
  %t120 = trunc i64 %t113 to i32
  store i32 %t120, i32* %t121
  %t122 = getelementptr inbounds %Particle, %Particle* %t119, i32 0, i32 0
  %t123 = load i32, i32* %t122
  %t124 = icmp eq i32 %t123, 2
  br i1 %t124, label %logic_short_42, label %logic_rhs_41
logic_rhs_41:
  %t125 = getelementptr inbounds %Particle, %Particle* %t119, i32 0, i32 0
  %t126 = load i32, i32* %t125
  %t127 = icmp eq i32 %t126, 4
  br label %logic_end_43
logic_short_42:
  br label %logic_end_43
logic_end_43:
  %t128 = phi i1 [ %t127, %logic_rhs_41 ], [ true, %logic_short_42 ]
  br i1 %t128, label %if_then_44, label %if_else_45
if_then_44:
  %t129 = getelementptr inbounds %Particle, %Particle* %t119, i32 0, i32 1
  store i1 true, i1* %t129
  br label %if_end_46
if_else_45:
  br label %if_end_46
if_end_46:
  br label %each_step_39
each_step_39:
  %t130 = add i64 %t113, 1
  store i64 %t130, i64* %t112
  br label %each_cond_36
each_end_40:
  %t131 = load %Particle*, %Particle** @arena.Particles.data
  %t132 = load i64, i64* @arena.Particles.count
  store i64 0, i64* %t133
  br label %each_cond_47
each_cond_47:
  %t134 = load i64, i64* %t133
  %t135 = icmp slt i64 %t134, %t132
  br i1 %t135, label %each_body_48, label %each_end_51
each_body_48:
  %t136 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t134
  %t137 = load i64, i64* %t136
  %t138 = and i64 %t137, 1
  %t139 = icmp eq i64 %t138, 1
  br i1 %t139, label %each_live_49, label %each_step_50
each_live_49:
  %t140 = getelementptr inbounds %Particle, %Particle* %t131, i64 %t134
  %t141 = trunc i64 %t134 to i32
  store i32 %t141, i32* %t142
  %t143 = getelementptr inbounds %Particle, %Particle* %t140, i32 0, i32 1
  %t144 = load i1, i1* %t143
  br i1 %t144, label %if_then_52, label %if_else_53
if_then_52:
  %t145 = load i32, i32* %t142
  %t146 = sext i32 %t145 to i64
  %t147 = icmp ult i64 %t146, 1024
  br i1 %t147, label %despawn_do_55, label %despawn_end_56
despawn_do_55:
  %t148 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t146
  %t149 = load i64, i64* %t148
  %t150 = and i64 %t149, 1
  %t151 = icmp eq i64 %t150, 1
  br i1 %t151, label %despawn_live_57, label %despawn_end_56
despawn_live_57:
  %t152 = add i64 %t149, 1
  store i64 %t152, i64* %t148
  %t153 = load i64, i64* @arena.Particles.free_top
  %t154 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t153
  store i64 %t146, i64* %t154
  %t155 = add i64 %t153, 1
  store i64 %t155, i64* @arena.Particles.free_top
  br label %despawn_end_56
despawn_end_56:
  br label %if_end_54
if_else_53:
  br label %if_end_54
if_end_54:
  br label %each_step_50
each_step_50:
  %t156 = add i64 %t134, 1
  store i64 %t156, i64* %t133
  br label %each_cond_47
each_end_51:
  %t157 = getelementptr inbounds { i64, i8*, [29 x i8] }, { i64, i8*, [29 x i8] }* @.str.4, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t157)
  call i32 (i8*, ...) @printf(i8* %t157)
  %t158 = load %Particle*, %Particle** @arena.Particles.data
  %t159 = load i64, i64* @arena.Particles.count
  store i64 0, i64* %t160
  br label %each_cond_58
each_cond_58:
  %t161 = load i64, i64* %t160
  %t162 = icmp slt i64 %t161, %t159
  br i1 %t162, label %each_body_59, label %each_end_62
each_body_59:
  %t163 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t161
  %t164 = load i64, i64* %t163
  %t165 = and i64 %t164, 1
  %t166 = icmp eq i64 %t165, 1
  br i1 %t166, label %each_live_60, label %each_step_61
each_live_60:
  %t167 = getelementptr inbounds %Particle, %Particle* %t158, i64 %t161
  %t168 = trunc i64 %t161 to i32
  store i32 %t168, i32* %t169
  %t170 = load i32, i32* %t169
  %t171 = getelementptr inbounds %Particle, %Particle* %t167, i32 0, i32 0
  %t172 = load i32, i32* %t171
  %t173 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t173, i32 %t170, i32 %t172)
  br label %each_step_61
each_step_61:
  %t174 = add i64 %t161, 1
  store i64 %t174, i64* %t160
  br label %each_cond_58
each_end_62:
  %t175 = load %Particle*, %Particle** @arena.Particles.data
  %t176 = icmp eq %Particle* %t175, null
  br i1 %t176, label %spawn_init_63, label %spawn_ready_64
spawn_init_63:
  %t177 = getelementptr %Particle, %Particle* null, i32 1
  %t178 = ptrtoint %Particle* %t177 to i64
  %t179 = mul i64 %t178, 1024
  %t180 = call i8* @malloc(i64 %t179)
  %t181 = bitcast i8* %t180 to %Particle*
  store %Particle* %t181, %Particle** @arena.Particles.data
  br label %spawn_ready_64
spawn_ready_64:
  %t182 = load %Particle*, %Particle** @arena.Particles.data
  %t183 = load i64, i64* @arena.Particles.free_top
  %t184 = icmp sgt i64 %t183, 0
  br i1 %t184, label %spawn_reuse_65, label %spawn_grow_66
spawn_reuse_65:
  %t185 = sub i64 %t183, 1
  store i64 %t185, i64* @arena.Particles.free_top
  %t186 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t185
  %t187 = load i64, i64* %t186
  br label %spawn_store_67
spawn_grow_66:
  %t188 = load i64, i64* @arena.Particles.count
  %t189 = icmp slt i64 %t188, 1024
  br i1 %t189, label %spawn_grow_ok_69, label %spawn_capacity_warn_70
spawn_capacity_warn_70:
  %t190 = load i1, i1* @arena.Particles.warned
  br i1 %t190, label %spawn_end_68, label %spawn_warn_print_71
spawn_warn_print_71:
  store i1 1, i1* @arena.Particles.warned
  %t191 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t191)
  br label %spawn_end_68
spawn_grow_ok_69:
  %t192 = add i64 %t188, 1
  store i64 %t192, i64* @arena.Particles.count
  br label %spawn_store_67
spawn_store_67:
  %t193 = phi i64 [ %t187, %spawn_reuse_65 ], [ %t188, %spawn_grow_ok_69 ]
  %t195 = getelementptr inbounds %Particle, %Particle* %t194, i32 0, i32 0
  store i32 99, i32* %t195
  %t196 = getelementptr inbounds %Particle, %Particle* %t194, i32 0, i32 1
  store i1 false, i1* %t196
  %t197 = load %Particle, %Particle* %t194
  %t198 = getelementptr inbounds %Particle, %Particle* %t182, i64 %t193
  store %Particle %t197, %Particle* %t198
  %t199 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t193
  %t200 = load i64, i64* %t199
  %t201 = add i64 %t200, 1
  store i64 %t201, i64* %t199
  br label %spawn_end_68
spawn_end_68:
  %t202 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.7, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t202)
  call i32 (i8*, ...) @printf(i8* %t202)
  %t203 = load %Particle*, %Particle** @arena.Particles.data
  %t204 = load i64, i64* @arena.Particles.count
  store i64 0, i64* %t205
  br label %each_cond_72
each_cond_72:
  %t206 = load i64, i64* %t205
  %t207 = icmp slt i64 %t206, %t204
  br i1 %t207, label %each_body_73, label %each_end_76
each_body_73:
  %t208 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t206
  %t209 = load i64, i64* %t208
  %t210 = and i64 %t209, 1
  %t211 = icmp eq i64 %t210, 1
  br i1 %t211, label %each_live_74, label %each_step_75
each_live_74:
  %t212 = getelementptr inbounds %Particle, %Particle* %t203, i64 %t206
  %t213 = trunc i64 %t206 to i32
  store i32 %t213, i32* %t214
  %t215 = load i32, i32* %t214
  %t216 = getelementptr inbounds %Particle, %Particle* %t212, i32 0, i32 0
  %t217 = load i32, i32* %t216
  %t218 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t218, i32 %t215, i32 %t217)
  br label %each_step_75
each_step_75:
  %t219 = add i64 %t206, 1
  store i64 %t219, i64* %t205
  br label %each_cond_72
each_end_76:
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.2 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.3 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [29 x i8] } { i64 -1, i8* null, [29 x i8] c"after reclaiming dead slots:\00" }
@.str.5 = private unnamed_addr constant [18 x i8] c"  slot %d: hp=%d\0A\00"
@.str.6 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"after respawn:\00" }
@.str.8 = private unnamed_addr constant [18 x i8] c"  slot %d: hp=%d\0A\00"
