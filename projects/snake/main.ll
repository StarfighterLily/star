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

%food__sb__grid__Cell = type { i32, i32 }
%food__sb__Snake = type { { [768 x %food__sb__grid__Cell], i64, i64 }, i32, i32, i32, i1 }
declare i32 @toupper(i32)
declare i32 @atoi(i8*)
%Particle = type { float, float, float, float, float }
%ParticlePool = type { [32 x %Particle] }
%Particles = type { %Particle*, i64 }
@arena.Particles.data = global %Particle* null
@arena.Particles.count = global i64 0
@arena.Particles.gen = global [256 x i64] zeroinitializer
@arena.Particles.free = global [256 x i64] zeroinitializer
@arena.Particles.free_top = global i64 0
@arena.Particles.warned = global i1 0

%ScratchSlot = type { i32 }
%Scratch = type { %ScratchSlot*, i64 }
@arena.Scratch.data = global %ScratchSlot* null
@arena.Scratch.count = global i64 0
@arena.Scratch.gen = global [1024 x i64] zeroinitializer
@arena.Scratch.free = global [1024 x i64] zeroinitializer
@arena.Scratch.free_top = global i64 0
@arena.Scratch.warned = global i1 0

%Stats = type { i32, i32, i32 }
%FlashOnEat = type { i8*, i32 }
%GameOverFlash = type { i8*, i32 }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define %food__sb__grid__Cell @food__sb__grid__delta(i32 %d) {
entry:
  %t0 = alloca i32
  %t7 = alloca %food__sb__grid__Cell
  %t15 = alloca %food__sb__grid__Cell
  %t22 = alloca %food__sb__grid__Cell
  %t30 = alloca %food__sb__grid__Cell
  store i32 %d, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t6 = icmp eq i32 %t1, 0
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  %t8 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t7, i32 0, i32 0
  store i32 0, i32* %t8
  %t9 = sub i32 0, 1
  %t10 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t7, i32 0, i32 1
  store i32 %t9, i32* %t10
  %t11 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t7
  br label %match_end_2
match_next_0_5:
  %t14 = icmp eq i32 %t1, 1
  br i1 %t14, label %match_then_1_12, label %match_next_1_13
match_then_1_12:
  %t16 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t15, i32 0, i32 0
  store i32 0, i32* %t16
  %t17 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t15, i32 0, i32 1
  store i32 1, i32* %t17
  %t18 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t15
  br label %match_end_2
match_next_1_13:
  %t21 = icmp eq i32 %t1, 2
  br i1 %t21, label %match_then_2_19, label %match_next_2_20
match_then_2_19:
  %t23 = sub i32 0, 1
  %t24 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t22, i32 0, i32 0
  store i32 %t23, i32* %t24
  %t25 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t22, i32 0, i32 1
  store i32 0, i32* %t25
  %t26 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t22
  br label %match_end_2
match_next_2_20:
  %t29 = icmp eq i32 %t1, 3
  br i1 %t29, label %match_then_3_27, label %match_next_3_28
match_then_3_27:
  %t31 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t30, i32 0, i32 0
  store i32 1, i32* %t31
  %t32 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t30, i32 0, i32 1
  store i32 0, i32* %t32
  %t33 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t30
  br label %match_end_2
match_next_3_28:
  br label %match_end_2
match_end_2:
  %t34 = phi %food__sb__grid__Cell [ %t11, %match_then_0_4 ], [ %t18, %match_then_1_12 ], [ %t26, %match_then_2_19 ], [ %t33, %match_then_3_27 ], [ undef, %match_next_3_28 ]
  ret %food__sb__grid__Cell %t34
}

define i32 @food__sb__grid__opposite(i32 %d) {
entry:
  %t0 = alloca i32
  store i32 %d, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t6 = icmp eq i32 %t1, 0
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  br label %match_end_2
match_next_0_5:
  %t9 = icmp eq i32 %t1, 1
  br i1 %t9, label %match_then_1_7, label %match_next_1_8
match_then_1_7:
  br label %match_end_2
match_next_1_8:
  %t12 = icmp eq i32 %t1, 2
  br i1 %t12, label %match_then_2_10, label %match_next_2_11
match_then_2_10:
  br label %match_end_2
match_next_2_11:
  %t15 = icmp eq i32 %t1, 3
  br i1 %t15, label %match_then_3_13, label %match_next_3_14
match_then_3_13:
  br label %match_end_2
match_next_3_14:
  br label %match_end_2
match_end_2:
  %t16 = phi i32 [ 1, %match_then_0_4 ], [ 0, %match_then_1_7 ], [ 3, %match_then_2_10 ], [ 2, %match_then_3_13 ], [ undef, %match_next_3_14 ]
  ret i32 %t16
}

define i8* @food__sb__grid__dir_name(i32 %d) {
entry:
  %t0 = alloca i32
  store i32 %d, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t6 = icmp eq i32 %t1, 0
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  %t7 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.0, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_0_5:
  %t10 = icmp eq i32 %t1, 1
  br i1 %t10, label %match_then_1_8, label %match_next_1_9
match_then_1_8:
  %t11 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.1, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_1_9:
  %t14 = icmp eq i32 %t1, 2
  br i1 %t14, label %match_then_2_12, label %match_next_2_13
match_then_2_12:
  %t15 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.2, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_2_13:
  %t18 = icmp eq i32 %t1, 3
  br i1 %t18, label %match_then_3_16, label %match_next_3_17
match_then_3_16:
  %t19 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_3_17:
  br label %match_end_2
match_end_2:
  %t20 = phi i8* [ %t7, %match_then_0_4 ], [ %t11, %match_then_1_8 ], [ %t15, %match_then_2_12 ], [ %t19, %match_then_3_16 ], [ undef, %match_next_3_17 ]
  ret i8* %t20
}

define %food__sb__grid__Cell @food__sb__grid__wrap(%food__sb__grid__Cell %c) {
entry:
  %t0 = alloca %food__sb__grid__Cell
  %t1 = alloca i32
  %t4 = alloca i32
  %t17 = alloca %food__sb__grid__Cell
  store %food__sb__grid__Cell %c, %food__sb__grid__Cell* %t0
  %t2 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  store i32 %t3, i32* %t1
  %t5 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 1
  %t6 = load i32, i32* %t5
  store i32 %t6, i32* %t4
  %t7 = load i32, i32* %t1
  %t8 = icmp slt i32 %t7, 0
  br i1 %t8, label %if_then_0, label %if_else_1
if_then_0:
  %t9 = sub i32 32, 1
  store i32 %t9, i32* %t1
  br label %if_end_2
if_else_1:
  br label %if_end_2
if_end_2:
  %t10 = load i32, i32* %t1
  %t11 = icmp sge i32 %t10, 32
  br i1 %t11, label %if_then_3, label %if_else_4
if_then_3:
  store i32 0, i32* %t1
  br label %if_end_5
if_else_4:
  br label %if_end_5
if_end_5:
  %t12 = load i32, i32* %t4
  %t13 = icmp slt i32 %t12, 0
  br i1 %t13, label %if_then_6, label %if_else_7
if_then_6:
  %t14 = sub i32 24, 1
  store i32 %t14, i32* %t4
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t15 = load i32, i32* %t4
  %t16 = icmp sge i32 %t15, 24
  br i1 %t16, label %if_then_9, label %if_else_10
if_then_9:
  store i32 0, i32* %t4
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t18 = load i32, i32* %t1
  %t19 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t17, i32 0, i32 0
  store i32 %t18, i32* %t19
  %t20 = load i32, i32* %t4
  %t21 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t17, i32 0, i32 1
  store i32 %t20, i32* %t21
  %t22 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t17
  ret %food__sb__grid__Cell %t22
}

define %food__sb__grid__Cell @food__sb__grid__cell_add(%food__sb__grid__Cell %a, %food__sb__grid__Cell %b) {
entry:
  %t0 = alloca %food__sb__grid__Cell
  %t1 = alloca %food__sb__grid__Cell
  %t2 = alloca %food__sb__grid__Cell
  store %food__sb__grid__Cell %a, %food__sb__grid__Cell* %t0
  store %food__sb__grid__Cell %b, %food__sb__grid__Cell* %t1
  %t3 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 0
  %t4 = load i32, i32* %t3
  %t5 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t1, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = add i32 %t4, %t6
  %t8 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t2, i32 0, i32 0
  store i32 %t7, i32* %t8
  %t9 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t1, i32 0, i32 1
  %t12 = load i32, i32* %t11
  %t13 = add i32 %t10, %t12
  %t14 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t2, i32 0, i32 1
  store i32 %t13, i32* %t14
  %t15 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t2
  ret %food__sb__grid__Cell %t15
}

define %food__sb__grid__Cell @food__sb__Snake__head(%food__sb__Snake* %self) {
entry:
  %t0 = alloca %food__sb__Snake*
  %t24 = alloca %food__sb__grid__Cell
  store %food__sb__Snake* %self, %food__sb__Snake** %t0
  %t1 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t2 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t1, i32 0, i32 0
  %t3 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t2, i32 0, i32 0
  %t4 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t2, i32 0, i32 1
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t2, i32 0, i32 2
  %t7 = load i64, i64* %t6
  %t8 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t9 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t8, i32 0, i32 0
  %t10 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t9, i32 0, i32 0
  %t11 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t9, i32 0, i32 1
  %t12 = load i64, i64* %t11
  %t13 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t9, i32 0, i32 2
  %t14 = load i64, i64* %t13
  %t15 = trunc i64 %t14 to i32
  %t16 = sub i32 %t15, 1
  %t17 = sext i32 %t16 to i64
  %t18 = load i64, i64* %t4
  %t19 = load i64, i64* %t6
  %t20 = icmp ult i64 %t17, %t19
  br i1 %t20, label %ring_rplace_ok_12, label %ring_rplace_oob_13
ring_rplace_ok_12:
  %t21 = add i64 %t18, %t17
  %t22 = urem i64 %t21, 768
  %t23 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t3, i32 0, i64 %t22
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t24
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t25 = phi %food__sb__grid__Cell* [ %t23, %ring_rplace_ok_12 ], [ %t24, %ring_rplace_oob_13 ]
  %t26 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t25
  ret %food__sb__grid__Cell %t26
}

define i32 @food__sb__Snake__length(%food__sb__Snake* %self) {
entry:
  %t0 = alloca %food__sb__Snake*
  store %food__sb__Snake* %self, %food__sb__Snake** %t0
  %t1 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t2 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t1, i32 0, i32 0
  %t3 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t2, i32 0, i32 0
  %t4 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t2, i32 0, i32 1
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t2, i32 0, i32 2
  %t7 = load i64, i64* %t6
  %t8 = trunc i64 %t7 to i32
  ret i32 %t8
}

define i1 @food__sb__Snake__contains(%food__sb__Snake* %self, %food__sb__grid__Cell %c) {
entry:
  %t0 = alloca %food__sb__Snake*
  %t1 = alloca %food__sb__grid__Cell
  %t2 = alloca i32
  %t3 = alloca i1
  %t29 = alloca %food__sb__grid__Cell
  store %food__sb__Snake* %self, %food__sb__Snake** %t0
  store %food__sb__grid__Cell %c, %food__sb__grid__Cell* %t1
  store i32 0, i32* %t2
  store i1 false, i1* %t3
  br label %while_cond_15
while_cond_15:
  %t4 = load i32, i32* %t2
  %t5 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t6 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t5, i32 0, i32 0
  %t7 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t6, i32 0, i32 0
  %t8 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t6, i32 0, i32 1
  %t9 = load i64, i64* %t8
  %t10 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t6, i32 0, i32 2
  %t11 = load i64, i64* %t10
  %t12 = trunc i64 %t11 to i32
  %t13 = icmp slt i32 %t4, %t12
  br i1 %t13, label %while_body_16, label %while_else_17
while_body_16:
  %t14 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t15 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t14, i32 0, i32 0
  %t16 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t15, i32 0, i32 0
  %t17 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t15, i32 0, i32 1
  %t18 = load i64, i64* %t17
  %t19 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t15, i32 0, i32 2
  %t20 = load i64, i64* %t19
  %t21 = load i32, i32* %t2
  %t22 = sext i32 %t21 to i64
  %t23 = load i64, i64* %t17
  %t24 = load i64, i64* %t19
  %t25 = icmp ult i64 %t22, %t24
  br i1 %t25, label %ring_rplace_ok_19, label %ring_rplace_oob_20
ring_rplace_ok_19:
  %t26 = add i64 %t23, %t22
  %t27 = urem i64 %t26, 768
  %t28 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t16, i32 0, i64 %t27
  br label %ring_rplace_end_21
ring_rplace_oob_20:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t29
  br label %ring_rplace_end_21
ring_rplace_end_21:
  %t30 = phi %food__sb__grid__Cell* [ %t28, %ring_rplace_ok_19 ], [ %t29, %ring_rplace_oob_20 ]
  %t31 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t30
  %t32 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t1
  %t40 = call i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %t31, %food__sb__grid__Cell %t32)
  br i1 %t40, label %if_then_22, label %if_else_23
if_then_22:
  store i1 true, i1* %t3
  br label %if_end_24
if_else_23:
  br label %if_end_24
if_end_24:
  %t41 = load i32, i32* %t2
  %t42 = add i32 %t41, 1
  store i32 %t42, i32* %t2
  br label %while_cond_15
while_else_17:
  br label %while_end_18
while_end_18:
  %t43 = load i1, i1* %t3
  ret i1 %t43
}

define void @food__sb__Snake__queue_turn(%food__sb__Snake* %self, i32 %d) {
entry:
  %t0 = alloca %food__sb__Snake*
  %t1 = alloca i32
  %t2 = alloca i1
  store %food__sb__Snake* %self, %food__sb__Snake** %t0
  store i32 %d, i32* %t1
  %t3 = load i32, i32* %t1
  %t4 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t5 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t4, i32 0, i32 1
  %t6 = load i32, i32* %t5
  %t7 = call i32 @food__sb__grid__opposite(i32 %t6)
  %t9 = call i1 @eq_e_food__sb__grid__Direction(i32 %t3, i32 %t7)
  store i1 %t9, i1* %t2
  %t10 = load i1, i1* %t2
  %t11 = xor i1 true, %t10
  br i1 %t11, label %if_then_25, label %if_else_26
if_then_25:
  %t12 = load i32, i32* %t1
  %t13 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t14 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t13, i32 0, i32 2
  store i32 %t12, i32* %t14
  br label %if_end_27
if_else_26:
  br label %if_end_27
if_end_27:
  ret void
}

define void @food__sb__Snake__grow(%food__sb__Snake* %self, i32 %amount) {
entry:
  %t0 = alloca %food__sb__Snake*
  %t1 = alloca i32
  store %food__sb__Snake* %self, %food__sb__Snake** %t0
  store i32 %amount, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t4 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t3, i32 0, i32 3
  %t5 = load i32, i32* %t4
  %t6 = add i32 %t5, %t2
  %t7 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t8 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t7, i32 0, i32 3
  store i32 %t6, i32* %t8
  ret void
}

define %food__sb__grid__Cell @food__sb__Snake__advance(%food__sb__Snake* %self) {
entry:
  %t0 = alloca %food__sb__Snake*
  %t6 = alloca %food__sb__grid__Cell
  store %food__sb__Snake* %self, %food__sb__Snake** %t0
  %t1 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t2 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t1, i32 0, i32 2
  %t3 = load i32, i32* %t2
  %t4 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t5 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t4, i32 0, i32 1
  store i32 %t3, i32* %t5
  %t7 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t8 = call %food__sb__grid__Cell @food__sb__Snake__head(%food__sb__Snake* %t7)
  %t9 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t10 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t9, i32 0, i32 1
  %t11 = load i32, i32* %t10
  %t12 = call %food__sb__grid__Cell @food__sb__grid__delta(i32 %t11)
  %t13 = call %food__sb__grid__Cell @food__sb__grid__cell_add(%food__sb__grid__Cell %t8, %food__sb__grid__Cell %t12)
  %t14 = call %food__sb__grid__Cell @food__sb__grid__wrap(%food__sb__grid__Cell %t13)
  store %food__sb__grid__Cell %t14, %food__sb__grid__Cell* %t6
  %t15 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t16 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t6
  %t17 = call i1 @food__sb__Snake__contains(%food__sb__Snake* %t15, %food__sb__grid__Cell %t16)
  br i1 %t17, label %if_then_28, label %if_else_29
if_then_28:
  %t18 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t19 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t18, i32 0, i32 4
  store i1 false, i1* %t19
  br label %if_end_30
if_else_29:
  br label %if_end_30
if_end_30:
  %t20 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t6
  %t21 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t22 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t21, i32 0, i32 0
  %t23 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t22, i32 0, i32 0
  %t24 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t22, i32 0, i32 1
  %t25 = load i64, i64* %t24
  %t26 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t22, i32 0, i32 2
  %t27 = load i64, i64* %t26
  %t28 = icmp sge i64 %t27, 768
  br i1 %t28, label %ring_push_full_31, label %ring_push_grow_32
ring_push_grow_32:
  %t29 = add i64 %t25, %t27
  %t30 = urem i64 %t29, 768
  %t31 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t23, i32 0, i64 %t30
  store %food__sb__grid__Cell %t20, %food__sb__grid__Cell* %t31
  %t32 = add i64 %t27, 1
  store i64 %t32, i64* %t26
  br label %ring_push_done_33
ring_push_full_31:
  %t33 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t23, i32 0, i64 %t25
  store %food__sb__grid__Cell %t20, %food__sb__grid__Cell* %t33
  %t34 = add i64 %t25, 1
  %t35 = urem i64 %t34, 768
  store i64 %t35, i64* %t24
  br label %ring_push_done_33
ring_push_done_33:
  %t36 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t37 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t36, i32 0, i32 3
  %t38 = load i32, i32* %t37
  %t39 = icmp sgt i32 %t38, 0
  br i1 %t39, label %if_then_34, label %if_else_35
if_then_34:
  %t40 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t41 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t40, i32 0, i32 3
  %t42 = load i32, i32* %t41
  %t43 = sub i32 %t42, 1
  %t44 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t45 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t44, i32 0, i32 3
  store i32 %t43, i32* %t45
  br label %if_end_36
if_else_35:
  %t46 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t47 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t46, i32 0, i32 0
  %t48 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t47, i32 0, i32 0
  %t49 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t47, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t47, i32 0, i32 2
  %t52 = load i64, i64* %t51
  %t53 = icmp eq i64 %t52, 0
  br i1 %t53, label %ring_pop_empty_37, label %ring_pop_nonempty_38
ring_pop_nonempty_38:
  %t54 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t48, i32 0, i64 %t50
  %t55 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t54
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t54
  %t56 = add i64 %t50, 1
  %t57 = urem i64 %t56, 768
  store i64 %t57, i64* %t49
  %t58 = sub i64 %t52, 1
  store i64 %t58, i64* %t51
  br label %ring_pop_end_39
ring_pop_empty_37:
  br label %ring_pop_end_39
ring_pop_end_39:
  %t59 = phi %food__sb__grid__Cell [ %t55, %ring_pop_nonempty_38 ], [ zeroinitializer, %ring_pop_empty_37 ]
  br label %if_end_36
if_end_36:
  %t60 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t6
  ret %food__sb__grid__Cell %t60
}

define %food__sb__Snake @food__sb__make_snake() {
entry:
  %t0 = alloca %food__sb__Snake
  %t1 = alloca %food__sb__Snake
  %t8 = alloca %food__sb__grid__Cell
  %t26 = alloca %food__sb__grid__Cell
  %t44 = alloca %food__sb__grid__Cell
  %t2 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t1, i32 0, i32 0
  store { [768 x %food__sb__grid__Cell], i64, i64 } zeroinitializer, { [768 x %food__sb__grid__Cell], i64, i64 }* %t2
  %t3 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t1, i32 0, i32 1
  store i32 3, i32* %t3
  %t4 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t1, i32 0, i32 2
  store i32 3, i32* %t4
  %t5 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t1, i32 0, i32 3
  store i32 2, i32* %t5
  %t6 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t1, i32 0, i32 4
  store i1 true, i1* %t6
  %t7 = load %food__sb__Snake, %food__sb__Snake* %t1
  store %food__sb__Snake %t7, %food__sb__Snake* %t0
  %t9 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t8, i32 0, i32 0
  store i32 5, i32* %t9
  %t10 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t8, i32 0, i32 1
  store i32 12, i32* %t10
  %t11 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t8
  %t12 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t0, i32 0, i32 0
  %t13 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t12, i32 0, i32 0
  %t14 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t12, i32 0, i32 1
  %t15 = load i64, i64* %t14
  %t16 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t12, i32 0, i32 2
  %t17 = load i64, i64* %t16
  %t18 = icmp sge i64 %t17, 768
  br i1 %t18, label %ring_push_full_40, label %ring_push_grow_41
ring_push_grow_41:
  %t19 = add i64 %t15, %t17
  %t20 = urem i64 %t19, 768
  %t21 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t13, i32 0, i64 %t20
  store %food__sb__grid__Cell %t11, %food__sb__grid__Cell* %t21
  %t22 = add i64 %t17, 1
  store i64 %t22, i64* %t16
  br label %ring_push_done_42
ring_push_full_40:
  %t23 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t13, i32 0, i64 %t15
  store %food__sb__grid__Cell %t11, %food__sb__grid__Cell* %t23
  %t24 = add i64 %t15, 1
  %t25 = urem i64 %t24, 768
  store i64 %t25, i64* %t14
  br label %ring_push_done_42
ring_push_done_42:
  %t27 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t26, i32 0, i32 0
  store i32 6, i32* %t27
  %t28 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t26, i32 0, i32 1
  store i32 12, i32* %t28
  %t29 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t26
  %t30 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t0, i32 0, i32 0
  %t31 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t30, i32 0, i32 0
  %t32 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t30, i32 0, i32 1
  %t33 = load i64, i64* %t32
  %t34 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t30, i32 0, i32 2
  %t35 = load i64, i64* %t34
  %t36 = icmp sge i64 %t35, 768
  br i1 %t36, label %ring_push_full_43, label %ring_push_grow_44
ring_push_grow_44:
  %t37 = add i64 %t33, %t35
  %t38 = urem i64 %t37, 768
  %t39 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t31, i32 0, i64 %t38
  store %food__sb__grid__Cell %t29, %food__sb__grid__Cell* %t39
  %t40 = add i64 %t35, 1
  store i64 %t40, i64* %t34
  br label %ring_push_done_45
ring_push_full_43:
  %t41 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t31, i32 0, i64 %t33
  store %food__sb__grid__Cell %t29, %food__sb__grid__Cell* %t41
  %t42 = add i64 %t33, 1
  %t43 = urem i64 %t42, 768
  store i64 %t43, i64* %t32
  br label %ring_push_done_45
ring_push_done_45:
  %t45 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t44, i32 0, i32 0
  store i32 7, i32* %t45
  %t46 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t44, i32 0, i32 1
  store i32 12, i32* %t46
  %t47 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t44
  %t48 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t0, i32 0, i32 0
  %t49 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t48, i32 0, i32 0
  %t50 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t48, i32 0, i32 1
  %t51 = load i64, i64* %t50
  %t52 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t48, i32 0, i32 2
  %t53 = load i64, i64* %t52
  %t54 = icmp sge i64 %t53, 768
  br i1 %t54, label %ring_push_full_46, label %ring_push_grow_47
ring_push_grow_47:
  %t55 = add i64 %t51, %t53
  %t56 = urem i64 %t55, 768
  %t57 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t49, i32 0, i64 %t56
  store %food__sb__grid__Cell %t47, %food__sb__grid__Cell* %t57
  %t58 = add i64 %t53, 1
  store i64 %t58, i64* %t52
  br label %ring_push_done_48
ring_push_full_46:
  %t59 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t49, i32 0, i64 %t51
  store %food__sb__grid__Cell %t47, %food__sb__grid__Cell* %t59
  %t60 = add i64 %t51, 1
  %t61 = urem i64 %t60, 768
  store i64 %t61, i64* %t50
  br label %ring_push_done_48
ring_push_done_48:
  %t62 = load %food__sb__Snake, %food__sb__Snake* %t0
  ret %food__sb__Snake %t62
}

define i8* @food__occupied_cells({ [768 x %food__sb__grid__Cell], i64, i64 } %body, i32 %len) {
entry:
  %t0 = alloca { [768 x %food__sb__grid__Cell], i64, i64 }
  %t1 = alloca i32
  %t2 = alloca i8*
  %t3 = alloca i32
  %t64 = alloca %food__sb__grid__Cell
  %t69 = alloca i64
  %t70 = alloca i1
  store { [768 x %food__sb__grid__Cell], i64, i64 } %body, { [768 x %food__sb__grid__Cell], i64, i64 }* %t0
  store i32 %len, i32* %t1
  store i8* null, i8** %t2
  store i32 0, i32* %t3
  br label %while_cond_49
while_cond_49:
  %t4 = load i32, i32* %t3
  %t5 = load i32, i32* %t1
  %t6 = icmp slt i32 %t4, %t5
  br i1 %t6, label %while_body_50, label %while_else_51
while_body_50:
  %t7 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t8 = ptrtoint %food__sb__grid__Cell* %t7 to i64
  %t9 = load i8*, i8** %t2
  %t10 = icmp eq i8* %t9, null
  br i1 %t10, label %set_cow_alloc_53, label %set_cow_check_54
set_cow_alloc_53:
  %t15 = bitcast void (i8*)* @set_release_s_food__sb__grid__Cell to i8*
  %t16 = call i8* @star_rc_alloc(i64 24, i8* %t15)
  %t17 = bitcast i8* %t16 to { %food__sb__grid__Cell*, i64, i64 }*
  %t18 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t17, i32 0, i32 0
  store %food__sb__grid__Cell* null, %food__sb__grid__Cell** %t18
  %t19 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t17, i32 0, i32 1
  store i64 0, i64* %t19
  %t20 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t17, i32 0, i32 2
  store i64 0, i64* %t20
  store i8* %t16, i8** %t2
  br label %set_cow_done_55
set_cow_check_54:
  %t21 = getelementptr inbounds i8, i8* %t9, i64 -16
  %t22 = bitcast i8* %t21 to i64*
  %t23 = load atomic i64, i64* %t22 seq_cst, align 8
  %t24 = icmp eq i64 %t23, 1
  br i1 %t24, label %set_cow_done_55, label %set_cow_clone_56
set_cow_clone_56:
  %t25 = bitcast i8* %t9 to { %food__sb__grid__Cell*, i64, i64 }*
  %t26 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t25, i32 0, i32 0
  %t27 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t26
  %t28 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t25, i32 0, i32 1
  %t29 = load i64, i64* %t28
  %t30 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t25, i32 0, i32 2
  %t31 = load i64, i64* %t30
  %t32 = bitcast void (i8*)* @set_release_s_food__sb__grid__Cell to i8*
  %t33 = call i8* @star_rc_alloc(i64 24, i8* %t32)
  %t34 = bitcast i8* %t33 to { %food__sb__grid__Cell*, i64, i64 }*
  %t35 = mul i64 %t31, %t8
  %t36 = call i8* @malloc(i64 %t35)
  %t37 = bitcast i8* %t36 to %food__sb__grid__Cell*
  %t38 = icmp sgt i64 %t29, 0
  br i1 %t38, label %set_cow_copy_57, label %set_cow_after_copy_58
set_cow_copy_57:
  %t39 = mul i64 %t29, %t8
  %t40 = bitcast %food__sb__grid__Cell* %t27 to i8*
  call i8* @memcpy(i8* %t36, i8* %t40, i64 %t39)
  br label %set_cow_after_copy_58
set_cow_after_copy_58:
  %t41 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t34, i32 0, i32 0
  store %food__sb__grid__Cell* %t37, %food__sb__grid__Cell** %t41
  %t42 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t34, i32 0, i32 1
  store i64 %t29, i64* %t42
  %t43 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t34, i32 0, i32 2
  store i64 %t31, i64* %t43
  call void @star_rc_release(i8* %t9)
  store i8* %t33, i8** %t2
  br label %set_cow_done_55
set_cow_done_55:
  %t44 = load i8*, i8** %t2
  %t45 = bitcast i8* %t44 to { %food__sb__grid__Cell*, i64, i64 }*
  %t46 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t45, i32 0, i32 0
  %t47 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t46
  %t48 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t45, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t45, i32 0, i32 2
  %t51 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t0, i32 0, i32 0
  %t52 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t0, i32 0, i32 1
  %t53 = load i64, i64* %t52
  %t54 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t0, i32 0, i32 2
  %t55 = load i64, i64* %t54
  %t56 = load i32, i32* %t3
  %t57 = sext i32 %t56 to i64
  %t58 = load i64, i64* %t52
  %t59 = load i64, i64* %t54
  %t60 = icmp ult i64 %t57, %t59
  br i1 %t60, label %ring_rplace_ok_59, label %ring_rplace_oob_60
ring_rplace_ok_59:
  %t61 = add i64 %t58, %t57
  %t62 = urem i64 %t61, 768
  %t63 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t51, i32 0, i64 %t62
  br label %ring_rplace_end_61
ring_rplace_oob_60:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t64
  br label %ring_rplace_end_61
ring_rplace_end_61:
  %t65 = phi %food__sb__grid__Cell* [ %t63, %ring_rplace_ok_59 ], [ %t64, %ring_rplace_oob_60 ]
  %t66 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t65
  %t67 = load i64, i64* %t48
  %t68 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t46
  store i64 0, i64* %t69
  store i1 false, i1* %t70
  br label %find_cond_62
find_cond_62:
  %t71 = load i64, i64* %t69
  %t72 = icmp slt i64 %t71, %t67
  br i1 %t72, label %find_body_63, label %find_end_66
find_body_63:
  %t73 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t68, i64 %t71
  %t74 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t73
  br label %find_eq_check_64
find_eq_check_64:
  %t75 = call i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %t74, %food__sb__grid__Cell %t66)
  br i1 %t75, label %find_end_66, label %find_next_65
find_next_65:
  %t76 = add i64 %t71, 1
  store i64 %t76, i64* %t69
  br label %find_cond_62
find_end_66:
  %t77 = load i64, i64* %t69
  %t78 = icmp slt i64 %t77, %t67
  br i1 %t78, label %set_insert_already_present_67, label %set_insert_do_68
set_insert_already_present_67:
  br label %set_insert_end_69
set_insert_do_68:
  %t79 = load i64, i64* %t50
  %t80 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t46
  %t81 = icmp sge i64 %t67, %t79
  br i1 %t81, label %set_insert_grow_70, label %set_insert_store_71
set_insert_grow_70:
  %t82 = mul i64 %t79, 2
  %t83 = icmp sgt i64 %t82, 0
  %t84 = select i1 %t83, i64 %t82, i64 1
  %t85 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t86 = ptrtoint %food__sb__grid__Cell* %t85 to i64
  %t87 = mul i64 %t84, %t86
  %t88 = call i8* @malloc(i64 %t87)
  %t89 = bitcast i8* %t88 to %food__sb__grid__Cell*
  %t90 = icmp sgt i64 %t79, 0
  br i1 %t90, label %set_insert_copy_72, label %set_insert_after_copy_73
set_insert_copy_72:
  %t91 = mul i64 %t67, %t86
  %t92 = bitcast %food__sb__grid__Cell* %t80 to i8*
  call i8* @memcpy(i8* %t88, i8* %t92, i64 %t91)
  call void @free(i8* %t92)
  br label %set_insert_after_copy_73
set_insert_after_copy_73:
  store %food__sb__grid__Cell* %t89, %food__sb__grid__Cell** %t46
  store i64 %t84, i64* %t50
  br label %set_insert_store_71
set_insert_store_71:
  %t93 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t46
  %t94 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t93, i64 %t67
  store %food__sb__grid__Cell %t66, %food__sb__grid__Cell* %t94
  %t95 = add i64 %t67, 1
  store i64 %t95, i64* %t48
  br label %set_insert_end_69
set_insert_end_69:
  %t96 = phi i1 [ false, %set_insert_already_present_67 ], [ true, %set_insert_store_71 ]
  %t97 = load i32, i32* %t3
  %t98 = add i32 %t97, 1
  store i32 %t98, i32* %t3
  br label %while_cond_49
while_else_51:
  br label %while_end_52
while_end_52:
  %t99 = load i8*, i8** %t2
  %t100 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t100)
  %t101 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t101)
  ret i8* %t99
}

define %food__sb__grid__Cell @food__spawn_food({ [768 x %food__sb__grid__Cell], i64, i64 } %body, i32 %len) {
entry:
  %t0 = alloca { [768 x %food__sb__grid__Cell], i64, i64 }
  %t1 = alloca i32
  %t2 = alloca i8*
  %t6 = alloca i8*
  %t7 = alloca i32
  %t10 = alloca i32
  %t13 = alloca %food__sb__grid__Cell
  %t28 = alloca i64
  %t29 = alloca i1
  %t83 = alloca %food__sb__grid__Cell
  %t122 = alloca %food__sb__grid__Cell
  %t130 = alloca i32
  store { [768 x %food__sb__grid__Cell], i64, i64 } %body, { [768 x %food__sb__grid__Cell], i64, i64 }* %t0
  store i32 %len, i32* %t1
  %t3 = load { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t0
  %t4 = load i32, i32* %t1
  %t5 = call i8* @food__occupied_cells({ [768 x %food__sb__grid__Cell], i64, i64 } %t3, i32 %t4)
  store i8* %t5, i8** %t2
  store i8* null, i8** %t6
  store i32 0, i32* %t7
  br label %while_cond_74
while_cond_74:
  %t8 = load i32, i32* %t7
  %t9 = icmp slt i32 %t8, 24
  br i1 %t9, label %while_body_75, label %while_else_76
while_body_75:
  store i32 0, i32* %t10
  br label %while_cond_78
while_cond_78:
  %t11 = load i32, i32* %t10
  %t12 = icmp slt i32 %t11, 32
  br i1 %t12, label %while_body_79, label %while_else_80
while_body_79:
  %t14 = load i32, i32* %t10
  %t15 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t13, i32 0, i32 0
  store i32 %t14, i32* %t15
  %t16 = load i32, i32* %t7
  %t17 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t13, i32 0, i32 1
  store i32 %t16, i32* %t17
  %t18 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t13
  %t19 = load i8*, i8** %t2
  %t20 = icmp eq i8* %t19, null
  br i1 %t20, label %set_read_null_82, label %set_read_real_83
set_read_null_82:
  br label %set_read_end_84
set_read_real_83:
  %t21 = bitcast i8* %t19 to { %food__sb__grid__Cell*, i64, i64 }*
  %t22 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t21, i32 0, i32 0
  %t23 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t22
  %t24 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t21, i32 0, i32 1
  %t25 = load i64, i64* %t24
  br label %set_read_end_84
set_read_end_84:
  %t26 = phi %food__sb__grid__Cell* [ null, %set_read_null_82 ], [ %t23, %set_read_real_83 ]
  %t27 = phi i64 [ 0, %set_read_null_82 ], [ %t25, %set_read_real_83 ]
  store i64 0, i64* %t28
  store i1 false, i1* %t29
  br label %find_cond_85
find_cond_85:
  %t30 = load i64, i64* %t28
  %t31 = icmp slt i64 %t30, %t27
  br i1 %t31, label %find_body_86, label %find_end_89
find_body_86:
  %t32 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t26, i64 %t30
  %t33 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t32
  br label %find_eq_check_87
find_eq_check_87:
  %t34 = call i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %t33, %food__sb__grid__Cell %t18)
  br i1 %t34, label %find_end_89, label %find_next_88
find_next_88:
  %t35 = add i64 %t30, 1
  store i64 %t35, i64* %t28
  br label %find_cond_85
find_end_89:
  %t36 = load i64, i64* %t28
  %t37 = icmp slt i64 %t36, %t27
  %t38 = xor i1 true, %t37
  br i1 %t38, label %if_then_90, label %if_else_91
if_then_90:
  %t39 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t40 = ptrtoint %food__sb__grid__Cell* %t39 to i64
  %t41 = load i8*, i8** %t6
  %t42 = icmp eq i8* %t41, null
  br i1 %t42, label %list_cow_alloc_93, label %list_cow_check_94
list_cow_alloc_93:
  %t47 = bitcast void (i8*)* @list_release_s_food__sb__grid__Cell to i8*
  %t48 = call i8* @star_rc_alloc(i64 24, i8* %t47)
  %t49 = bitcast i8* %t48 to { %food__sb__grid__Cell*, i64, i64 }*
  %t50 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t49, i32 0, i32 0
  store %food__sb__grid__Cell* null, %food__sb__grid__Cell** %t50
  %t51 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t49, i32 0, i32 1
  store i64 0, i64* %t51
  %t52 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t49, i32 0, i32 2
  store i64 0, i64* %t52
  store i8* %t48, i8** %t6
  br label %list_cow_done_95
list_cow_check_94:
  %t53 = getelementptr inbounds i8, i8* %t41, i64 -16
  %t54 = bitcast i8* %t53 to i64*
  %t55 = load atomic i64, i64* %t54 seq_cst, align 8
  %t56 = icmp eq i64 %t55, 1
  br i1 %t56, label %list_cow_done_95, label %list_cow_clone_96
list_cow_clone_96:
  %t57 = bitcast i8* %t41 to { %food__sb__grid__Cell*, i64, i64 }*
  %t58 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t57, i32 0, i32 0
  %t59 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t58
  %t60 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t57, i32 0, i32 1
  %t61 = load i64, i64* %t60
  %t62 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t57, i32 0, i32 2
  %t63 = load i64, i64* %t62
  %t64 = bitcast void (i8*)* @list_release_s_food__sb__grid__Cell to i8*
  %t65 = call i8* @star_rc_alloc(i64 24, i8* %t64)
  %t66 = bitcast i8* %t65 to { %food__sb__grid__Cell*, i64, i64 }*
  %t67 = mul i64 %t63, %t40
  %t68 = call i8* @malloc(i64 %t67)
  %t69 = bitcast i8* %t68 to %food__sb__grid__Cell*
  %t70 = icmp sgt i64 %t61, 0
  br i1 %t70, label %list_cow_copy_97, label %list_cow_after_copy_98
list_cow_copy_97:
  %t71 = mul i64 %t61, %t40
  %t72 = bitcast %food__sb__grid__Cell* %t59 to i8*
  call i8* @memcpy(i8* %t68, i8* %t72, i64 %t71)
  br label %list_cow_after_copy_98
list_cow_after_copy_98:
  %t73 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t66, i32 0, i32 0
  store %food__sb__grid__Cell* %t69, %food__sb__grid__Cell** %t73
  %t74 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t66, i32 0, i32 1
  store i64 %t61, i64* %t74
  %t75 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t66, i32 0, i32 2
  store i64 %t63, i64* %t75
  call void @star_rc_release(i8* %t41)
  store i8* %t65, i8** %t6
  br label %list_cow_done_95
list_cow_done_95:
  %t76 = load i8*, i8** %t6
  %t77 = bitcast i8* %t76 to { %food__sb__grid__Cell*, i64, i64 }*
  %t78 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t77, i32 0, i32 0
  %t79 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t78
  %t80 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t77, i32 0, i32 1
  %t81 = load i64, i64* %t80
  %t82 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t77, i32 0, i32 2
  %t84 = load i32, i32* %t10
  %t85 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t83, i32 0, i32 0
  store i32 %t84, i32* %t85
  %t86 = load i32, i32* %t7
  %t87 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t83, i32 0, i32 1
  store i32 %t86, i32* %t87
  %t88 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t83
  %t89 = load i64, i64* %t82
  %t90 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t78
  %t91 = load i64, i64* %t80
  %t92 = icmp sge i64 %t91, %t89
  br i1 %t92, label %list_push_grow_99, label %list_push_store_100
list_push_grow_99:
  %t93 = mul i64 %t89, 2
  %t94 = icmp sgt i64 %t93, 0
  %t95 = select i1 %t94, i64 %t93, i64 1
  %t96 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t97 = ptrtoint %food__sb__grid__Cell* %t96 to i64
  %t98 = mul i64 %t95, %t97
  %t99 = call i8* @malloc(i64 %t98)
  %t100 = bitcast i8* %t99 to %food__sb__grid__Cell*
  %t101 = icmp sgt i64 %t89, 0
  br i1 %t101, label %list_push_copy_101, label %list_push_after_copy_102
list_push_copy_101:
  %t102 = mul i64 %t91, %t97
  %t103 = bitcast %food__sb__grid__Cell* %t90 to i8*
  call i8* @memcpy(i8* %t99, i8* %t103, i64 %t102)
  call void @free(i8* %t103)
  br label %list_push_after_copy_102
list_push_after_copy_102:
  store %food__sb__grid__Cell* %t100, %food__sb__grid__Cell** %t78
  store i64 %t95, i64* %t82
  br label %list_push_store_100
list_push_store_100:
  %t104 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t78
  %t105 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t104, i64 %t91
  store %food__sb__grid__Cell %t88, %food__sb__grid__Cell* %t105
  %t106 = add i64 %t91, 1
  store i64 %t106, i64* %t80
  br label %if_end_92
if_else_91:
  br label %if_end_92
if_end_92:
  %t107 = load i32, i32* %t10
  %t108 = add i32 %t107, 1
  store i32 %t108, i32* %t10
  br label %while_cond_78
while_else_80:
  br label %while_end_81
while_end_81:
  %t109 = load i32, i32* %t7
  %t110 = add i32 %t109, 1
  store i32 %t110, i32* %t7
  br label %while_cond_74
while_else_76:
  br label %while_end_77
while_end_77:
  %t111 = load i8*, i8** %t6
  %t112 = icmp eq i8* %t111, null
  br i1 %t112, label %list_read_null_103, label %list_read_real_104
list_read_null_103:
  br label %list_read_end_105
list_read_real_104:
  %t113 = bitcast i8* %t111 to { %food__sb__grid__Cell*, i64, i64 }*
  %t114 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t113, i32 0, i32 0
  %t115 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t114
  %t116 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t113, i32 0, i32 1
  %t117 = load i64, i64* %t116
  br label %list_read_end_105
list_read_end_105:
  %t118 = phi %food__sb__grid__Cell* [ null, %list_read_null_103 ], [ %t115, %list_read_real_104 ]
  %t119 = phi i64 [ 0, %list_read_null_103 ], [ %t117, %list_read_real_104 ]
  %t120 = trunc i64 %t119 to i32
  %t121 = icmp eq i32 %t120, 0
  br i1 %t121, label %if_then_106, label %if_else_107
if_then_106:
  %t123 = sub i32 0, 1
  %t124 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t122, i32 0, i32 0
  store i32 %t123, i32* %t124
  %t125 = sub i32 0, 1
  %t126 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t122, i32 0, i32 1
  store i32 %t125, i32* %t126
  %t127 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t122
  %t128 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t128)
  %t129 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t129)
  ret %food__sb__grid__Cell %t127
if_else_107:
  br label %if_end_108
if_end_108:
  %t131 = load i8*, i8** %t6
  %t132 = icmp eq i8* %t131, null
  br i1 %t132, label %list_read_null_109, label %list_read_real_110
list_read_null_109:
  br label %list_read_end_111
list_read_real_110:
  %t133 = bitcast i8* %t131 to { %food__sb__grid__Cell*, i64, i64 }*
  %t134 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t133, i32 0, i32 0
  %t135 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t134
  %t136 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t133, i32 0, i32 1
  %t137 = load i64, i64* %t136
  br label %list_read_end_111
list_read_end_111:
  %t138 = phi %food__sb__grid__Cell* [ null, %list_read_null_109 ], [ %t135, %list_read_real_110 ]
  %t139 = phi i64 [ 0, %list_read_null_109 ], [ %t137, %list_read_real_110 ]
  %t140 = trunc i64 %t139 to i32
  %t141 = sub i32 %t140, 0
  %t142 = icmp sle i32 %t141, 0
  %t143 = select i1 %t142, i32 1, i32 %t141
  %t144 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t144, i32 -1)
  %t145 = load i32, i32* @rng.state
  %t146 = shl i32 %t145, 13
  %t147 = xor i32 %t145, %t146
  %t148 = lshr i32 %t147, 17
  %t149 = xor i32 %t147, %t148
  %t150 = shl i32 %t149, 5
  %t151 = xor i32 %t149, %t150
  store i32 %t151, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t144, i32 1, i32* null)
  %t152 = and i32 %t151, 2147483647
  %t153 = urem i32 %t152, %t143
  %t154 = add i32 0, %t153
  store i32 %t154, i32* %t130
  %t155 = load i8*, i8** %t6
  %t156 = icmp eq i8* %t155, null
  br i1 %t156, label %list_read_null_112, label %list_read_real_113
list_read_null_112:
  br label %list_read_end_114
list_read_real_113:
  %t157 = bitcast i8* %t155 to { %food__sb__grid__Cell*, i64, i64 }*
  %t158 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t157, i32 0, i32 0
  %t159 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t158
  %t160 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t157, i32 0, i32 1
  %t161 = load i64, i64* %t160
  br label %list_read_end_114
list_read_end_114:
  %t162 = phi %food__sb__grid__Cell* [ null, %list_read_null_112 ], [ %t159, %list_read_real_113 ]
  %t163 = phi i64 [ 0, %list_read_null_112 ], [ %t161, %list_read_real_113 ]
  %t164 = load i32, i32* %t130
  %t165 = sext i32 %t164 to i64
  %t166 = icmp ult i64 %t165, %t163
  br i1 %t166, label %list_idx_ok_115, label %list_idx_oob_116
list_idx_ok_115:
  %t167 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t162, i64 %t165
  %t168 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t167
  br label %list_idx_end_117
list_idx_oob_116:
  br label %list_idx_end_117
list_idx_end_117:
  %t169 = phi %food__sb__grid__Cell [ %t168, %list_idx_ok_115 ], [ zeroinitializer, %list_idx_oob_116 ]
  %t170 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t170)
  %t171 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t171)
  ret %food__sb__grid__Cell %t169
}

define i8* @save__normalize_difficulty(i8* %raw) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t8 = alloca i64
  %t26 = alloca i64
  %t62 = alloca i8*
  %t63 = alloca i32
  %t76 = alloca i32
  store i8* %raw, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = icmp eq i8* %t2, null
  %t5 = select i1 %t4, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t2
  %t6 = call i32 @strlen(i8* %t5)
  %t7 = sext i32 %t6 to i64
  store i64 0, i64* %t8
  br label %trim_start_cond_118
trim_start_cond_118:
  %t9 = load i64, i64* %t8
  %t10 = icmp slt i64 %t9, %t7
  br i1 %t10, label %trim_start_body_119, label %trim_start_done_121
trim_start_body_119:
  %t11 = getelementptr inbounds i8, i8* %t5, i64 %t9
  %t12 = load i8, i8* %t11
  %t13 = icmp eq i8 %t12, 32
  %t14 = icmp eq i8 %t12, 9
  %t15 = or i1 %t13, %t14
  %t16 = icmp eq i8 %t12, 10
  %t17 = or i1 %t15, %t16
  %t18 = icmp eq i8 %t12, 13
  %t19 = or i1 %t17, %t18
  %t20 = icmp eq i8 %t12, 11
  %t21 = or i1 %t19, %t20
  %t22 = icmp eq i8 %t12, 12
  %t23 = or i1 %t21, %t22
  br i1 %t23, label %trim_start_incr_120, label %trim_start_done_121
trim_start_incr_120:
  %t24 = add i64 %t9, 1
  store i64 %t24, i64* %t8
  br label %trim_start_cond_118
trim_start_done_121:
  %t25 = load i64, i64* %t8
  store i64 %t7, i64* %t26
  br label %trim_end_cond_122
trim_end_cond_122:
  %t27 = load i64, i64* %t26
  %t28 = icmp sgt i64 %t27, %t25
  br i1 %t28, label %trim_end_body_123, label %trim_end_done_125
trim_end_body_123:
  %t29 = sub i64 %t27, 1
  %t30 = getelementptr inbounds i8, i8* %t5, i64 %t29
  %t31 = load i8, i8* %t30
  %t32 = icmp eq i8 %t31, 32
  %t33 = icmp eq i8 %t31, 9
  %t34 = or i1 %t32, %t33
  %t35 = icmp eq i8 %t31, 10
  %t36 = or i1 %t34, %t35
  %t37 = icmp eq i8 %t31, 13
  %t38 = or i1 %t36, %t37
  %t39 = icmp eq i8 %t31, 11
  %t40 = or i1 %t38, %t39
  %t41 = icmp eq i8 %t31, 12
  %t42 = or i1 %t40, %t41
  br i1 %t42, label %trim_end_decr_124, label %trim_end_done_125
trim_end_decr_124:
  store i64 %t29, i64* %t26
  br label %trim_end_cond_122
trim_end_done_125:
  %t43 = load i64, i64* %t26
  %t44 = sub i64 %t43, %t25
  %t45 = add i64 %t44, 1
  %t46 = call i8* @star_rc_alloc(i64 %t45, i8* null)
  %t47 = getelementptr inbounds i8, i8* %t5, i64 %t25
  call i8* @memcpy(i8* %t46, i8* %t47, i64 %t44)
  %t48 = getelementptr inbounds i8, i8* %t46, i64 %t44
  store i8 0, i8* %t48
  call void @star_rc_release(i8* %t2)
  %t49 = call i32 @strlen(i8* %t46)
  %t50 = sext i32 %t49 to i64
  %t51 = call i8* @malloc(i64 %t50)
  call i8* @memcpy(i8* %t51, i8* %t46, i64 %t50)
  call void @star_rc_release(i8* %t46)
  %t56 = bitcast void (i8*)* @list_release_u8 to i8*
  %t57 = call i8* @star_rc_alloc(i64 24, i8* %t56)
  %t58 = bitcast i8* %t57 to { i8*, i64, i64 }*
  %t59 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t58, i32 0, i32 0
  store i8* %t51, i8** %t59
  %t60 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t58, i32 0, i32 1
  store i64 %t50, i64* %t60
  %t61 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t58, i32 0, i32 2
  store i64 %t50, i64* %t61
  store i8* %t57, i8** %t1
  store i8* null, i8** %t62
  store i32 0, i32* %t63
  br label %while_cond_126
while_cond_126:
  %t64 = load i32, i32* %t63
  %t65 = load i8*, i8** %t1
  %t66 = icmp eq i8* %t65, null
  br i1 %t66, label %list_read_null_130, label %list_read_real_131
list_read_null_130:
  br label %list_read_end_132
list_read_real_131:
  %t67 = bitcast i8* %t65 to { i8*, i64, i64 }*
  %t68 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t67, i32 0, i32 0
  %t69 = load i8*, i8** %t68
  %t70 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t67, i32 0, i32 1
  %t71 = load i64, i64* %t70
  br label %list_read_end_132
list_read_end_132:
  %t72 = phi i8* [ null, %list_read_null_130 ], [ %t69, %list_read_real_131 ]
  %t73 = phi i64 [ 0, %list_read_null_130 ], [ %t71, %list_read_real_131 ]
  %t74 = trunc i64 %t73 to i32
  %t75 = icmp slt i32 %t64, %t74
  br i1 %t75, label %while_body_127, label %while_else_128
while_body_127:
  %t77 = load i8*, i8** %t1
  %t78 = icmp eq i8* %t77, null
  br i1 %t78, label %list_read_null_133, label %list_read_real_134
list_read_null_133:
  br label %list_read_end_135
list_read_real_134:
  %t79 = bitcast i8* %t77 to { i8*, i64, i64 }*
  %t80 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t79, i32 0, i32 0
  %t81 = load i8*, i8** %t80
  %t82 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t79, i32 0, i32 1
  %t83 = load i64, i64* %t82
  br label %list_read_end_135
list_read_end_135:
  %t84 = phi i8* [ null, %list_read_null_133 ], [ %t81, %list_read_real_134 ]
  %t85 = phi i64 [ 0, %list_read_null_133 ], [ %t83, %list_read_real_134 ]
  %t86 = load i32, i32* %t63
  %t87 = sext i32 %t86 to i64
  %t88 = icmp ult i64 %t87, %t85
  br i1 %t88, label %list_idx_ok_136, label %list_idx_oob_137
list_idx_ok_136:
  %t89 = getelementptr inbounds i8, i8* %t84, i64 %t87
  %t90 = load i8, i8* %t89
  br label %list_idx_end_138
list_idx_oob_137:
  br label %list_idx_end_138
list_idx_end_138:
  %t91 = phi i8 [ %t90, %list_idx_ok_136 ], [ 0, %list_idx_oob_137 ]
  %t92 = zext i8 %t91 to i32
  %t93 = call i32 @toupper(i32 %t92)
  store i32 %t93, i32* %t76
  %t94 = getelementptr i8, i8* null, i32 1
  %t95 = ptrtoint i8* %t94 to i64
  %t96 = load i8*, i8** %t62
  %t97 = icmp eq i8* %t96, null
  br i1 %t97, label %list_cow_alloc_139, label %list_cow_check_140
list_cow_alloc_139:
  %t98 = bitcast void (i8*)* @list_release_u8 to i8*
  %t99 = call i8* @star_rc_alloc(i64 24, i8* %t98)
  %t100 = bitcast i8* %t99 to { i8*, i64, i64 }*
  %t101 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t100, i32 0, i32 0
  store i8* null, i8** %t101
  %t102 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t100, i32 0, i32 1
  store i64 0, i64* %t102
  %t103 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t100, i32 0, i32 2
  store i64 0, i64* %t103
  store i8* %t99, i8** %t62
  br label %list_cow_done_141
list_cow_check_140:
  %t104 = getelementptr inbounds i8, i8* %t96, i64 -16
  %t105 = bitcast i8* %t104 to i64*
  %t106 = load atomic i64, i64* %t105 seq_cst, align 8
  %t107 = icmp eq i64 %t106, 1
  br i1 %t107, label %list_cow_done_141, label %list_cow_clone_142
list_cow_clone_142:
  %t108 = bitcast i8* %t96 to { i8*, i64, i64 }*
  %t109 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t108, i32 0, i32 0
  %t110 = load i8*, i8** %t109
  %t111 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t108, i32 0, i32 1
  %t112 = load i64, i64* %t111
  %t113 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t108, i32 0, i32 2
  %t114 = load i64, i64* %t113
  %t115 = bitcast void (i8*)* @list_release_u8 to i8*
  %t116 = call i8* @star_rc_alloc(i64 24, i8* %t115)
  %t117 = bitcast i8* %t116 to { i8*, i64, i64 }*
  %t118 = mul i64 %t114, %t95
  %t119 = call i8* @malloc(i64 %t118)
  %t120 = bitcast i8* %t119 to i8*
  %t121 = icmp sgt i64 %t112, 0
  br i1 %t121, label %list_cow_copy_143, label %list_cow_after_copy_144
list_cow_copy_143:
  %t122 = mul i64 %t112, %t95
  %t123 = bitcast i8* %t110 to i8*
  call i8* @memcpy(i8* %t119, i8* %t123, i64 %t122)
  br label %list_cow_after_copy_144
list_cow_after_copy_144:
  %t124 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t117, i32 0, i32 0
  store i8* %t120, i8** %t124
  %t125 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t117, i32 0, i32 1
  store i64 %t112, i64* %t125
  %t126 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t117, i32 0, i32 2
  store i64 %t114, i64* %t126
  call void @star_rc_release(i8* %t96)
  store i8* %t116, i8** %t62
  br label %list_cow_done_141
list_cow_done_141:
  %t127 = load i8*, i8** %t62
  %t128 = bitcast i8* %t127 to { i8*, i64, i64 }*
  %t129 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t128, i32 0, i32 0
  %t130 = load i8*, i8** %t129
  %t131 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t128, i32 0, i32 1
  %t132 = load i64, i64* %t131
  %t133 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t128, i32 0, i32 2
  %t134 = load i32, i32* %t76
  %t135 = trunc i32 %t134 to i8
  %t136 = load i64, i64* %t133
  %t137 = load i8*, i8** %t129
  %t138 = load i64, i64* %t131
  %t139 = icmp sge i64 %t138, %t136
  br i1 %t139, label %list_push_grow_145, label %list_push_store_146
list_push_grow_145:
  %t140 = mul i64 %t136, 2
  %t141 = icmp sgt i64 %t140, 0
  %t142 = select i1 %t141, i64 %t140, i64 1
  %t143 = getelementptr i8, i8* null, i32 1
  %t144 = ptrtoint i8* %t143 to i64
  %t145 = mul i64 %t142, %t144
  %t146 = call i8* @malloc(i64 %t145)
  %t147 = bitcast i8* %t146 to i8*
  %t148 = icmp sgt i64 %t136, 0
  br i1 %t148, label %list_push_copy_147, label %list_push_after_copy_148
list_push_copy_147:
  %t149 = mul i64 %t138, %t144
  %t150 = bitcast i8* %t137 to i8*
  call i8* @memcpy(i8* %t146, i8* %t150, i64 %t149)
  call void @free(i8* %t150)
  br label %list_push_after_copy_148
list_push_after_copy_148:
  store i8* %t147, i8** %t129
  store i64 %t142, i64* %t133
  br label %list_push_store_146
list_push_store_146:
  %t151 = load i8*, i8** %t129
  %t152 = getelementptr inbounds i8, i8* %t151, i64 %t138
  store i8 %t135, i8* %t152
  %t153 = add i64 %t138, 1
  store i64 %t153, i64* %t131
  %t154 = load i32, i32* %t63
  %t155 = add i32 %t154, 1
  store i32 %t155, i32* %t63
  br label %while_cond_126
while_else_128:
  br label %while_end_129
while_end_129:
  %t156 = load i8*, i8** %t62
  %t157 = icmp eq i8* %t156, null
  br i1 %t157, label %list_read_null_149, label %list_read_real_150
list_read_null_149:
  br label %list_read_end_151
list_read_real_150:
  %t158 = bitcast i8* %t156 to { i8*, i64, i64 }*
  %t159 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t158, i32 0, i32 0
  %t160 = load i8*, i8** %t159
  %t161 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t158, i32 0, i32 1
  %t162 = load i64, i64* %t161
  br label %list_read_end_151
list_read_end_151:
  %t163 = phi i8* [ null, %list_read_null_149 ], [ %t160, %list_read_real_150 ]
  %t164 = phi i64 [ 0, %list_read_null_149 ], [ %t162, %list_read_real_150 ]
  %t165 = add i64 %t164, 1
  %t166 = call i8* @star_rc_alloc(i64 %t165, i8* null)
  call i8* @memcpy(i8* %t166, i8* %t163, i64 %t164)
  %t167 = getelementptr inbounds i8, i8* %t166, i64 %t164
  store i8 0, i8* %t167
  %t168 = load i8*, i8** %t62
  call void @star_rc_release(i8* %t168)
  %t169 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t169)
  %t170 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t170)
  ret i8* %t166
}

define i1 @save__save_high_score(i8* %path, i32 %score, i8* %difficulty) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t2 = alloca i8*
  %t3 = alloca i8*
  store i8* %path, i8** %t0
  store i32 %score, i32* %t1
  store i8* %difficulty, i8** %t2
  %t4 = load i8*, i8** %t0
  %t5 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t5)
  %t6 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t7 = call i8* @fopen(i8* %t4, i8* %t6)
  call void @star_rc_release(i8* %t4)
  call void @star_rc_release(i8* %t6)
  store i8* %t7, i8** %t3
  %t8 = load i8*, i8** %t3
  %t9 = icmp eq i8* %t8, null
  br i1 %t9, label %if_then_152, label %if_else_153
if_then_152:
  %t10 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t10)
  %t11 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t11)
  ret i1 false
if_else_153:
  br label %if_end_154
if_end_154:
  %t12 = load i8*, i8** %t3
  %t13 = icmp eq i8* %t12, null
  br i1 %t13, label %file_null_handle_155, label %file_handle_ok_156
file_null_handle_155:
  %t14 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t14)
  call void @exit(i32 1)
  unreachable
file_handle_ok_156:
  %t15 = load i32, i32* %t1
  %t16 = load i8*, i8** %t2
  %t17 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t17)
  call void @star_rc_release(i8* %t16)
  %t18 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.6, i64 0, i64 0
  %t19 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t18, i32 %t15, i8* %t16)
  %t20 = add i32 %t19, 1
  %t21 = sext i32 %t20 to i64
  %t22 = call i8* @star_rc_alloc(i64 %t21, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t22, i64 %t21, i8* %t18, i32 %t15, i8* %t16)
  %t23 = call i32 @strlen(i8* %t22)
  %t24 = sext i32 %t23 to i64
  %t25 = call i64 @fwrite(i8* %t22, i64 1, i64 %t24, i8* %t12)
  call void @star_rc_release(i8* %t22)
  %t26 = icmp eq i64 %t25, %t24
  %t27 = load i8*, i8** %t3
  %t28 = icmp eq i8* %t27, null
  br i1 %t28, label %file_null_handle_157, label %file_handle_ok_158
file_null_handle_157:
  %t29 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t29)
  call void @exit(i32 1)
  unreachable
file_handle_ok_158:
  call i32 @fclose(i8* %t27)
  store i8* null, i8** %t3
  %t30 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t30)
  %t31 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t31)
  ret i1 true
}

define { i32, i8* } @save__load_high_score(i8* %path) {
entry:
  %t0 = alloca i8*
  %t7 = alloca { i32, i8* }
  %t13 = alloca i8*
  %t20 = alloca { i32, i8* }
  %t26 = alloca i8*
  %t31 = alloca i64
  %t46 = alloca i8*
  %t53 = alloca i64
  %t71 = alloca i64
  %t101 = alloca i8**
  %t102 = alloca i64
  %t103 = alloca i64
  %t125 = alloca i8*
  %t205 = alloca { i32, i8* }
  %t213 = alloca i32
  %t231 = alloca i8*
  %t249 = alloca { i32, i8* }
  store i8* %path, i8** %t0
  %t1 = load i8*, i8** %t0
  %t2 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t2)
  %t3 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  %t4 = call i8* @fopen(i8* %t1, i8* %t3)
  call void @star_rc_release(i8* %t1)
  %t5 = icmp ne i8* %t4, null
  br i1 %t5, label %file_exists_close_159, label %file_exists_end_160
file_exists_close_159:
  call i32 @fclose(i8* %t4)
  br label %file_exists_end_160
file_exists_end_160:
  %t6 = xor i1 true, %t5
  br i1 %t6, label %if_then_161, label %if_else_162
if_then_161:
  %t8 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t7, i32 0, i32 0
  store i32 0, i32* %t8
  %t9 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t10 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t7, i32 0, i32 1
  store i8* %t9, i8** %t10
  %t11 = load { i32, i8* }, { i32, i8* }* %t7
  %t12 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t12)
  ret { i32, i8* } %t11
if_else_162:
  br label %if_end_163
if_end_163:
  %t14 = load i8*, i8** %t0
  %t15 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t15)
  %t16 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t17 = call i8* @fopen(i8* %t14, i8* %t16)
  call void @star_rc_release(i8* %t14)
  call void @star_rc_release(i8* %t16)
  store i8* %t17, i8** %t13
  %t18 = load i8*, i8** %t13
  %t19 = icmp eq i8* %t18, null
  br i1 %t19, label %if_then_164, label %if_else_165
if_then_164:
  %t21 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t20, i32 0, i32 0
  store i32 0, i32* %t21
  %t22 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t23 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t20, i32 0, i32 1
  store i8* %t22, i8** %t23
  %t24 = load { i32, i8* }, { i32, i8* }* %t20
  %t25 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t25)
  ret { i32, i8* } %t24
if_else_165:
  br label %if_end_166
if_end_166:
  %t27 = load i8*, i8** %t13
  %t28 = icmp eq i8* %t27, null
  br i1 %t28, label %file_null_handle_167, label %file_handle_ok_168
file_null_handle_167:
  %t29 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.12, i64 0, i64 0
  call i32 @puts(i8* %t29)
  call void @exit(i32 1)
  unreachable
file_handle_ok_168:
  %t30 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t31
  br label %file_read_line_cond_169
file_read_line_cond_169:
  %t32 = load i64, i64* %t31
  %t33 = icmp ult i64 %t32, 1023
  br i1 %t33, label %file_read_line_body_170, label %file_read_line_end_172
file_read_line_body_170:
  %t34 = call i32 @fgetc(i8* %t27)
  %t35 = icmp eq i32 %t34, -1
  %t36 = icmp eq i32 %t34, 10
  %t37 = or i1 %t35, %t36
  br i1 %t37, label %file_read_line_end_172, label %file_read_line_store_171
file_read_line_store_171:
  %t38 = getelementptr inbounds i8, i8* %t30, i64 %t32
  %t39 = trunc i32 %t34 to i8
  store i8 %t39, i8* %t38
  %t40 = add i64 %t32, 1
  store i64 %t40, i64* %t31
  br label %file_read_line_cond_169
file_read_line_end_172:
  %t41 = load i64, i64* %t31
  %t42 = getelementptr inbounds i8, i8* %t30, i64 %t41
  store i8 0, i8* %t42
  store i8* %t30, i8** %t26
  %t43 = load i8*, i8** %t13
  %t44 = icmp eq i8* %t43, null
  br i1 %t44, label %file_null_handle_173, label %file_handle_ok_174
file_null_handle_173:
  %t45 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t45)
  call void @exit(i32 1)
  unreachable
file_handle_ok_174:
  call i32 @fclose(i8* %t43)
  store i8* null, i8** %t13
  %t47 = load i8*, i8** %t26
  %t48 = load i8*, i8** %t26
  call void @star_rc_retain(i8* %t48)
  %t49 = icmp eq i8* %t47, null
  %t50 = select i1 %t49, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t47
  %t51 = call i32 @strlen(i8* %t50)
  %t52 = sext i32 %t51 to i64
  store i64 0, i64* %t53
  br label %trim_start_cond_175
trim_start_cond_175:
  %t54 = load i64, i64* %t53
  %t55 = icmp slt i64 %t54, %t52
  br i1 %t55, label %trim_start_body_176, label %trim_start_done_178
trim_start_body_176:
  %t56 = getelementptr inbounds i8, i8* %t50, i64 %t54
  %t57 = load i8, i8* %t56
  %t58 = icmp eq i8 %t57, 32
  %t59 = icmp eq i8 %t57, 9
  %t60 = or i1 %t58, %t59
  %t61 = icmp eq i8 %t57, 10
  %t62 = or i1 %t60, %t61
  %t63 = icmp eq i8 %t57, 13
  %t64 = or i1 %t62, %t63
  %t65 = icmp eq i8 %t57, 11
  %t66 = or i1 %t64, %t65
  %t67 = icmp eq i8 %t57, 12
  %t68 = or i1 %t66, %t67
  br i1 %t68, label %trim_start_incr_177, label %trim_start_done_178
trim_start_incr_177:
  %t69 = add i64 %t54, 1
  store i64 %t69, i64* %t53
  br label %trim_start_cond_175
trim_start_done_178:
  %t70 = load i64, i64* %t53
  store i64 %t52, i64* %t71
  br label %trim_end_cond_179
trim_end_cond_179:
  %t72 = load i64, i64* %t71
  %t73 = icmp sgt i64 %t72, %t70
  br i1 %t73, label %trim_end_body_180, label %trim_end_done_182
trim_end_body_180:
  %t74 = sub i64 %t72, 1
  %t75 = getelementptr inbounds i8, i8* %t50, i64 %t74
  %t76 = load i8, i8* %t75
  %t77 = icmp eq i8 %t76, 32
  %t78 = icmp eq i8 %t76, 9
  %t79 = or i1 %t77, %t78
  %t80 = icmp eq i8 %t76, 10
  %t81 = or i1 %t79, %t80
  %t82 = icmp eq i8 %t76, 13
  %t83 = or i1 %t81, %t82
  %t84 = icmp eq i8 %t76, 11
  %t85 = or i1 %t83, %t84
  %t86 = icmp eq i8 %t76, 12
  %t87 = or i1 %t85, %t86
  br i1 %t87, label %trim_end_decr_181, label %trim_end_done_182
trim_end_decr_181:
  store i64 %t74, i64* %t71
  br label %trim_end_cond_179
trim_end_done_182:
  %t88 = load i64, i64* %t71
  %t89 = sub i64 %t88, %t70
  %t90 = add i64 %t89, 1
  %t91 = call i8* @star_rc_alloc(i64 %t90, i8* null)
  %t92 = getelementptr inbounds i8, i8* %t50, i64 %t70
  call i8* @memcpy(i8* %t91, i8* %t92, i64 %t89)
  %t93 = getelementptr inbounds i8, i8* %t91, i64 %t89
  store i8 0, i8* %t93
  call void @star_rc_release(i8* %t47)
  %t94 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t95 = icmp eq i8* %t91, null
  %t96 = select i1 %t95, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t91
  %t97 = icmp eq i8* %t94, null
  %t98 = select i1 %t97, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t94
  %t99 = call i32 @strlen(i8* %t98)
  %t100 = sext i32 %t99 to i64
  store i8** null, i8*** %t101
  store i64 0, i64* %t102
  store i64 0, i64* %t103
  %t104 = icmp eq i64 %t100, 0
  br i1 %t104, label %split_single_183, label %split_scan_init_184
split_single_183:
  %t105 = call i32 @strlen(i8* %t96)
  %t106 = sext i32 %t105 to i64
  %t107 = add i64 %t106, 1
  %t108 = call i8* @star_rc_alloc(i64 %t107, i8* null)
  call i8* @strcpy(i8* %t108, i8* %t96)
  %t109 = load i64, i64* %t102
  %t110 = load i64, i64* %t103
  %t111 = icmp sge i64 %t109, %t110
  br i1 %t111, label %dynstr_grow_186, label %dynstr_store_187
dynstr_grow_186:
  %t112 = mul i64 %t110, 2
  %t113 = icmp sgt i64 %t112, 0
  %t114 = select i1 %t113, i64 %t112, i64 4
  %t115 = mul i64 %t114, 8
  %t116 = call i8* @malloc(i64 %t115)
  %t117 = bitcast i8* %t116 to i8**
  %t118 = icmp sgt i64 %t110, 0
  br i1 %t118, label %dynstr_copy_188, label %dynstr_after_copy_189
dynstr_copy_188:
  %t119 = load i8**, i8*** %t101
  %t120 = mul i64 %t109, 8
  %t121 = bitcast i8** %t119 to i8*
  call i8* @memcpy(i8* %t116, i8* %t121, i64 %t120)
  call void @free(i8* %t121)
  br label %dynstr_after_copy_189
dynstr_after_copy_189:
  store i8** %t117, i8*** %t101
  store i64 %t114, i64* %t103
  br label %dynstr_store_187
dynstr_store_187:
  %t122 = load i8**, i8*** %t101
  %t123 = getelementptr inbounds i8*, i8** %t122, i64 %t109
  store i8* %t108, i8** %t123
  %t124 = add i64 %t109, 1
  store i64 %t124, i64* %t102
  br label %split_finish_185
split_scan_init_184:
  store i8* %t96, i8** %t125
  br label %split_scan_cond_190
split_scan_cond_190:
  %t126 = load i8*, i8** %t125
  %t127 = call i8* @strstr(i8* %t126, i8* %t98)
  %t128 = icmp eq i8* %t127, null
  br i1 %t128, label %split_tail_192, label %split_match_191
split_match_191:
  %t129 = ptrtoint i8* %t127 to i64
  %t130 = ptrtoint i8* %t126 to i64
  %t131 = sub i64 %t129, %t130
  %t132 = add i64 %t131, 1
  %t133 = call i8* @star_rc_alloc(i64 %t132, i8* null)
  call i8* @memcpy(i8* %t133, i8* %t126, i64 %t131)
  %t134 = getelementptr inbounds i8, i8* %t133, i64 %t131
  store i8 0, i8* %t134
  %t135 = load i64, i64* %t102
  %t136 = load i64, i64* %t103
  %t137 = icmp sge i64 %t135, %t136
  br i1 %t137, label %dynstr_grow_193, label %dynstr_store_194
dynstr_grow_193:
  %t138 = mul i64 %t136, 2
  %t139 = icmp sgt i64 %t138, 0
  %t140 = select i1 %t139, i64 %t138, i64 4
  %t141 = mul i64 %t140, 8
  %t142 = call i8* @malloc(i64 %t141)
  %t143 = bitcast i8* %t142 to i8**
  %t144 = icmp sgt i64 %t136, 0
  br i1 %t144, label %dynstr_copy_195, label %dynstr_after_copy_196
dynstr_copy_195:
  %t145 = load i8**, i8*** %t101
  %t146 = mul i64 %t135, 8
  %t147 = bitcast i8** %t145 to i8*
  call i8* @memcpy(i8* %t142, i8* %t147, i64 %t146)
  call void @free(i8* %t147)
  br label %dynstr_after_copy_196
dynstr_after_copy_196:
  store i8** %t143, i8*** %t101
  store i64 %t140, i64* %t103
  br label %dynstr_store_194
dynstr_store_194:
  %t148 = load i8**, i8*** %t101
  %t149 = getelementptr inbounds i8*, i8** %t148, i64 %t135
  store i8* %t133, i8** %t149
  %t150 = add i64 %t135, 1
  store i64 %t150, i64* %t102
  %t151 = getelementptr inbounds i8, i8* %t127, i64 %t100
  store i8* %t151, i8** %t125
  br label %split_scan_cond_190
split_tail_192:
  %t152 = load i8*, i8** %t125
  %t153 = call i32 @strlen(i8* %t152)
  %t154 = sext i32 %t153 to i64
  %t155 = add i64 %t154, 1
  %t156 = call i8* @star_rc_alloc(i64 %t155, i8* null)
  call i8* @strcpy(i8* %t156, i8* %t152)
  %t157 = load i64, i64* %t102
  %t158 = load i64, i64* %t103
  %t159 = icmp sge i64 %t157, %t158
  br i1 %t159, label %dynstr_grow_197, label %dynstr_store_198
dynstr_grow_197:
  %t160 = mul i64 %t158, 2
  %t161 = icmp sgt i64 %t160, 0
  %t162 = select i1 %t161, i64 %t160, i64 4
  %t163 = mul i64 %t162, 8
  %t164 = call i8* @malloc(i64 %t163)
  %t165 = bitcast i8* %t164 to i8**
  %t166 = icmp sgt i64 %t158, 0
  br i1 %t166, label %dynstr_copy_199, label %dynstr_after_copy_200
dynstr_copy_199:
  %t167 = load i8**, i8*** %t101
  %t168 = mul i64 %t157, 8
  %t169 = bitcast i8** %t167 to i8*
  call i8* @memcpy(i8* %t164, i8* %t169, i64 %t168)
  call void @free(i8* %t169)
  br label %dynstr_after_copy_200
dynstr_after_copy_200:
  store i8** %t165, i8*** %t101
  store i64 %t162, i64* %t103
  br label %dynstr_store_198
dynstr_store_198:
  %t170 = load i8**, i8*** %t101
  %t171 = getelementptr inbounds i8*, i8** %t170, i64 %t157
  store i8* %t156, i8** %t171
  %t172 = add i64 %t157, 1
  store i64 %t172, i64* %t102
  br label %split_finish_185
split_finish_185:
  call void @star_rc_release(i8* %t91)
  call void @star_rc_release(i8* %t94)
  %t185 = bitcast void (i8*)* @list_release_str to i8*
  %t186 = call i8* @star_rc_alloc(i64 24, i8* %t185)
  %t187 = bitcast i8* %t186 to { i8**, i64, i64 }*
  %t188 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t187, i32 0, i32 0
  %t189 = load i8**, i8*** %t101
  store i8** %t189, i8*** %t188
  %t190 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t187, i32 0, i32 1
  %t191 = load i64, i64* %t102
  store i64 %t191, i64* %t190
  %t192 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t187, i32 0, i32 2
  %t193 = load i64, i64* %t103
  store i64 %t193, i64* %t192
  store i8* %t186, i8** %t46
  %t194 = load i8*, i8** %t46
  %t195 = icmp eq i8* %t194, null
  br i1 %t195, label %list_read_null_204, label %list_read_real_205
list_read_null_204:
  br label %list_read_end_206
list_read_real_205:
  %t196 = bitcast i8* %t194 to { i8**, i64, i64 }*
  %t197 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t196, i32 0, i32 0
  %t198 = load i8**, i8*** %t197
  %t199 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t196, i32 0, i32 1
  %t200 = load i64, i64* %t199
  br label %list_read_end_206
list_read_end_206:
  %t201 = phi i8** [ null, %list_read_null_204 ], [ %t198, %list_read_real_205 ]
  %t202 = phi i64 [ 0, %list_read_null_204 ], [ %t200, %list_read_real_205 ]
  %t203 = trunc i64 %t202 to i32
  %t204 = icmp ne i32 %t203, 2
  br i1 %t204, label %if_then_207, label %if_else_208
if_then_207:
  %t206 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t205, i32 0, i32 0
  store i32 0, i32* %t206
  %t207 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t208 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t205, i32 0, i32 1
  store i8* %t207, i8** %t208
  %t209 = load { i32, i8* }, { i32, i8* }* %t205
  %t210 = load i8*, i8** %t46
  call void @star_rc_release(i8* %t210)
  %t211 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t211)
  %t212 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t212)
  ret { i32, i8* } %t209
if_else_208:
  br label %if_end_209
if_end_209:
  %t214 = load i8*, i8** %t46
  %t215 = icmp eq i8* %t214, null
  br i1 %t215, label %list_read_null_210, label %list_read_real_211
list_read_null_210:
  br label %list_read_end_212
list_read_real_211:
  %t216 = bitcast i8* %t214 to { i8**, i64, i64 }*
  %t217 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t216, i32 0, i32 0
  %t218 = load i8**, i8*** %t217
  %t219 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t216, i32 0, i32 1
  %t220 = load i64, i64* %t219
  br label %list_read_end_212
list_read_end_212:
  %t221 = phi i8** [ null, %list_read_null_210 ], [ %t218, %list_read_real_211 ]
  %t222 = phi i64 [ 0, %list_read_null_210 ], [ %t220, %list_read_real_211 ]
  %t223 = sext i32 0 to i64
  %t224 = icmp ult i64 %t223, %t222
  br i1 %t224, label %list_idx_ok_213, label %list_idx_oob_214
list_idx_ok_213:
  %t225 = getelementptr inbounds i8*, i8** %t221, i64 %t223
  %t226 = load i8*, i8** %t225
  %t227 = load i8*, i8** %t225
  call void @star_rc_retain(i8* %t227)
  br label %list_idx_end_215
list_idx_oob_214:
  %t228 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t228
  br label %list_idx_end_215
list_idx_end_215:
  %t229 = phi i8* [ %t226, %list_idx_ok_213 ], [ %t228, %list_idx_oob_214 ]
  %t230 = call i32 @atoi(i8* %t229)
  call void @star_rc_release(i8* %t229)
  store i32 %t230, i32* %t213
  %t232 = load i8*, i8** %t46
  %t233 = icmp eq i8* %t232, null
  br i1 %t233, label %list_read_null_216, label %list_read_real_217
list_read_null_216:
  br label %list_read_end_218
list_read_real_217:
  %t234 = bitcast i8* %t232 to { i8**, i64, i64 }*
  %t235 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t234, i32 0, i32 0
  %t236 = load i8**, i8*** %t235
  %t237 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t234, i32 0, i32 1
  %t238 = load i64, i64* %t237
  br label %list_read_end_218
list_read_end_218:
  %t239 = phi i8** [ null, %list_read_null_216 ], [ %t236, %list_read_real_217 ]
  %t240 = phi i64 [ 0, %list_read_null_216 ], [ %t238, %list_read_real_217 ]
  %t241 = sext i32 1 to i64
  %t242 = icmp ult i64 %t241, %t240
  br i1 %t242, label %list_idx_ok_219, label %list_idx_oob_220
list_idx_ok_219:
  %t243 = getelementptr inbounds i8*, i8** %t239, i64 %t241
  %t244 = load i8*, i8** %t243
  %t245 = load i8*, i8** %t243
  call void @star_rc_retain(i8* %t245)
  br label %list_idx_end_221
list_idx_oob_220:
  %t246 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t246
  br label %list_idx_end_221
list_idx_end_221:
  %t247 = phi i8* [ %t244, %list_idx_ok_219 ], [ %t246, %list_idx_oob_220 ]
  %t248 = call i8* @save__normalize_difficulty(i8* %t247)
  store i8* %t248, i8** %t231
  %t250 = load i32, i32* %t213
  %t251 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t249, i32 0, i32 0
  store i32 %t250, i32* %t251
  %t252 = load i8*, i8** %t231
  %t253 = load i8*, i8** %t231
  call void @star_rc_retain(i8* %t253)
  %t254 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t249, i32 0, i32 1
  store i8* %t252, i8** %t254
  %t255 = load { i32, i8* }, { i32, i8* }* %t249
  %t256 = load i8*, i8** %t231
  call void @star_rc_release(i8* %t256)
  %t257 = load i8*, i8** %t46
  call void @star_rc_release(i8* %t257)
  %t258 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t258)
  %t259 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t259)
  ret { i32, i8* } %t255
}

define void @ParticlePool__spawn_burst(%ParticlePool* %self, float %cx, float %cy) {
entry:
  %t0 = alloca %ParticlePool*
  %t1 = alloca float
  %t2 = alloca float
  %t3 = alloca i32
  %t4 = alloca i32
  %t16 = alloca %Particle
  %t21 = alloca float
  %t34 = alloca float
  %t48 = alloca %Particle
  store %ParticlePool* %self, %ParticlePool** %t0
  store float %cx, float* %t1
  store float %cy, float* %t2
  store i32 0, i32* %t3
  store i32 0, i32* %t4
  br label %while_cond_222
while_cond_222:
  %t5 = load i32, i32* %t4
  %t6 = icmp slt i32 %t5, 32
  br i1 %t6, label %logic_rhs_226, label %logic_short_227
logic_rhs_226:
  %t7 = load i32, i32* %t3
  %t8 = icmp slt i32 %t7, 6
  br label %logic_end_228
logic_short_227:
  br label %logic_end_228
logic_end_228:
  %t9 = phi i1 [ %t8, %logic_rhs_226 ], [ false, %logic_short_227 ]
  br i1 %t9, label %while_body_223, label %while_else_224
while_body_223:
  %t10 = load %ParticlePool*, %ParticlePool** %t0
  %t11 = getelementptr inbounds %ParticlePool, %ParticlePool* %t10, i32 0, i32 0
  %t12 = load i32, i32* %t4
  %t13 = sext i32 %t12 to i64
  %t14 = icmp ult i64 %t13, 32
  br i1 %t14, label %arr_rplace_ok_229, label %arr_rplace_oob_230
arr_rplace_ok_229:
  %t15 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t11, i32 0, i64 %t13
  br label %arr_rplace_end_231
arr_rplace_oob_230:
  store %Particle zeroinitializer, %Particle* %t16
  br label %arr_rplace_end_231
arr_rplace_end_231:
  %t17 = phi %Particle* [ %t15, %arr_rplace_ok_229 ], [ %t16, %arr_rplace_oob_230 ]
  %t18 = getelementptr inbounds %Particle, %Particle* %t17, i32 0, i32 4
  %t19 = load float, float* %t18
  %t20 = fcmp ole float %t19, 0x0000000000000000
  br i1 %t20, label %if_then_232, label %if_else_233
if_then_232:
  %t22 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t22, i32 -1)
  %t23 = load i32, i32* @rng.state
  %t24 = shl i32 %t23, 13
  %t25 = xor i32 %t23, %t24
  %t26 = lshr i32 %t25, 17
  %t27 = xor i32 %t25, %t26
  %t28 = shl i32 %t27, 5
  %t29 = xor i32 %t27, %t28
  store i32 %t29, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t22, i32 1, i32* null)
  %t30 = and i32 %t29, 16777215
  %t31 = uitofp i32 %t30 to float
  %t32 = fdiv float %t31, 0x4170000000000000
  %t33 = fmul float %t32, 0x401921FB60000000
  store float %t33, float* %t21
  %t35 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t35, i32 -1)
  %t36 = load i32, i32* @rng.state
  %t37 = shl i32 %t36, 13
  %t38 = xor i32 %t36, %t37
  %t39 = lshr i32 %t38, 17
  %t40 = xor i32 %t38, %t39
  %t41 = shl i32 %t40, 5
  %t42 = xor i32 %t40, %t41
  store i32 %t42, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t35, i32 1, i32* null)
  %t43 = and i32 %t42, 16777215
  %t44 = uitofp i32 %t43 to float
  %t45 = fdiv float %t44, 0x4170000000000000
  %t46 = fmul float %t45, 0x4000000000000000
  %t47 = fadd float 0x3FF0000000000000, %t46
  store float %t47, float* %t34
  %t49 = load float, float* %t1
  %t50 = getelementptr inbounds %Particle, %Particle* %t48, i32 0, i32 0
  store float %t49, float* %t50
  %t51 = load float, float* %t2
  %t52 = getelementptr inbounds %Particle, %Particle* %t48, i32 0, i32 1
  store float %t51, float* %t52
  %t53 = load float, float* %t21
  %t54 = call float @llvm.cos.f32(float %t53)
  %t55 = load float, float* %t34
  %t56 = fmul float %t54, %t55
  %t57 = getelementptr inbounds %Particle, %Particle* %t48, i32 0, i32 2
  store float %t56, float* %t57
  %t58 = load float, float* %t21
  %t59 = call float @llvm.sin.f32(float %t58)
  %t60 = load float, float* %t34
  %t61 = fmul float %t59, %t60
  %t62 = getelementptr inbounds %Particle, %Particle* %t48, i32 0, i32 3
  store float %t61, float* %t62
  %t63 = getelementptr inbounds %Particle, %Particle* %t48, i32 0, i32 4
  store float 0x3FDCCCCCC0000000, float* %t63
  %t64 = load %Particle, %Particle* %t48
  %t65 = load %ParticlePool*, %ParticlePool** %t0
  %t66 = getelementptr inbounds %ParticlePool, %ParticlePool* %t65, i32 0, i32 0
  %t67 = load i32, i32* %t4
  %t68 = sext i32 %t67 to i64
  %t69 = icmp ult i64 %t68, 32
  br i1 %t69, label %arr_set_do_235, label %arr_set_oob_236
arr_set_do_235:
  %t70 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t66, i32 0, i64 %t68
  store %Particle %t64, %Particle* %t70
  br label %arr_set_end_237
arr_set_oob_236:
  br label %arr_set_end_237
arr_set_end_237:
  %t71 = load i32, i32* %t3
  %t72 = add i32 %t71, 1
  store i32 %t72, i32* %t3
  br label %if_end_234
if_else_233:
  br label %if_end_234
if_end_234:
  %t73 = load i32, i32* %t4
  %t74 = add i32 %t73, 1
  store i32 %t74, i32* %t4
  br label %while_cond_222
while_else_224:
  br label %while_end_225
while_end_225:
  ret void
}

define void @ParticlePool__update(%ParticlePool* %self, float %dt) {
entry:
  %t0 = alloca %ParticlePool*
  %t1 = alloca float
  %t2 = alloca i32
  %t11 = alloca %Particle
  %t23 = alloca %Particle
  %t34 = alloca %Particle
  %t43 = alloca %Particle
  %t53 = alloca %Particle
  %t64 = alloca %Particle
  %t73 = alloca %Particle
  %t83 = alloca %Particle
  %t94 = alloca %Particle
  %t103 = alloca %Particle
  %t114 = alloca %Particle
  store %ParticlePool* %self, %ParticlePool** %t0
  store float %dt, float* %t1
  store i32 0, i32* %t2
  br label %while_cond_238
while_cond_238:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 32
  br i1 %t4, label %while_body_239, label %while_else_240
while_body_239:
  %t5 = load %ParticlePool*, %ParticlePool** %t0
  %t6 = getelementptr inbounds %ParticlePool, %ParticlePool* %t5, i32 0, i32 0
  %t7 = load i32, i32* %t2
  %t8 = sext i32 %t7 to i64
  %t9 = icmp ult i64 %t8, 32
  br i1 %t9, label %arr_rplace_ok_242, label %arr_rplace_oob_243
arr_rplace_ok_242:
  %t10 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t6, i32 0, i64 %t8
  br label %arr_rplace_end_244
arr_rplace_oob_243:
  store %Particle zeroinitializer, %Particle* %t11
  br label %arr_rplace_end_244
arr_rplace_end_244:
  %t12 = phi %Particle* [ %t10, %arr_rplace_ok_242 ], [ %t11, %arr_rplace_oob_243 ]
  %t13 = getelementptr inbounds %Particle, %Particle* %t12, i32 0, i32 4
  %t14 = load float, float* %t13
  %t15 = fcmp ogt float %t14, 0x0000000000000000
  br i1 %t15, label %if_then_245, label %if_else_246
if_then_245:
  %t16 = load float, float* %t1
  %t17 = load %ParticlePool*, %ParticlePool** %t0
  %t18 = getelementptr inbounds %ParticlePool, %ParticlePool* %t17, i32 0, i32 0
  %t19 = load i32, i32* %t2
  %t20 = sext i32 %t19 to i64
  %t21 = icmp ult i64 %t20, 32
  br i1 %t21, label %arr_place_ok_248, label %arr_place_oob_249
arr_place_ok_248:
  %t22 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t18, i32 0, i64 %t20
  br label %arr_place_end_250
arr_place_oob_249:
  store %Particle zeroinitializer, %Particle* %t23
  br label %arr_place_end_250
arr_place_end_250:
  %t24 = phi %Particle* [ %t22, %arr_place_ok_248 ], [ %t23, %arr_place_oob_249 ]
  %t25 = getelementptr inbounds %Particle, %Particle* %t24, i32 0, i32 4
  %t26 = load float, float* %t25
  %t27 = fsub float %t26, %t16
  %t28 = load %ParticlePool*, %ParticlePool** %t0
  %t29 = getelementptr inbounds %ParticlePool, %ParticlePool* %t28, i32 0, i32 0
  %t30 = load i32, i32* %t2
  %t31 = sext i32 %t30 to i64
  %t32 = icmp ult i64 %t31, 32
  br i1 %t32, label %arr_place_ok_251, label %arr_place_oob_252
arr_place_ok_251:
  %t33 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t29, i32 0, i64 %t31
  br label %arr_place_end_253
arr_place_oob_252:
  store %Particle zeroinitializer, %Particle* %t34
  br label %arr_place_end_253
arr_place_end_253:
  %t35 = phi %Particle* [ %t33, %arr_place_ok_251 ], [ %t34, %arr_place_oob_252 ]
  %t36 = getelementptr inbounds %Particle, %Particle* %t35, i32 0, i32 4
  store float %t27, float* %t36
  %t37 = load %ParticlePool*, %ParticlePool** %t0
  %t38 = getelementptr inbounds %ParticlePool, %ParticlePool* %t37, i32 0, i32 0
  %t39 = load i32, i32* %t2
  %t40 = sext i32 %t39 to i64
  %t41 = icmp ult i64 %t40, 32
  br i1 %t41, label %arr_rplace_ok_254, label %arr_rplace_oob_255
arr_rplace_ok_254:
  %t42 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t38, i32 0, i64 %t40
  br label %arr_rplace_end_256
arr_rplace_oob_255:
  store %Particle zeroinitializer, %Particle* %t43
  br label %arr_rplace_end_256
arr_rplace_end_256:
  %t44 = phi %Particle* [ %t42, %arr_rplace_ok_254 ], [ %t43, %arr_rplace_oob_255 ]
  %t45 = getelementptr inbounds %Particle, %Particle* %t44, i32 0, i32 2
  %t46 = load float, float* %t45
  %t47 = load %ParticlePool*, %ParticlePool** %t0
  %t48 = getelementptr inbounds %ParticlePool, %ParticlePool* %t47, i32 0, i32 0
  %t49 = load i32, i32* %t2
  %t50 = sext i32 %t49 to i64
  %t51 = icmp ult i64 %t50, 32
  br i1 %t51, label %arr_place_ok_257, label %arr_place_oob_258
arr_place_ok_257:
  %t52 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t48, i32 0, i64 %t50
  br label %arr_place_end_259
arr_place_oob_258:
  store %Particle zeroinitializer, %Particle* %t53
  br label %arr_place_end_259
arr_place_end_259:
  %t54 = phi %Particle* [ %t52, %arr_place_ok_257 ], [ %t53, %arr_place_oob_258 ]
  %t55 = getelementptr inbounds %Particle, %Particle* %t54, i32 0, i32 0
  %t56 = load float, float* %t55
  %t57 = fadd float %t56, %t46
  %t58 = load %ParticlePool*, %ParticlePool** %t0
  %t59 = getelementptr inbounds %ParticlePool, %ParticlePool* %t58, i32 0, i32 0
  %t60 = load i32, i32* %t2
  %t61 = sext i32 %t60 to i64
  %t62 = icmp ult i64 %t61, 32
  br i1 %t62, label %arr_place_ok_260, label %arr_place_oob_261
arr_place_ok_260:
  %t63 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t59, i32 0, i64 %t61
  br label %arr_place_end_262
arr_place_oob_261:
  store %Particle zeroinitializer, %Particle* %t64
  br label %arr_place_end_262
arr_place_end_262:
  %t65 = phi %Particle* [ %t63, %arr_place_ok_260 ], [ %t64, %arr_place_oob_261 ]
  %t66 = getelementptr inbounds %Particle, %Particle* %t65, i32 0, i32 0
  store float %t57, float* %t66
  %t67 = load %ParticlePool*, %ParticlePool** %t0
  %t68 = getelementptr inbounds %ParticlePool, %ParticlePool* %t67, i32 0, i32 0
  %t69 = load i32, i32* %t2
  %t70 = sext i32 %t69 to i64
  %t71 = icmp ult i64 %t70, 32
  br i1 %t71, label %arr_rplace_ok_263, label %arr_rplace_oob_264
arr_rplace_ok_263:
  %t72 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t68, i32 0, i64 %t70
  br label %arr_rplace_end_265
arr_rplace_oob_264:
  store %Particle zeroinitializer, %Particle* %t73
  br label %arr_rplace_end_265
arr_rplace_end_265:
  %t74 = phi %Particle* [ %t72, %arr_rplace_ok_263 ], [ %t73, %arr_rplace_oob_264 ]
  %t75 = getelementptr inbounds %Particle, %Particle* %t74, i32 0, i32 3
  %t76 = load float, float* %t75
  %t77 = load %ParticlePool*, %ParticlePool** %t0
  %t78 = getelementptr inbounds %ParticlePool, %ParticlePool* %t77, i32 0, i32 0
  %t79 = load i32, i32* %t2
  %t80 = sext i32 %t79 to i64
  %t81 = icmp ult i64 %t80, 32
  br i1 %t81, label %arr_place_ok_266, label %arr_place_oob_267
arr_place_ok_266:
  %t82 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t78, i32 0, i64 %t80
  br label %arr_place_end_268
arr_place_oob_267:
  store %Particle zeroinitializer, %Particle* %t83
  br label %arr_place_end_268
arr_place_end_268:
  %t84 = phi %Particle* [ %t82, %arr_place_ok_266 ], [ %t83, %arr_place_oob_267 ]
  %t85 = getelementptr inbounds %Particle, %Particle* %t84, i32 0, i32 1
  %t86 = load float, float* %t85
  %t87 = fadd float %t86, %t76
  %t88 = load %ParticlePool*, %ParticlePool** %t0
  %t89 = getelementptr inbounds %ParticlePool, %ParticlePool* %t88, i32 0, i32 0
  %t90 = load i32, i32* %t2
  %t91 = sext i32 %t90 to i64
  %t92 = icmp ult i64 %t91, 32
  br i1 %t92, label %arr_place_ok_269, label %arr_place_oob_270
arr_place_ok_269:
  %t93 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t89, i32 0, i64 %t91
  br label %arr_place_end_271
arr_place_oob_270:
  store %Particle zeroinitializer, %Particle* %t94
  br label %arr_place_end_271
arr_place_end_271:
  %t95 = phi %Particle* [ %t93, %arr_place_ok_269 ], [ %t94, %arr_place_oob_270 ]
  %t96 = getelementptr inbounds %Particle, %Particle* %t95, i32 0, i32 1
  store float %t87, float* %t96
  %t97 = load %ParticlePool*, %ParticlePool** %t0
  %t98 = getelementptr inbounds %ParticlePool, %ParticlePool* %t97, i32 0, i32 0
  %t99 = load i32, i32* %t2
  %t100 = sext i32 %t99 to i64
  %t101 = icmp ult i64 %t100, 32
  br i1 %t101, label %arr_place_ok_272, label %arr_place_oob_273
arr_place_ok_272:
  %t102 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t98, i32 0, i64 %t100
  br label %arr_place_end_274
arr_place_oob_273:
  store %Particle zeroinitializer, %Particle* %t103
  br label %arr_place_end_274
arr_place_end_274:
  %t104 = phi %Particle* [ %t102, %arr_place_ok_272 ], [ %t103, %arr_place_oob_273 ]
  %t105 = getelementptr inbounds %Particle, %Particle* %t104, i32 0, i32 3
  %t106 = load float, float* %t105
  %t107 = fadd float %t106, 0x3FBEB851E0000000
  %t108 = load %ParticlePool*, %ParticlePool** %t0
  %t109 = getelementptr inbounds %ParticlePool, %ParticlePool* %t108, i32 0, i32 0
  %t110 = load i32, i32* %t2
  %t111 = sext i32 %t110 to i64
  %t112 = icmp ult i64 %t111, 32
  br i1 %t112, label %arr_place_ok_275, label %arr_place_oob_276
arr_place_ok_275:
  %t113 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t109, i32 0, i64 %t111
  br label %arr_place_end_277
arr_place_oob_276:
  store %Particle zeroinitializer, %Particle* %t114
  br label %arr_place_end_277
arr_place_end_277:
  %t115 = phi %Particle* [ %t113, %arr_place_ok_275 ], [ %t114, %arr_place_oob_276 ]
  %t116 = getelementptr inbounds %Particle, %Particle* %t115, i32 0, i32 3
  store float %t107, float* %t116
  br label %if_end_247
if_else_246:
  br label %if_end_247
if_end_247:
  %t117 = load i32, i32* %t2
  %t118 = add i32 %t117, 1
  store i32 %t118, i32* %t2
  br label %while_cond_238
while_else_240:
  br label %while_end_241
while_end_241:
  ret void
}

define void @ParticlePool__draw(%ParticlePool* %self, i8* %w) {
entry:
  %t0 = alloca %ParticlePool*
  %t1 = alloca i8*
  %t2 = alloca i32
  %t11 = alloca %Particle
  %t16 = alloca float
  %t23 = alloca %Particle
  %t41 = alloca %Particle
  %t52 = alloca %Particle
  store %ParticlePool* %self, %ParticlePool** %t0
  store i8* %w, i8** %t1
  store i32 0, i32* %t2
  br label %while_cond_278
while_cond_278:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 32
  br i1 %t4, label %while_body_279, label %while_else_280
while_body_279:
  %t5 = load %ParticlePool*, %ParticlePool** %t0
  %t6 = getelementptr inbounds %ParticlePool, %ParticlePool* %t5, i32 0, i32 0
  %t7 = load i32, i32* %t2
  %t8 = sext i32 %t7 to i64
  %t9 = icmp ult i64 %t8, 32
  br i1 %t9, label %arr_rplace_ok_282, label %arr_rplace_oob_283
arr_rplace_ok_282:
  %t10 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t6, i32 0, i64 %t8
  br label %arr_rplace_end_284
arr_rplace_oob_283:
  store %Particle zeroinitializer, %Particle* %t11
  br label %arr_rplace_end_284
arr_rplace_end_284:
  %t12 = phi %Particle* [ %t10, %arr_rplace_ok_282 ], [ %t11, %arr_rplace_oob_283 ]
  %t13 = getelementptr inbounds %Particle, %Particle* %t12, i32 0, i32 4
  %t14 = load float, float* %t13
  %t15 = fcmp ogt float %t14, 0x0000000000000000
  br i1 %t15, label %if_then_285, label %if_else_286
if_then_285:
  %t17 = load %ParticlePool*, %ParticlePool** %t0
  %t18 = getelementptr inbounds %ParticlePool, %ParticlePool* %t17, i32 0, i32 0
  %t19 = load i32, i32* %t2
  %t20 = sext i32 %t19 to i64
  %t21 = icmp ult i64 %t20, 32
  br i1 %t21, label %arr_rplace_ok_288, label %arr_rplace_oob_289
arr_rplace_ok_288:
  %t22 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t18, i32 0, i64 %t20
  br label %arr_rplace_end_290
arr_rplace_oob_289:
  store %Particle zeroinitializer, %Particle* %t23
  br label %arr_rplace_end_290
arr_rplace_end_290:
  %t24 = phi %Particle* [ %t22, %arr_rplace_ok_288 ], [ %t23, %arr_rplace_oob_289 ]
  %t25 = getelementptr inbounds %Particle, %Particle* %t24, i32 0, i32 4
  %t26 = load float, float* %t25
  %t27 = fmul float %t26, 0x406FE00000000000
  %t28 = fdiv float %t27, 0x3FDCCCCCC0000000
  %t29 = call float @llvm.maxnum.f32(float %t28, float 0x0000000000000000)
  %t30 = call float @llvm.minnum.f32(float %t29, float 0x406FE00000000000)
  store float %t30, float* %t16
  %t31 = load i8*, i8** %t1
  %t32 = icmp eq i8* %t31, null
  br i1 %t32, label %sdl_null_window_291, label %sdl_window_handle_ok_292
sdl_null_window_291:
  %t33 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.16, i64 0, i64 0
  call i32 @puts(i8* %t33)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_292:
  %t34 = call i8* @SDL_GetRenderer(i8* %t31)
  %t35 = load %ParticlePool*, %ParticlePool** %t0
  %t36 = getelementptr inbounds %ParticlePool, %ParticlePool* %t35, i32 0, i32 0
  %t37 = load i32, i32* %t2
  %t38 = sext i32 %t37 to i64
  %t39 = icmp ult i64 %t38, 32
  br i1 %t39, label %arr_rplace_ok_293, label %arr_rplace_oob_294
arr_rplace_ok_293:
  %t40 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t36, i32 0, i64 %t38
  br label %arr_rplace_end_295
arr_rplace_oob_294:
  store %Particle zeroinitializer, %Particle* %t41
  br label %arr_rplace_end_295
arr_rplace_end_295:
  %t42 = phi %Particle* [ %t40, %arr_rplace_ok_293 ], [ %t41, %arr_rplace_oob_294 ]
  %t43 = getelementptr inbounds %Particle, %Particle* %t42, i32 0, i32 0
  %t44 = load float, float* %t43
  %t45 = call i32 @llvm.fptosi.sat.i32.f32(float %t44)
  %t46 = load %ParticlePool*, %ParticlePool** %t0
  %t47 = getelementptr inbounds %ParticlePool, %ParticlePool* %t46, i32 0, i32 0
  %t48 = load i32, i32* %t2
  %t49 = sext i32 %t48 to i64
  %t50 = icmp ult i64 %t49, 32
  br i1 %t50, label %arr_rplace_ok_296, label %arr_rplace_oob_297
arr_rplace_ok_296:
  %t51 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t47, i32 0, i64 %t49
  br label %arr_rplace_end_298
arr_rplace_oob_297:
  store %Particle zeroinitializer, %Particle* %t52
  br label %arr_rplace_end_298
arr_rplace_end_298:
  %t53 = phi %Particle* [ %t51, %arr_rplace_ok_296 ], [ %t52, %arr_rplace_oob_297 ]
  %t54 = getelementptr inbounds %Particle, %Particle* %t53, i32 0, i32 1
  %t55 = load float, float* %t54
  %t56 = call i32 @llvm.fptosi.sat.i32.f32(float %t55)
  %t57 = and i32 255, 255
  %t58 = and i32 210, 255
  %t59 = shl i32 %t58, 8
  %t60 = or i32 %t57, %t59
  %t61 = and i32 90, 255
  %t62 = shl i32 %t61, 16
  %t63 = or i32 %t60, %t62
  %t64 = load float, float* %t16
  %t65 = call i32 @llvm.fptosi.sat.i32.f32(float %t64)
  %t66 = and i32 %t65, 255
  %t67 = shl i32 %t66, 24
  %t68 = or i32 %t63, %t67
  %t69 = and i32 %t68, 255
  %t70 = trunc i32 %t69 to i8
  %t71 = lshr i32 %t68, 8
  %t72 = and i32 %t71, 255
  %t73 = trunc i32 %t72 to i8
  %t74 = lshr i32 %t68, 16
  %t75 = and i32 %t74, 255
  %t76 = trunc i32 %t75 to i8
  %t77 = lshr i32 %t68, 24
  %t78 = and i32 %t77, 255
  %t79 = trunc i32 %t78 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t34, i8 %t70, i8 %t73, i8 %t76, i8 %t79)
  call i32 @SDL_RenderDrawPoint(i8* %t34, i32 %t45, i32 %t56)
  br label %if_end_287
if_else_286:
  br label %if_end_287
if_end_287:
  %t80 = load i32, i32* %t2
  %t81 = add i32 %t80, 1
  store i32 %t81, i32* %t2
  br label %while_cond_278
while_else_280:
  br label %while_end_281
while_end_281:
  ret void
}

define void @tick_particle_arena(float %dt) {
entry:
  %t0 = alloca float
  %t83 = alloca { i64, i64, float* }
  %t97 = alloca { i64, i64, float* }
  %t111 = alloca { i64, i64, float* }
  %t125 = alloca { i64, i64, float* }
  %t152 = alloca { i64, i64, float* }
  store float %dt, float* %t0
  call void @par.pool.ensure_init()
  %t60 = call i32 @GetCurrentThreadId()
  %t61 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t62 = load i32, i32* %t61
  %t63 = icmp eq i32 %t60, %t62
  %t64 = select i1 %t63, i32 0, i32 -1
  %t65 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t66 = load i32, i32* %t65
  %t67 = icmp eq i32 %t60, %t66
  %t68 = select i1 %t67, i32 1, i32 %t64
  %t69 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t70 = load i32, i32* %t69
  %t71 = icmp eq i32 %t60, %t70
  %t72 = select i1 %t71, i32 2, i32 %t68
  %t73 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t74 = load i32, i32* %t73
  %t75 = icmp eq i32 %t60, %t74
  %t76 = select i1 %t75, i32 3, i32 %t72
  %t77 = icmp sge i32 %t76, 0
  br i1 %t77, label %par_serial_306, label %par_pooled_305
par_pooled_305:
  %t78 = load i64, i64* @arena.Particles.count
  %t79 = mul i64 %t78, 0
  %t80 = sdiv i64 %t79, 4
  %t81 = mul i64 %t78, 1
  %t82 = sdiv i64 %t81, 4
  %t84 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t83, i32 0, i32 0
  store i64 %t80, i64* %t84
  %t85 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t83, i32 0, i32 1
  store i64 %t82, i64* %t85
  %t86 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t83, i32 0, i32 2
  store float* %t0, float** %t86
  %t87 = bitcast { i64, i64, float* }* %t83 to i8*
  %t88 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t87, i8** %t88
  %t89 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_299, i32 (i8*)** %t89
  %t90 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t91 = load i8*, i8** %t90
  %t92 = call i32 @ReleaseSemaphore(i8* %t91, i32 1, i32* null)
  %t93 = mul i64 %t78, 1
  %t94 = sdiv i64 %t93, 4
  %t95 = mul i64 %t78, 2
  %t96 = sdiv i64 %t95, 4
  %t98 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t97, i32 0, i32 0
  store i64 %t94, i64* %t98
  %t99 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t97, i32 0, i32 1
  store i64 %t96, i64* %t99
  %t100 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t97, i32 0, i32 2
  store float* %t0, float** %t100
  %t101 = bitcast { i64, i64, float* }* %t97 to i8*
  %t102 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t101, i8** %t102
  %t103 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_299, i32 (i8*)** %t103
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t105 = load i8*, i8** %t104
  %t106 = call i32 @ReleaseSemaphore(i8* %t105, i32 1, i32* null)
  %t107 = mul i64 %t78, 2
  %t108 = sdiv i64 %t107, 4
  %t109 = mul i64 %t78, 3
  %t110 = sdiv i64 %t109, 4
  %t112 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t111, i32 0, i32 0
  store i64 %t108, i64* %t112
  %t113 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t111, i32 0, i32 1
  store i64 %t110, i64* %t113
  %t114 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t111, i32 0, i32 2
  store float* %t0, float** %t114
  %t115 = bitcast { i64, i64, float* }* %t111 to i8*
  %t116 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t115, i8** %t116
  %t117 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_299, i32 (i8*)** %t117
  %t118 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t119 = load i8*, i8** %t118
  %t120 = call i32 @ReleaseSemaphore(i8* %t119, i32 1, i32* null)
  %t121 = mul i64 %t78, 3
  %t122 = sdiv i64 %t121, 4
  %t123 = mul i64 %t78, 4
  %t124 = sdiv i64 %t123, 4
  %t126 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t125, i32 0, i32 0
  store i64 %t122, i64* %t126
  %t127 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t125, i32 0, i32 1
  store i64 %t124, i64* %t127
  %t128 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t125, i32 0, i32 2
  store float* %t0, float** %t128
  %t129 = bitcast { i64, i64, float* }* %t125 to i8*
  %t130 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t129, i8** %t130
  %t131 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_299, i32 (i8*)** %t131
  %t132 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t133 = load i8*, i8** %t132
  %t134 = call i32 @ReleaseSemaphore(i8* %t133, i32 1, i32* null)
  %t135 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t136 = load i8*, i8** %t135
  %t137 = call i32 @WaitForSingleObject(i8* %t136, i32 -1)
  %t138 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t139 = load i8*, i8** %t138
  %t140 = call i32 @WaitForSingleObject(i8* %t139, i32 -1)
  %t141 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t142 = load i8*, i8** %t141
  %t143 = call i32 @WaitForSingleObject(i8* %t142, i32 -1)
  %t144 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t145 = load i8*, i8** %t144
  %t146 = call i32 @WaitForSingleObject(i8* %t145, i32 -1)
  br label %par_join_310
par_serial_306:
  %t147 = load i32, i32* @par.pool.serial_owner
  %t148 = icmp eq i32 %t147, %t76
  br i1 %t148, label %par_run_308, label %par_acquire_307
par_acquire_307:
  %t149 = load i8*, i8** @par.pool.serial_lock
  %t150 = call i32 @WaitForSingleObject(i8* %t149, i32 -1)
  store i32 %t76, i32* @par.pool.serial_owner
  br label %par_run_308
par_run_308:
  %t151 = load i64, i64* @arena.Particles.count
  %t153 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t152, i32 0, i32 0
  store i64 0, i64* %t153
  %t154 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t152, i32 0, i32 1
  store i64 %t151, i64* %t154
  %t155 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t152, i32 0, i32 2
  store float* %t0, float** %t155
  %t156 = bitcast { i64, i64, float* }* %t152 to i8*
  %t157 = call i32 @par_worker_299(i8* %t156)
  br i1 %t148, label %par_join_310, label %par_release_309
par_release_309:
  store i32 -1, i32* @par.pool.serial_owner
  %t158 = load i8*, i8** @par.pool.serial_lock
  %t159 = call i32 @ReleaseSemaphore(i8* %t158, i32 1, i32* null)
  br label %par_join_310
par_join_310:
  ret void
}

define void @reclaim_dead_particles() {
entry:
  %t2 = alloca i64
  %t11 = alloca i32
  %t0 = load %Particle*, %Particle** @arena.Particles.data
  %t1 = load i64, i64* @arena.Particles.count
  store i64 0, i64* %t2
  br label %each_cond_311
each_cond_311:
  %t3 = load i64, i64* %t2
  %t4 = icmp slt i64 %t3, %t1
  br i1 %t4, label %each_body_312, label %each_end_315
each_body_312:
  %t5 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t3
  %t6 = load i64, i64* %t5
  %t7 = and i64 %t6, 1
  %t8 = icmp eq i64 %t7, 1
  br i1 %t8, label %each_live_313, label %each_step_314
each_live_313:
  %t9 = getelementptr inbounds %Particle, %Particle* %t0, i64 %t3
  %t10 = trunc i64 %t3 to i32
  store i32 %t10, i32* %t11
  %t12 = getelementptr inbounds %Particle, %Particle* %t9, i32 0, i32 4
  %t13 = load float, float* %t12
  %t14 = fcmp ole float %t13, 0x0000000000000000
  br i1 %t14, label %if_then_316, label %if_else_317
if_then_316:
  %t15 = load i32, i32* %t11
  %t16 = sext i32 %t15 to i64
  %t17 = icmp ult i64 %t16, 256
  br i1 %t17, label %despawn_do_319, label %despawn_end_320
despawn_do_319:
  %t18 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t16
  %t19 = load i64, i64* %t18
  %t20 = and i64 %t19, 1
  %t21 = icmp eq i64 %t20, 1
  br i1 %t21, label %despawn_live_321, label %despawn_end_320
despawn_live_321:
  %t22 = add i64 %t19, 1
  store i64 %t22, i64* %t18
  %t23 = load i64, i64* @arena.Particles.free_top
  %t24 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.free, i64 0, i64 %t23
  store i64 %t16, i64* %t24
  %t25 = add i64 %t23, 1
  store i64 %t25, i64* @arena.Particles.free_top
  br label %despawn_end_320
despawn_end_320:
  br label %if_end_318
if_else_317:
  br label %if_end_318
if_end_318:
  br label %each_step_314
each_step_314:
  %t26 = add i64 %t3, 1
  store i64 %t26, i64* %t2
  br label %each_cond_311
each_end_315:
  ret void
}

define void @dump_particle_arena() {
entry:
  %t53 = alloca { i64, i64 }
  %t66 = alloca { i64, i64 }
  %t79 = alloca { i64, i64 }
  %t92 = alloca { i64, i64 }
  %t118 = alloca { i64, i64 }
  %t0 = getelementptr inbounds { i64, i8*, [35 x i8] }, { i64, i8*, [35 x i8] }* @.str.17, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t0)
  call i32 (i8*, ...) @printf(i8* %t0)
  %t1 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1)
  call void @par.pool.ensure_init()
  %t30 = call i32 @GetCurrentThreadId()
  %t31 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t32 = load i32, i32* %t31
  %t33 = icmp eq i32 %t30, %t32
  %t34 = select i1 %t33, i32 0, i32 -1
  %t35 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t36 = load i32, i32* %t35
  %t37 = icmp eq i32 %t30, %t36
  %t38 = select i1 %t37, i32 1, i32 %t34
  %t39 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t40 = load i32, i32* %t39
  %t41 = icmp eq i32 %t30, %t40
  %t42 = select i1 %t41, i32 2, i32 %t38
  %t43 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t30, %t44
  %t46 = select i1 %t45, i32 3, i32 %t42
  %t47 = icmp sge i32 %t46, 0
  br i1 %t47, label %par_serial_332, label %par_pooled_331
par_pooled_331:
  %t48 = load i64, i64* @arena.Particles.count
  %t49 = mul i64 %t48, 0
  %t50 = sdiv i64 %t49, 4
  %t51 = mul i64 %t48, 1
  %t52 = sdiv i64 %t51, 4
  %t54 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t53, i32 0, i32 0
  store i64 %t50, i64* %t54
  %t55 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t53, i32 0, i32 1
  store i64 %t52, i64* %t55
  %t56 = bitcast { i64, i64 }* %t53 to i8*
  %t57 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t56, i8** %t57
  %t58 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_322, i32 (i8*)** %t58
  %t59 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t60 = load i8*, i8** %t59
  %t61 = call i32 @ReleaseSemaphore(i8* %t60, i32 1, i32* null)
  %t62 = mul i64 %t48, 1
  %t63 = sdiv i64 %t62, 4
  %t64 = mul i64 %t48, 2
  %t65 = sdiv i64 %t64, 4
  %t67 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t66, i32 0, i32 0
  store i64 %t63, i64* %t67
  %t68 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t66, i32 0, i32 1
  store i64 %t65, i64* %t68
  %t69 = bitcast { i64, i64 }* %t66 to i8*
  %t70 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t69, i8** %t70
  %t71 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_322, i32 (i8*)** %t71
  %t72 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t73 = load i8*, i8** %t72
  %t74 = call i32 @ReleaseSemaphore(i8* %t73, i32 1, i32* null)
  %t75 = mul i64 %t48, 2
  %t76 = sdiv i64 %t75, 4
  %t77 = mul i64 %t48, 3
  %t78 = sdiv i64 %t77, 4
  %t80 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t79, i32 0, i32 0
  store i64 %t76, i64* %t80
  %t81 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t79, i32 0, i32 1
  store i64 %t78, i64* %t81
  %t82 = bitcast { i64, i64 }* %t79 to i8*
  %t83 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t82, i8** %t83
  %t84 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_322, i32 (i8*)** %t84
  %t85 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t86 = load i8*, i8** %t85
  %t87 = call i32 @ReleaseSemaphore(i8* %t86, i32 1, i32* null)
  %t88 = mul i64 %t48, 3
  %t89 = sdiv i64 %t88, 4
  %t90 = mul i64 %t48, 4
  %t91 = sdiv i64 %t90, 4
  %t93 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t92, i32 0, i32 0
  store i64 %t89, i64* %t93
  %t94 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t92, i32 0, i32 1
  store i64 %t91, i64* %t94
  %t95 = bitcast { i64, i64 }* %t92 to i8*
  %t96 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t95, i8** %t96
  %t97 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_322, i32 (i8*)** %t97
  %t98 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t99 = load i8*, i8** %t98
  %t100 = call i32 @ReleaseSemaphore(i8* %t99, i32 1, i32* null)
  %t101 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t102 = load i8*, i8** %t101
  %t103 = call i32 @WaitForSingleObject(i8* %t102, i32 -1)
  %t104 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t105 = load i8*, i8** %t104
  %t106 = call i32 @WaitForSingleObject(i8* %t105, i32 -1)
  %t107 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t108 = load i8*, i8** %t107
  %t109 = call i32 @WaitForSingleObject(i8* %t108, i32 -1)
  %t110 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t111 = load i8*, i8** %t110
  %t112 = call i32 @WaitForSingleObject(i8* %t111, i32 -1)
  br label %par_join_336
par_serial_332:
  %t113 = load i32, i32* @par.pool.serial_owner
  %t114 = icmp eq i32 %t113, %t46
  br i1 %t114, label %par_run_334, label %par_acquire_333
par_acquire_333:
  %t115 = load i8*, i8** @par.pool.serial_lock
  %t116 = call i32 @WaitForSingleObject(i8* %t115, i32 -1)
  store i32 %t46, i32* @par.pool.serial_owner
  br label %par_run_334
par_run_334:
  %t117 = load i64, i64* @arena.Particles.count
  %t119 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 0
  store i64 0, i64* %t119
  %t120 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 1
  store i64 %t117, i64* %t120
  %t121 = bitcast { i64, i64 }* %t118 to i8*
  %t122 = call i32 @par_worker_322(i8* %t121)
  br i1 %t114, label %par_join_336, label %par_release_335
par_release_335:
  store i32 -1, i32* @par.pool.serial_owner
  %t123 = load i8*, i8** @par.pool.serial_lock
  %t124 = call i32 @ReleaseSemaphore(i8* %t123, i32 1, i32* null)
  br label %par_join_336
par_join_336:
  ret void
}

define i1 @FlashOnEat__resume(%FlashOnEat* %self) {
entry:
  %t0 = alloca %FlashOnEat*
  store %FlashOnEat* %self, %FlashOnEat** %t0
  %t1 = load %FlashOnEat*, %FlashOnEat** %t0
  %t2 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t1, i32 0, i32 1
  %t3 = load i32, i32* %t2
  %t4 = icmp eq i32 %t3, 0
  br i1 %t4, label %if_then_337, label %if_else_338
if_then_337:
  %t5 = load %FlashOnEat*, %FlashOnEat** %t0
  %t6 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %sdl_null_window_340, label %sdl_window_handle_ok_341
sdl_null_window_340:
  %t9 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.20, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_341:
  %t10 = call i8* @SDL_GetRenderer(i8* %t7)
  %t11 = and i32 235, 255
  %t12 = and i32 235, 255
  %t13 = shl i32 %t12, 8
  %t14 = or i32 %t11, %t13
  %t15 = and i32 245, 255
  %t16 = shl i32 %t15, 16
  %t17 = or i32 %t14, %t16
  %t18 = and i32 255, 255
  %t19 = shl i32 %t18, 24
  %t20 = or i32 %t17, %t19
  %t21 = and i32 %t20, 255
  %t22 = trunc i32 %t21 to i8
  %t23 = lshr i32 %t20, 8
  %t24 = and i32 %t23, 255
  %t25 = trunc i32 %t24 to i8
  %t26 = lshr i32 %t20, 16
  %t27 = and i32 %t26, 255
  %t28 = trunc i32 %t27 to i8
  %t29 = lshr i32 %t20, 24
  %t30 = and i32 %t29, 255
  %t31 = trunc i32 %t30 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t10, i8 %t22, i8 %t25, i8 %t28, i8 %t31)
  call i32 @SDL_RenderClear(i8* %t10)
  %t32 = load %FlashOnEat*, %FlashOnEat** %t0
  %t33 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t32, i32 0, i32 0
  %t34 = load i8*, i8** %t33
  %t35 = icmp eq i8* %t34, null
  br i1 %t35, label %sdl_null_window_342, label %sdl_window_handle_ok_343
sdl_null_window_342:
  %t36 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.21, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_343:
  %t37 = call i8* @SDL_GetRenderer(i8* %t34)
  call void @SDL_RenderPresent(i8* %t37)
  %t38 = icmp slt i32 35, 0
  %t39 = select i1 %t38, i32 0, i32 35
  call void @SDL_Delay(i32 %t39)
  %t40 = load %FlashOnEat*, %FlashOnEat** %t0
  %t41 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t40, i32 0, i32 1
  store i32 1, i32* %t41
  ret i1 true
if_else_338:
  %t42 = load %FlashOnEat*, %FlashOnEat** %t0
  %t43 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t44, 1
  br i1 %t45, label %if_then_344, label %if_else_345
if_then_344:
  %t46 = load %FlashOnEat*, %FlashOnEat** %t0
  %t47 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t46, i32 0, i32 1
  store i32 2, i32* %t47
  ret i1 false
if_else_345:
  ret i1 false
}

define i1 @GameOverFlash__resume(%GameOverFlash* %self) {
entry:
  %t0 = alloca %GameOverFlash*
  store %GameOverFlash* %self, %GameOverFlash** %t0
  %t1 = load %GameOverFlash*, %GameOverFlash** %t0
  %t2 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t1, i32 0, i32 1
  %t3 = load i32, i32* %t2
  %t4 = icmp eq i32 %t3, 0
  br i1 %t4, label %if_then_347, label %if_else_348
if_then_347:
  %t5 = load %GameOverFlash*, %GameOverFlash** %t0
  %t6 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %sdl_null_window_350, label %sdl_window_handle_ok_351
sdl_null_window_350:
  %t9 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.22, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_351:
  %t10 = call i8* @SDL_GetRenderer(i8* %t7)
  %t11 = and i32 170, 255
  %t12 = and i32 25, 255
  %t13 = shl i32 %t12, 8
  %t14 = or i32 %t11, %t13
  %t15 = and i32 25, 255
  %t16 = shl i32 %t15, 16
  %t17 = or i32 %t14, %t16
  %t18 = and i32 255, 255
  %t19 = shl i32 %t18, 24
  %t20 = or i32 %t17, %t19
  %t21 = and i32 %t20, 255
  %t22 = trunc i32 %t21 to i8
  %t23 = lshr i32 %t20, 8
  %t24 = and i32 %t23, 255
  %t25 = trunc i32 %t24 to i8
  %t26 = lshr i32 %t20, 16
  %t27 = and i32 %t26, 255
  %t28 = trunc i32 %t27 to i8
  %t29 = lshr i32 %t20, 24
  %t30 = and i32 %t29, 255
  %t31 = trunc i32 %t30 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t10, i8 %t22, i8 %t25, i8 %t28, i8 %t31)
  call i32 @SDL_RenderClear(i8* %t10)
  %t32 = load %GameOverFlash*, %GameOverFlash** %t0
  %t33 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t32, i32 0, i32 0
  %t34 = load i8*, i8** %t33
  %t35 = icmp eq i8* %t34, null
  br i1 %t35, label %sdl_null_window_352, label %sdl_window_handle_ok_353
sdl_null_window_352:
  %t36 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.23, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_353:
  %t37 = call i8* @SDL_GetRenderer(i8* %t34)
  call void @SDL_RenderPresent(i8* %t37)
  %t38 = icmp slt i32 110, 0
  %t39 = select i1 %t38, i32 0, i32 110
  call void @SDL_Delay(i32 %t39)
  %t40 = load %GameOverFlash*, %GameOverFlash** %t0
  %t41 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t40, i32 0, i32 1
  store i32 1, i32* %t41
  ret i1 true
if_else_348:
  %t42 = load %GameOverFlash*, %GameOverFlash** %t0
  %t43 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t44, 1
  br i1 %t45, label %if_then_354, label %if_else_355
if_then_354:
  %t46 = load %GameOverFlash*, %GameOverFlash** %t0
  %t47 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t46, i32 0, i32 0
  %t48 = load i8*, i8** %t47
  %t49 = icmp eq i8* %t48, null
  br i1 %t49, label %sdl_null_window_357, label %sdl_window_handle_ok_358
sdl_null_window_357:
  %t50 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.24, i64 0, i64 0
  call i32 @puts(i8* %t50)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_358:
  %t51 = call i8* @SDL_GetRenderer(i8* %t48)
  %t52 = and i32 60, 255
  %t53 = and i32 10, 255
  %t54 = shl i32 %t53, 8
  %t55 = or i32 %t52, %t54
  %t56 = and i32 10, 255
  %t57 = shl i32 %t56, 16
  %t58 = or i32 %t55, %t57
  %t59 = and i32 255, 255
  %t60 = shl i32 %t59, 24
  %t61 = or i32 %t58, %t60
  %t62 = and i32 %t61, 255
  %t63 = trunc i32 %t62 to i8
  %t64 = lshr i32 %t61, 8
  %t65 = and i32 %t64, 255
  %t66 = trunc i32 %t65 to i8
  %t67 = lshr i32 %t61, 16
  %t68 = and i32 %t67, 255
  %t69 = trunc i32 %t68 to i8
  %t70 = lshr i32 %t61, 24
  %t71 = and i32 %t70, 255
  %t72 = trunc i32 %t71 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t51, i8 %t63, i8 %t66, i8 %t69, i8 %t72)
  call i32 @SDL_RenderClear(i8* %t51)
  %t73 = load %GameOverFlash*, %GameOverFlash** %t0
  %t74 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t73, i32 0, i32 0
  %t75 = load i8*, i8** %t74
  %t76 = icmp eq i8* %t75, null
  br i1 %t76, label %sdl_null_window_359, label %sdl_window_handle_ok_360
sdl_null_window_359:
  %t77 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.25, i64 0, i64 0
  call i32 @puts(i8* %t77)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_360:
  %t78 = call i8* @SDL_GetRenderer(i8* %t75)
  call void @SDL_RenderPresent(i8* %t78)
  %t79 = icmp slt i32 110, 0
  %t80 = select i1 %t79, i32 0, i32 110
  call void @SDL_Delay(i32 %t80)
  %t81 = load %GameOverFlash*, %GameOverFlash** %t0
  %t82 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t81, i32 0, i32 1
  store i32 2, i32* %t82
  ret i1 true
if_else_355:
  %t83 = load %GameOverFlash*, %GameOverFlash** %t0
  %t84 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t83, i32 0, i32 1
  %t85 = load i32, i32* %t84
  %t86 = icmp eq i32 %t85, 2
  br i1 %t86, label %if_then_361, label %if_else_362
if_then_361:
  %t87 = load %GameOverFlash*, %GameOverFlash** %t0
  %t88 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t87, i32 0, i32 1
  store i32 3, i32* %t88
  ret i1 false
if_else_362:
  ret i1 false
}

define void @demo_genref_staleness() {
entry:
  %t19 = alloca %ScratchSlot
  %t28 = alloca %GenRef
  %t34 = alloca %GenRef
  %t67 = alloca %ScratchSlot
  %t76 = alloca %GenRef
  %t82 = alloca %GenRef
  %t100 = alloca %ScratchSlot
  %t119 = alloca %ScratchSlot
  %t0 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t1 = icmp eq %ScratchSlot* %t0, null
  br i1 %t1, label %spawn_init_364, label %spawn_ready_365
spawn_init_364:
  %t2 = getelementptr %ScratchSlot, %ScratchSlot* null, i32 1
  %t3 = ptrtoint %ScratchSlot* %t2 to i64
  %t4 = mul i64 %t3, 1024
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to %ScratchSlot*
  store %ScratchSlot* %t6, %ScratchSlot** @arena.Scratch.data
  br label %spawn_ready_365
spawn_ready_365:
  %t7 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t8 = load i64, i64* @arena.Scratch.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_366, label %spawn_grow_367
spawn_reuse_366:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Scratch.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_368
spawn_grow_367:
  %t13 = load i64, i64* @arena.Scratch.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_370, label %spawn_capacity_warn_371
spawn_capacity_warn_371:
  %t15 = load i1, i1* @arena.Scratch.warned
  br i1 %t15, label %spawn_end_369, label %spawn_warn_print_372
spawn_warn_print_372:
  store i1 1, i1* @arena.Scratch.warned
  %t16 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.26, i64 0, i64 0
  call i32 @puts(i8* %t16)
  br label %spawn_end_369
spawn_grow_ok_370:
  %t17 = add i64 %t13, 1
  store i64 %t17, i64* @arena.Scratch.count
  br label %spawn_store_368
spawn_store_368:
  %t18 = phi i64 [ %t12, %spawn_reuse_366 ], [ %t13, %spawn_grow_ok_370 ]
  %t20 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t19, i32 0, i32 0
  store i32 111, i32* %t20
  %t21 = load %ScratchSlot, %ScratchSlot* %t19
  %t22 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t7, i64 %t18
  store %ScratchSlot %t21, %ScratchSlot* %t22
  %t23 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t18
  %t24 = load i64, i64* %t23
  %t25 = add i64 %t24, 1
  store i64 %t25, i64* %t23
  %t26 = trunc i64 %t18 to i32
  br label %spawn_end_369
spawn_end_369:
  %t27 = phi i32 [ %t26, %spawn_store_368 ], [ -1, %spawn_capacity_warn_371 ], [ -1, %spawn_warn_print_372 ]
  %t29 = sext i32 0 to i64
  %t30 = icmp ult i64 %t29, 1024
  br i1 %t30, label %genref_create_ok_373, label %genref_create_oob_374
genref_create_ok_373:
  %t31 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t29
  %t32 = load i64, i64* %t31
  br label %genref_create_end_375
genref_create_oob_374:
  br label %genref_create_end_375
genref_create_end_375:
  %t33 = phi i64 [ %t32, %genref_create_ok_373 ], [ 0, %genref_create_oob_374 ]
  %t35 = getelementptr inbounds %GenRef, %GenRef* %t34, i32 0, i32 0
  store i32 0, i32* %t35
  %t36 = getelementptr inbounds %GenRef, %GenRef* %t34, i32 0, i32 1
  store i64 %t33, i64* %t36
  %t37 = load %GenRef, %GenRef* %t34
  store %GenRef %t37, %GenRef* %t28
  %t38 = sext i32 0 to i64
  %t39 = icmp ult i64 %t38, 1024
  br i1 %t39, label %despawn_do_376, label %despawn_end_377
despawn_do_376:
  %t40 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t38
  %t41 = load i64, i64* %t40
  %t42 = and i64 %t41, 1
  %t43 = icmp eq i64 %t42, 1
  br i1 %t43, label %despawn_live_378, label %despawn_end_377
despawn_live_378:
  %t44 = add i64 %t41, 1
  store i64 %t44, i64* %t40
  %t45 = load i64, i64* @arena.Scratch.free_top
  %t46 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t45
  store i64 %t38, i64* %t46
  %t47 = add i64 %t45, 1
  store i64 %t47, i64* @arena.Scratch.free_top
  br label %despawn_end_377
despawn_end_377:
  %t48 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t49 = icmp eq %ScratchSlot* %t48, null
  br i1 %t49, label %spawn_init_379, label %spawn_ready_380
spawn_init_379:
  %t50 = getelementptr %ScratchSlot, %ScratchSlot* null, i32 1
  %t51 = ptrtoint %ScratchSlot* %t50 to i64
  %t52 = mul i64 %t51, 1024
  %t53 = call i8* @malloc(i64 %t52)
  %t54 = bitcast i8* %t53 to %ScratchSlot*
  store %ScratchSlot* %t54, %ScratchSlot** @arena.Scratch.data
  br label %spawn_ready_380
spawn_ready_380:
  %t55 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t56 = load i64, i64* @arena.Scratch.free_top
  %t57 = icmp sgt i64 %t56, 0
  br i1 %t57, label %spawn_reuse_381, label %spawn_grow_382
spawn_reuse_381:
  %t58 = sub i64 %t56, 1
  store i64 %t58, i64* @arena.Scratch.free_top
  %t59 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t58
  %t60 = load i64, i64* %t59
  br label %spawn_store_383
spawn_grow_382:
  %t61 = load i64, i64* @arena.Scratch.count
  %t62 = icmp slt i64 %t61, 1024
  br i1 %t62, label %spawn_grow_ok_385, label %spawn_capacity_warn_386
spawn_capacity_warn_386:
  %t63 = load i1, i1* @arena.Scratch.warned
  br i1 %t63, label %spawn_end_384, label %spawn_warn_print_387
spawn_warn_print_387:
  store i1 1, i1* @arena.Scratch.warned
  %t64 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.27, i64 0, i64 0
  call i32 @puts(i8* %t64)
  br label %spawn_end_384
spawn_grow_ok_385:
  %t65 = add i64 %t61, 1
  store i64 %t65, i64* @arena.Scratch.count
  br label %spawn_store_383
spawn_store_383:
  %t66 = phi i64 [ %t60, %spawn_reuse_381 ], [ %t61, %spawn_grow_ok_385 ]
  %t68 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t67, i32 0, i32 0
  store i32 222, i32* %t68
  %t69 = load %ScratchSlot, %ScratchSlot* %t67
  %t70 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t55, i64 %t66
  store %ScratchSlot %t69, %ScratchSlot* %t70
  %t71 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t66
  %t72 = load i64, i64* %t71
  %t73 = add i64 %t72, 1
  store i64 %t73, i64* %t71
  %t74 = trunc i64 %t66 to i32
  br label %spawn_end_384
spawn_end_384:
  %t75 = phi i32 [ %t74, %spawn_store_383 ], [ -1, %spawn_capacity_warn_386 ], [ -1, %spawn_warn_print_387 ]
  %t77 = sext i32 0 to i64
  %t78 = icmp ult i64 %t77, 1024
  br i1 %t78, label %genref_create_ok_388, label %genref_create_oob_389
genref_create_ok_388:
  %t79 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t77
  %t80 = load i64, i64* %t79
  br label %genref_create_end_390
genref_create_oob_389:
  br label %genref_create_end_390
genref_create_end_390:
  %t81 = phi i64 [ %t80, %genref_create_ok_388 ], [ 0, %genref_create_oob_389 ]
  %t83 = getelementptr inbounds %GenRef, %GenRef* %t82, i32 0, i32 0
  store i32 0, i32* %t83
  %t84 = getelementptr inbounds %GenRef, %GenRef* %t82, i32 0, i32 1
  store i64 %t81, i64* %t84
  %t85 = load %GenRef, %GenRef* %t82
  store %GenRef %t85, %GenRef* %t76
  %t86 = getelementptr inbounds %GenRef, %GenRef* %t28, i32 0, i32 0
  %t87 = load i32, i32* %t86
  %t88 = getelementptr inbounds %GenRef, %GenRef* %t28, i32 0, i32 1
  %t89 = load i64, i64* %t88
  %t90 = sext i32 %t87 to i64
  %t91 = icmp ult i64 %t90, 1024
  br i1 %t91, label %genref_place_check_391, label %genref_place_stale_393
genref_place_check_391:
  %t92 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t90
  %t93 = load i64, i64* %t92
  %t94 = icmp eq i64 %t89, %t93
  %t95 = and i64 %t93, 1
  %t96 = icmp eq i64 %t95, 1
  %t97 = and i1 %t94, %t96
  br i1 %t97, label %genref_place_ok_392, label %genref_place_stale_393
genref_place_ok_392:
  %t98 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t99 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t98, i64 %t90
  br label %genref_place_end_394
genref_place_stale_393:
  store %ScratchSlot zeroinitializer, %ScratchSlot* %t100
  br label %genref_place_end_394
genref_place_end_394:
  %t101 = phi %ScratchSlot* [ %t99, %genref_place_ok_392 ], [ %t100, %genref_place_stale_393 ]
  %t102 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t101, i32 0, i32 0
  %t103 = load i32, i32* %t102
  %t104 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t104, i32 %t103)
  %t105 = getelementptr inbounds %GenRef, %GenRef* %t76, i32 0, i32 0
  %t106 = load i32, i32* %t105
  %t107 = getelementptr inbounds %GenRef, %GenRef* %t76, i32 0, i32 1
  %t108 = load i64, i64* %t107
  %t109 = sext i32 %t106 to i64
  %t110 = icmp ult i64 %t109, 1024
  br i1 %t110, label %genref_place_check_395, label %genref_place_stale_397
genref_place_check_395:
  %t111 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t109
  %t112 = load i64, i64* %t111
  %t113 = icmp eq i64 %t108, %t112
  %t114 = and i64 %t112, 1
  %t115 = icmp eq i64 %t114, 1
  %t116 = and i1 %t113, %t115
  br i1 %t116, label %genref_place_ok_396, label %genref_place_stale_397
genref_place_ok_396:
  %t117 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t118 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t117, i64 %t109
  br label %genref_place_end_398
genref_place_stale_397:
  store %ScratchSlot zeroinitializer, %ScratchSlot* %t119
  br label %genref_place_end_398
genref_place_end_398:
  %t120 = phi %ScratchSlot* [ %t118, %genref_place_ok_396 ], [ %t119, %genref_place_stale_397 ]
  %t121 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t120, i32 0, i32 0
  %t122 = load i32, i32* %t121
  %t123 = getelementptr inbounds [51 x i8], [51 x i8]* @.str.29, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t123, i32 %t122)
  ret void
}

define { i32, i32 } @cell_px(%food__sb__grid__Cell %c) {
entry:
  %t0 = alloca %food__sb__grid__Cell
  %t1 = alloca { i32, i32 }
  store %food__sb__grid__Cell %c, %food__sb__grid__Cell* %t0
  %t2 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = mul i32 %t3, 20
  %t5 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 0
  store i32 %t4, i32* %t5
  %t6 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 1
  %t7 = load i32, i32* %t6
  %t8 = mul i32 %t7, 20
  %t9 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 1
  store i32 %t8, i32* %t9
  %t10 = load { i32, i32 }, { i32, i32 }* %t1
  ret { i32, i32 } %t10
}

define void @draw_cell(i8* %w, %food__sb__grid__Cell %c, i32 %color) {
entry:
  %t0 = alloca i8*
  %t1 = alloca %food__sb__grid__Cell
  %t2 = alloca i32
  %t3 = alloca { i32, i32 }
  %t28 = alloca [16 x i8]
  store i8* %w, i8** %t0
  store %food__sb__grid__Cell %c, %food__sb__grid__Cell* %t1
  store i32 %color, i32* %t2
  %t4 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t1
  %t5 = call { i32, i32 } @cell_px(%food__sb__grid__Cell %t4)
  store { i32, i32 } %t5, { i32, i32 }* %t3
  %t6 = load i8*, i8** %t0
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %sdl_null_window_399, label %sdl_window_handle_ok_400
sdl_null_window_399:
  %t8 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.30, i64 0, i64 0
  call i32 @puts(i8* %t8)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_400:
  %t9 = call i8* @SDL_GetRenderer(i8* %t6)
  %t10 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3, i32 0, i32 0
  %t11 = load i32, i32* %t10
  %t12 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3, i32 0, i32 1
  %t13 = load i32, i32* %t12
  %t14 = sub i32 20, 1
  %t15 = sub i32 20, 1
  %t16 = load i32, i32* %t2
  %t17 = and i32 %t16, 255
  %t18 = trunc i32 %t17 to i8
  %t19 = lshr i32 %t16, 8
  %t20 = and i32 %t19, 255
  %t21 = trunc i32 %t20 to i8
  %t22 = lshr i32 %t16, 16
  %t23 = and i32 %t22, 255
  %t24 = trunc i32 %t23 to i8
  %t25 = lshr i32 %t16, 24
  %t26 = and i32 %t25, 255
  %t27 = trunc i32 %t26 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t9, i8 %t18, i8 %t21, i8 %t24, i8 %t27)
  %t29 = getelementptr inbounds [16 x i8], [16 x i8]* %t28, i64 0, i64 0
  %t30 = bitcast i8* %t29 to i32*
  store i32 %t11, i32* %t30
  %t31 = getelementptr inbounds i8, i8* %t29, i64 4
  %t32 = bitcast i8* %t31 to i32*
  store i32 %t13, i32* %t32
  %t33 = getelementptr inbounds i8, i8* %t29, i64 8
  %t34 = bitcast i8* %t33 to i32*
  store i32 %t14, i32* %t34
  %t35 = getelementptr inbounds i8, i8* %t29, i64 12
  %t36 = bitcast i8* %t35 to i32*
  store i32 %t15, i32* %t36
  call i32 @SDL_RenderFillRect(i8* %t9, i8* %t29)
  ret void
}

define i32 @frame_demo() {
entry:
  %t10 = alloca %food__sb__grid__Cell
  %t23 = alloca %food__sb__grid__Cell
  %t0 = load i64, i64* @frame.off
  %t1 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t2 = ptrtoint %food__sb__grid__Cell* %t1 to i64
  %t3 = load i64, i64* @frame.off
  %t4 = add i64 %t3, %t2
  %t5 = icmp ugt i64 %t4, 4096
  br i1 %t5, label %frame_alloc_fail_401, label %frame_alloc_ok_402
frame_alloc_fail_401:
  %t6 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.31, i64 0, i64 0
  call i32 @puts(i8* %t6)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_402:
  store i64 %t4, i64* @frame.off
  %t7 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t8 = getelementptr inbounds i8, i8* %t7, i64 %t3
  %t9 = bitcast i8* %t8 to %food__sb__grid__Cell*
  %t11 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t10, i32 0, i32 0
  store i32 3, i32* %t11
  %t12 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t10, i32 0, i32 1
  store i32 4, i32* %t12
  %t13 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t10
  store %food__sb__grid__Cell %t13, %food__sb__grid__Cell* %t9
  %t14 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t15 = ptrtoint %food__sb__grid__Cell* %t14 to i64
  %t16 = load i64, i64* @frame.off
  %t17 = add i64 %t16, %t15
  %t18 = icmp ugt i64 %t17, 4096
  br i1 %t18, label %frame_alloc_fail_403, label %frame_alloc_ok_404
frame_alloc_fail_403:
  %t19 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.32, i64 0, i64 0
  call i32 @puts(i8* %t19)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_404:
  store i64 %t17, i64* @frame.off
  %t20 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t21 = getelementptr inbounds i8, i8* %t20, i64 %t16
  %t22 = bitcast i8* %t21 to %food__sb__grid__Cell*
  %t24 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t23, i32 0, i32 0
  store i32 10, i32* %t24
  %t25 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t23, i32 0, i32 1
  store i32 20, i32* %t25
  %t26 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t23
  store %food__sb__grid__Cell %t26, %food__sb__grid__Cell* %t22
  %t27 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t9, i32 0, i32 0
  %t28 = load i32, i32* %t27
  %t29 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t22, i32 0, i32 1
  %t30 = load i32, i32* %t29
  %t31 = add i32 %t28, %t30
  store i64 %t0, i64* @frame.off
  ret i32 %t31
}

define i32 @pick_color(i1 %cond, i32 %a, i32 %b) {
entry:
  %t0 = alloca i1
  %t1 = alloca i32
  %t2 = alloca i32
  %t3 = alloca i32
  store i1 %cond, i1* %t0
  store i32 %a, i32* %t1
  store i32 %b, i32* %t2
  %t4 = load i1, i1* %t0
  br i1 %t4, label %if_then_405, label %if_else_406
if_then_405:
  %t5 = load i32, i32* %t1
  br label %if_end_407
if_else_406:
  %t6 = load i32, i32* %t2
  br label %if_end_407
if_end_407:
  %t7 = phi i32 [ %t5, %if_then_405 ], [ %t6, %if_else_406 ]
  store i32 %t7, i32* %t3
  %t8 = load i32, i32* %t3
  ret i32 %t8
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i32
  %t4 = alloca i32
  %t6 = alloca i8*
  %t23 = alloca i8*
  %t25 = alloca { i32, i8* }
  %t29 = alloca %Stats
  %t30 = alloca %Stats
  %t47 = alloca %food__sb__Snake
  %t49 = alloca %food__sb__grid__Cell
  %t54 = alloca i64
  %t55 = alloca i8
  %t56 = alloca i8*
  %t57 = alloca i8
  %t59 = alloca [5 x i32]
  %t60 = alloca [5 x i32]
  %t62 = alloca i64
  %t68 = alloca %ParticlePool
  %t69 = alloca %ParticlePool
  %t70 = alloca [32 x %Particle]
  %t71 = alloca %Particle
  %t79 = alloca i64
  %t87 = alloca i32
  %t89 = alloca i1
  %t90 = alloca i1
  %t91 = alloca i1
  %t92 = alloca i1
  %t93 = alloca i32
  %t94 = alloca i32
  %t95 = alloca i32
  %t96 = alloca i32
  %t97 = alloca i32
  %t98 = alloca i32
  %t99 = alloca i32
  %t100 = alloca i32
  %t101 = alloca i32
  %t102 = alloca i32
  %t103 = alloca i32
  %t104 = alloca i32
  %t105 = alloca i32
  %t109 = alloca i1
  %t110 = alloca [56 x i8]
  %t128 = alloca i1
  %t158 = alloca i1
  %t191 = alloca i1
  %t312 = alloca i32
  %t326 = alloca i32
  %t341 = alloca i32
  %t344 = alloca %food__sb__grid__Cell
  %t394 = alloca i64
  %t492 = alloca i64
  %t535 = alloca { i32, i32 }
  %t538 = alloca float
  %t550 = alloca float
  %t584 = alloca %Particle
  %t599 = alloca %FlashOnEat
  %t600 = alloca %FlashOnEat
  %t605 = alloca i1
  %t630 = alloca i32
  %t711 = alloca i64
  %t796 = alloca i32
  %t808 = alloca i32
  %t824 = alloca i32
  %t836 = alloca i32
  %t842 = alloca i32
  %t848 = alloca i32
  %t854 = alloca i32
  %t860 = alloca i32
  %t864 = alloca %GameOverFlash
  %t865 = alloca %GameOverFlash
  %t870 = alloca i1
  %t876 = alloca float
  %t879 = alloca float
  %t909 = alloca { i32, i32 }
  %t912 = alloca i32
  %t956 = alloca [16 x i8]
  %t965 = alloca i32
  %t969 = alloca i1
  %t989 = alloca %food__sb__grid__Cell
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = mul i32 32, 20
  store i32 %t3, i32* %t2
  %t5 = mul i32 24, 20
  store i32 %t5, i32* %t4
  %t7 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.33, i64 0, i32 2, i64 0
  %t8 = load i32, i32* %t2
  %t9 = load i32, i32* %t4
  %t10 = call i32 @SDL_Init(i32 32)
  %t11 = icmp ne i32 %t10, 0
  br i1 %t11, label %sdl_init_fail_408, label %sdl_init_ok_409
sdl_init_fail_408:
  call void @star_rc_release(i8* %t7)
  br label %window_create_end_410
sdl_init_ok_409:
  %t12 = call i8* @SDL_CreateWindow(i8* %t7, i32 536805376, i32 536805376, i32 %t8, i32 %t9, i32 0)
  call void @star_rc_release(i8* %t7)
  %t13 = icmp eq i8* %t12, null
  br i1 %t13, label %sdl_window_fail_411, label %sdl_window_ok_412
sdl_window_fail_411:
  br label %window_create_end_410
sdl_window_ok_412:
  %t14 = call i8* @SDL_CreateRenderer(i8* %t12, i32 -1, i32 0)
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %sdl_renderer_fail_413, label %sdl_renderer_ok_414
sdl_renderer_fail_413:
  call void @SDL_DestroyWindow(i8* %t12)
  br label %window_create_end_410
sdl_renderer_ok_414:
  br label %window_create_end_410
window_create_end_410:
  %t16 = phi i8* [ null, %sdl_init_fail_408 ], [ null, %sdl_window_fail_411 ], [ null, %sdl_renderer_fail_413 ], [ %t12, %sdl_renderer_ok_414 ]
  store i8* %t16, i8** %t6
  %t17 = load i8*, i8** %t6
  %t18 = icmp eq i8* %t17, null
  br i1 %t18, label %if_then_415, label %if_else_416
if_then_415:
  %t19 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.34, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t19)
  call i32 (i8*, ...) @printf(i8* %t19)
  %t20 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.35, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t20)
  ret i32 0
if_else_416:
  br label %if_end_417
if_end_417:
  call void @demo_genref_staleness()
  %t21 = call i32 @frame_demo()
  %t22 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.36, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t22, i32 %t21)
  %t24 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.37, i64 0, i32 2, i64 0
  store i8* %t24, i8** %t23
  %t26 = load i8*, i8** %t23
  %t27 = load i8*, i8** %t23
  call void @star_rc_retain(i8* %t27)
  %t28 = call { i32, i8* } @save__load_high_score(i8* %t26)
  store { i32, i8* } %t28, { i32, i8* }* %t25
  %t31 = getelementptr inbounds %Stats, %Stats* %t30, i32 0, i32 0
  store i32 0, i32* %t31
  %t32 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t25, i32 0, i32 0
  %t33 = load i32, i32* %t32
  %t34 = getelementptr inbounds %Stats, %Stats* %t30, i32 0, i32 1
  store i32 %t33, i32* %t34
  %t35 = getelementptr inbounds %Stats, %Stats* %t30, i32 0, i32 2
  store i32 120, i32* %t35
  %t36 = load %Stats, %Stats* %t30
  store %Stats %t36, %Stats* %t29
  %t37 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 1
  %t38 = load i32, i32* %t37
  %t39 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t25, i32 0, i32 1
  %t40 = load i8*, i8** %t39
  %t41 = load i8*, i8** %t39
  call void @star_rc_retain(i8* %t41)
  call void @star_rc_release(i8* %t40)
  %t42 = getelementptr inbounds [50 x i8], [50 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t42, i32 %t38, i8* %t40)
  %t43 = call i32 @SDL_GetTicks()
  %t44 = icmp eq i32 %t43, 0
  %t45 = select i1 %t44, i32 1, i32 %t43
  %t46 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t46, i32 -1)
  store i32 %t45, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t46, i32 1, i32* null)
  %t48 = call %food__sb__Snake @food__sb__make_snake()
  store %food__sb__Snake %t48, %food__sb__Snake* %t47
  %t50 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t47, i32 0, i32 0
  %t51 = load { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t50
  %t52 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t47)
  %t53 = call %food__sb__grid__Cell @food__spawn_food({ [768 x %food__sb__grid__Cell], i64, i64 } %t51, i32 %t52)
  store %food__sb__grid__Cell %t53, %food__sb__grid__Cell* %t49
  store i64 0, i64* %t54
  store i8 0, i8* %t55
  store i8* null, i8** %t56
  %t58 = trunc i32 0 to i8
  store i8 %t58, i8* %t57
  %t61 = getelementptr inbounds [5 x i32], [5 x i32]* %t60, i32 0, i64 0
  store i32 0, i32* %t61
  store i64 1, i64* %t62
  br label %arr_rep_cond_418
arr_rep_cond_418:
  %t63 = load i64, i64* %t62
  %t64 = icmp ult i64 %t63, 5
  br i1 %t64, label %arr_rep_body_419, label %arr_rep_end_420
arr_rep_body_419:
  %t65 = getelementptr inbounds [5 x i32], [5 x i32]* %t60, i32 0, i64 %t63
  store i32 0, i32* %t65
  %t66 = add i64 %t63, 1
  store i64 %t66, i64* %t62
  br label %arr_rep_cond_418
arr_rep_end_420:
  %t67 = load [5 x i32], [5 x i32]* %t60
  store [5 x i32] %t67, [5 x i32]* %t59
  %t72 = getelementptr inbounds %Particle, %Particle* %t71, i32 0, i32 0
  store float 0x0000000000000000, float* %t72
  %t73 = getelementptr inbounds %Particle, %Particle* %t71, i32 0, i32 1
  store float 0x0000000000000000, float* %t73
  %t74 = getelementptr inbounds %Particle, %Particle* %t71, i32 0, i32 2
  store float 0x0000000000000000, float* %t74
  %t75 = getelementptr inbounds %Particle, %Particle* %t71, i32 0, i32 3
  store float 0x0000000000000000, float* %t75
  %t76 = getelementptr inbounds %Particle, %Particle* %t71, i32 0, i32 4
  store float 0x0000000000000000, float* %t76
  %t77 = load %Particle, %Particle* %t71
  %t78 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t70, i32 0, i64 0
  store %Particle %t77, %Particle* %t78
  store i64 1, i64* %t79
  br label %arr_rep_cond_421
arr_rep_cond_421:
  %t80 = load i64, i64* %t79
  %t81 = icmp ult i64 %t80, 32
  br i1 %t81, label %arr_rep_body_422, label %arr_rep_end_423
arr_rep_body_422:
  %t82 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t70, i32 0, i64 %t80
  store %Particle %t77, %Particle* %t82
  %t83 = add i64 %t80, 1
  store i64 %t83, i64* %t79
  br label %arr_rep_cond_421
arr_rep_end_423:
  %t84 = load [32 x %Particle], [32 x %Particle]* %t70
  %t85 = getelementptr inbounds %ParticlePool, %ParticlePool* %t69, i32 0, i32 0
  store [32 x %Particle] %t84, [32 x %Particle]* %t85
  %t86 = load %ParticlePool, %ParticlePool* %t69
  store %ParticlePool %t86, %ParticlePool* %t68
  %t88 = call i32 @SDL_GetTicks()
  store i32 %t88, i32* %t87
  store i1 false, i1* %t89
  store i1 false, i1* %t90
  store i1 false, i1* %t91
  store i1 false, i1* %t92
  store i32 41, i32* %t93
  store i32 19, i32* %t94
  store i32 58, i32* %t95
  store i32 21, i32* %t96
  store i32 225, i32* %t97
  store i32 82, i32* %t98
  store i32 81, i32* %t99
  store i32 80, i32* %t100
  store i32 79, i32* %t101
  store i32 26, i32* %t102
  store i32 22, i32* %t103
  store i32 4, i32* %t104
  store i32 7, i32* %t105
  br label %while_cond_424
while_cond_424:
  br i1 true, label %while_body_425, label %while_else_426
while_body_425:
  %t106 = load i8*, i8** %t6
  %t107 = icmp eq i8* %t106, null
  br i1 %t107, label %sdl_null_window_428, label %sdl_window_handle_ok_429
sdl_null_window_428:
  %t108 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.39, i64 0, i64 0
  call i32 @puts(i8* %t108)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_429:
  store i1 false, i1* %t109
  %t111 = getelementptr inbounds [56 x i8], [56 x i8]* %t110, i64 0, i64 0
  br label %sdl_poll_cond_430
sdl_poll_cond_430:
  %t112 = call i32 @SDL_PollEvent(i8* %t111)
  %t113 = icmp ne i32 %t112, 0
  br i1 %t113, label %sdl_poll_body_431, label %sdl_poll_end_433
sdl_poll_body_431:
  %t114 = bitcast i8* %t111 to i32*
  %t115 = load i32, i32* %t114
  %t116 = icmp eq i32 %t115, 256
  br i1 %t116, label %sdl_poll_set_quit_432, label %sdl_poll_cond_430
sdl_poll_set_quit_432:
  store i1 true, i1* %t109
  br label %sdl_poll_cond_430
sdl_poll_end_433:
  %t117 = load i1, i1* %t109
  br i1 %t117, label %if_then_434, label %if_else_435
if_then_434:
  br label %while_end_427
if_else_435:
  br label %if_end_436
if_end_436:
  %t118 = load i32, i32* %t93
  %t119 = icmp sge i32 %t118, 0
  %t120 = icmp slt i32 %t118, 512
  %t121 = and i1 %t119, %t120
  br i1 %t121, label %key_down_read_437, label %key_down_end_438
key_down_read_437:
  %t122 = call i8* @SDL_GetKeyboardState(i32* null)
  %t123 = sext i32 %t118 to i64
  %t124 = getelementptr inbounds i8, i8* %t122, i64 %t123
  %t125 = load i8, i8* %t124
  %t126 = icmp ne i8 %t125, 0
  br label %key_down_end_438
key_down_end_438:
  %t127 = phi i1 [ false, %if_end_436 ], [ %t126, %key_down_read_437 ]
  br i1 %t127, label %if_then_439, label %if_else_440
if_then_439:
  br label %while_end_427
if_else_440:
  br label %if_end_441
if_end_441:
  %t129 = load i32, i32* %t94
  %t130 = icmp sge i32 %t129, 0
  %t131 = icmp slt i32 %t129, 512
  %t132 = and i1 %t130, %t131
  br i1 %t132, label %key_down_read_442, label %key_down_end_443
key_down_read_442:
  %t133 = call i8* @SDL_GetKeyboardState(i32* null)
  %t134 = sext i32 %t129 to i64
  %t135 = getelementptr inbounds i8, i8* %t133, i64 %t134
  %t136 = load i8, i8* %t135
  %t137 = icmp ne i8 %t136, 0
  br label %key_down_end_443
key_down_end_443:
  %t138 = phi i1 [ false, %if_end_441 ], [ %t137, %key_down_read_442 ]
  store i1 %t138, i1* %t128
  %t139 = load i1, i1* %t128
  br i1 %t139, label %logic_rhs_444, label %logic_short_445
logic_rhs_444:
  %t140 = load i1, i1* %t89
  %t141 = xor i1 true, %t140
  br label %logic_end_446
logic_short_445:
  br label %logic_end_446
logic_end_446:
  %t142 = phi i1 [ %t141, %logic_rhs_444 ], [ false, %logic_short_445 ]
  br i1 %t142, label %if_then_447, label %if_else_448
if_then_447:
  %t143 = load i64, i64* %t54
  %t144 = zext i32 0 to i64
  %t145 = shl i64 1, %t144
  %t146 = and i64 %t143, %t145
  %t147 = icmp ne i64 %t146, 0
  br i1 %t147, label %if_then_450, label %if_else_451
if_then_450:
  %t148 = load i64, i64* %t54
  %t149 = zext i32 0 to i64
  %t150 = shl i64 1, %t149
  %t152 = xor i64 %t150, -1
  %t151 = and i64 %t148, %t152
  store i64 %t151, i64* %t54
  br label %if_end_452
if_else_451:
  %t153 = load i64, i64* %t54
  %t154 = zext i32 0 to i64
  %t155 = shl i64 1, %t154
  %t156 = or i64 %t153, %t155
  store i64 %t156, i64* %t54
  br label %if_end_452
if_end_452:
  br label %if_end_449
if_else_448:
  br label %if_end_449
if_end_449:
  %t157 = load i1, i1* %t128
  store i1 %t157, i1* %t89
  %t159 = load i32, i32* %t95
  %t160 = icmp sge i32 %t159, 0
  %t161 = icmp slt i32 %t159, 512
  %t162 = and i1 %t160, %t161
  br i1 %t162, label %key_down_read_453, label %key_down_end_454
key_down_read_453:
  %t163 = call i8* @SDL_GetKeyboardState(i32* null)
  %t164 = sext i32 %t159 to i64
  %t165 = getelementptr inbounds i8, i8* %t163, i64 %t164
  %t166 = load i8, i8* %t165
  %t167 = icmp ne i8 %t166, 0
  br label %key_down_end_454
key_down_end_454:
  %t168 = phi i1 [ false, %if_end_449 ], [ %t167, %key_down_read_453 ]
  store i1 %t168, i1* %t158
  %t169 = load i1, i1* %t158
  br i1 %t169, label %logic_rhs_455, label %logic_short_456
logic_rhs_455:
  %t170 = load i1, i1* %t90
  %t171 = xor i1 true, %t170
  br label %logic_end_457
logic_short_456:
  br label %logic_end_457
logic_end_457:
  %t172 = phi i1 [ %t171, %logic_rhs_455 ], [ false, %logic_short_456 ]
  br i1 %t172, label %if_then_458, label %if_else_459
if_then_458:
  %t173 = load i64, i64* %t54
  %t174 = zext i32 1 to i64
  %t175 = shl i64 1, %t174
  %t176 = and i64 %t173, %t175
  %t177 = icmp ne i64 %t176, 0
  br i1 %t177, label %if_then_461, label %if_else_462
if_then_461:
  %t178 = load i64, i64* %t54
  %t179 = zext i32 1 to i64
  %t180 = shl i64 1, %t179
  %t182 = xor i64 %t180, -1
  %t181 = and i64 %t178, %t182
  store i64 %t181, i64* %t54
  br label %if_end_463
if_else_462:
  %t183 = load i64, i64* %t54
  %t184 = zext i32 1 to i64
  %t185 = shl i64 1, %t184
  %t186 = or i64 %t183, %t185
  store i64 %t186, i64* %t54
  call void @dump_particle_arena()
  br label %if_end_463
if_end_463:
  br label %if_end_460
if_else_459:
  br label %if_end_460
if_end_460:
  %t187 = load i1, i1* %t158
  store i1 %t187, i1* %t90
  %t188 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t47, i32 0, i32 4
  %t189 = load i1, i1* %t188
  %t190 = xor i1 true, %t189
  br i1 %t190, label %if_then_464, label %if_else_465
if_then_464:
  %t192 = load i32, i32* %t96
  %t193 = icmp sge i32 %t192, 0
  %t194 = icmp slt i32 %t192, 512
  %t195 = and i1 %t193, %t194
  br i1 %t195, label %key_down_read_467, label %key_down_end_468
key_down_read_467:
  %t196 = call i8* @SDL_GetKeyboardState(i32* null)
  %t197 = sext i32 %t192 to i64
  %t198 = getelementptr inbounds i8, i8* %t196, i64 %t197
  %t199 = load i8, i8* %t198
  %t200 = icmp ne i8 %t199, 0
  br label %key_down_end_468
key_down_end_468:
  %t201 = phi i1 [ false, %if_then_464 ], [ %t200, %key_down_read_467 ]
  store i1 %t201, i1* %t191
  %t202 = load i1, i1* %t191
  br i1 %t202, label %logic_rhs_469, label %logic_short_470
logic_rhs_469:
  %t203 = load i1, i1* %t91
  %t204 = xor i1 true, %t203
  br label %logic_end_471
logic_short_470:
  br label %logic_end_471
logic_end_471:
  %t205 = phi i1 [ %t204, %logic_rhs_469 ], [ false, %logic_short_470 ]
  br i1 %t205, label %if_then_472, label %if_else_473
if_then_472:
  %t206 = call %food__sb__Snake @food__sb__make_snake()
  store %food__sb__Snake %t206, %food__sb__Snake* %t47
  %t207 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t47, i32 0, i32 0
  %t208 = load { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t207
  %t209 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t47)
  %t210 = call %food__sb__grid__Cell @food__spawn_food({ [768 x %food__sb__grid__Cell], i64, i64 } %t208, i32 %t209)
  store %food__sb__grid__Cell %t210, %food__sb__grid__Cell* %t49
  %t211 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  store i32 0, i32* %t211
  %t212 = load i8*, i8** %t56
  call void @star_rc_release(i8* %t212)
  store i8* null, i8** %t56
  br label %if_end_474
if_else_473:
  br label %if_end_474
if_end_474:
  %t213 = load i1, i1* %t191
  store i1 %t213, i1* %t91
  br label %if_end_466
if_else_465:
  %t214 = load i32, i32* %t98
  %t215 = icmp sge i32 %t214, 0
  %t216 = icmp slt i32 %t214, 512
  %t217 = and i1 %t215, %t216
  br i1 %t217, label %key_down_read_475, label %key_down_end_476
key_down_read_475:
  %t218 = call i8* @SDL_GetKeyboardState(i32* null)
  %t219 = sext i32 %t214 to i64
  %t220 = getelementptr inbounds i8, i8* %t218, i64 %t219
  %t221 = load i8, i8* %t220
  %t222 = icmp ne i8 %t221, 0
  br label %key_down_end_476
key_down_end_476:
  %t223 = phi i1 [ false, %if_else_465 ], [ %t222, %key_down_read_475 ]
  br i1 %t223, label %logic_short_478, label %logic_rhs_477
logic_rhs_477:
  %t224 = load i32, i32* %t102
  %t225 = icmp sge i32 %t224, 0
  %t226 = icmp slt i32 %t224, 512
  %t227 = and i1 %t225, %t226
  br i1 %t227, label %key_down_read_480, label %key_down_end_481
key_down_read_480:
  %t228 = call i8* @SDL_GetKeyboardState(i32* null)
  %t229 = sext i32 %t224 to i64
  %t230 = getelementptr inbounds i8, i8* %t228, i64 %t229
  %t231 = load i8, i8* %t230
  %t232 = icmp ne i8 %t231, 0
  br label %key_down_end_481
key_down_end_481:
  %t233 = phi i1 [ false, %logic_rhs_477 ], [ %t232, %key_down_read_480 ]
  br label %logic_end_479
logic_short_478:
  br label %logic_end_479
logic_end_479:
  %t234 = phi i1 [ %t233, %key_down_end_481 ], [ true, %logic_short_478 ]
  br i1 %t234, label %if_then_482, label %if_else_483
if_then_482:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t47, i32 0)
  br label %if_end_484
if_else_483:
  br label %if_end_484
if_end_484:
  %t236 = load i32, i32* %t99
  %t237 = icmp sge i32 %t236, 0
  %t238 = icmp slt i32 %t236, 512
  %t239 = and i1 %t237, %t238
  br i1 %t239, label %key_down_read_485, label %key_down_end_486
key_down_read_485:
  %t240 = call i8* @SDL_GetKeyboardState(i32* null)
  %t241 = sext i32 %t236 to i64
  %t242 = getelementptr inbounds i8, i8* %t240, i64 %t241
  %t243 = load i8, i8* %t242
  %t244 = icmp ne i8 %t243, 0
  br label %key_down_end_486
key_down_end_486:
  %t245 = phi i1 [ false, %if_end_484 ], [ %t244, %key_down_read_485 ]
  br i1 %t245, label %logic_short_488, label %logic_rhs_487
logic_rhs_487:
  %t246 = load i32, i32* %t103
  %t247 = icmp sge i32 %t246, 0
  %t248 = icmp slt i32 %t246, 512
  %t249 = and i1 %t247, %t248
  br i1 %t249, label %key_down_read_490, label %key_down_end_491
key_down_read_490:
  %t250 = call i8* @SDL_GetKeyboardState(i32* null)
  %t251 = sext i32 %t246 to i64
  %t252 = getelementptr inbounds i8, i8* %t250, i64 %t251
  %t253 = load i8, i8* %t252
  %t254 = icmp ne i8 %t253, 0
  br label %key_down_end_491
key_down_end_491:
  %t255 = phi i1 [ false, %logic_rhs_487 ], [ %t254, %key_down_read_490 ]
  br label %logic_end_489
logic_short_488:
  br label %logic_end_489
logic_end_489:
  %t256 = phi i1 [ %t255, %key_down_end_491 ], [ true, %logic_short_488 ]
  br i1 %t256, label %if_then_492, label %if_else_493
if_then_492:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t47, i32 1)
  br label %if_end_494
if_else_493:
  br label %if_end_494
if_end_494:
  %t258 = load i32, i32* %t100
  %t259 = icmp sge i32 %t258, 0
  %t260 = icmp slt i32 %t258, 512
  %t261 = and i1 %t259, %t260
  br i1 %t261, label %key_down_read_495, label %key_down_end_496
key_down_read_495:
  %t262 = call i8* @SDL_GetKeyboardState(i32* null)
  %t263 = sext i32 %t258 to i64
  %t264 = getelementptr inbounds i8, i8* %t262, i64 %t263
  %t265 = load i8, i8* %t264
  %t266 = icmp ne i8 %t265, 0
  br label %key_down_end_496
key_down_end_496:
  %t267 = phi i1 [ false, %if_end_494 ], [ %t266, %key_down_read_495 ]
  br i1 %t267, label %logic_short_498, label %logic_rhs_497
logic_rhs_497:
  %t268 = load i32, i32* %t104
  %t269 = icmp sge i32 %t268, 0
  %t270 = icmp slt i32 %t268, 512
  %t271 = and i1 %t269, %t270
  br i1 %t271, label %key_down_read_500, label %key_down_end_501
key_down_read_500:
  %t272 = call i8* @SDL_GetKeyboardState(i32* null)
  %t273 = sext i32 %t268 to i64
  %t274 = getelementptr inbounds i8, i8* %t272, i64 %t273
  %t275 = load i8, i8* %t274
  %t276 = icmp ne i8 %t275, 0
  br label %key_down_end_501
key_down_end_501:
  %t277 = phi i1 [ false, %logic_rhs_497 ], [ %t276, %key_down_read_500 ]
  br label %logic_end_499
logic_short_498:
  br label %logic_end_499
logic_end_499:
  %t278 = phi i1 [ %t277, %key_down_end_501 ], [ true, %logic_short_498 ]
  br i1 %t278, label %if_then_502, label %if_else_503
if_then_502:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t47, i32 2)
  br label %if_end_504
if_else_503:
  br label %if_end_504
if_end_504:
  %t280 = load i32, i32* %t101
  %t281 = icmp sge i32 %t280, 0
  %t282 = icmp slt i32 %t280, 512
  %t283 = and i1 %t281, %t282
  br i1 %t283, label %key_down_read_505, label %key_down_end_506
key_down_read_505:
  %t284 = call i8* @SDL_GetKeyboardState(i32* null)
  %t285 = sext i32 %t280 to i64
  %t286 = getelementptr inbounds i8, i8* %t284, i64 %t285
  %t287 = load i8, i8* %t286
  %t288 = icmp ne i8 %t287, 0
  br label %key_down_end_506
key_down_end_506:
  %t289 = phi i1 [ false, %if_end_504 ], [ %t288, %key_down_read_505 ]
  br i1 %t289, label %logic_short_508, label %logic_rhs_507
logic_rhs_507:
  %t290 = load i32, i32* %t105
  %t291 = icmp sge i32 %t290, 0
  %t292 = icmp slt i32 %t290, 512
  %t293 = and i1 %t291, %t292
  br i1 %t293, label %key_down_read_510, label %key_down_end_511
key_down_read_510:
  %t294 = call i8* @SDL_GetKeyboardState(i32* null)
  %t295 = sext i32 %t290 to i64
  %t296 = getelementptr inbounds i8, i8* %t294, i64 %t295
  %t297 = load i8, i8* %t296
  %t298 = icmp ne i8 %t297, 0
  br label %key_down_end_511
key_down_end_511:
  %t299 = phi i1 [ false, %logic_rhs_507 ], [ %t298, %key_down_read_510 ]
  br label %logic_end_509
logic_short_508:
  br label %logic_end_509
logic_end_509:
  %t300 = phi i1 [ %t299, %key_down_end_511 ], [ true, %logic_short_508 ]
  br i1 %t300, label %if_then_512, label %if_else_513
if_then_512:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t47, i32 3)
  br label %if_end_514
if_else_513:
  br label %if_end_514
if_end_514:
  %t302 = load i32, i32* %t97
  %t303 = icmp sge i32 %t302, 0
  %t304 = icmp slt i32 %t302, 512
  %t305 = and i1 %t303, %t304
  br i1 %t305, label %key_down_read_515, label %key_down_end_516
key_down_read_515:
  %t306 = call i8* @SDL_GetKeyboardState(i32* null)
  %t307 = sext i32 %t302 to i64
  %t308 = getelementptr inbounds i8, i8* %t306, i64 %t307
  %t309 = load i8, i8* %t308
  %t310 = icmp ne i8 %t309, 0
  br label %key_down_end_516
key_down_end_516:
  %t311 = phi i1 [ false, %if_end_514 ], [ %t310, %key_down_read_515 ]
  store i1 %t311, i1* %t92
  %t313 = load i1, i1* %t92
  br i1 %t313, label %if_then_517, label %if_else_518
if_then_517:
  %t314 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 2
  %t315 = load i32, i32* %t314
  %t316 = icmp eq i32 2, 0
  %t317 = icmp eq i32 %t315, -2147483648
  %t318 = icmp eq i32 2, -1
  %t319 = and i1 %t317, %t318
  %t320 = or i1 %t316, %t319
  br i1 %t320, label %int_div_fail_520, label %int_div_ok_521
int_div_fail_520:
  %t321 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.40, i64 0, i64 0
  call i32 @puts(i8* %t321)
  call void @exit(i32 1)
  unreachable
int_div_ok_521:
  %t322 = sdiv i32 %t315, 2
  br label %if_end_519
if_else_518:
  %t323 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 2
  %t324 = load i32, i32* %t323
  br label %if_end_519
if_end_519:
  %t325 = phi i32 [ %t322, %int_div_ok_521 ], [ %t324, %if_else_518 ]
  store i32 %t325, i32* %t312
  %t327 = call i32 @SDL_GetTicks()
  store i32 %t327, i32* %t326
  %t328 = load i64, i64* %t54
  %t329 = zext i32 0 to i64
  %t330 = shl i64 1, %t329
  %t331 = and i64 %t328, %t330
  %t332 = icmp ne i64 %t331, 0
  %t333 = xor i1 true, %t332
  br i1 %t333, label %logic_rhs_522, label %logic_short_523
logic_rhs_522:
  %t334 = load i32, i32* %t326
  %t335 = load i32, i32* %t87
  %t336 = sub i32 %t334, %t335
  %t337 = load i32, i32* %t312
  %t338 = icmp sge i32 %t336, %t337
  br label %logic_end_524
logic_short_523:
  br label %logic_end_524
logic_end_524:
  %t339 = phi i1 [ %t338, %logic_rhs_522 ], [ false, %logic_short_523 ]
  br i1 %t339, label %if_then_525, label %if_else_526
if_then_525:
  %t340 = load i32, i32* %t326
  store i32 %t340, i32* %t87
  %t342 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t343 = load i32, i32* %t342
  store i32 %t343, i32* %t341
  %t345 = call %food__sb__grid__Cell @food__sb__Snake__advance(%food__sb__Snake* %t47)
  store %food__sb__grid__Cell %t345, %food__sb__grid__Cell* %t344
  %t346 = getelementptr i64, i64* null, i32 1
  %t347 = ptrtoint i64* %t346 to i64
  %t348 = load i8*, i8** %t56
  %t349 = icmp eq i8* %t348, null
  br i1 %t349, label %list_cow_alloc_528, label %list_cow_check_529
list_cow_alloc_528:
  %t354 = bitcast void (i8*)* @list_release_symbol to i8*
  %t355 = call i8* @star_rc_alloc(i64 24, i8* %t354)
  %t356 = bitcast i8* %t355 to { i64*, i64, i64 }*
  %t357 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t356, i32 0, i32 0
  store i64* null, i64** %t357
  %t358 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t356, i32 0, i32 1
  store i64 0, i64* %t358
  %t359 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t356, i32 0, i32 2
  store i64 0, i64* %t359
  store i8* %t355, i8** %t56
  br label %list_cow_done_530
list_cow_check_529:
  %t360 = getelementptr inbounds i8, i8* %t348, i64 -16
  %t361 = bitcast i8* %t360 to i64*
  %t362 = load atomic i64, i64* %t361 seq_cst, align 8
  %t363 = icmp eq i64 %t362, 1
  br i1 %t363, label %list_cow_done_530, label %list_cow_clone_531
list_cow_clone_531:
  %t364 = bitcast i8* %t348 to { i64*, i64, i64 }*
  %t365 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t364, i32 0, i32 0
  %t366 = load i64*, i64** %t365
  %t367 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t364, i32 0, i32 1
  %t368 = load i64, i64* %t367
  %t369 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t364, i32 0, i32 2
  %t370 = load i64, i64* %t369
  %t371 = bitcast void (i8*)* @list_release_symbol to i8*
  %t372 = call i8* @star_rc_alloc(i64 24, i8* %t371)
  %t373 = bitcast i8* %t372 to { i64*, i64, i64 }*
  %t374 = mul i64 %t370, %t347
  %t375 = call i8* @malloc(i64 %t374)
  %t376 = bitcast i8* %t375 to i64*
  %t377 = icmp sgt i64 %t368, 0
  br i1 %t377, label %list_cow_copy_532, label %list_cow_after_copy_533
list_cow_copy_532:
  %t378 = mul i64 %t368, %t347
  %t379 = bitcast i64* %t366 to i8*
  call i8* @memcpy(i8* %t375, i8* %t379, i64 %t378)
  br label %list_cow_after_copy_533
list_cow_after_copy_533:
  %t380 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t373, i32 0, i32 0
  store i64* %t376, i64** %t380
  %t381 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t373, i32 0, i32 1
  store i64 %t368, i64* %t381
  %t382 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t373, i32 0, i32 2
  store i64 %t370, i64* %t382
  call void @star_rc_release(i8* %t348)
  store i8* %t372, i8** %t56
  br label %list_cow_done_530
list_cow_done_530:
  %t383 = load i8*, i8** %t56
  %t384 = bitcast i8* %t383 to { i64*, i64, i64 }*
  %t385 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t384, i32 0, i32 0
  %t386 = load i64*, i64** %t385
  %t387 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t384, i32 0, i32 1
  %t388 = load i64, i64* %t387
  %t389 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t384, i32 0, i32 2
  %t390 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.41, i64 0, i32 2, i64 0
  %t391 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t391, i32 -1)
  %t392 = load i64, i64* @sym.len
  %t393 = load i8**, i8*** @sym.data
  store i64 0, i64* %t394
  br label %sym_find_cond_534
sym_find_cond_534:
  %t395 = load i64, i64* %t394
  %t396 = icmp slt i64 %t395, %t392
  br i1 %t396, label %sym_find_body_535, label %sym_find_end_537
sym_find_body_535:
  %t397 = getelementptr inbounds i8*, i8** %t393, i64 %t395
  %t398 = load i8*, i8** %t397
  %t399 = call i32 @strcmp(i8* %t398, i8* %t390)
  %t400 = icmp eq i32 %t399, 0
  br i1 %t400, label %sym_find_end_537, label %sym_find_next_536
sym_find_next_536:
  %t401 = add i64 %t395, 1
  store i64 %t401, i64* %t394
  br label %sym_find_cond_534
sym_find_end_537:
  %t402 = load i64, i64* %t394
  %t403 = icmp slt i64 %t402, %t392
  br i1 %t403, label %sym_found_538, label %sym_notfound_539
sym_found_538:
  call void @star_rc_release(i8* %t390)
  br label %sym_done_540
sym_notfound_539:
  %t404 = load i64, i64* @sym.cap
  %t405 = icmp sge i64 %t392, %t404
  br i1 %t405, label %sym_grow_541, label %sym_store_542
sym_grow_541:
  %t406 = mul i64 %t404, 2
  %t407 = icmp sgt i64 %t406, 0
  %t408 = select i1 %t407, i64 %t406, i64 1
  %t409 = mul i64 %t408, 8
  %t410 = call i8* @malloc(i64 %t409)
  %t411 = bitcast i8* %t410 to i8**
  %t412 = icmp sgt i64 %t404, 0
  br i1 %t412, label %sym_copy_543, label %sym_after_copy_544
sym_copy_543:
  %t413 = mul i64 %t392, 8
  %t414 = bitcast i8** %t393 to i8*
  call i8* @memcpy(i8* %t410, i8* %t414, i64 %t413)
  call void @free(i8* %t414)
  br label %sym_after_copy_544
sym_after_copy_544:
  store i8** %t411, i8*** @sym.data
  store i64 %t408, i64* @sym.cap
  br label %sym_store_542
sym_store_542:
  %t415 = load i8**, i8*** @sym.data
  %t416 = getelementptr inbounds i8*, i8** %t415, i64 %t392
  store i8* %t390, i8** %t416
  %t417 = add i64 %t392, 1
  store i64 %t417, i64* @sym.len
  br label %sym_done_540
sym_done_540:
  %t418 = phi i64 [ %t402, %sym_found_538 ], [ %t392, %sym_store_542 ]
  call i32 @ReleaseSemaphore(i8* %t391, i32 1, i32* null)
  %t419 = load i64, i64* %t389
  %t420 = load i64*, i64** %t385
  %t421 = load i64, i64* %t387
  %t422 = icmp sge i64 %t421, %t419
  br i1 %t422, label %list_push_grow_545, label %list_push_store_546
list_push_grow_545:
  %t423 = mul i64 %t419, 2
  %t424 = icmp sgt i64 %t423, 0
  %t425 = select i1 %t424, i64 %t423, i64 1
  %t426 = getelementptr i64, i64* null, i32 1
  %t427 = ptrtoint i64* %t426 to i64
  %t428 = mul i64 %t425, %t427
  %t429 = call i8* @malloc(i64 %t428)
  %t430 = bitcast i8* %t429 to i64*
  %t431 = icmp sgt i64 %t419, 0
  br i1 %t431, label %list_push_copy_547, label %list_push_after_copy_548
list_push_copy_547:
  %t432 = mul i64 %t421, %t427
  %t433 = bitcast i64* %t420 to i8*
  call i8* @memcpy(i8* %t429, i8* %t433, i64 %t432)
  call void @free(i8* %t433)
  br label %list_push_after_copy_548
list_push_after_copy_548:
  store i64* %t430, i64** %t385
  store i64 %t425, i64* %t389
  br label %list_push_store_546
list_push_store_546:
  %t434 = load i64*, i64** %t385
  %t435 = getelementptr inbounds i64, i64* %t434, i64 %t421
  store i64 %t418, i64* %t435
  %t436 = add i64 %t421, 1
  store i64 %t436, i64* %t387
  %t437 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t47, i32 0, i32 4
  %t438 = load i1, i1* %t437
  br i1 %t438, label %logic_rhs_549, label %logic_short_550
logic_rhs_549:
  %t439 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t344
  %t440 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t49
  %t441 = call i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %t439, %food__sb__grid__Cell %t440)
  br label %logic_end_551
logic_short_550:
  br label %logic_end_551
logic_end_551:
  %t442 = phi i1 [ %t441, %logic_rhs_549 ], [ false, %logic_short_550 ]
  br i1 %t442, label %if_then_552, label %if_else_553
if_then_552:
  call void @food__sb__Snake__grow(%food__sb__Snake* %t47, i32 1)
  %t444 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t445 = load i32, i32* %t444
  %t446 = add i32 %t445, 10
  %t447 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  store i32 %t446, i32* %t447
  %t448 = getelementptr i64, i64* null, i32 1
  %t449 = ptrtoint i64* %t448 to i64
  %t450 = load i8*, i8** %t56
  %t451 = icmp eq i8* %t450, null
  br i1 %t451, label %list_cow_alloc_555, label %list_cow_check_556
list_cow_alloc_555:
  %t452 = bitcast void (i8*)* @list_release_symbol to i8*
  %t453 = call i8* @star_rc_alloc(i64 24, i8* %t452)
  %t454 = bitcast i8* %t453 to { i64*, i64, i64 }*
  %t455 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t454, i32 0, i32 0
  store i64* null, i64** %t455
  %t456 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t454, i32 0, i32 1
  store i64 0, i64* %t456
  %t457 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t454, i32 0, i32 2
  store i64 0, i64* %t457
  store i8* %t453, i8** %t56
  br label %list_cow_done_557
list_cow_check_556:
  %t458 = getelementptr inbounds i8, i8* %t450, i64 -16
  %t459 = bitcast i8* %t458 to i64*
  %t460 = load atomic i64, i64* %t459 seq_cst, align 8
  %t461 = icmp eq i64 %t460, 1
  br i1 %t461, label %list_cow_done_557, label %list_cow_clone_558
list_cow_clone_558:
  %t462 = bitcast i8* %t450 to { i64*, i64, i64 }*
  %t463 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t462, i32 0, i32 0
  %t464 = load i64*, i64** %t463
  %t465 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t462, i32 0, i32 1
  %t466 = load i64, i64* %t465
  %t467 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t462, i32 0, i32 2
  %t468 = load i64, i64* %t467
  %t469 = bitcast void (i8*)* @list_release_symbol to i8*
  %t470 = call i8* @star_rc_alloc(i64 24, i8* %t469)
  %t471 = bitcast i8* %t470 to { i64*, i64, i64 }*
  %t472 = mul i64 %t468, %t449
  %t473 = call i8* @malloc(i64 %t472)
  %t474 = bitcast i8* %t473 to i64*
  %t475 = icmp sgt i64 %t466, 0
  br i1 %t475, label %list_cow_copy_559, label %list_cow_after_copy_560
list_cow_copy_559:
  %t476 = mul i64 %t466, %t449
  %t477 = bitcast i64* %t464 to i8*
  call i8* @memcpy(i8* %t473, i8* %t477, i64 %t476)
  br label %list_cow_after_copy_560
list_cow_after_copy_560:
  %t478 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t471, i32 0, i32 0
  store i64* %t474, i64** %t478
  %t479 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t471, i32 0, i32 1
  store i64 %t466, i64* %t479
  %t480 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t471, i32 0, i32 2
  store i64 %t468, i64* %t480
  call void @star_rc_release(i8* %t450)
  store i8* %t470, i8** %t56
  br label %list_cow_done_557
list_cow_done_557:
  %t481 = load i8*, i8** %t56
  %t482 = bitcast i8* %t481 to { i64*, i64, i64 }*
  %t483 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t482, i32 0, i32 0
  %t484 = load i64*, i64** %t483
  %t485 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t482, i32 0, i32 1
  %t486 = load i64, i64* %t485
  %t487 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t482, i32 0, i32 2
  %t488 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.42, i64 0, i32 2, i64 0
  %t489 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t489, i32 -1)
  %t490 = load i64, i64* @sym.len
  %t491 = load i8**, i8*** @sym.data
  store i64 0, i64* %t492
  br label %sym_find_cond_561
sym_find_cond_561:
  %t493 = load i64, i64* %t492
  %t494 = icmp slt i64 %t493, %t490
  br i1 %t494, label %sym_find_body_562, label %sym_find_end_564
sym_find_body_562:
  %t495 = getelementptr inbounds i8*, i8** %t491, i64 %t493
  %t496 = load i8*, i8** %t495
  %t497 = call i32 @strcmp(i8* %t496, i8* %t488)
  %t498 = icmp eq i32 %t497, 0
  br i1 %t498, label %sym_find_end_564, label %sym_find_next_563
sym_find_next_563:
  %t499 = add i64 %t493, 1
  store i64 %t499, i64* %t492
  br label %sym_find_cond_561
sym_find_end_564:
  %t500 = load i64, i64* %t492
  %t501 = icmp slt i64 %t500, %t490
  br i1 %t501, label %sym_found_565, label %sym_notfound_566
sym_found_565:
  call void @star_rc_release(i8* %t488)
  br label %sym_done_567
sym_notfound_566:
  %t502 = load i64, i64* @sym.cap
  %t503 = icmp sge i64 %t490, %t502
  br i1 %t503, label %sym_grow_568, label %sym_store_569
sym_grow_568:
  %t504 = mul i64 %t502, 2
  %t505 = icmp sgt i64 %t504, 0
  %t506 = select i1 %t505, i64 %t504, i64 1
  %t507 = mul i64 %t506, 8
  %t508 = call i8* @malloc(i64 %t507)
  %t509 = bitcast i8* %t508 to i8**
  %t510 = icmp sgt i64 %t502, 0
  br i1 %t510, label %sym_copy_570, label %sym_after_copy_571
sym_copy_570:
  %t511 = mul i64 %t490, 8
  %t512 = bitcast i8** %t491 to i8*
  call i8* @memcpy(i8* %t508, i8* %t512, i64 %t511)
  call void @free(i8* %t512)
  br label %sym_after_copy_571
sym_after_copy_571:
  store i8** %t509, i8*** @sym.data
  store i64 %t506, i64* @sym.cap
  br label %sym_store_569
sym_store_569:
  %t513 = load i8**, i8*** @sym.data
  %t514 = getelementptr inbounds i8*, i8** %t513, i64 %t490
  store i8* %t488, i8** %t514
  %t515 = add i64 %t490, 1
  store i64 %t515, i64* @sym.len
  br label %sym_done_567
sym_done_567:
  %t516 = phi i64 [ %t500, %sym_found_565 ], [ %t490, %sym_store_569 ]
  call i32 @ReleaseSemaphore(i8* %t489, i32 1, i32* null)
  %t517 = load i64, i64* %t487
  %t518 = load i64*, i64** %t483
  %t519 = load i64, i64* %t485
  %t520 = icmp sge i64 %t519, %t517
  br i1 %t520, label %list_push_grow_572, label %list_push_store_573
list_push_grow_572:
  %t521 = mul i64 %t517, 2
  %t522 = icmp sgt i64 %t521, 0
  %t523 = select i1 %t522, i64 %t521, i64 1
  %t524 = getelementptr i64, i64* null, i32 1
  %t525 = ptrtoint i64* %t524 to i64
  %t526 = mul i64 %t523, %t525
  %t527 = call i8* @malloc(i64 %t526)
  %t528 = bitcast i8* %t527 to i64*
  %t529 = icmp sgt i64 %t517, 0
  br i1 %t529, label %list_push_copy_574, label %list_push_after_copy_575
list_push_copy_574:
  %t530 = mul i64 %t519, %t525
  %t531 = bitcast i64* %t518 to i8*
  call i8* @memcpy(i8* %t527, i8* %t531, i64 %t530)
  call void @free(i8* %t531)
  br label %list_push_after_copy_575
list_push_after_copy_575:
  store i64* %t528, i64** %t483
  store i64 %t523, i64* %t487
  br label %list_push_store_573
list_push_store_573:
  %t532 = load i64*, i64** %t483
  %t533 = getelementptr inbounds i64, i64* %t532, i64 %t519
  store i64 %t516, i64* %t533
  %t534 = add i64 %t519, 1
  store i64 %t534, i64* %t485
  %t536 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t49
  %t537 = call { i32, i32 } @cell_px(%food__sb__grid__Cell %t536)
  store { i32, i32 } %t537, { i32, i32 }* %t535
  %t539 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t535, i32 0, i32 0
  %t540 = load i32, i32* %t539
  %t541 = icmp eq i32 2, 0
  %t542 = icmp eq i32 20, -2147483648
  %t543 = icmp eq i32 2, -1
  %t544 = and i1 %t542, %t543
  %t545 = or i1 %t541, %t544
  br i1 %t545, label %int_div_fail_576, label %int_div_ok_577
int_div_fail_576:
  %t546 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.43, i64 0, i64 0
  call i32 @puts(i8* %t546)
  call void @exit(i32 1)
  unreachable
int_div_ok_577:
  %t547 = sdiv i32 20, 2
  %t548 = add i32 %t540, %t547
  %t549 = sitofp i32 %t548 to float
  store float %t549, float* %t538
  %t551 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t535, i32 0, i32 1
  %t552 = load i32, i32* %t551
  %t553 = icmp eq i32 2, 0
  %t554 = icmp eq i32 20, -2147483648
  %t555 = icmp eq i32 2, -1
  %t556 = and i1 %t554, %t555
  %t557 = or i1 %t553, %t556
  br i1 %t557, label %int_div_fail_578, label %int_div_ok_579
int_div_fail_578:
  %t558 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.44, i64 0, i64 0
  call i32 @puts(i8* %t558)
  call void @exit(i32 1)
  unreachable
int_div_ok_579:
  %t559 = sdiv i32 20, 2
  %t560 = add i32 %t552, %t559
  %t561 = sitofp i32 %t560 to float
  store float %t561, float* %t550
  %t562 = load float, float* %t538
  %t563 = load float, float* %t550
  call void @ParticlePool__spawn_burst(%ParticlePool* %t68, float %t562, float %t563)
  %t565 = load %Particle*, %Particle** @arena.Particles.data
  %t566 = icmp eq %Particle* %t565, null
  br i1 %t566, label %spawn_init_580, label %spawn_ready_581
spawn_init_580:
  %t567 = getelementptr %Particle, %Particle* null, i32 1
  %t568 = ptrtoint %Particle* %t567 to i64
  %t569 = mul i64 %t568, 256
  %t570 = call i8* @malloc(i64 %t569)
  %t571 = bitcast i8* %t570 to %Particle*
  store %Particle* %t571, %Particle** @arena.Particles.data
  br label %spawn_ready_581
spawn_ready_581:
  %t572 = load %Particle*, %Particle** @arena.Particles.data
  %t573 = load i64, i64* @arena.Particles.free_top
  %t574 = icmp sgt i64 %t573, 0
  br i1 %t574, label %spawn_reuse_582, label %spawn_grow_583
spawn_reuse_582:
  %t575 = sub i64 %t573, 1
  store i64 %t575, i64* @arena.Particles.free_top
  %t576 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.free, i64 0, i64 %t575
  %t577 = load i64, i64* %t576
  br label %spawn_store_584
spawn_grow_583:
  %t578 = load i64, i64* @arena.Particles.count
  %t579 = icmp slt i64 %t578, 256
  br i1 %t579, label %spawn_grow_ok_586, label %spawn_capacity_warn_587
spawn_capacity_warn_587:
  %t580 = load i1, i1* @arena.Particles.warned
  br i1 %t580, label %spawn_end_585, label %spawn_warn_print_588
spawn_warn_print_588:
  store i1 1, i1* @arena.Particles.warned
  %t581 = getelementptr inbounds [141 x i8], [141 x i8]* @.str.45, i64 0, i64 0
  call i32 @puts(i8* %t581)
  br label %spawn_end_585
spawn_grow_ok_586:
  %t582 = add i64 %t578, 1
  store i64 %t582, i64* @arena.Particles.count
  br label %spawn_store_584
spawn_store_584:
  %t583 = phi i64 [ %t577, %spawn_reuse_582 ], [ %t578, %spawn_grow_ok_586 ]
  %t585 = load float, float* %t538
  %t586 = getelementptr inbounds %Particle, %Particle* %t584, i32 0, i32 0
  store float %t585, float* %t586
  %t587 = load float, float* %t550
  %t588 = getelementptr inbounds %Particle, %Particle* %t584, i32 0, i32 1
  store float %t587, float* %t588
  %t589 = getelementptr inbounds %Particle, %Particle* %t584, i32 0, i32 2
  store float 0x0000000000000000, float* %t589
  %t590 = getelementptr inbounds %Particle, %Particle* %t584, i32 0, i32 3
  store float 0x0000000000000000, float* %t590
  %t591 = getelementptr inbounds %Particle, %Particle* %t584, i32 0, i32 4
  store float 0x3FDCCCCCC0000000, float* %t591
  %t592 = load %Particle, %Particle* %t584
  %t593 = getelementptr inbounds %Particle, %Particle* %t572, i64 %t583
  store %Particle %t592, %Particle* %t593
  %t594 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t583
  %t595 = load i64, i64* %t594
  %t596 = add i64 %t595, 1
  store i64 %t596, i64* %t594
  %t597 = trunc i64 %t583 to i32
  br label %spawn_end_585
spawn_end_585:
  %t598 = phi i32 [ %t597, %spawn_store_584 ], [ -1, %spawn_capacity_warn_587 ], [ -1, %spawn_warn_print_588 ]
  %t601 = load i8*, i8** %t6
  %t602 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t600, i32 0, i32 0
  store i8* %t601, i8** %t602
  %t603 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t600, i32 0, i32 1
  store i32 0, i32* %t603
  %t604 = load %FlashOnEat, %FlashOnEat* %t600
  store %FlashOnEat %t604, %FlashOnEat* %t599
  store i1 true, i1* %t605
  br label %while_cond_589
while_cond_589:
  %t606 = load i1, i1* %t605
  br i1 %t606, label %while_body_590, label %while_else_591
while_body_590:
  %t607 = call i1 @FlashOnEat__resume(%FlashOnEat* %t599)
  store i1 %t607, i1* %t605
  br label %while_cond_589
while_else_591:
  br label %while_end_592
while_end_592:
  %t608 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t47, i32 0, i32 0
  %t609 = load { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t608
  %t610 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t47)
  %t611 = call %food__sb__grid__Cell @food__spawn_food({ [768 x %food__sb__grid__Cell], i64, i64 } %t609, i32 %t610)
  store %food__sb__grid__Cell %t611, %food__sb__grid__Cell* %t49
  %t612 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t613 = load i32, i32* %t612
  %t614 = icmp eq i32 50, 0
  %t615 = icmp eq i32 %t613, -2147483648
  %t616 = icmp eq i32 50, -1
  %t617 = and i1 %t615, %t616
  %t618 = or i1 %t614, %t617
  br i1 %t618, label %int_div_fail_593, label %int_div_ok_594
int_div_fail_593:
  %t619 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.46, i64 0, i64 0
  call i32 @puts(i8* %t619)
  call void @exit(i32 1)
  unreachable
int_div_ok_594:
  %t620 = sdiv i32 %t613, 50
  %t621 = load i32, i32* %t341
  %t622 = icmp eq i32 50, 0
  %t623 = icmp eq i32 %t621, -2147483648
  %t624 = icmp eq i32 50, -1
  %t625 = and i1 %t623, %t624
  %t626 = or i1 %t622, %t625
  br i1 %t626, label %int_div_fail_595, label %int_div_ok_596
int_div_fail_595:
  %t627 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.47, i64 0, i64 0
  call i32 @puts(i8* %t627)
  call void @exit(i32 1)
  unreachable
int_div_ok_596:
  %t628 = sdiv i32 %t621, 50
  %t629 = icmp sgt i32 %t620, %t628
  br i1 %t629, label %if_then_597, label %if_else_598
if_then_597:
  %t631 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t632 = load i32, i32* %t631
  %t633 = icmp eq i32 50, 0
  %t634 = icmp eq i32 %t632, -2147483648
  %t635 = icmp eq i32 50, -1
  %t636 = and i1 %t634, %t635
  %t637 = or i1 %t633, %t636
  br i1 %t637, label %int_div_fail_600, label %int_div_ok_601
int_div_fail_600:
  %t638 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.48, i64 0, i64 0
  call i32 @puts(i8* %t638)
  call void @exit(i32 1)
  unreachable
int_div_ok_601:
  %t639 = sdiv i32 %t632, 50
  store i32 %t639, i32* %t630
  %t640 = load i32, i32* %t630
  %t641 = icmp sge i32 %t640, 1
  br i1 %t641, label %logic_rhs_602, label %logic_short_603
logic_rhs_602:
  %t642 = load i32, i32* %t630
  %t643 = icmp sle i32 %t642, 8
  br label %logic_end_604
logic_short_603:
  br label %logic_end_604
logic_end_604:
  %t644 = phi i1 [ %t643, %logic_rhs_602 ], [ false, %logic_short_603 ]
  br i1 %t644, label %if_then_605, label %if_else_606
if_then_605:
  %t645 = load i8, i8* %t55
  %t646 = load i32, i32* %t630
  %t647 = sub i32 %t646, 1
  %t648 = and i32 %t647, 7
  %t649 = trunc i32 %t648 to i8
  %t650 = shl i8 1, %t649
  %t651 = or i8 %t645, %t650
  store i8 %t651, i8* %t55
  %t652 = load i32, i32* %t630
  %t653 = load i8, i8* %t55
  %t654 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.49, i64 0, i64 0
  %t655 = zext i8 %t653 to i32
  call i32 (i8*, ...) @printf(i8* %t654, i32 %t652, i32 %t655)
  br label %if_end_607
if_else_606:
  br label %if_end_607
if_end_607:
  br label %if_end_599
if_else_598:
  br label %if_end_599
if_end_599:
  %t656 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t657 = load i32, i32* %t656
  %t658 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 1
  %t659 = load i32, i32* %t658
  %t660 = icmp sgt i32 %t657, %t659
  br i1 %t660, label %if_then_608, label %if_else_609
if_then_608:
  %t661 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t662 = load i32, i32* %t661
  %t663 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 1
  store i32 %t662, i32* %t663
  br label %if_end_610
if_else_609:
  br label %if_end_610
if_end_610:
  br label %if_end_554
if_else_553:
  br label %if_end_554
if_end_554:
  %t664 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t47, i32 0, i32 4
  %t665 = load i1, i1* %t664
  %t666 = xor i1 true, %t665
  br i1 %t666, label %if_then_611, label %if_else_612
if_then_611:
  %t667 = getelementptr i64, i64* null, i32 1
  %t668 = ptrtoint i64* %t667 to i64
  %t669 = load i8*, i8** %t56
  %t670 = icmp eq i8* %t669, null
  br i1 %t670, label %list_cow_alloc_614, label %list_cow_check_615
list_cow_alloc_614:
  %t671 = bitcast void (i8*)* @list_release_symbol to i8*
  %t672 = call i8* @star_rc_alloc(i64 24, i8* %t671)
  %t673 = bitcast i8* %t672 to { i64*, i64, i64 }*
  %t674 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t673, i32 0, i32 0
  store i64* null, i64** %t674
  %t675 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t673, i32 0, i32 1
  store i64 0, i64* %t675
  %t676 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t673, i32 0, i32 2
  store i64 0, i64* %t676
  store i8* %t672, i8** %t56
  br label %list_cow_done_616
list_cow_check_615:
  %t677 = getelementptr inbounds i8, i8* %t669, i64 -16
  %t678 = bitcast i8* %t677 to i64*
  %t679 = load atomic i64, i64* %t678 seq_cst, align 8
  %t680 = icmp eq i64 %t679, 1
  br i1 %t680, label %list_cow_done_616, label %list_cow_clone_617
list_cow_clone_617:
  %t681 = bitcast i8* %t669 to { i64*, i64, i64 }*
  %t682 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t681, i32 0, i32 0
  %t683 = load i64*, i64** %t682
  %t684 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t681, i32 0, i32 1
  %t685 = load i64, i64* %t684
  %t686 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t681, i32 0, i32 2
  %t687 = load i64, i64* %t686
  %t688 = bitcast void (i8*)* @list_release_symbol to i8*
  %t689 = call i8* @star_rc_alloc(i64 24, i8* %t688)
  %t690 = bitcast i8* %t689 to { i64*, i64, i64 }*
  %t691 = mul i64 %t687, %t668
  %t692 = call i8* @malloc(i64 %t691)
  %t693 = bitcast i8* %t692 to i64*
  %t694 = icmp sgt i64 %t685, 0
  br i1 %t694, label %list_cow_copy_618, label %list_cow_after_copy_619
list_cow_copy_618:
  %t695 = mul i64 %t685, %t668
  %t696 = bitcast i64* %t683 to i8*
  call i8* @memcpy(i8* %t692, i8* %t696, i64 %t695)
  br label %list_cow_after_copy_619
list_cow_after_copy_619:
  %t697 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t690, i32 0, i32 0
  store i64* %t693, i64** %t697
  %t698 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t690, i32 0, i32 1
  store i64 %t685, i64* %t698
  %t699 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t690, i32 0, i32 2
  store i64 %t687, i64* %t699
  call void @star_rc_release(i8* %t669)
  store i8* %t689, i8** %t56
  br label %list_cow_done_616
list_cow_done_616:
  %t700 = load i8*, i8** %t56
  %t701 = bitcast i8* %t700 to { i64*, i64, i64 }*
  %t702 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t701, i32 0, i32 0
  %t703 = load i64*, i64** %t702
  %t704 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t701, i32 0, i32 1
  %t705 = load i64, i64* %t704
  %t706 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t701, i32 0, i32 2
  %t707 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.50, i64 0, i32 2, i64 0
  %t708 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t708, i32 -1)
  %t709 = load i64, i64* @sym.len
  %t710 = load i8**, i8*** @sym.data
  store i64 0, i64* %t711
  br label %sym_find_cond_620
sym_find_cond_620:
  %t712 = load i64, i64* %t711
  %t713 = icmp slt i64 %t712, %t709
  br i1 %t713, label %sym_find_body_621, label %sym_find_end_623
sym_find_body_621:
  %t714 = getelementptr inbounds i8*, i8** %t710, i64 %t712
  %t715 = load i8*, i8** %t714
  %t716 = call i32 @strcmp(i8* %t715, i8* %t707)
  %t717 = icmp eq i32 %t716, 0
  br i1 %t717, label %sym_find_end_623, label %sym_find_next_622
sym_find_next_622:
  %t718 = add i64 %t712, 1
  store i64 %t718, i64* %t711
  br label %sym_find_cond_620
sym_find_end_623:
  %t719 = load i64, i64* %t711
  %t720 = icmp slt i64 %t719, %t709
  br i1 %t720, label %sym_found_624, label %sym_notfound_625
sym_found_624:
  call void @star_rc_release(i8* %t707)
  br label %sym_done_626
sym_notfound_625:
  %t721 = load i64, i64* @sym.cap
  %t722 = icmp sge i64 %t709, %t721
  br i1 %t722, label %sym_grow_627, label %sym_store_628
sym_grow_627:
  %t723 = mul i64 %t721, 2
  %t724 = icmp sgt i64 %t723, 0
  %t725 = select i1 %t724, i64 %t723, i64 1
  %t726 = mul i64 %t725, 8
  %t727 = call i8* @malloc(i64 %t726)
  %t728 = bitcast i8* %t727 to i8**
  %t729 = icmp sgt i64 %t721, 0
  br i1 %t729, label %sym_copy_629, label %sym_after_copy_630
sym_copy_629:
  %t730 = mul i64 %t709, 8
  %t731 = bitcast i8** %t710 to i8*
  call i8* @memcpy(i8* %t727, i8* %t731, i64 %t730)
  call void @free(i8* %t731)
  br label %sym_after_copy_630
sym_after_copy_630:
  store i8** %t728, i8*** @sym.data
  store i64 %t725, i64* @sym.cap
  br label %sym_store_628
sym_store_628:
  %t732 = load i8**, i8*** @sym.data
  %t733 = getelementptr inbounds i8*, i8** %t732, i64 %t709
  store i8* %t707, i8** %t733
  %t734 = add i64 %t709, 1
  store i64 %t734, i64* @sym.len
  br label %sym_done_626
sym_done_626:
  %t735 = phi i64 [ %t719, %sym_found_624 ], [ %t709, %sym_store_628 ]
  call i32 @ReleaseSemaphore(i8* %t708, i32 1, i32* null)
  %t736 = load i64, i64* %t706
  %t737 = load i64*, i64** %t702
  %t738 = load i64, i64* %t704
  %t739 = icmp sge i64 %t738, %t736
  br i1 %t739, label %list_push_grow_631, label %list_push_store_632
list_push_grow_631:
  %t740 = mul i64 %t736, 2
  %t741 = icmp sgt i64 %t740, 0
  %t742 = select i1 %t741, i64 %t740, i64 1
  %t743 = getelementptr i64, i64* null, i32 1
  %t744 = ptrtoint i64* %t743 to i64
  %t745 = mul i64 %t742, %t744
  %t746 = call i8* @malloc(i64 %t745)
  %t747 = bitcast i8* %t746 to i64*
  %t748 = icmp sgt i64 %t736, 0
  br i1 %t748, label %list_push_copy_633, label %list_push_after_copy_634
list_push_copy_633:
  %t749 = mul i64 %t738, %t744
  %t750 = bitcast i64* %t737 to i8*
  call i8* @memcpy(i8* %t746, i8* %t750, i64 %t749)
  call void @free(i8* %t750)
  br label %list_push_after_copy_634
list_push_after_copy_634:
  store i64* %t747, i64** %t702
  store i64 %t742, i64* %t706
  br label %list_push_store_632
list_push_store_632:
  %t751 = load i64*, i64** %t702
  %t752 = getelementptr inbounds i64, i64* %t751, i64 %t738
  store i64 %t735, i64* %t752
  %t753 = add i64 %t738, 1
  store i64 %t753, i64* %t704
  %t754 = load i8*, i8** %t56
  %t755 = icmp eq i8* %t754, null
  br i1 %t755, label %list_read_null_635, label %list_read_real_636
list_read_null_635:
  br label %list_read_end_637
list_read_real_636:
  %t756 = bitcast i8* %t754 to { i64*, i64, i64 }*
  %t757 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t756, i32 0, i32 0
  %t758 = load i64*, i64** %t757
  %t759 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t756, i32 0, i32 1
  %t760 = load i64, i64* %t759
  br label %list_read_end_637
list_read_end_637:
  %t761 = phi i64* [ null, %list_read_null_635 ], [ %t758, %list_read_real_636 ]
  %t762 = phi i64 [ 0, %list_read_null_635 ], [ %t760, %list_read_real_636 ]
  %t763 = load i8*, i8** %t56
  %t764 = icmp eq i8* %t763, null
  br i1 %t764, label %list_read_null_638, label %list_read_real_639
list_read_null_638:
  br label %list_read_end_640
list_read_real_639:
  %t765 = bitcast i8* %t763 to { i64*, i64, i64 }*
  %t766 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t765, i32 0, i32 0
  %t767 = load i64*, i64** %t766
  %t768 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t765, i32 0, i32 1
  %t769 = load i64, i64* %t768
  br label %list_read_end_640
list_read_end_640:
  %t770 = phi i64* [ null, %list_read_null_638 ], [ %t767, %list_read_real_639 ]
  %t771 = phi i64 [ 0, %list_read_null_638 ], [ %t769, %list_read_real_639 ]
  %t772 = trunc i64 %t771 to i32
  %t773 = sub i32 %t772, 1
  %t774 = sext i32 %t773 to i64
  %t775 = icmp ult i64 %t774, %t762
  br i1 %t775, label %list_idx_ok_641, label %list_idx_oob_642
list_idx_ok_641:
  %t776 = getelementptr inbounds i64, i64* %t761, i64 %t774
  %t777 = load i64, i64* %t776
  br label %list_idx_end_643
list_idx_oob_642:
  br label %list_idx_end_643
list_idx_end_643:
  %t778 = phi i64 [ %t777, %list_idx_ok_641 ], [ 0, %list_idx_oob_642 ]
  %t779 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t779, i32 -1)
  %t780 = load i64, i64* @sym.len
  %t781 = icmp sge i64 %t778, 0
  %t782 = icmp slt i64 %t778, %t780
  %t783 = and i1 %t781, %t782
  br i1 %t783, label %sym_name_ok_644, label %sym_name_oob_645
sym_name_ok_644:
  %t784 = load i8**, i8*** @sym.data
  %t785 = getelementptr inbounds i8*, i8** %t784, i64 %t778
  %t786 = load i8*, i8** %t785
  call void @star_rc_retain(i8* %t786)
  br label %sym_name_end_646
sym_name_oob_645:
  %t787 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t787
  br label %sym_name_end_646
sym_name_end_646:
  %t788 = phi i8* [ %t786, %sym_name_ok_644 ], [ %t787, %sym_name_oob_645 ]
  call i32 @ReleaseSemaphore(i8* %t779, i32 1, i32* null)
  call void @star_rc_release(i8* %t788)
  %t789 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t789, i8* %t788)
  %t790 = load i8*, i8** %t23
  %t791 = load i8*, i8** %t23
  call void @star_rc_retain(i8* %t791)
  %t792 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 1
  %t793 = load i32, i32* %t792
  %t794 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.52, i64 0, i32 2, i64 0
  %t795 = call i1 @save__save_high_score(i8* %t790, i32 %t793, i8* %t794)
  store i32 4, i32* %t796
  br label %while_cond_647
while_cond_647:
  %t797 = load i32, i32* %t796
  %t798 = icmp sge i32 %t797, 0
  br i1 %t798, label %while_body_648, label %while_else_649
while_body_648:
  %t799 = load i32, i32* %t796
  %t800 = icmp eq i32 %t799, 0
  br i1 %t800, label %logic_short_652, label %logic_rhs_651
logic_rhs_651:
  %t801 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t802 = load i32, i32* %t801
  %t803 = load i32, i32* %t796
  %t804 = sub i32 %t803, 1
  %t805 = sext i32 %t804 to i64
  %t806 = icmp ult i64 %t805, 5
  br i1 %t806, label %arr_rplace_ok_654, label %arr_rplace_oob_655
arr_rplace_ok_654:
  %t807 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t805
  br label %arr_rplace_end_656
arr_rplace_oob_655:
  store i32 0, i32* %t808
  br label %arr_rplace_end_656
arr_rplace_end_656:
  %t809 = phi i32* [ %t807, %arr_rplace_ok_654 ], [ %t808, %arr_rplace_oob_655 ]
  %t810 = load i32, i32* %t809
  %t811 = icmp sle i32 %t802, %t810
  br label %logic_end_653
logic_short_652:
  br label %logic_end_653
logic_end_653:
  %t812 = phi i1 [ %t811, %arr_rplace_end_656 ], [ true, %logic_short_652 ]
  br i1 %t812, label %if_then_657, label %if_else_658
if_then_657:
  %t813 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t814 = load i32, i32* %t813
  %t815 = load i32, i32* %t796
  %t816 = sext i32 %t815 to i64
  %t817 = icmp ult i64 %t816, 5
  br i1 %t817, label %arr_set_do_660, label %arr_set_oob_661
arr_set_do_660:
  %t818 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t816
  store i32 %t814, i32* %t818
  br label %arr_set_end_662
arr_set_oob_661:
  br label %arr_set_end_662
arr_set_end_662:
  br label %while_end_650
if_else_658:
  br label %if_end_659
if_end_659:
  %t819 = load i32, i32* %t796
  %t820 = sub i32 %t819, 1
  %t821 = sext i32 %t820 to i64
  %t822 = icmp ult i64 %t821, 5
  br i1 %t822, label %arr_rplace_ok_663, label %arr_rplace_oob_664
arr_rplace_ok_663:
  %t823 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t821
  br label %arr_rplace_end_665
arr_rplace_oob_664:
  store i32 0, i32* %t824
  br label %arr_rplace_end_665
arr_rplace_end_665:
  %t825 = phi i32* [ %t823, %arr_rplace_ok_663 ], [ %t824, %arr_rplace_oob_664 ]
  %t826 = load i32, i32* %t825
  %t827 = load i32, i32* %t796
  %t828 = sext i32 %t827 to i64
  %t829 = icmp ult i64 %t828, 5
  br i1 %t829, label %arr_set_do_666, label %arr_set_oob_667
arr_set_do_666:
  %t830 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t828
  store i32 %t826, i32* %t830
  br label %arr_set_end_668
arr_set_oob_667:
  br label %arr_set_end_668
arr_set_end_668:
  %t831 = load i32, i32* %t796
  %t832 = sub i32 %t831, 1
  store i32 %t832, i32* %t796
  br label %while_cond_647
while_else_649:
  br label %while_end_650
while_end_650:
  %t833 = sext i32 0 to i64
  %t834 = icmp ult i64 %t833, 5
  br i1 %t834, label %arr_rplace_ok_669, label %arr_rplace_oob_670
arr_rplace_ok_669:
  %t835 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t833
  br label %arr_rplace_end_671
arr_rplace_oob_670:
  store i32 0, i32* %t836
  br label %arr_rplace_end_671
arr_rplace_end_671:
  %t837 = phi i32* [ %t835, %arr_rplace_ok_669 ], [ %t836, %arr_rplace_oob_670 ]
  %t838 = load i32, i32* %t837
  %t839 = sext i32 1 to i64
  %t840 = icmp ult i64 %t839, 5
  br i1 %t840, label %arr_rplace_ok_672, label %arr_rplace_oob_673
arr_rplace_ok_672:
  %t841 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t839
  br label %arr_rplace_end_674
arr_rplace_oob_673:
  store i32 0, i32* %t842
  br label %arr_rplace_end_674
arr_rplace_end_674:
  %t843 = phi i32* [ %t841, %arr_rplace_ok_672 ], [ %t842, %arr_rplace_oob_673 ]
  %t844 = load i32, i32* %t843
  %t845 = sext i32 2 to i64
  %t846 = icmp ult i64 %t845, 5
  br i1 %t846, label %arr_rplace_ok_675, label %arr_rplace_oob_676
arr_rplace_ok_675:
  %t847 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t845
  br label %arr_rplace_end_677
arr_rplace_oob_676:
  store i32 0, i32* %t848
  br label %arr_rplace_end_677
arr_rplace_end_677:
  %t849 = phi i32* [ %t847, %arr_rplace_ok_675 ], [ %t848, %arr_rplace_oob_676 ]
  %t850 = load i32, i32* %t849
  %t851 = sext i32 3 to i64
  %t852 = icmp ult i64 %t851, 5
  br i1 %t852, label %arr_rplace_ok_678, label %arr_rplace_oob_679
arr_rplace_ok_678:
  %t853 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t851
  br label %arr_rplace_end_680
arr_rplace_oob_679:
  store i32 0, i32* %t854
  br label %arr_rplace_end_680
arr_rplace_end_680:
  %t855 = phi i32* [ %t853, %arr_rplace_ok_678 ], [ %t854, %arr_rplace_oob_679 ]
  %t856 = load i32, i32* %t855
  %t857 = sext i32 4 to i64
  %t858 = icmp ult i64 %t857, 5
  br i1 %t858, label %arr_rplace_ok_681, label %arr_rplace_oob_682
arr_rplace_ok_681:
  %t859 = getelementptr inbounds [5 x i32], [5 x i32]* %t59, i32 0, i64 %t857
  br label %arr_rplace_end_683
arr_rplace_oob_682:
  store i32 0, i32* %t860
  br label %arr_rplace_end_683
arr_rplace_end_683:
  %t861 = phi i32* [ %t859, %arr_rplace_ok_681 ], [ %t860, %arr_rplace_oob_682 ]
  %t862 = load i32, i32* %t861
  %t863 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.53, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t863, i32 %t838, i32 %t844, i32 %t850, i32 %t856, i32 %t862)
  %t866 = load i8*, i8** %t6
  %t867 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t865, i32 0, i32 0
  store i8* %t866, i8** %t867
  %t868 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t865, i32 0, i32 1
  store i32 0, i32* %t868
  %t869 = load %GameOverFlash, %GameOverFlash* %t865
  store %GameOverFlash %t869, %GameOverFlash* %t864
  store i1 true, i1* %t870
  br label %while_cond_684
while_cond_684:
  %t871 = load i1, i1* %t870
  br i1 %t871, label %while_body_685, label %while_else_686
while_body_685:
  %t872 = call i1 @GameOverFlash__resume(%GameOverFlash* %t864)
  store i1 %t872, i1* %t870
  br label %while_cond_684
while_else_686:
  br label %while_end_687
while_end_687:
  br label %if_end_613
if_else_612:
  br label %if_end_613
if_end_613:
  br label %if_end_527
if_else_526:
  br label %if_end_527
if_end_527:
  br label %if_end_466
if_end_466:
  %t873 = load i8, i8* %t57
  %t874 = trunc i32 1 to i8
  %t875 = add i8 %t873, %t874
  store i8 %t875, i8* %t57
  %t877 = load i8, i8* %t57
  %t878 = uitofp i8 %t877 to float
  store float %t878, float* %t876
  %t880 = load float, float* %t876
  %t881 = fmul float %t880, 0x3FC3333340000000
  %t882 = call float @llvm.sin.f32(float %t881)
  %t883 = fmul float %t882, 0x4000000000000000
  store float %t883, float* %t879
  %t884 = load i8*, i8** %t6
  %t885 = icmp eq i8* %t884, null
  br i1 %t885, label %sdl_null_window_688, label %sdl_window_handle_ok_689
sdl_null_window_688:
  %t886 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.54, i64 0, i64 0
  call i32 @puts(i8* %t886)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_689:
  %t887 = call i8* @SDL_GetRenderer(i8* %t884)
  %t888 = and i32 18, 255
  %t889 = and i32 18, 255
  %t890 = shl i32 %t889, 8
  %t891 = or i32 %t888, %t890
  %t892 = and i32 24, 255
  %t893 = shl i32 %t892, 16
  %t894 = or i32 %t891, %t893
  %t895 = and i32 255, 255
  %t896 = shl i32 %t895, 24
  %t897 = or i32 %t894, %t896
  %t898 = and i32 %t897, 255
  %t899 = trunc i32 %t898 to i8
  %t900 = lshr i32 %t897, 8
  %t901 = and i32 %t900, 255
  %t902 = trunc i32 %t901 to i8
  %t903 = lshr i32 %t897, 16
  %t904 = and i32 %t903, 255
  %t905 = trunc i32 %t904 to i8
  %t906 = lshr i32 %t897, 24
  %t907 = and i32 %t906, 255
  %t908 = trunc i32 %t907 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t887, i8 %t899, i8 %t902, i8 %t905, i8 %t908)
  call i32 @SDL_RenderClear(i8* %t887)
  %t910 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t49
  %t911 = call { i32, i32 } @cell_px(%food__sb__grid__Cell %t910)
  store { i32, i32 } %t911, { i32, i32 }* %t909
  %t913 = load float, float* %t879
  %t914 = call i32 @llvm.fptosi.sat.i32.f32(float %t913)
  store i32 %t914, i32* %t912
  %t915 = load i8*, i8** %t6
  %t916 = icmp eq i8* %t915, null
  br i1 %t916, label %sdl_null_window_690, label %sdl_window_handle_ok_691
sdl_null_window_690:
  %t917 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.55, i64 0, i64 0
  call i32 @puts(i8* %t917)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_691:
  %t918 = call i8* @SDL_GetRenderer(i8* %t915)
  %t919 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t909, i32 0, i32 0
  %t920 = load i32, i32* %t919
  %t921 = load i32, i32* %t912
  %t922 = sub i32 %t920, %t921
  %t923 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t909, i32 0, i32 1
  %t924 = load i32, i32* %t923
  %t925 = load i32, i32* %t912
  %t926 = sub i32 %t924, %t925
  %t927 = sub i32 20, 1
  %t928 = load i32, i32* %t912
  %t929 = mul i32 %t928, 2
  %t930 = add i32 %t927, %t929
  %t931 = sub i32 20, 1
  %t932 = load i32, i32* %t912
  %t933 = mul i32 %t932, 2
  %t934 = add i32 %t931, %t933
  %t935 = and i32 230, 255
  %t936 = and i32 90, 255
  %t937 = shl i32 %t936, 8
  %t938 = or i32 %t935, %t937
  %t939 = and i32 90, 255
  %t940 = shl i32 %t939, 16
  %t941 = or i32 %t938, %t940
  %t942 = and i32 255, 255
  %t943 = shl i32 %t942, 24
  %t944 = or i32 %t941, %t943
  %t945 = and i32 %t944, 255
  %t946 = trunc i32 %t945 to i8
  %t947 = lshr i32 %t944, 8
  %t948 = and i32 %t947, 255
  %t949 = trunc i32 %t948 to i8
  %t950 = lshr i32 %t944, 16
  %t951 = and i32 %t950, 255
  %t952 = trunc i32 %t951 to i8
  %t953 = lshr i32 %t944, 24
  %t954 = and i32 %t953, 255
  %t955 = trunc i32 %t954 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t918, i8 %t946, i8 %t949, i8 %t952, i8 %t955)
  %t957 = getelementptr inbounds [16 x i8], [16 x i8]* %t956, i64 0, i64 0
  %t958 = bitcast i8* %t957 to i32*
  store i32 %t922, i32* %t958
  %t959 = getelementptr inbounds i8, i8* %t957, i64 4
  %t960 = bitcast i8* %t959 to i32*
  store i32 %t926, i32* %t960
  %t961 = getelementptr inbounds i8, i8* %t957, i64 8
  %t962 = bitcast i8* %t961 to i32*
  store i32 %t930, i32* %t962
  %t963 = getelementptr inbounds i8, i8* %t957, i64 12
  %t964 = bitcast i8* %t963 to i32*
  store i32 %t934, i32* %t964
  call i32 @SDL_RenderFillRect(i8* %t918, i8* %t957)
  store i32 0, i32* %t965
  br label %while_cond_692
while_cond_692:
  %t966 = load i32, i32* %t965
  %t967 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t47)
  %t968 = icmp slt i32 %t966, %t967
  br i1 %t968, label %while_body_693, label %while_else_694
while_body_693:
  %t970 = load i32, i32* %t965
  %t971 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t47)
  %t972 = sub i32 %t971, 1
  %t973 = icmp eq i32 %t970, %t972
  store i1 %t973, i1* %t969
  %t974 = load i8*, i8** %t6
  %t975 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t47, i32 0, i32 0
  %t976 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t975, i32 0, i32 0
  %t977 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t975, i32 0, i32 1
  %t978 = load i64, i64* %t977
  %t979 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t975, i32 0, i32 2
  %t980 = load i64, i64* %t979
  %t981 = load i32, i32* %t965
  %t982 = sext i32 %t981 to i64
  %t983 = load i64, i64* %t977
  %t984 = load i64, i64* %t979
  %t985 = icmp ult i64 %t982, %t984
  br i1 %t985, label %ring_rplace_ok_696, label %ring_rplace_oob_697
ring_rplace_ok_696:
  %t986 = add i64 %t983, %t982
  %t987 = urem i64 %t986, 768
  %t988 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t976, i32 0, i64 %t987
  br label %ring_rplace_end_698
ring_rplace_oob_697:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t989
  br label %ring_rplace_end_698
ring_rplace_end_698:
  %t990 = phi %food__sb__grid__Cell* [ %t988, %ring_rplace_ok_696 ], [ %t989, %ring_rplace_oob_697 ]
  %t991 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t990
  %t992 = load i1, i1* %t969
  %t993 = and i32 140, 255
  %t994 = and i32 230, 255
  %t995 = shl i32 %t994, 8
  %t996 = or i32 %t993, %t995
  %t997 = and i32 160, 255
  %t998 = shl i32 %t997, 16
  %t999 = or i32 %t996, %t998
  %t1000 = and i32 255, 255
  %t1001 = shl i32 %t1000, 24
  %t1002 = or i32 %t999, %t1001
  %t1003 = and i32 80, 255
  %t1004 = and i32 190, 255
  %t1005 = shl i32 %t1004, 8
  %t1006 = or i32 %t1003, %t1005
  %t1007 = and i32 120, 255
  %t1008 = shl i32 %t1007, 16
  %t1009 = or i32 %t1006, %t1008
  %t1010 = and i32 255, 255
  %t1011 = shl i32 %t1010, 24
  %t1012 = or i32 %t1009, %t1011
  %t1013 = call i32 @pick_color(i1 %t992, i32 %t1002, i32 %t1012)
  call void @draw_cell(i8* %t974, %food__sb__grid__Cell %t991, i32 %t1013)
  %t1014 = load i32, i32* %t965
  %t1015 = add i32 %t1014, 1
  store i32 %t1015, i32* %t965
  br label %while_cond_692
while_else_694:
  br label %while_end_695
while_end_695:
  call void @ParticlePool__update(%ParticlePool* %t68, float 0x3F90624DE0000000)
  %t1017 = load i8*, i8** %t6
  call void @ParticlePool__draw(%ParticlePool* %t68, i8* %t1017)
  call void @tick_particle_arena(float 0x3F90624DE0000000)
  call void @reclaim_dead_particles()
  %t1019 = load i64, i64* %t54
  %t1020 = zext i32 1 to i64
  %t1021 = shl i64 1, %t1020
  %t1022 = and i64 %t1019, %t1021
  %t1023 = icmp ne i64 %t1022, 0
  br i1 %t1023, label %if_then_699, label %if_else_700
if_then_699:
  %t1024 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t1025 = load i32, i32* %t1024
  %t1026 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 1
  %t1027 = load i32, i32* %t1026
  %t1028 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t47)
  %t1029 = load i64, i64* %t54
  %t1030 = zext i32 0 to i64
  %t1031 = shl i64 1, %t1030
  %t1032 = and i64 %t1029, %t1031
  %t1033 = icmp ne i64 %t1032, 0
  %t1034 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t1035 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t1036 = select i1 %t1033, i8* %t1034, i8* %t1035
  %t1037 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t47, i32 0, i32 1
  %t1038 = load i32, i32* %t1037
  %t1039 = call i8* @food__sb__grid__dir_name(i32 %t1038)
  call void @star_rc_release(i8* %t1039)
  %t1040 = load i1, i1* %t92
  %t1041 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.58, i64 0, i64 0
  %t1042 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.59, i64 0, i64 0
  %t1043 = select i1 %t1040, i8* %t1041, i8* %t1042
  %t1044 = getelementptr inbounds [59 x i8], [59 x i8]* @.str.60, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1044, i32 %t1025, i32 %t1027, i32 %t1028, i8* %t1036, i8* %t1039, i8* %t1043)
  br label %if_end_701
if_else_700:
  br label %if_end_701
if_end_701:
  %t1045 = load i8*, i8** %t6
  %t1046 = icmp eq i8* %t1045, null
  br i1 %t1046, label %sdl_null_window_702, label %sdl_window_handle_ok_703
sdl_null_window_702:
  %t1047 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.61, i64 0, i64 0
  call i32 @puts(i8* %t1047)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_703:
  %t1048 = call i8* @SDL_GetRenderer(i8* %t1045)
  call void @SDL_RenderPresent(i8* %t1048)
  %t1049 = icmp slt i32 16, 0
  %t1050 = select i1 %t1049, i32 0, i32 16
  call void @SDL_Delay(i32 %t1050)
  br label %while_cond_424
while_else_426:
  br label %while_end_427
while_end_427:
  %t1051 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 0
  %t1052 = load i32, i32* %t1051
  %t1053 = getelementptr inbounds %Stats, %Stats* %t29, i32 0, i32 1
  %t1054 = load i32, i32* %t1053
  %t1055 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.62, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1055, i32 %t1052, i32 %t1054)
  %t1056 = load i8, i8* %t55
  %t1057 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.63, i64 0, i64 0
  %t1058 = zext i8 %t1056 to i32
  call i32 (i8*, ...) @printf(i8* %t1057, i32 %t1058)
  %t1059 = load i8*, i8** %t6
  %t1060 = icmp eq i8* %t1059, null
  br i1 %t1060, label %sdl_null_window_704, label %sdl_window_handle_ok_705
sdl_null_window_704:
  %t1061 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.64, i64 0, i64 0
  call i32 @puts(i8* %t1061)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_705:
  %t1062 = call i8* @SDL_GetRenderer(i8* %t1059)
  call void @SDL_DestroyRenderer(i8* %t1062)
  call void @SDL_DestroyWindow(i8* %t1059)
  store i8* null, i8** %t6
  %t1063 = load i8*, i8** %t56
  call void @star_rc_release(i8* %t1063)
  %t1064 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t25, i32 0, i32 1
  %t1065 = load i8*, i8** %t1064
  call void @star_rc_release(i8* %t1065)
  %t1066 = load i8*, i8** %t23
  call void @star_rc_release(i8* %t1066)
  ret i32 0
}


; par/swarm worker functions
define i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %a, %food__sb__grid__Cell %b) {
entry:
  %t33 = extractvalue %food__sb__grid__Cell %a, 0
  %t34 = extractvalue %food__sb__grid__Cell %b, 0
  %t35 = icmp eq i32 %t33, %t34
  %t36 = extractvalue %food__sb__grid__Cell %a, 1
  %t37 = extractvalue %food__sb__grid__Cell %b, 1
  %t38 = icmp eq i32 %t36, %t37
  %t39 = and i1 %t35, %t38
  ret i1 %t39
}


define i1 @eq_e_food__sb__grid__Direction(i32 %a, i32 %b) {
entry:
  %t8 = icmp eq i32 %a, %b
  ret i1 %t8
}


define void @set_release_s_food__sb__grid__Cell(i8* %objp) {
entry:
  %t11 = bitcast i8* %objp to { %food__sb__grid__Cell*, i64, i64 }*
  %t12 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t11, i32 0, i32 0
  %t13 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t12
  %t14 = bitcast %food__sb__grid__Cell* %t13 to i8*
  call void @free(i8* %t14)
  ret void
}


define void @list_release_s_food__sb__grid__Cell(i8* %objp) {
entry:
  %t43 = bitcast i8* %objp to { %food__sb__grid__Cell*, i64, i64 }*
  %t44 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t43, i32 0, i32 0
  %t45 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t44
  %t46 = bitcast %food__sb__grid__Cell* %t45 to i8*
  call void @free(i8* %t46)
  ret void
}


define void @list_release_u8(i8* %objp) {
entry:
  %t52 = bitcast i8* %objp to { i8*, i64, i64 }*
  %t53 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t52, i32 0, i32 0
  %t54 = load i8*, i8** %t53
  %t55 = bitcast i8* %t54 to i8*
  call void @free(i8* %t55)
  ret void
}


define void @list_release_str(i8* %objp) {
entry:
  %t178 = alloca i64
  %t173 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t174 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t173, i32 0, i32 0
  %t175 = load i8**, i8*** %t174
  %t176 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t173, i32 0, i32 1
  %t177 = load i64, i64* %t176
  store i64 0, i64* %t178
  br label %list_release_cond_201
list_release_cond_201:
  %t179 = load i64, i64* %t178
  %t180 = icmp slt i64 %t179, %t177
  br i1 %t180, label %list_release_body_202, label %list_release_end_203
list_release_body_202:
  %t181 = getelementptr inbounds i8*, i8** %t175, i64 %t179
  %t182 = load i8*, i8** %t181
  call void @star_rc_release(i8* %t182)
  %t183 = add i64 %t179, 1
  store i64 %t183, i64* %t178
  br label %list_release_cond_201
list_release_end_203:
  %t184 = bitcast i8** %t175 to i8*
  call void @free(i8* %t184)
  ret void
}


define i32 @par_worker_299(i8* %argp) {
entry:
  %t9 = alloca i64
  %t1 = bitcast i8* %argp to { i64, i64, float* }*
  %t2 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t1, i32 0, i32 0
  %t3 = load i64, i64* %t2
  %t4 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t1, i32 0, i32 1
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t1, i32 0, i32 2
  %t7 = load float*, float** %t6
  %t8 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t3, i64* %t9
  br label %par_cond_300
par_cond_300:
  %t10 = load i64, i64* %t9
  %t11 = icmp slt i64 %t10, %t5
  br i1 %t11, label %par_body_301, label %par_end_304
par_body_301:
  %t12 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t10
  %t13 = load i64, i64* %t12
  %t14 = and i64 %t13, 1
  %t15 = icmp eq i64 %t14, 1
  br i1 %t15, label %par_live_302, label %par_incr_303
par_live_302:
  %t16 = getelementptr inbounds %Particle, %Particle* %t8, i64 %t10
  %t17 = load float, float* %t7
  %t18 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 4
  %t19 = load float, float* %t18
  %t20 = fsub float %t19, %t17
  %t21 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 4
  store float %t20, float* %t21
  br label %par_incr_303
par_incr_303:
  %t22 = add i64 %t10, 1
  store i64 %t22, i64* %t9
  br label %par_cond_300
par_end_304:
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
  %t23 = ptrtoint i8* %idx_arg to i64
  %t24 = trunc i64 %t23 to i32
  %t25 = call i32 @GetCurrentThreadId()
  %t26 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t24
  store i32 %t25, i32* %t26
  br label %loop
loop:
  %t27 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t24
  %t28 = load i8*, i8** %t27
  %t29 = call i32 @WaitForSingleObject(i8* %t28, i32 -1)
  %t30 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t24
  %t31 = load i32 (i8*)*, i32 (i8*)** %t30
  %t32 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t24
  %t33 = load i8*, i8** %t32
  %t34 = call i32 %t31(i8* %t33)
  %t35 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t24
  %t36 = load i8*, i8** %t35
  %t37 = call i32 @ReleaseSemaphore(i8* %t36, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t38 = load i1, i1* @par.pool.inited
  br i1 %t38, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t39 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t39, i8** @par.pool.serial_lock
  %t40 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t41 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t40, i8** %t41
  %t42 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t43 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t42, i8** %t43
  %t44 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t45 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t46 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t45, i8** %t46
  %t47 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t48 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t47, i8** %t48
  %t49 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t50 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t51 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t50, i8** %t51
  %t52 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t53 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t52, i8** %t53
  %t54 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t55 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t56 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t55, i8** %t56
  %t57 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t58 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t57, i8** %t58
  %t59 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_322(i8* %argp) {
entry:
  %t8 = alloca i64
  %t2 = bitcast i8* %argp to { i64, i64 }*
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 0
  %t4 = load i64, i64* %t3
  %t5 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 1
  %t6 = load i64, i64* %t5
  %t7 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t4, i64* %t8
  br label %par_cond_323
par_cond_323:
  %t9 = load i64, i64* %t8
  %t10 = icmp slt i64 %t9, %t6
  br i1 %t10, label %par_body_324, label %par_end_327
par_body_324:
  %t11 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t9
  %t12 = load i64, i64* %t11
  %t13 = and i64 %t12, 1
  %t14 = icmp eq i64 %t13, 1
  br i1 %t14, label %par_live_325, label %par_incr_326
par_live_325:
  %t15 = getelementptr inbounds %Particle, %Particle* %t7, i64 %t9
  %t16 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 4
  %t17 = load float, float* %t16
  %t18 = fcmp ogt float %t17, 0x0000000000000000
  br i1 %t18, label %if_then_328, label %if_else_329
if_then_328:
  %t19 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 0
  %t20 = load float, float* %t19
  %t21 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 1
  %t22 = load float, float* %t21
  %t23 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 4
  %t24 = load float, float* %t23
  %t25 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.19, i64 0, i64 0
  %t26 = fpext float %t20 to double
  %t27 = fpext float %t22 to double
  %t28 = fpext float %t24 to double
  call i32 (i8*, ...) @printf(i8* %t25, double %t26, double %t27, double %t28)
  br label %if_end_330
if_else_329:
  br label %if_end_330
if_end_330:
  br label %par_incr_326
par_incr_326:
  %t29 = add i64 %t9, 1
  store i64 %t29, i64* %t8
  br label %par_cond_323
par_end_327:
  ret i32 0
}


define void @list_release_symbol(i8* %objp) {
entry:
  %t350 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t351 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t350, i32 0, i32 0
  %t352 = load i64*, i64** %t351
  %t353 = bitcast i64* %t352 to i8*
  call void @free(i8* %t353)
  ret void
}



; Global Constants
@__star_reflect_Stats = private unnamed_addr constant [77 x i8] c"score:0:i32:export;high_score:4:i32:export;move_interval_ms:8:i32:tweakable;\00"
@.str.0 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"Up\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Down\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Left\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Right\00" }
@.str.4 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"w\00" }
@.str.5 = private unnamed_addr constant [74 x i8] c"star runtime error: file_write(..) called with a null/closed file handle\0A\00"
@.str.6 = private unnamed_addr constant [7 x i8] c"%d,%s\0A\00"
@.str.7 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.8 = private unnamed_addr constant [2 x i8] c"r\00"
@.str.9 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.10 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"r\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.12 = private unnamed_addr constant [78 x i8] c"star runtime error: file_read_line(..) called with a null/closed file handle\0A\00"
@.str.13 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.14 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c",\00" }
@.str.15 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.16 = private unnamed_addr constant [76 x i8] c"star runtime error: draw_pixel(..) called with a null/closed window handle\0A\00"
@.str.17 = private unnamed_addr constant { i64, i8*, [35 x i8] } { i64 -1, i8* null, [35 x i8] c"[arena] live particles (life > 0):\00" }
@.str.18 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.19 = private unnamed_addr constant [21 x i8] c"  x=%f y=%f life=%f\0A\00"
@.str.20 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.21 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.22 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.23 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.24 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.25 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.26 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Scratch` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.27 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Scratch` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.28 = private unnamed_addr constant [73 x i8] c"[genref demo] stale ref reads tag=%d (expect 0 -- despawned generation)\0A\00"
@.str.29 = private unnamed_addr constant [51 x i8] c"[genref demo] fresh ref reads tag=%d (expect 222)\0A\00"
@.str.30 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.31 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.32 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.33 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"Star Snake\00" }
@.str.34 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"window_create failed\00" }
@.str.35 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.36 = private unnamed_addr constant [37 x i8] c"[frame demo] node1.x + node2.y = %d\0A\00"
@.str.37 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"snake_save.txt\00" }
@.str.38 = private unnamed_addr constant [50 x i8] c"[save] loaded high score %d, difficulty tag \22%s\22\0A\00"
@.str.39 = private unnamed_addr constant [85 x i8] c"star runtime error: window_should_close(..) called with a null/closed window handle\0A\00"
@.str.40 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.41 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"move\00" }
@.str.42 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"eat\00" }
@.str.43 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.44 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.45 = private unnamed_addr constant [141 x i8] c"star runtime warning: arena `Particles` is full (256 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.46 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.47 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.48 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.49 = private unnamed_addr constant [54 x i8] c"[achievement] unlocked milestone %d -- badges now %u\0A\00"
@.str.50 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"die\00" }
@.str.51 = private unnamed_addr constant [26 x i8] c"[events] final event: %s\0A\00"
@.str.52 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.53 = private unnamed_addr constant [34 x i8] c"[leaderboard] %d, %d, %d, %d, %d\0A\00"
@.str.54 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.55 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.56 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.57 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.58 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.59 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.60 = private unnamed_addr constant [59 x i8] c"[debug] score=%d high=%d len=%d paused=%s dir=%s boost=%s\0A\00"
@.str.61 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.62 = private unnamed_addr constant [38 x i8] c"[stats] final score=%d high_score=%d\0A\00"
@.str.63 = private unnamed_addr constant [34 x i8] c"[stats] achievements bitfield=%u\0A\00"
@.str.64 = private unnamed_addr constant [80 x i8] c"star runtime error: window_destroy(..) called with a null/closed window handle\0A\00"
