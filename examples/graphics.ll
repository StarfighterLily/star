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

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i32
  %t3 = alloca i32
  %t4 = alloca i32
  %t5 = alloca i8*
  %t20 = alloca i32
  %t21 = alloca i32
  %t22 = alloca i32
  %t23 = alloca i32
  %t24 = alloca i32
  %t25 = alloca i32
  %t36 = alloca i32
  %t50 = alloca i1
  %t51 = alloca [56 x i8]
  %t131 = alloca [16 x i8]
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i32 640, i32* %t2
  store i32 480, i32* %t3
  store i32 40, i32* %t4
  %t6 = getelementptr inbounds { i64, i8*, [20 x i8] }, { i64, i8*, [20 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t7 = load i32, i32* %t2
  %t8 = load i32, i32* %t3
  %t9 = call i32 @SDL_Init(i32 32)
  %t10 = icmp ne i32 %t9, 0
  br i1 %t10, label %sdl_init_fail_0, label %sdl_init_ok_1
sdl_init_fail_0:
  call void @star_rc_release(i8* %t6)
  br label %window_create_end_2
sdl_init_ok_1:
  %t11 = call i8* @SDL_CreateWindow(i8* %t6, i32 536805376, i32 536805376, i32 %t7, i32 %t8, i32 0)
  call void @star_rc_release(i8* %t6)
  %t12 = icmp eq i8* %t11, null
  br i1 %t12, label %sdl_window_fail_3, label %sdl_window_ok_4
sdl_window_fail_3:
  br label %window_create_end_2
sdl_window_ok_4:
  %t13 = call i8* @SDL_CreateRenderer(i8* %t11, i32 -1, i32 0)
  %t14 = icmp eq i8* %t13, null
  br i1 %t14, label %sdl_renderer_fail_5, label %sdl_renderer_ok_6
sdl_renderer_fail_5:
  call void @SDL_DestroyWindow(i8* %t11)
  br label %window_create_end_2
sdl_renderer_ok_6:
  br label %window_create_end_2
window_create_end_2:
  %t15 = phi i8* [ null, %sdl_init_fail_0 ], [ null, %sdl_window_fail_3 ], [ null, %sdl_renderer_fail_5 ], [ %t11, %sdl_renderer_ok_6 ]
  store i8* %t15, i8** %t5
  %t16 = load i8*, i8** %t5
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %if_then_7, label %if_else_8
if_then_7:
  %t18 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.1, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t18)
  call i32 (i8*, ...) @printf(i8* %t18)
  %t19 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t19)
  ret i32 0
if_else_8:
  br label %if_end_9
if_end_9:
  store i32 0, i32* %t20
  store i32 0, i32* %t21
  store i32 4, i32* %t22
  store i32 3, i32* %t23
  store i32 41, i32* %t24
  %t26 = and i32 20, 255
  %t27 = and i32 20, 255
  %t28 = shl i32 %t27, 8
  %t29 = or i32 %t26, %t28
  %t30 = and i32 30, 255
  %t31 = shl i32 %t30, 16
  %t32 = or i32 %t29, %t31
  %t33 = and i32 255, 255
  %t34 = shl i32 %t33, 24
  %t35 = or i32 %t32, %t34
  store i32 %t35, i32* %t25
  %t37 = and i32 80, 255
  %t38 = and i32 180, 255
  %t39 = shl i32 %t38, 8
  %t40 = or i32 %t37, %t39
  %t41 = and i32 255, 255
  %t42 = shl i32 %t41, 16
  %t43 = or i32 %t40, %t42
  %t44 = and i32 255, 255
  %t45 = shl i32 %t44, 24
  %t46 = or i32 %t43, %t45
  store i32 %t46, i32* %t36
  br label %while_cond_10
while_cond_10:
  br i1 true, label %while_body_11, label %while_else_12
while_body_11:
  %t47 = load i8*, i8** %t5
  %t48 = icmp eq i8* %t47, null
  br i1 %t48, label %sdl_null_window_14, label %sdl_window_handle_ok_15
sdl_null_window_14:
  %t49 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t49)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_15:
  store i1 false, i1* %t50
  %t52 = getelementptr inbounds [56 x i8], [56 x i8]* %t51, i64 0, i64 0
  br label %sdl_poll_cond_16
sdl_poll_cond_16:
  %t53 = call i32 @SDL_PollEvent(i8* %t52)
  %t54 = icmp ne i32 %t53, 0
  br i1 %t54, label %sdl_poll_body_17, label %sdl_poll_end_19
sdl_poll_body_17:
  %t55 = bitcast i8* %t52 to i32*
  %t56 = load i32, i32* %t55
  %t57 = icmp eq i32 %t56, 256
  br i1 %t57, label %sdl_poll_set_quit_18, label %sdl_poll_cond_16
sdl_poll_set_quit_18:
  store i1 true, i1* %t50
  br label %sdl_poll_cond_16
sdl_poll_end_19:
  %t58 = load i1, i1* %t50
  br i1 %t58, label %if_then_20, label %if_else_21
if_then_20:
  br label %while_end_13
if_else_21:
  br label %if_end_22
if_end_22:
  %t59 = load i32, i32* %t24
  %t60 = icmp sge i32 %t59, 0
  %t61 = icmp slt i32 %t59, 512
  %t62 = and i1 %t60, %t61
  br i1 %t62, label %key_down_read_23, label %key_down_end_24
key_down_read_23:
  %t63 = call i8* @SDL_GetKeyboardState(i32* null)
  %t64 = sext i32 %t59 to i64
  %t65 = getelementptr inbounds i8, i8* %t63, i64 %t64
  %t66 = load i8, i8* %t65
  %t67 = icmp ne i8 %t66, 0
  br label %key_down_end_24
key_down_end_24:
  %t68 = phi i1 [ false, %if_end_22 ], [ %t67, %key_down_read_23 ]
  br i1 %t68, label %if_then_25, label %if_else_26
if_then_25:
  br label %while_end_13
if_else_26:
  br label %if_end_27
if_end_27:
  %t69 = load i32, i32* %t22
  %t70 = load i32, i32* %t20
  %t71 = add i32 %t70, %t69
  store i32 %t71, i32* %t20
  %t72 = load i32, i32* %t23
  %t73 = load i32, i32* %t21
  %t74 = add i32 %t73, %t72
  store i32 %t74, i32* %t21
  %t75 = load i32, i32* %t20
  %t76 = icmp slt i32 %t75, 0
  br i1 %t76, label %logic_short_29, label %logic_rhs_28
logic_rhs_28:
  %t77 = load i32, i32* %t20
  %t78 = load i32, i32* %t4
  %t79 = add i32 %t77, %t78
  %t80 = load i32, i32* %t2
  %t81 = icmp sgt i32 %t79, %t80
  br label %logic_end_30
logic_short_29:
  br label %logic_end_30
logic_end_30:
  %t82 = phi i1 [ %t81, %logic_rhs_28 ], [ true, %logic_short_29 ]
  br i1 %t82, label %if_then_31, label %if_else_32
if_then_31:
  %t83 = load i32, i32* %t22
  %t84 = sub i32 0, %t83
  store i32 %t84, i32* %t22
  br label %if_end_33
if_else_32:
  br label %if_end_33
if_end_33:
  %t85 = load i32, i32* %t21
  %t86 = icmp slt i32 %t85, 0
  br i1 %t86, label %logic_short_35, label %logic_rhs_34
logic_rhs_34:
  %t87 = load i32, i32* %t21
  %t88 = load i32, i32* %t4
  %t89 = add i32 %t87, %t88
  %t90 = load i32, i32* %t3
  %t91 = icmp sgt i32 %t89, %t90
  br label %logic_end_36
logic_short_35:
  br label %logic_end_36
logic_end_36:
  %t92 = phi i1 [ %t91, %logic_rhs_34 ], [ true, %logic_short_35 ]
  br i1 %t92, label %if_then_37, label %if_else_38
if_then_37:
  %t93 = load i32, i32* %t23
  %t94 = sub i32 0, %t93
  store i32 %t94, i32* %t23
  br label %if_end_39
if_else_38:
  br label %if_end_39
if_end_39:
  %t95 = load i8*, i8** %t5
  %t96 = icmp eq i8* %t95, null
  br i1 %t96, label %sdl_null_window_40, label %sdl_window_handle_ok_41
sdl_null_window_40:
  %t97 = getelementptr inbounds [78 x i8], [78 x i8]* @.str.4, i64 0, i64 0
  call i32 @puts(i8* %t97)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_41:
  %t98 = call i8* @SDL_GetRenderer(i8* %t95)
  %t99 = load i32, i32* %t25
  %t100 = and i32 %t99, 255
  %t101 = trunc i32 %t100 to i8
  %t102 = lshr i32 %t99, 8
  %t103 = and i32 %t102, 255
  %t104 = trunc i32 %t103 to i8
  %t105 = lshr i32 %t99, 16
  %t106 = and i32 %t105, 255
  %t107 = trunc i32 %t106 to i8
  %t108 = lshr i32 %t99, 24
  %t109 = and i32 %t108, 255
  %t110 = trunc i32 %t109 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t98, i8 %t101, i8 %t104, i8 %t107, i8 %t110)
  call i32 @SDL_RenderClear(i8* %t98)
  %t111 = load i8*, i8** %t5
  %t112 = icmp eq i8* %t111, null
  br i1 %t112, label %sdl_null_window_42, label %sdl_window_handle_ok_43
sdl_null_window_42:
  %t113 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.5, i64 0, i64 0
  call i32 @puts(i8* %t113)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_43:
  %t114 = call i8* @SDL_GetRenderer(i8* %t111)
  %t115 = load i32, i32* %t20
  %t116 = load i32, i32* %t21
  %t117 = load i32, i32* %t4
  %t118 = load i32, i32* %t4
  %t119 = load i32, i32* %t36
  %t120 = and i32 %t119, 255
  %t121 = trunc i32 %t120 to i8
  %t122 = lshr i32 %t119, 8
  %t123 = and i32 %t122, 255
  %t124 = trunc i32 %t123 to i8
  %t125 = lshr i32 %t119, 16
  %t126 = and i32 %t125, 255
  %t127 = trunc i32 %t126 to i8
  %t128 = lshr i32 %t119, 24
  %t129 = and i32 %t128, 255
  %t130 = trunc i32 %t129 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t114, i8 %t121, i8 %t124, i8 %t127, i8 %t130)
  %t132 = getelementptr inbounds [16 x i8], [16 x i8]* %t131, i64 0, i64 0
  %t133 = bitcast i8* %t132 to i32*
  store i32 %t115, i32* %t133
  %t134 = getelementptr inbounds i8, i8* %t132, i64 4
  %t135 = bitcast i8* %t134 to i32*
  store i32 %t116, i32* %t135
  %t136 = getelementptr inbounds i8, i8* %t132, i64 8
  %t137 = bitcast i8* %t136 to i32*
  store i32 %t117, i32* %t137
  %t138 = getelementptr inbounds i8, i8* %t132, i64 12
  %t139 = bitcast i8* %t138 to i32*
  store i32 %t118, i32* %t139
  call i32 @SDL_RenderFillRect(i8* %t114, i8* %t132)
  %t140 = load i8*, i8** %t5
  %t141 = icmp eq i8* %t140, null
  br i1 %t141, label %sdl_null_window_44, label %sdl_window_handle_ok_45
sdl_null_window_44:
  %t142 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t142)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_45:
  %t143 = call i8* @SDL_GetRenderer(i8* %t140)
  call void @SDL_RenderPresent(i8* %t143)
  %t144 = icmp slt i32 16, 0
  %t145 = select i1 %t144, i32 0, i32 16
  call void @SDL_Delay(i32 %t145)
  br label %while_cond_10
while_else_12:
  br label %while_end_13
while_end_13:
  %t146 = load i8*, i8** %t5
  %t147 = icmp eq i8* %t146, null
  br i1 %t147, label %sdl_null_window_46, label %sdl_window_handle_ok_47
sdl_null_window_46:
  %t148 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.7, i64 0, i64 0
  call i32 @puts(i8* %t148)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_47:
  %t149 = call i8* @SDL_GetRenderer(i8* %t146)
  call void @SDL_DestroyRenderer(i8* %t149)
  call void @SDL_DestroyWindow(i8* %t146)
  store i8* null, i8** %t5
  ret i32 0
}


; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [20 x i8] } { i64 -1, i8* null, [20 x i8] c"Star: graphics.star\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"window_create failed\00" }
@.str.2 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.3 = private unnamed_addr constant [85 x i8] c"star runtime error: window_should_close(..) called with a null/closed window handle\0A\00"
@.str.4 = private unnamed_addr constant [78 x i8] c"star runtime error: clear_screen(..) called with a null/closed window handle\0A\00"
@.str.5 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.6 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.7 = private unnamed_addr constant [80 x i8] c"star runtime error: window_destroy(..) called with a null/closed window handle\0A\00"
