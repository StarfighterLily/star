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

define i1 @food__sb__grid__cell_eq(%food__sb__grid__Cell %a, %food__sb__grid__Cell %b) {
entry:
  %t0 = alloca %food__sb__grid__Cell
  %t1 = alloca %food__sb__grid__Cell
  store %food__sb__grid__Cell %a, %food__sb__grid__Cell* %t0
  store %food__sb__grid__Cell %b, %food__sb__grid__Cell* %t1
  %t2 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t1, i32 0, i32 0
  %t5 = load i32, i32* %t4
  %t6 = icmp eq i32 %t3, %t5
  br i1 %t6, label %logic_rhs_0, label %logic_short_1
logic_rhs_0:
  %t7 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t0, i32 0, i32 1
  %t8 = load i32, i32* %t7
  %t9 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t1, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = icmp eq i32 %t8, %t10
  br label %logic_end_2
logic_short_1:
  br label %logic_end_2
logic_end_2:
  %t12 = phi i1 [ %t11, %logic_rhs_0 ], [ false, %logic_short_1 ]
  ret i1 %t12
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
  br i1 %t8, label %if_then_3, label %if_else_4
if_then_3:
  %t9 = call i32 @food__sb__grid__cols()
  %t10 = sub i32 %t9, 1
  store i32 %t10, i32* %t1
  br label %if_end_5
if_else_4:
  br label %if_end_5
if_end_5:
  %t11 = load i32, i32* %t1
  %t12 = call i32 @food__sb__grid__cols()
  %t13 = icmp sge i32 %t11, %t12
  br i1 %t13, label %if_then_6, label %if_else_7
if_then_6:
  store i32 0, i32* %t1
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t14 = load i32, i32* %t4
  %t15 = icmp slt i32 %t14, 0
  br i1 %t15, label %if_then_9, label %if_else_10
if_then_9:
  %t16 = call i32 @food__sb__grid__rows()
  %t17 = sub i32 %t16, 1
  store i32 %t17, i32* %t4
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t18 = load i32, i32* %t4
  %t19 = call i32 @food__sb__grid__rows()
  %t20 = icmp sge i32 %t18, %t19
  br i1 %t20, label %if_then_12, label %if_else_13
if_then_12:
  store i32 0, i32* %t4
  br label %if_end_14
if_else_13:
  br label %if_end_14
if_end_14:
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
  br i1 %t20, label %ring_rplace_ok_15, label %ring_rplace_oob_16
ring_rplace_ok_15:
  %t21 = add i64 %t18, %t17
  %t22 = urem i64 %t21, 768
  %t23 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t3, i32 0, i64 %t22
  br label %ring_rplace_end_17
ring_rplace_oob_16:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t24
  br label %ring_rplace_end_17
ring_rplace_end_17:
  %t25 = phi %food__sb__grid__Cell* [ %t23, %ring_rplace_ok_15 ], [ %t24, %ring_rplace_oob_16 ]
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
  br label %while_cond_18
while_cond_18:
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
  br i1 %t13, label %while_body_19, label %while_else_20
while_body_19:
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
  br i1 %t25, label %ring_rplace_ok_22, label %ring_rplace_oob_23
ring_rplace_ok_22:
  %t26 = add i64 %t23, %t22
  %t27 = urem i64 %t26, 768
  %t28 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t16, i32 0, i64 %t27
  br label %ring_rplace_end_24
ring_rplace_oob_23:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t29
  br label %ring_rplace_end_24
ring_rplace_end_24:
  %t30 = phi %food__sb__grid__Cell* [ %t28, %ring_rplace_ok_22 ], [ %t29, %ring_rplace_oob_23 ]
  %t31 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t30
  %t32 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t1
  %t33 = call i1 @food__sb__grid__cell_eq(%food__sb__grid__Cell %t31, %food__sb__grid__Cell %t32)
  br i1 %t33, label %if_then_25, label %if_else_26
if_then_25:
  store i1 true, i1* %t3
  br label %if_end_27
if_else_26:
  br label %if_end_27
if_end_27:
  %t34 = load i32, i32* %t2
  %t35 = add i32 %t34, 1
  store i32 %t35, i32* %t2
  br label %while_cond_18
while_else_20:
  br label %while_end_21
while_end_21:
  %t36 = load i1, i1* %t3
  ret i1 %t36
}

define void @food__sb__Snake__queue_turn(%food__sb__Snake* %self, i32 %d) {
entry:
  %t0 = alloca %food__sb__Snake*
  %t1 = alloca i32
  %t2 = alloca %food__sb__grid__Cell
  %t5 = alloca %food__sb__grid__Cell
  %t10 = alloca i1
  store %food__sb__Snake* %self, %food__sb__Snake** %t0
  store i32 %d, i32* %t1
  %t3 = load i32, i32* %t1
  %t4 = call %food__sb__grid__Cell @food__sb__grid__delta(i32 %t3)
  store %food__sb__grid__Cell %t4, %food__sb__grid__Cell* %t2
  %t6 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t7 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t6, i32 0, i32 1
  %t8 = load i32, i32* %t7
  %t9 = call %food__sb__grid__Cell @food__sb__grid__delta(i32 %t8)
  store %food__sb__grid__Cell %t9, %food__sb__grid__Cell* %t5
  %t11 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t2, i32 0, i32 0
  %t12 = load i32, i32* %t11
  %t13 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t5, i32 0, i32 0
  %t14 = load i32, i32* %t13
  %t15 = sub i32 0, %t14
  %t16 = icmp eq i32 %t12, %t15
  br i1 %t16, label %logic_rhs_28, label %logic_short_29
logic_rhs_28:
  %t17 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t2, i32 0, i32 1
  %t18 = load i32, i32* %t17
  %t19 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t5, i32 0, i32 1
  %t20 = load i32, i32* %t19
  %t21 = sub i32 0, %t20
  %t22 = icmp eq i32 %t18, %t21
  br label %logic_end_30
logic_short_29:
  br label %logic_end_30
logic_end_30:
  %t23 = phi i1 [ %t22, %logic_rhs_28 ], [ false, %logic_short_29 ]
  store i1 %t23, i1* %t10
  %t24 = load i1, i1* %t10
  %t25 = xor i1 true, %t24
  br i1 %t25, label %if_then_31, label %if_else_32
if_then_31:
  %t26 = load i32, i32* %t1
  %t27 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t28 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t27, i32 0, i32 2
  store i32 %t26, i32* %t28
  br label %if_end_33
if_else_32:
  br label %if_end_33
if_end_33:
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
  br i1 %t17, label %if_then_34, label %if_else_35
if_then_34:
  %t18 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t19 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t18, i32 0, i32 4
  store i1 false, i1* %t19
  br label %if_end_36
if_else_35:
  br label %if_end_36
if_end_36:
  %t20 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t6
  %t21 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t22 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t21, i32 0, i32 0
  %t23 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t22, i32 0, i32 0
  %t24 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t22, i32 0, i32 1
  %t25 = load i64, i64* %t24
  %t26 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t22, i32 0, i32 2
  %t27 = load i64, i64* %t26
  %t28 = icmp sge i64 %t27, 768
  br i1 %t28, label %ring_push_full_37, label %ring_push_grow_38
ring_push_grow_38:
  %t29 = add i64 %t25, %t27
  %t30 = urem i64 %t29, 768
  %t31 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t23, i32 0, i64 %t30
  store %food__sb__grid__Cell %t20, %food__sb__grid__Cell* %t31
  %t32 = add i64 %t27, 1
  store i64 %t32, i64* %t26
  br label %ring_push_done_39
ring_push_full_37:
  %t33 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t23, i32 0, i64 %t25
  store %food__sb__grid__Cell %t20, %food__sb__grid__Cell* %t33
  %t34 = add i64 %t25, 1
  %t35 = urem i64 %t34, 768
  store i64 %t35, i64* %t24
  br label %ring_push_done_39
ring_push_done_39:
  %t36 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t37 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t36, i32 0, i32 3
  %t38 = load i32, i32* %t37
  %t39 = icmp sgt i32 %t38, 0
  br i1 %t39, label %if_then_40, label %if_else_41
if_then_40:
  %t40 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t41 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t40, i32 0, i32 3
  %t42 = load i32, i32* %t41
  %t43 = sub i32 %t42, 1
  %t44 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t45 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t44, i32 0, i32 3
  store i32 %t43, i32* %t45
  br label %if_end_42
if_else_41:
  %t46 = load %food__sb__Snake*, %food__sb__Snake** %t0
  %t47 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t46, i32 0, i32 0
  %t48 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t47, i32 0, i32 0
  %t49 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t47, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t47, i32 0, i32 2
  %t52 = load i64, i64* %t51
  %t53 = icmp eq i64 %t52, 0
  br i1 %t53, label %ring_pop_empty_43, label %ring_pop_nonempty_44
ring_pop_nonempty_44:
  %t54 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t48, i32 0, i64 %t50
  %t55 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t54
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t54
  %t56 = add i64 %t50, 1
  %t57 = urem i64 %t56, 768
  store i64 %t57, i64* %t49
  %t58 = sub i64 %t52, 1
  store i64 %t58, i64* %t51
  br label %ring_pop_end_45
ring_pop_empty_43:
  br label %ring_pop_end_45
ring_pop_end_45:
  %t59 = phi %food__sb__grid__Cell [ %t55, %ring_pop_nonempty_44 ], [ zeroinitializer, %ring_pop_empty_43 ]
  br label %if_end_42
if_end_42:
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
  br i1 %t18, label %ring_push_full_46, label %ring_push_grow_47
ring_push_grow_47:
  %t19 = add i64 %t15, %t17
  %t20 = urem i64 %t19, 768
  %t21 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t13, i32 0, i64 %t20
  store %food__sb__grid__Cell %t11, %food__sb__grid__Cell* %t21
  %t22 = add i64 %t17, 1
  store i64 %t22, i64* %t16
  br label %ring_push_done_48
ring_push_full_46:
  %t23 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t13, i32 0, i64 %t15
  store %food__sb__grid__Cell %t11, %food__sb__grid__Cell* %t23
  %t24 = add i64 %t15, 1
  %t25 = urem i64 %t24, 768
  store i64 %t25, i64* %t14
  br label %ring_push_done_48
ring_push_done_48:
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
  br i1 %t36, label %ring_push_full_49, label %ring_push_grow_50
ring_push_grow_50:
  %t37 = add i64 %t33, %t35
  %t38 = urem i64 %t37, 768
  %t39 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t31, i32 0, i64 %t38
  store %food__sb__grid__Cell %t29, %food__sb__grid__Cell* %t39
  %t40 = add i64 %t35, 1
  store i64 %t40, i64* %t34
  br label %ring_push_done_51
ring_push_full_49:
  %t41 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t31, i32 0, i64 %t33
  store %food__sb__grid__Cell %t29, %food__sb__grid__Cell* %t41
  %t42 = add i64 %t33, 1
  %t43 = urem i64 %t42, 768
  store i64 %t43, i64* %t32
  br label %ring_push_done_51
ring_push_done_51:
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
  br i1 %t54, label %ring_push_full_52, label %ring_push_grow_53
ring_push_grow_53:
  %t55 = add i64 %t51, %t53
  %t56 = urem i64 %t55, 768
  %t57 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t49, i32 0, i64 %t56
  store %food__sb__grid__Cell %t47, %food__sb__grid__Cell* %t57
  %t58 = add i64 %t53, 1
  store i64 %t58, i64* %t52
  br label %ring_push_done_54
ring_push_full_52:
  %t59 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t49, i32 0, i64 %t51
  store %food__sb__grid__Cell %t47, %food__sb__grid__Cell* %t59
  %t60 = add i64 %t51, 1
  %t61 = urem i64 %t60, 768
  store i64 %t61, i64* %t50
  br label %ring_push_done_54
ring_push_done_54:
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
  %t76 = alloca i64
  %t77 = alloca i1
  store { [768 x %food__sb__grid__Cell], i64, i64 } %body, { [768 x %food__sb__grid__Cell], i64, i64 }* %t0
  store i32 %len, i32* %t1
  store i8* null, i8** %t2
  store i32 0, i32* %t3
  br label %while_cond_55
while_cond_55:
  %t4 = load i32, i32* %t3
  %t5 = load i32, i32* %t1
  %t6 = icmp slt i32 %t4, %t5
  br i1 %t6, label %while_body_56, label %while_else_57
while_body_56:
  %t7 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t8 = ptrtoint %food__sb__grid__Cell* %t7 to i64
  %t9 = load i8*, i8** %t2
  %t10 = icmp eq i8* %t9, null
  br i1 %t10, label %set_cow_alloc_59, label %set_cow_check_60
set_cow_alloc_59:
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
  br label %set_cow_done_61
set_cow_check_60:
  %t21 = getelementptr inbounds i8, i8* %t9, i64 -16
  %t22 = bitcast i8* %t21 to i64*
  %t23 = load atomic i64, i64* %t22 seq_cst, align 8
  %t24 = icmp eq i64 %t23, 1
  br i1 %t24, label %set_cow_done_61, label %set_cow_clone_62
set_cow_clone_62:
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
  br i1 %t38, label %set_cow_copy_63, label %set_cow_after_copy_64
set_cow_copy_63:
  %t39 = mul i64 %t29, %t8
  %t40 = bitcast %food__sb__grid__Cell* %t27 to i8*
  call i8* @memcpy(i8* %t36, i8* %t40, i64 %t39)
  br label %set_cow_after_copy_64
set_cow_after_copy_64:
  %t41 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t34, i32 0, i32 0
  store %food__sb__grid__Cell* %t37, %food__sb__grid__Cell** %t41
  %t42 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t34, i32 0, i32 1
  store i64 %t29, i64* %t42
  %t43 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t34, i32 0, i32 2
  store i64 %t31, i64* %t43
  call void @star_rc_release(i8* %t9)
  store i8* %t33, i8** %t2
  br label %set_cow_done_61
set_cow_done_61:
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
  br i1 %t60, label %ring_rplace_ok_65, label %ring_rplace_oob_66
ring_rplace_ok_65:
  %t61 = add i64 %t58, %t57
  %t62 = urem i64 %t61, 768
  %t63 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t51, i32 0, i64 %t62
  br label %ring_rplace_end_67
ring_rplace_oob_66:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t64
  br label %ring_rplace_end_67
ring_rplace_end_67:
  %t65 = phi %food__sb__grid__Cell* [ %t63, %ring_rplace_ok_65 ], [ %t64, %ring_rplace_oob_66 ]
  %t66 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t65
  %t67 = load i64, i64* %t48
  %t68 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t46
  store i64 0, i64* %t76
  store i1 false, i1* %t77
  br label %find_cond_68
find_cond_68:
  %t78 = load i64, i64* %t76
  %t79 = icmp slt i64 %t78, %t67
  br i1 %t79, label %find_body_69, label %find_end_72
find_body_69:
  %t80 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t68, i64 %t78
  %t81 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t80
  br label %find_eq_check_70
find_eq_check_70:
  %t82 = call i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %t81, %food__sb__grid__Cell %t66)
  br i1 %t82, label %find_end_72, label %find_next_71
find_next_71:
  %t83 = add i64 %t78, 1
  store i64 %t83, i64* %t76
  br label %find_cond_68
find_end_72:
  %t84 = load i64, i64* %t76
  %t85 = icmp slt i64 %t84, %t67
  br i1 %t85, label %set_insert_already_present_73, label %set_insert_do_74
set_insert_already_present_73:
  br label %set_insert_end_75
set_insert_do_74:
  %t86 = load i64, i64* %t50
  %t87 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t46
  %t88 = icmp sge i64 %t67, %t86
  br i1 %t88, label %set_insert_grow_76, label %set_insert_store_77
set_insert_grow_76:
  %t89 = mul i64 %t86, 2
  %t90 = icmp sgt i64 %t89, 0
  %t91 = select i1 %t90, i64 %t89, i64 1
  %t92 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t93 = ptrtoint %food__sb__grid__Cell* %t92 to i64
  %t94 = mul i64 %t91, %t93
  %t95 = call i8* @malloc(i64 %t94)
  %t96 = bitcast i8* %t95 to %food__sb__grid__Cell*
  %t97 = icmp sgt i64 %t86, 0
  br i1 %t97, label %set_insert_copy_78, label %set_insert_after_copy_79
set_insert_copy_78:
  %t98 = mul i64 %t67, %t93
  %t99 = bitcast %food__sb__grid__Cell* %t87 to i8*
  call i8* @memcpy(i8* %t95, i8* %t99, i64 %t98)
  call void @free(i8* %t99)
  br label %set_insert_after_copy_79
set_insert_after_copy_79:
  store %food__sb__grid__Cell* %t96, %food__sb__grid__Cell** %t46
  store i64 %t91, i64* %t50
  br label %set_insert_store_77
set_insert_store_77:
  %t100 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t46
  %t101 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t100, i64 %t67
  store %food__sb__grid__Cell %t66, %food__sb__grid__Cell* %t101
  %t102 = add i64 %t67, 1
  store i64 %t102, i64* %t48
  br label %set_insert_end_75
set_insert_end_75:
  %t103 = phi i1 [ false, %set_insert_already_present_73 ], [ true, %set_insert_store_77 ]
  %t104 = load i32, i32* %t3
  %t105 = add i32 %t104, 1
  store i32 %t105, i32* %t3
  br label %while_cond_55
while_else_57:
  br label %while_end_58
while_end_58:
  %t106 = load i8*, i8** %t2
  %t107 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t107)
  %t108 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t108)
  ret i8* %t106
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
  br label %while_cond_80
while_cond_80:
  %t8 = load i32, i32* %t7
  %t9 = call i32 @food__sb__grid__rows()
  %t10 = icmp slt i32 %t8, %t9
  br i1 %t10, label %while_body_81, label %while_else_82
while_body_81:
  store i32 0, i32* %t11
  br label %while_cond_84
while_cond_84:
  %t12 = load i32, i32* %t11
  %t13 = call i32 @food__sb__grid__cols()
  %t14 = icmp slt i32 %t12, %t13
  br i1 %t14, label %while_body_85, label %while_else_86
while_body_85:
  %t16 = load i32, i32* %t11
  %t17 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t15, i32 0, i32 0
  store i32 %t16, i32* %t17
  %t18 = load i32, i32* %t7
  %t19 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t15, i32 0, i32 1
  store i32 %t18, i32* %t19
  %t20 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t15
  %t21 = load i8*, i8** %t2
  %t22 = icmp eq i8* %t21, null
  br i1 %t22, label %set_read_null_88, label %set_read_real_89
set_read_null_88:
  br label %set_read_end_90
set_read_real_89:
  %t23 = bitcast i8* %t21 to { %food__sb__grid__Cell*, i64, i64 }*
  %t24 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t23, i32 0, i32 0
  %t25 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t24
  %t26 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t23, i32 0, i32 1
  %t27 = load i64, i64* %t26
  br label %set_read_end_90
set_read_end_90:
  %t28 = phi %food__sb__grid__Cell* [ null, %set_read_null_88 ], [ %t25, %set_read_real_89 ]
  %t29 = phi i64 [ 0, %set_read_null_88 ], [ %t27, %set_read_real_89 ]
  store i64 0, i64* %t30
  store i1 false, i1* %t31
  br label %find_cond_91
find_cond_91:
  %t32 = load i64, i64* %t30
  %t33 = icmp slt i64 %t32, %t29
  br i1 %t33, label %find_body_92, label %find_end_95
find_body_92:
  %t34 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t28, i64 %t32
  %t35 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t34
  br label %find_eq_check_93
find_eq_check_93:
  %t36 = call i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %t35, %food__sb__grid__Cell %t20)
  br i1 %t36, label %find_end_95, label %find_next_94
find_next_94:
  %t37 = add i64 %t32, 1
  store i64 %t37, i64* %t30
  br label %find_cond_91
find_end_95:
  %t38 = load i64, i64* %t30
  %t39 = icmp slt i64 %t38, %t29
  %t40 = xor i1 true, %t39
  br i1 %t40, label %if_then_96, label %if_else_97
if_then_96:
  %t41 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t42 = ptrtoint %food__sb__grid__Cell* %t41 to i64
  %t43 = load i8*, i8** %t6
  %t44 = icmp eq i8* %t43, null
  br i1 %t44, label %list_cow_alloc_99, label %list_cow_check_100
list_cow_alloc_99:
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
  br label %list_cow_done_101
list_cow_check_100:
  %t55 = getelementptr inbounds i8, i8* %t43, i64 -16
  %t56 = bitcast i8* %t55 to i64*
  %t57 = load atomic i64, i64* %t56 seq_cst, align 8
  %t58 = icmp eq i64 %t57, 1
  br i1 %t58, label %list_cow_done_101, label %list_cow_clone_102
list_cow_clone_102:
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
  br i1 %t72, label %list_cow_copy_103, label %list_cow_after_copy_104
list_cow_copy_103:
  %t73 = mul i64 %t63, %t42
  %t74 = bitcast %food__sb__grid__Cell* %t61 to i8*
  call i8* @memcpy(i8* %t70, i8* %t74, i64 %t73)
  br label %list_cow_after_copy_104
list_cow_after_copy_104:
  %t75 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t68, i32 0, i32 0
  store %food__sb__grid__Cell* %t71, %food__sb__grid__Cell** %t75
  %t76 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t68, i32 0, i32 1
  store i64 %t63, i64* %t76
  %t77 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t68, i32 0, i32 2
  store i64 %t65, i64* %t77
  call void @star_rc_release(i8* %t43)
  store i8* %t67, i8** %t6
  br label %list_cow_done_101
list_cow_done_101:
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
  br i1 %t94, label %list_push_grow_105, label %list_push_store_106
list_push_grow_105:
  %t95 = mul i64 %t91, 2
  %t96 = icmp sgt i64 %t95, 0
  %t97 = select i1 %t96, i64 %t95, i64 1
  %t98 = getelementptr %food__sb__grid__Cell, %food__sb__grid__Cell* null, i32 1
  %t99 = ptrtoint %food__sb__grid__Cell* %t98 to i64
  %t100 = mul i64 %t97, %t99
  %t101 = call i8* @malloc(i64 %t100)
  %t102 = bitcast i8* %t101 to %food__sb__grid__Cell*
  %t103 = icmp sgt i64 %t91, 0
  br i1 %t103, label %list_push_copy_107, label %list_push_after_copy_108
list_push_copy_107:
  %t104 = mul i64 %t93, %t99
  %t105 = bitcast %food__sb__grid__Cell* %t92 to i8*
  call i8* @memcpy(i8* %t101, i8* %t105, i64 %t104)
  call void @free(i8* %t105)
  br label %list_push_after_copy_108
list_push_after_copy_108:
  store %food__sb__grid__Cell* %t102, %food__sb__grid__Cell** %t80
  store i64 %t97, i64* %t84
  br label %list_push_store_106
list_push_store_106:
  %t106 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t80
  %t107 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t106, i64 %t93
  store %food__sb__grid__Cell %t90, %food__sb__grid__Cell* %t107
  %t108 = add i64 %t93, 1
  store i64 %t108, i64* %t82
  br label %if_end_98
if_else_97:
  br label %if_end_98
if_end_98:
  %t109 = load i32, i32* %t11
  %t110 = add i32 %t109, 1
  store i32 %t110, i32* %t11
  br label %while_cond_84
while_else_86:
  br label %while_end_87
while_end_87:
  %t111 = load i32, i32* %t7
  %t112 = add i32 %t111, 1
  store i32 %t112, i32* %t7
  br label %while_cond_80
while_else_82:
  br label %while_end_83
while_end_83:
  %t113 = load i8*, i8** %t6
  %t114 = icmp eq i8* %t113, null
  br i1 %t114, label %list_read_null_109, label %list_read_real_110
list_read_null_109:
  br label %list_read_end_111
list_read_real_110:
  %t115 = bitcast i8* %t113 to { %food__sb__grid__Cell*, i64, i64 }*
  %t116 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t115, i32 0, i32 0
  %t117 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t116
  %t118 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t115, i32 0, i32 1
  %t119 = load i64, i64* %t118
  br label %list_read_end_111
list_read_end_111:
  %t120 = phi %food__sb__grid__Cell* [ null, %list_read_null_109 ], [ %t117, %list_read_real_110 ]
  %t121 = phi i64 [ 0, %list_read_null_109 ], [ %t119, %list_read_real_110 ]
  %t122 = trunc i64 %t121 to i32
  %t123 = icmp eq i32 %t122, 0
  br i1 %t123, label %if_then_112, label %if_else_113
if_then_112:
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
if_else_113:
  br label %if_end_114
if_end_114:
  %t133 = load i8*, i8** %t6
  %t134 = icmp eq i8* %t133, null
  br i1 %t134, label %list_read_null_115, label %list_read_real_116
list_read_null_115:
  br label %list_read_end_117
list_read_real_116:
  %t135 = bitcast i8* %t133 to { %food__sb__grid__Cell*, i64, i64 }*
  %t136 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t135, i32 0, i32 0
  %t137 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t136
  %t138 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t135, i32 0, i32 1
  %t139 = load i64, i64* %t138
  br label %list_read_end_117
list_read_end_117:
  %t140 = phi %food__sb__grid__Cell* [ null, %list_read_null_115 ], [ %t137, %list_read_real_116 ]
  %t141 = phi i64 [ 0, %list_read_null_115 ], [ %t139, %list_read_real_116 ]
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
  br i1 %t158, label %list_read_null_118, label %list_read_real_119
list_read_null_118:
  br label %list_read_end_120
list_read_real_119:
  %t159 = bitcast i8* %t157 to { %food__sb__grid__Cell*, i64, i64 }*
  %t160 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t159, i32 0, i32 0
  %t161 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t160
  %t162 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t159, i32 0, i32 1
  %t163 = load i64, i64* %t162
  br label %list_read_end_120
list_read_end_120:
  %t164 = phi %food__sb__grid__Cell* [ null, %list_read_null_118 ], [ %t161, %list_read_real_119 ]
  %t165 = phi i64 [ 0, %list_read_null_118 ], [ %t163, %list_read_real_119 ]
  %t166 = load i32, i32* %t132
  %t167 = sext i32 %t166 to i64
  %t168 = icmp ult i64 %t167, %t165
  br i1 %t168, label %list_idx_ok_121, label %list_idx_oob_122
list_idx_ok_121:
  %t169 = getelementptr inbounds %food__sb__grid__Cell, %food__sb__grid__Cell* %t164, i64 %t167
  %t170 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t169
  br label %list_idx_end_123
list_idx_oob_122:
  br label %list_idx_end_123
list_idx_end_123:
  %t171 = phi %food__sb__grid__Cell [ %t170, %list_idx_ok_121 ], [ zeroinitializer, %list_idx_oob_122 ]
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
  br label %trim_start_cond_124
trim_start_cond_124:
  %t9 = load i64, i64* %t8
  %t10 = icmp slt i64 %t9, %t7
  br i1 %t10, label %trim_start_body_125, label %trim_start_done_127
trim_start_body_125:
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
  br i1 %t23, label %trim_start_incr_126, label %trim_start_done_127
trim_start_incr_126:
  %t24 = add i64 %t9, 1
  store i64 %t24, i64* %t8
  br label %trim_start_cond_124
trim_start_done_127:
  %t25 = load i64, i64* %t8
  store i64 %t7, i64* %t26
  br label %trim_end_cond_128
trim_end_cond_128:
  %t27 = load i64, i64* %t26
  %t28 = icmp sgt i64 %t27, %t25
  br i1 %t28, label %trim_end_body_129, label %trim_end_done_131
trim_end_body_129:
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
  br i1 %t42, label %trim_end_decr_130, label %trim_end_done_131
trim_end_decr_130:
  store i64 %t29, i64* %t26
  br label %trim_end_cond_128
trim_end_done_131:
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
  br label %while_cond_132
while_cond_132:
  %t64 = load i32, i32* %t63
  %t65 = load i8*, i8** %t1
  %t66 = icmp eq i8* %t65, null
  br i1 %t66, label %list_read_null_136, label %list_read_real_137
list_read_null_136:
  br label %list_read_end_138
list_read_real_137:
  %t67 = bitcast i8* %t65 to { i8*, i64, i64 }*
  %t68 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t67, i32 0, i32 0
  %t69 = load i8*, i8** %t68
  %t70 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t67, i32 0, i32 1
  %t71 = load i64, i64* %t70
  br label %list_read_end_138
list_read_end_138:
  %t72 = phi i8* [ null, %list_read_null_136 ], [ %t69, %list_read_real_137 ]
  %t73 = phi i64 [ 0, %list_read_null_136 ], [ %t71, %list_read_real_137 ]
  %t74 = trunc i64 %t73 to i32
  %t75 = icmp slt i32 %t64, %t74
  br i1 %t75, label %while_body_133, label %while_else_134
while_body_133:
  %t77 = load i8*, i8** %t1
  %t78 = icmp eq i8* %t77, null
  br i1 %t78, label %list_read_null_139, label %list_read_real_140
list_read_null_139:
  br label %list_read_end_141
list_read_real_140:
  %t79 = bitcast i8* %t77 to { i8*, i64, i64 }*
  %t80 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t79, i32 0, i32 0
  %t81 = load i8*, i8** %t80
  %t82 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t79, i32 0, i32 1
  %t83 = load i64, i64* %t82
  br label %list_read_end_141
list_read_end_141:
  %t84 = phi i8* [ null, %list_read_null_139 ], [ %t81, %list_read_real_140 ]
  %t85 = phi i64 [ 0, %list_read_null_139 ], [ %t83, %list_read_real_140 ]
  %t86 = load i32, i32* %t63
  %t87 = sext i32 %t86 to i64
  %t88 = icmp ult i64 %t87, %t85
  br i1 %t88, label %list_idx_ok_142, label %list_idx_oob_143
list_idx_ok_142:
  %t89 = getelementptr inbounds i8, i8* %t84, i64 %t87
  %t90 = load i8, i8* %t89
  br label %list_idx_end_144
list_idx_oob_143:
  br label %list_idx_end_144
list_idx_end_144:
  %t91 = phi i8 [ %t90, %list_idx_ok_142 ], [ 0, %list_idx_oob_143 ]
  %t92 = zext i8 %t91 to i32
  %t93 = call i32 @toupper(i32 %t92)
  store i32 %t93, i32* %t76
  %t94 = getelementptr i8, i8* null, i32 1
  %t95 = ptrtoint i8* %t94 to i64
  %t96 = load i8*, i8** %t62
  %t97 = icmp eq i8* %t96, null
  br i1 %t97, label %list_cow_alloc_145, label %list_cow_check_146
list_cow_alloc_145:
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
  br label %list_cow_done_147
list_cow_check_146:
  %t104 = getelementptr inbounds i8, i8* %t96, i64 -16
  %t105 = bitcast i8* %t104 to i64*
  %t106 = load atomic i64, i64* %t105 seq_cst, align 8
  %t107 = icmp eq i64 %t106, 1
  br i1 %t107, label %list_cow_done_147, label %list_cow_clone_148
list_cow_clone_148:
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
  br i1 %t121, label %list_cow_copy_149, label %list_cow_after_copy_150
list_cow_copy_149:
  %t122 = mul i64 %t112, %t95
  %t123 = bitcast i8* %t110 to i8*
  call i8* @memcpy(i8* %t119, i8* %t123, i64 %t122)
  br label %list_cow_after_copy_150
list_cow_after_copy_150:
  %t124 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t117, i32 0, i32 0
  store i8* %t120, i8** %t124
  %t125 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t117, i32 0, i32 1
  store i64 %t112, i64* %t125
  %t126 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t117, i32 0, i32 2
  store i64 %t114, i64* %t126
  call void @star_rc_release(i8* %t96)
  store i8* %t116, i8** %t62
  br label %list_cow_done_147
list_cow_done_147:
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
  br i1 %t139, label %list_push_grow_151, label %list_push_store_152
list_push_grow_151:
  %t140 = mul i64 %t136, 2
  %t141 = icmp sgt i64 %t140, 0
  %t142 = select i1 %t141, i64 %t140, i64 1
  %t143 = getelementptr i8, i8* null, i32 1
  %t144 = ptrtoint i8* %t143 to i64
  %t145 = mul i64 %t142, %t144
  %t146 = call i8* @malloc(i64 %t145)
  %t147 = bitcast i8* %t146 to i8*
  %t148 = icmp sgt i64 %t136, 0
  br i1 %t148, label %list_push_copy_153, label %list_push_after_copy_154
list_push_copy_153:
  %t149 = mul i64 %t138, %t144
  %t150 = bitcast i8* %t137 to i8*
  call i8* @memcpy(i8* %t146, i8* %t150, i64 %t149)
  call void @free(i8* %t150)
  br label %list_push_after_copy_154
list_push_after_copy_154:
  store i8* %t147, i8** %t129
  store i64 %t142, i64* %t133
  br label %list_push_store_152
list_push_store_152:
  %t151 = load i8*, i8** %t129
  %t152 = getelementptr inbounds i8, i8* %t151, i64 %t138
  store i8 %t135, i8* %t152
  %t153 = add i64 %t138, 1
  store i64 %t153, i64* %t131
  %t154 = load i32, i32* %t63
  %t155 = add i32 %t154, 1
  store i32 %t155, i32* %t63
  br label %while_cond_132
while_else_134:
  br label %while_end_135
while_end_135:
  %t156 = load i8*, i8** %t62
  %t157 = icmp eq i8* %t156, null
  br i1 %t157, label %list_read_null_155, label %list_read_real_156
list_read_null_155:
  br label %list_read_end_157
list_read_real_156:
  %t158 = bitcast i8* %t156 to { i8*, i64, i64 }*
  %t159 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t158, i32 0, i32 0
  %t160 = load i8*, i8** %t159
  %t161 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t158, i32 0, i32 1
  %t162 = load i64, i64* %t161
  br label %list_read_end_157
list_read_end_157:
  %t163 = phi i8* [ null, %list_read_null_155 ], [ %t160, %list_read_real_156 ]
  %t164 = phi i64 [ 0, %list_read_null_155 ], [ %t162, %list_read_real_156 ]
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
  br i1 %t9, label %if_then_158, label %if_else_159
if_then_158:
  %t10 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t10)
  %t11 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t11)
  ret i1 false
if_else_159:
  br label %if_end_160
if_end_160:
  %t12 = load i8*, i8** %t3
  %t13 = icmp eq i8* %t12, null
  br i1 %t13, label %file_null_handle_161, label %file_handle_ok_162
file_null_handle_161:
  %t14 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t14)
  call void @exit(i32 1)
  unreachable
file_handle_ok_162:
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
  br i1 %t28, label %file_null_handle_163, label %file_handle_ok_164
file_null_handle_163:
  %t29 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t29)
  call void @exit(i32 1)
  unreachable
file_handle_ok_164:
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
  br i1 %t5, label %file_exists_close_165, label %file_exists_end_166
file_exists_close_165:
  call i32 @fclose(i8* %t4)
  br label %file_exists_end_166
file_exists_end_166:
  %t6 = xor i1 true, %t5
  br i1 %t6, label %if_then_167, label %if_else_168
if_then_167:
  %t8 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t7, i32 0, i32 0
  store i32 0, i32* %t8
  %t9 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t10 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t7, i32 0, i32 1
  store i8* %t9, i8** %t10
  %t11 = load { i32, i8* }, { i32, i8* }* %t7
  %t12 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t12)
  ret { i32, i8* } %t11
if_else_168:
  br label %if_end_169
if_end_169:
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
  br i1 %t19, label %if_then_170, label %if_else_171
if_then_170:
  %t21 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t20, i32 0, i32 0
  store i32 0, i32* %t21
  %t22 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t23 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t20, i32 0, i32 1
  store i8* %t22, i8** %t23
  %t24 = load { i32, i8* }, { i32, i8* }* %t20
  %t25 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t25)
  ret { i32, i8* } %t24
if_else_171:
  br label %if_end_172
if_end_172:
  %t27 = load i8*, i8** %t13
  %t28 = icmp eq i8* %t27, null
  br i1 %t28, label %file_null_handle_173, label %file_handle_ok_174
file_null_handle_173:
  %t29 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.12, i64 0, i64 0
  call i32 @puts(i8* %t29)
  call void @exit(i32 1)
  unreachable
file_handle_ok_174:
  %t30 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t31
  br label %file_read_line_cond_175
file_read_line_cond_175:
  %t32 = load i64, i64* %t31
  %t33 = icmp ult i64 %t32, 1023
  br i1 %t33, label %file_read_line_body_176, label %file_read_line_end_178
file_read_line_body_176:
  %t34 = call i32 @fgetc(i8* %t27)
  %t35 = icmp eq i32 %t34, -1
  %t36 = icmp eq i32 %t34, 10
  %t37 = or i1 %t35, %t36
  br i1 %t37, label %file_read_line_end_178, label %file_read_line_store_177
file_read_line_store_177:
  %t38 = getelementptr inbounds i8, i8* %t30, i64 %t32
  %t39 = trunc i32 %t34 to i8
  store i8 %t39, i8* %t38
  %t40 = add i64 %t32, 1
  store i64 %t40, i64* %t31
  br label %file_read_line_cond_175
file_read_line_end_178:
  %t41 = load i64, i64* %t31
  %t42 = getelementptr inbounds i8, i8* %t30, i64 %t41
  store i8 0, i8* %t42
  store i8* %t30, i8** %t26
  %t43 = load i8*, i8** %t13
  %t44 = icmp eq i8* %t43, null
  br i1 %t44, label %file_null_handle_179, label %file_handle_ok_180
file_null_handle_179:
  %t45 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t45)
  call void @exit(i32 1)
  unreachable
file_handle_ok_180:
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
  br label %trim_start_cond_181
trim_start_cond_181:
  %t54 = load i64, i64* %t53
  %t55 = icmp slt i64 %t54, %t52
  br i1 %t55, label %trim_start_body_182, label %trim_start_done_184
trim_start_body_182:
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
  br i1 %t68, label %trim_start_incr_183, label %trim_start_done_184
trim_start_incr_183:
  %t69 = add i64 %t54, 1
  store i64 %t69, i64* %t53
  br label %trim_start_cond_181
trim_start_done_184:
  %t70 = load i64, i64* %t53
  store i64 %t52, i64* %t71
  br label %trim_end_cond_185
trim_end_cond_185:
  %t72 = load i64, i64* %t71
  %t73 = icmp sgt i64 %t72, %t70
  br i1 %t73, label %trim_end_body_186, label %trim_end_done_188
trim_end_body_186:
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
  br i1 %t87, label %trim_end_decr_187, label %trim_end_done_188
trim_end_decr_187:
  store i64 %t74, i64* %t71
  br label %trim_end_cond_185
trim_end_done_188:
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
  br i1 %t104, label %split_single_189, label %split_scan_init_190
split_single_189:
  %t105 = call i32 @strlen(i8* %t96)
  %t106 = sext i32 %t105 to i64
  %t107 = add i64 %t106, 1
  %t108 = call i8* @star_rc_alloc(i64 %t107, i8* null)
  call i8* @strcpy(i8* %t108, i8* %t96)
  %t109 = load i64, i64* %t102
  %t110 = load i64, i64* %t103
  %t111 = icmp sge i64 %t109, %t110
  br i1 %t111, label %dynstr_grow_192, label %dynstr_store_193
dynstr_grow_192:
  %t112 = mul i64 %t110, 2
  %t113 = icmp sgt i64 %t112, 0
  %t114 = select i1 %t113, i64 %t112, i64 4
  %t115 = mul i64 %t114, 8
  %t116 = call i8* @malloc(i64 %t115)
  %t117 = bitcast i8* %t116 to i8**
  %t118 = icmp sgt i64 %t110, 0
  br i1 %t118, label %dynstr_copy_194, label %dynstr_after_copy_195
dynstr_copy_194:
  %t119 = load i8**, i8*** %t101
  %t120 = mul i64 %t109, 8
  %t121 = bitcast i8** %t119 to i8*
  call i8* @memcpy(i8* %t116, i8* %t121, i64 %t120)
  call void @free(i8* %t121)
  br label %dynstr_after_copy_195
dynstr_after_copy_195:
  store i8** %t117, i8*** %t101
  store i64 %t114, i64* %t103
  br label %dynstr_store_193
dynstr_store_193:
  %t122 = load i8**, i8*** %t101
  %t123 = getelementptr inbounds i8*, i8** %t122, i64 %t109
  store i8* %t108, i8** %t123
  %t124 = add i64 %t109, 1
  store i64 %t124, i64* %t102
  br label %split_finish_191
split_scan_init_190:
  store i8* %t96, i8** %t125
  br label %split_scan_cond_196
split_scan_cond_196:
  %t126 = load i8*, i8** %t125
  %t127 = call i8* @strstr(i8* %t126, i8* %t98)
  %t128 = icmp eq i8* %t127, null
  br i1 %t128, label %split_tail_198, label %split_match_197
split_match_197:
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
  br i1 %t137, label %dynstr_grow_199, label %dynstr_store_200
dynstr_grow_199:
  %t138 = mul i64 %t136, 2
  %t139 = icmp sgt i64 %t138, 0
  %t140 = select i1 %t139, i64 %t138, i64 4
  %t141 = mul i64 %t140, 8
  %t142 = call i8* @malloc(i64 %t141)
  %t143 = bitcast i8* %t142 to i8**
  %t144 = icmp sgt i64 %t136, 0
  br i1 %t144, label %dynstr_copy_201, label %dynstr_after_copy_202
dynstr_copy_201:
  %t145 = load i8**, i8*** %t101
  %t146 = mul i64 %t135, 8
  %t147 = bitcast i8** %t145 to i8*
  call i8* @memcpy(i8* %t142, i8* %t147, i64 %t146)
  call void @free(i8* %t147)
  br label %dynstr_after_copy_202
dynstr_after_copy_202:
  store i8** %t143, i8*** %t101
  store i64 %t140, i64* %t103
  br label %dynstr_store_200
dynstr_store_200:
  %t148 = load i8**, i8*** %t101
  %t149 = getelementptr inbounds i8*, i8** %t148, i64 %t135
  store i8* %t133, i8** %t149
  %t150 = add i64 %t135, 1
  store i64 %t150, i64* %t102
  %t151 = getelementptr inbounds i8, i8* %t127, i64 %t100
  store i8* %t151, i8** %t125
  br label %split_scan_cond_196
split_tail_198:
  %t152 = load i8*, i8** %t125
  %t153 = call i32 @strlen(i8* %t152)
  %t154 = sext i32 %t153 to i64
  %t155 = add i64 %t154, 1
  %t156 = call i8* @star_rc_alloc(i64 %t155, i8* null)
  call i8* @strcpy(i8* %t156, i8* %t152)
  %t157 = load i64, i64* %t102
  %t158 = load i64, i64* %t103
  %t159 = icmp sge i64 %t157, %t158
  br i1 %t159, label %dynstr_grow_203, label %dynstr_store_204
dynstr_grow_203:
  %t160 = mul i64 %t158, 2
  %t161 = icmp sgt i64 %t160, 0
  %t162 = select i1 %t161, i64 %t160, i64 4
  %t163 = mul i64 %t162, 8
  %t164 = call i8* @malloc(i64 %t163)
  %t165 = bitcast i8* %t164 to i8**
  %t166 = icmp sgt i64 %t158, 0
  br i1 %t166, label %dynstr_copy_205, label %dynstr_after_copy_206
dynstr_copy_205:
  %t167 = load i8**, i8*** %t101
  %t168 = mul i64 %t157, 8
  %t169 = bitcast i8** %t167 to i8*
  call i8* @memcpy(i8* %t164, i8* %t169, i64 %t168)
  call void @free(i8* %t169)
  br label %dynstr_after_copy_206
dynstr_after_copy_206:
  store i8** %t165, i8*** %t101
  store i64 %t162, i64* %t103
  br label %dynstr_store_204
dynstr_store_204:
  %t170 = load i8**, i8*** %t101
  %t171 = getelementptr inbounds i8*, i8** %t170, i64 %t157
  store i8* %t156, i8** %t171
  %t172 = add i64 %t157, 1
  store i64 %t172, i64* %t102
  br label %split_finish_191
split_finish_191:
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
  br i1 %t195, label %list_read_null_210, label %list_read_real_211
list_read_null_210:
  br label %list_read_end_212
list_read_real_211:
  %t196 = bitcast i8* %t194 to { i8**, i64, i64 }*
  %t197 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t196, i32 0, i32 0
  %t198 = load i8**, i8*** %t197
  %t199 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t196, i32 0, i32 1
  %t200 = load i64, i64* %t199
  br label %list_read_end_212
list_read_end_212:
  %t201 = phi i8** [ null, %list_read_null_210 ], [ %t198, %list_read_real_211 ]
  %t202 = phi i64 [ 0, %list_read_null_210 ], [ %t200, %list_read_real_211 ]
  %t203 = trunc i64 %t202 to i32
  %t204 = icmp ne i32 %t203, 2
  br i1 %t204, label %if_then_213, label %if_else_214
if_then_213:
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
if_else_214:
  br label %if_end_215
if_end_215:
  %t214 = load i8*, i8** %t46
  %t215 = icmp eq i8* %t214, null
  br i1 %t215, label %list_read_null_216, label %list_read_real_217
list_read_null_216:
  br label %list_read_end_218
list_read_real_217:
  %t216 = bitcast i8* %t214 to { i8**, i64, i64 }*
  %t217 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t216, i32 0, i32 0
  %t218 = load i8**, i8*** %t217
  %t219 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t216, i32 0, i32 1
  %t220 = load i64, i64* %t219
  br label %list_read_end_218
list_read_end_218:
  %t221 = phi i8** [ null, %list_read_null_216 ], [ %t218, %list_read_real_217 ]
  %t222 = phi i64 [ 0, %list_read_null_216 ], [ %t220, %list_read_real_217 ]
  %t223 = sext i32 0 to i64
  %t224 = icmp ult i64 %t223, %t222
  br i1 %t224, label %list_idx_ok_219, label %list_idx_oob_220
list_idx_ok_219:
  %t225 = getelementptr inbounds i8*, i8** %t221, i64 %t223
  %t226 = load i8*, i8** %t225
  %t227 = load i8*, i8** %t225
  call void @star_rc_retain(i8* %t227)
  br label %list_idx_end_221
list_idx_oob_220:
  %t228 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t228
  br label %list_idx_end_221
list_idx_end_221:
  %t229 = phi i8* [ %t226, %list_idx_ok_219 ], [ %t228, %list_idx_oob_220 ]
  %t230 = call i32 @atoi(i8* %t229)
  call void @star_rc_release(i8* %t229)
  store i32 %t230, i32* %t213
  %t232 = load i8*, i8** %t46
  %t233 = icmp eq i8* %t232, null
  br i1 %t233, label %list_read_null_222, label %list_read_real_223
list_read_null_222:
  br label %list_read_end_224
list_read_real_223:
  %t234 = bitcast i8* %t232 to { i8**, i64, i64 }*
  %t235 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t234, i32 0, i32 0
  %t236 = load i8**, i8*** %t235
  %t237 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t234, i32 0, i32 1
  %t238 = load i64, i64* %t237
  br label %list_read_end_224
list_read_end_224:
  %t239 = phi i8** [ null, %list_read_null_222 ], [ %t236, %list_read_real_223 ]
  %t240 = phi i64 [ 0, %list_read_null_222 ], [ %t238, %list_read_real_223 ]
  %t241 = sext i32 1 to i64
  %t242 = icmp ult i64 %t241, %t240
  br i1 %t242, label %list_idx_ok_225, label %list_idx_oob_226
list_idx_ok_225:
  %t243 = getelementptr inbounds i8*, i8** %t239, i64 %t241
  %t244 = load i8*, i8** %t243
  %t245 = load i8*, i8** %t243
  call void @star_rc_retain(i8* %t245)
  br label %list_idx_end_227
list_idx_oob_226:
  %t246 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t246
  br label %list_idx_end_227
list_idx_end_227:
  %t247 = phi i8* [ %t244, %list_idx_ok_225 ], [ %t246, %list_idx_oob_226 ]
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
  br label %while_cond_228
while_cond_228:
  %t5 = load i32, i32* %t4
  %t6 = icmp slt i32 %t5, 32
  br i1 %t6, label %logic_rhs_232, label %logic_short_233
logic_rhs_232:
  %t7 = load i32, i32* %t3
  %t8 = icmp slt i32 %t7, 6
  br label %logic_end_234
logic_short_233:
  br label %logic_end_234
logic_end_234:
  %t9 = phi i1 [ %t8, %logic_rhs_232 ], [ false, %logic_short_233 ]
  br i1 %t9, label %while_body_229, label %while_else_230
while_body_229:
  %t10 = load %ParticlePool*, %ParticlePool** %t0
  %t11 = getelementptr inbounds %ParticlePool, %ParticlePool* %t10, i32 0, i32 0
  %t12 = load i32, i32* %t4
  %t13 = sext i32 %t12 to i64
  %t14 = icmp ult i64 %t13, 32
  br i1 %t14, label %arr_rplace_ok_235, label %arr_rplace_oob_236
arr_rplace_ok_235:
  %t15 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t11, i32 0, i64 %t13
  br label %arr_rplace_end_237
arr_rplace_oob_236:
  store %Particle zeroinitializer, %Particle* %t16
  br label %arr_rplace_end_237
arr_rplace_end_237:
  %t17 = phi %Particle* [ %t15, %arr_rplace_ok_235 ], [ %t16, %arr_rplace_oob_236 ]
  %t18 = getelementptr inbounds %Particle, %Particle* %t17, i32 0, i32 4
  %t19 = load float, float* %t18
  %t20 = fcmp ole float %t19, 0x0000000000000000
  br i1 %t20, label %if_then_238, label %if_else_239
if_then_238:
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
  br i1 %t69, label %arr_set_do_241, label %arr_set_oob_242
arr_set_do_241:
  %t70 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t66, i32 0, i64 %t68
  store %Particle %t64, %Particle* %t70
  br label %arr_set_end_243
arr_set_oob_242:
  br label %arr_set_end_243
arr_set_end_243:
  %t71 = load i32, i32* %t3
  %t72 = add i32 %t71, 1
  store i32 %t72, i32* %t3
  br label %if_end_240
if_else_239:
  br label %if_end_240
if_end_240:
  %t73 = load i32, i32* %t4
  %t74 = add i32 %t73, 1
  store i32 %t74, i32* %t4
  br label %while_cond_228
while_else_230:
  br label %while_end_231
while_end_231:
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
  br label %while_cond_244
while_cond_244:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 32
  br i1 %t4, label %while_body_245, label %while_else_246
while_body_245:
  %t5 = load %ParticlePool*, %ParticlePool** %t0
  %t6 = getelementptr inbounds %ParticlePool, %ParticlePool* %t5, i32 0, i32 0
  %t7 = load i32, i32* %t2
  %t8 = sext i32 %t7 to i64
  %t9 = icmp ult i64 %t8, 32
  br i1 %t9, label %arr_rplace_ok_248, label %arr_rplace_oob_249
arr_rplace_ok_248:
  %t10 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t6, i32 0, i64 %t8
  br label %arr_rplace_end_250
arr_rplace_oob_249:
  store %Particle zeroinitializer, %Particle* %t11
  br label %arr_rplace_end_250
arr_rplace_end_250:
  %t12 = phi %Particle* [ %t10, %arr_rplace_ok_248 ], [ %t11, %arr_rplace_oob_249 ]
  %t13 = getelementptr inbounds %Particle, %Particle* %t12, i32 0, i32 4
  %t14 = load float, float* %t13
  %t15 = fcmp ogt float %t14, 0x0000000000000000
  br i1 %t15, label %if_then_251, label %if_else_252
if_then_251:
  %t16 = load float, float* %t1
  %t17 = load %ParticlePool*, %ParticlePool** %t0
  %t18 = getelementptr inbounds %ParticlePool, %ParticlePool* %t17, i32 0, i32 0
  %t19 = load i32, i32* %t2
  %t20 = sext i32 %t19 to i64
  %t21 = icmp ult i64 %t20, 32
  br i1 %t21, label %arr_place_ok_254, label %arr_place_oob_255
arr_place_ok_254:
  %t22 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t18, i32 0, i64 %t20
  br label %arr_place_end_256
arr_place_oob_255:
  store %Particle zeroinitializer, %Particle* %t23
  br label %arr_place_end_256
arr_place_end_256:
  %t24 = phi %Particle* [ %t22, %arr_place_ok_254 ], [ %t23, %arr_place_oob_255 ]
  %t25 = getelementptr inbounds %Particle, %Particle* %t24, i32 0, i32 4
  %t26 = load float, float* %t25
  %t27 = fsub float %t26, %t16
  %t28 = load %ParticlePool*, %ParticlePool** %t0
  %t29 = getelementptr inbounds %ParticlePool, %ParticlePool* %t28, i32 0, i32 0
  %t30 = load i32, i32* %t2
  %t31 = sext i32 %t30 to i64
  %t32 = icmp ult i64 %t31, 32
  br i1 %t32, label %arr_place_ok_257, label %arr_place_oob_258
arr_place_ok_257:
  %t33 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t29, i32 0, i64 %t31
  br label %arr_place_end_259
arr_place_oob_258:
  store %Particle zeroinitializer, %Particle* %t34
  br label %arr_place_end_259
arr_place_end_259:
  %t35 = phi %Particle* [ %t33, %arr_place_ok_257 ], [ %t34, %arr_place_oob_258 ]
  %t36 = getelementptr inbounds %Particle, %Particle* %t35, i32 0, i32 4
  store float %t27, float* %t36
  %t37 = load %ParticlePool*, %ParticlePool** %t0
  %t38 = getelementptr inbounds %ParticlePool, %ParticlePool* %t37, i32 0, i32 0
  %t39 = load i32, i32* %t2
  %t40 = sext i32 %t39 to i64
  %t41 = icmp ult i64 %t40, 32
  br i1 %t41, label %arr_rplace_ok_260, label %arr_rplace_oob_261
arr_rplace_ok_260:
  %t42 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t38, i32 0, i64 %t40
  br label %arr_rplace_end_262
arr_rplace_oob_261:
  store %Particle zeroinitializer, %Particle* %t43
  br label %arr_rplace_end_262
arr_rplace_end_262:
  %t44 = phi %Particle* [ %t42, %arr_rplace_ok_260 ], [ %t43, %arr_rplace_oob_261 ]
  %t45 = getelementptr inbounds %Particle, %Particle* %t44, i32 0, i32 2
  %t46 = load float, float* %t45
  %t47 = load %ParticlePool*, %ParticlePool** %t0
  %t48 = getelementptr inbounds %ParticlePool, %ParticlePool* %t47, i32 0, i32 0
  %t49 = load i32, i32* %t2
  %t50 = sext i32 %t49 to i64
  %t51 = icmp ult i64 %t50, 32
  br i1 %t51, label %arr_place_ok_263, label %arr_place_oob_264
arr_place_ok_263:
  %t52 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t48, i32 0, i64 %t50
  br label %arr_place_end_265
arr_place_oob_264:
  store %Particle zeroinitializer, %Particle* %t53
  br label %arr_place_end_265
arr_place_end_265:
  %t54 = phi %Particle* [ %t52, %arr_place_ok_263 ], [ %t53, %arr_place_oob_264 ]
  %t55 = getelementptr inbounds %Particle, %Particle* %t54, i32 0, i32 0
  %t56 = load float, float* %t55
  %t57 = fadd float %t56, %t46
  %t58 = load %ParticlePool*, %ParticlePool** %t0
  %t59 = getelementptr inbounds %ParticlePool, %ParticlePool* %t58, i32 0, i32 0
  %t60 = load i32, i32* %t2
  %t61 = sext i32 %t60 to i64
  %t62 = icmp ult i64 %t61, 32
  br i1 %t62, label %arr_place_ok_266, label %arr_place_oob_267
arr_place_ok_266:
  %t63 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t59, i32 0, i64 %t61
  br label %arr_place_end_268
arr_place_oob_267:
  store %Particle zeroinitializer, %Particle* %t64
  br label %arr_place_end_268
arr_place_end_268:
  %t65 = phi %Particle* [ %t63, %arr_place_ok_266 ], [ %t64, %arr_place_oob_267 ]
  %t66 = getelementptr inbounds %Particle, %Particle* %t65, i32 0, i32 0
  store float %t57, float* %t66
  %t67 = load %ParticlePool*, %ParticlePool** %t0
  %t68 = getelementptr inbounds %ParticlePool, %ParticlePool* %t67, i32 0, i32 0
  %t69 = load i32, i32* %t2
  %t70 = sext i32 %t69 to i64
  %t71 = icmp ult i64 %t70, 32
  br i1 %t71, label %arr_rplace_ok_269, label %arr_rplace_oob_270
arr_rplace_ok_269:
  %t72 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t68, i32 0, i64 %t70
  br label %arr_rplace_end_271
arr_rplace_oob_270:
  store %Particle zeroinitializer, %Particle* %t73
  br label %arr_rplace_end_271
arr_rplace_end_271:
  %t74 = phi %Particle* [ %t72, %arr_rplace_ok_269 ], [ %t73, %arr_rplace_oob_270 ]
  %t75 = getelementptr inbounds %Particle, %Particle* %t74, i32 0, i32 3
  %t76 = load float, float* %t75
  %t77 = load %ParticlePool*, %ParticlePool** %t0
  %t78 = getelementptr inbounds %ParticlePool, %ParticlePool* %t77, i32 0, i32 0
  %t79 = load i32, i32* %t2
  %t80 = sext i32 %t79 to i64
  %t81 = icmp ult i64 %t80, 32
  br i1 %t81, label %arr_place_ok_272, label %arr_place_oob_273
arr_place_ok_272:
  %t82 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t78, i32 0, i64 %t80
  br label %arr_place_end_274
arr_place_oob_273:
  store %Particle zeroinitializer, %Particle* %t83
  br label %arr_place_end_274
arr_place_end_274:
  %t84 = phi %Particle* [ %t82, %arr_place_ok_272 ], [ %t83, %arr_place_oob_273 ]
  %t85 = getelementptr inbounds %Particle, %Particle* %t84, i32 0, i32 1
  %t86 = load float, float* %t85
  %t87 = fadd float %t86, %t76
  %t88 = load %ParticlePool*, %ParticlePool** %t0
  %t89 = getelementptr inbounds %ParticlePool, %ParticlePool* %t88, i32 0, i32 0
  %t90 = load i32, i32* %t2
  %t91 = sext i32 %t90 to i64
  %t92 = icmp ult i64 %t91, 32
  br i1 %t92, label %arr_place_ok_275, label %arr_place_oob_276
arr_place_ok_275:
  %t93 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t89, i32 0, i64 %t91
  br label %arr_place_end_277
arr_place_oob_276:
  store %Particle zeroinitializer, %Particle* %t94
  br label %arr_place_end_277
arr_place_end_277:
  %t95 = phi %Particle* [ %t93, %arr_place_ok_275 ], [ %t94, %arr_place_oob_276 ]
  %t96 = getelementptr inbounds %Particle, %Particle* %t95, i32 0, i32 1
  store float %t87, float* %t96
  %t97 = load %ParticlePool*, %ParticlePool** %t0
  %t98 = getelementptr inbounds %ParticlePool, %ParticlePool* %t97, i32 0, i32 0
  %t99 = load i32, i32* %t2
  %t100 = sext i32 %t99 to i64
  %t101 = icmp ult i64 %t100, 32
  br i1 %t101, label %arr_place_ok_278, label %arr_place_oob_279
arr_place_ok_278:
  %t102 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t98, i32 0, i64 %t100
  br label %arr_place_end_280
arr_place_oob_279:
  store %Particle zeroinitializer, %Particle* %t103
  br label %arr_place_end_280
arr_place_end_280:
  %t104 = phi %Particle* [ %t102, %arr_place_ok_278 ], [ %t103, %arr_place_oob_279 ]
  %t105 = getelementptr inbounds %Particle, %Particle* %t104, i32 0, i32 3
  %t106 = load float, float* %t105
  %t107 = fadd float %t106, 0x3FBEB851E0000000
  %t108 = load %ParticlePool*, %ParticlePool** %t0
  %t109 = getelementptr inbounds %ParticlePool, %ParticlePool* %t108, i32 0, i32 0
  %t110 = load i32, i32* %t2
  %t111 = sext i32 %t110 to i64
  %t112 = icmp ult i64 %t111, 32
  br i1 %t112, label %arr_place_ok_281, label %arr_place_oob_282
arr_place_ok_281:
  %t113 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t109, i32 0, i64 %t111
  br label %arr_place_end_283
arr_place_oob_282:
  store %Particle zeroinitializer, %Particle* %t114
  br label %arr_place_end_283
arr_place_end_283:
  %t115 = phi %Particle* [ %t113, %arr_place_ok_281 ], [ %t114, %arr_place_oob_282 ]
  %t116 = getelementptr inbounds %Particle, %Particle* %t115, i32 0, i32 3
  store float %t107, float* %t116
  br label %if_end_253
if_else_252:
  br label %if_end_253
if_end_253:
  %t117 = load i32, i32* %t2
  %t118 = add i32 %t117, 1
  store i32 %t118, i32* %t2
  br label %while_cond_244
while_else_246:
  br label %while_end_247
while_end_247:
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
  br label %while_cond_284
while_cond_284:
  %t3 = load i32, i32* %t2
  %t4 = icmp slt i32 %t3, 32
  br i1 %t4, label %while_body_285, label %while_else_286
while_body_285:
  %t5 = load %ParticlePool*, %ParticlePool** %t0
  %t6 = getelementptr inbounds %ParticlePool, %ParticlePool* %t5, i32 0, i32 0
  %t7 = load i32, i32* %t2
  %t8 = sext i32 %t7 to i64
  %t9 = icmp ult i64 %t8, 32
  br i1 %t9, label %arr_rplace_ok_288, label %arr_rplace_oob_289
arr_rplace_ok_288:
  %t10 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t6, i32 0, i64 %t8
  br label %arr_rplace_end_290
arr_rplace_oob_289:
  store %Particle zeroinitializer, %Particle* %t11
  br label %arr_rplace_end_290
arr_rplace_end_290:
  %t12 = phi %Particle* [ %t10, %arr_rplace_ok_288 ], [ %t11, %arr_rplace_oob_289 ]
  %t13 = getelementptr inbounds %Particle, %Particle* %t12, i32 0, i32 4
  %t14 = load float, float* %t13
  %t15 = fcmp ogt float %t14, 0x0000000000000000
  br i1 %t15, label %if_then_291, label %if_else_292
if_then_291:
  %t17 = load %ParticlePool*, %ParticlePool** %t0
  %t18 = getelementptr inbounds %ParticlePool, %ParticlePool* %t17, i32 0, i32 0
  %t19 = load i32, i32* %t2
  %t20 = sext i32 %t19 to i64
  %t21 = icmp ult i64 %t20, 32
  br i1 %t21, label %arr_rplace_ok_294, label %arr_rplace_oob_295
arr_rplace_ok_294:
  %t22 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t18, i32 0, i64 %t20
  br label %arr_rplace_end_296
arr_rplace_oob_295:
  store %Particle zeroinitializer, %Particle* %t23
  br label %arr_rplace_end_296
arr_rplace_end_296:
  %t24 = phi %Particle* [ %t22, %arr_rplace_ok_294 ], [ %t23, %arr_rplace_oob_295 ]
  %t25 = getelementptr inbounds %Particle, %Particle* %t24, i32 0, i32 4
  %t26 = load float, float* %t25
  %t27 = fmul float %t26, 0x406FE00000000000
  %t28 = fdiv float %t27, 0x3FDCCCCCC0000000
  %t29 = call float @llvm.maxnum.f32(float %t28, float 0x0000000000000000)
  %t30 = call float @llvm.minnum.f32(float %t29, float 0x406FE00000000000)
  store float %t30, float* %t16
  %t31 = load i8*, i8** %t1
  %t32 = icmp eq i8* %t31, null
  br i1 %t32, label %sdl_null_window_297, label %sdl_window_handle_ok_298
sdl_null_window_297:
  %t33 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.16, i64 0, i64 0
  call i32 @puts(i8* %t33)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_298:
  %t34 = call i8* @SDL_GetRenderer(i8* %t31)
  %t35 = load %ParticlePool*, %ParticlePool** %t0
  %t36 = getelementptr inbounds %ParticlePool, %ParticlePool* %t35, i32 0, i32 0
  %t37 = load i32, i32* %t2
  %t38 = sext i32 %t37 to i64
  %t39 = icmp ult i64 %t38, 32
  br i1 %t39, label %arr_rplace_ok_299, label %arr_rplace_oob_300
arr_rplace_ok_299:
  %t40 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t36, i32 0, i64 %t38
  br label %arr_rplace_end_301
arr_rplace_oob_300:
  store %Particle zeroinitializer, %Particle* %t41
  br label %arr_rplace_end_301
arr_rplace_end_301:
  %t42 = phi %Particle* [ %t40, %arr_rplace_ok_299 ], [ %t41, %arr_rplace_oob_300 ]
  %t43 = getelementptr inbounds %Particle, %Particle* %t42, i32 0, i32 0
  %t44 = load float, float* %t43
  %t45 = call i32 @llvm.fptosi.sat.i32.f32(float %t44)
  %t46 = load %ParticlePool*, %ParticlePool** %t0
  %t47 = getelementptr inbounds %ParticlePool, %ParticlePool* %t46, i32 0, i32 0
  %t48 = load i32, i32* %t2
  %t49 = sext i32 %t48 to i64
  %t50 = icmp ult i64 %t49, 32
  br i1 %t50, label %arr_rplace_ok_302, label %arr_rplace_oob_303
arr_rplace_ok_302:
  %t51 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t47, i32 0, i64 %t49
  br label %arr_rplace_end_304
arr_rplace_oob_303:
  store %Particle zeroinitializer, %Particle* %t52
  br label %arr_rplace_end_304
arr_rplace_end_304:
  %t53 = phi %Particle* [ %t51, %arr_rplace_ok_302 ], [ %t52, %arr_rplace_oob_303 ]
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
  br label %if_end_293
if_else_292:
  br label %if_end_293
if_end_293:
  %t80 = load i32, i32* %t2
  %t81 = add i32 %t80, 1
  store i32 %t81, i32* %t2
  br label %while_cond_284
while_else_286:
  br label %while_end_287
while_end_287:
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
  br i1 %t77, label %par_serial_312, label %par_pooled_311
par_pooled_311:
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
  store i32 (i8*)* @par_worker_305, i32 (i8*)** %t89
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
  store i32 (i8*)* @par_worker_305, i32 (i8*)** %t103
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
  store i32 (i8*)* @par_worker_305, i32 (i8*)** %t117
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
  store i32 (i8*)* @par_worker_305, i32 (i8*)** %t131
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
  br label %par_join_316
par_serial_312:
  %t147 = load i32, i32* @par.pool.serial_owner
  %t148 = icmp eq i32 %t147, %t76
  br i1 %t148, label %par_run_314, label %par_acquire_313
par_acquire_313:
  %t149 = load i8*, i8** @par.pool.serial_lock
  %t150 = call i32 @WaitForSingleObject(i8* %t149, i32 -1)
  store i32 %t76, i32* @par.pool.serial_owner
  br label %par_run_314
par_run_314:
  %t151 = load i64, i64* @arena.Particles.count
  %t153 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t152, i32 0, i32 0
  store i64 0, i64* %t153
  %t154 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t152, i32 0, i32 1
  store i64 %t151, i64* %t154
  %t155 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t152, i32 0, i32 2
  store float* %t0, float** %t155
  %t156 = bitcast { i64, i64, float* }* %t152 to i8*
  %t157 = call i32 @par_worker_305(i8* %t156)
  br i1 %t148, label %par_join_316, label %par_release_315
par_release_315:
  store i32 -1, i32* @par.pool.serial_owner
  %t158 = load i8*, i8** @par.pool.serial_lock
  %t159 = call i32 @ReleaseSemaphore(i8* %t158, i32 1, i32* null)
  br label %par_join_316
par_join_316:
  ret void
}

define void @reclaim_dead_particles() {
entry:
  %t2 = alloca i64
  %t11 = alloca i32
  %t0 = load %Particle*, %Particle** @arena.Particles.data
  %t1 = load i64, i64* @arena.Particles.count
  store i64 0, i64* %t2
  br label %each_cond_317
each_cond_317:
  %t3 = load i64, i64* %t2
  %t4 = icmp slt i64 %t3, %t1
  br i1 %t4, label %each_body_318, label %each_end_321
each_body_318:
  %t5 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t3
  %t6 = load i64, i64* %t5
  %t7 = and i64 %t6, 1
  %t8 = icmp eq i64 %t7, 1
  br i1 %t8, label %each_live_319, label %each_step_320
each_live_319:
  %t9 = getelementptr inbounds %Particle, %Particle* %t0, i64 %t3
  %t10 = trunc i64 %t3 to i32
  store i32 %t10, i32* %t11
  %t12 = getelementptr inbounds %Particle, %Particle* %t9, i32 0, i32 4
  %t13 = load float, float* %t12
  %t14 = fcmp ole float %t13, 0x0000000000000000
  br i1 %t14, label %if_then_322, label %if_else_323
if_then_322:
  %t15 = load i32, i32* %t11
  %t16 = sext i32 %t15 to i64
  %t17 = icmp ult i64 %t16, 256
  br i1 %t17, label %despawn_do_325, label %despawn_end_326
despawn_do_325:
  %t18 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t16
  %t19 = load i64, i64* %t18
  %t20 = and i64 %t19, 1
  %t21 = icmp eq i64 %t20, 1
  br i1 %t21, label %despawn_live_327, label %despawn_end_326
despawn_live_327:
  %t22 = add i64 %t19, 1
  store i64 %t22, i64* %t18
  %t23 = load i64, i64* @arena.Particles.free_top
  %t24 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.free, i64 0, i64 %t23
  store i64 %t16, i64* %t24
  %t25 = add i64 %t23, 1
  store i64 %t25, i64* @arena.Particles.free_top
  br label %despawn_end_326
despawn_end_326:
  br label %if_end_324
if_else_323:
  br label %if_end_324
if_end_324:
  br label %each_step_320
each_step_320:
  %t26 = add i64 %t3, 1
  store i64 %t26, i64* %t2
  br label %each_cond_317
each_end_321:
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
  br i1 %t47, label %par_serial_338, label %par_pooled_337
par_pooled_337:
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
  store i32 (i8*)* @par_worker_328, i32 (i8*)** %t58
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
  store i32 (i8*)* @par_worker_328, i32 (i8*)** %t71
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
  store i32 (i8*)* @par_worker_328, i32 (i8*)** %t84
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
  store i32 (i8*)* @par_worker_328, i32 (i8*)** %t97
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
  br label %par_join_342
par_serial_338:
  %t113 = load i32, i32* @par.pool.serial_owner
  %t114 = icmp eq i32 %t113, %t46
  br i1 %t114, label %par_run_340, label %par_acquire_339
par_acquire_339:
  %t115 = load i8*, i8** @par.pool.serial_lock
  %t116 = call i32 @WaitForSingleObject(i8* %t115, i32 -1)
  store i32 %t46, i32* @par.pool.serial_owner
  br label %par_run_340
par_run_340:
  %t117 = load i64, i64* @arena.Particles.count
  %t119 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 0
  store i64 0, i64* %t119
  %t120 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 1
  store i64 %t117, i64* %t120
  %t121 = bitcast { i64, i64 }* %t118 to i8*
  %t122 = call i32 @par_worker_328(i8* %t121)
  br i1 %t114, label %par_join_342, label %par_release_341
par_release_341:
  store i32 -1, i32* @par.pool.serial_owner
  %t123 = load i8*, i8** @par.pool.serial_lock
  %t124 = call i32 @ReleaseSemaphore(i8* %t123, i32 1, i32* null)
  br label %par_join_342
par_join_342:
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
  br i1 %t4, label %if_then_343, label %if_else_344
if_then_343:
  %t5 = load %FlashOnEat*, %FlashOnEat** %t0
  %t6 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %sdl_null_window_346, label %sdl_window_handle_ok_347
sdl_null_window_346:
  %t9 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.20, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_347:
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
  br i1 %t35, label %sdl_null_window_348, label %sdl_window_handle_ok_349
sdl_null_window_348:
  %t36 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.21, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_349:
  %t37 = call i8* @SDL_GetRenderer(i8* %t34)
  call void @SDL_RenderPresent(i8* %t37)
  %t38 = icmp slt i32 35, 0
  %t39 = select i1 %t38, i32 0, i32 35
  call void @SDL_Delay(i32 %t39)
  %t40 = load %FlashOnEat*, %FlashOnEat** %t0
  %t41 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t40, i32 0, i32 1
  store i32 1, i32* %t41
  ret i1 true
if_else_344:
  %t42 = load %FlashOnEat*, %FlashOnEat** %t0
  %t43 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t44, 1
  br i1 %t45, label %if_then_350, label %if_else_351
if_then_350:
  %t46 = load %FlashOnEat*, %FlashOnEat** %t0
  %t47 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t46, i32 0, i32 1
  store i32 2, i32* %t47
  ret i1 false
if_else_351:
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
  br i1 %t4, label %if_then_353, label %if_else_354
if_then_353:
  %t5 = load %GameOverFlash*, %GameOverFlash** %t0
  %t6 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %sdl_null_window_356, label %sdl_window_handle_ok_357
sdl_null_window_356:
  %t9 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.22, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_357:
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
  br i1 %t35, label %sdl_null_window_358, label %sdl_window_handle_ok_359
sdl_null_window_358:
  %t36 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.23, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_359:
  %t37 = call i8* @SDL_GetRenderer(i8* %t34)
  call void @SDL_RenderPresent(i8* %t37)
  %t38 = icmp slt i32 110, 0
  %t39 = select i1 %t38, i32 0, i32 110
  call void @SDL_Delay(i32 %t39)
  %t40 = load %GameOverFlash*, %GameOverFlash** %t0
  %t41 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t40, i32 0, i32 1
  store i32 1, i32* %t41
  ret i1 true
if_else_354:
  %t42 = load %GameOverFlash*, %GameOverFlash** %t0
  %t43 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t44, 1
  br i1 %t45, label %if_then_360, label %if_else_361
if_then_360:
  %t46 = load %GameOverFlash*, %GameOverFlash** %t0
  %t47 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t46, i32 0, i32 0
  %t48 = load i8*, i8** %t47
  %t49 = icmp eq i8* %t48, null
  br i1 %t49, label %sdl_null_window_363, label %sdl_window_handle_ok_364
sdl_null_window_363:
  %t50 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.24, i64 0, i64 0
  call i32 @puts(i8* %t50)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_364:
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
  br i1 %t76, label %sdl_null_window_365, label %sdl_window_handle_ok_366
sdl_null_window_365:
  %t77 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.25, i64 0, i64 0
  call i32 @puts(i8* %t77)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_366:
  %t78 = call i8* @SDL_GetRenderer(i8* %t75)
  call void @SDL_RenderPresent(i8* %t78)
  %t79 = icmp slt i32 110, 0
  %t80 = select i1 %t79, i32 0, i32 110
  call void @SDL_Delay(i32 %t80)
  %t81 = load %GameOverFlash*, %GameOverFlash** %t0
  %t82 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t81, i32 0, i32 1
  store i32 2, i32* %t82
  ret i1 true
if_else_361:
  %t83 = load %GameOverFlash*, %GameOverFlash** %t0
  %t84 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t83, i32 0, i32 1
  %t85 = load i32, i32* %t84
  %t86 = icmp eq i32 %t85, 2
  br i1 %t86, label %if_then_367, label %if_else_368
if_then_367:
  %t87 = load %GameOverFlash*, %GameOverFlash** %t0
  %t88 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t87, i32 0, i32 1
  store i32 3, i32* %t88
  ret i1 false
if_else_368:
  ret i1 false
}

define void @demo_genref_staleness() {
entry:
  %t19 = alloca %ScratchSlot
  %t26 = alloca %GenRef
  %t32 = alloca %GenRef
  %t65 = alloca %ScratchSlot
  %t72 = alloca %GenRef
  %t78 = alloca %GenRef
  %t96 = alloca %ScratchSlot
  %t115 = alloca %ScratchSlot
  %t0 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t1 = icmp eq %ScratchSlot* %t0, null
  br i1 %t1, label %spawn_init_370, label %spawn_ready_371
spawn_init_370:
  %t2 = getelementptr %ScratchSlot, %ScratchSlot* null, i32 1
  %t3 = ptrtoint %ScratchSlot* %t2 to i64
  %t4 = mul i64 %t3, 1024
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to %ScratchSlot*
  store %ScratchSlot* %t6, %ScratchSlot** @arena.Scratch.data
  br label %spawn_ready_371
spawn_ready_371:
  %t7 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t8 = load i64, i64* @arena.Scratch.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_372, label %spawn_grow_373
spawn_reuse_372:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Scratch.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_374
spawn_grow_373:
  %t13 = load i64, i64* @arena.Scratch.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_376, label %spawn_capacity_warn_377
spawn_capacity_warn_377:
  %t15 = load i1, i1* @arena.Scratch.warned
  br i1 %t15, label %spawn_end_375, label %spawn_warn_print_378
spawn_warn_print_378:
  store i1 1, i1* @arena.Scratch.warned
  %t16 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.26, i64 0, i64 0
  call i32 @puts(i8* %t16)
  br label %spawn_end_375
spawn_grow_ok_376:
  %t17 = add i64 %t13, 1
  store i64 %t17, i64* @arena.Scratch.count
  br label %spawn_store_374
spawn_store_374:
  %t18 = phi i64 [ %t12, %spawn_reuse_372 ], [ %t13, %spawn_grow_ok_376 ]
  %t20 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t19, i32 0, i32 0
  store i32 111, i32* %t20
  %t21 = load %ScratchSlot, %ScratchSlot* %t19
  %t22 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t7, i64 %t18
  store %ScratchSlot %t21, %ScratchSlot* %t22
  %t23 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t18
  %t24 = load i64, i64* %t23
  %t25 = add i64 %t24, 1
  store i64 %t25, i64* %t23
  br label %spawn_end_375
spawn_end_375:
  %t27 = sext i32 0 to i64
  %t28 = icmp ult i64 %t27, 1024
  br i1 %t28, label %genref_create_ok_379, label %genref_create_oob_380
genref_create_ok_379:
  %t29 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t27
  %t30 = load i64, i64* %t29
  br label %genref_create_end_381
genref_create_oob_380:
  br label %genref_create_end_381
genref_create_end_381:
  %t31 = phi i64 [ %t30, %genref_create_ok_379 ], [ 0, %genref_create_oob_380 ]
  %t33 = getelementptr inbounds %GenRef, %GenRef* %t32, i32 0, i32 0
  store i32 0, i32* %t33
  %t34 = getelementptr inbounds %GenRef, %GenRef* %t32, i32 0, i32 1
  store i64 %t31, i64* %t34
  %t35 = load %GenRef, %GenRef* %t32
  store %GenRef %t35, %GenRef* %t26
  %t36 = sext i32 0 to i64
  %t37 = icmp ult i64 %t36, 1024
  br i1 %t37, label %despawn_do_382, label %despawn_end_383
despawn_do_382:
  %t38 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t36
  %t39 = load i64, i64* %t38
  %t40 = and i64 %t39, 1
  %t41 = icmp eq i64 %t40, 1
  br i1 %t41, label %despawn_live_384, label %despawn_end_383
despawn_live_384:
  %t42 = add i64 %t39, 1
  store i64 %t42, i64* %t38
  %t43 = load i64, i64* @arena.Scratch.free_top
  %t44 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t43
  store i64 %t36, i64* %t44
  %t45 = add i64 %t43, 1
  store i64 %t45, i64* @arena.Scratch.free_top
  br label %despawn_end_383
despawn_end_383:
  %t46 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t47 = icmp eq %ScratchSlot* %t46, null
  br i1 %t47, label %spawn_init_385, label %spawn_ready_386
spawn_init_385:
  %t48 = getelementptr %ScratchSlot, %ScratchSlot* null, i32 1
  %t49 = ptrtoint %ScratchSlot* %t48 to i64
  %t50 = mul i64 %t49, 1024
  %t51 = call i8* @malloc(i64 %t50)
  %t52 = bitcast i8* %t51 to %ScratchSlot*
  store %ScratchSlot* %t52, %ScratchSlot** @arena.Scratch.data
  br label %spawn_ready_386
spawn_ready_386:
  %t53 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t54 = load i64, i64* @arena.Scratch.free_top
  %t55 = icmp sgt i64 %t54, 0
  br i1 %t55, label %spawn_reuse_387, label %spawn_grow_388
spawn_reuse_387:
  %t56 = sub i64 %t54, 1
  store i64 %t56, i64* @arena.Scratch.free_top
  %t57 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t56
  %t58 = load i64, i64* %t57
  br label %spawn_store_389
spawn_grow_388:
  %t59 = load i64, i64* @arena.Scratch.count
  %t60 = icmp slt i64 %t59, 1024
  br i1 %t60, label %spawn_grow_ok_391, label %spawn_capacity_warn_392
spawn_capacity_warn_392:
  %t61 = load i1, i1* @arena.Scratch.warned
  br i1 %t61, label %spawn_end_390, label %spawn_warn_print_393
spawn_warn_print_393:
  store i1 1, i1* @arena.Scratch.warned
  %t62 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.27, i64 0, i64 0
  call i32 @puts(i8* %t62)
  br label %spawn_end_390
spawn_grow_ok_391:
  %t63 = add i64 %t59, 1
  store i64 %t63, i64* @arena.Scratch.count
  br label %spawn_store_389
spawn_store_389:
  %t64 = phi i64 [ %t58, %spawn_reuse_387 ], [ %t59, %spawn_grow_ok_391 ]
  %t66 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t65, i32 0, i32 0
  store i32 222, i32* %t66
  %t67 = load %ScratchSlot, %ScratchSlot* %t65
  %t68 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t53, i64 %t64
  store %ScratchSlot %t67, %ScratchSlot* %t68
  %t69 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t64
  %t70 = load i64, i64* %t69
  %t71 = add i64 %t70, 1
  store i64 %t71, i64* %t69
  br label %spawn_end_390
spawn_end_390:
  %t73 = sext i32 0 to i64
  %t74 = icmp ult i64 %t73, 1024
  br i1 %t74, label %genref_create_ok_394, label %genref_create_oob_395
genref_create_ok_394:
  %t75 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t73
  %t76 = load i64, i64* %t75
  br label %genref_create_end_396
genref_create_oob_395:
  br label %genref_create_end_396
genref_create_end_396:
  %t77 = phi i64 [ %t76, %genref_create_ok_394 ], [ 0, %genref_create_oob_395 ]
  %t79 = getelementptr inbounds %GenRef, %GenRef* %t78, i32 0, i32 0
  store i32 0, i32* %t79
  %t80 = getelementptr inbounds %GenRef, %GenRef* %t78, i32 0, i32 1
  store i64 %t77, i64* %t80
  %t81 = load %GenRef, %GenRef* %t78
  store %GenRef %t81, %GenRef* %t72
  %t82 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 0
  %t83 = load i32, i32* %t82
  %t84 = getelementptr inbounds %GenRef, %GenRef* %t26, i32 0, i32 1
  %t85 = load i64, i64* %t84
  %t86 = sext i32 %t83 to i64
  %t87 = icmp ult i64 %t86, 1024
  br i1 %t87, label %genref_place_check_397, label %genref_place_stale_399
genref_place_check_397:
  %t88 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t86
  %t89 = load i64, i64* %t88
  %t90 = icmp eq i64 %t85, %t89
  %t91 = and i64 %t89, 1
  %t92 = icmp eq i64 %t91, 1
  %t93 = and i1 %t90, %t92
  br i1 %t93, label %genref_place_ok_398, label %genref_place_stale_399
genref_place_ok_398:
  %t94 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t95 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t94, i64 %t86
  br label %genref_place_end_400
genref_place_stale_399:
  store %ScratchSlot zeroinitializer, %ScratchSlot* %t96
  br label %genref_place_end_400
genref_place_end_400:
  %t97 = phi %ScratchSlot* [ %t95, %genref_place_ok_398 ], [ %t96, %genref_place_stale_399 ]
  %t98 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t97, i32 0, i32 0
  %t99 = load i32, i32* %t98
  %t100 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t100, i32 %t99)
  %t101 = getelementptr inbounds %GenRef, %GenRef* %t72, i32 0, i32 0
  %t102 = load i32, i32* %t101
  %t103 = getelementptr inbounds %GenRef, %GenRef* %t72, i32 0, i32 1
  %t104 = load i64, i64* %t103
  %t105 = sext i32 %t102 to i64
  %t106 = icmp ult i64 %t105, 1024
  br i1 %t106, label %genref_place_check_401, label %genref_place_stale_403
genref_place_check_401:
  %t107 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t105
  %t108 = load i64, i64* %t107
  %t109 = icmp eq i64 %t104, %t108
  %t110 = and i64 %t108, 1
  %t111 = icmp eq i64 %t110, 1
  %t112 = and i1 %t109, %t111
  br i1 %t112, label %genref_place_ok_402, label %genref_place_stale_403
genref_place_ok_402:
  %t113 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t114 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t113, i64 %t105
  br label %genref_place_end_404
genref_place_stale_403:
  store %ScratchSlot zeroinitializer, %ScratchSlot* %t115
  br label %genref_place_end_404
genref_place_end_404:
  %t116 = phi %ScratchSlot* [ %t114, %genref_place_ok_402 ], [ %t115, %genref_place_stale_403 ]
  %t117 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t116, i32 0, i32 0
  %t118 = load i32, i32* %t117
  %t119 = getelementptr inbounds [51 x i8], [51 x i8]* @.str.29, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t119, i32 %t118)
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
  br i1 %t7, label %sdl_null_window_405, label %sdl_window_handle_ok_406
sdl_null_window_405:
  %t8 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.30, i64 0, i64 0
  call i32 @puts(i8* %t8)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_406:
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
  br i1 %t5, label %frame_alloc_fail_407, label %frame_alloc_ok_408
frame_alloc_fail_407:
  %t6 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.31, i64 0, i64 0
  call i32 @puts(i8* %t6)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_408:
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
  br i1 %t18, label %frame_alloc_fail_409, label %frame_alloc_ok_410
frame_alloc_fail_409:
  %t19 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.32, i64 0, i64 0
  call i32 @puts(i8* %t19)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_410:
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
  br i1 %t4, label %if_then_411, label %if_else_412
if_then_411:
  %t5 = load i32, i32* %t1
  br label %if_end_413
if_else_412:
  %t6 = load i32, i32* %t2
  br label %if_end_413
if_end_413:
  %t7 = phi i32 [ %t5, %if_then_411 ], [ %t6, %if_else_412 ]
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
  %t603 = alloca %FlashOnEat
  %t604 = alloca %FlashOnEat
  %t609 = alloca i1
  %t634 = alloca i32
  %t715 = alloca i64
  %t800 = alloca i32
  %t812 = alloca i32
  %t828 = alloca i32
  %t840 = alloca i32
  %t846 = alloca i32
  %t852 = alloca i32
  %t858 = alloca i32
  %t864 = alloca i32
  %t868 = alloca %GameOverFlash
  %t869 = alloca %GameOverFlash
  %t874 = alloca i1
  %t880 = alloca float
  %t883 = alloca float
  %t913 = alloca { i32, i32 }
  %t916 = alloca i32
  %t962 = alloca [16 x i8]
  %t971 = alloca i32
  %t975 = alloca i1
  %t995 = alloca %food__sb__grid__Cell
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
  br i1 %t15, label %sdl_init_fail_414, label %sdl_init_ok_415
sdl_init_fail_414:
  call void @star_rc_release(i8* %t11)
  br label %window_create_end_416
sdl_init_ok_415:
  %t16 = call i8* @SDL_CreateWindow(i8* %t11, i32 536805376, i32 536805376, i32 %t12, i32 %t13, i32 0)
  call void @star_rc_release(i8* %t11)
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %sdl_window_fail_417, label %sdl_window_ok_418
sdl_window_fail_417:
  br label %window_create_end_416
sdl_window_ok_418:
  %t18 = call i8* @SDL_CreateRenderer(i8* %t16, i32 -1, i32 0)
  %t19 = icmp eq i8* %t18, null
  br i1 %t19, label %sdl_renderer_fail_419, label %sdl_renderer_ok_420
sdl_renderer_fail_419:
  call void @SDL_DestroyWindow(i8* %t16)
  br label %window_create_end_416
sdl_renderer_ok_420:
  br label %window_create_end_416
window_create_end_416:
  %t20 = phi i8* [ null, %sdl_init_fail_414 ], [ null, %sdl_window_fail_417 ], [ null, %sdl_renderer_fail_419 ], [ %t16, %sdl_renderer_ok_420 ]
  store i8* %t20, i8** %t10
  %t21 = load i8*, i8** %t10
  %t22 = icmp eq i8* %t21, null
  br i1 %t22, label %if_then_421, label %if_else_422
if_then_421:
  %t23 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.34, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t23)
  call i32 (i8*, ...) @printf(i8* %t23)
  %t24 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.35, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24)
  ret i32 0
if_else_422:
  br label %if_end_423
if_end_423:
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
  br label %arr_rep_cond_424
arr_rep_cond_424:
  %t67 = load i64, i64* %t66
  %t68 = icmp ult i64 %t67, 5
  br i1 %t68, label %arr_rep_body_425, label %arr_rep_end_426
arr_rep_body_425:
  %t69 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 %t67
  store i32 0, i32* %t69
  %t70 = add i64 %t67, 1
  store i64 %t70, i64* %t66
  br label %arr_rep_cond_424
arr_rep_end_426:
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
  br label %arr_rep_cond_427
arr_rep_cond_427:
  %t84 = load i64, i64* %t83
  %t85 = icmp ult i64 %t84, 32
  br i1 %t85, label %arr_rep_body_428, label %arr_rep_end_429
arr_rep_body_428:
  %t86 = getelementptr inbounds [32 x %Particle], [32 x %Particle]* %t74, i32 0, i64 %t84
  store %Particle %t81, %Particle* %t86
  %t87 = add i64 %t84, 1
  store i64 %t87, i64* %t83
  br label %arr_rep_cond_427
arr_rep_end_429:
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
  br label %while_cond_430
while_cond_430:
  br i1 true, label %while_body_431, label %while_else_432
while_body_431:
  %t110 = load i8*, i8** %t10
  %t111 = icmp eq i8* %t110, null
  br i1 %t111, label %sdl_null_window_434, label %sdl_window_handle_ok_435
sdl_null_window_434:
  %t112 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.39, i64 0, i64 0
  call i32 @puts(i8* %t112)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_435:
  store i1 false, i1* %t113
  %t115 = getelementptr inbounds [56 x i8], [56 x i8]* %t114, i64 0, i64 0
  br label %sdl_poll_cond_436
sdl_poll_cond_436:
  %t116 = call i32 @SDL_PollEvent(i8* %t115)
  %t117 = icmp ne i32 %t116, 0
  br i1 %t117, label %sdl_poll_body_437, label %sdl_poll_end_439
sdl_poll_body_437:
  %t118 = bitcast i8* %t115 to i32*
  %t119 = load i32, i32* %t118
  %t120 = icmp eq i32 %t119, 256
  br i1 %t120, label %sdl_poll_set_quit_438, label %sdl_poll_cond_436
sdl_poll_set_quit_438:
  store i1 true, i1* %t113
  br label %sdl_poll_cond_436
sdl_poll_end_439:
  %t121 = load i1, i1* %t113
  br i1 %t121, label %if_then_440, label %if_else_441
if_then_440:
  br label %while_end_433
if_else_441:
  br label %if_end_442
if_end_442:
  %t122 = load i32, i32* %t97
  %t123 = icmp sge i32 %t122, 0
  %t124 = icmp slt i32 %t122, 512
  %t125 = and i1 %t123, %t124
  br i1 %t125, label %key_down_read_443, label %key_down_end_444
key_down_read_443:
  %t126 = call i8* @SDL_GetKeyboardState(i32* null)
  %t127 = sext i32 %t122 to i64
  %t128 = getelementptr inbounds i8, i8* %t126, i64 %t127
  %t129 = load i8, i8* %t128
  %t130 = icmp ne i8 %t129, 0
  br label %key_down_end_444
key_down_end_444:
  %t131 = phi i1 [ false, %if_end_442 ], [ %t130, %key_down_read_443 ]
  br i1 %t131, label %if_then_445, label %if_else_446
if_then_445:
  br label %while_end_433
if_else_446:
  br label %if_end_447
if_end_447:
  %t133 = load i32, i32* %t98
  %t134 = icmp sge i32 %t133, 0
  %t135 = icmp slt i32 %t133, 512
  %t136 = and i1 %t134, %t135
  br i1 %t136, label %key_down_read_448, label %key_down_end_449
key_down_read_448:
  %t137 = call i8* @SDL_GetKeyboardState(i32* null)
  %t138 = sext i32 %t133 to i64
  %t139 = getelementptr inbounds i8, i8* %t137, i64 %t138
  %t140 = load i8, i8* %t139
  %t141 = icmp ne i8 %t140, 0
  br label %key_down_end_449
key_down_end_449:
  %t142 = phi i1 [ false, %if_end_447 ], [ %t141, %key_down_read_448 ]
  store i1 %t142, i1* %t132
  %t143 = load i1, i1* %t132
  br i1 %t143, label %logic_rhs_450, label %logic_short_451
logic_rhs_450:
  %t144 = load i1, i1* %t93
  %t145 = xor i1 true, %t144
  br label %logic_end_452
logic_short_451:
  br label %logic_end_452
logic_end_452:
  %t146 = phi i1 [ %t145, %logic_rhs_450 ], [ false, %logic_short_451 ]
  br i1 %t146, label %if_then_453, label %if_else_454
if_then_453:
  %t147 = load i64, i64* %t58
  %t148 = zext i32 0 to i64
  %t149 = shl i64 1, %t148
  %t150 = and i64 %t147, %t149
  %t151 = icmp ne i64 %t150, 0
  br i1 %t151, label %if_then_456, label %if_else_457
if_then_456:
  %t152 = load i64, i64* %t58
  %t153 = zext i32 0 to i64
  %t154 = shl i64 1, %t153
  %t156 = xor i64 %t154, -1
  %t155 = and i64 %t152, %t156
  store i64 %t155, i64* %t58
  br label %if_end_458
if_else_457:
  %t157 = load i64, i64* %t58
  %t158 = zext i32 0 to i64
  %t159 = shl i64 1, %t158
  %t160 = or i64 %t157, %t159
  store i64 %t160, i64* %t58
  br label %if_end_458
if_end_458:
  br label %if_end_455
if_else_454:
  br label %if_end_455
if_end_455:
  %t161 = load i1, i1* %t132
  store i1 %t161, i1* %t93
  %t163 = load i32, i32* %t99
  %t164 = icmp sge i32 %t163, 0
  %t165 = icmp slt i32 %t163, 512
  %t166 = and i1 %t164, %t165
  br i1 %t166, label %key_down_read_459, label %key_down_end_460
key_down_read_459:
  %t167 = call i8* @SDL_GetKeyboardState(i32* null)
  %t168 = sext i32 %t163 to i64
  %t169 = getelementptr inbounds i8, i8* %t167, i64 %t168
  %t170 = load i8, i8* %t169
  %t171 = icmp ne i8 %t170, 0
  br label %key_down_end_460
key_down_end_460:
  %t172 = phi i1 [ false, %if_end_455 ], [ %t171, %key_down_read_459 ]
  store i1 %t172, i1* %t162
  %t173 = load i1, i1* %t162
  br i1 %t173, label %logic_rhs_461, label %logic_short_462
logic_rhs_461:
  %t174 = load i1, i1* %t94
  %t175 = xor i1 true, %t174
  br label %logic_end_463
logic_short_462:
  br label %logic_end_463
logic_end_463:
  %t176 = phi i1 [ %t175, %logic_rhs_461 ], [ false, %logic_short_462 ]
  br i1 %t176, label %if_then_464, label %if_else_465
if_then_464:
  %t177 = load i64, i64* %t58
  %t178 = zext i32 1 to i64
  %t179 = shl i64 1, %t178
  %t180 = and i64 %t177, %t179
  %t181 = icmp ne i64 %t180, 0
  br i1 %t181, label %if_then_467, label %if_else_468
if_then_467:
  %t182 = load i64, i64* %t58
  %t183 = zext i32 1 to i64
  %t184 = shl i64 1, %t183
  %t186 = xor i64 %t184, -1
  %t185 = and i64 %t182, %t186
  store i64 %t185, i64* %t58
  br label %if_end_469
if_else_468:
  %t187 = load i64, i64* %t58
  %t188 = zext i32 1 to i64
  %t189 = shl i64 1, %t188
  %t190 = or i64 %t187, %t189
  store i64 %t190, i64* %t58
  call void @dump_particle_arena()
  br label %if_end_469
if_end_469:
  br label %if_end_466
if_else_465:
  br label %if_end_466
if_end_466:
  %t191 = load i1, i1* %t162
  store i1 %t191, i1* %t94
  %t192 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 4
  %t193 = load i1, i1* %t192
  %t194 = xor i1 true, %t193
  br i1 %t194, label %if_then_470, label %if_else_471
if_then_470:
  %t196 = load i32, i32* %t100
  %t197 = icmp sge i32 %t196, 0
  %t198 = icmp slt i32 %t196, 512
  %t199 = and i1 %t197, %t198
  br i1 %t199, label %key_down_read_473, label %key_down_end_474
key_down_read_473:
  %t200 = call i8* @SDL_GetKeyboardState(i32* null)
  %t201 = sext i32 %t196 to i64
  %t202 = getelementptr inbounds i8, i8* %t200, i64 %t201
  %t203 = load i8, i8* %t202
  %t204 = icmp ne i8 %t203, 0
  br label %key_down_end_474
key_down_end_474:
  %t205 = phi i1 [ false, %if_then_470 ], [ %t204, %key_down_read_473 ]
  store i1 %t205, i1* %t195
  %t206 = load i1, i1* %t195
  br i1 %t206, label %logic_rhs_475, label %logic_short_476
logic_rhs_475:
  %t207 = load i1, i1* %t95
  %t208 = xor i1 true, %t207
  br label %logic_end_477
logic_short_476:
  br label %logic_end_477
logic_end_477:
  %t209 = phi i1 [ %t208, %logic_rhs_475 ], [ false, %logic_short_476 ]
  br i1 %t209, label %if_then_478, label %if_else_479
if_then_478:
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
  br label %if_end_480
if_else_479:
  br label %if_end_480
if_end_480:
  %t217 = load i1, i1* %t195
  store i1 %t217, i1* %t95
  br label %if_end_472
if_else_471:
  %t218 = load i32, i32* %t102
  %t219 = icmp sge i32 %t218, 0
  %t220 = icmp slt i32 %t218, 512
  %t221 = and i1 %t219, %t220
  br i1 %t221, label %key_down_read_481, label %key_down_end_482
key_down_read_481:
  %t222 = call i8* @SDL_GetKeyboardState(i32* null)
  %t223 = sext i32 %t218 to i64
  %t224 = getelementptr inbounds i8, i8* %t222, i64 %t223
  %t225 = load i8, i8* %t224
  %t226 = icmp ne i8 %t225, 0
  br label %key_down_end_482
key_down_end_482:
  %t227 = phi i1 [ false, %if_else_471 ], [ %t226, %key_down_read_481 ]
  br i1 %t227, label %logic_short_484, label %logic_rhs_483
logic_rhs_483:
  %t228 = load i32, i32* %t106
  %t229 = icmp sge i32 %t228, 0
  %t230 = icmp slt i32 %t228, 512
  %t231 = and i1 %t229, %t230
  br i1 %t231, label %key_down_read_486, label %key_down_end_487
key_down_read_486:
  %t232 = call i8* @SDL_GetKeyboardState(i32* null)
  %t233 = sext i32 %t228 to i64
  %t234 = getelementptr inbounds i8, i8* %t232, i64 %t233
  %t235 = load i8, i8* %t234
  %t236 = icmp ne i8 %t235, 0
  br label %key_down_end_487
key_down_end_487:
  %t237 = phi i1 [ false, %logic_rhs_483 ], [ %t236, %key_down_read_486 ]
  br label %logic_end_485
logic_short_484:
  br label %logic_end_485
logic_end_485:
  %t238 = phi i1 [ %t237, %key_down_end_487 ], [ true, %logic_short_484 ]
  br i1 %t238, label %if_then_488, label %if_else_489
if_then_488:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t51, i32 0)
  br label %if_end_490
if_else_489:
  br label %if_end_490
if_end_490:
  %t240 = load i32, i32* %t103
  %t241 = icmp sge i32 %t240, 0
  %t242 = icmp slt i32 %t240, 512
  %t243 = and i1 %t241, %t242
  br i1 %t243, label %key_down_read_491, label %key_down_end_492
key_down_read_491:
  %t244 = call i8* @SDL_GetKeyboardState(i32* null)
  %t245 = sext i32 %t240 to i64
  %t246 = getelementptr inbounds i8, i8* %t244, i64 %t245
  %t247 = load i8, i8* %t246
  %t248 = icmp ne i8 %t247, 0
  br label %key_down_end_492
key_down_end_492:
  %t249 = phi i1 [ false, %if_end_490 ], [ %t248, %key_down_read_491 ]
  br i1 %t249, label %logic_short_494, label %logic_rhs_493
logic_rhs_493:
  %t250 = load i32, i32* %t107
  %t251 = icmp sge i32 %t250, 0
  %t252 = icmp slt i32 %t250, 512
  %t253 = and i1 %t251, %t252
  br i1 %t253, label %key_down_read_496, label %key_down_end_497
key_down_read_496:
  %t254 = call i8* @SDL_GetKeyboardState(i32* null)
  %t255 = sext i32 %t250 to i64
  %t256 = getelementptr inbounds i8, i8* %t254, i64 %t255
  %t257 = load i8, i8* %t256
  %t258 = icmp ne i8 %t257, 0
  br label %key_down_end_497
key_down_end_497:
  %t259 = phi i1 [ false, %logic_rhs_493 ], [ %t258, %key_down_read_496 ]
  br label %logic_end_495
logic_short_494:
  br label %logic_end_495
logic_end_495:
  %t260 = phi i1 [ %t259, %key_down_end_497 ], [ true, %logic_short_494 ]
  br i1 %t260, label %if_then_498, label %if_else_499
if_then_498:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t51, i32 1)
  br label %if_end_500
if_else_499:
  br label %if_end_500
if_end_500:
  %t262 = load i32, i32* %t104
  %t263 = icmp sge i32 %t262, 0
  %t264 = icmp slt i32 %t262, 512
  %t265 = and i1 %t263, %t264
  br i1 %t265, label %key_down_read_501, label %key_down_end_502
key_down_read_501:
  %t266 = call i8* @SDL_GetKeyboardState(i32* null)
  %t267 = sext i32 %t262 to i64
  %t268 = getelementptr inbounds i8, i8* %t266, i64 %t267
  %t269 = load i8, i8* %t268
  %t270 = icmp ne i8 %t269, 0
  br label %key_down_end_502
key_down_end_502:
  %t271 = phi i1 [ false, %if_end_500 ], [ %t270, %key_down_read_501 ]
  br i1 %t271, label %logic_short_504, label %logic_rhs_503
logic_rhs_503:
  %t272 = load i32, i32* %t108
  %t273 = icmp sge i32 %t272, 0
  %t274 = icmp slt i32 %t272, 512
  %t275 = and i1 %t273, %t274
  br i1 %t275, label %key_down_read_506, label %key_down_end_507
key_down_read_506:
  %t276 = call i8* @SDL_GetKeyboardState(i32* null)
  %t277 = sext i32 %t272 to i64
  %t278 = getelementptr inbounds i8, i8* %t276, i64 %t277
  %t279 = load i8, i8* %t278
  %t280 = icmp ne i8 %t279, 0
  br label %key_down_end_507
key_down_end_507:
  %t281 = phi i1 [ false, %logic_rhs_503 ], [ %t280, %key_down_read_506 ]
  br label %logic_end_505
logic_short_504:
  br label %logic_end_505
logic_end_505:
  %t282 = phi i1 [ %t281, %key_down_end_507 ], [ true, %logic_short_504 ]
  br i1 %t282, label %if_then_508, label %if_else_509
if_then_508:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t51, i32 2)
  br label %if_end_510
if_else_509:
  br label %if_end_510
if_end_510:
  %t284 = load i32, i32* %t105
  %t285 = icmp sge i32 %t284, 0
  %t286 = icmp slt i32 %t284, 512
  %t287 = and i1 %t285, %t286
  br i1 %t287, label %key_down_read_511, label %key_down_end_512
key_down_read_511:
  %t288 = call i8* @SDL_GetKeyboardState(i32* null)
  %t289 = sext i32 %t284 to i64
  %t290 = getelementptr inbounds i8, i8* %t288, i64 %t289
  %t291 = load i8, i8* %t290
  %t292 = icmp ne i8 %t291, 0
  br label %key_down_end_512
key_down_end_512:
  %t293 = phi i1 [ false, %if_end_510 ], [ %t292, %key_down_read_511 ]
  br i1 %t293, label %logic_short_514, label %logic_rhs_513
logic_rhs_513:
  %t294 = load i32, i32* %t109
  %t295 = icmp sge i32 %t294, 0
  %t296 = icmp slt i32 %t294, 512
  %t297 = and i1 %t295, %t296
  br i1 %t297, label %key_down_read_516, label %key_down_end_517
key_down_read_516:
  %t298 = call i8* @SDL_GetKeyboardState(i32* null)
  %t299 = sext i32 %t294 to i64
  %t300 = getelementptr inbounds i8, i8* %t298, i64 %t299
  %t301 = load i8, i8* %t300
  %t302 = icmp ne i8 %t301, 0
  br label %key_down_end_517
key_down_end_517:
  %t303 = phi i1 [ false, %logic_rhs_513 ], [ %t302, %key_down_read_516 ]
  br label %logic_end_515
logic_short_514:
  br label %logic_end_515
logic_end_515:
  %t304 = phi i1 [ %t303, %key_down_end_517 ], [ true, %logic_short_514 ]
  br i1 %t304, label %if_then_518, label %if_else_519
if_then_518:
  call void @food__sb__Snake__queue_turn(%food__sb__Snake* %t51, i32 3)
  br label %if_end_520
if_else_519:
  br label %if_end_520
if_end_520:
  %t306 = load i32, i32* %t101
  %t307 = icmp sge i32 %t306, 0
  %t308 = icmp slt i32 %t306, 512
  %t309 = and i1 %t307, %t308
  br i1 %t309, label %key_down_read_521, label %key_down_end_522
key_down_read_521:
  %t310 = call i8* @SDL_GetKeyboardState(i32* null)
  %t311 = sext i32 %t306 to i64
  %t312 = getelementptr inbounds i8, i8* %t310, i64 %t311
  %t313 = load i8, i8* %t312
  %t314 = icmp ne i8 %t313, 0
  br label %key_down_end_522
key_down_end_522:
  %t315 = phi i1 [ false, %if_end_520 ], [ %t314, %key_down_read_521 ]
  store i1 %t315, i1* %t96
  %t317 = load i1, i1* %t96
  br i1 %t317, label %if_then_523, label %if_else_524
if_then_523:
  %t318 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 2
  %t319 = load i32, i32* %t318
  %t320 = icmp eq i32 2, 0
  %t321 = icmp eq i32 %t319, -2147483648
  %t322 = icmp eq i32 2, -1
  %t323 = and i1 %t321, %t322
  %t324 = or i1 %t320, %t323
  br i1 %t324, label %int_div_fail_526, label %int_div_ok_527
int_div_fail_526:
  %t325 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.40, i64 0, i64 0
  call i32 @puts(i8* %t325)
  call void @exit(i32 1)
  unreachable
int_div_ok_527:
  %t326 = sdiv i32 %t319, 2
  br label %if_end_525
if_else_524:
  %t327 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 2
  %t328 = load i32, i32* %t327
  br label %if_end_525
if_end_525:
  %t329 = phi i32 [ %t326, %int_div_ok_527 ], [ %t328, %if_else_524 ]
  store i32 %t329, i32* %t316
  %t331 = call i32 @SDL_GetTicks()
  store i32 %t331, i32* %t330
  %t332 = load i64, i64* %t58
  %t333 = zext i32 0 to i64
  %t334 = shl i64 1, %t333
  %t335 = and i64 %t332, %t334
  %t336 = icmp ne i64 %t335, 0
  %t337 = xor i1 true, %t336
  br i1 %t337, label %logic_rhs_528, label %logic_short_529
logic_rhs_528:
  %t338 = load i32, i32* %t330
  %t339 = load i32, i32* %t91
  %t340 = sub i32 %t338, %t339
  %t341 = load i32, i32* %t316
  %t342 = icmp sge i32 %t340, %t341
  br label %logic_end_530
logic_short_529:
  br label %logic_end_530
logic_end_530:
  %t343 = phi i1 [ %t342, %logic_rhs_528 ], [ false, %logic_short_529 ]
  br i1 %t343, label %if_then_531, label %if_else_532
if_then_531:
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
  br i1 %t353, label %list_cow_alloc_534, label %list_cow_check_535
list_cow_alloc_534:
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
  br label %list_cow_done_536
list_cow_check_535:
  %t364 = getelementptr inbounds i8, i8* %t352, i64 -16
  %t365 = bitcast i8* %t364 to i64*
  %t366 = load atomic i64, i64* %t365 seq_cst, align 8
  %t367 = icmp eq i64 %t366, 1
  br i1 %t367, label %list_cow_done_536, label %list_cow_clone_537
list_cow_clone_537:
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
  br i1 %t381, label %list_cow_copy_538, label %list_cow_after_copy_539
list_cow_copy_538:
  %t382 = mul i64 %t372, %t351
  %t383 = bitcast i64* %t370 to i8*
  call i8* @memcpy(i8* %t379, i8* %t383, i64 %t382)
  br label %list_cow_after_copy_539
list_cow_after_copy_539:
  %t384 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t377, i32 0, i32 0
  store i64* %t380, i64** %t384
  %t385 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t377, i32 0, i32 1
  store i64 %t372, i64* %t385
  %t386 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t377, i32 0, i32 2
  store i64 %t374, i64* %t386
  call void @star_rc_release(i8* %t352)
  store i8* %t376, i8** %t60
  br label %list_cow_done_536
list_cow_done_536:
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
  br label %sym_find_cond_540
sym_find_cond_540:
  %t399 = load i64, i64* %t398
  %t400 = icmp slt i64 %t399, %t396
  br i1 %t400, label %sym_find_body_541, label %sym_find_end_543
sym_find_body_541:
  %t401 = getelementptr inbounds i8*, i8** %t397, i64 %t399
  %t402 = load i8*, i8** %t401
  %t403 = call i32 @strcmp(i8* %t402, i8* %t394)
  %t404 = icmp eq i32 %t403, 0
  br i1 %t404, label %sym_find_end_543, label %sym_find_next_542
sym_find_next_542:
  %t405 = add i64 %t399, 1
  store i64 %t405, i64* %t398
  br label %sym_find_cond_540
sym_find_end_543:
  %t406 = load i64, i64* %t398
  %t407 = icmp slt i64 %t406, %t396
  br i1 %t407, label %sym_found_544, label %sym_notfound_545
sym_found_544:
  call void @star_rc_release(i8* %t394)
  br label %sym_done_546
sym_notfound_545:
  %t408 = load i64, i64* @sym.cap
  %t409 = icmp sge i64 %t396, %t408
  br i1 %t409, label %sym_grow_547, label %sym_store_548
sym_grow_547:
  %t410 = mul i64 %t408, 2
  %t411 = icmp sgt i64 %t410, 0
  %t412 = select i1 %t411, i64 %t410, i64 1
  %t413 = mul i64 %t412, 8
  %t414 = call i8* @malloc(i64 %t413)
  %t415 = bitcast i8* %t414 to i8**
  %t416 = icmp sgt i64 %t408, 0
  br i1 %t416, label %sym_copy_549, label %sym_after_copy_550
sym_copy_549:
  %t417 = mul i64 %t396, 8
  %t418 = bitcast i8** %t397 to i8*
  call i8* @memcpy(i8* %t414, i8* %t418, i64 %t417)
  call void @free(i8* %t418)
  br label %sym_after_copy_550
sym_after_copy_550:
  store i8** %t415, i8*** @sym.data
  store i64 %t412, i64* @sym.cap
  br label %sym_store_548
sym_store_548:
  %t419 = load i8**, i8*** @sym.data
  %t420 = getelementptr inbounds i8*, i8** %t419, i64 %t396
  store i8* %t394, i8** %t420
  %t421 = add i64 %t396, 1
  store i64 %t421, i64* @sym.len
  br label %sym_done_546
sym_done_546:
  %t422 = phi i64 [ %t406, %sym_found_544 ], [ %t396, %sym_store_548 ]
  call i32 @ReleaseSemaphore(i8* %t395, i32 1, i32* null)
  %t423 = load i64, i64* %t393
  %t424 = load i64*, i64** %t389
  %t425 = load i64, i64* %t391
  %t426 = icmp sge i64 %t425, %t423
  br i1 %t426, label %list_push_grow_551, label %list_push_store_552
list_push_grow_551:
  %t427 = mul i64 %t423, 2
  %t428 = icmp sgt i64 %t427, 0
  %t429 = select i1 %t428, i64 %t427, i64 1
  %t430 = getelementptr i64, i64* null, i32 1
  %t431 = ptrtoint i64* %t430 to i64
  %t432 = mul i64 %t429, %t431
  %t433 = call i8* @malloc(i64 %t432)
  %t434 = bitcast i8* %t433 to i64*
  %t435 = icmp sgt i64 %t423, 0
  br i1 %t435, label %list_push_copy_553, label %list_push_after_copy_554
list_push_copy_553:
  %t436 = mul i64 %t425, %t431
  %t437 = bitcast i64* %t424 to i8*
  call i8* @memcpy(i8* %t433, i8* %t437, i64 %t436)
  call void @free(i8* %t437)
  br label %list_push_after_copy_554
list_push_after_copy_554:
  store i64* %t434, i64** %t389
  store i64 %t429, i64* %t393
  br label %list_push_store_552
list_push_store_552:
  %t438 = load i64*, i64** %t389
  %t439 = getelementptr inbounds i64, i64* %t438, i64 %t425
  store i64 %t422, i64* %t439
  %t440 = add i64 %t425, 1
  store i64 %t440, i64* %t391
  %t441 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 4
  %t442 = load i1, i1* %t441
  br i1 %t442, label %logic_rhs_555, label %logic_short_556
logic_rhs_555:
  %t443 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t348
  %t444 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t53
  %t445 = call i1 @food__sb__grid__cell_eq(%food__sb__grid__Cell %t443, %food__sb__grid__Cell %t444)
  br label %logic_end_557
logic_short_556:
  br label %logic_end_557
logic_end_557:
  %t446 = phi i1 [ %t445, %logic_rhs_555 ], [ false, %logic_short_556 ]
  br i1 %t446, label %if_then_558, label %if_else_559
if_then_558:
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
  br i1 %t455, label %list_cow_alloc_561, label %list_cow_check_562
list_cow_alloc_561:
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
  br label %list_cow_done_563
list_cow_check_562:
  %t462 = getelementptr inbounds i8, i8* %t454, i64 -16
  %t463 = bitcast i8* %t462 to i64*
  %t464 = load atomic i64, i64* %t463 seq_cst, align 8
  %t465 = icmp eq i64 %t464, 1
  br i1 %t465, label %list_cow_done_563, label %list_cow_clone_564
list_cow_clone_564:
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
  br i1 %t479, label %list_cow_copy_565, label %list_cow_after_copy_566
list_cow_copy_565:
  %t480 = mul i64 %t470, %t453
  %t481 = bitcast i64* %t468 to i8*
  call i8* @memcpy(i8* %t477, i8* %t481, i64 %t480)
  br label %list_cow_after_copy_566
list_cow_after_copy_566:
  %t482 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t475, i32 0, i32 0
  store i64* %t478, i64** %t482
  %t483 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t475, i32 0, i32 1
  store i64 %t470, i64* %t483
  %t484 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t475, i32 0, i32 2
  store i64 %t472, i64* %t484
  call void @star_rc_release(i8* %t454)
  store i8* %t474, i8** %t60
  br label %list_cow_done_563
list_cow_done_563:
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
  br label %sym_find_cond_567
sym_find_cond_567:
  %t497 = load i64, i64* %t496
  %t498 = icmp slt i64 %t497, %t494
  br i1 %t498, label %sym_find_body_568, label %sym_find_end_570
sym_find_body_568:
  %t499 = getelementptr inbounds i8*, i8** %t495, i64 %t497
  %t500 = load i8*, i8** %t499
  %t501 = call i32 @strcmp(i8* %t500, i8* %t492)
  %t502 = icmp eq i32 %t501, 0
  br i1 %t502, label %sym_find_end_570, label %sym_find_next_569
sym_find_next_569:
  %t503 = add i64 %t497, 1
  store i64 %t503, i64* %t496
  br label %sym_find_cond_567
sym_find_end_570:
  %t504 = load i64, i64* %t496
  %t505 = icmp slt i64 %t504, %t494
  br i1 %t505, label %sym_found_571, label %sym_notfound_572
sym_found_571:
  call void @star_rc_release(i8* %t492)
  br label %sym_done_573
sym_notfound_572:
  %t506 = load i64, i64* @sym.cap
  %t507 = icmp sge i64 %t494, %t506
  br i1 %t507, label %sym_grow_574, label %sym_store_575
sym_grow_574:
  %t508 = mul i64 %t506, 2
  %t509 = icmp sgt i64 %t508, 0
  %t510 = select i1 %t509, i64 %t508, i64 1
  %t511 = mul i64 %t510, 8
  %t512 = call i8* @malloc(i64 %t511)
  %t513 = bitcast i8* %t512 to i8**
  %t514 = icmp sgt i64 %t506, 0
  br i1 %t514, label %sym_copy_576, label %sym_after_copy_577
sym_copy_576:
  %t515 = mul i64 %t494, 8
  %t516 = bitcast i8** %t495 to i8*
  call i8* @memcpy(i8* %t512, i8* %t516, i64 %t515)
  call void @free(i8* %t516)
  br label %sym_after_copy_577
sym_after_copy_577:
  store i8** %t513, i8*** @sym.data
  store i64 %t510, i64* @sym.cap
  br label %sym_store_575
sym_store_575:
  %t517 = load i8**, i8*** @sym.data
  %t518 = getelementptr inbounds i8*, i8** %t517, i64 %t494
  store i8* %t492, i8** %t518
  %t519 = add i64 %t494, 1
  store i64 %t519, i64* @sym.len
  br label %sym_done_573
sym_done_573:
  %t520 = phi i64 [ %t504, %sym_found_571 ], [ %t494, %sym_store_575 ]
  call i32 @ReleaseSemaphore(i8* %t493, i32 1, i32* null)
  %t521 = load i64, i64* %t491
  %t522 = load i64*, i64** %t487
  %t523 = load i64, i64* %t489
  %t524 = icmp sge i64 %t523, %t521
  br i1 %t524, label %list_push_grow_578, label %list_push_store_579
list_push_grow_578:
  %t525 = mul i64 %t521, 2
  %t526 = icmp sgt i64 %t525, 0
  %t527 = select i1 %t526, i64 %t525, i64 1
  %t528 = getelementptr i64, i64* null, i32 1
  %t529 = ptrtoint i64* %t528 to i64
  %t530 = mul i64 %t527, %t529
  %t531 = call i8* @malloc(i64 %t530)
  %t532 = bitcast i8* %t531 to i64*
  %t533 = icmp sgt i64 %t521, 0
  br i1 %t533, label %list_push_copy_580, label %list_push_after_copy_581
list_push_copy_580:
  %t534 = mul i64 %t523, %t529
  %t535 = bitcast i64* %t522 to i8*
  call i8* @memcpy(i8* %t531, i8* %t535, i64 %t534)
  call void @free(i8* %t535)
  br label %list_push_after_copy_581
list_push_after_copy_581:
  store i64* %t532, i64** %t487
  store i64 %t527, i64* %t491
  br label %list_push_store_579
list_push_store_579:
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
  br i1 %t550, label %int_div_fail_582, label %int_div_ok_583
int_div_fail_582:
  %t551 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.43, i64 0, i64 0
  call i32 @puts(i8* %t551)
  call void @exit(i32 1)
  unreachable
int_div_ok_583:
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
  br i1 %t563, label %int_div_fail_584, label %int_div_ok_585
int_div_fail_584:
  %t564 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.44, i64 0, i64 0
  call i32 @puts(i8* %t564)
  call void @exit(i32 1)
  unreachable
int_div_ok_585:
  %t565 = sdiv i32 %t558, 2
  %t566 = add i32 %t557, %t565
  %t567 = sitofp i32 %t566 to float
  store float %t567, float* %t555
  %t568 = load float, float* %t542
  %t569 = load float, float* %t555
  call void @ParticlePool__spawn_burst(%ParticlePool* %t72, float %t568, float %t569)
  %t571 = load %Particle*, %Particle** @arena.Particles.data
  %t572 = icmp eq %Particle* %t571, null
  br i1 %t572, label %spawn_init_586, label %spawn_ready_587
spawn_init_586:
  %t573 = getelementptr %Particle, %Particle* null, i32 1
  %t574 = ptrtoint %Particle* %t573 to i64
  %t575 = mul i64 %t574, 256
  %t576 = call i8* @malloc(i64 %t575)
  %t577 = bitcast i8* %t576 to %Particle*
  store %Particle* %t577, %Particle** @arena.Particles.data
  br label %spawn_ready_587
spawn_ready_587:
  %t578 = load %Particle*, %Particle** @arena.Particles.data
  %t579 = load i64, i64* @arena.Particles.free_top
  %t580 = icmp sgt i64 %t579, 0
  br i1 %t580, label %spawn_reuse_588, label %spawn_grow_589
spawn_reuse_588:
  %t581 = sub i64 %t579, 1
  store i64 %t581, i64* @arena.Particles.free_top
  %t582 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.free, i64 0, i64 %t581
  %t583 = load i64, i64* %t582
  br label %spawn_store_590
spawn_grow_589:
  %t584 = load i64, i64* @arena.Particles.count
  %t585 = icmp slt i64 %t584, 256
  br i1 %t585, label %spawn_grow_ok_592, label %spawn_capacity_warn_593
spawn_capacity_warn_593:
  %t586 = load i1, i1* @arena.Particles.warned
  br i1 %t586, label %spawn_end_591, label %spawn_warn_print_594
spawn_warn_print_594:
  store i1 1, i1* @arena.Particles.warned
  %t587 = getelementptr inbounds [141 x i8], [141 x i8]* @.str.45, i64 0, i64 0
  call i32 @puts(i8* %t587)
  br label %spawn_end_591
spawn_grow_ok_592:
  %t588 = add i64 %t584, 1
  store i64 %t588, i64* @arena.Particles.count
  br label %spawn_store_590
spawn_store_590:
  %t589 = phi i64 [ %t583, %spawn_reuse_588 ], [ %t584, %spawn_grow_ok_592 ]
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
  br label %spawn_end_591
spawn_end_591:
  %t605 = load i8*, i8** %t10
  %t606 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t604, i32 0, i32 0
  store i8* %t605, i8** %t606
  %t607 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t604, i32 0, i32 1
  store i32 0, i32* %t607
  %t608 = load %FlashOnEat, %FlashOnEat* %t604
  store %FlashOnEat %t608, %FlashOnEat* %t603
  store i1 true, i1* %t609
  br label %while_cond_595
while_cond_595:
  %t610 = load i1, i1* %t609
  br i1 %t610, label %while_body_596, label %while_else_597
while_body_596:
  %t611 = call i1 @FlashOnEat__resume(%FlashOnEat* %t603)
  store i1 %t611, i1* %t609
  br label %while_cond_595
while_else_597:
  br label %while_end_598
while_end_598:
  %t612 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 0
  %t613 = load { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t612
  %t614 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t615 = call %food__sb__grid__Cell @food__spawn_food({ [768 x %food__sb__grid__Cell], i64, i64 } %t613, i32 %t614)
  store %food__sb__grid__Cell %t615, %food__sb__grid__Cell* %t53
  %t616 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t617 = load i32, i32* %t616
  %t618 = icmp eq i32 50, 0
  %t619 = icmp eq i32 %t617, -2147483648
  %t620 = icmp eq i32 50, -1
  %t621 = and i1 %t619, %t620
  %t622 = or i1 %t618, %t621
  br i1 %t622, label %int_div_fail_599, label %int_div_ok_600
int_div_fail_599:
  %t623 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.46, i64 0, i64 0
  call i32 @puts(i8* %t623)
  call void @exit(i32 1)
  unreachable
int_div_ok_600:
  %t624 = sdiv i32 %t617, 50
  %t625 = load i32, i32* %t345
  %t626 = icmp eq i32 50, 0
  %t627 = icmp eq i32 %t625, -2147483648
  %t628 = icmp eq i32 50, -1
  %t629 = and i1 %t627, %t628
  %t630 = or i1 %t626, %t629
  br i1 %t630, label %int_div_fail_601, label %int_div_ok_602
int_div_fail_601:
  %t631 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.47, i64 0, i64 0
  call i32 @puts(i8* %t631)
  call void @exit(i32 1)
  unreachable
int_div_ok_602:
  %t632 = sdiv i32 %t625, 50
  %t633 = icmp sgt i32 %t624, %t632
  br i1 %t633, label %if_then_603, label %if_else_604
if_then_603:
  %t635 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t636 = load i32, i32* %t635
  %t637 = icmp eq i32 50, 0
  %t638 = icmp eq i32 %t636, -2147483648
  %t639 = icmp eq i32 50, -1
  %t640 = and i1 %t638, %t639
  %t641 = or i1 %t637, %t640
  br i1 %t641, label %int_div_fail_606, label %int_div_ok_607
int_div_fail_606:
  %t642 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.48, i64 0, i64 0
  call i32 @puts(i8* %t642)
  call void @exit(i32 1)
  unreachable
int_div_ok_607:
  %t643 = sdiv i32 %t636, 50
  store i32 %t643, i32* %t634
  %t644 = load i32, i32* %t634
  %t645 = icmp sge i32 %t644, 1
  br i1 %t645, label %logic_rhs_608, label %logic_short_609
logic_rhs_608:
  %t646 = load i32, i32* %t634
  %t647 = icmp sle i32 %t646, 8
  br label %logic_end_610
logic_short_609:
  br label %logic_end_610
logic_end_610:
  %t648 = phi i1 [ %t647, %logic_rhs_608 ], [ false, %logic_short_609 ]
  br i1 %t648, label %if_then_611, label %if_else_612
if_then_611:
  %t649 = load i8, i8* %t59
  %t650 = load i32, i32* %t634
  %t651 = sub i32 %t650, 1
  %t652 = and i32 %t651, 7
  %t653 = trunc i32 %t652 to i8
  %t654 = shl i8 1, %t653
  %t655 = or i8 %t649, %t654
  store i8 %t655, i8* %t59
  %t656 = load i32, i32* %t634
  %t657 = load i8, i8* %t59
  %t658 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.49, i64 0, i64 0
  %t659 = zext i8 %t657 to i32
  call i32 (i8*, ...) @printf(i8* %t658, i32 %t656, i32 %t659)
  br label %if_end_613
if_else_612:
  br label %if_end_613
if_end_613:
  br label %if_end_605
if_else_604:
  br label %if_end_605
if_end_605:
  %t660 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t661 = load i32, i32* %t660
  %t662 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t663 = load i32, i32* %t662
  %t664 = icmp sgt i32 %t661, %t663
  br i1 %t664, label %if_then_614, label %if_else_615
if_then_614:
  %t665 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t666 = load i32, i32* %t665
  %t667 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  store i32 %t666, i32* %t667
  br label %if_end_616
if_else_615:
  br label %if_end_616
if_end_616:
  br label %if_end_560
if_else_559:
  br label %if_end_560
if_end_560:
  %t668 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 4
  %t669 = load i1, i1* %t668
  %t670 = xor i1 true, %t669
  br i1 %t670, label %if_then_617, label %if_else_618
if_then_617:
  %t671 = getelementptr i64, i64* null, i32 1
  %t672 = ptrtoint i64* %t671 to i64
  %t673 = load i8*, i8** %t60
  %t674 = icmp eq i8* %t673, null
  br i1 %t674, label %list_cow_alloc_620, label %list_cow_check_621
list_cow_alloc_620:
  %t675 = bitcast void (i8*)* @list_release_symbol to i8*
  %t676 = call i8* @star_rc_alloc(i64 24, i8* %t675)
  %t677 = bitcast i8* %t676 to { i64*, i64, i64 }*
  %t678 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 0
  store i64* null, i64** %t678
  %t679 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 1
  store i64 0, i64* %t679
  %t680 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 2
  store i64 0, i64* %t680
  store i8* %t676, i8** %t60
  br label %list_cow_done_622
list_cow_check_621:
  %t681 = getelementptr inbounds i8, i8* %t673, i64 -16
  %t682 = bitcast i8* %t681 to i64*
  %t683 = load atomic i64, i64* %t682 seq_cst, align 8
  %t684 = icmp eq i64 %t683, 1
  br i1 %t684, label %list_cow_done_622, label %list_cow_clone_623
list_cow_clone_623:
  %t685 = bitcast i8* %t673 to { i64*, i64, i64 }*
  %t686 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t685, i32 0, i32 0
  %t687 = load i64*, i64** %t686
  %t688 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t685, i32 0, i32 1
  %t689 = load i64, i64* %t688
  %t690 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t685, i32 0, i32 2
  %t691 = load i64, i64* %t690
  %t692 = bitcast void (i8*)* @list_release_symbol to i8*
  %t693 = call i8* @star_rc_alloc(i64 24, i8* %t692)
  %t694 = bitcast i8* %t693 to { i64*, i64, i64 }*
  %t695 = mul i64 %t691, %t672
  %t696 = call i8* @malloc(i64 %t695)
  %t697 = bitcast i8* %t696 to i64*
  %t698 = icmp sgt i64 %t689, 0
  br i1 %t698, label %list_cow_copy_624, label %list_cow_after_copy_625
list_cow_copy_624:
  %t699 = mul i64 %t689, %t672
  %t700 = bitcast i64* %t687 to i8*
  call i8* @memcpy(i8* %t696, i8* %t700, i64 %t699)
  br label %list_cow_after_copy_625
list_cow_after_copy_625:
  %t701 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t694, i32 0, i32 0
  store i64* %t697, i64** %t701
  %t702 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t694, i32 0, i32 1
  store i64 %t689, i64* %t702
  %t703 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t694, i32 0, i32 2
  store i64 %t691, i64* %t703
  call void @star_rc_release(i8* %t673)
  store i8* %t693, i8** %t60
  br label %list_cow_done_622
list_cow_done_622:
  %t704 = load i8*, i8** %t60
  %t705 = bitcast i8* %t704 to { i64*, i64, i64 }*
  %t706 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t705, i32 0, i32 0
  %t707 = load i64*, i64** %t706
  %t708 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t705, i32 0, i32 1
  %t709 = load i64, i64* %t708
  %t710 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t705, i32 0, i32 2
  %t711 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.50, i64 0, i32 2, i64 0
  %t712 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t712, i32 -1)
  %t713 = load i64, i64* @sym.len
  %t714 = load i8**, i8*** @sym.data
  store i64 0, i64* %t715
  br label %sym_find_cond_626
sym_find_cond_626:
  %t716 = load i64, i64* %t715
  %t717 = icmp slt i64 %t716, %t713
  br i1 %t717, label %sym_find_body_627, label %sym_find_end_629
sym_find_body_627:
  %t718 = getelementptr inbounds i8*, i8** %t714, i64 %t716
  %t719 = load i8*, i8** %t718
  %t720 = call i32 @strcmp(i8* %t719, i8* %t711)
  %t721 = icmp eq i32 %t720, 0
  br i1 %t721, label %sym_find_end_629, label %sym_find_next_628
sym_find_next_628:
  %t722 = add i64 %t716, 1
  store i64 %t722, i64* %t715
  br label %sym_find_cond_626
sym_find_end_629:
  %t723 = load i64, i64* %t715
  %t724 = icmp slt i64 %t723, %t713
  br i1 %t724, label %sym_found_630, label %sym_notfound_631
sym_found_630:
  call void @star_rc_release(i8* %t711)
  br label %sym_done_632
sym_notfound_631:
  %t725 = load i64, i64* @sym.cap
  %t726 = icmp sge i64 %t713, %t725
  br i1 %t726, label %sym_grow_633, label %sym_store_634
sym_grow_633:
  %t727 = mul i64 %t725, 2
  %t728 = icmp sgt i64 %t727, 0
  %t729 = select i1 %t728, i64 %t727, i64 1
  %t730 = mul i64 %t729, 8
  %t731 = call i8* @malloc(i64 %t730)
  %t732 = bitcast i8* %t731 to i8**
  %t733 = icmp sgt i64 %t725, 0
  br i1 %t733, label %sym_copy_635, label %sym_after_copy_636
sym_copy_635:
  %t734 = mul i64 %t713, 8
  %t735 = bitcast i8** %t714 to i8*
  call i8* @memcpy(i8* %t731, i8* %t735, i64 %t734)
  call void @free(i8* %t735)
  br label %sym_after_copy_636
sym_after_copy_636:
  store i8** %t732, i8*** @sym.data
  store i64 %t729, i64* @sym.cap
  br label %sym_store_634
sym_store_634:
  %t736 = load i8**, i8*** @sym.data
  %t737 = getelementptr inbounds i8*, i8** %t736, i64 %t713
  store i8* %t711, i8** %t737
  %t738 = add i64 %t713, 1
  store i64 %t738, i64* @sym.len
  br label %sym_done_632
sym_done_632:
  %t739 = phi i64 [ %t723, %sym_found_630 ], [ %t713, %sym_store_634 ]
  call i32 @ReleaseSemaphore(i8* %t712, i32 1, i32* null)
  %t740 = load i64, i64* %t710
  %t741 = load i64*, i64** %t706
  %t742 = load i64, i64* %t708
  %t743 = icmp sge i64 %t742, %t740
  br i1 %t743, label %list_push_grow_637, label %list_push_store_638
list_push_grow_637:
  %t744 = mul i64 %t740, 2
  %t745 = icmp sgt i64 %t744, 0
  %t746 = select i1 %t745, i64 %t744, i64 1
  %t747 = getelementptr i64, i64* null, i32 1
  %t748 = ptrtoint i64* %t747 to i64
  %t749 = mul i64 %t746, %t748
  %t750 = call i8* @malloc(i64 %t749)
  %t751 = bitcast i8* %t750 to i64*
  %t752 = icmp sgt i64 %t740, 0
  br i1 %t752, label %list_push_copy_639, label %list_push_after_copy_640
list_push_copy_639:
  %t753 = mul i64 %t742, %t748
  %t754 = bitcast i64* %t741 to i8*
  call i8* @memcpy(i8* %t750, i8* %t754, i64 %t753)
  call void @free(i8* %t754)
  br label %list_push_after_copy_640
list_push_after_copy_640:
  store i64* %t751, i64** %t706
  store i64 %t746, i64* %t710
  br label %list_push_store_638
list_push_store_638:
  %t755 = load i64*, i64** %t706
  %t756 = getelementptr inbounds i64, i64* %t755, i64 %t742
  store i64 %t739, i64* %t756
  %t757 = add i64 %t742, 1
  store i64 %t757, i64* %t708
  %t758 = load i8*, i8** %t60
  %t759 = icmp eq i8* %t758, null
  br i1 %t759, label %list_read_null_641, label %list_read_real_642
list_read_null_641:
  br label %list_read_end_643
list_read_real_642:
  %t760 = bitcast i8* %t758 to { i64*, i64, i64 }*
  %t761 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t760, i32 0, i32 0
  %t762 = load i64*, i64** %t761
  %t763 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t760, i32 0, i32 1
  %t764 = load i64, i64* %t763
  br label %list_read_end_643
list_read_end_643:
  %t765 = phi i64* [ null, %list_read_null_641 ], [ %t762, %list_read_real_642 ]
  %t766 = phi i64 [ 0, %list_read_null_641 ], [ %t764, %list_read_real_642 ]
  %t767 = load i8*, i8** %t60
  %t768 = icmp eq i8* %t767, null
  br i1 %t768, label %list_read_null_644, label %list_read_real_645
list_read_null_644:
  br label %list_read_end_646
list_read_real_645:
  %t769 = bitcast i8* %t767 to { i64*, i64, i64 }*
  %t770 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t769, i32 0, i32 0
  %t771 = load i64*, i64** %t770
  %t772 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t769, i32 0, i32 1
  %t773 = load i64, i64* %t772
  br label %list_read_end_646
list_read_end_646:
  %t774 = phi i64* [ null, %list_read_null_644 ], [ %t771, %list_read_real_645 ]
  %t775 = phi i64 [ 0, %list_read_null_644 ], [ %t773, %list_read_real_645 ]
  %t776 = trunc i64 %t775 to i32
  %t777 = sub i32 %t776, 1
  %t778 = sext i32 %t777 to i64
  %t779 = icmp ult i64 %t778, %t766
  br i1 %t779, label %list_idx_ok_647, label %list_idx_oob_648
list_idx_ok_647:
  %t780 = getelementptr inbounds i64, i64* %t765, i64 %t778
  %t781 = load i64, i64* %t780
  br label %list_idx_end_649
list_idx_oob_648:
  br label %list_idx_end_649
list_idx_end_649:
  %t782 = phi i64 [ %t781, %list_idx_ok_647 ], [ 0, %list_idx_oob_648 ]
  %t783 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t783, i32 -1)
  %t784 = load i64, i64* @sym.len
  %t785 = icmp sge i64 %t782, 0
  %t786 = icmp slt i64 %t782, %t784
  %t787 = and i1 %t785, %t786
  br i1 %t787, label %sym_name_ok_650, label %sym_name_oob_651
sym_name_ok_650:
  %t788 = load i8**, i8*** @sym.data
  %t789 = getelementptr inbounds i8*, i8** %t788, i64 %t782
  %t790 = load i8*, i8** %t789
  call void @star_rc_retain(i8* %t790)
  br label %sym_name_end_652
sym_name_oob_651:
  %t791 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t791
  br label %sym_name_end_652
sym_name_end_652:
  %t792 = phi i8* [ %t790, %sym_name_ok_650 ], [ %t791, %sym_name_oob_651 ]
  call i32 @ReleaseSemaphore(i8* %t783, i32 1, i32* null)
  call void @star_rc_release(i8* %t792)
  %t793 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t793, i8* %t792)
  %t794 = load i8*, i8** %t27
  %t795 = load i8*, i8** %t27
  call void @star_rc_retain(i8* %t795)
  %t796 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t797 = load i32, i32* %t796
  %t798 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.52, i64 0, i32 2, i64 0
  %t799 = call i1 @save__save_high_score(i8* %t794, i32 %t797, i8* %t798)
  store i32 4, i32* %t800
  br label %while_cond_653
while_cond_653:
  %t801 = load i32, i32* %t800
  %t802 = icmp sge i32 %t801, 0
  br i1 %t802, label %while_body_654, label %while_else_655
while_body_654:
  %t803 = load i32, i32* %t800
  %t804 = icmp eq i32 %t803, 0
  br i1 %t804, label %logic_short_658, label %logic_rhs_657
logic_rhs_657:
  %t805 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t806 = load i32, i32* %t805
  %t807 = load i32, i32* %t800
  %t808 = sub i32 %t807, 1
  %t809 = sext i32 %t808 to i64
  %t810 = icmp ult i64 %t809, 5
  br i1 %t810, label %arr_rplace_ok_660, label %arr_rplace_oob_661
arr_rplace_ok_660:
  %t811 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t809
  br label %arr_rplace_end_662
arr_rplace_oob_661:
  store i32 0, i32* %t812
  br label %arr_rplace_end_662
arr_rplace_end_662:
  %t813 = phi i32* [ %t811, %arr_rplace_ok_660 ], [ %t812, %arr_rplace_oob_661 ]
  %t814 = load i32, i32* %t813
  %t815 = icmp sle i32 %t806, %t814
  br label %logic_end_659
logic_short_658:
  br label %logic_end_659
logic_end_659:
  %t816 = phi i1 [ %t815, %arr_rplace_end_662 ], [ true, %logic_short_658 ]
  br i1 %t816, label %if_then_663, label %if_else_664
if_then_663:
  %t817 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t818 = load i32, i32* %t817
  %t819 = load i32, i32* %t800
  %t820 = sext i32 %t819 to i64
  %t821 = icmp ult i64 %t820, 5
  br i1 %t821, label %arr_set_do_666, label %arr_set_oob_667
arr_set_do_666:
  %t822 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t820
  store i32 %t818, i32* %t822
  br label %arr_set_end_668
arr_set_oob_667:
  br label %arr_set_end_668
arr_set_end_668:
  br label %while_end_656
if_else_664:
  br label %if_end_665
if_end_665:
  %t823 = load i32, i32* %t800
  %t824 = sub i32 %t823, 1
  %t825 = sext i32 %t824 to i64
  %t826 = icmp ult i64 %t825, 5
  br i1 %t826, label %arr_rplace_ok_669, label %arr_rplace_oob_670
arr_rplace_ok_669:
  %t827 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t825
  br label %arr_rplace_end_671
arr_rplace_oob_670:
  store i32 0, i32* %t828
  br label %arr_rplace_end_671
arr_rplace_end_671:
  %t829 = phi i32* [ %t827, %arr_rplace_ok_669 ], [ %t828, %arr_rplace_oob_670 ]
  %t830 = load i32, i32* %t829
  %t831 = load i32, i32* %t800
  %t832 = sext i32 %t831 to i64
  %t833 = icmp ult i64 %t832, 5
  br i1 %t833, label %arr_set_do_672, label %arr_set_oob_673
arr_set_do_672:
  %t834 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t832
  store i32 %t830, i32* %t834
  br label %arr_set_end_674
arr_set_oob_673:
  br label %arr_set_end_674
arr_set_end_674:
  %t835 = load i32, i32* %t800
  %t836 = sub i32 %t835, 1
  store i32 %t836, i32* %t800
  br label %while_cond_653
while_else_655:
  br label %while_end_656
while_end_656:
  %t837 = sext i32 0 to i64
  %t838 = icmp ult i64 %t837, 5
  br i1 %t838, label %arr_rplace_ok_675, label %arr_rplace_oob_676
arr_rplace_ok_675:
  %t839 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t837
  br label %arr_rplace_end_677
arr_rplace_oob_676:
  store i32 0, i32* %t840
  br label %arr_rplace_end_677
arr_rplace_end_677:
  %t841 = phi i32* [ %t839, %arr_rplace_ok_675 ], [ %t840, %arr_rplace_oob_676 ]
  %t842 = load i32, i32* %t841
  %t843 = sext i32 1 to i64
  %t844 = icmp ult i64 %t843, 5
  br i1 %t844, label %arr_rplace_ok_678, label %arr_rplace_oob_679
arr_rplace_ok_678:
  %t845 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t843
  br label %arr_rplace_end_680
arr_rplace_oob_679:
  store i32 0, i32* %t846
  br label %arr_rplace_end_680
arr_rplace_end_680:
  %t847 = phi i32* [ %t845, %arr_rplace_ok_678 ], [ %t846, %arr_rplace_oob_679 ]
  %t848 = load i32, i32* %t847
  %t849 = sext i32 2 to i64
  %t850 = icmp ult i64 %t849, 5
  br i1 %t850, label %arr_rplace_ok_681, label %arr_rplace_oob_682
arr_rplace_ok_681:
  %t851 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t849
  br label %arr_rplace_end_683
arr_rplace_oob_682:
  store i32 0, i32* %t852
  br label %arr_rplace_end_683
arr_rplace_end_683:
  %t853 = phi i32* [ %t851, %arr_rplace_ok_681 ], [ %t852, %arr_rplace_oob_682 ]
  %t854 = load i32, i32* %t853
  %t855 = sext i32 3 to i64
  %t856 = icmp ult i64 %t855, 5
  br i1 %t856, label %arr_rplace_ok_684, label %arr_rplace_oob_685
arr_rplace_ok_684:
  %t857 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t855
  br label %arr_rplace_end_686
arr_rplace_oob_685:
  store i32 0, i32* %t858
  br label %arr_rplace_end_686
arr_rplace_end_686:
  %t859 = phi i32* [ %t857, %arr_rplace_ok_684 ], [ %t858, %arr_rplace_oob_685 ]
  %t860 = load i32, i32* %t859
  %t861 = sext i32 4 to i64
  %t862 = icmp ult i64 %t861, 5
  br i1 %t862, label %arr_rplace_ok_687, label %arr_rplace_oob_688
arr_rplace_ok_687:
  %t863 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t861
  br label %arr_rplace_end_689
arr_rplace_oob_688:
  store i32 0, i32* %t864
  br label %arr_rplace_end_689
arr_rplace_end_689:
  %t865 = phi i32* [ %t863, %arr_rplace_ok_687 ], [ %t864, %arr_rplace_oob_688 ]
  %t866 = load i32, i32* %t865
  %t867 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.53, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t867, i32 %t842, i32 %t848, i32 %t854, i32 %t860, i32 %t866)
  %t870 = load i8*, i8** %t10
  %t871 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t869, i32 0, i32 0
  store i8* %t870, i8** %t871
  %t872 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t869, i32 0, i32 1
  store i32 0, i32* %t872
  %t873 = load %GameOverFlash, %GameOverFlash* %t869
  store %GameOverFlash %t873, %GameOverFlash* %t868
  store i1 true, i1* %t874
  br label %while_cond_690
while_cond_690:
  %t875 = load i1, i1* %t874
  br i1 %t875, label %while_body_691, label %while_else_692
while_body_691:
  %t876 = call i1 @GameOverFlash__resume(%GameOverFlash* %t868)
  store i1 %t876, i1* %t874
  br label %while_cond_690
while_else_692:
  br label %while_end_693
while_end_693:
  br label %if_end_619
if_else_618:
  br label %if_end_619
if_end_619:
  br label %if_end_533
if_else_532:
  br label %if_end_533
if_end_533:
  br label %if_end_472
if_end_472:
  %t877 = load i8, i8* %t61
  %t878 = trunc i32 1 to i8
  %t879 = add i8 %t877, %t878
  store i8 %t879, i8* %t61
  %t881 = load i8, i8* %t61
  %t882 = uitofp i8 %t881 to float
  store float %t882, float* %t880
  %t884 = load float, float* %t880
  %t885 = fmul float %t884, 0x3FC3333340000000
  %t886 = call float @llvm.sin.f32(float %t885)
  %t887 = fmul float %t886, 0x4000000000000000
  store float %t887, float* %t883
  %t888 = load i8*, i8** %t10
  %t889 = icmp eq i8* %t888, null
  br i1 %t889, label %sdl_null_window_694, label %sdl_window_handle_ok_695
sdl_null_window_694:
  %t890 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.54, i64 0, i64 0
  call i32 @puts(i8* %t890)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_695:
  %t891 = call i8* @SDL_GetRenderer(i8* %t888)
  %t892 = and i32 18, 255
  %t893 = and i32 18, 255
  %t894 = shl i32 %t893, 8
  %t895 = or i32 %t892, %t894
  %t896 = and i32 24, 255
  %t897 = shl i32 %t896, 16
  %t898 = or i32 %t895, %t897
  %t899 = and i32 255, 255
  %t900 = shl i32 %t899, 24
  %t901 = or i32 %t898, %t900
  %t902 = and i32 %t901, 255
  %t903 = trunc i32 %t902 to i8
  %t904 = lshr i32 %t901, 8
  %t905 = and i32 %t904, 255
  %t906 = trunc i32 %t905 to i8
  %t907 = lshr i32 %t901, 16
  %t908 = and i32 %t907, 255
  %t909 = trunc i32 %t908 to i8
  %t910 = lshr i32 %t901, 24
  %t911 = and i32 %t910, 255
  %t912 = trunc i32 %t911 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t891, i8 %t903, i8 %t906, i8 %t909, i8 %t912)
  call i32 @SDL_RenderClear(i8* %t891)
  %t914 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t53
  %t915 = call { i32, i32 } @cell_px(%food__sb__grid__Cell %t914)
  store { i32, i32 } %t915, { i32, i32 }* %t913
  %t917 = load float, float* %t883
  %t918 = call i32 @llvm.fptosi.sat.i32.f32(float %t917)
  store i32 %t918, i32* %t916
  %t919 = load i8*, i8** %t10
  %t920 = icmp eq i8* %t919, null
  br i1 %t920, label %sdl_null_window_696, label %sdl_window_handle_ok_697
sdl_null_window_696:
  %t921 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.55, i64 0, i64 0
  call i32 @puts(i8* %t921)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_697:
  %t922 = call i8* @SDL_GetRenderer(i8* %t919)
  %t923 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t913, i32 0, i32 0
  %t924 = load i32, i32* %t923
  %t925 = load i32, i32* %t916
  %t926 = sub i32 %t924, %t925
  %t927 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t913, i32 0, i32 1
  %t928 = load i32, i32* %t927
  %t929 = load i32, i32* %t916
  %t930 = sub i32 %t928, %t929
  %t931 = call i32 @food__sb__grid__cell_size()
  %t932 = sub i32 %t931, 1
  %t933 = load i32, i32* %t916
  %t934 = mul i32 %t933, 2
  %t935 = add i32 %t932, %t934
  %t936 = call i32 @food__sb__grid__cell_size()
  %t937 = sub i32 %t936, 1
  %t938 = load i32, i32* %t916
  %t939 = mul i32 %t938, 2
  %t940 = add i32 %t937, %t939
  %t941 = and i32 230, 255
  %t942 = and i32 90, 255
  %t943 = shl i32 %t942, 8
  %t944 = or i32 %t941, %t943
  %t945 = and i32 90, 255
  %t946 = shl i32 %t945, 16
  %t947 = or i32 %t944, %t946
  %t948 = and i32 255, 255
  %t949 = shl i32 %t948, 24
  %t950 = or i32 %t947, %t949
  %t951 = and i32 %t950, 255
  %t952 = trunc i32 %t951 to i8
  %t953 = lshr i32 %t950, 8
  %t954 = and i32 %t953, 255
  %t955 = trunc i32 %t954 to i8
  %t956 = lshr i32 %t950, 16
  %t957 = and i32 %t956, 255
  %t958 = trunc i32 %t957 to i8
  %t959 = lshr i32 %t950, 24
  %t960 = and i32 %t959, 255
  %t961 = trunc i32 %t960 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t922, i8 %t952, i8 %t955, i8 %t958, i8 %t961)
  %t963 = getelementptr inbounds [16 x i8], [16 x i8]* %t962, i64 0, i64 0
  %t964 = bitcast i8* %t963 to i32*
  store i32 %t926, i32* %t964
  %t965 = getelementptr inbounds i8, i8* %t963, i64 4
  %t966 = bitcast i8* %t965 to i32*
  store i32 %t930, i32* %t966
  %t967 = getelementptr inbounds i8, i8* %t963, i64 8
  %t968 = bitcast i8* %t967 to i32*
  store i32 %t935, i32* %t968
  %t969 = getelementptr inbounds i8, i8* %t963, i64 12
  %t970 = bitcast i8* %t969 to i32*
  store i32 %t940, i32* %t970
  call i32 @SDL_RenderFillRect(i8* %t922, i8* %t963)
  store i32 0, i32* %t971
  br label %while_cond_698
while_cond_698:
  %t972 = load i32, i32* %t971
  %t973 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t974 = icmp slt i32 %t972, %t973
  br i1 %t974, label %while_body_699, label %while_else_700
while_body_699:
  %t976 = load i32, i32* %t971
  %t977 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t978 = sub i32 %t977, 1
  %t979 = icmp eq i32 %t976, %t978
  store i1 %t979, i1* %t975
  %t980 = load i8*, i8** %t10
  %t981 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 0
  %t982 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t981, i32 0, i32 0
  %t983 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t981, i32 0, i32 1
  %t984 = load i64, i64* %t983
  %t985 = getelementptr inbounds { [768 x %food__sb__grid__Cell], i64, i64 }, { [768 x %food__sb__grid__Cell], i64, i64 }* %t981, i32 0, i32 2
  %t986 = load i64, i64* %t985
  %t987 = load i32, i32* %t971
  %t988 = sext i32 %t987 to i64
  %t989 = load i64, i64* %t983
  %t990 = load i64, i64* %t985
  %t991 = icmp ult i64 %t988, %t990
  br i1 %t991, label %ring_rplace_ok_702, label %ring_rplace_oob_703
ring_rplace_ok_702:
  %t992 = add i64 %t989, %t988
  %t993 = urem i64 %t992, 768
  %t994 = getelementptr inbounds [768 x %food__sb__grid__Cell], [768 x %food__sb__grid__Cell]* %t982, i32 0, i64 %t993
  br label %ring_rplace_end_704
ring_rplace_oob_703:
  store %food__sb__grid__Cell zeroinitializer, %food__sb__grid__Cell* %t995
  br label %ring_rplace_end_704
ring_rplace_end_704:
  %t996 = phi %food__sb__grid__Cell* [ %t994, %ring_rplace_ok_702 ], [ %t995, %ring_rplace_oob_703 ]
  %t997 = load %food__sb__grid__Cell, %food__sb__grid__Cell* %t996
  %t998 = load i1, i1* %t975
  %t999 = and i32 140, 255
  %t1000 = and i32 230, 255
  %t1001 = shl i32 %t1000, 8
  %t1002 = or i32 %t999, %t1001
  %t1003 = and i32 160, 255
  %t1004 = shl i32 %t1003, 16
  %t1005 = or i32 %t1002, %t1004
  %t1006 = and i32 255, 255
  %t1007 = shl i32 %t1006, 24
  %t1008 = or i32 %t1005, %t1007
  %t1009 = and i32 80, 255
  %t1010 = and i32 190, 255
  %t1011 = shl i32 %t1010, 8
  %t1012 = or i32 %t1009, %t1011
  %t1013 = and i32 120, 255
  %t1014 = shl i32 %t1013, 16
  %t1015 = or i32 %t1012, %t1014
  %t1016 = and i32 255, 255
  %t1017 = shl i32 %t1016, 24
  %t1018 = or i32 %t1015, %t1017
  %t1019 = call i32 @pick_color(i1 %t998, i32 %t1008, i32 %t1018)
  call void @draw_cell(i8* %t980, %food__sb__grid__Cell %t997, i32 %t1019)
  %t1020 = load i32, i32* %t971
  %t1021 = add i32 %t1020, 1
  store i32 %t1021, i32* %t971
  br label %while_cond_698
while_else_700:
  br label %while_end_701
while_end_701:
  call void @ParticlePool__update(%ParticlePool* %t72, float 0x3F90624DE0000000)
  %t1023 = load i8*, i8** %t10
  call void @ParticlePool__draw(%ParticlePool* %t72, i8* %t1023)
  call void @tick_particle_arena(float 0x3F90624DE0000000)
  call void @reclaim_dead_particles()
  %t1025 = load i64, i64* %t58
  %t1026 = zext i32 1 to i64
  %t1027 = shl i64 1, %t1026
  %t1028 = and i64 %t1025, %t1027
  %t1029 = icmp ne i64 %t1028, 0
  br i1 %t1029, label %if_then_705, label %if_else_706
if_then_705:
  %t1030 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t1031 = load i32, i32* %t1030
  %t1032 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t1033 = load i32, i32* %t1032
  %t1034 = call i32 @food__sb__Snake__length(%food__sb__Snake* %t51)
  %t1035 = load i64, i64* %t58
  %t1036 = zext i32 0 to i64
  %t1037 = shl i64 1, %t1036
  %t1038 = and i64 %t1035, %t1037
  %t1039 = icmp ne i64 %t1038, 0
  %t1040 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t1041 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t1042 = select i1 %t1039, i8* %t1040, i8* %t1041
  %t1043 = getelementptr inbounds %food__sb__Snake, %food__sb__Snake* %t51, i32 0, i32 1
  %t1044 = load i32, i32* %t1043
  %t1045 = call i8* @food__sb__grid__dir_name(i32 %t1044)
  call void @star_rc_release(i8* %t1045)
  %t1046 = load i1, i1* %t96
  %t1047 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.58, i64 0, i64 0
  %t1048 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.59, i64 0, i64 0
  %t1049 = select i1 %t1046, i8* %t1047, i8* %t1048
  %t1050 = getelementptr inbounds [59 x i8], [59 x i8]* @.str.60, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1050, i32 %t1031, i32 %t1033, i32 %t1034, i8* %t1042, i8* %t1045, i8* %t1049)
  br label %if_end_707
if_else_706:
  br label %if_end_707
if_end_707:
  %t1051 = load i8*, i8** %t10
  %t1052 = icmp eq i8* %t1051, null
  br i1 %t1052, label %sdl_null_window_708, label %sdl_window_handle_ok_709
sdl_null_window_708:
  %t1053 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.61, i64 0, i64 0
  call i32 @puts(i8* %t1053)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_709:
  %t1054 = call i8* @SDL_GetRenderer(i8* %t1051)
  call void @SDL_RenderPresent(i8* %t1054)
  %t1055 = icmp slt i32 16, 0
  %t1056 = select i1 %t1055, i32 0, i32 16
  call void @SDL_Delay(i32 %t1056)
  br label %while_cond_430
while_else_432:
  br label %while_end_433
while_end_433:
  %t1057 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 0
  %t1058 = load i32, i32* %t1057
  %t1059 = getelementptr inbounds %Stats, %Stats* %t33, i32 0, i32 1
  %t1060 = load i32, i32* %t1059
  %t1061 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.62, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1061, i32 %t1058, i32 %t1060)
  %t1062 = load i8, i8* %t59
  %t1063 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.63, i64 0, i64 0
  %t1064 = zext i8 %t1062 to i32
  call i32 (i8*, ...) @printf(i8* %t1063, i32 %t1064)
  %t1065 = load i8*, i8** %t10
  %t1066 = icmp eq i8* %t1065, null
  br i1 %t1066, label %sdl_null_window_710, label %sdl_window_handle_ok_711
sdl_null_window_710:
  %t1067 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.64, i64 0, i64 0
  call i32 @puts(i8* %t1067)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_711:
  %t1068 = call i8* @SDL_GetRenderer(i8* %t1065)
  call void @SDL_DestroyRenderer(i8* %t1068)
  call void @SDL_DestroyWindow(i8* %t1065)
  store i8* null, i8** %t10
  %t1069 = load i8*, i8** %t60
  call void @star_rc_release(i8* %t1069)
  %t1070 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t29, i32 0, i32 1
  %t1071 = load i8*, i8** %t1070
  call void @star_rc_release(i8* %t1071)
  %t1072 = load i8*, i8** %t27
  call void @star_rc_release(i8* %t1072)
  ret i32 0
}


; par/swarm worker functions
define void @set_release_s_food__sb__grid__Cell(i8* %objp) {
entry:
  %t11 = bitcast i8* %objp to { %food__sb__grid__Cell*, i64, i64 }*
  %t12 = getelementptr inbounds { %food__sb__grid__Cell*, i64, i64 }, { %food__sb__grid__Cell*, i64, i64 }* %t11, i32 0, i32 0
  %t13 = load %food__sb__grid__Cell*, %food__sb__grid__Cell** %t12
  %t14 = bitcast %food__sb__grid__Cell* %t13 to i8*
  call void @free(i8* %t14)
  ret void
}


define i1 @eq_s_food__sb__grid__Cell(%food__sb__grid__Cell %a, %food__sb__grid__Cell %b) {
entry:
  %t69 = extractvalue %food__sb__grid__Cell %a, 0
  %t70 = extractvalue %food__sb__grid__Cell %b, 0
  %t71 = icmp eq i32 %t69, %t70
  %t72 = extractvalue %food__sb__grid__Cell %a, 1
  %t73 = extractvalue %food__sb__grid__Cell %b, 1
  %t74 = icmp eq i32 %t72, %t73
  %t75 = and i1 %t71, %t74
  ret i1 %t75
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
  br label %list_release_cond_207
list_release_cond_207:
  %t179 = load i64, i64* %t178
  %t180 = icmp slt i64 %t179, %t177
  br i1 %t180, label %list_release_body_208, label %list_release_end_209
list_release_body_208:
  %t181 = getelementptr inbounds i8*, i8** %t175, i64 %t179
  %t182 = load i8*, i8** %t181
  call void @star_rc_release(i8* %t182)
  %t183 = add i64 %t179, 1
  store i64 %t183, i64* %t178
  br label %list_release_cond_207
list_release_end_209:
  %t184 = bitcast i8** %t175 to i8*
  call void @free(i8* %t184)
  ret void
}


define i32 @par_worker_305(i8* %argp) {
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
  br label %par_cond_306
par_cond_306:
  %t10 = load i64, i64* %t9
  %t11 = icmp slt i64 %t10, %t5
  br i1 %t11, label %par_body_307, label %par_end_310
par_body_307:
  %t12 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t10
  %t13 = load i64, i64* %t12
  %t14 = and i64 %t13, 1
  %t15 = icmp eq i64 %t14, 1
  br i1 %t15, label %par_live_308, label %par_incr_309
par_live_308:
  %t16 = getelementptr inbounds %Particle, %Particle* %t8, i64 %t10
  %t17 = load float, float* %t7
  %t18 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 4
  %t19 = load float, float* %t18
  %t20 = fsub float %t19, %t17
  %t21 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 4
  store float %t20, float* %t21
  br label %par_incr_309
par_incr_309:
  %t22 = add i64 %t10, 1
  store i64 %t22, i64* %t9
  br label %par_cond_306
par_end_310:
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


define i32 @par_worker_328(i8* %argp) {
entry:
  %t8 = alloca i64
  %t2 = bitcast i8* %argp to { i64, i64 }*
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 0
  %t4 = load i64, i64* %t3
  %t5 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 1
  %t6 = load i64, i64* %t5
  %t7 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t4, i64* %t8
  br label %par_cond_329
par_cond_329:
  %t9 = load i64, i64* %t8
  %t10 = icmp slt i64 %t9, %t6
  br i1 %t10, label %par_body_330, label %par_end_333
par_body_330:
  %t11 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t9
  %t12 = load i64, i64* %t11
  %t13 = and i64 %t12, 1
  %t14 = icmp eq i64 %t13, 1
  br i1 %t14, label %par_live_331, label %par_incr_332
par_live_331:
  %t15 = getelementptr inbounds %Particle, %Particle* %t7, i64 %t9
  %t16 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 4
  %t17 = load float, float* %t16
  %t18 = fcmp ogt float %t17, 0x0000000000000000
  br i1 %t18, label %if_then_334, label %if_else_335
if_then_334:
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
  br label %if_end_336
if_else_335:
  br label %if_end_336
if_end_336:
  br label %par_incr_332
par_incr_332:
  %t29 = add i64 %t9, 1
  store i64 %t29, i64* %t8
  br label %par_cond_329
par_end_333:
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
