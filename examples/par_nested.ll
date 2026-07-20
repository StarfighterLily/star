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

%Enemy = type { i32 }
%Bullet = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i64] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0

%Bullets = type { %Bullet*, i64 }
@arena.Bullets.data = global %Bullet* null
@arena.Bullets.count = global i64 0
@arena.Bullets.gen = global [1024 x i64] zeroinitializer
@arena.Bullets.free = global [1024 x i64] zeroinitializer
@arena.Bullets.free_top = global i64 0

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t20 = alloca %Enemy
  %t45 = alloca %Enemy
  %t70 = alloca %Enemy
  %t95 = alloca %Bullet
  %t120 = alloca %Bullet
  %t145 = alloca %Bullet
  %t170 = alloca %Bullet
  %t373 = alloca { i64, i64 }
  %t386 = alloca { i64, i64 }
  %t399 = alloca { i64, i64 }
  %t412 = alloca { i64, i64 }
  %t438 = alloca { i64, i64 }
  %t486 = alloca { i64, i64 }
  %t499 = alloca { i64, i64 }
  %t512 = alloca { i64, i64 }
  %t525 = alloca { i64, i64 }
  %t551 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t3 = icmp eq %Enemy* %t2, null
  br i1 %t3, label %spawn_init_0, label %spawn_ready_1
spawn_init_0:
  %t4 = getelementptr %Enemy, %Enemy* null, i32 1
  %t5 = ptrtoint %Enemy* %t4 to i64
  %t6 = mul i64 %t5, 1024
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to %Enemy*
  store %Enemy* %t8, %Enemy** @arena.Enemies.data
  br label %spawn_ready_1
spawn_ready_1:
  %t9 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t10 = load i64, i64* @arena.Enemies.free_top
  %t11 = icmp sgt i64 %t10, 0
  br i1 %t11, label %spawn_reuse_2, label %spawn_grow_3
spawn_reuse_2:
  %t12 = sub i64 %t10, 1
  store i64 %t12, i64* @arena.Enemies.free_top
  %t13 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t12
  %t14 = load i64, i64* %t13
  br label %spawn_store_4
spawn_grow_3:
  %t15 = load i64, i64* @arena.Enemies.count
  %t16 = icmp slt i64 %t15, 1024
  br i1 %t16, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t17 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t17)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t18 = add i64 %t15, 1
  store i64 %t18, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t19 = phi i64 [ %t14, %spawn_reuse_2 ], [ %t15, %spawn_grow_ok_6 ]
  %t21 = getelementptr inbounds %Enemy, %Enemy* %t20, i32 0, i32 0
  store i32 10, i32* %t21
  %t22 = load %Enemy, %Enemy* %t20
  %t23 = getelementptr inbounds %Enemy, %Enemy* %t9, i64 %t19
  store %Enemy %t22, %Enemy* %t23
  %t24 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t19
  %t25 = load i64, i64* %t24
  %t26 = add i64 %t25, 1
  store i64 %t26, i64* %t24
  br label %spawn_end_5
spawn_end_5:
  %t27 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t28 = icmp eq %Enemy* %t27, null
  br i1 %t28, label %spawn_init_8, label %spawn_ready_9
spawn_init_8:
  %t29 = getelementptr %Enemy, %Enemy* null, i32 1
  %t30 = ptrtoint %Enemy* %t29 to i64
  %t31 = mul i64 %t30, 1024
  %t32 = call i8* @malloc(i64 %t31)
  %t33 = bitcast i8* %t32 to %Enemy*
  store %Enemy* %t33, %Enemy** @arena.Enemies.data
  br label %spawn_ready_9
spawn_ready_9:
  %t34 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t35 = load i64, i64* @arena.Enemies.free_top
  %t36 = icmp sgt i64 %t35, 0
  br i1 %t36, label %spawn_reuse_10, label %spawn_grow_11
spawn_reuse_10:
  %t37 = sub i64 %t35, 1
  store i64 %t37, i64* @arena.Enemies.free_top
  %t38 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t37
  %t39 = load i64, i64* %t38
  br label %spawn_store_12
spawn_grow_11:
  %t40 = load i64, i64* @arena.Enemies.count
  %t41 = icmp slt i64 %t40, 1024
  br i1 %t41, label %spawn_grow_ok_14, label %spawn_capacity_warn_15
spawn_capacity_warn_15:
  %t42 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t42)
  br label %spawn_end_13
spawn_grow_ok_14:
  %t43 = add i64 %t40, 1
  store i64 %t43, i64* @arena.Enemies.count
  br label %spawn_store_12
spawn_store_12:
  %t44 = phi i64 [ %t39, %spawn_reuse_10 ], [ %t40, %spawn_grow_ok_14 ]
  %t46 = getelementptr inbounds %Enemy, %Enemy* %t45, i32 0, i32 0
  store i32 10, i32* %t46
  %t47 = load %Enemy, %Enemy* %t45
  %t48 = getelementptr inbounds %Enemy, %Enemy* %t34, i64 %t44
  store %Enemy %t47, %Enemy* %t48
  %t49 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t44
  %t50 = load i64, i64* %t49
  %t51 = add i64 %t50, 1
  store i64 %t51, i64* %t49
  br label %spawn_end_13
spawn_end_13:
  %t52 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t53 = icmp eq %Enemy* %t52, null
  br i1 %t53, label %spawn_init_16, label %spawn_ready_17
spawn_init_16:
  %t54 = getelementptr %Enemy, %Enemy* null, i32 1
  %t55 = ptrtoint %Enemy* %t54 to i64
  %t56 = mul i64 %t55, 1024
  %t57 = call i8* @malloc(i64 %t56)
  %t58 = bitcast i8* %t57 to %Enemy*
  store %Enemy* %t58, %Enemy** @arena.Enemies.data
  br label %spawn_ready_17
spawn_ready_17:
  %t59 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t60 = load i64, i64* @arena.Enemies.free_top
  %t61 = icmp sgt i64 %t60, 0
  br i1 %t61, label %spawn_reuse_18, label %spawn_grow_19
spawn_reuse_18:
  %t62 = sub i64 %t60, 1
  store i64 %t62, i64* @arena.Enemies.free_top
  %t63 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t62
  %t64 = load i64, i64* %t63
  br label %spawn_store_20
spawn_grow_19:
  %t65 = load i64, i64* @arena.Enemies.count
  %t66 = icmp slt i64 %t65, 1024
  br i1 %t66, label %spawn_grow_ok_22, label %spawn_capacity_warn_23
spawn_capacity_warn_23:
  %t67 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t67)
  br label %spawn_end_21
spawn_grow_ok_22:
  %t68 = add i64 %t65, 1
  store i64 %t68, i64* @arena.Enemies.count
  br label %spawn_store_20
spawn_store_20:
  %t69 = phi i64 [ %t64, %spawn_reuse_18 ], [ %t65, %spawn_grow_ok_22 ]
  %t71 = getelementptr inbounds %Enemy, %Enemy* %t70, i32 0, i32 0
  store i32 10, i32* %t71
  %t72 = load %Enemy, %Enemy* %t70
  %t73 = getelementptr inbounds %Enemy, %Enemy* %t59, i64 %t69
  store %Enemy %t72, %Enemy* %t73
  %t74 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t69
  %t75 = load i64, i64* %t74
  %t76 = add i64 %t75, 1
  store i64 %t76, i64* %t74
  br label %spawn_end_21
spawn_end_21:
  %t77 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t78 = icmp eq %Bullet* %t77, null
  br i1 %t78, label %spawn_init_24, label %spawn_ready_25
spawn_init_24:
  %t79 = getelementptr %Bullet, %Bullet* null, i32 1
  %t80 = ptrtoint %Bullet* %t79 to i64
  %t81 = mul i64 %t80, 1024
  %t82 = call i8* @malloc(i64 %t81)
  %t83 = bitcast i8* %t82 to %Bullet*
  store %Bullet* %t83, %Bullet** @arena.Bullets.data
  br label %spawn_ready_25
spawn_ready_25:
  %t84 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t85 = load i64, i64* @arena.Bullets.free_top
  %t86 = icmp sgt i64 %t85, 0
  br i1 %t86, label %spawn_reuse_26, label %spawn_grow_27
spawn_reuse_26:
  %t87 = sub i64 %t85, 1
  store i64 %t87, i64* @arena.Bullets.free_top
  %t88 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t87
  %t89 = load i64, i64* %t88
  br label %spawn_store_28
spawn_grow_27:
  %t90 = load i64, i64* @arena.Bullets.count
  %t91 = icmp slt i64 %t90, 1024
  br i1 %t91, label %spawn_grow_ok_30, label %spawn_capacity_warn_31
spawn_capacity_warn_31:
  %t92 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t92)
  br label %spawn_end_29
spawn_grow_ok_30:
  %t93 = add i64 %t90, 1
  store i64 %t93, i64* @arena.Bullets.count
  br label %spawn_store_28
spawn_store_28:
  %t94 = phi i64 [ %t89, %spawn_reuse_26 ], [ %t90, %spawn_grow_ok_30 ]
  %t96 = getelementptr inbounds %Bullet, %Bullet* %t95, i32 0, i32 0
  store i32 0, i32* %t96
  %t97 = load %Bullet, %Bullet* %t95
  %t98 = getelementptr inbounds %Bullet, %Bullet* %t84, i64 %t94
  store %Bullet %t97, %Bullet* %t98
  %t99 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t94
  %t100 = load i64, i64* %t99
  %t101 = add i64 %t100, 1
  store i64 %t101, i64* %t99
  br label %spawn_end_29
spawn_end_29:
  %t102 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t103 = icmp eq %Bullet* %t102, null
  br i1 %t103, label %spawn_init_32, label %spawn_ready_33
spawn_init_32:
  %t104 = getelementptr %Bullet, %Bullet* null, i32 1
  %t105 = ptrtoint %Bullet* %t104 to i64
  %t106 = mul i64 %t105, 1024
  %t107 = call i8* @malloc(i64 %t106)
  %t108 = bitcast i8* %t107 to %Bullet*
  store %Bullet* %t108, %Bullet** @arena.Bullets.data
  br label %spawn_ready_33
spawn_ready_33:
  %t109 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t110 = load i64, i64* @arena.Bullets.free_top
  %t111 = icmp sgt i64 %t110, 0
  br i1 %t111, label %spawn_reuse_34, label %spawn_grow_35
spawn_reuse_34:
  %t112 = sub i64 %t110, 1
  store i64 %t112, i64* @arena.Bullets.free_top
  %t113 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t112
  %t114 = load i64, i64* %t113
  br label %spawn_store_36
spawn_grow_35:
  %t115 = load i64, i64* @arena.Bullets.count
  %t116 = icmp slt i64 %t115, 1024
  br i1 %t116, label %spawn_grow_ok_38, label %spawn_capacity_warn_39
spawn_capacity_warn_39:
  %t117 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t117)
  br label %spawn_end_37
spawn_grow_ok_38:
  %t118 = add i64 %t115, 1
  store i64 %t118, i64* @arena.Bullets.count
  br label %spawn_store_36
spawn_store_36:
  %t119 = phi i64 [ %t114, %spawn_reuse_34 ], [ %t115, %spawn_grow_ok_38 ]
  %t121 = getelementptr inbounds %Bullet, %Bullet* %t120, i32 0, i32 0
  store i32 0, i32* %t121
  %t122 = load %Bullet, %Bullet* %t120
  %t123 = getelementptr inbounds %Bullet, %Bullet* %t109, i64 %t119
  store %Bullet %t122, %Bullet* %t123
  %t124 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t119
  %t125 = load i64, i64* %t124
  %t126 = add i64 %t125, 1
  store i64 %t126, i64* %t124
  br label %spawn_end_37
spawn_end_37:
  %t127 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t128 = icmp eq %Bullet* %t127, null
  br i1 %t128, label %spawn_init_40, label %spawn_ready_41
spawn_init_40:
  %t129 = getelementptr %Bullet, %Bullet* null, i32 1
  %t130 = ptrtoint %Bullet* %t129 to i64
  %t131 = mul i64 %t130, 1024
  %t132 = call i8* @malloc(i64 %t131)
  %t133 = bitcast i8* %t132 to %Bullet*
  store %Bullet* %t133, %Bullet** @arena.Bullets.data
  br label %spawn_ready_41
spawn_ready_41:
  %t134 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t135 = load i64, i64* @arena.Bullets.free_top
  %t136 = icmp sgt i64 %t135, 0
  br i1 %t136, label %spawn_reuse_42, label %spawn_grow_43
spawn_reuse_42:
  %t137 = sub i64 %t135, 1
  store i64 %t137, i64* @arena.Bullets.free_top
  %t138 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t137
  %t139 = load i64, i64* %t138
  br label %spawn_store_44
spawn_grow_43:
  %t140 = load i64, i64* @arena.Bullets.count
  %t141 = icmp slt i64 %t140, 1024
  br i1 %t141, label %spawn_grow_ok_46, label %spawn_capacity_warn_47
spawn_capacity_warn_47:
  %t142 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t142)
  br label %spawn_end_45
spawn_grow_ok_46:
  %t143 = add i64 %t140, 1
  store i64 %t143, i64* @arena.Bullets.count
  br label %spawn_store_44
spawn_store_44:
  %t144 = phi i64 [ %t139, %spawn_reuse_42 ], [ %t140, %spawn_grow_ok_46 ]
  %t146 = getelementptr inbounds %Bullet, %Bullet* %t145, i32 0, i32 0
  store i32 0, i32* %t146
  %t147 = load %Bullet, %Bullet* %t145
  %t148 = getelementptr inbounds %Bullet, %Bullet* %t134, i64 %t144
  store %Bullet %t147, %Bullet* %t148
  %t149 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t144
  %t150 = load i64, i64* %t149
  %t151 = add i64 %t150, 1
  store i64 %t151, i64* %t149
  br label %spawn_end_45
spawn_end_45:
  %t152 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t153 = icmp eq %Bullet* %t152, null
  br i1 %t153, label %spawn_init_48, label %spawn_ready_49
spawn_init_48:
  %t154 = getelementptr %Bullet, %Bullet* null, i32 1
  %t155 = ptrtoint %Bullet* %t154 to i64
  %t156 = mul i64 %t155, 1024
  %t157 = call i8* @malloc(i64 %t156)
  %t158 = bitcast i8* %t157 to %Bullet*
  store %Bullet* %t158, %Bullet** @arena.Bullets.data
  br label %spawn_ready_49
spawn_ready_49:
  %t159 = load %Bullet*, %Bullet** @arena.Bullets.data
  %t160 = load i64, i64* @arena.Bullets.free_top
  %t161 = icmp sgt i64 %t160, 0
  br i1 %t161, label %spawn_reuse_50, label %spawn_grow_51
spawn_reuse_50:
  %t162 = sub i64 %t160, 1
  store i64 %t162, i64* @arena.Bullets.free_top
  %t163 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.free, i64 0, i64 %t162
  %t164 = load i64, i64* %t163
  br label %spawn_store_52
spawn_grow_51:
  %t165 = load i64, i64* @arena.Bullets.count
  %t166 = icmp slt i64 %t165, 1024
  br i1 %t166, label %spawn_grow_ok_54, label %spawn_capacity_warn_55
spawn_capacity_warn_55:
  %t167 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t167)
  br label %spawn_end_53
spawn_grow_ok_54:
  %t168 = add i64 %t165, 1
  store i64 %t168, i64* @arena.Bullets.count
  br label %spawn_store_52
spawn_store_52:
  %t169 = phi i64 [ %t164, %spawn_reuse_50 ], [ %t165, %spawn_grow_ok_54 ]
  %t171 = getelementptr inbounds %Bullet, %Bullet* %t170, i32 0, i32 0
  store i32 0, i32* %t171
  %t172 = load %Bullet, %Bullet* %t170
  %t173 = getelementptr inbounds %Bullet, %Bullet* %t159, i64 %t169
  store %Bullet %t172, %Bullet* %t173
  %t174 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t169
  %t175 = load i64, i64* %t174
  %t176 = add i64 %t175, 1
  store i64 %t176, i64* %t174
  br label %spawn_end_53
spawn_end_53:
  call void @par.pool.ensure_init()
  %t350 = call i32 @GetCurrentThreadId()
  %t351 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t352 = load i32, i32* %t351
  %t353 = icmp eq i32 %t350, %t352
  %t354 = select i1 %t353, i32 0, i32 -1
  %t355 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t356 = load i32, i32* %t355
  %t357 = icmp eq i32 %t350, %t356
  %t358 = select i1 %t357, i32 1, i32 %t354
  %t359 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t360 = load i32, i32* %t359
  %t361 = icmp eq i32 %t350, %t360
  %t362 = select i1 %t361, i32 2, i32 %t358
  %t363 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t364 = load i32, i32* %t363
  %t365 = icmp eq i32 %t350, %t364
  %t366 = select i1 %t365, i32 3, i32 %t362
  %t367 = icmp sge i32 %t366, 0
  br i1 %t367, label %par_serial_75, label %par_pooled_74
par_pooled_74:
  %t368 = load i64, i64* @arena.Enemies.count
  %t369 = mul i64 %t368, 0
  %t370 = sdiv i64 %t369, 4
  %t371 = mul i64 %t368, 1
  %t372 = sdiv i64 %t371, 4
  %t374 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t373, i32 0, i32 0
  store i64 %t370, i64* %t374
  %t375 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t373, i32 0, i32 1
  store i64 %t372, i64* %t375
  %t376 = bitcast { i64, i64 }* %t373 to i8*
  %t377 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t376, i8** %t377
  %t378 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t378
  %t379 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t380 = load i8*, i8** %t379
  %t381 = call i32 @ReleaseSemaphore(i8* %t380, i32 1, i32* null)
  %t382 = mul i64 %t368, 1
  %t383 = sdiv i64 %t382, 4
  %t384 = mul i64 %t368, 2
  %t385 = sdiv i64 %t384, 4
  %t387 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t386, i32 0, i32 0
  store i64 %t383, i64* %t387
  %t388 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t386, i32 0, i32 1
  store i64 %t385, i64* %t388
  %t389 = bitcast { i64, i64 }* %t386 to i8*
  %t390 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t389, i8** %t390
  %t391 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t391
  %t392 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t393 = load i8*, i8** %t392
  %t394 = call i32 @ReleaseSemaphore(i8* %t393, i32 1, i32* null)
  %t395 = mul i64 %t368, 2
  %t396 = sdiv i64 %t395, 4
  %t397 = mul i64 %t368, 3
  %t398 = sdiv i64 %t397, 4
  %t400 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t399, i32 0, i32 0
  store i64 %t396, i64* %t400
  %t401 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t399, i32 0, i32 1
  store i64 %t398, i64* %t401
  %t402 = bitcast { i64, i64 }* %t399 to i8*
  %t403 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t402, i8** %t403
  %t404 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t404
  %t405 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t406 = load i8*, i8** %t405
  %t407 = call i32 @ReleaseSemaphore(i8* %t406, i32 1, i32* null)
  %t408 = mul i64 %t368, 3
  %t409 = sdiv i64 %t408, 4
  %t410 = mul i64 %t368, 4
  %t411 = sdiv i64 %t410, 4
  %t413 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t412, i32 0, i32 0
  store i64 %t409, i64* %t413
  %t414 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t412, i32 0, i32 1
  store i64 %t411, i64* %t414
  %t415 = bitcast { i64, i64 }* %t412 to i8*
  %t416 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t415, i8** %t416
  %t417 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_56, i32 (i8*)** %t417
  %t418 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t419 = load i8*, i8** %t418
  %t420 = call i32 @ReleaseSemaphore(i8* %t419, i32 1, i32* null)
  %t421 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t422 = load i8*, i8** %t421
  %t423 = call i32 @WaitForSingleObject(i8* %t422, i32 -1)
  %t424 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t425 = load i8*, i8** %t424
  %t426 = call i32 @WaitForSingleObject(i8* %t425, i32 -1)
  %t427 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t428 = load i8*, i8** %t427
  %t429 = call i32 @WaitForSingleObject(i8* %t428, i32 -1)
  %t430 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t431 = load i8*, i8** %t430
  %t432 = call i32 @WaitForSingleObject(i8* %t431, i32 -1)
  br label %par_join_79
par_serial_75:
  %t433 = load i32, i32* @par.pool.serial_owner
  %t434 = icmp eq i32 %t433, %t366
  br i1 %t434, label %par_run_77, label %par_acquire_76
par_acquire_76:
  %t435 = load i8*, i8** @par.pool.serial_lock
  %t436 = call i32 @WaitForSingleObject(i8* %t435, i32 -1)
  store i32 %t366, i32* @par.pool.serial_owner
  br label %par_run_77
par_run_77:
  %t437 = load i64, i64* @arena.Enemies.count
  %t439 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t438, i32 0, i32 0
  store i64 0, i64* %t439
  %t440 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t438, i32 0, i32 1
  store i64 %t437, i64* %t440
  %t441 = bitcast { i64, i64 }* %t438 to i8*
  %t442 = call i32 @par_worker_56(i8* %t441)
  br i1 %t434, label %par_join_79, label %par_release_78
par_release_78:
  store i32 -1, i32* @par.pool.serial_owner
  %t443 = load i8*, i8** @par.pool.serial_lock
  %t444 = call i32 @ReleaseSemaphore(i8* %t443, i32 1, i32* null)
  br label %par_join_79
par_join_79:
  call void @par.pool.ensure_init()
  %t463 = call i32 @GetCurrentThreadId()
  %t464 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t465 = load i32, i32* %t464
  %t466 = icmp eq i32 %t463, %t465
  %t467 = select i1 %t466, i32 0, i32 -1
  %t468 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t469 = load i32, i32* %t468
  %t470 = icmp eq i32 %t463, %t469
  %t471 = select i1 %t470, i32 1, i32 %t467
  %t472 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t473 = load i32, i32* %t472
  %t474 = icmp eq i32 %t463, %t473
  %t475 = select i1 %t474, i32 2, i32 %t471
  %t476 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t477 = load i32, i32* %t476
  %t478 = icmp eq i32 %t463, %t477
  %t479 = select i1 %t478, i32 3, i32 %t475
  %t480 = icmp sge i32 %t479, 0
  br i1 %t480, label %par_serial_87, label %par_pooled_86
par_pooled_86:
  %t481 = load i64, i64* @arena.Bullets.count
  %t482 = mul i64 %t481, 0
  %t483 = sdiv i64 %t482, 4
  %t484 = mul i64 %t481, 1
  %t485 = sdiv i64 %t484, 4
  %t487 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t486, i32 0, i32 0
  store i64 %t483, i64* %t487
  %t488 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t486, i32 0, i32 1
  store i64 %t485, i64* %t488
  %t489 = bitcast { i64, i64 }* %t486 to i8*
  %t490 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t489, i8** %t490
  %t491 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t491
  %t492 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t493 = load i8*, i8** %t492
  %t494 = call i32 @ReleaseSemaphore(i8* %t493, i32 1, i32* null)
  %t495 = mul i64 %t481, 1
  %t496 = sdiv i64 %t495, 4
  %t497 = mul i64 %t481, 2
  %t498 = sdiv i64 %t497, 4
  %t500 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t499, i32 0, i32 0
  store i64 %t496, i64* %t500
  %t501 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t499, i32 0, i32 1
  store i64 %t498, i64* %t501
  %t502 = bitcast { i64, i64 }* %t499 to i8*
  %t503 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t502, i8** %t503
  %t504 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t504
  %t505 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t506 = load i8*, i8** %t505
  %t507 = call i32 @ReleaseSemaphore(i8* %t506, i32 1, i32* null)
  %t508 = mul i64 %t481, 2
  %t509 = sdiv i64 %t508, 4
  %t510 = mul i64 %t481, 3
  %t511 = sdiv i64 %t510, 4
  %t513 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t512, i32 0, i32 0
  store i64 %t509, i64* %t513
  %t514 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t512, i32 0, i32 1
  store i64 %t511, i64* %t514
  %t515 = bitcast { i64, i64 }* %t512 to i8*
  %t516 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t515, i8** %t516
  %t517 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t517
  %t518 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t519 = load i8*, i8** %t518
  %t520 = call i32 @ReleaseSemaphore(i8* %t519, i32 1, i32* null)
  %t521 = mul i64 %t481, 3
  %t522 = sdiv i64 %t521, 4
  %t523 = mul i64 %t481, 4
  %t524 = sdiv i64 %t523, 4
  %t526 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t525, i32 0, i32 0
  store i64 %t522, i64* %t526
  %t527 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t525, i32 0, i32 1
  store i64 %t524, i64* %t527
  %t528 = bitcast { i64, i64 }* %t525 to i8*
  %t529 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t528, i8** %t529
  %t530 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_80, i32 (i8*)** %t530
  %t531 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t532 = load i8*, i8** %t531
  %t533 = call i32 @ReleaseSemaphore(i8* %t532, i32 1, i32* null)
  %t534 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t535 = load i8*, i8** %t534
  %t536 = call i32 @WaitForSingleObject(i8* %t535, i32 -1)
  %t537 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t538 = load i8*, i8** %t537
  %t539 = call i32 @WaitForSingleObject(i8* %t538, i32 -1)
  %t540 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t541 = load i8*, i8** %t540
  %t542 = call i32 @WaitForSingleObject(i8* %t541, i32 -1)
  %t543 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t544 = load i8*, i8** %t543
  %t545 = call i32 @WaitForSingleObject(i8* %t544, i32 -1)
  br label %par_join_91
par_serial_87:
  %t546 = load i32, i32* @par.pool.serial_owner
  %t547 = icmp eq i32 %t546, %t479
  br i1 %t547, label %par_run_89, label %par_acquire_88
par_acquire_88:
  %t548 = load i8*, i8** @par.pool.serial_lock
  %t549 = call i32 @WaitForSingleObject(i8* %t548, i32 -1)
  store i32 %t479, i32* @par.pool.serial_owner
  br label %par_run_89
par_run_89:
  %t550 = load i64, i64* @arena.Bullets.count
  %t552 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t551, i32 0, i32 0
  store i64 0, i64* %t552
  %t553 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t551, i32 0, i32 1
  store i64 %t550, i64* %t553
  %t554 = bitcast { i64, i64 }* %t551 to i8*
  %t555 = call i32 @par_worker_80(i8* %t554)
  br i1 %t547, label %par_join_91, label %par_release_90
par_release_90:
  store i32 -1, i32* @par.pool.serial_owner
  %t556 = load i8*, i8** @par.pool.serial_lock
  %t557 = call i32 @ReleaseSemaphore(i8* %t556, i32 1, i32* null)
  br label %par_join_91
par_join_91:
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_62(i8* %argp) {
entry:
  %t199 = alloca i64
  %t191 = bitcast i8* %argp to { i64, i64, %Enemy* }*
  %t192 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t191, i32 0, i32 0
  %t193 = load i64, i64* %t192
  %t194 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t191, i32 0, i32 1
  %t195 = load i64, i64* %t194
  %t196 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t191, i32 0, i32 2
  %t197 = load %Enemy*, %Enemy** %t196
  %t198 = load %Bullet*, %Bullet** @arena.Bullets.data
  store i64 %t193, i64* %t199
  br label %par_cond_63
par_cond_63:
  %t200 = load i64, i64* %t199
  %t201 = icmp slt i64 %t200, %t195
  br i1 %t201, label %par_body_64, label %par_end_67
par_body_64:
  %t202 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t200
  %t203 = load i64, i64* %t202
  %t204 = and i64 %t203, 1
  %t205 = icmp eq i64 %t204, 1
  br i1 %t205, label %par_live_65, label %par_incr_66
par_live_65:
  %t206 = getelementptr inbounds %Bullet, %Bullet* %t198, i64 %t200
  %t207 = getelementptr inbounds %Bullet, %Bullet* %t206, i32 0, i32 0
  %t208 = load i32, i32* %t207
  %t209 = add i32 %t208, 1
  %t210 = getelementptr inbounds %Bullet, %Bullet* %t206, i32 0, i32 0
  store i32 %t209, i32* %t210
  br label %par_incr_66
par_incr_66:
  %t211 = add i64 %t200, 1
  store i64 %t211, i64* %t199
  br label %par_cond_63
par_end_67:
  ret i32 0
}


@par.pool.job_fn = global [4 x i32 (i8*)*] zeroinitializer
@par.pool.job_arg = global [4 x i8*] zeroinitializer
@par.pool.start_sem = global [4 x i8*] zeroinitializer
@par.pool.done_sem = global [4 x i8*] zeroinitializer
@par.pool.tid = global [4 x i32] zeroinitializer
@par.pool.inited = global i1 false
@par.pool.serial_lock = global i8* null
@par.pool.serial_owner = global i32 -1

define i32 @par.pool.worker_main(i8* %idx_arg) {
entry:
  %t212 = ptrtoint i8* %idx_arg to i64
  %t213 = trunc i64 %t212 to i32
  %t214 = call i32 @GetCurrentThreadId()
  %t215 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t213
  store i32 %t214, i32* %t215
  br label %loop
loop:
  %t216 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t213
  %t217 = load i8*, i8** %t216
  %t218 = call i32 @WaitForSingleObject(i8* %t217, i32 -1)
  %t219 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t213
  %t220 = load i32 (i8*)*, i32 (i8*)** %t219
  %t221 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t213
  %t222 = load i8*, i8** %t221
  %t223 = call i32 %t220(i8* %t222)
  %t224 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t213
  %t225 = load i8*, i8** %t224
  %t226 = call i32 @ReleaseSemaphore(i8* %t225, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t227 = load i1, i1* @par.pool.inited
  br i1 %t227, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t228 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t228, i8** @par.pool.serial_lock
  %t229 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t230 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t229, i8** %t230
  %t231 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t232 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t231, i8** %t232
  %t233 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t234 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t235 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t234, i8** %t235
  %t236 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t237 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t236, i8** %t237
  %t238 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t239 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t240 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t239, i8** %t240
  %t241 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t242 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t241, i8** %t242
  %t243 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t244 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t245 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t244, i8** %t245
  %t246 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t247 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t246, i8** %t247
  %t248 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_56(i8* %argp) {
entry:
  %t183 = alloca i64
  %t272 = alloca { i64, i64, %Enemy* }
  %t286 = alloca { i64, i64, %Enemy* }
  %t300 = alloca { i64, i64, %Enemy* }
  %t314 = alloca { i64, i64, %Enemy* }
  %t341 = alloca { i64, i64, %Enemy* }
  %t177 = bitcast i8* %argp to { i64, i64 }*
  %t178 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t177, i32 0, i32 0
  %t179 = load i64, i64* %t178
  %t180 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t177, i32 0, i32 1
  %t181 = load i64, i64* %t180
  %t182 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t179, i64* %t183
  br label %par_cond_57
par_cond_57:
  %t184 = load i64, i64* %t183
  %t185 = icmp slt i64 %t184, %t181
  br i1 %t185, label %par_body_58, label %par_end_61
par_body_58:
  %t186 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t184
  %t187 = load i64, i64* %t186
  %t188 = and i64 %t187, 1
  %t189 = icmp eq i64 %t188, 1
  br i1 %t189, label %par_live_59, label %par_incr_60
par_live_59:
  %t190 = getelementptr inbounds %Enemy, %Enemy* %t182, i64 %t184
  call void @par.pool.ensure_init()
  %t249 = call i32 @GetCurrentThreadId()
  %t250 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t251 = load i32, i32* %t250
  %t252 = icmp eq i32 %t249, %t251
  %t253 = select i1 %t252, i32 0, i32 -1
  %t254 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t255 = load i32, i32* %t254
  %t256 = icmp eq i32 %t249, %t255
  %t257 = select i1 %t256, i32 1, i32 %t253
  %t258 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t259 = load i32, i32* %t258
  %t260 = icmp eq i32 %t249, %t259
  %t261 = select i1 %t260, i32 2, i32 %t257
  %t262 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t263 = load i32, i32* %t262
  %t264 = icmp eq i32 %t249, %t263
  %t265 = select i1 %t264, i32 3, i32 %t261
  %t266 = icmp sge i32 %t265, 0
  br i1 %t266, label %par_serial_69, label %par_pooled_68
par_pooled_68:
  %t267 = load i64, i64* @arena.Bullets.count
  %t268 = mul i64 %t267, 0
  %t269 = sdiv i64 %t268, 4
  %t270 = mul i64 %t267, 1
  %t271 = sdiv i64 %t270, 4
  %t273 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t272, i32 0, i32 0
  store i64 %t269, i64* %t273
  %t274 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t272, i32 0, i32 1
  store i64 %t271, i64* %t274
  %t275 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t272, i32 0, i32 2
  store %Enemy* %t190, %Enemy** %t275
  %t276 = bitcast { i64, i64, %Enemy* }* %t272 to i8*
  %t277 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t276, i8** %t277
  %t278 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t278
  %t279 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t280 = load i8*, i8** %t279
  %t281 = call i32 @ReleaseSemaphore(i8* %t280, i32 1, i32* null)
  %t282 = mul i64 %t267, 1
  %t283 = sdiv i64 %t282, 4
  %t284 = mul i64 %t267, 2
  %t285 = sdiv i64 %t284, 4
  %t287 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t286, i32 0, i32 0
  store i64 %t283, i64* %t287
  %t288 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t286, i32 0, i32 1
  store i64 %t285, i64* %t288
  %t289 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t286, i32 0, i32 2
  store %Enemy* %t190, %Enemy** %t289
  %t290 = bitcast { i64, i64, %Enemy* }* %t286 to i8*
  %t291 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t290, i8** %t291
  %t292 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t292
  %t293 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t294 = load i8*, i8** %t293
  %t295 = call i32 @ReleaseSemaphore(i8* %t294, i32 1, i32* null)
  %t296 = mul i64 %t267, 2
  %t297 = sdiv i64 %t296, 4
  %t298 = mul i64 %t267, 3
  %t299 = sdiv i64 %t298, 4
  %t301 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t300, i32 0, i32 0
  store i64 %t297, i64* %t301
  %t302 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t300, i32 0, i32 1
  store i64 %t299, i64* %t302
  %t303 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t300, i32 0, i32 2
  store %Enemy* %t190, %Enemy** %t303
  %t304 = bitcast { i64, i64, %Enemy* }* %t300 to i8*
  %t305 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t304, i8** %t305
  %t306 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t306
  %t307 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t308 = load i8*, i8** %t307
  %t309 = call i32 @ReleaseSemaphore(i8* %t308, i32 1, i32* null)
  %t310 = mul i64 %t267, 3
  %t311 = sdiv i64 %t310, 4
  %t312 = mul i64 %t267, 4
  %t313 = sdiv i64 %t312, 4
  %t315 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t314, i32 0, i32 0
  store i64 %t311, i64* %t315
  %t316 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t314, i32 0, i32 1
  store i64 %t313, i64* %t316
  %t317 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t314, i32 0, i32 2
  store %Enemy* %t190, %Enemy** %t317
  %t318 = bitcast { i64, i64, %Enemy* }* %t314 to i8*
  %t319 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t318, i8** %t319
  %t320 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_62, i32 (i8*)** %t320
  %t321 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t322 = load i8*, i8** %t321
  %t323 = call i32 @ReleaseSemaphore(i8* %t322, i32 1, i32* null)
  %t324 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t325 = load i8*, i8** %t324
  %t326 = call i32 @WaitForSingleObject(i8* %t325, i32 -1)
  %t327 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t328 = load i8*, i8** %t327
  %t329 = call i32 @WaitForSingleObject(i8* %t328, i32 -1)
  %t330 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t331 = load i8*, i8** %t330
  %t332 = call i32 @WaitForSingleObject(i8* %t331, i32 -1)
  %t333 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t334 = load i8*, i8** %t333
  %t335 = call i32 @WaitForSingleObject(i8* %t334, i32 -1)
  br label %par_join_73
par_serial_69:
  %t336 = load i32, i32* @par.pool.serial_owner
  %t337 = icmp eq i32 %t336, %t265
  br i1 %t337, label %par_run_71, label %par_acquire_70
par_acquire_70:
  %t338 = load i8*, i8** @par.pool.serial_lock
  %t339 = call i32 @WaitForSingleObject(i8* %t338, i32 -1)
  store i32 %t265, i32* @par.pool.serial_owner
  br label %par_run_71
par_run_71:
  %t340 = load i64, i64* @arena.Bullets.count
  %t342 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t341, i32 0, i32 0
  store i64 0, i64* %t342
  %t343 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t341, i32 0, i32 1
  store i64 %t340, i64* %t343
  %t344 = getelementptr inbounds { i64, i64, %Enemy* }, { i64, i64, %Enemy* }* %t341, i32 0, i32 2
  store %Enemy* %t190, %Enemy** %t344
  %t345 = bitcast { i64, i64, %Enemy* }* %t341 to i8*
  %t346 = call i32 @par_worker_62(i8* %t345)
  br i1 %t337, label %par_join_73, label %par_release_72
par_release_72:
  store i32 -1, i32* @par.pool.serial_owner
  %t347 = load i8*, i8** @par.pool.serial_lock
  %t348 = call i32 @ReleaseSemaphore(i8* %t347, i32 1, i32* null)
  br label %par_join_73
par_join_73:
  br label %par_incr_60
par_incr_60:
  %t349 = add i64 %t184, 1
  store i64 %t349, i64* %t183
  br label %par_cond_57
par_end_61:
  ret i32 0
}


define i32 @par_worker_80(i8* %argp) {
entry:
  %t451 = alloca i64
  %t445 = bitcast i8* %argp to { i64, i64 }*
  %t446 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t445, i32 0, i32 0
  %t447 = load i64, i64* %t446
  %t448 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t445, i32 0, i32 1
  %t449 = load i64, i64* %t448
  %t450 = load %Bullet*, %Bullet** @arena.Bullets.data
  store i64 %t447, i64* %t451
  br label %par_cond_81
par_cond_81:
  %t452 = load i64, i64* %t451
  %t453 = icmp slt i64 %t452, %t449
  br i1 %t453, label %par_body_82, label %par_end_85
par_body_82:
  %t454 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Bullets.gen, i64 0, i64 %t452
  %t455 = load i64, i64* %t454
  %t456 = and i64 %t455, 1
  %t457 = icmp eq i64 %t456, 1
  br i1 %t457, label %par_live_83, label %par_incr_84
par_live_83:
  %t458 = getelementptr inbounds %Bullet, %Bullet* %t450, i64 %t452
  %t459 = getelementptr inbounds %Bullet, %Bullet* %t458, i32 0, i32 0
  %t460 = load i32, i32* %t459
  %t461 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t461, i32 %t460)
  br label %par_incr_84
par_incr_84:
  %t462 = add i64 %t452, 1
  store i64 %t462, i64* %t451
  br label %par_cond_81
par_end_85:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.1 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.2 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.3 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.4 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.5 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.6 = private unnamed_addr constant [85 x i8] c"star runtime warning: arena `Bullets` is full (1024 live elements) -- spawn dropped\0A\00"
@.str.7 = private unnamed_addr constant [9 x i8] c"dmg: %d\0A\00"
