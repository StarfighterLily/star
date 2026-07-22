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

%Enemy = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [3 x i64] zeroinitializer
@arena.Enemies.free = global [3 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0
@arena.Enemies.warned = global i1 0

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t21 = alloca %Enemy
  %t30 = alloca i32
  %t50 = alloca %Enemy
  %t78 = alloca %Enemy
  %t87 = alloca %GenRef
  %t94 = alloca %GenRef
  %t112 = alloca %Enemy
  %t132 = alloca %GenRef
  %t139 = alloca %GenRef
  %t158 = alloca %Enemy
  %t163 = alloca i32
  %t183 = alloca %Enemy
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
  %t6 = mul i64 %t5, 3
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
  %t13 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.free, i64 0, i64 %t12
  %t14 = load i64, i64* %t13
  br label %spawn_store_4
spawn_grow_3:
  %t15 = load i64, i64* @arena.Enemies.count
  %t16 = icmp slt i64 %t15, 3
  br i1 %t16, label %spawn_grow_ok_6, label %spawn_capacity_warn_7
spawn_capacity_warn_7:
  %t17 = load i1, i1* @arena.Enemies.warned
  br i1 %t17, label %spawn_end_5, label %spawn_warn_print_8
spawn_warn_print_8:
  store i1 1, i1* @arena.Enemies.warned
  %t18 = getelementptr inbounds [137 x i8], [137 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t18)
  br label %spawn_end_5
spawn_grow_ok_6:
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* @arena.Enemies.count
  br label %spawn_store_4
spawn_store_4:
  %t20 = phi i64 [ %t14, %spawn_reuse_2 ], [ %t15, %spawn_grow_ok_6 ]
  %t22 = getelementptr inbounds %Enemy, %Enemy* %t21, i32 0, i32 0
  store i32 1, i32* %t22
  %t23 = load %Enemy, %Enemy* %t21
  %t24 = getelementptr inbounds %Enemy, %Enemy* %t9, i64 %t20
  store %Enemy %t23, %Enemy* %t24
  %t25 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t20
  %t26 = load i64, i64* %t25
  %t27 = add i64 %t26, 1
  store i64 %t27, i64* %t25
  %t28 = trunc i64 %t20 to i32
  br label %spawn_end_5
spawn_end_5:
  %t29 = phi i32 [ %t28, %spawn_store_4 ], [ -1, %spawn_capacity_warn_7 ], [ -1, %spawn_warn_print_8 ]
  %t31 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t32 = icmp eq %Enemy* %t31, null
  br i1 %t32, label %spawn_init_9, label %spawn_ready_10
spawn_init_9:
  %t33 = getelementptr %Enemy, %Enemy* null, i32 1
  %t34 = ptrtoint %Enemy* %t33 to i64
  %t35 = mul i64 %t34, 3
  %t36 = call i8* @malloc(i64 %t35)
  %t37 = bitcast i8* %t36 to %Enemy*
  store %Enemy* %t37, %Enemy** @arena.Enemies.data
  br label %spawn_ready_10
spawn_ready_10:
  %t38 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t39 = load i64, i64* @arena.Enemies.free_top
  %t40 = icmp sgt i64 %t39, 0
  br i1 %t40, label %spawn_reuse_11, label %spawn_grow_12
spawn_reuse_11:
  %t41 = sub i64 %t39, 1
  store i64 %t41, i64* @arena.Enemies.free_top
  %t42 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.free, i64 0, i64 %t41
  %t43 = load i64, i64* %t42
  br label %spawn_store_13
spawn_grow_12:
  %t44 = load i64, i64* @arena.Enemies.count
  %t45 = icmp slt i64 %t44, 3
  br i1 %t45, label %spawn_grow_ok_15, label %spawn_capacity_warn_16
spawn_capacity_warn_16:
  %t46 = load i1, i1* @arena.Enemies.warned
  br i1 %t46, label %spawn_end_14, label %spawn_warn_print_17
spawn_warn_print_17:
  store i1 1, i1* @arena.Enemies.warned
  %t47 = getelementptr inbounds [137 x i8], [137 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t47)
  br label %spawn_end_14
spawn_grow_ok_15:
  %t48 = add i64 %t44, 1
  store i64 %t48, i64* @arena.Enemies.count
  br label %spawn_store_13
spawn_store_13:
  %t49 = phi i64 [ %t43, %spawn_reuse_11 ], [ %t44, %spawn_grow_ok_15 ]
  %t51 = getelementptr inbounds %Enemy, %Enemy* %t50, i32 0, i32 0
  store i32 50, i32* %t51
  %t52 = load %Enemy, %Enemy* %t50
  %t53 = getelementptr inbounds %Enemy, %Enemy* %t38, i64 %t49
  store %Enemy %t52, %Enemy* %t53
  %t54 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t49
  %t55 = load i64, i64* %t54
  %t56 = add i64 %t55, 1
  store i64 %t56, i64* %t54
  %t57 = trunc i64 %t49 to i32
  br label %spawn_end_14
spawn_end_14:
  %t58 = phi i32 [ %t57, %spawn_store_13 ], [ -1, %spawn_capacity_warn_16 ], [ -1, %spawn_warn_print_17 ]
  store i32 %t58, i32* %t30
  %t59 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t60 = icmp eq %Enemy* %t59, null
  br i1 %t60, label %spawn_init_18, label %spawn_ready_19
spawn_init_18:
  %t61 = getelementptr %Enemy, %Enemy* null, i32 1
  %t62 = ptrtoint %Enemy* %t61 to i64
  %t63 = mul i64 %t62, 3
  %t64 = call i8* @malloc(i64 %t63)
  %t65 = bitcast i8* %t64 to %Enemy*
  store %Enemy* %t65, %Enemy** @arena.Enemies.data
  br label %spawn_ready_19
spawn_ready_19:
  %t66 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t67 = load i64, i64* @arena.Enemies.free_top
  %t68 = icmp sgt i64 %t67, 0
  br i1 %t68, label %spawn_reuse_20, label %spawn_grow_21
spawn_reuse_20:
  %t69 = sub i64 %t67, 1
  store i64 %t69, i64* @arena.Enemies.free_top
  %t70 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.free, i64 0, i64 %t69
  %t71 = load i64, i64* %t70
  br label %spawn_store_22
spawn_grow_21:
  %t72 = load i64, i64* @arena.Enemies.count
  %t73 = icmp slt i64 %t72, 3
  br i1 %t73, label %spawn_grow_ok_24, label %spawn_capacity_warn_25
spawn_capacity_warn_25:
  %t74 = load i1, i1* @arena.Enemies.warned
  br i1 %t74, label %spawn_end_23, label %spawn_warn_print_26
spawn_warn_print_26:
  store i1 1, i1* @arena.Enemies.warned
  %t75 = getelementptr inbounds [137 x i8], [137 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t75)
  br label %spawn_end_23
spawn_grow_ok_24:
  %t76 = add i64 %t72, 1
  store i64 %t76, i64* @arena.Enemies.count
  br label %spawn_store_22
spawn_store_22:
  %t77 = phi i64 [ %t71, %spawn_reuse_20 ], [ %t72, %spawn_grow_ok_24 ]
  %t79 = getelementptr inbounds %Enemy, %Enemy* %t78, i32 0, i32 0
  store i32 3, i32* %t79
  %t80 = load %Enemy, %Enemy* %t78
  %t81 = getelementptr inbounds %Enemy, %Enemy* %t66, i64 %t77
  store %Enemy %t80, %Enemy* %t81
  %t82 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t77
  %t83 = load i64, i64* %t82
  %t84 = add i64 %t83, 1
  store i64 %t84, i64* %t82
  %t85 = trunc i64 %t77 to i32
  br label %spawn_end_23
spawn_end_23:
  %t86 = phi i32 [ %t85, %spawn_store_22 ], [ -1, %spawn_capacity_warn_25 ], [ -1, %spawn_warn_print_26 ]
  %t88 = load i32, i32* %t30
  %t89 = sext i32 %t88 to i64
  %t90 = icmp ult i64 %t89, 3
  br i1 %t90, label %genref_create_ok_27, label %genref_create_oob_28
genref_create_ok_27:
  %t91 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t89
  %t92 = load i64, i64* %t91
  br label %genref_create_end_29
genref_create_oob_28:
  br label %genref_create_end_29
genref_create_end_29:
  %t93 = phi i64 [ %t92, %genref_create_ok_27 ], [ 0, %genref_create_oob_28 ]
  %t95 = getelementptr inbounds %GenRef, %GenRef* %t94, i32 0, i32 0
  store i32 %t88, i32* %t95
  %t96 = getelementptr inbounds %GenRef, %GenRef* %t94, i32 0, i32 1
  store i64 %t93, i64* %t96
  %t97 = load %GenRef, %GenRef* %t94
  store %GenRef %t97, %GenRef* %t87
  %t98 = getelementptr inbounds %GenRef, %GenRef* %t87, i32 0, i32 0
  %t99 = load i32, i32* %t98
  %t100 = getelementptr inbounds %GenRef, %GenRef* %t87, i32 0, i32 1
  %t101 = load i64, i64* %t100
  %t102 = sext i32 %t99 to i64
  %t103 = icmp ult i64 %t102, 3
  br i1 %t103, label %genref_place_check_30, label %genref_place_stale_32
genref_place_check_30:
  %t104 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t102
  %t105 = load i64, i64* %t104
  %t106 = icmp eq i64 %t101, %t105
  %t107 = and i64 %t105, 1
  %t108 = icmp eq i64 %t107, 1
  %t109 = and i1 %t106, %t108
  br i1 %t109, label %genref_place_ok_31, label %genref_place_stale_32
genref_place_ok_31:
  %t110 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t111 = getelementptr inbounds %Enemy, %Enemy* %t110, i64 %t102
  br label %genref_place_end_33
genref_place_stale_32:
  store %Enemy zeroinitializer, %Enemy* %t112
  br label %genref_place_end_33
genref_place_end_33:
  %t113 = phi %Enemy* [ %t111, %genref_place_ok_31 ], [ %t112, %genref_place_stale_32 ]
  %t114 = getelementptr inbounds %Enemy, %Enemy* %t113, i32 0, i32 0
  %t115 = load i32, i32* %t114
  %t116 = sub i32 %t115, 5
  %t117 = getelementptr inbounds %GenRef, %GenRef* %t87, i32 0, i32 0
  %t118 = load i32, i32* %t117
  %t119 = getelementptr inbounds %GenRef, %GenRef* %t87, i32 0, i32 1
  %t120 = load i64, i64* %t119
  %t121 = sext i32 %t118 to i64
  %t122 = icmp ult i64 %t121, 3
  br i1 %t122, label %genref_wcheck_34, label %genref_wstale_36
genref_wcheck_34:
  %t123 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t121
  %t124 = load i64, i64* %t123
  %t125 = icmp eq i64 %t120, %t124
  %t126 = and i64 %t124, 1
  %t127 = icmp eq i64 %t126, 1
  %t128 = and i1 %t125, %t127
  br i1 %t128, label %genref_wok_35, label %genref_wstale_36
genref_wok_35:
  %t129 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t130 = getelementptr inbounds %Enemy, %Enemy* %t129, i64 %t121
  %t131 = getelementptr inbounds %Enemy, %Enemy* %t130, i32 0, i32 0
  store i32 %t116, i32* %t131
  br label %genref_wend_37
genref_wstale_36:
  br label %genref_wend_37
genref_wend_37:
  %t133 = load i32, i32* %t30
  %t134 = sext i32 %t133 to i64
  %t135 = icmp ult i64 %t134, 3
  br i1 %t135, label %genref_create_ok_38, label %genref_create_oob_39
genref_create_ok_38:
  %t136 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t134
  %t137 = load i64, i64* %t136
  br label %genref_create_end_40
genref_create_oob_39:
  br label %genref_create_end_40
genref_create_end_40:
  %t138 = phi i64 [ %t137, %genref_create_ok_38 ], [ 0, %genref_create_oob_39 ]
  %t140 = getelementptr inbounds %GenRef, %GenRef* %t139, i32 0, i32 0
  store i32 %t133, i32* %t140
  %t141 = getelementptr inbounds %GenRef, %GenRef* %t139, i32 0, i32 1
  store i64 %t138, i64* %t141
  %t142 = load %GenRef, %GenRef* %t139
  store %GenRef %t142, %GenRef* %t132
  %t143 = load i32, i32* %t30
  %t144 = getelementptr inbounds %GenRef, %GenRef* %t132, i32 0, i32 0
  %t145 = load i32, i32* %t144
  %t146 = getelementptr inbounds %GenRef, %GenRef* %t132, i32 0, i32 1
  %t147 = load i64, i64* %t146
  %t148 = sext i32 %t145 to i64
  %t149 = icmp ult i64 %t148, 3
  br i1 %t149, label %genref_place_check_41, label %genref_place_stale_43
genref_place_check_41:
  %t150 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t148
  %t151 = load i64, i64* %t150
  %t152 = icmp eq i64 %t147, %t151
  %t153 = and i64 %t151, 1
  %t154 = icmp eq i64 %t153, 1
  %t155 = and i1 %t152, %t154
  br i1 %t155, label %genref_place_ok_42, label %genref_place_stale_43
genref_place_ok_42:
  %t156 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t157 = getelementptr inbounds %Enemy, %Enemy* %t156, i64 %t148
  br label %genref_place_end_44
genref_place_stale_43:
  store %Enemy zeroinitializer, %Enemy* %t158
  br label %genref_place_end_44
genref_place_end_44:
  %t159 = phi %Enemy* [ %t157, %genref_place_ok_42 ], [ %t158, %genref_place_stale_43 ]
  %t160 = getelementptr inbounds %Enemy, %Enemy* %t159, i32 0, i32 0
  %t161 = load i32, i32* %t160
  %t162 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t162, i32 %t143, i32 %t161)
  %t164 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t165 = icmp eq %Enemy* %t164, null
  br i1 %t165, label %spawn_init_45, label %spawn_ready_46
spawn_init_45:
  %t166 = getelementptr %Enemy, %Enemy* null, i32 1
  %t167 = ptrtoint %Enemy* %t166 to i64
  %t168 = mul i64 %t167, 3
  %t169 = call i8* @malloc(i64 %t168)
  %t170 = bitcast i8* %t169 to %Enemy*
  store %Enemy* %t170, %Enemy** @arena.Enemies.data
  br label %spawn_ready_46
spawn_ready_46:
  %t171 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t172 = load i64, i64* @arena.Enemies.free_top
  %t173 = icmp sgt i64 %t172, 0
  br i1 %t173, label %spawn_reuse_47, label %spawn_grow_48
spawn_reuse_47:
  %t174 = sub i64 %t172, 1
  store i64 %t174, i64* @arena.Enemies.free_top
  %t175 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.free, i64 0, i64 %t174
  %t176 = load i64, i64* %t175
  br label %spawn_store_49
spawn_grow_48:
  %t177 = load i64, i64* @arena.Enemies.count
  %t178 = icmp slt i64 %t177, 3
  br i1 %t178, label %spawn_grow_ok_51, label %spawn_capacity_warn_52
spawn_capacity_warn_52:
  %t179 = load i1, i1* @arena.Enemies.warned
  br i1 %t179, label %spawn_end_50, label %spawn_warn_print_53
spawn_warn_print_53:
  store i1 1, i1* @arena.Enemies.warned
  %t180 = getelementptr inbounds [137 x i8], [137 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t180)
  br label %spawn_end_50
spawn_grow_ok_51:
  %t181 = add i64 %t177, 1
  store i64 %t181, i64* @arena.Enemies.count
  br label %spawn_store_49
spawn_store_49:
  %t182 = phi i64 [ %t176, %spawn_reuse_47 ], [ %t177, %spawn_grow_ok_51 ]
  %t184 = getelementptr inbounds %Enemy, %Enemy* %t183, i32 0, i32 0
  store i32 999, i32* %t184
  %t185 = load %Enemy, %Enemy* %t183
  %t186 = getelementptr inbounds %Enemy, %Enemy* %t171, i64 %t182
  store %Enemy %t185, %Enemy* %t186
  %t187 = getelementptr inbounds [3 x i64], [3 x i64]* @arena.Enemies.gen, i64 0, i64 %t182
  %t188 = load i64, i64* %t187
  %t189 = add i64 %t188, 1
  store i64 %t189, i64* %t187
  %t190 = trunc i64 %t182 to i32
  br label %spawn_end_50
spawn_end_50:
  %t191 = phi i32 [ %t190, %spawn_store_49 ], [ -1, %spawn_capacity_warn_52 ], [ -1, %spawn_warn_print_53 ]
  store i32 %t191, i32* %t163
  %t192 = load i32, i32* %t163
  %t193 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t193, i32 %t192)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [137 x i8] c"star runtime warning: arena `Enemies` is full (3 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [137 x i8] c"star runtime warning: arena `Enemies` is full (3 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.2 = private unnamed_addr constant [137 x i8] c"star runtime warning: arena `Enemies` is full (3 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.3 = private unnamed_addr constant [27 x i8] c"spawned at slot %d, hp=%d\0A\00"
@.str.4 = private unnamed_addr constant [137 x i8] c"star runtime warning: arena `Enemies` is full (3 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.5 = private unnamed_addr constant [37 x i8] c"spawn into a full arena reports: %d\0A\00"

