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

define void @tick_particle_arena(float %dt) {
entry:
  %t0 = alloca float
  %t102 = alloca { i64, i64, float* }
  %t116 = alloca { i64, i64, float* }
  %t130 = alloca { i64, i64, float* }
  %t144 = alloca { i64, i64, float* }
  %t171 = alloca { i64, i64, float* }
  store float %dt, float* %t0
  call void @par.pool.ensure_init()
  %t79 = call i32 @GetCurrentThreadId()
  %t80 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 0
  %t81 = load i32, i32* %t80
  %t82 = icmp eq i32 %t79, %t81
  %t83 = select i1 %t82, i32 0, i32 -1
  %t84 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 1
  %t85 = load i32, i32* %t84
  %t86 = icmp eq i32 %t79, %t85
  %t87 = select i1 %t86, i32 1, i32 %t83
  %t88 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 2
  %t89 = load i32, i32* %t88
  %t90 = icmp eq i32 %t79, %t89
  %t91 = select i1 %t90, i32 2, i32 %t87
  %t92 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 3
  %t93 = load i32, i32* %t92
  %t94 = icmp eq i32 %t79, %t93
  %t95 = select i1 %t94, i32 3, i32 %t91
  %t96 = icmp sge i32 %t95, 0
  br i1 %t96, label %par_serial_232, label %par_pooled_231
par_pooled_231:
  %t97 = load i64, i64* @arena.Particles.count
  %t98 = mul i64 %t97, 0
  %t99 = sdiv i64 %t98, 4
  %t100 = mul i64 %t97, 1
  %t101 = sdiv i64 %t100, 4
  %t103 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t102, i32 0, i32 0
  store i64 %t99, i64* %t103
  %t104 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t102, i32 0, i32 1
  store i64 %t101, i64* %t104
  %t105 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t102, i32 0, i32 2
  store float* %t0, float** %t105
  %t106 = bitcast { i64, i64, float* }* %t102 to i8*
  %t107 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 0
  store i8* %t106, i8** %t107
  %t108 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 0
  store i32 (i8*)* @par_worker_222, i32 (i8*)** %t108
  %t109 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  %t110 = load i8*, i8** %t109
  %t111 = call i32 @ReleaseSemaphore(i8* %t110, i32 1, i32* null)
  %t112 = mul i64 %t97, 1
  %t113 = sdiv i64 %t112, 4
  %t114 = mul i64 %t97, 2
  %t115 = sdiv i64 %t114, 4
  %t117 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t116, i32 0, i32 0
  store i64 %t113, i64* %t117
  %t118 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t116, i32 0, i32 1
  store i64 %t115, i64* %t118
  %t119 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t116, i32 0, i32 2
  store float* %t0, float** %t119
  %t120 = bitcast { i64, i64, float* }* %t116 to i8*
  %t121 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 1
  store i8* %t120, i8** %t121
  %t122 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 1
  store i32 (i8*)* @par_worker_222, i32 (i8*)** %t122
  %t123 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  %t124 = load i8*, i8** %t123
  %t125 = call i32 @ReleaseSemaphore(i8* %t124, i32 1, i32* null)
  %t126 = mul i64 %t97, 2
  %t127 = sdiv i64 %t126, 4
  %t128 = mul i64 %t97, 3
  %t129 = sdiv i64 %t128, 4
  %t131 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t130, i32 0, i32 0
  store i64 %t127, i64* %t131
  %t132 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t130, i32 0, i32 1
  store i64 %t129, i64* %t132
  %t133 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t130, i32 0, i32 2
  store float* %t0, float** %t133
  %t134 = bitcast { i64, i64, float* }* %t130 to i8*
  %t135 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 2
  store i8* %t134, i8** %t135
  %t136 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 2
  store i32 (i8*)* @par_worker_222, i32 (i8*)** %t136
  %t137 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  %t138 = load i8*, i8** %t137
  %t139 = call i32 @ReleaseSemaphore(i8* %t138, i32 1, i32* null)
  %t140 = mul i64 %t97, 3
  %t141 = sdiv i64 %t140, 4
  %t142 = mul i64 %t97, 4
  %t143 = sdiv i64 %t142, 4
  %t145 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t144, i32 0, i32 0
  store i64 %t141, i64* %t145
  %t146 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t144, i32 0, i32 1
  store i64 %t143, i64* %t146
  %t147 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t144, i32 0, i32 2
  store float* %t0, float** %t147
  %t148 = bitcast { i64, i64, float* }* %t144 to i8*
  %t149 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 3
  store i8* %t148, i8** %t149
  %t150 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 3
  store i32 (i8*)* @par_worker_222, i32 (i8*)** %t150
  %t151 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  %t152 = load i8*, i8** %t151
  %t153 = call i32 @ReleaseSemaphore(i8* %t152, i32 1, i32* null)
  %t154 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  %t155 = load i8*, i8** %t154
  %t156 = call i32 @WaitForSingleObject(i8* %t155, i32 -1)
  %t157 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  %t158 = load i8*, i8** %t157
  %t159 = call i32 @WaitForSingleObject(i8* %t158, i32 -1)
  %t160 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  %t161 = load i8*, i8** %t160
  %t162 = call i32 @WaitForSingleObject(i8* %t161, i32 -1)
  %t163 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  %t164 = load i8*, i8** %t163
  %t165 = call i32 @WaitForSingleObject(i8* %t164, i32 -1)
  br label %par_join_236
par_serial_232:
  %t166 = load i32, i32* @par.pool.serial_owner
  %t167 = icmp eq i32 %t166, %t95
  br i1 %t167, label %par_run_234, label %par_acquire_233
par_acquire_233:
  %t168 = load i8*, i8** @par.pool.serial_lock
  %t169 = call i32 @WaitForSingleObject(i8* %t168, i32 -1)
  store i32 %t95, i32* @par.pool.serial_owner
  br label %par_run_234
par_run_234:
  %t170 = load i64, i64* @arena.Particles.count
  %t172 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t171, i32 0, i32 0
  store i64 0, i64* %t172
  %t173 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t171, i32 0, i32 1
  store i64 %t170, i64* %t173
  %t174 = getelementptr inbounds { i64, i64, float* }, { i64, i64, float* }* %t171, i32 0, i32 2
  store float* %t0, float** %t174
  %t175 = bitcast { i64, i64, float* }* %t171 to i8*
  %t176 = call i32 @par_worker_222(i8* %t175)
  br i1 %t167, label %par_join_236, label %par_release_235
par_release_235:
  store i32 -1, i32* @par.pool.serial_owner
  %t177 = load i8*, i8** @par.pool.serial_lock
  %t178 = call i32 @ReleaseSemaphore(i8* %t177, i32 1, i32* null)
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

define i32 @spawn_particle_burst(float %cx, float %cy) {
entry:
  %t0 = alloca float
  %t1 = alloca float
  %t2 = alloca i32
  %t4 = alloca i32
  %t7 = alloca float
  %t20 = alloca float
  %t34 = alloca i32
  %t54 = alloca %Particle
  store float %cx, float* %t0
  store float %cy, float* %t1
  %t3 = sub i32 0, 1
  store i32 %t3, i32* %t2
  store i32 0, i32* %t4
  br label %while_cond_273
while_cond_273:
  %t5 = load i32, i32* %t4
  %t6 = icmp slt i32 %t5, 6
  br i1 %t6, label %while_body_274, label %while_else_275
while_body_274:
  %t8 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t8, i32 -1)
  %t9 = load i32, i32* @rng.state
  %t10 = shl i32 %t9, 13
  %t11 = xor i32 %t9, %t10
  %t12 = lshr i32 %t11, 17
  %t13 = xor i32 %t11, %t12
  %t14 = shl i32 %t13, 5
  %t15 = xor i32 %t13, %t14
  store i32 %t15, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t8, i32 1, i32* null)
  %t16 = and i32 %t15, 16777215
  %t17 = uitofp i32 %t16 to float
  %t18 = fdiv float %t17, 0x4170000000000000
  %t19 = fmul float %t18, 0x401921FB60000000
  store float %t19, float* %t7
  %t21 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t21, i32 -1)
  %t22 = load i32, i32* @rng.state
  %t23 = shl i32 %t22, 13
  %t24 = xor i32 %t22, %t23
  %t25 = lshr i32 %t24, 17
  %t26 = xor i32 %t24, %t25
  %t27 = shl i32 %t26, 5
  %t28 = xor i32 %t26, %t27
  store i32 %t28, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t21, i32 1, i32* null)
  %t29 = and i32 %t28, 16777215
  %t30 = uitofp i32 %t29 to float
  %t31 = fdiv float %t30, 0x4170000000000000
  %t32 = fmul float %t31, 0x4000000000000000
  %t33 = fadd float 0x3FF0000000000000, %t32
  store float %t33, float* %t20
  %t35 = load %Particle*, %Particle** @arena.Particles.data
  %t36 = icmp eq %Particle* %t35, null
  br i1 %t36, label %spawn_init_277, label %spawn_ready_278
spawn_init_277:
  %t37 = getelementptr %Particle, %Particle* null, i32 1
  %t38 = ptrtoint %Particle* %t37 to i64
  %t39 = mul i64 %t38, 256
  %t40 = call i8* @malloc(i64 %t39)
  %t41 = bitcast i8* %t40 to %Particle*
  store %Particle* %t41, %Particle** @arena.Particles.data
  br label %spawn_ready_278
spawn_ready_278:
  %t42 = load %Particle*, %Particle** @arena.Particles.data
  %t43 = load i64, i64* @arena.Particles.free_top
  %t44 = icmp sgt i64 %t43, 0
  br i1 %t44, label %spawn_reuse_279, label %spawn_grow_280
spawn_reuse_279:
  %t45 = sub i64 %t43, 1
  store i64 %t45, i64* @arena.Particles.free_top
  %t46 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.free, i64 0, i64 %t45
  %t47 = load i64, i64* %t46
  br label %spawn_store_281
spawn_grow_280:
  %t48 = load i64, i64* @arena.Particles.count
  %t49 = icmp slt i64 %t48, 256
  br i1 %t49, label %spawn_grow_ok_283, label %spawn_capacity_warn_284
spawn_capacity_warn_284:
  %t50 = load i1, i1* @arena.Particles.warned
  br i1 %t50, label %spawn_end_282, label %spawn_warn_print_285
spawn_warn_print_285:
  store i1 1, i1* @arena.Particles.warned
  %t51 = getelementptr inbounds [141 x i8], [141 x i8]* @.str.16, i64 0, i64 0
  call i32 @puts(i8* %t51)
  br label %spawn_end_282
spawn_grow_ok_283:
  %t52 = add i64 %t48, 1
  store i64 %t52, i64* @arena.Particles.count
  br label %spawn_store_281
spawn_store_281:
  %t53 = phi i64 [ %t47, %spawn_reuse_279 ], [ %t48, %spawn_grow_ok_283 ]
  %t55 = load float, float* %t0
  %t56 = getelementptr inbounds %Particle, %Particle* %t54, i32 0, i32 0
  store float %t55, float* %t56
  %t57 = load float, float* %t1
  %t58 = getelementptr inbounds %Particle, %Particle* %t54, i32 0, i32 1
  store float %t57, float* %t58
  %t59 = load float, float* %t7
  %t60 = call float @llvm.cos.f32(float %t59)
  %t61 = load float, float* %t20
  %t62 = fmul float %t60, %t61
  %t63 = getelementptr inbounds %Particle, %Particle* %t54, i32 0, i32 2
  store float %t62, float* %t63
  %t64 = load float, float* %t7
  %t65 = call float @llvm.sin.f32(float %t64)
  %t66 = load float, float* %t20
  %t67 = fmul float %t65, %t66
  %t68 = getelementptr inbounds %Particle, %Particle* %t54, i32 0, i32 3
  store float %t67, float* %t68
  %t69 = getelementptr inbounds %Particle, %Particle* %t54, i32 0, i32 4
  store float 0x3FDCCCCCC0000000, float* %t69
  %t70 = load %Particle, %Particle* %t54
  %t71 = getelementptr inbounds %Particle, %Particle* %t42, i64 %t53
  store %Particle %t70, %Particle* %t71
  %t72 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t53
  %t73 = load i64, i64* %t72
  %t74 = add i64 %t73, 1
  store i64 %t74, i64* %t72
  %t75 = trunc i64 %t53 to i32
  br label %spawn_end_282
spawn_end_282:
  %t76 = phi i32 [ %t75, %spawn_store_281 ], [ -1, %spawn_capacity_warn_284 ], [ -1, %spawn_warn_print_285 ]
  store i32 %t76, i32* %t34
  %t77 = load i32, i32* %t34
  store i32 %t77, i32* %t2
  %t78 = load i32, i32* %t4
  %t79 = add i32 %t78, 1
  store i32 %t79, i32* %t4
  br label %while_cond_273
while_else_275:
  br label %while_end_276
while_end_276:
  %t80 = load i32, i32* %t2
  ret i32 %t80
}

define i1 @FlashOnEat__resume(%FlashOnEat* %self) {
entry:
  %t0 = alloca %FlashOnEat*
  store %FlashOnEat* %self, %FlashOnEat** %t0
  %t1 = load %FlashOnEat*, %FlashOnEat** %t0
  %t2 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t1, i32 0, i32 1
  %t3 = load i32, i32* %t2
  %t4 = icmp eq i32 %t3, 0
  br i1 %t4, label %if_then_286, label %if_else_287
if_then_286:
  %t5 = load %FlashOnEat*, %FlashOnEat** %t0
  %t6 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %sdl_null_window_289, label %sdl_window_handle_ok_290
sdl_null_window_289:
  %t9 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.17, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_290:
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
  br i1 %t35, label %sdl_null_window_291, label %sdl_window_handle_ok_292
sdl_null_window_291:
  %t36 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.18, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_292:
  %t37 = call i8* @SDL_GetRenderer(i8* %t34)
  call void @SDL_RenderPresent(i8* %t37)
  %t38 = icmp slt i32 35, 0
  %t39 = select i1 %t38, i32 0, i32 35
  call void @SDL_Delay(i32 %t39)
  %t40 = load %FlashOnEat*, %FlashOnEat** %t0
  %t41 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t40, i32 0, i32 1
  store i32 1, i32* %t41
  ret i1 true
if_else_287:
  %t42 = load %FlashOnEat*, %FlashOnEat** %t0
  %t43 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t44, 1
  br i1 %t45, label %if_then_293, label %if_else_294
if_then_293:
  %t46 = load %FlashOnEat*, %FlashOnEat** %t0
  %t47 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t46, i32 0, i32 1
  store i32 2, i32* %t47
  ret i1 false
if_else_294:
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
  br i1 %t4, label %if_then_296, label %if_else_297
if_then_296:
  %t5 = load %GameOverFlash*, %GameOverFlash** %t0
  %t6 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %sdl_null_window_299, label %sdl_window_handle_ok_300
sdl_null_window_299:
  %t9 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.19, i64 0, i64 0
  call i32 @puts(i8* %t9)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_300:
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
  br i1 %t35, label %sdl_null_window_301, label %sdl_window_handle_ok_302
sdl_null_window_301:
  %t36 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.20, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_302:
  %t37 = call i8* @SDL_GetRenderer(i8* %t34)
  call void @SDL_RenderPresent(i8* %t37)
  %t38 = icmp slt i32 110, 0
  %t39 = select i1 %t38, i32 0, i32 110
  call void @SDL_Delay(i32 %t39)
  %t40 = load %GameOverFlash*, %GameOverFlash** %t0
  %t41 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t40, i32 0, i32 1
  store i32 1, i32* %t41
  ret i1 true
if_else_297:
  %t42 = load %GameOverFlash*, %GameOverFlash** %t0
  %t43 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t42, i32 0, i32 1
  %t44 = load i32, i32* %t43
  %t45 = icmp eq i32 %t44, 1
  br i1 %t45, label %if_then_303, label %if_else_304
if_then_303:
  %t46 = load %GameOverFlash*, %GameOverFlash** %t0
  %t47 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t46, i32 0, i32 0
  %t48 = load i8*, i8** %t47
  %t49 = icmp eq i8* %t48, null
  br i1 %t49, label %sdl_null_window_306, label %sdl_window_handle_ok_307
sdl_null_window_306:
  %t50 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.21, i64 0, i64 0
  call i32 @puts(i8* %t50)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_307:
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
  br i1 %t76, label %sdl_null_window_308, label %sdl_window_handle_ok_309
sdl_null_window_308:
  %t77 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.22, i64 0, i64 0
  call i32 @puts(i8* %t77)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_309:
  %t78 = call i8* @SDL_GetRenderer(i8* %t75)
  call void @SDL_RenderPresent(i8* %t78)
  %t79 = icmp slt i32 110, 0
  %t80 = select i1 %t79, i32 0, i32 110
  call void @SDL_Delay(i32 %t80)
  %t81 = load %GameOverFlash*, %GameOverFlash** %t0
  %t82 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t81, i32 0, i32 1
  store i32 2, i32* %t82
  ret i1 true
if_else_304:
  %t83 = load %GameOverFlash*, %GameOverFlash** %t0
  %t84 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t83, i32 0, i32 1
  %t85 = load i32, i32* %t84
  %t86 = icmp eq i32 %t85, 2
  br i1 %t86, label %if_then_310, label %if_else_311
if_then_310:
  %t87 = load %GameOverFlash*, %GameOverFlash** %t0
  %t88 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t87, i32 0, i32 1
  store i32 3, i32* %t88
  ret i1 false
if_else_311:
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
  br i1 %t1, label %spawn_init_313, label %spawn_ready_314
spawn_init_313:
  %t2 = getelementptr %ScratchSlot, %ScratchSlot* null, i32 1
  %t3 = ptrtoint %ScratchSlot* %t2 to i64
  %t4 = mul i64 %t3, 1024
  %t5 = call i8* @malloc(i64 %t4)
  %t6 = bitcast i8* %t5 to %ScratchSlot*
  store %ScratchSlot* %t6, %ScratchSlot** @arena.Scratch.data
  br label %spawn_ready_314
spawn_ready_314:
  %t7 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t8 = load i64, i64* @arena.Scratch.free_top
  %t9 = icmp sgt i64 %t8, 0
  br i1 %t9, label %spawn_reuse_315, label %spawn_grow_316
spawn_reuse_315:
  %t10 = sub i64 %t8, 1
  store i64 %t10, i64* @arena.Scratch.free_top
  %t11 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t10
  %t12 = load i64, i64* %t11
  br label %spawn_store_317
spawn_grow_316:
  %t13 = load i64, i64* @arena.Scratch.count
  %t14 = icmp slt i64 %t13, 1024
  br i1 %t14, label %spawn_grow_ok_319, label %spawn_capacity_warn_320
spawn_capacity_warn_320:
  %t15 = load i1, i1* @arena.Scratch.warned
  br i1 %t15, label %spawn_end_318, label %spawn_warn_print_321
spawn_warn_print_321:
  store i1 1, i1* @arena.Scratch.warned
  %t16 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.23, i64 0, i64 0
  call i32 @puts(i8* %t16)
  br label %spawn_end_318
spawn_grow_ok_319:
  %t17 = add i64 %t13, 1
  store i64 %t17, i64* @arena.Scratch.count
  br label %spawn_store_317
spawn_store_317:
  %t18 = phi i64 [ %t12, %spawn_reuse_315 ], [ %t13, %spawn_grow_ok_319 ]
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
  br label %spawn_end_318
spawn_end_318:
  %t27 = phi i32 [ %t26, %spawn_store_317 ], [ -1, %spawn_capacity_warn_320 ], [ -1, %spawn_warn_print_321 ]
  %t29 = sext i32 0 to i64
  %t30 = icmp ult i64 %t29, 1024
  br i1 %t30, label %genref_create_ok_322, label %genref_create_oob_323
genref_create_ok_322:
  %t31 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t29
  %t32 = load i64, i64* %t31
  br label %genref_create_end_324
genref_create_oob_323:
  br label %genref_create_end_324
genref_create_end_324:
  %t33 = phi i64 [ %t32, %genref_create_ok_322 ], [ 0, %genref_create_oob_323 ]
  %t35 = getelementptr inbounds %GenRef, %GenRef* %t34, i32 0, i32 0
  store i32 0, i32* %t35
  %t36 = getelementptr inbounds %GenRef, %GenRef* %t34, i32 0, i32 1
  store i64 %t33, i64* %t36
  %t37 = load %GenRef, %GenRef* %t34
  store %GenRef %t37, %GenRef* %t28
  %t38 = sext i32 0 to i64
  %t39 = icmp ult i64 %t38, 1024
  br i1 %t39, label %despawn_do_325, label %despawn_end_326
despawn_do_325:
  %t40 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t38
  %t41 = load i64, i64* %t40
  %t42 = and i64 %t41, 1
  %t43 = icmp eq i64 %t42, 1
  br i1 %t43, label %despawn_live_327, label %despawn_end_326
despawn_live_327:
  %t44 = add i64 %t41, 1
  store i64 %t44, i64* %t40
  %t45 = load i64, i64* @arena.Scratch.free_top
  %t46 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t45
  store i64 %t38, i64* %t46
  %t47 = add i64 %t45, 1
  store i64 %t47, i64* @arena.Scratch.free_top
  br label %despawn_end_326
despawn_end_326:
  %t48 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t49 = icmp eq %ScratchSlot* %t48, null
  br i1 %t49, label %spawn_init_328, label %spawn_ready_329
spawn_init_328:
  %t50 = getelementptr %ScratchSlot, %ScratchSlot* null, i32 1
  %t51 = ptrtoint %ScratchSlot* %t50 to i64
  %t52 = mul i64 %t51, 1024
  %t53 = call i8* @malloc(i64 %t52)
  %t54 = bitcast i8* %t53 to %ScratchSlot*
  store %ScratchSlot* %t54, %ScratchSlot** @arena.Scratch.data
  br label %spawn_ready_329
spawn_ready_329:
  %t55 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t56 = load i64, i64* @arena.Scratch.free_top
  %t57 = icmp sgt i64 %t56, 0
  br i1 %t57, label %spawn_reuse_330, label %spawn_grow_331
spawn_reuse_330:
  %t58 = sub i64 %t56, 1
  store i64 %t58, i64* @arena.Scratch.free_top
  %t59 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.free, i64 0, i64 %t58
  %t60 = load i64, i64* %t59
  br label %spawn_store_332
spawn_grow_331:
  %t61 = load i64, i64* @arena.Scratch.count
  %t62 = icmp slt i64 %t61, 1024
  br i1 %t62, label %spawn_grow_ok_334, label %spawn_capacity_warn_335
spawn_capacity_warn_335:
  %t63 = load i1, i1* @arena.Scratch.warned
  br i1 %t63, label %spawn_end_333, label %spawn_warn_print_336
spawn_warn_print_336:
  store i1 1, i1* @arena.Scratch.warned
  %t64 = getelementptr inbounds [140 x i8], [140 x i8]* @.str.24, i64 0, i64 0
  call i32 @puts(i8* %t64)
  br label %spawn_end_333
spawn_grow_ok_334:
  %t65 = add i64 %t61, 1
  store i64 %t65, i64* @arena.Scratch.count
  br label %spawn_store_332
spawn_store_332:
  %t66 = phi i64 [ %t60, %spawn_reuse_330 ], [ %t61, %spawn_grow_ok_334 ]
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
  br label %spawn_end_333
spawn_end_333:
  %t75 = phi i32 [ %t74, %spawn_store_332 ], [ -1, %spawn_capacity_warn_335 ], [ -1, %spawn_warn_print_336 ]
  %t77 = sext i32 0 to i64
  %t78 = icmp ult i64 %t77, 1024
  br i1 %t78, label %genref_create_ok_337, label %genref_create_oob_338
genref_create_ok_337:
  %t79 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t77
  %t80 = load i64, i64* %t79
  br label %genref_create_end_339
genref_create_oob_338:
  br label %genref_create_end_339
genref_create_end_339:
  %t81 = phi i64 [ %t80, %genref_create_ok_337 ], [ 0, %genref_create_oob_338 ]
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
  br i1 %t91, label %genref_place_check_340, label %genref_place_stale_342
genref_place_check_340:
  %t92 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t90
  %t93 = load i64, i64* %t92
  %t94 = icmp eq i64 %t89, %t93
  %t95 = and i64 %t93, 1
  %t96 = icmp eq i64 %t95, 1
  %t97 = and i1 %t94, %t96
  br i1 %t97, label %genref_place_ok_341, label %genref_place_stale_342
genref_place_ok_341:
  %t98 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t99 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t98, i64 %t90
  br label %genref_place_end_343
genref_place_stale_342:
  store %ScratchSlot zeroinitializer, %ScratchSlot* %t100
  br label %genref_place_end_343
genref_place_end_343:
  %t101 = phi %ScratchSlot* [ %t99, %genref_place_ok_341 ], [ %t100, %genref_place_stale_342 ]
  %t102 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t101, i32 0, i32 0
  %t103 = load i32, i32* %t102
  %t104 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t104, i32 %t103)
  %t105 = getelementptr inbounds %GenRef, %GenRef* %t76, i32 0, i32 0
  %t106 = load i32, i32* %t105
  %t107 = getelementptr inbounds %GenRef, %GenRef* %t76, i32 0, i32 1
  %t108 = load i64, i64* %t107
  %t109 = sext i32 %t106 to i64
  %t110 = icmp ult i64 %t109, 1024
  br i1 %t110, label %genref_place_check_344, label %genref_place_stale_346
genref_place_check_344:
  %t111 = getelementptr inbounds [1024 x i64], [1024 x i64]* @arena.Scratch.gen, i64 0, i64 %t109
  %t112 = load i64, i64* %t111
  %t113 = icmp eq i64 %t108, %t112
  %t114 = and i64 %t112, 1
  %t115 = icmp eq i64 %t114, 1
  %t116 = and i1 %t113, %t115
  br i1 %t116, label %genref_place_ok_345, label %genref_place_stale_346
genref_place_ok_345:
  %t117 = load %ScratchSlot*, %ScratchSlot** @arena.Scratch.data
  %t118 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t117, i64 %t109
  br label %genref_place_end_347
genref_place_stale_346:
  store %ScratchSlot zeroinitializer, %ScratchSlot* %t119
  br label %genref_place_end_347
genref_place_end_347:
  %t120 = phi %ScratchSlot* [ %t118, %genref_place_ok_345 ], [ %t119, %genref_place_stale_346 ]
  %t121 = getelementptr inbounds %ScratchSlot, %ScratchSlot* %t120, i32 0, i32 0
  %t122 = load i32, i32* %t121
  %t123 = getelementptr inbounds [51 x i8], [51 x i8]* @.str.26, i64 0, i64 0
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
  br i1 %t7, label %sdl_null_window_348, label %sdl_window_handle_ok_349
sdl_null_window_348:
  %t8 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.27, i64 0, i64 0
  call i32 @puts(i8* %t8)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_349:
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
  br i1 %t3, label %if_then_350, label %if_else_351
if_then_350:
  %t4 = load i32, i32* %t1
  br label %if_end_352
if_else_351:
  %t5 = load i32, i32* %t2
  br label %if_end_352
if_end_352:
  %t6 = phi i32 [ %t4, %if_then_350 ], [ %t5, %if_else_351 ]
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
  br i1 %t5, label %frame_alloc_fail_353, label %frame_alloc_ok_354
frame_alloc_fail_353:
  %t6 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.28, i64 0, i64 0
  call i32 @puts(i8* %t6)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_354:
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
  br i1 %t18, label %frame_alloc_fail_355, label %frame_alloc_ok_356
frame_alloc_fail_355:
  %t19 = getelementptr inbounds [70 x i8], [70 x i8]* @.str.29, i64 0, i64 0
  call i32 @puts(i8* %t19)
  call void @exit(i32 1)
  unreachable
frame_alloc_ok_356:
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
  %t49 = alloca %sb__Snake
  %t51 = alloca %grid__Cell
  %t56 = alloca i64
  %t57 = alloca i8
  %t58 = alloca i8*
  %t59 = alloca i8
  %t61 = alloca [5 x i32]
  %t62 = alloca [5 x i32]
  %t64 = alloca i64
  %t70 = alloca i32
  %t72 = alloca i1
  %t73 = alloca i1
  %t74 = alloca i1
  %t75 = alloca i1
  %t76 = alloca i32
  %t77 = alloca i32
  %t78 = alloca i32
  %t79 = alloca i32
  %t80 = alloca i32
  %t81 = alloca i32
  %t82 = alloca i32
  %t83 = alloca i32
  %t84 = alloca i32
  %t85 = alloca i32
  %t86 = alloca i32
  %t87 = alloca i32
  %t88 = alloca i32
  %t92 = alloca i1
  %t93 = alloca [56 x i8]
  %t111 = alloca i1
  %t141 = alloca i1
  %t174 = alloca i1
  %t295 = alloca i32
  %t309 = alloca i32
  %t324 = alloca i32
  %t327 = alloca %grid__Cell
  %t377 = alloca i64
  %t475 = alloca i64
  %t518 = alloca { i32, i32 }
  %t521 = alloca float
  %t533 = alloca float
  %t545 = alloca i32
  %t557 = alloca %GenRef
  %t564 = alloca %GenRef
  %t583 = alloca %Particle
  %t589 = alloca %FlashOnEat
  %t590 = alloca %FlashOnEat
  %t595 = alloca i1
  %t620 = alloca i32
  %t701 = alloca i64
  %t786 = alloca i32
  %t798 = alloca i32
  %t814 = alloca i32
  %t826 = alloca i32
  %t832 = alloca i32
  %t838 = alloca i32
  %t844 = alloca i32
  %t850 = alloca i32
  %t854 = alloca %GameOverFlash
  %t855 = alloca %GameOverFlash
  %t860 = alloca i1
  %t866 = alloca float
  %t869 = alloca float
  %t899 = alloca { i32, i32 }
  %t902 = alloca i32
  %t946 = alloca [16 x i8]
  %t955 = alloca i32
  %t959 = alloca i1
  %t979 = alloca %grid__Cell
  %t1059 = alloca i32
  %t1060 = alloca i32
  %t1061 = alloca i64
  %t1085 = alloca i32
  %t1093 = alloca i32
  %t1106 = alloca [16 x i8]
  %t1172 = alloca i32
  %t1173 = alloca i32
  %t1174 = alloca i64
  %t1198 = alloca i32
  %t1206 = alloca i32
  %t1219 = alloca [16 x i8]
  %t1238 = alloca i8*
  %t1240 = alloca { i32, i32 }
  %t1263 = alloca i32
  %t1264 = alloca i32
  %t1265 = alloca i32
  %t1266 = alloca i64
  %t1290 = alloca { i32, i32 }
  %t1363 = alloca i32
  %t1364 = alloca i32
  %t1365 = alloca i64
  %t1389 = alloca i32
  %t1397 = alloca i32
  %t1410 = alloca [16 x i8]
  %t1428 = alloca i8*
  %t1430 = alloca i8*
  %t1432 = alloca { i32, i32 }
  %t1455 = alloca i32
  %t1456 = alloca i32
  %t1457 = alloca i32
  %t1458 = alloca i64
  %t1482 = alloca { i32, i32 }
  %t1486 = alloca { i32, i32 }
  %t1509 = alloca i32
  %t1510 = alloca i32
  %t1511 = alloca i32
  %t1512 = alloca i64
  %t1536 = alloca { i32, i32 }
  %t1540 = alloca i32
  %t1612 = alloca i32
  %t1613 = alloca i32
  %t1614 = alloca i64
  %t1638 = alloca i32
  %t1646 = alloca i32
  %t1659 = alloca [16 x i8]
  %t1740 = alloca i32
  %t1741 = alloca i32
  %t1742 = alloca i64
  %t1766 = alloca i32
  %t1774 = alloca i32
  %t1787 = alloca [16 x i8]
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
  %t7 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.30, i64 0, i32 2, i64 0
  %t8 = load i32, i32* %t2
  %t9 = load i32, i32* %t4
  %t10 = call i32 @SDL_Init(i32 32)
  %t11 = icmp ne i32 %t10, 0
  br i1 %t11, label %sdl_init_fail_357, label %sdl_init_ok_358
sdl_init_fail_357:
  call void @star_rc_release(i8* %t7)
  br label %window_create_end_359
sdl_init_ok_358:
  %t12 = call i8* @SDL_CreateWindow(i8* %t7, i32 536805376, i32 536805376, i32 %t8, i32 %t9, i32 0)
  call void @star_rc_release(i8* %t7)
  %t13 = icmp eq i8* %t12, null
  br i1 %t13, label %sdl_window_fail_360, label %sdl_window_ok_361
sdl_window_fail_360:
  br label %window_create_end_359
sdl_window_ok_361:
  %t14 = call i8* @SDL_CreateRenderer(i8* %t12, i32 -1, i32 0)
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %sdl_renderer_fail_362, label %sdl_renderer_ok_363
sdl_renderer_fail_362:
  call void @SDL_DestroyWindow(i8* %t12)
  br label %window_create_end_359
sdl_renderer_ok_363:
  br label %window_create_end_359
window_create_end_359:
  %t16 = phi i8* [ null, %sdl_init_fail_357 ], [ null, %sdl_window_fail_360 ], [ null, %sdl_renderer_fail_362 ], [ %t12, %sdl_renderer_ok_363 ]
  store i8* %t16, i8** %t6
  %t17 = load i8*, i8** %t6
  %t18 = icmp eq i8* %t17, null
  br i1 %t18, label %if_then_364, label %if_else_365
if_then_364:
  %t19 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.31, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t19)
  call i32 (i8*, ...) @printf(i8* %t19)
  %t20 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.32, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t20)
  ret i32 0
if_else_365:
  br label %if_end_366
if_end_366:
  call void @demo_genref_staleness()
  %t21 = call i32 @frame_demo()
  %t22 = getelementptr inbounds [37 x i8], [37 x i8]* @.str.33, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t22, i32 %t21)
  %t24 = getelementptr inbounds [417 x i8], [417 x i8]* @.str.34, i64 0, i64 0
  store i8* %t24, i8** %t23
  %t26 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.35, i64 0, i32 2, i64 0
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
  %t37 = getelementptr inbounds %Stats, %Stats* %t32, i32 0, i32 2
  store i32 120, i32* %t37
  %t38 = load %Stats, %Stats* %t32
  store %Stats %t38, %Stats* %t31
  %t39 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t40 = load i32, i32* %t39
  %t41 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t27, i32 0, i32 1
  %t42 = load i8*, i8** %t41
  %t43 = load i8*, i8** %t41
  call void @star_rc_retain(i8* %t43)
  call void @star_rc_release(i8* %t42)
  %t44 = getelementptr inbounds [50 x i8], [50 x i8]* @.str.36, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t44, i32 %t40, i8* %t42)
  %t45 = call i32 @SDL_GetTicks()
  %t46 = icmp eq i32 %t45, 0
  %t47 = select i1 %t46, i32 1, i32 %t45
  %t48 = load i8*, i8** @rng.lock
  call i32 @WaitForSingleObject(i8* %t48, i32 -1)
  store i32 %t47, i32* @rng.state
  call i32 @ReleaseSemaphore(i8* %t48, i32 1, i32* null)
  %t50 = call %sb__Snake @sb__make_snake()
  store %sb__Snake %t50, %sb__Snake* %t49
  %t52 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 0
  %t53 = load { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t52
  %t54 = call i32 @sb__Snake__length(%sb__Snake* %t49)
  %t55 = call %grid__Cell @food__spawn_food({ [768 x %grid__Cell], i64, i64 } %t53, i32 %t54)
  store %grid__Cell %t55, %grid__Cell* %t51
  store i64 0, i64* %t56
  store i8 0, i8* %t57
  store i8* null, i8** %t58
  %t60 = trunc i32 0 to i8
  store i8 %t60, i8* %t59
  %t63 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 0
  store i32 0, i32* %t63
  store i64 1, i64* %t64
  br label %arr_rep_cond_367
arr_rep_cond_367:
  %t65 = load i64, i64* %t64
  %t66 = icmp ult i64 %t65, 5
  br i1 %t66, label %arr_rep_body_368, label %arr_rep_end_369
arr_rep_body_368:
  %t67 = getelementptr inbounds [5 x i32], [5 x i32]* %t62, i32 0, i64 %t65
  store i32 0, i32* %t67
  %t68 = add i64 %t65, 1
  store i64 %t68, i64* %t64
  br label %arr_rep_cond_367
arr_rep_end_369:
  %t69 = load [5 x i32], [5 x i32]* %t62
  store [5 x i32] %t69, [5 x i32]* %t61
  %t71 = call i32 @SDL_GetTicks()
  store i32 %t71, i32* %t70
  store i1 false, i1* %t72
  store i1 false, i1* %t73
  store i1 false, i1* %t74
  store i1 false, i1* %t75
  store i32 41, i32* %t76
  store i32 19, i32* %t77
  store i32 58, i32* %t78
  store i32 21, i32* %t79
  store i32 225, i32* %t80
  store i32 82, i32* %t81
  store i32 81, i32* %t82
  store i32 80, i32* %t83
  store i32 79, i32* %t84
  store i32 26, i32* %t85
  store i32 22, i32* %t86
  store i32 4, i32* %t87
  store i32 7, i32* %t88
  br label %while_cond_370
while_cond_370:
  br i1 true, label %while_body_371, label %while_else_372
while_body_371:
  %t89 = load i8*, i8** %t6
  %t90 = icmp eq i8* %t89, null
  br i1 %t90, label %sdl_null_window_374, label %sdl_window_handle_ok_375
sdl_null_window_374:
  %t91 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.37, i64 0, i64 0
  call i32 @puts(i8* %t91)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_375:
  store i1 false, i1* %t92
  %t94 = getelementptr inbounds [56 x i8], [56 x i8]* %t93, i64 0, i64 0
  br label %sdl_poll_cond_376
sdl_poll_cond_376:
  %t95 = call i32 @SDL_PollEvent(i8* %t94)
  %t96 = icmp ne i32 %t95, 0
  br i1 %t96, label %sdl_poll_body_377, label %sdl_poll_end_379
sdl_poll_body_377:
  %t97 = bitcast i8* %t94 to i32*
  %t98 = load i32, i32* %t97
  %t99 = icmp eq i32 %t98, 256
  br i1 %t99, label %sdl_poll_set_quit_378, label %sdl_poll_cond_376
sdl_poll_set_quit_378:
  store i1 true, i1* %t92
  br label %sdl_poll_cond_376
sdl_poll_end_379:
  %t100 = load i1, i1* %t92
  br i1 %t100, label %if_then_380, label %if_else_381
if_then_380:
  br label %while_end_373
if_else_381:
  br label %if_end_382
if_end_382:
  %t101 = load i32, i32* %t76
  %t102 = icmp sge i32 %t101, 0
  %t103 = icmp slt i32 %t101, 512
  %t104 = and i1 %t102, %t103
  br i1 %t104, label %key_down_read_383, label %key_down_end_384
key_down_read_383:
  %t105 = call i8* @SDL_GetKeyboardState(i32* null)
  %t106 = sext i32 %t101 to i64
  %t107 = getelementptr inbounds i8, i8* %t105, i64 %t106
  %t108 = load i8, i8* %t107
  %t109 = icmp ne i8 %t108, 0
  br label %key_down_end_384
key_down_end_384:
  %t110 = phi i1 [ false, %if_end_382 ], [ %t109, %key_down_read_383 ]
  br i1 %t110, label %if_then_385, label %if_else_386
if_then_385:
  br label %while_end_373
if_else_386:
  br label %if_end_387
if_end_387:
  %t112 = load i32, i32* %t77
  %t113 = icmp sge i32 %t112, 0
  %t114 = icmp slt i32 %t112, 512
  %t115 = and i1 %t113, %t114
  br i1 %t115, label %key_down_read_388, label %key_down_end_389
key_down_read_388:
  %t116 = call i8* @SDL_GetKeyboardState(i32* null)
  %t117 = sext i32 %t112 to i64
  %t118 = getelementptr inbounds i8, i8* %t116, i64 %t117
  %t119 = load i8, i8* %t118
  %t120 = icmp ne i8 %t119, 0
  br label %key_down_end_389
key_down_end_389:
  %t121 = phi i1 [ false, %if_end_387 ], [ %t120, %key_down_read_388 ]
  store i1 %t121, i1* %t111
  %t122 = load i1, i1* %t111
  br i1 %t122, label %logic_rhs_390, label %logic_short_391
logic_rhs_390:
  %t123 = load i1, i1* %t72
  %t124 = xor i1 true, %t123
  br label %logic_end_392
logic_short_391:
  br label %logic_end_392
logic_end_392:
  %t125 = phi i1 [ %t124, %logic_rhs_390 ], [ false, %logic_short_391 ]
  br i1 %t125, label %if_then_393, label %if_else_394
if_then_393:
  %t126 = load i64, i64* %t56
  %t127 = zext i32 0 to i64
  %t128 = shl i64 1, %t127
  %t129 = and i64 %t126, %t128
  %t130 = icmp ne i64 %t129, 0
  br i1 %t130, label %if_then_396, label %if_else_397
if_then_396:
  %t131 = load i64, i64* %t56
  %t132 = zext i32 0 to i64
  %t133 = shl i64 1, %t132
  %t135 = xor i64 %t133, -1
  %t134 = and i64 %t131, %t135
  store i64 %t134, i64* %t56
  br label %if_end_398
if_else_397:
  %t136 = load i64, i64* %t56
  %t137 = zext i32 0 to i64
  %t138 = shl i64 1, %t137
  %t139 = or i64 %t136, %t138
  store i64 %t139, i64* %t56
  br label %if_end_398
if_end_398:
  br label %if_end_395
if_else_394:
  br label %if_end_395
if_end_395:
  %t140 = load i1, i1* %t111
  store i1 %t140, i1* %t72
  %t142 = load i32, i32* %t78
  %t143 = icmp sge i32 %t142, 0
  %t144 = icmp slt i32 %t142, 512
  %t145 = and i1 %t143, %t144
  br i1 %t145, label %key_down_read_399, label %key_down_end_400
key_down_read_399:
  %t146 = call i8* @SDL_GetKeyboardState(i32* null)
  %t147 = sext i32 %t142 to i64
  %t148 = getelementptr inbounds i8, i8* %t146, i64 %t147
  %t149 = load i8, i8* %t148
  %t150 = icmp ne i8 %t149, 0
  br label %key_down_end_400
key_down_end_400:
  %t151 = phi i1 [ false, %if_end_395 ], [ %t150, %key_down_read_399 ]
  store i1 %t151, i1* %t141
  %t152 = load i1, i1* %t141
  br i1 %t152, label %logic_rhs_401, label %logic_short_402
logic_rhs_401:
  %t153 = load i1, i1* %t73
  %t154 = xor i1 true, %t153
  br label %logic_end_403
logic_short_402:
  br label %logic_end_403
logic_end_403:
  %t155 = phi i1 [ %t154, %logic_rhs_401 ], [ false, %logic_short_402 ]
  br i1 %t155, label %if_then_404, label %if_else_405
if_then_404:
  %t156 = load i64, i64* %t56
  %t157 = zext i32 1 to i64
  %t158 = shl i64 1, %t157
  %t159 = and i64 %t156, %t158
  %t160 = icmp ne i64 %t159, 0
  br i1 %t160, label %if_then_407, label %if_else_408
if_then_407:
  %t161 = load i64, i64* %t56
  %t162 = zext i32 1 to i64
  %t163 = shl i64 1, %t162
  %t165 = xor i64 %t163, -1
  %t164 = and i64 %t161, %t165
  store i64 %t164, i64* %t56
  br label %if_end_409
if_else_408:
  %t166 = load i64, i64* %t56
  %t167 = zext i32 1 to i64
  %t168 = shl i64 1, %t167
  %t169 = or i64 %t166, %t168
  store i64 %t169, i64* %t56
  call void @dump_particle_arena()
  br label %if_end_409
if_end_409:
  br label %if_end_406
if_else_405:
  br label %if_end_406
if_end_406:
  %t170 = load i1, i1* %t141
  store i1 %t170, i1* %t73
  %t171 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 4
  %t172 = load i1, i1* %t171
  %t173 = xor i1 true, %t172
  br i1 %t173, label %if_then_410, label %if_else_411
if_then_410:
  %t175 = load i32, i32* %t79
  %t176 = icmp sge i32 %t175, 0
  %t177 = icmp slt i32 %t175, 512
  %t178 = and i1 %t176, %t177
  br i1 %t178, label %key_down_read_413, label %key_down_end_414
key_down_read_413:
  %t179 = call i8* @SDL_GetKeyboardState(i32* null)
  %t180 = sext i32 %t175 to i64
  %t181 = getelementptr inbounds i8, i8* %t179, i64 %t180
  %t182 = load i8, i8* %t181
  %t183 = icmp ne i8 %t182, 0
  br label %key_down_end_414
key_down_end_414:
  %t184 = phi i1 [ false, %if_then_410 ], [ %t183, %key_down_read_413 ]
  store i1 %t184, i1* %t174
  %t185 = load i1, i1* %t174
  br i1 %t185, label %logic_rhs_415, label %logic_short_416
logic_rhs_415:
  %t186 = load i1, i1* %t74
  %t187 = xor i1 true, %t186
  br label %logic_end_417
logic_short_416:
  br label %logic_end_417
logic_end_417:
  %t188 = phi i1 [ %t187, %logic_rhs_415 ], [ false, %logic_short_416 ]
  br i1 %t188, label %if_then_418, label %if_else_419
if_then_418:
  %t189 = call %sb__Snake @sb__make_snake()
  store %sb__Snake %t189, %sb__Snake* %t49
  %t190 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 0
  %t191 = load { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t190
  %t192 = call i32 @sb__Snake__length(%sb__Snake* %t49)
  %t193 = call %grid__Cell @food__spawn_food({ [768 x %grid__Cell], i64, i64 } %t191, i32 %t192)
  store %grid__Cell %t193, %grid__Cell* %t51
  %t194 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  store i32 0, i32* %t194
  %t195 = load i8*, i8** %t58
  call void @star_rc_release(i8* %t195)
  store i8* null, i8** %t58
  br label %if_end_420
if_else_419:
  br label %if_end_420
if_end_420:
  %t196 = load i1, i1* %t174
  store i1 %t196, i1* %t74
  br label %if_end_412
if_else_411:
  %t197 = load i32, i32* %t81
  %t198 = icmp sge i32 %t197, 0
  %t199 = icmp slt i32 %t197, 512
  %t200 = and i1 %t198, %t199
  br i1 %t200, label %key_down_read_421, label %key_down_end_422
key_down_read_421:
  %t201 = call i8* @SDL_GetKeyboardState(i32* null)
  %t202 = sext i32 %t197 to i64
  %t203 = getelementptr inbounds i8, i8* %t201, i64 %t202
  %t204 = load i8, i8* %t203
  %t205 = icmp ne i8 %t204, 0
  br label %key_down_end_422
key_down_end_422:
  %t206 = phi i1 [ false, %if_else_411 ], [ %t205, %key_down_read_421 ]
  br i1 %t206, label %logic_short_424, label %logic_rhs_423
logic_rhs_423:
  %t207 = load i32, i32* %t85
  %t208 = icmp sge i32 %t207, 0
  %t209 = icmp slt i32 %t207, 512
  %t210 = and i1 %t208, %t209
  br i1 %t210, label %key_down_read_426, label %key_down_end_427
key_down_read_426:
  %t211 = call i8* @SDL_GetKeyboardState(i32* null)
  %t212 = sext i32 %t207 to i64
  %t213 = getelementptr inbounds i8, i8* %t211, i64 %t212
  %t214 = load i8, i8* %t213
  %t215 = icmp ne i8 %t214, 0
  br label %key_down_end_427
key_down_end_427:
  %t216 = phi i1 [ false, %logic_rhs_423 ], [ %t215, %key_down_read_426 ]
  br label %logic_end_425
logic_short_424:
  br label %logic_end_425
logic_end_425:
  %t217 = phi i1 [ %t216, %key_down_end_427 ], [ true, %logic_short_424 ]
  br i1 %t217, label %if_then_428, label %if_else_429
if_then_428:
  call void @sb__Snake__queue_turn(%sb__Snake* %t49, i32 0)
  br label %if_end_430
if_else_429:
  br label %if_end_430
if_end_430:
  %t219 = load i32, i32* %t82
  %t220 = icmp sge i32 %t219, 0
  %t221 = icmp slt i32 %t219, 512
  %t222 = and i1 %t220, %t221
  br i1 %t222, label %key_down_read_431, label %key_down_end_432
key_down_read_431:
  %t223 = call i8* @SDL_GetKeyboardState(i32* null)
  %t224 = sext i32 %t219 to i64
  %t225 = getelementptr inbounds i8, i8* %t223, i64 %t224
  %t226 = load i8, i8* %t225
  %t227 = icmp ne i8 %t226, 0
  br label %key_down_end_432
key_down_end_432:
  %t228 = phi i1 [ false, %if_end_430 ], [ %t227, %key_down_read_431 ]
  br i1 %t228, label %logic_short_434, label %logic_rhs_433
logic_rhs_433:
  %t229 = load i32, i32* %t86
  %t230 = icmp sge i32 %t229, 0
  %t231 = icmp slt i32 %t229, 512
  %t232 = and i1 %t230, %t231
  br i1 %t232, label %key_down_read_436, label %key_down_end_437
key_down_read_436:
  %t233 = call i8* @SDL_GetKeyboardState(i32* null)
  %t234 = sext i32 %t229 to i64
  %t235 = getelementptr inbounds i8, i8* %t233, i64 %t234
  %t236 = load i8, i8* %t235
  %t237 = icmp ne i8 %t236, 0
  br label %key_down_end_437
key_down_end_437:
  %t238 = phi i1 [ false, %logic_rhs_433 ], [ %t237, %key_down_read_436 ]
  br label %logic_end_435
logic_short_434:
  br label %logic_end_435
logic_end_435:
  %t239 = phi i1 [ %t238, %key_down_end_437 ], [ true, %logic_short_434 ]
  br i1 %t239, label %if_then_438, label %if_else_439
if_then_438:
  call void @sb__Snake__queue_turn(%sb__Snake* %t49, i32 1)
  br label %if_end_440
if_else_439:
  br label %if_end_440
if_end_440:
  %t241 = load i32, i32* %t83
  %t242 = icmp sge i32 %t241, 0
  %t243 = icmp slt i32 %t241, 512
  %t244 = and i1 %t242, %t243
  br i1 %t244, label %key_down_read_441, label %key_down_end_442
key_down_read_441:
  %t245 = call i8* @SDL_GetKeyboardState(i32* null)
  %t246 = sext i32 %t241 to i64
  %t247 = getelementptr inbounds i8, i8* %t245, i64 %t246
  %t248 = load i8, i8* %t247
  %t249 = icmp ne i8 %t248, 0
  br label %key_down_end_442
key_down_end_442:
  %t250 = phi i1 [ false, %if_end_440 ], [ %t249, %key_down_read_441 ]
  br i1 %t250, label %logic_short_444, label %logic_rhs_443
logic_rhs_443:
  %t251 = load i32, i32* %t87
  %t252 = icmp sge i32 %t251, 0
  %t253 = icmp slt i32 %t251, 512
  %t254 = and i1 %t252, %t253
  br i1 %t254, label %key_down_read_446, label %key_down_end_447
key_down_read_446:
  %t255 = call i8* @SDL_GetKeyboardState(i32* null)
  %t256 = sext i32 %t251 to i64
  %t257 = getelementptr inbounds i8, i8* %t255, i64 %t256
  %t258 = load i8, i8* %t257
  %t259 = icmp ne i8 %t258, 0
  br label %key_down_end_447
key_down_end_447:
  %t260 = phi i1 [ false, %logic_rhs_443 ], [ %t259, %key_down_read_446 ]
  br label %logic_end_445
logic_short_444:
  br label %logic_end_445
logic_end_445:
  %t261 = phi i1 [ %t260, %key_down_end_447 ], [ true, %logic_short_444 ]
  br i1 %t261, label %if_then_448, label %if_else_449
if_then_448:
  call void @sb__Snake__queue_turn(%sb__Snake* %t49, i32 2)
  br label %if_end_450
if_else_449:
  br label %if_end_450
if_end_450:
  %t263 = load i32, i32* %t84
  %t264 = icmp sge i32 %t263, 0
  %t265 = icmp slt i32 %t263, 512
  %t266 = and i1 %t264, %t265
  br i1 %t266, label %key_down_read_451, label %key_down_end_452
key_down_read_451:
  %t267 = call i8* @SDL_GetKeyboardState(i32* null)
  %t268 = sext i32 %t263 to i64
  %t269 = getelementptr inbounds i8, i8* %t267, i64 %t268
  %t270 = load i8, i8* %t269
  %t271 = icmp ne i8 %t270, 0
  br label %key_down_end_452
key_down_end_452:
  %t272 = phi i1 [ false, %if_end_450 ], [ %t271, %key_down_read_451 ]
  br i1 %t272, label %logic_short_454, label %logic_rhs_453
logic_rhs_453:
  %t273 = load i32, i32* %t88
  %t274 = icmp sge i32 %t273, 0
  %t275 = icmp slt i32 %t273, 512
  %t276 = and i1 %t274, %t275
  br i1 %t276, label %key_down_read_456, label %key_down_end_457
key_down_read_456:
  %t277 = call i8* @SDL_GetKeyboardState(i32* null)
  %t278 = sext i32 %t273 to i64
  %t279 = getelementptr inbounds i8, i8* %t277, i64 %t278
  %t280 = load i8, i8* %t279
  %t281 = icmp ne i8 %t280, 0
  br label %key_down_end_457
key_down_end_457:
  %t282 = phi i1 [ false, %logic_rhs_453 ], [ %t281, %key_down_read_456 ]
  br label %logic_end_455
logic_short_454:
  br label %logic_end_455
logic_end_455:
  %t283 = phi i1 [ %t282, %key_down_end_457 ], [ true, %logic_short_454 ]
  br i1 %t283, label %if_then_458, label %if_else_459
if_then_458:
  call void @sb__Snake__queue_turn(%sb__Snake* %t49, i32 3)
  br label %if_end_460
if_else_459:
  br label %if_end_460
if_end_460:
  %t285 = load i32, i32* %t80
  %t286 = icmp sge i32 %t285, 0
  %t287 = icmp slt i32 %t285, 512
  %t288 = and i1 %t286, %t287
  br i1 %t288, label %key_down_read_461, label %key_down_end_462
key_down_read_461:
  %t289 = call i8* @SDL_GetKeyboardState(i32* null)
  %t290 = sext i32 %t285 to i64
  %t291 = getelementptr inbounds i8, i8* %t289, i64 %t290
  %t292 = load i8, i8* %t291
  %t293 = icmp ne i8 %t292, 0
  br label %key_down_end_462
key_down_end_462:
  %t294 = phi i1 [ false, %if_end_460 ], [ %t293, %key_down_read_461 ]
  store i1 %t294, i1* %t75
  %t296 = load i1, i1* %t75
  br i1 %t296, label %if_then_463, label %if_else_464
if_then_463:
  %t297 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 2
  %t298 = load i32, i32* %t297
  %t299 = icmp eq i32 2, 0
  %t300 = icmp eq i32 %t298, -2147483648
  %t301 = icmp eq i32 2, -1
  %t302 = and i1 %t300, %t301
  %t303 = or i1 %t299, %t302
  br i1 %t303, label %int_div_fail_466, label %int_div_ok_467
int_div_fail_466:
  %t304 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.38, i64 0, i64 0
  call i32 @puts(i8* %t304)
  call void @exit(i32 1)
  unreachable
int_div_ok_467:
  %t305 = sdiv i32 %t298, 2
  br label %if_end_465
if_else_464:
  %t306 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 2
  %t307 = load i32, i32* %t306
  br label %if_end_465
if_end_465:
  %t308 = phi i32 [ %t305, %int_div_ok_467 ], [ %t307, %if_else_464 ]
  store i32 %t308, i32* %t295
  %t310 = call i32 @SDL_GetTicks()
  store i32 %t310, i32* %t309
  %t311 = load i64, i64* %t56
  %t312 = zext i32 0 to i64
  %t313 = shl i64 1, %t312
  %t314 = and i64 %t311, %t313
  %t315 = icmp ne i64 %t314, 0
  %t316 = xor i1 true, %t315
  br i1 %t316, label %logic_rhs_468, label %logic_short_469
logic_rhs_468:
  %t317 = load i32, i32* %t309
  %t318 = load i32, i32* %t70
  %t319 = sub i32 %t317, %t318
  %t320 = load i32, i32* %t295
  %t321 = icmp sge i32 %t319, %t320
  br label %logic_end_470
logic_short_469:
  br label %logic_end_470
logic_end_470:
  %t322 = phi i1 [ %t321, %logic_rhs_468 ], [ false, %logic_short_469 ]
  br i1 %t322, label %if_then_471, label %if_else_472
if_then_471:
  %t323 = load i32, i32* %t309
  store i32 %t323, i32* %t70
  %t325 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t326 = load i32, i32* %t325
  store i32 %t326, i32* %t324
  %t328 = call %grid__Cell @sb__Snake__advance(%sb__Snake* %t49)
  store %grid__Cell %t328, %grid__Cell* %t327
  %t329 = getelementptr i64, i64* null, i32 1
  %t330 = ptrtoint i64* %t329 to i64
  %t331 = load i8*, i8** %t58
  %t332 = icmp eq i8* %t331, null
  br i1 %t332, label %list_cow_alloc_474, label %list_cow_check_475
list_cow_alloc_474:
  %t337 = bitcast void (i8*)* @list_release_symbol to i8*
  %t338 = call i8* @star_rc_alloc(i64 24, i8* %t337)
  %t339 = bitcast i8* %t338 to { i64*, i64, i64 }*
  %t340 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t339, i32 0, i32 0
  store i64* null, i64** %t340
  %t341 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t339, i32 0, i32 1
  store i64 0, i64* %t341
  %t342 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t339, i32 0, i32 2
  store i64 0, i64* %t342
  store i8* %t338, i8** %t58
  br label %list_cow_done_476
list_cow_check_475:
  %t343 = getelementptr inbounds i8, i8* %t331, i64 -16
  %t344 = bitcast i8* %t343 to i64*
  %t345 = load atomic i64, i64* %t344 seq_cst, align 8
  %t346 = icmp eq i64 %t345, 1
  br i1 %t346, label %list_cow_done_476, label %list_cow_clone_477
list_cow_clone_477:
  %t347 = bitcast i8* %t331 to { i64*, i64, i64 }*
  %t348 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t347, i32 0, i32 0
  %t349 = load i64*, i64** %t348
  %t350 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t347, i32 0, i32 1
  %t351 = load i64, i64* %t350
  %t352 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t347, i32 0, i32 2
  %t353 = load i64, i64* %t352
  %t354 = bitcast void (i8*)* @list_release_symbol to i8*
  %t355 = call i8* @star_rc_alloc(i64 24, i8* %t354)
  %t356 = bitcast i8* %t355 to { i64*, i64, i64 }*
  %t357 = mul i64 %t353, %t330
  %t358 = call i8* @malloc(i64 %t357)
  %t359 = bitcast i8* %t358 to i64*
  %t360 = icmp sgt i64 %t351, 0
  br i1 %t360, label %list_cow_copy_478, label %list_cow_after_copy_479
list_cow_copy_478:
  %t361 = mul i64 %t351, %t330
  %t362 = bitcast i64* %t349 to i8*
  call i8* @memcpy(i8* %t358, i8* %t362, i64 %t361)
  br label %list_cow_after_copy_479
list_cow_after_copy_479:
  %t363 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t356, i32 0, i32 0
  store i64* %t359, i64** %t363
  %t364 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t356, i32 0, i32 1
  store i64 %t351, i64* %t364
  %t365 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t356, i32 0, i32 2
  store i64 %t353, i64* %t365
  call void @star_rc_release(i8* %t331)
  store i8* %t355, i8** %t58
  br label %list_cow_done_476
list_cow_done_476:
  %t366 = load i8*, i8** %t58
  %t367 = bitcast i8* %t366 to { i64*, i64, i64 }*
  %t368 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t367, i32 0, i32 0
  %t369 = load i64*, i64** %t368
  %t370 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t367, i32 0, i32 1
  %t371 = load i64, i64* %t370
  %t372 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t367, i32 0, i32 2
  %t373 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.39, i64 0, i32 2, i64 0
  %t374 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t374, i32 -1)
  %t375 = load i64, i64* @sym.len
  %t376 = load i8**, i8*** @sym.data
  store i64 0, i64* %t377
  br label %sym_find_cond_480
sym_find_cond_480:
  %t378 = load i64, i64* %t377
  %t379 = icmp slt i64 %t378, %t375
  br i1 %t379, label %sym_find_body_481, label %sym_find_end_483
sym_find_body_481:
  %t380 = getelementptr inbounds i8*, i8** %t376, i64 %t378
  %t381 = load i8*, i8** %t380
  %t382 = call i32 @strcmp(i8* %t381, i8* %t373)
  %t383 = icmp eq i32 %t382, 0
  br i1 %t383, label %sym_find_end_483, label %sym_find_next_482
sym_find_next_482:
  %t384 = add i64 %t378, 1
  store i64 %t384, i64* %t377
  br label %sym_find_cond_480
sym_find_end_483:
  %t385 = load i64, i64* %t377
  %t386 = icmp slt i64 %t385, %t375
  br i1 %t386, label %sym_found_484, label %sym_notfound_485
sym_found_484:
  call void @star_rc_release(i8* %t373)
  br label %sym_done_486
sym_notfound_485:
  %t387 = load i64, i64* @sym.cap
  %t388 = icmp sge i64 %t375, %t387
  br i1 %t388, label %sym_grow_487, label %sym_store_488
sym_grow_487:
  %t389 = mul i64 %t387, 2
  %t390 = icmp sgt i64 %t389, 0
  %t391 = select i1 %t390, i64 %t389, i64 1
  %t392 = mul i64 %t391, 8
  %t393 = call i8* @malloc(i64 %t392)
  %t394 = bitcast i8* %t393 to i8**
  %t395 = icmp sgt i64 %t387, 0
  br i1 %t395, label %sym_copy_489, label %sym_after_copy_490
sym_copy_489:
  %t396 = mul i64 %t375, 8
  %t397 = bitcast i8** %t376 to i8*
  call i8* @memcpy(i8* %t393, i8* %t397, i64 %t396)
  call void @free(i8* %t397)
  br label %sym_after_copy_490
sym_after_copy_490:
  store i8** %t394, i8*** @sym.data
  store i64 %t391, i64* @sym.cap
  br label %sym_store_488
sym_store_488:
  %t398 = load i8**, i8*** @sym.data
  %t399 = getelementptr inbounds i8*, i8** %t398, i64 %t375
  store i8* %t373, i8** %t399
  %t400 = add i64 %t375, 1
  store i64 %t400, i64* @sym.len
  br label %sym_done_486
sym_done_486:
  %t401 = phi i64 [ %t385, %sym_found_484 ], [ %t375, %sym_store_488 ]
  call i32 @ReleaseSemaphore(i8* %t374, i32 1, i32* null)
  %t402 = load i64, i64* %t372
  %t403 = load i64*, i64** %t368
  %t404 = load i64, i64* %t370
  %t405 = icmp sge i64 %t404, %t402
  br i1 %t405, label %list_push_grow_491, label %list_push_store_492
list_push_grow_491:
  %t406 = mul i64 %t402, 2
  %t407 = icmp sgt i64 %t406, 0
  %t408 = select i1 %t407, i64 %t406, i64 1
  %t409 = getelementptr i64, i64* null, i32 1
  %t410 = ptrtoint i64* %t409 to i64
  %t411 = mul i64 %t408, %t410
  %t412 = call i8* @malloc(i64 %t411)
  %t413 = bitcast i8* %t412 to i64*
  %t414 = icmp sgt i64 %t402, 0
  br i1 %t414, label %list_push_copy_493, label %list_push_after_copy_494
list_push_copy_493:
  %t415 = mul i64 %t404, %t410
  %t416 = bitcast i64* %t403 to i8*
  call i8* @memcpy(i8* %t412, i8* %t416, i64 %t415)
  call void @free(i8* %t416)
  br label %list_push_after_copy_494
list_push_after_copy_494:
  store i64* %t413, i64** %t368
  store i64 %t408, i64* %t372
  br label %list_push_store_492
list_push_store_492:
  %t417 = load i64*, i64** %t368
  %t418 = getelementptr inbounds i64, i64* %t417, i64 %t404
  store i64 %t401, i64* %t418
  %t419 = add i64 %t404, 1
  store i64 %t419, i64* %t370
  %t420 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 4
  %t421 = load i1, i1* %t420
  br i1 %t421, label %logic_rhs_495, label %logic_short_496
logic_rhs_495:
  %t422 = load %grid__Cell, %grid__Cell* %t327
  %t423 = load %grid__Cell, %grid__Cell* %t51
  %t424 = call i1 @eq_s_grid__Cell(%grid__Cell %t422, %grid__Cell %t423)
  br label %logic_end_497
logic_short_496:
  br label %logic_end_497
logic_end_497:
  %t425 = phi i1 [ %t424, %logic_rhs_495 ], [ false, %logic_short_496 ]
  br i1 %t425, label %if_then_498, label %if_else_499
if_then_498:
  call void @sb__Snake__grow(%sb__Snake* %t49, i32 1)
  %t427 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t428 = load i32, i32* %t427
  %t429 = add i32 %t428, 10
  %t430 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  store i32 %t429, i32* %t430
  %t431 = getelementptr i64, i64* null, i32 1
  %t432 = ptrtoint i64* %t431 to i64
  %t433 = load i8*, i8** %t58
  %t434 = icmp eq i8* %t433, null
  br i1 %t434, label %list_cow_alloc_501, label %list_cow_check_502
list_cow_alloc_501:
  %t435 = bitcast void (i8*)* @list_release_symbol to i8*
  %t436 = call i8* @star_rc_alloc(i64 24, i8* %t435)
  %t437 = bitcast i8* %t436 to { i64*, i64, i64 }*
  %t438 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t437, i32 0, i32 0
  store i64* null, i64** %t438
  %t439 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t437, i32 0, i32 1
  store i64 0, i64* %t439
  %t440 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t437, i32 0, i32 2
  store i64 0, i64* %t440
  store i8* %t436, i8** %t58
  br label %list_cow_done_503
list_cow_check_502:
  %t441 = getelementptr inbounds i8, i8* %t433, i64 -16
  %t442 = bitcast i8* %t441 to i64*
  %t443 = load atomic i64, i64* %t442 seq_cst, align 8
  %t444 = icmp eq i64 %t443, 1
  br i1 %t444, label %list_cow_done_503, label %list_cow_clone_504
list_cow_clone_504:
  %t445 = bitcast i8* %t433 to { i64*, i64, i64 }*
  %t446 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t445, i32 0, i32 0
  %t447 = load i64*, i64** %t446
  %t448 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t445, i32 0, i32 1
  %t449 = load i64, i64* %t448
  %t450 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t445, i32 0, i32 2
  %t451 = load i64, i64* %t450
  %t452 = bitcast void (i8*)* @list_release_symbol to i8*
  %t453 = call i8* @star_rc_alloc(i64 24, i8* %t452)
  %t454 = bitcast i8* %t453 to { i64*, i64, i64 }*
  %t455 = mul i64 %t451, %t432
  %t456 = call i8* @malloc(i64 %t455)
  %t457 = bitcast i8* %t456 to i64*
  %t458 = icmp sgt i64 %t449, 0
  br i1 %t458, label %list_cow_copy_505, label %list_cow_after_copy_506
list_cow_copy_505:
  %t459 = mul i64 %t449, %t432
  %t460 = bitcast i64* %t447 to i8*
  call i8* @memcpy(i8* %t456, i8* %t460, i64 %t459)
  br label %list_cow_after_copy_506
list_cow_after_copy_506:
  %t461 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t454, i32 0, i32 0
  store i64* %t457, i64** %t461
  %t462 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t454, i32 0, i32 1
  store i64 %t449, i64* %t462
  %t463 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t454, i32 0, i32 2
  store i64 %t451, i64* %t463
  call void @star_rc_release(i8* %t433)
  store i8* %t453, i8** %t58
  br label %list_cow_done_503
list_cow_done_503:
  %t464 = load i8*, i8** %t58
  %t465 = bitcast i8* %t464 to { i64*, i64, i64 }*
  %t466 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t465, i32 0, i32 0
  %t467 = load i64*, i64** %t466
  %t468 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t465, i32 0, i32 1
  %t469 = load i64, i64* %t468
  %t470 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t465, i32 0, i32 2
  %t471 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.40, i64 0, i32 2, i64 0
  %t472 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t472, i32 -1)
  %t473 = load i64, i64* @sym.len
  %t474 = load i8**, i8*** @sym.data
  store i64 0, i64* %t475
  br label %sym_find_cond_507
sym_find_cond_507:
  %t476 = load i64, i64* %t475
  %t477 = icmp slt i64 %t476, %t473
  br i1 %t477, label %sym_find_body_508, label %sym_find_end_510
sym_find_body_508:
  %t478 = getelementptr inbounds i8*, i8** %t474, i64 %t476
  %t479 = load i8*, i8** %t478
  %t480 = call i32 @strcmp(i8* %t479, i8* %t471)
  %t481 = icmp eq i32 %t480, 0
  br i1 %t481, label %sym_find_end_510, label %sym_find_next_509
sym_find_next_509:
  %t482 = add i64 %t476, 1
  store i64 %t482, i64* %t475
  br label %sym_find_cond_507
sym_find_end_510:
  %t483 = load i64, i64* %t475
  %t484 = icmp slt i64 %t483, %t473
  br i1 %t484, label %sym_found_511, label %sym_notfound_512
sym_found_511:
  call void @star_rc_release(i8* %t471)
  br label %sym_done_513
sym_notfound_512:
  %t485 = load i64, i64* @sym.cap
  %t486 = icmp sge i64 %t473, %t485
  br i1 %t486, label %sym_grow_514, label %sym_store_515
sym_grow_514:
  %t487 = mul i64 %t485, 2
  %t488 = icmp sgt i64 %t487, 0
  %t489 = select i1 %t488, i64 %t487, i64 1
  %t490 = mul i64 %t489, 8
  %t491 = call i8* @malloc(i64 %t490)
  %t492 = bitcast i8* %t491 to i8**
  %t493 = icmp sgt i64 %t485, 0
  br i1 %t493, label %sym_copy_516, label %sym_after_copy_517
sym_copy_516:
  %t494 = mul i64 %t473, 8
  %t495 = bitcast i8** %t474 to i8*
  call i8* @memcpy(i8* %t491, i8* %t495, i64 %t494)
  call void @free(i8* %t495)
  br label %sym_after_copy_517
sym_after_copy_517:
  store i8** %t492, i8*** @sym.data
  store i64 %t489, i64* @sym.cap
  br label %sym_store_515
sym_store_515:
  %t496 = load i8**, i8*** @sym.data
  %t497 = getelementptr inbounds i8*, i8** %t496, i64 %t473
  store i8* %t471, i8** %t497
  %t498 = add i64 %t473, 1
  store i64 %t498, i64* @sym.len
  br label %sym_done_513
sym_done_513:
  %t499 = phi i64 [ %t483, %sym_found_511 ], [ %t473, %sym_store_515 ]
  call i32 @ReleaseSemaphore(i8* %t472, i32 1, i32* null)
  %t500 = load i64, i64* %t470
  %t501 = load i64*, i64** %t466
  %t502 = load i64, i64* %t468
  %t503 = icmp sge i64 %t502, %t500
  br i1 %t503, label %list_push_grow_518, label %list_push_store_519
list_push_grow_518:
  %t504 = mul i64 %t500, 2
  %t505 = icmp sgt i64 %t504, 0
  %t506 = select i1 %t505, i64 %t504, i64 1
  %t507 = getelementptr i64, i64* null, i32 1
  %t508 = ptrtoint i64* %t507 to i64
  %t509 = mul i64 %t506, %t508
  %t510 = call i8* @malloc(i64 %t509)
  %t511 = bitcast i8* %t510 to i64*
  %t512 = icmp sgt i64 %t500, 0
  br i1 %t512, label %list_push_copy_520, label %list_push_after_copy_521
list_push_copy_520:
  %t513 = mul i64 %t502, %t508
  %t514 = bitcast i64* %t501 to i8*
  call i8* @memcpy(i8* %t510, i8* %t514, i64 %t513)
  call void @free(i8* %t514)
  br label %list_push_after_copy_521
list_push_after_copy_521:
  store i64* %t511, i64** %t466
  store i64 %t506, i64* %t470
  br label %list_push_store_519
list_push_store_519:
  %t515 = load i64*, i64** %t466
  %t516 = getelementptr inbounds i64, i64* %t515, i64 %t502
  store i64 %t499, i64* %t516
  %t517 = add i64 %t502, 1
  store i64 %t517, i64* %t468
  %t519 = load %grid__Cell, %grid__Cell* %t51
  %t520 = call { i32, i32 } @cell_px(%grid__Cell %t519)
  store { i32, i32 } %t520, { i32, i32 }* %t518
  %t522 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t518, i32 0, i32 0
  %t523 = load i32, i32* %t522
  %t524 = icmp eq i32 2, 0
  %t525 = icmp eq i32 20, -2147483648
  %t526 = icmp eq i32 2, -1
  %t527 = and i1 %t525, %t526
  %t528 = or i1 %t524, %t527
  br i1 %t528, label %int_div_fail_522, label %int_div_ok_523
int_div_fail_522:
  %t529 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.41, i64 0, i64 0
  call i32 @puts(i8* %t529)
  call void @exit(i32 1)
  unreachable
int_div_ok_523:
  %t530 = sdiv i32 20, 2
  %t531 = add i32 %t523, %t530
  %t532 = sitofp i32 %t531 to float
  store float %t532, float* %t521
  %t534 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t518, i32 0, i32 1
  %t535 = load i32, i32* %t534
  %t536 = icmp eq i32 2, 0
  %t537 = icmp eq i32 20, -2147483648
  %t538 = icmp eq i32 2, -1
  %t539 = and i1 %t537, %t538
  %t540 = or i1 %t536, %t539
  br i1 %t540, label %int_div_fail_524, label %int_div_ok_525
int_div_fail_524:
  %t541 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.42, i64 0, i64 0
  call i32 @puts(i8* %t541)
  call void @exit(i32 1)
  unreachable
int_div_ok_525:
  %t542 = sdiv i32 20, 2
  %t543 = add i32 %t535, %t542
  %t544 = sitofp i32 %t543 to float
  store float %t544, float* %t533
  %t546 = load float, float* %t521
  %t547 = load float, float* %t533
  %t548 = call i32 @spawn_particle_burst(float %t546, float %t547)
  store i32 %t548, i32* %t545
  %t549 = load i64, i64* %t56
  %t550 = zext i32 1 to i64
  %t551 = shl i64 1, %t550
  %t552 = and i64 %t549, %t551
  %t553 = icmp ne i64 %t552, 0
  br i1 %t553, label %logic_rhs_526, label %logic_short_527
logic_rhs_526:
  %t554 = load i32, i32* %t545
  %t555 = icmp sge i32 %t554, 0
  br label %logic_end_528
logic_short_527:
  br label %logic_end_528
logic_end_528:
  %t556 = phi i1 [ %t555, %logic_rhs_526 ], [ false, %logic_short_527 ]
  br i1 %t556, label %if_then_529, label %if_else_530
if_then_529:
  %t558 = load i32, i32* %t545
  %t559 = sext i32 %t558 to i64
  %t560 = icmp ult i64 %t559, 256
  br i1 %t560, label %genref_create_ok_532, label %genref_create_oob_533
genref_create_ok_532:
  %t561 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t559
  %t562 = load i64, i64* %t561
  br label %genref_create_end_534
genref_create_oob_533:
  br label %genref_create_end_534
genref_create_end_534:
  %t563 = phi i64 [ %t562, %genref_create_ok_532 ], [ 0, %genref_create_oob_533 ]
  %t565 = getelementptr inbounds %GenRef, %GenRef* %t564, i32 0, i32 0
  store i32 %t558, i32* %t565
  %t566 = getelementptr inbounds %GenRef, %GenRef* %t564, i32 0, i32 1
  store i64 %t563, i64* %t566
  %t567 = load %GenRef, %GenRef* %t564
  store %GenRef %t567, %GenRef* %t557
  %t568 = load i32, i32* %t545
  %t569 = getelementptr inbounds %GenRef, %GenRef* %t557, i32 0, i32 0
  %t570 = load i32, i32* %t569
  %t571 = getelementptr inbounds %GenRef, %GenRef* %t557, i32 0, i32 1
  %t572 = load i64, i64* %t571
  %t573 = sext i32 %t570 to i64
  %t574 = icmp ult i64 %t573, 256
  br i1 %t574, label %genref_place_check_535, label %genref_place_stale_537
genref_place_check_535:
  %t575 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t573
  %t576 = load i64, i64* %t575
  %t577 = icmp eq i64 %t572, %t576
  %t578 = and i64 %t576, 1
  %t579 = icmp eq i64 %t578, 1
  %t580 = and i1 %t577, %t579
  br i1 %t580, label %genref_place_ok_536, label %genref_place_stale_537
genref_place_ok_536:
  %t581 = load %Particle*, %Particle** @arena.Particles.data
  %t582 = getelementptr inbounds %Particle, %Particle* %t581, i64 %t573
  br label %genref_place_end_538
genref_place_stale_537:
  store %Particle zeroinitializer, %Particle* %t583
  br label %genref_place_end_538
genref_place_end_538:
  %t584 = phi %Particle* [ %t582, %genref_place_ok_536 ], [ %t583, %genref_place_stale_537 ]
  %t585 = getelementptr inbounds %Particle, %Particle* %t584, i32 0, i32 4
  %t586 = load float, float* %t585
  %t587 = getelementptr inbounds [58 x i8], [58 x i8]* @.str.43, i64 0, i64 0
  %t588 = fpext float %t586 to double
  call i32 (i8*, ...) @printf(i8* %t587, i32 %t568, double %t588)
  br label %if_end_531
if_else_530:
  br label %if_end_531
if_end_531:
  %t591 = load i8*, i8** %t6
  %t592 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t590, i32 0, i32 0
  store i8* %t591, i8** %t592
  %t593 = getelementptr inbounds %FlashOnEat, %FlashOnEat* %t590, i32 0, i32 1
  store i32 0, i32* %t593
  %t594 = load %FlashOnEat, %FlashOnEat* %t590
  store %FlashOnEat %t594, %FlashOnEat* %t589
  store i1 true, i1* %t595
  br label %while_cond_539
while_cond_539:
  %t596 = load i1, i1* %t595
  br i1 %t596, label %while_body_540, label %while_else_541
while_body_540:
  %t597 = call i1 @FlashOnEat__resume(%FlashOnEat* %t589)
  store i1 %t597, i1* %t595
  br label %while_cond_539
while_else_541:
  br label %while_end_542
while_end_542:
  %t598 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 0
  %t599 = load { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t598
  %t600 = call i32 @sb__Snake__length(%sb__Snake* %t49)
  %t601 = call %grid__Cell @food__spawn_food({ [768 x %grid__Cell], i64, i64 } %t599, i32 %t600)
  store %grid__Cell %t601, %grid__Cell* %t51
  %t602 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t603 = load i32, i32* %t602
  %t604 = icmp eq i32 50, 0
  %t605 = icmp eq i32 %t603, -2147483648
  %t606 = icmp eq i32 50, -1
  %t607 = and i1 %t605, %t606
  %t608 = or i1 %t604, %t607
  br i1 %t608, label %int_div_fail_543, label %int_div_ok_544
int_div_fail_543:
  %t609 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.44, i64 0, i64 0
  call i32 @puts(i8* %t609)
  call void @exit(i32 1)
  unreachable
int_div_ok_544:
  %t610 = sdiv i32 %t603, 50
  %t611 = load i32, i32* %t324
  %t612 = icmp eq i32 50, 0
  %t613 = icmp eq i32 %t611, -2147483648
  %t614 = icmp eq i32 50, -1
  %t615 = and i1 %t613, %t614
  %t616 = or i1 %t612, %t615
  br i1 %t616, label %int_div_fail_545, label %int_div_ok_546
int_div_fail_545:
  %t617 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.45, i64 0, i64 0
  call i32 @puts(i8* %t617)
  call void @exit(i32 1)
  unreachable
int_div_ok_546:
  %t618 = sdiv i32 %t611, 50
  %t619 = icmp sgt i32 %t610, %t618
  br i1 %t619, label %if_then_547, label %if_else_548
if_then_547:
  %t621 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t622 = load i32, i32* %t621
  %t623 = icmp eq i32 50, 0
  %t624 = icmp eq i32 %t622, -2147483648
  %t625 = icmp eq i32 50, -1
  %t626 = and i1 %t624, %t625
  %t627 = or i1 %t623, %t626
  br i1 %t627, label %int_div_fail_550, label %int_div_ok_551
int_div_fail_550:
  %t628 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.46, i64 0, i64 0
  call i32 @puts(i8* %t628)
  call void @exit(i32 1)
  unreachable
int_div_ok_551:
  %t629 = sdiv i32 %t622, 50
  store i32 %t629, i32* %t620
  %t630 = load i32, i32* %t620
  %t631 = icmp sge i32 %t630, 1
  br i1 %t631, label %logic_rhs_552, label %logic_short_553
logic_rhs_552:
  %t632 = load i32, i32* %t620
  %t633 = icmp sle i32 %t632, 8
  br label %logic_end_554
logic_short_553:
  br label %logic_end_554
logic_end_554:
  %t634 = phi i1 [ %t633, %logic_rhs_552 ], [ false, %logic_short_553 ]
  br i1 %t634, label %if_then_555, label %if_else_556
if_then_555:
  %t635 = load i8, i8* %t57
  %t636 = load i32, i32* %t620
  %t637 = sub i32 %t636, 1
  %t638 = and i32 %t637, 7
  %t639 = trunc i32 %t638 to i8
  %t640 = shl i8 1, %t639
  %t641 = or i8 %t635, %t640
  store i8 %t641, i8* %t57
  %t642 = load i32, i32* %t620
  %t643 = load i8, i8* %t57
  %t644 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.47, i64 0, i64 0
  %t645 = zext i8 %t643 to i32
  call i32 (i8*, ...) @printf(i8* %t644, i32 %t642, i32 %t645)
  br label %if_end_557
if_else_556:
  br label %if_end_557
if_end_557:
  br label %if_end_549
if_else_548:
  br label %if_end_549
if_end_549:
  %t646 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t647 = load i32, i32* %t646
  %t648 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t649 = load i32, i32* %t648
  %t650 = icmp sgt i32 %t647, %t649
  br i1 %t650, label %if_then_558, label %if_else_559
if_then_558:
  %t651 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t652 = load i32, i32* %t651
  %t653 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  store i32 %t652, i32* %t653
  br label %if_end_560
if_else_559:
  br label %if_end_560
if_end_560:
  br label %if_end_500
if_else_499:
  br label %if_end_500
if_end_500:
  %t654 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 4
  %t655 = load i1, i1* %t654
  %t656 = xor i1 true, %t655
  br i1 %t656, label %if_then_561, label %if_else_562
if_then_561:
  %t657 = getelementptr i64, i64* null, i32 1
  %t658 = ptrtoint i64* %t657 to i64
  %t659 = load i8*, i8** %t58
  %t660 = icmp eq i8* %t659, null
  br i1 %t660, label %list_cow_alloc_564, label %list_cow_check_565
list_cow_alloc_564:
  %t661 = bitcast void (i8*)* @list_release_symbol to i8*
  %t662 = call i8* @star_rc_alloc(i64 24, i8* %t661)
  %t663 = bitcast i8* %t662 to { i64*, i64, i64 }*
  %t664 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t663, i32 0, i32 0
  store i64* null, i64** %t664
  %t665 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t663, i32 0, i32 1
  store i64 0, i64* %t665
  %t666 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t663, i32 0, i32 2
  store i64 0, i64* %t666
  store i8* %t662, i8** %t58
  br label %list_cow_done_566
list_cow_check_565:
  %t667 = getelementptr inbounds i8, i8* %t659, i64 -16
  %t668 = bitcast i8* %t667 to i64*
  %t669 = load atomic i64, i64* %t668 seq_cst, align 8
  %t670 = icmp eq i64 %t669, 1
  br i1 %t670, label %list_cow_done_566, label %list_cow_clone_567
list_cow_clone_567:
  %t671 = bitcast i8* %t659 to { i64*, i64, i64 }*
  %t672 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t671, i32 0, i32 0
  %t673 = load i64*, i64** %t672
  %t674 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t671, i32 0, i32 1
  %t675 = load i64, i64* %t674
  %t676 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t671, i32 0, i32 2
  %t677 = load i64, i64* %t676
  %t678 = bitcast void (i8*)* @list_release_symbol to i8*
  %t679 = call i8* @star_rc_alloc(i64 24, i8* %t678)
  %t680 = bitcast i8* %t679 to { i64*, i64, i64 }*
  %t681 = mul i64 %t677, %t658
  %t682 = call i8* @malloc(i64 %t681)
  %t683 = bitcast i8* %t682 to i64*
  %t684 = icmp sgt i64 %t675, 0
  br i1 %t684, label %list_cow_copy_568, label %list_cow_after_copy_569
list_cow_copy_568:
  %t685 = mul i64 %t675, %t658
  %t686 = bitcast i64* %t673 to i8*
  call i8* @memcpy(i8* %t682, i8* %t686, i64 %t685)
  br label %list_cow_after_copy_569
list_cow_after_copy_569:
  %t687 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t680, i32 0, i32 0
  store i64* %t683, i64** %t687
  %t688 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t680, i32 0, i32 1
  store i64 %t675, i64* %t688
  %t689 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t680, i32 0, i32 2
  store i64 %t677, i64* %t689
  call void @star_rc_release(i8* %t659)
  store i8* %t679, i8** %t58
  br label %list_cow_done_566
list_cow_done_566:
  %t690 = load i8*, i8** %t58
  %t691 = bitcast i8* %t690 to { i64*, i64, i64 }*
  %t692 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t691, i32 0, i32 0
  %t693 = load i64*, i64** %t692
  %t694 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t691, i32 0, i32 1
  %t695 = load i64, i64* %t694
  %t696 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t691, i32 0, i32 2
  %t697 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.48, i64 0, i32 2, i64 0
  %t698 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t698, i32 -1)
  %t699 = load i64, i64* @sym.len
  %t700 = load i8**, i8*** @sym.data
  store i64 0, i64* %t701
  br label %sym_find_cond_570
sym_find_cond_570:
  %t702 = load i64, i64* %t701
  %t703 = icmp slt i64 %t702, %t699
  br i1 %t703, label %sym_find_body_571, label %sym_find_end_573
sym_find_body_571:
  %t704 = getelementptr inbounds i8*, i8** %t700, i64 %t702
  %t705 = load i8*, i8** %t704
  %t706 = call i32 @strcmp(i8* %t705, i8* %t697)
  %t707 = icmp eq i32 %t706, 0
  br i1 %t707, label %sym_find_end_573, label %sym_find_next_572
sym_find_next_572:
  %t708 = add i64 %t702, 1
  store i64 %t708, i64* %t701
  br label %sym_find_cond_570
sym_find_end_573:
  %t709 = load i64, i64* %t701
  %t710 = icmp slt i64 %t709, %t699
  br i1 %t710, label %sym_found_574, label %sym_notfound_575
sym_found_574:
  call void @star_rc_release(i8* %t697)
  br label %sym_done_576
sym_notfound_575:
  %t711 = load i64, i64* @sym.cap
  %t712 = icmp sge i64 %t699, %t711
  br i1 %t712, label %sym_grow_577, label %sym_store_578
sym_grow_577:
  %t713 = mul i64 %t711, 2
  %t714 = icmp sgt i64 %t713, 0
  %t715 = select i1 %t714, i64 %t713, i64 1
  %t716 = mul i64 %t715, 8
  %t717 = call i8* @malloc(i64 %t716)
  %t718 = bitcast i8* %t717 to i8**
  %t719 = icmp sgt i64 %t711, 0
  br i1 %t719, label %sym_copy_579, label %sym_after_copy_580
sym_copy_579:
  %t720 = mul i64 %t699, 8
  %t721 = bitcast i8** %t700 to i8*
  call i8* @memcpy(i8* %t717, i8* %t721, i64 %t720)
  call void @free(i8* %t721)
  br label %sym_after_copy_580
sym_after_copy_580:
  store i8** %t718, i8*** @sym.data
  store i64 %t715, i64* @sym.cap
  br label %sym_store_578
sym_store_578:
  %t722 = load i8**, i8*** @sym.data
  %t723 = getelementptr inbounds i8*, i8** %t722, i64 %t699
  store i8* %t697, i8** %t723
  %t724 = add i64 %t699, 1
  store i64 %t724, i64* @sym.len
  br label %sym_done_576
sym_done_576:
  %t725 = phi i64 [ %t709, %sym_found_574 ], [ %t699, %sym_store_578 ]
  call i32 @ReleaseSemaphore(i8* %t698, i32 1, i32* null)
  %t726 = load i64, i64* %t696
  %t727 = load i64*, i64** %t692
  %t728 = load i64, i64* %t694
  %t729 = icmp sge i64 %t728, %t726
  br i1 %t729, label %list_push_grow_581, label %list_push_store_582
list_push_grow_581:
  %t730 = mul i64 %t726, 2
  %t731 = icmp sgt i64 %t730, 0
  %t732 = select i1 %t731, i64 %t730, i64 1
  %t733 = getelementptr i64, i64* null, i32 1
  %t734 = ptrtoint i64* %t733 to i64
  %t735 = mul i64 %t732, %t734
  %t736 = call i8* @malloc(i64 %t735)
  %t737 = bitcast i8* %t736 to i64*
  %t738 = icmp sgt i64 %t726, 0
  br i1 %t738, label %list_push_copy_583, label %list_push_after_copy_584
list_push_copy_583:
  %t739 = mul i64 %t728, %t734
  %t740 = bitcast i64* %t727 to i8*
  call i8* @memcpy(i8* %t736, i8* %t740, i64 %t739)
  call void @free(i8* %t740)
  br label %list_push_after_copy_584
list_push_after_copy_584:
  store i64* %t737, i64** %t692
  store i64 %t732, i64* %t696
  br label %list_push_store_582
list_push_store_582:
  %t741 = load i64*, i64** %t692
  %t742 = getelementptr inbounds i64, i64* %t741, i64 %t728
  store i64 %t725, i64* %t742
  %t743 = add i64 %t728, 1
  store i64 %t743, i64* %t694
  %t744 = load i8*, i8** %t58
  %t745 = icmp eq i8* %t744, null
  br i1 %t745, label %list_read_null_585, label %list_read_real_586
list_read_null_585:
  br label %list_read_end_587
list_read_real_586:
  %t746 = bitcast i8* %t744 to { i64*, i64, i64 }*
  %t747 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t746, i32 0, i32 0
  %t748 = load i64*, i64** %t747
  %t749 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t746, i32 0, i32 1
  %t750 = load i64, i64* %t749
  br label %list_read_end_587
list_read_end_587:
  %t751 = phi i64* [ null, %list_read_null_585 ], [ %t748, %list_read_real_586 ]
  %t752 = phi i64 [ 0, %list_read_null_585 ], [ %t750, %list_read_real_586 ]
  %t753 = load i8*, i8** %t58
  %t754 = icmp eq i8* %t753, null
  br i1 %t754, label %list_read_null_588, label %list_read_real_589
list_read_null_588:
  br label %list_read_end_590
list_read_real_589:
  %t755 = bitcast i8* %t753 to { i64*, i64, i64 }*
  %t756 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t755, i32 0, i32 0
  %t757 = load i64*, i64** %t756
  %t758 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t755, i32 0, i32 1
  %t759 = load i64, i64* %t758
  br label %list_read_end_590
list_read_end_590:
  %t760 = phi i64* [ null, %list_read_null_588 ], [ %t757, %list_read_real_589 ]
  %t761 = phi i64 [ 0, %list_read_null_588 ], [ %t759, %list_read_real_589 ]
  %t762 = trunc i64 %t761 to i32
  %t763 = sub i32 %t762, 1
  %t764 = sext i32 %t763 to i64
  %t765 = icmp ult i64 %t764, %t752
  br i1 %t765, label %list_idx_ok_591, label %list_idx_oob_592
list_idx_ok_591:
  %t766 = getelementptr inbounds i64, i64* %t751, i64 %t764
  %t767 = load i64, i64* %t766
  br label %list_idx_end_593
list_idx_oob_592:
  br label %list_idx_end_593
list_idx_end_593:
  %t768 = phi i64 [ %t767, %list_idx_ok_591 ], [ 0, %list_idx_oob_592 ]
  %t769 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t769, i32 -1)
  %t770 = load i64, i64* @sym.len
  %t771 = icmp sge i64 %t768, 0
  %t772 = icmp slt i64 %t768, %t770
  %t773 = and i1 %t771, %t772
  br i1 %t773, label %sym_name_ok_594, label %sym_name_oob_595
sym_name_ok_594:
  %t774 = load i8**, i8*** @sym.data
  %t775 = getelementptr inbounds i8*, i8** %t774, i64 %t768
  %t776 = load i8*, i8** %t775
  call void @star_rc_retain(i8* %t776)
  br label %sym_name_end_596
sym_name_oob_595:
  %t777 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t777
  br label %sym_name_end_596
sym_name_end_596:
  %t778 = phi i8* [ %t776, %sym_name_ok_594 ], [ %t777, %sym_name_oob_595 ]
  call i32 @ReleaseSemaphore(i8* %t769, i32 1, i32* null)
  call void @star_rc_release(i8* %t778)
  %t779 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.49, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t779, i8* %t778)
  %t780 = load i8*, i8** %t25
  %t781 = load i8*, i8** %t25
  call void @star_rc_retain(i8* %t781)
  %t782 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t783 = load i32, i32* %t782
  %t784 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.50, i64 0, i32 2, i64 0
  %t785 = call i1 @save__save_high_score(i8* %t780, i32 %t783, i8* %t784)
  store i32 4, i32* %t786
  br label %while_cond_597
while_cond_597:
  %t787 = load i32, i32* %t786
  %t788 = icmp sge i32 %t787, 0
  br i1 %t788, label %while_body_598, label %while_else_599
while_body_598:
  %t789 = load i32, i32* %t786
  %t790 = icmp eq i32 %t789, 0
  br i1 %t790, label %logic_short_602, label %logic_rhs_601
logic_rhs_601:
  %t791 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t792 = load i32, i32* %t791
  %t793 = load i32, i32* %t786
  %t794 = sub i32 %t793, 1
  %t795 = sext i32 %t794 to i64
  %t796 = icmp ult i64 %t795, 5
  br i1 %t796, label %arr_rplace_ok_604, label %arr_rplace_oob_605
arr_rplace_ok_604:
  %t797 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t795
  br label %arr_rplace_end_606
arr_rplace_oob_605:
  store i32 0, i32* %t798
  br label %arr_rplace_end_606
arr_rplace_end_606:
  %t799 = phi i32* [ %t797, %arr_rplace_ok_604 ], [ %t798, %arr_rplace_oob_605 ]
  %t800 = load i32, i32* %t799
  %t801 = icmp sle i32 %t792, %t800
  br label %logic_end_603
logic_short_602:
  br label %logic_end_603
logic_end_603:
  %t802 = phi i1 [ %t801, %arr_rplace_end_606 ], [ true, %logic_short_602 ]
  br i1 %t802, label %if_then_607, label %if_else_608
if_then_607:
  %t803 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t804 = load i32, i32* %t803
  %t805 = load i32, i32* %t786
  %t806 = sext i32 %t805 to i64
  %t807 = icmp ult i64 %t806, 5
  br i1 %t807, label %arr_set_do_610, label %arr_set_oob_611
arr_set_do_610:
  %t808 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t806
  store i32 %t804, i32* %t808
  br label %arr_set_end_612
arr_set_oob_611:
  br label %arr_set_end_612
arr_set_end_612:
  br label %while_end_600
if_else_608:
  br label %if_end_609
if_end_609:
  %t809 = load i32, i32* %t786
  %t810 = sub i32 %t809, 1
  %t811 = sext i32 %t810 to i64
  %t812 = icmp ult i64 %t811, 5
  br i1 %t812, label %arr_rplace_ok_613, label %arr_rplace_oob_614
arr_rplace_ok_613:
  %t813 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t811
  br label %arr_rplace_end_615
arr_rplace_oob_614:
  store i32 0, i32* %t814
  br label %arr_rplace_end_615
arr_rplace_end_615:
  %t815 = phi i32* [ %t813, %arr_rplace_ok_613 ], [ %t814, %arr_rplace_oob_614 ]
  %t816 = load i32, i32* %t815
  %t817 = load i32, i32* %t786
  %t818 = sext i32 %t817 to i64
  %t819 = icmp ult i64 %t818, 5
  br i1 %t819, label %arr_set_do_616, label %arr_set_oob_617
arr_set_do_616:
  %t820 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t818
  store i32 %t816, i32* %t820
  br label %arr_set_end_618
arr_set_oob_617:
  br label %arr_set_end_618
arr_set_end_618:
  %t821 = load i32, i32* %t786
  %t822 = sub i32 %t821, 1
  store i32 %t822, i32* %t786
  br label %while_cond_597
while_else_599:
  br label %while_end_600
while_end_600:
  %t823 = sext i32 0 to i64
  %t824 = icmp ult i64 %t823, 5
  br i1 %t824, label %arr_rplace_ok_619, label %arr_rplace_oob_620
arr_rplace_ok_619:
  %t825 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t823
  br label %arr_rplace_end_621
arr_rplace_oob_620:
  store i32 0, i32* %t826
  br label %arr_rplace_end_621
arr_rplace_end_621:
  %t827 = phi i32* [ %t825, %arr_rplace_ok_619 ], [ %t826, %arr_rplace_oob_620 ]
  %t828 = load i32, i32* %t827
  %t829 = sext i32 1 to i64
  %t830 = icmp ult i64 %t829, 5
  br i1 %t830, label %arr_rplace_ok_622, label %arr_rplace_oob_623
arr_rplace_ok_622:
  %t831 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t829
  br label %arr_rplace_end_624
arr_rplace_oob_623:
  store i32 0, i32* %t832
  br label %arr_rplace_end_624
arr_rplace_end_624:
  %t833 = phi i32* [ %t831, %arr_rplace_ok_622 ], [ %t832, %arr_rplace_oob_623 ]
  %t834 = load i32, i32* %t833
  %t835 = sext i32 2 to i64
  %t836 = icmp ult i64 %t835, 5
  br i1 %t836, label %arr_rplace_ok_625, label %arr_rplace_oob_626
arr_rplace_ok_625:
  %t837 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t835
  br label %arr_rplace_end_627
arr_rplace_oob_626:
  store i32 0, i32* %t838
  br label %arr_rplace_end_627
arr_rplace_end_627:
  %t839 = phi i32* [ %t837, %arr_rplace_ok_625 ], [ %t838, %arr_rplace_oob_626 ]
  %t840 = load i32, i32* %t839
  %t841 = sext i32 3 to i64
  %t842 = icmp ult i64 %t841, 5
  br i1 %t842, label %arr_rplace_ok_628, label %arr_rplace_oob_629
arr_rplace_ok_628:
  %t843 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t841
  br label %arr_rplace_end_630
arr_rplace_oob_629:
  store i32 0, i32* %t844
  br label %arr_rplace_end_630
arr_rplace_end_630:
  %t845 = phi i32* [ %t843, %arr_rplace_ok_628 ], [ %t844, %arr_rplace_oob_629 ]
  %t846 = load i32, i32* %t845
  %t847 = sext i32 4 to i64
  %t848 = icmp ult i64 %t847, 5
  br i1 %t848, label %arr_rplace_ok_631, label %arr_rplace_oob_632
arr_rplace_ok_631:
  %t849 = getelementptr inbounds [5 x i32], [5 x i32]* %t61, i32 0, i64 %t847
  br label %arr_rplace_end_633
arr_rplace_oob_632:
  store i32 0, i32* %t850
  br label %arr_rplace_end_633
arr_rplace_end_633:
  %t851 = phi i32* [ %t849, %arr_rplace_ok_631 ], [ %t850, %arr_rplace_oob_632 ]
  %t852 = load i32, i32* %t851
  %t853 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t853, i32 %t828, i32 %t834, i32 %t840, i32 %t846, i32 %t852)
  %t856 = load i8*, i8** %t6
  %t857 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t855, i32 0, i32 0
  store i8* %t856, i8** %t857
  %t858 = getelementptr inbounds %GameOverFlash, %GameOverFlash* %t855, i32 0, i32 1
  store i32 0, i32* %t858
  %t859 = load %GameOverFlash, %GameOverFlash* %t855
  store %GameOverFlash %t859, %GameOverFlash* %t854
  store i1 true, i1* %t860
  br label %while_cond_634
while_cond_634:
  %t861 = load i1, i1* %t860
  br i1 %t861, label %while_body_635, label %while_else_636
while_body_635:
  %t862 = call i1 @GameOverFlash__resume(%GameOverFlash* %t854)
  store i1 %t862, i1* %t860
  br label %while_cond_634
while_else_636:
  br label %while_end_637
while_end_637:
  br label %if_end_563
if_else_562:
  br label %if_end_563
if_end_563:
  br label %if_end_473
if_else_472:
  br label %if_end_473
if_end_473:
  br label %if_end_412
if_end_412:
  %t863 = load i8, i8* %t59
  %t864 = trunc i32 1 to i8
  %t865 = add i8 %t863, %t864
  store i8 %t865, i8* %t59
  %t867 = load i8, i8* %t59
  %t868 = uitofp i8 %t867 to float
  store float %t868, float* %t866
  %t870 = load float, float* %t866
  %t871 = fmul float %t870, 0x3FC3333340000000
  %t872 = call float @llvm.sin.f32(float %t871)
  %t873 = fmul float %t872, 0x4000000000000000
  store float %t873, float* %t869
  %t874 = load i8*, i8** %t6
  %t875 = icmp eq i8* %t874, null
  br i1 %t875, label %sdl_null_window_638, label %sdl_window_handle_ok_639
sdl_null_window_638:
  %t876 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.52, i64 0, i64 0
  call i32 @puts(i8* %t876)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_639:
  %t877 = call i8* @SDL_GetRenderer(i8* %t874)
  %t878 = and i32 18, 255
  %t879 = and i32 18, 255
  %t880 = shl i32 %t879, 8
  %t881 = or i32 %t878, %t880
  %t882 = and i32 24, 255
  %t883 = shl i32 %t882, 16
  %t884 = or i32 %t881, %t883
  %t885 = and i32 255, 255
  %t886 = shl i32 %t885, 24
  %t887 = or i32 %t884, %t886
  %t888 = and i32 %t887, 255
  %t889 = trunc i32 %t888 to i8
  %t890 = lshr i32 %t887, 8
  %t891 = and i32 %t890, 255
  %t892 = trunc i32 %t891 to i8
  %t893 = lshr i32 %t887, 16
  %t894 = and i32 %t893, 255
  %t895 = trunc i32 %t894 to i8
  %t896 = lshr i32 %t887, 24
  %t897 = and i32 %t896, 255
  %t898 = trunc i32 %t897 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t877, i8 %t889, i8 %t892, i8 %t895, i8 %t898)
  call i32 @SDL_RenderClear(i8* %t877)
  %t900 = load %grid__Cell, %grid__Cell* %t51
  %t901 = call { i32, i32 } @cell_px(%grid__Cell %t900)
  store { i32, i32 } %t901, { i32, i32 }* %t899
  %t903 = load float, float* %t869
  %t904 = call i32 @llvm.fptosi.sat.i32.f32(float %t903)
  store i32 %t904, i32* %t902
  %t905 = load i8*, i8** %t6
  %t906 = icmp eq i8* %t905, null
  br i1 %t906, label %sdl_null_window_640, label %sdl_window_handle_ok_641
sdl_null_window_640:
  %t907 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.53, i64 0, i64 0
  call i32 @puts(i8* %t907)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_641:
  %t908 = call i8* @SDL_GetRenderer(i8* %t905)
  %t909 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t899, i32 0, i32 0
  %t910 = load i32, i32* %t909
  %t911 = load i32, i32* %t902
  %t912 = sub i32 %t910, %t911
  %t913 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t899, i32 0, i32 1
  %t914 = load i32, i32* %t913
  %t915 = load i32, i32* %t902
  %t916 = sub i32 %t914, %t915
  %t917 = sub i32 20, 1
  %t918 = load i32, i32* %t902
  %t919 = mul i32 %t918, 2
  %t920 = add i32 %t917, %t919
  %t921 = sub i32 20, 1
  %t922 = load i32, i32* %t902
  %t923 = mul i32 %t922, 2
  %t924 = add i32 %t921, %t923
  %t925 = and i32 230, 255
  %t926 = and i32 90, 255
  %t927 = shl i32 %t926, 8
  %t928 = or i32 %t925, %t927
  %t929 = and i32 90, 255
  %t930 = shl i32 %t929, 16
  %t931 = or i32 %t928, %t930
  %t932 = and i32 255, 255
  %t933 = shl i32 %t932, 24
  %t934 = or i32 %t931, %t933
  %t935 = and i32 %t934, 255
  %t936 = trunc i32 %t935 to i8
  %t937 = lshr i32 %t934, 8
  %t938 = and i32 %t937, 255
  %t939 = trunc i32 %t938 to i8
  %t940 = lshr i32 %t934, 16
  %t941 = and i32 %t940, 255
  %t942 = trunc i32 %t941 to i8
  %t943 = lshr i32 %t934, 24
  %t944 = and i32 %t943, 255
  %t945 = trunc i32 %t944 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t908, i8 %t936, i8 %t939, i8 %t942, i8 %t945)
  %t947 = getelementptr inbounds [16 x i8], [16 x i8]* %t946, i64 0, i64 0
  %t948 = bitcast i8* %t947 to i32*
  store i32 %t912, i32* %t948
  %t949 = getelementptr inbounds i8, i8* %t947, i64 4
  %t950 = bitcast i8* %t949 to i32*
  store i32 %t916, i32* %t950
  %t951 = getelementptr inbounds i8, i8* %t947, i64 8
  %t952 = bitcast i8* %t951 to i32*
  store i32 %t920, i32* %t952
  %t953 = getelementptr inbounds i8, i8* %t947, i64 12
  %t954 = bitcast i8* %t953 to i32*
  store i32 %t924, i32* %t954
  call i32 @SDL_RenderFillRect(i8* %t908, i8* %t947)
  store i32 0, i32* %t955
  br label %while_cond_642
while_cond_642:
  %t956 = load i32, i32* %t955
  %t957 = call i32 @sb__Snake__length(%sb__Snake* %t49)
  %t958 = icmp slt i32 %t956, %t957
  br i1 %t958, label %while_body_643, label %while_else_644
while_body_643:
  %t960 = load i32, i32* %t955
  %t961 = call i32 @sb__Snake__length(%sb__Snake* %t49)
  %t962 = sub i32 %t961, 1
  %t963 = icmp eq i32 %t960, %t962
  store i1 %t963, i1* %t959
  %t964 = load i8*, i8** %t6
  %t965 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 0
  %t966 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t965, i32 0, i32 0
  %t967 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t965, i32 0, i32 1
  %t968 = load i64, i64* %t967
  %t969 = getelementptr inbounds { [768 x %grid__Cell], i64, i64 }, { [768 x %grid__Cell], i64, i64 }* %t965, i32 0, i32 2
  %t970 = load i64, i64* %t969
  %t971 = load i32, i32* %t955
  %t972 = sext i32 %t971 to i64
  %t973 = load i64, i64* %t967
  %t974 = load i64, i64* %t969
  %t975 = icmp ult i64 %t972, %t974
  br i1 %t975, label %ring_rplace_ok_646, label %ring_rplace_oob_647
ring_rplace_ok_646:
  %t976 = add i64 %t973, %t972
  %t977 = urem i64 %t976, 768
  %t978 = getelementptr inbounds [768 x %grid__Cell], [768 x %grid__Cell]* %t966, i32 0, i64 %t977
  br label %ring_rplace_end_648
ring_rplace_oob_647:
  store %grid__Cell zeroinitializer, %grid__Cell* %t979
  br label %ring_rplace_end_648
ring_rplace_end_648:
  %t980 = phi %grid__Cell* [ %t978, %ring_rplace_ok_646 ], [ %t979, %ring_rplace_oob_647 ]
  %t981 = load %grid__Cell, %grid__Cell* %t980
  %t982 = load i1, i1* %t959
  %t983 = and i32 140, 255
  %t984 = and i32 230, 255
  %t985 = shl i32 %t984, 8
  %t986 = or i32 %t983, %t985
  %t987 = and i32 160, 255
  %t988 = shl i32 %t987, 16
  %t989 = or i32 %t986, %t988
  %t990 = and i32 255, 255
  %t991 = shl i32 %t990, 24
  %t992 = or i32 %t989, %t991
  %t993 = and i32 80, 255
  %t994 = and i32 190, 255
  %t995 = shl i32 %t994, 8
  %t996 = or i32 %t993, %t995
  %t997 = and i32 120, 255
  %t998 = shl i32 %t997, 16
  %t999 = or i32 %t996, %t998
  %t1000 = and i32 255, 255
  %t1001 = shl i32 %t1000, 24
  %t1002 = or i32 %t999, %t1001
  %t1003 = call i32 @pick_color(i1 %t982, i32 %t992, i32 %t1002)
  call void @draw_cell(i8* %t964, %grid__Cell %t981, i32 %t1003)
  %t1004 = load i32, i32* %t955
  %t1005 = add i32 %t1004, 1
  store i32 %t1005, i32* %t955
  br label %while_cond_642
while_else_644:
  br label %while_end_645
while_end_645:
  call void @tick_particle_arena(float 0x3F90624DE0000000)
  %t1006 = load i8*, i8** %t6
  call void @draw_particle_arena(i8* %t1006)
  call void @reclaim_dead_particles()
  %t1007 = load i8*, i8** %t6
  %t1008 = icmp eq i8* %t1007, null
  br i1 %t1008, label %sdl_null_window_649, label %sdl_window_handle_ok_650
sdl_null_window_649:
  %t1009 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.54, i64 0, i64 0
  call i32 @puts(i8* %t1009)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_650:
  %t1010 = load i8*, i8** %t23
  %t1011 = icmp eq i8* %t1010, null
  br i1 %t1011, label %font_null_handle_651, label %font_handle_ok_652
font_null_handle_651:
  %t1012 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.55, i64 0, i64 0
  call i32 @puts(i8* %t1012)
  call void @exit(i32 1)
  unreachable
font_handle_ok_652:
  %t1013 = call i8* @SDL_GetRenderer(i8* %t1007)
  %t1014 = and i32 240, 255
  %t1015 = and i32 240, 255
  %t1016 = shl i32 %t1015, 8
  %t1017 = or i32 %t1014, %t1016
  %t1018 = and i32 245, 255
  %t1019 = shl i32 %t1018, 16
  %t1020 = or i32 %t1017, %t1019
  %t1021 = and i32 255, 255
  %t1022 = shl i32 %t1021, 24
  %t1023 = or i32 %t1020, %t1022
  %t1024 = and i32 %t1023, 255
  %t1025 = trunc i32 %t1024 to i8
  %t1026 = lshr i32 %t1023, 8
  %t1027 = and i32 %t1026, 255
  %t1028 = trunc i32 %t1027 to i8
  %t1029 = lshr i32 %t1023, 16
  %t1030 = and i32 %t1029, 255
  %t1031 = trunc i32 %t1030 to i8
  %t1032 = lshr i32 %t1023, 24
  %t1033 = and i32 %t1032, 255
  %t1034 = trunc i32 %t1033 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1013, i8 %t1025, i8 %t1028, i8 %t1031, i8 %t1034)
  %t1035 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t1036 = load i32, i32* %t1035
  %t1037 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.56, i64 0, i64 0
  %t1038 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t1037, i32 %t1036)
  %t1039 = add i32 %t1038, 1
  %t1040 = sext i32 %t1039 to i64
  %t1041 = call i8* @star_rc_alloc(i64 %t1040, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t1041, i64 %t1040, i8* %t1037, i32 %t1036)
  %t1042 = icmp sgt i32 2, 0
  %t1043 = select i1 %t1042, i32 2, i32 1
  %t1044 = load i8, i8* %t1010
  %t1045 = zext i8 %t1044 to i32
  %t1046 = getelementptr inbounds i8, i8* %t1010, i64 1
  %t1047 = load i8, i8* %t1046
  %t1048 = zext i8 %t1047 to i32
  %t1049 = getelementptr inbounds i8, i8* %t1010, i64 2
  %t1050 = load i8, i8* %t1049
  %t1051 = zext i8 %t1050 to i32
  %t1052 = getelementptr inbounds i8, i8* %t1010, i64 3
  %t1053 = load i8, i8* %t1052
  %t1054 = zext i8 %t1053 to i32
  %t1055 = add i32 %t1045, 1
  %t1056 = mul i32 %t1055, %t1043
  %t1057 = add i32 %t1048, 1
  %t1058 = mul i32 %t1057, %t1043
  store i32 6, i32* %t1059
  store i32 6, i32* %t1060
  store i64 0, i64* %t1061
  br label %draw_text_cond_653
draw_text_cond_653:
  %t1062 = load i64, i64* %t1061
  %t1063 = getelementptr inbounds i8, i8* %t1041, i64 %t1062
  %t1064 = load i8, i8* %t1063
  %t1065 = icmp eq i8 %t1064, 0
  br i1 %t1065, label %draw_text_end_659, label %draw_text_body_654
draw_text_body_654:
  %t1066 = zext i8 %t1064 to i32
  %t1067 = icmp eq i32 %t1066, 10
  br i1 %t1067, label %draw_text_newline_655, label %draw_text_glyph_656
draw_text_newline_655:
  store i32 6, i32* %t1059
  %t1068 = load i32, i32* %t1060
  %t1069 = add i32 %t1068, %t1058
  store i32 %t1069, i32* %t1060
  %t1070 = add i64 %t1062, 1
  store i64 %t1070, i64* %t1061
  br label %draw_text_cond_653
draw_text_glyph_656:
  %t1071 = icmp sge i32 %t1066, 97
  %t1072 = icmp sle i32 %t1066, 122
  %t1073 = and i1 %t1071, %t1072
  %t1074 = sub i32 %t1066, 32
  %t1075 = select i1 %t1073, i32 %t1074, i32 %t1066
  %t1076 = sub i32 %t1075, %t1051
  %t1077 = icmp sge i32 %t1076, 0
  %t1078 = icmp slt i32 %t1076, %t1054
  %t1079 = and i1 %t1077, %t1078
  br i1 %t1079, label %draw_text_draw_glyph_657, label %draw_text_advance_658
draw_text_draw_glyph_657:
  %t1080 = mul i32 %t1076, %t1048
  %t1081 = add i32 %t1080, 4
  %t1082 = sext i32 %t1081 to i64
  %t1083 = load i32, i32* %t1059
  %t1084 = load i32, i32* %t1060
  store i32 0, i32* %t1085
  br label %draw_text_row_cond_660
draw_text_row_cond_660:
  %t1086 = load i32, i32* %t1085
  %t1087 = icmp slt i32 %t1086, %t1048
  br i1 %t1087, label %draw_text_row_body_661, label %draw_text_row_end_662
draw_text_row_body_661:
  %t1088 = sext i32 %t1086 to i64
  %t1089 = add i64 %t1082, %t1088
  %t1090 = getelementptr inbounds i8, i8* %t1010, i64 %t1089
  %t1091 = load i8, i8* %t1090
  %t1092 = zext i8 %t1091 to i32
  store i32 0, i32* %t1093
  br label %draw_text_col_cond_663
draw_text_col_cond_663:
  %t1094 = load i32, i32* %t1093
  %t1095 = icmp slt i32 %t1094, %t1045
  br i1 %t1095, label %draw_text_col_body_664, label %draw_text_col_end_665
draw_text_col_body_664:
  %t1096 = sub i32 %t1045, 1
  %t1097 = sub i32 %t1096, %t1094
  %t1098 = and i32 %t1097, 31
  %t1099 = lshr i32 %t1092, %t1098
  %t1100 = and i32 %t1099, 1
  %t1101 = icmp ne i32 %t1100, 0
  br i1 %t1101, label %draw_text_pixel_666, label %draw_text_after_pixel_667
draw_text_pixel_666:
  %t1102 = mul i32 %t1094, %t1043
  %t1103 = add i32 %t1083, %t1102
  %t1104 = mul i32 %t1086, %t1043
  %t1105 = add i32 %t1084, %t1104
  %t1107 = getelementptr inbounds [16 x i8], [16 x i8]* %t1106, i64 0, i64 0
  %t1108 = bitcast i8* %t1107 to i32*
  store i32 %t1103, i32* %t1108
  %t1109 = getelementptr inbounds i8, i8* %t1107, i64 4
  %t1110 = bitcast i8* %t1109 to i32*
  store i32 %t1105, i32* %t1110
  %t1111 = getelementptr inbounds i8, i8* %t1107, i64 8
  %t1112 = bitcast i8* %t1111 to i32*
  store i32 %t1043, i32* %t1112
  %t1113 = getelementptr inbounds i8, i8* %t1107, i64 12
  %t1114 = bitcast i8* %t1113 to i32*
  store i32 %t1043, i32* %t1114
  call i32 @SDL_RenderFillRect(i8* %t1013, i8* %t1107)
  br label %draw_text_after_pixel_667
draw_text_after_pixel_667:
  %t1115 = add i32 %t1094, 1
  store i32 %t1115, i32* %t1093
  br label %draw_text_col_cond_663
draw_text_col_end_665:
  %t1116 = add i32 %t1086, 1
  store i32 %t1116, i32* %t1085
  br label %draw_text_row_cond_660
draw_text_row_end_662:
  br label %draw_text_advance_658
draw_text_advance_658:
  %t1117 = load i32, i32* %t1059
  %t1118 = add i32 %t1117, %t1056
  store i32 %t1118, i32* %t1059
  %t1119 = add i64 %t1062, 1
  store i64 %t1119, i64* %t1061
  br label %draw_text_cond_653
draw_text_end_659:
  call void @star_rc_release(i8* %t1041)
  %t1120 = load i8*, i8** %t6
  %t1121 = icmp eq i8* %t1120, null
  br i1 %t1121, label %sdl_null_window_668, label %sdl_window_handle_ok_669
sdl_null_window_668:
  %t1122 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.57, i64 0, i64 0
  call i32 @puts(i8* %t1122)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_669:
  %t1123 = load i8*, i8** %t23
  %t1124 = icmp eq i8* %t1123, null
  br i1 %t1124, label %font_null_handle_670, label %font_handle_ok_671
font_null_handle_670:
  %t1125 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.58, i64 0, i64 0
  call i32 @puts(i8* %t1125)
  call void @exit(i32 1)
  unreachable
font_handle_ok_671:
  %t1126 = call i8* @SDL_GetRenderer(i8* %t1120)
  %t1127 = and i32 190, 255
  %t1128 = and i32 190, 255
  %t1129 = shl i32 %t1128, 8
  %t1130 = or i32 %t1127, %t1129
  %t1131 = and i32 200, 255
  %t1132 = shl i32 %t1131, 16
  %t1133 = or i32 %t1130, %t1132
  %t1134 = and i32 255, 255
  %t1135 = shl i32 %t1134, 24
  %t1136 = or i32 %t1133, %t1135
  %t1137 = and i32 %t1136, 255
  %t1138 = trunc i32 %t1137 to i8
  %t1139 = lshr i32 %t1136, 8
  %t1140 = and i32 %t1139, 255
  %t1141 = trunc i32 %t1140 to i8
  %t1142 = lshr i32 %t1136, 16
  %t1143 = and i32 %t1142, 255
  %t1144 = trunc i32 %t1143 to i8
  %t1145 = lshr i32 %t1136, 24
  %t1146 = and i32 %t1145, 255
  %t1147 = trunc i32 %t1146 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1126, i8 %t1138, i8 %t1141, i8 %t1144, i8 %t1147)
  %t1148 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t1149 = load i32, i32* %t1148
  %t1150 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.59, i64 0, i64 0
  %t1151 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t1150, i32 %t1149)
  %t1152 = add i32 %t1151, 1
  %t1153 = sext i32 %t1152 to i64
  %t1154 = call i8* @star_rc_alloc(i64 %t1153, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t1154, i64 %t1153, i8* %t1150, i32 %t1149)
  %t1155 = icmp sgt i32 2, 0
  %t1156 = select i1 %t1155, i32 2, i32 1
  %t1157 = load i8, i8* %t1123
  %t1158 = zext i8 %t1157 to i32
  %t1159 = getelementptr inbounds i8, i8* %t1123, i64 1
  %t1160 = load i8, i8* %t1159
  %t1161 = zext i8 %t1160 to i32
  %t1162 = getelementptr inbounds i8, i8* %t1123, i64 2
  %t1163 = load i8, i8* %t1162
  %t1164 = zext i8 %t1163 to i32
  %t1165 = getelementptr inbounds i8, i8* %t1123, i64 3
  %t1166 = load i8, i8* %t1165
  %t1167 = zext i8 %t1166 to i32
  %t1168 = add i32 %t1158, 1
  %t1169 = mul i32 %t1168, %t1156
  %t1170 = add i32 %t1161, 1
  %t1171 = mul i32 %t1170, %t1156
  store i32 6, i32* %t1172
  store i32 24, i32* %t1173
  store i64 0, i64* %t1174
  br label %draw_text_cond_672
draw_text_cond_672:
  %t1175 = load i64, i64* %t1174
  %t1176 = getelementptr inbounds i8, i8* %t1154, i64 %t1175
  %t1177 = load i8, i8* %t1176
  %t1178 = icmp eq i8 %t1177, 0
  br i1 %t1178, label %draw_text_end_678, label %draw_text_body_673
draw_text_body_673:
  %t1179 = zext i8 %t1177 to i32
  %t1180 = icmp eq i32 %t1179, 10
  br i1 %t1180, label %draw_text_newline_674, label %draw_text_glyph_675
draw_text_newline_674:
  store i32 6, i32* %t1172
  %t1181 = load i32, i32* %t1173
  %t1182 = add i32 %t1181, %t1171
  store i32 %t1182, i32* %t1173
  %t1183 = add i64 %t1175, 1
  store i64 %t1183, i64* %t1174
  br label %draw_text_cond_672
draw_text_glyph_675:
  %t1184 = icmp sge i32 %t1179, 97
  %t1185 = icmp sle i32 %t1179, 122
  %t1186 = and i1 %t1184, %t1185
  %t1187 = sub i32 %t1179, 32
  %t1188 = select i1 %t1186, i32 %t1187, i32 %t1179
  %t1189 = sub i32 %t1188, %t1164
  %t1190 = icmp sge i32 %t1189, 0
  %t1191 = icmp slt i32 %t1189, %t1167
  %t1192 = and i1 %t1190, %t1191
  br i1 %t1192, label %draw_text_draw_glyph_676, label %draw_text_advance_677
draw_text_draw_glyph_676:
  %t1193 = mul i32 %t1189, %t1161
  %t1194 = add i32 %t1193, 4
  %t1195 = sext i32 %t1194 to i64
  %t1196 = load i32, i32* %t1172
  %t1197 = load i32, i32* %t1173
  store i32 0, i32* %t1198
  br label %draw_text_row_cond_679
draw_text_row_cond_679:
  %t1199 = load i32, i32* %t1198
  %t1200 = icmp slt i32 %t1199, %t1161
  br i1 %t1200, label %draw_text_row_body_680, label %draw_text_row_end_681
draw_text_row_body_680:
  %t1201 = sext i32 %t1199 to i64
  %t1202 = add i64 %t1195, %t1201
  %t1203 = getelementptr inbounds i8, i8* %t1123, i64 %t1202
  %t1204 = load i8, i8* %t1203
  %t1205 = zext i8 %t1204 to i32
  store i32 0, i32* %t1206
  br label %draw_text_col_cond_682
draw_text_col_cond_682:
  %t1207 = load i32, i32* %t1206
  %t1208 = icmp slt i32 %t1207, %t1158
  br i1 %t1208, label %draw_text_col_body_683, label %draw_text_col_end_684
draw_text_col_body_683:
  %t1209 = sub i32 %t1158, 1
  %t1210 = sub i32 %t1209, %t1207
  %t1211 = and i32 %t1210, 31
  %t1212 = lshr i32 %t1205, %t1211
  %t1213 = and i32 %t1212, 1
  %t1214 = icmp ne i32 %t1213, 0
  br i1 %t1214, label %draw_text_pixel_685, label %draw_text_after_pixel_686
draw_text_pixel_685:
  %t1215 = mul i32 %t1207, %t1156
  %t1216 = add i32 %t1196, %t1215
  %t1217 = mul i32 %t1199, %t1156
  %t1218 = add i32 %t1197, %t1217
  %t1220 = getelementptr inbounds [16 x i8], [16 x i8]* %t1219, i64 0, i64 0
  %t1221 = bitcast i8* %t1220 to i32*
  store i32 %t1216, i32* %t1221
  %t1222 = getelementptr inbounds i8, i8* %t1220, i64 4
  %t1223 = bitcast i8* %t1222 to i32*
  store i32 %t1218, i32* %t1223
  %t1224 = getelementptr inbounds i8, i8* %t1220, i64 8
  %t1225 = bitcast i8* %t1224 to i32*
  store i32 %t1156, i32* %t1225
  %t1226 = getelementptr inbounds i8, i8* %t1220, i64 12
  %t1227 = bitcast i8* %t1226 to i32*
  store i32 %t1156, i32* %t1227
  call i32 @SDL_RenderFillRect(i8* %t1126, i8* %t1220)
  br label %draw_text_after_pixel_686
draw_text_after_pixel_686:
  %t1228 = add i32 %t1207, 1
  store i32 %t1228, i32* %t1206
  br label %draw_text_col_cond_682
draw_text_col_end_684:
  %t1229 = add i32 %t1199, 1
  store i32 %t1229, i32* %t1198
  br label %draw_text_row_cond_679
draw_text_row_end_681:
  br label %draw_text_advance_677
draw_text_advance_677:
  %t1230 = load i32, i32* %t1172
  %t1231 = add i32 %t1230, %t1169
  store i32 %t1231, i32* %t1172
  %t1232 = add i64 %t1175, 1
  store i64 %t1232, i64* %t1174
  br label %draw_text_cond_672
draw_text_end_678:
  call void @star_rc_release(i8* %t1154)
  %t1233 = load i64, i64* %t56
  %t1234 = zext i32 0 to i64
  %t1235 = shl i64 1, %t1234
  %t1236 = and i64 %t1233, %t1235
  %t1237 = icmp ne i64 %t1236, 0
  br i1 %t1237, label %if_then_687, label %if_else_688
if_then_687:
  %t1239 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.60, i64 0, i32 2, i64 0
  store i8* %t1239, i8** %t1238
  %t1241 = load i8*, i8** %t23
  %t1242 = icmp eq i8* %t1241, null
  br i1 %t1242, label %font_null_handle_690, label %font_handle_ok_691
font_null_handle_690:
  %t1243 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.61, i64 0, i64 0
  call i32 @puts(i8* %t1243)
  call void @exit(i32 1)
  unreachable
font_handle_ok_691:
  %t1244 = load i8*, i8** %t1238
  %t1245 = load i8*, i8** %t1238
  call void @star_rc_retain(i8* %t1245)
  %t1246 = icmp sgt i32 3, 0
  %t1247 = select i1 %t1246, i32 3, i32 1
  %t1248 = load i8, i8* %t1241
  %t1249 = zext i8 %t1248 to i32
  %t1250 = getelementptr inbounds i8, i8* %t1241, i64 1
  %t1251 = load i8, i8* %t1250
  %t1252 = zext i8 %t1251 to i32
  %t1253 = getelementptr inbounds i8, i8* %t1241, i64 2
  %t1254 = load i8, i8* %t1253
  %t1255 = zext i8 %t1254 to i32
  %t1256 = getelementptr inbounds i8, i8* %t1241, i64 3
  %t1257 = load i8, i8* %t1256
  %t1258 = zext i8 %t1257 to i32
  %t1259 = add i32 %t1249, 1
  %t1260 = mul i32 %t1259, %t1247
  %t1261 = add i32 %t1252, 1
  %t1262 = mul i32 %t1261, %t1247
  store i32 0, i32* %t1263
  store i32 0, i32* %t1264
  store i32 1, i32* %t1265
  store i64 0, i64* %t1266
  br label %measure_text_cond_692
measure_text_cond_692:
  %t1267 = load i64, i64* %t1266
  %t1268 = getelementptr inbounds i8, i8* %t1244, i64 %t1267
  %t1269 = load i8, i8* %t1268
  %t1270 = icmp eq i8 %t1269, 0
  br i1 %t1270, label %measure_text_end_696, label %measure_text_body_693
measure_text_body_693:
  %t1271 = zext i8 %t1269 to i32
  %t1272 = icmp eq i32 %t1271, 10
  br i1 %t1272, label %measure_text_newline_694, label %measure_text_advance_695
measure_text_newline_694:
  %t1273 = load i32, i32* %t1263
  %t1274 = load i32, i32* %t1264
  %t1275 = icmp sgt i32 %t1273, %t1274
  %t1276 = select i1 %t1275, i32 %t1273, i32 %t1274
  store i32 %t1276, i32* %t1264
  store i32 0, i32* %t1263
  %t1277 = load i32, i32* %t1265
  %t1278 = add i32 %t1277, 1
  store i32 %t1278, i32* %t1265
  %t1279 = add i64 %t1267, 1
  store i64 %t1279, i64* %t1266
  br label %measure_text_cond_692
measure_text_advance_695:
  %t1280 = load i32, i32* %t1263
  %t1281 = add i32 %t1280, %t1260
  store i32 %t1281, i32* %t1263
  %t1282 = add i64 %t1267, 1
  store i64 %t1282, i64* %t1266
  br label %measure_text_cond_692
measure_text_end_696:
  call void @star_rc_release(i8* %t1244)
  %t1283 = load i32, i32* %t1263
  %t1284 = load i32, i32* %t1264
  %t1285 = icmp sgt i32 %t1283, %t1284
  %t1286 = select i1 %t1285, i32 %t1283, i32 %t1284
  %t1287 = load i32, i32* %t1265
  %t1288 = mul i32 %t1287, %t1262
  %t1289 = sub i32 %t1288, %t1247
  %t1291 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1290, i32 0, i32 0
  store i32 %t1286, i32* %t1291
  %t1292 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1290, i32 0, i32 1
  store i32 %t1289, i32* %t1292
  %t1293 = load { i32, i32 }, { i32, i32 }* %t1290
  store { i32, i32 } %t1293, { i32, i32 }* %t1240
  %t1294 = load i8*, i8** %t6
  %t1295 = icmp eq i8* %t1294, null
  br i1 %t1295, label %sdl_null_window_697, label %sdl_window_handle_ok_698
sdl_null_window_697:
  %t1296 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.62, i64 0, i64 0
  call i32 @puts(i8* %t1296)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_698:
  %t1297 = load i8*, i8** %t23
  %t1298 = icmp eq i8* %t1297, null
  br i1 %t1298, label %font_null_handle_699, label %font_handle_ok_700
font_null_handle_699:
  %t1299 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.63, i64 0, i64 0
  call i32 @puts(i8* %t1299)
  call void @exit(i32 1)
  unreachable
font_handle_ok_700:
  %t1300 = call i8* @SDL_GetRenderer(i8* %t1294)
  %t1301 = and i32 255, 255
  %t1302 = and i32 220, 255
  %t1303 = shl i32 %t1302, 8
  %t1304 = or i32 %t1301, %t1303
  %t1305 = and i32 90, 255
  %t1306 = shl i32 %t1305, 16
  %t1307 = or i32 %t1304, %t1306
  %t1308 = and i32 255, 255
  %t1309 = shl i32 %t1308, 24
  %t1310 = or i32 %t1307, %t1309
  %t1311 = and i32 %t1310, 255
  %t1312 = trunc i32 %t1311 to i8
  %t1313 = lshr i32 %t1310, 8
  %t1314 = and i32 %t1313, 255
  %t1315 = trunc i32 %t1314 to i8
  %t1316 = lshr i32 %t1310, 16
  %t1317 = and i32 %t1316, 255
  %t1318 = trunc i32 %t1317 to i8
  %t1319 = lshr i32 %t1310, 24
  %t1320 = and i32 %t1319, 255
  %t1321 = trunc i32 %t1320 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1300, i8 %t1312, i8 %t1315, i8 %t1318, i8 %t1321)
  %t1322 = load i8*, i8** %t1238
  %t1323 = load i8*, i8** %t1238
  call void @star_rc_retain(i8* %t1323)
  %t1324 = load i32, i32* %t2
  %t1325 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1240, i32 0, i32 0
  %t1326 = load i32, i32* %t1325
  %t1327 = sub i32 %t1324, %t1326
  %t1328 = icmp eq i32 2, 0
  %t1329 = icmp eq i32 %t1327, -2147483648
  %t1330 = icmp eq i32 2, -1
  %t1331 = and i1 %t1329, %t1330
  %t1332 = or i1 %t1328, %t1331
  br i1 %t1332, label %int_div_fail_701, label %int_div_ok_702
int_div_fail_701:
  %t1333 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.64, i64 0, i64 0
  call i32 @puts(i8* %t1333)
  call void @exit(i32 1)
  unreachable
int_div_ok_702:
  %t1334 = sdiv i32 %t1327, 2
  %t1335 = load i32, i32* %t4
  %t1336 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1240, i32 0, i32 1
  %t1337 = load i32, i32* %t1336
  %t1338 = sub i32 %t1335, %t1337
  %t1339 = icmp eq i32 2, 0
  %t1340 = icmp eq i32 %t1338, -2147483648
  %t1341 = icmp eq i32 2, -1
  %t1342 = and i1 %t1340, %t1341
  %t1343 = or i1 %t1339, %t1342
  br i1 %t1343, label %int_div_fail_703, label %int_div_ok_704
int_div_fail_703:
  %t1344 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.65, i64 0, i64 0
  call i32 @puts(i8* %t1344)
  call void @exit(i32 1)
  unreachable
int_div_ok_704:
  %t1345 = sdiv i32 %t1338, 2
  %t1346 = icmp sgt i32 3, 0
  %t1347 = select i1 %t1346, i32 3, i32 1
  %t1348 = load i8, i8* %t1297
  %t1349 = zext i8 %t1348 to i32
  %t1350 = getelementptr inbounds i8, i8* %t1297, i64 1
  %t1351 = load i8, i8* %t1350
  %t1352 = zext i8 %t1351 to i32
  %t1353 = getelementptr inbounds i8, i8* %t1297, i64 2
  %t1354 = load i8, i8* %t1353
  %t1355 = zext i8 %t1354 to i32
  %t1356 = getelementptr inbounds i8, i8* %t1297, i64 3
  %t1357 = load i8, i8* %t1356
  %t1358 = zext i8 %t1357 to i32
  %t1359 = add i32 %t1349, 1
  %t1360 = mul i32 %t1359, %t1347
  %t1361 = add i32 %t1352, 1
  %t1362 = mul i32 %t1361, %t1347
  store i32 %t1334, i32* %t1363
  store i32 %t1345, i32* %t1364
  store i64 0, i64* %t1365
  br label %draw_text_cond_705
draw_text_cond_705:
  %t1366 = load i64, i64* %t1365
  %t1367 = getelementptr inbounds i8, i8* %t1322, i64 %t1366
  %t1368 = load i8, i8* %t1367
  %t1369 = icmp eq i8 %t1368, 0
  br i1 %t1369, label %draw_text_end_711, label %draw_text_body_706
draw_text_body_706:
  %t1370 = zext i8 %t1368 to i32
  %t1371 = icmp eq i32 %t1370, 10
  br i1 %t1371, label %draw_text_newline_707, label %draw_text_glyph_708
draw_text_newline_707:
  store i32 %t1334, i32* %t1363
  %t1372 = load i32, i32* %t1364
  %t1373 = add i32 %t1372, %t1362
  store i32 %t1373, i32* %t1364
  %t1374 = add i64 %t1366, 1
  store i64 %t1374, i64* %t1365
  br label %draw_text_cond_705
draw_text_glyph_708:
  %t1375 = icmp sge i32 %t1370, 97
  %t1376 = icmp sle i32 %t1370, 122
  %t1377 = and i1 %t1375, %t1376
  %t1378 = sub i32 %t1370, 32
  %t1379 = select i1 %t1377, i32 %t1378, i32 %t1370
  %t1380 = sub i32 %t1379, %t1355
  %t1381 = icmp sge i32 %t1380, 0
  %t1382 = icmp slt i32 %t1380, %t1358
  %t1383 = and i1 %t1381, %t1382
  br i1 %t1383, label %draw_text_draw_glyph_709, label %draw_text_advance_710
draw_text_draw_glyph_709:
  %t1384 = mul i32 %t1380, %t1352
  %t1385 = add i32 %t1384, 4
  %t1386 = sext i32 %t1385 to i64
  %t1387 = load i32, i32* %t1363
  %t1388 = load i32, i32* %t1364
  store i32 0, i32* %t1389
  br label %draw_text_row_cond_712
draw_text_row_cond_712:
  %t1390 = load i32, i32* %t1389
  %t1391 = icmp slt i32 %t1390, %t1352
  br i1 %t1391, label %draw_text_row_body_713, label %draw_text_row_end_714
draw_text_row_body_713:
  %t1392 = sext i32 %t1390 to i64
  %t1393 = add i64 %t1386, %t1392
  %t1394 = getelementptr inbounds i8, i8* %t1297, i64 %t1393
  %t1395 = load i8, i8* %t1394
  %t1396 = zext i8 %t1395 to i32
  store i32 0, i32* %t1397
  br label %draw_text_col_cond_715
draw_text_col_cond_715:
  %t1398 = load i32, i32* %t1397
  %t1399 = icmp slt i32 %t1398, %t1349
  br i1 %t1399, label %draw_text_col_body_716, label %draw_text_col_end_717
draw_text_col_body_716:
  %t1400 = sub i32 %t1349, 1
  %t1401 = sub i32 %t1400, %t1398
  %t1402 = and i32 %t1401, 31
  %t1403 = lshr i32 %t1396, %t1402
  %t1404 = and i32 %t1403, 1
  %t1405 = icmp ne i32 %t1404, 0
  br i1 %t1405, label %draw_text_pixel_718, label %draw_text_after_pixel_719
draw_text_pixel_718:
  %t1406 = mul i32 %t1398, %t1347
  %t1407 = add i32 %t1387, %t1406
  %t1408 = mul i32 %t1390, %t1347
  %t1409 = add i32 %t1388, %t1408
  %t1411 = getelementptr inbounds [16 x i8], [16 x i8]* %t1410, i64 0, i64 0
  %t1412 = bitcast i8* %t1411 to i32*
  store i32 %t1407, i32* %t1412
  %t1413 = getelementptr inbounds i8, i8* %t1411, i64 4
  %t1414 = bitcast i8* %t1413 to i32*
  store i32 %t1409, i32* %t1414
  %t1415 = getelementptr inbounds i8, i8* %t1411, i64 8
  %t1416 = bitcast i8* %t1415 to i32*
  store i32 %t1347, i32* %t1416
  %t1417 = getelementptr inbounds i8, i8* %t1411, i64 12
  %t1418 = bitcast i8* %t1417 to i32*
  store i32 %t1347, i32* %t1418
  call i32 @SDL_RenderFillRect(i8* %t1300, i8* %t1411)
  br label %draw_text_after_pixel_719
draw_text_after_pixel_719:
  %t1419 = add i32 %t1398, 1
  store i32 %t1419, i32* %t1397
  br label %draw_text_col_cond_715
draw_text_col_end_717:
  %t1420 = add i32 %t1390, 1
  store i32 %t1420, i32* %t1389
  br label %draw_text_row_cond_712
draw_text_row_end_714:
  br label %draw_text_advance_710
draw_text_advance_710:
  %t1421 = load i32, i32* %t1363
  %t1422 = add i32 %t1421, %t1360
  store i32 %t1422, i32* %t1363
  %t1423 = add i64 %t1366, 1
  store i64 %t1423, i64* %t1365
  br label %draw_text_cond_705
draw_text_end_711:
  call void @star_rc_release(i8* %t1322)
  %t1424 = load i8*, i8** %t1238
  call void @star_rc_release(i8* %t1424)
  br label %if_end_689
if_else_688:
  br label %if_end_689
if_end_689:
  %t1425 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 4
  %t1426 = load i1, i1* %t1425
  %t1427 = xor i1 true, %t1426
  br i1 %t1427, label %if_then_720, label %if_else_721
if_then_720:
  %t1429 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.66, i64 0, i32 2, i64 0
  store i8* %t1429, i8** %t1428
  %t1431 = getelementptr inbounds { i64, i8*, [19 x i8] }, { i64, i8*, [19 x i8] }* @.str.67, i64 0, i32 2, i64 0
  store i8* %t1431, i8** %t1430
  %t1433 = load i8*, i8** %t23
  %t1434 = icmp eq i8* %t1433, null
  br i1 %t1434, label %font_null_handle_723, label %font_handle_ok_724
font_null_handle_723:
  %t1435 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.68, i64 0, i64 0
  call i32 @puts(i8* %t1435)
  call void @exit(i32 1)
  unreachable
font_handle_ok_724:
  %t1436 = load i8*, i8** %t1428
  %t1437 = load i8*, i8** %t1428
  call void @star_rc_retain(i8* %t1437)
  %t1438 = icmp sgt i32 3, 0
  %t1439 = select i1 %t1438, i32 3, i32 1
  %t1440 = load i8, i8* %t1433
  %t1441 = zext i8 %t1440 to i32
  %t1442 = getelementptr inbounds i8, i8* %t1433, i64 1
  %t1443 = load i8, i8* %t1442
  %t1444 = zext i8 %t1443 to i32
  %t1445 = getelementptr inbounds i8, i8* %t1433, i64 2
  %t1446 = load i8, i8* %t1445
  %t1447 = zext i8 %t1446 to i32
  %t1448 = getelementptr inbounds i8, i8* %t1433, i64 3
  %t1449 = load i8, i8* %t1448
  %t1450 = zext i8 %t1449 to i32
  %t1451 = add i32 %t1441, 1
  %t1452 = mul i32 %t1451, %t1439
  %t1453 = add i32 %t1444, 1
  %t1454 = mul i32 %t1453, %t1439
  store i32 0, i32* %t1455
  store i32 0, i32* %t1456
  store i32 1, i32* %t1457
  store i64 0, i64* %t1458
  br label %measure_text_cond_725
measure_text_cond_725:
  %t1459 = load i64, i64* %t1458
  %t1460 = getelementptr inbounds i8, i8* %t1436, i64 %t1459
  %t1461 = load i8, i8* %t1460
  %t1462 = icmp eq i8 %t1461, 0
  br i1 %t1462, label %measure_text_end_729, label %measure_text_body_726
measure_text_body_726:
  %t1463 = zext i8 %t1461 to i32
  %t1464 = icmp eq i32 %t1463, 10
  br i1 %t1464, label %measure_text_newline_727, label %measure_text_advance_728
measure_text_newline_727:
  %t1465 = load i32, i32* %t1455
  %t1466 = load i32, i32* %t1456
  %t1467 = icmp sgt i32 %t1465, %t1466
  %t1468 = select i1 %t1467, i32 %t1465, i32 %t1466
  store i32 %t1468, i32* %t1456
  store i32 0, i32* %t1455
  %t1469 = load i32, i32* %t1457
  %t1470 = add i32 %t1469, 1
  store i32 %t1470, i32* %t1457
  %t1471 = add i64 %t1459, 1
  store i64 %t1471, i64* %t1458
  br label %measure_text_cond_725
measure_text_advance_728:
  %t1472 = load i32, i32* %t1455
  %t1473 = add i32 %t1472, %t1452
  store i32 %t1473, i32* %t1455
  %t1474 = add i64 %t1459, 1
  store i64 %t1474, i64* %t1458
  br label %measure_text_cond_725
measure_text_end_729:
  call void @star_rc_release(i8* %t1436)
  %t1475 = load i32, i32* %t1455
  %t1476 = load i32, i32* %t1456
  %t1477 = icmp sgt i32 %t1475, %t1476
  %t1478 = select i1 %t1477, i32 %t1475, i32 %t1476
  %t1479 = load i32, i32* %t1457
  %t1480 = mul i32 %t1479, %t1454
  %t1481 = sub i32 %t1480, %t1439
  %t1483 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1482, i32 0, i32 0
  store i32 %t1478, i32* %t1483
  %t1484 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1482, i32 0, i32 1
  store i32 %t1481, i32* %t1484
  %t1485 = load { i32, i32 }, { i32, i32 }* %t1482
  store { i32, i32 } %t1485, { i32, i32 }* %t1432
  %t1487 = load i8*, i8** %t23
  %t1488 = icmp eq i8* %t1487, null
  br i1 %t1488, label %font_null_handle_730, label %font_handle_ok_731
font_null_handle_730:
  %t1489 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.69, i64 0, i64 0
  call i32 @puts(i8* %t1489)
  call void @exit(i32 1)
  unreachable
font_handle_ok_731:
  %t1490 = load i8*, i8** %t1430
  %t1491 = load i8*, i8** %t1430
  call void @star_rc_retain(i8* %t1491)
  %t1492 = icmp sgt i32 2, 0
  %t1493 = select i1 %t1492, i32 2, i32 1
  %t1494 = load i8, i8* %t1487
  %t1495 = zext i8 %t1494 to i32
  %t1496 = getelementptr inbounds i8, i8* %t1487, i64 1
  %t1497 = load i8, i8* %t1496
  %t1498 = zext i8 %t1497 to i32
  %t1499 = getelementptr inbounds i8, i8* %t1487, i64 2
  %t1500 = load i8, i8* %t1499
  %t1501 = zext i8 %t1500 to i32
  %t1502 = getelementptr inbounds i8, i8* %t1487, i64 3
  %t1503 = load i8, i8* %t1502
  %t1504 = zext i8 %t1503 to i32
  %t1505 = add i32 %t1495, 1
  %t1506 = mul i32 %t1505, %t1493
  %t1507 = add i32 %t1498, 1
  %t1508 = mul i32 %t1507, %t1493
  store i32 0, i32* %t1509
  store i32 0, i32* %t1510
  store i32 1, i32* %t1511
  store i64 0, i64* %t1512
  br label %measure_text_cond_732
measure_text_cond_732:
  %t1513 = load i64, i64* %t1512
  %t1514 = getelementptr inbounds i8, i8* %t1490, i64 %t1513
  %t1515 = load i8, i8* %t1514
  %t1516 = icmp eq i8 %t1515, 0
  br i1 %t1516, label %measure_text_end_736, label %measure_text_body_733
measure_text_body_733:
  %t1517 = zext i8 %t1515 to i32
  %t1518 = icmp eq i32 %t1517, 10
  br i1 %t1518, label %measure_text_newline_734, label %measure_text_advance_735
measure_text_newline_734:
  %t1519 = load i32, i32* %t1509
  %t1520 = load i32, i32* %t1510
  %t1521 = icmp sgt i32 %t1519, %t1520
  %t1522 = select i1 %t1521, i32 %t1519, i32 %t1520
  store i32 %t1522, i32* %t1510
  store i32 0, i32* %t1509
  %t1523 = load i32, i32* %t1511
  %t1524 = add i32 %t1523, 1
  store i32 %t1524, i32* %t1511
  %t1525 = add i64 %t1513, 1
  store i64 %t1525, i64* %t1512
  br label %measure_text_cond_732
measure_text_advance_735:
  %t1526 = load i32, i32* %t1509
  %t1527 = add i32 %t1526, %t1506
  store i32 %t1527, i32* %t1509
  %t1528 = add i64 %t1513, 1
  store i64 %t1528, i64* %t1512
  br label %measure_text_cond_732
measure_text_end_736:
  call void @star_rc_release(i8* %t1490)
  %t1529 = load i32, i32* %t1509
  %t1530 = load i32, i32* %t1510
  %t1531 = icmp sgt i32 %t1529, %t1530
  %t1532 = select i1 %t1531, i32 %t1529, i32 %t1530
  %t1533 = load i32, i32* %t1511
  %t1534 = mul i32 %t1533, %t1508
  %t1535 = sub i32 %t1534, %t1493
  %t1537 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1536, i32 0, i32 0
  store i32 %t1532, i32* %t1537
  %t1538 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1536, i32 0, i32 1
  store i32 %t1535, i32* %t1538
  %t1539 = load { i32, i32 }, { i32, i32 }* %t1536
  store { i32, i32 } %t1539, { i32, i32 }* %t1486
  %t1541 = load i32, i32* %t4
  %t1542 = icmp eq i32 2, 0
  %t1543 = icmp eq i32 %t1541, -2147483648
  %t1544 = icmp eq i32 2, -1
  %t1545 = and i1 %t1543, %t1544
  %t1546 = or i1 %t1542, %t1545
  br i1 %t1546, label %int_div_fail_737, label %int_div_ok_738
int_div_fail_737:
  %t1547 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.70, i64 0, i64 0
  call i32 @puts(i8* %t1547)
  call void @exit(i32 1)
  unreachable
int_div_ok_738:
  %t1548 = sdiv i32 %t1541, 2
  %t1549 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1432, i32 0, i32 1
  %t1550 = load i32, i32* %t1549
  %t1551 = sub i32 %t1548, %t1550
  %t1552 = sub i32 %t1551, 6
  store i32 %t1552, i32* %t1540
  %t1553 = load i8*, i8** %t6
  %t1554 = icmp eq i8* %t1553, null
  br i1 %t1554, label %sdl_null_window_739, label %sdl_window_handle_ok_740
sdl_null_window_739:
  %t1555 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.71, i64 0, i64 0
  call i32 @puts(i8* %t1555)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_740:
  %t1556 = load i8*, i8** %t23
  %t1557 = icmp eq i8* %t1556, null
  br i1 %t1557, label %font_null_handle_741, label %font_handle_ok_742
font_null_handle_741:
  %t1558 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.72, i64 0, i64 0
  call i32 @puts(i8* %t1558)
  call void @exit(i32 1)
  unreachable
font_handle_ok_742:
  %t1559 = call i8* @SDL_GetRenderer(i8* %t1553)
  %t1560 = and i32 230, 255
  %t1561 = and i32 90, 255
  %t1562 = shl i32 %t1561, 8
  %t1563 = or i32 %t1560, %t1562
  %t1564 = and i32 90, 255
  %t1565 = shl i32 %t1564, 16
  %t1566 = or i32 %t1563, %t1565
  %t1567 = and i32 255, 255
  %t1568 = shl i32 %t1567, 24
  %t1569 = or i32 %t1566, %t1568
  %t1570 = and i32 %t1569, 255
  %t1571 = trunc i32 %t1570 to i8
  %t1572 = lshr i32 %t1569, 8
  %t1573 = and i32 %t1572, 255
  %t1574 = trunc i32 %t1573 to i8
  %t1575 = lshr i32 %t1569, 16
  %t1576 = and i32 %t1575, 255
  %t1577 = trunc i32 %t1576 to i8
  %t1578 = lshr i32 %t1569, 24
  %t1579 = and i32 %t1578, 255
  %t1580 = trunc i32 %t1579 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1559, i8 %t1571, i8 %t1574, i8 %t1577, i8 %t1580)
  %t1581 = load i8*, i8** %t1428
  %t1582 = load i8*, i8** %t1428
  call void @star_rc_retain(i8* %t1582)
  %t1583 = load i32, i32* %t2
  %t1584 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1432, i32 0, i32 0
  %t1585 = load i32, i32* %t1584
  %t1586 = sub i32 %t1583, %t1585
  %t1587 = icmp eq i32 2, 0
  %t1588 = icmp eq i32 %t1586, -2147483648
  %t1589 = icmp eq i32 2, -1
  %t1590 = and i1 %t1588, %t1589
  %t1591 = or i1 %t1587, %t1590
  br i1 %t1591, label %int_div_fail_743, label %int_div_ok_744
int_div_fail_743:
  %t1592 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.73, i64 0, i64 0
  call i32 @puts(i8* %t1592)
  call void @exit(i32 1)
  unreachable
int_div_ok_744:
  %t1593 = sdiv i32 %t1586, 2
  %t1594 = load i32, i32* %t1540
  %t1595 = icmp sgt i32 3, 0
  %t1596 = select i1 %t1595, i32 3, i32 1
  %t1597 = load i8, i8* %t1556
  %t1598 = zext i8 %t1597 to i32
  %t1599 = getelementptr inbounds i8, i8* %t1556, i64 1
  %t1600 = load i8, i8* %t1599
  %t1601 = zext i8 %t1600 to i32
  %t1602 = getelementptr inbounds i8, i8* %t1556, i64 2
  %t1603 = load i8, i8* %t1602
  %t1604 = zext i8 %t1603 to i32
  %t1605 = getelementptr inbounds i8, i8* %t1556, i64 3
  %t1606 = load i8, i8* %t1605
  %t1607 = zext i8 %t1606 to i32
  %t1608 = add i32 %t1598, 1
  %t1609 = mul i32 %t1608, %t1596
  %t1610 = add i32 %t1601, 1
  %t1611 = mul i32 %t1610, %t1596
  store i32 %t1593, i32* %t1612
  store i32 %t1594, i32* %t1613
  store i64 0, i64* %t1614
  br label %draw_text_cond_745
draw_text_cond_745:
  %t1615 = load i64, i64* %t1614
  %t1616 = getelementptr inbounds i8, i8* %t1581, i64 %t1615
  %t1617 = load i8, i8* %t1616
  %t1618 = icmp eq i8 %t1617, 0
  br i1 %t1618, label %draw_text_end_751, label %draw_text_body_746
draw_text_body_746:
  %t1619 = zext i8 %t1617 to i32
  %t1620 = icmp eq i32 %t1619, 10
  br i1 %t1620, label %draw_text_newline_747, label %draw_text_glyph_748
draw_text_newline_747:
  store i32 %t1593, i32* %t1612
  %t1621 = load i32, i32* %t1613
  %t1622 = add i32 %t1621, %t1611
  store i32 %t1622, i32* %t1613
  %t1623 = add i64 %t1615, 1
  store i64 %t1623, i64* %t1614
  br label %draw_text_cond_745
draw_text_glyph_748:
  %t1624 = icmp sge i32 %t1619, 97
  %t1625 = icmp sle i32 %t1619, 122
  %t1626 = and i1 %t1624, %t1625
  %t1627 = sub i32 %t1619, 32
  %t1628 = select i1 %t1626, i32 %t1627, i32 %t1619
  %t1629 = sub i32 %t1628, %t1604
  %t1630 = icmp sge i32 %t1629, 0
  %t1631 = icmp slt i32 %t1629, %t1607
  %t1632 = and i1 %t1630, %t1631
  br i1 %t1632, label %draw_text_draw_glyph_749, label %draw_text_advance_750
draw_text_draw_glyph_749:
  %t1633 = mul i32 %t1629, %t1601
  %t1634 = add i32 %t1633, 4
  %t1635 = sext i32 %t1634 to i64
  %t1636 = load i32, i32* %t1612
  %t1637 = load i32, i32* %t1613
  store i32 0, i32* %t1638
  br label %draw_text_row_cond_752
draw_text_row_cond_752:
  %t1639 = load i32, i32* %t1638
  %t1640 = icmp slt i32 %t1639, %t1601
  br i1 %t1640, label %draw_text_row_body_753, label %draw_text_row_end_754
draw_text_row_body_753:
  %t1641 = sext i32 %t1639 to i64
  %t1642 = add i64 %t1635, %t1641
  %t1643 = getelementptr inbounds i8, i8* %t1556, i64 %t1642
  %t1644 = load i8, i8* %t1643
  %t1645 = zext i8 %t1644 to i32
  store i32 0, i32* %t1646
  br label %draw_text_col_cond_755
draw_text_col_cond_755:
  %t1647 = load i32, i32* %t1646
  %t1648 = icmp slt i32 %t1647, %t1598
  br i1 %t1648, label %draw_text_col_body_756, label %draw_text_col_end_757
draw_text_col_body_756:
  %t1649 = sub i32 %t1598, 1
  %t1650 = sub i32 %t1649, %t1647
  %t1651 = and i32 %t1650, 31
  %t1652 = lshr i32 %t1645, %t1651
  %t1653 = and i32 %t1652, 1
  %t1654 = icmp ne i32 %t1653, 0
  br i1 %t1654, label %draw_text_pixel_758, label %draw_text_after_pixel_759
draw_text_pixel_758:
  %t1655 = mul i32 %t1647, %t1596
  %t1656 = add i32 %t1636, %t1655
  %t1657 = mul i32 %t1639, %t1596
  %t1658 = add i32 %t1637, %t1657
  %t1660 = getelementptr inbounds [16 x i8], [16 x i8]* %t1659, i64 0, i64 0
  %t1661 = bitcast i8* %t1660 to i32*
  store i32 %t1656, i32* %t1661
  %t1662 = getelementptr inbounds i8, i8* %t1660, i64 4
  %t1663 = bitcast i8* %t1662 to i32*
  store i32 %t1658, i32* %t1663
  %t1664 = getelementptr inbounds i8, i8* %t1660, i64 8
  %t1665 = bitcast i8* %t1664 to i32*
  store i32 %t1596, i32* %t1665
  %t1666 = getelementptr inbounds i8, i8* %t1660, i64 12
  %t1667 = bitcast i8* %t1666 to i32*
  store i32 %t1596, i32* %t1667
  call i32 @SDL_RenderFillRect(i8* %t1559, i8* %t1660)
  br label %draw_text_after_pixel_759
draw_text_after_pixel_759:
  %t1668 = add i32 %t1647, 1
  store i32 %t1668, i32* %t1646
  br label %draw_text_col_cond_755
draw_text_col_end_757:
  %t1669 = add i32 %t1639, 1
  store i32 %t1669, i32* %t1638
  br label %draw_text_row_cond_752
draw_text_row_end_754:
  br label %draw_text_advance_750
draw_text_advance_750:
  %t1670 = load i32, i32* %t1612
  %t1671 = add i32 %t1670, %t1609
  store i32 %t1671, i32* %t1612
  %t1672 = add i64 %t1615, 1
  store i64 %t1672, i64* %t1614
  br label %draw_text_cond_745
draw_text_end_751:
  call void @star_rc_release(i8* %t1581)
  %t1673 = load i8*, i8** %t6
  %t1674 = icmp eq i8* %t1673, null
  br i1 %t1674, label %sdl_null_window_760, label %sdl_window_handle_ok_761
sdl_null_window_760:
  %t1675 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.74, i64 0, i64 0
  call i32 @puts(i8* %t1675)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_761:
  %t1676 = load i8*, i8** %t23
  %t1677 = icmp eq i8* %t1676, null
  br i1 %t1677, label %font_null_handle_762, label %font_handle_ok_763
font_null_handle_762:
  %t1678 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.75, i64 0, i64 0
  call i32 @puts(i8* %t1678)
  call void @exit(i32 1)
  unreachable
font_handle_ok_763:
  %t1679 = call i8* @SDL_GetRenderer(i8* %t1673)
  %t1680 = and i32 230, 255
  %t1681 = and i32 230, 255
  %t1682 = shl i32 %t1681, 8
  %t1683 = or i32 %t1680, %t1682
  %t1684 = and i32 235, 255
  %t1685 = shl i32 %t1684, 16
  %t1686 = or i32 %t1683, %t1685
  %t1687 = and i32 255, 255
  %t1688 = shl i32 %t1687, 24
  %t1689 = or i32 %t1686, %t1688
  %t1690 = and i32 %t1689, 255
  %t1691 = trunc i32 %t1690 to i8
  %t1692 = lshr i32 %t1689, 8
  %t1693 = and i32 %t1692, 255
  %t1694 = trunc i32 %t1693 to i8
  %t1695 = lshr i32 %t1689, 16
  %t1696 = and i32 %t1695, 255
  %t1697 = trunc i32 %t1696 to i8
  %t1698 = lshr i32 %t1689, 24
  %t1699 = and i32 %t1698, 255
  %t1700 = trunc i32 %t1699 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1679, i8 %t1691, i8 %t1694, i8 %t1697, i8 %t1700)
  %t1701 = load i8*, i8** %t1430
  %t1702 = load i8*, i8** %t1430
  call void @star_rc_retain(i8* %t1702)
  %t1703 = load i32, i32* %t2
  %t1704 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1486, i32 0, i32 0
  %t1705 = load i32, i32* %t1704
  %t1706 = sub i32 %t1703, %t1705
  %t1707 = icmp eq i32 2, 0
  %t1708 = icmp eq i32 %t1706, -2147483648
  %t1709 = icmp eq i32 2, -1
  %t1710 = and i1 %t1708, %t1709
  %t1711 = or i1 %t1707, %t1710
  br i1 %t1711, label %int_div_fail_764, label %int_div_ok_765
int_div_fail_764:
  %t1712 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.76, i64 0, i64 0
  call i32 @puts(i8* %t1712)
  call void @exit(i32 1)
  unreachable
int_div_ok_765:
  %t1713 = sdiv i32 %t1706, 2
  %t1714 = load i32, i32* %t4
  %t1715 = icmp eq i32 2, 0
  %t1716 = icmp eq i32 %t1714, -2147483648
  %t1717 = icmp eq i32 2, -1
  %t1718 = and i1 %t1716, %t1717
  %t1719 = or i1 %t1715, %t1718
  br i1 %t1719, label %int_div_fail_766, label %int_div_ok_767
int_div_fail_766:
  %t1720 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.77, i64 0, i64 0
  call i32 @puts(i8* %t1720)
  call void @exit(i32 1)
  unreachable
int_div_ok_767:
  %t1721 = sdiv i32 %t1714, 2
  %t1722 = add i32 %t1721, 6
  %t1723 = icmp sgt i32 2, 0
  %t1724 = select i1 %t1723, i32 2, i32 1
  %t1725 = load i8, i8* %t1676
  %t1726 = zext i8 %t1725 to i32
  %t1727 = getelementptr inbounds i8, i8* %t1676, i64 1
  %t1728 = load i8, i8* %t1727
  %t1729 = zext i8 %t1728 to i32
  %t1730 = getelementptr inbounds i8, i8* %t1676, i64 2
  %t1731 = load i8, i8* %t1730
  %t1732 = zext i8 %t1731 to i32
  %t1733 = getelementptr inbounds i8, i8* %t1676, i64 3
  %t1734 = load i8, i8* %t1733
  %t1735 = zext i8 %t1734 to i32
  %t1736 = add i32 %t1726, 1
  %t1737 = mul i32 %t1736, %t1724
  %t1738 = add i32 %t1729, 1
  %t1739 = mul i32 %t1738, %t1724
  store i32 %t1713, i32* %t1740
  store i32 %t1722, i32* %t1741
  store i64 0, i64* %t1742
  br label %draw_text_cond_768
draw_text_cond_768:
  %t1743 = load i64, i64* %t1742
  %t1744 = getelementptr inbounds i8, i8* %t1701, i64 %t1743
  %t1745 = load i8, i8* %t1744
  %t1746 = icmp eq i8 %t1745, 0
  br i1 %t1746, label %draw_text_end_774, label %draw_text_body_769
draw_text_body_769:
  %t1747 = zext i8 %t1745 to i32
  %t1748 = icmp eq i32 %t1747, 10
  br i1 %t1748, label %draw_text_newline_770, label %draw_text_glyph_771
draw_text_newline_770:
  store i32 %t1713, i32* %t1740
  %t1749 = load i32, i32* %t1741
  %t1750 = add i32 %t1749, %t1739
  store i32 %t1750, i32* %t1741
  %t1751 = add i64 %t1743, 1
  store i64 %t1751, i64* %t1742
  br label %draw_text_cond_768
draw_text_glyph_771:
  %t1752 = icmp sge i32 %t1747, 97
  %t1753 = icmp sle i32 %t1747, 122
  %t1754 = and i1 %t1752, %t1753
  %t1755 = sub i32 %t1747, 32
  %t1756 = select i1 %t1754, i32 %t1755, i32 %t1747
  %t1757 = sub i32 %t1756, %t1732
  %t1758 = icmp sge i32 %t1757, 0
  %t1759 = icmp slt i32 %t1757, %t1735
  %t1760 = and i1 %t1758, %t1759
  br i1 %t1760, label %draw_text_draw_glyph_772, label %draw_text_advance_773
draw_text_draw_glyph_772:
  %t1761 = mul i32 %t1757, %t1729
  %t1762 = add i32 %t1761, 4
  %t1763 = sext i32 %t1762 to i64
  %t1764 = load i32, i32* %t1740
  %t1765 = load i32, i32* %t1741
  store i32 0, i32* %t1766
  br label %draw_text_row_cond_775
draw_text_row_cond_775:
  %t1767 = load i32, i32* %t1766
  %t1768 = icmp slt i32 %t1767, %t1729
  br i1 %t1768, label %draw_text_row_body_776, label %draw_text_row_end_777
draw_text_row_body_776:
  %t1769 = sext i32 %t1767 to i64
  %t1770 = add i64 %t1763, %t1769
  %t1771 = getelementptr inbounds i8, i8* %t1676, i64 %t1770
  %t1772 = load i8, i8* %t1771
  %t1773 = zext i8 %t1772 to i32
  store i32 0, i32* %t1774
  br label %draw_text_col_cond_778
draw_text_col_cond_778:
  %t1775 = load i32, i32* %t1774
  %t1776 = icmp slt i32 %t1775, %t1726
  br i1 %t1776, label %draw_text_col_body_779, label %draw_text_col_end_780
draw_text_col_body_779:
  %t1777 = sub i32 %t1726, 1
  %t1778 = sub i32 %t1777, %t1775
  %t1779 = and i32 %t1778, 31
  %t1780 = lshr i32 %t1773, %t1779
  %t1781 = and i32 %t1780, 1
  %t1782 = icmp ne i32 %t1781, 0
  br i1 %t1782, label %draw_text_pixel_781, label %draw_text_after_pixel_782
draw_text_pixel_781:
  %t1783 = mul i32 %t1775, %t1724
  %t1784 = add i32 %t1764, %t1783
  %t1785 = mul i32 %t1767, %t1724
  %t1786 = add i32 %t1765, %t1785
  %t1788 = getelementptr inbounds [16 x i8], [16 x i8]* %t1787, i64 0, i64 0
  %t1789 = bitcast i8* %t1788 to i32*
  store i32 %t1784, i32* %t1789
  %t1790 = getelementptr inbounds i8, i8* %t1788, i64 4
  %t1791 = bitcast i8* %t1790 to i32*
  store i32 %t1786, i32* %t1791
  %t1792 = getelementptr inbounds i8, i8* %t1788, i64 8
  %t1793 = bitcast i8* %t1792 to i32*
  store i32 %t1724, i32* %t1793
  %t1794 = getelementptr inbounds i8, i8* %t1788, i64 12
  %t1795 = bitcast i8* %t1794 to i32*
  store i32 %t1724, i32* %t1795
  call i32 @SDL_RenderFillRect(i8* %t1679, i8* %t1788)
  br label %draw_text_after_pixel_782
draw_text_after_pixel_782:
  %t1796 = add i32 %t1775, 1
  store i32 %t1796, i32* %t1774
  br label %draw_text_col_cond_778
draw_text_col_end_780:
  %t1797 = add i32 %t1767, 1
  store i32 %t1797, i32* %t1766
  br label %draw_text_row_cond_775
draw_text_row_end_777:
  br label %draw_text_advance_773
draw_text_advance_773:
  %t1798 = load i32, i32* %t1740
  %t1799 = add i32 %t1798, %t1737
  store i32 %t1799, i32* %t1740
  %t1800 = add i64 %t1743, 1
  store i64 %t1800, i64* %t1742
  br label %draw_text_cond_768
draw_text_end_774:
  call void @star_rc_release(i8* %t1701)
  %t1801 = load i8*, i8** %t1430
  call void @star_rc_release(i8* %t1801)
  %t1802 = load i8*, i8** %t1428
  call void @star_rc_release(i8* %t1802)
  br label %if_end_722
if_else_721:
  br label %if_end_722
if_end_722:
  %t1803 = load i64, i64* %t56
  %t1804 = zext i32 1 to i64
  %t1805 = shl i64 1, %t1804
  %t1806 = and i64 %t1803, %t1805
  %t1807 = icmp ne i64 %t1806, 0
  br i1 %t1807, label %if_then_783, label %if_else_784
if_then_783:
  %t1808 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t1809 = load i32, i32* %t1808
  %t1810 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t1811 = load i32, i32* %t1810
  %t1812 = call i32 @sb__Snake__length(%sb__Snake* %t49)
  %t1813 = load i64, i64* %t56
  %t1814 = zext i32 0 to i64
  %t1815 = shl i64 1, %t1814
  %t1816 = and i64 %t1813, %t1815
  %t1817 = icmp ne i64 %t1816, 0
  %t1818 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.78, i64 0, i64 0
  %t1819 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.79, i64 0, i64 0
  %t1820 = select i1 %t1817, i8* %t1818, i8* %t1819
  %t1821 = getelementptr inbounds %sb__Snake, %sb__Snake* %t49, i32 0, i32 1
  %t1822 = load i32, i32* %t1821
  %t1823 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.80, i64 0, i64 0
  %t1824 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.81, i64 0, i64 0
  %t1825 = icmp eq i32 %t1822, 2
  %t1826 = select i1 %t1825, i8* %t1824, i8* %t1823
  %t1827 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.82, i64 0, i64 0
  %t1828 = icmp eq i32 %t1822, 1
  %t1829 = select i1 %t1828, i8* %t1827, i8* %t1826
  %t1830 = getelementptr inbounds [3 x i8], [3 x i8]* @.str.83, i64 0, i64 0
  %t1831 = icmp eq i32 %t1822, 0
  %t1832 = select i1 %t1831, i8* %t1830, i8* %t1829
  %t1833 = load i1, i1* %t75
  %t1834 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.84, i64 0, i64 0
  %t1835 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.85, i64 0, i64 0
  %t1836 = select i1 %t1833, i8* %t1834, i8* %t1835
  %t1837 = getelementptr inbounds [59 x i8], [59 x i8]* @.str.86, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1837, i32 %t1809, i32 %t1811, i32 %t1812, i8* %t1820, i8* %t1832, i8* %t1836)
  br label %if_end_785
if_else_784:
  br label %if_end_785
if_end_785:
  %t1838 = load i8*, i8** %t6
  %t1839 = icmp eq i8* %t1838, null
  br i1 %t1839, label %sdl_null_window_786, label %sdl_window_handle_ok_787
sdl_null_window_786:
  %t1840 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.87, i64 0, i64 0
  call i32 @puts(i8* %t1840)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_787:
  %t1841 = call i8* @SDL_GetRenderer(i8* %t1838)
  call void @SDL_RenderPresent(i8* %t1841)
  %t1842 = icmp slt i32 16, 0
  %t1843 = select i1 %t1842, i32 0, i32 16
  call void @SDL_Delay(i32 %t1843)
  br label %while_cond_370
while_else_372:
  br label %while_end_373
while_end_373:
  %t1844 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 0
  %t1845 = load i32, i32* %t1844
  %t1846 = getelementptr inbounds %Stats, %Stats* %t31, i32 0, i32 1
  %t1847 = load i32, i32* %t1846
  %t1848 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.88, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1848, i32 %t1845, i32 %t1847)
  %t1849 = load i8, i8* %t57
  %t1850 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.89, i64 0, i64 0
  %t1851 = zext i8 %t1849 to i32
  call i32 (i8*, ...) @printf(i8* %t1850, i32 %t1851)
  %t1852 = load i8*, i8** %t6
  %t1853 = icmp eq i8* %t1852, null
  br i1 %t1853, label %sdl_null_window_788, label %sdl_window_handle_ok_789
sdl_null_window_788:
  %t1854 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.90, i64 0, i64 0
  call i32 @puts(i8* %t1854)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_789:
  %t1855 = call i8* @SDL_GetRenderer(i8* %t1852)
  call void @SDL_DestroyRenderer(i8* %t1855)
  call void @SDL_DestroyWindow(i8* %t1852)
  store i8* null, i8** %t6
  %t1856 = load i8*, i8** %t58
  call void @star_rc_release(i8* %t1856)
  %t1857 = getelementptr inbounds { i32, i8* }, { i32, i8* }* %t27, i32 0, i32 1
  %t1858 = load i8*, i8** %t1857
  call void @star_rc_release(i8* %t1858)
  %t1859 = load i8*, i8** %t25
  call void @star_rc_release(i8* %t1859)
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
  br label %par_cond_223
par_cond_223:
  %t10 = load i64, i64* %t9
  %t11 = icmp slt i64 %t10, %t5
  br i1 %t11, label %par_body_224, label %par_end_227
par_body_224:
  %t12 = getelementptr inbounds [256 x i64], [256 x i64]* @arena.Particles.gen, i64 0, i64 %t10
  %t13 = load i64, i64* %t12
  %t14 = and i64 %t13, 1
  %t15 = icmp eq i64 %t14, 1
  br i1 %t15, label %par_live_225, label %par_incr_226
par_live_225:
  %t16 = getelementptr inbounds %Particle, %Particle* %t8, i64 %t10
  %t17 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 4
  %t18 = load float, float* %t17
  %t19 = fcmp ogt float %t18, 0x0000000000000000
  br i1 %t19, label %if_then_228, label %if_else_229
if_then_228:
  %t20 = load float, float* %t7
  %t21 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 4
  %t22 = load float, float* %t21
  %t23 = fsub float %t22, %t20
  %t24 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 4
  store float %t23, float* %t24
  %t25 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 2
  %t26 = load float, float* %t25
  %t27 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 0
  %t28 = load float, float* %t27
  %t29 = fadd float %t28, %t26
  %t30 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 0
  store float %t29, float* %t30
  %t31 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 3
  %t32 = load float, float* %t31
  %t33 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 1
  %t34 = load float, float* %t33
  %t35 = fadd float %t34, %t32
  %t36 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 1
  store float %t35, float* %t36
  %t37 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 3
  %t38 = load float, float* %t37
  %t39 = fadd float %t38, 0x3FBEB851E0000000
  %t40 = getelementptr inbounds %Particle, %Particle* %t16, i32 0, i32 3
  store float %t39, float* %t40
  br label %if_end_230
if_else_229:
  br label %if_end_230
if_end_230:
  br label %par_incr_226
par_incr_226:
  %t41 = add i64 %t10, 1
  store i64 %t41, i64* %t9
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
  %t42 = ptrtoint i8* %idx_arg to i64
  %t43 = trunc i64 %t42 to i32
  %t44 = call i32 @GetCurrentThreadId()
  %t45 = getelementptr inbounds [4 x i32], [4 x i32]* @par.pool.tid, i32 0, i32 %t43
  store i32 %t44, i32* %t45
  br label %loop
loop:
  %t46 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 %t43
  %t47 = load i8*, i8** %t46
  %t48 = call i32 @WaitForSingleObject(i8* %t47, i32 -1)
  %t49 = getelementptr inbounds [4 x i32 (i8*)*], [4 x i32 (i8*)*]* @par.pool.job_fn, i32 0, i32 %t43
  %t50 = load i32 (i8*)*, i32 (i8*)** %t49
  %t51 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.job_arg, i32 0, i32 %t43
  %t52 = load i8*, i8** %t51
  %t53 = call i32 %t50(i8* %t52)
  %t54 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 %t43
  %t55 = load i8*, i8** %t54
  %t56 = call i32 @ReleaseSemaphore(i8* %t55, i32 1, i32* null)
  br label %loop
}

define void @par.pool.ensure_init() {
entry:
  %t57 = load i1, i1* @par.pool.inited
  br i1 %t57, label %par_pool_already, label %par_pool_init
par_pool_init:
  %t58 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t58, i8** @par.pool.serial_lock
  %t59 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t60 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 0
  store i8* %t59, i8** %t60
  %t61 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t62 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 0
  store i8* %t61, i8** %t62
  %t63 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 0 to i8*), i32 0, i32* null)
  %t64 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t65 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 1
  store i8* %t64, i8** %t65
  %t66 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t67 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 1
  store i8* %t66, i8** %t67
  %t68 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 1 to i8*), i32 0, i32* null)
  %t69 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t70 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 2
  store i8* %t69, i8** %t70
  %t71 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t72 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 2
  store i8* %t71, i8** %t72
  %t73 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 2 to i8*), i32 0, i32* null)
  %t74 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t75 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.start_sem, i32 0, i32 3
  store i8* %t74, i8** %t75
  %t76 = call i8* @CreateSemaphoreA(i8* null, i32 0, i32 1, i8* null)
  %t77 = getelementptr inbounds [4 x i8*], [4 x i8*]* @par.pool.done_sem, i32 0, i32 3
  store i8* %t76, i8** %t77
  %t78 = call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @par.pool.worker_main to i8*), i8* inttoptr (i64 3 to i8*), i32 0, i32* null)
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


define void @list_release_symbol(i8* %objp) {
entry:
  %t333 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t334 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t333, i32 0, i32 0
  %t335 = load i64*, i64** %t334
  %t336 = bitcast i64* %t335 to i8*
  call void @free(i8* %t336)
  ret void
}



; Global Constants
@__star_reflect_Stats = private unnamed_addr constant [77 x i8] c"score:0:i32:export;high_score:4:i32:export;move_interval_ms:8:i32:tweakable;\00"
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
@.str.17 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.18 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.19 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.20 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.21 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.22 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.23 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Scratch` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.24 = private unnamed_addr constant [140 x i8] c"star runtime warning: arena `Scratch` is full (1024 live elements) -- spawn dropped (further overflows on this arena will not be reported)\0A\00"
@.str.25 = private unnamed_addr constant [73 x i8] c"[genref demo] stale ref reads tag=%d (expect 0 -- despawned generation)\0A\00"
@.str.26 = private unnamed_addr constant [51 x i8] c"[genref demo] fresh ref reads tag=%d (expect 222)\0A\00"
@.str.27 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.28 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.29 = private unnamed_addr constant [70 x i8] c"star runtime error: a `frame:` block exceeded its 4096-byte capacity\0A\00"
@.str.30 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"Star Snake\00" }
@.str.31 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"window_create failed\00" }
@.str.32 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.33 = private unnamed_addr constant [37 x i8] c"[frame demo] node1.x + node2.y = %d\0A\00"
@.str.34 = private unnamed_addr constant [417 x i8] c"\05\07\20\3B\00\00\00\00\00\00\00\04\04\04\04\04\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\04\04\00\00\00\00\00\02\04\08\08\08\04\02\08\04\02\02\02\04\08\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\04\08\00\00\00\1F\00\00\00\00\00\00\00\00\04\04\01\02\04\04\08\10\10\0E\11\13\15\19\11\0E\04\0C\04\04\04\04\0E\0E\11\01\02\04\08\1F\0E\11\01\06\01\11\0E\02\06\0A\12\1F\02\02\1F\10\1E\01\01\11\0E\06\08\10\1E\11\11\0E\1F\01\02\04\08\08\08\0E\11\11\0E\11\11\0E\0E\11\11\0F\01\02\0C\00\04\00\00\04\00\00\00\04\00\00\04\08\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0E\11\01\02\04\00\04\00\00\00\00\00\00\00\04\0A\11\11\1F\11\11\1E\11\11\1E\11\11\1E\0E\11\10\10\10\11\0E\1C\12\11\11\11\12\1C\1F\10\10\1E\10\10\1F\1F\10\10\1E\10\10\10\0E\11\10\17\11\11\0E\11\11\11\1F\11\11\11\0E\04\04\04\04\04\0E\07\02\02\02\02\12\0C\11\12\14\18\14\12\11\10\10\10\10\10\10\1F\11\1B\15\11\11\11\11\11\19\15\13\11\11\11\0E\11\11\11\11\11\0E\1E\11\11\1E\10\10\10\0E\11\11\11\15\12\0D\1E\11\11\1E\14\12\11\0F\10\10\0E\01\01\1E\1F\04\04\04\04\04\04\11\11\11\11\11\11\0E\11\11\11\11\11\0A\04\11\11\11\15\15\1B\11\11\11\0A\04\0A\11\11\11\11\0A\04\04\04\04\1F\01\02\04\08\10\1F"
@.str.35 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"snake_save.txt\00" }
@.str.36 = private unnamed_addr constant [50 x i8] c"[save] loaded high score %d, difficulty tag \22%s\22\0A\00"
@.str.37 = private unnamed_addr constant [85 x i8] c"star runtime error: window_should_close(..) called with a null/closed window handle\0A\00"
@.str.38 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.39 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"move\00" }
@.str.40 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"eat\00" }
@.str.41 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.42 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.43 = private unnamed_addr constant [58 x i8] c"[spawn handle] particle just spawned at slot %d, life=%f\0A\00"
@.str.44 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.45 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.46 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.47 = private unnamed_addr constant [54 x i8] c"[achievement] unlocked milestone %d -- badges now %u\0A\00"
@.str.48 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"die\00" }
@.str.49 = private unnamed_addr constant [26 x i8] c"[events] final event: %s\0A\00"
@.str.50 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"normal\00" }
@.str.51 = private unnamed_addr constant [34 x i8] c"[leaderboard] %d, %d, %d, %d, %d\0A\00"
@.str.52 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.53 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.54 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.55 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.56 = private unnamed_addr constant [10 x i8] c"SCORE: %d\00"
@.str.57 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.58 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.59 = private unnamed_addr constant [9 x i8] c"HIGH: %d\00"
@.str.60 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"PAUSED\00" }
@.str.61 = private unnamed_addr constant [76 x i8] c"star runtime error: measure_text(..) called with a null/closed font handle\0A\00"
@.str.62 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.63 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.64 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.65 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.66 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"GAME OVER\00" }
@.str.67 = private unnamed_addr constant { i64, i8*, [19 x i8] } { i64 -1, i8* null, [19 x i8] c"PRESS R TO RESTART\00" }
@.str.68 = private unnamed_addr constant [76 x i8] c"star runtime error: measure_text(..) called with a null/closed font handle\0A\00"
@.str.69 = private unnamed_addr constant [76 x i8] c"star runtime error: measure_text(..) called with a null/closed font handle\0A\00"
@.str.70 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.71 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.72 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.73 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.74 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.75 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.76 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.77 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.78 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.79 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.80 = private unnamed_addr constant [6 x i8] c"Right\00"
@.str.81 = private unnamed_addr constant [5 x i8] c"Left\00"
@.str.82 = private unnamed_addr constant [5 x i8] c"Down\00"
@.str.83 = private unnamed_addr constant [3 x i8] c"Up\00"
@.str.84 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.85 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.86 = private unnamed_addr constant [59 x i8] c"[debug] score=%d high=%d len=%d paused=%s dir=%s boost=%s\0A\00"
@.str.87 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.88 = private unnamed_addr constant [38 x i8] c"[stats] final score=%d high_score=%d\0A\00"
@.str.89 = private unnamed_addr constant [34 x i8] c"[stats] achievements bitfield=%u\0A\00"
@.str.90 = private unnamed_addr constant [80 x i8] c"star runtime error: window_destroy(..) called with a null/closed window handle\0A\00"
