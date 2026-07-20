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

%Player = type { i32, i8* }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define { i32, i32 } @min_max(i32 %a, i32 %b) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  %t10 = alloca { i32, i32 }
  %t19 = alloca { i32, i32 }
  store i32 %a, i32* %t0
  store i32 %b, i32* %t1
  %t2 = load i32, i32* %t0
  %t3 = load i32, i32* %t1
  %t4 = icmp sle i32 %t2, %t3
  br label %match_scrutinee_6
match_scrutinee_6:
  %t9 = icmp eq i1 %t4, true
  br i1 %t9, label %match_then_0_7, label %match_next_0_8
match_then_0_7:
  %t11 = load i32, i32* %t0
  %t12 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t10, i32 0, i32 0
  store i32 %t11, i32* %t12
  %t13 = load i32, i32* %t1
  %t14 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t10, i32 0, i32 1
  store i32 %t13, i32* %t14
  %t15 = load { i32, i32 }, { i32, i32 }* %t10
  br label %match_end_5
match_next_0_8:
  %t18 = icmp eq i1 %t4, false
  br i1 %t18, label %match_then_1_16, label %match_next_1_17
match_then_1_16:
  %t20 = load i32, i32* %t1
  %t21 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t19, i32 0, i32 0
  store i32 %t20, i32* %t21
  %t22 = load i32, i32* %t0
  %t23 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t19, i32 0, i32 1
  store i32 %t22, i32* %t23
  %t24 = load { i32, i32 }, { i32, i32 }* %t19
  br label %match_end_5
match_next_1_17:
  br label %match_end_5
match_end_5:
  %t25 = phi { i32, i32 } [ %t15, %match_then_0_7 ], [ %t24, %match_then_1_16 ], [ undef, %match_next_1_17 ]
  ret { i32, i32 } %t25
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca { i32, i32 }
  %t3 = alloca { i32, i32 }
  %t18 = alloca { i32, i32 }
  %t25 = alloca { %Player, i8* }
  %t26 = alloca { %Player, i8* }
  %t27 = alloca %Player
  %t53 = alloca i32
  %t56 = alloca { i32 }
  %t57 = alloca { i32 }
  %t63 = alloca [5 x i32]
  %t64 = alloca [5 x i32]
  %t66 = alloca i64
  %t80 = alloca i32
  %t86 = alloca i32
  %t92 = alloca i32
  %t98 = alloca i32
  %t104 = alloca i32
  %t111 = alloca i32
  %t121 = alloca i32
  %t125 = alloca [3 x %Player]
  %t126 = alloca [3 x %Player]
  %t127 = alloca %Player
  %t133 = alloca i64
  %t144 = alloca %Player
  %t152 = alloca %Player
  %t158 = alloca %Player
  %t165 = alloca %Player
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t4 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3, i32 0, i32 0
  store i32 3, i32* %t4
  %t5 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t3, i32 0, i32 1
  store i32 4, i32* %t5
  %t6 = load { i32, i32 }, { i32, i32 }* %t3
  store { i32, i32 } %t6, { i32, i32 }* %t2
  %t7 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 0
  %t8 = load i32, i32* %t7
  %t9 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 1
  %t10 = load i32, i32* %t9
  %t11 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t11, i32 %t8, i32 %t10)
  %t12 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 0
  store i32 10, i32* %t12
  %t13 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 0
  %t14 = load i32, i32* %t13
  %t15 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t2, i32 0, i32 1
  %t16 = load i32, i32* %t15
  %t17 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t17, i32 %t14, i32 %t16)
  %t19 = call { i32, i32 } @min_max(i32 7, i32 2)
  store { i32, i32 } %t19, { i32, i32 }* %t18
  %t20 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t18, i32 0, i32 0
  %t21 = load i32, i32* %t20
  %t22 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t18, i32 0, i32 1
  %t23 = load i32, i32* %t22
  %t24 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t24, i32 %t21, i32 %t23)
  %t28 = getelementptr inbounds %Player, %Player* %t27, i32 0, i32 0
  store i32 100, i32* %t28
  %t29 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t30 = getelementptr inbounds %Player, %Player* %t27, i32 0, i32 1
  store i8* %t29, i8** %t30
  %t31 = load %Player, %Player* %t27
  %t32 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t26, i32 0, i32 0
  store %Player %t31, %Player* %t32
  %t33 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t34 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t26, i32 0, i32 1
  store i8* %t33, i8** %t34
  %t35 = load { %Player, i8* }, { %Player, i8* }* %t26
  store { %Player, i8* } %t35, { %Player, i8* }* %t25
  %t36 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t37 = getelementptr inbounds %Player, %Player* %t36, i32 0, i32 0
  %t38 = load i32, i32* %t37
  %t39 = sub i32 %t38, 25
  %t40 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t41 = getelementptr inbounds %Player, %Player* %t40, i32 0, i32 0
  store i32 %t39, i32* %t41
  %t42 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t43 = getelementptr inbounds %Player, %Player* %t42, i32 0, i32 1
  %t44 = load i8*, i8** %t43
  %t45 = load i8*, i8** %t43
  call void @star_rc_retain(i8* %t45)
  call void @star_rc_release(i8* %t44)
  %t46 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t47 = getelementptr inbounds %Player, %Player* %t46, i32 0, i32 0
  %t48 = load i32, i32* %t47
  %t49 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 1
  %t50 = load i8*, i8** %t49
  %t51 = load i8*, i8** %t49
  call void @star_rc_retain(i8* %t51)
  call void @star_rc_release(i8* %t50)
  %t52 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t52, i8* %t44, i32 %t48, i8* %t50)
  store i32 5, i32* %t53
  %t54 = load i32, i32* %t53
  %t55 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t55, i32 %t54)
  %t58 = getelementptr inbounds { i32 }, { i32 }* %t57, i32 0, i32 0
  store i32 9, i32* %t58
  %t59 = load { i32 }, { i32 }* %t57
  store { i32 } %t59, { i32 }* %t56
  %t60 = getelementptr inbounds { i32 }, { i32 }* %t56, i32 0, i32 0
  %t61 = load i32, i32* %t60
  %t62 = getelementptr inbounds [12 x i8], [12 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t62, i32 %t61)
  %t65 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 0
  store i32 0, i32* %t65
  store i64 1, i64* %t66
  br label %arr_rep_cond_0
arr_rep_cond_0:
  %t67 = load i64, i64* %t66
  %t68 = icmp ult i64 %t67, 5
  br i1 %t68, label %arr_rep_body_1, label %arr_rep_end_2
arr_rep_body_1:
  %t69 = getelementptr inbounds [5 x i32], [5 x i32]* %t64, i32 0, i64 %t67
  store i32 0, i32* %t69
  %t70 = add i64 %t67, 1
  store i64 %t70, i64* %t66
  br label %arr_rep_cond_0
arr_rep_end_2:
  %t71 = load [5 x i32], [5 x i32]* %t64
  store [5 x i32] %t71, [5 x i32]* %t63
  %t72 = load [5 x i32], [5 x i32]* %t63
  %t73 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t73, i32 5)
  %t74 = sext i32 2 to i64
  %t75 = icmp ult i64 %t74, 5
  br i1 %t75, label %arr_set_do_3, label %arr_set_oob_4
arr_set_do_3:
  %t76 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t74
  store i32 42, i32* %t76
  br label %arr_set_end_5
arr_set_oob_4:
  br label %arr_set_end_5
arr_set_end_5:
  %t77 = sext i32 0 to i64
  %t78 = icmp ult i64 %t77, 5
  br i1 %t78, label %arr_rplace_ok_6, label %arr_rplace_oob_7
arr_rplace_ok_6:
  %t79 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t77
  br label %arr_rplace_end_8
arr_rplace_oob_7:
  store i32 0, i32* %t80
  br label %arr_rplace_end_8
arr_rplace_end_8:
  %t81 = phi i32* [ %t79, %arr_rplace_ok_6 ], [ %t80, %arr_rplace_oob_7 ]
  %t82 = load i32, i32* %t81
  %t83 = sext i32 1 to i64
  %t84 = icmp ult i64 %t83, 5
  br i1 %t84, label %arr_rplace_ok_9, label %arr_rplace_oob_10
arr_rplace_ok_9:
  %t85 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t83
  br label %arr_rplace_end_11
arr_rplace_oob_10:
  store i32 0, i32* %t86
  br label %arr_rplace_end_11
arr_rplace_end_11:
  %t87 = phi i32* [ %t85, %arr_rplace_ok_9 ], [ %t86, %arr_rplace_oob_10 ]
  %t88 = load i32, i32* %t87
  %t89 = sext i32 2 to i64
  %t90 = icmp ult i64 %t89, 5
  br i1 %t90, label %arr_rplace_ok_12, label %arr_rplace_oob_13
arr_rplace_ok_12:
  %t91 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t89
  br label %arr_rplace_end_14
arr_rplace_oob_13:
  store i32 0, i32* %t92
  br label %arr_rplace_end_14
arr_rplace_end_14:
  %t93 = phi i32* [ %t91, %arr_rplace_ok_12 ], [ %t92, %arr_rplace_oob_13 ]
  %t94 = load i32, i32* %t93
  %t95 = sext i32 3 to i64
  %t96 = icmp ult i64 %t95, 5
  br i1 %t96, label %arr_rplace_ok_15, label %arr_rplace_oob_16
arr_rplace_ok_15:
  %t97 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t95
  br label %arr_rplace_end_17
arr_rplace_oob_16:
  store i32 0, i32* %t98
  br label %arr_rplace_end_17
arr_rplace_end_17:
  %t99 = phi i32* [ %t97, %arr_rplace_ok_15 ], [ %t98, %arr_rplace_oob_16 ]
  %t100 = load i32, i32* %t99
  %t101 = sext i32 4 to i64
  %t102 = icmp ult i64 %t101, 5
  br i1 %t102, label %arr_rplace_ok_18, label %arr_rplace_oob_19
arr_rplace_ok_18:
  %t103 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t101
  br label %arr_rplace_end_20
arr_rplace_oob_19:
  store i32 0, i32* %t104
  br label %arr_rplace_end_20
arr_rplace_end_20:
  %t105 = phi i32* [ %t103, %arr_rplace_ok_18 ], [ %t104, %arr_rplace_oob_19 ]
  %t106 = load i32, i32* %t105
  %t107 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t107, i32 %t82, i32 %t88, i32 %t94, i32 %t100, i32 %t106)
  %t108 = sext i32 99 to i64
  %t109 = icmp ult i64 %t108, 5
  br i1 %t109, label %arr_rplace_ok_21, label %arr_rplace_oob_22
arr_rplace_ok_21:
  %t110 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t108
  br label %arr_rplace_end_23
arr_rplace_oob_22:
  store i32 0, i32* %t111
  br label %arr_rplace_end_23
arr_rplace_end_23:
  %t112 = phi i32* [ %t110, %arr_rplace_ok_21 ], [ %t111, %arr_rplace_oob_22 ]
  %t113 = load i32, i32* %t112
  %t114 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t114, i32 %t113)
  %t115 = sext i32 99 to i64
  %t116 = icmp ult i64 %t115, 5
  br i1 %t116, label %arr_set_do_24, label %arr_set_oob_25
arr_set_do_24:
  %t117 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t115
  store i32 7, i32* %t117
  br label %arr_set_end_26
arr_set_oob_25:
  br label %arr_set_end_26
arr_set_end_26:
  %t118 = sext i32 2 to i64
  %t119 = icmp ult i64 %t118, 5
  br i1 %t119, label %arr_rplace_ok_27, label %arr_rplace_oob_28
arr_rplace_ok_27:
  %t120 = getelementptr inbounds [5 x i32], [5 x i32]* %t63, i32 0, i64 %t118
  br label %arr_rplace_end_29
arr_rplace_oob_28:
  store i32 0, i32* %t121
  br label %arr_rplace_end_29
arr_rplace_end_29:
  %t122 = phi i32* [ %t120, %arr_rplace_ok_27 ], [ %t121, %arr_rplace_oob_28 ]
  %t123 = load i32, i32* %t122
  %t124 = getelementptr inbounds [54 x i8], [54 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t124, i32 %t123)
  %t128 = getelementptr inbounds %Player, %Player* %t127, i32 0, i32 0
  store i32 50, i32* %t128
  %t129 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t130 = getelementptr inbounds %Player, %Player* %t127, i32 0, i32 1
  store i8* %t129, i8** %t130
  %t131 = load %Player, %Player* %t127
  %t132 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 0
  store %Player %t131, %Player* %t132
  store i64 1, i64* %t133
  br label %arr_rep_cond_30
arr_rep_cond_30:
  %t134 = load i64, i64* %t133
  %t135 = icmp ult i64 %t134, 3
  br i1 %t135, label %arr_rep_body_31, label %arr_rep_end_32
arr_rep_body_31:
  %t136 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t126, i32 0, i64 %t134
  store %Player %t131, %Player* %t136
  %t137 = getelementptr inbounds %Player, %Player* %t136, i32 0, i32 1
  %t138 = load i8*, i8** %t137
  call void @star_rc_retain(i8* %t138)
  %t139 = add i64 %t134, 1
  store i64 %t139, i64* %t133
  br label %arr_rep_cond_30
arr_rep_end_32:
  %t140 = load [3 x %Player], [3 x %Player]* %t126
  store [3 x %Player] %t140, [3 x %Player]* %t125
  %t141 = sext i32 0 to i64
  %t142 = icmp ult i64 %t141, 3
  br i1 %t142, label %arr_place_ok_33, label %arr_place_oob_34
arr_place_ok_33:
  %t143 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 %t141
  br label %arr_place_end_35
arr_place_oob_34:
  store %Player zeroinitializer, %Player* %t144
  br label %arr_place_end_35
arr_place_end_35:
  %t145 = phi %Player* [ %t143, %arr_place_ok_33 ], [ %t144, %arr_place_oob_34 ]
  %t146 = getelementptr inbounds %Player, %Player* %t145, i32 0, i32 0
  %t147 = load i32, i32* %t146
  %t148 = sub i32 %t147, 10
  %t149 = sext i32 0 to i64
  %t150 = icmp ult i64 %t149, 3
  br i1 %t150, label %arr_place_ok_36, label %arr_place_oob_37
arr_place_ok_36:
  %t151 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 %t149
  br label %arr_place_end_38
arr_place_oob_37:
  store %Player zeroinitializer, %Player* %t152
  br label %arr_place_end_38
arr_place_end_38:
  %t153 = phi %Player* [ %t151, %arr_place_ok_36 ], [ %t152, %arr_place_oob_37 ]
  %t154 = getelementptr inbounds %Player, %Player* %t153, i32 0, i32 0
  store i32 %t148, i32* %t154
  %t155 = sext i32 0 to i64
  %t156 = icmp ult i64 %t155, 3
  br i1 %t156, label %arr_rplace_ok_39, label %arr_rplace_oob_40
arr_rplace_ok_39:
  %t157 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 %t155
  br label %arr_rplace_end_41
arr_rplace_oob_40:
  store %Player zeroinitializer, %Player* %t158
  br label %arr_rplace_end_41
arr_rplace_end_41:
  %t159 = phi %Player* [ %t157, %arr_rplace_ok_39 ], [ %t158, %arr_rplace_oob_40 ]
  %t160 = getelementptr inbounds %Player, %Player* %t159, i32 0, i32 0
  %t161 = load i32, i32* %t160
  %t162 = sext i32 1 to i64
  %t163 = icmp ult i64 %t162, 3
  br i1 %t163, label %arr_rplace_ok_42, label %arr_rplace_oob_43
arr_rplace_ok_42:
  %t164 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 %t162
  br label %arr_rplace_end_44
arr_rplace_oob_43:
  store %Player zeroinitializer, %Player* %t165
  br label %arr_rplace_end_44
arr_rplace_end_44:
  %t166 = phi %Player* [ %t164, %arr_rplace_ok_42 ], [ %t165, %arr_rplace_oob_43 ]
  %t167 = getelementptr inbounds %Player, %Player* %t166, i32 0, i32 0
  %t168 = load i32, i32* %t167
  %t169 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.13, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t169, i32 %t161, i32 %t168)
  %t170 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 0
  %t171 = getelementptr inbounds %Player, %Player* %t170, i32 0, i32 1
  %t172 = load i8*, i8** %t171
  call void @star_rc_release(i8* %t172)
  %t173 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 1
  %t174 = getelementptr inbounds %Player, %Player* %t173, i32 0, i32 1
  %t175 = load i8*, i8** %t174
  call void @star_rc_release(i8* %t175)
  %t176 = getelementptr inbounds [3 x %Player], [3 x %Player]* %t125, i32 0, i64 2
  %t177 = getelementptr inbounds %Player, %Player* %t176, i32 0, i32 1
  %t178 = load i8*, i8** %t177
  call void @star_rc_release(i8* %t178)
  %t179 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 0
  %t180 = getelementptr inbounds %Player, %Player* %t179, i32 0, i32 1
  %t181 = load i8*, i8** %t180
  call void @star_rc_release(i8* %t181)
  %t182 = getelementptr inbounds { %Player, i8* }, { %Player, i8* }* %t25, i32 0, i32 1
  %t183 = load i8*, i8** %t182
  call void @star_rc_release(i8* %t183)
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant [18 x i8] c"point = (%d, %d)\0A\00"
@.str.1 = private unnamed_addr constant [33 x i8] c"point after mutation = (%d, %d)\0A\00"
@.str.2 = private unnamed_addr constant [26 x i8] c"min_max(7, 2) = (%d, %d)\0A\00"
@.str.3 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"Hero\00" }
@.str.4 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"extra lives: 2\00" }
@.str.5 = private unnamed_addr constant [15 x i8] c"%s hp=%d (%s)\0A\00"
@.str.6 = private unnamed_addr constant [14 x i8] c"grouped = %d\0A\00"
@.str.7 = private unnamed_addr constant [12 x i8] c"one.0 = %d\0A\00"
@.str.8 = private unnamed_addr constant [19 x i8] c"scores.len() = %d\0A\00"
@.str.9 = private unnamed_addr constant [31 x i8] c"scores = [%d, %d, %d, %d, %d]\0A\00"
@.str.10 = private unnamed_addr constant [17 x i8] c"scores[99] = %d\0A\00"
@.str.11 = private unnamed_addr constant [54 x i8] c"scores[2] unaffected by the out-of-bounds write = %d\0A\00"
@.str.12 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Grunt\00" }
@.str.13 = private unnamed_addr constant [39 x i8] c"party[0].health=%d party[1].health=%d\0A\00"
