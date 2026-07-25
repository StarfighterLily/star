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
declare i32 @SDL_RenderReadPixels(i8*, i8*, i32, i8*, i32)
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

@frame.buf = global [16777216 x i8] zeroinitializer
@frame.off = global i64 0

@star.argc = global i32 0
@star.argv = global i8** null

@rng.state = global i32 123456789
@rng.lock = global i8* null

@sym.data = global i8** null
@sym.len = global i64 0
@sym.cap = global i64 0
@sym.tbl.ids = global i64* null
@sym.tbl.cap = global i64 0
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
%Particle = type { i32 }
%Enemies = type { %Enemy*, i64 }
@arena.Enemies.data = global %Enemy* null
@arena.Enemies.count = global i64 0
@arena.Enemies.gen = global [1024 x i64] zeroinitializer
@arena.Enemies.free = global [1024 x i64] zeroinitializer
@arena.Enemies.free_top = global i64 0
@arena.Enemies.warned = global i1 0

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
define i32 @sys.UpdateEnemies(i8* %_unused) {
entry:
  %t79 = alloca { i64, i64 }
  %t92 = alloca { i64, i64 }
  %t105 = alloca { i64, i64 }
  %t118 = alloca { i64, i64 }
  %t144 = alloca { i64, i64 }
  call void @par.pool.ensure_init()
  %t56 = call i32 @GetCurrentThreadId()
  %t57 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t58 = load i32, i32* %t57
  %t59 = icmp eq i32 %t56, %t58
  %t60 = select i1 %t59, i32 0, i32 -1
  %t61 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t62 = load i32, i32* %t61
  %t63 = icmp eq i32 %t56, %t62
  %t64 = select i1 %t63, i32 1, i32 %t60
  %t65 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t66 = load i32, i32* %t65
  %t67 = icmp eq i32 %t56, %t66
  %t68 = select i1 %t67, i32 2, i32 %t64
  %t69 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t70 = load i32, i32* %t69
  %t71 = icmp eq i32 %t56, %t70
  %t72 = select i1 %t71, i32 3, i32 %t68
  %t73 = icmp sge i32 %t72, 0
  br i1 %t73, label %par_serial_7, label %par_pooled_6
par_pooled_6:
  %t74 = load i64, i64* @arena.Enemies.count
  %t75 = mul i64 %t74, 0
  %t76 = sdiv i64 %t75, 4
  %t77 = mul i64 %t74, 1
  %t78 = sdiv i64 %t77, 4
  %t80 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t79, i32 0, i32 0
  store i64 %t76, i64* %t80
  %t81 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t79, i32 0, i32 1
  store i64 %t78, i64* %t81
  %t82 = bitcast { i64, i64 }* %t79 to i8*
  %t83 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t82, i8** %t83
  %t84 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t84
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t86 = load i8*, i8** %t85
  %t87 = call i32 @ReleaseSemaphore(i8* %t86, i32 1, i32* null)
  %t88 = mul i64 %t74, 1
  %t89 = sdiv i64 %t88, 4
  %t90 = mul i64 %t74, 2
  %t91 = sdiv i64 %t90, 4
  %t93 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t92, i32 0, i32 0
  store i64 %t89, i64* %t93
  %t94 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t92, i32 0, i32 1
  store i64 %t91, i64* %t94
  %t95 = bitcast { i64, i64 }* %t92 to i8*
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t95, i8** %t96
  %t97 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t97
  %t98 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t99 = load i8*, i8** %t98
  %t100 = call i32 @ReleaseSemaphore(i8* %t99, i32 1, i32* null)
  %t101 = mul i64 %t74, 2
  %t102 = sdiv i64 %t101, 4
  %t103 = mul i64 %t74, 3
  %t104 = sdiv i64 %t103, 4
  %t106 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t105, i32 0, i32 0
  store i64 %t102, i64* %t106
  %t107 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t105, i32 0, i32 1
  store i64 %t104, i64* %t107
  %t108 = bitcast { i64, i64 }* %t105 to i8*
  %t109 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t108, i8** %t109
  %t110 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t110
  %t111 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t112 = load i8*, i8** %t111
  %t113 = call i32 @ReleaseSemaphore(i8* %t112, i32 1, i32* null)
  %t114 = mul i64 %t74, 3
  %t115 = sdiv i64 %t114, 4
  %t116 = mul i64 %t74, 4
  %t117 = sdiv i64 %t116, 4
  %t119 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 0
  store i64 %t115, i64* %t119
  %t120 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 1
  store i64 %t117, i64* %t120
  %t121 = bitcast { i64, i64 }* %t118 to i8*
  %t122 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t121, i8** %t122
  %t123 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_0, i32 (i8*)** %t123
  %t124 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t125 = load i8*, i8** %t124
  %t126 = call i32 @ReleaseSemaphore(i8* %t125, i32 1, i32* null)
  %t127 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t128 = load i8*, i8** %t127
  %t129 = call i32 @WaitForSingleObject(i8* %t128, i32 -1)
  %t130 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t131 = load i8*, i8** %t130
  %t132 = call i32 @WaitForSingleObject(i8* %t131, i32 -1)
  %t133 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t134 = load i8*, i8** %t133
  %t135 = call i32 @WaitForSingleObject(i8* %t134, i32 -1)
  %t136 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t137 = load i8*, i8** %t136
  %t138 = call i32 @WaitForSingleObject(i8* %t137, i32 -1)
  br label %par_join_11
par_serial_7:
  %t139 = load i32, i32* @par.pool.serial_owner
  %t140 = icmp eq i32 %t139, %t72
  br i1 %t140, label %par_run_9, label %par_acquire_8
par_acquire_8:
  %t141 = load i8*, i8** @par.pool.serial_lock
  %t142 = call i32 @WaitForSingleObject(i8* %t141, i32 -1)
  store i32 %t72, i32* @par.pool.serial_owner
  br label %par_run_9
par_run_9:
  %t143 = load i64, i64* @arena.Enemies.count
  %t145 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t144, i32 0, i32 0
  store i64 0, i64* %t145
  %t146 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t144, i32 0, i32 1
  store i64 %t143, i64* %t146
  %t147 = bitcast { i64, i64 }* %t144 to i8*
  %t148 = call i32 @par_worker_0(i8* %t147)
  br i1 %t140, label %par_join_11, label %par_release_10
par_release_10:
  store i32 -1, i32* @par.pool.serial_owner
  %t149 = load i8*, i8** @par.pool.serial_lock
  %t150 = call i32 @ReleaseSemaphore(i8* %t149, i32 1, i32* null)
  br label %par_join_11
par_join_11:
  ret i32 0
}

define i32 @sys.UpdateParticles(i8* %_unused) {
entry:
  %t42 = alloca { i64, i64 }
  %t55 = alloca { i64, i64 }
  %t68 = alloca { i64, i64 }
  %t81 = alloca { i64, i64 }
  %t107 = alloca { i64, i64 }
  call void @par.pool.ensure_init()
  %t19 = call i32 @GetCurrentThreadId()
  %t20 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t21 = load i32, i32* %t20
  %t22 = icmp eq i32 %t19, %t21
  %t23 = select i1 %t22, i32 0, i32 -1
  %t24 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t25 = load i32, i32* %t24
  %t26 = icmp eq i32 %t19, %t25
  %t27 = select i1 %t26, i32 1, i32 %t23
  %t28 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t29 = load i32, i32* %t28
  %t30 = icmp eq i32 %t19, %t29
  %t31 = select i1 %t30, i32 2, i32 %t27
  %t32 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t33 = load i32, i32* %t32
  %t34 = icmp eq i32 %t19, %t33
  %t35 = select i1 %t34, i32 3, i32 %t31
  %t36 = icmp sge i32 %t35, 0
  br i1 %t36, label %par_serial_19, label %par_pooled_18
par_pooled_18:
  %t37 = load i64, i64* @arena.Particles.count
  %t38 = mul i64 %t37, 0
  %t39 = sdiv i64 %t38, 4
  %t40 = mul i64 %t37, 1
  %t41 = sdiv i64 %t40, 4
  %t43 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t42, i32 0, i32 0
  store i64 %t39, i64* %t43
  %t44 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t42, i32 0, i32 1
  store i64 %t41, i64* %t44
  %t45 = bitcast { i64, i64 }* %t42 to i8*
  %t46 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t45, i8** %t46
  %t47 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t47
  %t48 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t49 = load i8*, i8** %t48
  %t50 = call i32 @ReleaseSemaphore(i8* %t49, i32 1, i32* null)
  %t51 = mul i64 %t37, 1
  %t52 = sdiv i64 %t51, 4
  %t53 = mul i64 %t37, 2
  %t54 = sdiv i64 %t53, 4
  %t56 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t55, i32 0, i32 0
  store i64 %t52, i64* %t56
  %t57 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t55, i32 0, i32 1
  store i64 %t54, i64* %t57
  %t58 = bitcast { i64, i64 }* %t55 to i8*
  %t59 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t58, i8** %t59
  %t60 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t60
  %t61 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t62 = load i8*, i8** %t61
  %t63 = call i32 @ReleaseSemaphore(i8* %t62, i32 1, i32* null)
  %t64 = mul i64 %t37, 2
  %t65 = sdiv i64 %t64, 4
  %t66 = mul i64 %t37, 3
  %t67 = sdiv i64 %t66, 4
  %t69 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t68, i32 0, i32 0
  store i64 %t65, i64* %t69
  %t70 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t68, i32 0, i32 1
  store i64 %t67, i64* %t70
  %t71 = bitcast { i64, i64 }* %t68 to i8*
  %t72 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t71, i8** %t72
  %t73 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t73
  %t74 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t75 = load i8*, i8** %t74
  %t76 = call i32 @ReleaseSemaphore(i8* %t75, i32 1, i32* null)
  %t77 = mul i64 %t37, 3
  %t78 = sdiv i64 %t77, 4
  %t79 = mul i64 %t37, 4
  %t80 = sdiv i64 %t79, 4
  %t82 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t81, i32 0, i32 0
  store i64 %t78, i64* %t82
  %t83 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t81, i32 0, i32 1
  store i64 %t80, i64* %t83
  %t84 = bitcast { i64, i64 }* %t81 to i8*
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t84, i8** %t85
  %t86 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_12, i32 (i8*)** %t86
  %t87 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t88 = load i8*, i8** %t87
  %t89 = call i32 @ReleaseSemaphore(i8* %t88, i32 1, i32* null)
  %t90 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t91 = load i8*, i8** %t90
  %t92 = call i32 @WaitForSingleObject(i8* %t91, i32 -1)
  %t93 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t94 = load i8*, i8** %t93
  %t95 = call i32 @WaitForSingleObject(i8* %t94, i32 -1)
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t97 = load i8*, i8** %t96
  %t98 = call i32 @WaitForSingleObject(i8* %t97, i32 -1)
  %t99 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t100 = load i8*, i8** %t99
  %t101 = call i32 @WaitForSingleObject(i8* %t100, i32 -1)
  br label %par_join_23
par_serial_19:
  %t102 = load i32, i32* @par.pool.serial_owner
  %t103 = icmp eq i32 %t102, %t35
  br i1 %t103, label %par_run_21, label %par_acquire_20
par_acquire_20:
  %t104 = load i8*, i8** @par.pool.serial_lock
  %t105 = call i32 @WaitForSingleObject(i8* %t104, i32 -1)
  store i32 %t35, i32* @par.pool.serial_owner
  br label %par_run_21
par_run_21:
  %t106 = load i64, i64* @arena.Particles.count
  %t108 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t107, i32 0, i32 0
  store i64 0, i64* %t108
  %t109 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t107, i32 0, i32 1
  store i64 %t106, i64* %t109
  %t110 = bitcast { i64, i64 }* %t107 to i8*
  %t111 = call i32 @par_worker_12(i8* %t110)
  br i1 %t103, label %par_join_23, label %par_release_22
par_release_22:
  store i32 -1, i32* @par.pool.serial_owner
  %t112 = load i8*, i8** @par.pool.serial_lock
  %t113 = call i32 @ReleaseSemaphore(i8* %t112, i32 1, i32* null)
  br label %par_join_23
par_join_23:
  ret i32 0
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t21 = alloca %Enemy
  %t49 = alloca %Enemy
  %t77 = alloca %Enemy
  %t105 = alloca %Particle
  %t133 = alloca %Particle
  %t199 = alloca { i64, i64 }
  %t212 = alloca { i64, i64 }
  %t225 = alloca { i64, i64 }
  %t238 = alloca { i64, i64 }
  %t264 = alloca { i64, i64 }
  %t312 = alloca { i64, i64 }
  %t325 = alloca { i64, i64 }
  %t338 = alloca { i64, i64 }
  %t351 = alloca { i64, i64 }
  %t377 = alloca { i64, i64 }
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t2 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t3 = icmp eq %Enemy* %t2, null
  br i1 %t3, label %spawn_init_24, label %spawn_ready_25
spawn_init_24:
  %t4 = getelementptr %Enemy, %Enemy* null, i32 1
  %t5 = ptrtoint %Enemy* %t4 to i64
  %t6 = mul i64 %t5, 1024
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to %Enemy*
  store %Enemy* %t8, %Enemy** @arena.Enemies.data
  br label %spawn_ready_25
spawn_ready_25:
  %t9 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t10 = load i64, i64* @arena.Enemies.free_top
  %t11 = icmp sgt i64 %t10, 0
  br i1 %t11, label %spawn_reuse_26, label %spawn_grow_27
spawn_reuse_26:
  %t12 = sub i64 %t10, 1
  store i64 %t12, i64* @arena.Enemies.free_top
  %t13 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t12
  %t14 = load i64, i64* %t13
  br label %spawn_store_28
spawn_grow_27:
  %t15 = load i64, i64* @arena.Enemies.count
  %t16 = icmp slt i64 %t15, 1024
  br i1 %t16, label %spawn_grow_ok_30, label %spawn_capacity_warn_31
spawn_capacity_warn_31:
  %t17 = load i1, i1* @arena.Enemies.warned
  br i1 %t17, label %spawn_end_29, label %spawn_warn_print_32
spawn_warn_print_32:
  store i1 1, i1* @arena.Enemies.warned
  %t18 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.0, i64 0, i64 0
  call i32 @puts(i8* %t18)
  br label %spawn_end_29
spawn_grow_ok_30:
  %t19 = add i64 %t15, 1
  store i64 %t19, i64* @arena.Enemies.count
  br label %spawn_store_28
spawn_store_28:
  %t20 = phi i64 [ %t14, %spawn_reuse_26 ], [ %t15, %spawn_grow_ok_30 ]
  %t22 = getelementptr inbounds %Enemy, %Enemy* %t21, i32 0, i32 0
  store i32 10, i32* %t22
  %t23 = load %Enemy, %Enemy* %t21
  %t24 = getelementptr inbounds %Enemy, %Enemy* %t9, i64 %t20
  store %Enemy %t23, %Enemy* %t24
  %t25 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t20
  %t26 = load i64, i64* %t25
  %t27 = add i64 %t26, 1
  store i64 %t27, i64* %t25
  %t28 = trunc i64 %t20 to i32
  br label %spawn_end_29
spawn_end_29:
  %t29 = phi i32 [ %t28, %spawn_store_28 ], [ -1, %spawn_capacity_warn_31 ], [ -1, %spawn_warn_print_32 ]
  %t30 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t31 = icmp eq %Enemy* %t30, null
  br i1 %t31, label %spawn_init_33, label %spawn_ready_34
spawn_init_33:
  %t32 = getelementptr %Enemy, %Enemy* null, i32 1
  %t33 = ptrtoint %Enemy* %t32 to i64
  %t34 = mul i64 %t33, 1024
  %t35 = call i8* @malloc(i64 %t34)
  %t36 = bitcast i8* %t35 to %Enemy*
  store %Enemy* %t36, %Enemy** @arena.Enemies.data
  br label %spawn_ready_34
spawn_ready_34:
  %t37 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t38 = load i64, i64* @arena.Enemies.free_top
  %t39 = icmp sgt i64 %t38, 0
  br i1 %t39, label %spawn_reuse_35, label %spawn_grow_36
spawn_reuse_35:
  %t40 = sub i64 %t38, 1
  store i64 %t40, i64* @arena.Enemies.free_top
  %t41 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t40
  %t42 = load i64, i64* %t41
  br label %spawn_store_37
spawn_grow_36:
  %t43 = load i64, i64* @arena.Enemies.count
  %t44 = icmp slt i64 %t43, 1024
  br i1 %t44, label %spawn_grow_ok_39, label %spawn_capacity_warn_40
spawn_capacity_warn_40:
  %t45 = load i1, i1* @arena.Enemies.warned
  br i1 %t45, label %spawn_end_38, label %spawn_warn_print_41
spawn_warn_print_41:
  store i1 1, i1* @arena.Enemies.warned
  %t46 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t46)
  br label %spawn_end_38
spawn_grow_ok_39:
  %t47 = add i64 %t43, 1
  store i64 %t47, i64* @arena.Enemies.count
  br label %spawn_store_37
spawn_store_37:
  %t48 = phi i64 [ %t42, %spawn_reuse_35 ], [ %t43, %spawn_grow_ok_39 ]
  %t50 = getelementptr inbounds %Enemy, %Enemy* %t49, i32 0, i32 0
  store i32 20, i32* %t50
  %t51 = load %Enemy, %Enemy* %t49
  %t52 = getelementptr inbounds %Enemy, %Enemy* %t37, i64 %t48
  store %Enemy %t51, %Enemy* %t52
  %t53 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t48
  %t54 = load i64, i64* %t53
  %t55 = add i64 %t54, 1
  store i64 %t55, i64* %t53
  %t56 = trunc i64 %t48 to i32
  br label %spawn_end_38
spawn_end_38:
  %t57 = phi i32 [ %t56, %spawn_store_37 ], [ -1, %spawn_capacity_warn_40 ], [ -1, %spawn_warn_print_41 ]
  %t58 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t59 = icmp eq %Enemy* %t58, null
  br i1 %t59, label %spawn_init_42, label %spawn_ready_43
spawn_init_42:
  %t60 = getelementptr %Enemy, %Enemy* null, i32 1
  %t61 = ptrtoint %Enemy* %t60 to i64
  %t62 = mul i64 %t61, 1024
  %t63 = call i8* @malloc(i64 %t62)
  %t64 = bitcast i8* %t63 to %Enemy*
  store %Enemy* %t64, %Enemy** @arena.Enemies.data
  br label %spawn_ready_43
spawn_ready_43:
  %t65 = load %Enemy*, %Enemy** @arena.Enemies.data
  %t66 = load i64, i64* @arena.Enemies.free_top
  %t67 = icmp sgt i64 %t66, 0
  br i1 %t67, label %spawn_reuse_44, label %spawn_grow_45
spawn_reuse_44:
  %t68 = sub i64 %t66, 1
  store i64 %t68, i64* @arena.Enemies.free_top
  %t69 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.free, i64 0, i64 %t68
  %t70 = load i64, i64* %t69
  br label %spawn_store_46
spawn_grow_45:
  %t71 = load i64, i64* @arena.Enemies.count
  %t72 = icmp slt i64 %t71, 1024
  br i1 %t72, label %spawn_grow_ok_48, label %spawn_capacity_warn_49
spawn_capacity_warn_49:
  %t73 = load i1, i1* @arena.Enemies.warned
  br i1 %t73, label %spawn_end_47, label %spawn_warn_print_50
spawn_warn_print_50:
  store i1 1, i1* @arena.Enemies.warned
  %t74 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t74)
  br label %spawn_end_47
spawn_grow_ok_48:
  %t75 = add i64 %t71, 1
  store i64 %t75, i64* @arena.Enemies.count
  br label %spawn_store_46
spawn_store_46:
  %t76 = phi i64 [ %t70, %spawn_reuse_44 ], [ %t71, %spawn_grow_ok_48 ]
  %t78 = getelementptr inbounds %Enemy, %Enemy* %t77, i32 0, i32 0
  store i32 30, i32* %t78
  %t79 = load %Enemy, %Enemy* %t77
  %t80 = getelementptr inbounds %Enemy, %Enemy* %t65, i64 %t76
  store %Enemy %t79, %Enemy* %t80
  %t81 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t76
  %t82 = load i64, i64* %t81
  %t83 = add i64 %t82, 1
  store i64 %t83, i64* %t81
  %t84 = trunc i64 %t76 to i32
  br label %spawn_end_47
spawn_end_47:
  %t85 = phi i32 [ %t84, %spawn_store_46 ], [ -1, %spawn_capacity_warn_49 ], [ -1, %spawn_warn_print_50 ]
  %t86 = load %Particle*, %Particle** @arena.Particles.data
  %t87 = icmp eq %Particle* %t86, null
  br i1 %t87, label %spawn_init_51, label %spawn_ready_52
spawn_init_51:
  %t88 = getelementptr %Particle, %Particle* null, i32 1
  %t89 = ptrtoint %Particle* %t88 to i64
  %t90 = mul i64 %t89, 1024
  %t91 = call i8* @malloc(i64 %t90)
  %t92 = bitcast i8* %t91 to %Particle*
  store %Particle* %t92, %Particle** @arena.Particles.data
  br label %spawn_ready_52
spawn_ready_52:
  %t93 = load %Particle*, %Particle** @arena.Particles.data
  %t94 = load i64, i64* @arena.Particles.free_top
  %t95 = icmp sgt i64 %t94, 0
  br i1 %t95, label %spawn_reuse_53, label %spawn_grow_54
spawn_reuse_53:
  %t96 = sub i64 %t94, 1
  store i64 %t96, i64* @arena.Particles.free_top
  %t97 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t96
  %t98 = load i64, i64* %t97
  br label %spawn_store_55
spawn_grow_54:
  %t99 = load i64, i64* @arena.Particles.count
  %t100 = icmp slt i64 %t99, 1024
  br i1 %t100, label %spawn_grow_ok_57, label %spawn_capacity_warn_58
spawn_capacity_warn_58:
  %t101 = load i1, i1* @arena.Particles.warned
  br i1 %t101, label %spawn_end_56, label %spawn_warn_print_59
spawn_warn_print_59:
  store i1 1, i1* @arena.Particles.warned
  %t102 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t102)
  br label %spawn_end_56
spawn_grow_ok_57:
  %t103 = add i64 %t99, 1
  store i64 %t103, i64* @arena.Particles.count
  br label %spawn_store_55
spawn_store_55:
  %t104 = phi i64 [ %t98, %spawn_reuse_53 ], [ %t99, %spawn_grow_ok_57 ]
  %t106 = getelementptr inbounds %Particle, %Particle* %t105, i32 0, i32 0
  store i32 5, i32* %t106
  %t107 = load %Particle, %Particle* %t105
  %t108 = getelementptr inbounds %Particle, %Particle* %t93, i64 %t104
  store %Particle %t107, %Particle* %t108
  %t109 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t104
  %t110 = load i64, i64* %t109
  %t111 = add i64 %t110, 1
  store i64 %t111, i64* %t109
  %t112 = trunc i64 %t104 to i32
  br label %spawn_end_56
spawn_end_56:
  %t113 = phi i32 [ %t112, %spawn_store_55 ], [ -1, %spawn_capacity_warn_58 ], [ -1, %spawn_warn_print_59 ]
  %t114 = load %Particle*, %Particle** @arena.Particles.data
  %t115 = icmp eq %Particle* %t114, null
  br i1 %t115, label %spawn_init_60, label %spawn_ready_61
spawn_init_60:
  %t116 = getelementptr %Particle, %Particle* null, i32 1
  %t117 = ptrtoint %Particle* %t116 to i64
  %t118 = mul i64 %t117, 1024
  %t119 = call i8* @malloc(i64 %t118)
  %t120 = bitcast i8* %t119 to %Particle*
  store %Particle* %t120, %Particle** @arena.Particles.data
  br label %spawn_ready_61
spawn_ready_61:
  %t121 = load %Particle*, %Particle** @arena.Particles.data
  %t122 = load i64, i64* @arena.Particles.free_top
  %t123 = icmp sgt i64 %t122, 0
  br i1 %t123, label %spawn_reuse_62, label %spawn_grow_63
spawn_reuse_62:
  %t124 = sub i64 %t122, 1
  store i64 %t124, i64* @arena.Particles.free_top
  %t125 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.free, i64 0, i64 %t124
  %t126 = load i64, i64* %t125
  br label %spawn_store_64
spawn_grow_63:
  %t127 = load i64, i64* @arena.Particles.count
  %t128 = icmp slt i64 %t127, 1024
  br i1 %t128, label %spawn_grow_ok_66, label %spawn_capacity_warn_67
spawn_capacity_warn_67:
  %t129 = load i1, i1* @arena.Particles.warned
  br i1 %t129, label %spawn_end_65, label %spawn_warn_print_68
spawn_warn_print_68:
  store i1 1, i1* @arena.Particles.warned
  %t130 = getelementptr inbounds [142 x i8], [142 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t130)
  br label %spawn_end_65
spawn_grow_ok_66:
  %t131 = add i64 %t127, 1
  store i64 %t131, i64* @arena.Particles.count
  br label %spawn_store_64
spawn_store_64:
  %t132 = phi i64 [ %t126, %spawn_reuse_62 ], [ %t127, %spawn_grow_ok_66 ]
  %t134 = getelementptr inbounds %Particle, %Particle* %t133, i32 0, i32 0
  store i32 8, i32* %t134
  %t135 = load %Particle, %Particle* %t133
  %t136 = getelementptr inbounds %Particle, %Particle* %t121, i64 %t132
  store %Particle %t135, %Particle* %t136
  %t137 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t132
  %t138 = load i64, i64* %t137
  %t139 = add i64 %t138, 1
  store i64 %t139, i64* %t137
  %t140 = trunc i64 %t132 to i32
  br label %spawn_end_65
spawn_end_65:
  %t141 = phi i32 [ %t140, %spawn_store_64 ], [ -1, %spawn_capacity_warn_67 ], [ -1, %spawn_warn_print_68 ]
  call void @par.pool.ensure_init()
  %t142 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @sys.UpdateEnemies, i32 (i8*)** %t142
  %t143 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* null, i8** %t143
  %t144 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t145 = load i8*, i8** %t144
  %t146 = call i32 @ReleaseSemaphore(i8* %t145, i32 1, i32* null)
  %t147 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @sys.UpdateParticles, i32 (i8*)** %t147
  %t148 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* null, i8** %t148
  %t149 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t150 = load i8*, i8** %t149
  %t151 = call i32 @ReleaseSemaphore(i8* %t150, i32 1, i32* null)
  %t152 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t153 = load i8*, i8** %t152
  %t154 = call i32 @WaitForSingleObject(i8* %t153, i32 -1)
  %t155 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t156 = load i8*, i8** %t155
  %t157 = call i32 @WaitForSingleObject(i8* %t156, i32 -1)
  call void @par.pool.ensure_init()
  %t176 = call i32 @GetCurrentThreadId()
  %t177 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t178 = load i32, i32* %t177
  %t179 = icmp eq i32 %t176, %t178
  %t180 = select i1 %t179, i32 0, i32 -1
  %t181 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t182 = load i32, i32* %t181
  %t183 = icmp eq i32 %t176, %t182
  %t184 = select i1 %t183, i32 1, i32 %t180
  %t185 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t186 = load i32, i32* %t185
  %t187 = icmp eq i32 %t176, %t186
  %t188 = select i1 %t187, i32 2, i32 %t184
  %t189 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t190 = load i32, i32* %t189
  %t191 = icmp eq i32 %t176, %t190
  %t192 = select i1 %t191, i32 3, i32 %t188
  %t193 = icmp sge i32 %t192, 0
  br i1 %t193, label %par_serial_76, label %par_pooled_75
par_pooled_75:
  %t194 = load i64, i64* @arena.Enemies.count
  %t195 = mul i64 %t194, 0
  %t196 = sdiv i64 %t195, 4
  %t197 = mul i64 %t194, 1
  %t198 = sdiv i64 %t197, 4
  %t200 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t199, i32 0, i32 0
  store i64 %t196, i64* %t200
  %t201 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t199, i32 0, i32 1
  store i64 %t198, i64* %t201
  %t202 = bitcast { i64, i64 }* %t199 to i8*
  %t203 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t202, i8** %t203
  %t204 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_69, i32 (i8*)** %t204
  %t205 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t206 = load i8*, i8** %t205
  %t207 = call i32 @ReleaseSemaphore(i8* %t206, i32 1, i32* null)
  %t208 = mul i64 %t194, 1
  %t209 = sdiv i64 %t208, 4
  %t210 = mul i64 %t194, 2
  %t211 = sdiv i64 %t210, 4
  %t213 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t212, i32 0, i32 0
  store i64 %t209, i64* %t213
  %t214 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t212, i32 0, i32 1
  store i64 %t211, i64* %t214
  %t215 = bitcast { i64, i64 }* %t212 to i8*
  %t216 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t215, i8** %t216
  %t217 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_69, i32 (i8*)** %t217
  %t218 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t219 = load i8*, i8** %t218
  %t220 = call i32 @ReleaseSemaphore(i8* %t219, i32 1, i32* null)
  %t221 = mul i64 %t194, 2
  %t222 = sdiv i64 %t221, 4
  %t223 = mul i64 %t194, 3
  %t224 = sdiv i64 %t223, 4
  %t226 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t225, i32 0, i32 0
  store i64 %t222, i64* %t226
  %t227 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t225, i32 0, i32 1
  store i64 %t224, i64* %t227
  %t228 = bitcast { i64, i64 }* %t225 to i8*
  %t229 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t228, i8** %t229
  %t230 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_69, i32 (i8*)** %t230
  %t231 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t232 = load i8*, i8** %t231
  %t233 = call i32 @ReleaseSemaphore(i8* %t232, i32 1, i32* null)
  %t234 = mul i64 %t194, 3
  %t235 = sdiv i64 %t234, 4
  %t236 = mul i64 %t194, 4
  %t237 = sdiv i64 %t236, 4
  %t239 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t238, i32 0, i32 0
  store i64 %t235, i64* %t239
  %t240 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t238, i32 0, i32 1
  store i64 %t237, i64* %t240
  %t241 = bitcast { i64, i64 }* %t238 to i8*
  %t242 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t241, i8** %t242
  %t243 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_69, i32 (i8*)** %t243
  %t244 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t245 = load i8*, i8** %t244
  %t246 = call i32 @ReleaseSemaphore(i8* %t245, i32 1, i32* null)
  %t247 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t248 = load i8*, i8** %t247
  %t249 = call i32 @WaitForSingleObject(i8* %t248, i32 -1)
  %t250 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t251 = load i8*, i8** %t250
  %t252 = call i32 @WaitForSingleObject(i8* %t251, i32 -1)
  %t253 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t254 = load i8*, i8** %t253
  %t255 = call i32 @WaitForSingleObject(i8* %t254, i32 -1)
  %t256 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t257 = load i8*, i8** %t256
  %t258 = call i32 @WaitForSingleObject(i8* %t257, i32 -1)
  br label %par_join_80
par_serial_76:
  %t259 = load i32, i32* @par.pool.serial_owner
  %t260 = icmp eq i32 %t259, %t192
  br i1 %t260, label %par_run_78, label %par_acquire_77
par_acquire_77:
  %t261 = load i8*, i8** @par.pool.serial_lock
  %t262 = call i32 @WaitForSingleObject(i8* %t261, i32 -1)
  store i32 %t192, i32* @par.pool.serial_owner
  br label %par_run_78
par_run_78:
  %t263 = load i64, i64* @arena.Enemies.count
  %t265 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t264, i32 0, i32 0
  store i64 0, i64* %t265
  %t266 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t264, i32 0, i32 1
  store i64 %t263, i64* %t266
  %t267 = bitcast { i64, i64 }* %t264 to i8*
  %t268 = call i32 @par_worker_69(i8* %t267)
  br i1 %t260, label %par_join_80, label %par_release_79
par_release_79:
  store i32 -1, i32* @par.pool.serial_owner
  %t269 = load i8*, i8** @par.pool.serial_lock
  %t270 = call i32 @ReleaseSemaphore(i8* %t269, i32 1, i32* null)
  br label %par_join_80
par_join_80:
  call void @par.pool.ensure_init()
  %t289 = call i32 @GetCurrentThreadId()
  %t290 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t291 = load i32, i32* %t290
  %t292 = icmp eq i32 %t289, %t291
  %t293 = select i1 %t292, i32 0, i32 -1
  %t294 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t295 = load i32, i32* %t294
  %t296 = icmp eq i32 %t289, %t295
  %t297 = select i1 %t296, i32 1, i32 %t293
  %t298 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t299 = load i32, i32* %t298
  %t300 = icmp eq i32 %t289, %t299
  %t301 = select i1 %t300, i32 2, i32 %t297
  %t302 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t303 = load i32, i32* %t302
  %t304 = icmp eq i32 %t289, %t303
  %t305 = select i1 %t304, i32 3, i32 %t301
  %t306 = icmp sge i32 %t305, 0
  br i1 %t306, label %par_serial_88, label %par_pooled_87
par_pooled_87:
  %t307 = load i64, i64* @arena.Particles.count
  %t308 = mul i64 %t307, 0
  %t309 = sdiv i64 %t308, 4
  %t310 = mul i64 %t307, 1
  %t311 = sdiv i64 %t310, 4
  %t313 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t312, i32 0, i32 0
  store i64 %t309, i64* %t313
  %t314 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t312, i32 0, i32 1
  store i64 %t311, i64* %t314
  %t315 = bitcast { i64, i64 }* %t312 to i8*
  %t316 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t315, i8** %t316
  %t317 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_81, i32 (i8*)** %t317
  %t318 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t319 = load i8*, i8** %t318
  %t320 = call i32 @ReleaseSemaphore(i8* %t319, i32 1, i32* null)
  %t321 = mul i64 %t307, 1
  %t322 = sdiv i64 %t321, 4
  %t323 = mul i64 %t307, 2
  %t324 = sdiv i64 %t323, 4
  %t326 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t325, i32 0, i32 0
  store i64 %t322, i64* %t326
  %t327 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t325, i32 0, i32 1
  store i64 %t324, i64* %t327
  %t328 = bitcast { i64, i64 }* %t325 to i8*
  %t329 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t328, i8** %t329
  %t330 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_81, i32 (i8*)** %t330
  %t331 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t332 = load i8*, i8** %t331
  %t333 = call i32 @ReleaseSemaphore(i8* %t332, i32 1, i32* null)
  %t334 = mul i64 %t307, 2
  %t335 = sdiv i64 %t334, 4
  %t336 = mul i64 %t307, 3
  %t337 = sdiv i64 %t336, 4
  %t339 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t338, i32 0, i32 0
  store i64 %t335, i64* %t339
  %t340 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t338, i32 0, i32 1
  store i64 %t337, i64* %t340
  %t341 = bitcast { i64, i64 }* %t338 to i8*
  %t342 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t341, i8** %t342
  %t343 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_81, i32 (i8*)** %t343
  %t344 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t345 = load i8*, i8** %t344
  %t346 = call i32 @ReleaseSemaphore(i8* %t345, i32 1, i32* null)
  %t347 = mul i64 %t307, 3
  %t348 = sdiv i64 %t347, 4
  %t349 = mul i64 %t307, 4
  %t350 = sdiv i64 %t349, 4
  %t352 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t351, i32 0, i32 0
  store i64 %t348, i64* %t352
  %t353 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t351, i32 0, i32 1
  store i64 %t350, i64* %t353
  %t354 = bitcast { i64, i64 }* %t351 to i8*
  %t355 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t354, i8** %t355
  %t356 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_81, i32 (i8*)** %t356
  %t357 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t358 = load i8*, i8** %t357
  %t359 = call i32 @ReleaseSemaphore(i8* %t358, i32 1, i32* null)
  %t360 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t361 = load i8*, i8** %t360
  %t362 = call i32 @WaitForSingleObject(i8* %t361, i32 -1)
  %t363 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t364 = load i8*, i8** %t363
  %t365 = call i32 @WaitForSingleObject(i8* %t364, i32 -1)
  %t366 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t367 = load i8*, i8** %t366
  %t368 = call i32 @WaitForSingleObject(i8* %t367, i32 -1)
  %t369 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t370 = load i8*, i8** %t369
  %t371 = call i32 @WaitForSingleObject(i8* %t370, i32 -1)
  br label %par_join_92
par_serial_88:
  %t372 = load i32, i32* @par.pool.serial_owner
  %t373 = icmp eq i32 %t372, %t305
  br i1 %t373, label %par_run_90, label %par_acquire_89
par_acquire_89:
  %t374 = load i8*, i8** @par.pool.serial_lock
  %t375 = call i32 @WaitForSingleObject(i8* %t374, i32 -1)
  store i32 %t305, i32* @par.pool.serial_owner
  br label %par_run_90
par_run_90:
  %t376 = load i64, i64* @arena.Particles.count
  %t378 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t377, i32 0, i32 0
  store i64 0, i64* %t378
  %t379 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t377, i32 0, i32 1
  store i64 %t376, i64* %t379
  %t380 = bitcast { i64, i64 }* %t377 to i8*
  %t381 = call i32 @par_worker_81(i8* %t380)
  br i1 %t373, label %par_join_92, label %par_release_91
par_release_91:
  store i32 -1, i32* @par.pool.serial_owner
  %t382 = load i8*, i8** @par.pool.serial_lock
  %t383 = call i32 @ReleaseSemaphore(i8* %t382, i32 1, i32* null)
  br label %par_join_92
par_join_92:
  %t384 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t384)
  ret i32 0
}


; par/swarm worker functions
define i32 @par_worker_0(i8* %argp) {
entry:
  %t6 = alloca i64
  %t0 = bitcast i8* %argp to { i64, i64 }*
  %t1 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 0
  %t2 = load i64, i64* %t1
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t2, i64* %t6
  br label %par_cond_1
par_cond_1:
  %t7 = load i64, i64* %t6
  %t8 = icmp slt i64 %t7, %t4
  br i1 %t8, label %par_body_2, label %par_end_5
par_body_2:
  %t9 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t7
  %t10 = load i64, i64* %t9
  %t11 = and i64 %t10, 1
  %t12 = icmp eq i64 %t11, 1
  br i1 %t12, label %par_live_3, label %par_incr_4
par_live_3:
  %t13 = getelementptr inbounds %Enemy, %Enemy* %t5, i64 %t7
  %t14 = getelementptr inbounds %Enemy, %Enemy* %t13, i32 0, i32 0
  %t15 = load i32, i32* %t14
  %t16 = sub i32 %t15, 1
  %t17 = getelementptr inbounds %Enemy, %Enemy* %t13, i32 0, i32 0
  store i32 %t16, i32* %t17
  br label %par_incr_4
par_incr_4:
  %t18 = add i64 %t7, 1
  store i64 %t18, i64* %t6
  br label %par_cond_1
par_end_5:
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
  %t19 = ptrtoint i8* %idx_arg to i64
  %t20 = trunc i64 %t19 to i32
  %t21 = call i32 @GetCurrentThreadId()
  %t22 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t20
  store i32 %t21, i32* %t22
  br label %loop
loop:
  %t23 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t20
  %t24 = load i8*, i8** %t23
  %t25 = call i32 @WaitForSingleObject(i8* %t24, i32 -1)
  %t26 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t20
  %t27 = load i32 (i8*)*, i32 (i8*)** %t26
  %t28 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t20
  %t29 = load i8*, i8** %t28
  %t30 = call i32 %t27(i8* %t29)
  %t31 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t20
  %t32 = load i8*, i8** %t31
  %t33 = call i32 @ReleaseSemaphore(i8* %t32, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t34 = load i1, i1* @par.pool.inited
  br i1 %t34, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t35 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t35, i8** @par.pool.serial_lock
  %t36 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t37 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t36, i8** %t37
  %t38 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t39 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t38, i8** %t39
  %t40 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t41 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t42 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t41, i8** %t42
  %t43 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t44 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t43, i8** %t44
  %t45 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t46 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t47 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t46, i8** %t47
  %t48 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t49 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t48, i8** %t49
  %t50 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t51 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t52 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t51, i8** %t52
  %t53 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t54 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t53, i8** %t54
  %t55 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_12(i8* %argp) {
entry:
  %t6 = alloca i64
  %t0 = bitcast i8* %argp to { i64, i64 }*
  %t1 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 0
  %t2 = load i64, i64* %t1
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t0, i32 0, i32 1
  %t4 = load i64, i64* %t3
  %t5 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t2, i64* %t6
  br label %par_cond_13
par_cond_13:
  %t7 = load i64, i64* %t6
  %t8 = icmp slt i64 %t7, %t4
  br i1 %t8, label %par_body_14, label %par_end_17
par_body_14:
  %t9 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t7
  %t10 = load i64, i64* %t9
  %t11 = and i64 %t10, 1
  %t12 = icmp eq i64 %t11, 1
  br i1 %t12, label %par_live_15, label %par_incr_16
par_live_15:
  %t13 = getelementptr inbounds %Particle, %Particle* %t5, i64 %t7
  %t14 = getelementptr inbounds %Particle, %Particle* %t13, i32 0, i32 0
  %t15 = load i32, i32* %t14
  %t16 = sub i32 %t15, 1
  %t17 = getelementptr inbounds %Particle, %Particle* %t13, i32 0, i32 0
  store i32 %t16, i32* %t17
  br label %par_incr_16
par_incr_16:
  %t18 = add i64 %t7, 1
  store i64 %t18, i64* %t6
  br label %par_cond_13
par_end_17:
  ret i32 0
}


define i32 @par_worker_69(i8* %argp) {
entry:
  %t164 = alloca i64
  %t158 = bitcast i8* %argp to { i64, i64 }*
  %t159 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t158, i32 0, i32 0
  %t160 = load i64, i64* %t159
  %t161 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t158, i32 0, i32 1
  %t162 = load i64, i64* %t161
  %t163 = load %Enemy*, %Enemy** @arena.Enemies.data
  store i64 %t160, i64* %t164
  br label %par_cond_70
par_cond_70:
  %t165 = load i64, i64* %t164
  %t166 = icmp slt i64 %t165, %t162
  br i1 %t166, label %par_body_71, label %par_end_74
par_body_71:
  %t167 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Enemies.gen, i64 0, i64 %t165
  %t168 = load i64, i64* %t167
  %t169 = and i64 %t168, 1
  %t170 = icmp eq i64 %t169, 1
  br i1 %t170, label %par_live_72, label %par_incr_73
par_live_72:
  %t171 = getelementptr inbounds %Enemy, %Enemy* %t163, i64 %t165
  %t172 = getelementptr inbounds %Enemy, %Enemy* %t171, i32 0, i32 0
  %t173 = load i32, i32* %t172
  %t174 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t174, i32 %t173)
  br label %par_incr_73
par_incr_73:
  %t175 = add i64 %t165, 1
  store i64 %t175, i64* %t164
  br label %par_cond_70
par_end_74:
  ret i32 0
}


define i32 @par_worker_81(i8* %argp) {
entry:
  %t277 = alloca i64
  %t271 = bitcast i8* %argp to { i64, i64 }*
  %t272 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t271, i32 0, i32 0
  %t273 = load i64, i64* %t272
  %t274 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t271, i32 0, i32 1
  %t275 = load i64, i64* %t274
  %t276 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t273, i64* %t277
  br label %par_cond_82
par_cond_82:
  %t278 = load i64, i64* %t277
  %t279 = icmp slt i64 %t278, %t275
  br i1 %t279, label %par_body_83, label %par_end_86
par_body_83:
  %t280 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Particles.gen, i64 0, i64 %t278
  %t281 = load i64, i64* %t280
  %t282 = and i64 %t281, 1
  %t283 = icmp eq i64 %t282, 1
  br i1 %t283, label %par_live_84, label %par_incr_85
par_live_84:
  %t284 = getelementptr inbounds %Particle, %Particle* %t276, i64 %t278
  %t285 = getelementptr inbounds %Particle, %Particle* %t284, i32 0, i32 0
  %t286 = load i32, i32* %t285
  %t287 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t287, i32 %t286)
  br label %par_incr_85
par_incr_85:
  %t288 = add i64 %t278, 1
  store i64 %t288, i64* %t277
  br label %par_cond_82
par_end_86:
  ret i32 0
}



; Global Constants
@.str.0 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.1 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.2 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Enemies` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.3 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.4 = private unnamed_addr constant [142 x i8] c"star runtime warning: arena `Particles` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.5 = private unnamed_addr constant [14 x i8] c"enemy hp: %d\0A\00"
@.str.6 = private unnamed_addr constant [19 x i8] c"particle life: %d\0A\00"
@.str.7 = private unnamed_addr constant [15 x i8] c"parallel done\0A\00"
