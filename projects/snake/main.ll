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
define i32 @food__sb__grid__cols() {
entry:
  ret i32 32
}

define i32 @food__sb__grid__rows() {
entry:
  ret i32 24
}

define i32 @food__sb__grid__cell_size() {
entry:
  ret i32 20
}

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
  %t21 = alloca %food__sb__grid__Cell
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
  %t9 = call i32 @food__sb__grid__cols()
  %t10 = sub i32 %t9, 1
  store i32 %t10, i32* %t1
  br label %if_end_2
if_else_1:
  br label %if_end_2
if_end_2:
  %t11 = load i32, i32* %t1
  %t12 = call i32 @food__sb__grid__cols()
  %t13 = icmp sge i32 %t11, %t12
  br i1 %t13, label %if_then_3, label %if_else_4
if_then_3:
  store i32 0, i32* %t1
  br label %if_end_5
if_else_4:
  br label %if_end_5
if_end_5:
  %t14 = load i32, i32* %t4
  %t15 = icmp slt i32 %t14, 0
  br i1 %t15, label %if_then_6, label %if_else_7
if_then_6:
  %t16 = call i32 @food__sb__grid__rows()
  %t17 = sub i32 %t16, 1
  store i32 %t17, i32* %t4
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t18 = load i32, i32* %t4
  %t19 = call i32 @food__sb__grid__rows()
  %t20 = icmp sge i32 %t18, %t19
  br i1 %t20, label %if_then_9, label %if_else_10
if_then_9:
  store i32 0, i32* %t4
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t22 = load i32, i32* %t1
  %t23 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t21, i32 0, i32 0
  store i32 %t22, i32* %t23
  %t24 = load i32, i32* %t4
  %t25 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t21, i32 0, i32 1
  store i32 %t24, i32* %t25
  %t26 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t21
  ret %food__sb__grid__Cell %t26
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
  %t11 = alloca i32
  %t15 = alloca %food__sb__grid__Cell
  %t30 = alloca i64
  %t31 = alloca i1
  %t85 = alloca %food__sb__grid__Cell
  %t124 = alloca %food__sb__grid__Cell
  %t132 = alloca i32
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
  %t9 = call i32 @food__sb__grid__rows()
  %t10 = icmp slt i32 %t8, %t9
  br i1 %t10, label %while_body_75, label %while_else_76
while_body_75:
  store i32 0, i32* %t11
  br label %while_cond_78
while_cond_78:
  %t12 = load i32, i32* %t11
  %t13 = call i32 @food__sb__grid__cols()
  %t14 = icmp slt i32 %t12, %t13
  br i1 %t14, label %while_body_79, label %while_else_80
while_body_79:
  %t16 = load i32, i32* %t11
  %t17 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t15, i32 0, i32 0
  store i32 %t16, i32* %t17
  %t18 = load i32, i32* %t7
  %t19 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t15, i32 0, i32 1
  store i32 %t18, i32* %t19
  %t20 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t15
  %t21 = load i8*, i8** %t2
  %t22 = icmp eq i8* %t21, null
  br i1 %t22, label %set_read_null_82, label %set_read_real_83
set_read_null_82:
  br label %set_read_end_84
set_read_real_83:
  %t23 = bitcast i8* %t21 to { %food__sb__grid__Cell*, i64, i64 }*
  %t24 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t23, i32 0, i32 0
  %t25 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t24
  %t26 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t23, i32 0, i32 1
  %t27 = load i64, i64* %t26
  br label %set_read_end_84
set_read_end_84:
  %t28 = phi %food__sb__grid__Cell* [ null, %set_read_null_82 ], [ %t25, %set_read_real_83 ]
  %t29 = phi i64 [ 0, %set_read_null_82 ], [ %t27, %set_read_real_83 ]
  store i64 0, i64* %t30
  store i1 false, i1* %t31
  br label %find_cond_85
find_cond_85:
  %t32 = load i64, i64* %t30
  %t33 = icmp slt i64 %t32, %t29
  br i1 %t33, label %find_body_86, label %find_end_89
find_body_86:
  %t34 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t28, i64 %t32
  %t35 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t34
  br label %find_eq_check_87
find_eq_check_87:
  %t36 = call i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %t35, %food__sb__grid__Cell %t20)
  br i1 %t36, label %find_end_89, label %find_next_88
find_next_88:
  %t37 = add i64 %t32, 1
  store i64 %t37, i64* %t30
  br label %find_cond_85
find_end_89:
  %t38 = load i64, i64* %t30
  %t39 = icmp slt i64 %t38, %t29
  %t40 = xor i1 true, %t39
  br i1 %t40, label %if_then_90, label %if_else_91
if_then_90:
  %t41 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t42 = ptrtoint %food__sb__grid__Cell* %t41 to i64
  %t43 = load i8*, i8** %t6
  %t44 = icmp eq i8* %t43, null
  br i1 %t44, label %list_cow_alloc_93, label %list_cow_check_94
list_cow_alloc_93:
  %t49 = bitcast void (i8*)* @list_release_s_food__sb__grid__Cell to i8*
  %t50 = call i8* @star_rc_alloc(i64 24, i8* %t49)
  %t51 = bitcast i8* %t50 to { %food__sb__grid__Cell*, i64, i64 }*
  %t52 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t51, i32 0, i32 0
  store %food__sb__grid__Cell* null, %food__sb__grid__Cell** %t52
  %t53 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t51, i32 0, i32 1
  store i64 0, i64* %t53
  %t54 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t51, i32 0, i32 2
  store i64 0, i64* %t54
  store i8* %t50, i8** %t6
  br label %list_cow_done_95
list_cow_check_94:
  %t55 = getelementptr inbounds i8, i8* %t43, i64 -16
  %t56 = bitcast i8* %t55 to i64*
  %t57 = load atomic i64, i64* %t56 seq_cst, align 8
  %t58 = icmp eq i64 %t57, 1
  br i1 %t58, label %list_cow_done_95, label %list_cow_clone_96
list_cow_clone_96:
  %t59 = bitcast i8* %t43 to { %food__sb__grid__Cell*, i64, i64 }*
  %t60 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t59, i32 0, i32 0
  %t61 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t60
  %t62 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t59, i32 0, i32 1
  %t63 = load i64, i64* %t62
  %t64 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t59, i32 0, i32 2
  %t65 = load i64, i64* %t64
  %t66 = bitcast void (i8*)* @list_release_s_food__sb__grid__Cell to i8*
  %t67 = call i8* @star_rc_alloc(i64 24, i8* %t66)
  %t68 = bitcast i8* %t67 to { %food__sb__grid__Cell*, i64, i64 }*
  %t69 = mul i64 %t65, %t42
  %t70 = call i8* @malloc(i64 %t69)
  %t71 = bitcast i8* %t70 to %food__sb__grid__Cell*
  %t72 = icmp sgt i64 %t63, 0
  br i1 %t72, label %list_cow_copy_97, label %list_cow_after_copy_98
list_cow_copy_97:
  %t73 = mul i64 %t63, %t42
  %t74 = bitcast %food__sb__grid__Cell* %t61 to i8*
  call i8* @memcpy(i8* %t70, i8* %t74, i64 %t73)
  br label %list_cow_after_copy_98
list_cow_after_copy_98:
  %t75 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t68, i32 0, i32 0
  store %food__sb__grid__Cell* %t71, %food__sb__grid__Cell** %t75
  %t76 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t68, i32 0, i32 1
  store i64 %t63, i64* %t76
  %t77 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t68, i32 0, i32 2
  store i64 %t65, i64* %t77
  call void @star_rc_release(i8* %t43)
  store i8* %t67, i8** %t6
  br label %list_cow_done_95
list_cow_done_95:
  %t78 = load i8*, i8** %t6
  %t79 = bitcast i8* %t78 to { %food__sb__grid__Cell*, i64, i64 }*
  %t80 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t79, i32 0, i32 0
  %t81 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t80
  %t82 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t79, i32 0, i32 1
  %t83 = load i64, i64* %t82
  %t84 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t79, i32 0, i32 2
  %t86 = load i32, i32* %t11
  %t87 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t85, i32 0, i32 0
  store i32 %t86, i32* %t87
  %t88 = load i32, i32* %t7
  %t89 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t85, i32 0, i32 1
  store i32 %t88, i32* %t89
  %t90 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t85
  %t91 = load i64, i64* %t84
  %t92 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t80
  %t93 = load i64, i64* %t82
  %t94 = icmp sge i64 %t93, %t91
  br i1 %t94, label %list_push_grow_99, label %list_push_store_100
list_push_grow_99:
  %t95 = mul i64 %t91, 2
  %t96 = icmp sgt i64 %t95, 0
  %t97 = select i1 %t96, i64 %t95, i64 1
  %t98 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t99 = ptrtoint %food__sb__grid__Cell* %t98 to i64
  %t100 = mul i64 %t97, %t99
  %t101 = call i8* @malloc(i64 %t100)
  %t102 = bitcast i8* %t101 to %food__sb__grid__Cell*
  %t103 = icmp sgt i64 %t91, 0
  br i1 %t103, label %list_push_copy_101, label %list_push_after_copy_102
list_push_copy_101:
  %t104 = mul i64 %t93, %t99
  %t105 = bitcast %food__sb__grid__Cell* %t92 to i8*
  call i8* @memcpy(i8* %t101, i8* %t105, i64 %t104)
  call void @free(i8* %t105)
  br label %list_push_after_copy_102
list_push_after_copy_102:
  store %food__sb__grid__Cell* %t102, %food__sb__grid__Cell** %t80
  store i64 %t97, i64* %t84
  br label %list_push_store_100
list_push_store_100:
  %t106 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t80
  %t107 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t106, i64 %t93
  store %food__sb__grid__Cell %t90, %food__sb__grid__Cell* %t107
  %t108 = add i64 %t93, 1
  store i64 %t108, i64* %t82
  br label %if_end_92
if_else_91:
  br label %if_end_92
if_end_92:
  %t109 = load i32, i32* %t11
  %t110 = add i32 %t109, 1
  store i32 %t110, i32* %t11
  br label %while_cond_78
while_else_80:
  br label %while_end_81
while_end_81:
  %t111 = load i32, i32* %t7
  %t112 = add i32 %t111, 1
  store i32 %t112, i32* %t7
  br label %while_cond_74
while_else_76:
  br label %while_end_77
while_end_77:
  %t113 = load i8*, i8** %t6
  %t114 = icmp eq i8* %t113, null
  br i1 %t114, label %list_read_null_103, label %list_read_real_104
list_read_null_103:
  br label %list_read_end_105
list_read_real_104:
  %t115 = bitcast i8* %t113 to { %food__sb__grid__Cell*, i64, i64 }*
  %t116 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t115, i32 0, i32 0
  %t117 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t116
  %t118 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t115, i32 0, i32 1
  %t119 = load i64, i64* %t118
  br label %list_read_end_105
list_read_end_105:
  %t120 = phi %food__sb__grid__Cell* [ null, %list_read_null_103 ], [ %t117, %list_read_real_104 ]
  %t121 = phi i64 [ 0, %list_read_null_103 ], [ %t119, %list_read_real_104 ]
  %t122 = trunc i64 %t121 to i32
  %t123 = icmp eq i32 %t122, 0
  br i1 %t123, label %if_then_106, label %if_else_107
if_then_106:
  %t125 = sub i32 0, 1
  %t126 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t124, i32 0, i32 0
  store i32 %t125, i32* %t126
  %t127 = sub i32 0, 1
  %t128 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t124, i32 0, i32 1
  store i32 %t127, i32* %t128
  %t129 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t124
  %t130 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t130)
  %t131 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t131)
  ret %food__sb__grid__Cell %t129
if_else_107:
  br label %if_end_108
if_end_108:
  %t133 = load i8*, i8** %t6
  %t134 = icmp eq i8* %t133, null
  br i1 %t134, label %list_read_null_109, label %list_read_real_110
list_read_null_109:
  br label %list_read_end_111
list_read_real_110:
  %t135 = bitcast i8* %t133 to { %food__sb__grid__Cell*, i64, i64 }*
  %t136 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t135, i32 0, i32 0
  %t137 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t136
  %t138 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t135, i32 0, i32 1
  %t139 = load i64, i64* %t138
  br label %list_read_end_111
list_read_end_111:
  %t140 = phi %food__sb__grid__Cell* [ null, %list_read_null_109 ], [ %t137, %list_read_real_110 ]
  %t141 = phi i64 [ 0, %list_read_null_109 ], [ %t139, %list_read_real_110 ]
  %t142 = trunc i64 %t141 to i32
  %t143 = sub i32 %t142, 0
  %t144 = icmp sle i32 %t143, 0
  %t145 = select i1 %t144, i32 1, i32 %t143
  %t146 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t146, i32 -1)
  %t147 = load i32, i32* @rng.state
  %t148 = shl i32 %t147, 13
  %t149 = xor i32 %t147, %t148
  %t150 = lshr i32 %t149, 17
  %t151 = xor i32 %t149, %t150
  %t152 = shl i32 %t151, 5
  %t153 = xor i32 %t151, %t152
  store i32 %t153, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t146, i32 1, i32* null)
  %t154 = and i32 %t153, 2147483647
  %t155 = urem i32 %t154, %t145
  %t156 = add i32 0, %t155
  store i32 %t156, i32* %t132
  %t157 = load i8*, i8** %t6
  %t158 = icmp eq i8* %t157, null
  br i1 %t158, label %list_read_null_112, label %list_read_real_113
list_read_null_112:
  br label %list_read_end_114
list_read_real_113:
  %t159 = bitcast i8* %t157 to { %food__sb__grid__Cell*, i64, i64 }*
  %t160 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t159, i32 0, i32 0
  %t161 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t160
  %t162 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t159, i32 0, i32 1
  %t163 = load i64, i64* %t162
  br label %list_read_end_114
list_read_end_114:
  %t164 = phi %food__sb__grid__Cell* [ null, %list_read_null_112 ], [ %t161, %list_read_real_113 ]
  %t165 = phi i64 [ 0, %list_read_null_112 ], [ %t163, %list_read_real_113 ]
  %t166 = load i32, i32* %t132
  %t167 = sext i32 %t166 to i64
  %t168 = icmp ult i64 %t167, %t165
  br i1 %t168, label %list_idx_ok_115, label %list_idx_oob_116
list_idx_ok_115:
  %t169 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t164, i64 %t167
  %t170 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t169
  br label %list_idx_end_117
list_idx_oob_116:
  br label %list_idx_end_117
list_idx_end_117:
  %t171 = phi %food__sb__grid__Cell [ %t170, %list_idx_ok_115 ], [ zeroinitializer, %list_idx_oob_116 ]
  %t172 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t172)
  %t173 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t173)
  ret %food__sb__grid__Cell %t171
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
  %t4 = call i32 @food__sb__grid__cell_size()
  %t5 = mul i32 %t3, %t4
  %t6 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 0
  store i32 %t5, i32* %t6
  %t7 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 1
  %t8 = load i32, i32* %t7
  %t9 = call i32 @food__sb__grid__cell_size()
  %t10 = mul i32 %t8, %t9
  %t11 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 1
  store i32 %t10, i32* %t11
  %t12 = load { i32, i32 }, { i32, i32 }* %t1
  ret { i32, i32 } %t12
}

define void @draw_cell(i8* %w, %food__sb__grid__Cell %c, i32 %color) {
entry:
  %t0 = alloca i8*
  %t1 = alloca %food__sb__grid__Cell
  %t2 = alloca i32
  %t3 = alloca { i32, i32 }
  %t30 = alloca [16 x i8]
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
  %t14 = call i32 @food__sb__grid__cell_size()
  %t15 = sub i32 %t14, 1
  %t16 = call i32 @food__sb__grid__cell_size()
  %t17 = sub i32 %t16, 1
  %t18 = load i32, i32* %t2
  %t19 = and i32 %t18, 255
  %t20 = trunc i32 %t19 to i8
  %t21 = lshr i32 %t18, 8
  %t22 = and i32 %t21, 255
  %t23 = trunc i32 %t22 to i8
  %t24 = lshr i32 %t18, 16
  %t25 = and i32 %t24, 255
  %t26 = trunc i32 %t25 to i8
  %t27 = lshr i32 %t18, 24
  %t28 = and i32 %t27, 255
  %t29 = trunc i32 %t28 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t9, i8 %t20, i8 %t23, i8 %t26, i8 %t29)
  %t31 = getelementptr inbounds [16 x i8], [16 x i8]* %t30, i64 0, i64 0
  %t32 = bitcast i8* %t31 to i32*
  store i32 %t11, i32* %t32
  %t33 = getelementptr inbounds i8, i8* %t31, i64 4
  %t34 = bitcast i8* %t33 to i32*
  store i32 %t13, i32* %t34
  %t35 = getelementptr inbounds i8, i8* %t31, i64 8
  %t36 = bitcast i8* %t35 to i32*
  store i32 %t15, i32* %t36
  %t37 = getelementptr inbounds i8, i8* %t31, i64 12
  %t38 = bitcast i8* %t37 to i32*
  store i32 %t17, i32* %t38
  call i32 @SDL_RenderFillRect(i8* %t9, i8* %t31)
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
  %t6 = alloca i32
  %t10 = alloca i8*
  %t27 = alloca i8*
  %t29 = alloca { i32, i8* }
  %t33 = alloca %Stats
  %t34 = alloca %Stats
  %t51 = alloca %food__sb__Snake
  %t53 = alloca %food__sb__grid__Cell
  %t58 = alloca i64
  %t59 = alloca i8
  %t60 = alloca i8*
  %t61 = alloca i8
  %t63 = alloca [5 x i32]
  %t64 = alloca [5 x i32]
  %t66 = alloca i64
  %t72 = alloca %ParticlePool
  %t73 = alloca %ParticlePool
  %t74 = alloca [32 x %Particle]
  %t75 = alloca %Particle
  %t83 = alloca i64
  %t91 = alloca i32
  %t93 = alloca i1
  %t94 = alloca i1
  %t95 = alloca i1
  %t96 = alloca i1
  %t97 = alloca i32
  %t98 = alloca i32
  %t99 = alloca i32
  %t100 = alloca i32
  %t101 = alloca i32
  %t102 = alloca i32
  %t103 = alloca i32
  %t104 = alloca i32
  %t105 = alloca i32
  %t106 = alloca i32
  %t107 = alloca i32
  %t108 = alloca i32
  %t109 = alloca i32
  %t113 = alloca i1
  %t114 = alloca [56 x i8]
  %t132 = alloca i1
  %t162 = alloca i1
  %t195 = alloca i1
  %t316 = alloca i32
  %t330 = alloca i32
  %t345 = alloca i32
  %t348 = alloca %food__sb__grid__Cell
  %t398 = alloca i64
  %t496 = alloca i64
  %t539 = alloca { i32, i32 }
  %t542 = alloca float
  %t555 = alloca float
  %t590 = alloca %Particle
  %t605 = alloca %FlashOnEat
  %t606 = alloca %FlashOnEat
  %t611 = alloca i1
  %t636 = alloca i32
  %t717 = alloca i64
  %t802 = alloca i32
  %t814 = alloca i32
  %t830 = alloca i32
  %t842 = alloca i32
  %t848 = alloca i32
  %t854 = alloca i32
  %t860 = alloca i32
  %t866 = alloca i32
  %t870 = alloca %GameOverFlash
  %t871 = alloca %GameOverFlash
  %t876 = alloca i1
  %t882 = alloca float
  %t885 = alloca float
  %t915 = alloca { i32, i32 }
  %t918 = alloca i32
  %t964 = alloca [16 x i8]
  %t973 = alloca i32
  %t977 = alloca i1
  %t997 = alloca %food__sb__grid__Cell
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = call i32 @food__sb__grid__cols()
  %t4 = call i32 @food__sb__grid__cell_size()
  %t5 = mul i32 %t3, %t4
  store i32 %t5, i32* %t2
  %t7 = call i32 @food__sb__grid__rows()
  %t8 = call i32 @food__sb__grid__cell_size()
  %t9 = mul i32 %t7, %t8
  store i32 %t9, i32* %t6
  %t11 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.33, i64 0, i32 2, i64 0
  %t12 = load i32, i32* %t2
  %t13 = load i32, i32* %t6
  %t14 = call i32 @SDL_Init(i32 32)
  %t15 = icmp ne i32 %t14, 0
  br i1 %t15, label %sdl_init_fail_408, label %sdl_init_ok_409
sdl_init_fail_408:
  call void @star_rc_release(i8* %t11)
  br label %window_create_end_410
sdl_init_ok_409:
  %t16 = call i8* @SDL_CreateWindow(i8* %t11, i32 536805376, i32 536805376, i32 %t12, i32 %t13, i32 0)
  call void @star_rc_release(i8* %t11)
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %sdl_window_fail_411, label %sdl_window_ok_412
sdl_window_fail_411:
  br label %window_create_end_410
sdl_window_ok_412:
  %t18 = call i8* @SDL_CreateRenderer(i8* %t16, i32 -1, i32 0)
  %t19 = icmp eq i8* %t18, null
  br i1 %t19, label %sdl_renderer_fail_413, label %sdl_renderer_ok_414
sdl_renderer_fail_413:
  call void @SDL_DestroyWindow(i8* %t16)
  br label %window_create_end_410
sdl_renderer_ok_414:
  br label %window_create_end_410
window_create_end_410:
  %t20 = phi i8* [ null, %sdl_init_fail_408 ], [ null, %sdl_window_fail_411 ], [ null, %sdl_renderer_fail_413 ], [ %t16, %sdl_renderer_ok_414 ]
  store i8* %t20, i8** %t10
  %t21 = load i8*, i8** %t10
  %t22 = icmp eq i8* %t21, null
  br i1 %t22, label %if_then_415, label %if_else_416
if_then_415:
  %t23 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.34, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t23)
  call i32 (i8*, ...) @printf(i8* %t23)
  %t24 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.35, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24)
  ret i32 0
if_else_416:
  br label %if_end_417
if_end_417:
  call void @demo_genref_staleness()
  %t25 = call i32 @frame_demo()
  %t26 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.36, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t26, i32 %t25)
  %t28 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.37, i64 0, i32 2, i64 0
  store i8* %t28, i8** %t27
  %t30 = load i8*, i8** %t27
  %t31 = load i8*, i8** %t27
  call void @star_rc_retain(i8* %t31)
  %t32 = call { i32, i8* } @save__load_high_score(i8* %t30)
  store { i32, i8* } %t32, { i32, i8* }* %t29
  %t35 = getelementptr inbounds %Stats, %Stats* %t34, i32 0, i32 0
  store i32 0, i32* %t35
  %t36 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t29, i32 0, i32 0
  %t37 = load i32, i32* %t36
  %t38 = getelementptr inbounds %Stats, %Stats* %t34, i32 0, i32 1
  store i32 %t37, i32* %t38
  %t39 = getelementptr inbounds %Stats, %Stats* %t34, i32 0, i32 2
  store i32 120, i32* %t39
  %t40 = load %Stats, %Stats* %t34
  store %Stats %t40, %Stats* %t33
  %t41 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t42 = load i32, i32* %t41
  %t43 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t29, i32 0, i32 1
  %t44 = load i8*, i8** %t43
  %t45 = load i8*, i8** %t43
  call void @star_rc_retain(i8* %t45)
  call void @star_rc_release(i8* %t44)
  %t46 = getelementptr inbounds [50 x i8], [50 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t46, i32 %t42, i8* %t44)
  %t47 = call i32 @SDL_GetTicks()
  %t48 = icmp eq i32 %t47, 0
  %t49 = select i1 %t48, i32 1, i32 %t47
  %t50 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t50, i32 -1)
  store i32 %t49, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t50, i32 1, i32* null)
  %t52 = call %food__sb__Snake @food__sb__make_snake()
  store %food__sb__Snake %t52, %food__sb__Snake* %t51
  %t54 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 0
  %t55 = load { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t54
  %t56 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t57 = call %food__sb__grid__Cell @food__spawn_food({ [768 x %food__sb__grid__Cell], i64, i64 } %t55, i32 %t56)
  store %food__sb__grid__Cell %t57, %food__sb__grid__Cell* %t53
  store i64 0, i64* %t58
  store i8 0, i8* %t59
  store i8* null, i8** %t60
  %t62 = trunc i32 0 to i8
  store i8 %t62, i8* %t61
  %t65 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 0
  store i32 0, i32* %t65
  store i64 1, i64* %t66
  br label %arr_rep_cond_418
arr_rep_cond_418:
  %t67 = load i64, i64* %t66
  %t68 = icmp ult i64 %t67, 5
  br i1 %t68, label %arr_rep_body_419, label %arr_rep_end_420
arr_rep_body_419:
  %t69 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 %t67
  store i32 0, i32* %t69
  %t70 = add i64 %t67, 1
  store i64 %t70, i64* %t66
  br label %arr_rep_cond_418
arr_rep_end_420:
  %t71 = load [5 x i32], [5 x i32]* %t64
  store [5 x i32] %t71, [5 x i32]* %t63
  %t76 = getelementptr inbounds %Particle, %Particle* %t75, i32 0, i32 0
  store float 0x0000000000000000, float* %t76
  %t77 = getelementptr inbounds %Particle, %Particle* %t75, i32 0, i32 1
  store float 0x0000000000000000, float* %t77
  %t78 = getelementptr inbounds %Particle, %Particle* %t75, i32 0, i32 2
  store float 0x0000000000000000, float* %t78
  %t79 = getelementptr inbounds %Particle, %Particle* %t75, i32 0, i32 3
  store float 0x0000000000000000, float* %t79
  %t80 = getelementptr inbounds %Particle, %Particle* %t75, i32 0, i32 4
  store float 0x0000000000000000, float* %t80
  %t81 = load %Particle, %Particle* %t75
  %t82 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t74, i32 0, i64 0
  store %Particle %t81, %Particle* %t82
  store i64 1, i64* %t83
  br label %arr_rep_cond_421
arr_rep_cond_421:
  %t84 = load i64, i64* %t83
  %t85 = icmp ult i64 %t84, 32
  br i1 %t85, label %arr_rep_body_422, label %arr_rep_end_423
arr_rep_body_422:
  %t86 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t74, i32 0, i64 %t84
  store %Particle %t81, %Particle* %t86
  %t87 = add i64 %t84, 1
  store i64 %t87, i64* %t83
  br label %arr_rep_cond_421
arr_rep_end_423:
  %t88 = load [32 x %Particle], [32 x %Particle]* %t74
  %t89 = getelementptr inbounds %ParticlePool, %ParticlePool* %t73, i32 0, i32 0
  store [32 x %Particle] %t88, [32 x %Particle]* %t89
  %t90 = load %ParticlePool, %ParticlePool* %t73
  store %ParticlePool %t90, %ParticlePool* %t72
  %t92 = call i32 @SDL_GetTicks()
  store i32 %t92, i32* %t91
  store i1 false, i1* %t93
  store i1 false, i1* %t94
  store i1 false, i1* %t95
  store i1 false, i1* %t96
  store i32 41, i32* %t97
  store i32 19, i32* %t98
  store i32 58, i32* %t99
  store i32 21, i32* %t100
  store i32 225, i32* %t101
  store i32 82, i32* %t102
  store i32 81, i32* %t103
  store i32 80, i32* %t104
  store i32 79, i32* %t105
  store i32 26, i32* %t106
  store i32 22, i32* %t107
  store i32 4, i32* %t108
  store i32 7, i32* %t109
  br label %while_cond_424
while_cond_424:
  br i1 true, label %while_body_425, label %while_else_426
while_body_425:
  %t110 = load i8*, i8** %t10
  %t111 = icmp eq i8* %t110, null
  br i1 %t111, label %sdl_null_window_428, label %sdl_window_handle_ok_429
sdl_null_window_428:
  %t112 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.39, i64 0, i64 0
  call i32 @puts(i8* %t112)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_429:
  store i1 false, i1* %t113
  %t115 = getelementptr inbounds [56 x i8], [56 x i8]* %t114, i64 0, i64 0
  br label %sdl_poll_cond_430
sdl_poll_cond_430:
  %t116 = call i32 @SDL_PollEvent(i8* %t115)
  %t117 = icmp ne i32 %t116, 0
  br i1 %t117, label %sdl_poll_body_431, label %sdl_poll_end_433
sdl_poll_body_431:
  %t118 = bitcast i8* %t115 to i32*
  %t119 = load i32, i32* %t118
  %t120 = icmp eq i32 %t119, 256
  br i1 %t120, label %sdl_poll_set_quit_432, label %sdl_poll_cond_430
sdl_poll_set_quit_432:
  store i1 true, i1* %t113
  br label %sdl_poll_cond_430
sdl_poll_end_433:
  %t121 = load i1, i1* %t113
  br i1 %t121, label %if_then_434, label %if_else_435
if_then_434:
  br label %while_end_427
if_else_435:
  br label %if_end_436
if_end_436:
  %t122 = load i32, i32* %t97
  %t123 = icmp sge i32 %t122, 0
  %t124 = icmp slt i32 %t122, 512
  %t125 = and i1 %t123, %t124
  br i1 %t125, label %key_down_read_437, label %key_down_end_438
key_down_read_437:
  %t126 = call i8* @SDL_GetKeyboardState(i32* null)
  %t127 = sext i32 %t122 to i64
  %t128 = getelementptr inbounds i8, i8* %t126, i64 %t127
  %t129 = load i8, i8* %t128
  %t130 = icmp ne i8 %t129, 0
  br label %key_down_end_438
key_down_end_438:
  %t131 = phi i1 [ false, %if_end_436 ], [ %t130, %key_down_read_437 ]
  br i1 %t131, label %if_then_439, label %if_else_440
if_then_439:
  br label %while_end_427
if_else_440:
  br label %if_end_441
if_end_441:
  %t133 = load i32, i32* %t98
  %t134 = icmp sge i32 %t133, 0
  %t135 = icmp slt i32 %t133, 512
  %t136 = and i1 %t134, %t135
  br i1 %t136, label %key_down_read_442, label %key_down_end_443
key_down_read_442:
  %t137 = call i8* @SDL_GetKeyboardState(i32* null)
  %t138 = sext i32 %t133 to i64
  %t139 = getelementptr inbounds i8, i8* %t137, i64 %t138
  %t140 = load i8, i8* %t139
  %t141 = icmp ne i8 %t140, 0
  br label %key_down_end_443
key_down_end_443:
  %t142 = phi i1 [ false, %if_end_441 ], [ %t141, %key_down_read_442 ]
  store i1 %t142, i1* %t132
  %t143 = load i1, i1* %t132
  br i1 %t143, label %logic_rhs_444, label %logic_short_445
logic_rhs_444:
  %t144 = load i1, i1* %t93
  %t145 = xor i1 true, %t144
  br label %logic_end_446
logic_short_445:
  br label %logic_end_446
logic_end_446:
  %t146 = phi i1 [ %t145, %logic_rhs_444 ], [ false, %logic_short_445 ]
  br i1 %t146, label %if_then_447, label %if_else_448
if_then_447:
  %t147 = load i64, i64* %t58
  %t148 = zext i32 0 to i64
  %t149 = shl i64 1, %t148
  %t150 = and i64 %t147, %t149
  %t151 = icmp ne i64 %t150, 0
  br i1 %t151, label %if_then_450, label %if_else_451
if_then_450:
  %t152 = load i64, i64* %t58
  %t153 = zext i32 0 to i64
  %t154 = shl i64 1, %t153
  %t156 = xor i64 %t154, -1
  %t155 = and i64 %t152, %t156
  store i64 %t155, i64* %t58
  br label %if_end_452
if_else_451:
  %t157 = load i64, i64* %t58
  %t158 = zext i32 0 to i64
  %t159 = shl i64 1, %t158
  %t160 = or i64 %t157, %t159
  store i64 %t160, i64* %t58
  br label %if_end_452
if_end_452:
  br label %if_end_449
if_else_448:
  br label %if_end_449
if_end_449:
  %t161 = load i1, i1* %t132
  store i1 %t161, i1* %t93
  %t163 = load i32, i32* %t99
  %t164 = icmp sge i32 %t163, 0
  %t165 = icmp slt i32 %t163, 512
  %t166 = and i1 %t164, %t165
  br i1 %t166, label %key_down_read_453, label %key_down_end_454
key_down_read_453:
  %t167 = call i8* @SDL_GetKeyboardState(i32* null)
  %t168 = sext i32 %t163 to i64
  %t169 = getelementptr inbounds i8, i8* %t167, i64 %t168
  %t170 = load i8, i8* %t169
  %t171 = icmp ne i8 %t170, 0
  br label %key_down_end_454
key_down_end_454:
  %t172 = phi i1 [ false, %if_end_449 ], [ %t171, %key_down_read_453 ]
  store i1 %t172, i1* %t162
  %t173 = load i1, i1* %t162
  br i1 %t173, label %logic_rhs_455, label %logic_short_456
logic_rhs_455:
  %t174 = load i1, i1* %t94
  %t175 = xor i1 true, %t174
  br label %logic_end_457
logic_short_456:
  br label %logic_end_457
logic_end_457:
  %t176 = phi i1 [ %t175, %logic_rhs_455 ], [ false, %logic_short_456 ]
  br i1 %t176, label %if_then_458, label %if_else_459
if_then_458:
  %t177 = load i64, i64* %t58
  %t178 = zext i32 1 to i64
  %t179 = shl i64 1, %t178
  %t180 = and i64 %t177, %t179
  %t181 = icmp ne i64 %t180, 0
  br i1 %t181, label %if_then_461, label %if_else_462
if_then_461:
  %t182 = load i64, i64* %t58
  %t183 = zext i32 1 to i64
  %t184 = shl i64 1, %t183
  %t186 = xor i64 %t184, -1
  %t185 = and i64 %t182, %t186
  store i64 %t185, i64* %t58
  br label %if_end_463
if_else_462:
  %t187 = load i64, i64* %t58
  %t188 = zext i32 1 to i64
  %t189 = shl i64 1, %t188
  %t190 = or i64 %t187, %t189
  store i64 %t190, i64* %t58
  call void @dump_particle_arena()
  br label %if_end_463
if_end_463:
  br label %if_end_460
if_else_459:
  br label %if_end_460
if_end_460:
  %t191 = load i1, i1* %t162
  store i1 %t191, i1* %t94
  %t192 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 4
  %t193 = load i1, i1* %t192
  %t194 = xor i1 true, %t193
  br i1 %t194, label %if_then_464, label %if_else_465
if_then_464:
  %t196 = load i32, i32* %t100
  %t197 = icmp sge i32 %t196, 0
  %t198 = icmp slt i32 %t196, 512
  %t199 = and i1 %t197, %t198
  br i1 %t199, label %key_down_read_467, label %key_down_end_468
key_down_read_467:
  %t200 = call i8* @SDL_GetKeyboardState(i32* null)
  %t201 = sext i32 %t196 to i64
  %t202 = getelementptr inbounds i8, i8* %t200, i64 %t201
  %t203 = load i8, i8* %t202
  %t204 = icmp ne i8 %t203, 0
  br label %key_down_end_468
key_down_end_468:
  %t205 = phi i1 [ false, %if_then_464 ], [ %t204, %key_down_read_467 ]
  store i1 %t205, i1* %t195
  %t206 = load i1, i1* %t195
  br i1 %t206, label %logic_rhs_469, label %logic_short_470
logic_rhs_469:
  %t207 = load i1, i1* %t95
  %t208 = xor i1 true, %t207
  br label %logic_end_471
logic_short_470:
  br label %logic_end_471
logic_end_471:
  %t209 = phi i1 [ %t208, %logic_rhs_469 ], [ false, %logic_short_470 ]
  br i1 %t209, label %if_then_472, label %if_else_473
if_then_472:
  %t210 = call %food__sb__Snake @food__sb__make_snake()
  store %food__sb__Snake %t210, %food__sb__Snake* %t51
  %t211 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 0
  %t212 = load { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t211
  %t213 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t214 = call %food__sb__grid__Cell @food__spawn_food({ [768 x %food__sb__grid__Cell], i64, i64 } %t212, i32 %t213)
  store %food__sb__grid__Cell %t214, %food__sb__grid__Cell* %t53
  %t215 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  store i32 0, i32* %t215
  %t216 = load i8*, i8** %t60
  call void @star_rc_release(i8* %t216)
  store i8* null, i8** %t60
  br label %if_end_474
if_else_473:
  br label %if_end_474
if_end_474:
  %t217 = load i1, i1* %t195
  store i1 %t217, i1* %t95
  br label %if_end_466
if_else_465:
  %t218 = load i32, i32* %t102
  %t219 = icmp sge i32 %t218, 0
  %t220 = icmp slt i32 %t218, 512
  %t221 = and i1 %t219, %t220
  br i1 %t221, label %key_down_read_475, label %key_down_end_476
key_down_read_475:
  %t222 = call i8* @SDL_GetKeyboardState(i32* null)
  %t223 = sext i32 %t218 to i64
  %t224 = getelementptr inbounds i8, i8* %t222, i64 %t223
  %t225 = load i8, i8* %t224
  %t226 = icmp ne i8 %t225, 0
  br label %key_down_end_476
key_down_end_476:
  %t227 = phi i1 [ false, %if_else_465 ], [ %t226, %key_down_read_475 ]
  br i1 %t227, label %logic_short_478, label %logic_rhs_477
logic_rhs_477:
  %t228 = load i32, i32* %t106
  %t229 = icmp sge i32 %t228, 0
  %t230 = icmp slt i32 %t228, 512
  %t231 = and i1 %t229, %t230
  br i1 %t231, label %key_down_read_480, label %key_down_end_481
key_down_read_480:
  %t232 = call i8* @SDL_GetKeyboardState(i32* null)
  %t233 = sext i32 %t228 to i64
  %t234 = getelementptr inbounds i8, i8* %t232, i64 %t233
  %t235 = load i8, i8* %t234
  %t236 = icmp ne i8 %t235, 0
  br label %key_down_end_481
key_down_end_481:
  %t237 = phi i1 [ false, %logic_rhs_477 ], [ %t236, %key_down_read_480 ]
  br label %logic_end_479
logic_short_478:
  br label %logic_end_479
logic_end_479:
  %t238 = phi i1 [ %t237, %key_down_end_481 ], [ true, %logic_short_478 ]
  br i1 %t238, label %if_then_482, label %if_else_483
if_then_482:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t51, i32 0)
  br label %if_end_484
if_else_483:
  br label %if_end_484
if_end_484:
  %t240 = load i32, i32* %t103
  %t241 = icmp sge i32 %t240, 0
  %t242 = icmp slt i32 %t240, 512
  %t243 = and i1 %t241, %t242
  br i1 %t243, label %key_down_read_485, label %key_down_end_486
key_down_read_485:
  %t244 = call i8* @SDL_GetKeyboardState(i32* null)
  %t245 = sext i32 %t240 to i64
  %t246 = getelementptr inbounds i8, i8* %t244, i64 %t245
  %t247 = load i8, i8* %t246
  %t248 = icmp ne i8 %t247, 0
  br label %key_down_end_486
key_down_end_486:
  %t249 = phi i1 [ false, %if_end_484 ], [ %t248, %key_down_read_485 ]
  br i1 %t249, label %logic_short_488, label %logic_rhs_487
logic_rhs_487:
  %t250 = load i32, i32* %t107
  %t251 = icmp sge i32 %t250, 0
  %t252 = icmp slt i32 %t250, 512
  %t253 = and i1 %t251, %t252
  br i1 %t253, label %key_down_read_490, label %key_down_end_491
key_down_read_490:
  %t254 = call i8* @SDL_GetKeyboardState(i32* null)
  %t255 = sext i32 %t250 to i64
  %t256 = getelementptr inbounds i8, i8* %t254, i64 %t255
  %t257 = load i8, i8* %t256
  %t258 = icmp ne i8 %t257, 0
  br label %key_down_end_491
key_down_end_491:
  %t259 = phi i1 [ false, %logic_rhs_487 ], [ %t258, %key_down_read_490 ]
  br label %logic_end_489
logic_short_488:
  br label %logic_end_489
logic_end_489:
  %t260 = phi i1 [ %t259, %key_down_end_491 ], [ true, %logic_short_488 ]
  br i1 %t260, label %if_then_492, label %if_else_493
if_then_492:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t51, i32 1)
  br label %if_end_494
if_else_493:
  br label %if_end_494
if_end_494:
  %t262 = load i32, i32* %t104
  %t263 = icmp sge i32 %t262, 0
  %t264 = icmp slt i32 %t262, 512
  %t265 = and i1 %t263, %t264
  br i1 %t265, label %key_down_read_495, label %key_down_end_496
key_down_read_495:
  %t266 = call i8* @SDL_GetKeyboardState(i32* null)
  %t267 = sext i32 %t262 to i64
  %t268 = getelementptr inbounds i8, i8* %t266, i64 %t267
  %t269 = load i8, i8* %t268
  %t270 = icmp ne i8 %t269, 0
  br label %key_down_end_496
key_down_end_496:
  %t271 = phi i1 [ false, %if_end_494 ], [ %t270, %key_down_read_495 ]
  br i1 %t271, label %logic_short_498, label %logic_rhs_497
logic_rhs_497:
  %t272 = load i32, i32* %t108
  %t273 = icmp sge i32 %t272, 0
  %t274 = icmp slt i32 %t272, 512
  %t275 = and i1 %t273, %t274
  br i1 %t275, label %key_down_read_500, label %key_down_end_501
key_down_read_500:
  %t276 = call i8* @SDL_GetKeyboardState(i32* null)
  %t277 = sext i32 %t272 to i64
  %t278 = getelementptr inbounds i8, i8* %t276, i64 %t277
  %t279 = load i8, i8* %t278
  %t280 = icmp ne i8 %t279, 0
  br label %key_down_end_501
key_down_end_501:
  %t281 = phi i1 [ false, %logic_rhs_497 ], [ %t280, %key_down_read_500 ]
  br label %logic_end_499
logic_short_498:
  br label %logic_end_499
logic_end_499:
  %t282 = phi i1 [ %t281, %key_down_end_501 ], [ true, %logic_short_498 ]
  br i1 %t282, label %if_then_502, label %if_else_503
if_then_502:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t51, i32 2)
  br label %if_end_504
if_else_503:
  br label %if_end_504
if_end_504:
  %t284 = load i32, i32* %t105
  %t285 = icmp sge i32 %t284, 0
  %t286 = icmp slt i32 %t284, 512
  %t287 = and i1 %t285, %t286
  br i1 %t287, label %key_down_read_505, label %key_down_end_506
key_down_read_505:
  %t288 = call i8* @SDL_GetKeyboardState(i32* null)
  %t289 = sext i32 %t284 to i64
  %t290 = getelementptr inbounds i8, i8* %t288, i64 %t289
  %t291 = load i8, i8* %t290
  %t292 = icmp ne i8 %t291, 0
  br label %key_down_end_506
key_down_end_506:
  %t293 = phi i1 [ false, %if_end_504 ], [ %t292, %key_down_read_505 ]
  br i1 %t293, label %logic_short_508, label %logic_rhs_507
logic_rhs_507:
  %t294 = load i32, i32* %t109
  %t295 = icmp sge i32 %t294, 0
  %t296 = icmp slt i32 %t294, 512
  %t297 = and i1 %t295, %t296
  br i1 %t297, label %key_down_read_510, label %key_down_end_511
key_down_read_510:
  %t298 = call i8* @SDL_GetKeyboardState(i32* null)
  %t299 = sext i32 %t294 to i64
  %t300 = getelementptr inbounds i8, i8* %t298, i64 %t299
  %t301 = load i8, i8* %t300
  %t302 = icmp ne i8 %t301, 0
  br label %key_down_end_511
key_down_end_511:
  %t303 = phi i1 [ false, %logic_rhs_507 ], [ %t302, %key_down_read_510 ]
  br label %logic_end_509
logic_short_508:
  br label %logic_end_509
logic_end_509:
  %t304 = phi i1 [ %t303, %key_down_end_511 ], [ true, %logic_short_508 ]
  br i1 %t304, label %if_then_512, label %if_else_513
if_then_512:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t51, i32 3)
  br label %if_end_514
if_else_513:
  br label %if_end_514
if_end_514:
  %t306 = load i32, i32* %t101
  %t307 = icmp sge i32 %t306, 0
  %t308 = icmp slt i32 %t306, 512
  %t309 = and i1 %t307, %t308
  br i1 %t309, label %key_down_read_515, label %key_down_end_516
key_down_read_515:
  %t310 = call i8* @SDL_GetKeyboardState(i32* null)
  %t311 = sext i32 %t306 to i64
  %t312 = getelementptr inbounds i8, i8* %t310, i64 %t311
  %t313 = load i8, i8* %t312
  %t314 = icmp ne i8 %t313, 0
  br label %key_down_end_516
key_down_end_516:
  %t315 = phi i1 [ false, %if_end_514 ], [ %t314, %key_down_read_515 ]
  store i1 %t315, i1* %t96
  %t317 = load i1, i1* %t96
  br i1 %t317, label %if_then_517, label %if_else_518
if_then_517:
  %t318 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 2
  %t319 = load i32, i32* %t318
  %t320 = icmp eq i32 2, 0
  %t321 = icmp eq i32 %t319, -2147483648
  %t322 = icmp eq i32 2, -1
  %t323 = and i1 %t321, %t322
  %t324 = or i1 %t320, %t323
  br i1 %t324, label %int_div_fail_520, label %int_div_ok_521
int_div_fail_520:
  %t325 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.40, i64 0, i64 0
  call i32 @puts(i8* %t325)
  call void @exit(i32 1)
  unreachable
int_div_ok_521:
  %t326 = sdiv i32 %t319, 2
  br label %if_end_519
if_else_518:
  %t327 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 2
  %t328 = load i32, i32* %t327
  br label %if_end_519
if_end_519:
  %t329 = phi i32 [ %t326, %int_div_ok_521 ], [ %t328, %if_else_518 ]
  store i32 %t329, i32* %t316
  %t331 = call i32 @SDL_GetTicks()
  store i32 %t331, i32* %t330
  %t332 = load i64, i64* %t58
  %t333 = zext i32 0 to i64
  %t334 = shl i64 1, %t333
  %t335 = and i64 %t332, %t334
  %t336 = icmp ne i64 %t335, 0
  %t337 = xor i1 true, %t336
  br i1 %t337, label %logic_rhs_522, label %logic_short_523
logic_rhs_522:
  %t338 = load i32, i32* %t330
  %t339 = load i32, i32* %t91
  %t340 = sub i32 %t338, %t339
  %t341 = load i32, i32* %t316
  %t342 = icmp sge i32 %t340, %t341
  br label %logic_end_524
logic_short_523:
  br label %logic_end_524
logic_end_524:
  %t343 = phi i1 [ %t342, %logic_rhs_522 ], [ false, %logic_short_523 ]
  br i1 %t343, label %if_then_525, label %if_else_526
if_then_525:
  %t344 = load i32, i32* %t330
  store i32 %t344, i32* %t91
  %t346 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t347 = load i32, i32* %t346
  store i32 %t347, i32* %t345
  %t349 = call %food__sb__grid__Cell @food__sb__Snake__advance(%food__sb__Snake* %t51)
  store %food__sb__grid__Cell %t349, %food__sb__grid__Cell* %t348
  %t350 = getelementptr i64, i64* null, i32 1
  %t351 = ptrtoint i64* %t350 to i64
  %t352 = load i8*, i8** %t60
  %t353 = icmp eq i8* %t352, null
  br i1 %t353, label %list_cow_alloc_528, label %list_cow_check_529
list_cow_alloc_528:
  %t358 = bitcast void (i8*)* @list_release_symbol to i8*
  %t359 = call i8* @star_rc_alloc(i64 24, i8* %t358)
  %t360 = bitcast i8* %t359 to { i64*, i64, i64 }*
  %t361 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t360, i32 0, i32 0
  store i64* null, i64** %t361
  %t362 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t360, i32 0, i32 1
  store i64 0, i64* %t362
  %t363 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t360, i32 0, i32 2
  store i64 0, i64* %t363
  store i8* %t359, i8** %t60
  br label %list_cow_done_530
list_cow_check_529:
  %t364 = getelementptr inbounds i8, i8* %t352, i64 -16
  %t365 = bitcast i8* %t364 to i64*
  %t366 = load atomic i64, i64* %t365 seq_cst, align 8
  %t367 = icmp eq i64 %t366, 1
  br i1 %t367, label %list_cow_done_530, label %list_cow_clone_531
list_cow_clone_531:
  %t368 = bitcast i8* %t352 to { i64*, i64, i64 }*
  %t369 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t368, i32 0, i32 0
  %t370 = load i64*, i64** %t369
  %t371 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t368, i32 0, i32 1
  %t372 = load i64, i64* %t371
  %t373 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t368, i32 0, i32 2
  %t374 = load i64, i64* %t373
  %t375 = bitcast void (i8*)* @list_release_symbol to i8*
  %t376 = call i8* @star_rc_alloc(i64 24, i8* %t375)
  %t377 = bitcast i8* %t376 to { i64*, i64, i64 }*
  %t378 = mul i64 %t374, %t351
  %t379 = call i8* @malloc(i64 %t378)
  %t380 = bitcast i8* %t379 to i64*
  %t381 = icmp sgt i64 %t372, 0
  br i1 %t381, label %list_cow_copy_532, label %list_cow_after_copy_533
list_cow_copy_532:
  %t382 = mul i64 %t372, %t351
  %t383 = bitcast i64* %t370 to i8*
  call i8* @memcpy(i8* %t379, i8* %t383, i64 %t382)
  br label %list_cow_after_copy_533
list_cow_after_copy_533:
  %t384 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t377, i32 0, i32 0
  store i64* %t380, i64** %t384
  %t385 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t377, i32 0, i32 1
  store i64 %t372, i64* %t385
  %t386 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t377, i32 0, i32 2
  store i64 %t374, i64* %t386
  call void @star_rc_release(i8* %t352)
  store i8* %t376, i8** %t60
  br label %list_cow_done_530
list_cow_done_530:
  %t387 = load i8*, i8** %t60
  %t388 = bitcast i8* %t387 to { i64*, i64, i64 }*
  %t389 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t388, i32 0, i32 0
  %t390 = load i64*, i64** %t389
  %t391 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t388, i32 0, i32 1
  %t392 = load i64, i64* %t391
  %t393 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t388, i32 0, i32 2
  %t394 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.41, i64 0, i32 2, i64 0
  %t395 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t395, i32 -1)
  %t396 = load i64, i64* @sym.len
  %t397 = load i8**, i8*** @sym.data
  store i64 0, i64* %t398
  br label %sym_find_cond_534
sym_find_cond_534:
  %t399 = load i64, i64* %t398
  %t400 = icmp slt i64 %t399, %t396
  br i1 %t400, label %sym_find_body_535, label %sym_find_end_537
sym_find_body_535:
  %t401 = getelementptr inbounds i8*, i8** %t397, i64 %t399
  %t402 = load i8*, i8** %t401
  %t403 = call i32 @strcmp(i8* %t402, i8* %t394)
  %t404 = icmp eq i32 %t403, 0
  br i1 %t404, label %sym_find_end_537, label %sym_find_next_536
sym_find_next_536:
  %t405 = add i64 %t399, 1
  store i64 %t405, i64* %t398
  br label %sym_find_cond_534
sym_find_end_537:
  %t406 = load i64, i64* %t398
  %t407 = icmp slt i64 %t406, %t396
  br i1 %t407, label %sym_found_538, label %sym_notfound_539
sym_found_538:
  call void @star_rc_release(i8* %t394)
  br label %sym_done_540
sym_notfound_539:
  %t408 = load i64, i64* @sym.cap
  %t409 = icmp sge i64 %t396, %t408
  br i1 %t409, label %sym_grow_541, label %sym_store_542
sym_grow_541:
  %t410 = mul i64 %t408, 2
  %t411 = icmp sgt i64 %t410, 0
  %t412 = select i1 %t411, i64 %t410, i64 1
  %t413 = mul i64 %t412, 8
  %t414 = call i8* @malloc(i64 %t413)
  %t415 = bitcast i8* %t414 to i8**
  %t416 = icmp sgt i64 %t408, 0
  br i1 %t416, label %sym_copy_543, label %sym_after_copy_544
sym_copy_543:
  %t417 = mul i64 %t396, 8
  %t418 = bitcast i8** %t397 to i8*
  call i8* @memcpy(i8* %t414, i8* %t418, i64 %t417)
  call void @free(i8* %t418)
  br label %sym_after_copy_544
sym_after_copy_544:
  store i8** %t415, i8*** @sym.data
  store i64 %t412, i64* @sym.cap
  br label %sym_store_542
sym_store_542:
  %t419 = load i8**, i8*** @sym.data
  %t420 = getelementptr inbounds i8*, i8** %t419, i64 %t396
  store i8* %t394, i8** %t420
  %t421 = add i64 %t396, 1
  store i64 %t421, i64* @sym.len
  br label %sym_done_540
sym_done_540:
  %t422 = phi i64 [ %t406, %sym_found_538 ], [ %t396, %sym_store_542 ]
  call i32 @ReleaseSemaphore(i8* %t395, i32 1, i32* null)
  %t423 = load i64, i64* %t393
  %t424 = load i64*, i64** %t389
  %t425 = load i64, i64* %t391
  %t426 = icmp sge i64 %t425, %t423
  br i1 %t426, label %list_push_grow_545, label %list_push_store_546
list_push_grow_545:
  %t427 = mul i64 %t423, 2
  %t428 = icmp sgt i64 %t427, 0
  %t429 = select i1 %t428, i64 %t427, i64 1
  %t430 = getelementptr i64, i64* null, i32 1
  %t431 = ptrtoint i64* %t430 to i64
  %t432 = mul i64 %t429, %t431
  %t433 = call i8* @malloc(i64 %t432)
  %t434 = bitcast i8* %t433 to i64*
  %t435 = icmp sgt i64 %t423, 0
  br i1 %t435, label %list_push_copy_547, label %list_push_after_copy_548
list_push_copy_547:
  %t436 = mul i64 %t425, %t431
  %t437 = bitcast i64* %t424 to i8*
  call i8* @memcpy(i8* %t433, i8* %t437, i64 %t436)
  call void @free(i8* %t437)
  br label %list_push_after_copy_548
list_push_after_copy_548:
  store i64* %t434, i64** %t389
  store i64 %t429, i64* %t393
  br label %list_push_store_546
list_push_store_546:
  %t438 = load i64*, i64** %t389
  %t439 = getelementptr inbounds i64, i64* %t438, i64 %t425
  store i64 %t422, i64* %t439
  %t440 = add i64 %t425, 1
  store i64 %t440, i64* %t391
  %t441 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 4
  %t442 = load i1, i1* %t441
  br i1 %t442, label %logic_rhs_549, label %logic_short_550
logic_rhs_549:
  %t443 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t348
  %t444 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t53
  %t445 = call i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %t443, %food__sb__grid__Cell %t444)
  br label %logic_end_551
logic_short_550:
  br label %logic_end_551
logic_end_551:
  %t446 = phi i1 [ %t445, %logic_rhs_549 ], [ false, %logic_short_550 ]
  br i1 %t446, label %if_then_552, label %if_else_553
if_then_552:
  call void @food__sb__Snake__grow(%food__sb__Snake* %t51, i32 1)
  %t448 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t449 = load i32, i32* %t448
  %t450 = add i32 %t449, 10
  %t451 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  store i32 %t450, i32* %t451
  %t452 = getelementptr i64, i64* null, i32 1
  %t453 = ptrtoint i64* %t452 to i64
  %t454 = load i8*, i8** %t60
  %t455 = icmp eq i8* %t454, null
  br i1 %t455, label %list_cow_alloc_555, label %list_cow_check_556
list_cow_alloc_555:
  %t456 = bitcast void (i8*)* @list_release_symbol to i8*
  %t457 = call i8* @star_rc_alloc(i64 24, i8* %t456)
  %t458 = bitcast i8* %t457 to { i64*, i64, i64 }*
  %t459 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t458, i32 0, i32 0
  store i64* null, i64** %t459
  %t460 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t458, i32 0, i32 1
  store i64 0, i64* %t460
  %t461 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t458, i32 0, i32 2
  store i64 0, i64* %t461
  store i8* %t457, i8** %t60
  br label %list_cow_done_557
list_cow_check_556:
  %t462 = getelementptr inbounds i8, i8* %t454, i64 -16
  %t463 = bitcast i8* %t462 to i64*
  %t464 = load atomic i64, i64* %t463 seq_cst, align 8
  %t465 = icmp eq i64 %t464, 1
  br i1 %t465, label %list_cow_done_557, label %list_cow_clone_558
list_cow_clone_558:
  %t466 = bitcast i8* %t454 to { i64*, i64, i64 }*
  %t467 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t466, i32 0, i32 0
  %t468 = load i64*, i64** %t467
  %t469 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t466, i32 0, i32 1
  %t470 = load i64, i64* %t469
  %t471 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t466, i32 0, i32 2
  %t472 = load i64, i64* %t471
  %t473 = bitcast void (i8*)* @list_release_symbol to i8*
  %t474 = call i8* @star_rc_alloc(i64 24, i8* %t473)
  %t475 = bitcast i8* %t474 to { i64*, i64, i64 }*
  %t476 = mul i64 %t472, %t453
  %t477 = call i8* @malloc(i64 %t476)
  %t478 = bitcast i8* %t477 to i64*
  %t479 = icmp sgt i64 %t470, 0
  br i1 %t479, label %list_cow_copy_559, label %list_cow_after_copy_560
list_cow_copy_559:
  %t480 = mul i64 %t470, %t453
  %t481 = bitcast i64* %t468 to i8*
  call i8* @memcpy(i8* %t477, i8* %t481, i64 %t480)
  br label %list_cow_after_copy_560
list_cow_after_copy_560:
  %t482 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t475, i32 0, i32 0
  store i64* %t478, i64** %t482
  %t483 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t475, i32 0, i32 1
  store i64 %t470, i64* %t483
  %t484 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t475, i32 0, i32 2
  store i64 %t472, i64* %t484
  call void @star_rc_release(i8* %t454)
  store i8* %t474, i8** %t60
  br label %list_cow_done_557
list_cow_done_557:
  %t485 = load i8*, i8** %t60
  %t486 = bitcast i8* %t485 to { i64*, i64, i64 }*
  %t487 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t486, i32 0, i32 0
  %t488 = load i64*, i64** %t487
  %t489 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t486, i32 0, i32 1
  %t490 = load i64, i64* %t489
  %t491 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t486, i32 0, i32 2
  %t492 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.42, i64 0, i32 2, i64 0
  %t493 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t493, i32 -1)
  %t494 = load i64, i64* @sym.len
  %t495 = load i8**, i8*** @sym.data
  store i64 0, i64* %t496
  br label %sym_find_cond_561
sym_find_cond_561:
  %t497 = load i64, i64* %t496
  %t498 = icmp slt i64 %t497, %t494
  br i1 %t498, label %sym_find_body_562, label %sym_find_end_564
sym_find_body_562:
  %t499 = getelementptr inbounds i8*, i8** %t495, i64 %t497
  %t500 = load i8*, i8** %t499
  %t501 = call i32 @strcmp(i8* %t500, i8* %t492)
  %t502 = icmp eq i32 %t501, 0
  br i1 %t502, label %sym_find_end_564, label %sym_find_next_563
sym_find_next_563:
  %t503 = add i64 %t497, 1
  store i64 %t503, i64* %t496
  br label %sym_find_cond_561
sym_find_end_564:
  %t504 = load i64, i64* %t496
  %t505 = icmp slt i64 %t504, %t494
  br i1 %t505, label %sym_found_565, label %sym_notfound_566
sym_found_565:
  call void @star_rc_release(i8* %t492)
  br label %sym_done_567
sym_notfound_566:
  %t506 = load i64, i64* @sym.cap
  %t507 = icmp sge i64 %t494, %t506
  br i1 %t507, label %sym_grow_568, label %sym_store_569
sym_grow_568:
  %t508 = mul i64 %t506, 2
  %t509 = icmp sgt i64 %t508, 0
  %t510 = select i1 %t509, i64 %t508, i64 1
  %t511 = mul i64 %t510, 8
  %t512 = call i8* @malloc(i64 %t511)
  %t513 = bitcast i8* %t512 to i8**
  %t514 = icmp sgt i64 %t506, 0
  br i1 %t514, label %sym_copy_570, label %sym_after_copy_571
sym_copy_570:
  %t515 = mul i64 %t494, 8
  %t516 = bitcast i8** %t495 to i8*
  call i8* @memcpy(i8* %t512, i8* %t516, i64 %t515)
  call void @free(i8* %t516)
  br label %sym_after_copy_571
sym_after_copy_571:
  store i8** %t513, i8*** @sym.data
  store i64 %t510, i64* @sym.cap
  br label %sym_store_569
sym_store_569:
  %t517 = load i8**, i8*** @sym.data
  %t518 = getelementptr inbounds i8*, i8** %t517, i64 %t494
  store i8* %t492, i8** %t518
  %t519 = add i64 %t494, 1
  store i64 %t519, i64* @sym.len
  br label %sym_done_567
sym_done_567:
  %t520 = phi i64 [ %t504, %sym_found_565 ], [ %t494, %sym_store_569 ]
  call i32 @ReleaseSemaphore(i8* %t493, i32 1, i32* null)
  %t521 = load i64, i64* %t491
  %t522 = load i64*, i64** %t487
  %t523 = load i64, i64* %t489
  %t524 = icmp sge i64 %t523, %t521
  br i1 %t524, label %list_push_grow_572, label %list_push_store_573
list_push_grow_572:
  %t525 = mul i64 %t521, 2
  %t526 = icmp sgt i64 %t525, 0
  %t527 = select i1 %t526, i64 %t525, i64 1
  %t528 = getelementptr i64, i64* null, i32 1
  %t529 = ptrtoint i64* %t528 to i64
  %t530 = mul i64 %t527, %t529
  %t531 = call i8* @malloc(i64 %t530)
  %t532 = bitcast i8* %t531 to i64*
  %t533 = icmp sgt i64 %t521, 0
  br i1 %t533, label %list_push_copy_574, label %list_push_after_copy_575
list_push_copy_574:
  %t534 = mul i64 %t523, %t529
  %t535 = bitcast i64* %t522 to i8*
  call i8* @memcpy(i8* %t531, i8* %t535, i64 %t534)
  call void @free(i8* %t535)
  br label %list_push_after_copy_575
list_push_after_copy_575:
  store i64* %t532, i64** %t487
  store i64 %t527, i64* %t491
  br label %list_push_store_573
list_push_store_573:
  %t536 = load i64*, i64** %t487
  %t537 = getelementptr inbounds i64, i64* %t536, i64 %t523
  store i64 %t520, i64* %t537
  %t538 = add i64 %t523, 1
  store i64 %t538, i64* %t489
  %t540 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t53
  %t541 = call { i32, i32 } @cell_px(%food__sb__grid__Cell %t540)
  store { i32, i32 } %t541, { i32, i32 }* %t539
  %t543 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t539, i32 0, i32 0
  %t544 = load i32, i32* %t543
  %t545 = call i32 @food__sb__grid__cell_size()
  %t546 = icmp eq i32 2, 0
  %t547 = icmp eq i32 %t545, -2147483648
  %t548 = icmp eq i32 2, -1
  %t549 = and i1 %t547, %t548
  %t550 = or i1 %t546, %t549
  br i1 %t550, label %int_div_fail_576, label %int_div_ok_577
int_div_fail_576:
  %t551 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.43, i64 0, i64 0
  call i32 @puts(i8* %t551)
  call void @exit(i32 1)
  unreachable
int_div_ok_577:
  %t552 = sdiv i32 %t545, 2
  %t553 = add i32 %t544, %t552
  %t554 = sitofp i32 %t553 to float
  store float %t554, float* %t542
  %t556 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t539, i32 0, i32 1
  %t557 = load i32, i32* %t556
  %t558 = call i32 @food__sb__grid__cell_size()
  %t559 = icmp eq i32 2, 0
  %t560 = icmp eq i32 %t558, -2147483648
  %t561 = icmp eq i32 2, -1
  %t562 = and i1 %t560, %t561
  %t563 = or i1 %t559, %t562
  br i1 %t563, label %int_div_fail_578, label %int_div_ok_579
int_div_fail_578:
  %t564 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.44, i64 0, i64 0
  call i32 @puts(i8* %t564)
  call void @exit(i32 1)
  unreachable
int_div_ok_579:
  %t565 = sdiv i32 %t558, 2
  %t566 = add i32 %t557, %t565
  %t567 = sitofp i32 %t566 to float
  store float %t567, float* %t555
  %t568 = load float, float* %t542
  %t569 = load float, float* %t555
  call void @ParticlePool__spawn_burst(%ParticlePool* %t72, float %t568, float %t569)
  %t571 = load %Particle*, %Particle** @arena.Particles.data
  %t572 = icmp eq %Particle* %t571, null
  br i1 %t572, label %spawn_init_580, label %spawn_ready_581
spawn_init_580:
  %t573 = getelementptr %Particle, %Particle* null, i32 1
  %t574 = ptrtoint %Particle* %t573 to i64
  %t575 = mul i64 %t574, 256
  %t576 = call i8* @malloc(i64 %t575)
  %t577 = bitcast i8* %t576 to %Particle*
  store %Particle* %t577, %Particle** @arena.Particles.data
  br label %spawn_ready_581
spawn_ready_581:
  %t578 = load %Particle*, %Particle** @arena.Particles.data
  %t579 = load i64, i64* @arena.Particles.free_top
  %t580 = icmp sgt i64 %t579, 0
  br i1 %t580, label %spawn_reuse_582, label %spawn_grow_583
spawn_reuse_582:
  %t581 = sub i64 %t579, 1
  store i64 %t581, i64* @arena.Particles.free_top
  %t582 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.free, i64 0, i64 %t581
  %t583 = load i64, i64* %t582
  br label %spawn_store_584
spawn_grow_583:
  %t584 = load i64, i64* @arena.Particles.count
  %t585 = icmp slt i64 %t584, 256
  br i1 %t585, label %spawn_grow_ok_586, label %spawn_capacity_warn_587
spawn_capacity_warn_587:
  %t586 = load i1, i1* @arena.Particles.warned
  br i1 %t586, label %spawn_end_585, label %spawn_warn_print_588
spawn_warn_print_588:
  store i1 1, i1* @arena.Particles.warned
  %t587 = getelementptr inbounds [141 x i8], [141 x i8]* @.str.45, i64 0, i64 0
  call i32 @puts(i8* %t587)
  br label %spawn_end_585
spawn_grow_ok_586:
  %t588 = add i64 %t584, 1
  store i64 %t588, i64* @arena.Particles.count
  br label %spawn_store_584
spawn_store_584:
  %t589 = phi i64 [ %t583, %spawn_reuse_582 ], [ %t584, %spawn_grow_ok_586 ]
  %t591 = load float, float* %t542
  %t592 = getelementptr inbounds %Particle, %Particle* %t590, i32 0, i32 0
  store float %t591, float* %t592
  %t593 = load float, float* %t555
  %t594 = getelementptr inbounds %Particle, %Particle* %t590, i32 0, i32 1
  store float %t593, float* %t594
  %t595 = getelementptr inbounds %Particle, %Particle* %t590, i32 0, i32 2
  store float 0x0000000000000000, float* %t595
  %t596 = getelementptr inbounds %Particle, %Particle* %t590, i32 0, i32 3
  store float 0x0000000000000000, float* %t596
  %t597 = getelementptr inbounds %Particle, %Particle* %t590, i32 0, i32 4
  store float 0x3FDCCCCCC0000000, float* %t597
  %t598 = load %Particle, %Particle* %t590
  %t599 = getelementptr inbounds %Particle, %Particle* %t578, i64 %t589
  store %Particle %t598, %Particle* %t599
  %t600 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t589
  %t601 = load i64, i64* %t600
  %t602 = add i64 %t601, 1
  store i64 %t602, i64* %t600
  %t603 = trunc i64 %t589 to i32
  br label %spawn_end_585
spawn_end_585:
  %t604 = phi i32 [ %t603, %spawn_store_584 ], [ -1, %spawn_capacity_warn_587 ], [ -1, %spawn_warn_print_588 ]
  %t607 = load i8*, i8** %t10
  %t608 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t606, i32 0, i32 0
  store i8* %t607, i8** %t608
  %t609 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t606, i32 0, i32 1
  store i32 0, i32* %t609
  %t610 = load %FlashOnEat, %FlashOnEat* %t606
  store %FlashOnEat %t610, %FlashOnEat* %t605
  store i1 true, i1* %t611
  br label %while_cond_589
while_cond_589:
  %t612 = load i1, i1* %t611
  br i1 %t612, label %while_body_590, label %while_else_591
while_body_590:
  %t613 = call i1 @FlashOnEat__resume(%FlashOnEat* %t605)
  store i1 %t613, i1* %t611
  br label %while_cond_589
while_else_591:
  br label %while_end_592
while_end_592:
  %t614 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 0
  %t615 = load { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t614
  %t616 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t617 = call %food__sb__grid__Cell @food__spawn_food({ [768 x %food__sb__grid__Cell], i64, i64 } %t615, i32 %t616)
  store %food__sb__grid__Cell %t617, %food__sb__grid__Cell* %t53
  %t618 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t619 = load i32, i32* %t618
  %t620 = icmp eq i32 50, 0
  %t621 = icmp eq i32 %t619, -2147483648
  %t622 = icmp eq i32 50, -1
  %t623 = and i1 %t621, %t622
  %t624 = or i1 %t620, %t623
  br i1 %t624, label %int_div_fail_593, label %int_div_ok_594
int_div_fail_593:
  %t625 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.46, i64 0, i64 0
  call i32 @puts(i8* %t625)
  call void @exit(i32 1)
  unreachable
int_div_ok_594:
  %t626 = sdiv i32 %t619, 50
  %t627 = load i32, i32* %t345
  %t628 = icmp eq i32 50, 0
  %t629 = icmp eq i32 %t627, -2147483648
  %t630 = icmp eq i32 50, -1
  %t631 = and i1 %t629, %t630
  %t632 = or i1 %t628, %t631
  br i1 %t632, label %int_div_fail_595, label %int_div_ok_596
int_div_fail_595:
  %t633 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.47, i64 0, i64 0
  call i32 @puts(i8* %t633)
  call void @exit(i32 1)
  unreachable
int_div_ok_596:
  %t634 = sdiv i32 %t627, 50
  %t635 = icmp sgt i32 %t626, %t634
  br i1 %t635, label %if_then_597, label %if_else_598
if_then_597:
  %t637 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t638 = load i32, i32* %t637
  %t639 = icmp eq i32 50, 0
  %t640 = icmp eq i32 %t638, -2147483648
  %t641 = icmp eq i32 50, -1
  %t642 = and i1 %t640, %t641
  %t643 = or i1 %t639, %t642
  br i1 %t643, label %int_div_fail_600, label %int_div_ok_601
int_div_fail_600:
  %t644 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.48, i64 0, i64 0
  call i32 @puts(i8* %t644)
  call void @exit(i32 1)
  unreachable
int_div_ok_601:
  %t645 = sdiv i32 %t638, 50
  store i32 %t645, i32* %t636
  %t646 = load i32, i32* %t636
  %t647 = icmp sge i32 %t646, 1
  br i1 %t647, label %logic_rhs_602, label %logic_short_603
logic_rhs_602:
  %t648 = load i32, i32* %t636
  %t649 = icmp sle i32 %t648, 8
  br label %logic_end_604
logic_short_603:
  br label %logic_end_604
logic_end_604:
  %t650 = phi i1 [ %t649, %logic_rhs_602 ], [ false, %logic_short_603 ]
  br i1 %t650, label %if_then_605, label %if_else_606
if_then_605:
  %t651 = load i8, i8* %t59
  %t652 = load i32, i32* %t636
  %t653 = sub i32 %t652, 1
  %t654 = and i32 %t653, 7
  %t655 = trunc i32 %t654 to i8
  %t656 = shl i8 1, %t655
  %t657 = or i8 %t651, %t656
  store i8 %t657, i8* %t59
  %t658 = load i32, i32* %t636
  %t659 = load i8, i8* %t59
  %t660 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.49, i64 0, i64 0
  %t661 = zext i8 %t659 to i32
  call i32 (i8*, ...) @printf(i8* %t660, i32 %t658, i32 %t661)
  br label %if_end_607
if_else_606:
  br label %if_end_607
if_end_607:
  br label %if_end_599
if_else_598:
  br label %if_end_599
if_end_599:
  %t662 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t663 = load i32, i32* %t662
  %t664 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t665 = load i32, i32* %t664
  %t666 = icmp sgt i32 %t663, %t665
  br i1 %t666, label %if_then_608, label %if_else_609
if_then_608:
  %t667 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t668 = load i32, i32* %t667
  %t669 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  store i32 %t668, i32* %t669
  br label %if_end_610
if_else_609:
  br label %if_end_610
if_end_610:
  br label %if_end_554
if_else_553:
  br label %if_end_554
if_end_554:
  %t670 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 4
  %t671 = load i1, i1* %t670
  %t672 = xor i1 true, %t671
  br i1 %t672, label %if_then_611, label %if_else_612
if_then_611:
  %t673 = getelementptr i64, i64* null, i32 1
  %t674 = ptrtoint i64* %t673 to i64
  %t675 = load i8*, i8** %t60
  %t676 = icmp eq i8* %t675, null
  br i1 %t676, label %list_cow_alloc_614, label %list_cow_check_615
list_cow_alloc_614:
  %t677 = bitcast void (i8*)* @list_release_symbol to i8*
  %t678 = call i8* @star_rc_alloc(i64 24, i8* %t677)
  %t679 = bitcast i8* %t678 to { i64*, i64, i64 }*
  %t680 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t679, i32 0, i32 0
  store i64* null, i64** %t680
  %t681 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t679, i32 0, i32 1
  store i64 0, i64* %t681
  %t682 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t679, i32 0, i32 2
  store i64 0, i64* %t682
  store i8* %t678, i8** %t60
  br label %list_cow_done_616
list_cow_check_615:
  %t683 = getelementptr inbounds i8, i8* %t675, i64 -16
  %t684 = bitcast i8* %t683 to i64*
  %t685 = load atomic i64, i64* %t684 seq_cst, align 8
  %t686 = icmp eq i64 %t685, 1
  br i1 %t686, label %list_cow_done_616, label %list_cow_clone_617
list_cow_clone_617:
  %t687 = bitcast i8* %t675 to { i64*, i64, i64 }*
  %t688 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t687, i32 0, i32 0
  %t689 = load i64*, i64** %t688
  %t690 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t687, i32 0, i32 1
  %t691 = load i64, i64* %t690
  %t692 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t687, i32 0, i32 2
  %t693 = load i64, i64* %t692
  %t694 = bitcast void (i8*)* @list_release_symbol to i8*
  %t695 = call i8* @star_rc_alloc(i64 24, i8* %t694)
  %t696 = bitcast i8* %t695 to { i64*, i64, i64 }*
  %t697 = mul i64 %t693, %t674
  %t698 = call i8* @malloc(i64 %t697)
  %t699 = bitcast i8* %t698 to i64*
  %t700 = icmp sgt i64 %t691, 0
  br i1 %t700, label %list_cow_copy_618, label %list_cow_after_copy_619
list_cow_copy_618:
  %t701 = mul i64 %t691, %t674
  %t702 = bitcast i64* %t689 to i8*
  call i8* @memcpy(i8* %t698, i8* %t702, i64 %t701)
  br label %list_cow_after_copy_619
list_cow_after_copy_619:
  %t703 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t696, i32 0, i32 0
  store i64* %t699, i64** %t703
  %t704 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t696, i32 0, i32 1
  store i64 %t691, i64* %t704
  %t705 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t696, i32 0, i32 2
  store i64 %t693, i64* %t705
  call void @star_rc_release(i8* %t675)
  store i8* %t695, i8** %t60
  br label %list_cow_done_616
list_cow_done_616:
  %t706 = load i8*, i8** %t60
  %t707 = bitcast i8* %t706 to { i64*, i64, i64 }*
  %t708 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t707, i32 0, i32 0
  %t709 = load i64*, i64** %t708
  %t710 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t707, i32 0, i32 1
  %t711 = load i64, i64* %t710
  %t712 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t707, i32 0, i32 2
  %t713 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.50, i64 0, i32 2, i64 0
  %t714 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t714, i32 -1)
  %t715 = load i64, i64* @sym.len
  %t716 = load i8**, i8*** @sym.data
  store i64 0, i64* %t717
  br label %sym_find_cond_620
sym_find_cond_620:
  %t718 = load i64, i64* %t717
  %t719 = icmp slt i64 %t718, %t715
  br i1 %t719, label %sym_find_body_621, label %sym_find_end_623
sym_find_body_621:
  %t720 = getelementptr inbounds i8*, i8** %t716, i64 %t718
  %t721 = load i8*, i8** %t720
  %t722 = call i32 @strcmp(i8* %t721, i8* %t713)
  %t723 = icmp eq i32 %t722, 0
  br i1 %t723, label %sym_find_end_623, label %sym_find_next_622
sym_find_next_622:
  %t724 = add i64 %t718, 1
  store i64 %t724, i64* %t717
  br label %sym_find_cond_620
sym_find_end_623:
  %t725 = load i64, i64* %t717
  %t726 = icmp slt i64 %t725, %t715
  br i1 %t726, label %sym_found_624, label %sym_notfound_625
sym_found_624:
  call void @star_rc_release(i8* %t713)
  br label %sym_done_626
sym_notfound_625:
  %t727 = load i64, i64* @sym.cap
  %t728 = icmp sge i64 %t715, %t727
  br i1 %t728, label %sym_grow_627, label %sym_store_628
sym_grow_627:
  %t729 = mul i64 %t727, 2
  %t730 = icmp sgt i64 %t729, 0
  %t731 = select i1 %t730, i64 %t729, i64 1
  %t732 = mul i64 %t731, 8
  %t733 = call i8* @malloc(i64 %t732)
  %t734 = bitcast i8* %t733 to i8**
  %t735 = icmp sgt i64 %t727, 0
  br i1 %t735, label %sym_copy_629, label %sym_after_copy_630
sym_copy_629:
  %t736 = mul i64 %t715, 8
  %t737 = bitcast i8** %t716 to i8*
  call i8* @memcpy(i8* %t733, i8* %t737, i64 %t736)
  call void @free(i8* %t737)
  br label %sym_after_copy_630
sym_after_copy_630:
  store i8** %t734, i8*** @sym.data
  store i64 %t731, i64* @sym.cap
  br label %sym_store_628
sym_store_628:
  %t738 = load i8**, i8*** @sym.data
  %t739 = getelementptr inbounds i8*, i8** %t738, i64 %t715
  store i8* %t713, i8** %t739
  %t740 = add i64 %t715, 1
  store i64 %t740, i64* @sym.len
  br label %sym_done_626
sym_done_626:
  %t741 = phi i64 [ %t725, %sym_found_624 ], [ %t715, %sym_store_628 ]
  call i32 @ReleaseSemaphore(i8* %t714, i32 1, i32* null)
  %t742 = load i64, i64* %t712
  %t743 = load i64*, i64** %t708
  %t744 = load i64, i64* %t710
  %t745 = icmp sge i64 %t744, %t742
  br i1 %t745, label %list_push_grow_631, label %list_push_store_632
list_push_grow_631:
  %t746 = mul i64 %t742, 2
  %t747 = icmp sgt i64 %t746, 0
  %t748 = select i1 %t747, i64 %t746, i64 1
  %t749 = getelementptr i64, i64* null, i32 1
  %t750 = ptrtoint i64* %t749 to i64
  %t751 = mul i64 %t748, %t750
  %t752 = call i8* @malloc(i64 %t751)
  %t753 = bitcast i8* %t752 to i64*
  %t754 = icmp sgt i64 %t742, 0
  br i1 %t754, label %list_push_copy_633, label %list_push_after_copy_634
list_push_copy_633:
  %t755 = mul i64 %t744, %t750
  %t756 = bitcast i64* %t743 to i8*
  call i8* @memcpy(i8* %t752, i8* %t756, i64 %t755)
  call void @free(i8* %t756)
  br label %list_push_after_copy_634
list_push_after_copy_634:
  store i64* %t753, i64** %t708
  store i64 %t748, i64* %t712
  br label %list_push_store_632
list_push_store_632:
  %t757 = load i64*, i64** %t708
  %t758 = getelementptr inbounds i64, i64* %t757, i64 %t744
  store i64 %t741, i64* %t758
  %t759 = add i64 %t744, 1
  store i64 %t759, i64* %t710
  %t760 = load i8*, i8** %t60
  %t761 = icmp eq i8* %t760, null
  br i1 %t761, label %list_read_null_635, label %list_read_real_636
list_read_null_635:
  br label %list_read_end_637
list_read_real_636:
  %t762 = bitcast i8* %t760 to { i64*, i64, i64 }*
  %t763 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t762, i32 0, i32 0
  %t764 = load i64*, i64** %t763
  %t765 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t762, i32 0, i32 1
  %t766 = load i64, i64* %t765
  br label %list_read_end_637
list_read_end_637:
  %t767 = phi i64* [ null, %list_read_null_635 ], [ %t764, %list_read_real_636 ]
  %t768 = phi i64 [ 0, %list_read_null_635 ], [ %t766, %list_read_real_636 ]
  %t769 = load i8*, i8** %t60
  %t770 = icmp eq i8* %t769, null
  br i1 %t770, label %list_read_null_638, label %list_read_real_639
list_read_null_638:
  br label %list_read_end_640
list_read_real_639:
  %t771 = bitcast i8* %t769 to { i64*, i64, i64 }*
  %t772 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t771, i32 0, i32 0
  %t773 = load i64*, i64** %t772
  %t774 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t771, i32 0, i32 1
  %t775 = load i64, i64* %t774
  br label %list_read_end_640
list_read_end_640:
  %t776 = phi i64* [ null, %list_read_null_638 ], [ %t773, %list_read_real_639 ]
  %t777 = phi i64 [ 0, %list_read_null_638 ], [ %t775, %list_read_real_639 ]
  %t778 = trunc i64 %t777 to i32
  %t779 = sub i32 %t778, 1
  %t780 = sext i32 %t779 to i64
  %t781 = icmp ult i64 %t780, %t768
  br i1 %t781, label %list_idx_ok_641, label %list_idx_oob_642
list_idx_ok_641:
  %t782 = getelementptr inbounds i64, i64* %t767, i64 %t780
  %t783 = load i64, i64* %t782
  br label %list_idx_end_643
list_idx_oob_642:
  br label %list_idx_end_643
list_idx_end_643:
  %t784 = phi i64 [ %t783, %list_idx_ok_641 ], [ 0, %list_idx_oob_642 ]
  %t785 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t785, i32 -1)
  %t786 = load i64, i64* @sym.len
  %t787 = icmp sge i64 %t784, 0
  %t788 = icmp slt i64 %t784, %t786
  %t789 = and i1 %t787, %t788
  br i1 %t789, label %sym_name_ok_644, label %sym_name_oob_645
sym_name_ok_644:
  %t790 = load i8**, i8*** @sym.data
  %t791 = getelementptr inbounds i8*, i8** %t790, i64 %t784
  %t792 = load i8*, i8** %t791
  call void @star_rc_retain(i8* %t792)
  br label %sym_name_end_646
sym_name_oob_645:
  %t793 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t793
  br label %sym_name_end_646
sym_name_end_646:
  %t794 = phi i8* [ %t792, %sym_name_ok_644 ], [ %t793, %sym_name_oob_645 ]
  call i32 @ReleaseSemaphore(i8* %t785, i32 1, i32* null)
  call void @star_rc_release(i8* %t794)
  %t795 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t795, i8* %t794)
  %t796 = load i8*, i8** %t27
  %t797 = load i8*, i8** %t27
  call void @star_rc_retain(i8* %t797)
  %t798 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t799 = load i32, i32* %t798
  %t800 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.52, i64 0, i32 2, i64 0
  %t801 = call i1 @save__save_high_score(i8* %t796, i32 %t799, i8* %t800)
  store i32 4, i32* %t802
  br label %while_cond_647
while_cond_647:
  %t803 = load i32, i32* %t802
  %t804 = icmp sge i32 %t803, 0
  br i1 %t804, label %while_body_648, label %while_else_649
while_body_648:
  %t805 = load i32, i32* %t802
  %t806 = icmp eq i32 %t805, 0
  br i1 %t806, label %logic_short_652, label %logic_rhs_651
logic_rhs_651:
  %t807 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t808 = load i32, i32* %t807
  %t809 = load i32, i32* %t802
  %t810 = sub i32 %t809, 1
  %t811 = sext i32 %t810 to i64
  %t812 = icmp ult i64 %t811, 5
  br i1 %t812, label %arr_rplace_ok_654, label %arr_rplace_oob_655
arr_rplace_ok_654:
  %t813 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t811
  br label %arr_rplace_end_656
arr_rplace_oob_655:
  store i32 0, i32* %t814
  br label %arr_rplace_end_656
arr_rplace_end_656:
  %t815 = phi i32* [ %t813, %arr_rplace_ok_654 ], [ %t814, %arr_rplace_oob_655 ]
  %t816 = load i32, i32* %t815
  %t817 = icmp sle i32 %t808, %t816
  br label %logic_end_653
logic_short_652:
  br label %logic_end_653
logic_end_653:
  %t818 = phi i1 [ %t817, %arr_rplace_end_656 ], [ true, %logic_short_652 ]
  br i1 %t818, label %if_then_657, label %if_else_658
if_then_657:
  %t819 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t820 = load i32, i32* %t819
  %t821 = load i32, i32* %t802
  %t822 = sext i32 %t821 to i64
  %t823 = icmp ult i64 %t822, 5
  br i1 %t823, label %arr_set_do_660, label %arr_set_oob_661
arr_set_do_660:
  %t824 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t822
  store i32 %t820, i32* %t824
  br label %arr_set_end_662
arr_set_oob_661:
  br label %arr_set_end_662
arr_set_end_662:
  br label %while_end_650
if_else_658:
  br label %if_end_659
if_end_659:
  %t825 = load i32, i32* %t802
  %t826 = sub i32 %t825, 1
  %t827 = sext i32 %t826 to i64
  %t828 = icmp ult i64 %t827, 5
  br i1 %t828, label %arr_rplace_ok_663, label %arr_rplace_oob_664
arr_rplace_ok_663:
  %t829 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t827
  br label %arr_rplace_end_665
arr_rplace_oob_664:
  store i32 0, i32* %t830
  br label %arr_rplace_end_665
arr_rplace_end_665:
  %t831 = phi i32* [ %t829, %arr_rplace_ok_663 ], [ %t830, %arr_rplace_oob_664 ]
  %t832 = load i32, i32* %t831
  %t833 = load i32, i32* %t802
  %t834 = sext i32 %t833 to i64
  %t835 = icmp ult i64 %t834, 5
  br i1 %t835, label %arr_set_do_666, label %arr_set_oob_667
arr_set_do_666:
  %t836 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t834
  store i32 %t832, i32* %t836
  br label %arr_set_end_668
arr_set_oob_667:
  br label %arr_set_end_668
arr_set_end_668:
  %t837 = load i32, i32* %t802
  %t838 = sub i32 %t837, 1
  store i32 %t838, i32* %t802
  br label %while_cond_647
while_else_649:
  br label %while_end_650
while_end_650:
  %t839 = sext i32 0 to i64
  %t840 = icmp ult i64 %t839, 5
  br i1 %t840, label %arr_rplace_ok_669, label %arr_rplace_oob_670
arr_rplace_ok_669:
  %t841 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t839
  br label %arr_rplace_end_671
arr_rplace_oob_670:
  store i32 0, i32* %t842
  br label %arr_rplace_end_671
arr_rplace_end_671:
  %t843 = phi i32* [ %t841, %arr_rplace_ok_669 ], [ %t842, %arr_rplace_oob_670 ]
  %t844 = load i32, i32* %t843
  %t845 = sext i32 1 to i64
  %t846 = icmp ult i64 %t845, 5
  br i1 %t846, label %arr_rplace_ok_672, label %arr_rplace_oob_673
arr_rplace_ok_672:
  %t847 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t845
  br label %arr_rplace_end_674
arr_rplace_oob_673:
  store i32 0, i32* %t848
  br label %arr_rplace_end_674
arr_rplace_end_674:
  %t849 = phi i32* [ %t847, %arr_rplace_ok_672 ], [ %t848, %arr_rplace_oob_673 ]
  %t850 = load i32, i32* %t849
  %t851 = sext i32 2 to i64
  %t852 = icmp ult i64 %t851, 5
  br i1 %t852, label %arr_rplace_ok_675, label %arr_rplace_oob_676
arr_rplace_ok_675:
  %t853 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t851
  br label %arr_rplace_end_677
arr_rplace_oob_676:
  store i32 0, i32* %t854
  br label %arr_rplace_end_677
arr_rplace_end_677:
  %t855 = phi i32* [ %t853, %arr_rplace_ok_675 ], [ %t854, %arr_rplace_oob_676 ]
  %t856 = load i32, i32* %t855
  %t857 = sext i32 3 to i64
  %t858 = icmp ult i64 %t857, 5
  br i1 %t858, label %arr_rplace_ok_678, label %arr_rplace_oob_679
arr_rplace_ok_678:
  %t859 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t857
  br label %arr_rplace_end_680
arr_rplace_oob_679:
  store i32 0, i32* %t860
  br label %arr_rplace_end_680
arr_rplace_end_680:
  %t861 = phi i32* [ %t859, %arr_rplace_ok_678 ], [ %t860, %arr_rplace_oob_679 ]
  %t862 = load i32, i32* %t861
  %t863 = sext i32 4 to i64
  %t864 = icmp ult i64 %t863, 5
  br i1 %t864, label %arr_rplace_ok_681, label %arr_rplace_oob_682
arr_rplace_ok_681:
  %t865 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t863
  br label %arr_rplace_end_683
arr_rplace_oob_682:
  store i32 0, i32* %t866
  br label %arr_rplace_end_683
arr_rplace_end_683:
  %t867 = phi i32* [ %t865, %arr_rplace_ok_681 ], [ %t866, %arr_rplace_oob_682 ]
  %t868 = load i32, i32* %t867
  %t869 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.53, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t869, i32 %t844, i32 %t850, i32 %t856, i32 %t862, i32 %t868)
  %t872 = load i8*, i8** %t10
  %t873 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t871, i32 0, i32 0
  store i8* %t872, i8** %t873
  %t874 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t871, i32 0, i32 1
  store i32 0, i32* %t874
  %t875 = load %GameOverFlash, %GameOverFlash* %t871
  store %GameOverFlash %t875, %GameOverFlash* %t870
  store i1 true, i1* %t876
  br label %while_cond_684
while_cond_684:
  %t877 = load i1, i1* %t876
  br i1 %t877, label %while_body_685, label %while_else_686
while_body_685:
  %t878 = call i1 @GameOverFlash__resume(%GameOverFlash* %t870)
  store i1 %t878, i1* %t876
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
  %t879 = load i8, i8* %t61
  %t880 = trunc i32 1 to i8
  %t881 = add i8 %t879, %t880
  store i8 %t881, i8* %t61
  %t883 = load i8, i8* %t61
  %t884 = uitofp i8 %t883 to float
  store float %t884, float* %t882
  %t886 = load float, float* %t882
  %t887 = fmul float %t886, 0x3FC3333340000000
  %t888 = call float @llvm.sin.f32(float %t887)
  %t889 = fmul float %t888, 0x4000000000000000
  store float %t889, float* %t885
  %t890 = load i8*, i8** %t10
  %t891 = icmp eq i8* %t890, null
  br i1 %t891, label %sdl_null_window_688, label %sdl_window_handle_ok_689
sdl_null_window_688:
  %t892 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.54, i64 0, i64 0
  call i32 @puts(i8* %t892)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_689:
  %t893 = call i8* @SDL_GetRenderer(i8* %t890)
  %t894 = and i32 18, 255
  %t895 = and i32 18, 255
  %t896 = shl i32 %t895, 8
  %t897 = or i32 %t894, %t896
  %t898 = and i32 24, 255
  %t899 = shl i32 %t898, 16
  %t900 = or i32 %t897, %t899
  %t901 = and i32 255, 255
  %t902 = shl i32 %t901, 24
  %t903 = or i32 %t900, %t902
  %t904 = and i32 %t903, 255
  %t905 = trunc i32 %t904 to i8
  %t906 = lshr i32 %t903, 8
  %t907 = and i32 %t906, 255
  %t908 = trunc i32 %t907 to i8
  %t909 = lshr i32 %t903, 16
  %t910 = and i32 %t909, 255
  %t911 = trunc i32 %t910 to i8
  %t912 = lshr i32 %t903, 24
  %t913 = and i32 %t912, 255
  %t914 = trunc i32 %t913 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t893, i8 %t905, i8 %t908, i8 %t911, i8 %t914)
  call i32 @SDL_RenderClear(i8* %t893)
  %t916 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t53
  %t917 = call { i32, i32 } @cell_px(%food__sb__grid__Cell %t916)
  store { i32, i32 } %t917, { i32, i32 }* %t915
  %t919 = load float, float* %t885
  %t920 = call i32 @llvm.fptosi.sat.i32.f32(float %t919)
  store i32 %t920, i32* %t918
  %t921 = load i8*, i8** %t10
  %t922 = icmp eq i8* %t921, null
  br i1 %t922, label %sdl_null_window_690, label %sdl_window_handle_ok_691
sdl_null_window_690:
  %t923 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.55, i64 0, i64 0
  call i32 @puts(i8* %t923)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_691:
  %t924 = call i8* @SDL_GetRenderer(i8* %t921)
  %t925 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t915, i32 0, i32 0
  %t926 = load i32, i32* %t925
  %t927 = load i32, i32* %t918
  %t928 = sub i32 %t926, %t927
  %t929 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t915, i32 0, i32 1
  %t930 = load i32, i32* %t929
  %t931 = load i32, i32* %t918
  %t932 = sub i32 %t930, %t931
  %t933 = call i32 @food__sb__grid__cell_size()
  %t934 = sub i32 %t933, 1
  %t935 = load i32, i32* %t918
  %t936 = mul i32 %t935, 2
  %t937 = add i32 %t934, %t936
  %t938 = call i32 @food__sb__grid__cell_size()
  %t939 = sub i32 %t938, 1
  %t940 = load i32, i32* %t918
  %t941 = mul i32 %t940, 2
  %t942 = add i32 %t939, %t941
  %t943 = and i32 230, 255
  %t944 = and i32 90, 255
  %t945 = shl i32 %t944, 8
  %t946 = or i32 %t943, %t945
  %t947 = and i32 90, 255
  %t948 = shl i32 %t947, 16
  %t949 = or i32 %t946, %t948
  %t950 = and i32 255, 255
  %t951 = shl i32 %t950, 24
  %t952 = or i32 %t949, %t951
  %t953 = and i32 %t952, 255
  %t954 = trunc i32 %t953 to i8
  %t955 = lshr i32 %t952, 8
  %t956 = and i32 %t955, 255
  %t957 = trunc i32 %t956 to i8
  %t958 = lshr i32 %t952, 16
  %t959 = and i32 %t958, 255
  %t960 = trunc i32 %t959 to i8
  %t961 = lshr i32 %t952, 24
  %t962 = and i32 %t961, 255
  %t963 = trunc i32 %t962 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t924, i8 %t954, i8 %t957, i8 %t960, i8 %t963)
  %t965 = getelementptr inbounds [16 x i8], [16 x i8]* %t964, i64 0, i64 0
  %t966 = bitcast i8* %t965 to i32*
  store i32 %t928, i32* %t966
  %t967 = getelementptr inbounds i8, i8* %t965, i64 4
  %t968 = bitcast i8* %t967 to i32*
  store i32 %t932, i32* %t968
  %t969 = getelementptr inbounds i8, i8* %t965, i64 8
  %t970 = bitcast i8* %t969 to i32*
  store i32 %t937, i32* %t970
  %t971 = getelementptr inbounds i8, i8* %t965, i64 12
  %t972 = bitcast i8* %t971 to i32*
  store i32 %t942, i32* %t972
  call i32 @SDL_RenderFillRect(i8* %t924, i8* %t965)
  store i32 0, i32* %t973
  br label %while_cond_692
while_cond_692:
  %t974 = load i32, i32* %t973
  %t975 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t976 = icmp slt i32 %t974, %t975
  br i1 %t976, label %while_body_693, label %while_else_694
while_body_693:
  %t978 = load i32, i32* %t973
  %t979 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t980 = sub i32 %t979, 1
  %t981 = icmp eq i32 %t978, %t980
  store i1 %t981, i1* %t977
  %t982 = load i8*, i8** %t10
  %t983 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 0
  %t984 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t983, i32 0, i32 0
  %t985 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t983, i32 0, i32 1
  %t986 = load i64, i64* %t985
  %t987 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t983, i32 0, i32 2
  %t988 = load i64, i64* %t987
  %t989 = load i32, i32* %t973
  %t990 = sext i32 %t989 to i64
  %t991 = load i64, i64* %t985
  %t992 = load i64, i64* %t987
  %t993 = icmp ult i64 %t990, %t992
  br i1 %t993, label %ring_rplace_ok_696, label %ring_rplace_oob_697
ring_rplace_ok_696:
  %t994 = add i64 %t991, %t990
  %t995 = urem i64 %t994, 768
  %t996 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t984, i32 0, i64 %t995
  br label %ring_rplace_end_698
ring_rplace_oob_697:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t997
  br label %ring_rplace_end_698
ring_rplace_end_698:
  %t998 = phi %food__sb__grid__Cell* [ %t996, %ring_rplace_ok_696 ], [ %t997, %ring_rplace_oob_697 ]
  %t999 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t998
  %t1000 = load i1, i1* %t977
  %t1001 = and i32 140, 255
  %t1002 = and i32 230, 255
  %t1003 = shl i32 %t1002, 8
  %t1004 = or i32 %t1001, %t1003
  %t1005 = and i32 160, 255
  %t1006 = shl i32 %t1005, 16
  %t1007 = or i32 %t1004, %t1006
  %t1008 = and i32 255, 255
  %t1009 = shl i32 %t1008, 24
  %t1010 = or i32 %t1007, %t1009
  %t1011 = and i32 80, 255
  %t1012 = and i32 190, 255
  %t1013 = shl i32 %t1012, 8
  %t1014 = or i32 %t1011, %t1013
  %t1015 = and i32 120, 255
  %t1016 = shl i32 %t1015, 16
  %t1017 = or i32 %t1014, %t1016
  %t1018 = and i32 255, 255
  %t1019 = shl i32 %t1018, 24
  %t1020 = or i32 %t1017, %t1019
  %t1021 = call i32 @pick_color(i1 %t1000, i32 %t1010, i32 %t1020)
  call void @draw_cell(i8* %t982, %food__sb__grid__Cell %t999, i32 %t1021)
  %t1022 = load i32, i32* %t973
  %t1023 = add i32 %t1022, 1
  store i32 %t1023, i32* %t973
  br label %while_cond_692
while_else_694:
  br label %while_end_695
while_end_695:
  call void @ParticlePool__update(%ParticlePool* %t72, float 0x3F90624DE0000000)
  %t1025 = load i8*, i8** %t10
  call void @ParticlePool__draw(%ParticlePool* %t72, i8* %t1025)
  call void @tick_particle_arena(float 0x3F90624DE0000000)
  call void @reclaim_dead_particles()
  %t1027 = load i64, i64* %t58
  %t1028 = zext i32 1 to i64
  %t1029 = shl i64 1, %t1028
  %t1030 = and i64 %t1027, %t1029
  %t1031 = icmp ne i64 %t1030, 0
  br i1 %t1031, label %if_then_699, label %if_else_700
if_then_699:
  %t1032 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t1033 = load i32, i32* %t1032
  %t1034 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t1035 = load i32, i32* %t1034
  %t1036 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t1037 = load i64, i64* %t58
  %t1038 = zext i32 0 to i64
  %t1039 = shl i64 1, %t1038
  %t1040 = and i64 %t1037, %t1039
  %t1041 = icmp ne i64 %t1040, 0
  %t1042 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t1043 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t1044 = select i1 %t1041, i8* %t1042, i8* %t1043
  %t1045 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 1
  %t1046 = load i32, i32* %t1045
  %t1047 = call i8* @food__sb__grid__dir_name(i32 %t1046)
  call void @star_rc_release(i8* %t1047)
  %t1048 = load i1, i1* %t96
  %t1049 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.58, i64 0, i64 0
  %t1050 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.59, i64 0, i64 0
  %t1051 = select i1 %t1048, i8* %t1049, i8* %t1050
  %t1052 = getelementptr inbounds [59 x i8], [59 x i8]* @.str.60, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1052, i32 %t1033, i32 %t1035, i32 %t1036, i8* %t1044, i8* %t1047, i8* %t1051)
  br label %if_end_701
if_else_700:
  br label %if_end_701
if_end_701:
  %t1053 = load i8*, i8** %t10
  %t1054 = icmp eq i8* %t1053, null
  br i1 %t1054, label %sdl_null_window_702, label %sdl_window_handle_ok_703
sdl_null_window_702:
  %t1055 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.61, i64 0, i64 0
  call i32 @puts(i8* %t1055)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_703:
  %t1056 = call i8* @SDL_GetRenderer(i8* %t1053)
  call void @SDL_RenderPresent(i8* %t1056)
  %t1057 = icmp slt i32 16, 0
  %t1058 = select i1 %t1057, i32 0, i32 16
  call void @SDL_Delay(i32 %t1058)
  br label %while_cond_424
while_else_426:
  br label %while_end_427
while_end_427:
  %t1059 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t1060 = load i32, i32* %t1059
  %t1061 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t1062 = load i32, i32* %t1061
  %t1063 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.62, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1063, i32 %t1060, i32 %t1062)
  %t1064 = load i8, i8* %t59
  %t1065 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.63, i64 0, i64 0
  %t1066 = zext i8 %t1064 to i32
  call i32 (i8*, ...) @printf(i8* %t1065, i32 %t1066)
  %t1067 = load i8*, i8** %t10
  %t1068 = icmp eq i8* %t1067, null
  br i1 %t1068, label %sdl_null_window_704, label %sdl_window_handle_ok_705
sdl_null_window_704:
  %t1069 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.64, i64 0, i64 0
  call i32 @puts(i8* %t1069)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_705:
  %t1070 = call i8* @SDL_GetRenderer(i8* %t1067)
  call void @SDL_DestroyRenderer(i8* %t1070)
  call void @SDL_DestroyWindow(i8* %t1067)
  store i8* null, i8** %t10
  %t1071 = load i8*, i8** %t60
  call void @star_rc_release(i8* %t1071)
  %t1072 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t29, i32 0, i32 1
  %t1073 = load i8*, i8** %t1072
  call void @star_rc_release(i8* %t1073)
  %t1074 = load i8*, i8** %t27
  call void @star_rc_release(i8* %t1074)
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
  %t45 = bitcast i8* %objp to { %food__sb__grid__Cell*, i64, i64 }*
  %t46 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t45, i32 0, i32 0
  %t47 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t46
  %t48 = bitcast %food__sb__grid__Cell* %t47 to i8*
  call void @free(i8* %t48)
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
  %t354 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t355 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t354, i32 0, i32 0
  %t356 = load i64*, i64** %t355
  %t357 = bitcast i64* %t356 to i8*
  call void @free(i8* %t357)
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
