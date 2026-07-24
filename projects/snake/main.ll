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

%grid__Cell = type { i32, i32 }
%sb__Snake = type { { [768 x %grid__Cell], i64, i64 }, i32, i32, i32, i1 }
declare i32 @toupper(i32)
declare i32 @atoi(i8*)
%Particle = type { float, float, float, float, float }
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

%Stats = type { i32, i32 }
declare double @atof(i8*)
%Tuning = type { i32, float, float, i1 }
%FlashOnEat = type { i8*, i32 }
%GameOverFlash = type { i8*, i32 }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define %grid__Cell @grid__delta(i32 %d) {
entry:
  %t0 = alloca i32
  %t7 = alloca %grid__Cell
  %t15 = alloca %grid__Cell
  %t22 = alloca %grid__Cell
  %t30 = alloca %grid__Cell
  store i32 %d, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t6 = icmp eq i32 %t1, 0
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  %t8 = getelementptr inbounds %grid__Cell, %grid__Cell* %t7, i32 0, i32 0
  store i32 0, i32* %t8
  %t9 = sub i32 0, 1
  %t10 = getelementptr inbounds %grid__Cell, %grid__Cell* %t7, i32 0, i32 1
  store i32 %t9, i32* %t10
  %t11 = load %grid__Cell, %grid__Cell* %t7
  br label %match_end_2
match_next_0_5:
  %t14 = icmp eq i32 %t1, 1
  br i1 %t14, label %match_then_1_12, label %match_next_1_13
match_then_1_12:
  %t16 = getelementptr inbounds %grid__Cell, %grid__Cell* %t15, i32 0, i32 0
  store i32 0, i32* %t16
  %t17 = getelementptr inbounds %grid__Cell, %grid__Cell* %t15, i32 0, i32 1
  store i32 1, i32* %t17
  %t18 = load %grid__Cell, %grid__Cell* %t15
  br label %match_end_2
match_next_1_13:
  %t21 = icmp eq i32 %t1, 2
  br i1 %t21, label %match_then_2_19, label %match_next_2_20
match_then_2_19:
  %t23 = sub i32 0, 1
  %t24 = getelementptr inbounds %grid__Cell, %grid__Cell* %t22, i32 0, i32 0
  store i32 %t23, i32* %t24
  %t25 = getelementptr inbounds %grid__Cell, %grid__Cell* %t22, i32 0, i32 1
  store i32 0, i32* %t25
  %t26 = load %grid__Cell, %grid__Cell* %t22
  br label %match_end_2
match_next_2_20:
  %t29 = icmp eq i32 %t1, 3
  br i1 %t29, label %match_then_3_27, label %match_next_3_28
match_then_3_27:
  %t31 = getelementptr inbounds %grid__Cell, %grid__Cell* %t30, i32 0, i32 0
  store i32 1, i32* %t31
  %t32 = getelementptr inbounds %grid__Cell, %grid__Cell* %t30, i32 0, i32 1
  store i32 0, i32* %t32
  %t33 = load %grid__Cell, %grid__Cell* %t30
  br label %match_end_2
match_next_3_28:
  br label %match_end_2
match_end_2:
  %t34 = phi %grid__Cell [ %t11, %match_then_0_4 ], [ %t18, %match_then_1_12 ], [ %t26, %match_then_2_19 ], [ %t33, %match_then_3_27 ], [ undef, %match_next_3_28 ]
  ret %grid__Cell %t34
}

define i32 @grid__opposite(i32 %d) {
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

define %grid__Cell @grid__wrap(%grid__Cell %c) {
entry:
  %t0 = alloca %grid__Cell
  %t1 = alloca i32
  %t4 = alloca i32
  %t17 = alloca %grid__Cell
  store %grid__Cell %c, %grid__Cell* %t0
  %t2 = getelementptr inbounds %grid__Cell, %grid__Cell* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  store i32 %t3, i32* %t1
  %t5 = getelementptr inbounds %grid__Cell, %grid__Cell* %t0, i32 0, i32 1
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
  %t19 = getelementptr inbounds %grid__Cell, %grid__Cell* %t17, i32 0, i32 0
  store i32 %t18, i32* %t19
  %t20 = load i32, i32* %t4
  %t21 = getelementptr inbounds %grid__Cell, %grid__Cell* %t17, i32 0, i32 1
  store i32 %t20, i32* %t21
  %t22 = load %grid__Cell, %grid__Cell* %t17
  ret %grid__Cell %t22
}

define %grid__Cell @grid__cell_add(%grid__Cell %a, %grid__Cell %b) {
entry:
  %t0 = alloca %grid__Cell
  %t1 = alloca %grid__Cell
  %t2 = alloca %grid__Cell
  store %grid__Cell %a, %grid__Cell* %t0
  store %grid__Cell %b, %grid__Cell* %t1
  %t3 = getelementptr inbounds %grid__Cell, %grid__Cell* %t0, i32 0, i32 0
  %t4 = load i32, i32* %t3
  %t5 = getelementptr inbounds %grid__Cell, %grid__Cell* %t1, i32 0, i32 0
  %t6 = load i32, i32* %t5
  %t7 = add i32 %t4, %t6
  %t8 = getelementptr inbounds %grid__Cell, %grid__Cell* %t2, i32 0, i32 0
  store i32 %t7, i32* %t8
  %t9 = getelementptr inbounds %grid__Cell, %grid__Cell* %t0, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = getelementptr inbounds %grid__Cell, %grid__Cell* %t1, i32 0, i32 1
  %t12 = load i32, i32* %t11
  %t13 = add i32 %t10, %t12
  %t14 = getelementptr inbounds %grid__Cell, %grid__Cell* %t2, i32 0, i32 1
  store i32 %t13, i32* %t14
  %t15 = load %grid__Cell, %grid__Cell* %t2
  ret %grid__Cell %t15
}

define %grid__Cell @sb__Snake__head(%sb__Snake* %self) {
entry:
  %t0 = alloca %sb__Snake*
  %t24 = alloca %grid__Cell
  store %sb__Snake* %self, %sb__Snake** %t0
  %t1 = load %sb__Snake*, %sb__Snake** %t0
  %t2 = getelementptr inbounds %sb__Snake, %sb__Snake* %t1, i32 0, i32 0
  %t3 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t2, i32 0, i32 0
  %t4 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t2, i32 0, i32 1
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t2, i32 0, i32 2
  %t7 = load i64, i64* %t6
  %t8 = load %sb__Snake*, %sb__Snake** %t0
  %t9 = getelementptr inbounds %sb__Snake, %sb__Snake* %t8, i32 0, i32 0
  %t10 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t9, i32 0, i32 0
  %t11 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t9, i32 0, i32 1
  %t12 = load i64, i64* %t11
  %t13 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t9, i32 0, i32 2
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
  %t23 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t3, i32 0, i64 %t22
  br label %ring_rplace_end_14
ring_rplace_oob_13:
  store %grid__Cell zeroinitializer, %grid__Cell* %t24
  br label %ring_rplace_end_14
ring_rplace_end_14:
  %t25 = phi %grid__Cell* [ %t23, %ring_rplace_ok_12 ], [ %t24, %ring_rplace_oob_13 ]
  %t26 = load %grid__Cell, %grid__Cell* %t25
  ret %grid__Cell %t26
}

define i32 @sb__Snake__length(%sb__Snake* %self) {
entry:
  %t0 = alloca %sb__Snake*
  store %sb__Snake* %self, %sb__Snake** %t0
  %t1 = load %sb__Snake*, %sb__Snake** %t0
  %t2 = getelementptr inbounds %sb__Snake, %sb__Snake* %t1, i32 0, i32 0
  %t3 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t2, i32 0, i32 0
  %t4 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t2, i32 0, i32 1
  %t5 = load i64, i64* %t4
  %t6 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t2, i32 0, i32 2
  %t7 = load i64, i64* %t6
  %t8 = trunc i64 %t7 to i32
  ret i32 %t8
}

define i1 @sb__Snake__contains(%sb__Snake* %self, %grid__Cell %c) {
entry:
  %t0 = alloca %sb__Snake*
  %t1 = alloca %grid__Cell
  %t2 = alloca i32
  %t3 = alloca i1
  %t29 = alloca %grid__Cell
  store %sb__Snake* %self, %sb__Snake** %t0
  store %grid__Cell %c, %grid__Cell* %t1
  store i32 0, i32* %t2
  store i1 false, i1* %t3
  br label %while_cond_15
while_cond_15:
  %t4 = load i32, i32* %t2
  %t5 = load %sb__Snake*, %sb__Snake** %t0
  %t6 = getelementptr inbounds %sb__Snake, %sb__Snake* %t5, i32 0, i32 0
  %t7 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t6, i32 0, i32 0
  %t8 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t6, i32 0, i32 1
  %t9 = load i64, i64* %t8
  %t10 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t6, i32 0, i32 2
  %t11 = load i64, i64* %t10
  %t12 = trunc i64 %t11 to i32
  %t13 = icmp slt i32 %t4, %t12
  br i1 %t13, label %while_body_16, label %while_else_17
while_body_16:
  %t14 = load %sb__Snake*, %sb__Snake** %t0
  %t15 = getelementptr inbounds %sb__Snake, %sb__Snake* %t14, i32 0, i32 0
  %t16 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t15, i32 0, i32 0
  %t17 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t15, i32 0, i32 1
  %t18 = load i64, i64* %t17
  %t19 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t15, i32 0, i32 2
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
  %t28 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t16, i32 0, i64 %t27
  br label %ring_rplace_end_21
ring_rplace_oob_20:
  store %grid__Cell zeroinitializer, %grid__Cell* %t29
  br label %ring_rplace_end_21
ring_rplace_end_21:
  %t30 = phi %grid__Cell* [ %t28, %ring_rplace_ok_19 ], [ %t29, %ring_rplace_oob_20 ]
  %t31 = load %grid__Cell, %grid__Cell* %t30
  %t32 = load %grid__Cell, %grid__Cell* %t1
  %t40 = call i1 @eq_s_grid__Cell(%grid__Cell %t31, %grid__Cell %t32)
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

define void @sb__Snake__queue_turn(%sb__Snake* %self, i32 %d) {
entry:
  %t0 = alloca %sb__Snake*
  %t1 = alloca i32
  %t2 = alloca i1
  store %sb__Snake* %self, %sb__Snake** %t0
  store i32 %d, i32* %t1
  %t3 = load i32, i32* %t1
  %t4 = load %sb__Snake*, %sb__Snake** %t0
  %t5 = getelementptr inbounds %sb__Snake, %sb__Snake* %t4, i32 0, i32 1
  %t6 = load i32, i32* %t5
  %t7 = call i32 @grid__opposite(i32 %t6)
  %t9 = call i1 @eq_e_grid__Direction(i32 %t3, i32 %t7)
  store i1 %t9, i1* %t2
  %t10 = load i1, i1* %t2
  %t11 = xor i1 true, %t10
  br i1 %t11, label %if_then_25, label %if_else_26
if_then_25:
  %t12 = load i32, i32* %t1
  %t13 = load %sb__Snake*, %sb__Snake** %t0
  %t14 = getelementptr inbounds %sb__Snake, %sb__Snake* %t13, i32 0, i32 2
  store i32 %t12, i32* %t14
  br label %if_end_27
if_else_26:
  br label %if_end_27
if_end_27:
  ret void
}

define void @sb__Snake__grow(%sb__Snake* %self, i32 %amount) {
entry:
  %t0 = alloca %sb__Snake*
  %t1 = alloca i32
  store %sb__Snake* %self, %sb__Snake** %t0
  store i32 %amount, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = load %sb__Snake*, %sb__Snake** %t0
  %t4 = getelementptr inbounds %sb__Snake, %sb__Snake* %t3, i32 0, i32 3
  %t5 = load i32, i32* %t4
  %t6 = add i32 %t5, %t2
  %t7 = load %sb__Snake*, %sb__Snake** %t0
  %t8 = getelementptr inbounds %sb__Snake, %sb__Snake* %t7, i32 0, i32 3
  store i32 %t6, i32* %t8
  ret void
}

define %grid__Cell @sb__Snake__advance(%sb__Snake* %self) {
entry:
  %t0 = alloca %sb__Snake*
  %t6 = alloca %grid__Cell
  store %sb__Snake* %self, %sb__Snake** %t0
  %t1 = load %sb__Snake*, %sb__Snake** %t0
  %t2 = getelementptr inbounds %sb__Snake, %sb__Snake* %t1, i32 0, i32 2
  %t3 = load i32, i32* %t2
  %t4 = load %sb__Snake*, %sb__Snake** %t0
  %t5 = getelementptr inbounds %sb__Snake, %sb__Snake* %t4, i32 0, i32 1
  store i32 %t3, i32* %t5
  %t7 = load %sb__Snake*, %sb__Snake** %t0
  %t8 = call %grid__Cell @sb__Snake__head(%sb__Snake* %t7)
  %t9 = load %sb__Snake*, %sb__Snake** %t0
  %t10 = getelementptr inbounds %sb__Snake, %sb__Snake* %t9, i32 0, i32 1
  %t11 = load i32, i32* %t10
  %t12 = call %grid__Cell @grid__delta(i32 %t11)
  %t13 = call %grid__Cell @grid__cell_add(%grid__Cell %t8, %grid__Cell %t12)
  %t14 = call %grid__Cell @grid__wrap(%grid__Cell %t13)
  store %grid__Cell %t14, %grid__Cell* %t6
  %t15 = load %sb__Snake*, %sb__Snake** %t0
  %t16 = load %grid__Cell, %grid__Cell* %t6
  %t17 = call i1 @sb__Snake__contains(%sb__Snake* %t15, %grid__Cell %t16)
  br i1 %t17, label %if_then_28, label %if_else_29
if_then_28:
  %t18 = load %sb__Snake*, %sb__Snake** %t0
  %t19 = getelementptr inbounds %sb__Snake, %sb__Snake* %t18, i32 0, i32 4
  store i1 false, i1* %t19
  br label %if_end_30
if_else_29:
  br label %if_end_30
if_end_30:
  %t20 = load %grid__Cell, %grid__Cell* %t6
  %t21 = load %sb__Snake*, %sb__Snake** %t0
  %t22 = getelementptr inbounds %sb__Snake, %sb__Snake* %t21, i32 0, i32 0
  %t23 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t22, i32 0, i32 0
  %t24 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t22, i32 0, i32 1
  %t25 = load i64, i64* %t24
  %t26 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t22, i32 0, i32 2
  %t27 = load i64, i64* %t26
  %t28 = icmp sge i64 %t27, 768
  br i1 %t28, label %ring_push_full_31, label %ring_push_grow_32
ring_push_grow_32:
  %t29 = add i64 %t25, %t27
  %t30 = urem i64 %t29, 768
  %t31 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t23, i32 0, i64 %t30
  store %grid__Cell %t20, %grid__Cell* %t31
  %t32 = add i64 %t27, 1
  store i64 %t32, i64* %t26
  br label %ring_push_done_33
ring_push_full_31:
  %t33 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t23, i32 0, i64 %t25
  store %grid__Cell %t20, %grid__Cell* %t33
  %t34 = add i64 %t25, 1
  %t35 = urem i64 %t34, 768
  store i64 %t35, i64* %t24
  br label %ring_push_done_33
ring_push_done_33:
  %t36 = load %sb__Snake*, %sb__Snake** %t0
  %t37 = getelementptr inbounds %sb__Snake, %sb__Snake* %t36, i32 0, i32 3
  %t38 = load i32, i32* %t37
  %t39 = icmp sgt i32 %t38, 0
  br i1 %t39, label %if_then_34, label %if_else_35
if_then_34:
  %t40 = load %sb__Snake*, %sb__Snake** %t0
  %t41 = getelementptr inbounds %sb__Snake, %sb__Snake* %t40, i32 0, i32 3
  %t42 = load i32, i32* %t41
  %t43 = sub i32 %t42, 1
  %t44 = load %sb__Snake*, %sb__Snake** %t0
  %t45 = getelementptr inbounds %sb__Snake, %sb__Snake* %t44, i32 0, i32 3
  store i32 %t43, i32* %t45
  br label %if_end_36
if_else_35:
  %t46 = load %sb__Snake*, %sb__Snake** %t0
  %t47 = getelementptr inbounds %sb__Snake, %sb__Snake* %t46, i32 0, i32 0
  %t48 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t47, i32 0, i32 0
  %t49 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t47, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t47, i32 0, i32 2
  %t52 = load i64, i64* %t51
  %t53 = icmp eq i64 %t52, 0
  br i1 %t53, label %ring_pop_empty_37, label %ring_pop_nonempty_38
ring_pop_nonempty_38:
  %t54 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t48, i32 0, i64 %t50
  %t55 = load %grid__Cell, %grid__Cell* %t54
  store %grid__Cell zeroinitializer, %grid__Cell* %t54
  %t56 = add i64 %t50, 1
  %t57 = urem i64 %t56, 768
  store i64 %t57, i64* %t49
  %t58 = sub i64 %t52, 1
  store i64 %t58, i64* %t51
  br label %ring_pop_end_39
ring_pop_empty_37:
  br label %ring_pop_end_39
ring_pop_end_39:
  %t59 = phi %grid__Cell [ %t55, %ring_pop_nonempty_38 ], [ zeroinitializer, %ring_pop_empty_37 ]
  br label %if_end_36
if_end_36:
  %t60 = load %grid__Cell, %grid__Cell* %t6
  ret %grid__Cell %t60
}

define %sb__Snake @sb__make_snake() {
entry:
  %t0 = alloca %sb__Snake
  %t1 = alloca %sb__Snake
  %t8 = alloca %grid__Cell
  %t26 = alloca %grid__Cell
  %t44 = alloca %grid__Cell
  %t2 = getelementptr inbounds %sb__Snake, %sb__Snake* %t1, i32 0, i32 0
  store { [768 x %grid__Cell], i64, i64 } zeroinitializer, { [768 x %grid__Cell], i64, i64 }* %t2
  %t3 = getelementptr inbounds %sb__Snake, %sb__Snake* %t1, i32 0, i32 1
  store i32 3, i32* %t3
  %t4 = getelementptr inbounds %sb__Snake, %sb__Snake* %t1, i32 0, i32 2
  store i32 3, i32* %t4
  %t5 = getelementptr inbounds %sb__Snake, %sb__Snake* %t1, i32 0, i32 3
  store i32 2, i32* %t5
  %t6 = getelementptr inbounds %sb__Snake, %sb__Snake* %t1, i32 0, i32 4
  store i1 true, i1* %t6
  %t7 = load %sb__Snake, %sb__Snake* %t1
  store %sb__Snake %t7, %sb__Snake* %t0
  %t9 = getelementptr inbounds %grid__Cell, %grid__Cell* %t8, i32 0, i32 0
  store i32 5, i32* %t9
  %t10 = getelementptr inbounds %grid__Cell, %grid__Cell* %t8, i32 0, i32 1
  store i32 12, i32* %t10
  %t11 = load %grid__Cell, %grid__Cell* %t8
  %t12 = getelementptr inbounds %sb__Snake, %sb__Snake* %t0, i32 0, i32 0
  %t13 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t12, i32 0, i32 0
  %t14 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t12, i32 0, i32 1
  %t15 = load i64, i64* %t14
  %t16 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t12, i32 0, i32 2
  %t17 = load i64, i64* %t16
  %t18 = icmp sge i64 %t17, 768
  br i1 %t18, label %ring_push_full_40, label %ring_push_grow_41
ring_push_grow_41:
  %t19 = add i64 %t15, %t17
  %t20 = urem i64 %t19, 768
  %t21 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t13, i32 0, i64 %t20
  store %grid__Cell %t11, %grid__Cell* %t21
  %t22 = add i64 %t17, 1
  store i64 %t22, i64* %t16
  br label %ring_push_done_42
ring_push_full_40:
  %t23 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t13, i32 0, i64 %t15
  store %grid__Cell %t11, %grid__Cell* %t23
  %t24 = add i64 %t15, 1
  %t25 = urem i64 %t24, 768
  store i64 %t25, i64* %t14
  br label %ring_push_done_42
ring_push_done_42:
  %t27 = getelementptr inbounds %grid__Cell, %grid__Cell* %t26, i32 0, i32 0
  store i32 6, i32* %t27
  %t28 = getelementptr inbounds %grid__Cell, %grid__Cell* %t26, i32 0, i32 1
  store i32 12, i32* %t28
  %t29 = load %grid__Cell, %grid__Cell* %t26
  %t30 = getelementptr inbounds %sb__Snake, %sb__Snake* %t0, i32 0, i32 0
  %t31 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t30, i32 0, i32 0
  %t32 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t30, i32 0, i32 1
  %t33 = load i64, i64* %t32
  %t34 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t30, i32 0, i32 2
  %t35 = load i64, i64* %t34
  %t36 = icmp sge i64 %t35, 768
  br i1 %t36, label %ring_push_full_43, label %ring_push_grow_44
ring_push_grow_44:
  %t37 = add i64 %t33, %t35
  %t38 = urem i64 %t37, 768
  %t39 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t31, i32 0, i64 %t38
  store %grid__Cell %t29, %grid__Cell* %t39
  %t40 = add i64 %t35, 1
  store i64 %t40, i64* %t34
  br label %ring_push_done_45
ring_push_full_43:
  %t41 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t31, i32 0, i64 %t33
  store %grid__Cell %t29, %grid__Cell* %t41
  %t42 = add i64 %t33, 1
  %t43 = urem i64 %t42, 768
  store i64 %t43, i64* %t32
  br label %ring_push_done_45
ring_push_done_45:
  %t45 = getelementptr inbounds %grid__Cell, %grid__Cell* %t44, i32 0, i32 0
  store i32 7, i32* %t45
  %t46 = getelementptr inbounds %grid__Cell, %grid__Cell* %t44, i32 0, i32 1
  store i32 12, i32* %t46
  %t47 = load %grid__Cell, %grid__Cell* %t44
  %t48 = getelementptr inbounds %sb__Snake, %sb__Snake* %t0, i32 0, i32 0
  %t49 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t48, i32 0, i32 0
  %t50 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t48, i32 0, i32 1
  %t51 = load i64, i64* %t50
  %t52 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t48, i32 0, i32 2
  %t53 = load i64, i64* %t52
  %t54 = icmp sge i64 %t53, 768
  br i1 %t54, label %ring_push_full_46, label %ring_push_grow_47
ring_push_grow_47:
  %t55 = add i64 %t51, %t53
  %t56 = urem i64 %t55, 768
  %t57 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t49, i32 0, i64 %t56
  store %grid__Cell %t47, %grid__Cell* %t57
  %t58 = add i64 %t53, 1
  store i64 %t58, i64* %t52
  br label %ring_push_done_48
ring_push_full_46:
  %t59 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t49, i32 0, i64 %t51
  store %grid__Cell %t47, %grid__Cell* %t59
  %t60 = add i64 %t51, 1
  %t61 = urem i64 %t60, 768
  store i64 %t61, i64* %t50
  br label %ring_push_done_48
ring_push_done_48:
  %t62 = load %sb__Snake, %sb__Snake* %t0
  ret %sb__Snake %t62
}

define i8* @food__occupied_cells({ [768 x %grid__Cell], i64, i64 } %body, i32 %len) {
entry:
  %t0 = alloca { [768 x %grid__Cell], i64, i64 }
  %t1 = alloca i32
  %t2 = alloca i8*
  %t3 = alloca i32
  %t64 = alloca %grid__Cell
  %t69 = alloca i64
  %t70 = alloca i1
  store { [768 x %grid__Cell], i64, i64 } %body, { [768 x %grid__Cell], i64, i64 }* %t0
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
  %t7 = getelementptr %grid__Cell, %grid__Cell* null, i32 1
  %t8 = ptrtoint %grid__Cell* %t7 to i64
  %t9 = load i8*, i8** %t2
  %t10 = icmp eq i8* %t9, null
  br i1 %t10, label %set_cow_alloc_53, label %set_cow_check_54
set_cow_alloc_53:
  %t15 = bitcast void (i8*)* @set_release_s_grid__Cell to i8*
  %t16 = call i8* @star_rc_alloc(i64 24, i8* %t15)
  %t17 = bitcast i8* %t16 to { %grid__Cell*, i64, i64 }*
  %t18 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t17, i32 0, i32 0
  store %grid__Cell* null, %grid__Cell** %t18
  %t19 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t17, i32 0, i32 1
  store i64 0, i64* %t19
  %t20 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t17, i32 0, i32 2
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
  %t25 = bitcast i8* %t9 to { %grid__Cell*, i64, i64 }*
  %t26 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t25, i32 0, i32 0
  %t27 = load %grid__Cell*, %grid__Cell** %t26
  %t28 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t25, i32 0, i32 1
  %t29 = load i64, i64* %t28
  %t30 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t25, i32 0, i32 2
  %t31 = load i64, i64* %t30
  %t32 = bitcast void (i8*)* @set_release_s_grid__Cell to i8*
  %t33 = call i8* @star_rc_alloc(i64 24, i8* %t32)
  %t34 = bitcast i8* %t33 to { %grid__Cell*, i64, i64 }*
  %t35 = mul i64 %t31, %t8
  %t36 = call i8* @malloc(i64 %t35)
  %t37 = bitcast i8* %t36 to %grid__Cell*
  %t38 = icmp sgt i64 %t29, 0
  br i1 %t38, label %set_cow_copy_57, label %set_cow_after_copy_58
set_cow_copy_57:
  %t39 = mul i64 %t29, %t8
  %t40 = bitcast %grid__Cell* %t27 to i8*
  call i8* @memcpy(i8* %t36, i8* %t40, i64 %t39)
  br label %set_cow_after_copy_58
set_cow_after_copy_58:
  %t41 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t34, i32 0, i32 0
  store %grid__Cell* %t37, %grid__Cell** %t41
  %t42 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t34, i32 0, i32 1
  store i64 %t29, i64* %t42
  %t43 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t34, i32 0, i32 2
  store i64 %t31, i64* %t43
  call void @star_rc_release(i8* %t9)
  store i8* %t33, i8** %t2
  br label %set_cow_done_55
set_cow_done_55:
  %t44 = load i8*, i8** %t2
  %t45 = bitcast i8* %t44 to { %grid__Cell*, i64, i64 }*
  %t46 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t45, i32 0, i32 0
  %t47 = load %grid__Cell*, %grid__Cell** %t46
  %t48 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t45, i32 0, i32 1
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t45, i32 0, i32 2
  %t51 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t0, i32 0, i32 0
  %t52 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t0, i32 0, i32 1
  %t53 = load i64, i64* %t52
  %t54 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t0, i32 0, i32 2
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
  %t63 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t51, i32 0, i64 %t62
  br label %ring_rplace_end_61
ring_rplace_oob_60:
  store %grid__Cell zeroinitializer, %grid__Cell* %t64
  br label %ring_rplace_end_61
ring_rplace_end_61:
  %t65 = phi %grid__Cell* [ %t63, %ring_rplace_ok_59 ], [ %t64, %ring_rplace_oob_60 ]
  %t66 = load %grid__Cell, %grid__Cell* %t65
  %t67 = load i64, i64* %t48
  %t68 = load %grid__Cell*, %grid__Cell** %t46
  store i64 0, i64* %t69
  store i1 false, i1* %t70
  br label %find_cond_62
find_cond_62:
  %t71 = load i64, i64* %t69
  %t72 = icmp slt i64 %t71, %t67
  br i1 %t72, label %find_body_63, label %find_end_66
find_body_63:
  %t73 = getelementptr inbounds %grid__Cell, %grid__Cell* %t68, i64 %t71
  %t74 = load %grid__Cell, %grid__Cell* %t73
  br label %find_eq_check_64
find_eq_check_64:
  %t75 = call i1 @eq_s_grid__Cell(%grid__Cell %t74, %grid__Cell %t66)
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
  %t80 = load %grid__Cell*, %grid__Cell** %t46
  %t81 = icmp sge i64 %t67, %t79
  br i1 %t81, label %set_insert_grow_70, label %set_insert_store_71
set_insert_grow_70:
  %t82 = mul i64 %t79, 2
  %t83 = icmp sgt i64 %t82, 0
  %t84 = select i1 %t83, i64 %t82, i64 1
  %t85 = getelementptr %grid__Cell, %grid__Cell* null, i32 1
  %t86 = ptrtoint %grid__Cell* %t85 to i64
  %t87 = mul i64 %t84, %t86
  %t88 = call i8* @malloc(i64 %t87)
  %t89 = bitcast i8* %t88 to %grid__Cell*
  %t90 = icmp sgt i64 %t79, 0
  br i1 %t90, label %set_insert_copy_72, label %set_insert_after_copy_73
set_insert_copy_72:
  %t91 = mul i64 %t67, %t86
  %t92 = bitcast %grid__Cell* %t80 to i8*
  call i8* @memcpy(i8* %t88, i8* %t92, i64 %t91)
  call void @free(i8* %t92)
  br label %set_insert_after_copy_73
set_insert_after_copy_73:
  store %grid__Cell* %t89, %grid__Cell** %t46
  store i64 %t84, i64* %t50
  br label %set_insert_store_71
set_insert_store_71:
  %t93 = load %grid__Cell*, %grid__Cell** %t46
  %t94 = getelementptr inbounds %grid__Cell, %grid__Cell* %t93, i64 %t67
  store %grid__Cell %t66, %grid__Cell* %t94
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

define %grid__Cell @food__spawn_food({ [768 x %grid__Cell], i64, i64 } %body, i32 %len) {
entry:
  %t0 = alloca { [768 x %grid__Cell], i64, i64 }
  %t1 = alloca i32
  %t2 = alloca i8*
  %t6 = alloca i8*
  %t7 = alloca i32
  %t10 = alloca i32
  %t13 = alloca %grid__Cell
  %t28 = alloca i64
  %t29 = alloca i1
  %t83 = alloca %grid__Cell
  %t122 = alloca %grid__Cell
  %t130 = alloca i32
  store { [768 x %grid__Cell], i64, i64 } %body, { [768 x %grid__Cell], i64, i64 }* %t0
  store i32 %len, i32* %t1
  %t3 = load { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t0
  %t4 = load i32, i32* %t1
  %t5 = call i8* @food__occupied_cells({ [768 x %grid__Cell], i64, i64 } %t3, i32 %t4)
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
  %t15 = getelementptr inbounds %grid__Cell, %grid__Cell* %t13, i32 0, i32 0
  store i32 %t14, i32* %t15
  %t16 = load i32, i32* %t7
  %t17 = getelementptr inbounds %grid__Cell, %grid__Cell* %t13, i32 0, i32 1
  store i32 %t16, i32* %t17
  %t18 = load %grid__Cell, %grid__Cell* %t13
  %t19 = load i8*, i8** %t2
  %t20 = icmp eq i8* %t19, null
  br i1 %t20, label %set_read_null_82, label %set_read_real_83
set_read_null_82:
  br label %set_read_end_84
set_read_real_83:
  %t21 = bitcast i8* %t19 to { %grid__Cell*, i64, i64 }*
  %t22 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t21, i32 0, i32 0
  %t23 = load %grid__Cell*, %grid__Cell** %t22
  %t24 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t21, i32 0, i32 1
  %t25 = load i64, i64* %t24
  br label %set_read_end_84
set_read_end_84:
  %t26 = phi %grid__Cell* [ null, %set_read_null_82 ], [ %t23, %set_read_real_83 ]
  %t27 = phi i64 [ 0, %set_read_null_82 ], [ %t25, %set_read_real_83 ]
  store i64 0, i64* %t28
  store i1 false, i1* %t29
  br label %find_cond_85
find_cond_85:
  %t30 = load i64, i64* %t28
  %t31 = icmp slt i64 %t30, %t27
  br i1 %t31, label %find_body_86, label %find_end_89
find_body_86:
  %t32 = getelementptr inbounds %grid__Cell, %grid__Cell* %t26, i64 %t30
  %t33 = load %grid__Cell, %grid__Cell* %t32
  br label %find_eq_check_87
find_eq_check_87:
  %t34 = call i1 @eq_s_grid__Cell(%grid__Cell %t33, %grid__Cell %t18)
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
  %t39 = getelementptr %grid__Cell, %grid__Cell* null, i32 1
  %t40 = ptrtoint %grid__Cell* %t39 to i64
  %t41 = load i8*, i8** %t6
  %t42 = icmp eq i8* %t41, null
  br i1 %t42, label %list_cow_alloc_93, label %list_cow_check_94
list_cow_alloc_93:
  %t47 = bitcast void (i8*)* @list_release_s_grid__Cell to i8*
  %t48 = call i8* @star_rc_alloc(i64 24, i8* %t47)
  %t49 = bitcast i8* %t48 to { %grid__Cell*, i64, i64 }*
  %t50 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t49, i32 0, i32 0
  store %grid__Cell* null, %grid__Cell** %t50
  %t51 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t49, i32 0, i32 1
  store i64 0, i64* %t51
  %t52 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t49, i32 0, i32 2
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
  %t57 = bitcast i8* %t41 to { %grid__Cell*, i64, i64 }*
  %t58 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t57, i32 0, i32 0
  %t59 = load %grid__Cell*, %grid__Cell** %t58
  %t60 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t57, i32 0, i32 1
  %t61 = load i64, i64* %t60
  %t62 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t57, i32 0, i32 2
  %t63 = load i64, i64* %t62
  %t64 = bitcast void (i8*)* @list_release_s_grid__Cell to i8*
  %t65 = call i8* @star_rc_alloc(i64 24, i8* %t64)
  %t66 = bitcast i8* %t65 to { %grid__Cell*, i64, i64 }*
  %t67 = mul i64 %t63, %t40
  %t68 = call i8* @malloc(i64 %t67)
  %t69 = bitcast i8* %t68 to %grid__Cell*
  %t70 = icmp sgt i64 %t61, 0
  br i1 %t70, label %list_cow_copy_97, label %list_cow_after_copy_98
list_cow_copy_97:
  %t71 = mul i64 %t61, %t40
  %t72 = bitcast %grid__Cell* %t59 to i8*
  call i8* @memcpy(i8* %t68, i8* %t72, i64 %t71)
  br label %list_cow_after_copy_98
list_cow_after_copy_98:
  %t73 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t66, i32 0, i32 0
  store %grid__Cell* %t69, %grid__Cell** %t73
  %t74 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t66, i32 0, i32 1
  store i64 %t61, i64* %t74
  %t75 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t66, i32 0, i32 2
  store i64 %t63, i64* %t75
  call void @star_rc_release(i8* %t41)
  store i8* %t65, i8** %t6
  br label %list_cow_done_95
list_cow_done_95:
  %t76 = load i8*, i8** %t6
  %t77 = bitcast i8* %t76 to { %grid__Cell*, i64, i64 }*
  %t78 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t77, i32 0, i32 0
  %t79 = load %grid__Cell*, %grid__Cell** %t78
  %t80 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t77, i32 0, i32 1
  %t81 = load i64, i64* %t80
  %t82 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t77, i32 0, i32 2
  %t84 = load i32, i32* %t10
  %t85 = getelementptr inbounds %grid__Cell, %grid__Cell* %t83, i32 0, i32 0
  store i32 %t84, i32* %t85
  %t86 = load i32, i32* %t7
  %t87 = getelementptr inbounds %grid__Cell, %grid__Cell* %t83, i32 0, i32 1
  store i32 %t86, i32* %t87
  %t88 = load %grid__Cell, %grid__Cell* %t83
  %t89 = load i64, i64* %t82
  %t90 = load %grid__Cell*, %grid__Cell** %t78
  %t91 = load i64, i64* %t80
  %t92 = icmp sge i64 %t91, %t89
  br i1 %t92, label %list_push_grow_99, label %list_push_store_100
list_push_grow_99:
  %t93 = mul i64 %t89, 2
  %t94 = icmp sgt i64 %t93, 0
  %t95 = select i1 %t94, i64 %t93, i64 1
  %t96 = getelementptr %grid__Cell, %grid__Cell* null, i32 1
  %t97 = ptrtoint %grid__Cell* %t96 to i64
  %t98 = mul i64 %t95, %t97
  %t99 = call i8* @malloc(i64 %t98)
  %t100 = bitcast i8* %t99 to %grid__Cell*
  %t101 = icmp sgt i64 %t89, 0
  br i1 %t101, label %list_push_copy_101, label %list_push_after_copy_102
list_push_copy_101:
  %t102 = mul i64 %t91, %t97
  %t103 = bitcast %grid__Cell* %t90 to i8*
  call i8* @memcpy(i8* %t99, i8* %t103, i64 %t102)
  call void @free(i8* %t103)
  br label %list_push_after_copy_102
list_push_after_copy_102:
  store %grid__Cell* %t100, %grid__Cell** %t78
  store i64 %t95, i64* %t82
  br label %list_push_store_100
list_push_store_100:
  %t104 = load %grid__Cell*, %grid__Cell** %t78
  %t105 = getelementptr inbounds %grid__Cell, %grid__Cell* %t104, i64 %t91
  store %grid__Cell %t88, %grid__Cell* %t105
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
  %t113 = bitcast i8* %t111 to { %grid__Cell*, i64, i64 }*
  %t114 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t113, i32 0, i32 0
  %t115 = load %grid__Cell*, %grid__Cell** %t114
  %t116 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t113, i32 0, i32 1
  %t117 = load i64, i64* %t116
  br label %list_read_end_105
list_read_end_105:
  %t118 = phi %grid__Cell* [ null, %list_read_null_103 ], [ %t115, %list_read_real_104 ]
  %t119 = phi i64 [ 0, %list_read_null_103 ], [ %t117, %list_read_real_104 ]
  %t120 = trunc i64 %t119 to i32
  %t121 = icmp eq i32 %t120, 0
  br i1 %t121, label %if_then_106, label %if_else_107
if_then_106:
  %t123 = sub i32 0, 1
  %t124 = getelementptr inbounds %grid__Cell, %grid__Cell* %t122, i32 0, i32 0
  store i32 %t123, i32* %t124
  %t125 = sub i32 0, 1
  %t126 = getelementptr inbounds %grid__Cell, %grid__Cell* %t122, i32 0, i32 1
  store i32 %t125, i32* %t126
  %t127 = load %grid__Cell, %grid__Cell* %t122
  %t128 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t128)
  %t129 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t129)
  ret %grid__Cell %t127
if_else_107:
  br label %if_end_108
if_end_108:
  %t131 = load i8*, i8** %t6
  %t132 = icmp eq i8* %t131, null
  br i1 %t132, label %list_read_null_109, label %list_read_real_110
list_read_null_109:
  br label %list_read_end_111
list_read_real_110:
  %t133 = bitcast i8* %t131 to { %grid__Cell*, i64, i64 }*
  %t134 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t133, i32 0, i32 0
  %t135 = load %grid__Cell*, %grid__Cell** %t134
  %t136 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t133, i32 0, i32 1
  %t137 = load i64, i64* %t136
  br label %list_read_end_111
list_read_end_111:
  %t138 = phi %grid__Cell* [ null, %list_read_null_109 ], [ %t135, %list_read_real_110 ]
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
  %t157 = bitcast i8* %t155 to { %grid__Cell*, i64, i64 }*
  %t158 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t157, i32 0, i32 0
  %t159 = load %grid__Cell*, %grid__Cell** %t158
  %t160 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t157, i32 0, i32 1
  %t161 = load i64, i64* %t160
  br label %list_read_end_114
list_read_end_114:
  %t162 = phi %grid__Cell* [ null, %list_read_null_112 ], [ %t159, %list_read_real_113 ]
  %t163 = phi i64 [ 0, %list_read_null_112 ], [ %t161, %list_read_real_113 ]
  %t164 = load i32, i32* %t130
  %t165 = sext i32 %t164 to i64
  %t166 = icmp ult i64 %t165, %t163
  br i1 %t166, label %list_idx_ok_115, label %list_idx_oob_116
list_idx_ok_115:
  %t167 = getelementptr inbounds %grid__Cell, %grid__Cell* %t162, i64 %t165
  %t168 = load %grid__Cell, %grid__Cell* %t167
  br label %list_idx_end_117
list_idx_oob_116:
  br label %list_idx_end_117
list_idx_end_117:
  %t169 = phi %grid__Cell [ %t168, %list_idx_ok_115 ], [ zeroinitializer, %list_idx_oob_116 ]
  %t170 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t170)
  %t171 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t171)
  ret %grid__Cell %t169
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
  %t6 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.0, i64 0, i32 2, i64 0
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
  %t14 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.1, i64 0, i64 0
  call i32 @puts(i8* %t14)
  call void @exit(i32 1)
  unreachable
file_handle_ok_156:
  %t15 = load i32, i32* %t1
  %t16 = load i8*, i8** %t2
  %t17 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t17)
  call void @star_rc_release(i8* %t16)
  %t18 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.2, i64 0, i64 0
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
  %t29 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.3, i64 0, i64 0
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
  %t3 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.4, i64 0, i64 0
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
  %t9 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.5, i64 0, i32 2, i64 0
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
  %t16 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.6, i64 0, i32 2, i64 0
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
  %t22 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.7, i64 0, i32 2, i64 0
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
  %t29 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.8, i64 0, i64 0
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
  %t45 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.9, i64 0, i64 0
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
  %t94 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.10, i64 0, i32 2, i64 0
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
  %t207 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.11, i64 0, i32 2, i64 0
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

define void @tick_particle_arena(float %dt, float %gravity) {
entry:
  %t0 = alloca float
  %t1 = alloca float
  %t106 = alloca { i64, i64, float*, float* }
  %t121 = alloca { i64, i64, float*, float* }
  %t136 = alloca { i64, i64, float*, float* }
  %t151 = alloca { i64, i64, float*, float* }
  %t179 = alloca { i64, i64, float*, float* }
  store float %dt, float* %t0
  store float %gravity, float* %t1
  call void @par.pool.ensure_init()
  %t83 = call i32 @GetCurrentThreadId()
  %t84 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t85 = load i32, i32* %t84
  %t86 = icmp eq i32 %t83, %t85
  %t87 = select i1 %t86, i32 0, i32 -1
  %t88 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t89 = load i32, i32* %t88
  %t90 = icmp eq i32 %t83, %t89
  %t91 = select i1 %t90, i32 1, i32 %t87
  %t92 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t93 = load i32, i32* %t92
  %t94 = icmp eq i32 %t83, %t93
  %t95 = select i1 %t94, i32 2, i32 %t91
  %t96 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t97 = load i32, i32* %t96
  %t98 = icmp eq i32 %t83, %t97
  %t99 = select i1 %t98, i32 3, i32 %t95
  %t100 = icmp sge i32 %t99, 0
  br i1 %t100, label %par_serial_232, label %par_pooled_231
par_pooled_231:
  %t101 = load i64, i64* @arena.Particles.count
  %t102 = mul i64 %t101, 0
  %t103 = sdiv i64 %t102, 4
  %t104 = mul i64 %t101, 1
  %t105 = sdiv i64 %t104, 4
  %t107 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t106, i32 0, i32 0
  store i64 %t103, i64* %t107
  %t108 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t106, i32 0, i32 1
  store i64 %t105, i64* %t108
  %t109 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t106, i32 0, i32 2
  store float* %t0, float** %t109
  %t110 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t106, i32 0, i32 3
  store float* %t1, float** %t110
  %t111 = bitcast { i64, i64, float*, float* }* %t106 to i8*
  %t112 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t111, i8** %t112
  %t113 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_222, i32 (i8*)** %t113
  %t114 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t115 = load i8*, i8** %t114
  %t116 = call i32 @ReleaseSemaphore(i8* %t115, i32 1, i32* null)
  %t117 = mul i64 %t101, 1
  %t118 = sdiv i64 %t117, 4
  %t119 = mul i64 %t101, 2
  %t120 = sdiv i64 %t119, 4
  %t122 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t121, i32 0, i32 0
  store i64 %t118, i64* %t122
  %t123 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t121, i32 0, i32 1
  store i64 %t120, i64* %t123
  %t124 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t121, i32 0, i32 2
  store float* %t0, float** %t124
  %t125 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t121, i32 0, i32 3
  store float* %t1, float** %t125
  %t126 = bitcast { i64, i64, float*, float* }* %t121 to i8*
  %t127 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t126, i8** %t127
  %t128 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_222, i32 (i8*)** %t128
  %t129 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t130 = load i8*, i8** %t129
  %t131 = call i32 @ReleaseSemaphore(i8* %t130, i32 1, i32* null)
  %t132 = mul i64 %t101, 2
  %t133 = sdiv i64 %t132, 4
  %t134 = mul i64 %t101, 3
  %t135 = sdiv i64 %t134, 4
  %t137 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t136, i32 0, i32 0
  store i64 %t133, i64* %t137
  %t138 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t136, i32 0, i32 1
  store i64 %t135, i64* %t138
  %t139 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t136, i32 0, i32 2
  store float* %t0, float** %t139
  %t140 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t136, i32 0, i32 3
  store float* %t1, float** %t140
  %t141 = bitcast { i64, i64, float*, float* }* %t136 to i8*
  %t142 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t141, i8** %t142
  %t143 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_222, i32 (i8*)** %t143
  %t144 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t145 = load i8*, i8** %t144
  %t146 = call i32 @ReleaseSemaphore(i8* %t145, i32 1, i32* null)
  %t147 = mul i64 %t101, 3
  %t148 = sdiv i64 %t147, 4
  %t149 = mul i64 %t101, 4
  %t150 = sdiv i64 %t149, 4
  %t152 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t151, i32 0, i32 0
  store i64 %t148, i64* %t152
  %t153 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t151, i32 0, i32 1
  store i64 %t150, i64* %t153
  %t154 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t151, i32 0, i32 2
  store float* %t0, float** %t154
  %t155 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t151, i32 0, i32 3
  store float* %t1, float** %t155
  %t156 = bitcast { i64, i64, float*, float* }* %t151 to i8*
  %t157 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t156, i8** %t157
  %t158 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_222, i32 (i8*)** %t158
  %t159 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t160 = load i8*, i8** %t159
  %t161 = call i32 @ReleaseSemaphore(i8* %t160, i32 1, i32* null)
  %t162 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t163 = load i8*, i8** %t162
  %t164 = call i32 @WaitForSingleObject(i8* %t163, i32 -1)
  %t165 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t166 = load i8*, i8** %t165
  %t167 = call i32 @WaitForSingleObject(i8* %t166, i32 -1)
  %t168 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t169 = load i8*, i8** %t168
  %t170 = call i32 @WaitForSingleObject(i8* %t169, i32 -1)
  %t171 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t172 = load i8*, i8** %t171
  %t173 = call i32 @WaitForSingleObject(i8* %t172, i32 -1)
  br label %par_join_236
par_serial_232:
  %t174 = load i32, i32* @par.pool.serial_owner
  %t175 = icmp eq i32 %t174, %t99
  br i1 %t175, label %par_run_234, label %par_acquire_233
par_acquire_233:
  %t176 = load i8*, i8** @par.pool.serial_lock
  %t177 = call i32 @WaitForSingleObject(i8* %t176, i32 -1)
  store i32 %t99, i32* @par.pool.serial_owner
  br label %par_run_234
par_run_234:
  %t178 = load i64, i64* @arena.Particles.count
  %t180 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t179, i32 0, i32 0
  store i64 0, i64* %t180
  %t181 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t179, i32 0, i32 1
  store i64 %t178, i64* %t181
  %t182 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t179, i32 0, i32 2
  store float* %t0, float** %t182
  %t183 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t179, i32 0, i32 3
  store float* %t1, float** %t183
  %t184 = bitcast { i64, i64, float*, float* }* %t179 to i8*
  %t185 = call i32 @par_worker_222(i8* %t184)
  br i1 %t175, label %par_join_236, label %par_release_235
par_release_235:
  store i32 -1, i32* @par.pool.serial_owner
  %t186 = load i8*, i8** @par.pool.serial_lock
  %t187 = call i32 @ReleaseSemaphore(i8* %t186, i32 1, i32* null)
  br label %par_join_236
par_join_236:
  ret void
}

define void @draw_particle_arena(i8* %w) {
entry:
  %t0 = alloca i8*
  %t3 = alloca i64
  %t14 = alloca float
  store i8* %w, i8** %t0
  %t1 = load %Particle*, %Particle** @arena.Particles.data
  %t2 = load i64, i64* @arena.Particles.count
  store i64 0, i64* %t3
  br label %each_cond_237
each_cond_237:
  %t4 = load i64, i64* %t3
  %t5 = icmp slt i64 %t4, %t2
  br i1 %t5, label %each_body_238, label %each_end_241
each_body_238:
  %t6 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t4
  %t7 = load i64, i64* %t6
  %t8 = and i64 %t7, 1
  %t9 = icmp eq i64 %t8, 1
  br i1 %t9, label %each_live_239, label %each_step_240
each_live_239:
  %t10 = getelementptr inbounds %Particle, %Particle* %t1, i64 %t4
  %t11 = getelementptr inbounds %Particle, %Particle* %t10, i32 0, i32 4
  %t12 = load float, float* %t11
  %t13 = fcmp ogt float %t12, 0x0000000000000000
  br i1 %t13, label %if_then_242, label %if_else_243
if_then_242:
  %t15 = getelementptr inbounds %Particle, %Particle* %t10, i32 0, i32 4
  %t16 = load float, float* %t15
  %t17 = fmul float %t16, 0x406FE00000000000
  %t18 = fdiv float %t17, 0x3FDCCCCCC0000000
  %t19 = call float @llvm.maxnum.f32(float %t18, float 0x0000000000000000)
  %t20 = call float @llvm.minnum.f32(float %t19, float 0x406FE00000000000)
  store float %t20, float* %t14
  %t21 = load i8*, i8** %t0
  %t22 = icmp eq i8* %t21, null
  br i1 %t22, label %sdl_null_window_245, label %sdl_window_handle_ok_246
sdl_null_window_245:
  %t23 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.12, i64 0, i64 0
  call i32 @puts(i8* %t23)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_246:
  %t24 = call i8* @SDL_GetRenderer(i8* %t21)
  %t25 = getelementptr inbounds %Particle, %Particle* %t10, i32 0, i32 0
  %t26 = load float, float* %t25
  %t27 = call i32 @llvm.fptosi.sat.i32.f32(float %t26)
  %t28 = getelementptr inbounds %Particle, %Particle* %t10, i32 0, i32 1
  %t29 = load float, float* %t28
  %t30 = call i32 @llvm.fptosi.sat.i32.f32(float %t29)
  %t31 = and i32 255, 255
  %t32 = and i32 210, 255
  %t33 = shl i32 %t32, 8
  %t34 = or i32 %t31, %t33
  %t35 = and i32 90, 255
  %t36 = shl i32 %t35, 16
  %t37 = or i32 %t34, %t36
  %t38 = load float, float* %t14
  %t39 = call i32 @llvm.fptosi.sat.i32.f32(float %t38)
  %t40 = and i32 %t39, 255
  %t41 = shl i32 %t40, 24
  %t42 = or i32 %t37, %t41
  %t43 = and i32 %t42, 255
  %t44 = trunc i32 %t43 to i8
  %t45 = lshr i32 %t42, 8
  %t46 = and i32 %t45, 255
  %t47 = trunc i32 %t46 to i8
  %t48 = lshr i32 %t42, 16
  %t49 = and i32 %t48, 255
  %t50 = trunc i32 %t49 to i8
  %t51 = lshr i32 %t42, 24
  %t52 = and i32 %t51, 255
  %t53 = trunc i32 %t52 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t24, i8 %t44, i8 %t47, i8 %t50, i8 %t53)
  call i32 @SDL_RenderDrawPoint(i8* %t24, i32 %t27, i32 %t30)
  br label %if_end_244
if_else_243:
  br label %if_end_244
if_end_244:
  br label %each_step_240
each_step_240:
  %t54 = add i64 %t4, 1
  store i64 %t54, i64* %t3
  br label %each_cond_237
each_end_241:
  ret void
}

define void @reclaim_dead_particles() {
entry:
  %t2 = alloca i64
  %t11 = alloca i32
  %t0 = load %Particle*, %Particle** @arena.Particles.data
  %t1 = load i64, i64* @arena.Particles.count
  store i64 0, i64* %t2
  br label %each_cond_247
each_cond_247:
  %t3 = load i64, i64* %t2
  %t4 = icmp slt i64 %t3, %t1
  br i1 %t4, label %each_body_248, label %each_end_251
each_body_248:
  %t5 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t3
  %t6 = load i64, i64* %t5
  %t7 = and i64 %t6, 1
  %t8 = icmp eq i64 %t7, 1
  br i1 %t8, label %each_live_249, label %each_step_250
each_live_249:
  %t9 = getelementptr inbounds %Particle, %Particle* %t0, i64 %t3
  %t10 = trunc i64 %t3 to i32
  store i32 %t10, i32* %t11
  %t12 = getelementptr inbounds %Particle, %Particle* %t9, i32 0, i32 4
  %t13 = load float, float* %t12
  %t14 = fcmp ole float %t13, 0x0000000000000000
  br i1 %t14, label %if_then_252, label %if_else_253
if_then_252:
  %t15 = load i32, i32* %t11
  %t16 = sext i32 %t15 to i64
  %t17 = icmp ult i64 %t16, 256
  br i1 %t17, label %despawn_do_255, label %despawn_end_256
despawn_do_255:
  %t18 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t16
  %t19 = load i64, i64* %t18
  %t20 = and i64 %t19, 1
  %t21 = icmp eq i64 %t20, 1
  br i1 %t21, label %despawn_live_257, label %despawn_end_256
despawn_live_257:
  %t22 = add i64 %t19, 1
  store i64 %t22, i64* %t18
  %t23 = load i64, i64* @arena.Particles.free_top
  %t24 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.free, i64 0, i64 %t23
  store i64 %t16, i64* %t24
  %t25 = add i64 %t23, 1
  store i64 %t25, i64* @arena.Particles.free_top
  br label %despawn_end_256
despawn_end_256:
  br label %if_end_254
if_else_253:
  br label %if_end_254
if_end_254:
  br label %each_step_250
each_step_250:
  %t26 = add i64 %t3, 1
  store i64 %t26, i64* %t2
  br label %each_cond_247
each_end_251:
  ret void
}

define void @dump_particle_arena() {
entry:
  %t53 = alloca { i64, i64 }
  %t66 = alloca { i64, i64 }
  %t79 = alloca { i64, i64 }
  %t92 = alloca { i64, i64 }
  %t118 = alloca { i64, i64 }
  %t0 = getelementptr inbounds { i64, i8*, [35 x i8] }, { i64, i8*, [35 x i8] }* @.str.13, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t0)
  call i32 (i8*, ...) @printf(i8* %t0)
  %t1 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.14, i64 0, i64 0
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
  br i1 %t47, label %par_serial_268, label %par_pooled_267
par_pooled_267:
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
  store i32 (i8*)* @par_worker_258, i32 (i8*)** %t58
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
  store i32 (i8*)* @par_worker_258, i32 (i8*)** %t71
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
  store i32 (i8*)* @par_worker_258, i32 (i8*)** %t84
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
  store i32 (i8*)* @par_worker_258, i32 (i8*)** %t97
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
  br label %par_join_272
par_serial_268:
  %t113 = load i32, i32* @par.pool.serial_owner
  %t114 = icmp eq i32 %t113, %t46
  br i1 %t114, label %par_run_270, label %par_acquire_269
par_acquire_269:
  %t115 = load i8*, i8** @par.pool.serial_lock
  %t116 = call i32 @WaitForSingleObject(i8* %t115, i32 -1)
  store i32 %t46, i32* @par.pool.serial_owner
  br label %par_run_270
par_run_270:
  %t117 = load i64, i64* @arena.Particles.count
  %t119 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 0
  store i64 0, i64* %t119
  %t120 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t118, i32 0, i32 1
  store i64 %t117, i64* %t120
  %t121 = bitcast { i64, i64 }* %t118 to i8*
  %t122 = call i32 @par_worker_258(i8* %t121)
  br i1 %t114, label %par_join_272, label %par_release_271
par_release_271:
  store i32 -1, i32* @par.pool.serial_owner
  %t123 = load i8*, i8** @par.pool.serial_lock
  %t124 = call i32 @ReleaseSemaphore(i8* %t123, i32 1, i32* null)
  br label %par_join_272
par_join_272:
  ret void
}

define i32 @spawn_particle_burst(float %cx, float %cy, float %life) {
entry:
  %t0 = alloca float
  %t1 = alloca float
  %t2 = alloca float
  %t3 = alloca i32
  %t5 = alloca i32
  %t8 = alloca float
  %t21 = alloca float
  %t35 = alloca i32
  %t55 = alloca %Particle
  store float %cx, float* %t0
  store float %cy, float* %t1
  store float %life, float* %t2
  %t4 = sub i32 0, 1
  store i32 %t4, i32* %t3
  store i32 0, i32* %t5
  br label %while_cond_273
while_cond_273:
  %t6 = load i32, i32* %t5
  %t7 = icmp slt i32 %t6, 6
  br i1 %t7, label %while_body_274, label %while_else_275
while_body_274:
  %t9 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t9, i32 -1)
  %t10 = load i32, i32* @rng.state
  %t11 = shl i32 %t10, 13
  %t12 = xor i32 %t10, %t11
  %t13 = lshr i32 %t12, 17
  %t14 = xor i32 %t12, %t13
  %t15 = shl i32 %t14, 5
  %t16 = xor i32 %t14, %t15
  store i32 %t16, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t9, i32 1, i32* null)
  %t17 = and i32 %t16, 16777215
  %t18 = uitofp i32 %t17 to float
  %t19 = fdiv float %t18, 0x4170000000000000
  %t20 = fmul float %t19, 0x401921FB60000000
  store float %t20, float* %t8
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
  %t33 = fmul float %t32, 0x4000000000000000
  %t34 = fadd float 0x3FF0000000000000, %t33
  store float %t34, float* %t21
  %t36 = load %Particle*, %Particle** @arena.Particles.data
  %t37 = icmp eq %Particle* %t36, null
  br i1 %t37, label %spawn_init_277, label %spawn_ready_278
spawn_init_277:
  %t38 = getelementptr %Particle, %Particle* null, i32 1
  %t39 = ptrtoint %Particle* %t38 to i64
  %t40 = mul i64 %t39, 256
  %t41 = call i8* @malloc(i64 %t40)
  %t42 = bitcast i8* %t41 to %Particle*
  store %Particle* %t42, %Particle** @arena.Particles.data
  br label %spawn_ready_278
spawn_ready_278:
  %t43 = load %Particle*, %Particle** @arena.Particles.data
  %t44 = load i64, i64* @arena.Particles.free_top
  %t45 = icmp sgt i64 %t44, 0
  br i1 %t45, label %spawn_reuse_279, label %spawn_grow_280
spawn_reuse_279:
  %t46 = sub i64 %t44, 1
  store i64 %t46, i64* @arena.Particles.free_top
  %t47 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.free, i64 0, i64 %t46
  %t48 = load i64, i64* %t47
  br label %spawn_store_281
spawn_grow_280:
  %t49 = load i64, i64* @arena.Particles.count
  %t50 = icmp slt i64 %t49, 256
  br i1 %t50, label %spawn_grow_ok_283, label %spawn_capacity_warn_284
spawn_capacity_warn_284:
  %t51 = load i1, i1* @arena.Particles.warned
  br i1 %t51, label %spawn_end_282, label %spawn_warn_print_285
spawn_warn_print_285:
  store i1 1, i1* @arena.Particles.warned
  %t52 = getelementptr inbounds [141 x i8], [141 x i8]* @.str.16, i64 0, i64 0
  call i32 @puts(i8* %t52)
  br label %spawn_end_282
spawn_grow_ok_283:
  %t53 = add i64 %t49, 1
  store i64 %t53, i64* @arena.Particles.count
  br label %spawn_store_281
spawn_store_281:
  %t54 = phi i64 [ %t48, %spawn_reuse_279 ], [ %t49, %spawn_grow_ok_283 ]
  %t56 = load float, float* %t0
  %t57 = getelementptr inbounds %Particle, %Particle* %t55, i32 0, i32 0
  store float %t56, float* %t57
  %t58 = load float, float* %t1
  %t59 = getelementptr inbounds %Particle, %Particle* %t55, i32 0, i32 1
  store float %t58, float* %t59
  %t60 = load float, float* %t8
  %t61 = call float @llvm.cos.f32(float %t60)
  %t62 = load float, float* %t21
  %t63 = fmul float %t61, %t62
  %t64 = getelementptr inbounds %Particle, %Particle* %t55, i32 0, i32 2
  store float %t63, float* %t64
  %t65 = load float, float* %t8
  %t66 = call float @llvm.sin.f32(float %t65)
  %t67 = load float, float* %t21
  %t68 = fmul float %t66, %t67
  %t69 = getelementptr inbounds %Particle, %Particle* %t55, i32 0, i32 3
  store float %t68, float* %t69
  %t70 = load float, float* %t2
  %t71 = getelementptr inbounds %Particle, %Particle* %t55, i32 0, i32 4
  store float %t70, float* %t71
  %t72 = load %Particle, %Particle* %t55
  %t73 = getelementptr inbounds %Particle, %Particle* %t43, i64 %t54
  store %Particle %t72, %Particle* %t73
  %t74 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t54
  %t75 = load i64, i64* %t74
  %t76 = add i64 %t75, 1
  store i64 %t76, i64* %t74
  %t77 = trunc i64 %t54 to i32
  br label %spawn_end_282
spawn_end_282:
  %t78 = phi i32 [ %t77, %spawn_store_281 ], [ -1, %spawn_capacity_warn_284 ], [ -1, %spawn_warn_print_285 ]
  store i32 %t78, i32* %t35
  %t79 = load i32, i32* %t35
  store i32 %t79, i32* %t3
  %t80 = load i32, i32* %t5
  %t81 = add i32 %t80, 1
  store i32 %t81, i32* %t5
  br label %while_cond_273
while_else_275:
  br label %while_end_276
while_end_276:
  %t82 = load i32, i32* %t3
  ret i32 %t82
}

define i32 @parse_int_tweak(i8* %s) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t13 = alloca i32
  %t14 = alloca i32
  %t15 = alloca i1
  %t56 = alloca i32
  store i8* %s, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = call i32 @strlen(i8* %t2)
  %t5 = sext i32 %t4 to i64
  %t6 = call i8* @malloc(i64 %t5)
  call i8* @memcpy(i8* %t6, i8* %t2, i64 %t5)
  call void @star_rc_release(i8* %t2)
  %t7 = bitcast void (i8*)* @list_release_u8 to i8*
  %t8 = call i8* @star_rc_alloc(i64 24, i8* %t7)
  %t9 = bitcast i8* %t8 to { i8*, i64, i64 }*
  %t10 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t9, i32 0, i32 0
  store i8* %t6, i8** %t10
  %t11 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t9, i32 0, i32 1
  store i64 %t5, i64* %t11
  %t12 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t9, i32 0, i32 2
  store i64 %t5, i64* %t12
  store i8* %t8, i8** %t1
  store i32 0, i32* %t13
  store i32 0, i32* %t14
  store i1 false, i1* %t15
  %t16 = load i8*, i8** %t1
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %list_read_null_286, label %list_read_real_287
list_read_null_286:
  br label %list_read_end_288
list_read_real_287:
  %t18 = bitcast i8* %t16 to { i8*, i64, i64 }*
  %t19 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 0
  %t20 = load i8*, i8** %t19
  %t21 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 1
  %t22 = load i64, i64* %t21
  br label %list_read_end_288
list_read_end_288:
  %t23 = phi i8* [ null, %list_read_null_286 ], [ %t20, %list_read_real_287 ]
  %t24 = phi i64 [ 0, %list_read_null_286 ], [ %t22, %list_read_real_287 ]
  %t25 = trunc i64 %t24 to i32
  %t26 = icmp sgt i32 %t25, 0
  br i1 %t26, label %logic_rhs_289, label %logic_short_290
logic_rhs_289:
  %t27 = load i8*, i8** %t1
  %t28 = icmp eq i8* %t27, null
  br i1 %t28, label %list_read_null_292, label %list_read_real_293
list_read_null_292:
  br label %list_read_end_294
list_read_real_293:
  %t29 = bitcast i8* %t27 to { i8*, i64, i64 }*
  %t30 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t29, i32 0, i32 0
  %t31 = load i8*, i8** %t30
  %t32 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t29, i32 0, i32 1
  %t33 = load i64, i64* %t32
  br label %list_read_end_294
list_read_end_294:
  %t34 = phi i8* [ null, %list_read_null_292 ], [ %t31, %list_read_real_293 ]
  %t35 = phi i64 [ 0, %list_read_null_292 ], [ %t33, %list_read_real_293 ]
  %t36 = sext i32 0 to i64
  %t37 = icmp ult i64 %t36, %t35
  br i1 %t37, label %list_idx_ok_295, label %list_idx_oob_296
list_idx_ok_295:
  %t38 = getelementptr inbounds i8, i8* %t34, i64 %t36
  %t39 = load i8, i8* %t38
  br label %list_idx_end_297
list_idx_oob_296:
  br label %list_idx_end_297
list_idx_end_297:
  %t40 = phi i8 [ %t39, %list_idx_ok_295 ], [ 0, %list_idx_oob_296 ]
  %t41 = zext i8 %t40 to i32
  %t42 = icmp eq i32 %t41, 45
  br label %logic_end_291
logic_short_290:
  br label %logic_end_291
logic_end_291:
  %t43 = phi i1 [ %t42, %list_idx_end_297 ], [ false, %logic_short_290 ]
  br i1 %t43, label %if_then_298, label %if_else_299
if_then_298:
  store i1 true, i1* %t15
  store i32 1, i32* %t14
  br label %if_end_300
if_else_299:
  br label %if_end_300
if_end_300:
  br label %while_cond_301
while_cond_301:
  %t44 = load i32, i32* %t14
  %t45 = load i8*, i8** %t1
  %t46 = icmp eq i8* %t45, null
  br i1 %t46, label %list_read_null_305, label %list_read_real_306
list_read_null_305:
  br label %list_read_end_307
list_read_real_306:
  %t47 = bitcast i8* %t45 to { i8*, i64, i64 }*
  %t48 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t47, i32 0, i32 0
  %t49 = load i8*, i8** %t48
  %t50 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t47, i32 0, i32 1
  %t51 = load i64, i64* %t50
  br label %list_read_end_307
list_read_end_307:
  %t52 = phi i8* [ null, %list_read_null_305 ], [ %t49, %list_read_real_306 ]
  %t53 = phi i64 [ 0, %list_read_null_305 ], [ %t51, %list_read_real_306 ]
  %t54 = trunc i64 %t53 to i32
  %t55 = icmp slt i32 %t44, %t54
  br i1 %t55, label %while_body_302, label %while_else_303
while_body_302:
  %t57 = load i8*, i8** %t1
  %t58 = icmp eq i8* %t57, null
  br i1 %t58, label %list_read_null_308, label %list_read_real_309
list_read_null_308:
  br label %list_read_end_310
list_read_real_309:
  %t59 = bitcast i8* %t57 to { i8*, i64, i64 }*
  %t60 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t59, i32 0, i32 0
  %t61 = load i8*, i8** %t60
  %t62 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t59, i32 0, i32 1
  %t63 = load i64, i64* %t62
  br label %list_read_end_310
list_read_end_310:
  %t64 = phi i8* [ null, %list_read_null_308 ], [ %t61, %list_read_real_309 ]
  %t65 = phi i64 [ 0, %list_read_null_308 ], [ %t63, %list_read_real_309 ]
  %t66 = load i32, i32* %t14
  %t67 = sext i32 %t66 to i64
  %t68 = icmp ult i64 %t67, %t65
  br i1 %t68, label %list_idx_ok_311, label %list_idx_oob_312
list_idx_ok_311:
  %t69 = getelementptr inbounds i8, i8* %t64, i64 %t67
  %t70 = load i8, i8* %t69
  br label %list_idx_end_313
list_idx_oob_312:
  br label %list_idx_end_313
list_idx_end_313:
  %t71 = phi i8 [ %t70, %list_idx_ok_311 ], [ 0, %list_idx_oob_312 ]
  %t72 = zext i8 %t71 to i32
  %t73 = sub i32 %t72, 48
  store i32 %t73, i32* %t56
  %t74 = load i32, i32* %t56
  %t75 = icmp slt i32 %t74, 0
  br i1 %t75, label %logic_short_315, label %logic_rhs_314
logic_rhs_314:
  %t76 = load i32, i32* %t56
  %t77 = icmp sgt i32 %t76, 9
  br label %logic_end_316
logic_short_315:
  br label %logic_end_316
logic_end_316:
  %t78 = phi i1 [ %t77, %logic_rhs_314 ], [ true, %logic_short_315 ]
  br i1 %t78, label %if_then_317, label %if_else_318
if_then_317:
  br label %while_end_304
if_else_318:
  br label %if_end_319
if_end_319:
  %t79 = load i32, i32* %t13
  %t80 = mul i32 %t79, 10
  %t81 = load i32, i32* %t56
  %t82 = add i32 %t80, %t81
  store i32 %t82, i32* %t13
  %t83 = load i32, i32* %t14
  %t84 = add i32 %t83, 1
  store i32 %t84, i32* %t14
  br label %while_cond_301
while_else_303:
  br label %while_end_304
while_end_304:
  %t85 = load i1, i1* %t15
  br i1 %t85, label %if_then_320, label %if_else_321
if_then_320:
  %t86 = load i32, i32* %t13
  %t87 = sub i32 0, %t86
  br label %if_end_322
if_else_321:
  %t88 = load i32, i32* %t13
  br label %if_end_322
if_end_322:
  %t89 = phi i32 [ %t87, %if_then_320 ], [ %t88, %if_else_321 ]
  %t90 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t90)
  %t91 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t91)
  ret i32 %t89
}

define void @Tuning__load_from_file(%Tuning* %self, i8* %path) {
entry:
  %t0 = alloca %Tuning*
  %t1 = alloca i8*
  %t9 = alloca i8*
  %t17 = alloca i8*
  %t22 = alloca i64
  %t40 = alloca i8*
  %t47 = alloca i64
  %t65 = alloca i64
  %t107 = alloca i8*
  %t117 = alloca i8**
  %t118 = alloca i64
  %t119 = alloca i64
  %t141 = alloca i8*
  %t212 = alloca i8*
  %t233 = alloca i64
  %t251 = alloca i64
  %t274 = alloca i8*
  %t295 = alloca i64
  %t313 = alloca i64
  store %Tuning* %self, %Tuning** %t0
  store i8* %path, i8** %t1
  %t2 = load i8*, i8** %t1
  %t3 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t3)
  %t4 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.17, i64 0, i64 0
  %t5 = call i8* @fopen(i8* %t2, i8* %t4)
  call void @star_rc_release(i8* %t2)
  %t6 = icmp ne i8* %t5, null
  br i1 %t6, label %file_exists_close_323, label %file_exists_end_324
file_exists_close_323:
  call i32 @fclose(i8* %t5)
  br label %file_exists_end_324
file_exists_end_324:
  %t7 = xor i1 true, %t6
  br i1 %t7, label %if_then_325, label %if_else_326
if_then_325:
  %t8 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t8)
  ret void
if_else_326:
  br label %if_end_327
if_end_327:
  %t10 = load i8*, i8** %t1
  %t11 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t11)
  %t12 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.18, i64 0, i32 2, i64 0
  %t13 = call i8* @fopen(i8* %t10, i8* %t12)
  call void @star_rc_release(i8* %t10)
  call void @star_rc_release(i8* %t12)
  store i8* %t13, i8** %t9
  %t14 = load i8*, i8** %t9
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %if_then_328, label %if_else_329
if_then_328:
  %t16 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t16)
  ret void
if_else_329:
  br label %if_end_330
if_end_330:
  br label %while_cond_331
while_cond_331:
  br i1 true, label %while_body_332, label %while_else_333
while_body_332:
  %t18 = load i8*, i8** %t9
  %t19 = icmp eq i8* %t18, null
  br i1 %t19, label %file_null_handle_335, label %file_handle_ok_336
file_null_handle_335:
  %t20 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.19, i64 0, i64 0
  call i32 @puts(i8* %t20)
  call void @exit(i32 1)
  unreachable
file_handle_ok_336:
  %t21 = call i8* @star_rc_alloc(i64 1024, i8* null)
  store i64 0, i64* %t22
  br label %file_read_line_cond_337
file_read_line_cond_337:
  %t23 = load i64, i64* %t22
  %t24 = icmp ult i64 %t23, 1023
  br i1 %t24, label %file_read_line_body_338, label %file_read_line_end_340
file_read_line_body_338:
  %t25 = call i32 @fgetc(i8* %t18)
  %t26 = icmp eq i32 %t25, -1
  %t27 = icmp eq i32 %t25, 10
  %t28 = or i1 %t26, %t27
  br i1 %t28, label %file_read_line_end_340, label %file_read_line_store_339
file_read_line_store_339:
  %t29 = getelementptr inbounds i8, i8* %t21, i64 %t23
  %t30 = trunc i32 %t25 to i8
  store i8 %t30, i8* %t29
  %t31 = add i64 %t23, 1
  store i64 %t31, i64* %t22
  br label %file_read_line_cond_337
file_read_line_end_340:
  %t32 = load i64, i64* %t22
  %t33 = getelementptr inbounds i8, i8* %t21, i64 %t32
  store i8 0, i8* %t33
  store i8* %t21, i8** %t17
  %t34 = load i8*, i8** %t17
  %t35 = load i8*, i8** %t17
  call void @star_rc_retain(i8* %t35)
  %t36 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t37 = call i32 @strcmp(i8* %t34, i8* %t36)
  call void @star_rc_release(i8* %t34)
  call void @star_rc_release(i8* %t36)
  %t38 = icmp eq i32 %t37, 0
  br i1 %t38, label %if_then_341, label %if_else_342
if_then_341:
  %t39 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t39)
  br label %while_end_334
if_else_342:
  br label %if_end_343
if_end_343:
  %t41 = load i8*, i8** %t17
  %t42 = load i8*, i8** %t17
  call void @star_rc_retain(i8* %t42)
  %t43 = icmp eq i8* %t41, null
  %t44 = select i1 %t43, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t41
  %t45 = call i32 @strlen(i8* %t44)
  %t46 = sext i32 %t45 to i64
  store i64 0, i64* %t47
  br label %trim_start_cond_344
trim_start_cond_344:
  %t48 = load i64, i64* %t47
  %t49 = icmp slt i64 %t48, %t46
  br i1 %t49, label %trim_start_body_345, label %trim_start_done_347
trim_start_body_345:
  %t50 = getelementptr inbounds i8, i8* %t44, i64 %t48
  %t51 = load i8, i8* %t50
  %t52 = icmp eq i8 %t51, 32
  %t53 = icmp eq i8 %t51, 9
  %t54 = or i1 %t52, %t53
  %t55 = icmp eq i8 %t51, 10
  %t56 = or i1 %t54, %t55
  %t57 = icmp eq i8 %t51, 13
  %t58 = or i1 %t56, %t57
  %t59 = icmp eq i8 %t51, 11
  %t60 = or i1 %t58, %t59
  %t61 = icmp eq i8 %t51, 12
  %t62 = or i1 %t60, %t61
  br i1 %t62, label %trim_start_incr_346, label %trim_start_done_347
trim_start_incr_346:
  %t63 = add i64 %t48, 1
  store i64 %t63, i64* %t47
  br label %trim_start_cond_344
trim_start_done_347:
  %t64 = load i64, i64* %t47
  store i64 %t46, i64* %t65
  br label %trim_end_cond_348
trim_end_cond_348:
  %t66 = load i64, i64* %t65
  %t67 = icmp sgt i64 %t66, %t64
  br i1 %t67, label %trim_end_body_349, label %trim_end_done_351
trim_end_body_349:
  %t68 = sub i64 %t66, 1
  %t69 = getelementptr inbounds i8, i8* %t44, i64 %t68
  %t70 = load i8, i8* %t69
  %t71 = icmp eq i8 %t70, 32
  %t72 = icmp eq i8 %t70, 9
  %t73 = or i1 %t71, %t72
  %t74 = icmp eq i8 %t70, 10
  %t75 = or i1 %t73, %t74
  %t76 = icmp eq i8 %t70, 13
  %t77 = or i1 %t75, %t76
  %t78 = icmp eq i8 %t70, 11
  %t79 = or i1 %t77, %t78
  %t80 = icmp eq i8 %t70, 12
  %t81 = or i1 %t79, %t80
  br i1 %t81, label %trim_end_decr_350, label %trim_end_done_351
trim_end_decr_350:
  store i64 %t68, i64* %t65
  br label %trim_end_cond_348
trim_end_done_351:
  %t82 = load i64, i64* %t65
  %t83 = sub i64 %t82, %t64
  %t84 = add i64 %t83, 1
  %t85 = call i8* @star_rc_alloc(i64 %t84, i8* null)
  %t86 = getelementptr inbounds i8, i8* %t44, i64 %t64
  call i8* @memcpy(i8* %t85, i8* %t86, i64 %t83)
  %t87 = getelementptr inbounds i8, i8* %t85, i64 %t83
  store i8 0, i8* %t87
  call void @star_rc_release(i8* %t41)
  store i8* %t85, i8** %t40
  %t88 = load i8*, i8** %t40
  %t89 = load i8*, i8** %t40
  call void @star_rc_retain(i8* %t89)
  %t90 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t91 = call i32 @strcmp(i8* %t88, i8* %t90)
  call void @star_rc_release(i8* %t88)
  call void @star_rc_release(i8* %t90)
  %t92 = icmp eq i32 %t91, 0
  br i1 %t92, label %logic_short_353, label %logic_rhs_352
logic_rhs_352:
  %t93 = load i8*, i8** %t40
  %t94 = load i8*, i8** %t40
  call void @star_rc_retain(i8* %t94)
  %t95 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.22, i64 0, i32 2, i64 0
  %t96 = icmp eq i8* %t93, null
  %t97 = select i1 %t96, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t93
  %t98 = icmp eq i8* %t95, null
  %t99 = select i1 %t98, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t95
  %t100 = call i32 @strlen(i8* %t99)
  %t101 = sext i32 %t100 to i64
  %t102 = call i32 @strncmp(i8* %t97, i8* %t99, i64 %t101)
  %t103 = icmp eq i32 %t102, 0
  call void @star_rc_release(i8* %t93)
  call void @star_rc_release(i8* %t95)
  br label %logic_end_354
logic_short_353:
  br label %logic_end_354
logic_end_354:
  %t104 = phi i1 [ %t103, %logic_rhs_352 ], [ true, %logic_short_353 ]
  br i1 %t104, label %if_then_355, label %if_else_356
if_then_355:
  %t105 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t105)
  %t106 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t106)
  br label %while_cond_331
if_else_356:
  br label %if_end_357
if_end_357:
  %t108 = load i8*, i8** %t40
  %t109 = load i8*, i8** %t40
  call void @star_rc_retain(i8* %t109)
  %t110 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.23, i64 0, i32 2, i64 0
  %t111 = icmp eq i8* %t108, null
  %t112 = select i1 %t111, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t108
  %t113 = icmp eq i8* %t110, null
  %t114 = select i1 %t113, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t110
  %t115 = call i32 @strlen(i8* %t114)
  %t116 = sext i32 %t115 to i64
  store i8** null, i8*** %t117
  store i64 0, i64* %t118
  store i64 0, i64* %t119
  %t120 = icmp eq i64 %t116, 0
  br i1 %t120, label %split_single_358, label %split_scan_init_359
split_single_358:
  %t121 = call i32 @strlen(i8* %t112)
  %t122 = sext i32 %t121 to i64
  %t123 = add i64 %t122, 1
  %t124 = call i8* @star_rc_alloc(i64 %t123, i8* null)
  call i8* @strcpy(i8* %t124, i8* %t112)
  %t125 = load i64, i64* %t118
  %t126 = load i64, i64* %t119
  %t127 = icmp sge i64 %t125, %t126
  br i1 %t127, label %dynstr_grow_361, label %dynstr_store_362
dynstr_grow_361:
  %t128 = mul i64 %t126, 2
  %t129 = icmp sgt i64 %t128, 0
  %t130 = select i1 %t129, i64 %t128, i64 4
  %t131 = mul i64 %t130, 8
  %t132 = call i8* @malloc(i64 %t131)
  %t133 = bitcast i8* %t132 to i8**
  %t134 = icmp sgt i64 %t126, 0
  br i1 %t134, label %dynstr_copy_363, label %dynstr_after_copy_364
dynstr_copy_363:
  %t135 = load i8**, i8*** %t117
  %t136 = mul i64 %t125, 8
  %t137 = bitcast i8** %t135 to i8*
  call i8* @memcpy(i8* %t132, i8* %t137, i64 %t136)
  call void @free(i8* %t137)
  br label %dynstr_after_copy_364
dynstr_after_copy_364:
  store i8** %t133, i8*** %t117
  store i64 %t130, i64* %t119
  br label %dynstr_store_362
dynstr_store_362:
  %t138 = load i8**, i8*** %t117
  %t139 = getelementptr inbounds i8*, i8** %t138, i64 %t125
  store i8* %t124, i8** %t139
  %t140 = add i64 %t125, 1
  store i64 %t140, i64* %t118
  br label %split_finish_360
split_scan_init_359:
  store i8* %t112, i8** %t141
  br label %split_scan_cond_365
split_scan_cond_365:
  %t142 = load i8*, i8** %t141
  %t143 = call i8* @strstr(i8* %t142, i8* %t114)
  %t144 = icmp eq i8* %t143, null
  br i1 %t144, label %split_tail_367, label %split_match_366
split_match_366:
  %t145 = ptrtoint i8* %t143 to i64
  %t146 = ptrtoint i8* %t142 to i64
  %t147 = sub i64 %t145, %t146
  %t148 = add i64 %t147, 1
  %t149 = call i8* @star_rc_alloc(i64 %t148, i8* null)
  call i8* @memcpy(i8* %t149, i8* %t142, i64 %t147)
  %t150 = getelementptr inbounds i8, i8* %t149, i64 %t147
  store i8 0, i8* %t150
  %t151 = load i64, i64* %t118
  %t152 = load i64, i64* %t119
  %t153 = icmp sge i64 %t151, %t152
  br i1 %t153, label %dynstr_grow_368, label %dynstr_store_369
dynstr_grow_368:
  %t154 = mul i64 %t152, 2
  %t155 = icmp sgt i64 %t154, 0
  %t156 = select i1 %t155, i64 %t154, i64 4
  %t157 = mul i64 %t156, 8
  %t158 = call i8* @malloc(i64 %t157)
  %t159 = bitcast i8* %t158 to i8**
  %t160 = icmp sgt i64 %t152, 0
  br i1 %t160, label %dynstr_copy_370, label %dynstr_after_copy_371
dynstr_copy_370:
  %t161 = load i8**, i8*** %t117
  %t162 = mul i64 %t151, 8
  %t163 = bitcast i8** %t161 to i8*
  call i8* @memcpy(i8* %t158, i8* %t163, i64 %t162)
  call void @free(i8* %t163)
  br label %dynstr_after_copy_371
dynstr_after_copy_371:
  store i8** %t159, i8*** %t117
  store i64 %t156, i64* %t119
  br label %dynstr_store_369
dynstr_store_369:
  %t164 = load i8**, i8*** %t117
  %t165 = getelementptr inbounds i8*, i8** %t164, i64 %t151
  store i8* %t149, i8** %t165
  %t166 = add i64 %t151, 1
  store i64 %t166, i64* %t118
  %t167 = getelementptr inbounds i8, i8* %t143, i64 %t116
  store i8* %t167, i8** %t141
  br label %split_scan_cond_365
split_tail_367:
  %t168 = load i8*, i8** %t141
  %t169 = call i32 @strlen(i8* %t168)
  %t170 = sext i32 %t169 to i64
  %t171 = add i64 %t170, 1
  %t172 = call i8* @star_rc_alloc(i64 %t171, i8* null)
  call i8* @strcpy(i8* %t172, i8* %t168)
  %t173 = load i64, i64* %t118
  %t174 = load i64, i64* %t119
  %t175 = icmp sge i64 %t173, %t174
  br i1 %t175, label %dynstr_grow_372, label %dynstr_store_373
dynstr_grow_372:
  %t176 = mul i64 %t174, 2
  %t177 = icmp sgt i64 %t176, 0
  %t178 = select i1 %t177, i64 %t176, i64 4
  %t179 = mul i64 %t178, 8
  %t180 = call i8* @malloc(i64 %t179)
  %t181 = bitcast i8* %t180 to i8**
  %t182 = icmp sgt i64 %t174, 0
  br i1 %t182, label %dynstr_copy_374, label %dynstr_after_copy_375
dynstr_copy_374:
  %t183 = load i8**, i8*** %t117
  %t184 = mul i64 %t173, 8
  %t185 = bitcast i8** %t183 to i8*
  call i8* @memcpy(i8* %t180, i8* %t185, i64 %t184)
  call void @free(i8* %t185)
  br label %dynstr_after_copy_375
dynstr_after_copy_375:
  store i8** %t181, i8*** %t117
  store i64 %t178, i64* %t119
  br label %dynstr_store_373
dynstr_store_373:
  %t186 = load i8**, i8*** %t117
  %t187 = getelementptr inbounds i8*, i8** %t186, i64 %t173
  store i8* %t172, i8** %t187
  %t188 = add i64 %t173, 1
  store i64 %t188, i64* %t118
  br label %split_finish_360
split_finish_360:
  call void @star_rc_release(i8* %t108)
  call void @star_rc_release(i8* %t110)
  %t189 = bitcast void (i8*)* @list_release_str to i8*
  %t190 = call i8* @star_rc_alloc(i64 24, i8* %t189)
  %t191 = bitcast i8* %t190 to { i8**, i64, i64 }*
  %t192 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t191, i32 0, i32 0
  %t193 = load i8**, i8*** %t117
  store i8** %t193, i8*** %t192
  %t194 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t191, i32 0, i32 1
  %t195 = load i64, i64* %t118
  store i64 %t195, i64* %t194
  %t196 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t191, i32 0, i32 2
  %t197 = load i64, i64* %t119
  store i64 %t197, i64* %t196
  store i8* %t190, i8** %t107
  %t198 = load i8*, i8** %t107
  %t199 = icmp eq i8* %t198, null
  br i1 %t199, label %list_read_null_376, label %list_read_real_377
list_read_null_376:
  br label %list_read_end_378
list_read_real_377:
  %t200 = bitcast i8* %t198 to { i8**, i64, i64 }*
  %t201 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t200, i32 0, i32 0
  %t202 = load i8**, i8*** %t201
  %t203 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t200, i32 0, i32 1
  %t204 = load i64, i64* %t203
  br label %list_read_end_378
list_read_end_378:
  %t205 = phi i8** [ null, %list_read_null_376 ], [ %t202, %list_read_real_377 ]
  %t206 = phi i64 [ 0, %list_read_null_376 ], [ %t204, %list_read_real_377 ]
  %t207 = trunc i64 %t206 to i32
  %t208 = icmp ne i32 %t207, 2
  br i1 %t208, label %if_then_379, label %if_else_380
if_then_379:
  %t209 = load i8*, i8** %t107
  call void @star_rc_release(i8* %t209)
  %t210 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t210)
  %t211 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t211)
  br label %while_cond_331
if_else_380:
  br label %if_end_381
if_end_381:
  %t213 = load i8*, i8** %t107
  %t214 = icmp eq i8* %t213, null
  br i1 %t214, label %list_read_null_382, label %list_read_real_383
list_read_null_382:
  br label %list_read_end_384
list_read_real_383:
  %t215 = bitcast i8* %t213 to { i8**, i64, i64 }*
  %t216 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t215, i32 0, i32 0
  %t217 = load i8**, i8*** %t216
  %t218 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t215, i32 0, i32 1
  %t219 = load i64, i64* %t218
  br label %list_read_end_384
list_read_end_384:
  %t220 = phi i8** [ null, %list_read_null_382 ], [ %t217, %list_read_real_383 ]
  %t221 = phi i64 [ 0, %list_read_null_382 ], [ %t219, %list_read_real_383 ]
  %t222 = sext i32 0 to i64
  %t223 = icmp ult i64 %t222, %t221
  br i1 %t223, label %list_idx_ok_385, label %list_idx_oob_386
list_idx_ok_385:
  %t224 = getelementptr inbounds i8*, i8** %t220, i64 %t222
  %t225 = load i8*, i8** %t224
  %t226 = load i8*, i8** %t224
  call void @star_rc_retain(i8* %t226)
  br label %list_idx_end_387
list_idx_oob_386:
  %t227 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t227
  br label %list_idx_end_387
list_idx_end_387:
  %t228 = phi i8* [ %t225, %list_idx_ok_385 ], [ %t227, %list_idx_oob_386 ]
  %t229 = icmp eq i8* %t228, null
  %t230 = select i1 %t229, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t228
  %t231 = call i32 @strlen(i8* %t230)
  %t232 = sext i32 %t231 to i64
  store i64 0, i64* %t233
  br label %trim_start_cond_388
trim_start_cond_388:
  %t234 = load i64, i64* %t233
  %t235 = icmp slt i64 %t234, %t232
  br i1 %t235, label %trim_start_body_389, label %trim_start_done_391
trim_start_body_389:
  %t236 = getelementptr inbounds i8, i8* %t230, i64 %t234
  %t237 = load i8, i8* %t236
  %t238 = icmp eq i8 %t237, 32
  %t239 = icmp eq i8 %t237, 9
  %t240 = or i1 %t238, %t239
  %t241 = icmp eq i8 %t237, 10
  %t242 = or i1 %t240, %t241
  %t243 = icmp eq i8 %t237, 13
  %t244 = or i1 %t242, %t243
  %t245 = icmp eq i8 %t237, 11
  %t246 = or i1 %t244, %t245
  %t247 = icmp eq i8 %t237, 12
  %t248 = or i1 %t246, %t247
  br i1 %t248, label %trim_start_incr_390, label %trim_start_done_391
trim_start_incr_390:
  %t249 = add i64 %t234, 1
  store i64 %t249, i64* %t233
  br label %trim_start_cond_388
trim_start_done_391:
  %t250 = load i64, i64* %t233
  store i64 %t232, i64* %t251
  br label %trim_end_cond_392
trim_end_cond_392:
  %t252 = load i64, i64* %t251
  %t253 = icmp sgt i64 %t252, %t250
  br i1 %t253, label %trim_end_body_393, label %trim_end_done_395
trim_end_body_393:
  %t254 = sub i64 %t252, 1
  %t255 = getelementptr inbounds i8, i8* %t230, i64 %t254
  %t256 = load i8, i8* %t255
  %t257 = icmp eq i8 %t256, 32
  %t258 = icmp eq i8 %t256, 9
  %t259 = or i1 %t257, %t258
  %t260 = icmp eq i8 %t256, 10
  %t261 = or i1 %t259, %t260
  %t262 = icmp eq i8 %t256, 13
  %t263 = or i1 %t261, %t262
  %t264 = icmp eq i8 %t256, 11
  %t265 = or i1 %t263, %t264
  %t266 = icmp eq i8 %t256, 12
  %t267 = or i1 %t265, %t266
  br i1 %t267, label %trim_end_decr_394, label %trim_end_done_395
trim_end_decr_394:
  store i64 %t254, i64* %t251
  br label %trim_end_cond_392
trim_end_done_395:
  %t268 = load i64, i64* %t251
  %t269 = sub i64 %t268, %t250
  %t270 = add i64 %t269, 1
  %t271 = call i8* @star_rc_alloc(i64 %t270, i8* null)
  %t272 = getelementptr inbounds i8, i8* %t230, i64 %t250
  call i8* @memcpy(i8* %t271, i8* %t272, i64 %t269)
  %t273 = getelementptr inbounds i8, i8* %t271, i64 %t269
  store i8 0, i8* %t273
  call void @star_rc_release(i8* %t228)
  store i8* %t271, i8** %t212
  %t275 = load i8*, i8** %t107
  %t276 = icmp eq i8* %t275, null
  br i1 %t276, label %list_read_null_396, label %list_read_real_397
list_read_null_396:
  br label %list_read_end_398
list_read_real_397:
  %t277 = bitcast i8* %t275 to { i8**, i64, i64 }*
  %t278 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t277, i32 0, i32 0
  %t279 = load i8**, i8*** %t278
  %t280 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t277, i32 0, i32 1
  %t281 = load i64, i64* %t280
  br label %list_read_end_398
list_read_end_398:
  %t282 = phi i8** [ null, %list_read_null_396 ], [ %t279, %list_read_real_397 ]
  %t283 = phi i64 [ 0, %list_read_null_396 ], [ %t281, %list_read_real_397 ]
  %t284 = sext i32 1 to i64
  %t285 = icmp ult i64 %t284, %t283
  br i1 %t285, label %list_idx_ok_399, label %list_idx_oob_400
list_idx_ok_399:
  %t286 = getelementptr inbounds i8*, i8** %t282, i64 %t284
  %t287 = load i8*, i8** %t286
  %t288 = load i8*, i8** %t286
  call void @star_rc_retain(i8* %t288)
  br label %list_idx_end_401
list_idx_oob_400:
  %t289 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t289
  br label %list_idx_end_401
list_idx_end_401:
  %t290 = phi i8* [ %t287, %list_idx_ok_399 ], [ %t289, %list_idx_oob_400 ]
  %t291 = icmp eq i8* %t290, null
  %t292 = select i1 %t291, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t290
  %t293 = call i32 @strlen(i8* %t292)
  %t294 = sext i32 %t293 to i64
  store i64 0, i64* %t295
  br label %trim_start_cond_402
trim_start_cond_402:
  %t296 = load i64, i64* %t295
  %t297 = icmp slt i64 %t296, %t294
  br i1 %t297, label %trim_start_body_403, label %trim_start_done_405
trim_start_body_403:
  %t298 = getelementptr inbounds i8, i8* %t292, i64 %t296
  %t299 = load i8, i8* %t298
  %t300 = icmp eq i8 %t299, 32
  %t301 = icmp eq i8 %t299, 9
  %t302 = or i1 %t300, %t301
  %t303 = icmp eq i8 %t299, 10
  %t304 = or i1 %t302, %t303
  %t305 = icmp eq i8 %t299, 13
  %t306 = or i1 %t304, %t305
  %t307 = icmp eq i8 %t299, 11
  %t308 = or i1 %t306, %t307
  %t309 = icmp eq i8 %t299, 12
  %t310 = or i1 %t308, %t309
  br i1 %t310, label %trim_start_incr_404, label %trim_start_done_405
trim_start_incr_404:
  %t311 = add i64 %t296, 1
  store i64 %t311, i64* %t295
  br label %trim_start_cond_402
trim_start_done_405:
  %t312 = load i64, i64* %t295
  store i64 %t294, i64* %t313
  br label %trim_end_cond_406
trim_end_cond_406:
  %t314 = load i64, i64* %t313
  %t315 = icmp sgt i64 %t314, %t312
  br i1 %t315, label %trim_end_body_407, label %trim_end_done_409
trim_end_body_407:
  %t316 = sub i64 %t314, 1
  %t317 = getelementptr inbounds i8, i8* %t292, i64 %t316
  %t318 = load i8, i8* %t317
  %t319 = icmp eq i8 %t318, 32
  %t320 = icmp eq i8 %t318, 9
  %t321 = or i1 %t319, %t320
  %t322 = icmp eq i8 %t318, 10
  %t323 = or i1 %t321, %t322
  %t324 = icmp eq i8 %t318, 13
  %t325 = or i1 %t323, %t324
  %t326 = icmp eq i8 %t318, 11
  %t327 = or i1 %t325, %t326
  %t328 = icmp eq i8 %t318, 12
  %t329 = or i1 %t327, %t328
  br i1 %t329, label %trim_end_decr_408, label %trim_end_done_409
trim_end_decr_408:
  store i64 %t316, i64* %t313
  br label %trim_end_cond_406
trim_end_done_409:
  %t330 = load i64, i64* %t313
  %t331 = sub i64 %t330, %t312
  %t332 = add i64 %t331, 1
  %t333 = call i8* @star_rc_alloc(i64 %t332, i8* null)
  %t334 = getelementptr inbounds i8, i8* %t292, i64 %t312
  call i8* @memcpy(i8* %t333, i8* %t334, i64 %t331)
  %t335 = getelementptr inbounds i8, i8* %t333, i64 %t331
  store i8 0, i8* %t335
  call void @star_rc_release(i8* %t290)
  store i8* %t333, i8** %t274
  %t348 = load %Tuning*, %Tuning** %t0
  %t349 = load i8*, i8** %t212
  %t350 = load i8*, i8** %t212
  call void @star_rc_retain(i8* %t350)
  %t351 = call i1 @__star_reflect_has_field_Tuning(i8* %t349)
  %t352 = xor i1 true, %t351
  br i1 %t352, label %if_then_418, label %if_else_419
if_then_418:
  %t353 = load i8*, i8** %t212
  %t354 = load i8*, i8** %t212
  call void @star_rc_retain(i8* %t354)
  call void @star_rc_release(i8* %t353)
  %t355 = load i8*, i8** %t1
  %t356 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t356)
  call void @star_rc_release(i8* %t355)
  %t357 = getelementptr inbounds [42 x i8], [42 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t357, i8* %t353, i8* %t355)
  %t358 = load i8*, i8** %t274
  call void @star_rc_release(i8* %t358)
  %t359 = load i8*, i8** %t212
  call void @star_rc_release(i8* %t359)
  %t360 = load i8*, i8** %t107
  call void @star_rc_release(i8* %t360)
  %t361 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t361)
  %t362 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t362)
  br label %while_cond_331
if_else_419:
  br label %if_end_420
if_end_420:
  %t363 = load i8*, i8** %t212
  %t364 = load i8*, i8** %t212
  call void @star_rc_retain(i8* %t364)
  %t365 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.29, i64 0, i32 2, i64 0
  %t366 = call i32 @strcmp(i8* %t363, i8* %t365)
  call void @star_rc_release(i8* %t363)
  call void @star_rc_release(i8* %t365)
  %t367 = icmp eq i32 %t366, 0
  br i1 %t367, label %if_then_421, label %if_else_422
if_then_421:
  %t372 = load %Tuning*, %Tuning** %t0
  %t373 = load i8*, i8** %t212
  %t374 = load i8*, i8** %t212
  call void @star_rc_retain(i8* %t374)
  %t375 = load i8*, i8** %t274
  %t376 = load i8*, i8** %t274
  call void @star_rc_retain(i8* %t376)
  %t377 = call i32 @parse_int_tweak(i8* %t375)
  call void @__star_reflect_set_i32_Tuning(%Tuning* %t372, i8* %t373, i32 %t377)
  %t378 = load i8*, i8** %t274
  call void @star_rc_release(i8* %t378)
  %t379 = load i8*, i8** %t212
  call void @star_rc_release(i8* %t379)
  %t380 = load i8*, i8** %t107
  call void @star_rc_release(i8* %t380)
  %t381 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t381)
  %t382 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t382)
  br label %while_cond_331
if_else_422:
  br label %if_end_423
if_end_423:
  %t383 = load i8*, i8** %t212
  %t384 = load i8*, i8** %t212
  call void @star_rc_retain(i8* %t384)
  %t385 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.30, i64 0, i32 2, i64 0
  %t386 = call i32 @strcmp(i8* %t383, i8* %t385)
  call void @star_rc_release(i8* %t383)
  call void @star_rc_release(i8* %t385)
  %t387 = icmp eq i32 %t386, 0
  br i1 %t387, label %if_then_426, label %if_else_427
if_then_426:
  %t392 = load %Tuning*, %Tuning** %t0
  %t393 = load i8*, i8** %t212
  %t394 = load i8*, i8** %t212
  call void @star_rc_retain(i8* %t394)
  %t395 = load i8*, i8** %t274
  %t396 = load i8*, i8** %t274
  call void @star_rc_retain(i8* %t396)
  %t397 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.31, i64 0, i32 2, i64 0
  %t398 = call i32 @strcmp(i8* %t395, i8* %t397)
  call void @star_rc_release(i8* %t395)
  call void @star_rc_release(i8* %t397)
  %t399 = icmp eq i32 %t398, 0
  call void @__star_reflect_set_bool_Tuning(%Tuning* %t392, i8* %t393, i1 %t399)
  %t400 = load i8*, i8** %t274
  call void @star_rc_release(i8* %t400)
  %t401 = load i8*, i8** %t212
  call void @star_rc_release(i8* %t401)
  %t402 = load i8*, i8** %t107
  call void @star_rc_release(i8* %t402)
  %t403 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t403)
  %t404 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t404)
  br label %while_cond_331
if_else_427:
  br label %if_end_428
if_end_428:
  %t413 = load %Tuning*, %Tuning** %t0
  %t414 = load i8*, i8** %t212
  %t415 = load i8*, i8** %t212
  call void @star_rc_retain(i8* %t415)
  %t416 = load i8*, i8** %t274
  %t417 = load i8*, i8** %t274
  call void @star_rc_retain(i8* %t417)
  %t418 = call double @atof(i8* %t416)
  call void @star_rc_release(i8* %t416)
  %t419 = fptrunc double %t418 to float
  call void @__star_reflect_set_f32_Tuning(%Tuning* %t413, i8* %t414, float %t419)
  %t420 = load i8*, i8** %t274
  call void @star_rc_release(i8* %t420)
  %t421 = load i8*, i8** %t212
  call void @star_rc_release(i8* %t421)
  %t422 = load i8*, i8** %t107
  call void @star_rc_release(i8* %t422)
  %t423 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t423)
  %t424 = load i8*, i8** %t17
  call void @star_rc_release(i8* %t424)
  br label %while_cond_331
while_else_333:
  br label %while_end_334
while_end_334:
  %t425 = load i8*, i8** %t9
  %t426 = icmp eq i8* %t425, null
  br i1 %t426, label %file_null_handle_435, label %file_handle_ok_436
file_null_handle_435:
  %t427 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.32, i64 0, i64 0
  call i32 @puts(i8* %t427)
  call void @exit(i32 1)
  unreachable
file_handle_ok_436:
  call i32 @fclose(i8* %t425)
  store i8* null, i8** %t9
  %t428 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t428)
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
  br i1 %t4, label %if_then_437, label %if_else_438
if_then_437:
  %t5 = load %FlashOnEat*, %FlashOnEat** %t0
  %t6 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %sdl_null_window_440, label %sdl_window_handle_ok_441
sdl_null_window_440:
  %t9 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.33, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_441:
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
  br i1 %t35, label %sdl_null_window_442, label %sdl_window_handle_ok_443
sdl_null_window_442:
  %t36 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.34, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_443:
  %t37 = call i8* @SDL_GetRenderer(i8* %t34)
  call void @SDL_RenderPresent(i8* %t37)
  %t38 = icmp slt i32 35, 0
  %t39 = select i1 %t38, i32 0, i32 35
  call void @SDL_Delay(i32 %t39)
  %t40 = load %FlashOnEat*, %FlashOnEat** %t0
  %t41 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t40, i32 0, i32 1
  store i32 1, i32* %t41
  ret i1 true
if_else_438:
  %t42 = load %FlashOnEat*, %FlashOnEat** %t0
  %t43 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t44, 1
  br i1 %t45, label %if_then_444, label %if_else_445
if_then_444:
  %t46 = load %FlashOnEat*, %FlashOnEat** %t0
  %t47 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t46, i32 0, i32 1
  store i32 2, i32* %t47
  ret i1 false
if_else_445:
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
  br i1 %t4, label %if_then_447, label %if_else_448
if_then_447:
  %t5 = load %GameOverFlash*, %GameOverFlash** %t0
  %t6 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %sdl_null_window_450, label %sdl_window_handle_ok_451
sdl_null_window_450:
  %t9 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.35, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_451:
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
  br i1 %t35, label %sdl_null_window_452, label %sdl_window_handle_ok_453
sdl_null_window_452:
  %t36 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.36, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_453:
  %t37 = call i8* @SDL_GetRenderer(i8* %t34)
  call void @SDL_RenderPresent(i8* %t37)
  %t38 = icmp slt i32 110, 0
  %t39 = select i1 %t38, i32 0, i32 110
  call void @SDL_Delay(i32 %t39)
  %t40 = load %GameOverFlash*, %GameOverFlash** %t0
  %t41 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t40, i32 0, i32 1
  store i32 1, i32* %t41
  ret i1 true
if_else_448:
  %t42 = load %GameOverFlash*, %GameOverFlash** %t0
  %t43 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t44, 1
  br i1 %t45, label %if_then_454, label %if_else_455
if_then_454:
  %t46 = load %GameOverFlash*, %GameOverFlash** %t0
  %t47 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t46, i32 0, i32 0
  %t48 = load i8*, i8** %t47
  %t49 = icmp eq i8* %t48, null
  br i1 %t49, label %sdl_null_window_457, label %sdl_window_handle_ok_458
sdl_null_window_457:
  %t50 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.37, i64 0, i64 0
  call i32 @puts(i8* %t50)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_458:
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
  br i1 %t76, label %sdl_null_window_459, label %sdl_window_handle_ok_460
sdl_null_window_459:
  %t77 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.38, i64 0, i64 0
  call i32 @puts(i8* %t77)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_460:
  %t78 = call i8* @SDL_GetRenderer(i8* %t75)
  call void @SDL_RenderPresent(i8* %t78)
  %t79 = icmp slt i32 110, 0
  %t80 = select i1 %t79, i32 0, i32 110
  call void @SDL_Delay(i32 %t80)
  %t81 = load %GameOverFlash*, %GameOverFlash** %t0
  %t82 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t81, i32 0, i32 1
  store i32 2, i32* %t82
  ret i1 true
if_else_455:
  %t83 = load %GameOverFlash*, %GameOverFlash** %t0
  %t84 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t83, i32 0, i32 1
  %t85 = load i32, i32* %t84
  %t86 = icmp eq i32 %t85, 2
  br i1 %t86, label %if_then_461, label %if_else_462
if_then_461:
  %t87 = load %GameOverFlash*, %GameOverFlash** %t0
  %t88 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t87, i32 0, i32 1
  store i32 3, i32* %t88
  ret i1 false
if_else_462:
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
  br i1 %t1, label %spawn_init_464, label %spawn_ready_465
spawn_init_464:
  %t2 = getelementptr %ScratchSlot, %ScratchSlot* null, i32 1
  %t3 = ptrtoint %ScratchSlot* %t2 to i64
  %t4 = mul i64 %t3, 1024
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to %ScratchSlot*
  store %ScratchSlot* %t6, %ScratchSlot** @arena.Scratch.data
  br label %spawn_ready_465
spawn_ready_465:
  %t7 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t8 = load i64, i64* @arena.Scratch.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_466, label %spawn_grow_467
spawn_reuse_466:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Scratch.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_468
spawn_grow_467:
  %t13 = load i64, i64* @arena.Scratch.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_470, label %spawn_capacity_warn_471
spawn_capacity_warn_471:
  %t15 = load i1, i1* @arena.Scratch.warned
  br i1 %t15, label %spawn_end_469, label %spawn_warn_print_472
spawn_warn_print_472:
  store i1 1, i1* @arena.Scratch.warned
  %t16 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.39, i64 0, i64 0
  call i32 @puts(i8* %t16)
  br label %spawn_end_469
spawn_grow_ok_470:
  %t17 = add i64 %t13, 1
  store i64 %t17, i64* @arena.Scratch.count
  br label %spawn_store_468
spawn_store_468:
  %t18 = phi i64 [ %t12, %spawn_reuse_466 ], [ %t13, %spawn_grow_ok_470 ]
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
  br label %spawn_end_469
spawn_end_469:
  %t27 = phi i32 [ %t26, %spawn_store_468 ], [ -1, %spawn_capacity_warn_471 ], [ -1, %spawn_warn_print_472 ]
  %t29 = sext i32 0 to i64
  %t30 = icmp ult i64 %t29, 1024
  br i1 %t30, label %genref_create_ok_473, label %genref_create_oob_474
genref_create_ok_473:
  %t31 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t29
  %t32 = load i64, i64* %t31
  br label %genref_create_end_475
genref_create_oob_474:
  br label %genref_create_end_475
genref_create_end_475:
  %t33 = phi i64 [ %t32, %genref_create_ok_473 ], [ 0, %genref_create_oob_474 ]
  %t35 = getelementptr inbounds %GenRef, %GenRef* %t34, i32 0, i32 0
  store i32 0, i32* %t35
  %t36 = getelementptr inbounds %GenRef, %GenRef* %t34, i32 0, i32 1
  store i64 %t33, i64* %t36
  %t37 = load %GenRef, %GenRef* %t34
  store %GenRef %t37, %GenRef* %t28
  %t38 = sext i32 0 to i64
  %t39 = icmp ult i64 %t38, 1024
  br i1 %t39, label %despawn_do_476, label %despawn_end_477
despawn_do_476:
  %t40 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t38
  %t41 = load i64, i64* %t40
  %t42 = and i64 %t41, 1
  %t43 = icmp eq i64 %t42, 1
  br i1 %t43, label %despawn_live_478, label %despawn_end_477
despawn_live_478:
  %t44 = add i64 %t41, 1
  store i64 %t44, i64* %t40
  %t45 = load i64, i64* @arena.Scratch.free_top
  %t46 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t45
  store i64 %t38, i64* %t46
  %t47 = add i64 %t45, 1
  store i64 %t47, i64* @arena.Scratch.free_top
  br label %despawn_end_477
despawn_end_477:
  %t48 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t49 = icmp eq %ScratchSlot* %t48, null
  br i1 %t49, label %spawn_init_479, label %spawn_ready_480
spawn_init_479:
  %t50 = getelementptr %ScratchSlot, %ScratchSlot* null, i32 1
  %t51 = ptrtoint %ScratchSlot* %t50 to i64
  %t52 = mul i64 %t51, 1024
  %t53 = call i8* @malloc(i64 %t52)
  %t54 = bitcast i8* %t53 to %ScratchSlot*
  store %ScratchSlot* %t54, %ScratchSlot** @arena.Scratch.data
  br label %spawn_ready_480
spawn_ready_480:
  %t55 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t56 = load i64, i64* @arena.Scratch.free_top
  %t57 = icmp sgt i64 %t56, 0
  br i1 %t57, label %spawn_reuse_481, label %spawn_grow_482
spawn_reuse_481:
  %t58 = sub i64 %t56, 1
  store i64 %t58, i64* @arena.Scratch.free_top
  %t59 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t58
  %t60 = load i64, i64* %t59
  br label %spawn_store_483
spawn_grow_482:
  %t61 = load i64, i64* @arena.Scratch.count
  %t62 = icmp slt i64 %t61, 1024
  br i1 %t62, label %spawn_grow_ok_485, label %spawn_capacity_warn_486
spawn_capacity_warn_486:
  %t63 = load i1, i1* @arena.Scratch.warned
  br i1 %t63, label %spawn_end_484, label %spawn_warn_print_487
spawn_warn_print_487:
  store i1 1, i1* @arena.Scratch.warned
  %t64 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.40, i64 0, i64 0
  call i32 @puts(i8* %t64)
  br label %spawn_end_484
spawn_grow_ok_485:
  %t65 = add i64 %t61, 1
  store i64 %t65, i64* @arena.Scratch.count
  br label %spawn_store_483
spawn_store_483:
  %t66 = phi i64 [ %t60, %spawn_reuse_481 ], [ %t61, %spawn_grow_ok_485 ]
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
  br label %spawn_end_484
spawn_end_484:
  %t75 = phi i32 [ %t74, %spawn_store_483 ], [ -1, %spawn_capacity_warn_486 ], [ -1, %spawn_warn_print_487 ]
  %t77 = sext i32 0 to i64
  %t78 = icmp ult i64 %t77, 1024
  br i1 %t78, label %genref_create_ok_488, label %genref_create_oob_489
genref_create_ok_488:
  %t79 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t77
  %t80 = load i64, i64* %t79
  br label %genref_create_end_490
genref_create_oob_489:
  br label %genref_create_end_490
genref_create_end_490:
  %t81 = phi i64 [ %t80, %genref_create_ok_488 ], [ 0, %genref_create_oob_489 ]
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
  br i1 %t91, label %genref_place_check_491, label %genref_place_stale_493
genref_place_check_491:
  %t92 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t90
  %t93 = load i64, i64* %t92
  %t94 = icmp eq i64 %t89, %t93
  %t95 = and i64 %t93, 1
  %t96 = icmp eq i64 %t95, 1
  %t97 = and i1 %t94, %t96
  br i1 %t97, label %genref_place_ok_492, label %genref_place_stale_493
genref_place_ok_492:
  %t98 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t99 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t98, i64 %t90
  br label %genref_place_end_494
genref_place_stale_493:
  store %ScratchSlot zeroinitializer, %ScratchSlot* %t100
  br label %genref_place_end_494
genref_place_end_494:
  %t101 = phi %ScratchSlot* [ %t99, %genref_place_ok_492 ], [ %t100, %genref_place_stale_493 ]
  %t102 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t101, i32 0, i32 0
  %t103 = load i32, i32* %t102
  %t104 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.41, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t104, i32 %t103)
  %t105 = getelementptr inbounds %GenRef, %GenRef* %t76, i32 0, i32 0
  %t106 = load i32, i32* %t105
  %t107 = getelementptr inbounds %GenRef, %GenRef* %t76, i32 0, i32 1
  %t108 = load i64, i64* %t107
  %t109 = sext i32 %t106 to i64
  %t110 = icmp ult i64 %t109, 1024
  br i1 %t110, label %genref_place_check_495, label %genref_place_stale_497
genref_place_check_495:
  %t111 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t109
  %t112 = load i64, i64* %t111
  %t113 = icmp eq i64 %t108, %t112
  %t114 = and i64 %t112, 1
  %t115 = icmp eq i64 %t114, 1
  %t116 = and i1 %t113, %t115
  br i1 %t116, label %genref_place_ok_496, label %genref_place_stale_497
genref_place_ok_496:
  %t117 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t118 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t117, i64 %t109
  br label %genref_place_end_498
genref_place_stale_497:
  store %ScratchSlot zeroinitializer, %ScratchSlot* %t119
  br label %genref_place_end_498
genref_place_end_498:
  %t120 = phi %ScratchSlot* [ %t118, %genref_place_ok_496 ], [ %t119, %genref_place_stale_497 ]
  %t121 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t120, i32 0, i32 0
  %t122 = load i32, i32* %t121
  %t123 = getelementptr inbounds [51 x i8], [51 x i8]* @.str.42, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t123, i32 %t122)
  ret void
}

define { i32, i32 } @cell_px(%grid__Cell %c) {
entry:
  %t0 = alloca %grid__Cell
  %t1 = alloca { i32, i32 }
  store %grid__Cell %c, %grid__Cell* %t0
  %t2 = getelementptr inbounds %grid__Cell, %grid__Cell* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = mul i32 %t3, 20
  %t5 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 0
  store i32 %t4, i32* %t5
  %t6 = getelementptr inbounds %grid__Cell, %grid__Cell* %t0, i32 0, i32 1
  %t7 = load i32, i32* %t6
  %t8 = mul i32 %t7, 20
  %t9 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1, i32 0, i32 1
  store i32 %t8, i32* %t9
  %t10 = load { i32, i32 }, { i32, i32 }* %t1
  ret { i32, i32 } %t10
}

define void @draw_cell(i8* %w, %grid__Cell %c, i32 %color) {
entry:
  %t0 = alloca i8*
  %t1 = alloca %grid__Cell
  %t2 = alloca i32
  %t3 = alloca { i32, i32 }
  %t28 = alloca [16 x i8]
  store i8* %w, i8** %t0
  store %grid__Cell %c, %grid__Cell* %t1
  store i32 %color, i32* %t2
  %t4 = load %grid__Cell, %grid__Cell* %t1
  %t5 = call { i32, i32 } @cell_px(%grid__Cell %t4)
  store { i32, i32 } %t5, { i32, i32 }* %t3
  %t6 = load i8*, i8** %t0
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %sdl_null_window_499, label %sdl_window_handle_ok_500
sdl_null_window_499:
  %t8 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.43, i64 0, i64 0
  call i32 @puts(i8* %t8)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_500:
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

define i32 @pick_color(i1 %cond, i32 %a, i32 %b) {
entry:
  %t0 = alloca i1
  %t1 = alloca i32
  %t2 = alloca i32
  store i1 %cond, i1* %t0
  store i32 %a, i32* %t1
  store i32 %b, i32* %t2
  %t3 = load i1, i1* %t0
  br i1 %t3, label %if_then_501, label %if_else_502
if_then_501:
  %t4 = load i32, i32* %t1
  br label %if_end_503
if_else_502:
  %t5 = load i32, i32* %t2
  br label %if_end_503
if_end_503:
  %t6 = phi i32 [ %t4, %if_then_501 ], [ %t5, %if_else_502 ]
  ret i32 %t6
}

define i32 @frame_demo() {
entry:
  %t10 = alloca %grid__Cell
  %t23 = alloca %grid__Cell
  %t0 = load i64, i64* @frame.off
  %t1 = getelementptr %grid__Cell, %grid__Cell* null, i32 1
  %t2 = ptrtoint %grid__Cell* %t1 to i64
  %t3 = load i64, i64* @frame.off
  %t4 = add i64 %t3, %t2
  %t5 = icmp ugt i64 %t4, 4096
  br i1 %t5, label %frame_alloc_fail_504, label %frame_alloc_ok_505
frame_alloc_fail_504:
  %t6 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.44, i64 0, i64 0
  call i32 @puts(i8* %t6)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_505:
  store i64 %t4, i64* @frame.off
  %t7 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t8 = getelementptr inbounds i8, i8* %t7, i64 %t3
  %t9 = bitcast i8* %t8 to %grid__Cell*
  %t11 = getelementptr inbounds %grid__Cell, %grid__Cell* %t10, i32 0, i32 0
  store i32 3, i32* %t11
  %t12 = getelementptr inbounds %grid__Cell, %grid__Cell* %t10, i32 0, i32 1
  store i32 4, i32* %t12
  %t13 = load %grid__Cell, %grid__Cell* %t10
  store %grid__Cell %t13, %grid__Cell* %t9
  %t14 = getelementptr %grid__Cell, %grid__Cell* null, i32 1
  %t15 = ptrtoint %grid__Cell* %t14 to i64
  %t16 = load i64, i64* @frame.off
  %t17 = add i64 %t16, %t15
  %t18 = icmp ugt i64 %t17, 4096
  br i1 %t18, label %frame_alloc_fail_506, label %frame_alloc_ok_507
frame_alloc_fail_506:
  %t19 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.45, i64 0, i64 0
  call i32 @puts(i8* %t19)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_507:
  store i64 %t17, i64* @frame.off
  %t20 = getelementptr inbounds [4096 x i8], [4096 x i8]* @frame.buf, i64 0, i64 0
  %t21 = getelementptr inbounds i8, i8* %t20, i64 %t16
  %t22 = bitcast i8* %t21 to %grid__Cell*
  %t24 = getelementptr inbounds %grid__Cell, %grid__Cell* %t23, i32 0, i32 0
  store i32 10, i32* %t24
  %t25 = getelementptr inbounds %grid__Cell, %grid__Cell* %t23, i32 0, i32 1
  store i32 20, i32* %t25
  %t26 = load %grid__Cell, %grid__Cell* %t23
  store %grid__Cell %t26, %grid__Cell* %t22
  %t27 = getelementptr inbounds %grid__Cell, %grid__Cell* %t9, i32 0, i32 0
  %t28 = load i32, i32* %t27
  %t29 = getelementptr inbounds %grid__Cell, %grid__Cell* %t22, i32 0, i32 1
  %t30 = load i32, i32* %t29
  %t31 = add i32 %t28, %t30
  store i64 %t0, i64* @frame.off
  ret i32 %t31
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i32
  %t4 = alloca i32
  %t6 = alloca i8*
  %t23 = alloca i8*
  %t25 = alloca i8*
  %t27 = alloca { i32, i8* }
  %t31 = alloca %Stats
  %t32 = alloca %Stats
  %t44 = alloca %Tuning
  %t45 = alloca %Tuning
  %t71 = alloca %sb__Snake
  %t73 = alloca %grid__Cell
  %t78 = alloca i64
  %t79 = alloca i8
  %t80 = alloca i8*
  %t81 = alloca i8
  %t83 = alloca [5 x i32]
  %t84 = alloca [5 x i32]
  %t86 = alloca i64
  %t92 = alloca i32
  %t94 = alloca i1
  %t95 = alloca i1
  %t96 = alloca i1
  %t97 = alloca i1
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
  %t110 = alloca i32
  %t114 = alloca i1
  %t115 = alloca [56 x i8]
  %t133 = alloca i1
  %t163 = alloca i1
  %t196 = alloca i1
  %t317 = alloca i32
  %t331 = alloca i32
  %t346 = alloca i32
  %t349 = alloca %grid__Cell
  %t399 = alloca i64
  %t497 = alloca i64
  %t540 = alloca { i32, i32 }
  %t543 = alloca float
  %t555 = alloca float
  %t567 = alloca i32
  %t584 = alloca %GenRef
  %t591 = alloca %GenRef
  %t610 = alloca %Particle
  %t616 = alloca %FlashOnEat
  %t617 = alloca %FlashOnEat
  %t622 = alloca i1
  %t647 = alloca i32
  %t728 = alloca i64
  %t813 = alloca i32
  %t825 = alloca i32
  %t841 = alloca i32
  %t853 = alloca i32
  %t859 = alloca i32
  %t865 = alloca i32
  %t871 = alloca i32
  %t877 = alloca i32
  %t881 = alloca %GameOverFlash
  %t882 = alloca %GameOverFlash
  %t887 = alloca i1
  %t893 = alloca float
  %t896 = alloca float
  %t926 = alloca { i32, i32 }
  %t929 = alloca i32
  %t973 = alloca [16 x i8]
  %t982 = alloca i32
  %t986 = alloca i1
  %t1006 = alloca %grid__Cell
  %t1088 = alloca i32
  %t1089 = alloca i32
  %t1090 = alloca i64
  %t1114 = alloca i32
  %t1122 = alloca i32
  %t1135 = alloca [16 x i8]
  %t1201 = alloca i32
  %t1202 = alloca i32
  %t1203 = alloca i64
  %t1227 = alloca i32
  %t1235 = alloca i32
  %t1248 = alloca [16 x i8]
  %t1267 = alloca i8*
  %t1269 = alloca { i32, i32 }
  %t1292 = alloca i32
  %t1293 = alloca i32
  %t1294 = alloca i32
  %t1295 = alloca i64
  %t1319 = alloca { i32, i32 }
  %t1392 = alloca i32
  %t1393 = alloca i32
  %t1394 = alloca i64
  %t1418 = alloca i32
  %t1426 = alloca i32
  %t1439 = alloca [16 x i8]
  %t1457 = alloca i8*
  %t1459 = alloca i8*
  %t1461 = alloca { i32, i32 }
  %t1484 = alloca i32
  %t1485 = alloca i32
  %t1486 = alloca i32
  %t1487 = alloca i64
  %t1511 = alloca { i32, i32 }
  %t1515 = alloca { i32, i32 }
  %t1538 = alloca i32
  %t1539 = alloca i32
  %t1540 = alloca i32
  %t1541 = alloca i64
  %t1565 = alloca { i32, i32 }
  %t1569 = alloca i32
  %t1641 = alloca i32
  %t1642 = alloca i32
  %t1643 = alloca i64
  %t1667 = alloca i32
  %t1675 = alloca i32
  %t1688 = alloca [16 x i8]
  %t1769 = alloca i32
  %t1770 = alloca i32
  %t1771 = alloca i64
  %t1795 = alloca i32
  %t1803 = alloca i32
  %t1816 = alloca [16 x i8]
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
  %t7 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.46, i64 0, i32 2, i64 0
  %t8 = load i32, i32* %t2
  %t9 = load i32, i32* %t4
  %t10 = call i32 @SDL_Init(i32 32)
  %t11 = icmp ne i32 %t10, 0
  br i1 %t11, label %sdl_init_fail_508, label %sdl_init_ok_509
sdl_init_fail_508:
  call void @star_rc_release(i8* %t7)
  br label %window_create_end_510
sdl_init_ok_509:
  %t12 = call i8* @SDL_CreateWindow(i8* %t7, i32 536805376, i32 536805376, i32 %t8, i32 %t9, i32 0)
  call void @star_rc_release(i8* %t7)
  %t13 = icmp eq i8* %t12, null
  br i1 %t13, label %sdl_window_fail_511, label %sdl_window_ok_512
sdl_window_fail_511:
  br label %window_create_end_510
sdl_window_ok_512:
  %t14 = call i8* @SDL_CreateRenderer(i8* %t12, i32 -1, i32 0)
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %sdl_renderer_fail_513, label %sdl_renderer_ok_514
sdl_renderer_fail_513:
  call void @SDL_DestroyWindow(i8* %t12)
  br label %window_create_end_510
sdl_renderer_ok_514:
  br label %window_create_end_510
window_create_end_510:
  %t16 = phi i8* [ null, %sdl_init_fail_508 ], [ null, %sdl_window_fail_511 ], [ null, %sdl_renderer_fail_513 ], [ %t12, %sdl_renderer_ok_514 ]
  store i8* %t16, i8** %t6
  %t17 = load i8*, i8** %t6
  %t18 = icmp eq i8* %t17, null
  br i1 %t18, label %if_then_515, label %if_else_516
if_then_515:
  %t19 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.47, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t19)
  call i32 (i8*, ...) @printf(i8* %t19)
  %t20 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.48, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t20)
  ret i32 0
if_else_516:
  br label %if_end_517
if_end_517:
  call void @demo_genref_staleness()
  %t21 = call i32 @frame_demo()
  %t22 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.49, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t22, i32 %t21)
  %t24 = getelementptr inbounds [417 x i8], [417 x i8]* @.str.50, i64 0, i64 0
  store i8* %t24, i8** %t23
  %t26 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.51, i64 0, i32 2, i64 0
  store i8* %t26, i8** %t25
  %t28 = load i8*, i8** %t25
  %t29 = load i8*, i8** %t25
  call void @star_rc_retain(i8* %t29)
  %t30 = call { i32, i8* } @save__load_high_score(i8* %t28)
  store { i32, i8* } %t30, { i32, i8* }* %t27
  %t33 = getelementptr inbounds %Stats, %Stats* %t32, i32 0, i32 0
  store i32 0, i32* %t33
  %t34 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t27, i32 0, i32 0
  %t35 = load i32, i32* %t34
  %t36 = getelementptr inbounds %Stats, %Stats* %t32, i32 0, i32 1
  store i32 %t35, i32* %t36
  %t37 = load %Stats, %Stats* %t32
  store %Stats %t37, %Stats* %t31
  %t38 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t39 = load i32, i32* %t38
  %t40 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t27, i32 0, i32 1
  %t41 = load i8*, i8** %t40
  %t42 = load i8*, i8** %t40
  call void @star_rc_retain(i8* %t42)
  call void @star_rc_release(i8* %t41)
  %t43 = getelementptr inbounds [50 x i8], [50 x i8]* @.str.52, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t43, i32 %t39, i8* %t41)
  %t46 = getelementptr inbounds %Tuning, %Tuning* %t45, i32 0, i32 0
  store i32 120, i32* %t46
  %t47 = getelementptr inbounds %Tuning, %Tuning* %t45, i32 0, i32 1
  store float 0x3FBEB851E0000000, float* %t47
  %t48 = getelementptr inbounds %Tuning, %Tuning* %t45, i32 0, i32 2
  store float 0x3FDCCCCCC0000000, float* %t48
  %t49 = getelementptr inbounds %Tuning, %Tuning* %t45, i32 0, i32 3
  store i1 true, i1* %t49
  %t50 = load %Tuning, %Tuning* %t45
  store %Tuning %t50, %Tuning* %t44
  %t51 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.53, i64 0, i32 2, i64 0
  call void @Tuning__load_from_file(%Tuning* %t44, i8* %t51)
  %t53 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 0
  %t54 = load i32, i32* %t53
  %t55 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 1
  %t56 = load float, float* %t55
  %t57 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 2
  %t58 = load float, float* %t57
  %t59 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 3
  %t60 = load i1, i1* %t59
  %t61 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.54, i64 0, i64 0
  %t62 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.55, i64 0, i64 0
  %t63 = select i1 %t60, i8* %t61, i8* %t62
  %t64 = getelementptr inbounds [88 x i8], [88 x i8]* @.str.56, i64 0, i64 0
  %t65 = fpext float %t56 to double
  %t66 = fpext float %t58 to double
  call i32 (i8*, ...) @printf(i8* %t64, i32 %t54, double %t65, double %t66, i8* %t63)
  %t67 = call i32 @SDL_GetTicks()
  %t68 = icmp eq i32 %t67, 0
  %t69 = select i1 %t68, i32 1, i32 %t67
  %t70 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t70, i32 -1)
  store i32 %t69, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t70, i32 1, i32* null)
  %t72 = call %sb__Snake @sb__make_snake()
  store %sb__Snake %t72, %sb__Snake* %t71
  %t74 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 0
  %t75 = load { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t74
  %t76 = call i32 @sb__Snake__length(%sb__Snake* %t71)
  %t77 = call %grid__Cell @food__spawn_food({ [768 x %grid__Cell], i64, i64 } %t75, i32 %t76)
  store %grid__Cell %t77, %grid__Cell* %t73
  store i64 0, i64* %t78
  store i8 0, i8* %t79
  store i8* null, i8** %t80
  %t82 = trunc i32 0 to i8
  store i8 %t82, i8* %t81
  %t85 = getelementptr inbounds [5 x i32], [5 x i32]* %t84, i32 0, i64 0
  store i32 0, i32* %t85
  store i64 1, i64* %t86
  br label %arr_rep_cond_518
arr_rep_cond_518:
  %t87 = load i64, i64* %t86
  %t88 = icmp ult i64 %t87, 5
  br i1 %t88, label %arr_rep_body_519, label %arr_rep_end_520
arr_rep_body_519:
  %t89 = getelementptr inbounds [5 x i32], [5 x i32]* %t84, i32 0, i64 %t87
  store i32 0, i32* %t89
  %t90 = add i64 %t87, 1
  store i64 %t90, i64* %t86
  br label %arr_rep_cond_518
arr_rep_end_520:
  %t91 = load [5 x i32], [5 x i32]* %t84
  store [5 x i32] %t91, [5 x i32]* %t83
  %t93 = call i32 @SDL_GetTicks()
  store i32 %t93, i32* %t92
  store i1 false, i1* %t94
  store i1 false, i1* %t95
  store i1 false, i1* %t96
  store i1 false, i1* %t97
  store i32 41, i32* %t98
  store i32 19, i32* %t99
  store i32 58, i32* %t100
  store i32 21, i32* %t101
  store i32 225, i32* %t102
  store i32 82, i32* %t103
  store i32 81, i32* %t104
  store i32 80, i32* %t105
  store i32 79, i32* %t106
  store i32 26, i32* %t107
  store i32 22, i32* %t108
  store i32 4, i32* %t109
  store i32 7, i32* %t110
  br label %while_cond_521
while_cond_521:
  br i1 true, label %while_body_522, label %while_else_523
while_body_522:
  %t111 = load i8*, i8** %t6
  %t112 = icmp eq i8* %t111, null
  br i1 %t112, label %sdl_null_window_525, label %sdl_window_handle_ok_526
sdl_null_window_525:
  %t113 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.57, i64 0, i64 0
  call i32 @puts(i8* %t113)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_526:
  store i1 false, i1* %t114
  %t116 = getelementptr inbounds [56 x i8], [56 x i8]* %t115, i64 0, i64 0
  br label %sdl_poll_cond_527
sdl_poll_cond_527:
  %t117 = call i32 @SDL_PollEvent(i8* %t116)
  %t118 = icmp ne i32 %t117, 0
  br i1 %t118, label %sdl_poll_body_528, label %sdl_poll_end_530
sdl_poll_body_528:
  %t119 = bitcast i8* %t116 to i32*
  %t120 = load i32, i32* %t119
  %t121 = icmp eq i32 %t120, 256
  br i1 %t121, label %sdl_poll_set_quit_529, label %sdl_poll_cond_527
sdl_poll_set_quit_529:
  store i1 true, i1* %t114
  br label %sdl_poll_cond_527
sdl_poll_end_530:
  %t122 = load i1, i1* %t114
  br i1 %t122, label %if_then_531, label %if_else_532
if_then_531:
  br label %while_end_524
if_else_532:
  br label %if_end_533
if_end_533:
  %t123 = load i32, i32* %t98
  %t124 = icmp sge i32 %t123, 0
  %t125 = icmp slt i32 %t123, 512
  %t126 = and i1 %t124, %t125
  br i1 %t126, label %key_down_read_534, label %key_down_end_535
key_down_read_534:
  %t127 = call i8* @SDL_GetKeyboardState(i32* null)
  %t128 = sext i32 %t123 to i64
  %t129 = getelementptr inbounds i8, i8* %t127, i64 %t128
  %t130 = load i8, i8* %t129
  %t131 = icmp ne i8 %t130, 0
  br label %key_down_end_535
key_down_end_535:
  %t132 = phi i1 [ false, %if_end_533 ], [ %t131, %key_down_read_534 ]
  br i1 %t132, label %if_then_536, label %if_else_537
if_then_536:
  br label %while_end_524
if_else_537:
  br label %if_end_538
if_end_538:
  %t134 = load i32, i32* %t99
  %t135 = icmp sge i32 %t134, 0
  %t136 = icmp slt i32 %t134, 512
  %t137 = and i1 %t135, %t136
  br i1 %t137, label %key_down_read_539, label %key_down_end_540
key_down_read_539:
  %t138 = call i8* @SDL_GetKeyboardState(i32* null)
  %t139 = sext i32 %t134 to i64
  %t140 = getelementptr inbounds i8, i8* %t138, i64 %t139
  %t141 = load i8, i8* %t140
  %t142 = icmp ne i8 %t141, 0
  br label %key_down_end_540
key_down_end_540:
  %t143 = phi i1 [ false, %if_end_538 ], [ %t142, %key_down_read_539 ]
  store i1 %t143, i1* %t133
  %t144 = load i1, i1* %t133
  br i1 %t144, label %logic_rhs_541, label %logic_short_542
logic_rhs_541:
  %t145 = load i1, i1* %t94
  %t146 = xor i1 true, %t145
  br label %logic_end_543
logic_short_542:
  br label %logic_end_543
logic_end_543:
  %t147 = phi i1 [ %t146, %logic_rhs_541 ], [ false, %logic_short_542 ]
  br i1 %t147, label %if_then_544, label %if_else_545
if_then_544:
  %t148 = load i64, i64* %t78
  %t149 = zext i32 0 to i64
  %t150 = shl i64 1, %t149
  %t151 = and i64 %t148, %t150
  %t152 = icmp ne i64 %t151, 0
  br i1 %t152, label %if_then_547, label %if_else_548
if_then_547:
  %t153 = load i64, i64* %t78
  %t154 = zext i32 0 to i64
  %t155 = shl i64 1, %t154
  %t157 = xor i64 %t155, -1
  %t156 = and i64 %t153, %t157
  store i64 %t156, i64* %t78
  br label %if_end_549
if_else_548:
  %t158 = load i64, i64* %t78
  %t159 = zext i32 0 to i64
  %t160 = shl i64 1, %t159
  %t161 = or i64 %t158, %t160
  store i64 %t161, i64* %t78
  br label %if_end_549
if_end_549:
  br label %if_end_546
if_else_545:
  br label %if_end_546
if_end_546:
  %t162 = load i1, i1* %t133
  store i1 %t162, i1* %t94
  %t164 = load i32, i32* %t100
  %t165 = icmp sge i32 %t164, 0
  %t166 = icmp slt i32 %t164, 512
  %t167 = and i1 %t165, %t166
  br i1 %t167, label %key_down_read_550, label %key_down_end_551
key_down_read_550:
  %t168 = call i8* @SDL_GetKeyboardState(i32* null)
  %t169 = sext i32 %t164 to i64
  %t170 = getelementptr inbounds i8, i8* %t168, i64 %t169
  %t171 = load i8, i8* %t170
  %t172 = icmp ne i8 %t171, 0
  br label %key_down_end_551
key_down_end_551:
  %t173 = phi i1 [ false, %if_end_546 ], [ %t172, %key_down_read_550 ]
  store i1 %t173, i1* %t163
  %t174 = load i1, i1* %t163
  br i1 %t174, label %logic_rhs_552, label %logic_short_553
logic_rhs_552:
  %t175 = load i1, i1* %t95
  %t176 = xor i1 true, %t175
  br label %logic_end_554
logic_short_553:
  br label %logic_end_554
logic_end_554:
  %t177 = phi i1 [ %t176, %logic_rhs_552 ], [ false, %logic_short_553 ]
  br i1 %t177, label %if_then_555, label %if_else_556
if_then_555:
  %t178 = load i64, i64* %t78
  %t179 = zext i32 1 to i64
  %t180 = shl i64 1, %t179
  %t181 = and i64 %t178, %t180
  %t182 = icmp ne i64 %t181, 0
  br i1 %t182, label %if_then_558, label %if_else_559
if_then_558:
  %t183 = load i64, i64* %t78
  %t184 = zext i32 1 to i64
  %t185 = shl i64 1, %t184
  %t187 = xor i64 %t185, -1
  %t186 = and i64 %t183, %t187
  store i64 %t186, i64* %t78
  br label %if_end_560
if_else_559:
  %t188 = load i64, i64* %t78
  %t189 = zext i32 1 to i64
  %t190 = shl i64 1, %t189
  %t191 = or i64 %t188, %t190
  store i64 %t191, i64* %t78
  call void @dump_particle_arena()
  br label %if_end_560
if_end_560:
  br label %if_end_557
if_else_556:
  br label %if_end_557
if_end_557:
  %t192 = load i1, i1* %t163
  store i1 %t192, i1* %t95
  %t193 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 4
  %t194 = load i1, i1* %t193
  %t195 = xor i1 true, %t194
  br i1 %t195, label %if_then_561, label %if_else_562
if_then_561:
  %t197 = load i32, i32* %t101
  %t198 = icmp sge i32 %t197, 0
  %t199 = icmp slt i32 %t197, 512
  %t200 = and i1 %t198, %t199
  br i1 %t200, label %key_down_read_564, label %key_down_end_565
key_down_read_564:
  %t201 = call i8* @SDL_GetKeyboardState(i32* null)
  %t202 = sext i32 %t197 to i64
  %t203 = getelementptr inbounds i8, i8* %t201, i64 %t202
  %t204 = load i8, i8* %t203
  %t205 = icmp ne i8 %t204, 0
  br label %key_down_end_565
key_down_end_565:
  %t206 = phi i1 [ false, %if_then_561 ], [ %t205, %key_down_read_564 ]
  store i1 %t206, i1* %t196
  %t207 = load i1, i1* %t196
  br i1 %t207, label %logic_rhs_566, label %logic_short_567
logic_rhs_566:
  %t208 = load i1, i1* %t96
  %t209 = xor i1 true, %t208
  br label %logic_end_568
logic_short_567:
  br label %logic_end_568
logic_end_568:
  %t210 = phi i1 [ %t209, %logic_rhs_566 ], [ false, %logic_short_567 ]
  br i1 %t210, label %if_then_569, label %if_else_570
if_then_569:
  %t211 = call %sb__Snake @sb__make_snake()
  store %sb__Snake %t211, %sb__Snake* %t71
  %t212 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 0
  %t213 = load { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t212
  %t214 = call i32 @sb__Snake__length(%sb__Snake* %t71)
  %t215 = call %grid__Cell @food__spawn_food({ [768 x %grid__Cell], i64, i64 } %t213, i32 %t214)
  store %grid__Cell %t215, %grid__Cell* %t73
  %t216 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  store i32 0, i32* %t216
  %t217 = load i8*, i8** %t80
  call void @star_rc_release(i8* %t217)
  store i8* null, i8** %t80
  br label %if_end_571
if_else_570:
  br label %if_end_571
if_end_571:
  %t218 = load i1, i1* %t196
  store i1 %t218, i1* %t96
  br label %if_end_563
if_else_562:
  %t219 = load i32, i32* %t103
  %t220 = icmp sge i32 %t219, 0
  %t221 = icmp slt i32 %t219, 512
  %t222 = and i1 %t220, %t221
  br i1 %t222, label %key_down_read_572, label %key_down_end_573
key_down_read_572:
  %t223 = call i8* @SDL_GetKeyboardState(i32* null)
  %t224 = sext i32 %t219 to i64
  %t225 = getelementptr inbounds i8, i8* %t223, i64 %t224
  %t226 = load i8, i8* %t225
  %t227 = icmp ne i8 %t226, 0
  br label %key_down_end_573
key_down_end_573:
  %t228 = phi i1 [ false, %if_else_562 ], [ %t227, %key_down_read_572 ]
  br i1 %t228, label %logic_short_575, label %logic_rhs_574
logic_rhs_574:
  %t229 = load i32, i32* %t107
  %t230 = icmp sge i32 %t229, 0
  %t231 = icmp slt i32 %t229, 512
  %t232 = and i1 %t230, %t231
  br i1 %t232, label %key_down_read_577, label %key_down_end_578
key_down_read_577:
  %t233 = call i8* @SDL_GetKeyboardState(i32* null)
  %t234 = sext i32 %t229 to i64
  %t235 = getelementptr inbounds i8, i8* %t233, i64 %t234
  %t236 = load i8, i8* %t235
  %t237 = icmp ne i8 %t236, 0
  br label %key_down_end_578
key_down_end_578:
  %t238 = phi i1 [ false, %logic_rhs_574 ], [ %t237, %key_down_read_577 ]
  br label %logic_end_576
logic_short_575:
  br label %logic_end_576
logic_end_576:
  %t239 = phi i1 [ %t238, %key_down_end_578 ], [ true, %logic_short_575 ]
  br i1 %t239, label %if_then_579, label %if_else_580
if_then_579:
  call void @sb__Snake__queue_turn(%sb__Snake* %t71, i32 0)
  br label %if_end_581
if_else_580:
  br label %if_end_581
if_end_581:
  %t241 = load i32, i32* %t104
  %t242 = icmp sge i32 %t241, 0
  %t243 = icmp slt i32 %t241, 512
  %t244 = and i1 %t242, %t243
  br i1 %t244, label %key_down_read_582, label %key_down_end_583
key_down_read_582:
  %t245 = call i8* @SDL_GetKeyboardState(i32* null)
  %t246 = sext i32 %t241 to i64
  %t247 = getelementptr inbounds i8, i8* %t245, i64 %t246
  %t248 = load i8, i8* %t247
  %t249 = icmp ne i8 %t248, 0
  br label %key_down_end_583
key_down_end_583:
  %t250 = phi i1 [ false, %if_end_581 ], [ %t249, %key_down_read_582 ]
  br i1 %t250, label %logic_short_585, label %logic_rhs_584
logic_rhs_584:
  %t251 = load i32, i32* %t108
  %t252 = icmp sge i32 %t251, 0
  %t253 = icmp slt i32 %t251, 512
  %t254 = and i1 %t252, %t253
  br i1 %t254, label %key_down_read_587, label %key_down_end_588
key_down_read_587:
  %t255 = call i8* @SDL_GetKeyboardState(i32* null)
  %t256 = sext i32 %t251 to i64
  %t257 = getelementptr inbounds i8, i8* %t255, i64 %t256
  %t258 = load i8, i8* %t257
  %t259 = icmp ne i8 %t258, 0
  br label %key_down_end_588
key_down_end_588:
  %t260 = phi i1 [ false, %logic_rhs_584 ], [ %t259, %key_down_read_587 ]
  br label %logic_end_586
logic_short_585:
  br label %logic_end_586
logic_end_586:
  %t261 = phi i1 [ %t260, %key_down_end_588 ], [ true, %logic_short_585 ]
  br i1 %t261, label %if_then_589, label %if_else_590
if_then_589:
  call void @sb__Snake__queue_turn(%sb__Snake* %t71, i32 1)
  br label %if_end_591
if_else_590:
  br label %if_end_591
if_end_591:
  %t263 = load i32, i32* %t105
  %t264 = icmp sge i32 %t263, 0
  %t265 = icmp slt i32 %t263, 512
  %t266 = and i1 %t264, %t265
  br i1 %t266, label %key_down_read_592, label %key_down_end_593
key_down_read_592:
  %t267 = call i8* @SDL_GetKeyboardState(i32* null)
  %t268 = sext i32 %t263 to i64
  %t269 = getelementptr inbounds i8, i8* %t267, i64 %t268
  %t270 = load i8, i8* %t269
  %t271 = icmp ne i8 %t270, 0
  br label %key_down_end_593
key_down_end_593:
  %t272 = phi i1 [ false, %if_end_591 ], [ %t271, %key_down_read_592 ]
  br i1 %t272, label %logic_short_595, label %logic_rhs_594
logic_rhs_594:
  %t273 = load i32, i32* %t109
  %t274 = icmp sge i32 %t273, 0
  %t275 = icmp slt i32 %t273, 512
  %t276 = and i1 %t274, %t275
  br i1 %t276, label %key_down_read_597, label %key_down_end_598
key_down_read_597:
  %t277 = call i8* @SDL_GetKeyboardState(i32* null)
  %t278 = sext i32 %t273 to i64
  %t279 = getelementptr inbounds i8, i8* %t277, i64 %t278
  %t280 = load i8, i8* %t279
  %t281 = icmp ne i8 %t280, 0
  br label %key_down_end_598
key_down_end_598:
  %t282 = phi i1 [ false, %logic_rhs_594 ], [ %t281, %key_down_read_597 ]
  br label %logic_end_596
logic_short_595:
  br label %logic_end_596
logic_end_596:
  %t283 = phi i1 [ %t282, %key_down_end_598 ], [ true, %logic_short_595 ]
  br i1 %t283, label %if_then_599, label %if_else_600
if_then_599:
  call void @sb__Snake__queue_turn(%sb__Snake* %t71, i32 2)
  br label %if_end_601
if_else_600:
  br label %if_end_601
if_end_601:
  %t285 = load i32, i32* %t106
  %t286 = icmp sge i32 %t285, 0
  %t287 = icmp slt i32 %t285, 512
  %t288 = and i1 %t286, %t287
  br i1 %t288, label %key_down_read_602, label %key_down_end_603
key_down_read_602:
  %t289 = call i8* @SDL_GetKeyboardState(i32* null)
  %t290 = sext i32 %t285 to i64
  %t291 = getelementptr inbounds i8, i8* %t289, i64 %t290
  %t292 = load i8, i8* %t291
  %t293 = icmp ne i8 %t292, 0
  br label %key_down_end_603
key_down_end_603:
  %t294 = phi i1 [ false, %if_end_601 ], [ %t293, %key_down_read_602 ]
  br i1 %t294, label %logic_short_605, label %logic_rhs_604
logic_rhs_604:
  %t295 = load i32, i32* %t110
  %t296 = icmp sge i32 %t295, 0
  %t297 = icmp slt i32 %t295, 512
  %t298 = and i1 %t296, %t297
  br i1 %t298, label %key_down_read_607, label %key_down_end_608
key_down_read_607:
  %t299 = call i8* @SDL_GetKeyboardState(i32* null)
  %t300 = sext i32 %t295 to i64
  %t301 = getelementptr inbounds i8, i8* %t299, i64 %t300
  %t302 = load i8, i8* %t301
  %t303 = icmp ne i8 %t302, 0
  br label %key_down_end_608
key_down_end_608:
  %t304 = phi i1 [ false, %logic_rhs_604 ], [ %t303, %key_down_read_607 ]
  br label %logic_end_606
logic_short_605:
  br label %logic_end_606
logic_end_606:
  %t305 = phi i1 [ %t304, %key_down_end_608 ], [ true, %logic_short_605 ]
  br i1 %t305, label %if_then_609, label %if_else_610
if_then_609:
  call void @sb__Snake__queue_turn(%sb__Snake* %t71, i32 3)
  br label %if_end_611
if_else_610:
  br label %if_end_611
if_end_611:
  %t307 = load i32, i32* %t102
  %t308 = icmp sge i32 %t307, 0
  %t309 = icmp slt i32 %t307, 512
  %t310 = and i1 %t308, %t309
  br i1 %t310, label %key_down_read_612, label %key_down_end_613
key_down_read_612:
  %t311 = call i8* @SDL_GetKeyboardState(i32* null)
  %t312 = sext i32 %t307 to i64
  %t313 = getelementptr inbounds i8, i8* %t311, i64 %t312
  %t314 = load i8, i8* %t313
  %t315 = icmp ne i8 %t314, 0
  br label %key_down_end_613
key_down_end_613:
  %t316 = phi i1 [ false, %if_end_611 ], [ %t315, %key_down_read_612 ]
  store i1 %t316, i1* %t97
  %t318 = load i1, i1* %t97
  br i1 %t318, label %if_then_614, label %if_else_615
if_then_614:
  %t319 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 0
  %t320 = load i32, i32* %t319
  %t321 = icmp eq i32 2, 0
  %t322 = icmp eq i32 %t320, -2147483648
  %t323 = icmp eq i32 2, -1
  %t324 = and i1 %t322, %t323
  %t325 = or i1 %t321, %t324
  br i1 %t325, label %int_div_fail_617, label %int_div_ok_618
int_div_fail_617:
  %t326 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.58, i64 0, i64 0
  call i32 @puts(i8* %t326)
  call void @exit(i32 1)
  unreachable
int_div_ok_618:
  %t327 = sdiv i32 %t320, 2
  br label %if_end_616
if_else_615:
  %t328 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 0
  %t329 = load i32, i32* %t328
  br label %if_end_616
if_end_616:
  %t330 = phi i32 [ %t327, %int_div_ok_618 ], [ %t329, %if_else_615 ]
  store i32 %t330, i32* %t317
  %t332 = call i32 @SDL_GetTicks()
  store i32 %t332, i32* %t331
  %t333 = load i64, i64* %t78
  %t334 = zext i32 0 to i64
  %t335 = shl i64 1, %t334
  %t336 = and i64 %t333, %t335
  %t337 = icmp ne i64 %t336, 0
  %t338 = xor i1 true, %t337
  br i1 %t338, label %logic_rhs_619, label %logic_short_620
logic_rhs_619:
  %t339 = load i32, i32* %t331
  %t340 = load i32, i32* %t92
  %t341 = sub i32 %t339, %t340
  %t342 = load i32, i32* %t317
  %t343 = icmp sge i32 %t341, %t342
  br label %logic_end_621
logic_short_620:
  br label %logic_end_621
logic_end_621:
  %t344 = phi i1 [ %t343, %logic_rhs_619 ], [ false, %logic_short_620 ]
  br i1 %t344, label %if_then_622, label %if_else_623
if_then_622:
  %t345 = load i32, i32* %t331
  store i32 %t345, i32* %t92
  %t347 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t348 = load i32, i32* %t347
  store i32 %t348, i32* %t346
  %t350 = call %grid__Cell @sb__Snake__advance(%sb__Snake* %t71)
  store %grid__Cell %t350, %grid__Cell* %t349
  %t351 = getelementptr i64, i64* null, i32 1
  %t352 = ptrtoint i64* %t351 to i64
  %t353 = load i8*, i8** %t80
  %t354 = icmp eq i8* %t353, null
  br i1 %t354, label %list_cow_alloc_625, label %list_cow_check_626
list_cow_alloc_625:
  %t359 = bitcast void (i8*)* @list_release_symbol to i8*
  %t360 = call i8* @star_rc_alloc(i64 24, i8* %t359)
  %t361 = bitcast i8* %t360 to { i64*, i64, i64 }*
  %t362 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t361, i32 0, i32 0
  store i64* null, i64** %t362
  %t363 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t361, i32 0, i32 1
  store i64 0, i64* %t363
  %t364 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t361, i32 0, i32 2
  store i64 0, i64* %t364
  store i8* %t360, i8** %t80
  br label %list_cow_done_627
list_cow_check_626:
  %t365 = getelementptr inbounds i8, i8* %t353, i64 -16
  %t366 = bitcast i8* %t365 to i64*
  %t367 = load atomic i64, i64* %t366 seq_cst, align 8
  %t368 = icmp eq i64 %t367, 1
  br i1 %t368, label %list_cow_done_627, label %list_cow_clone_628
list_cow_clone_628:
  %t369 = bitcast i8* %t353 to { i64*, i64, i64 }*
  %t370 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t369, i32 0, i32 0
  %t371 = load i64*, i64** %t370
  %t372 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t369, i32 0, i32 1
  %t373 = load i64, i64* %t372
  %t374 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t369, i32 0, i32 2
  %t375 = load i64, i64* %t374
  %t376 = bitcast void (i8*)* @list_release_symbol to i8*
  %t377 = call i8* @star_rc_alloc(i64 24, i8* %t376)
  %t378 = bitcast i8* %t377 to { i64*, i64, i64 }*
  %t379 = mul i64 %t375, %t352
  %t380 = call i8* @malloc(i64 %t379)
  %t381 = bitcast i8* %t380 to i64*
  %t382 = icmp sgt i64 %t373, 0
  br i1 %t382, label %list_cow_copy_629, label %list_cow_after_copy_630
list_cow_copy_629:
  %t383 = mul i64 %t373, %t352
  %t384 = bitcast i64* %t371 to i8*
  call i8* @memcpy(i8* %t380, i8* %t384, i64 %t383)
  br label %list_cow_after_copy_630
list_cow_after_copy_630:
  %t385 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t378, i32 0, i32 0
  store i64* %t381, i64** %t385
  %t386 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t378, i32 0, i32 1
  store i64 %t373, i64* %t386
  %t387 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t378, i32 0, i32 2
  store i64 %t375, i64* %t387
  call void @star_rc_release(i8* %t353)
  store i8* %t377, i8** %t80
  br label %list_cow_done_627
list_cow_done_627:
  %t388 = load i8*, i8** %t80
  %t389 = bitcast i8* %t388 to { i64*, i64, i64 }*
  %t390 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t389, i32 0, i32 0
  %t391 = load i64*, i64** %t390
  %t392 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t389, i32 0, i32 1
  %t393 = load i64, i64* %t392
  %t394 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t389, i32 0, i32 2
  %t395 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.59, i64 0, i32 2, i64 0
  %t396 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t396, i32 -1)
  %t397 = load i64, i64* @sym.len
  %t398 = load i8**, i8*** @sym.data
  store i64 0, i64* %t399
  br label %sym_find_cond_631
sym_find_cond_631:
  %t400 = load i64, i64* %t399
  %t401 = icmp slt i64 %t400, %t397
  br i1 %t401, label %sym_find_body_632, label %sym_find_end_634
sym_find_body_632:
  %t402 = getelementptr inbounds i8*, i8** %t398, i64 %t400
  %t403 = load i8*, i8** %t402
  %t404 = call i32 @strcmp(i8* %t403, i8* %t395)
  %t405 = icmp eq i32 %t404, 0
  br i1 %t405, label %sym_find_end_634, label %sym_find_next_633
sym_find_next_633:
  %t406 = add i64 %t400, 1
  store i64 %t406, i64* %t399
  br label %sym_find_cond_631
sym_find_end_634:
  %t407 = load i64, i64* %t399
  %t408 = icmp slt i64 %t407, %t397
  br i1 %t408, label %sym_found_635, label %sym_notfound_636
sym_found_635:
  call void @star_rc_release(i8* %t395)
  br label %sym_done_637
sym_notfound_636:
  %t409 = load i64, i64* @sym.cap
  %t410 = icmp sge i64 %t397, %t409
  br i1 %t410, label %sym_grow_638, label %sym_store_639
sym_grow_638:
  %t411 = mul i64 %t409, 2
  %t412 = icmp sgt i64 %t411, 0
  %t413 = select i1 %t412, i64 %t411, i64 1
  %t414 = mul i64 %t413, 8
  %t415 = call i8* @malloc(i64 %t414)
  %t416 = bitcast i8* %t415 to i8**
  %t417 = icmp sgt i64 %t409, 0
  br i1 %t417, label %sym_copy_640, label %sym_after_copy_641
sym_copy_640:
  %t418 = mul i64 %t397, 8
  %t419 = bitcast i8** %t398 to i8*
  call i8* @memcpy(i8* %t415, i8* %t419, i64 %t418)
  call void @free(i8* %t419)
  br label %sym_after_copy_641
sym_after_copy_641:
  store i8** %t416, i8*** @sym.data
  store i64 %t413, i64* @sym.cap
  br label %sym_store_639
sym_store_639:
  %t420 = load i8**, i8*** @sym.data
  %t421 = getelementptr inbounds i8*, i8** %t420, i64 %t397
  store i8* %t395, i8** %t421
  %t422 = add i64 %t397, 1
  store i64 %t422, i64* @sym.len
  br label %sym_done_637
sym_done_637:
  %t423 = phi i64 [ %t407, %sym_found_635 ], [ %t397, %sym_store_639 ]
  call i32 @ReleaseSemaphore(i8* %t396, i32 1, i32* null)
  %t424 = load i64, i64* %t394
  %t425 = load i64*, i64** %t390
  %t426 = load i64, i64* %t392
  %t427 = icmp sge i64 %t426, %t424
  br i1 %t427, label %list_push_grow_642, label %list_push_store_643
list_push_grow_642:
  %t428 = mul i64 %t424, 2
  %t429 = icmp sgt i64 %t428, 0
  %t430 = select i1 %t429, i64 %t428, i64 1
  %t431 = getelementptr i64, i64* null, i32 1
  %t432 = ptrtoint i64* %t431 to i64
  %t433 = mul i64 %t430, %t432
  %t434 = call i8* @malloc(i64 %t433)
  %t435 = bitcast i8* %t434 to i64*
  %t436 = icmp sgt i64 %t424, 0
  br i1 %t436, label %list_push_copy_644, label %list_push_after_copy_645
list_push_copy_644:
  %t437 = mul i64 %t426, %t432
  %t438 = bitcast i64* %t425 to i8*
  call i8* @memcpy(i8* %t434, i8* %t438, i64 %t437)
  call void @free(i8* %t438)
  br label %list_push_after_copy_645
list_push_after_copy_645:
  store i64* %t435, i64** %t390
  store i64 %t430, i64* %t394
  br label %list_push_store_643
list_push_store_643:
  %t439 = load i64*, i64** %t390
  %t440 = getelementptr inbounds i64, i64* %t439, i64 %t426
  store i64 %t423, i64* %t440
  %t441 = add i64 %t426, 1
  store i64 %t441, i64* %t392
  %t442 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 4
  %t443 = load i1, i1* %t442
  br i1 %t443, label %logic_rhs_646, label %logic_short_647
logic_rhs_646:
  %t444 = load %grid__Cell, %grid__Cell* %t349
  %t445 = load %grid__Cell, %grid__Cell* %t73
  %t446 = call i1 @eq_s_grid__Cell(%grid__Cell %t444, %grid__Cell %t445)
  br label %logic_end_648
logic_short_647:
  br label %logic_end_648
logic_end_648:
  %t447 = phi i1 [ %t446, %logic_rhs_646 ], [ false, %logic_short_647 ]
  br i1 %t447, label %if_then_649, label %if_else_650
if_then_649:
  call void @sb__Snake__grow(%sb__Snake* %t71, i32 1)
  %t449 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t450 = load i32, i32* %t449
  %t451 = add i32 %t450, 10
  %t452 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  store i32 %t451, i32* %t452
  %t453 = getelementptr i64, i64* null, i32 1
  %t454 = ptrtoint i64* %t453 to i64
  %t455 = load i8*, i8** %t80
  %t456 = icmp eq i8* %t455, null
  br i1 %t456, label %list_cow_alloc_652, label %list_cow_check_653
list_cow_alloc_652:
  %t457 = bitcast void (i8*)* @list_release_symbol to i8*
  %t458 = call i8* @star_rc_alloc(i64 24, i8* %t457)
  %t459 = bitcast i8* %t458 to { i64*, i64, i64 }*
  %t460 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t459, i32 0, i32 0
  store i64* null, i64** %t460
  %t461 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t459, i32 0, i32 1
  store i64 0, i64* %t461
  %t462 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t459, i32 0, i32 2
  store i64 0, i64* %t462
  store i8* %t458, i8** %t80
  br label %list_cow_done_654
list_cow_check_653:
  %t463 = getelementptr inbounds i8, i8* %t455, i64 -16
  %t464 = bitcast i8* %t463 to i64*
  %t465 = load atomic i64, i64* %t464 seq_cst, align 8
  %t466 = icmp eq i64 %t465, 1
  br i1 %t466, label %list_cow_done_654, label %list_cow_clone_655
list_cow_clone_655:
  %t467 = bitcast i8* %t455 to { i64*, i64, i64 }*
  %t468 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t467, i32 0, i32 0
  %t469 = load i64*, i64** %t468
  %t470 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t467, i32 0, i32 1
  %t471 = load i64, i64* %t470
  %t472 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t467, i32 0, i32 2
  %t473 = load i64, i64* %t472
  %t474 = bitcast void (i8*)* @list_release_symbol to i8*
  %t475 = call i8* @star_rc_alloc(i64 24, i8* %t474)
  %t476 = bitcast i8* %t475 to { i64*, i64, i64 }*
  %t477 = mul i64 %t473, %t454
  %t478 = call i8* @malloc(i64 %t477)
  %t479 = bitcast i8* %t478 to i64*
  %t480 = icmp sgt i64 %t471, 0
  br i1 %t480, label %list_cow_copy_656, label %list_cow_after_copy_657
list_cow_copy_656:
  %t481 = mul i64 %t471, %t454
  %t482 = bitcast i64* %t469 to i8*
  call i8* @memcpy(i8* %t478, i8* %t482, i64 %t481)
  br label %list_cow_after_copy_657
list_cow_after_copy_657:
  %t483 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t476, i32 0, i32 0
  store i64* %t479, i64** %t483
  %t484 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t476, i32 0, i32 1
  store i64 %t471, i64* %t484
  %t485 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t476, i32 0, i32 2
  store i64 %t473, i64* %t485
  call void @star_rc_release(i8* %t455)
  store i8* %t475, i8** %t80
  br label %list_cow_done_654
list_cow_done_654:
  %t486 = load i8*, i8** %t80
  %t487 = bitcast i8* %t486 to { i64*, i64, i64 }*
  %t488 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t487, i32 0, i32 0
  %t489 = load i64*, i64** %t488
  %t490 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t487, i32 0, i32 1
  %t491 = load i64, i64* %t490
  %t492 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t487, i32 0, i32 2
  %t493 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.60, i64 0, i32 2, i64 0
  %t494 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t494, i32 -1)
  %t495 = load i64, i64* @sym.len
  %t496 = load i8**, i8*** @sym.data
  store i64 0, i64* %t497
  br label %sym_find_cond_658
sym_find_cond_658:
  %t498 = load i64, i64* %t497
  %t499 = icmp slt i64 %t498, %t495
  br i1 %t499, label %sym_find_body_659, label %sym_find_end_661
sym_find_body_659:
  %t500 = getelementptr inbounds i8*, i8** %t496, i64 %t498
  %t501 = load i8*, i8** %t500
  %t502 = call i32 @strcmp(i8* %t501, i8* %t493)
  %t503 = icmp eq i32 %t502, 0
  br i1 %t503, label %sym_find_end_661, label %sym_find_next_660
sym_find_next_660:
  %t504 = add i64 %t498, 1
  store i64 %t504, i64* %t497
  br label %sym_find_cond_658
sym_find_end_661:
  %t505 = load i64, i64* %t497
  %t506 = icmp slt i64 %t505, %t495
  br i1 %t506, label %sym_found_662, label %sym_notfound_663
sym_found_662:
  call void @star_rc_release(i8* %t493)
  br label %sym_done_664
sym_notfound_663:
  %t507 = load i64, i64* @sym.cap
  %t508 = icmp sge i64 %t495, %t507
  br i1 %t508, label %sym_grow_665, label %sym_store_666
sym_grow_665:
  %t509 = mul i64 %t507, 2
  %t510 = icmp sgt i64 %t509, 0
  %t511 = select i1 %t510, i64 %t509, i64 1
  %t512 = mul i64 %t511, 8
  %t513 = call i8* @malloc(i64 %t512)
  %t514 = bitcast i8* %t513 to i8**
  %t515 = icmp sgt i64 %t507, 0
  br i1 %t515, label %sym_copy_667, label %sym_after_copy_668
sym_copy_667:
  %t516 = mul i64 %t495, 8
  %t517 = bitcast i8** %t496 to i8*
  call i8* @memcpy(i8* %t513, i8* %t517, i64 %t516)
  call void @free(i8* %t517)
  br label %sym_after_copy_668
sym_after_copy_668:
  store i8** %t514, i8*** @sym.data
  store i64 %t511, i64* @sym.cap
  br label %sym_store_666
sym_store_666:
  %t518 = load i8**, i8*** @sym.data
  %t519 = getelementptr inbounds i8*, i8** %t518, i64 %t495
  store i8* %t493, i8** %t519
  %t520 = add i64 %t495, 1
  store i64 %t520, i64* @sym.len
  br label %sym_done_664
sym_done_664:
  %t521 = phi i64 [ %t505, %sym_found_662 ], [ %t495, %sym_store_666 ]
  call i32 @ReleaseSemaphore(i8* %t494, i32 1, i32* null)
  %t522 = load i64, i64* %t492
  %t523 = load i64*, i64** %t488
  %t524 = load i64, i64* %t490
  %t525 = icmp sge i64 %t524, %t522
  br i1 %t525, label %list_push_grow_669, label %list_push_store_670
list_push_grow_669:
  %t526 = mul i64 %t522, 2
  %t527 = icmp sgt i64 %t526, 0
  %t528 = select i1 %t527, i64 %t526, i64 1
  %t529 = getelementptr i64, i64* null, i32 1
  %t530 = ptrtoint i64* %t529 to i64
  %t531 = mul i64 %t528, %t530
  %t532 = call i8* @malloc(i64 %t531)
  %t533 = bitcast i8* %t532 to i64*
  %t534 = icmp sgt i64 %t522, 0
  br i1 %t534, label %list_push_copy_671, label %list_push_after_copy_672
list_push_copy_671:
  %t535 = mul i64 %t524, %t530
  %t536 = bitcast i64* %t523 to i8*
  call i8* @memcpy(i8* %t532, i8* %t536, i64 %t535)
  call void @free(i8* %t536)
  br label %list_push_after_copy_672
list_push_after_copy_672:
  store i64* %t533, i64** %t488
  store i64 %t528, i64* %t492
  br label %list_push_store_670
list_push_store_670:
  %t537 = load i64*, i64** %t488
  %t538 = getelementptr inbounds i64, i64* %t537, i64 %t524
  store i64 %t521, i64* %t538
  %t539 = add i64 %t524, 1
  store i64 %t539, i64* %t490
  %t541 = load %grid__Cell, %grid__Cell* %t73
  %t542 = call { i32, i32 } @cell_px(%grid__Cell %t541)
  store { i32, i32 } %t542, { i32, i32 }* %t540
  %t544 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t540, i32 0, i32 0
  %t545 = load i32, i32* %t544
  %t546 = icmp eq i32 2, 0
  %t547 = icmp eq i32 20, -2147483648
  %t548 = icmp eq i32 2, -1
  %t549 = and i1 %t547, %t548
  %t550 = or i1 %t546, %t549
  br i1 %t550, label %int_div_fail_673, label %int_div_ok_674
int_div_fail_673:
  %t551 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.61, i64 0, i64 0
  call i32 @puts(i8* %t551)
  call void @exit(i32 1)
  unreachable
int_div_ok_674:
  %t552 = sdiv i32 20, 2
  %t553 = add i32 %t545, %t552
  %t554 = sitofp i32 %t553 to float
  store float %t554, float* %t543
  %t556 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t540, i32 0, i32 1
  %t557 = load i32, i32* %t556
  %t558 = icmp eq i32 2, 0
  %t559 = icmp eq i32 20, -2147483648
  %t560 = icmp eq i32 2, -1
  %t561 = and i1 %t559, %t560
  %t562 = or i1 %t558, %t561
  br i1 %t562, label %int_div_fail_675, label %int_div_ok_676
int_div_fail_675:
  %t563 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.62, i64 0, i64 0
  call i32 @puts(i8* %t563)
  call void @exit(i32 1)
  unreachable
int_div_ok_676:
  %t564 = sdiv i32 20, 2
  %t565 = add i32 %t557, %t564
  %t566 = sitofp i32 %t565 to float
  store float %t566, float* %t555
  %t568 = sub i32 0, 1
  store i32 %t568, i32* %t567
  %t569 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 3
  %t570 = load i1, i1* %t569
  br i1 %t570, label %if_then_677, label %if_else_678
if_then_677:
  %t571 = load float, float* %t543
  %t572 = load float, float* %t555
  %t573 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 2
  %t574 = load float, float* %t573
  %t575 = call i32 @spawn_particle_burst(float %t571, float %t572, float %t574)
  store i32 %t575, i32* %t567
  br label %if_end_679
if_else_678:
  br label %if_end_679
if_end_679:
  %t576 = load i64, i64* %t78
  %t577 = zext i32 1 to i64
  %t578 = shl i64 1, %t577
  %t579 = and i64 %t576, %t578
  %t580 = icmp ne i64 %t579, 0
  br i1 %t580, label %logic_rhs_680, label %logic_short_681
logic_rhs_680:
  %t581 = load i32, i32* %t567
  %t582 = icmp sge i32 %t581, 0
  br label %logic_end_682
logic_short_681:
  br label %logic_end_682
logic_end_682:
  %t583 = phi i1 [ %t582, %logic_rhs_680 ], [ false, %logic_short_681 ]
  br i1 %t583, label %if_then_683, label %if_else_684
if_then_683:
  %t585 = load i32, i32* %t567
  %t586 = sext i32 %t585 to i64
  %t587 = icmp ult i64 %t586, 256
  br i1 %t587, label %genref_create_ok_686, label %genref_create_oob_687
genref_create_ok_686:
  %t588 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t586
  %t589 = load i64, i64* %t588
  br label %genref_create_end_688
genref_create_oob_687:
  br label %genref_create_end_688
genref_create_end_688:
  %t590 = phi i64 [ %t589, %genref_create_ok_686 ], [ 0, %genref_create_oob_687 ]
  %t592 = getelementptr inbounds %GenRef, %GenRef* %t591, i32 0, i32 0
  store i32 %t585, i32* %t592
  %t593 = getelementptr inbounds %GenRef, %GenRef* %t591, i32 0, i32 1
  store i64 %t590, i64* %t593
  %t594 = load %GenRef, %GenRef* %t591
  store %GenRef %t594, %GenRef* %t584
  %t595 = load i32, i32* %t567
  %t596 = getelementptr inbounds %GenRef, %GenRef* %t584, i32 0, i32 0
  %t597 = load i32, i32* %t596
  %t598 = getelementptr inbounds %GenRef, %GenRef* %t584, i32 0, i32 1
  %t599 = load i64, i64* %t598
  %t600 = sext i32 %t597 to i64
  %t601 = icmp ult i64 %t600, 256
  br i1 %t601, label %genref_place_check_689, label %genref_place_stale_691
genref_place_check_689:
  %t602 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t600
  %t603 = load i64, i64* %t602
  %t604 = icmp eq i64 %t599, %t603
  %t605 = and i64 %t603, 1
  %t606 = icmp eq i64 %t605, 1
  %t607 = and i1 %t604, %t606
  br i1 %t607, label %genref_place_ok_690, label %genref_place_stale_691
genref_place_ok_690:
  %t608 = load %Particle*, %Particle** @arena.Particles.data
  %t609 = getelementptr inbounds %Particle, %Particle* %t608, i64 %t600
  br label %genref_place_end_692
genref_place_stale_691:
  store %Particle zeroinitializer, %Particle* %t610
  br label %genref_place_end_692
genref_place_end_692:
  %t611 = phi %Particle* [ %t609, %genref_place_ok_690 ], [ %t610, %genref_place_stale_691 ]
  %t612 = getelementptr inbounds %Particle, %Particle* %t611, i32 0, i32 4
  %t613 = load float, float* %t612
  %t614 = getelementptr inbounds [58 x i8], [58 x i8]* @.str.63, i64 0, i64 0
  %t615 = fpext float %t613 to double
  call i32 (i8*, ...) @printf(i8* %t614, i32 %t595, double %t615)
  br label %if_end_685
if_else_684:
  br label %if_end_685
if_end_685:
  %t618 = load i8*, i8** %t6
  %t619 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t617, i32 0, i32 0
  store i8* %t618, i8** %t619
  %t620 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t617, i32 0, i32 1
  store i32 0, i32* %t620
  %t621 = load %FlashOnEat, %FlashOnEat* %t617
  store %FlashOnEat %t621, %FlashOnEat* %t616
  store i1 true, i1* %t622
  br label %while_cond_693
while_cond_693:
  %t623 = load i1, i1* %t622
  br i1 %t623, label %while_body_694, label %while_else_695
while_body_694:
  %t624 = call i1 @FlashOnEat__resume(%FlashOnEat* %t616)
  store i1 %t624, i1* %t622
  br label %while_cond_693
while_else_695:
  br label %while_end_696
while_end_696:
  %t625 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 0
  %t626 = load { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t625
  %t627 = call i32 @sb__Snake__length(%sb__Snake* %t71)
  %t628 = call %grid__Cell @food__spawn_food({ [768 x %grid__Cell], i64, i64 } %t626, i32 %t627)
  store %grid__Cell %t628, %grid__Cell* %t73
  %t629 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t630 = load i32, i32* %t629
  %t631 = icmp eq i32 50, 0
  %t632 = icmp eq i32 %t630, -2147483648
  %t633 = icmp eq i32 50, -1
  %t634 = and i1 %t632, %t633
  %t635 = or i1 %t631, %t634
  br i1 %t635, label %int_div_fail_697, label %int_div_ok_698
int_div_fail_697:
  %t636 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.64, i64 0, i64 0
  call i32 @puts(i8* %t636)
  call void @exit(i32 1)
  unreachable
int_div_ok_698:
  %t637 = sdiv i32 %t630, 50
  %t638 = load i32, i32* %t346
  %t639 = icmp eq i32 50, 0
  %t640 = icmp eq i32 %t638, -2147483648
  %t641 = icmp eq i32 50, -1
  %t642 = and i1 %t640, %t641
  %t643 = or i1 %t639, %t642
  br i1 %t643, label %int_div_fail_699, label %int_div_ok_700
int_div_fail_699:
  %t644 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.65, i64 0, i64 0
  call i32 @puts(i8* %t644)
  call void @exit(i32 1)
  unreachable
int_div_ok_700:
  %t645 = sdiv i32 %t638, 50
  %t646 = icmp sgt i32 %t637, %t645
  br i1 %t646, label %if_then_701, label %if_else_702
if_then_701:
  %t648 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t649 = load i32, i32* %t648
  %t650 = icmp eq i32 50, 0
  %t651 = icmp eq i32 %t649, -2147483648
  %t652 = icmp eq i32 50, -1
  %t653 = and i1 %t651, %t652
  %t654 = or i1 %t650, %t653
  br i1 %t654, label %int_div_fail_704, label %int_div_ok_705
int_div_fail_704:
  %t655 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.66, i64 0, i64 0
  call i32 @puts(i8* %t655)
  call void @exit(i32 1)
  unreachable
int_div_ok_705:
  %t656 = sdiv i32 %t649, 50
  store i32 %t656, i32* %t647
  %t657 = load i32, i32* %t647
  %t658 = icmp sge i32 %t657, 1
  br i1 %t658, label %logic_rhs_706, label %logic_short_707
logic_rhs_706:
  %t659 = load i32, i32* %t647
  %t660 = icmp sle i32 %t659, 8
  br label %logic_end_708
logic_short_707:
  br label %logic_end_708
logic_end_708:
  %t661 = phi i1 [ %t660, %logic_rhs_706 ], [ false, %logic_short_707 ]
  br i1 %t661, label %if_then_709, label %if_else_710
if_then_709:
  %t662 = load i8, i8* %t79
  %t663 = load i32, i32* %t647
  %t664 = sub i32 %t663, 1
  %t665 = and i32 %t664, 7
  %t666 = trunc i32 %t665 to i8
  %t667 = shl i8 1, %t666
  %t668 = or i8 %t662, %t667
  store i8 %t668, i8* %t79
  %t669 = load i32, i32* %t647
  %t670 = load i8, i8* %t79
  %t671 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.67, i64 0, i64 0
  %t672 = zext i8 %t670 to i32
  call i32 (i8*, ...) @printf(i8* %t671, i32 %t669, i32 %t672)
  br label %if_end_711
if_else_710:
  br label %if_end_711
if_end_711:
  br label %if_end_703
if_else_702:
  br label %if_end_703
if_end_703:
  %t673 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t674 = load i32, i32* %t673
  %t675 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t676 = load i32, i32* %t675
  %t677 = icmp sgt i32 %t674, %t676
  br i1 %t677, label %if_then_712, label %if_else_713
if_then_712:
  %t678 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t679 = load i32, i32* %t678
  %t680 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  store i32 %t679, i32* %t680
  br label %if_end_714
if_else_713:
  br label %if_end_714
if_end_714:
  br label %if_end_651
if_else_650:
  br label %if_end_651
if_end_651:
  %t681 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 4
  %t682 = load i1, i1* %t681
  %t683 = xor i1 true, %t682
  br i1 %t683, label %if_then_715, label %if_else_716
if_then_715:
  %t684 = getelementptr i64, i64* null, i32 1
  %t685 = ptrtoint i64* %t684 to i64
  %t686 = load i8*, i8** %t80
  %t687 = icmp eq i8* %t686, null
  br i1 %t687, label %list_cow_alloc_718, label %list_cow_check_719
list_cow_alloc_718:
  %t688 = bitcast void (i8*)* @list_release_symbol to i8*
  %t689 = call i8* @star_rc_alloc(i64 24, i8* %t688)
  %t690 = bitcast i8* %t689 to { i64*, i64, i64 }*
  %t691 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t690, i32 0, i32 0
  store i64* null, i64** %t691
  %t692 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t690, i32 0, i32 1
  store i64 0, i64* %t692
  %t693 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t690, i32 0, i32 2
  store i64 0, i64* %t693
  store i8* %t689, i8** %t80
  br label %list_cow_done_720
list_cow_check_719:
  %t694 = getelementptr inbounds i8, i8* %t686, i64 -16
  %t695 = bitcast i8* %t694 to i64*
  %t696 = load atomic i64, i64* %t695 seq_cst, align 8
  %t697 = icmp eq i64 %t696, 1
  br i1 %t697, label %list_cow_done_720, label %list_cow_clone_721
list_cow_clone_721:
  %t698 = bitcast i8* %t686 to { i64*, i64, i64 }*
  %t699 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t698, i32 0, i32 0
  %t700 = load i64*, i64** %t699
  %t701 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t698, i32 0, i32 1
  %t702 = load i64, i64* %t701
  %t703 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t698, i32 0, i32 2
  %t704 = load i64, i64* %t703
  %t705 = bitcast void (i8*)* @list_release_symbol to i8*
  %t706 = call i8* @star_rc_alloc(i64 24, i8* %t705)
  %t707 = bitcast i8* %t706 to { i64*, i64, i64 }*
  %t708 = mul i64 %t704, %t685
  %t709 = call i8* @malloc(i64 %t708)
  %t710 = bitcast i8* %t709 to i64*
  %t711 = icmp sgt i64 %t702, 0
  br i1 %t711, label %list_cow_copy_722, label %list_cow_after_copy_723
list_cow_copy_722:
  %t712 = mul i64 %t702, %t685
  %t713 = bitcast i64* %t700 to i8*
  call i8* @memcpy(i8* %t709, i8* %t713, i64 %t712)
  br label %list_cow_after_copy_723
list_cow_after_copy_723:
  %t714 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t707, i32 0, i32 0
  store i64* %t710, i64** %t714
  %t715 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t707, i32 0, i32 1
  store i64 %t702, i64* %t715
  %t716 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t707, i32 0, i32 2
  store i64 %t704, i64* %t716
  call void @star_rc_release(i8* %t686)
  store i8* %t706, i8** %t80
  br label %list_cow_done_720
list_cow_done_720:
  %t717 = load i8*, i8** %t80
  %t718 = bitcast i8* %t717 to { i64*, i64, i64 }*
  %t719 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t718, i32 0, i32 0
  %t720 = load i64*, i64** %t719
  %t721 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t718, i32 0, i32 1
  %t722 = load i64, i64* %t721
  %t723 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t718, i32 0, i32 2
  %t724 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.68, i64 0, i32 2, i64 0
  %t725 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t725, i32 -1)
  %t726 = load i64, i64* @sym.len
  %t727 = load i8**, i8*** @sym.data
  store i64 0, i64* %t728
  br label %sym_find_cond_724
sym_find_cond_724:
  %t729 = load i64, i64* %t728
  %t730 = icmp slt i64 %t729, %t726
  br i1 %t730, label %sym_find_body_725, label %sym_find_end_727
sym_find_body_725:
  %t731 = getelementptr inbounds i8*, i8** %t727, i64 %t729
  %t732 = load i8*, i8** %t731
  %t733 = call i32 @strcmp(i8* %t732, i8* %t724)
  %t734 = icmp eq i32 %t733, 0
  br i1 %t734, label %sym_find_end_727, label %sym_find_next_726
sym_find_next_726:
  %t735 = add i64 %t729, 1
  store i64 %t735, i64* %t728
  br label %sym_find_cond_724
sym_find_end_727:
  %t736 = load i64, i64* %t728
  %t737 = icmp slt i64 %t736, %t726
  br i1 %t737, label %sym_found_728, label %sym_notfound_729
sym_found_728:
  call void @star_rc_release(i8* %t724)
  br label %sym_done_730
sym_notfound_729:
  %t738 = load i64, i64* @sym.cap
  %t739 = icmp sge i64 %t726, %t738
  br i1 %t739, label %sym_grow_731, label %sym_store_732
sym_grow_731:
  %t740 = mul i64 %t738, 2
  %t741 = icmp sgt i64 %t740, 0
  %t742 = select i1 %t741, i64 %t740, i64 1
  %t743 = mul i64 %t742, 8
  %t744 = call i8* @malloc(i64 %t743)
  %t745 = bitcast i8* %t744 to i8**
  %t746 = icmp sgt i64 %t738, 0
  br i1 %t746, label %sym_copy_733, label %sym_after_copy_734
sym_copy_733:
  %t747 = mul i64 %t726, 8
  %t748 = bitcast i8** %t727 to i8*
  call i8* @memcpy(i8* %t744, i8* %t748, i64 %t747)
  call void @free(i8* %t748)
  br label %sym_after_copy_734
sym_after_copy_734:
  store i8** %t745, i8*** @sym.data
  store i64 %t742, i64* @sym.cap
  br label %sym_store_732
sym_store_732:
  %t749 = load i8**, i8*** @sym.data
  %t750 = getelementptr inbounds i8*, i8** %t749, i64 %t726
  store i8* %t724, i8** %t750
  %t751 = add i64 %t726, 1
  store i64 %t751, i64* @sym.len
  br label %sym_done_730
sym_done_730:
  %t752 = phi i64 [ %t736, %sym_found_728 ], [ %t726, %sym_store_732 ]
  call i32 @ReleaseSemaphore(i8* %t725, i32 1, i32* null)
  %t753 = load i64, i64* %t723
  %t754 = load i64*, i64** %t719
  %t755 = load i64, i64* %t721
  %t756 = icmp sge i64 %t755, %t753
  br i1 %t756, label %list_push_grow_735, label %list_push_store_736
list_push_grow_735:
  %t757 = mul i64 %t753, 2
  %t758 = icmp sgt i64 %t757, 0
  %t759 = select i1 %t758, i64 %t757, i64 1
  %t760 = getelementptr i64, i64* null, i32 1
  %t761 = ptrtoint i64* %t760 to i64
  %t762 = mul i64 %t759, %t761
  %t763 = call i8* @malloc(i64 %t762)
  %t764 = bitcast i8* %t763 to i64*
  %t765 = icmp sgt i64 %t753, 0
  br i1 %t765, label %list_push_copy_737, label %list_push_after_copy_738
list_push_copy_737:
  %t766 = mul i64 %t755, %t761
  %t767 = bitcast i64* %t754 to i8*
  call i8* @memcpy(i8* %t763, i8* %t767, i64 %t766)
  call void @free(i8* %t767)
  br label %list_push_after_copy_738
list_push_after_copy_738:
  store i64* %t764, i64** %t719
  store i64 %t759, i64* %t723
  br label %list_push_store_736
list_push_store_736:
  %t768 = load i64*, i64** %t719
  %t769 = getelementptr inbounds i64, i64* %t768, i64 %t755
  store i64 %t752, i64* %t769
  %t770 = add i64 %t755, 1
  store i64 %t770, i64* %t721
  %t771 = load i8*, i8** %t80
  %t772 = icmp eq i8* %t771, null
  br i1 %t772, label %list_read_null_739, label %list_read_real_740
list_read_null_739:
  br label %list_read_end_741
list_read_real_740:
  %t773 = bitcast i8* %t771 to { i64*, i64, i64 }*
  %t774 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t773, i32 0, i32 0
  %t775 = load i64*, i64** %t774
  %t776 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t773, i32 0, i32 1
  %t777 = load i64, i64* %t776
  br label %list_read_end_741
list_read_end_741:
  %t778 = phi i64* [ null, %list_read_null_739 ], [ %t775, %list_read_real_740 ]
  %t779 = phi i64 [ 0, %list_read_null_739 ], [ %t777, %list_read_real_740 ]
  %t780 = load i8*, i8** %t80
  %t781 = icmp eq i8* %t780, null
  br i1 %t781, label %list_read_null_742, label %list_read_real_743
list_read_null_742:
  br label %list_read_end_744
list_read_real_743:
  %t782 = bitcast i8* %t780 to { i64*, i64, i64 }*
  %t783 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t782, i32 0, i32 0
  %t784 = load i64*, i64** %t783
  %t785 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t782, i32 0, i32 1
  %t786 = load i64, i64* %t785
  br label %list_read_end_744
list_read_end_744:
  %t787 = phi i64* [ null, %list_read_null_742 ], [ %t784, %list_read_real_743 ]
  %t788 = phi i64 [ 0, %list_read_null_742 ], [ %t786, %list_read_real_743 ]
  %t789 = trunc i64 %t788 to i32
  %t790 = sub i32 %t789, 1
  %t791 = sext i32 %t790 to i64
  %t792 = icmp ult i64 %t791, %t779
  br i1 %t792, label %list_idx_ok_745, label %list_idx_oob_746
list_idx_ok_745:
  %t793 = getelementptr inbounds i64, i64* %t778, i64 %t791
  %t794 = load i64, i64* %t793
  br label %list_idx_end_747
list_idx_oob_746:
  br label %list_idx_end_747
list_idx_end_747:
  %t795 = phi i64 [ %t794, %list_idx_ok_745 ], [ 0, %list_idx_oob_746 ]
  %t796 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t796, i32 -1)
  %t797 = load i64, i64* @sym.len
  %t798 = icmp sge i64 %t795, 0
  %t799 = icmp slt i64 %t795, %t797
  %t800 = and i1 %t798, %t799
  br i1 %t800, label %sym_name_ok_748, label %sym_name_oob_749
sym_name_ok_748:
  %t801 = load i8**, i8*** @sym.data
  %t802 = getelementptr inbounds i8*, i8** %t801, i64 %t795
  %t803 = load i8*, i8** %t802
  call void @star_rc_retain(i8* %t803)
  br label %sym_name_end_750
sym_name_oob_749:
  %t804 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t804
  br label %sym_name_end_750
sym_name_end_750:
  %t805 = phi i8* [ %t803, %sym_name_ok_748 ], [ %t804, %sym_name_oob_749 ]
  call i32 @ReleaseSemaphore(i8* %t796, i32 1, i32* null)
  call void @star_rc_release(i8* %t805)
  %t806 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.69, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t806, i8* %t805)
  %t807 = load i8*, i8** %t25
  %t808 = load i8*, i8** %t25
  call void @star_rc_retain(i8* %t808)
  %t809 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t810 = load i32, i32* %t809
  %t811 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.70, i64 0, i32 2, i64 0
  %t812 = call i1 @save__save_high_score(i8* %t807, i32 %t810, i8* %t811)
  store i32 4, i32* %t813
  br label %while_cond_751
while_cond_751:
  %t814 = load i32, i32* %t813
  %t815 = icmp sge i32 %t814, 0
  br i1 %t815, label %while_body_752, label %while_else_753
while_body_752:
  %t816 = load i32, i32* %t813
  %t817 = icmp eq i32 %t816, 0
  br i1 %t817, label %logic_short_756, label %logic_rhs_755
logic_rhs_755:
  %t818 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t819 = load i32, i32* %t818
  %t820 = load i32, i32* %t813
  %t821 = sub i32 %t820, 1
  %t822 = sext i32 %t821 to i64
  %t823 = icmp ult i64 %t822, 5
  br i1 %t823, label %arr_rplace_ok_758, label %arr_rplace_oob_759
arr_rplace_ok_758:
  %t824 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t822
  br label %arr_rplace_end_760
arr_rplace_oob_759:
  store i32 0, i32* %t825
  br label %arr_rplace_end_760
arr_rplace_end_760:
  %t826 = phi i32* [ %t824, %arr_rplace_ok_758 ], [ %t825, %arr_rplace_oob_759 ]
  %t827 = load i32, i32* %t826
  %t828 = icmp sle i32 %t819, %t827
  br label %logic_end_757
logic_short_756:
  br label %logic_end_757
logic_end_757:
  %t829 = phi i1 [ %t828, %arr_rplace_end_760 ], [ true, %logic_short_756 ]
  br i1 %t829, label %if_then_761, label %if_else_762
if_then_761:
  %t830 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t831 = load i32, i32* %t830
  %t832 = load i32, i32* %t813
  %t833 = sext i32 %t832 to i64
  %t834 = icmp ult i64 %t833, 5
  br i1 %t834, label %arr_set_do_764, label %arr_set_oob_765
arr_set_do_764:
  %t835 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t833
  store i32 %t831, i32* %t835
  br label %arr_set_end_766
arr_set_oob_765:
  br label %arr_set_end_766
arr_set_end_766:
  br label %while_end_754
if_else_762:
  br label %if_end_763
if_end_763:
  %t836 = load i32, i32* %t813
  %t837 = sub i32 %t836, 1
  %t838 = sext i32 %t837 to i64
  %t839 = icmp ult i64 %t838, 5
  br i1 %t839, label %arr_rplace_ok_767, label %arr_rplace_oob_768
arr_rplace_ok_767:
  %t840 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t838
  br label %arr_rplace_end_769
arr_rplace_oob_768:
  store i32 0, i32* %t841
  br label %arr_rplace_end_769
arr_rplace_end_769:
  %t842 = phi i32* [ %t840, %arr_rplace_ok_767 ], [ %t841, %arr_rplace_oob_768 ]
  %t843 = load i32, i32* %t842
  %t844 = load i32, i32* %t813
  %t845 = sext i32 %t844 to i64
  %t846 = icmp ult i64 %t845, 5
  br i1 %t846, label %arr_set_do_770, label %arr_set_oob_771
arr_set_do_770:
  %t847 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t845
  store i32 %t843, i32* %t847
  br label %arr_set_end_772
arr_set_oob_771:
  br label %arr_set_end_772
arr_set_end_772:
  %t848 = load i32, i32* %t813
  %t849 = sub i32 %t848, 1
  store i32 %t849, i32* %t813
  br label %while_cond_751
while_else_753:
  br label %while_end_754
while_end_754:
  %t850 = sext i32 0 to i64
  %t851 = icmp ult i64 %t850, 5
  br i1 %t851, label %arr_rplace_ok_773, label %arr_rplace_oob_774
arr_rplace_ok_773:
  %t852 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t850
  br label %arr_rplace_end_775
arr_rplace_oob_774:
  store i32 0, i32* %t853
  br label %arr_rplace_end_775
arr_rplace_end_775:
  %t854 = phi i32* [ %t852, %arr_rplace_ok_773 ], [ %t853, %arr_rplace_oob_774 ]
  %t855 = load i32, i32* %t854
  %t856 = sext i32 1 to i64
  %t857 = icmp ult i64 %t856, 5
  br i1 %t857, label %arr_rplace_ok_776, label %arr_rplace_oob_777
arr_rplace_ok_776:
  %t858 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t856
  br label %arr_rplace_end_778
arr_rplace_oob_777:
  store i32 0, i32* %t859
  br label %arr_rplace_end_778
arr_rplace_end_778:
  %t860 = phi i32* [ %t858, %arr_rplace_ok_776 ], [ %t859, %arr_rplace_oob_777 ]
  %t861 = load i32, i32* %t860
  %t862 = sext i32 2 to i64
  %t863 = icmp ult i64 %t862, 5
  br i1 %t863, label %arr_rplace_ok_779, label %arr_rplace_oob_780
arr_rplace_ok_779:
  %t864 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t862
  br label %arr_rplace_end_781
arr_rplace_oob_780:
  store i32 0, i32* %t865
  br label %arr_rplace_end_781
arr_rplace_end_781:
  %t866 = phi i32* [ %t864, %arr_rplace_ok_779 ], [ %t865, %arr_rplace_oob_780 ]
  %t867 = load i32, i32* %t866
  %t868 = sext i32 3 to i64
  %t869 = icmp ult i64 %t868, 5
  br i1 %t869, label %arr_rplace_ok_782, label %arr_rplace_oob_783
arr_rplace_ok_782:
  %t870 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t868
  br label %arr_rplace_end_784
arr_rplace_oob_783:
  store i32 0, i32* %t871
  br label %arr_rplace_end_784
arr_rplace_end_784:
  %t872 = phi i32* [ %t870, %arr_rplace_ok_782 ], [ %t871, %arr_rplace_oob_783 ]
  %t873 = load i32, i32* %t872
  %t874 = sext i32 4 to i64
  %t875 = icmp ult i64 %t874, 5
  br i1 %t875, label %arr_rplace_ok_785, label %arr_rplace_oob_786
arr_rplace_ok_785:
  %t876 = getelementptr inbounds [5 x i32], [5 x i32]* %t83, i32 0, i64 %t874
  br label %arr_rplace_end_787
arr_rplace_oob_786:
  store i32 0, i32* %t877
  br label %arr_rplace_end_787
arr_rplace_end_787:
  %t878 = phi i32* [ %t876, %arr_rplace_ok_785 ], [ %t877, %arr_rplace_oob_786 ]
  %t879 = load i32, i32* %t878
  %t880 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.71, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t880, i32 %t855, i32 %t861, i32 %t867, i32 %t873, i32 %t879)
  %t883 = load i8*, i8** %t6
  %t884 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t882, i32 0, i32 0
  store i8* %t883, i8** %t884
  %t885 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t882, i32 0, i32 1
  store i32 0, i32* %t885
  %t886 = load %GameOverFlash, %GameOverFlash* %t882
  store %GameOverFlash %t886, %GameOverFlash* %t881
  store i1 true, i1* %t887
  br label %while_cond_788
while_cond_788:
  %t888 = load i1, i1* %t887
  br i1 %t888, label %while_body_789, label %while_else_790
while_body_789:
  %t889 = call i1 @GameOverFlash__resume(%GameOverFlash* %t881)
  store i1 %t889, i1* %t887
  br label %while_cond_788
while_else_790:
  br label %while_end_791
while_end_791:
  br label %if_end_717
if_else_716:
  br label %if_end_717
if_end_717:
  br label %if_end_624
if_else_623:
  br label %if_end_624
if_end_624:
  br label %if_end_563
if_end_563:
  %t890 = load i8, i8* %t81
  %t891 = trunc i32 1 to i8
  %t892 = add i8 %t890, %t891
  store i8 %t892, i8* %t81
  %t894 = load i8, i8* %t81
  %t895 = uitofp i8 %t894 to float
  store float %t895, float* %t893
  %t897 = load float, float* %t893
  %t898 = fmul float %t897, 0x3FC3333340000000
  %t899 = call float @llvm.sin.f32(float %t898)
  %t900 = fmul float %t899, 0x4000000000000000
  store float %t900, float* %t896
  %t901 = load i8*, i8** %t6
  %t902 = icmp eq i8* %t901, null
  br i1 %t902, label %sdl_null_window_792, label %sdl_window_handle_ok_793
sdl_null_window_792:
  %t903 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.72, i64 0, i64 0
  call i32 @puts(i8* %t903)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_793:
  %t904 = call i8* @SDL_GetRenderer(i8* %t901)
  %t905 = and i32 18, 255
  %t906 = and i32 18, 255
  %t907 = shl i32 %t906, 8
  %t908 = or i32 %t905, %t907
  %t909 = and i32 24, 255
  %t910 = shl i32 %t909, 16
  %t911 = or i32 %t908, %t910
  %t912 = and i32 255, 255
  %t913 = shl i32 %t912, 24
  %t914 = or i32 %t911, %t913
  %t915 = and i32 %t914, 255
  %t916 = trunc i32 %t915 to i8
  %t917 = lshr i32 %t914, 8
  %t918 = and i32 %t917, 255
  %t919 = trunc i32 %t918 to i8
  %t920 = lshr i32 %t914, 16
  %t921 = and i32 %t920, 255
  %t922 = trunc i32 %t921 to i8
  %t923 = lshr i32 %t914, 24
  %t924 = and i32 %t923, 255
  %t925 = trunc i32 %t924 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t904, i8 %t916, i8 %t919, i8 %t922, i8 %t925)
  call i32 @SDL_RenderClear(i8* %t904)
  %t927 = load %grid__Cell, %grid__Cell* %t73
  %t928 = call { i32, i32 } @cell_px(%grid__Cell %t927)
  store { i32, i32 } %t928, { i32, i32 }* %t926
  %t930 = load float, float* %t896
  %t931 = call i32 @llvm.fptosi.sat.i32.f32(float %t930)
  store i32 %t931, i32* %t929
  %t932 = load i8*, i8** %t6
  %t933 = icmp eq i8* %t932, null
  br i1 %t933, label %sdl_null_window_794, label %sdl_window_handle_ok_795
sdl_null_window_794:
  %t934 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.73, i64 0, i64 0
  call i32 @puts(i8* %t934)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_795:
  %t935 = call i8* @SDL_GetRenderer(i8* %t932)
  %t936 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t926, i32 0, i32 0
  %t937 = load i32, i32* %t936
  %t938 = load i32, i32* %t929
  %t939 = sub i32 %t937, %t938
  %t940 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t926, i32 0, i32 1
  %t941 = load i32, i32* %t940
  %t942 = load i32, i32* %t929
  %t943 = sub i32 %t941, %t942
  %t944 = sub i32 20, 1
  %t945 = load i32, i32* %t929
  %t946 = mul i32 %t945, 2
  %t947 = add i32 %t944, %t946
  %t948 = sub i32 20, 1
  %t949 = load i32, i32* %t929
  %t950 = mul i32 %t949, 2
  %t951 = add i32 %t948, %t950
  %t952 = and i32 230, 255
  %t953 = and i32 90, 255
  %t954 = shl i32 %t953, 8
  %t955 = or i32 %t952, %t954
  %t956 = and i32 90, 255
  %t957 = shl i32 %t956, 16
  %t958 = or i32 %t955, %t957
  %t959 = and i32 255, 255
  %t960 = shl i32 %t959, 24
  %t961 = or i32 %t958, %t960
  %t962 = and i32 %t961, 255
  %t963 = trunc i32 %t962 to i8
  %t964 = lshr i32 %t961, 8
  %t965 = and i32 %t964, 255
  %t966 = trunc i32 %t965 to i8
  %t967 = lshr i32 %t961, 16
  %t968 = and i32 %t967, 255
  %t969 = trunc i32 %t968 to i8
  %t970 = lshr i32 %t961, 24
  %t971 = and i32 %t970, 255
  %t972 = trunc i32 %t971 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t935, i8 %t963, i8 %t966, i8 %t969, i8 %t972)
  %t974 = getelementptr inbounds [16 x i8], [16 x i8]* %t973, i64 0, i64 0
  %t975 = bitcast i8* %t974 to i32*
  store i32 %t939, i32* %t975
  %t976 = getelementptr inbounds i8, i8* %t974, i64 4
  %t977 = bitcast i8* %t976 to i32*
  store i32 %t943, i32* %t977
  %t978 = getelementptr inbounds i8, i8* %t974, i64 8
  %t979 = bitcast i8* %t978 to i32*
  store i32 %t947, i32* %t979
  %t980 = getelementptr inbounds i8, i8* %t974, i64 12
  %t981 = bitcast i8* %t980 to i32*
  store i32 %t951, i32* %t981
  call i32 @SDL_RenderFillRect(i8* %t935, i8* %t974)
  store i32 0, i32* %t982
  br label %while_cond_796
while_cond_796:
  %t983 = load i32, i32* %t982
  %t984 = call i32 @sb__Snake__length(%sb__Snake* %t71)
  %t985 = icmp slt i32 %t983, %t984
  br i1 %t985, label %while_body_797, label %while_else_798
while_body_797:
  %t987 = load i32, i32* %t982
  %t988 = call i32 @sb__Snake__length(%sb__Snake* %t71)
  %t989 = sub i32 %t988, 1
  %t990 = icmp eq i32 %t987, %t989
  store i1 %t990, i1* %t986
  %t991 = load i8*, i8** %t6
  %t992 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 0
  %t993 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t992, i32 0, i32 0
  %t994 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t992, i32 0, i32 1
  %t995 = load i64, i64* %t994
  %t996 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t992, i32 0, i32 2
  %t997 = load i64, i64* %t996
  %t998 = load i32, i32* %t982
  %t999 = sext i32 %t998 to i64
  %t1000 = load i64, i64* %t994
  %t1001 = load i64, i64* %t996
  %t1002 = icmp ult i64 %t999, %t1001
  br i1 %t1002, label %ring_rplace_ok_800, label %ring_rplace_oob_801
ring_rplace_ok_800:
  %t1003 = add i64 %t1000, %t999
  %t1004 = urem i64 %t1003, 768
  %t1005 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t993, i32 0, i64 %t1004
  br label %ring_rplace_end_802
ring_rplace_oob_801:
  store %grid__Cell zeroinitializer, %grid__Cell* %t1006
  br label %ring_rplace_end_802
ring_rplace_end_802:
  %t1007 = phi %grid__Cell* [ %t1005, %ring_rplace_ok_800 ], [ %t1006, %ring_rplace_oob_801 ]
  %t1008 = load %grid__Cell, %grid__Cell* %t1007
  %t1009 = load i1, i1* %t986
  %t1010 = and i32 140, 255
  %t1011 = and i32 230, 255
  %t1012 = shl i32 %t1011, 8
  %t1013 = or i32 %t1010, %t1012
  %t1014 = and i32 160, 255
  %t1015 = shl i32 %t1014, 16
  %t1016 = or i32 %t1013, %t1015
  %t1017 = and i32 255, 255
  %t1018 = shl i32 %t1017, 24
  %t1019 = or i32 %t1016, %t1018
  %t1020 = and i32 80, 255
  %t1021 = and i32 190, 255
  %t1022 = shl i32 %t1021, 8
  %t1023 = or i32 %t1020, %t1022
  %t1024 = and i32 120, 255
  %t1025 = shl i32 %t1024, 16
  %t1026 = or i32 %t1023, %t1025
  %t1027 = and i32 255, 255
  %t1028 = shl i32 %t1027, 24
  %t1029 = or i32 %t1026, %t1028
  %t1030 = call i32 @pick_color(i1 %t1009, i32 %t1019, i32 %t1029)
  call void @draw_cell(i8* %t991, %grid__Cell %t1008, i32 %t1030)
  %t1031 = load i32, i32* %t982
  %t1032 = add i32 %t1031, 1
  store i32 %t1032, i32* %t982
  br label %while_cond_796
while_else_798:
  br label %while_end_799
while_end_799:
  %t1033 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 1
  %t1034 = load float, float* %t1033
  call void @tick_particle_arena(float 0x3F90624DE0000000, float %t1034)
  %t1035 = load i8*, i8** %t6
  call void @draw_particle_arena(i8* %t1035)
  call void @reclaim_dead_particles()
  %t1036 = load i8*, i8** %t6
  %t1037 = icmp eq i8* %t1036, null
  br i1 %t1037, label %sdl_null_window_803, label %sdl_window_handle_ok_804
sdl_null_window_803:
  %t1038 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.74, i64 0, i64 0
  call i32 @puts(i8* %t1038)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_804:
  %t1039 = load i8*, i8** %t23
  %t1040 = icmp eq i8* %t1039, null
  br i1 %t1040, label %font_null_handle_805, label %font_handle_ok_806
font_null_handle_805:
  %t1041 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.75, i64 0, i64 0
  call i32 @puts(i8* %t1041)
  call void @exit(i32 1)
  unreachable
font_handle_ok_806:
  %t1042 = call i8* @SDL_GetRenderer(i8* %t1036)
  %t1043 = and i32 240, 255
  %t1044 = and i32 240, 255
  %t1045 = shl i32 %t1044, 8
  %t1046 = or i32 %t1043, %t1045
  %t1047 = and i32 245, 255
  %t1048 = shl i32 %t1047, 16
  %t1049 = or i32 %t1046, %t1048
  %t1050 = and i32 255, 255
  %t1051 = shl i32 %t1050, 24
  %t1052 = or i32 %t1049, %t1051
  %t1053 = and i32 %t1052, 255
  %t1054 = trunc i32 %t1053 to i8
  %t1055 = lshr i32 %t1052, 8
  %t1056 = and i32 %t1055, 255
  %t1057 = trunc i32 %t1056 to i8
  %t1058 = lshr i32 %t1052, 16
  %t1059 = and i32 %t1058, 255
  %t1060 = trunc i32 %t1059 to i8
  %t1061 = lshr i32 %t1052, 24
  %t1062 = and i32 %t1061, 255
  %t1063 = trunc i32 %t1062 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1042, i8 %t1054, i8 %t1057, i8 %t1060, i8 %t1063)
  %t1064 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t1065 = load i32, i32* %t1064
  %t1066 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.76, i64 0, i64 0
  %t1067 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t1066, i32 %t1065)
  %t1068 = add i32 %t1067, 1
  %t1069 = sext i32 %t1068 to i64
  %t1070 = call i8* @star_rc_alloc(i64 %t1069, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t1070, i64 %t1069, i8* %t1066, i32 %t1065)
  %t1071 = icmp sgt i32 2, 0
  %t1072 = select i1 %t1071, i32 2, i32 1
  %t1073 = load i8, i8* %t1039
  %t1074 = zext i8 %t1073 to i32
  %t1075 = getelementptr inbounds i8, i8* %t1039, i64 1
  %t1076 = load i8, i8* %t1075
  %t1077 = zext i8 %t1076 to i32
  %t1078 = getelementptr inbounds i8, i8* %t1039, i64 2
  %t1079 = load i8, i8* %t1078
  %t1080 = zext i8 %t1079 to i32
  %t1081 = getelementptr inbounds i8, i8* %t1039, i64 3
  %t1082 = load i8, i8* %t1081
  %t1083 = zext i8 %t1082 to i32
  %t1084 = add i32 %t1074, 1
  %t1085 = mul i32 %t1084, %t1072
  %t1086 = add i32 %t1077, 1
  %t1087 = mul i32 %t1086, %t1072
  store i32 6, i32* %t1088
  store i32 6, i32* %t1089
  store i64 0, i64* %t1090
  br label %draw_text_cond_807
draw_text_cond_807:
  %t1091 = load i64, i64* %t1090
  %t1092 = getelementptr inbounds i8, i8* %t1070, i64 %t1091
  %t1093 = load i8, i8* %t1092
  %t1094 = icmp eq i8 %t1093, 0
  br i1 %t1094, label %draw_text_end_813, label %draw_text_body_808
draw_text_body_808:
  %t1095 = zext i8 %t1093 to i32
  %t1096 = icmp eq i32 %t1095, 10
  br i1 %t1096, label %draw_text_newline_809, label %draw_text_glyph_810
draw_text_newline_809:
  store i32 6, i32* %t1088
  %t1097 = load i32, i32* %t1089
  %t1098 = add i32 %t1097, %t1087
  store i32 %t1098, i32* %t1089
  %t1099 = add i64 %t1091, 1
  store i64 %t1099, i64* %t1090
  br label %draw_text_cond_807
draw_text_glyph_810:
  %t1100 = icmp sge i32 %t1095, 97
  %t1101 = icmp sle i32 %t1095, 122
  %t1102 = and i1 %t1100, %t1101
  %t1103 = sub i32 %t1095, 32
  %t1104 = select i1 %t1102, i32 %t1103, i32 %t1095
  %t1105 = sub i32 %t1104, %t1080
  %t1106 = icmp sge i32 %t1105, 0
  %t1107 = icmp slt i32 %t1105, %t1083
  %t1108 = and i1 %t1106, %t1107
  br i1 %t1108, label %draw_text_draw_glyph_811, label %draw_text_advance_812
draw_text_draw_glyph_811:
  %t1109 = mul i32 %t1105, %t1077
  %t1110 = add i32 %t1109, 4
  %t1111 = sext i32 %t1110 to i64
  %t1112 = load i32, i32* %t1088
  %t1113 = load i32, i32* %t1089
  store i32 0, i32* %t1114
  br label %draw_text_row_cond_814
draw_text_row_cond_814:
  %t1115 = load i32, i32* %t1114
  %t1116 = icmp slt i32 %t1115, %t1077
  br i1 %t1116, label %draw_text_row_body_815, label %draw_text_row_end_816
draw_text_row_body_815:
  %t1117 = sext i32 %t1115 to i64
  %t1118 = add i64 %t1111, %t1117
  %t1119 = getelementptr inbounds i8, i8* %t1039, i64 %t1118
  %t1120 = load i8, i8* %t1119
  %t1121 = zext i8 %t1120 to i32
  store i32 0, i32* %t1122
  br label %draw_text_col_cond_817
draw_text_col_cond_817:
  %t1123 = load i32, i32* %t1122
  %t1124 = icmp slt i32 %t1123, %t1074
  br i1 %t1124, label %draw_text_col_body_818, label %draw_text_col_end_819
draw_text_col_body_818:
  %t1125 = sub i32 %t1074, 1
  %t1126 = sub i32 %t1125, %t1123
  %t1127 = and i32 %t1126, 31
  %t1128 = lshr i32 %t1121, %t1127
  %t1129 = and i32 %t1128, 1
  %t1130 = icmp ne i32 %t1129, 0
  br i1 %t1130, label %draw_text_pixel_820, label %draw_text_after_pixel_821
draw_text_pixel_820:
  %t1131 = mul i32 %t1123, %t1072
  %t1132 = add i32 %t1112, %t1131
  %t1133 = mul i32 %t1115, %t1072
  %t1134 = add i32 %t1113, %t1133
  %t1136 = getelementptr inbounds [16 x i8], [16 x i8]* %t1135, i64 0, i64 0
  %t1137 = bitcast i8* %t1136 to i32*
  store i32 %t1132, i32* %t1137
  %t1138 = getelementptr inbounds i8, i8* %t1136, i64 4
  %t1139 = bitcast i8* %t1138 to i32*
  store i32 %t1134, i32* %t1139
  %t1140 = getelementptr inbounds i8, i8* %t1136, i64 8
  %t1141 = bitcast i8* %t1140 to i32*
  store i32 %t1072, i32* %t1141
  %t1142 = getelementptr inbounds i8, i8* %t1136, i64 12
  %t1143 = bitcast i8* %t1142 to i32*
  store i32 %t1072, i32* %t1143
  call i32 @SDL_RenderFillRect(i8* %t1042, i8* %t1136)
  br label %draw_text_after_pixel_821
draw_text_after_pixel_821:
  %t1144 = add i32 %t1123, 1
  store i32 %t1144, i32* %t1122
  br label %draw_text_col_cond_817
draw_text_col_end_819:
  %t1145 = add i32 %t1115, 1
  store i32 %t1145, i32* %t1114
  br label %draw_text_row_cond_814
draw_text_row_end_816:
  br label %draw_text_advance_812
draw_text_advance_812:
  %t1146 = load i32, i32* %t1088
  %t1147 = add i32 %t1146, %t1085
  store i32 %t1147, i32* %t1088
  %t1148 = add i64 %t1091, 1
  store i64 %t1148, i64* %t1090
  br label %draw_text_cond_807
draw_text_end_813:
  call void @star_rc_release(i8* %t1070)
  %t1149 = load i8*, i8** %t6
  %t1150 = icmp eq i8* %t1149, null
  br i1 %t1150, label %sdl_null_window_822, label %sdl_window_handle_ok_823
sdl_null_window_822:
  %t1151 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.77, i64 0, i64 0
  call i32 @puts(i8* %t1151)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_823:
  %t1152 = load i8*, i8** %t23
  %t1153 = icmp eq i8* %t1152, null
  br i1 %t1153, label %font_null_handle_824, label %font_handle_ok_825
font_null_handle_824:
  %t1154 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.78, i64 0, i64 0
  call i32 @puts(i8* %t1154)
  call void @exit(i32 1)
  unreachable
font_handle_ok_825:
  %t1155 = call i8* @SDL_GetRenderer(i8* %t1149)
  %t1156 = and i32 190, 255
  %t1157 = and i32 190, 255
  %t1158 = shl i32 %t1157, 8
  %t1159 = or i32 %t1156, %t1158
  %t1160 = and i32 200, 255
  %t1161 = shl i32 %t1160, 16
  %t1162 = or i32 %t1159, %t1161
  %t1163 = and i32 255, 255
  %t1164 = shl i32 %t1163, 24
  %t1165 = or i32 %t1162, %t1164
  %t1166 = and i32 %t1165, 255
  %t1167 = trunc i32 %t1166 to i8
  %t1168 = lshr i32 %t1165, 8
  %t1169 = and i32 %t1168, 255
  %t1170 = trunc i32 %t1169 to i8
  %t1171 = lshr i32 %t1165, 16
  %t1172 = and i32 %t1171, 255
  %t1173 = trunc i32 %t1172 to i8
  %t1174 = lshr i32 %t1165, 24
  %t1175 = and i32 %t1174, 255
  %t1176 = trunc i32 %t1175 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1155, i8 %t1167, i8 %t1170, i8 %t1173, i8 %t1176)
  %t1177 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t1178 = load i32, i32* %t1177
  %t1179 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.79, i64 0, i64 0
  %t1180 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t1179, i32 %t1178)
  %t1181 = add i32 %t1180, 1
  %t1182 = sext i32 %t1181 to i64
  %t1183 = call i8* @star_rc_alloc(i64 %t1182, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t1183, i64 %t1182, i8* %t1179, i32 %t1178)
  %t1184 = icmp sgt i32 2, 0
  %t1185 = select i1 %t1184, i32 2, i32 1
  %t1186 = load i8, i8* %t1152
  %t1187 = zext i8 %t1186 to i32
  %t1188 = getelementptr inbounds i8, i8* %t1152, i64 1
  %t1189 = load i8, i8* %t1188
  %t1190 = zext i8 %t1189 to i32
  %t1191 = getelementptr inbounds i8, i8* %t1152, i64 2
  %t1192 = load i8, i8* %t1191
  %t1193 = zext i8 %t1192 to i32
  %t1194 = getelementptr inbounds i8, i8* %t1152, i64 3
  %t1195 = load i8, i8* %t1194
  %t1196 = zext i8 %t1195 to i32
  %t1197 = add i32 %t1187, 1
  %t1198 = mul i32 %t1197, %t1185
  %t1199 = add i32 %t1190, 1
  %t1200 = mul i32 %t1199, %t1185
  store i32 6, i32* %t1201
  store i32 24, i32* %t1202
  store i64 0, i64* %t1203
  br label %draw_text_cond_826
draw_text_cond_826:
  %t1204 = load i64, i64* %t1203
  %t1205 = getelementptr inbounds i8, i8* %t1183, i64 %t1204
  %t1206 = load i8, i8* %t1205
  %t1207 = icmp eq i8 %t1206, 0
  br i1 %t1207, label %draw_text_end_832, label %draw_text_body_827
draw_text_body_827:
  %t1208 = zext i8 %t1206 to i32
  %t1209 = icmp eq i32 %t1208, 10
  br i1 %t1209, label %draw_text_newline_828, label %draw_text_glyph_829
draw_text_newline_828:
  store i32 6, i32* %t1201
  %t1210 = load i32, i32* %t1202
  %t1211 = add i32 %t1210, %t1200
  store i32 %t1211, i32* %t1202
  %t1212 = add i64 %t1204, 1
  store i64 %t1212, i64* %t1203
  br label %draw_text_cond_826
draw_text_glyph_829:
  %t1213 = icmp sge i32 %t1208, 97
  %t1214 = icmp sle i32 %t1208, 122
  %t1215 = and i1 %t1213, %t1214
  %t1216 = sub i32 %t1208, 32
  %t1217 = select i1 %t1215, i32 %t1216, i32 %t1208
  %t1218 = sub i32 %t1217, %t1193
  %t1219 = icmp sge i32 %t1218, 0
  %t1220 = icmp slt i32 %t1218, %t1196
  %t1221 = and i1 %t1219, %t1220
  br i1 %t1221, label %draw_text_draw_glyph_830, label %draw_text_advance_831
draw_text_draw_glyph_830:
  %t1222 = mul i32 %t1218, %t1190
  %t1223 = add i32 %t1222, 4
  %t1224 = sext i32 %t1223 to i64
  %t1225 = load i32, i32* %t1201
  %t1226 = load i32, i32* %t1202
  store i32 0, i32* %t1227
  br label %draw_text_row_cond_833
draw_text_row_cond_833:
  %t1228 = load i32, i32* %t1227
  %t1229 = icmp slt i32 %t1228, %t1190
  br i1 %t1229, label %draw_text_row_body_834, label %draw_text_row_end_835
draw_text_row_body_834:
  %t1230 = sext i32 %t1228 to i64
  %t1231 = add i64 %t1224, %t1230
  %t1232 = getelementptr inbounds i8, i8* %t1152, i64 %t1231
  %t1233 = load i8, i8* %t1232
  %t1234 = zext i8 %t1233 to i32
  store i32 0, i32* %t1235
  br label %draw_text_col_cond_836
draw_text_col_cond_836:
  %t1236 = load i32, i32* %t1235
  %t1237 = icmp slt i32 %t1236, %t1187
  br i1 %t1237, label %draw_text_col_body_837, label %draw_text_col_end_838
draw_text_col_body_837:
  %t1238 = sub i32 %t1187, 1
  %t1239 = sub i32 %t1238, %t1236
  %t1240 = and i32 %t1239, 31
  %t1241 = lshr i32 %t1234, %t1240
  %t1242 = and i32 %t1241, 1
  %t1243 = icmp ne i32 %t1242, 0
  br i1 %t1243, label %draw_text_pixel_839, label %draw_text_after_pixel_840
draw_text_pixel_839:
  %t1244 = mul i32 %t1236, %t1185
  %t1245 = add i32 %t1225, %t1244
  %t1246 = mul i32 %t1228, %t1185
  %t1247 = add i32 %t1226, %t1246
  %t1249 = getelementptr inbounds [16 x i8], [16 x i8]* %t1248, i64 0, i64 0
  %t1250 = bitcast i8* %t1249 to i32*
  store i32 %t1245, i32* %t1250
  %t1251 = getelementptr inbounds i8, i8* %t1249, i64 4
  %t1252 = bitcast i8* %t1251 to i32*
  store i32 %t1247, i32* %t1252
  %t1253 = getelementptr inbounds i8, i8* %t1249, i64 8
  %t1254 = bitcast i8* %t1253 to i32*
  store i32 %t1185, i32* %t1254
  %t1255 = getelementptr inbounds i8, i8* %t1249, i64 12
  %t1256 = bitcast i8* %t1255 to i32*
  store i32 %t1185, i32* %t1256
  call i32 @SDL_RenderFillRect(i8* %t1155, i8* %t1249)
  br label %draw_text_after_pixel_840
draw_text_after_pixel_840:
  %t1257 = add i32 %t1236, 1
  store i32 %t1257, i32* %t1235
  br label %draw_text_col_cond_836
draw_text_col_end_838:
  %t1258 = add i32 %t1228, 1
  store i32 %t1258, i32* %t1227
  br label %draw_text_row_cond_833
draw_text_row_end_835:
  br label %draw_text_advance_831
draw_text_advance_831:
  %t1259 = load i32, i32* %t1201
  %t1260 = add i32 %t1259, %t1198
  store i32 %t1260, i32* %t1201
  %t1261 = add i64 %t1204, 1
  store i64 %t1261, i64* %t1203
  br label %draw_text_cond_826
draw_text_end_832:
  call void @star_rc_release(i8* %t1183)
  %t1262 = load i64, i64* %t78
  %t1263 = zext i32 0 to i64
  %t1264 = shl i64 1, %t1263
  %t1265 = and i64 %t1262, %t1264
  %t1266 = icmp ne i64 %t1265, 0
  br i1 %t1266, label %if_then_841, label %if_else_842
if_then_841:
  %t1268 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.80, i64 0, i32 2, i64 0
  store i8* %t1268, i8** %t1267
  %t1270 = load i8*, i8** %t23
  %t1271 = icmp eq i8* %t1270, null
  br i1 %t1271, label %font_null_handle_844, label %font_handle_ok_845
font_null_handle_844:
  %t1272 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.81, i64 0, i64 0
  call i32 @puts(i8* %t1272)
  call void @exit(i32 1)
  unreachable
font_handle_ok_845:
  %t1273 = load i8*, i8** %t1267
  %t1274 = load i8*, i8** %t1267
  call void @star_rc_retain(i8* %t1274)
  %t1275 = icmp sgt i32 3, 0
  %t1276 = select i1 %t1275, i32 3, i32 1
  %t1277 = load i8, i8* %t1270
  %t1278 = zext i8 %t1277 to i32
  %t1279 = getelementptr inbounds i8, i8* %t1270, i64 1
  %t1280 = load i8, i8* %t1279
  %t1281 = zext i8 %t1280 to i32
  %t1282 = getelementptr inbounds i8, i8* %t1270, i64 2
  %t1283 = load i8, i8* %t1282
  %t1284 = zext i8 %t1283 to i32
  %t1285 = getelementptr inbounds i8, i8* %t1270, i64 3
  %t1286 = load i8, i8* %t1285
  %t1287 = zext i8 %t1286 to i32
  %t1288 = add i32 %t1278, 1
  %t1289 = mul i32 %t1288, %t1276
  %t1290 = add i32 %t1281, 1
  %t1291 = mul i32 %t1290, %t1276
  store i32 0, i32* %t1292
  store i32 0, i32* %t1293
  store i32 1, i32* %t1294
  store i64 0, i64* %t1295
  br label %measure_text_cond_846
measure_text_cond_846:
  %t1296 = load i64, i64* %t1295
  %t1297 = getelementptr inbounds i8, i8* %t1273, i64 %t1296
  %t1298 = load i8, i8* %t1297
  %t1299 = icmp eq i8 %t1298, 0
  br i1 %t1299, label %measure_text_end_850, label %measure_text_body_847
measure_text_body_847:
  %t1300 = zext i8 %t1298 to i32
  %t1301 = icmp eq i32 %t1300, 10
  br i1 %t1301, label %measure_text_newline_848, label %measure_text_advance_849
measure_text_newline_848:
  %t1302 = load i32, i32* %t1292
  %t1303 = load i32, i32* %t1293
  %t1304 = icmp sgt i32 %t1302, %t1303
  %t1305 = select i1 %t1304, i32 %t1302, i32 %t1303
  store i32 %t1305, i32* %t1293
  store i32 0, i32* %t1292
  %t1306 = load i32, i32* %t1294
  %t1307 = add i32 %t1306, 1
  store i32 %t1307, i32* %t1294
  %t1308 = add i64 %t1296, 1
  store i64 %t1308, i64* %t1295
  br label %measure_text_cond_846
measure_text_advance_849:
  %t1309 = load i32, i32* %t1292
  %t1310 = add i32 %t1309, %t1289
  store i32 %t1310, i32* %t1292
  %t1311 = add i64 %t1296, 1
  store i64 %t1311, i64* %t1295
  br label %measure_text_cond_846
measure_text_end_850:
  call void @star_rc_release(i8* %t1273)
  %t1312 = load i32, i32* %t1292
  %t1313 = load i32, i32* %t1293
  %t1314 = icmp sgt i32 %t1312, %t1313
  %t1315 = select i1 %t1314, i32 %t1312, i32 %t1313
  %t1316 = load i32, i32* %t1294
  %t1317 = mul i32 %t1316, %t1291
  %t1318 = sub i32 %t1317, %t1276
  %t1320 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1319, i32 0, i32 0
  store i32 %t1315, i32* %t1320
  %t1321 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1319, i32 0, i32 1
  store i32 %t1318, i32* %t1321
  %t1322 = load { i32, i32 }, { i32, i32 }* %t1319
  store { i32, i32 } %t1322, { i32, i32 }* %t1269
  %t1323 = load i8*, i8** %t6
  %t1324 = icmp eq i8* %t1323, null
  br i1 %t1324, label %sdl_null_window_851, label %sdl_window_handle_ok_852
sdl_null_window_851:
  %t1325 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.82, i64 0, i64 0
  call i32 @puts(i8* %t1325)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_852:
  %t1326 = load i8*, i8** %t23
  %t1327 = icmp eq i8* %t1326, null
  br i1 %t1327, label %font_null_handle_853, label %font_handle_ok_854
font_null_handle_853:
  %t1328 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.83, i64 0, i64 0
  call i32 @puts(i8* %t1328)
  call void @exit(i32 1)
  unreachable
font_handle_ok_854:
  %t1329 = call i8* @SDL_GetRenderer(i8* %t1323)
  %t1330 = and i32 255, 255
  %t1331 = and i32 220, 255
  %t1332 = shl i32 %t1331, 8
  %t1333 = or i32 %t1330, %t1332
  %t1334 = and i32 90, 255
  %t1335 = shl i32 %t1334, 16
  %t1336 = or i32 %t1333, %t1335
  %t1337 = and i32 255, 255
  %t1338 = shl i32 %t1337, 24
  %t1339 = or i32 %t1336, %t1338
  %t1340 = and i32 %t1339, 255
  %t1341 = trunc i32 %t1340 to i8
  %t1342 = lshr i32 %t1339, 8
  %t1343 = and i32 %t1342, 255
  %t1344 = trunc i32 %t1343 to i8
  %t1345 = lshr i32 %t1339, 16
  %t1346 = and i32 %t1345, 255
  %t1347 = trunc i32 %t1346 to i8
  %t1348 = lshr i32 %t1339, 24
  %t1349 = and i32 %t1348, 255
  %t1350 = trunc i32 %t1349 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1329, i8 %t1341, i8 %t1344, i8 %t1347, i8 %t1350)
  %t1351 = load i8*, i8** %t1267
  %t1352 = load i8*, i8** %t1267
  call void @star_rc_retain(i8* %t1352)
  %t1353 = load i32, i32* %t2
  %t1354 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1269, i32 0, i32 0
  %t1355 = load i32, i32* %t1354
  %t1356 = sub i32 %t1353, %t1355
  %t1357 = icmp eq i32 2, 0
  %t1358 = icmp eq i32 %t1356, -2147483648
  %t1359 = icmp eq i32 2, -1
  %t1360 = and i1 %t1358, %t1359
  %t1361 = or i1 %t1357, %t1360
  br i1 %t1361, label %int_div_fail_855, label %int_div_ok_856
int_div_fail_855:
  %t1362 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.84, i64 0, i64 0
  call i32 @puts(i8* %t1362)
  call void @exit(i32 1)
  unreachable
int_div_ok_856:
  %t1363 = sdiv i32 %t1356, 2
  %t1364 = load i32, i32* %t4
  %t1365 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1269, i32 0, i32 1
  %t1366 = load i32, i32* %t1365
  %t1367 = sub i32 %t1364, %t1366
  %t1368 = icmp eq i32 2, 0
  %t1369 = icmp eq i32 %t1367, -2147483648
  %t1370 = icmp eq i32 2, -1
  %t1371 = and i1 %t1369, %t1370
  %t1372 = or i1 %t1368, %t1371
  br i1 %t1372, label %int_div_fail_857, label %int_div_ok_858
int_div_fail_857:
  %t1373 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.85, i64 0, i64 0
  call i32 @puts(i8* %t1373)
  call void @exit(i32 1)
  unreachable
int_div_ok_858:
  %t1374 = sdiv i32 %t1367, 2
  %t1375 = icmp sgt i32 3, 0
  %t1376 = select i1 %t1375, i32 3, i32 1
  %t1377 = load i8, i8* %t1326
  %t1378 = zext i8 %t1377 to i32
  %t1379 = getelementptr inbounds i8, i8* %t1326, i64 1
  %t1380 = load i8, i8* %t1379
  %t1381 = zext i8 %t1380 to i32
  %t1382 = getelementptr inbounds i8, i8* %t1326, i64 2
  %t1383 = load i8, i8* %t1382
  %t1384 = zext i8 %t1383 to i32
  %t1385 = getelementptr inbounds i8, i8* %t1326, i64 3
  %t1386 = load i8, i8* %t1385
  %t1387 = zext i8 %t1386 to i32
  %t1388 = add i32 %t1378, 1
  %t1389 = mul i32 %t1388, %t1376
  %t1390 = add i32 %t1381, 1
  %t1391 = mul i32 %t1390, %t1376
  store i32 %t1363, i32* %t1392
  store i32 %t1374, i32* %t1393
  store i64 0, i64* %t1394
  br label %draw_text_cond_859
draw_text_cond_859:
  %t1395 = load i64, i64* %t1394
  %t1396 = getelementptr inbounds i8, i8* %t1351, i64 %t1395
  %t1397 = load i8, i8* %t1396
  %t1398 = icmp eq i8 %t1397, 0
  br i1 %t1398, label %draw_text_end_865, label %draw_text_body_860
draw_text_body_860:
  %t1399 = zext i8 %t1397 to i32
  %t1400 = icmp eq i32 %t1399, 10
  br i1 %t1400, label %draw_text_newline_861, label %draw_text_glyph_862
draw_text_newline_861:
  store i32 %t1363, i32* %t1392
  %t1401 = load i32, i32* %t1393
  %t1402 = add i32 %t1401, %t1391
  store i32 %t1402, i32* %t1393
  %t1403 = add i64 %t1395, 1
  store i64 %t1403, i64* %t1394
  br label %draw_text_cond_859
draw_text_glyph_862:
  %t1404 = icmp sge i32 %t1399, 97
  %t1405 = icmp sle i32 %t1399, 122
  %t1406 = and i1 %t1404, %t1405
  %t1407 = sub i32 %t1399, 32
  %t1408 = select i1 %t1406, i32 %t1407, i32 %t1399
  %t1409 = sub i32 %t1408, %t1384
  %t1410 = icmp sge i32 %t1409, 0
  %t1411 = icmp slt i32 %t1409, %t1387
  %t1412 = and i1 %t1410, %t1411
  br i1 %t1412, label %draw_text_draw_glyph_863, label %draw_text_advance_864
draw_text_draw_glyph_863:
  %t1413 = mul i32 %t1409, %t1381
  %t1414 = add i32 %t1413, 4
  %t1415 = sext i32 %t1414 to i64
  %t1416 = load i32, i32* %t1392
  %t1417 = load i32, i32* %t1393
  store i32 0, i32* %t1418
  br label %draw_text_row_cond_866
draw_text_row_cond_866:
  %t1419 = load i32, i32* %t1418
  %t1420 = icmp slt i32 %t1419, %t1381
  br i1 %t1420, label %draw_text_row_body_867, label %draw_text_row_end_868
draw_text_row_body_867:
  %t1421 = sext i32 %t1419 to i64
  %t1422 = add i64 %t1415, %t1421
  %t1423 = getelementptr inbounds i8, i8* %t1326, i64 %t1422
  %t1424 = load i8, i8* %t1423
  %t1425 = zext i8 %t1424 to i32
  store i32 0, i32* %t1426
  br label %draw_text_col_cond_869
draw_text_col_cond_869:
  %t1427 = load i32, i32* %t1426
  %t1428 = icmp slt i32 %t1427, %t1378
  br i1 %t1428, label %draw_text_col_body_870, label %draw_text_col_end_871
draw_text_col_body_870:
  %t1429 = sub i32 %t1378, 1
  %t1430 = sub i32 %t1429, %t1427
  %t1431 = and i32 %t1430, 31
  %t1432 = lshr i32 %t1425, %t1431
  %t1433 = and i32 %t1432, 1
  %t1434 = icmp ne i32 %t1433, 0
  br i1 %t1434, label %draw_text_pixel_872, label %draw_text_after_pixel_873
draw_text_pixel_872:
  %t1435 = mul i32 %t1427, %t1376
  %t1436 = add i32 %t1416, %t1435
  %t1437 = mul i32 %t1419, %t1376
  %t1438 = add i32 %t1417, %t1437
  %t1440 = getelementptr inbounds [16 x i8], [16 x i8]* %t1439, i64 0, i64 0
  %t1441 = bitcast i8* %t1440 to i32*
  store i32 %t1436, i32* %t1441
  %t1442 = getelementptr inbounds i8, i8* %t1440, i64 4
  %t1443 = bitcast i8* %t1442 to i32*
  store i32 %t1438, i32* %t1443
  %t1444 = getelementptr inbounds i8, i8* %t1440, i64 8
  %t1445 = bitcast i8* %t1444 to i32*
  store i32 %t1376, i32* %t1445
  %t1446 = getelementptr inbounds i8, i8* %t1440, i64 12
  %t1447 = bitcast i8* %t1446 to i32*
  store i32 %t1376, i32* %t1447
  call i32 @SDL_RenderFillRect(i8* %t1329, i8* %t1440)
  br label %draw_text_after_pixel_873
draw_text_after_pixel_873:
  %t1448 = add i32 %t1427, 1
  store i32 %t1448, i32* %t1426
  br label %draw_text_col_cond_869
draw_text_col_end_871:
  %t1449 = add i32 %t1419, 1
  store i32 %t1449, i32* %t1418
  br label %draw_text_row_cond_866
draw_text_row_end_868:
  br label %draw_text_advance_864
draw_text_advance_864:
  %t1450 = load i32, i32* %t1392
  %t1451 = add i32 %t1450, %t1389
  store i32 %t1451, i32* %t1392
  %t1452 = add i64 %t1395, 1
  store i64 %t1452, i64* %t1394
  br label %draw_text_cond_859
draw_text_end_865:
  call void @star_rc_release(i8* %t1351)
  %t1453 = load i8*, i8** %t1267
  call void @star_rc_release(i8* %t1453)
  br label %if_end_843
if_else_842:
  br label %if_end_843
if_end_843:
  %t1454 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 4
  %t1455 = load i1, i1* %t1454
  %t1456 = xor i1 true, %t1455
  br i1 %t1456, label %if_then_874, label %if_else_875
if_then_874:
  %t1458 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.86, i64 0, i32 2, i64 0
  store i8* %t1458, i8** %t1457
  %t1460 = getelementptr inbounds { i64, i8*, [19 x i8] }, { i64, i8*, [19 x i8] }* @.str.87, i64 0, i32 2, i64 0
  store i8* %t1460, i8** %t1459
  %t1462 = load i8*, i8** %t23
  %t1463 = icmp eq i8* %t1462, null
  br i1 %t1463, label %font_null_handle_877, label %font_handle_ok_878
font_null_handle_877:
  %t1464 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.88, i64 0, i64 0
  call i32 @puts(i8* %t1464)
  call void @exit(i32 1)
  unreachable
font_handle_ok_878:
  %t1465 = load i8*, i8** %t1457
  %t1466 = load i8*, i8** %t1457
  call void @star_rc_retain(i8* %t1466)
  %t1467 = icmp sgt i32 3, 0
  %t1468 = select i1 %t1467, i32 3, i32 1
  %t1469 = load i8, i8* %t1462
  %t1470 = zext i8 %t1469 to i32
  %t1471 = getelementptr inbounds i8, i8* %t1462, i64 1
  %t1472 = load i8, i8* %t1471
  %t1473 = zext i8 %t1472 to i32
  %t1474 = getelementptr inbounds i8, i8* %t1462, i64 2
  %t1475 = load i8, i8* %t1474
  %t1476 = zext i8 %t1475 to i32
  %t1477 = getelementptr inbounds i8, i8* %t1462, i64 3
  %t1478 = load i8, i8* %t1477
  %t1479 = zext i8 %t1478 to i32
  %t1480 = add i32 %t1470, 1
  %t1481 = mul i32 %t1480, %t1468
  %t1482 = add i32 %t1473, 1
  %t1483 = mul i32 %t1482, %t1468
  store i32 0, i32* %t1484
  store i32 0, i32* %t1485
  store i32 1, i32* %t1486
  store i64 0, i64* %t1487
  br label %measure_text_cond_879
measure_text_cond_879:
  %t1488 = load i64, i64* %t1487
  %t1489 = getelementptr inbounds i8, i8* %t1465, i64 %t1488
  %t1490 = load i8, i8* %t1489
  %t1491 = icmp eq i8 %t1490, 0
  br i1 %t1491, label %measure_text_end_883, label %measure_text_body_880
measure_text_body_880:
  %t1492 = zext i8 %t1490 to i32
  %t1493 = icmp eq i32 %t1492, 10
  br i1 %t1493, label %measure_text_newline_881, label %measure_text_advance_882
measure_text_newline_881:
  %t1494 = load i32, i32* %t1484
  %t1495 = load i32, i32* %t1485
  %t1496 = icmp sgt i32 %t1494, %t1495
  %t1497 = select i1 %t1496, i32 %t1494, i32 %t1495
  store i32 %t1497, i32* %t1485
  store i32 0, i32* %t1484
  %t1498 = load i32, i32* %t1486
  %t1499 = add i32 %t1498, 1
  store i32 %t1499, i32* %t1486
  %t1500 = add i64 %t1488, 1
  store i64 %t1500, i64* %t1487
  br label %measure_text_cond_879
measure_text_advance_882:
  %t1501 = load i32, i32* %t1484
  %t1502 = add i32 %t1501, %t1481
  store i32 %t1502, i32* %t1484
  %t1503 = add i64 %t1488, 1
  store i64 %t1503, i64* %t1487
  br label %measure_text_cond_879
measure_text_end_883:
  call void @star_rc_release(i8* %t1465)
  %t1504 = load i32, i32* %t1484
  %t1505 = load i32, i32* %t1485
  %t1506 = icmp sgt i32 %t1504, %t1505
  %t1507 = select i1 %t1506, i32 %t1504, i32 %t1505
  %t1508 = load i32, i32* %t1486
  %t1509 = mul i32 %t1508, %t1483
  %t1510 = sub i32 %t1509, %t1468
  %t1512 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1511, i32 0, i32 0
  store i32 %t1507, i32* %t1512
  %t1513 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1511, i32 0, i32 1
  store i32 %t1510, i32* %t1513
  %t1514 = load { i32, i32 }, { i32, i32 }* %t1511
  store { i32, i32 } %t1514, { i32, i32 }* %t1461
  %t1516 = load i8*, i8** %t23
  %t1517 = icmp eq i8* %t1516, null
  br i1 %t1517, label %font_null_handle_884, label %font_handle_ok_885
font_null_handle_884:
  %t1518 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.89, i64 0, i64 0
  call i32 @puts(i8* %t1518)
  call void @exit(i32 1)
  unreachable
font_handle_ok_885:
  %t1519 = load i8*, i8** %t1459
  %t1520 = load i8*, i8** %t1459
  call void @star_rc_retain(i8* %t1520)
  %t1521 = icmp sgt i32 2, 0
  %t1522 = select i1 %t1521, i32 2, i32 1
  %t1523 = load i8, i8* %t1516
  %t1524 = zext i8 %t1523 to i32
  %t1525 = getelementptr inbounds i8, i8* %t1516, i64 1
  %t1526 = load i8, i8* %t1525
  %t1527 = zext i8 %t1526 to i32
  %t1528 = getelementptr inbounds i8, i8* %t1516, i64 2
  %t1529 = load i8, i8* %t1528
  %t1530 = zext i8 %t1529 to i32
  %t1531 = getelementptr inbounds i8, i8* %t1516, i64 3
  %t1532 = load i8, i8* %t1531
  %t1533 = zext i8 %t1532 to i32
  %t1534 = add i32 %t1524, 1
  %t1535 = mul i32 %t1534, %t1522
  %t1536 = add i32 %t1527, 1
  %t1537 = mul i32 %t1536, %t1522
  store i32 0, i32* %t1538
  store i32 0, i32* %t1539
  store i32 1, i32* %t1540
  store i64 0, i64* %t1541
  br label %measure_text_cond_886
measure_text_cond_886:
  %t1542 = load i64, i64* %t1541
  %t1543 = getelementptr inbounds i8, i8* %t1519, i64 %t1542
  %t1544 = load i8, i8* %t1543
  %t1545 = icmp eq i8 %t1544, 0
  br i1 %t1545, label %measure_text_end_890, label %measure_text_body_887
measure_text_body_887:
  %t1546 = zext i8 %t1544 to i32
  %t1547 = icmp eq i32 %t1546, 10
  br i1 %t1547, label %measure_text_newline_888, label %measure_text_advance_889
measure_text_newline_888:
  %t1548 = load i32, i32* %t1538
  %t1549 = load i32, i32* %t1539
  %t1550 = icmp sgt i32 %t1548, %t1549
  %t1551 = select i1 %t1550, i32 %t1548, i32 %t1549
  store i32 %t1551, i32* %t1539
  store i32 0, i32* %t1538
  %t1552 = load i32, i32* %t1540
  %t1553 = add i32 %t1552, 1
  store i32 %t1553, i32* %t1540
  %t1554 = add i64 %t1542, 1
  store i64 %t1554, i64* %t1541
  br label %measure_text_cond_886
measure_text_advance_889:
  %t1555 = load i32, i32* %t1538
  %t1556 = add i32 %t1555, %t1535
  store i32 %t1556, i32* %t1538
  %t1557 = add i64 %t1542, 1
  store i64 %t1557, i64* %t1541
  br label %measure_text_cond_886
measure_text_end_890:
  call void @star_rc_release(i8* %t1519)
  %t1558 = load i32, i32* %t1538
  %t1559 = load i32, i32* %t1539
  %t1560 = icmp sgt i32 %t1558, %t1559
  %t1561 = select i1 %t1560, i32 %t1558, i32 %t1559
  %t1562 = load i32, i32* %t1540
  %t1563 = mul i32 %t1562, %t1537
  %t1564 = sub i32 %t1563, %t1522
  %t1566 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1565, i32 0, i32 0
  store i32 %t1561, i32* %t1566
  %t1567 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1565, i32 0, i32 1
  store i32 %t1564, i32* %t1567
  %t1568 = load { i32, i32 }, { i32, i32 }* %t1565
  store { i32, i32 } %t1568, { i32, i32 }* %t1515
  %t1570 = load i32, i32* %t4
  %t1571 = icmp eq i32 2, 0
  %t1572 = icmp eq i32 %t1570, -2147483648
  %t1573 = icmp eq i32 2, -1
  %t1574 = and i1 %t1572, %t1573
  %t1575 = or i1 %t1571, %t1574
  br i1 %t1575, label %int_div_fail_891, label %int_div_ok_892
int_div_fail_891:
  %t1576 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.90, i64 0, i64 0
  call i32 @puts(i8* %t1576)
  call void @exit(i32 1)
  unreachable
int_div_ok_892:
  %t1577 = sdiv i32 %t1570, 2
  %t1578 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1461, i32 0, i32 1
  %t1579 = load i32, i32* %t1578
  %t1580 = sub i32 %t1577, %t1579
  %t1581 = sub i32 %t1580, 6
  store i32 %t1581, i32* %t1569
  %t1582 = load i8*, i8** %t6
  %t1583 = icmp eq i8* %t1582, null
  br i1 %t1583, label %sdl_null_window_893, label %sdl_window_handle_ok_894
sdl_null_window_893:
  %t1584 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.91, i64 0, i64 0
  call i32 @puts(i8* %t1584)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_894:
  %t1585 = load i8*, i8** %t23
  %t1586 = icmp eq i8* %t1585, null
  br i1 %t1586, label %font_null_handle_895, label %font_handle_ok_896
font_null_handle_895:
  %t1587 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.92, i64 0, i64 0
  call i32 @puts(i8* %t1587)
  call void @exit(i32 1)
  unreachable
font_handle_ok_896:
  %t1588 = call i8* @SDL_GetRenderer(i8* %t1582)
  %t1589 = and i32 230, 255
  %t1590 = and i32 90, 255
  %t1591 = shl i32 %t1590, 8
  %t1592 = or i32 %t1589, %t1591
  %t1593 = and i32 90, 255
  %t1594 = shl i32 %t1593, 16
  %t1595 = or i32 %t1592, %t1594
  %t1596 = and i32 255, 255
  %t1597 = shl i32 %t1596, 24
  %t1598 = or i32 %t1595, %t1597
  %t1599 = and i32 %t1598, 255
  %t1600 = trunc i32 %t1599 to i8
  %t1601 = lshr i32 %t1598, 8
  %t1602 = and i32 %t1601, 255
  %t1603 = trunc i32 %t1602 to i8
  %t1604 = lshr i32 %t1598, 16
  %t1605 = and i32 %t1604, 255
  %t1606 = trunc i32 %t1605 to i8
  %t1607 = lshr i32 %t1598, 24
  %t1608 = and i32 %t1607, 255
  %t1609 = trunc i32 %t1608 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1588, i8 %t1600, i8 %t1603, i8 %t1606, i8 %t1609)
  %t1610 = load i8*, i8** %t1457
  %t1611 = load i8*, i8** %t1457
  call void @star_rc_retain(i8* %t1611)
  %t1612 = load i32, i32* %t2
  %t1613 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1461, i32 0, i32 0
  %t1614 = load i32, i32* %t1613
  %t1615 = sub i32 %t1612, %t1614
  %t1616 = icmp eq i32 2, 0
  %t1617 = icmp eq i32 %t1615, -2147483648
  %t1618 = icmp eq i32 2, -1
  %t1619 = and i1 %t1617, %t1618
  %t1620 = or i1 %t1616, %t1619
  br i1 %t1620, label %int_div_fail_897, label %int_div_ok_898
int_div_fail_897:
  %t1621 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.93, i64 0, i64 0
  call i32 @puts(i8* %t1621)
  call void @exit(i32 1)
  unreachable
int_div_ok_898:
  %t1622 = sdiv i32 %t1615, 2
  %t1623 = load i32, i32* %t1569
  %t1624 = icmp sgt i32 3, 0
  %t1625 = select i1 %t1624, i32 3, i32 1
  %t1626 = load i8, i8* %t1585
  %t1627 = zext i8 %t1626 to i32
  %t1628 = getelementptr inbounds i8, i8* %t1585, i64 1
  %t1629 = load i8, i8* %t1628
  %t1630 = zext i8 %t1629 to i32
  %t1631 = getelementptr inbounds i8, i8* %t1585, i64 2
  %t1632 = load i8, i8* %t1631
  %t1633 = zext i8 %t1632 to i32
  %t1634 = getelementptr inbounds i8, i8* %t1585, i64 3
  %t1635 = load i8, i8* %t1634
  %t1636 = zext i8 %t1635 to i32
  %t1637 = add i32 %t1627, 1
  %t1638 = mul i32 %t1637, %t1625
  %t1639 = add i32 %t1630, 1
  %t1640 = mul i32 %t1639, %t1625
  store i32 %t1622, i32* %t1641
  store i32 %t1623, i32* %t1642
  store i64 0, i64* %t1643
  br label %draw_text_cond_899
draw_text_cond_899:
  %t1644 = load i64, i64* %t1643
  %t1645 = getelementptr inbounds i8, i8* %t1610, i64 %t1644
  %t1646 = load i8, i8* %t1645
  %t1647 = icmp eq i8 %t1646, 0
  br i1 %t1647, label %draw_text_end_905, label %draw_text_body_900
draw_text_body_900:
  %t1648 = zext i8 %t1646 to i32
  %t1649 = icmp eq i32 %t1648, 10
  br i1 %t1649, label %draw_text_newline_901, label %draw_text_glyph_902
draw_text_newline_901:
  store i32 %t1622, i32* %t1641
  %t1650 = load i32, i32* %t1642
  %t1651 = add i32 %t1650, %t1640
  store i32 %t1651, i32* %t1642
  %t1652 = add i64 %t1644, 1
  store i64 %t1652, i64* %t1643
  br label %draw_text_cond_899
draw_text_glyph_902:
  %t1653 = icmp sge i32 %t1648, 97
  %t1654 = icmp sle i32 %t1648, 122
  %t1655 = and i1 %t1653, %t1654
  %t1656 = sub i32 %t1648, 32
  %t1657 = select i1 %t1655, i32 %t1656, i32 %t1648
  %t1658 = sub i32 %t1657, %t1633
  %t1659 = icmp sge i32 %t1658, 0
  %t1660 = icmp slt i32 %t1658, %t1636
  %t1661 = and i1 %t1659, %t1660
  br i1 %t1661, label %draw_text_draw_glyph_903, label %draw_text_advance_904
draw_text_draw_glyph_903:
  %t1662 = mul i32 %t1658, %t1630
  %t1663 = add i32 %t1662, 4
  %t1664 = sext i32 %t1663 to i64
  %t1665 = load i32, i32* %t1641
  %t1666 = load i32, i32* %t1642
  store i32 0, i32* %t1667
  br label %draw_text_row_cond_906
draw_text_row_cond_906:
  %t1668 = load i32, i32* %t1667
  %t1669 = icmp slt i32 %t1668, %t1630
  br i1 %t1669, label %draw_text_row_body_907, label %draw_text_row_end_908
draw_text_row_body_907:
  %t1670 = sext i32 %t1668 to i64
  %t1671 = add i64 %t1664, %t1670
  %t1672 = getelementptr inbounds i8, i8* %t1585, i64 %t1671
  %t1673 = load i8, i8* %t1672
  %t1674 = zext i8 %t1673 to i32
  store i32 0, i32* %t1675
  br label %draw_text_col_cond_909
draw_text_col_cond_909:
  %t1676 = load i32, i32* %t1675
  %t1677 = icmp slt i32 %t1676, %t1627
  br i1 %t1677, label %draw_text_col_body_910, label %draw_text_col_end_911
draw_text_col_body_910:
  %t1678 = sub i32 %t1627, 1
  %t1679 = sub i32 %t1678, %t1676
  %t1680 = and i32 %t1679, 31
  %t1681 = lshr i32 %t1674, %t1680
  %t1682 = and i32 %t1681, 1
  %t1683 = icmp ne i32 %t1682, 0
  br i1 %t1683, label %draw_text_pixel_912, label %draw_text_after_pixel_913
draw_text_pixel_912:
  %t1684 = mul i32 %t1676, %t1625
  %t1685 = add i32 %t1665, %t1684
  %t1686 = mul i32 %t1668, %t1625
  %t1687 = add i32 %t1666, %t1686
  %t1689 = getelementptr inbounds [16 x i8], [16 x i8]* %t1688, i64 0, i64 0
  %t1690 = bitcast i8* %t1689 to i32*
  store i32 %t1685, i32* %t1690
  %t1691 = getelementptr inbounds i8, i8* %t1689, i64 4
  %t1692 = bitcast i8* %t1691 to i32*
  store i32 %t1687, i32* %t1692
  %t1693 = getelementptr inbounds i8, i8* %t1689, i64 8
  %t1694 = bitcast i8* %t1693 to i32*
  store i32 %t1625, i32* %t1694
  %t1695 = getelementptr inbounds i8, i8* %t1689, i64 12
  %t1696 = bitcast i8* %t1695 to i32*
  store i32 %t1625, i32* %t1696
  call i32 @SDL_RenderFillRect(i8* %t1588, i8* %t1689)
  br label %draw_text_after_pixel_913
draw_text_after_pixel_913:
  %t1697 = add i32 %t1676, 1
  store i32 %t1697, i32* %t1675
  br label %draw_text_col_cond_909
draw_text_col_end_911:
  %t1698 = add i32 %t1668, 1
  store i32 %t1698, i32* %t1667
  br label %draw_text_row_cond_906
draw_text_row_end_908:
  br label %draw_text_advance_904
draw_text_advance_904:
  %t1699 = load i32, i32* %t1641
  %t1700 = add i32 %t1699, %t1638
  store i32 %t1700, i32* %t1641
  %t1701 = add i64 %t1644, 1
  store i64 %t1701, i64* %t1643
  br label %draw_text_cond_899
draw_text_end_905:
  call void @star_rc_release(i8* %t1610)
  %t1702 = load i8*, i8** %t6
  %t1703 = icmp eq i8* %t1702, null
  br i1 %t1703, label %sdl_null_window_914, label %sdl_window_handle_ok_915
sdl_null_window_914:
  %t1704 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.94, i64 0, i64 0
  call i32 @puts(i8* %t1704)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_915:
  %t1705 = load i8*, i8** %t23
  %t1706 = icmp eq i8* %t1705, null
  br i1 %t1706, label %font_null_handle_916, label %font_handle_ok_917
font_null_handle_916:
  %t1707 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.95, i64 0, i64 0
  call i32 @puts(i8* %t1707)
  call void @exit(i32 1)
  unreachable
font_handle_ok_917:
  %t1708 = call i8* @SDL_GetRenderer(i8* %t1702)
  %t1709 = and i32 230, 255
  %t1710 = and i32 230, 255
  %t1711 = shl i32 %t1710, 8
  %t1712 = or i32 %t1709, %t1711
  %t1713 = and i32 235, 255
  %t1714 = shl i32 %t1713, 16
  %t1715 = or i32 %t1712, %t1714
  %t1716 = and i32 255, 255
  %t1717 = shl i32 %t1716, 24
  %t1718 = or i32 %t1715, %t1717
  %t1719 = and i32 %t1718, 255
  %t1720 = trunc i32 %t1719 to i8
  %t1721 = lshr i32 %t1718, 8
  %t1722 = and i32 %t1721, 255
  %t1723 = trunc i32 %t1722 to i8
  %t1724 = lshr i32 %t1718, 16
  %t1725 = and i32 %t1724, 255
  %t1726 = trunc i32 %t1725 to i8
  %t1727 = lshr i32 %t1718, 24
  %t1728 = and i32 %t1727, 255
  %t1729 = trunc i32 %t1728 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1708, i8 %t1720, i8 %t1723, i8 %t1726, i8 %t1729)
  %t1730 = load i8*, i8** %t1459
  %t1731 = load i8*, i8** %t1459
  call void @star_rc_retain(i8* %t1731)
  %t1732 = load i32, i32* %t2
  %t1733 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1515, i32 0, i32 0
  %t1734 = load i32, i32* %t1733
  %t1735 = sub i32 %t1732, %t1734
  %t1736 = icmp eq i32 2, 0
  %t1737 = icmp eq i32 %t1735, -2147483648
  %t1738 = icmp eq i32 2, -1
  %t1739 = and i1 %t1737, %t1738
  %t1740 = or i1 %t1736, %t1739
  br i1 %t1740, label %int_div_fail_918, label %int_div_ok_919
int_div_fail_918:
  %t1741 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.96, i64 0, i64 0
  call i32 @puts(i8* %t1741)
  call void @exit(i32 1)
  unreachable
int_div_ok_919:
  %t1742 = sdiv i32 %t1735, 2
  %t1743 = load i32, i32* %t4
  %t1744 = icmp eq i32 2, 0
  %t1745 = icmp eq i32 %t1743, -2147483648
  %t1746 = icmp eq i32 2, -1
  %t1747 = and i1 %t1745, %t1746
  %t1748 = or i1 %t1744, %t1747
  br i1 %t1748, label %int_div_fail_920, label %int_div_ok_921
int_div_fail_920:
  %t1749 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.97, i64 0, i64 0
  call i32 @puts(i8* %t1749)
  call void @exit(i32 1)
  unreachable
int_div_ok_921:
  %t1750 = sdiv i32 %t1743, 2
  %t1751 = add i32 %t1750, 6
  %t1752 = icmp sgt i32 2, 0
  %t1753 = select i1 %t1752, i32 2, i32 1
  %t1754 = load i8, i8* %t1705
  %t1755 = zext i8 %t1754 to i32
  %t1756 = getelementptr inbounds i8, i8* %t1705, i64 1
  %t1757 = load i8, i8* %t1756
  %t1758 = zext i8 %t1757 to i32
  %t1759 = getelementptr inbounds i8, i8* %t1705, i64 2
  %t1760 = load i8, i8* %t1759
  %t1761 = zext i8 %t1760 to i32
  %t1762 = getelementptr inbounds i8, i8* %t1705, i64 3
  %t1763 = load i8, i8* %t1762
  %t1764 = zext i8 %t1763 to i32
  %t1765 = add i32 %t1755, 1
  %t1766 = mul i32 %t1765, %t1753
  %t1767 = add i32 %t1758, 1
  %t1768 = mul i32 %t1767, %t1753
  store i32 %t1742, i32* %t1769
  store i32 %t1751, i32* %t1770
  store i64 0, i64* %t1771
  br label %draw_text_cond_922
draw_text_cond_922:
  %t1772 = load i64, i64* %t1771
  %t1773 = getelementptr inbounds i8, i8* %t1730, i64 %t1772
  %t1774 = load i8, i8* %t1773
  %t1775 = icmp eq i8 %t1774, 0
  br i1 %t1775, label %draw_text_end_928, label %draw_text_body_923
draw_text_body_923:
  %t1776 = zext i8 %t1774 to i32
  %t1777 = icmp eq i32 %t1776, 10
  br i1 %t1777, label %draw_text_newline_924, label %draw_text_glyph_925
draw_text_newline_924:
  store i32 %t1742, i32* %t1769
  %t1778 = load i32, i32* %t1770
  %t1779 = add i32 %t1778, %t1768
  store i32 %t1779, i32* %t1770
  %t1780 = add i64 %t1772, 1
  store i64 %t1780, i64* %t1771
  br label %draw_text_cond_922
draw_text_glyph_925:
  %t1781 = icmp sge i32 %t1776, 97
  %t1782 = icmp sle i32 %t1776, 122
  %t1783 = and i1 %t1781, %t1782
  %t1784 = sub i32 %t1776, 32
  %t1785 = select i1 %t1783, i32 %t1784, i32 %t1776
  %t1786 = sub i32 %t1785, %t1761
  %t1787 = icmp sge i32 %t1786, 0
  %t1788 = icmp slt i32 %t1786, %t1764
  %t1789 = and i1 %t1787, %t1788
  br i1 %t1789, label %draw_text_draw_glyph_926, label %draw_text_advance_927
draw_text_draw_glyph_926:
  %t1790 = mul i32 %t1786, %t1758
  %t1791 = add i32 %t1790, 4
  %t1792 = sext i32 %t1791 to i64
  %t1793 = load i32, i32* %t1769
  %t1794 = load i32, i32* %t1770
  store i32 0, i32* %t1795
  br label %draw_text_row_cond_929
draw_text_row_cond_929:
  %t1796 = load i32, i32* %t1795
  %t1797 = icmp slt i32 %t1796, %t1758
  br i1 %t1797, label %draw_text_row_body_930, label %draw_text_row_end_931
draw_text_row_body_930:
  %t1798 = sext i32 %t1796 to i64
  %t1799 = add i64 %t1792, %t1798
  %t1800 = getelementptr inbounds i8, i8* %t1705, i64 %t1799
  %t1801 = load i8, i8* %t1800
  %t1802 = zext i8 %t1801 to i32
  store i32 0, i32* %t1803
  br label %draw_text_col_cond_932
draw_text_col_cond_932:
  %t1804 = load i32, i32* %t1803
  %t1805 = icmp slt i32 %t1804, %t1755
  br i1 %t1805, label %draw_text_col_body_933, label %draw_text_col_end_934
draw_text_col_body_933:
  %t1806 = sub i32 %t1755, 1
  %t1807 = sub i32 %t1806, %t1804
  %t1808 = and i32 %t1807, 31
  %t1809 = lshr i32 %t1802, %t1808
  %t1810 = and i32 %t1809, 1
  %t1811 = icmp ne i32 %t1810, 0
  br i1 %t1811, label %draw_text_pixel_935, label %draw_text_after_pixel_936
draw_text_pixel_935:
  %t1812 = mul i32 %t1804, %t1753
  %t1813 = add i32 %t1793, %t1812
  %t1814 = mul i32 %t1796, %t1753
  %t1815 = add i32 %t1794, %t1814
  %t1817 = getelementptr inbounds [16 x i8], [16 x i8]* %t1816, i64 0, i64 0
  %t1818 = bitcast i8* %t1817 to i32*
  store i32 %t1813, i32* %t1818
  %t1819 = getelementptr inbounds i8, i8* %t1817, i64 4
  %t1820 = bitcast i8* %t1819 to i32*
  store i32 %t1815, i32* %t1820
  %t1821 = getelementptr inbounds i8, i8* %t1817, i64 8
  %t1822 = bitcast i8* %t1821 to i32*
  store i32 %t1753, i32* %t1822
  %t1823 = getelementptr inbounds i8, i8* %t1817, i64 12
  %t1824 = bitcast i8* %t1823 to i32*
  store i32 %t1753, i32* %t1824
  call i32 @SDL_RenderFillRect(i8* %t1708, i8* %t1817)
  br label %draw_text_after_pixel_936
draw_text_after_pixel_936:
  %t1825 = add i32 %t1804, 1
  store i32 %t1825, i32* %t1803
  br label %draw_text_col_cond_932
draw_text_col_end_934:
  %t1826 = add i32 %t1796, 1
  store i32 %t1826, i32* %t1795
  br label %draw_text_row_cond_929
draw_text_row_end_931:
  br label %draw_text_advance_927
draw_text_advance_927:
  %t1827 = load i32, i32* %t1769
  %t1828 = add i32 %t1827, %t1766
  store i32 %t1828, i32* %t1769
  %t1829 = add i64 %t1772, 1
  store i64 %t1829, i64* %t1771
  br label %draw_text_cond_922
draw_text_end_928:
  call void @star_rc_release(i8* %t1730)
  %t1830 = load i8*, i8** %t1459
  call void @star_rc_release(i8* %t1830)
  %t1831 = load i8*, i8** %t1457
  call void @star_rc_release(i8* %t1831)
  br label %if_end_876
if_else_875:
  br label %if_end_876
if_end_876:
  %t1832 = load i64, i64* %t78
  %t1833 = zext i32 1 to i64
  %t1834 = shl i64 1, %t1833
  %t1835 = and i64 %t1832, %t1834
  %t1836 = icmp ne i64 %t1835, 0
  br i1 %t1836, label %if_then_937, label %if_else_938
if_then_937:
  %t1837 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t1838 = load i32, i32* %t1837
  %t1839 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t1840 = load i32, i32* %t1839
  %t1841 = call i32 @sb__Snake__length(%sb__Snake* %t71)
  %t1842 = load i64, i64* %t78
  %t1843 = zext i32 0 to i64
  %t1844 = shl i64 1, %t1843
  %t1845 = and i64 %t1842, %t1844
  %t1846 = icmp ne i64 %t1845, 0
  %t1847 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.98, i64 0, i64 0
  %t1848 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.99, i64 0, i64 0
  %t1849 = select i1 %t1846, i8* %t1847, i8* %t1848
  %t1850 = getelementptr inbounds %sb__Snake, %sb__Snake* %t71, i32 0, i32 1
  %t1851 = load i32, i32* %t1850
  %t1852 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.100, i64 0, i64 0
  %t1853 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.101, i64 0, i64 0
  %t1854 = icmp eq i32 %t1851, 2
  %t1855 = select i1 %t1854, i8* %t1853, i8* %t1852
  %t1856 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.102, i64 0, i64 0
  %t1857 = icmp eq i32 %t1851, 1
  %t1858 = select i1 %t1857, i8* %t1856, i8* %t1855
  %t1859 = getelementptr inbounds [3 x i8], [3 x i8]* @.str.103, i64 0, i64 0
  %t1860 = icmp eq i32 %t1851, 0
  %t1861 = select i1 %t1860, i8* %t1859, i8* %t1858
  %t1862 = load i1, i1* %t97
  %t1863 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.104, i64 0, i64 0
  %t1864 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.105, i64 0, i64 0
  %t1865 = select i1 %t1862, i8* %t1863, i8* %t1864
  %t1866 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 0
  %t1867 = load i32, i32* %t1866
  %t1868 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 1
  %t1869 = load float, float* %t1868
  %t1870 = getelementptr inbounds %Tuning, %Tuning* %t44, i32 0, i32 3
  %t1871 = load i1, i1* %t1870
  %t1872 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.106, i64 0, i64 0
  %t1873 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.107, i64 0, i64 0
  %t1874 = select i1 %t1871, i8* %t1872, i8* %t1873
  %t1875 = getelementptr inbounds [95 x i8], [95 x i8]* @.str.108, i64 0, i64 0
  %t1876 = fpext float %t1869 to double
  call i32 (i8*, ...) @printf(i8* %t1875, i32 %t1838, i32 %t1840, i32 %t1841, i8* %t1849, i8* %t1861, i8* %t1865, i32 %t1867, double %t1876, i8* %t1874)
  br label %if_end_939
if_else_938:
  br label %if_end_939
if_end_939:
  %t1877 = load i8*, i8** %t6
  %t1878 = icmp eq i8* %t1877, null
  br i1 %t1878, label %sdl_null_window_940, label %sdl_window_handle_ok_941
sdl_null_window_940:
  %t1879 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.109, i64 0, i64 0
  call i32 @puts(i8* %t1879)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_941:
  %t1880 = call i8* @SDL_GetRenderer(i8* %t1877)
  call void @SDL_RenderPresent(i8* %t1880)
  %t1881 = icmp slt i32 16, 0
  %t1882 = select i1 %t1881, i32 0, i32 16
  call void @SDL_Delay(i32 %t1882)
  br label %while_cond_521
while_else_523:
  br label %while_end_524
while_end_524:
  %t1883 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t1884 = load i32, i32* %t1883
  %t1885 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t1886 = load i32, i32* %t1885
  %t1887 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.110, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1887, i32 %t1884, i32 %t1886)
  %t1888 = load i8, i8* %t79
  %t1889 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.111, i64 0, i64 0
  %t1890 = zext i8 %t1888 to i32
  call i32 (i8*, ...) @printf(i8* %t1889, i32 %t1890)
  %t1891 = load i8*, i8** %t6
  %t1892 = icmp eq i8* %t1891, null
  br i1 %t1892, label %sdl_null_window_942, label %sdl_window_handle_ok_943
sdl_null_window_942:
  %t1893 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.112, i64 0, i64 0
  call i32 @puts(i8* %t1893)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_943:
  %t1894 = call i8* @SDL_GetRenderer(i8* %t1891)
  call void @SDL_DestroyRenderer(i8* %t1894)
  call void @SDL_DestroyWindow(i8* %t1891)
  store i8* null, i8** %t6
  %t1895 = load i8*, i8** %t80
  call void @star_rc_release(i8* %t1895)
  %t1896 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t27, i32 0, i32 1
  %t1897 = load i8*, i8** %t1896
  call void @star_rc_release(i8* %t1897)
  %t1898 = load i8*, i8** %t25
  call void @star_rc_release(i8* %t1898)
  ret i32 0
}


; par/swarm worker functions
define i1 @eq_s_grid__Cell(%grid__Cell %a, %grid__Cell %b) {
entry:
  %t33 = extractvalue %grid__Cell %a, 0
  %t34 = extractvalue %grid__Cell %b, 0
  %t35 = icmp eq i32 %t33, %t34
  %t36 = extractvalue %grid__Cell %a, 1
  %t37 = extractvalue %grid__Cell %b, 1
  %t38 = icmp eq i32 %t36, %t37
  %t39 = and i1 %t35, %t38
  ret i1 %t39
}


define i1 @eq_e_grid__Direction(i32 %a, i32 %b) {
entry:
  %t8 = icmp eq i32 %a, %b
  ret i1 %t8
}


define void @set_release_s_grid__Cell(i8* %objp) {
entry:
  %t11 = bitcast i8* %objp to { %grid__Cell*, i64, i64 }*
  %t12 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t11, i32 0, i32 0
  %t13 = load %grid__Cell*, %grid__Cell** %t12
  %t14 = bitcast %grid__Cell* %t13 to i8*
  call void @free(i8* %t14)
  ret void
}


define void @list_release_s_grid__Cell(i8* %objp) {
entry:
  %t43 = bitcast i8* %objp to { %grid__Cell*, i64, i64 }*
  %t44 = getelementptr inbounds { %grid__Cell*, i64, i64 }, { %grid__Cell*, i64, i64 }* %t43, i32 0, i32 0
  %t45 = load %grid__Cell*, %grid__Cell** %t44
  %t46 = bitcast %grid__Cell* %t45 to i8*
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


define i32 @par_worker_222(i8* %argp) {
entry:
  %t12 = alloca i64
  %t2 = bitcast i8* %argp to { i64, i64, float*, float* }*
  %t3 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t2, i32 0, i32 0
  %t4 = load i64, i64* %t3
  %t5 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t2, i32 0, i32 1
  %t6 = load i64, i64* %t5
  %t7 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t2, i32 0, i32 2
  %t8 = load float*, float** %t7
  %t9 = getelementptr inbounds { i64, i64, float*, float* }, { i64, i64, float*, float* }* %t2, i32 0, i32 3
  %t10 = load float*, float** %t9
  %t11 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t4, i64* %t12
  br label %par_cond_223
par_cond_223:
  %t13 = load i64, i64* %t12
  %t14 = icmp slt i64 %t13, %t6
  br i1 %t14, label %par_body_224, label %par_end_227
par_body_224:
  %t15 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t13
  %t16 = load i64, i64* %t15
  %t17 = and i64 %t16, 1
  %t18 = icmp eq i64 %t17, 1
  br i1 %t18, label %par_live_225, label %par_incr_226
par_live_225:
  %t19 = getelementptr inbounds %Particle, %Particle* %t11, i64 %t13
  %t20 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 4
  %t21 = load float, float* %t20
  %t22 = fcmp ogt float %t21, 0x0000000000000000
  br i1 %t22, label %if_then_228, label %if_else_229
if_then_228:
  %t23 = load float, float* %t8
  %t24 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 4
  %t25 = load float, float* %t24
  %t26 = fsub float %t25, %t23
  %t27 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 4
  store float %t26, float* %t27
  %t28 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 2
  %t29 = load float, float* %t28
  %t30 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 0
  %t31 = load float, float* %t30
  %t32 = fadd float %t31, %t29
  %t33 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 0
  store float %t32, float* %t33
  %t34 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 3
  %t35 = load float, float* %t34
  %t36 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 1
  %t37 = load float, float* %t36
  %t38 = fadd float %t37, %t35
  %t39 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 1
  store float %t38, float* %t39
  %t40 = load float, float* %t10
  %t41 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 3
  %t42 = load float, float* %t41
  %t43 = fadd float %t42, %t40
  %t44 = getelementptr inbounds %Particle, %Particle* %t19, i32 0, i32 3
  store float %t43, float* %t44
  br label %if_end_230
if_else_229:
  br label %if_end_230
if_end_230:
  br label %par_incr_226
par_incr_226:
  %t45 = add i64 %t13, 1
  store i64 %t45, i64* %t12
  br label %par_cond_223
par_end_227:
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
  %t46 = ptrtoint i8* %idx_arg to i64
  %t47 = trunc i64 %t46 to i32
  %t48 = call i32 @GetCurrentThreadId()
  %t49 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t47
  store i32 %t48, i32* %t49
  br label %loop
loop:
  %t50 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t47
  %t51 = load i8*, i8** %t50
  %t52 = call i32 @WaitForSingleObject(i8* %t51, i32 -1)
  %t53 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t47
  %t54 = load i32 (i8*)*, i32 (i8*)** %t53
  %t55 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t47
  %t56 = load i8*, i8** %t55
  %t57 = call i32 %t54(i8* %t56)
  %t58 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t47
  %t59 = load i8*, i8** %t58
  %t60 = call i32 @ReleaseSemaphore(i8* %t59, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t61 = load i1, i1* @par.pool.inited
  br i1 %t61, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t62 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t62, i8** @par.pool.serial_lock
  %t63 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t64 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t63, i8** %t64
  %t65 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t66 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t65, i8** %t66
  %t67 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t68 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t69 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t68, i8** %t69
  %t70 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t71 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t70, i8** %t71
  %t72 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t73 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t74 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t73, i8** %t74
  %t75 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t76 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t75, i8** %t76
  %t77 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t78 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t79 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t78, i8** %t79
  %t80 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t81 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t80, i8** %t81
  %t82 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
  store i1 true, i1* @par.pool.inited
  br label %par_pool_already
par_pool_already:
  ret void
}


define i32 @par_worker_258(i8* %argp) {
entry:
  %t8 = alloca i64
  %t2 = bitcast i8* %argp to { i64, i64 }*
  %t3 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 0
  %t4 = load i64, i64* %t3
  %t5 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %t2, i32 0, i32 1
  %t6 = load i64, i64* %t5
  %t7 = load %Particle*, %Particle** @arena.Particles.data
  store i64 %t4, i64* %t8
  br label %par_cond_259
par_cond_259:
  %t9 = load i64, i64* %t8
  %t10 = icmp slt i64 %t9, %t6
  br i1 %t10, label %par_body_260, label %par_end_263
par_body_260:
  %t11 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t9
  %t12 = load i64, i64* %t11
  %t13 = and i64 %t12, 1
  %t14 = icmp eq i64 %t13, 1
  br i1 %t14, label %par_live_261, label %par_incr_262
par_live_261:
  %t15 = getelementptr inbounds %Particle, %Particle* %t7, i64 %t9
  %t16 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 4
  %t17 = load float, float* %t16
  %t18 = fcmp ogt float %t17, 0x0000000000000000
  br i1 %t18, label %if_then_264, label %if_else_265
if_then_264:
  %t19 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 0
  %t20 = load float, float* %t19
  %t21 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 1
  %t22 = load float, float* %t21
  %t23 = getelementptr inbounds %Particle, %Particle* %t15, i32 0, i32 4
  %t24 = load float, float* %t23
  %t25 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.15, i64 0, i64 0
  %t26 = fpext float %t20 to double
  %t27 = fpext float %t22 to double
  %t28 = fpext float %t24 to double
  call i32 (i8*, ...) @printf(i8* %t25, double %t26, double %t27, double %t28)
  br label %if_end_266
if_else_265:
  br label %if_end_266
if_end_266:
  br label %par_incr_262
par_incr_262:
  %t29 = add i64 %t9, 1
  store i64 %t29, i64* %t8
  br label %par_cond_259
par_end_263:
  ret i32 0
}


define i1 @__star_reflect_has_field_Tuning(i8* %name) {
entry:
  %t336 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.24, i64 0, i64 0
  %t337 = call i32 @strcmp(i8* %name, i8* %t336)
  %t338 = icmp eq i32 %t337, 0
  br i1 %t338, label %reflect_hit_410, label %reflect_next_411
reflect_hit_410:
  ret i1 1
reflect_next_411:
  %t339 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.25, i64 0, i64 0
  %t340 = call i32 @strcmp(i8* %name, i8* %t339)
  %t341 = icmp eq i32 %t340, 0
  br i1 %t341, label %reflect_hit_412, label %reflect_next_413
reflect_hit_412:
  ret i1 1
reflect_next_413:
  %t342 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.26, i64 0, i64 0
  %t343 = call i32 @strcmp(i8* %name, i8* %t342)
  %t344 = icmp eq i32 %t343, 0
  br i1 %t344, label %reflect_hit_414, label %reflect_next_415
reflect_hit_414:
  ret i1 1
reflect_next_415:
  %t345 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.27, i64 0, i64 0
  %t346 = call i32 @strcmp(i8* %name, i8* %t345)
  %t347 = icmp eq i32 %t346, 0
  br i1 %t347, label %reflect_hit_416, label %reflect_next_417
reflect_hit_416:
  ret i1 1
reflect_next_417:
  ret i1 0
}


define void @__star_reflect_set_i32_Tuning(%Tuning* %s, i8* %name, i32 %val) {
entry:
  %t368 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.24, i64 0, i64 0
  %t369 = call i32 @strcmp(i8* %name, i8* %t368)
  %t370 = icmp eq i32 %t369, 0
  br i1 %t370, label %reflect_hit_424, label %reflect_next_425
reflect_hit_424:
  %t371 = getelementptr inbounds %Tuning, %Tuning* %s, i32 0, i32 0
  store i32 %val, i32* %t371
  ret void
reflect_next_425:
  ret void
}


define void @__star_reflect_set_bool_Tuning(%Tuning* %s, i8* %name, i1 %val) {
entry:
  %t388 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.27, i64 0, i64 0
  %t389 = call i32 @strcmp(i8* %name, i8* %t388)
  %t390 = icmp eq i32 %t389, 0
  br i1 %t390, label %reflect_hit_429, label %reflect_next_430
reflect_hit_429:
  %t391 = getelementptr inbounds %Tuning, %Tuning* %s, i32 0, i32 3
  store i1 %val, i1* %t391
  ret void
reflect_next_430:
  ret void
}


define void @__star_reflect_set_f32_Tuning(%Tuning* %s, i8* %name, float %val) {
entry:
  %t405 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.25, i64 0, i64 0
  %t406 = call i32 @strcmp(i8* %name, i8* %t405)
  %t407 = icmp eq i32 %t406, 0
  br i1 %t407, label %reflect_hit_431, label %reflect_next_432
reflect_hit_431:
  %t408 = getelementptr inbounds %Tuning, %Tuning* %s, i32 0, i32 1
  store float %val, float* %t408
  ret void
reflect_next_432:
  %t409 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.26, i64 0, i64 0
  %t410 = call i32 @strcmp(i8* %name, i8* %t409)
  %t411 = icmp eq i32 %t410, 0
  br i1 %t411, label %reflect_hit_433, label %reflect_next_434
reflect_hit_433:
  %t412 = getelementptr inbounds %Tuning, %Tuning* %s, i32 0, i32 2
  store float %val, float* %t412
  ret void
reflect_next_434:
  ret void
}


define void @list_release_symbol(i8* %objp) {
entry:
  %t355 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t356 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t355, i32 0, i32 0
  %t357 = load i64*, i64** %t356
  %t358 = bitcast i64* %t357 to i8*
  call void @free(i8* %t358)
  ret void
}



; Global Constants
@__star_reflect_Stats = private unnamed_addr constant [44 x i8] c"score:0:i32:export;high_score:4:i32:export;\00"
@__star_reflect_Tuning = private unnamed_addr constant [137 x i8] c"move_interval_ms:0:i32:tweakable;particle_gravity:4:float:tweakable;particle_life:8:float:tweakable;particles_enabled:12:bool:tweakable;\00"
@.str.0 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"w\00" }
@.str.1 = private unnamed_addr constant [74 x i8] c"star runtime error: file_write(..) called with a null/closed file handle\0A\00"
@.str.2 = private unnamed_addr constant [7 x i8] c"%d,%s\0A\00"
@.str.3 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.4 = private unnamed_addr constant [2 x i8] c"r\00"
@.str.5 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.6 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"r\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.8 = private unnamed_addr constant [78 x i8] c"star runtime error: file_read_line(..) called with a null/closed file handle\0A\00"
@.str.9 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c",\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.12 = private unnamed_addr constant [76 x i8] c"star runtime error: draw_pixel(..) called with a null/closed window handle\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [35 x i8] } { i64 -1, i8* null, [35 x i8] c"[arena] live particles (life > 0):\00" }
@.str.14 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.15 = private unnamed_addr constant [21 x i8] c"  x=%f y=%f life=%f\0A\00"
@.str.16 = private unnamed_addr constant [141 x i8] c"star runtime warning: arena `Particles` is full (256 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.17 = private unnamed_addr constant [2 x i8] c"r\00"
@.str.18 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"r\00" }
@.str.19 = private unnamed_addr constant [78 x i8] c"star runtime error: file_read_line(..) called with a null/closed file handle\0A\00"
@.str.20 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.21 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.22 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"#\00" }
@.str.23 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"=\00" }
@.str.24 = private unnamed_addr constant [17 x i8] c"move_interval_ms\00"
@.str.25 = private unnamed_addr constant [17 x i8] c"particle_gravity\00"
@.str.26 = private unnamed_addr constant [14 x i8] c"particle_life\00"
@.str.27 = private unnamed_addr constant [18 x i8] c"particles_enabled\00"
@.str.28 = private unnamed_addr constant [42 x i8] c"[tweaks] ignoring unknown key \22%s\22 in %s\0A\00"
@.str.29 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"move_interval_ms\00" }
@.str.30 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"particles_enabled\00" }
@.str.31 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"true\00" }
@.str.32 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.33 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.34 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.35 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.36 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.37 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.38 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.39 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Scratch` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.40 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Scratch` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.41 = private unnamed_addr constant [73 x i8] c"[genref demo] stale ref reads tag=%d (expect 0 -- despawned generation)\0A\00"
@.str.42 = private unnamed_addr constant [51 x i8] c"[genref demo] fresh ref reads tag=%d (expect 222)\0A\00"
@.str.43 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.44 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.45 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.46 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"Star Snake\00" }
@.str.47 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"window_create failed\00" }
@.str.48 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.49 = private unnamed_addr constant [37 x i8] c"[frame demo] node1.x + node2.y = %d\0A\00"
@.str.50 = private unnamed_addr constant [417 x i8] c"\05\07\20\3B\00\00\00\00\00\00\00\04\04\04\04\04\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\04\04\00\00\00\00\00\02\04\08\08\08\04\02\08\04\02\02\02\04\08\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\04\08\00\00\00\1F\00\00\00\00\00\00\00\00\04\04\01\02\04\04\08\10\10\0E\11\13\15\19\11\0E\04\0C\04\04\04\04\0E\0E\11\01\02\04\08\1F\0E\11\01\06\01\11\0E\02\06\0A\12\1F\02\02\1F\10\1E\01\01\11\0E\06\08\10\1E\11\11\0E\1F\01\02\04\08\08\08\0E\11\11\0E\11\11\0E\0E\11\11\0F\01\02\0C\00\04\00\00\04\00\00\00\04\00\00\04\08\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0E\11\01\02\04\00\04\00\00\00\00\00\00\00\04\0A\11\11\1F\11\11\1E\11\11\1E\11\11\1E\0E\11\10\10\10\11\0E\1C\12\11\11\11\12\1C\1F\10\10\1E\10\10\1F\1F\10\10\1E\10\10\10\0E\11\10\17\11\11\0E\11\11\11\1F\11\11\11\0E\04\04\04\04\04\0E\07\02\02\02\02\12\0C\11\12\14\18\14\12\11\10\10\10\10\10\10\1F\11\1B\15\11\11\11\11\11\19\15\13\11\11\11\0E\11\11\11\11\11\0E\1E\11\11\1E\10\10\10\0E\11\11\11\15\12\0D\1E\11\11\1E\14\12\11\0F\10\10\0E\01\01\1E\1F\04\04\04\04\04\04\11\11\11\11\11\11\0E\11\11\11\11\11\0A\04\11\11\11\15\15\1B\11\11\11\0A\04\0A\11\11\11\11\0A\04\04\04\04\1F\01\02\04\08\10\1F"
@.str.51 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"snake_save.txt\00" }
@.str.52 = private unnamed_addr constant [50 x i8] c"[save] loaded high score %d, difficulty tag \22%s\22\0A\00"
@.str.53 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"tweaks.txt\00" }
@.str.54 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.55 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.56 = private unnamed_addr constant [88 x i8] c"[tweaks] move_interval_ms=%d particle_gravity=%f particle_life=%f particles_enabled=%s\0A\00"
@.str.57 = private unnamed_addr constant [85 x i8] c"star runtime error: window_should_close(..) called with a null/closed window handle\0A\00"
@.str.58 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.59 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"move\00" }
@.str.60 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"eat\00" }
@.str.61 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.62 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.63 = private unnamed_addr constant [58 x i8] c"[spawn handle] particle just spawned at slot %d, life=%f\0A\00"
@.str.64 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.65 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.66 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.67 = private unnamed_addr constant [54 x i8] c"[achievement] unlocked milestone %d -- badges now %u\0A\00"
@.str.68 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"die\00" }
@.str.69 = private unnamed_addr constant [26 x i8] c"[events] final event: %s\0A\00"
@.str.70 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.71 = private unnamed_addr constant [34 x i8] c"[leaderboard] %d, %d, %d, %d, %d\0A\00"
@.str.72 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.73 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.74 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.75 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.76 = private unnamed_addr constant [10 x i8] c"SCORE: %d\00"
@.str.77 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.78 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.79 = private unnamed_addr constant [9 x i8] c"HIGH: %d\00"
@.str.80 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"PAUSED\00" }
@.str.81 = private unnamed_addr constant [76 x i8] c"star runtime error: measure_text(..) called with a null/closed font handle\0A\00"
@.str.82 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.83 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.84 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.85 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.86 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"GAME OVER\00" }
@.str.87 = private unnamed_addr constant { i64, i8*, [19 x i8] } { i64 -1, i8* null, [19 x i8] c"PRESS R TO RESTART\00" }
@.str.88 = private unnamed_addr constant [76 x i8] c"star runtime error: measure_text(..) called with a null/closed font handle\0A\00"
@.str.89 = private unnamed_addr constant [76 x i8] c"star runtime error: measure_text(..) called with a null/closed font handle\0A\00"
@.str.90 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.91 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.92 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.93 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.94 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.95 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.96 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.97 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.98 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.99 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.100 = private unnamed_addr constant [6 x i8] c"Right\00"
@.str.101 = private unnamed_addr constant [5 x i8] c"Left\00"
@.str.102 = private unnamed_addr constant [5 x i8] c"Down\00"
@.str.103 = private unnamed_addr constant [3 x i8] c"Up\00"
@.str.104 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.105 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.106 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.107 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.108 = private unnamed_addr constant [95 x i8] c"[debug] score=%d high=%d len=%d paused=%s dir=%s boost=%s interval=%d gravity=%f particles=%s\0A\00"
@.str.109 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.110 = private unnamed_addr constant [38 x i8] c"[stats] final score=%d high_score=%d\0A\00"
@.str.111 = private unnamed_addr constant [34 x i8] c"[stats] achievements bitfield=%u\0A\00"
@.str.112 = private unnamed_addr constant [80 x i8] c"star runtime error: window_destroy(..) called with a null/closed window handle\0A\00"
