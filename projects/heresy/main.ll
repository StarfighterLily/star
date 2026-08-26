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
declare i32 @ioctlsocket(i8*, i32, i32*)
declare i32 @WSAGetLastError()
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
declare i32 @SDL_OpenAudioDevice(i8*, i32, i8*, i8*, i32)
declare void @SDL_PauseAudioDevice(i32, i32)
declare void @SDL_MixAudioFormat(i8*, i8*, i16, i32, i32)
declare i32 @SDL_NumJoysticks()
declare i8* @SDL_JoystickOpen(i32)
declare void @SDL_JoystickClose(i8*)
declare void @SDL_JoystickUpdate()
declare i8 @SDL_JoystickGetButton(i8*, i32)
declare i16 @SDL_JoystickGetAxis(i8*, i32)
declare i32 @SDL_JoystickGetAttached(i8*)
declare i8* @CreateCompatibleDC(i8*)
declare i8* @CreateFontA(i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i8*)
declare i8* @SelectObject(i8*, i8*)
declare i32 @DeleteObject(i8*)
declare i32 @DeleteDC(i8*)
declare i32 @SetBkMode(i8*, i32)
declare i32 @SetTextColor(i8*, i32)
declare i32 @GetTextExtentPoint32A(i8*, i8*, i32, i8*)
declare i32 @GetTextMetricsA(i8*, i8*)
declare i8* @CreateDIBSection(i8*, i8*, i32, i8**, i8*, i32)
declare i32 @TextOutA(i8*, i32, i32, i8*, i32)
declare i32 @AddFontResourceExA(i8*, i32, i8*)
declare i32 @RemoveFontResourceExA(i8*, i32, i8*)
declare i32 @GetOpenFileNameA(i8*)
declare i8* @SDL_CreateTexture(i8*, i32, i32, i32, i32)
declare i32 @SDL_UpdateTexture(i8*, i8*, i8*, i32)
declare i32 @SDL_SetTextureBlendMode(i8*, i32)
declare i32 @SDL_SetTextureColorMod(i8*, i8, i8, i8)
declare i32 @SDL_SetTextureAlphaMod(i8*, i8)
declare i32 @SDL_RenderCopy(i8*, i8*, i8*, i8*)
declare void @SDL_DestroyTexture(i8*)
declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)
declare i32 @WaitForSingleObject(i8*, i32)
declare i8* @CreateSemaphoreA(i8*, i32, i32, i8*)
declare i32 @ReleaseSemaphore(i8*, i32, i32*)
declare i32 @GetCurrentThreadId()
declare void @GetSystemInfo(i8*)
declare i32 @atoi(i8*)
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

%map__Level = type { i8*, i8*, i8*, i8*, i8*, i32, float }
%sprites__SpriteSet = type { i8*, i8*, i8*, i8*, i8* }
%audio__Sounds = type { i8*, i8*, i8*, i8* }
%Player = type { float, float, float, float, float, i32, i1 }
%Enemy = type { float, float, float, i32, i1, float }
%Projectile = type { float, float, float, float, i1, i1 }
%Pickup = type { float, float, i32, i1 }
%Game = type { %Player, i8*, i8*, i8*, float, i1, i32, i32 }
%SpriteDraw = type { float, i32, float, float }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define %map__Level @map__parse_level() {
entry:
  %t0 = alloca i8*
  %t9 = alloca i8**
  %t10 = alloca i64
  %t11 = alloca i64
  %t33 = alloca i8*
  %t102 = alloca i8*
  %t103 = alloca i8*
  %t104 = alloca i8*
  %t105 = alloca i8*
  %t106 = alloca i8*
  %t107 = alloca i32
  %t108 = alloca i32
  %t111 = alloca i8*
  %t129 = alloca i8*
  %t145 = alloca i32
  %t148 = alloca i32
  %t165 = alloca i32
  %t665 = alloca %map__Level
  %t1 = getelementptr inbounds { i64, i8*, [258 x i8] }, { i64, i8*, [258 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t2 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t3 = icmp eq i8* %t1, null
  %t4 = select i1 %t3, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t1
  %t5 = icmp eq i8* %t2, null
  %t6 = select i1 %t5, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t2
  %t7 = call i32 @strlen(i8* %t6)
  %t8 = sext i32 %t7 to i64
  store i8** null, i8*** %t9
  store i64 0, i64* %t10
  store i64 0, i64* %t11
  %t12 = icmp eq i64 %t8, 0
  br i1 %t12, label %split_single_0, label %split_scan_init_1
split_single_0:
  %t13 = call i32 @strlen(i8* %t4)
  %t14 = sext i32 %t13 to i64
  %t15 = add i64 %t14, 1
  %t16 = call i8* @star_rc_alloc(i64 %t15, i8* null)
  call i8* @strcpy(i8* %t16, i8* %t4)
  %t17 = load i64, i64* %t10
  %t18 = load i64, i64* %t11
  %t19 = icmp sge i64 %t17, %t18
  br i1 %t19, label %dynstr_grow_3, label %dynstr_store_4
dynstr_grow_3:
  %t20 = mul i64 %t18, 2
  %t21 = icmp sgt i64 %t20, 0
  %t22 = select i1 %t21, i64 %t20, i64 4
  %t23 = mul i64 %t22, 8
  %t24 = call i8* @malloc(i64 %t23)
  %t25 = bitcast i8* %t24 to i8**
  %t26 = icmp sgt i64 %t18, 0
  br i1 %t26, label %dynstr_copy_5, label %dynstr_after_copy_6
dynstr_copy_5:
  %t27 = load i8**, i8*** %t9
  %t28 = mul i64 %t17, 8
  %t29 = bitcast i8** %t27 to i8*
  call i8* @memcpy(i8* %t24, i8* %t29, i64 %t28)
  call void @free(i8* %t29)
  br label %dynstr_after_copy_6
dynstr_after_copy_6:
  store i8** %t25, i8*** %t9
  store i64 %t22, i64* %t11
  br label %dynstr_store_4
dynstr_store_4:
  %t30 = load i8**, i8*** %t9
  %t31 = getelementptr inbounds i8*, i8** %t30, i64 %t17
  store i8* %t16, i8** %t31
  %t32 = add i64 %t17, 1
  store i64 %t32, i64* %t10
  br label %split_finish_2
split_scan_init_1:
  store i8* %t4, i8** %t33
  br label %split_scan_cond_7
split_scan_cond_7:
  %t34 = load i8*, i8** %t33
  %t35 = call i8* @strstr(i8* %t34, i8* %t6)
  %t36 = icmp eq i8* %t35, null
  br i1 %t36, label %split_tail_9, label %split_match_8
split_match_8:
  %t37 = ptrtoint i8* %t35 to i64
  %t38 = ptrtoint i8* %t34 to i64
  %t39 = sub i64 %t37, %t38
  %t40 = add i64 %t39, 1
  %t41 = call i8* @star_rc_alloc(i64 %t40, i8* null)
  call i8* @memcpy(i8* %t41, i8* %t34, i64 %t39)
  %t42 = getelementptr inbounds i8, i8* %t41, i64 %t39
  store i8 0, i8* %t42
  %t43 = load i64, i64* %t10
  %t44 = load i64, i64* %t11
  %t45 = icmp sge i64 %t43, %t44
  br i1 %t45, label %dynstr_grow_10, label %dynstr_store_11
dynstr_grow_10:
  %t46 = mul i64 %t44, 2
  %t47 = icmp sgt i64 %t46, 0
  %t48 = select i1 %t47, i64 %t46, i64 4
  %t49 = mul i64 %t48, 8
  %t50 = call i8* @malloc(i64 %t49)
  %t51 = bitcast i8* %t50 to i8**
  %t52 = icmp sgt i64 %t44, 0
  br i1 %t52, label %dynstr_copy_12, label %dynstr_after_copy_13
dynstr_copy_12:
  %t53 = load i8**, i8*** %t9
  %t54 = mul i64 %t43, 8
  %t55 = bitcast i8** %t53 to i8*
  call i8* @memcpy(i8* %t50, i8* %t55, i64 %t54)
  call void @free(i8* %t55)
  br label %dynstr_after_copy_13
dynstr_after_copy_13:
  store i8** %t51, i8*** %t9
  store i64 %t48, i64* %t11
  br label %dynstr_store_11
dynstr_store_11:
  %t56 = load i8**, i8*** %t9
  %t57 = getelementptr inbounds i8*, i8** %t56, i64 %t43
  store i8* %t41, i8** %t57
  %t58 = add i64 %t43, 1
  store i64 %t58, i64* %t10
  %t59 = getelementptr inbounds i8, i8* %t35, i64 %t8
  store i8* %t59, i8** %t33
  br label %split_scan_cond_7
split_tail_9:
  %t60 = load i8*, i8** %t33
  %t61 = call i32 @strlen(i8* %t60)
  %t62 = sext i32 %t61 to i64
  %t63 = add i64 %t62, 1
  %t64 = call i8* @star_rc_alloc(i64 %t63, i8* null)
  call i8* @strcpy(i8* %t64, i8* %t60)
  %t65 = load i64, i64* %t10
  %t66 = load i64, i64* %t11
  %t67 = icmp sge i64 %t65, %t66
  br i1 %t67, label %dynstr_grow_14, label %dynstr_store_15
dynstr_grow_14:
  %t68 = mul i64 %t66, 2
  %t69 = icmp sgt i64 %t68, 0
  %t70 = select i1 %t69, i64 %t68, i64 4
  %t71 = mul i64 %t70, 8
  %t72 = call i8* @malloc(i64 %t71)
  %t73 = bitcast i8* %t72 to i8**
  %t74 = icmp sgt i64 %t66, 0
  br i1 %t74, label %dynstr_copy_16, label %dynstr_after_copy_17
dynstr_copy_16:
  %t75 = load i8**, i8*** %t9
  %t76 = mul i64 %t65, 8
  %t77 = bitcast i8** %t75 to i8*
  call i8* @memcpy(i8* %t72, i8* %t77, i64 %t76)
  call void @free(i8* %t77)
  br label %dynstr_after_copy_17
dynstr_after_copy_17:
  store i8** %t73, i8*** %t9
  store i64 %t70, i64* %t11
  br label %dynstr_store_15
dynstr_store_15:
  %t78 = load i8**, i8*** %t9
  %t79 = getelementptr inbounds i8*, i8** %t78, i64 %t65
  store i8* %t64, i8** %t79
  %t80 = add i64 %t65, 1
  store i64 %t80, i64* %t10
  br label %split_finish_2
split_finish_2:
  call void @star_rc_release(i8* %t1)
  call void @star_rc_release(i8* %t2)
  %t93 = bitcast void (i8*)* @list_release_str to i8*
  %t94 = call i8* @star_rc_alloc(i64 24, i8* %t93)
  %t95 = bitcast i8* %t94 to { i8**, i64, i64 }*
  %t96 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t95, i32 0, i32 0
  %t97 = load i8**, i8*** %t9
  store i8** %t97, i8*** %t96
  %t98 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t95, i32 0, i32 1
  %t99 = load i64, i64* %t10
  store i64 %t99, i64* %t98
  %t100 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t95, i32 0, i32 2
  %t101 = load i64, i64* %t11
  store i64 %t101, i64* %t100
  store i8* %t94, i8** %t0
  store i8* null, i8** %t102
  store i8* null, i8** %t103
  store i8* null, i8** %t104
  store i8* null, i8** %t105
  store i8* null, i8** %t106
  store i32 0, i32* %t107
  store i32 0, i32* %t108
  br label %while_cond_21
while_cond_21:
  %t109 = load i32, i32* %t108
  %t110 = icmp slt i32 %t109, 16
  br i1 %t110, label %while_body_22, label %while_else_23
while_body_22:
  %t112 = load i8*, i8** %t0
  %t113 = icmp eq i8* %t112, null
  br i1 %t113, label %list_read_null_25, label %list_read_real_26
list_read_null_25:
  br label %list_read_end_27
list_read_real_26:
  %t114 = bitcast i8* %t112 to { i8**, i64, i64 }*
  %t115 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t114, i32 0, i32 0
  %t116 = load i8**, i8*** %t115
  %t117 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t114, i32 0, i32 1
  %t118 = load i64, i64* %t117
  br label %list_read_end_27
list_read_end_27:
  %t119 = phi i8** [ null, %list_read_null_25 ], [ %t116, %list_read_real_26 ]
  %t120 = phi i64 [ 0, %list_read_null_25 ], [ %t118, %list_read_real_26 ]
  %t121 = load i32, i32* %t108
  %t122 = sext i32 %t121 to i64
  %t123 = icmp ult i64 %t122, %t120
  br i1 %t123, label %list_idx_ok_28, label %list_idx_oob_29
list_idx_ok_28:
  %t124 = getelementptr inbounds i8*, i8** %t119, i64 %t122
  %t125 = load i8*, i8** %t124
  %t126 = load i8*, i8** %t124
  call void @star_rc_retain(i8* %t126)
  br label %list_idx_end_30
list_idx_oob_29:
  %t127 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t127
  br label %list_idx_end_30
list_idx_end_30:
  %t128 = phi i8* [ %t125, %list_idx_ok_28 ], [ %t127, %list_idx_oob_29 ]
  store i8* %t128, i8** %t111
  %t130 = load i8*, i8** %t111
  %t131 = load i8*, i8** %t111
  call void @star_rc_retain(i8* %t131)
  %t132 = call i32 @strlen(i8* %t130)
  %t133 = sext i32 %t132 to i64
  %t134 = call i8* @malloc(i64 %t133)
  call i8* @memcpy(i8* %t134, i8* %t130, i64 %t133)
  call void @star_rc_release(i8* %t130)
  %t139 = bitcast void (i8*)* @list_release_u8 to i8*
  %t140 = call i8* @star_rc_alloc(i64 24, i8* %t139)
  %t141 = bitcast i8* %t140 to { i8*, i64, i64 }*
  %t142 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t141, i32 0, i32 0
  store i8* %t134, i8** %t142
  %t143 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t141, i32 0, i32 1
  store i64 %t133, i64* %t143
  %t144 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t141, i32 0, i32 2
  store i64 %t133, i64* %t144
  store i8* %t140, i8** %t129
  store i32 0, i32* %t145
  br label %while_cond_31
while_cond_31:
  %t146 = load i32, i32* %t145
  %t147 = icmp slt i32 %t146, 16
  br i1 %t147, label %while_body_32, label %while_else_33
while_body_32:
  %t149 = load i8*, i8** %t129
  %t150 = icmp eq i8* %t149, null
  br i1 %t150, label %list_read_null_35, label %list_read_real_36
list_read_null_35:
  br label %list_read_end_37
list_read_real_36:
  %t151 = bitcast i8* %t149 to { i8*, i64, i64 }*
  %t152 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t151, i32 0, i32 0
  %t153 = load i8*, i8** %t152
  %t154 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t151, i32 0, i32 1
  %t155 = load i64, i64* %t154
  br label %list_read_end_37
list_read_end_37:
  %t156 = phi i8* [ null, %list_read_null_35 ], [ %t153, %list_read_real_36 ]
  %t157 = phi i64 [ 0, %list_read_null_35 ], [ %t155, %list_read_real_36 ]
  %t158 = load i32, i32* %t145
  %t159 = sext i32 %t158 to i64
  %t160 = icmp ult i64 %t159, %t157
  br i1 %t160, label %list_idx_ok_38, label %list_idx_oob_39
list_idx_ok_38:
  %t161 = getelementptr inbounds i8, i8* %t156, i64 %t159
  %t162 = load i8, i8* %t161
  br label %list_idx_end_40
list_idx_oob_39:
  br label %list_idx_end_40
list_idx_end_40:
  %t163 = phi i8 [ %t162, %list_idx_ok_38 ], [ 0, %list_idx_oob_39 ]
  %t164 = zext i8 %t163 to i32
  store i32 %t164, i32* %t148
  %t166 = load i32, i32* %t108
  %t167 = mul i32 %t166, 16
  %t168 = load i32, i32* %t145
  %t169 = add i32 %t167, %t168
  store i32 %t169, i32* %t165
  %t170 = load i32, i32* %t148
  %t171 = icmp eq i32 %t170, 35
  br i1 %t171, label %if_then_41, label %if_else_42
if_then_41:
  %t172 = getelementptr i32, i32* null, i32 1
  %t173 = ptrtoint i32* %t172 to i64
  %t174 = load i8*, i8** %t102
  %t175 = icmp eq i8* %t174, null
  br i1 %t175, label %list_cow_alloc_44, label %list_cow_check_45
list_cow_alloc_44:
  %t180 = bitcast void (i8*)* @list_release_i32 to i8*
  %t181 = call i8* @star_rc_alloc(i64 24, i8* %t180)
  %t182 = bitcast i8* %t181 to { i32*, i64, i64 }*
  %t183 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t182, i32 0, i32 0
  store i32* null, i32** %t183
  %t184 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t182, i32 0, i32 1
  store i64 0, i64* %t184
  %t185 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t182, i32 0, i32 2
  store i64 0, i64* %t185
  store i8* %t181, i8** %t102
  br label %list_cow_done_46
list_cow_check_45:
  %t186 = getelementptr inbounds i8, i8* %t174, i64 -16
  %t187 = bitcast i8* %t186 to i64*
  %t188 = load atomic i64, i64* %t187 seq_cst, align 8
  %t189 = icmp eq i64 %t188, 1
  br i1 %t189, label %list_cow_done_46, label %list_cow_clone_47
list_cow_clone_47:
  %t190 = bitcast i8* %t174 to { i32*, i64, i64 }*
  %t191 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t190, i32 0, i32 0
  %t192 = load i32*, i32** %t191
  %t193 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t190, i32 0, i32 1
  %t194 = load i64, i64* %t193
  %t195 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t190, i32 0, i32 2
  %t196 = load i64, i64* %t195
  %t197 = bitcast void (i8*)* @list_release_i32 to i8*
  %t198 = call i8* @star_rc_alloc(i64 24, i8* %t197)
  %t199 = bitcast i8* %t198 to { i32*, i64, i64 }*
  %t200 = mul i64 %t196, %t173
  %t201 = call i8* @malloc(i64 %t200)
  %t202 = bitcast i8* %t201 to i32*
  %t203 = icmp sgt i64 %t194, 0
  br i1 %t203, label %list_cow_copy_48, label %list_cow_after_copy_49
list_cow_copy_48:
  %t204 = mul i64 %t194, %t173
  %t205 = bitcast i32* %t192 to i8*
  call i8* @memcpy(i8* %t201, i8* %t205, i64 %t204)
  br label %list_cow_after_copy_49
list_cow_after_copy_49:
  %t206 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t199, i32 0, i32 0
  store i32* %t202, i32** %t206
  %t207 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t199, i32 0, i32 1
  store i64 %t194, i64* %t207
  %t208 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t199, i32 0, i32 2
  store i64 %t196, i64* %t208
  call void @star_rc_release(i8* %t174)
  store i8* %t198, i8** %t102
  br label %list_cow_done_46
list_cow_done_46:
  %t209 = load i8*, i8** %t102
  %t210 = bitcast i8* %t209 to { i32*, i64, i64 }*
  %t211 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t210, i32 0, i32 0
  %t212 = load i32*, i32** %t211
  %t213 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t210, i32 0, i32 1
  %t214 = load i64, i64* %t213
  %t215 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t210, i32 0, i32 2
  %t216 = load i64, i64* %t215
  %t217 = load i32*, i32** %t211
  %t218 = load i64, i64* %t213
  %t219 = icmp sge i64 %t218, %t216
  br i1 %t219, label %list_push_grow_50, label %list_push_store_51
list_push_grow_50:
  %t220 = mul i64 %t216, 2
  %t221 = icmp sgt i64 %t220, 0
  %t222 = select i1 %t221, i64 %t220, i64 1
  %t223 = getelementptr i32, i32* null, i32 1
  %t224 = ptrtoint i32* %t223 to i64
  %t225 = mul i64 %t222, %t224
  %t226 = call i8* @malloc(i64 %t225)
  %t227 = bitcast i8* %t226 to i32*
  %t228 = icmp sgt i64 %t216, 0
  br i1 %t228, label %list_push_copy_52, label %list_push_after_copy_53
list_push_copy_52:
  %t229 = mul i64 %t218, %t224
  %t230 = bitcast i32* %t217 to i8*
  call i8* @memcpy(i8* %t226, i8* %t230, i64 %t229)
  call void @free(i8* %t230)
  br label %list_push_after_copy_53
list_push_after_copy_53:
  store i32* %t227, i32** %t211
  store i64 %t222, i64* %t215
  br label %list_push_store_51
list_push_store_51:
  %t231 = load i32*, i32** %t211
  %t232 = getelementptr inbounds i32, i32* %t231, i64 %t218
  store i32 1, i32* %t232
  %t233 = add i64 %t218, 1
  store i64 %t233, i64* %t213
  br label %if_end_43
if_else_42:
  %t234 = load i32, i32* %t148
  %t235 = icmp eq i32 %t234, 66
  br i1 %t235, label %if_then_54, label %if_else_55
if_then_54:
  %t236 = getelementptr i32, i32* null, i32 1
  %t237 = ptrtoint i32* %t236 to i64
  %t238 = load i8*, i8** %t102
  %t239 = icmp eq i8* %t238, null
  br i1 %t239, label %list_cow_alloc_57, label %list_cow_check_58
list_cow_alloc_57:
  %t240 = bitcast void (i8*)* @list_release_i32 to i8*
  %t241 = call i8* @star_rc_alloc(i64 24, i8* %t240)
  %t242 = bitcast i8* %t241 to { i32*, i64, i64 }*
  %t243 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t242, i32 0, i32 0
  store i32* null, i32** %t243
  %t244 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t242, i32 0, i32 1
  store i64 0, i64* %t244
  %t245 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t242, i32 0, i32 2
  store i64 0, i64* %t245
  store i8* %t241, i8** %t102
  br label %list_cow_done_59
list_cow_check_58:
  %t246 = getelementptr inbounds i8, i8* %t238, i64 -16
  %t247 = bitcast i8* %t246 to i64*
  %t248 = load atomic i64, i64* %t247 seq_cst, align 8
  %t249 = icmp eq i64 %t248, 1
  br i1 %t249, label %list_cow_done_59, label %list_cow_clone_60
list_cow_clone_60:
  %t250 = bitcast i8* %t238 to { i32*, i64, i64 }*
  %t251 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t250, i32 0, i32 0
  %t252 = load i32*, i32** %t251
  %t253 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t250, i32 0, i32 1
  %t254 = load i64, i64* %t253
  %t255 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t250, i32 0, i32 2
  %t256 = load i64, i64* %t255
  %t257 = bitcast void (i8*)* @list_release_i32 to i8*
  %t258 = call i8* @star_rc_alloc(i64 24, i8* %t257)
  %t259 = bitcast i8* %t258 to { i32*, i64, i64 }*
  %t260 = mul i64 %t256, %t237
  %t261 = call i8* @malloc(i64 %t260)
  %t262 = bitcast i8* %t261 to i32*
  %t263 = icmp sgt i64 %t254, 0
  br i1 %t263, label %list_cow_copy_61, label %list_cow_after_copy_62
list_cow_copy_61:
  %t264 = mul i64 %t254, %t237
  %t265 = bitcast i32* %t252 to i8*
  call i8* @memcpy(i8* %t261, i8* %t265, i64 %t264)
  br label %list_cow_after_copy_62
list_cow_after_copy_62:
  %t266 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t259, i32 0, i32 0
  store i32* %t262, i32** %t266
  %t267 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t259, i32 0, i32 1
  store i64 %t254, i64* %t267
  %t268 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t259, i32 0, i32 2
  store i64 %t256, i64* %t268
  call void @star_rc_release(i8* %t238)
  store i8* %t258, i8** %t102
  br label %list_cow_done_59
list_cow_done_59:
  %t269 = load i8*, i8** %t102
  %t270 = bitcast i8* %t269 to { i32*, i64, i64 }*
  %t271 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t270, i32 0, i32 0
  %t272 = load i32*, i32** %t271
  %t273 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t270, i32 0, i32 1
  %t274 = load i64, i64* %t273
  %t275 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t270, i32 0, i32 2
  %t276 = load i64, i64* %t275
  %t277 = load i32*, i32** %t271
  %t278 = load i64, i64* %t273
  %t279 = icmp sge i64 %t278, %t276
  br i1 %t279, label %list_push_grow_63, label %list_push_store_64
list_push_grow_63:
  %t280 = mul i64 %t276, 2
  %t281 = icmp sgt i64 %t280, 0
  %t282 = select i1 %t281, i64 %t280, i64 1
  %t283 = getelementptr i32, i32* null, i32 1
  %t284 = ptrtoint i32* %t283 to i64
  %t285 = mul i64 %t282, %t284
  %t286 = call i8* @malloc(i64 %t285)
  %t287 = bitcast i8* %t286 to i32*
  %t288 = icmp sgt i64 %t276, 0
  br i1 %t288, label %list_push_copy_65, label %list_push_after_copy_66
list_push_copy_65:
  %t289 = mul i64 %t278, %t284
  %t290 = bitcast i32* %t277 to i8*
  call i8* @memcpy(i8* %t286, i8* %t290, i64 %t289)
  call void @free(i8* %t290)
  br label %list_push_after_copy_66
list_push_after_copy_66:
  store i32* %t287, i32** %t271
  store i64 %t282, i64* %t275
  br label %list_push_store_64
list_push_store_64:
  %t291 = load i32*, i32** %t271
  %t292 = getelementptr inbounds i32, i32* %t291, i64 %t278
  store i32 2, i32* %t292
  %t293 = add i64 %t278, 1
  store i64 %t293, i64* %t273
  br label %if_end_56
if_else_55:
  %t294 = load i32, i32* %t148
  %t295 = icmp eq i32 %t294, 71
  br i1 %t295, label %if_then_67, label %if_else_68
if_then_67:
  %t296 = getelementptr i32, i32* null, i32 1
  %t297 = ptrtoint i32* %t296 to i64
  %t298 = load i8*, i8** %t102
  %t299 = icmp eq i8* %t298, null
  br i1 %t299, label %list_cow_alloc_70, label %list_cow_check_71
list_cow_alloc_70:
  %t300 = bitcast void (i8*)* @list_release_i32 to i8*
  %t301 = call i8* @star_rc_alloc(i64 24, i8* %t300)
  %t302 = bitcast i8* %t301 to { i32*, i64, i64 }*
  %t303 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t302, i32 0, i32 0
  store i32* null, i32** %t303
  %t304 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t302, i32 0, i32 1
  store i64 0, i64* %t304
  %t305 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t302, i32 0, i32 2
  store i64 0, i64* %t305
  store i8* %t301, i8** %t102
  br label %list_cow_done_72
list_cow_check_71:
  %t306 = getelementptr inbounds i8, i8* %t298, i64 -16
  %t307 = bitcast i8* %t306 to i64*
  %t308 = load atomic i64, i64* %t307 seq_cst, align 8
  %t309 = icmp eq i64 %t308, 1
  br i1 %t309, label %list_cow_done_72, label %list_cow_clone_73
list_cow_clone_73:
  %t310 = bitcast i8* %t298 to { i32*, i64, i64 }*
  %t311 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t310, i32 0, i32 0
  %t312 = load i32*, i32** %t311
  %t313 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t310, i32 0, i32 1
  %t314 = load i64, i64* %t313
  %t315 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t310, i32 0, i32 2
  %t316 = load i64, i64* %t315
  %t317 = bitcast void (i8*)* @list_release_i32 to i8*
  %t318 = call i8* @star_rc_alloc(i64 24, i8* %t317)
  %t319 = bitcast i8* %t318 to { i32*, i64, i64 }*
  %t320 = mul i64 %t316, %t297
  %t321 = call i8* @malloc(i64 %t320)
  %t322 = bitcast i8* %t321 to i32*
  %t323 = icmp sgt i64 %t314, 0
  br i1 %t323, label %list_cow_copy_74, label %list_cow_after_copy_75
list_cow_copy_74:
  %t324 = mul i64 %t314, %t297
  %t325 = bitcast i32* %t312 to i8*
  call i8* @memcpy(i8* %t321, i8* %t325, i64 %t324)
  br label %list_cow_after_copy_75
list_cow_after_copy_75:
  %t326 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 0
  store i32* %t322, i32** %t326
  %t327 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 1
  store i64 %t314, i64* %t327
  %t328 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t319, i32 0, i32 2
  store i64 %t316, i64* %t328
  call void @star_rc_release(i8* %t298)
  store i8* %t318, i8** %t102
  br label %list_cow_done_72
list_cow_done_72:
  %t329 = load i8*, i8** %t102
  %t330 = bitcast i8* %t329 to { i32*, i64, i64 }*
  %t331 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t330, i32 0, i32 0
  %t332 = load i32*, i32** %t331
  %t333 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t330, i32 0, i32 1
  %t334 = load i64, i64* %t333
  %t335 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t330, i32 0, i32 2
  %t336 = load i64, i64* %t335
  %t337 = load i32*, i32** %t331
  %t338 = load i64, i64* %t333
  %t339 = icmp sge i64 %t338, %t336
  br i1 %t339, label %list_push_grow_76, label %list_push_store_77
list_push_grow_76:
  %t340 = mul i64 %t336, 2
  %t341 = icmp sgt i64 %t340, 0
  %t342 = select i1 %t341, i64 %t340, i64 1
  %t343 = getelementptr i32, i32* null, i32 1
  %t344 = ptrtoint i32* %t343 to i64
  %t345 = mul i64 %t342, %t344
  %t346 = call i8* @malloc(i64 %t345)
  %t347 = bitcast i8* %t346 to i32*
  %t348 = icmp sgt i64 %t336, 0
  br i1 %t348, label %list_push_copy_78, label %list_push_after_copy_79
list_push_copy_78:
  %t349 = mul i64 %t338, %t344
  %t350 = bitcast i32* %t337 to i8*
  call i8* @memcpy(i8* %t346, i8* %t350, i64 %t349)
  call void @free(i8* %t350)
  br label %list_push_after_copy_79
list_push_after_copy_79:
  store i32* %t347, i32** %t331
  store i64 %t342, i64* %t335
  br label %list_push_store_77
list_push_store_77:
  %t351 = load i32*, i32** %t331
  %t352 = getelementptr inbounds i32, i32* %t351, i64 %t338
  store i32 3, i32* %t352
  %t353 = add i64 %t338, 1
  store i64 %t353, i64* %t333
  br label %if_end_69
if_else_68:
  %t354 = getelementptr i32, i32* null, i32 1
  %t355 = ptrtoint i32* %t354 to i64
  %t356 = load i8*, i8** %t102
  %t357 = icmp eq i8* %t356, null
  br i1 %t357, label %list_cow_alloc_80, label %list_cow_check_81
list_cow_alloc_80:
  %t358 = bitcast void (i8*)* @list_release_i32 to i8*
  %t359 = call i8* @star_rc_alloc(i64 24, i8* %t358)
  %t360 = bitcast i8* %t359 to { i32*, i64, i64 }*
  %t361 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t360, i32 0, i32 0
  store i32* null, i32** %t361
  %t362 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t360, i32 0, i32 1
  store i64 0, i64* %t362
  %t363 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t360, i32 0, i32 2
  store i64 0, i64* %t363
  store i8* %t359, i8** %t102
  br label %list_cow_done_82
list_cow_check_81:
  %t364 = getelementptr inbounds i8, i8* %t356, i64 -16
  %t365 = bitcast i8* %t364 to i64*
  %t366 = load atomic i64, i64* %t365 seq_cst, align 8
  %t367 = icmp eq i64 %t366, 1
  br i1 %t367, label %list_cow_done_82, label %list_cow_clone_83
list_cow_clone_83:
  %t368 = bitcast i8* %t356 to { i32*, i64, i64 }*
  %t369 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t368, i32 0, i32 0
  %t370 = load i32*, i32** %t369
  %t371 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t368, i32 0, i32 1
  %t372 = load i64, i64* %t371
  %t373 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t368, i32 0, i32 2
  %t374 = load i64, i64* %t373
  %t375 = bitcast void (i8*)* @list_release_i32 to i8*
  %t376 = call i8* @star_rc_alloc(i64 24, i8* %t375)
  %t377 = bitcast i8* %t376 to { i32*, i64, i64 }*
  %t378 = mul i64 %t374, %t355
  %t379 = call i8* @malloc(i64 %t378)
  %t380 = bitcast i8* %t379 to i32*
  %t381 = icmp sgt i64 %t372, 0
  br i1 %t381, label %list_cow_copy_84, label %list_cow_after_copy_85
list_cow_copy_84:
  %t382 = mul i64 %t372, %t355
  %t383 = bitcast i32* %t370 to i8*
  call i8* @memcpy(i8* %t379, i8* %t383, i64 %t382)
  br label %list_cow_after_copy_85
list_cow_after_copy_85:
  %t384 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t377, i32 0, i32 0
  store i32* %t380, i32** %t384
  %t385 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t377, i32 0, i32 1
  store i64 %t372, i64* %t385
  %t386 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t377, i32 0, i32 2
  store i64 %t374, i64* %t386
  call void @star_rc_release(i8* %t356)
  store i8* %t376, i8** %t102
  br label %list_cow_done_82
list_cow_done_82:
  %t387 = load i8*, i8** %t102
  %t388 = bitcast i8* %t387 to { i32*, i64, i64 }*
  %t389 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t388, i32 0, i32 0
  %t390 = load i32*, i32** %t389
  %t391 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t388, i32 0, i32 1
  %t392 = load i64, i64* %t391
  %t393 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t388, i32 0, i32 2
  %t394 = load i64, i64* %t393
  %t395 = load i32*, i32** %t389
  %t396 = load i64, i64* %t391
  %t397 = icmp sge i64 %t396, %t394
  br i1 %t397, label %list_push_grow_86, label %list_push_store_87
list_push_grow_86:
  %t398 = mul i64 %t394, 2
  %t399 = icmp sgt i64 %t398, 0
  %t400 = select i1 %t399, i64 %t398, i64 1
  %t401 = getelementptr i32, i32* null, i32 1
  %t402 = ptrtoint i32* %t401 to i64
  %t403 = mul i64 %t400, %t402
  %t404 = call i8* @malloc(i64 %t403)
  %t405 = bitcast i8* %t404 to i32*
  %t406 = icmp sgt i64 %t394, 0
  br i1 %t406, label %list_push_copy_88, label %list_push_after_copy_89
list_push_copy_88:
  %t407 = mul i64 %t396, %t402
  %t408 = bitcast i32* %t395 to i8*
  call i8* @memcpy(i8* %t404, i8* %t408, i64 %t407)
  call void @free(i8* %t408)
  br label %list_push_after_copy_89
list_push_after_copy_89:
  store i32* %t405, i32** %t389
  store i64 %t400, i64* %t393
  br label %list_push_store_87
list_push_store_87:
  %t409 = load i32*, i32** %t389
  %t410 = getelementptr inbounds i32, i32* %t409, i64 %t396
  store i32 0, i32* %t410
  %t411 = add i64 %t396, 1
  store i64 %t411, i64* %t391
  %t412 = load i32, i32* %t148
  %t413 = icmp eq i32 %t412, 80
  br i1 %t413, label %if_then_90, label %if_else_91
if_then_90:
  %t414 = load i32, i32* %t165
  store i32 %t414, i32* %t107
  br label %if_end_92
if_else_91:
  %t415 = load i32, i32* %t148
  %t416 = icmp eq i32 %t415, 69
  br i1 %t416, label %if_then_93, label %if_else_94
if_then_93:
  %t417 = getelementptr i32, i32* null, i32 1
  %t418 = ptrtoint i32* %t417 to i64
  %t419 = load i8*, i8** %t103
  %t420 = icmp eq i8* %t419, null
  br i1 %t420, label %list_cow_alloc_96, label %list_cow_check_97
list_cow_alloc_96:
  %t421 = bitcast void (i8*)* @list_release_i32 to i8*
  %t422 = call i8* @star_rc_alloc(i64 24, i8* %t421)
  %t423 = bitcast i8* %t422 to { i32*, i64, i64 }*
  %t424 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t423, i32 0, i32 0
  store i32* null, i32** %t424
  %t425 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t423, i32 0, i32 1
  store i64 0, i64* %t425
  %t426 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t423, i32 0, i32 2
  store i64 0, i64* %t426
  store i8* %t422, i8** %t103
  br label %list_cow_done_98
list_cow_check_97:
  %t427 = getelementptr inbounds i8, i8* %t419, i64 -16
  %t428 = bitcast i8* %t427 to i64*
  %t429 = load atomic i64, i64* %t428 seq_cst, align 8
  %t430 = icmp eq i64 %t429, 1
  br i1 %t430, label %list_cow_done_98, label %list_cow_clone_99
list_cow_clone_99:
  %t431 = bitcast i8* %t419 to { i32*, i64, i64 }*
  %t432 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t431, i32 0, i32 0
  %t433 = load i32*, i32** %t432
  %t434 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t431, i32 0, i32 1
  %t435 = load i64, i64* %t434
  %t436 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t431, i32 0, i32 2
  %t437 = load i64, i64* %t436
  %t438 = bitcast void (i8*)* @list_release_i32 to i8*
  %t439 = call i8* @star_rc_alloc(i64 24, i8* %t438)
  %t440 = bitcast i8* %t439 to { i32*, i64, i64 }*
  %t441 = mul i64 %t437, %t418
  %t442 = call i8* @malloc(i64 %t441)
  %t443 = bitcast i8* %t442 to i32*
  %t444 = icmp sgt i64 %t435, 0
  br i1 %t444, label %list_cow_copy_100, label %list_cow_after_copy_101
list_cow_copy_100:
  %t445 = mul i64 %t435, %t418
  %t446 = bitcast i32* %t433 to i8*
  call i8* @memcpy(i8* %t442, i8* %t446, i64 %t445)
  br label %list_cow_after_copy_101
list_cow_after_copy_101:
  %t447 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t440, i32 0, i32 0
  store i32* %t443, i32** %t447
  %t448 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t440, i32 0, i32 1
  store i64 %t435, i64* %t448
  %t449 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t440, i32 0, i32 2
  store i64 %t437, i64* %t449
  call void @star_rc_release(i8* %t419)
  store i8* %t439, i8** %t103
  br label %list_cow_done_98
list_cow_done_98:
  %t450 = load i8*, i8** %t103
  %t451 = bitcast i8* %t450 to { i32*, i64, i64 }*
  %t452 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t451, i32 0, i32 0
  %t453 = load i32*, i32** %t452
  %t454 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t451, i32 0, i32 1
  %t455 = load i64, i64* %t454
  %t456 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t451, i32 0, i32 2
  %t457 = load i32, i32* %t165
  %t458 = load i64, i64* %t456
  %t459 = load i32*, i32** %t452
  %t460 = load i64, i64* %t454
  %t461 = icmp sge i64 %t460, %t458
  br i1 %t461, label %list_push_grow_102, label %list_push_store_103
list_push_grow_102:
  %t462 = mul i64 %t458, 2
  %t463 = icmp sgt i64 %t462, 0
  %t464 = select i1 %t463, i64 %t462, i64 1
  %t465 = getelementptr i32, i32* null, i32 1
  %t466 = ptrtoint i32* %t465 to i64
  %t467 = mul i64 %t464, %t466
  %t468 = call i8* @malloc(i64 %t467)
  %t469 = bitcast i8* %t468 to i32*
  %t470 = icmp sgt i64 %t458, 0
  br i1 %t470, label %list_push_copy_104, label %list_push_after_copy_105
list_push_copy_104:
  %t471 = mul i64 %t460, %t466
  %t472 = bitcast i32* %t459 to i8*
  call i8* @memcpy(i8* %t468, i8* %t472, i64 %t471)
  call void @free(i8* %t472)
  br label %list_push_after_copy_105
list_push_after_copy_105:
  store i32* %t469, i32** %t452
  store i64 %t464, i64* %t456
  br label %list_push_store_103
list_push_store_103:
  %t473 = load i32*, i32** %t452
  %t474 = getelementptr inbounds i32, i32* %t473, i64 %t460
  store i32 %t457, i32* %t474
  %t475 = add i64 %t460, 1
  store i64 %t475, i64* %t454
  br label %if_end_95
if_else_94:
  %t476 = load i32, i32* %t148
  %t477 = icmp eq i32 %t476, 88
  br i1 %t477, label %if_then_106, label %if_else_107
if_then_106:
  %t478 = getelementptr i32, i32* null, i32 1
  %t479 = ptrtoint i32* %t478 to i64
  %t480 = load i8*, i8** %t104
  %t481 = icmp eq i8* %t480, null
  br i1 %t481, label %list_cow_alloc_109, label %list_cow_check_110
list_cow_alloc_109:
  %t482 = bitcast void (i8*)* @list_release_i32 to i8*
  %t483 = call i8* @star_rc_alloc(i64 24, i8* %t482)
  %t484 = bitcast i8* %t483 to { i32*, i64, i64 }*
  %t485 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 0
  store i32* null, i32** %t485
  %t486 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 1
  store i64 0, i64* %t486
  %t487 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 2
  store i64 0, i64* %t487
  store i8* %t483, i8** %t104
  br label %list_cow_done_111
list_cow_check_110:
  %t488 = getelementptr inbounds i8, i8* %t480, i64 -16
  %t489 = bitcast i8* %t488 to i64*
  %t490 = load atomic i64, i64* %t489 seq_cst, align 8
  %t491 = icmp eq i64 %t490, 1
  br i1 %t491, label %list_cow_done_111, label %list_cow_clone_112
list_cow_clone_112:
  %t492 = bitcast i8* %t480 to { i32*, i64, i64 }*
  %t493 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t492, i32 0, i32 0
  %t494 = load i32*, i32** %t493
  %t495 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t492, i32 0, i32 1
  %t496 = load i64, i64* %t495
  %t497 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t492, i32 0, i32 2
  %t498 = load i64, i64* %t497
  %t499 = bitcast void (i8*)* @list_release_i32 to i8*
  %t500 = call i8* @star_rc_alloc(i64 24, i8* %t499)
  %t501 = bitcast i8* %t500 to { i32*, i64, i64 }*
  %t502 = mul i64 %t498, %t479
  %t503 = call i8* @malloc(i64 %t502)
  %t504 = bitcast i8* %t503 to i32*
  %t505 = icmp sgt i64 %t496, 0
  br i1 %t505, label %list_cow_copy_113, label %list_cow_after_copy_114
list_cow_copy_113:
  %t506 = mul i64 %t496, %t479
  %t507 = bitcast i32* %t494 to i8*
  call i8* @memcpy(i8* %t503, i8* %t507, i64 %t506)
  br label %list_cow_after_copy_114
list_cow_after_copy_114:
  %t508 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t501, i32 0, i32 0
  store i32* %t504, i32** %t508
  %t509 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t501, i32 0, i32 1
  store i64 %t496, i64* %t509
  %t510 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t501, i32 0, i32 2
  store i64 %t498, i64* %t510
  call void @star_rc_release(i8* %t480)
  store i8* %t500, i8** %t104
  br label %list_cow_done_111
list_cow_done_111:
  %t511 = load i8*, i8** %t104
  %t512 = bitcast i8* %t511 to { i32*, i64, i64 }*
  %t513 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t512, i32 0, i32 0
  %t514 = load i32*, i32** %t513
  %t515 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t512, i32 0, i32 1
  %t516 = load i64, i64* %t515
  %t517 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t512, i32 0, i32 2
  %t518 = load i32, i32* %t165
  %t519 = load i64, i64* %t517
  %t520 = load i32*, i32** %t513
  %t521 = load i64, i64* %t515
  %t522 = icmp sge i64 %t521, %t519
  br i1 %t522, label %list_push_grow_115, label %list_push_store_116
list_push_grow_115:
  %t523 = mul i64 %t519, 2
  %t524 = icmp sgt i64 %t523, 0
  %t525 = select i1 %t524, i64 %t523, i64 1
  %t526 = getelementptr i32, i32* null, i32 1
  %t527 = ptrtoint i32* %t526 to i64
  %t528 = mul i64 %t525, %t527
  %t529 = call i8* @malloc(i64 %t528)
  %t530 = bitcast i8* %t529 to i32*
  %t531 = icmp sgt i64 %t519, 0
  br i1 %t531, label %list_push_copy_117, label %list_push_after_copy_118
list_push_copy_117:
  %t532 = mul i64 %t521, %t527
  %t533 = bitcast i32* %t520 to i8*
  call i8* @memcpy(i8* %t529, i8* %t533, i64 %t532)
  call void @free(i8* %t533)
  br label %list_push_after_copy_118
list_push_after_copy_118:
  store i32* %t530, i32** %t513
  store i64 %t525, i64* %t517
  br label %list_push_store_116
list_push_store_116:
  %t534 = load i32*, i32** %t513
  %t535 = getelementptr inbounds i32, i32* %t534, i64 %t521
  store i32 %t518, i32* %t535
  %t536 = add i64 %t521, 1
  store i64 %t536, i64* %t515
  br label %if_end_108
if_else_107:
  %t537 = load i32, i32* %t148
  %t538 = icmp eq i32 %t537, 104
  br i1 %t538, label %if_then_119, label %if_else_120
if_then_119:
  %t539 = getelementptr i32, i32* null, i32 1
  %t540 = ptrtoint i32* %t539 to i64
  %t541 = load i8*, i8** %t105
  %t542 = icmp eq i8* %t541, null
  br i1 %t542, label %list_cow_alloc_122, label %list_cow_check_123
list_cow_alloc_122:
  %t543 = bitcast void (i8*)* @list_release_i32 to i8*
  %t544 = call i8* @star_rc_alloc(i64 24, i8* %t543)
  %t545 = bitcast i8* %t544 to { i32*, i64, i64 }*
  %t546 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t545, i32 0, i32 0
  store i32* null, i32** %t546
  %t547 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t545, i32 0, i32 1
  store i64 0, i64* %t547
  %t548 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t545, i32 0, i32 2
  store i64 0, i64* %t548
  store i8* %t544, i8** %t105
  br label %list_cow_done_124
list_cow_check_123:
  %t549 = getelementptr inbounds i8, i8* %t541, i64 -16
  %t550 = bitcast i8* %t549 to i64*
  %t551 = load atomic i64, i64* %t550 seq_cst, align 8
  %t552 = icmp eq i64 %t551, 1
  br i1 %t552, label %list_cow_done_124, label %list_cow_clone_125
list_cow_clone_125:
  %t553 = bitcast i8* %t541 to { i32*, i64, i64 }*
  %t554 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t553, i32 0, i32 0
  %t555 = load i32*, i32** %t554
  %t556 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t553, i32 0, i32 1
  %t557 = load i64, i64* %t556
  %t558 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t553, i32 0, i32 2
  %t559 = load i64, i64* %t558
  %t560 = bitcast void (i8*)* @list_release_i32 to i8*
  %t561 = call i8* @star_rc_alloc(i64 24, i8* %t560)
  %t562 = bitcast i8* %t561 to { i32*, i64, i64 }*
  %t563 = mul i64 %t559, %t540
  %t564 = call i8* @malloc(i64 %t563)
  %t565 = bitcast i8* %t564 to i32*
  %t566 = icmp sgt i64 %t557, 0
  br i1 %t566, label %list_cow_copy_126, label %list_cow_after_copy_127
list_cow_copy_126:
  %t567 = mul i64 %t557, %t540
  %t568 = bitcast i32* %t555 to i8*
  call i8* @memcpy(i8* %t564, i8* %t568, i64 %t567)
  br label %list_cow_after_copy_127
list_cow_after_copy_127:
  %t569 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t562, i32 0, i32 0
  store i32* %t565, i32** %t569
  %t570 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t562, i32 0, i32 1
  store i64 %t557, i64* %t570
  %t571 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t562, i32 0, i32 2
  store i64 %t559, i64* %t571
  call void @star_rc_release(i8* %t541)
  store i8* %t561, i8** %t105
  br label %list_cow_done_124
list_cow_done_124:
  %t572 = load i8*, i8** %t105
  %t573 = bitcast i8* %t572 to { i32*, i64, i64 }*
  %t574 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t573, i32 0, i32 0
  %t575 = load i32*, i32** %t574
  %t576 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t573, i32 0, i32 1
  %t577 = load i64, i64* %t576
  %t578 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t573, i32 0, i32 2
  %t579 = load i32, i32* %t165
  %t580 = load i64, i64* %t578
  %t581 = load i32*, i32** %t574
  %t582 = load i64, i64* %t576
  %t583 = icmp sge i64 %t582, %t580
  br i1 %t583, label %list_push_grow_128, label %list_push_store_129
list_push_grow_128:
  %t584 = mul i64 %t580, 2
  %t585 = icmp sgt i64 %t584, 0
  %t586 = select i1 %t585, i64 %t584, i64 1
  %t587 = getelementptr i32, i32* null, i32 1
  %t588 = ptrtoint i32* %t587 to i64
  %t589 = mul i64 %t586, %t588
  %t590 = call i8* @malloc(i64 %t589)
  %t591 = bitcast i8* %t590 to i32*
  %t592 = icmp sgt i64 %t580, 0
  br i1 %t592, label %list_push_copy_130, label %list_push_after_copy_131
list_push_copy_130:
  %t593 = mul i64 %t582, %t588
  %t594 = bitcast i32* %t581 to i8*
  call i8* @memcpy(i8* %t590, i8* %t594, i64 %t593)
  call void @free(i8* %t594)
  br label %list_push_after_copy_131
list_push_after_copy_131:
  store i32* %t591, i32** %t574
  store i64 %t586, i64* %t578
  br label %list_push_store_129
list_push_store_129:
  %t595 = load i32*, i32** %t574
  %t596 = getelementptr inbounds i32, i32* %t595, i64 %t582
  store i32 %t579, i32* %t596
  %t597 = add i64 %t582, 1
  store i64 %t597, i64* %t576
  br label %if_end_121
if_else_120:
  %t598 = load i32, i32* %t148
  %t599 = icmp eq i32 %t598, 109
  br i1 %t599, label %if_then_132, label %if_else_133
if_then_132:
  %t600 = getelementptr i32, i32* null, i32 1
  %t601 = ptrtoint i32* %t600 to i64
  %t602 = load i8*, i8** %t106
  %t603 = icmp eq i8* %t602, null
  br i1 %t603, label %list_cow_alloc_135, label %list_cow_check_136
list_cow_alloc_135:
  %t604 = bitcast void (i8*)* @list_release_i32 to i8*
  %t605 = call i8* @star_rc_alloc(i64 24, i8* %t604)
  %t606 = bitcast i8* %t605 to { i32*, i64, i64 }*
  %t607 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t606, i32 0, i32 0
  store i32* null, i32** %t607
  %t608 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t606, i32 0, i32 1
  store i64 0, i64* %t608
  %t609 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t606, i32 0, i32 2
  store i64 0, i64* %t609
  store i8* %t605, i8** %t106
  br label %list_cow_done_137
list_cow_check_136:
  %t610 = getelementptr inbounds i8, i8* %t602, i64 -16
  %t611 = bitcast i8* %t610 to i64*
  %t612 = load atomic i64, i64* %t611 seq_cst, align 8
  %t613 = icmp eq i64 %t612, 1
  br i1 %t613, label %list_cow_done_137, label %list_cow_clone_138
list_cow_clone_138:
  %t614 = bitcast i8* %t602 to { i32*, i64, i64 }*
  %t615 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t614, i32 0, i32 0
  %t616 = load i32*, i32** %t615
  %t617 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t614, i32 0, i32 1
  %t618 = load i64, i64* %t617
  %t619 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t614, i32 0, i32 2
  %t620 = load i64, i64* %t619
  %t621 = bitcast void (i8*)* @list_release_i32 to i8*
  %t622 = call i8* @star_rc_alloc(i64 24, i8* %t621)
  %t623 = bitcast i8* %t622 to { i32*, i64, i64 }*
  %t624 = mul i64 %t620, %t601
  %t625 = call i8* @malloc(i64 %t624)
  %t626 = bitcast i8* %t625 to i32*
  %t627 = icmp sgt i64 %t618, 0
  br i1 %t627, label %list_cow_copy_139, label %list_cow_after_copy_140
list_cow_copy_139:
  %t628 = mul i64 %t618, %t601
  %t629 = bitcast i32* %t616 to i8*
  call i8* @memcpy(i8* %t625, i8* %t629, i64 %t628)
  br label %list_cow_after_copy_140
list_cow_after_copy_140:
  %t630 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t623, i32 0, i32 0
  store i32* %t626, i32** %t630
  %t631 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t623, i32 0, i32 1
  store i64 %t618, i64* %t631
  %t632 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t623, i32 0, i32 2
  store i64 %t620, i64* %t632
  call void @star_rc_release(i8* %t602)
  store i8* %t622, i8** %t106
  br label %list_cow_done_137
list_cow_done_137:
  %t633 = load i8*, i8** %t106
  %t634 = bitcast i8* %t633 to { i32*, i64, i64 }*
  %t635 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t634, i32 0, i32 0
  %t636 = load i32*, i32** %t635
  %t637 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t634, i32 0, i32 1
  %t638 = load i64, i64* %t637
  %t639 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t634, i32 0, i32 2
  %t640 = load i32, i32* %t165
  %t641 = load i64, i64* %t639
  %t642 = load i32*, i32** %t635
  %t643 = load i64, i64* %t637
  %t644 = icmp sge i64 %t643, %t641
  br i1 %t644, label %list_push_grow_141, label %list_push_store_142
list_push_grow_141:
  %t645 = mul i64 %t641, 2
  %t646 = icmp sgt i64 %t645, 0
  %t647 = select i1 %t646, i64 %t645, i64 1
  %t648 = getelementptr i32, i32* null, i32 1
  %t649 = ptrtoint i32* %t648 to i64
  %t650 = mul i64 %t647, %t649
  %t651 = call i8* @malloc(i64 %t650)
  %t652 = bitcast i8* %t651 to i32*
  %t653 = icmp sgt i64 %t641, 0
  br i1 %t653, label %list_push_copy_143, label %list_push_after_copy_144
list_push_copy_143:
  %t654 = mul i64 %t643, %t649
  %t655 = bitcast i32* %t642 to i8*
  call i8* @memcpy(i8* %t651, i8* %t655, i64 %t654)
  call void @free(i8* %t655)
  br label %list_push_after_copy_144
list_push_after_copy_144:
  store i32* %t652, i32** %t635
  store i64 %t647, i64* %t639
  br label %list_push_store_142
list_push_store_142:
  %t656 = load i32*, i32** %t635
  %t657 = getelementptr inbounds i32, i32* %t656, i64 %t643
  store i32 %t640, i32* %t657
  %t658 = add i64 %t643, 1
  store i64 %t658, i64* %t637
  br label %if_end_134
if_else_133:
  br label %if_end_134
if_end_134:
  br label %if_end_121
if_end_121:
  br label %if_end_108
if_end_108:
  br label %if_end_95
if_end_95:
  br label %if_end_92
if_end_92:
  br label %if_end_69
if_end_69:
  br label %if_end_56
if_end_56:
  br label %if_end_43
if_end_43:
  %t659 = load i32, i32* %t145
  %t660 = add i32 %t659, 1
  store i32 %t660, i32* %t145
  br label %while_cond_31
while_else_33:
  br label %while_end_34
while_end_34:
  %t661 = load i32, i32* %t108
  %t662 = add i32 %t661, 1
  store i32 %t662, i32* %t108
  %t663 = load i8*, i8** %t129
  call void @star_rc_release(i8* %t663)
  %t664 = load i8*, i8** %t111
  call void @star_rc_release(i8* %t664)
  br label %while_cond_21
while_else_23:
  br label %while_end_24
while_end_24:
  %t666 = getelementptr inbounds %map__Level, %map__Level* %t665, i32 0, i32 0
  %t667 = load i8*, i8** %t102
  %t668 = load i8*, i8** %t102
  call void @star_rc_retain(i8* %t668)
  store i8* %t667, i8** %t666
  %t669 = getelementptr inbounds %map__Level, %map__Level* %t665, i32 0, i32 1
  %t670 = load i8*, i8** %t103
  %t671 = load i8*, i8** %t103
  call void @star_rc_retain(i8* %t671)
  store i8* %t670, i8** %t669
  %t672 = getelementptr inbounds %map__Level, %map__Level* %t665, i32 0, i32 2
  %t673 = load i8*, i8** %t104
  %t674 = load i8*, i8** %t104
  call void @star_rc_retain(i8* %t674)
  store i8* %t673, i8** %t672
  %t675 = getelementptr inbounds %map__Level, %map__Level* %t665, i32 0, i32 3
  %t676 = load i8*, i8** %t105
  %t677 = load i8*, i8** %t105
  call void @star_rc_retain(i8* %t677)
  store i8* %t676, i8** %t675
  %t678 = getelementptr inbounds %map__Level, %map__Level* %t665, i32 0, i32 4
  %t679 = load i8*, i8** %t106
  %t680 = load i8*, i8** %t106
  call void @star_rc_retain(i8* %t680)
  store i8* %t679, i8** %t678
  %t681 = getelementptr inbounds %map__Level, %map__Level* %t665, i32 0, i32 5
  %t682 = load i32, i32* %t107
  store i32 %t682, i32* %t681
  %t683 = getelementptr inbounds %map__Level, %map__Level* %t665, i32 0, i32 6
  store float 0x0000000000000000, float* %t683
  %t684 = load %map__Level, %map__Level* %t665
  %t685 = load i8*, i8** %t106
  call void @star_rc_release(i8* %t685)
  %t686 = load i8*, i8** %t105
  call void @star_rc_release(i8* %t686)
  %t687 = load i8*, i8** %t104
  call void @star_rc_release(i8* %t687)
  %t688 = load i8*, i8** %t103
  call void @star_rc_release(i8* %t688)
  %t689 = load i8*, i8** %t102
  call void @star_rc_release(i8* %t689)
  %t690 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t690)
  ret %map__Level %t684
}

define i32 @map__cell_at(i8* %map, i32 %cx, i32 %cy) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t2 = alloca i32
  store i8* %map, i8** %t0
  store i32 %cx, i32* %t1
  store i32 %cy, i32* %t2
  %t3 = load i32, i32* %t1
  %t4 = icmp slt i32 %t3, 0
  br i1 %t4, label %logic_short_146, label %logic_rhs_145
logic_rhs_145:
  %t5 = load i32, i32* %t2
  %t6 = icmp slt i32 %t5, 0
  br label %logic_end_147
logic_short_146:
  br label %logic_end_147
logic_end_147:
  %t7 = phi i1 [ %t6, %logic_rhs_145 ], [ true, %logic_short_146 ]
  br i1 %t7, label %logic_short_149, label %logic_rhs_148
logic_rhs_148:
  %t8 = load i32, i32* %t1
  %t9 = icmp sge i32 %t8, 16
  br label %logic_end_150
logic_short_149:
  br label %logic_end_150
logic_end_150:
  %t10 = phi i1 [ %t9, %logic_rhs_148 ], [ true, %logic_short_149 ]
  br i1 %t10, label %logic_short_152, label %logic_rhs_151
logic_rhs_151:
  %t11 = load i32, i32* %t2
  %t12 = icmp sge i32 %t11, 16
  br label %logic_end_153
logic_short_152:
  br label %logic_end_153
logic_end_153:
  %t13 = phi i1 [ %t12, %logic_rhs_151 ], [ true, %logic_short_152 ]
  br i1 %t13, label %if_then_154, label %if_else_155
if_then_154:
  %t14 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t14)
  ret i32 1
if_else_155:
  br label %if_end_156
if_end_156:
  %t15 = load i8*, i8** %t0
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %list_read_null_157, label %list_read_real_158
list_read_null_157:
  br label %list_read_end_159
list_read_real_158:
  %t17 = bitcast i8* %t15 to { i32*, i64, i64 }*
  %t18 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 0
  %t19 = load i32*, i32** %t18
  %t20 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 1
  %t21 = load i64, i64* %t20
  br label %list_read_end_159
list_read_end_159:
  %t22 = phi i32* [ null, %list_read_null_157 ], [ %t19, %list_read_real_158 ]
  %t23 = phi i64 [ 0, %list_read_null_157 ], [ %t21, %list_read_real_158 ]
  %t24 = load i32, i32* %t2
  %t25 = mul i32 %t24, 16
  %t26 = load i32, i32* %t1
  %t27 = add i32 %t25, %t26
  %t28 = sext i32 %t27 to i64
  %t29 = icmp ult i64 %t28, %t23
  br i1 %t29, label %list_idx_ok_160, label %list_idx_oob_161
list_idx_ok_160:
  %t30 = getelementptr inbounds i32, i32* %t22, i64 %t28
  %t31 = load i32, i32* %t30
  br label %list_idx_end_162
list_idx_oob_161:
  br label %list_idx_end_162
list_idx_end_162:
  %t32 = phi i32 [ %t31, %list_idx_ok_160 ], [ 0, %list_idx_oob_161 ]
  %t33 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t33)
  ret i32 %t32
}

define float @map__cell_center_x(i32 %idx) {
entry:
  %t0 = alloca i32
  store i32 %idx, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp eq i32 16, 0
  %t3 = icmp eq i32 %t1, -2147483648
  %t4 = icmp eq i32 16, -1
  %t5 = and i1 %t3, %t4
  %t6 = or i1 %t2, %t5
  br i1 %t6, label %int_div_fail_163, label %int_div_ok_164
int_div_fail_163:
  %t7 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.2, i64 0, i64 0
  call i32 @puts(i8* %t7)
  call void @exit(i32 1)
  unreachable
int_div_ok_164:
  %t8 = srem i32 %t1, 16
  %t9 = sitofp i32 %t8 to float
  %t10 = fadd float %t9, 0x3FE0000000000000
  ret float %t10
}

define float @map__cell_center_y(i32 %idx) {
entry:
  %t0 = alloca i32
  store i32 %idx, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp eq i32 16, 0
  %t3 = icmp eq i32 %t1, -2147483648
  %t4 = icmp eq i32 16, -1
  %t5 = and i1 %t3, %t4
  %t6 = or i1 %t2, %t5
  br i1 %t6, label %int_div_fail_165, label %int_div_ok_166
int_div_fail_165:
  %t7 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.3, i64 0, i64 0
  call i32 @puts(i8* %t7)
  call void @exit(i32 1)
  unreachable
int_div_ok_166:
  %t8 = sdiv i32 %t1, 16
  %t9 = sitofp i32 %t8 to float
  %t10 = fadd float %t9, 0x3FE0000000000000
  ret float %t10
}

define { i32, i32, i32 } @map__wall_base(i32 %kind) {
entry:
  %t0 = alloca i32
  %t3 = alloca { i32, i32, i32 }
  %t10 = alloca { i32, i32, i32 }
  %t15 = alloca { i32, i32, i32 }
  store i32 %kind, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp eq i32 %t1, 2
  br i1 %t2, label %if_then_167, label %if_else_168
if_then_167:
  %t4 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t3, i32 0, i32 0
  store i32 150, i32* %t4
  %t5 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t3, i32 0, i32 1
  store i32 70, i32* %t5
  %t6 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t3, i32 0, i32 2
  store i32 50, i32* %t6
  %t7 = load { i32, i32, i32 }, { i32, i32, i32 }* %t3
  ret { i32, i32, i32 } %t7
if_else_168:
  br label %if_end_169
if_end_169:
  %t8 = load i32, i32* %t0
  %t9 = icmp eq i32 %t8, 3
  br i1 %t9, label %if_then_170, label %if_else_171
if_then_170:
  %t11 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t10, i32 0, i32 0
  store i32 70, i32* %t11
  %t12 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t10, i32 0, i32 1
  store i32 115, i32* %t12
  %t13 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t10, i32 0, i32 2
  store i32 65, i32* %t13
  %t14 = load { i32, i32, i32 }, { i32, i32, i32 }* %t10
  ret { i32, i32, i32 } %t14
if_else_171:
  br label %if_end_172
if_end_172:
  %t16 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t15, i32 0, i32 0
  store i32 120, i32* %t16
  %t17 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t15, i32 0, i32 1
  store i32 112, i32* %t17
  %t18 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t15, i32 0, i32 2
  store i32 104, i32* %t18
  %t19 = load { i32, i32, i32 }, { i32, i32, i32 }* %t15
  ret { i32, i32, i32 } %t19
}

define { i32, i32, i32, i32 } @sprites__legend_color(i32 %ch) {
entry:
  %t0 = alloca i32
  %t3 = alloca { i32, i32, i32, i32 }
  %t11 = alloca { i32, i32, i32, i32 }
  %t19 = alloca { i32, i32, i32, i32 }
  %t27 = alloca { i32, i32, i32, i32 }
  %t35 = alloca { i32, i32, i32, i32 }
  %t43 = alloca { i32, i32, i32, i32 }
  %t51 = alloca { i32, i32, i32, i32 }
  %t59 = alloca { i32, i32, i32, i32 }
  %t67 = alloca { i32, i32, i32, i32 }
  %t75 = alloca { i32, i32, i32, i32 }
  %t83 = alloca { i32, i32, i32, i32 }
  %t91 = alloca { i32, i32, i32, i32 }
  %t97 = alloca { i32, i32, i32, i32 }
  store i32 %ch, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp eq i32 %t1, 82
  br i1 %t2, label %if_then_173, label %if_else_174
if_then_173:
  %t4 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t3, i32 0, i32 0
  store i32 200, i32* %t4
  %t5 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t3, i32 0, i32 1
  store i32 40, i32* %t5
  %t6 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t3, i32 0, i32 2
  store i32 40, i32* %t6
  %t7 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t3, i32 0, i32 3
  store i32 255, i32* %t7
  %t8 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t3
  ret { i32, i32, i32, i32 } %t8
if_else_174:
  br label %if_end_175
if_end_175:
  %t9 = load i32, i32* %t0
  %t10 = icmp eq i32 %t9, 114
  br i1 %t10, label %if_then_176, label %if_else_177
if_then_176:
  %t12 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t11, i32 0, i32 0
  store i32 120, i32* %t12
  %t13 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t11, i32 0, i32 1
  store i32 20, i32* %t13
  %t14 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t11, i32 0, i32 2
  store i32 20, i32* %t14
  %t15 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t11, i32 0, i32 3
  store i32 255, i32* %t15
  %t16 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t11
  ret { i32, i32, i32, i32 } %t16
if_else_177:
  br label %if_end_178
if_end_178:
  %t17 = load i32, i32* %t0
  %t18 = icmp eq i32 %t17, 89
  br i1 %t18, label %if_then_179, label %if_else_180
if_then_179:
  %t20 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t19, i32 0, i32 0
  store i32 240, i32* %t20
  %t21 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t19, i32 0, i32 1
  store i32 220, i32* %t21
  %t22 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t19, i32 0, i32 2
  store i32 60, i32* %t22
  %t23 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t19, i32 0, i32 3
  store i32 255, i32* %t23
  %t24 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t19
  ret { i32, i32, i32, i32 } %t24
if_else_180:
  br label %if_end_181
if_end_181:
  %t25 = load i32, i32* %t0
  %t26 = icmp eq i32 %t25, 79
  br i1 %t26, label %if_then_182, label %if_else_183
if_then_182:
  %t28 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t27, i32 0, i32 0
  store i32 240, i32* %t28
  %t29 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t27, i32 0, i32 1
  store i32 140, i32* %t29
  %t30 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t27, i32 0, i32 2
  store i32 40, i32* %t30
  %t31 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t27, i32 0, i32 3
  store i32 255, i32* %t31
  %t32 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t27
  ret { i32, i32, i32, i32 } %t32
if_else_183:
  br label %if_end_184
if_end_184:
  %t33 = load i32, i32* %t0
  %t34 = icmp eq i32 %t33, 66
  br i1 %t34, label %if_then_185, label %if_else_186
if_then_185:
  %t36 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t35, i32 0, i32 0
  store i32 120, i32* %t36
  %t37 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t35, i32 0, i32 1
  store i32 80, i32* %t37
  %t38 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t35, i32 0, i32 2
  store i32 50, i32* %t38
  %t39 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t35, i32 0, i32 3
  store i32 255, i32* %t39
  %t40 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t35
  ret { i32, i32, i32, i32 } %t40
if_else_186:
  br label %if_end_187
if_end_187:
  %t41 = load i32, i32* %t0
  %t42 = icmp eq i32 %t41, 98
  br i1 %t42, label %if_then_188, label %if_else_189
if_then_188:
  %t44 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t43, i32 0, i32 0
  store i32 70, i32* %t44
  %t45 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t43, i32 0, i32 1
  store i32 45, i32* %t45
  %t46 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t43, i32 0, i32 2
  store i32 30, i32* %t46
  %t47 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t43, i32 0, i32 3
  store i32 255, i32* %t47
  %t48 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t43
  ret { i32, i32, i32, i32 } %t48
if_else_189:
  br label %if_end_190
if_end_190:
  %t49 = load i32, i32* %t0
  %t50 = icmp eq i32 %t49, 87
  br i1 %t50, label %if_then_191, label %if_else_192
if_then_191:
  %t52 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t51, i32 0, i32 0
  store i32 240, i32* %t52
  %t53 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t51, i32 0, i32 1
  store i32 240, i32* %t53
  %t54 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t51, i32 0, i32 2
  store i32 240, i32* %t54
  %t55 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t51, i32 0, i32 3
  store i32 255, i32* %t55
  %t56 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t51
  ret { i32, i32, i32, i32 } %t56
if_else_192:
  br label %if_end_193
if_end_193:
  %t57 = load i32, i32* %t0
  %t58 = icmp eq i32 %t57, 71
  br i1 %t58, label %if_then_194, label %if_else_195
if_then_194:
  %t60 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t59, i32 0, i32 0
  store i32 60, i32* %t60
  %t61 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t59, i32 0, i32 1
  store i32 200, i32* %t61
  %t62 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t59, i32 0, i32 2
  store i32 60, i32* %t62
  %t63 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t59, i32 0, i32 3
  store i32 255, i32* %t63
  %t64 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t59
  ret { i32, i32, i32, i32 } %t64
if_else_195:
  br label %if_end_196
if_end_196:
  %t65 = load i32, i32* %t0
  %t66 = icmp eq i32 %t65, 103
  br i1 %t66, label %if_then_197, label %if_else_198
if_then_197:
  %t68 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t67, i32 0, i32 0
  store i32 30, i32* %t68
  %t69 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t67, i32 0, i32 1
  store i32 120, i32* %t69
  %t70 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t67, i32 0, i32 2
  store i32 30, i32* %t70
  %t71 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t67, i32 0, i32 3
  store i32 255, i32* %t71
  %t72 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t67
  ret { i32, i32, i32, i32 } %t72
if_else_198:
  br label %if_end_199
if_end_199:
  %t73 = load i32, i32* %t0
  %t74 = icmp eq i32 %t73, 67
  br i1 %t74, label %if_then_200, label %if_else_201
if_then_200:
  %t76 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t75, i32 0, i32 0
  store i32 60, i32* %t76
  %t77 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t75, i32 0, i32 1
  store i32 200, i32* %t77
  %t78 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t75, i32 0, i32 2
  store i32 200, i32* %t78
  %t79 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t75, i32 0, i32 3
  store i32 255, i32* %t79
  %t80 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t75
  ret { i32, i32, i32, i32 } %t80
if_else_201:
  br label %if_end_202
if_end_202:
  %t81 = load i32, i32* %t0
  %t82 = icmp eq i32 %t81, 99
  br i1 %t82, label %if_then_203, label %if_else_204
if_then_203:
  %t84 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t83, i32 0, i32 0
  store i32 30, i32* %t84
  %t85 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t83, i32 0, i32 1
  store i32 120, i32* %t85
  %t86 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t83, i32 0, i32 2
  store i32 120, i32* %t86
  %t87 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t83, i32 0, i32 3
  store i32 255, i32* %t87
  %t88 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t83
  ret { i32, i32, i32, i32 } %t88
if_else_204:
  br label %if_end_205
if_end_205:
  %t89 = load i32, i32* %t0
  %t90 = icmp eq i32 %t89, 77
  br i1 %t90, label %if_then_206, label %if_else_207
if_then_206:
  %t92 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t91, i32 0, i32 0
  store i32 200, i32* %t92
  %t93 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t91, i32 0, i32 1
  store i32 60, i32* %t93
  %t94 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t91, i32 0, i32 2
  store i32 200, i32* %t94
  %t95 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t91, i32 0, i32 3
  store i32 255, i32* %t95
  %t96 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t91
  ret { i32, i32, i32, i32 } %t96
if_else_207:
  br label %if_end_208
if_end_208:
  %t98 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t97, i32 0, i32 0
  store i32 0, i32* %t98
  %t99 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t97, i32 0, i32 1
  store i32 0, i32* %t99
  %t100 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t97, i32 0, i32 2
  store i32 0, i32* %t100
  %t101 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t97, i32 0, i32 3
  store i32 0, i32* %t101
  %t102 = load { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t97
  ret { i32, i32, i32, i32 } %t102
}

define i8* @sprites__parse_sprite(i8* %art) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t11 = alloca i8**
  %t12 = alloca i64
  %t13 = alloca i64
  %t35 = alloca i8*
  %t92 = alloca i8*
  %t93 = alloca i32
  %t96 = alloca i8*
  %t114 = alloca i8*
  %t126 = alloca i32
  %t129 = alloca i32
  %t146 = alloca { i32, i32, i32, i32 }
  store i8* %art, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t5 = icmp eq i8* %t2, null
  %t6 = select i1 %t5, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t2
  %t7 = icmp eq i8* %t4, null
  %t8 = select i1 %t7, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t4
  %t9 = call i32 @strlen(i8* %t8)
  %t10 = sext i32 %t9 to i64
  store i8** null, i8*** %t11
  store i64 0, i64* %t12
  store i64 0, i64* %t13
  %t14 = icmp eq i64 %t10, 0
  br i1 %t14, label %split_single_209, label %split_scan_init_210
split_single_209:
  %t15 = call i32 @strlen(i8* %t6)
  %t16 = sext i32 %t15 to i64
  %t17 = add i64 %t16, 1
  %t18 = call i8* @star_rc_alloc(i64 %t17, i8* null)
  call i8* @strcpy(i8* %t18, i8* %t6)
  %t19 = load i64, i64* %t12
  %t20 = load i64, i64* %t13
  %t21 = icmp sge i64 %t19, %t20
  br i1 %t21, label %dynstr_grow_212, label %dynstr_store_213
dynstr_grow_212:
  %t22 = mul i64 %t20, 2
  %t23 = icmp sgt i64 %t22, 0
  %t24 = select i1 %t23, i64 %t22, i64 4
  %t25 = mul i64 %t24, 8
  %t26 = call i8* @malloc(i64 %t25)
  %t27 = bitcast i8* %t26 to i8**
  %t28 = icmp sgt i64 %t20, 0
  br i1 %t28, label %dynstr_copy_214, label %dynstr_after_copy_215
dynstr_copy_214:
  %t29 = load i8**, i8*** %t11
  %t30 = mul i64 %t19, 8
  %t31 = bitcast i8** %t29 to i8*
  call i8* @memcpy(i8* %t26, i8* %t31, i64 %t30)
  call void @free(i8* %t31)
  br label %dynstr_after_copy_215
dynstr_after_copy_215:
  store i8** %t27, i8*** %t11
  store i64 %t24, i64* %t13
  br label %dynstr_store_213
dynstr_store_213:
  %t32 = load i8**, i8*** %t11
  %t33 = getelementptr inbounds i8*, i8** %t32, i64 %t19
  store i8* %t18, i8** %t33
  %t34 = add i64 %t19, 1
  store i64 %t34, i64* %t12
  br label %split_finish_211
split_scan_init_210:
  store i8* %t6, i8** %t35
  br label %split_scan_cond_216
split_scan_cond_216:
  %t36 = load i8*, i8** %t35
  %t37 = call i8* @strstr(i8* %t36, i8* %t8)
  %t38 = icmp eq i8* %t37, null
  br i1 %t38, label %split_tail_218, label %split_match_217
split_match_217:
  %t39 = ptrtoint i8* %t37 to i64
  %t40 = ptrtoint i8* %t36 to i64
  %t41 = sub i64 %t39, %t40
  %t42 = add i64 %t41, 1
  %t43 = call i8* @star_rc_alloc(i64 %t42, i8* null)
  call i8* @memcpy(i8* %t43, i8* %t36, i64 %t41)
  %t44 = getelementptr inbounds i8, i8* %t43, i64 %t41
  store i8 0, i8* %t44
  %t45 = load i64, i64* %t12
  %t46 = load i64, i64* %t13
  %t47 = icmp sge i64 %t45, %t46
  br i1 %t47, label %dynstr_grow_219, label %dynstr_store_220
dynstr_grow_219:
  %t48 = mul i64 %t46, 2
  %t49 = icmp sgt i64 %t48, 0
  %t50 = select i1 %t49, i64 %t48, i64 4
  %t51 = mul i64 %t50, 8
  %t52 = call i8* @malloc(i64 %t51)
  %t53 = bitcast i8* %t52 to i8**
  %t54 = icmp sgt i64 %t46, 0
  br i1 %t54, label %dynstr_copy_221, label %dynstr_after_copy_222
dynstr_copy_221:
  %t55 = load i8**, i8*** %t11
  %t56 = mul i64 %t45, 8
  %t57 = bitcast i8** %t55 to i8*
  call i8* @memcpy(i8* %t52, i8* %t57, i64 %t56)
  call void @free(i8* %t57)
  br label %dynstr_after_copy_222
dynstr_after_copy_222:
  store i8** %t53, i8*** %t11
  store i64 %t50, i64* %t13
  br label %dynstr_store_220
dynstr_store_220:
  %t58 = load i8**, i8*** %t11
  %t59 = getelementptr inbounds i8*, i8** %t58, i64 %t45
  store i8* %t43, i8** %t59
  %t60 = add i64 %t45, 1
  store i64 %t60, i64* %t12
  %t61 = getelementptr inbounds i8, i8* %t37, i64 %t10
  store i8* %t61, i8** %t35
  br label %split_scan_cond_216
split_tail_218:
  %t62 = load i8*, i8** %t35
  %t63 = call i32 @strlen(i8* %t62)
  %t64 = sext i32 %t63 to i64
  %t65 = add i64 %t64, 1
  %t66 = call i8* @star_rc_alloc(i64 %t65, i8* null)
  call i8* @strcpy(i8* %t66, i8* %t62)
  %t67 = load i64, i64* %t12
  %t68 = load i64, i64* %t13
  %t69 = icmp sge i64 %t67, %t68
  br i1 %t69, label %dynstr_grow_223, label %dynstr_store_224
dynstr_grow_223:
  %t70 = mul i64 %t68, 2
  %t71 = icmp sgt i64 %t70, 0
  %t72 = select i1 %t71, i64 %t70, i64 4
  %t73 = mul i64 %t72, 8
  %t74 = call i8* @malloc(i64 %t73)
  %t75 = bitcast i8* %t74 to i8**
  %t76 = icmp sgt i64 %t68, 0
  br i1 %t76, label %dynstr_copy_225, label %dynstr_after_copy_226
dynstr_copy_225:
  %t77 = load i8**, i8*** %t11
  %t78 = mul i64 %t67, 8
  %t79 = bitcast i8** %t77 to i8*
  call i8* @memcpy(i8* %t74, i8* %t79, i64 %t78)
  call void @free(i8* %t79)
  br label %dynstr_after_copy_226
dynstr_after_copy_226:
  store i8** %t75, i8*** %t11
  store i64 %t72, i64* %t13
  br label %dynstr_store_224
dynstr_store_224:
  %t80 = load i8**, i8*** %t11
  %t81 = getelementptr inbounds i8*, i8** %t80, i64 %t67
  store i8* %t66, i8** %t81
  %t82 = add i64 %t67, 1
  store i64 %t82, i64* %t12
  br label %split_finish_211
split_finish_211:
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t4)
  %t83 = bitcast void (i8*)* @list_release_str to i8*
  %t84 = call i8* @star_rc_alloc(i64 24, i8* %t83)
  %t85 = bitcast i8* %t84 to { i8**, i64, i64 }*
  %t86 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t85, i32 0, i32 0
  %t87 = load i8**, i8*** %t11
  store i8** %t87, i8*** %t86
  %t88 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t85, i32 0, i32 1
  %t89 = load i64, i64* %t12
  store i64 %t89, i64* %t88
  %t90 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t85, i32 0, i32 2
  %t91 = load i64, i64* %t13
  store i64 %t91, i64* %t90
  store i8* %t84, i8** %t1
  store i8* null, i8** %t92
  store i32 0, i32* %t93
  br label %while_cond_227
while_cond_227:
  %t94 = load i32, i32* %t93
  %t95 = icmp slt i32 %t94, 16
  br i1 %t95, label %while_body_228, label %while_else_229
while_body_228:
  %t97 = load i8*, i8** %t1
  %t98 = icmp eq i8* %t97, null
  br i1 %t98, label %list_read_null_231, label %list_read_real_232
list_read_null_231:
  br label %list_read_end_233
list_read_real_232:
  %t99 = bitcast i8* %t97 to { i8**, i64, i64 }*
  %t100 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t99, i32 0, i32 0
  %t101 = load i8**, i8*** %t100
  %t102 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t99, i32 0, i32 1
  %t103 = load i64, i64* %t102
  br label %list_read_end_233
list_read_end_233:
  %t104 = phi i8** [ null, %list_read_null_231 ], [ %t101, %list_read_real_232 ]
  %t105 = phi i64 [ 0, %list_read_null_231 ], [ %t103, %list_read_real_232 ]
  %t106 = load i32, i32* %t93
  %t107 = sext i32 %t106 to i64
  %t108 = icmp ult i64 %t107, %t105
  br i1 %t108, label %list_idx_ok_234, label %list_idx_oob_235
list_idx_ok_234:
  %t109 = getelementptr inbounds i8*, i8** %t104, i64 %t107
  %t110 = load i8*, i8** %t109
  %t111 = load i8*, i8** %t109
  call void @star_rc_retain(i8* %t111)
  br label %list_idx_end_236
list_idx_oob_235:
  %t112 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t112
  br label %list_idx_end_236
list_idx_end_236:
  %t113 = phi i8* [ %t110, %list_idx_ok_234 ], [ %t112, %list_idx_oob_235 ]
  store i8* %t113, i8** %t96
  %t115 = load i8*, i8** %t96
  %t116 = load i8*, i8** %t96
  call void @star_rc_retain(i8* %t116)
  %t117 = call i32 @strlen(i8* %t115)
  %t118 = sext i32 %t117 to i64
  %t119 = call i8* @malloc(i64 %t118)
  call i8* @memcpy(i8* %t119, i8* %t115, i64 %t118)
  call void @star_rc_release(i8* %t115)
  %t120 = bitcast void (i8*)* @list_release_u8 to i8*
  %t121 = call i8* @star_rc_alloc(i64 24, i8* %t120)
  %t122 = bitcast i8* %t121 to { i8*, i64, i64 }*
  %t123 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t122, i32 0, i32 0
  store i8* %t119, i8** %t123
  %t124 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t122, i32 0, i32 1
  store i64 %t118, i64* %t124
  %t125 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t122, i32 0, i32 2
  store i64 %t118, i64* %t125
  store i8* %t121, i8** %t114
  store i32 0, i32* %t126
  br label %while_cond_237
while_cond_237:
  %t127 = load i32, i32* %t126
  %t128 = icmp slt i32 %t127, 16
  br i1 %t128, label %while_body_238, label %while_else_239
while_body_238:
  %t130 = load i8*, i8** %t114
  %t131 = icmp eq i8* %t130, null
  br i1 %t131, label %list_read_null_241, label %list_read_real_242
list_read_null_241:
  br label %list_read_end_243
list_read_real_242:
  %t132 = bitcast i8* %t130 to { i8*, i64, i64 }*
  %t133 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t132, i32 0, i32 0
  %t134 = load i8*, i8** %t133
  %t135 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t132, i32 0, i32 1
  %t136 = load i64, i64* %t135
  br label %list_read_end_243
list_read_end_243:
  %t137 = phi i8* [ null, %list_read_null_241 ], [ %t134, %list_read_real_242 ]
  %t138 = phi i64 [ 0, %list_read_null_241 ], [ %t136, %list_read_real_242 ]
  %t139 = load i32, i32* %t126
  %t140 = sext i32 %t139 to i64
  %t141 = icmp ult i64 %t140, %t138
  br i1 %t141, label %list_idx_ok_244, label %list_idx_oob_245
list_idx_ok_244:
  %t142 = getelementptr inbounds i8, i8* %t137, i64 %t140
  %t143 = load i8, i8* %t142
  br label %list_idx_end_246
list_idx_oob_245:
  br label %list_idx_end_246
list_idx_end_246:
  %t144 = phi i8 [ %t143, %list_idx_ok_244 ], [ 0, %list_idx_oob_245 ]
  %t145 = zext i8 %t144 to i32
  store i32 %t145, i32* %t129
  %t147 = load i32, i32* %t129
  %t148 = call { i32, i32, i32, i32 } @sprites__legend_color(i32 %t147)
  store { i32, i32, i32, i32 } %t148, { i32, i32, i32, i32 }* %t146
  %t149 = getelementptr i8, i8* null, i32 1
  %t150 = ptrtoint i8* %t149 to i64
  %t151 = load i8*, i8** %t92
  %t152 = icmp eq i8* %t151, null
  br i1 %t152, label %list_cow_alloc_247, label %list_cow_check_248
list_cow_alloc_247:
  %t153 = bitcast void (i8*)* @list_release_u8 to i8*
  %t154 = call i8* @star_rc_alloc(i64 24, i8* %t153)
  %t155 = bitcast i8* %t154 to { i8*, i64, i64 }*
  %t156 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t155, i32 0, i32 0
  store i8* null, i8** %t156
  %t157 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t155, i32 0, i32 1
  store i64 0, i64* %t157
  %t158 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t155, i32 0, i32 2
  store i64 0, i64* %t158
  store i8* %t154, i8** %t92
  br label %list_cow_done_249
list_cow_check_248:
  %t159 = getelementptr inbounds i8, i8* %t151, i64 -16
  %t160 = bitcast i8* %t159 to i64*
  %t161 = load atomic i64, i64* %t160 seq_cst, align 8
  %t162 = icmp eq i64 %t161, 1
  br i1 %t162, label %list_cow_done_249, label %list_cow_clone_250
list_cow_clone_250:
  %t163 = bitcast i8* %t151 to { i8*, i64, i64 }*
  %t164 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t163, i32 0, i32 0
  %t165 = load i8*, i8** %t164
  %t166 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t163, i32 0, i32 1
  %t167 = load i64, i64* %t166
  %t168 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t163, i32 0, i32 2
  %t169 = load i64, i64* %t168
  %t170 = bitcast void (i8*)* @list_release_u8 to i8*
  %t171 = call i8* @star_rc_alloc(i64 24, i8* %t170)
  %t172 = bitcast i8* %t171 to { i8*, i64, i64 }*
  %t173 = mul i64 %t169, %t150
  %t174 = call i8* @malloc(i64 %t173)
  %t175 = bitcast i8* %t174 to i8*
  %t176 = icmp sgt i64 %t167, 0
  br i1 %t176, label %list_cow_copy_251, label %list_cow_after_copy_252
list_cow_copy_251:
  %t177 = mul i64 %t167, %t150
  %t178 = bitcast i8* %t165 to i8*
  call i8* @memcpy(i8* %t174, i8* %t178, i64 %t177)
  br label %list_cow_after_copy_252
list_cow_after_copy_252:
  %t179 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t172, i32 0, i32 0
  store i8* %t175, i8** %t179
  %t180 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t172, i32 0, i32 1
  store i64 %t167, i64* %t180
  %t181 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t172, i32 0, i32 2
  store i64 %t169, i64* %t181
  call void @star_rc_release(i8* %t151)
  store i8* %t171, i8** %t92
  br label %list_cow_done_249
list_cow_done_249:
  %t182 = load i8*, i8** %t92
  %t183 = bitcast i8* %t182 to { i8*, i64, i64 }*
  %t184 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t183, i32 0, i32 0
  %t185 = load i8*, i8** %t184
  %t186 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t183, i32 0, i32 1
  %t187 = load i64, i64* %t186
  %t188 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t183, i32 0, i32 2
  %t189 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t146, i32 0, i32 0
  %t190 = load i32, i32* %t189
  %t191 = trunc i32 %t190 to i8
  %t192 = load i64, i64* %t188
  %t193 = load i8*, i8** %t184
  %t194 = load i64, i64* %t186
  %t195 = icmp sge i64 %t194, %t192
  br i1 %t195, label %list_push_grow_253, label %list_push_store_254
list_push_grow_253:
  %t196 = mul i64 %t192, 2
  %t197 = icmp sgt i64 %t196, 0
  %t198 = select i1 %t197, i64 %t196, i64 1
  %t199 = getelementptr i8, i8* null, i32 1
  %t200 = ptrtoint i8* %t199 to i64
  %t201 = mul i64 %t198, %t200
  %t202 = call i8* @malloc(i64 %t201)
  %t203 = bitcast i8* %t202 to i8*
  %t204 = icmp sgt i64 %t192, 0
  br i1 %t204, label %list_push_copy_255, label %list_push_after_copy_256
list_push_copy_255:
  %t205 = mul i64 %t194, %t200
  %t206 = bitcast i8* %t193 to i8*
  call i8* @memcpy(i8* %t202, i8* %t206, i64 %t205)
  call void @free(i8* %t206)
  br label %list_push_after_copy_256
list_push_after_copy_256:
  store i8* %t203, i8** %t184
  store i64 %t198, i64* %t188
  br label %list_push_store_254
list_push_store_254:
  %t207 = load i8*, i8** %t184
  %t208 = getelementptr inbounds i8, i8* %t207, i64 %t194
  store i8 %t191, i8* %t208
  %t209 = add i64 %t194, 1
  store i64 %t209, i64* %t186
  %t210 = getelementptr i8, i8* null, i32 1
  %t211 = ptrtoint i8* %t210 to i64
  %t212 = load i8*, i8** %t92
  %t213 = icmp eq i8* %t212, null
  br i1 %t213, label %list_cow_alloc_257, label %list_cow_check_258
list_cow_alloc_257:
  %t214 = bitcast void (i8*)* @list_release_u8 to i8*
  %t215 = call i8* @star_rc_alloc(i64 24, i8* %t214)
  %t216 = bitcast i8* %t215 to { i8*, i64, i64 }*
  %t217 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t216, i32 0, i32 0
  store i8* null, i8** %t217
  %t218 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t216, i32 0, i32 1
  store i64 0, i64* %t218
  %t219 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t216, i32 0, i32 2
  store i64 0, i64* %t219
  store i8* %t215, i8** %t92
  br label %list_cow_done_259
list_cow_check_258:
  %t220 = getelementptr inbounds i8, i8* %t212, i64 -16
  %t221 = bitcast i8* %t220 to i64*
  %t222 = load atomic i64, i64* %t221 seq_cst, align 8
  %t223 = icmp eq i64 %t222, 1
  br i1 %t223, label %list_cow_done_259, label %list_cow_clone_260
list_cow_clone_260:
  %t224 = bitcast i8* %t212 to { i8*, i64, i64 }*
  %t225 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t224, i32 0, i32 0
  %t226 = load i8*, i8** %t225
  %t227 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t224, i32 0, i32 1
  %t228 = load i64, i64* %t227
  %t229 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t224, i32 0, i32 2
  %t230 = load i64, i64* %t229
  %t231 = bitcast void (i8*)* @list_release_u8 to i8*
  %t232 = call i8* @star_rc_alloc(i64 24, i8* %t231)
  %t233 = bitcast i8* %t232 to { i8*, i64, i64 }*
  %t234 = mul i64 %t230, %t211
  %t235 = call i8* @malloc(i64 %t234)
  %t236 = bitcast i8* %t235 to i8*
  %t237 = icmp sgt i64 %t228, 0
  br i1 %t237, label %list_cow_copy_261, label %list_cow_after_copy_262
list_cow_copy_261:
  %t238 = mul i64 %t228, %t211
  %t239 = bitcast i8* %t226 to i8*
  call i8* @memcpy(i8* %t235, i8* %t239, i64 %t238)
  br label %list_cow_after_copy_262
list_cow_after_copy_262:
  %t240 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t233, i32 0, i32 0
  store i8* %t236, i8** %t240
  %t241 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t233, i32 0, i32 1
  store i64 %t228, i64* %t241
  %t242 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t233, i32 0, i32 2
  store i64 %t230, i64* %t242
  call void @star_rc_release(i8* %t212)
  store i8* %t232, i8** %t92
  br label %list_cow_done_259
list_cow_done_259:
  %t243 = load i8*, i8** %t92
  %t244 = bitcast i8* %t243 to { i8*, i64, i64 }*
  %t245 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t244, i32 0, i32 0
  %t246 = load i8*, i8** %t245
  %t247 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t244, i32 0, i32 1
  %t248 = load i64, i64* %t247
  %t249 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t244, i32 0, i32 2
  %t250 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t146, i32 0, i32 1
  %t251 = load i32, i32* %t250
  %t252 = trunc i32 %t251 to i8
  %t253 = load i64, i64* %t249
  %t254 = load i8*, i8** %t245
  %t255 = load i64, i64* %t247
  %t256 = icmp sge i64 %t255, %t253
  br i1 %t256, label %list_push_grow_263, label %list_push_store_264
list_push_grow_263:
  %t257 = mul i64 %t253, 2
  %t258 = icmp sgt i64 %t257, 0
  %t259 = select i1 %t258, i64 %t257, i64 1
  %t260 = getelementptr i8, i8* null, i32 1
  %t261 = ptrtoint i8* %t260 to i64
  %t262 = mul i64 %t259, %t261
  %t263 = call i8* @malloc(i64 %t262)
  %t264 = bitcast i8* %t263 to i8*
  %t265 = icmp sgt i64 %t253, 0
  br i1 %t265, label %list_push_copy_265, label %list_push_after_copy_266
list_push_copy_265:
  %t266 = mul i64 %t255, %t261
  %t267 = bitcast i8* %t254 to i8*
  call i8* @memcpy(i8* %t263, i8* %t267, i64 %t266)
  call void @free(i8* %t267)
  br label %list_push_after_copy_266
list_push_after_copy_266:
  store i8* %t264, i8** %t245
  store i64 %t259, i64* %t249
  br label %list_push_store_264
list_push_store_264:
  %t268 = load i8*, i8** %t245
  %t269 = getelementptr inbounds i8, i8* %t268, i64 %t255
  store i8 %t252, i8* %t269
  %t270 = add i64 %t255, 1
  store i64 %t270, i64* %t247
  %t271 = getelementptr i8, i8* null, i32 1
  %t272 = ptrtoint i8* %t271 to i64
  %t273 = load i8*, i8** %t92
  %t274 = icmp eq i8* %t273, null
  br i1 %t274, label %list_cow_alloc_267, label %list_cow_check_268
list_cow_alloc_267:
  %t275 = bitcast void (i8*)* @list_release_u8 to i8*
  %t276 = call i8* @star_rc_alloc(i64 24, i8* %t275)
  %t277 = bitcast i8* %t276 to { i8*, i64, i64 }*
  %t278 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t277, i32 0, i32 0
  store i8* null, i8** %t278
  %t279 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t277, i32 0, i32 1
  store i64 0, i64* %t279
  %t280 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t277, i32 0, i32 2
  store i64 0, i64* %t280
  store i8* %t276, i8** %t92
  br label %list_cow_done_269
list_cow_check_268:
  %t281 = getelementptr inbounds i8, i8* %t273, i64 -16
  %t282 = bitcast i8* %t281 to i64*
  %t283 = load atomic i64, i64* %t282 seq_cst, align 8
  %t284 = icmp eq i64 %t283, 1
  br i1 %t284, label %list_cow_done_269, label %list_cow_clone_270
list_cow_clone_270:
  %t285 = bitcast i8* %t273 to { i8*, i64, i64 }*
  %t286 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t285, i32 0, i32 0
  %t287 = load i8*, i8** %t286
  %t288 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t285, i32 0, i32 1
  %t289 = load i64, i64* %t288
  %t290 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t285, i32 0, i32 2
  %t291 = load i64, i64* %t290
  %t292 = bitcast void (i8*)* @list_release_u8 to i8*
  %t293 = call i8* @star_rc_alloc(i64 24, i8* %t292)
  %t294 = bitcast i8* %t293 to { i8*, i64, i64 }*
  %t295 = mul i64 %t291, %t272
  %t296 = call i8* @malloc(i64 %t295)
  %t297 = bitcast i8* %t296 to i8*
  %t298 = icmp sgt i64 %t289, 0
  br i1 %t298, label %list_cow_copy_271, label %list_cow_after_copy_272
list_cow_copy_271:
  %t299 = mul i64 %t289, %t272
  %t300 = bitcast i8* %t287 to i8*
  call i8* @memcpy(i8* %t296, i8* %t300, i64 %t299)
  br label %list_cow_after_copy_272
list_cow_after_copy_272:
  %t301 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t294, i32 0, i32 0
  store i8* %t297, i8** %t301
  %t302 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t294, i32 0, i32 1
  store i64 %t289, i64* %t302
  %t303 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t294, i32 0, i32 2
  store i64 %t291, i64* %t303
  call void @star_rc_release(i8* %t273)
  store i8* %t293, i8** %t92
  br label %list_cow_done_269
list_cow_done_269:
  %t304 = load i8*, i8** %t92
  %t305 = bitcast i8* %t304 to { i8*, i64, i64 }*
  %t306 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t305, i32 0, i32 0
  %t307 = load i8*, i8** %t306
  %t308 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t305, i32 0, i32 1
  %t309 = load i64, i64* %t308
  %t310 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t305, i32 0, i32 2
  %t311 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t146, i32 0, i32 2
  %t312 = load i32, i32* %t311
  %t313 = trunc i32 %t312 to i8
  %t314 = load i64, i64* %t310
  %t315 = load i8*, i8** %t306
  %t316 = load i64, i64* %t308
  %t317 = icmp sge i64 %t316, %t314
  br i1 %t317, label %list_push_grow_273, label %list_push_store_274
list_push_grow_273:
  %t318 = mul i64 %t314, 2
  %t319 = icmp sgt i64 %t318, 0
  %t320 = select i1 %t319, i64 %t318, i64 1
  %t321 = getelementptr i8, i8* null, i32 1
  %t322 = ptrtoint i8* %t321 to i64
  %t323 = mul i64 %t320, %t322
  %t324 = call i8* @malloc(i64 %t323)
  %t325 = bitcast i8* %t324 to i8*
  %t326 = icmp sgt i64 %t314, 0
  br i1 %t326, label %list_push_copy_275, label %list_push_after_copy_276
list_push_copy_275:
  %t327 = mul i64 %t316, %t322
  %t328 = bitcast i8* %t315 to i8*
  call i8* @memcpy(i8* %t324, i8* %t328, i64 %t327)
  call void @free(i8* %t328)
  br label %list_push_after_copy_276
list_push_after_copy_276:
  store i8* %t325, i8** %t306
  store i64 %t320, i64* %t310
  br label %list_push_store_274
list_push_store_274:
  %t329 = load i8*, i8** %t306
  %t330 = getelementptr inbounds i8, i8* %t329, i64 %t316
  store i8 %t313, i8* %t330
  %t331 = add i64 %t316, 1
  store i64 %t331, i64* %t308
  %t332 = getelementptr i8, i8* null, i32 1
  %t333 = ptrtoint i8* %t332 to i64
  %t334 = load i8*, i8** %t92
  %t335 = icmp eq i8* %t334, null
  br i1 %t335, label %list_cow_alloc_277, label %list_cow_check_278
list_cow_alloc_277:
  %t336 = bitcast void (i8*)* @list_release_u8 to i8*
  %t337 = call i8* @star_rc_alloc(i64 24, i8* %t336)
  %t338 = bitcast i8* %t337 to { i8*, i64, i64 }*
  %t339 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t338, i32 0, i32 0
  store i8* null, i8** %t339
  %t340 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t338, i32 0, i32 1
  store i64 0, i64* %t340
  %t341 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t338, i32 0, i32 2
  store i64 0, i64* %t341
  store i8* %t337, i8** %t92
  br label %list_cow_done_279
list_cow_check_278:
  %t342 = getelementptr inbounds i8, i8* %t334, i64 -16
  %t343 = bitcast i8* %t342 to i64*
  %t344 = load atomic i64, i64* %t343 seq_cst, align 8
  %t345 = icmp eq i64 %t344, 1
  br i1 %t345, label %list_cow_done_279, label %list_cow_clone_280
list_cow_clone_280:
  %t346 = bitcast i8* %t334 to { i8*, i64, i64 }*
  %t347 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t346, i32 0, i32 0
  %t348 = load i8*, i8** %t347
  %t349 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t346, i32 0, i32 1
  %t350 = load i64, i64* %t349
  %t351 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t346, i32 0, i32 2
  %t352 = load i64, i64* %t351
  %t353 = bitcast void (i8*)* @list_release_u8 to i8*
  %t354 = call i8* @star_rc_alloc(i64 24, i8* %t353)
  %t355 = bitcast i8* %t354 to { i8*, i64, i64 }*
  %t356 = mul i64 %t352, %t333
  %t357 = call i8* @malloc(i64 %t356)
  %t358 = bitcast i8* %t357 to i8*
  %t359 = icmp sgt i64 %t350, 0
  br i1 %t359, label %list_cow_copy_281, label %list_cow_after_copy_282
list_cow_copy_281:
  %t360 = mul i64 %t350, %t333
  %t361 = bitcast i8* %t348 to i8*
  call i8* @memcpy(i8* %t357, i8* %t361, i64 %t360)
  br label %list_cow_after_copy_282
list_cow_after_copy_282:
  %t362 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t355, i32 0, i32 0
  store i8* %t358, i8** %t362
  %t363 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t355, i32 0, i32 1
  store i64 %t350, i64* %t363
  %t364 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t355, i32 0, i32 2
  store i64 %t352, i64* %t364
  call void @star_rc_release(i8* %t334)
  store i8* %t354, i8** %t92
  br label %list_cow_done_279
list_cow_done_279:
  %t365 = load i8*, i8** %t92
  %t366 = bitcast i8* %t365 to { i8*, i64, i64 }*
  %t367 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t366, i32 0, i32 0
  %t368 = load i8*, i8** %t367
  %t369 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t366, i32 0, i32 1
  %t370 = load i64, i64* %t369
  %t371 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t366, i32 0, i32 2
  %t372 = getelementptr inbounds { i32, i32, i32, i32 }, { i32, i32, i32, i32 }* %t146, i32 0, i32 3
  %t373 = load i32, i32* %t372
  %t374 = trunc i32 %t373 to i8
  %t375 = load i64, i64* %t371
  %t376 = load i8*, i8** %t367
  %t377 = load i64, i64* %t369
  %t378 = icmp sge i64 %t377, %t375
  br i1 %t378, label %list_push_grow_283, label %list_push_store_284
list_push_grow_283:
  %t379 = mul i64 %t375, 2
  %t380 = icmp sgt i64 %t379, 0
  %t381 = select i1 %t380, i64 %t379, i64 1
  %t382 = getelementptr i8, i8* null, i32 1
  %t383 = ptrtoint i8* %t382 to i64
  %t384 = mul i64 %t381, %t383
  %t385 = call i8* @malloc(i64 %t384)
  %t386 = bitcast i8* %t385 to i8*
  %t387 = icmp sgt i64 %t375, 0
  br i1 %t387, label %list_push_copy_285, label %list_push_after_copy_286
list_push_copy_285:
  %t388 = mul i64 %t377, %t383
  %t389 = bitcast i8* %t376 to i8*
  call i8* @memcpy(i8* %t385, i8* %t389, i64 %t388)
  call void @free(i8* %t389)
  br label %list_push_after_copy_286
list_push_after_copy_286:
  store i8* %t386, i8** %t367
  store i64 %t381, i64* %t371
  br label %list_push_store_284
list_push_store_284:
  %t390 = load i8*, i8** %t367
  %t391 = getelementptr inbounds i8, i8* %t390, i64 %t377
  store i8 %t374, i8* %t391
  %t392 = add i64 %t377, 1
  store i64 %t392, i64* %t369
  %t393 = load i32, i32* %t126
  %t394 = add i32 %t393, 1
  store i32 %t394, i32* %t126
  br label %while_cond_237
while_else_239:
  br label %while_end_240
while_end_240:
  %t395 = load i32, i32* %t93
  %t396 = add i32 %t395, 1
  store i32 %t396, i32* %t93
  %t397 = load i8*, i8** %t114
  call void @star_rc_release(i8* %t397)
  %t398 = load i8*, i8** %t96
  call void @star_rc_release(i8* %t398)
  br label %while_cond_227
while_else_229:
  br label %while_end_230
while_end_230:
  %t399 = load i8*, i8** %t92
  %t400 = load i8*, i8** %t92
  call void @star_rc_retain(i8* %t400)
  %t401 = load i8*, i8** %t92
  call void @star_rc_release(i8* %t401)
  %t402 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t402)
  %t403 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t403)
  ret i8* %t399
}

define %sprites__SpriteSet @sprites__make_sprites() {
entry:
  %t0 = alloca %sprites__SpriteSet
  %t1 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 0
  %t2 = getelementptr inbounds { i64, i8*, [272 x i8] }, { i64, i8*, [272 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t3 = call i8* @sprites__parse_sprite(i8* %t2)
  store i8* %t3, i8** %t1
  %t4 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 1
  %t5 = getelementptr inbounds { i64, i8*, [272 x i8] }, { i64, i8*, [272 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t6 = call i8* @sprites__parse_sprite(i8* %t5)
  store i8* %t6, i8** %t4
  %t7 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 2
  %t8 = getelementptr inbounds { i64, i8*, [272 x i8] }, { i64, i8*, [272 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t9 = call i8* @sprites__parse_sprite(i8* %t8)
  store i8* %t9, i8** %t7
  %t10 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 3
  %t11 = getelementptr inbounds { i64, i8*, [272 x i8] }, { i64, i8*, [272 x i8] }* @.str.8, i64 0, i32 2, i64 0
  %t12 = call i8* @sprites__parse_sprite(i8* %t11)
  store i8* %t12, i8** %t10
  %t13 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 4
  %t14 = getelementptr inbounds { i64, i8*, [272 x i8] }, { i64, i8*, [272 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t15 = call i8* @sprites__parse_sprite(i8* %t14)
  store i8* %t15, i8** %t13
  %t16 = load %sprites__SpriteSet, %sprites__SpriteSet* %t0
  ret %sprites__SpriteSet %t16
}

define i8* @audio__push_i16(i8* %buf, i32 %v) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t2 = alloca i32
  %t5 = alloca i32
  %t10 = alloca i8*
  store i8* %buf, i8** %t0
  store i32 %v, i32* %t1
  %t3 = load i32, i32* %t1
  %t4 = and i32 %t3, 255
  store i32 %t4, i32* %t2
  %t6 = load i32, i32* %t1
  %t7 = and i32 8, 31
  %t8 = ashr i32 %t6, %t7
  %t9 = and i32 %t8, 255
  store i32 %t9, i32* %t5
  %t11 = load i8*, i8** %t0
  %t12 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t12)
  store i8* %t11, i8** %t10
  %t13 = getelementptr i8, i8* null, i32 1
  %t14 = ptrtoint i8* %t13 to i64
  %t15 = load i8*, i8** %t10
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %list_cow_alloc_287, label %list_cow_check_288
list_cow_alloc_287:
  %t17 = bitcast void (i8*)* @list_release_u8 to i8*
  %t18 = call i8* @star_rc_alloc(i64 24, i8* %t17)
  %t19 = bitcast i8* %t18 to { i8*, i64, i64 }*
  %t20 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t19, i32 0, i32 0
  store i8* null, i8** %t20
  %t21 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t19, i32 0, i32 1
  store i64 0, i64* %t21
  %t22 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t19, i32 0, i32 2
  store i64 0, i64* %t22
  store i8* %t18, i8** %t10
  br label %list_cow_done_289
list_cow_check_288:
  %t23 = getelementptr inbounds i8, i8* %t15, i64 -16
  %t24 = bitcast i8* %t23 to i64*
  %t25 = load atomic i64, i64* %t24 seq_cst, align 8
  %t26 = icmp eq i64 %t25, 1
  br i1 %t26, label %list_cow_done_289, label %list_cow_clone_290
list_cow_clone_290:
  %t27 = bitcast i8* %t15 to { i8*, i64, i64 }*
  %t28 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t27, i32 0, i32 0
  %t29 = load i8*, i8** %t28
  %t30 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t27, i32 0, i32 1
  %t31 = load i64, i64* %t30
  %t32 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t27, i32 0, i32 2
  %t33 = load i64, i64* %t32
  %t34 = bitcast void (i8*)* @list_release_u8 to i8*
  %t35 = call i8* @star_rc_alloc(i64 24, i8* %t34)
  %t36 = bitcast i8* %t35 to { i8*, i64, i64 }*
  %t37 = mul i64 %t33, %t14
  %t38 = call i8* @malloc(i64 %t37)
  %t39 = bitcast i8* %t38 to i8*
  %t40 = icmp sgt i64 %t31, 0
  br i1 %t40, label %list_cow_copy_291, label %list_cow_after_copy_292
list_cow_copy_291:
  %t41 = mul i64 %t31, %t14
  %t42 = bitcast i8* %t29 to i8*
  call i8* @memcpy(i8* %t38, i8* %t42, i64 %t41)
  br label %list_cow_after_copy_292
list_cow_after_copy_292:
  %t43 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t36, i32 0, i32 0
  store i8* %t39, i8** %t43
  %t44 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t36, i32 0, i32 1
  store i64 %t31, i64* %t44
  %t45 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t36, i32 0, i32 2
  store i64 %t33, i64* %t45
  call void @star_rc_release(i8* %t15)
  store i8* %t35, i8** %t10
  br label %list_cow_done_289
list_cow_done_289:
  %t46 = load i8*, i8** %t10
  %t47 = bitcast i8* %t46 to { i8*, i64, i64 }*
  %t48 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t47, i32 0, i32 0
  %t49 = load i8*, i8** %t48
  %t50 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t47, i32 0, i32 1
  %t51 = load i64, i64* %t50
  %t52 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t47, i32 0, i32 2
  %t53 = load i32, i32* %t2
  %t54 = trunc i32 %t53 to i8
  %t55 = load i64, i64* %t52
  %t56 = load i8*, i8** %t48
  %t57 = load i64, i64* %t50
  %t58 = icmp sge i64 %t57, %t55
  br i1 %t58, label %list_push_grow_293, label %list_push_store_294
list_push_grow_293:
  %t59 = mul i64 %t55, 2
  %t60 = icmp sgt i64 %t59, 0
  %t61 = select i1 %t60, i64 %t59, i64 1
  %t62 = getelementptr i8, i8* null, i32 1
  %t63 = ptrtoint i8* %t62 to i64
  %t64 = mul i64 %t61, %t63
  %t65 = call i8* @malloc(i64 %t64)
  %t66 = bitcast i8* %t65 to i8*
  %t67 = icmp sgt i64 %t55, 0
  br i1 %t67, label %list_push_copy_295, label %list_push_after_copy_296
list_push_copy_295:
  %t68 = mul i64 %t57, %t63
  %t69 = bitcast i8* %t56 to i8*
  call i8* @memcpy(i8* %t65, i8* %t69, i64 %t68)
  call void @free(i8* %t69)
  br label %list_push_after_copy_296
list_push_after_copy_296:
  store i8* %t66, i8** %t48
  store i64 %t61, i64* %t52
  br label %list_push_store_294
list_push_store_294:
  %t70 = load i8*, i8** %t48
  %t71 = getelementptr inbounds i8, i8* %t70, i64 %t57
  store i8 %t54, i8* %t71
  %t72 = add i64 %t57, 1
  store i64 %t72, i64* %t50
  %t73 = getelementptr i8, i8* null, i32 1
  %t74 = ptrtoint i8* %t73 to i64
  %t75 = load i8*, i8** %t10
  %t76 = icmp eq i8* %t75, null
  br i1 %t76, label %list_cow_alloc_297, label %list_cow_check_298
list_cow_alloc_297:
  %t77 = bitcast void (i8*)* @list_release_u8 to i8*
  %t78 = call i8* @star_rc_alloc(i64 24, i8* %t77)
  %t79 = bitcast i8* %t78 to { i8*, i64, i64 }*
  %t80 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t79, i32 0, i32 0
  store i8* null, i8** %t80
  %t81 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t79, i32 0, i32 1
  store i64 0, i64* %t81
  %t82 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t79, i32 0, i32 2
  store i64 0, i64* %t82
  store i8* %t78, i8** %t10
  br label %list_cow_done_299
list_cow_check_298:
  %t83 = getelementptr inbounds i8, i8* %t75, i64 -16
  %t84 = bitcast i8* %t83 to i64*
  %t85 = load atomic i64, i64* %t84 seq_cst, align 8
  %t86 = icmp eq i64 %t85, 1
  br i1 %t86, label %list_cow_done_299, label %list_cow_clone_300
list_cow_clone_300:
  %t87 = bitcast i8* %t75 to { i8*, i64, i64 }*
  %t88 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t87, i32 0, i32 0
  %t89 = load i8*, i8** %t88
  %t90 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t87, i32 0, i32 1
  %t91 = load i64, i64* %t90
  %t92 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t87, i32 0, i32 2
  %t93 = load i64, i64* %t92
  %t94 = bitcast void (i8*)* @list_release_u8 to i8*
  %t95 = call i8* @star_rc_alloc(i64 24, i8* %t94)
  %t96 = bitcast i8* %t95 to { i8*, i64, i64 }*
  %t97 = mul i64 %t93, %t74
  %t98 = call i8* @malloc(i64 %t97)
  %t99 = bitcast i8* %t98 to i8*
  %t100 = icmp sgt i64 %t91, 0
  br i1 %t100, label %list_cow_copy_301, label %list_cow_after_copy_302
list_cow_copy_301:
  %t101 = mul i64 %t91, %t74
  %t102 = bitcast i8* %t89 to i8*
  call i8* @memcpy(i8* %t98, i8* %t102, i64 %t101)
  br label %list_cow_after_copy_302
list_cow_after_copy_302:
  %t103 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t96, i32 0, i32 0
  store i8* %t99, i8** %t103
  %t104 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t96, i32 0, i32 1
  store i64 %t91, i64* %t104
  %t105 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t96, i32 0, i32 2
  store i64 %t93, i64* %t105
  call void @star_rc_release(i8* %t75)
  store i8* %t95, i8** %t10
  br label %list_cow_done_299
list_cow_done_299:
  %t106 = load i8*, i8** %t10
  %t107 = bitcast i8* %t106 to { i8*, i64, i64 }*
  %t108 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t107, i32 0, i32 0
  %t109 = load i8*, i8** %t108
  %t110 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t107, i32 0, i32 1
  %t111 = load i64, i64* %t110
  %t112 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t107, i32 0, i32 2
  %t113 = load i32, i32* %t5
  %t114 = trunc i32 %t113 to i8
  %t115 = load i64, i64* %t112
  %t116 = load i8*, i8** %t108
  %t117 = load i64, i64* %t110
  %t118 = icmp sge i64 %t117, %t115
  br i1 %t118, label %list_push_grow_303, label %list_push_store_304
list_push_grow_303:
  %t119 = mul i64 %t115, 2
  %t120 = icmp sgt i64 %t119, 0
  %t121 = select i1 %t120, i64 %t119, i64 1
  %t122 = getelementptr i8, i8* null, i32 1
  %t123 = ptrtoint i8* %t122 to i64
  %t124 = mul i64 %t121, %t123
  %t125 = call i8* @malloc(i64 %t124)
  %t126 = bitcast i8* %t125 to i8*
  %t127 = icmp sgt i64 %t115, 0
  br i1 %t127, label %list_push_copy_305, label %list_push_after_copy_306
list_push_copy_305:
  %t128 = mul i64 %t117, %t123
  %t129 = bitcast i8* %t116 to i8*
  call i8* @memcpy(i8* %t125, i8* %t129, i64 %t128)
  call void @free(i8* %t129)
  br label %list_push_after_copy_306
list_push_after_copy_306:
  store i8* %t126, i8** %t108
  store i64 %t121, i64* %t112
  br label %list_push_store_304
list_push_store_304:
  %t130 = load i8*, i8** %t108
  %t131 = getelementptr inbounds i8, i8* %t130, i64 %t117
  store i8 %t114, i8* %t131
  %t132 = add i64 %t117, 1
  store i64 %t132, i64* %t110
  %t133 = load i8*, i8** %t10
  %t134 = load i8*, i8** %t10
  call void @star_rc_retain(i8* %t134)
  %t135 = load i8*, i8** %t10
  call void @star_rc_release(i8* %t135)
  %t136 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t136)
  ret i8* %t133
}

define void @audio__write_wav(i8* %path, i8* %samples) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t2 = alloca i8*
  %t11 = alloca i8*
  %t248 = alloca i32
  %t783 = alloca i32
  store i8* %path, i8** %t0
  store i8* %samples, i8** %t1
  %t3 = load i8*, i8** %t0
  %t4 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t4)
  %t5 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t6 = call i8* @fopen(i8* %t3, i8* %t5)
  call void @star_rc_release(i8* %t3)
  call void @star_rc_release(i8* %t5)
  store i8* %t6, i8** %t2
  %t7 = load i8*, i8** %t2
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %if_then_307, label %if_else_308
if_then_307:
  %t9 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t9)
  %t10 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t10)
  ret void
if_else_308:
  br label %if_end_309
if_end_309:
  store i8* null, i8** %t11
  %t12 = getelementptr i8, i8* null, i32 1
  %t13 = ptrtoint i8* %t12 to i64
  %t14 = load i8*, i8** %t11
  %t15 = icmp eq i8* %t14, null
  br i1 %t15, label %list_cow_alloc_310, label %list_cow_check_311
list_cow_alloc_310:
  %t16 = bitcast void (i8*)* @list_release_u8 to i8*
  %t17 = call i8* @star_rc_alloc(i64 24, i8* %t16)
  %t18 = bitcast i8* %t17 to { i8*, i64, i64 }*
  %t19 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 0
  store i8* null, i8** %t19
  %t20 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 1
  store i64 0, i64* %t20
  %t21 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 2
  store i64 0, i64* %t21
  store i8* %t17, i8** %t11
  br label %list_cow_done_312
list_cow_check_311:
  %t22 = getelementptr inbounds i8, i8* %t14, i64 -16
  %t23 = bitcast i8* %t22 to i64*
  %t24 = load atomic i64, i64* %t23 seq_cst, align 8
  %t25 = icmp eq i64 %t24, 1
  br i1 %t25, label %list_cow_done_312, label %list_cow_clone_313
list_cow_clone_313:
  %t26 = bitcast i8* %t14 to { i8*, i64, i64 }*
  %t27 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t26, i32 0, i32 0
  %t28 = load i8*, i8** %t27
  %t29 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t26, i32 0, i32 1
  %t30 = load i64, i64* %t29
  %t31 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t26, i32 0, i32 2
  %t32 = load i64, i64* %t31
  %t33 = bitcast void (i8*)* @list_release_u8 to i8*
  %t34 = call i8* @star_rc_alloc(i64 24, i8* %t33)
  %t35 = bitcast i8* %t34 to { i8*, i64, i64 }*
  %t36 = mul i64 %t32, %t13
  %t37 = call i8* @malloc(i64 %t36)
  %t38 = bitcast i8* %t37 to i8*
  %t39 = icmp sgt i64 %t30, 0
  br i1 %t39, label %list_cow_copy_314, label %list_cow_after_copy_315
list_cow_copy_314:
  %t40 = mul i64 %t30, %t13
  %t41 = bitcast i8* %t28 to i8*
  call i8* @memcpy(i8* %t37, i8* %t41, i64 %t40)
  br label %list_cow_after_copy_315
list_cow_after_copy_315:
  %t42 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t35, i32 0, i32 0
  store i8* %t38, i8** %t42
  %t43 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t35, i32 0, i32 1
  store i64 %t30, i64* %t43
  %t44 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t35, i32 0, i32 2
  store i64 %t32, i64* %t44
  call void @star_rc_release(i8* %t14)
  store i8* %t34, i8** %t11
  br label %list_cow_done_312
list_cow_done_312:
  %t45 = load i8*, i8** %t11
  %t46 = bitcast i8* %t45 to { i8*, i64, i64 }*
  %t47 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t46, i32 0, i32 0
  %t48 = load i8*, i8** %t47
  %t49 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t46, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t46, i32 0, i32 2
  %t52 = trunc i32 82 to i8
  %t53 = load i64, i64* %t51
  %t54 = load i8*, i8** %t47
  %t55 = load i64, i64* %t49
  %t56 = icmp sge i64 %t55, %t53
  br i1 %t56, label %list_push_grow_316, label %list_push_store_317
list_push_grow_316:
  %t57 = mul i64 %t53, 2
  %t58 = icmp sgt i64 %t57, 0
  %t59 = select i1 %t58, i64 %t57, i64 1
  %t60 = getelementptr i8, i8* null, i32 1
  %t61 = ptrtoint i8* %t60 to i64
  %t62 = mul i64 %t59, %t61
  %t63 = call i8* @malloc(i64 %t62)
  %t64 = bitcast i8* %t63 to i8*
  %t65 = icmp sgt i64 %t53, 0
  br i1 %t65, label %list_push_copy_318, label %list_push_after_copy_319
list_push_copy_318:
  %t66 = mul i64 %t55, %t61
  %t67 = bitcast i8* %t54 to i8*
  call i8* @memcpy(i8* %t63, i8* %t67, i64 %t66)
  call void @free(i8* %t67)
  br label %list_push_after_copy_319
list_push_after_copy_319:
  store i8* %t64, i8** %t47
  store i64 %t59, i64* %t51
  br label %list_push_store_317
list_push_store_317:
  %t68 = load i8*, i8** %t47
  %t69 = getelementptr inbounds i8, i8* %t68, i64 %t55
  store i8 %t52, i8* %t69
  %t70 = add i64 %t55, 1
  store i64 %t70, i64* %t49
  %t71 = getelementptr i8, i8* null, i32 1
  %t72 = ptrtoint i8* %t71 to i64
  %t73 = load i8*, i8** %t11
  %t74 = icmp eq i8* %t73, null
  br i1 %t74, label %list_cow_alloc_320, label %list_cow_check_321
list_cow_alloc_320:
  %t75 = bitcast void (i8*)* @list_release_u8 to i8*
  %t76 = call i8* @star_rc_alloc(i64 24, i8* %t75)
  %t77 = bitcast i8* %t76 to { i8*, i64, i64 }*
  %t78 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t77, i32 0, i32 0
  store i8* null, i8** %t78
  %t79 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t77, i32 0, i32 1
  store i64 0, i64* %t79
  %t80 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t77, i32 0, i32 2
  store i64 0, i64* %t80
  store i8* %t76, i8** %t11
  br label %list_cow_done_322
list_cow_check_321:
  %t81 = getelementptr inbounds i8, i8* %t73, i64 -16
  %t82 = bitcast i8* %t81 to i64*
  %t83 = load atomic i64, i64* %t82 seq_cst, align 8
  %t84 = icmp eq i64 %t83, 1
  br i1 %t84, label %list_cow_done_322, label %list_cow_clone_323
list_cow_clone_323:
  %t85 = bitcast i8* %t73 to { i8*, i64, i64 }*
  %t86 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t85, i32 0, i32 0
  %t87 = load i8*, i8** %t86
  %t88 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t85, i32 0, i32 1
  %t89 = load i64, i64* %t88
  %t90 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t85, i32 0, i32 2
  %t91 = load i64, i64* %t90
  %t92 = bitcast void (i8*)* @list_release_u8 to i8*
  %t93 = call i8* @star_rc_alloc(i64 24, i8* %t92)
  %t94 = bitcast i8* %t93 to { i8*, i64, i64 }*
  %t95 = mul i64 %t91, %t72
  %t96 = call i8* @malloc(i64 %t95)
  %t97 = bitcast i8* %t96 to i8*
  %t98 = icmp sgt i64 %t89, 0
  br i1 %t98, label %list_cow_copy_324, label %list_cow_after_copy_325
list_cow_copy_324:
  %t99 = mul i64 %t89, %t72
  %t100 = bitcast i8* %t87 to i8*
  call i8* @memcpy(i8* %t96, i8* %t100, i64 %t99)
  br label %list_cow_after_copy_325
list_cow_after_copy_325:
  %t101 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t94, i32 0, i32 0
  store i8* %t97, i8** %t101
  %t102 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t94, i32 0, i32 1
  store i64 %t89, i64* %t102
  %t103 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t94, i32 0, i32 2
  store i64 %t91, i64* %t103
  call void @star_rc_release(i8* %t73)
  store i8* %t93, i8** %t11
  br label %list_cow_done_322
list_cow_done_322:
  %t104 = load i8*, i8** %t11
  %t105 = bitcast i8* %t104 to { i8*, i64, i64 }*
  %t106 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t105, i32 0, i32 0
  %t107 = load i8*, i8** %t106
  %t108 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t105, i32 0, i32 1
  %t109 = load i64, i64* %t108
  %t110 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t105, i32 0, i32 2
  %t111 = trunc i32 73 to i8
  %t112 = load i64, i64* %t110
  %t113 = load i8*, i8** %t106
  %t114 = load i64, i64* %t108
  %t115 = icmp sge i64 %t114, %t112
  br i1 %t115, label %list_push_grow_326, label %list_push_store_327
list_push_grow_326:
  %t116 = mul i64 %t112, 2
  %t117 = icmp sgt i64 %t116, 0
  %t118 = select i1 %t117, i64 %t116, i64 1
  %t119 = getelementptr i8, i8* null, i32 1
  %t120 = ptrtoint i8* %t119 to i64
  %t121 = mul i64 %t118, %t120
  %t122 = call i8* @malloc(i64 %t121)
  %t123 = bitcast i8* %t122 to i8*
  %t124 = icmp sgt i64 %t112, 0
  br i1 %t124, label %list_push_copy_328, label %list_push_after_copy_329
list_push_copy_328:
  %t125 = mul i64 %t114, %t120
  %t126 = bitcast i8* %t113 to i8*
  call i8* @memcpy(i8* %t122, i8* %t126, i64 %t125)
  call void @free(i8* %t126)
  br label %list_push_after_copy_329
list_push_after_copy_329:
  store i8* %t123, i8** %t106
  store i64 %t118, i64* %t110
  br label %list_push_store_327
list_push_store_327:
  %t127 = load i8*, i8** %t106
  %t128 = getelementptr inbounds i8, i8* %t127, i64 %t114
  store i8 %t111, i8* %t128
  %t129 = add i64 %t114, 1
  store i64 %t129, i64* %t108
  %t130 = getelementptr i8, i8* null, i32 1
  %t131 = ptrtoint i8* %t130 to i64
  %t132 = load i8*, i8** %t11
  %t133 = icmp eq i8* %t132, null
  br i1 %t133, label %list_cow_alloc_330, label %list_cow_check_331
list_cow_alloc_330:
  %t134 = bitcast void (i8*)* @list_release_u8 to i8*
  %t135 = call i8* @star_rc_alloc(i64 24, i8* %t134)
  %t136 = bitcast i8* %t135 to { i8*, i64, i64 }*
  %t137 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t136, i32 0, i32 0
  store i8* null, i8** %t137
  %t138 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t136, i32 0, i32 1
  store i64 0, i64* %t138
  %t139 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t136, i32 0, i32 2
  store i64 0, i64* %t139
  store i8* %t135, i8** %t11
  br label %list_cow_done_332
list_cow_check_331:
  %t140 = getelementptr inbounds i8, i8* %t132, i64 -16
  %t141 = bitcast i8* %t140 to i64*
  %t142 = load atomic i64, i64* %t141 seq_cst, align 8
  %t143 = icmp eq i64 %t142, 1
  br i1 %t143, label %list_cow_done_332, label %list_cow_clone_333
list_cow_clone_333:
  %t144 = bitcast i8* %t132 to { i8*, i64, i64 }*
  %t145 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t144, i32 0, i32 0
  %t146 = load i8*, i8** %t145
  %t147 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t144, i32 0, i32 1
  %t148 = load i64, i64* %t147
  %t149 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t144, i32 0, i32 2
  %t150 = load i64, i64* %t149
  %t151 = bitcast void (i8*)* @list_release_u8 to i8*
  %t152 = call i8* @star_rc_alloc(i64 24, i8* %t151)
  %t153 = bitcast i8* %t152 to { i8*, i64, i64 }*
  %t154 = mul i64 %t150, %t131
  %t155 = call i8* @malloc(i64 %t154)
  %t156 = bitcast i8* %t155 to i8*
  %t157 = icmp sgt i64 %t148, 0
  br i1 %t157, label %list_cow_copy_334, label %list_cow_after_copy_335
list_cow_copy_334:
  %t158 = mul i64 %t148, %t131
  %t159 = bitcast i8* %t146 to i8*
  call i8* @memcpy(i8* %t155, i8* %t159, i64 %t158)
  br label %list_cow_after_copy_335
list_cow_after_copy_335:
  %t160 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t153, i32 0, i32 0
  store i8* %t156, i8** %t160
  %t161 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t153, i32 0, i32 1
  store i64 %t148, i64* %t161
  %t162 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t153, i32 0, i32 2
  store i64 %t150, i64* %t162
  call void @star_rc_release(i8* %t132)
  store i8* %t152, i8** %t11
  br label %list_cow_done_332
list_cow_done_332:
  %t163 = load i8*, i8** %t11
  %t164 = bitcast i8* %t163 to { i8*, i64, i64 }*
  %t165 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t164, i32 0, i32 0
  %t166 = load i8*, i8** %t165
  %t167 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t164, i32 0, i32 1
  %t168 = load i64, i64* %t167
  %t169 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t164, i32 0, i32 2
  %t170 = trunc i32 70 to i8
  %t171 = load i64, i64* %t169
  %t172 = load i8*, i8** %t165
  %t173 = load i64, i64* %t167
  %t174 = icmp sge i64 %t173, %t171
  br i1 %t174, label %list_push_grow_336, label %list_push_store_337
list_push_grow_336:
  %t175 = mul i64 %t171, 2
  %t176 = icmp sgt i64 %t175, 0
  %t177 = select i1 %t176, i64 %t175, i64 1
  %t178 = getelementptr i8, i8* null, i32 1
  %t179 = ptrtoint i8* %t178 to i64
  %t180 = mul i64 %t177, %t179
  %t181 = call i8* @malloc(i64 %t180)
  %t182 = bitcast i8* %t181 to i8*
  %t183 = icmp sgt i64 %t171, 0
  br i1 %t183, label %list_push_copy_338, label %list_push_after_copy_339
list_push_copy_338:
  %t184 = mul i64 %t173, %t179
  %t185 = bitcast i8* %t172 to i8*
  call i8* @memcpy(i8* %t181, i8* %t185, i64 %t184)
  call void @free(i8* %t185)
  br label %list_push_after_copy_339
list_push_after_copy_339:
  store i8* %t182, i8** %t165
  store i64 %t177, i64* %t169
  br label %list_push_store_337
list_push_store_337:
  %t186 = load i8*, i8** %t165
  %t187 = getelementptr inbounds i8, i8* %t186, i64 %t173
  store i8 %t170, i8* %t187
  %t188 = add i64 %t173, 1
  store i64 %t188, i64* %t167
  %t189 = getelementptr i8, i8* null, i32 1
  %t190 = ptrtoint i8* %t189 to i64
  %t191 = load i8*, i8** %t11
  %t192 = icmp eq i8* %t191, null
  br i1 %t192, label %list_cow_alloc_340, label %list_cow_check_341
list_cow_alloc_340:
  %t193 = bitcast void (i8*)* @list_release_u8 to i8*
  %t194 = call i8* @star_rc_alloc(i64 24, i8* %t193)
  %t195 = bitcast i8* %t194 to { i8*, i64, i64 }*
  %t196 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t195, i32 0, i32 0
  store i8* null, i8** %t196
  %t197 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t195, i32 0, i32 1
  store i64 0, i64* %t197
  %t198 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t195, i32 0, i32 2
  store i64 0, i64* %t198
  store i8* %t194, i8** %t11
  br label %list_cow_done_342
list_cow_check_341:
  %t199 = getelementptr inbounds i8, i8* %t191, i64 -16
  %t200 = bitcast i8* %t199 to i64*
  %t201 = load atomic i64, i64* %t200 seq_cst, align 8
  %t202 = icmp eq i64 %t201, 1
  br i1 %t202, label %list_cow_done_342, label %list_cow_clone_343
list_cow_clone_343:
  %t203 = bitcast i8* %t191 to { i8*, i64, i64 }*
  %t204 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t203, i32 0, i32 0
  %t205 = load i8*, i8** %t204
  %t206 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t203, i32 0, i32 1
  %t207 = load i64, i64* %t206
  %t208 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t203, i32 0, i32 2
  %t209 = load i64, i64* %t208
  %t210 = bitcast void (i8*)* @list_release_u8 to i8*
  %t211 = call i8* @star_rc_alloc(i64 24, i8* %t210)
  %t212 = bitcast i8* %t211 to { i8*, i64, i64 }*
  %t213 = mul i64 %t209, %t190
  %t214 = call i8* @malloc(i64 %t213)
  %t215 = bitcast i8* %t214 to i8*
  %t216 = icmp sgt i64 %t207, 0
  br i1 %t216, label %list_cow_copy_344, label %list_cow_after_copy_345
list_cow_copy_344:
  %t217 = mul i64 %t207, %t190
  %t218 = bitcast i8* %t205 to i8*
  call i8* @memcpy(i8* %t214, i8* %t218, i64 %t217)
  br label %list_cow_after_copy_345
list_cow_after_copy_345:
  %t219 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t212, i32 0, i32 0
  store i8* %t215, i8** %t219
  %t220 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t212, i32 0, i32 1
  store i64 %t207, i64* %t220
  %t221 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t212, i32 0, i32 2
  store i64 %t209, i64* %t221
  call void @star_rc_release(i8* %t191)
  store i8* %t211, i8** %t11
  br label %list_cow_done_342
list_cow_done_342:
  %t222 = load i8*, i8** %t11
  %t223 = bitcast i8* %t222 to { i8*, i64, i64 }*
  %t224 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t223, i32 0, i32 0
  %t225 = load i8*, i8** %t224
  %t226 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t223, i32 0, i32 1
  %t227 = load i64, i64* %t226
  %t228 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t223, i32 0, i32 2
  %t229 = trunc i32 70 to i8
  %t230 = load i64, i64* %t228
  %t231 = load i8*, i8** %t224
  %t232 = load i64, i64* %t226
  %t233 = icmp sge i64 %t232, %t230
  br i1 %t233, label %list_push_grow_346, label %list_push_store_347
list_push_grow_346:
  %t234 = mul i64 %t230, 2
  %t235 = icmp sgt i64 %t234, 0
  %t236 = select i1 %t235, i64 %t234, i64 1
  %t237 = getelementptr i8, i8* null, i32 1
  %t238 = ptrtoint i8* %t237 to i64
  %t239 = mul i64 %t236, %t238
  %t240 = call i8* @malloc(i64 %t239)
  %t241 = bitcast i8* %t240 to i8*
  %t242 = icmp sgt i64 %t230, 0
  br i1 %t242, label %list_push_copy_348, label %list_push_after_copy_349
list_push_copy_348:
  %t243 = mul i64 %t232, %t238
  %t244 = bitcast i8* %t231 to i8*
  call i8* @memcpy(i8* %t240, i8* %t244, i64 %t243)
  call void @free(i8* %t244)
  br label %list_push_after_copy_349
list_push_after_copy_349:
  store i8* %t241, i8** %t224
  store i64 %t236, i64* %t228
  br label %list_push_store_347
list_push_store_347:
  %t245 = load i8*, i8** %t224
  %t246 = getelementptr inbounds i8, i8* %t245, i64 %t232
  store i8 %t229, i8* %t246
  %t247 = add i64 %t232, 1
  store i64 %t247, i64* %t226
  %t249 = load i8*, i8** %t1
  %t250 = icmp eq i8* %t249, null
  br i1 %t250, label %list_read_null_350, label %list_read_real_351
list_read_null_350:
  br label %list_read_end_352
list_read_real_351:
  %t251 = bitcast i8* %t249 to { i8*, i64, i64 }*
  %t252 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t251, i32 0, i32 0
  %t253 = load i8*, i8** %t252
  %t254 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t251, i32 0, i32 1
  %t255 = load i64, i64* %t254
  br label %list_read_end_352
list_read_end_352:
  %t256 = phi i8* [ null, %list_read_null_350 ], [ %t253, %list_read_real_351 ]
  %t257 = phi i64 [ 0, %list_read_null_350 ], [ %t255, %list_read_real_351 ]
  %t258 = trunc i64 %t257 to i32
  store i32 %t258, i32* %t248
  %t259 = load i8*, i8** %t11
  %t260 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t260)
  %t261 = load i32, i32* %t248
  %t262 = add i32 36, %t261
  %t263 = and i32 %t262, 65535
  %t264 = call i8* @audio__push_i16(i8* %t259, i32 %t263)
  %t265 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t265)
  store i8* %t264, i8** %t11
  %t266 = load i8*, i8** %t11
  %t267 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t267)
  %t268 = load i32, i32* %t248
  %t269 = add i32 36, %t268
  %t270 = and i32 16, 31
  %t271 = ashr i32 %t269, %t270
  %t272 = and i32 %t271, 65535
  %t273 = call i8* @audio__push_i16(i8* %t266, i32 %t272)
  %t274 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t274)
  store i8* %t273, i8** %t11
  %t275 = getelementptr i8, i8* null, i32 1
  %t276 = ptrtoint i8* %t275 to i64
  %t277 = load i8*, i8** %t11
  %t278 = icmp eq i8* %t277, null
  br i1 %t278, label %list_cow_alloc_353, label %list_cow_check_354
list_cow_alloc_353:
  %t279 = bitcast void (i8*)* @list_release_u8 to i8*
  %t280 = call i8* @star_rc_alloc(i64 24, i8* %t279)
  %t281 = bitcast i8* %t280 to { i8*, i64, i64 }*
  %t282 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t281, i32 0, i32 0
  store i8* null, i8** %t282
  %t283 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t281, i32 0, i32 1
  store i64 0, i64* %t283
  %t284 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t281, i32 0, i32 2
  store i64 0, i64* %t284
  store i8* %t280, i8** %t11
  br label %list_cow_done_355
list_cow_check_354:
  %t285 = getelementptr inbounds i8, i8* %t277, i64 -16
  %t286 = bitcast i8* %t285 to i64*
  %t287 = load atomic i64, i64* %t286 seq_cst, align 8
  %t288 = icmp eq i64 %t287, 1
  br i1 %t288, label %list_cow_done_355, label %list_cow_clone_356
list_cow_clone_356:
  %t289 = bitcast i8* %t277 to { i8*, i64, i64 }*
  %t290 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t289, i32 0, i32 0
  %t291 = load i8*, i8** %t290
  %t292 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t289, i32 0, i32 1
  %t293 = load i64, i64* %t292
  %t294 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t289, i32 0, i32 2
  %t295 = load i64, i64* %t294
  %t296 = bitcast void (i8*)* @list_release_u8 to i8*
  %t297 = call i8* @star_rc_alloc(i64 24, i8* %t296)
  %t298 = bitcast i8* %t297 to { i8*, i64, i64 }*
  %t299 = mul i64 %t295, %t276
  %t300 = call i8* @malloc(i64 %t299)
  %t301 = bitcast i8* %t300 to i8*
  %t302 = icmp sgt i64 %t293, 0
  br i1 %t302, label %list_cow_copy_357, label %list_cow_after_copy_358
list_cow_copy_357:
  %t303 = mul i64 %t293, %t276
  %t304 = bitcast i8* %t291 to i8*
  call i8* @memcpy(i8* %t300, i8* %t304, i64 %t303)
  br label %list_cow_after_copy_358
list_cow_after_copy_358:
  %t305 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t298, i32 0, i32 0
  store i8* %t301, i8** %t305
  %t306 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t298, i32 0, i32 1
  store i64 %t293, i64* %t306
  %t307 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t298, i32 0, i32 2
  store i64 %t295, i64* %t307
  call void @star_rc_release(i8* %t277)
  store i8* %t297, i8** %t11
  br label %list_cow_done_355
list_cow_done_355:
  %t308 = load i8*, i8** %t11
  %t309 = bitcast i8* %t308 to { i8*, i64, i64 }*
  %t310 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t309, i32 0, i32 0
  %t311 = load i8*, i8** %t310
  %t312 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t309, i32 0, i32 1
  %t313 = load i64, i64* %t312
  %t314 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t309, i32 0, i32 2
  %t315 = trunc i32 87 to i8
  %t316 = load i64, i64* %t314
  %t317 = load i8*, i8** %t310
  %t318 = load i64, i64* %t312
  %t319 = icmp sge i64 %t318, %t316
  br i1 %t319, label %list_push_grow_359, label %list_push_store_360
list_push_grow_359:
  %t320 = mul i64 %t316, 2
  %t321 = icmp sgt i64 %t320, 0
  %t322 = select i1 %t321, i64 %t320, i64 1
  %t323 = getelementptr i8, i8* null, i32 1
  %t324 = ptrtoint i8* %t323 to i64
  %t325 = mul i64 %t322, %t324
  %t326 = call i8* @malloc(i64 %t325)
  %t327 = bitcast i8* %t326 to i8*
  %t328 = icmp sgt i64 %t316, 0
  br i1 %t328, label %list_push_copy_361, label %list_push_after_copy_362
list_push_copy_361:
  %t329 = mul i64 %t318, %t324
  %t330 = bitcast i8* %t317 to i8*
  call i8* @memcpy(i8* %t326, i8* %t330, i64 %t329)
  call void @free(i8* %t330)
  br label %list_push_after_copy_362
list_push_after_copy_362:
  store i8* %t327, i8** %t310
  store i64 %t322, i64* %t314
  br label %list_push_store_360
list_push_store_360:
  %t331 = load i8*, i8** %t310
  %t332 = getelementptr inbounds i8, i8* %t331, i64 %t318
  store i8 %t315, i8* %t332
  %t333 = add i64 %t318, 1
  store i64 %t333, i64* %t312
  %t334 = getelementptr i8, i8* null, i32 1
  %t335 = ptrtoint i8* %t334 to i64
  %t336 = load i8*, i8** %t11
  %t337 = icmp eq i8* %t336, null
  br i1 %t337, label %list_cow_alloc_363, label %list_cow_check_364
list_cow_alloc_363:
  %t338 = bitcast void (i8*)* @list_release_u8 to i8*
  %t339 = call i8* @star_rc_alloc(i64 24, i8* %t338)
  %t340 = bitcast i8* %t339 to { i8*, i64, i64 }*
  %t341 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t340, i32 0, i32 0
  store i8* null, i8** %t341
  %t342 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t340, i32 0, i32 1
  store i64 0, i64* %t342
  %t343 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t340, i32 0, i32 2
  store i64 0, i64* %t343
  store i8* %t339, i8** %t11
  br label %list_cow_done_365
list_cow_check_364:
  %t344 = getelementptr inbounds i8, i8* %t336, i64 -16
  %t345 = bitcast i8* %t344 to i64*
  %t346 = load atomic i64, i64* %t345 seq_cst, align 8
  %t347 = icmp eq i64 %t346, 1
  br i1 %t347, label %list_cow_done_365, label %list_cow_clone_366
list_cow_clone_366:
  %t348 = bitcast i8* %t336 to { i8*, i64, i64 }*
  %t349 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t348, i32 0, i32 0
  %t350 = load i8*, i8** %t349
  %t351 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t348, i32 0, i32 1
  %t352 = load i64, i64* %t351
  %t353 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t348, i32 0, i32 2
  %t354 = load i64, i64* %t353
  %t355 = bitcast void (i8*)* @list_release_u8 to i8*
  %t356 = call i8* @star_rc_alloc(i64 24, i8* %t355)
  %t357 = bitcast i8* %t356 to { i8*, i64, i64 }*
  %t358 = mul i64 %t354, %t335
  %t359 = call i8* @malloc(i64 %t358)
  %t360 = bitcast i8* %t359 to i8*
  %t361 = icmp sgt i64 %t352, 0
  br i1 %t361, label %list_cow_copy_367, label %list_cow_after_copy_368
list_cow_copy_367:
  %t362 = mul i64 %t352, %t335
  %t363 = bitcast i8* %t350 to i8*
  call i8* @memcpy(i8* %t359, i8* %t363, i64 %t362)
  br label %list_cow_after_copy_368
list_cow_after_copy_368:
  %t364 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t357, i32 0, i32 0
  store i8* %t360, i8** %t364
  %t365 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t357, i32 0, i32 1
  store i64 %t352, i64* %t365
  %t366 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t357, i32 0, i32 2
  store i64 %t354, i64* %t366
  call void @star_rc_release(i8* %t336)
  store i8* %t356, i8** %t11
  br label %list_cow_done_365
list_cow_done_365:
  %t367 = load i8*, i8** %t11
  %t368 = bitcast i8* %t367 to { i8*, i64, i64 }*
  %t369 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t368, i32 0, i32 0
  %t370 = load i8*, i8** %t369
  %t371 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t368, i32 0, i32 1
  %t372 = load i64, i64* %t371
  %t373 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t368, i32 0, i32 2
  %t374 = trunc i32 65 to i8
  %t375 = load i64, i64* %t373
  %t376 = load i8*, i8** %t369
  %t377 = load i64, i64* %t371
  %t378 = icmp sge i64 %t377, %t375
  br i1 %t378, label %list_push_grow_369, label %list_push_store_370
list_push_grow_369:
  %t379 = mul i64 %t375, 2
  %t380 = icmp sgt i64 %t379, 0
  %t381 = select i1 %t380, i64 %t379, i64 1
  %t382 = getelementptr i8, i8* null, i32 1
  %t383 = ptrtoint i8* %t382 to i64
  %t384 = mul i64 %t381, %t383
  %t385 = call i8* @malloc(i64 %t384)
  %t386 = bitcast i8* %t385 to i8*
  %t387 = icmp sgt i64 %t375, 0
  br i1 %t387, label %list_push_copy_371, label %list_push_after_copy_372
list_push_copy_371:
  %t388 = mul i64 %t377, %t383
  %t389 = bitcast i8* %t376 to i8*
  call i8* @memcpy(i8* %t385, i8* %t389, i64 %t388)
  call void @free(i8* %t389)
  br label %list_push_after_copy_372
list_push_after_copy_372:
  store i8* %t386, i8** %t369
  store i64 %t381, i64* %t373
  br label %list_push_store_370
list_push_store_370:
  %t390 = load i8*, i8** %t369
  %t391 = getelementptr inbounds i8, i8* %t390, i64 %t377
  store i8 %t374, i8* %t391
  %t392 = add i64 %t377, 1
  store i64 %t392, i64* %t371
  %t393 = getelementptr i8, i8* null, i32 1
  %t394 = ptrtoint i8* %t393 to i64
  %t395 = load i8*, i8** %t11
  %t396 = icmp eq i8* %t395, null
  br i1 %t396, label %list_cow_alloc_373, label %list_cow_check_374
list_cow_alloc_373:
  %t397 = bitcast void (i8*)* @list_release_u8 to i8*
  %t398 = call i8* @star_rc_alloc(i64 24, i8* %t397)
  %t399 = bitcast i8* %t398 to { i8*, i64, i64 }*
  %t400 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t399, i32 0, i32 0
  store i8* null, i8** %t400
  %t401 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t399, i32 0, i32 1
  store i64 0, i64* %t401
  %t402 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t399, i32 0, i32 2
  store i64 0, i64* %t402
  store i8* %t398, i8** %t11
  br label %list_cow_done_375
list_cow_check_374:
  %t403 = getelementptr inbounds i8, i8* %t395, i64 -16
  %t404 = bitcast i8* %t403 to i64*
  %t405 = load atomic i64, i64* %t404 seq_cst, align 8
  %t406 = icmp eq i64 %t405, 1
  br i1 %t406, label %list_cow_done_375, label %list_cow_clone_376
list_cow_clone_376:
  %t407 = bitcast i8* %t395 to { i8*, i64, i64 }*
  %t408 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t407, i32 0, i32 0
  %t409 = load i8*, i8** %t408
  %t410 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t407, i32 0, i32 1
  %t411 = load i64, i64* %t410
  %t412 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t407, i32 0, i32 2
  %t413 = load i64, i64* %t412
  %t414 = bitcast void (i8*)* @list_release_u8 to i8*
  %t415 = call i8* @star_rc_alloc(i64 24, i8* %t414)
  %t416 = bitcast i8* %t415 to { i8*, i64, i64 }*
  %t417 = mul i64 %t413, %t394
  %t418 = call i8* @malloc(i64 %t417)
  %t419 = bitcast i8* %t418 to i8*
  %t420 = icmp sgt i64 %t411, 0
  br i1 %t420, label %list_cow_copy_377, label %list_cow_after_copy_378
list_cow_copy_377:
  %t421 = mul i64 %t411, %t394
  %t422 = bitcast i8* %t409 to i8*
  call i8* @memcpy(i8* %t418, i8* %t422, i64 %t421)
  br label %list_cow_after_copy_378
list_cow_after_copy_378:
  %t423 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t416, i32 0, i32 0
  store i8* %t419, i8** %t423
  %t424 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t416, i32 0, i32 1
  store i64 %t411, i64* %t424
  %t425 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t416, i32 0, i32 2
  store i64 %t413, i64* %t425
  call void @star_rc_release(i8* %t395)
  store i8* %t415, i8** %t11
  br label %list_cow_done_375
list_cow_done_375:
  %t426 = load i8*, i8** %t11
  %t427 = bitcast i8* %t426 to { i8*, i64, i64 }*
  %t428 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t427, i32 0, i32 0
  %t429 = load i8*, i8** %t428
  %t430 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t427, i32 0, i32 1
  %t431 = load i64, i64* %t430
  %t432 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t427, i32 0, i32 2
  %t433 = trunc i32 86 to i8
  %t434 = load i64, i64* %t432
  %t435 = load i8*, i8** %t428
  %t436 = load i64, i64* %t430
  %t437 = icmp sge i64 %t436, %t434
  br i1 %t437, label %list_push_grow_379, label %list_push_store_380
list_push_grow_379:
  %t438 = mul i64 %t434, 2
  %t439 = icmp sgt i64 %t438, 0
  %t440 = select i1 %t439, i64 %t438, i64 1
  %t441 = getelementptr i8, i8* null, i32 1
  %t442 = ptrtoint i8* %t441 to i64
  %t443 = mul i64 %t440, %t442
  %t444 = call i8* @malloc(i64 %t443)
  %t445 = bitcast i8* %t444 to i8*
  %t446 = icmp sgt i64 %t434, 0
  br i1 %t446, label %list_push_copy_381, label %list_push_after_copy_382
list_push_copy_381:
  %t447 = mul i64 %t436, %t442
  %t448 = bitcast i8* %t435 to i8*
  call i8* @memcpy(i8* %t444, i8* %t448, i64 %t447)
  call void @free(i8* %t448)
  br label %list_push_after_copy_382
list_push_after_copy_382:
  store i8* %t445, i8** %t428
  store i64 %t440, i64* %t432
  br label %list_push_store_380
list_push_store_380:
  %t449 = load i8*, i8** %t428
  %t450 = getelementptr inbounds i8, i8* %t449, i64 %t436
  store i8 %t433, i8* %t450
  %t451 = add i64 %t436, 1
  store i64 %t451, i64* %t430
  %t452 = getelementptr i8, i8* null, i32 1
  %t453 = ptrtoint i8* %t452 to i64
  %t454 = load i8*, i8** %t11
  %t455 = icmp eq i8* %t454, null
  br i1 %t455, label %list_cow_alloc_383, label %list_cow_check_384
list_cow_alloc_383:
  %t456 = bitcast void (i8*)* @list_release_u8 to i8*
  %t457 = call i8* @star_rc_alloc(i64 24, i8* %t456)
  %t458 = bitcast i8* %t457 to { i8*, i64, i64 }*
  %t459 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t458, i32 0, i32 0
  store i8* null, i8** %t459
  %t460 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t458, i32 0, i32 1
  store i64 0, i64* %t460
  %t461 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t458, i32 0, i32 2
  store i64 0, i64* %t461
  store i8* %t457, i8** %t11
  br label %list_cow_done_385
list_cow_check_384:
  %t462 = getelementptr inbounds i8, i8* %t454, i64 -16
  %t463 = bitcast i8* %t462 to i64*
  %t464 = load atomic i64, i64* %t463 seq_cst, align 8
  %t465 = icmp eq i64 %t464, 1
  br i1 %t465, label %list_cow_done_385, label %list_cow_clone_386
list_cow_clone_386:
  %t466 = bitcast i8* %t454 to { i8*, i64, i64 }*
  %t467 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t466, i32 0, i32 0
  %t468 = load i8*, i8** %t467
  %t469 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t466, i32 0, i32 1
  %t470 = load i64, i64* %t469
  %t471 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t466, i32 0, i32 2
  %t472 = load i64, i64* %t471
  %t473 = bitcast void (i8*)* @list_release_u8 to i8*
  %t474 = call i8* @star_rc_alloc(i64 24, i8* %t473)
  %t475 = bitcast i8* %t474 to { i8*, i64, i64 }*
  %t476 = mul i64 %t472, %t453
  %t477 = call i8* @malloc(i64 %t476)
  %t478 = bitcast i8* %t477 to i8*
  %t479 = icmp sgt i64 %t470, 0
  br i1 %t479, label %list_cow_copy_387, label %list_cow_after_copy_388
list_cow_copy_387:
  %t480 = mul i64 %t470, %t453
  %t481 = bitcast i8* %t468 to i8*
  call i8* @memcpy(i8* %t477, i8* %t481, i64 %t480)
  br label %list_cow_after_copy_388
list_cow_after_copy_388:
  %t482 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t475, i32 0, i32 0
  store i8* %t478, i8** %t482
  %t483 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t475, i32 0, i32 1
  store i64 %t470, i64* %t483
  %t484 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t475, i32 0, i32 2
  store i64 %t472, i64* %t484
  call void @star_rc_release(i8* %t454)
  store i8* %t474, i8** %t11
  br label %list_cow_done_385
list_cow_done_385:
  %t485 = load i8*, i8** %t11
  %t486 = bitcast i8* %t485 to { i8*, i64, i64 }*
  %t487 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t486, i32 0, i32 0
  %t488 = load i8*, i8** %t487
  %t489 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t486, i32 0, i32 1
  %t490 = load i64, i64* %t489
  %t491 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t486, i32 0, i32 2
  %t492 = trunc i32 69 to i8
  %t493 = load i64, i64* %t491
  %t494 = load i8*, i8** %t487
  %t495 = load i64, i64* %t489
  %t496 = icmp sge i64 %t495, %t493
  br i1 %t496, label %list_push_grow_389, label %list_push_store_390
list_push_grow_389:
  %t497 = mul i64 %t493, 2
  %t498 = icmp sgt i64 %t497, 0
  %t499 = select i1 %t498, i64 %t497, i64 1
  %t500 = getelementptr i8, i8* null, i32 1
  %t501 = ptrtoint i8* %t500 to i64
  %t502 = mul i64 %t499, %t501
  %t503 = call i8* @malloc(i64 %t502)
  %t504 = bitcast i8* %t503 to i8*
  %t505 = icmp sgt i64 %t493, 0
  br i1 %t505, label %list_push_copy_391, label %list_push_after_copy_392
list_push_copy_391:
  %t506 = mul i64 %t495, %t501
  %t507 = bitcast i8* %t494 to i8*
  call i8* @memcpy(i8* %t503, i8* %t507, i64 %t506)
  call void @free(i8* %t507)
  br label %list_push_after_copy_392
list_push_after_copy_392:
  store i8* %t504, i8** %t487
  store i64 %t499, i64* %t491
  br label %list_push_store_390
list_push_store_390:
  %t508 = load i8*, i8** %t487
  %t509 = getelementptr inbounds i8, i8* %t508, i64 %t495
  store i8 %t492, i8* %t509
  %t510 = add i64 %t495, 1
  store i64 %t510, i64* %t489
  %t511 = getelementptr i8, i8* null, i32 1
  %t512 = ptrtoint i8* %t511 to i64
  %t513 = load i8*, i8** %t11
  %t514 = icmp eq i8* %t513, null
  br i1 %t514, label %list_cow_alloc_393, label %list_cow_check_394
list_cow_alloc_393:
  %t515 = bitcast void (i8*)* @list_release_u8 to i8*
  %t516 = call i8* @star_rc_alloc(i64 24, i8* %t515)
  %t517 = bitcast i8* %t516 to { i8*, i64, i64 }*
  %t518 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t517, i32 0, i32 0
  store i8* null, i8** %t518
  %t519 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t517, i32 0, i32 1
  store i64 0, i64* %t519
  %t520 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t517, i32 0, i32 2
  store i64 0, i64* %t520
  store i8* %t516, i8** %t11
  br label %list_cow_done_395
list_cow_check_394:
  %t521 = getelementptr inbounds i8, i8* %t513, i64 -16
  %t522 = bitcast i8* %t521 to i64*
  %t523 = load atomic i64, i64* %t522 seq_cst, align 8
  %t524 = icmp eq i64 %t523, 1
  br i1 %t524, label %list_cow_done_395, label %list_cow_clone_396
list_cow_clone_396:
  %t525 = bitcast i8* %t513 to { i8*, i64, i64 }*
  %t526 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t525, i32 0, i32 0
  %t527 = load i8*, i8** %t526
  %t528 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t525, i32 0, i32 1
  %t529 = load i64, i64* %t528
  %t530 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t525, i32 0, i32 2
  %t531 = load i64, i64* %t530
  %t532 = bitcast void (i8*)* @list_release_u8 to i8*
  %t533 = call i8* @star_rc_alloc(i64 24, i8* %t532)
  %t534 = bitcast i8* %t533 to { i8*, i64, i64 }*
  %t535 = mul i64 %t531, %t512
  %t536 = call i8* @malloc(i64 %t535)
  %t537 = bitcast i8* %t536 to i8*
  %t538 = icmp sgt i64 %t529, 0
  br i1 %t538, label %list_cow_copy_397, label %list_cow_after_copy_398
list_cow_copy_397:
  %t539 = mul i64 %t529, %t512
  %t540 = bitcast i8* %t527 to i8*
  call i8* @memcpy(i8* %t536, i8* %t540, i64 %t539)
  br label %list_cow_after_copy_398
list_cow_after_copy_398:
  %t541 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t534, i32 0, i32 0
  store i8* %t537, i8** %t541
  %t542 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t534, i32 0, i32 1
  store i64 %t529, i64* %t542
  %t543 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t534, i32 0, i32 2
  store i64 %t531, i64* %t543
  call void @star_rc_release(i8* %t513)
  store i8* %t533, i8** %t11
  br label %list_cow_done_395
list_cow_done_395:
  %t544 = load i8*, i8** %t11
  %t545 = bitcast i8* %t544 to { i8*, i64, i64 }*
  %t546 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t545, i32 0, i32 0
  %t547 = load i8*, i8** %t546
  %t548 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t545, i32 0, i32 1
  %t549 = load i64, i64* %t548
  %t550 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t545, i32 0, i32 2
  %t551 = trunc i32 102 to i8
  %t552 = load i64, i64* %t550
  %t553 = load i8*, i8** %t546
  %t554 = load i64, i64* %t548
  %t555 = icmp sge i64 %t554, %t552
  br i1 %t555, label %list_push_grow_399, label %list_push_store_400
list_push_grow_399:
  %t556 = mul i64 %t552, 2
  %t557 = icmp sgt i64 %t556, 0
  %t558 = select i1 %t557, i64 %t556, i64 1
  %t559 = getelementptr i8, i8* null, i32 1
  %t560 = ptrtoint i8* %t559 to i64
  %t561 = mul i64 %t558, %t560
  %t562 = call i8* @malloc(i64 %t561)
  %t563 = bitcast i8* %t562 to i8*
  %t564 = icmp sgt i64 %t552, 0
  br i1 %t564, label %list_push_copy_401, label %list_push_after_copy_402
list_push_copy_401:
  %t565 = mul i64 %t554, %t560
  %t566 = bitcast i8* %t553 to i8*
  call i8* @memcpy(i8* %t562, i8* %t566, i64 %t565)
  call void @free(i8* %t566)
  br label %list_push_after_copy_402
list_push_after_copy_402:
  store i8* %t563, i8** %t546
  store i64 %t558, i64* %t550
  br label %list_push_store_400
list_push_store_400:
  %t567 = load i8*, i8** %t546
  %t568 = getelementptr inbounds i8, i8* %t567, i64 %t554
  store i8 %t551, i8* %t568
  %t569 = add i64 %t554, 1
  store i64 %t569, i64* %t548
  %t570 = getelementptr i8, i8* null, i32 1
  %t571 = ptrtoint i8* %t570 to i64
  %t572 = load i8*, i8** %t11
  %t573 = icmp eq i8* %t572, null
  br i1 %t573, label %list_cow_alloc_403, label %list_cow_check_404
list_cow_alloc_403:
  %t574 = bitcast void (i8*)* @list_release_u8 to i8*
  %t575 = call i8* @star_rc_alloc(i64 24, i8* %t574)
  %t576 = bitcast i8* %t575 to { i8*, i64, i64 }*
  %t577 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t576, i32 0, i32 0
  store i8* null, i8** %t577
  %t578 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t576, i32 0, i32 1
  store i64 0, i64* %t578
  %t579 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t576, i32 0, i32 2
  store i64 0, i64* %t579
  store i8* %t575, i8** %t11
  br label %list_cow_done_405
list_cow_check_404:
  %t580 = getelementptr inbounds i8, i8* %t572, i64 -16
  %t581 = bitcast i8* %t580 to i64*
  %t582 = load atomic i64, i64* %t581 seq_cst, align 8
  %t583 = icmp eq i64 %t582, 1
  br i1 %t583, label %list_cow_done_405, label %list_cow_clone_406
list_cow_clone_406:
  %t584 = bitcast i8* %t572 to { i8*, i64, i64 }*
  %t585 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t584, i32 0, i32 0
  %t586 = load i8*, i8** %t585
  %t587 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t584, i32 0, i32 1
  %t588 = load i64, i64* %t587
  %t589 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t584, i32 0, i32 2
  %t590 = load i64, i64* %t589
  %t591 = bitcast void (i8*)* @list_release_u8 to i8*
  %t592 = call i8* @star_rc_alloc(i64 24, i8* %t591)
  %t593 = bitcast i8* %t592 to { i8*, i64, i64 }*
  %t594 = mul i64 %t590, %t571
  %t595 = call i8* @malloc(i64 %t594)
  %t596 = bitcast i8* %t595 to i8*
  %t597 = icmp sgt i64 %t588, 0
  br i1 %t597, label %list_cow_copy_407, label %list_cow_after_copy_408
list_cow_copy_407:
  %t598 = mul i64 %t588, %t571
  %t599 = bitcast i8* %t586 to i8*
  call i8* @memcpy(i8* %t595, i8* %t599, i64 %t598)
  br label %list_cow_after_copy_408
list_cow_after_copy_408:
  %t600 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t593, i32 0, i32 0
  store i8* %t596, i8** %t600
  %t601 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t593, i32 0, i32 1
  store i64 %t588, i64* %t601
  %t602 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t593, i32 0, i32 2
  store i64 %t590, i64* %t602
  call void @star_rc_release(i8* %t572)
  store i8* %t592, i8** %t11
  br label %list_cow_done_405
list_cow_done_405:
  %t603 = load i8*, i8** %t11
  %t604 = bitcast i8* %t603 to { i8*, i64, i64 }*
  %t605 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t604, i32 0, i32 0
  %t606 = load i8*, i8** %t605
  %t607 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t604, i32 0, i32 1
  %t608 = load i64, i64* %t607
  %t609 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t604, i32 0, i32 2
  %t610 = trunc i32 109 to i8
  %t611 = load i64, i64* %t609
  %t612 = load i8*, i8** %t605
  %t613 = load i64, i64* %t607
  %t614 = icmp sge i64 %t613, %t611
  br i1 %t614, label %list_push_grow_409, label %list_push_store_410
list_push_grow_409:
  %t615 = mul i64 %t611, 2
  %t616 = icmp sgt i64 %t615, 0
  %t617 = select i1 %t616, i64 %t615, i64 1
  %t618 = getelementptr i8, i8* null, i32 1
  %t619 = ptrtoint i8* %t618 to i64
  %t620 = mul i64 %t617, %t619
  %t621 = call i8* @malloc(i64 %t620)
  %t622 = bitcast i8* %t621 to i8*
  %t623 = icmp sgt i64 %t611, 0
  br i1 %t623, label %list_push_copy_411, label %list_push_after_copy_412
list_push_copy_411:
  %t624 = mul i64 %t613, %t619
  %t625 = bitcast i8* %t612 to i8*
  call i8* @memcpy(i8* %t621, i8* %t625, i64 %t624)
  call void @free(i8* %t625)
  br label %list_push_after_copy_412
list_push_after_copy_412:
  store i8* %t622, i8** %t605
  store i64 %t617, i64* %t609
  br label %list_push_store_410
list_push_store_410:
  %t626 = load i8*, i8** %t605
  %t627 = getelementptr inbounds i8, i8* %t626, i64 %t613
  store i8 %t610, i8* %t627
  %t628 = add i64 %t613, 1
  store i64 %t628, i64* %t607
  %t629 = getelementptr i8, i8* null, i32 1
  %t630 = ptrtoint i8* %t629 to i64
  %t631 = load i8*, i8** %t11
  %t632 = icmp eq i8* %t631, null
  br i1 %t632, label %list_cow_alloc_413, label %list_cow_check_414
list_cow_alloc_413:
  %t633 = bitcast void (i8*)* @list_release_u8 to i8*
  %t634 = call i8* @star_rc_alloc(i64 24, i8* %t633)
  %t635 = bitcast i8* %t634 to { i8*, i64, i64 }*
  %t636 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t635, i32 0, i32 0
  store i8* null, i8** %t636
  %t637 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t635, i32 0, i32 1
  store i64 0, i64* %t637
  %t638 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t635, i32 0, i32 2
  store i64 0, i64* %t638
  store i8* %t634, i8** %t11
  br label %list_cow_done_415
list_cow_check_414:
  %t639 = getelementptr inbounds i8, i8* %t631, i64 -16
  %t640 = bitcast i8* %t639 to i64*
  %t641 = load atomic i64, i64* %t640 seq_cst, align 8
  %t642 = icmp eq i64 %t641, 1
  br i1 %t642, label %list_cow_done_415, label %list_cow_clone_416
list_cow_clone_416:
  %t643 = bitcast i8* %t631 to { i8*, i64, i64 }*
  %t644 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t643, i32 0, i32 0
  %t645 = load i8*, i8** %t644
  %t646 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t643, i32 0, i32 1
  %t647 = load i64, i64* %t646
  %t648 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t643, i32 0, i32 2
  %t649 = load i64, i64* %t648
  %t650 = bitcast void (i8*)* @list_release_u8 to i8*
  %t651 = call i8* @star_rc_alloc(i64 24, i8* %t650)
  %t652 = bitcast i8* %t651 to { i8*, i64, i64 }*
  %t653 = mul i64 %t649, %t630
  %t654 = call i8* @malloc(i64 %t653)
  %t655 = bitcast i8* %t654 to i8*
  %t656 = icmp sgt i64 %t647, 0
  br i1 %t656, label %list_cow_copy_417, label %list_cow_after_copy_418
list_cow_copy_417:
  %t657 = mul i64 %t647, %t630
  %t658 = bitcast i8* %t645 to i8*
  call i8* @memcpy(i8* %t654, i8* %t658, i64 %t657)
  br label %list_cow_after_copy_418
list_cow_after_copy_418:
  %t659 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t652, i32 0, i32 0
  store i8* %t655, i8** %t659
  %t660 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t652, i32 0, i32 1
  store i64 %t647, i64* %t660
  %t661 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t652, i32 0, i32 2
  store i64 %t649, i64* %t661
  call void @star_rc_release(i8* %t631)
  store i8* %t651, i8** %t11
  br label %list_cow_done_415
list_cow_done_415:
  %t662 = load i8*, i8** %t11
  %t663 = bitcast i8* %t662 to { i8*, i64, i64 }*
  %t664 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t663, i32 0, i32 0
  %t665 = load i8*, i8** %t664
  %t666 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t663, i32 0, i32 1
  %t667 = load i64, i64* %t666
  %t668 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t663, i32 0, i32 2
  %t669 = trunc i32 116 to i8
  %t670 = load i64, i64* %t668
  %t671 = load i8*, i8** %t664
  %t672 = load i64, i64* %t666
  %t673 = icmp sge i64 %t672, %t670
  br i1 %t673, label %list_push_grow_419, label %list_push_store_420
list_push_grow_419:
  %t674 = mul i64 %t670, 2
  %t675 = icmp sgt i64 %t674, 0
  %t676 = select i1 %t675, i64 %t674, i64 1
  %t677 = getelementptr i8, i8* null, i32 1
  %t678 = ptrtoint i8* %t677 to i64
  %t679 = mul i64 %t676, %t678
  %t680 = call i8* @malloc(i64 %t679)
  %t681 = bitcast i8* %t680 to i8*
  %t682 = icmp sgt i64 %t670, 0
  br i1 %t682, label %list_push_copy_421, label %list_push_after_copy_422
list_push_copy_421:
  %t683 = mul i64 %t672, %t678
  %t684 = bitcast i8* %t671 to i8*
  call i8* @memcpy(i8* %t680, i8* %t684, i64 %t683)
  call void @free(i8* %t684)
  br label %list_push_after_copy_422
list_push_after_copy_422:
  store i8* %t681, i8** %t664
  store i64 %t676, i64* %t668
  br label %list_push_store_420
list_push_store_420:
  %t685 = load i8*, i8** %t664
  %t686 = getelementptr inbounds i8, i8* %t685, i64 %t672
  store i8 %t669, i8* %t686
  %t687 = add i64 %t672, 1
  store i64 %t687, i64* %t666
  %t688 = getelementptr i8, i8* null, i32 1
  %t689 = ptrtoint i8* %t688 to i64
  %t690 = load i8*, i8** %t11
  %t691 = icmp eq i8* %t690, null
  br i1 %t691, label %list_cow_alloc_423, label %list_cow_check_424
list_cow_alloc_423:
  %t692 = bitcast void (i8*)* @list_release_u8 to i8*
  %t693 = call i8* @star_rc_alloc(i64 24, i8* %t692)
  %t694 = bitcast i8* %t693 to { i8*, i64, i64 }*
  %t695 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t694, i32 0, i32 0
  store i8* null, i8** %t695
  %t696 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t694, i32 0, i32 1
  store i64 0, i64* %t696
  %t697 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t694, i32 0, i32 2
  store i64 0, i64* %t697
  store i8* %t693, i8** %t11
  br label %list_cow_done_425
list_cow_check_424:
  %t698 = getelementptr inbounds i8, i8* %t690, i64 -16
  %t699 = bitcast i8* %t698 to i64*
  %t700 = load atomic i64, i64* %t699 seq_cst, align 8
  %t701 = icmp eq i64 %t700, 1
  br i1 %t701, label %list_cow_done_425, label %list_cow_clone_426
list_cow_clone_426:
  %t702 = bitcast i8* %t690 to { i8*, i64, i64 }*
  %t703 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t702, i32 0, i32 0
  %t704 = load i8*, i8** %t703
  %t705 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t702, i32 0, i32 1
  %t706 = load i64, i64* %t705
  %t707 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t702, i32 0, i32 2
  %t708 = load i64, i64* %t707
  %t709 = bitcast void (i8*)* @list_release_u8 to i8*
  %t710 = call i8* @star_rc_alloc(i64 24, i8* %t709)
  %t711 = bitcast i8* %t710 to { i8*, i64, i64 }*
  %t712 = mul i64 %t708, %t689
  %t713 = call i8* @malloc(i64 %t712)
  %t714 = bitcast i8* %t713 to i8*
  %t715 = icmp sgt i64 %t706, 0
  br i1 %t715, label %list_cow_copy_427, label %list_cow_after_copy_428
list_cow_copy_427:
  %t716 = mul i64 %t706, %t689
  %t717 = bitcast i8* %t704 to i8*
  call i8* @memcpy(i8* %t713, i8* %t717, i64 %t716)
  br label %list_cow_after_copy_428
list_cow_after_copy_428:
  %t718 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t711, i32 0, i32 0
  store i8* %t714, i8** %t718
  %t719 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t711, i32 0, i32 1
  store i64 %t706, i64* %t719
  %t720 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t711, i32 0, i32 2
  store i64 %t708, i64* %t720
  call void @star_rc_release(i8* %t690)
  store i8* %t710, i8** %t11
  br label %list_cow_done_425
list_cow_done_425:
  %t721 = load i8*, i8** %t11
  %t722 = bitcast i8* %t721 to { i8*, i64, i64 }*
  %t723 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t722, i32 0, i32 0
  %t724 = load i8*, i8** %t723
  %t725 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t722, i32 0, i32 1
  %t726 = load i64, i64* %t725
  %t727 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t722, i32 0, i32 2
  %t728 = trunc i32 32 to i8
  %t729 = load i64, i64* %t727
  %t730 = load i8*, i8** %t723
  %t731 = load i64, i64* %t725
  %t732 = icmp sge i64 %t731, %t729
  br i1 %t732, label %list_push_grow_429, label %list_push_store_430
list_push_grow_429:
  %t733 = mul i64 %t729, 2
  %t734 = icmp sgt i64 %t733, 0
  %t735 = select i1 %t734, i64 %t733, i64 1
  %t736 = getelementptr i8, i8* null, i32 1
  %t737 = ptrtoint i8* %t736 to i64
  %t738 = mul i64 %t735, %t737
  %t739 = call i8* @malloc(i64 %t738)
  %t740 = bitcast i8* %t739 to i8*
  %t741 = icmp sgt i64 %t729, 0
  br i1 %t741, label %list_push_copy_431, label %list_push_after_copy_432
list_push_copy_431:
  %t742 = mul i64 %t731, %t737
  %t743 = bitcast i8* %t730 to i8*
  call i8* @memcpy(i8* %t739, i8* %t743, i64 %t742)
  call void @free(i8* %t743)
  br label %list_push_after_copy_432
list_push_after_copy_432:
  store i8* %t740, i8** %t723
  store i64 %t735, i64* %t727
  br label %list_push_store_430
list_push_store_430:
  %t744 = load i8*, i8** %t723
  %t745 = getelementptr inbounds i8, i8* %t744, i64 %t731
  store i8 %t728, i8* %t745
  %t746 = add i64 %t731, 1
  store i64 %t746, i64* %t725
  %t747 = load i8*, i8** %t11
  %t748 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t748)
  %t749 = call i8* @audio__push_i16(i8* %t747, i32 16)
  %t750 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t750)
  store i8* %t749, i8** %t11
  %t751 = load i8*, i8** %t11
  %t752 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t752)
  %t753 = call i8* @audio__push_i16(i8* %t751, i32 0)
  %t754 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t754)
  store i8* %t753, i8** %t11
  %t755 = load i8*, i8** %t11
  %t756 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t756)
  %t757 = call i8* @audio__push_i16(i8* %t755, i32 1)
  %t758 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t758)
  store i8* %t757, i8** %t11
  %t759 = load i8*, i8** %t11
  %t760 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t760)
  %t761 = call i8* @audio__push_i16(i8* %t759, i32 0)
  %t762 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t762)
  store i8* %t761, i8** %t11
  %t763 = load i8*, i8** %t11
  %t764 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t764)
  %t765 = call i8* @audio__push_i16(i8* %t763, i32 2)
  %t766 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t766)
  store i8* %t765, i8** %t11
  %t767 = load i8*, i8** %t11
  %t768 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t768)
  %t769 = call i8* @audio__push_i16(i8* %t767, i32 0)
  %t770 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t770)
  store i8* %t769, i8** %t11
  %t771 = load i8*, i8** %t11
  %t772 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t772)
  %t773 = and i32 44100, 65535
  %t774 = call i8* @audio__push_i16(i8* %t771, i32 %t773)
  %t775 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t775)
  store i8* %t774, i8** %t11
  %t776 = load i8*, i8** %t11
  %t777 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t777)
  %t778 = and i32 16, 31
  %t779 = ashr i32 44100, %t778
  %t780 = and i32 %t779, 65535
  %t781 = call i8* @audio__push_i16(i8* %t776, i32 %t780)
  %t782 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t782)
  store i8* %t781, i8** %t11
  %t784 = mul i32 44100, 2
  %t785 = mul i32 %t784, 2
  store i32 %t785, i32* %t783
  %t786 = load i8*, i8** %t11
  %t787 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t787)
  %t788 = load i32, i32* %t783
  %t789 = and i32 %t788, 65535
  %t790 = call i8* @audio__push_i16(i8* %t786, i32 %t789)
  %t791 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t791)
  store i8* %t790, i8** %t11
  %t792 = load i8*, i8** %t11
  %t793 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t793)
  %t794 = load i32, i32* %t783
  %t795 = and i32 16, 31
  %t796 = ashr i32 %t794, %t795
  %t797 = and i32 %t796, 65535
  %t798 = call i8* @audio__push_i16(i8* %t792, i32 %t797)
  %t799 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t799)
  store i8* %t798, i8** %t11
  %t800 = load i8*, i8** %t11
  %t801 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t801)
  %t802 = call i8* @audio__push_i16(i8* %t800, i32 4)
  %t803 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t803)
  store i8* %t802, i8** %t11
  %t804 = load i8*, i8** %t11
  %t805 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t805)
  %t806 = call i8* @audio__push_i16(i8* %t804, i32 0)
  %t807 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t807)
  store i8* %t806, i8** %t11
  %t808 = load i8*, i8** %t11
  %t809 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t809)
  %t810 = call i8* @audio__push_i16(i8* %t808, i32 16)
  %t811 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t811)
  store i8* %t810, i8** %t11
  %t812 = load i8*, i8** %t11
  %t813 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t813)
  %t814 = call i8* @audio__push_i16(i8* %t812, i32 0)
  %t815 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t815)
  store i8* %t814, i8** %t11
  %t816 = getelementptr i8, i8* null, i32 1
  %t817 = ptrtoint i8* %t816 to i64
  %t818 = load i8*, i8** %t11
  %t819 = icmp eq i8* %t818, null
  br i1 %t819, label %list_cow_alloc_433, label %list_cow_check_434
list_cow_alloc_433:
  %t820 = bitcast void (i8*)* @list_release_u8 to i8*
  %t821 = call i8* @star_rc_alloc(i64 24, i8* %t820)
  %t822 = bitcast i8* %t821 to { i8*, i64, i64 }*
  %t823 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t822, i32 0, i32 0
  store i8* null, i8** %t823
  %t824 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t822, i32 0, i32 1
  store i64 0, i64* %t824
  %t825 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t822, i32 0, i32 2
  store i64 0, i64* %t825
  store i8* %t821, i8** %t11
  br label %list_cow_done_435
list_cow_check_434:
  %t826 = getelementptr inbounds i8, i8* %t818, i64 -16
  %t827 = bitcast i8* %t826 to i64*
  %t828 = load atomic i64, i64* %t827 seq_cst, align 8
  %t829 = icmp eq i64 %t828, 1
  br i1 %t829, label %list_cow_done_435, label %list_cow_clone_436
list_cow_clone_436:
  %t830 = bitcast i8* %t818 to { i8*, i64, i64 }*
  %t831 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t830, i32 0, i32 0
  %t832 = load i8*, i8** %t831
  %t833 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t830, i32 0, i32 1
  %t834 = load i64, i64* %t833
  %t835 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t830, i32 0, i32 2
  %t836 = load i64, i64* %t835
  %t837 = bitcast void (i8*)* @list_release_u8 to i8*
  %t838 = call i8* @star_rc_alloc(i64 24, i8* %t837)
  %t839 = bitcast i8* %t838 to { i8*, i64, i64 }*
  %t840 = mul i64 %t836, %t817
  %t841 = call i8* @malloc(i64 %t840)
  %t842 = bitcast i8* %t841 to i8*
  %t843 = icmp sgt i64 %t834, 0
  br i1 %t843, label %list_cow_copy_437, label %list_cow_after_copy_438
list_cow_copy_437:
  %t844 = mul i64 %t834, %t817
  %t845 = bitcast i8* %t832 to i8*
  call i8* @memcpy(i8* %t841, i8* %t845, i64 %t844)
  br label %list_cow_after_copy_438
list_cow_after_copy_438:
  %t846 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t839, i32 0, i32 0
  store i8* %t842, i8** %t846
  %t847 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t839, i32 0, i32 1
  store i64 %t834, i64* %t847
  %t848 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t839, i32 0, i32 2
  store i64 %t836, i64* %t848
  call void @star_rc_release(i8* %t818)
  store i8* %t838, i8** %t11
  br label %list_cow_done_435
list_cow_done_435:
  %t849 = load i8*, i8** %t11
  %t850 = bitcast i8* %t849 to { i8*, i64, i64 }*
  %t851 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t850, i32 0, i32 0
  %t852 = load i8*, i8** %t851
  %t853 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t850, i32 0, i32 1
  %t854 = load i64, i64* %t853
  %t855 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t850, i32 0, i32 2
  %t856 = trunc i32 100 to i8
  %t857 = load i64, i64* %t855
  %t858 = load i8*, i8** %t851
  %t859 = load i64, i64* %t853
  %t860 = icmp sge i64 %t859, %t857
  br i1 %t860, label %list_push_grow_439, label %list_push_store_440
list_push_grow_439:
  %t861 = mul i64 %t857, 2
  %t862 = icmp sgt i64 %t861, 0
  %t863 = select i1 %t862, i64 %t861, i64 1
  %t864 = getelementptr i8, i8* null, i32 1
  %t865 = ptrtoint i8* %t864 to i64
  %t866 = mul i64 %t863, %t865
  %t867 = call i8* @malloc(i64 %t866)
  %t868 = bitcast i8* %t867 to i8*
  %t869 = icmp sgt i64 %t857, 0
  br i1 %t869, label %list_push_copy_441, label %list_push_after_copy_442
list_push_copy_441:
  %t870 = mul i64 %t859, %t865
  %t871 = bitcast i8* %t858 to i8*
  call i8* @memcpy(i8* %t867, i8* %t871, i64 %t870)
  call void @free(i8* %t871)
  br label %list_push_after_copy_442
list_push_after_copy_442:
  store i8* %t868, i8** %t851
  store i64 %t863, i64* %t855
  br label %list_push_store_440
list_push_store_440:
  %t872 = load i8*, i8** %t851
  %t873 = getelementptr inbounds i8, i8* %t872, i64 %t859
  store i8 %t856, i8* %t873
  %t874 = add i64 %t859, 1
  store i64 %t874, i64* %t853
  %t875 = getelementptr i8, i8* null, i32 1
  %t876 = ptrtoint i8* %t875 to i64
  %t877 = load i8*, i8** %t11
  %t878 = icmp eq i8* %t877, null
  br i1 %t878, label %list_cow_alloc_443, label %list_cow_check_444
list_cow_alloc_443:
  %t879 = bitcast void (i8*)* @list_release_u8 to i8*
  %t880 = call i8* @star_rc_alloc(i64 24, i8* %t879)
  %t881 = bitcast i8* %t880 to { i8*, i64, i64 }*
  %t882 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t881, i32 0, i32 0
  store i8* null, i8** %t882
  %t883 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t881, i32 0, i32 1
  store i64 0, i64* %t883
  %t884 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t881, i32 0, i32 2
  store i64 0, i64* %t884
  store i8* %t880, i8** %t11
  br label %list_cow_done_445
list_cow_check_444:
  %t885 = getelementptr inbounds i8, i8* %t877, i64 -16
  %t886 = bitcast i8* %t885 to i64*
  %t887 = load atomic i64, i64* %t886 seq_cst, align 8
  %t888 = icmp eq i64 %t887, 1
  br i1 %t888, label %list_cow_done_445, label %list_cow_clone_446
list_cow_clone_446:
  %t889 = bitcast i8* %t877 to { i8*, i64, i64 }*
  %t890 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t889, i32 0, i32 0
  %t891 = load i8*, i8** %t890
  %t892 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t889, i32 0, i32 1
  %t893 = load i64, i64* %t892
  %t894 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t889, i32 0, i32 2
  %t895 = load i64, i64* %t894
  %t896 = bitcast void (i8*)* @list_release_u8 to i8*
  %t897 = call i8* @star_rc_alloc(i64 24, i8* %t896)
  %t898 = bitcast i8* %t897 to { i8*, i64, i64 }*
  %t899 = mul i64 %t895, %t876
  %t900 = call i8* @malloc(i64 %t899)
  %t901 = bitcast i8* %t900 to i8*
  %t902 = icmp sgt i64 %t893, 0
  br i1 %t902, label %list_cow_copy_447, label %list_cow_after_copy_448
list_cow_copy_447:
  %t903 = mul i64 %t893, %t876
  %t904 = bitcast i8* %t891 to i8*
  call i8* @memcpy(i8* %t900, i8* %t904, i64 %t903)
  br label %list_cow_after_copy_448
list_cow_after_copy_448:
  %t905 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t898, i32 0, i32 0
  store i8* %t901, i8** %t905
  %t906 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t898, i32 0, i32 1
  store i64 %t893, i64* %t906
  %t907 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t898, i32 0, i32 2
  store i64 %t895, i64* %t907
  call void @star_rc_release(i8* %t877)
  store i8* %t897, i8** %t11
  br label %list_cow_done_445
list_cow_done_445:
  %t908 = load i8*, i8** %t11
  %t909 = bitcast i8* %t908 to { i8*, i64, i64 }*
  %t910 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t909, i32 0, i32 0
  %t911 = load i8*, i8** %t910
  %t912 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t909, i32 0, i32 1
  %t913 = load i64, i64* %t912
  %t914 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t909, i32 0, i32 2
  %t915 = trunc i32 97 to i8
  %t916 = load i64, i64* %t914
  %t917 = load i8*, i8** %t910
  %t918 = load i64, i64* %t912
  %t919 = icmp sge i64 %t918, %t916
  br i1 %t919, label %list_push_grow_449, label %list_push_store_450
list_push_grow_449:
  %t920 = mul i64 %t916, 2
  %t921 = icmp sgt i64 %t920, 0
  %t922 = select i1 %t921, i64 %t920, i64 1
  %t923 = getelementptr i8, i8* null, i32 1
  %t924 = ptrtoint i8* %t923 to i64
  %t925 = mul i64 %t922, %t924
  %t926 = call i8* @malloc(i64 %t925)
  %t927 = bitcast i8* %t926 to i8*
  %t928 = icmp sgt i64 %t916, 0
  br i1 %t928, label %list_push_copy_451, label %list_push_after_copy_452
list_push_copy_451:
  %t929 = mul i64 %t918, %t924
  %t930 = bitcast i8* %t917 to i8*
  call i8* @memcpy(i8* %t926, i8* %t930, i64 %t929)
  call void @free(i8* %t930)
  br label %list_push_after_copy_452
list_push_after_copy_452:
  store i8* %t927, i8** %t910
  store i64 %t922, i64* %t914
  br label %list_push_store_450
list_push_store_450:
  %t931 = load i8*, i8** %t910
  %t932 = getelementptr inbounds i8, i8* %t931, i64 %t918
  store i8 %t915, i8* %t932
  %t933 = add i64 %t918, 1
  store i64 %t933, i64* %t912
  %t934 = getelementptr i8, i8* null, i32 1
  %t935 = ptrtoint i8* %t934 to i64
  %t936 = load i8*, i8** %t11
  %t937 = icmp eq i8* %t936, null
  br i1 %t937, label %list_cow_alloc_453, label %list_cow_check_454
list_cow_alloc_453:
  %t938 = bitcast void (i8*)* @list_release_u8 to i8*
  %t939 = call i8* @star_rc_alloc(i64 24, i8* %t938)
  %t940 = bitcast i8* %t939 to { i8*, i64, i64 }*
  %t941 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t940, i32 0, i32 0
  store i8* null, i8** %t941
  %t942 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t940, i32 0, i32 1
  store i64 0, i64* %t942
  %t943 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t940, i32 0, i32 2
  store i64 0, i64* %t943
  store i8* %t939, i8** %t11
  br label %list_cow_done_455
list_cow_check_454:
  %t944 = getelementptr inbounds i8, i8* %t936, i64 -16
  %t945 = bitcast i8* %t944 to i64*
  %t946 = load atomic i64, i64* %t945 seq_cst, align 8
  %t947 = icmp eq i64 %t946, 1
  br i1 %t947, label %list_cow_done_455, label %list_cow_clone_456
list_cow_clone_456:
  %t948 = bitcast i8* %t936 to { i8*, i64, i64 }*
  %t949 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t948, i32 0, i32 0
  %t950 = load i8*, i8** %t949
  %t951 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t948, i32 0, i32 1
  %t952 = load i64, i64* %t951
  %t953 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t948, i32 0, i32 2
  %t954 = load i64, i64* %t953
  %t955 = bitcast void (i8*)* @list_release_u8 to i8*
  %t956 = call i8* @star_rc_alloc(i64 24, i8* %t955)
  %t957 = bitcast i8* %t956 to { i8*, i64, i64 }*
  %t958 = mul i64 %t954, %t935
  %t959 = call i8* @malloc(i64 %t958)
  %t960 = bitcast i8* %t959 to i8*
  %t961 = icmp sgt i64 %t952, 0
  br i1 %t961, label %list_cow_copy_457, label %list_cow_after_copy_458
list_cow_copy_457:
  %t962 = mul i64 %t952, %t935
  %t963 = bitcast i8* %t950 to i8*
  call i8* @memcpy(i8* %t959, i8* %t963, i64 %t962)
  br label %list_cow_after_copy_458
list_cow_after_copy_458:
  %t964 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t957, i32 0, i32 0
  store i8* %t960, i8** %t964
  %t965 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t957, i32 0, i32 1
  store i64 %t952, i64* %t965
  %t966 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t957, i32 0, i32 2
  store i64 %t954, i64* %t966
  call void @star_rc_release(i8* %t936)
  store i8* %t956, i8** %t11
  br label %list_cow_done_455
list_cow_done_455:
  %t967 = load i8*, i8** %t11
  %t968 = bitcast i8* %t967 to { i8*, i64, i64 }*
  %t969 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t968, i32 0, i32 0
  %t970 = load i8*, i8** %t969
  %t971 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t968, i32 0, i32 1
  %t972 = load i64, i64* %t971
  %t973 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t968, i32 0, i32 2
  %t974 = trunc i32 116 to i8
  %t975 = load i64, i64* %t973
  %t976 = load i8*, i8** %t969
  %t977 = load i64, i64* %t971
  %t978 = icmp sge i64 %t977, %t975
  br i1 %t978, label %list_push_grow_459, label %list_push_store_460
list_push_grow_459:
  %t979 = mul i64 %t975, 2
  %t980 = icmp sgt i64 %t979, 0
  %t981 = select i1 %t980, i64 %t979, i64 1
  %t982 = getelementptr i8, i8* null, i32 1
  %t983 = ptrtoint i8* %t982 to i64
  %t984 = mul i64 %t981, %t983
  %t985 = call i8* @malloc(i64 %t984)
  %t986 = bitcast i8* %t985 to i8*
  %t987 = icmp sgt i64 %t975, 0
  br i1 %t987, label %list_push_copy_461, label %list_push_after_copy_462
list_push_copy_461:
  %t988 = mul i64 %t977, %t983
  %t989 = bitcast i8* %t976 to i8*
  call i8* @memcpy(i8* %t985, i8* %t989, i64 %t988)
  call void @free(i8* %t989)
  br label %list_push_after_copy_462
list_push_after_copy_462:
  store i8* %t986, i8** %t969
  store i64 %t981, i64* %t973
  br label %list_push_store_460
list_push_store_460:
  %t990 = load i8*, i8** %t969
  %t991 = getelementptr inbounds i8, i8* %t990, i64 %t977
  store i8 %t974, i8* %t991
  %t992 = add i64 %t977, 1
  store i64 %t992, i64* %t971
  %t993 = getelementptr i8, i8* null, i32 1
  %t994 = ptrtoint i8* %t993 to i64
  %t995 = load i8*, i8** %t11
  %t996 = icmp eq i8* %t995, null
  br i1 %t996, label %list_cow_alloc_463, label %list_cow_check_464
list_cow_alloc_463:
  %t997 = bitcast void (i8*)* @list_release_u8 to i8*
  %t998 = call i8* @star_rc_alloc(i64 24, i8* %t997)
  %t999 = bitcast i8* %t998 to { i8*, i64, i64 }*
  %t1000 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t999, i32 0, i32 0
  store i8* null, i8** %t1000
  %t1001 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t999, i32 0, i32 1
  store i64 0, i64* %t1001
  %t1002 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t999, i32 0, i32 2
  store i64 0, i64* %t1002
  store i8* %t998, i8** %t11
  br label %list_cow_done_465
list_cow_check_464:
  %t1003 = getelementptr inbounds i8, i8* %t995, i64 -16
  %t1004 = bitcast i8* %t1003 to i64*
  %t1005 = load atomic i64, i64* %t1004 seq_cst, align 8
  %t1006 = icmp eq i64 %t1005, 1
  br i1 %t1006, label %list_cow_done_465, label %list_cow_clone_466
list_cow_clone_466:
  %t1007 = bitcast i8* %t995 to { i8*, i64, i64 }*
  %t1008 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1007, i32 0, i32 0
  %t1009 = load i8*, i8** %t1008
  %t1010 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1007, i32 0, i32 1
  %t1011 = load i64, i64* %t1010
  %t1012 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1007, i32 0, i32 2
  %t1013 = load i64, i64* %t1012
  %t1014 = bitcast void (i8*)* @list_release_u8 to i8*
  %t1015 = call i8* @star_rc_alloc(i64 24, i8* %t1014)
  %t1016 = bitcast i8* %t1015 to { i8*, i64, i64 }*
  %t1017 = mul i64 %t1013, %t994
  %t1018 = call i8* @malloc(i64 %t1017)
  %t1019 = bitcast i8* %t1018 to i8*
  %t1020 = icmp sgt i64 %t1011, 0
  br i1 %t1020, label %list_cow_copy_467, label %list_cow_after_copy_468
list_cow_copy_467:
  %t1021 = mul i64 %t1011, %t994
  %t1022 = bitcast i8* %t1009 to i8*
  call i8* @memcpy(i8* %t1018, i8* %t1022, i64 %t1021)
  br label %list_cow_after_copy_468
list_cow_after_copy_468:
  %t1023 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1016, i32 0, i32 0
  store i8* %t1019, i8** %t1023
  %t1024 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1016, i32 0, i32 1
  store i64 %t1011, i64* %t1024
  %t1025 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1016, i32 0, i32 2
  store i64 %t1013, i64* %t1025
  call void @star_rc_release(i8* %t995)
  store i8* %t1015, i8** %t11
  br label %list_cow_done_465
list_cow_done_465:
  %t1026 = load i8*, i8** %t11
  %t1027 = bitcast i8* %t1026 to { i8*, i64, i64 }*
  %t1028 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1027, i32 0, i32 0
  %t1029 = load i8*, i8** %t1028
  %t1030 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1027, i32 0, i32 1
  %t1031 = load i64, i64* %t1030
  %t1032 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1027, i32 0, i32 2
  %t1033 = trunc i32 97 to i8
  %t1034 = load i64, i64* %t1032
  %t1035 = load i8*, i8** %t1028
  %t1036 = load i64, i64* %t1030
  %t1037 = icmp sge i64 %t1036, %t1034
  br i1 %t1037, label %list_push_grow_469, label %list_push_store_470
list_push_grow_469:
  %t1038 = mul i64 %t1034, 2
  %t1039 = icmp sgt i64 %t1038, 0
  %t1040 = select i1 %t1039, i64 %t1038, i64 1
  %t1041 = getelementptr i8, i8* null, i32 1
  %t1042 = ptrtoint i8* %t1041 to i64
  %t1043 = mul i64 %t1040, %t1042
  %t1044 = call i8* @malloc(i64 %t1043)
  %t1045 = bitcast i8* %t1044 to i8*
  %t1046 = icmp sgt i64 %t1034, 0
  br i1 %t1046, label %list_push_copy_471, label %list_push_after_copy_472
list_push_copy_471:
  %t1047 = mul i64 %t1036, %t1042
  %t1048 = bitcast i8* %t1035 to i8*
  call i8* @memcpy(i8* %t1044, i8* %t1048, i64 %t1047)
  call void @free(i8* %t1048)
  br label %list_push_after_copy_472
list_push_after_copy_472:
  store i8* %t1045, i8** %t1028
  store i64 %t1040, i64* %t1032
  br label %list_push_store_470
list_push_store_470:
  %t1049 = load i8*, i8** %t1028
  %t1050 = getelementptr inbounds i8, i8* %t1049, i64 %t1036
  store i8 %t1033, i8* %t1050
  %t1051 = add i64 %t1036, 1
  store i64 %t1051, i64* %t1030
  %t1052 = load i8*, i8** %t11
  %t1053 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t1053)
  %t1054 = load i32, i32* %t248
  %t1055 = and i32 %t1054, 65535
  %t1056 = call i8* @audio__push_i16(i8* %t1052, i32 %t1055)
  %t1057 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t1057)
  store i8* %t1056, i8** %t11
  %t1058 = load i8*, i8** %t11
  %t1059 = load i8*, i8** %t11
  call void @star_rc_retain(i8* %t1059)
  %t1060 = load i32, i32* %t248
  %t1061 = and i32 16, 31
  %t1062 = ashr i32 %t1060, %t1061
  %t1063 = and i32 %t1062, 65535
  %t1064 = call i8* @audio__push_i16(i8* %t1058, i32 %t1063)
  %t1065 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t1065)
  store i8* %t1064, i8** %t11
  %t1066 = load i8*, i8** %t2
  %t1067 = icmp eq i8* %t1066, null
  br i1 %t1067, label %file_null_handle_473, label %file_handle_ok_474
file_null_handle_473:
  %t1068 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.11, i64 0, i64 0
  call i32 @puts(i8* %t1068)
  call void @exit(i32 1)
  unreachable
file_handle_ok_474:
  %t1069 = load i8*, i8** %t11
  %t1070 = icmp eq i8* %t1069, null
  br i1 %t1070, label %list_read_null_475, label %list_read_real_476
list_read_null_475:
  br label %list_read_end_477
list_read_real_476:
  %t1071 = bitcast i8* %t1069 to { i8*, i64, i64 }*
  %t1072 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1071, i32 0, i32 0
  %t1073 = load i8*, i8** %t1072
  %t1074 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1071, i32 0, i32 1
  %t1075 = load i64, i64* %t1074
  br label %list_read_end_477
list_read_end_477:
  %t1076 = phi i8* [ null, %list_read_null_475 ], [ %t1073, %list_read_real_476 ]
  %t1077 = phi i64 [ 0, %list_read_null_475 ], [ %t1075, %list_read_real_476 ]
  %t1078 = call i64 @fwrite(i8* %t1076, i64 1, i64 %t1077, i8* %t1066)
  %t1079 = icmp eq i64 %t1078, %t1077
  %t1080 = load i8*, i8** %t2
  %t1081 = icmp eq i8* %t1080, null
  br i1 %t1081, label %file_null_handle_478, label %file_handle_ok_479
file_null_handle_478:
  %t1082 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.12, i64 0, i64 0
  call i32 @puts(i8* %t1082)
  call void @exit(i32 1)
  unreachable
file_handle_ok_479:
  %t1083 = load i8*, i8** %t1
  %t1084 = icmp eq i8* %t1083, null
  br i1 %t1084, label %list_read_null_480, label %list_read_real_481
list_read_null_480:
  br label %list_read_end_482
list_read_real_481:
  %t1085 = bitcast i8* %t1083 to { i8*, i64, i64 }*
  %t1086 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1085, i32 0, i32 0
  %t1087 = load i8*, i8** %t1086
  %t1088 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t1085, i32 0, i32 1
  %t1089 = load i64, i64* %t1088
  br label %list_read_end_482
list_read_end_482:
  %t1090 = phi i8* [ null, %list_read_null_480 ], [ %t1087, %list_read_real_481 ]
  %t1091 = phi i64 [ 0, %list_read_null_480 ], [ %t1089, %list_read_real_481 ]
  %t1092 = call i64 @fwrite(i8* %t1090, i64 1, i64 %t1091, i8* %t1080)
  %t1093 = icmp eq i64 %t1092, %t1091
  %t1094 = load i8*, i8** %t2
  %t1095 = icmp eq i8* %t1094, null
  br i1 %t1095, label %file_null_handle_483, label %file_handle_ok_484
file_null_handle_483:
  %t1096 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t1096)
  call void @exit(i32 1)
  unreachable
file_handle_ok_484:
  call i32 @fclose(i8* %t1094)
  store i8* null, i8** %t2
  %t1097 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t1097)
  %t1098 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t1098)
  %t1099 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t1099)
  ret void
}

define i8* @audio__synth_zap() {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t9 = alloca i32
  %t13 = alloca float
  %t19 = alloca float
  %t23 = alloca float
  %t30 = alloca float
  %t42 = alloca float
  %t46 = alloca i32
  store i8* null, i8** %t0
  %t2 = icmp eq i32 8, 0
  %t3 = icmp eq i32 44100, -2147483648
  %t4 = icmp eq i32 8, -1
  %t5 = and i1 %t3, %t4
  %t6 = or i1 %t2, %t5
  br i1 %t6, label %int_div_fail_485, label %int_div_ok_486
int_div_fail_485:
  %t7 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.14, i64 0, i64 0
  call i32 @puts(i8* %t7)
  call void @exit(i32 1)
  unreachable
int_div_ok_486:
  %t8 = sdiv i32 44100, 8
  store i32 %t8, i32* %t1
  store i32 0, i32* %t9
  br label %while_cond_487
while_cond_487:
  %t10 = load i32, i32* %t9
  %t11 = load i32, i32* %t1
  %t12 = icmp slt i32 %t10, %t11
  br i1 %t12, label %while_body_488, label %while_else_489
while_body_488:
  %t14 = load i32, i32* %t9
  %t15 = sitofp i32 %t14 to float
  %t16 = load i32, i32* %t1
  %t17 = sitofp i32 %t16 to float
  %t18 = fdiv float %t15, %t17
  store float %t18, float* %t13
  %t20 = load float, float* %t13
  %t21 = fmul float %t20, 0x408C200000000000
  %t22 = fsub float 0x4092C00000000000, %t21
  store float %t22, float* %t19
  %t24 = load i32, i32* %t9
  %t25 = sitofp i32 %t24 to float
  %t26 = load float, float* %t19
  %t27 = fmul float %t25, %t26
  %t28 = sitofp i32 44100 to float
  %t29 = fdiv float %t27, %t28
  store float %t29, float* %t23
  store float 0x0000000000000000, float* %t30
  %t31 = load float, float* %t23
  %t32 = call i32 @llvm.fptosi.sat.i32.f32(float %t31)
  %t33 = icmp eq i32 2, 0
  %t34 = icmp eq i32 %t32, -2147483648
  %t35 = icmp eq i32 2, -1
  %t36 = and i1 %t34, %t35
  %t37 = or i1 %t33, %t36
  br i1 %t37, label %int_div_fail_491, label %int_div_ok_492
int_div_fail_491:
  %t38 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.15, i64 0, i64 0
  call i32 @puts(i8* %t38)
  call void @exit(i32 1)
  unreachable
int_div_ok_492:
  %t39 = srem i32 %t32, 2
  %t40 = icmp eq i32 %t39, 0
  br i1 %t40, label %if_then_493, label %if_else_494
if_then_493:
  store float 0x3FE0000000000000, float* %t30
  br label %if_end_495
if_else_494:
  %t41 = fsub float 0.0, 0x3FE0000000000000
  store float %t41, float* %t30
  br label %if_end_495
if_end_495:
  %t43 = load float, float* %t13
  %t44 = fsub float 0x3FF0000000000000, %t43
  %t45 = fmul float 0x3FD99999A0000000, %t44
  store float %t45, float* %t42
  %t47 = load float, float* %t30
  %t48 = load float, float* %t42
  %t49 = fmul float %t47, %t48
  %t50 = fmul float %t49, 0x40DFFFC000000000
  %t51 = call i32 @llvm.fptosi.sat.i32.f32(float %t50)
  store i32 %t51, i32* %t46
  %t52 = load i8*, i8** %t0
  %t53 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t53)
  %t54 = load i32, i32* %t46
  %t55 = call i8* @audio__push_i16(i8* %t52, i32 %t54)
  %t56 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t56)
  store i8* %t55, i8** %t0
  %t57 = load i8*, i8** %t0
  %t58 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t58)
  %t59 = load i32, i32* %t46
  %t60 = call i8* @audio__push_i16(i8* %t57, i32 %t59)
  %t61 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t61)
  store i8* %t60, i8** %t0
  %t62 = load i32, i32* %t9
  %t63 = add i32 %t62, 1
  store i32 %t63, i32* %t9
  br label %while_cond_487
while_else_489:
  br label %while_end_490
while_end_490:
  %t64 = load i8*, i8** %t0
  %t65 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t65)
  %t66 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t66)
  ret i8* %t64
}

define i8* @audio__synth_growl() {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t9 = alloca i32
  %t13 = alloca float
  %t19 = alloca float
  %t25 = alloca float
  %t31 = alloca float
  %t35 = alloca float
  %t39 = alloca i32
  store i8* null, i8** %t0
  %t2 = icmp eq i32 5, 0
  %t3 = icmp eq i32 44100, -2147483648
  %t4 = icmp eq i32 5, -1
  %t5 = and i1 %t3, %t4
  %t6 = or i1 %t2, %t5
  br i1 %t6, label %int_div_fail_496, label %int_div_ok_497
int_div_fail_496:
  %t7 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.16, i64 0, i64 0
  call i32 @puts(i8* %t7)
  call void @exit(i32 1)
  unreachable
int_div_ok_497:
  %t8 = sdiv i32 44100, 5
  store i32 %t8, i32* %t1
  store i32 0, i32* %t9
  br label %while_cond_498
while_cond_498:
  %t10 = load i32, i32* %t9
  %t11 = load i32, i32* %t1
  %t12 = icmp slt i32 %t10, %t11
  br i1 %t12, label %while_body_499, label %while_else_500
while_body_499:
  %t14 = load i32, i32* %t9
  %t15 = sitofp i32 %t14 to float
  %t16 = load i32, i32* %t1
  %t17 = sitofp i32 %t16 to float
  %t18 = fdiv float %t15, %t17
  store float %t18, float* %t13
  %t20 = load i32, i32* %t9
  %t21 = sitofp i32 %t20 to float
  %t22 = fmul float %t21, 0x4056800000000000
  %t23 = sitofp i32 44100 to float
  %t24 = fdiv float %t22, %t23
  store float %t24, float* %t19
  %t26 = load float, float* %t19
  %t27 = load float, float* %t19
  %t28 = call i32 @llvm.fptosi.sat.i32.f32(float %t27)
  %t29 = sitofp i32 %t28 to float
  %t30 = fsub float %t26, %t29
  store float %t30, float* %t25
  %t32 = load float, float* %t25
  %t33 = fmul float %t32, 0x4000000000000000
  %t34 = fsub float %t33, 0x3FF0000000000000
  store float %t34, float* %t31
  %t36 = load float, float* %t13
  %t37 = fsub float 0x3FF0000000000000, %t36
  %t38 = fmul float 0x3FE0000000000000, %t37
  store float %t38, float* %t35
  %t40 = load float, float* %t31
  %t41 = load float, float* %t35
  %t42 = fmul float %t40, %t41
  %t43 = fmul float %t42, 0x40DFFFC000000000
  %t44 = call i32 @llvm.fptosi.sat.i32.f32(float %t43)
  store i32 %t44, i32* %t39
  %t45 = load i8*, i8** %t0
  %t46 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t46)
  %t47 = load i32, i32* %t39
  %t48 = call i8* @audio__push_i16(i8* %t45, i32 %t47)
  %t49 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t49)
  store i8* %t48, i8** %t0
  %t50 = load i8*, i8** %t0
  %t51 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t51)
  %t52 = load i32, i32* %t39
  %t53 = call i8* @audio__push_i16(i8* %t50, i32 %t52)
  %t54 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t54)
  store i8* %t53, i8** %t0
  %t55 = load i32, i32* %t9
  %t56 = add i32 %t55, 1
  store i32 %t56, i32* %t9
  br label %while_cond_498
while_else_500:
  br label %while_end_501
while_end_501:
  %t57 = load i8*, i8** %t0
  %t58 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t58)
  %t59 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t59)
  ret i8* %t57
}

define i8* @audio__synth_pickup() {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t9 = alloca i32
  %t13 = alloca float
  %t19 = alloca float
  %t23 = alloca float
  %t30 = alloca float
  %t34 = alloca float
  %t38 = alloca i32
  store i8* null, i8** %t0
  %t2 = icmp eq i32 7, 0
  %t3 = icmp eq i32 44100, -2147483648
  %t4 = icmp eq i32 7, -1
  %t5 = and i1 %t3, %t4
  %t6 = or i1 %t2, %t5
  br i1 %t6, label %int_div_fail_502, label %int_div_ok_503
int_div_fail_502:
  %t7 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.17, i64 0, i64 0
  call i32 @puts(i8* %t7)
  call void @exit(i32 1)
  unreachable
int_div_ok_503:
  %t8 = sdiv i32 44100, 7
  store i32 %t8, i32* %t1
  store i32 0, i32* %t9
  br label %while_cond_504
while_cond_504:
  %t10 = load i32, i32* %t9
  %t11 = load i32, i32* %t1
  %t12 = icmp slt i32 %t10, %t11
  br i1 %t12, label %while_body_505, label %while_else_506
while_body_505:
  %t14 = load i32, i32* %t9
  %t15 = sitofp i32 %t14 to float
  %t16 = load i32, i32* %t1
  %t17 = sitofp i32 %t16 to float
  %t18 = fdiv float %t15, %t17
  store float %t18, float* %t13
  %t20 = load float, float* %t13
  %t21 = fcmp olt float %t20, 0x3FE0000000000000
  br i1 %t21, label %if_then_508, label %if_else_509
if_then_508:
  br label %if_end_510
if_else_509:
  br label %if_end_510
if_end_510:
  %t22 = phi float [ 0x408B800000000000, %if_then_508 ], [ 0x4094A00000000000, %if_else_509 ]
  store float %t22, float* %t19
  %t24 = load i32, i32* %t9
  %t25 = sitofp i32 %t24 to float
  %t26 = load float, float* %t19
  %t27 = fmul float %t25, %t26
  %t28 = sitofp i32 44100 to float
  %t29 = fdiv float %t27, %t28
  store float %t29, float* %t23
  %t31 = load float, float* %t23
  %t32 = fmul float %t31, 0x401921FB60000000
  %t33 = call float @llvm.sin.f32(float %t32)
  store float %t33, float* %t30
  %t35 = load float, float* %t13
  %t36 = fsub float 0x3FF0000000000000, %t35
  %t37 = fmul float 0x3FD6666660000000, %t36
  store float %t37, float* %t34
  %t39 = load float, float* %t30
  %t40 = load float, float* %t34
  %t41 = fmul float %t39, %t40
  %t42 = fmul float %t41, 0x40DFFFC000000000
  %t43 = call i32 @llvm.fptosi.sat.i32.f32(float %t42)
  store i32 %t43, i32* %t38
  %t44 = load i8*, i8** %t0
  %t45 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t45)
  %t46 = load i32, i32* %t38
  %t47 = call i8* @audio__push_i16(i8* %t44, i32 %t46)
  %t48 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t48)
  store i8* %t47, i8** %t0
  %t49 = load i8*, i8** %t0
  %t50 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t50)
  %t51 = load i32, i32* %t38
  %t52 = call i8* @audio__push_i16(i8* %t49, i32 %t51)
  %t53 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t53)
  store i8* %t52, i8** %t0
  %t54 = load i32, i32* %t9
  %t55 = add i32 %t54, 1
  store i32 %t55, i32* %t9
  br label %while_cond_504
while_else_506:
  br label %while_end_507
while_end_507:
  %t56 = load i8*, i8** %t0
  %t57 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t57)
  %t58 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t58)
  ret i8* %t56
}

define i8* @audio__synth_drone() {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t3 = alloca i32
  %t7 = alloca float
  %t13 = alloca float
  %t19 = alloca float
  %t23 = alloca float
  %t29 = alloca float
  %t32 = alloca i32
  store i8* null, i8** %t0
  %t2 = mul i32 44100, 2
  store i32 %t2, i32* %t1
  store i32 0, i32* %t3
  br label %while_cond_511
while_cond_511:
  %t4 = load i32, i32* %t3
  %t5 = load i32, i32* %t1
  %t6 = icmp slt i32 %t4, %t5
  br i1 %t6, label %while_body_512, label %while_else_513
while_body_512:
  %t8 = load i32, i32* %t3
  %t9 = sitofp i32 %t8 to float
  %t10 = load i32, i32* %t1
  %t11 = sitofp i32 %t10 to float
  %t12 = fdiv float %t9, %t11
  store float %t12, float* %t7
  %t14 = load i32, i32* %t3
  %t15 = sitofp i32 %t14 to float
  %t16 = fmul float %t15, 0x404B800000000000
  %t17 = sitofp i32 44100 to float
  %t18 = fdiv float %t16, %t17
  store float %t18, float* %t13
  %t20 = load float, float* %t13
  %t21 = fmul float %t20, 0x401921FB60000000
  %t22 = call float @llvm.sin.f32(float %t21)
  store float %t22, float* %t19
  %t24 = load float, float* %t7
  %t25 = fmul float %t24, 0x400921FB60000000
  %t26 = call float @llvm.sin.f32(float %t25)
  %t27 = fmul float 0x3FE0000000000000, %t26
  %t28 = fadd float 0x3FE0000000000000, %t27
  store float %t28, float* %t23
  %t30 = load float, float* %t23
  %t31 = fmul float 0x3FD0000000000000, %t30
  store float %t31, float* %t29
  %t33 = load float, float* %t19
  %t34 = load float, float* %t29
  %t35 = fmul float %t33, %t34
  %t36 = fmul float %t35, 0x40DFFFC000000000
  %t37 = call i32 @llvm.fptosi.sat.i32.f32(float %t36)
  store i32 %t37, i32* %t32
  %t38 = load i8*, i8** %t0
  %t39 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t39)
  %t40 = load i32, i32* %t32
  %t41 = call i8* @audio__push_i16(i8* %t38, i32 %t40)
  %t42 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t42)
  store i8* %t41, i8** %t0
  %t43 = load i8*, i8** %t0
  %t44 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t44)
  %t45 = load i32, i32* %t32
  %t46 = call i8* @audio__push_i16(i8* %t43, i32 %t45)
  %t47 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t47)
  store i8* %t46, i8** %t0
  %t48 = load i32, i32* %t3
  %t49 = add i32 %t48, 1
  store i32 %t49, i32* %t3
  br label %while_cond_511
while_else_513:
  br label %while_end_514
while_end_514:
  %t50 = load i8*, i8** %t0
  %t51 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t51)
  %t52 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t52)
  ret i8* %t50
}

define %audio__Sounds @audio__make_sounds() {
entry:
  %t8 = alloca %audio__Sounds
  %t0 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.18, i64 0, i32 2, i64 0
  %t1 = call i8* @audio__synth_zap()
  call void @audio__write_wav(i8* %t0, i8* %t1)
  %t2 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.19, i64 0, i32 2, i64 0
  %t3 = call i8* @audio__synth_growl()
  call void @audio__write_wav(i8* %t2, i8* %t3)
  %t4 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t5 = call i8* @audio__synth_pickup()
  call void @audio__write_wav(i8* %t4, i8* %t5)
  %t6 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t7 = call i8* @audio__synth_drone()
  call void @audio__write_wav(i8* %t6, i8* %t7)
  %t9 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t8, i32 0, i32 0
  %t10 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.22, i64 0, i32 2, i64 0
  %t11 = getelementptr inbounds [3 x i8], [3 x i8]* @.str.23, i64 0, i64 0
  %t12 = call i8* @fopen(i8* %t10, i8* %t11)
  call void @star_rc_release(i8* %t10)
  %t13 = icmp eq i8* %t12, null
  br i1 %t13, label %sound_load_open_fail_515, label %sound_load_open_ok_516
sound_load_open_fail_515:
  br label %sound_load_end_517
sound_load_open_ok_516:
  call i32 @fseek(i8* %t12, i32 0, i32 2)
  %t14 = call i32 @ftell(i8* %t12)
  call i32 @fseek(i8* %t12, i32 0, i32 0)
  %t15 = icmp sge i32 %t14, 44
  br i1 %t15, label %sound_load_read_519, label %sound_load_too_small_518
sound_load_too_small_518:
  call i32 @fclose(i8* %t12)
  br label %sound_load_end_517
sound_load_read_519:
  %t16 = sext i32 %t14 to i64
  %t17 = call i8* @malloc(i64 %t16)
  %t18 = call i64 @fread(i8* %t17, i64 1, i64 %t16, i8* %t12)
  call i32 @fclose(i8* %t12)
  %t19 = icmp eq i64 %t18, %t16
  br i1 %t19, label %sound_load_validate_521, label %sound_load_short_read_520
sound_load_short_read_520:
  call void @free(i8* %t17)
  br label %sound_load_end_517
sound_load_validate_521:
  %t20 = getelementptr inbounds i8, i8* %t17, i64 0
  %t21 = bitcast i8* %t20 to i32*
  %t22 = load i32, i32* %t21
  %t23 = icmp eq i32 %t22, 1179011410
  %t24 = getelementptr inbounds i8, i8* %t17, i64 8
  %t25 = bitcast i8* %t24 to i32*
  %t26 = load i32, i32* %t25
  %t27 = icmp eq i32 %t26, 1163280727
  %t28 = getelementptr inbounds i8, i8* %t17, i64 12
  %t29 = bitcast i8* %t28 to i32*
  %t30 = load i32, i32* %t29
  %t31 = icmp eq i32 %t30, 544501094
  %t32 = getelementptr inbounds i8, i8* %t17, i64 16
  %t33 = bitcast i8* %t32 to i32*
  %t34 = load i32, i32* %t33
  %t35 = icmp eq i32 %t34, 16
  %t36 = getelementptr inbounds i8, i8* %t17, i64 20
  %t37 = bitcast i8* %t36 to i32*
  %t38 = load i32, i32* %t37
  %t39 = icmp eq i32 %t38, 131073
  %t40 = getelementptr inbounds i8, i8* %t17, i64 24
  %t41 = bitcast i8* %t40 to i32*
  %t42 = load i32, i32* %t41
  %t43 = icmp eq i32 %t42, 44100
  %t44 = getelementptr inbounds i8, i8* %t17, i64 34
  %t45 = bitcast i8* %t44 to i16*
  %t46 = load i16, i16* %t45
  %t47 = icmp eq i16 %t46, 16
  %t48 = getelementptr inbounds i8, i8* %t17, i64 36
  %t49 = bitcast i8* %t48 to i32*
  %t50 = load i32, i32* %t49
  %t51 = icmp eq i32 %t50, 1635017060
  %t52 = and i1 %t23, %t27
  %t53 = and i1 %t52, %t31
  %t54 = and i1 %t53, %t35
  %t55 = and i1 %t54, %t39
  %t56 = and i1 %t55, %t43
  %t57 = and i1 %t56, %t47
  %t58 = and i1 %t57, %t51
  br i1 %t58, label %sound_load_valid_523, label %sound_load_invalid_522
sound_load_invalid_522:
  call void @free(i8* %t17)
  br label %sound_load_end_517
sound_load_valid_523:
  %t59 = getelementptr inbounds i8, i8* %t17, i64 40
  %t60 = bitcast i8* %t59 to i32*
  %t61 = load i32, i32* %t60
  %t62 = zext i32 %t61 to i64
  %t63 = call i8* @malloc(i64 16)
  %t64 = bitcast i8* %t63 to i64*
  store i64 %t62, i64* %t64
  %t65 = getelementptr inbounds i8, i8* %t63, i64 8
  %t66 = bitcast i8* %t65 to i8**
  store i8* %t17, i8** %t66
  br label %sound_load_end_517
sound_load_end_517:
  %t67 = phi i8* [ null, %sound_load_open_fail_515 ], [ null, %sound_load_too_small_518 ], [ null, %sound_load_short_read_520 ], [ null, %sound_load_invalid_522 ], [ %t63, %sound_load_valid_523 ]
  store i8* %t67, i8** %t9
  %t68 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t8, i32 0, i32 1
  %t69 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t70 = getelementptr inbounds [3 x i8], [3 x i8]* @.str.25, i64 0, i64 0
  %t71 = call i8* @fopen(i8* %t69, i8* %t70)
  call void @star_rc_release(i8* %t69)
  %t72 = icmp eq i8* %t71, null
  br i1 %t72, label %sound_load_open_fail_524, label %sound_load_open_ok_525
sound_load_open_fail_524:
  br label %sound_load_end_526
sound_load_open_ok_525:
  call i32 @fseek(i8* %t71, i32 0, i32 2)
  %t73 = call i32 @ftell(i8* %t71)
  call i32 @fseek(i8* %t71, i32 0, i32 0)
  %t74 = icmp sge i32 %t73, 44
  br i1 %t74, label %sound_load_read_528, label %sound_load_too_small_527
sound_load_too_small_527:
  call i32 @fclose(i8* %t71)
  br label %sound_load_end_526
sound_load_read_528:
  %t75 = sext i32 %t73 to i64
  %t76 = call i8* @malloc(i64 %t75)
  %t77 = call i64 @fread(i8* %t76, i64 1, i64 %t75, i8* %t71)
  call i32 @fclose(i8* %t71)
  %t78 = icmp eq i64 %t77, %t75
  br i1 %t78, label %sound_load_validate_530, label %sound_load_short_read_529
sound_load_short_read_529:
  call void @free(i8* %t76)
  br label %sound_load_end_526
sound_load_validate_530:
  %t79 = getelementptr inbounds i8, i8* %t76, i64 0
  %t80 = bitcast i8* %t79 to i32*
  %t81 = load i32, i32* %t80
  %t82 = icmp eq i32 %t81, 1179011410
  %t83 = getelementptr inbounds i8, i8* %t76, i64 8
  %t84 = bitcast i8* %t83 to i32*
  %t85 = load i32, i32* %t84
  %t86 = icmp eq i32 %t85, 1163280727
  %t87 = getelementptr inbounds i8, i8* %t76, i64 12
  %t88 = bitcast i8* %t87 to i32*
  %t89 = load i32, i32* %t88
  %t90 = icmp eq i32 %t89, 544501094
  %t91 = getelementptr inbounds i8, i8* %t76, i64 16
  %t92 = bitcast i8* %t91 to i32*
  %t93 = load i32, i32* %t92
  %t94 = icmp eq i32 %t93, 16
  %t95 = getelementptr inbounds i8, i8* %t76, i64 20
  %t96 = bitcast i8* %t95 to i32*
  %t97 = load i32, i32* %t96
  %t98 = icmp eq i32 %t97, 131073
  %t99 = getelementptr inbounds i8, i8* %t76, i64 24
  %t100 = bitcast i8* %t99 to i32*
  %t101 = load i32, i32* %t100
  %t102 = icmp eq i32 %t101, 44100
  %t103 = getelementptr inbounds i8, i8* %t76, i64 34
  %t104 = bitcast i8* %t103 to i16*
  %t105 = load i16, i16* %t104
  %t106 = icmp eq i16 %t105, 16
  %t107 = getelementptr inbounds i8, i8* %t76, i64 36
  %t108 = bitcast i8* %t107 to i32*
  %t109 = load i32, i32* %t108
  %t110 = icmp eq i32 %t109, 1635017060
  %t111 = and i1 %t82, %t86
  %t112 = and i1 %t111, %t90
  %t113 = and i1 %t112, %t94
  %t114 = and i1 %t113, %t98
  %t115 = and i1 %t114, %t102
  %t116 = and i1 %t115, %t106
  %t117 = and i1 %t116, %t110
  br i1 %t117, label %sound_load_valid_532, label %sound_load_invalid_531
sound_load_invalid_531:
  call void @free(i8* %t76)
  br label %sound_load_end_526
sound_load_valid_532:
  %t118 = getelementptr inbounds i8, i8* %t76, i64 40
  %t119 = bitcast i8* %t118 to i32*
  %t120 = load i32, i32* %t119
  %t121 = zext i32 %t120 to i64
  %t122 = call i8* @malloc(i64 16)
  %t123 = bitcast i8* %t122 to i64*
  store i64 %t121, i64* %t123
  %t124 = getelementptr inbounds i8, i8* %t122, i64 8
  %t125 = bitcast i8* %t124 to i8**
  store i8* %t76, i8** %t125
  br label %sound_load_end_526
sound_load_end_526:
  %t126 = phi i8* [ null, %sound_load_open_fail_524 ], [ null, %sound_load_too_small_527 ], [ null, %sound_load_short_read_529 ], [ null, %sound_load_invalid_531 ], [ %t122, %sound_load_valid_532 ]
  store i8* %t126, i8** %t68
  %t127 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t8, i32 0, i32 2
  %t128 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.26, i64 0, i32 2, i64 0
  %t129 = getelementptr inbounds [3 x i8], [3 x i8]* @.str.27, i64 0, i64 0
  %t130 = call i8* @fopen(i8* %t128, i8* %t129)
  call void @star_rc_release(i8* %t128)
  %t131 = icmp eq i8* %t130, null
  br i1 %t131, label %sound_load_open_fail_533, label %sound_load_open_ok_534
sound_load_open_fail_533:
  br label %sound_load_end_535
sound_load_open_ok_534:
  call i32 @fseek(i8* %t130, i32 0, i32 2)
  %t132 = call i32 @ftell(i8* %t130)
  call i32 @fseek(i8* %t130, i32 0, i32 0)
  %t133 = icmp sge i32 %t132, 44
  br i1 %t133, label %sound_load_read_537, label %sound_load_too_small_536
sound_load_too_small_536:
  call i32 @fclose(i8* %t130)
  br label %sound_load_end_535
sound_load_read_537:
  %t134 = sext i32 %t132 to i64
  %t135 = call i8* @malloc(i64 %t134)
  %t136 = call i64 @fread(i8* %t135, i64 1, i64 %t134, i8* %t130)
  call i32 @fclose(i8* %t130)
  %t137 = icmp eq i64 %t136, %t134
  br i1 %t137, label %sound_load_validate_539, label %sound_load_short_read_538
sound_load_short_read_538:
  call void @free(i8* %t135)
  br label %sound_load_end_535
sound_load_validate_539:
  %t138 = getelementptr inbounds i8, i8* %t135, i64 0
  %t139 = bitcast i8* %t138 to i32*
  %t140 = load i32, i32* %t139
  %t141 = icmp eq i32 %t140, 1179011410
  %t142 = getelementptr inbounds i8, i8* %t135, i64 8
  %t143 = bitcast i8* %t142 to i32*
  %t144 = load i32, i32* %t143
  %t145 = icmp eq i32 %t144, 1163280727
  %t146 = getelementptr inbounds i8, i8* %t135, i64 12
  %t147 = bitcast i8* %t146 to i32*
  %t148 = load i32, i32* %t147
  %t149 = icmp eq i32 %t148, 544501094
  %t150 = getelementptr inbounds i8, i8* %t135, i64 16
  %t151 = bitcast i8* %t150 to i32*
  %t152 = load i32, i32* %t151
  %t153 = icmp eq i32 %t152, 16
  %t154 = getelementptr inbounds i8, i8* %t135, i64 20
  %t155 = bitcast i8* %t154 to i32*
  %t156 = load i32, i32* %t155
  %t157 = icmp eq i32 %t156, 131073
  %t158 = getelementptr inbounds i8, i8* %t135, i64 24
  %t159 = bitcast i8* %t158 to i32*
  %t160 = load i32, i32* %t159
  %t161 = icmp eq i32 %t160, 44100
  %t162 = getelementptr inbounds i8, i8* %t135, i64 34
  %t163 = bitcast i8* %t162 to i16*
  %t164 = load i16, i16* %t163
  %t165 = icmp eq i16 %t164, 16
  %t166 = getelementptr inbounds i8, i8* %t135, i64 36
  %t167 = bitcast i8* %t166 to i32*
  %t168 = load i32, i32* %t167
  %t169 = icmp eq i32 %t168, 1635017060
  %t170 = and i1 %t141, %t145
  %t171 = and i1 %t170, %t149
  %t172 = and i1 %t171, %t153
  %t173 = and i1 %t172, %t157
  %t174 = and i1 %t173, %t161
  %t175 = and i1 %t174, %t165
  %t176 = and i1 %t175, %t169
  br i1 %t176, label %sound_load_valid_541, label %sound_load_invalid_540
sound_load_invalid_540:
  call void @free(i8* %t135)
  br label %sound_load_end_535
sound_load_valid_541:
  %t177 = getelementptr inbounds i8, i8* %t135, i64 40
  %t178 = bitcast i8* %t177 to i32*
  %t179 = load i32, i32* %t178
  %t180 = zext i32 %t179 to i64
  %t181 = call i8* @malloc(i64 16)
  %t182 = bitcast i8* %t181 to i64*
  store i64 %t180, i64* %t182
  %t183 = getelementptr inbounds i8, i8* %t181, i64 8
  %t184 = bitcast i8* %t183 to i8**
  store i8* %t135, i8** %t184
  br label %sound_load_end_535
sound_load_end_535:
  %t185 = phi i8* [ null, %sound_load_open_fail_533 ], [ null, %sound_load_too_small_536 ], [ null, %sound_load_short_read_538 ], [ null, %sound_load_invalid_540 ], [ %t181, %sound_load_valid_541 ]
  store i8* %t185, i8** %t127
  %t186 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t8, i32 0, i32 3
  %t187 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.28, i64 0, i32 2, i64 0
  %t188 = getelementptr inbounds [3 x i8], [3 x i8]* @.str.29, i64 0, i64 0
  %t189 = call i8* @fopen(i8* %t187, i8* %t188)
  call void @star_rc_release(i8* %t187)
  %t190 = icmp eq i8* %t189, null
  br i1 %t190, label %sound_load_open_fail_542, label %sound_load_open_ok_543
sound_load_open_fail_542:
  br label %sound_load_end_544
sound_load_open_ok_543:
  call i32 @fseek(i8* %t189, i32 0, i32 2)
  %t191 = call i32 @ftell(i8* %t189)
  call i32 @fseek(i8* %t189, i32 0, i32 0)
  %t192 = icmp sge i32 %t191, 44
  br i1 %t192, label %sound_load_read_546, label %sound_load_too_small_545
sound_load_too_small_545:
  call i32 @fclose(i8* %t189)
  br label %sound_load_end_544
sound_load_read_546:
  %t193 = sext i32 %t191 to i64
  %t194 = call i8* @malloc(i64 %t193)
  %t195 = call i64 @fread(i8* %t194, i64 1, i64 %t193, i8* %t189)
  call i32 @fclose(i8* %t189)
  %t196 = icmp eq i64 %t195, %t193
  br i1 %t196, label %sound_load_validate_548, label %sound_load_short_read_547
sound_load_short_read_547:
  call void @free(i8* %t194)
  br label %sound_load_end_544
sound_load_validate_548:
  %t197 = getelementptr inbounds i8, i8* %t194, i64 0
  %t198 = bitcast i8* %t197 to i32*
  %t199 = load i32, i32* %t198
  %t200 = icmp eq i32 %t199, 1179011410
  %t201 = getelementptr inbounds i8, i8* %t194, i64 8
  %t202 = bitcast i8* %t201 to i32*
  %t203 = load i32, i32* %t202
  %t204 = icmp eq i32 %t203, 1163280727
  %t205 = getelementptr inbounds i8, i8* %t194, i64 12
  %t206 = bitcast i8* %t205 to i32*
  %t207 = load i32, i32* %t206
  %t208 = icmp eq i32 %t207, 544501094
  %t209 = getelementptr inbounds i8, i8* %t194, i64 16
  %t210 = bitcast i8* %t209 to i32*
  %t211 = load i32, i32* %t210
  %t212 = icmp eq i32 %t211, 16
  %t213 = getelementptr inbounds i8, i8* %t194, i64 20
  %t214 = bitcast i8* %t213 to i32*
  %t215 = load i32, i32* %t214
  %t216 = icmp eq i32 %t215, 131073
  %t217 = getelementptr inbounds i8, i8* %t194, i64 24
  %t218 = bitcast i8* %t217 to i32*
  %t219 = load i32, i32* %t218
  %t220 = icmp eq i32 %t219, 44100
  %t221 = getelementptr inbounds i8, i8* %t194, i64 34
  %t222 = bitcast i8* %t221 to i16*
  %t223 = load i16, i16* %t222
  %t224 = icmp eq i16 %t223, 16
  %t225 = getelementptr inbounds i8, i8* %t194, i64 36
  %t226 = bitcast i8* %t225 to i32*
  %t227 = load i32, i32* %t226
  %t228 = icmp eq i32 %t227, 1635017060
  %t229 = and i1 %t200, %t204
  %t230 = and i1 %t229, %t208
  %t231 = and i1 %t230, %t212
  %t232 = and i1 %t231, %t216
  %t233 = and i1 %t232, %t220
  %t234 = and i1 %t233, %t224
  %t235 = and i1 %t234, %t228
  br i1 %t235, label %sound_load_valid_550, label %sound_load_invalid_549
sound_load_invalid_549:
  call void @free(i8* %t194)
  br label %sound_load_end_544
sound_load_valid_550:
  %t236 = getelementptr inbounds i8, i8* %t194, i64 40
  %t237 = bitcast i8* %t236 to i32*
  %t238 = load i32, i32* %t237
  %t239 = zext i32 %t238 to i64
  %t240 = call i8* @malloc(i64 16)
  %t241 = bitcast i8* %t240 to i64*
  store i64 %t239, i64* %t241
  %t242 = getelementptr inbounds i8, i8* %t240, i64 8
  %t243 = bitcast i8* %t242 to i8**
  store i8* %t194, i8** %t243
  br label %sound_load_end_544
sound_load_end_544:
  %t244 = phi i8* [ null, %sound_load_open_fail_542 ], [ null, %sound_load_too_small_545 ], [ null, %sound_load_short_read_547 ], [ null, %sound_load_invalid_549 ], [ %t240, %sound_load_valid_550 ]
  store i8* %t244, i8** %t186
  %t245 = load %audio__Sounds, %audio__Sounds* %t8
  ret %audio__Sounds %t245
}

define i8* @build_enemies(%map__Level %level) {
entry:
  %t0 = alloca %map__Level
  %t1 = alloca i8*
  %t2 = alloca i32
  %t16 = alloca i32
  %t77 = alloca %Enemy
  %t122 = alloca i32
  %t179 = alloca %Enemy
  store %map__Level %level, %map__Level* %t0
  store i8* null, i8** %t1
  store i32 0, i32* %t2
  br label %while_cond_551
while_cond_551:
  %t3 = load i32, i32* %t2
  %t4 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 1
  %t5 = load i8*, i8** %t4
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %list_read_null_555, label %list_read_real_556
list_read_null_555:
  br label %list_read_end_557
list_read_real_556:
  %t7 = bitcast i8* %t5 to { i32*, i64, i64 }*
  %t8 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t7, i32 0, i32 0
  %t9 = load i32*, i32** %t8
  %t10 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t7, i32 0, i32 1
  %t11 = load i64, i64* %t10
  br label %list_read_end_557
list_read_end_557:
  %t12 = phi i32* [ null, %list_read_null_555 ], [ %t9, %list_read_real_556 ]
  %t13 = phi i64 [ 0, %list_read_null_555 ], [ %t11, %list_read_real_556 ]
  %t14 = trunc i64 %t13 to i32
  %t15 = icmp slt i32 %t3, %t14
  br i1 %t15, label %while_body_552, label %while_else_553
while_body_552:
  %t17 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 1
  %t18 = load i8*, i8** %t17
  %t19 = icmp eq i8* %t18, null
  br i1 %t19, label %list_read_null_558, label %list_read_real_559
list_read_null_558:
  br label %list_read_end_560
list_read_real_559:
  %t20 = bitcast i8* %t18 to { i32*, i64, i64 }*
  %t21 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t20, i32 0, i32 0
  %t22 = load i32*, i32** %t21
  %t23 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t20, i32 0, i32 1
  %t24 = load i64, i64* %t23
  br label %list_read_end_560
list_read_end_560:
  %t25 = phi i32* [ null, %list_read_null_558 ], [ %t22, %list_read_real_559 ]
  %t26 = phi i64 [ 0, %list_read_null_558 ], [ %t24, %list_read_real_559 ]
  %t27 = load i32, i32* %t2
  %t28 = sext i32 %t27 to i64
  %t29 = icmp ult i64 %t28, %t26
  br i1 %t29, label %list_idx_ok_561, label %list_idx_oob_562
list_idx_ok_561:
  %t30 = getelementptr inbounds i32, i32* %t25, i64 %t28
  %t31 = load i32, i32* %t30
  br label %list_idx_end_563
list_idx_oob_562:
  br label %list_idx_end_563
list_idx_end_563:
  %t32 = phi i32 [ %t31, %list_idx_ok_561 ], [ 0, %list_idx_oob_562 ]
  store i32 %t32, i32* %t16
  %t33 = getelementptr %Enemy, %Enemy* null, i32 1
  %t34 = ptrtoint %Enemy* %t33 to i64
  %t35 = load i8*, i8** %t1
  %t36 = icmp eq i8* %t35, null
  br i1 %t36, label %list_cow_alloc_564, label %list_cow_check_565
list_cow_alloc_564:
  %t41 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t42 = call i8* @star_rc_alloc(i64 24, i8* %t41)
  %t43 = bitcast i8* %t42 to { %Enemy*, i64, i64 }*
  %t44 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t43, i32 0, i32 0
  store %Enemy* null, %Enemy** %t44
  %t45 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t43, i32 0, i32 1
  store i64 0, i64* %t45
  %t46 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t43, i32 0, i32 2
  store i64 0, i64* %t46
  store i8* %t42, i8** %t1
  br label %list_cow_done_566
list_cow_check_565:
  %t47 = getelementptr inbounds i8, i8* %t35, i64 -16
  %t48 = bitcast i8* %t47 to i64*
  %t49 = load atomic i64, i64* %t48 seq_cst, align 8
  %t50 = icmp eq i64 %t49, 1
  br i1 %t50, label %list_cow_done_566, label %list_cow_clone_567
list_cow_clone_567:
  %t51 = bitcast i8* %t35 to { %Enemy*, i64, i64 }*
  %t52 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t51, i32 0, i32 0
  %t53 = load %Enemy*, %Enemy** %t52
  %t54 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t51, i32 0, i32 1
  %t55 = load i64, i64* %t54
  %t56 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t51, i32 0, i32 2
  %t57 = load i64, i64* %t56
  %t58 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t59 = call i8* @star_rc_alloc(i64 24, i8* %t58)
  %t60 = bitcast i8* %t59 to { %Enemy*, i64, i64 }*
  %t61 = mul i64 %t57, %t34
  %t62 = call i8* @malloc(i64 %t61)
  %t63 = bitcast i8* %t62 to %Enemy*
  %t64 = icmp sgt i64 %t55, 0
  br i1 %t64, label %list_cow_copy_568, label %list_cow_after_copy_569
list_cow_copy_568:
  %t65 = mul i64 %t55, %t34
  %t66 = bitcast %Enemy* %t53 to i8*
  call i8* @memcpy(i8* %t62, i8* %t66, i64 %t65)
  br label %list_cow_after_copy_569
list_cow_after_copy_569:
  %t67 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t60, i32 0, i32 0
  store %Enemy* %t63, %Enemy** %t67
  %t68 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t60, i32 0, i32 1
  store i64 %t55, i64* %t68
  %t69 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t60, i32 0, i32 2
  store i64 %t57, i64* %t69
  call void @star_rc_release(i8* %t35)
  store i8* %t59, i8** %t1
  br label %list_cow_done_566
list_cow_done_566:
  %t70 = load i8*, i8** %t1
  %t71 = bitcast i8* %t70 to { %Enemy*, i64, i64 }*
  %t72 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t71, i32 0, i32 0
  %t73 = load %Enemy*, %Enemy** %t72
  %t74 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t71, i32 0, i32 1
  %t75 = load i64, i64* %t74
  %t76 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t71, i32 0, i32 2
  %t78 = getelementptr inbounds %Enemy, %Enemy* %t77, i32 0, i32 0
  %t79 = load i32, i32* %t16
  %t80 = call float @map__cell_center_x(i32 %t79)
  store float %t80, float* %t78
  %t81 = getelementptr inbounds %Enemy, %Enemy* %t77, i32 0, i32 1
  %t82 = load i32, i32* %t16
  %t83 = call float @map__cell_center_y(i32 %t82)
  store float %t83, float* %t81
  %t84 = getelementptr inbounds %Enemy, %Enemy* %t77, i32 0, i32 2
  store float 0x403E000000000000, float* %t84
  %t85 = getelementptr inbounds %Enemy, %Enemy* %t77, i32 0, i32 3
  store i32 0, i32* %t85
  %t86 = getelementptr inbounds %Enemy, %Enemy* %t77, i32 0, i32 4
  store i1 true, i1* %t86
  %t87 = getelementptr inbounds %Enemy, %Enemy* %t77, i32 0, i32 5
  store float 0x0000000000000000, float* %t87
  %t88 = load %Enemy, %Enemy* %t77
  %t89 = load i64, i64* %t76
  %t90 = load %Enemy*, %Enemy** %t72
  %t91 = load i64, i64* %t74
  %t92 = icmp sge i64 %t91, %t89
  br i1 %t92, label %list_push_grow_570, label %list_push_store_571
list_push_grow_570:
  %t93 = mul i64 %t89, 2
  %t94 = icmp sgt i64 %t93, 0
  %t95 = select i1 %t94, i64 %t93, i64 1
  %t96 = getelementptr %Enemy, %Enemy* null, i32 1
  %t97 = ptrtoint %Enemy* %t96 to i64
  %t98 = mul i64 %t95, %t97
  %t99 = call i8* @malloc(i64 %t98)
  %t100 = bitcast i8* %t99 to %Enemy*
  %t101 = icmp sgt i64 %t89, 0
  br i1 %t101, label %list_push_copy_572, label %list_push_after_copy_573
list_push_copy_572:
  %t102 = mul i64 %t91, %t97
  %t103 = bitcast %Enemy* %t90 to i8*
  call i8* @memcpy(i8* %t99, i8* %t103, i64 %t102)
  call void @free(i8* %t103)
  br label %list_push_after_copy_573
list_push_after_copy_573:
  store %Enemy* %t100, %Enemy** %t72
  store i64 %t95, i64* %t76
  br label %list_push_store_571
list_push_store_571:
  %t104 = load %Enemy*, %Enemy** %t72
  %t105 = getelementptr inbounds %Enemy, %Enemy* %t104, i64 %t91
  store %Enemy %t88, %Enemy* %t105
  %t106 = add i64 %t91, 1
  store i64 %t106, i64* %t74
  %t107 = load i32, i32* %t2
  %t108 = add i32 %t107, 1
  store i32 %t108, i32* %t2
  br label %while_cond_551
while_else_553:
  br label %while_end_554
while_end_554:
  store i32 0, i32* %t2
  br label %while_cond_574
while_cond_574:
  %t109 = load i32, i32* %t2
  %t110 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 2
  %t111 = load i8*, i8** %t110
  %t112 = icmp eq i8* %t111, null
  br i1 %t112, label %list_read_null_578, label %list_read_real_579
list_read_null_578:
  br label %list_read_end_580
list_read_real_579:
  %t113 = bitcast i8* %t111 to { i32*, i64, i64 }*
  %t114 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t113, i32 0, i32 0
  %t115 = load i32*, i32** %t114
  %t116 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t113, i32 0, i32 1
  %t117 = load i64, i64* %t116
  br label %list_read_end_580
list_read_end_580:
  %t118 = phi i32* [ null, %list_read_null_578 ], [ %t115, %list_read_real_579 ]
  %t119 = phi i64 [ 0, %list_read_null_578 ], [ %t117, %list_read_real_579 ]
  %t120 = trunc i64 %t119 to i32
  %t121 = icmp slt i32 %t109, %t120
  br i1 %t121, label %while_body_575, label %while_else_576
while_body_575:
  %t123 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 2
  %t124 = load i8*, i8** %t123
  %t125 = icmp eq i8* %t124, null
  br i1 %t125, label %list_read_null_581, label %list_read_real_582
list_read_null_581:
  br label %list_read_end_583
list_read_real_582:
  %t126 = bitcast i8* %t124 to { i32*, i64, i64 }*
  %t127 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t126, i32 0, i32 0
  %t128 = load i32*, i32** %t127
  %t129 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t126, i32 0, i32 1
  %t130 = load i64, i64* %t129
  br label %list_read_end_583
list_read_end_583:
  %t131 = phi i32* [ null, %list_read_null_581 ], [ %t128, %list_read_real_582 ]
  %t132 = phi i64 [ 0, %list_read_null_581 ], [ %t130, %list_read_real_582 ]
  %t133 = load i32, i32* %t2
  %t134 = sext i32 %t133 to i64
  %t135 = icmp ult i64 %t134, %t132
  br i1 %t135, label %list_idx_ok_584, label %list_idx_oob_585
list_idx_ok_584:
  %t136 = getelementptr inbounds i32, i32* %t131, i64 %t134
  %t137 = load i32, i32* %t136
  br label %list_idx_end_586
list_idx_oob_585:
  br label %list_idx_end_586
list_idx_end_586:
  %t138 = phi i32 [ %t137, %list_idx_ok_584 ], [ 0, %list_idx_oob_585 ]
  store i32 %t138, i32* %t122
  %t139 = getelementptr %Enemy, %Enemy* null, i32 1
  %t140 = ptrtoint %Enemy* %t139 to i64
  %t141 = load i8*, i8** %t1
  %t142 = icmp eq i8* %t141, null
  br i1 %t142, label %list_cow_alloc_587, label %list_cow_check_588
list_cow_alloc_587:
  %t143 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t144 = call i8* @star_rc_alloc(i64 24, i8* %t143)
  %t145 = bitcast i8* %t144 to { %Enemy*, i64, i64 }*
  %t146 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t145, i32 0, i32 0
  store %Enemy* null, %Enemy** %t146
  %t147 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t145, i32 0, i32 1
  store i64 0, i64* %t147
  %t148 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t145, i32 0, i32 2
  store i64 0, i64* %t148
  store i8* %t144, i8** %t1
  br label %list_cow_done_589
list_cow_check_588:
  %t149 = getelementptr inbounds i8, i8* %t141, i64 -16
  %t150 = bitcast i8* %t149 to i64*
  %t151 = load atomic i64, i64* %t150 seq_cst, align 8
  %t152 = icmp eq i64 %t151, 1
  br i1 %t152, label %list_cow_done_589, label %list_cow_clone_590
list_cow_clone_590:
  %t153 = bitcast i8* %t141 to { %Enemy*, i64, i64 }*
  %t154 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t153, i32 0, i32 0
  %t155 = load %Enemy*, %Enemy** %t154
  %t156 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t153, i32 0, i32 1
  %t157 = load i64, i64* %t156
  %t158 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t153, i32 0, i32 2
  %t159 = load i64, i64* %t158
  %t160 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t161 = call i8* @star_rc_alloc(i64 24, i8* %t160)
  %t162 = bitcast i8* %t161 to { %Enemy*, i64, i64 }*
  %t163 = mul i64 %t159, %t140
  %t164 = call i8* @malloc(i64 %t163)
  %t165 = bitcast i8* %t164 to %Enemy*
  %t166 = icmp sgt i64 %t157, 0
  br i1 %t166, label %list_cow_copy_591, label %list_cow_after_copy_592
list_cow_copy_591:
  %t167 = mul i64 %t157, %t140
  %t168 = bitcast %Enemy* %t155 to i8*
  call i8* @memcpy(i8* %t164, i8* %t168, i64 %t167)
  br label %list_cow_after_copy_592
list_cow_after_copy_592:
  %t169 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t162, i32 0, i32 0
  store %Enemy* %t165, %Enemy** %t169
  %t170 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t162, i32 0, i32 1
  store i64 %t157, i64* %t170
  %t171 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t162, i32 0, i32 2
  store i64 %t159, i64* %t171
  call void @star_rc_release(i8* %t141)
  store i8* %t161, i8** %t1
  br label %list_cow_done_589
list_cow_done_589:
  %t172 = load i8*, i8** %t1
  %t173 = bitcast i8* %t172 to { %Enemy*, i64, i64 }*
  %t174 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t173, i32 0, i32 0
  %t175 = load %Enemy*, %Enemy** %t174
  %t176 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t173, i32 0, i32 1
  %t177 = load i64, i64* %t176
  %t178 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t173, i32 0, i32 2
  %t180 = getelementptr inbounds %Enemy, %Enemy* %t179, i32 0, i32 0
  %t181 = load i32, i32* %t122
  %t182 = call float @map__cell_center_x(i32 %t181)
  store float %t182, float* %t180
  %t183 = getelementptr inbounds %Enemy, %Enemy* %t179, i32 0, i32 1
  %t184 = load i32, i32* %t122
  %t185 = call float @map__cell_center_y(i32 %t184)
  store float %t185, float* %t183
  %t186 = getelementptr inbounds %Enemy, %Enemy* %t179, i32 0, i32 2
  store float 0x404E000000000000, float* %t186
  %t187 = getelementptr inbounds %Enemy, %Enemy* %t179, i32 0, i32 3
  store i32 1, i32* %t187
  %t188 = getelementptr inbounds %Enemy, %Enemy* %t179, i32 0, i32 4
  store i1 true, i1* %t188
  %t189 = getelementptr inbounds %Enemy, %Enemy* %t179, i32 0, i32 5
  store float 0x0000000000000000, float* %t189
  %t190 = load %Enemy, %Enemy* %t179
  %t191 = load i64, i64* %t178
  %t192 = load %Enemy*, %Enemy** %t174
  %t193 = load i64, i64* %t176
  %t194 = icmp sge i64 %t193, %t191
  br i1 %t194, label %list_push_grow_593, label %list_push_store_594
list_push_grow_593:
  %t195 = mul i64 %t191, 2
  %t196 = icmp sgt i64 %t195, 0
  %t197 = select i1 %t196, i64 %t195, i64 1
  %t198 = getelementptr %Enemy, %Enemy* null, i32 1
  %t199 = ptrtoint %Enemy* %t198 to i64
  %t200 = mul i64 %t197, %t199
  %t201 = call i8* @malloc(i64 %t200)
  %t202 = bitcast i8* %t201 to %Enemy*
  %t203 = icmp sgt i64 %t191, 0
  br i1 %t203, label %list_push_copy_595, label %list_push_after_copy_596
list_push_copy_595:
  %t204 = mul i64 %t193, %t199
  %t205 = bitcast %Enemy* %t192 to i8*
  call i8* @memcpy(i8* %t201, i8* %t205, i64 %t204)
  call void @free(i8* %t205)
  br label %list_push_after_copy_596
list_push_after_copy_596:
  store %Enemy* %t202, %Enemy** %t174
  store i64 %t197, i64* %t178
  br label %list_push_store_594
list_push_store_594:
  %t206 = load %Enemy*, %Enemy** %t174
  %t207 = getelementptr inbounds %Enemy, %Enemy* %t206, i64 %t193
  store %Enemy %t190, %Enemy* %t207
  %t208 = add i64 %t193, 1
  store i64 %t208, i64* %t176
  %t209 = load i32, i32* %t2
  %t210 = add i32 %t209, 1
  store i32 %t210, i32* %t2
  br label %while_cond_574
while_else_576:
  br label %while_end_577
while_end_577:
  %t211 = load i8*, i8** %t1
  %t212 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t212)
  %t213 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t213)
  %t214 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 0
  %t215 = load i8*, i8** %t214
  call void @star_rc_release(i8* %t215)
  %t216 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 1
  %t217 = load i8*, i8** %t216
  call void @star_rc_release(i8* %t217)
  %t218 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 2
  %t219 = load i8*, i8** %t218
  call void @star_rc_release(i8* %t219)
  %t220 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 3
  %t221 = load i8*, i8** %t220
  call void @star_rc_release(i8* %t221)
  %t222 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 4
  %t223 = load i8*, i8** %t222
  call void @star_rc_release(i8* %t223)
  ret i8* %t211
}

define i8* @build_pickups(%map__Level %level) {
entry:
  %t0 = alloca %map__Level
  %t1 = alloca i8*
  %t2 = alloca i32
  %t16 = alloca i32
  %t77 = alloca %Pickup
  %t120 = alloca i32
  %t177 = alloca %Pickup
  store %map__Level %level, %map__Level* %t0
  store i8* null, i8** %t1
  store i32 0, i32* %t2
  br label %while_cond_597
while_cond_597:
  %t3 = load i32, i32* %t2
  %t4 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 3
  %t5 = load i8*, i8** %t4
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %list_read_null_601, label %list_read_real_602
list_read_null_601:
  br label %list_read_end_603
list_read_real_602:
  %t7 = bitcast i8* %t5 to { i32*, i64, i64 }*
  %t8 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t7, i32 0, i32 0
  %t9 = load i32*, i32** %t8
  %t10 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t7, i32 0, i32 1
  %t11 = load i64, i64* %t10
  br label %list_read_end_603
list_read_end_603:
  %t12 = phi i32* [ null, %list_read_null_601 ], [ %t9, %list_read_real_602 ]
  %t13 = phi i64 [ 0, %list_read_null_601 ], [ %t11, %list_read_real_602 ]
  %t14 = trunc i64 %t13 to i32
  %t15 = icmp slt i32 %t3, %t14
  br i1 %t15, label %while_body_598, label %while_else_599
while_body_598:
  %t17 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 3
  %t18 = load i8*, i8** %t17
  %t19 = icmp eq i8* %t18, null
  br i1 %t19, label %list_read_null_604, label %list_read_real_605
list_read_null_604:
  br label %list_read_end_606
list_read_real_605:
  %t20 = bitcast i8* %t18 to { i32*, i64, i64 }*
  %t21 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t20, i32 0, i32 0
  %t22 = load i32*, i32** %t21
  %t23 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t20, i32 0, i32 1
  %t24 = load i64, i64* %t23
  br label %list_read_end_606
list_read_end_606:
  %t25 = phi i32* [ null, %list_read_null_604 ], [ %t22, %list_read_real_605 ]
  %t26 = phi i64 [ 0, %list_read_null_604 ], [ %t24, %list_read_real_605 ]
  %t27 = load i32, i32* %t2
  %t28 = sext i32 %t27 to i64
  %t29 = icmp ult i64 %t28, %t26
  br i1 %t29, label %list_idx_ok_607, label %list_idx_oob_608
list_idx_ok_607:
  %t30 = getelementptr inbounds i32, i32* %t25, i64 %t28
  %t31 = load i32, i32* %t30
  br label %list_idx_end_609
list_idx_oob_608:
  br label %list_idx_end_609
list_idx_end_609:
  %t32 = phi i32 [ %t31, %list_idx_ok_607 ], [ 0, %list_idx_oob_608 ]
  store i32 %t32, i32* %t16
  %t33 = getelementptr %Pickup, %Pickup* null, i32 1
  %t34 = ptrtoint %Pickup* %t33 to i64
  %t35 = load i8*, i8** %t1
  %t36 = icmp eq i8* %t35, null
  br i1 %t36, label %list_cow_alloc_610, label %list_cow_check_611
list_cow_alloc_610:
  %t41 = bitcast void (i8*)* @list_release_s_Pickup to i8*
  %t42 = call i8* @star_rc_alloc(i64 24, i8* %t41)
  %t43 = bitcast i8* %t42 to { %Pickup*, i64, i64 }*
  %t44 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t43, i32 0, i32 0
  store %Pickup* null, %Pickup** %t44
  %t45 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t43, i32 0, i32 1
  store i64 0, i64* %t45
  %t46 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t43, i32 0, i32 2
  store i64 0, i64* %t46
  store i8* %t42, i8** %t1
  br label %list_cow_done_612
list_cow_check_611:
  %t47 = getelementptr inbounds i8, i8* %t35, i64 -16
  %t48 = bitcast i8* %t47 to i64*
  %t49 = load atomic i64, i64* %t48 seq_cst, align 8
  %t50 = icmp eq i64 %t49, 1
  br i1 %t50, label %list_cow_done_612, label %list_cow_clone_613
list_cow_clone_613:
  %t51 = bitcast i8* %t35 to { %Pickup*, i64, i64 }*
  %t52 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t51, i32 0, i32 0
  %t53 = load %Pickup*, %Pickup** %t52
  %t54 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t51, i32 0, i32 1
  %t55 = load i64, i64* %t54
  %t56 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t51, i32 0, i32 2
  %t57 = load i64, i64* %t56
  %t58 = bitcast void (i8*)* @list_release_s_Pickup to i8*
  %t59 = call i8* @star_rc_alloc(i64 24, i8* %t58)
  %t60 = bitcast i8* %t59 to { %Pickup*, i64, i64 }*
  %t61 = mul i64 %t57, %t34
  %t62 = call i8* @malloc(i64 %t61)
  %t63 = bitcast i8* %t62 to %Pickup*
  %t64 = icmp sgt i64 %t55, 0
  br i1 %t64, label %list_cow_copy_614, label %list_cow_after_copy_615
list_cow_copy_614:
  %t65 = mul i64 %t55, %t34
  %t66 = bitcast %Pickup* %t53 to i8*
  call i8* @memcpy(i8* %t62, i8* %t66, i64 %t65)
  br label %list_cow_after_copy_615
list_cow_after_copy_615:
  %t67 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t60, i32 0, i32 0
  store %Pickup* %t63, %Pickup** %t67
  %t68 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t60, i32 0, i32 1
  store i64 %t55, i64* %t68
  %t69 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t60, i32 0, i32 2
  store i64 %t57, i64* %t69
  call void @star_rc_release(i8* %t35)
  store i8* %t59, i8** %t1
  br label %list_cow_done_612
list_cow_done_612:
  %t70 = load i8*, i8** %t1
  %t71 = bitcast i8* %t70 to { %Pickup*, i64, i64 }*
  %t72 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t71, i32 0, i32 0
  %t73 = load %Pickup*, %Pickup** %t72
  %t74 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t71, i32 0, i32 1
  %t75 = load i64, i64* %t74
  %t76 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t71, i32 0, i32 2
  %t78 = getelementptr inbounds %Pickup, %Pickup* %t77, i32 0, i32 0
  %t79 = load i32, i32* %t16
  %t80 = call float @map__cell_center_x(i32 %t79)
  store float %t80, float* %t78
  %t81 = getelementptr inbounds %Pickup, %Pickup* %t77, i32 0, i32 1
  %t82 = load i32, i32* %t16
  %t83 = call float @map__cell_center_y(i32 %t82)
  store float %t83, float* %t81
  %t84 = getelementptr inbounds %Pickup, %Pickup* %t77, i32 0, i32 2
  store i32 0, i32* %t84
  %t85 = getelementptr inbounds %Pickup, %Pickup* %t77, i32 0, i32 3
  store i1 false, i1* %t85
  %t86 = load %Pickup, %Pickup* %t77
  %t87 = load i64, i64* %t76
  %t88 = load %Pickup*, %Pickup** %t72
  %t89 = load i64, i64* %t74
  %t90 = icmp sge i64 %t89, %t87
  br i1 %t90, label %list_push_grow_616, label %list_push_store_617
list_push_grow_616:
  %t91 = mul i64 %t87, 2
  %t92 = icmp sgt i64 %t91, 0
  %t93 = select i1 %t92, i64 %t91, i64 1
  %t94 = getelementptr %Pickup, %Pickup* null, i32 1
  %t95 = ptrtoint %Pickup* %t94 to i64
  %t96 = mul i64 %t93, %t95
  %t97 = call i8* @malloc(i64 %t96)
  %t98 = bitcast i8* %t97 to %Pickup*
  %t99 = icmp sgt i64 %t87, 0
  br i1 %t99, label %list_push_copy_618, label %list_push_after_copy_619
list_push_copy_618:
  %t100 = mul i64 %t89, %t95
  %t101 = bitcast %Pickup* %t88 to i8*
  call i8* @memcpy(i8* %t97, i8* %t101, i64 %t100)
  call void @free(i8* %t101)
  br label %list_push_after_copy_619
list_push_after_copy_619:
  store %Pickup* %t98, %Pickup** %t72
  store i64 %t93, i64* %t76
  br label %list_push_store_617
list_push_store_617:
  %t102 = load %Pickup*, %Pickup** %t72
  %t103 = getelementptr inbounds %Pickup, %Pickup* %t102, i64 %t89
  store %Pickup %t86, %Pickup* %t103
  %t104 = add i64 %t89, 1
  store i64 %t104, i64* %t74
  %t105 = load i32, i32* %t2
  %t106 = add i32 %t105, 1
  store i32 %t106, i32* %t2
  br label %while_cond_597
while_else_599:
  br label %while_end_600
while_end_600:
  store i32 0, i32* %t2
  br label %while_cond_620
while_cond_620:
  %t107 = load i32, i32* %t2
  %t108 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 4
  %t109 = load i8*, i8** %t108
  %t110 = icmp eq i8* %t109, null
  br i1 %t110, label %list_read_null_624, label %list_read_real_625
list_read_null_624:
  br label %list_read_end_626
list_read_real_625:
  %t111 = bitcast i8* %t109 to { i32*, i64, i64 }*
  %t112 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t111, i32 0, i32 0
  %t113 = load i32*, i32** %t112
  %t114 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t111, i32 0, i32 1
  %t115 = load i64, i64* %t114
  br label %list_read_end_626
list_read_end_626:
  %t116 = phi i32* [ null, %list_read_null_624 ], [ %t113, %list_read_real_625 ]
  %t117 = phi i64 [ 0, %list_read_null_624 ], [ %t115, %list_read_real_625 ]
  %t118 = trunc i64 %t117 to i32
  %t119 = icmp slt i32 %t107, %t118
  br i1 %t119, label %while_body_621, label %while_else_622
while_body_621:
  %t121 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 4
  %t122 = load i8*, i8** %t121
  %t123 = icmp eq i8* %t122, null
  br i1 %t123, label %list_read_null_627, label %list_read_real_628
list_read_null_627:
  br label %list_read_end_629
list_read_real_628:
  %t124 = bitcast i8* %t122 to { i32*, i64, i64 }*
  %t125 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t124, i32 0, i32 0
  %t126 = load i32*, i32** %t125
  %t127 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t124, i32 0, i32 1
  %t128 = load i64, i64* %t127
  br label %list_read_end_629
list_read_end_629:
  %t129 = phi i32* [ null, %list_read_null_627 ], [ %t126, %list_read_real_628 ]
  %t130 = phi i64 [ 0, %list_read_null_627 ], [ %t128, %list_read_real_628 ]
  %t131 = load i32, i32* %t2
  %t132 = sext i32 %t131 to i64
  %t133 = icmp ult i64 %t132, %t130
  br i1 %t133, label %list_idx_ok_630, label %list_idx_oob_631
list_idx_ok_630:
  %t134 = getelementptr inbounds i32, i32* %t129, i64 %t132
  %t135 = load i32, i32* %t134
  br label %list_idx_end_632
list_idx_oob_631:
  br label %list_idx_end_632
list_idx_end_632:
  %t136 = phi i32 [ %t135, %list_idx_ok_630 ], [ 0, %list_idx_oob_631 ]
  store i32 %t136, i32* %t120
  %t137 = getelementptr %Pickup, %Pickup* null, i32 1
  %t138 = ptrtoint %Pickup* %t137 to i64
  %t139 = load i8*, i8** %t1
  %t140 = icmp eq i8* %t139, null
  br i1 %t140, label %list_cow_alloc_633, label %list_cow_check_634
list_cow_alloc_633:
  %t141 = bitcast void (i8*)* @list_release_s_Pickup to i8*
  %t142 = call i8* @star_rc_alloc(i64 24, i8* %t141)
  %t143 = bitcast i8* %t142 to { %Pickup*, i64, i64 }*
  %t144 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t143, i32 0, i32 0
  store %Pickup* null, %Pickup** %t144
  %t145 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t143, i32 0, i32 1
  store i64 0, i64* %t145
  %t146 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t143, i32 0, i32 2
  store i64 0, i64* %t146
  store i8* %t142, i8** %t1
  br label %list_cow_done_635
list_cow_check_634:
  %t147 = getelementptr inbounds i8, i8* %t139, i64 -16
  %t148 = bitcast i8* %t147 to i64*
  %t149 = load atomic i64, i64* %t148 seq_cst, align 8
  %t150 = icmp eq i64 %t149, 1
  br i1 %t150, label %list_cow_done_635, label %list_cow_clone_636
list_cow_clone_636:
  %t151 = bitcast i8* %t139 to { %Pickup*, i64, i64 }*
  %t152 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t151, i32 0, i32 0
  %t153 = load %Pickup*, %Pickup** %t152
  %t154 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t151, i32 0, i32 1
  %t155 = load i64, i64* %t154
  %t156 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t151, i32 0, i32 2
  %t157 = load i64, i64* %t156
  %t158 = bitcast void (i8*)* @list_release_s_Pickup to i8*
  %t159 = call i8* @star_rc_alloc(i64 24, i8* %t158)
  %t160 = bitcast i8* %t159 to { %Pickup*, i64, i64 }*
  %t161 = mul i64 %t157, %t138
  %t162 = call i8* @malloc(i64 %t161)
  %t163 = bitcast i8* %t162 to %Pickup*
  %t164 = icmp sgt i64 %t155, 0
  br i1 %t164, label %list_cow_copy_637, label %list_cow_after_copy_638
list_cow_copy_637:
  %t165 = mul i64 %t155, %t138
  %t166 = bitcast %Pickup* %t153 to i8*
  call i8* @memcpy(i8* %t162, i8* %t166, i64 %t165)
  br label %list_cow_after_copy_638
list_cow_after_copy_638:
  %t167 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t160, i32 0, i32 0
  store %Pickup* %t163, %Pickup** %t167
  %t168 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t160, i32 0, i32 1
  store i64 %t155, i64* %t168
  %t169 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t160, i32 0, i32 2
  store i64 %t157, i64* %t169
  call void @star_rc_release(i8* %t139)
  store i8* %t159, i8** %t1
  br label %list_cow_done_635
list_cow_done_635:
  %t170 = load i8*, i8** %t1
  %t171 = bitcast i8* %t170 to { %Pickup*, i64, i64 }*
  %t172 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t171, i32 0, i32 0
  %t173 = load %Pickup*, %Pickup** %t172
  %t174 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t171, i32 0, i32 1
  %t175 = load i64, i64* %t174
  %t176 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t171, i32 0, i32 2
  %t178 = getelementptr inbounds %Pickup, %Pickup* %t177, i32 0, i32 0
  %t179 = load i32, i32* %t120
  %t180 = call float @map__cell_center_x(i32 %t179)
  store float %t180, float* %t178
  %t181 = getelementptr inbounds %Pickup, %Pickup* %t177, i32 0, i32 1
  %t182 = load i32, i32* %t120
  %t183 = call float @map__cell_center_y(i32 %t182)
  store float %t183, float* %t181
  %t184 = getelementptr inbounds %Pickup, %Pickup* %t177, i32 0, i32 2
  store i32 1, i32* %t184
  %t185 = getelementptr inbounds %Pickup, %Pickup* %t177, i32 0, i32 3
  store i1 false, i1* %t185
  %t186 = load %Pickup, %Pickup* %t177
  %t187 = load i64, i64* %t176
  %t188 = load %Pickup*, %Pickup** %t172
  %t189 = load i64, i64* %t174
  %t190 = icmp sge i64 %t189, %t187
  br i1 %t190, label %list_push_grow_639, label %list_push_store_640
list_push_grow_639:
  %t191 = mul i64 %t187, 2
  %t192 = icmp sgt i64 %t191, 0
  %t193 = select i1 %t192, i64 %t191, i64 1
  %t194 = getelementptr %Pickup, %Pickup* null, i32 1
  %t195 = ptrtoint %Pickup* %t194 to i64
  %t196 = mul i64 %t193, %t195
  %t197 = call i8* @malloc(i64 %t196)
  %t198 = bitcast i8* %t197 to %Pickup*
  %t199 = icmp sgt i64 %t187, 0
  br i1 %t199, label %list_push_copy_641, label %list_push_after_copy_642
list_push_copy_641:
  %t200 = mul i64 %t189, %t195
  %t201 = bitcast %Pickup* %t188 to i8*
  call i8* @memcpy(i8* %t197, i8* %t201, i64 %t200)
  call void @free(i8* %t201)
  br label %list_push_after_copy_642
list_push_after_copy_642:
  store %Pickup* %t198, %Pickup** %t172
  store i64 %t193, i64* %t176
  br label %list_push_store_640
list_push_store_640:
  %t202 = load %Pickup*, %Pickup** %t172
  %t203 = getelementptr inbounds %Pickup, %Pickup* %t202, i64 %t189
  store %Pickup %t186, %Pickup* %t203
  %t204 = add i64 %t189, 1
  store i64 %t204, i64* %t174
  %t205 = load i32, i32* %t2
  %t206 = add i32 %t205, 1
  store i32 %t206, i32* %t2
  br label %while_cond_620
while_else_622:
  br label %while_end_623
while_end_623:
  %t207 = load i8*, i8** %t1
  %t208 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t208)
  %t209 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t209)
  %t210 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 0
  %t211 = load i8*, i8** %t210
  call void @star_rc_release(i8* %t211)
  %t212 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 1
  %t213 = load i8*, i8** %t212
  call void @star_rc_release(i8* %t213)
  %t214 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 2
  %t215 = load i8*, i8** %t214
  call void @star_rc_release(i8* %t215)
  %t216 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 3
  %t217 = load i8*, i8** %t216
  call void @star_rc_release(i8* %t217)
  %t218 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 4
  %t219 = load i8*, i8** %t218
  call void @star_rc_release(i8* %t219)
  ret i8* %t207
}

define { float, i32, float, i32 } @cast_ray(i8* %map_grid, float %px, float %py, float %dir_x, float %dir_y, float %plane_x, float %plane_y, float %camera_x) {
entry:
  %t0 = alloca i8*
  %t1 = alloca float
  %t2 = alloca float
  %t3 = alloca float
  %t4 = alloca float
  %t5 = alloca float
  %t6 = alloca float
  %t7 = alloca float
  %t8 = alloca float
  %t14 = alloca float
  %t20 = alloca i32
  %t23 = alloca i32
  %t26 = alloca float
  %t33 = alloca float
  %t40 = alloca float
  %t43 = alloca float
  %t46 = alloca i32
  %t47 = alloca i32
  %t48 = alloca float
  %t49 = alloca float
  %t82 = alloca i32
  %t83 = alloca i32
  %t84 = alloca i32
  %t109 = alloca float
  %t119 = alloca float
  %t133 = alloca float
  %t139 = alloca { float, i32, float, i32 }
  store i8* %map_grid, i8** %t0
  store float %px, float* %t1
  store float %py, float* %t2
  store float %dir_x, float* %t3
  store float %dir_y, float* %t4
  store float %plane_x, float* %t5
  store float %plane_y, float* %t6
  store float %camera_x, float* %t7
  %t9 = load float, float* %t3
  %t10 = load float, float* %t5
  %t11 = load float, float* %t7
  %t12 = fmul float %t10, %t11
  %t13 = fadd float %t9, %t12
  store float %t13, float* %t8
  %t15 = load float, float* %t4
  %t16 = load float, float* %t6
  %t17 = load float, float* %t7
  %t18 = fmul float %t16, %t17
  %t19 = fadd float %t15, %t18
  store float %t19, float* %t14
  %t21 = load float, float* %t1
  %t22 = call i32 @llvm.fptosi.sat.i32.f32(float %t21)
  store i32 %t22, i32* %t20
  %t24 = load float, float* %t2
  %t25 = call i32 @llvm.fptosi.sat.i32.f32(float %t24)
  store i32 %t25, i32* %t23
  %t27 = load float, float* %t8
  %t28 = call float @llvm.fabs.f32(float %t27)
  %t29 = fcmp olt float %t28, 0x3F1A36E2E0000000
  br i1 %t29, label %if_then_643, label %if_else_644
if_then_643:
  br label %if_end_645
if_else_644:
  %t30 = load float, float* %t8
  %t31 = fdiv float 0x3FF0000000000000, %t30
  br label %if_end_645
if_end_645:
  %t32 = phi float [ 0x412E848000000000, %if_then_643 ], [ %t31, %if_else_644 ]
  store float %t32, float* %t26
  %t34 = load float, float* %t14
  %t35 = call float @llvm.fabs.f32(float %t34)
  %t36 = fcmp olt float %t35, 0x3F1A36E2E0000000
  br i1 %t36, label %if_then_646, label %if_else_647
if_then_646:
  br label %if_end_648
if_else_647:
  %t37 = load float, float* %t14
  %t38 = fdiv float 0x3FF0000000000000, %t37
  br label %if_end_648
if_end_648:
  %t39 = phi float [ 0x412E848000000000, %if_then_646 ], [ %t38, %if_else_647 ]
  store float %t39, float* %t33
  %t41 = load float, float* %t26
  %t42 = call float @llvm.fabs.f32(float %t41)
  store float %t42, float* %t40
  %t44 = load float, float* %t33
  %t45 = call float @llvm.fabs.f32(float %t44)
  store float %t45, float* %t43
  store i32 0, i32* %t46
  store i32 0, i32* %t47
  store float 0x0000000000000000, float* %t48
  store float 0x0000000000000000, float* %t49
  %t50 = load float, float* %t8
  %t51 = fcmp olt float %t50, 0x0000000000000000
  br i1 %t51, label %if_then_649, label %if_else_650
if_then_649:
  %t52 = sub i32 0, 1
  store i32 %t52, i32* %t46
  %t53 = load float, float* %t1
  %t54 = load i32, i32* %t20
  %t55 = sitofp i32 %t54 to float
  %t56 = fsub float %t53, %t55
  %t57 = load float, float* %t40
  %t58 = fmul float %t56, %t57
  store float %t58, float* %t48
  br label %if_end_651
if_else_650:
  store i32 1, i32* %t46
  %t59 = load i32, i32* %t20
  %t60 = add i32 %t59, 1
  %t61 = sitofp i32 %t60 to float
  %t62 = load float, float* %t1
  %t63 = fsub float %t61, %t62
  %t64 = load float, float* %t40
  %t65 = fmul float %t63, %t64
  store float %t65, float* %t48
  br label %if_end_651
if_end_651:
  %t66 = load float, float* %t14
  %t67 = fcmp olt float %t66, 0x0000000000000000
  br i1 %t67, label %if_then_652, label %if_else_653
if_then_652:
  %t68 = sub i32 0, 1
  store i32 %t68, i32* %t47
  %t69 = load float, float* %t2
  %t70 = load i32, i32* %t23
  %t71 = sitofp i32 %t70 to float
  %t72 = fsub float %t69, %t71
  %t73 = load float, float* %t43
  %t74 = fmul float %t72, %t73
  store float %t74, float* %t49
  br label %if_end_654
if_else_653:
  store i32 1, i32* %t47
  %t75 = load i32, i32* %t23
  %t76 = add i32 %t75, 1
  %t77 = sitofp i32 %t76 to float
  %t78 = load float, float* %t2
  %t79 = fsub float %t77, %t78
  %t80 = load float, float* %t43
  %t81 = fmul float %t79, %t80
  store float %t81, float* %t49
  br label %if_end_654
if_end_654:
  store i32 0, i32* %t82
  store i32 0, i32* %t83
  store i32 0, i32* %t84
  br label %while_cond_655
while_cond_655:
  %t85 = load i32, i32* %t83
  %t86 = icmp eq i32 %t85, 0
  br i1 %t86, label %while_body_656, label %while_else_657
while_body_656:
  %t87 = load float, float* %t48
  %t88 = load float, float* %t49
  %t89 = fcmp olt float %t87, %t88
  br i1 %t89, label %if_then_659, label %if_else_660
if_then_659:
  %t90 = load float, float* %t40
  %t91 = load float, float* %t48
  %t92 = fadd float %t91, %t90
  store float %t92, float* %t48
  %t93 = load i32, i32* %t46
  %t94 = load i32, i32* %t20
  %t95 = add i32 %t94, %t93
  store i32 %t95, i32* %t20
  store i32 0, i32* %t82
  br label %if_end_661
if_else_660:
  %t96 = load float, float* %t43
  %t97 = load float, float* %t49
  %t98 = fadd float %t97, %t96
  store float %t98, float* %t49
  %t99 = load i32, i32* %t47
  %t100 = load i32, i32* %t23
  %t101 = add i32 %t100, %t99
  store i32 %t101, i32* %t23
  store i32 1, i32* %t82
  br label %if_end_661
if_end_661:
  %t102 = load i8*, i8** %t0
  %t103 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t103)
  %t104 = load i32, i32* %t20
  %t105 = load i32, i32* %t23
  %t106 = call i32 @map__cell_at(i8* %t102, i32 %t104, i32 %t105)
  store i32 %t106, i32* %t84
  %t107 = load i32, i32* %t84
  %t108 = icmp sgt i32 %t107, 0
  br i1 %t108, label %if_then_662, label %if_else_663
if_then_662:
  store i32 1, i32* %t83
  br label %if_end_664
if_else_663:
  br label %if_end_664
if_end_664:
  br label %while_cond_655
while_else_657:
  br label %while_end_658
while_end_658:
  %t110 = load i32, i32* %t82
  %t111 = icmp eq i32 %t110, 0
  br i1 %t111, label %if_then_665, label %if_else_666
if_then_665:
  %t112 = load float, float* %t48
  %t113 = load float, float* %t40
  %t114 = fsub float %t112, %t113
  br label %if_end_667
if_else_666:
  %t115 = load float, float* %t49
  %t116 = load float, float* %t43
  %t117 = fsub float %t115, %t116
  br label %if_end_667
if_end_667:
  %t118 = phi float [ %t114, %if_then_665 ], [ %t117, %if_else_666 ]
  store float %t118, float* %t109
  %t120 = load i32, i32* %t82
  %t121 = icmp eq i32 %t120, 0
  br i1 %t121, label %if_then_668, label %if_else_669
if_then_668:
  %t122 = load float, float* %t2
  %t123 = load float, float* %t109
  %t124 = load float, float* %t14
  %t125 = fmul float %t123, %t124
  %t126 = fadd float %t122, %t125
  br label %if_end_670
if_else_669:
  %t127 = load float, float* %t1
  %t128 = load float, float* %t109
  %t129 = load float, float* %t8
  %t130 = fmul float %t128, %t129
  %t131 = fadd float %t127, %t130
  br label %if_end_670
if_end_670:
  %t132 = phi float [ %t126, %if_then_668 ], [ %t131, %if_else_669 ]
  store float %t132, float* %t119
  %t134 = load float, float* %t119
  %t135 = load float, float* %t119
  %t136 = call i32 @llvm.fptosi.sat.i32.f32(float %t135)
  %t137 = sitofp i32 %t136 to float
  %t138 = fsub float %t134, %t137
  store float %t138, float* %t133
  %t140 = load float, float* %t109
  %t141 = getelementptr inbounds { float, i32, float, i32 }, { float, i32, float, i32 }* %t139, i32 0, i32 0
  store float %t140, float* %t141
  %t142 = load i32, i32* %t84
  %t143 = getelementptr inbounds { float, i32, float, i32 }, { float, i32, float, i32 }* %t139, i32 0, i32 1
  store i32 %t142, i32* %t143
  %t144 = load float, float* %t133
  %t145 = getelementptr inbounds { float, i32, float, i32 }, { float, i32, float, i32 }* %t139, i32 0, i32 2
  store float %t144, float* %t145
  %t146 = load i32, i32* %t82
  %t147 = getelementptr inbounds { float, i32, float, i32 }, { float, i32, float, i32 }* %t139, i32 0, i32 3
  store i32 %t146, i32* %t147
  %t148 = load { float, i32, float, i32 }, { float, i32, float, i32 }* %t139
  %t149 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t149)
  ret { float, i32, float, i32 } %t148
}

define { i32, i32, i32 } @wall_pixel(i32 %kind, float %wall_frac, i32 %tex_y, i32 %tex_h) {
entry:
  %t0 = alloca i32
  %t1 = alloca float
  %t2 = alloca i32
  %t3 = alloca i32
  %t4 = alloca { i32, i32, i32 }
  %t7 = alloca i32
  %t10 = alloca i32
  %t13 = alloca i32
  %t16 = alloca i32
  %t56 = alloca i32
  %t103 = alloca { i32, i32, i32 }
  store i32 %kind, i32* %t0
  store float %wall_frac, float* %t1
  store i32 %tex_y, i32* %t2
  store i32 %tex_h, i32* %t3
  %t5 = load i32, i32* %t0
  %t6 = call { i32, i32, i32 } @map__wall_base(i32 %t5)
  store { i32, i32, i32 } %t6, { i32, i32, i32 }* %t4
  %t8 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t4, i32 0, i32 0
  %t9 = load i32, i32* %t8
  store i32 %t9, i32* %t7
  %t11 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t4, i32 0, i32 1
  %t12 = load i32, i32* %t11
  store i32 %t12, i32* %t10
  %t14 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t4, i32 0, i32 2
  %t15 = load i32, i32* %t14
  store i32 %t15, i32* %t13
  %t17 = load float, float* %t1
  %t18 = fmul float %t17, 0x4020000000000000
  %t19 = call i32 @llvm.fptosi.sat.i32.f32(float %t18)
  store i32 %t19, i32* %t16
  %t20 = load i32, i32* %t16
  %t21 = icmp eq i32 2, 0
  %t22 = icmp eq i32 %t20, -2147483648
  %t23 = icmp eq i32 2, -1
  %t24 = and i1 %t22, %t23
  %t25 = or i1 %t21, %t24
  br i1 %t25, label %int_div_fail_671, label %int_div_ok_672
int_div_fail_671:
  %t26 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.30, i64 0, i64 0
  call i32 @puts(i8* %t26)
  call void @exit(i32 1)
  unreachable
int_div_ok_672:
  %t27 = srem i32 %t20, 2
  %t28 = icmp eq i32 %t27, 0
  br i1 %t28, label %if_then_673, label %if_else_674
if_then_673:
  %t29 = load i32, i32* %t7
  %t30 = mul i32 %t29, 8
  %t31 = icmp eq i32 10, 0
  %t32 = icmp eq i32 %t30, -2147483648
  %t33 = icmp eq i32 10, -1
  %t34 = and i1 %t32, %t33
  %t35 = or i1 %t31, %t34
  br i1 %t35, label %int_div_fail_676, label %int_div_ok_677
int_div_fail_676:
  %t36 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.31, i64 0, i64 0
  call i32 @puts(i8* %t36)
  call void @exit(i32 1)
  unreachable
int_div_ok_677:
  %t37 = sdiv i32 %t30, 10
  store i32 %t37, i32* %t7
  %t38 = load i32, i32* %t10
  %t39 = mul i32 %t38, 8
  %t40 = icmp eq i32 10, 0
  %t41 = icmp eq i32 %t39, -2147483648
  %t42 = icmp eq i32 10, -1
  %t43 = and i1 %t41, %t42
  %t44 = or i1 %t40, %t43
  br i1 %t44, label %int_div_fail_678, label %int_div_ok_679
int_div_fail_678:
  %t45 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.32, i64 0, i64 0
  call i32 @puts(i8* %t45)
  call void @exit(i32 1)
  unreachable
int_div_ok_679:
  %t46 = sdiv i32 %t39, 10
  store i32 %t46, i32* %t10
  %t47 = load i32, i32* %t13
  %t48 = mul i32 %t47, 8
  %t49 = icmp eq i32 10, 0
  %t50 = icmp eq i32 %t48, -2147483648
  %t51 = icmp eq i32 10, -1
  %t52 = and i1 %t50, %t51
  %t53 = or i1 %t49, %t52
  br i1 %t53, label %int_div_fail_680, label %int_div_ok_681
int_div_fail_680:
  %t54 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.33, i64 0, i64 0
  call i32 @puts(i8* %t54)
  call void @exit(i32 1)
  unreachable
int_div_ok_681:
  %t55 = sdiv i32 %t48, 10
  store i32 %t55, i32* %t13
  br label %if_end_675
if_else_674:
  br label %if_end_675
if_end_675:
  %t57 = load i32, i32* %t2
  %t58 = mul i32 %t57, 8
  %t59 = load i32, i32* %t3
  %t60 = icmp eq i32 %t59, 0
  %t61 = icmp eq i32 %t58, -2147483648
  %t62 = icmp eq i32 %t59, -1
  %t63 = and i1 %t61, %t62
  %t64 = or i1 %t60, %t63
  br i1 %t64, label %int_div_fail_682, label %int_div_ok_683
int_div_fail_682:
  %t65 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.34, i64 0, i64 0
  call i32 @puts(i8* %t65)
  call void @exit(i32 1)
  unreachable
int_div_ok_683:
  %t66 = sdiv i32 %t58, %t59
  store i32 %t66, i32* %t56
  %t67 = load i32, i32* %t56
  %t68 = icmp eq i32 2, 0
  %t69 = icmp eq i32 %t67, -2147483648
  %t70 = icmp eq i32 2, -1
  %t71 = and i1 %t69, %t70
  %t72 = or i1 %t68, %t71
  br i1 %t72, label %int_div_fail_684, label %int_div_ok_685
int_div_fail_684:
  %t73 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.35, i64 0, i64 0
  call i32 @puts(i8* %t73)
  call void @exit(i32 1)
  unreachable
int_div_ok_685:
  %t74 = srem i32 %t67, 2
  %t75 = icmp eq i32 %t74, 0
  br i1 %t75, label %if_then_686, label %if_else_687
if_then_686:
  %t76 = load i32, i32* %t7
  %t77 = mul i32 %t76, 8
  %t78 = icmp eq i32 10, 0
  %t79 = icmp eq i32 %t77, -2147483648
  %t80 = icmp eq i32 10, -1
  %t81 = and i1 %t79, %t80
  %t82 = or i1 %t78, %t81
  br i1 %t82, label %int_div_fail_689, label %int_div_ok_690
int_div_fail_689:
  %t83 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.36, i64 0, i64 0
  call i32 @puts(i8* %t83)
  call void @exit(i32 1)
  unreachable
int_div_ok_690:
  %t84 = sdiv i32 %t77, 10
  store i32 %t84, i32* %t7
  %t85 = load i32, i32* %t10
  %t86 = mul i32 %t85, 8
  %t87 = icmp eq i32 10, 0
  %t88 = icmp eq i32 %t86, -2147483648
  %t89 = icmp eq i32 10, -1
  %t90 = and i1 %t88, %t89
  %t91 = or i1 %t87, %t90
  br i1 %t91, label %int_div_fail_691, label %int_div_ok_692
int_div_fail_691:
  %t92 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.37, i64 0, i64 0
  call i32 @puts(i8* %t92)
  call void @exit(i32 1)
  unreachable
int_div_ok_692:
  %t93 = sdiv i32 %t86, 10
  store i32 %t93, i32* %t10
  %t94 = load i32, i32* %t13
  %t95 = mul i32 %t94, 8
  %t96 = icmp eq i32 10, 0
  %t97 = icmp eq i32 %t95, -2147483648
  %t98 = icmp eq i32 10, -1
  %t99 = and i1 %t97, %t98
  %t100 = or i1 %t96, %t99
  br i1 %t100, label %int_div_fail_693, label %int_div_ok_694
int_div_fail_693:
  %t101 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.38, i64 0, i64 0
  call i32 @puts(i8* %t101)
  call void @exit(i32 1)
  unreachable
int_div_ok_694:
  %t102 = sdiv i32 %t95, 10
  store i32 %t102, i32* %t13
  br label %if_end_688
if_else_687:
  br label %if_end_688
if_end_688:
  %t104 = load i32, i32* %t7
  %t105 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t103, i32 0, i32 0
  store i32 %t104, i32* %t105
  %t106 = load i32, i32* %t10
  %t107 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t103, i32 0, i32 1
  store i32 %t106, i32* %t107
  %t108 = load i32, i32* %t13
  %t109 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t103, i32 0, i32 2
  store i32 %t108, i32* %t109
  %t110 = load { i32, i32, i32 }, { i32, i32, i32 }* %t103
  ret { i32, i32, i32 } %t110
}

define { i32, i32, i32 } @shade_color(i32 %r, i32 %g, i32 %b, float %shade) {
entry:
  %t0 = alloca i32
  %t1 = alloca i32
  %t2 = alloca i32
  %t3 = alloca float
  %t4 = alloca { i32, i32, i32 }
  store i32 %r, i32* %t0
  store i32 %g, i32* %t1
  store i32 %b, i32* %t2
  store float %shade, float* %t3
  %t5 = load i32, i32* %t0
  %t6 = sitofp i32 %t5 to float
  %t7 = load float, float* %t3
  %t8 = fmul float %t6, %t7
  %t9 = call i32 @llvm.fptosi.sat.i32.f32(float %t8)
  %t10 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t4, i32 0, i32 0
  store i32 %t9, i32* %t10
  %t11 = load i32, i32* %t1
  %t12 = sitofp i32 %t11 to float
  %t13 = load float, float* %t3
  %t14 = fmul float %t12, %t13
  %t15 = call i32 @llvm.fptosi.sat.i32.f32(float %t14)
  %t16 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t4, i32 0, i32 1
  store i32 %t15, i32* %t16
  %t17 = load i32, i32* %t2
  %t18 = sitofp i32 %t17 to float
  %t19 = load float, float* %t3
  %t20 = fmul float %t18, %t19
  %t21 = call i32 @llvm.fptosi.sat.i32.f32(float %t20)
  %t22 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t4, i32 0, i32 2
  store i32 %t21, i32* %t22
  %t23 = load { i32, i32, i32 }, { i32, i32, i32 }* %t4
  ret { i32, i32, i32 } %t23
}

define i8* @pick_sprite(%sprites__SpriteSet %s, i32 %kind) {
entry:
  %t0 = alloca %sprites__SpriteSet
  %t1 = alloca i32
  store %sprites__SpriteSet %s, %sprites__SpriteSet* %t0
  store i32 %kind, i32* %t1
  %t2 = load i32, i32* %t1
  %t3 = icmp eq i32 %t2, 0
  br i1 %t3, label %if_then_695, label %if_else_696
if_then_695:
  %t4 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 0
  %t5 = load i8*, i8** %t4
  %t6 = load i8*, i8** %t4
  call void @star_rc_retain(i8* %t6)
  %t7 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 0
  %t8 = load i8*, i8** %t7
  call void @star_rc_release(i8* %t8)
  %t9 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 1
  %t10 = load i8*, i8** %t9
  call void @star_rc_release(i8* %t10)
  %t11 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 2
  %t12 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t12)
  %t13 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 3
  %t14 = load i8*, i8** %t13
  call void @star_rc_release(i8* %t14)
  %t15 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 4
  %t16 = load i8*, i8** %t15
  call void @star_rc_release(i8* %t16)
  ret i8* %t5
if_else_696:
  br label %if_end_697
if_end_697:
  %t17 = load i32, i32* %t1
  %t18 = icmp eq i32 %t17, 1
  br i1 %t18, label %if_then_698, label %if_else_699
if_then_698:
  %t19 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 4
  %t20 = load i8*, i8** %t19
  %t21 = load i8*, i8** %t19
  call void @star_rc_retain(i8* %t21)
  %t22 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 0
  %t23 = load i8*, i8** %t22
  call void @star_rc_release(i8* %t23)
  %t24 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 1
  %t25 = load i8*, i8** %t24
  call void @star_rc_release(i8* %t25)
  %t26 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 2
  %t27 = load i8*, i8** %t26
  call void @star_rc_release(i8* %t27)
  %t28 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 3
  %t29 = load i8*, i8** %t28
  call void @star_rc_release(i8* %t29)
  %t30 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 4
  %t31 = load i8*, i8** %t30
  call void @star_rc_release(i8* %t31)
  ret i8* %t20
if_else_699:
  br label %if_end_700
if_end_700:
  %t32 = load i32, i32* %t1
  %t33 = icmp eq i32 %t32, 2
  br i1 %t33, label %if_then_701, label %if_else_702
if_then_701:
  %t34 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 2
  %t35 = load i8*, i8** %t34
  %t36 = load i8*, i8** %t34
  call void @star_rc_retain(i8* %t36)
  %t37 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 0
  %t38 = load i8*, i8** %t37
  call void @star_rc_release(i8* %t38)
  %t39 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 1
  %t40 = load i8*, i8** %t39
  call void @star_rc_release(i8* %t40)
  %t41 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 2
  %t42 = load i8*, i8** %t41
  call void @star_rc_release(i8* %t42)
  %t43 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 3
  %t44 = load i8*, i8** %t43
  call void @star_rc_release(i8* %t44)
  %t45 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 4
  %t46 = load i8*, i8** %t45
  call void @star_rc_release(i8* %t46)
  ret i8* %t35
if_else_702:
  br label %if_end_703
if_end_703:
  %t47 = load i32, i32* %t1
  %t48 = icmp eq i32 %t47, 3
  br i1 %t48, label %if_then_704, label %if_else_705
if_then_704:
  %t49 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 3
  %t50 = load i8*, i8** %t49
  %t51 = load i8*, i8** %t49
  call void @star_rc_retain(i8* %t51)
  %t52 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 0
  %t53 = load i8*, i8** %t52
  call void @star_rc_release(i8* %t53)
  %t54 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 1
  %t55 = load i8*, i8** %t54
  call void @star_rc_release(i8* %t55)
  %t56 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 2
  %t57 = load i8*, i8** %t56
  call void @star_rc_release(i8* %t57)
  %t58 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 3
  %t59 = load i8*, i8** %t58
  call void @star_rc_release(i8* %t59)
  %t60 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 4
  %t61 = load i8*, i8** %t60
  call void @star_rc_release(i8* %t61)
  ret i8* %t50
if_else_705:
  br label %if_end_706
if_end_706:
  %t62 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 1
  %t63 = load i8*, i8** %t62
  %t64 = load i8*, i8** %t62
  call void @star_rc_retain(i8* %t64)
  %t65 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 0
  %t66 = load i8*, i8** %t65
  call void @star_rc_release(i8* %t66)
  %t67 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 1
  %t68 = load i8*, i8** %t67
  call void @star_rc_release(i8* %t68)
  %t69 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 2
  %t70 = load i8*, i8** %t69
  call void @star_rc_release(i8* %t70)
  %t71 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 3
  %t72 = load i8*, i8** %t71
  call void @star_rc_release(i8* %t72)
  %t73 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t0, i32 0, i32 4
  %t74 = load i8*, i8** %t73
  call void @star_rc_release(i8* %t74)
  ret i8* %t63
}

define { i8*, i8* } @render_walls(float %px, float %py, float %angle, i8* %map_grid) {
entry:
  %t0 = alloca float
  %t1 = alloca float
  %t2 = alloca float
  %t3 = alloca i8*
  %t4 = alloca i8*
  %t5 = alloca i8*
  %t6 = alloca i32
  %t73 = alloca i32
  %t76 = alloca i32
  %t77 = alloca i32
  %t78 = alloca i32
  %t88 = alloca float
  %t112 = alloca float
  %t144 = alloca i32
  %t390 = alloca float
  %t393 = alloca float
  %t396 = alloca float
  %t401 = alloca float
  %t405 = alloca i32
  %t408 = alloca float
  %t415 = alloca { float, i32, float, i32 }
  %t426 = alloca float
  %t429 = alloca i32
  %t432 = alloca float
  %t494 = alloca float
  %t498 = alloca i32
  %t506 = alloca i32
  %t513 = alloca float
  %t519 = alloca i32
  %t529 = alloca i32
  %t545 = alloca { i32, i32, i32 }
  %t550 = alloca { i32, i32, i32 }
  %t805 = alloca { i8*, i8* }
  store float %px, float* %t0
  store float %py, float* %t1
  store float %angle, float* %t2
  store i8* %map_grid, i8** %t3
  store i8* null, i8** %t4
  store i8* null, i8** %t5
  store i32 0, i32* %t6
  br label %while_cond_707
while_cond_707:
  %t7 = load i32, i32* %t6
  %t8 = icmp slt i32 %t7, 320
  br i1 %t8, label %while_body_708, label %while_else_709
while_body_708:
  %t9 = getelementptr float, float* null, i32 1
  %t10 = ptrtoint float* %t9 to i64
  %t11 = load i8*, i8** %t5
  %t12 = icmp eq i8* %t11, null
  br i1 %t12, label %list_cow_alloc_711, label %list_cow_check_712
list_cow_alloc_711:
  %t17 = bitcast void (i8*)* @list_release_f32 to i8*
  %t18 = call i8* @star_rc_alloc(i64 24, i8* %t17)
  %t19 = bitcast i8* %t18 to { float*, i64, i64 }*
  %t20 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t19, i32 0, i32 0
  store float* null, float** %t20
  %t21 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t19, i32 0, i32 1
  store i64 0, i64* %t21
  %t22 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t19, i32 0, i32 2
  store i64 0, i64* %t22
  store i8* %t18, i8** %t5
  br label %list_cow_done_713
list_cow_check_712:
  %t23 = getelementptr inbounds i8, i8* %t11, i64 -16
  %t24 = bitcast i8* %t23 to i64*
  %t25 = load atomic i64, i64* %t24 seq_cst, align 8
  %t26 = icmp eq i64 %t25, 1
  br i1 %t26, label %list_cow_done_713, label %list_cow_clone_714
list_cow_clone_714:
  %t27 = bitcast i8* %t11 to { float*, i64, i64 }*
  %t28 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t27, i32 0, i32 0
  %t29 = load float*, float** %t28
  %t30 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t27, i32 0, i32 1
  %t31 = load i64, i64* %t30
  %t32 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t27, i32 0, i32 2
  %t33 = load i64, i64* %t32
  %t34 = bitcast void (i8*)* @list_release_f32 to i8*
  %t35 = call i8* @star_rc_alloc(i64 24, i8* %t34)
  %t36 = bitcast i8* %t35 to { float*, i64, i64 }*
  %t37 = mul i64 %t33, %t10
  %t38 = call i8* @malloc(i64 %t37)
  %t39 = bitcast i8* %t38 to float*
  %t40 = icmp sgt i64 %t31, 0
  br i1 %t40, label %list_cow_copy_715, label %list_cow_after_copy_716
list_cow_copy_715:
  %t41 = mul i64 %t31, %t10
  %t42 = bitcast float* %t29 to i8*
  call i8* @memcpy(i8* %t38, i8* %t42, i64 %t41)
  br label %list_cow_after_copy_716
list_cow_after_copy_716:
  %t43 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t36, i32 0, i32 0
  store float* %t39, float** %t43
  %t44 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t36, i32 0, i32 1
  store i64 %t31, i64* %t44
  %t45 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t36, i32 0, i32 2
  store i64 %t33, i64* %t45
  call void @star_rc_release(i8* %t11)
  store i8* %t35, i8** %t5
  br label %list_cow_done_713
list_cow_done_713:
  %t46 = load i8*, i8** %t5
  %t47 = bitcast i8* %t46 to { float*, i64, i64 }*
  %t48 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t47, i32 0, i32 0
  %t49 = load float*, float** %t48
  %t50 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t47, i32 0, i32 1
  %t51 = load i64, i64* %t50
  %t52 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t47, i32 0, i32 2
  %t53 = load i64, i64* %t52
  %t54 = load float*, float** %t48
  %t55 = load i64, i64* %t50
  %t56 = icmp sge i64 %t55, %t53
  br i1 %t56, label %list_push_grow_717, label %list_push_store_718
list_push_grow_717:
  %t57 = mul i64 %t53, 2
  %t58 = icmp sgt i64 %t57, 0
  %t59 = select i1 %t58, i64 %t57, i64 1
  %t60 = getelementptr float, float* null, i32 1
  %t61 = ptrtoint float* %t60 to i64
  %t62 = mul i64 %t59, %t61
  %t63 = call i8* @malloc(i64 %t62)
  %t64 = bitcast i8* %t63 to float*
  %t65 = icmp sgt i64 %t53, 0
  br i1 %t65, label %list_push_copy_719, label %list_push_after_copy_720
list_push_copy_719:
  %t66 = mul i64 %t55, %t61
  %t67 = bitcast float* %t54 to i8*
  call i8* @memcpy(i8* %t63, i8* %t67, i64 %t66)
  call void @free(i8* %t67)
  br label %list_push_after_copy_720
list_push_after_copy_720:
  store float* %t64, float** %t48
  store i64 %t59, i64* %t52
  br label %list_push_store_718
list_push_store_718:
  %t68 = load float*, float** %t48
  %t69 = getelementptr inbounds float, float* %t68, i64 %t55
  store float 0x408F400000000000, float* %t69
  %t70 = add i64 %t55, 1
  store i64 %t70, i64* %t50
  %t71 = load i32, i32* %t6
  %t72 = add i32 %t71, 1
  store i32 %t72, i32* %t6
  br label %while_cond_707
while_else_709:
  br label %while_end_710
while_end_710:
  store i32 0, i32* %t73
  br label %while_cond_721
while_cond_721:
  %t74 = load i32, i32* %t73
  %t75 = icmp slt i32 %t74, 200
  br i1 %t75, label %while_body_722, label %while_else_723
while_body_722:
  store i32 0, i32* %t76
  store i32 0, i32* %t77
  store i32 0, i32* %t78
  %t79 = load i32, i32* %t73
  %t80 = icmp eq i32 2, 0
  %t81 = icmp eq i32 200, -2147483648
  %t82 = icmp eq i32 2, -1
  %t83 = and i1 %t81, %t82
  %t84 = or i1 %t80, %t83
  br i1 %t84, label %int_div_fail_725, label %int_div_ok_726
int_div_fail_725:
  %t85 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.39, i64 0, i64 0
  call i32 @puts(i8* %t85)
  call void @exit(i32 1)
  unreachable
int_div_ok_726:
  %t86 = sdiv i32 200, 2
  %t87 = icmp slt i32 %t79, %t86
  br i1 %t87, label %if_then_727, label %if_else_728
if_then_727:
  %t89 = load i32, i32* %t73
  %t90 = sitofp i32 %t89 to float
  %t91 = icmp eq i32 2, 0
  %t92 = icmp eq i32 200, -2147483648
  %t93 = icmp eq i32 2, -1
  %t94 = and i1 %t92, %t93
  %t95 = or i1 %t91, %t94
  br i1 %t95, label %int_div_fail_730, label %int_div_ok_731
int_div_fail_730:
  %t96 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.40, i64 0, i64 0
  call i32 @puts(i8* %t96)
  call void @exit(i32 1)
  unreachable
int_div_ok_731:
  %t97 = sdiv i32 200, 2
  %t98 = sitofp i32 %t97 to float
  %t99 = fdiv float %t90, %t98
  store float %t99, float* %t88
  %t100 = load float, float* %t88
  %t101 = fmul float %t100, 0x4032000000000000
  %t102 = call i32 @llvm.fptosi.sat.i32.f32(float %t101)
  %t103 = add i32 8, %t102
  store i32 %t103, i32* %t76
  %t104 = load float, float* %t88
  %t105 = fmul float %t104, 0x4032000000000000
  %t106 = call i32 @llvm.fptosi.sat.i32.f32(float %t105)
  %t107 = add i32 8, %t106
  store i32 %t107, i32* %t77
  %t108 = load float, float* %t88
  %t109 = fmul float %t108, 0x403E000000000000
  %t110 = call i32 @llvm.fptosi.sat.i32.f32(float %t109)
  %t111 = add i32 16, %t110
  store i32 %t111, i32* %t78
  br label %if_end_729
if_else_728:
  %t113 = load i32, i32* %t73
  %t114 = icmp eq i32 2, 0
  %t115 = icmp eq i32 200, -2147483648
  %t116 = icmp eq i32 2, -1
  %t117 = and i1 %t115, %t116
  %t118 = or i1 %t114, %t117
  br i1 %t118, label %int_div_fail_732, label %int_div_ok_733
int_div_fail_732:
  %t119 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.41, i64 0, i64 0
  call i32 @puts(i8* %t119)
  call void @exit(i32 1)
  unreachable
int_div_ok_733:
  %t120 = sdiv i32 200, 2
  %t121 = sub i32 %t113, %t120
  %t122 = sitofp i32 %t121 to float
  %t123 = icmp eq i32 2, 0
  %t124 = icmp eq i32 200, -2147483648
  %t125 = icmp eq i32 2, -1
  %t126 = and i1 %t124, %t125
  %t127 = or i1 %t123, %t126
  br i1 %t127, label %int_div_fail_734, label %int_div_ok_735
int_div_fail_734:
  %t128 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.42, i64 0, i64 0
  call i32 @puts(i8* %t128)
  call void @exit(i32 1)
  unreachable
int_div_ok_735:
  %t129 = sdiv i32 200, 2
  %t130 = sitofp i32 %t129 to float
  %t131 = fdiv float %t122, %t130
  store float %t131, float* %t112
  %t132 = load float, float* %t112
  %t133 = fmul float %t132, 0x4034000000000000
  %t134 = call i32 @llvm.fptosi.sat.i32.f32(float %t133)
  %t135 = add i32 26, %t134
  store i32 %t135, i32* %t76
  %t136 = load float, float* %t112
  %t137 = fmul float %t136, 0x4034000000000000
  %t138 = call i32 @llvm.fptosi.sat.i32.f32(float %t137)
  %t139 = add i32 26, %t138
  store i32 %t139, i32* %t77
  %t140 = load float, float* %t112
  %t141 = fmul float %t140, 0x403E000000000000
  %t142 = call i32 @llvm.fptosi.sat.i32.f32(float %t141)
  %t143 = add i32 46, %t142
  store i32 %t143, i32* %t78
  br label %if_end_729
if_end_729:
  store i32 0, i32* %t144
  br label %while_cond_736
while_cond_736:
  %t145 = load i32, i32* %t144
  %t146 = icmp slt i32 %t145, 320
  br i1 %t146, label %while_body_737, label %while_else_738
while_body_737:
  %t147 = getelementptr i8, i8* null, i32 1
  %t148 = ptrtoint i8* %t147 to i64
  %t149 = load i8*, i8** %t4
  %t150 = icmp eq i8* %t149, null
  br i1 %t150, label %list_cow_alloc_740, label %list_cow_check_741
list_cow_alloc_740:
  %t151 = bitcast void (i8*)* @list_release_u8 to i8*
  %t152 = call i8* @star_rc_alloc(i64 24, i8* %t151)
  %t153 = bitcast i8* %t152 to { i8*, i64, i64 }*
  %t154 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t153, i32 0, i32 0
  store i8* null, i8** %t154
  %t155 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t153, i32 0, i32 1
  store i64 0, i64* %t155
  %t156 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t153, i32 0, i32 2
  store i64 0, i64* %t156
  store i8* %t152, i8** %t4
  br label %list_cow_done_742
list_cow_check_741:
  %t157 = getelementptr inbounds i8, i8* %t149, i64 -16
  %t158 = bitcast i8* %t157 to i64*
  %t159 = load atomic i64, i64* %t158 seq_cst, align 8
  %t160 = icmp eq i64 %t159, 1
  br i1 %t160, label %list_cow_done_742, label %list_cow_clone_743
list_cow_clone_743:
  %t161 = bitcast i8* %t149 to { i8*, i64, i64 }*
  %t162 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t161, i32 0, i32 0
  %t163 = load i8*, i8** %t162
  %t164 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t161, i32 0, i32 1
  %t165 = load i64, i64* %t164
  %t166 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t161, i32 0, i32 2
  %t167 = load i64, i64* %t166
  %t168 = bitcast void (i8*)* @list_release_u8 to i8*
  %t169 = call i8* @star_rc_alloc(i64 24, i8* %t168)
  %t170 = bitcast i8* %t169 to { i8*, i64, i64 }*
  %t171 = mul i64 %t167, %t148
  %t172 = call i8* @malloc(i64 %t171)
  %t173 = bitcast i8* %t172 to i8*
  %t174 = icmp sgt i64 %t165, 0
  br i1 %t174, label %list_cow_copy_744, label %list_cow_after_copy_745
list_cow_copy_744:
  %t175 = mul i64 %t165, %t148
  %t176 = bitcast i8* %t163 to i8*
  call i8* @memcpy(i8* %t172, i8* %t176, i64 %t175)
  br label %list_cow_after_copy_745
list_cow_after_copy_745:
  %t177 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t170, i32 0, i32 0
  store i8* %t173, i8** %t177
  %t178 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t170, i32 0, i32 1
  store i64 %t165, i64* %t178
  %t179 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t170, i32 0, i32 2
  store i64 %t167, i64* %t179
  call void @star_rc_release(i8* %t149)
  store i8* %t169, i8** %t4
  br label %list_cow_done_742
list_cow_done_742:
  %t180 = load i8*, i8** %t4
  %t181 = bitcast i8* %t180 to { i8*, i64, i64 }*
  %t182 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t181, i32 0, i32 0
  %t183 = load i8*, i8** %t182
  %t184 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t181, i32 0, i32 1
  %t185 = load i64, i64* %t184
  %t186 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t181, i32 0, i32 2
  %t187 = load i32, i32* %t76
  %t188 = trunc i32 %t187 to i8
  %t189 = load i64, i64* %t186
  %t190 = load i8*, i8** %t182
  %t191 = load i64, i64* %t184
  %t192 = icmp sge i64 %t191, %t189
  br i1 %t192, label %list_push_grow_746, label %list_push_store_747
list_push_grow_746:
  %t193 = mul i64 %t189, 2
  %t194 = icmp sgt i64 %t193, 0
  %t195 = select i1 %t194, i64 %t193, i64 1
  %t196 = getelementptr i8, i8* null, i32 1
  %t197 = ptrtoint i8* %t196 to i64
  %t198 = mul i64 %t195, %t197
  %t199 = call i8* @malloc(i64 %t198)
  %t200 = bitcast i8* %t199 to i8*
  %t201 = icmp sgt i64 %t189, 0
  br i1 %t201, label %list_push_copy_748, label %list_push_after_copy_749
list_push_copy_748:
  %t202 = mul i64 %t191, %t197
  %t203 = bitcast i8* %t190 to i8*
  call i8* @memcpy(i8* %t199, i8* %t203, i64 %t202)
  call void @free(i8* %t203)
  br label %list_push_after_copy_749
list_push_after_copy_749:
  store i8* %t200, i8** %t182
  store i64 %t195, i64* %t186
  br label %list_push_store_747
list_push_store_747:
  %t204 = load i8*, i8** %t182
  %t205 = getelementptr inbounds i8, i8* %t204, i64 %t191
  store i8 %t188, i8* %t205
  %t206 = add i64 %t191, 1
  store i64 %t206, i64* %t184
  %t207 = getelementptr i8, i8* null, i32 1
  %t208 = ptrtoint i8* %t207 to i64
  %t209 = load i8*, i8** %t4
  %t210 = icmp eq i8* %t209, null
  br i1 %t210, label %list_cow_alloc_750, label %list_cow_check_751
list_cow_alloc_750:
  %t211 = bitcast void (i8*)* @list_release_u8 to i8*
  %t212 = call i8* @star_rc_alloc(i64 24, i8* %t211)
  %t213 = bitcast i8* %t212 to { i8*, i64, i64 }*
  %t214 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t213, i32 0, i32 0
  store i8* null, i8** %t214
  %t215 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t213, i32 0, i32 1
  store i64 0, i64* %t215
  %t216 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t213, i32 0, i32 2
  store i64 0, i64* %t216
  store i8* %t212, i8** %t4
  br label %list_cow_done_752
list_cow_check_751:
  %t217 = getelementptr inbounds i8, i8* %t209, i64 -16
  %t218 = bitcast i8* %t217 to i64*
  %t219 = load atomic i64, i64* %t218 seq_cst, align 8
  %t220 = icmp eq i64 %t219, 1
  br i1 %t220, label %list_cow_done_752, label %list_cow_clone_753
list_cow_clone_753:
  %t221 = bitcast i8* %t209 to { i8*, i64, i64 }*
  %t222 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t221, i32 0, i32 0
  %t223 = load i8*, i8** %t222
  %t224 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t221, i32 0, i32 1
  %t225 = load i64, i64* %t224
  %t226 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t221, i32 0, i32 2
  %t227 = load i64, i64* %t226
  %t228 = bitcast void (i8*)* @list_release_u8 to i8*
  %t229 = call i8* @star_rc_alloc(i64 24, i8* %t228)
  %t230 = bitcast i8* %t229 to { i8*, i64, i64 }*
  %t231 = mul i64 %t227, %t208
  %t232 = call i8* @malloc(i64 %t231)
  %t233 = bitcast i8* %t232 to i8*
  %t234 = icmp sgt i64 %t225, 0
  br i1 %t234, label %list_cow_copy_754, label %list_cow_after_copy_755
list_cow_copy_754:
  %t235 = mul i64 %t225, %t208
  %t236 = bitcast i8* %t223 to i8*
  call i8* @memcpy(i8* %t232, i8* %t236, i64 %t235)
  br label %list_cow_after_copy_755
list_cow_after_copy_755:
  %t237 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t230, i32 0, i32 0
  store i8* %t233, i8** %t237
  %t238 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t230, i32 0, i32 1
  store i64 %t225, i64* %t238
  %t239 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t230, i32 0, i32 2
  store i64 %t227, i64* %t239
  call void @star_rc_release(i8* %t209)
  store i8* %t229, i8** %t4
  br label %list_cow_done_752
list_cow_done_752:
  %t240 = load i8*, i8** %t4
  %t241 = bitcast i8* %t240 to { i8*, i64, i64 }*
  %t242 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t241, i32 0, i32 0
  %t243 = load i8*, i8** %t242
  %t244 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t241, i32 0, i32 1
  %t245 = load i64, i64* %t244
  %t246 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t241, i32 0, i32 2
  %t247 = load i32, i32* %t77
  %t248 = trunc i32 %t247 to i8
  %t249 = load i64, i64* %t246
  %t250 = load i8*, i8** %t242
  %t251 = load i64, i64* %t244
  %t252 = icmp sge i64 %t251, %t249
  br i1 %t252, label %list_push_grow_756, label %list_push_store_757
list_push_grow_756:
  %t253 = mul i64 %t249, 2
  %t254 = icmp sgt i64 %t253, 0
  %t255 = select i1 %t254, i64 %t253, i64 1
  %t256 = getelementptr i8, i8* null, i32 1
  %t257 = ptrtoint i8* %t256 to i64
  %t258 = mul i64 %t255, %t257
  %t259 = call i8* @malloc(i64 %t258)
  %t260 = bitcast i8* %t259 to i8*
  %t261 = icmp sgt i64 %t249, 0
  br i1 %t261, label %list_push_copy_758, label %list_push_after_copy_759
list_push_copy_758:
  %t262 = mul i64 %t251, %t257
  %t263 = bitcast i8* %t250 to i8*
  call i8* @memcpy(i8* %t259, i8* %t263, i64 %t262)
  call void @free(i8* %t263)
  br label %list_push_after_copy_759
list_push_after_copy_759:
  store i8* %t260, i8** %t242
  store i64 %t255, i64* %t246
  br label %list_push_store_757
list_push_store_757:
  %t264 = load i8*, i8** %t242
  %t265 = getelementptr inbounds i8, i8* %t264, i64 %t251
  store i8 %t248, i8* %t265
  %t266 = add i64 %t251, 1
  store i64 %t266, i64* %t244
  %t267 = getelementptr i8, i8* null, i32 1
  %t268 = ptrtoint i8* %t267 to i64
  %t269 = load i8*, i8** %t4
  %t270 = icmp eq i8* %t269, null
  br i1 %t270, label %list_cow_alloc_760, label %list_cow_check_761
list_cow_alloc_760:
  %t271 = bitcast void (i8*)* @list_release_u8 to i8*
  %t272 = call i8* @star_rc_alloc(i64 24, i8* %t271)
  %t273 = bitcast i8* %t272 to { i8*, i64, i64 }*
  %t274 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t273, i32 0, i32 0
  store i8* null, i8** %t274
  %t275 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t273, i32 0, i32 1
  store i64 0, i64* %t275
  %t276 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t273, i32 0, i32 2
  store i64 0, i64* %t276
  store i8* %t272, i8** %t4
  br label %list_cow_done_762
list_cow_check_761:
  %t277 = getelementptr inbounds i8, i8* %t269, i64 -16
  %t278 = bitcast i8* %t277 to i64*
  %t279 = load atomic i64, i64* %t278 seq_cst, align 8
  %t280 = icmp eq i64 %t279, 1
  br i1 %t280, label %list_cow_done_762, label %list_cow_clone_763
list_cow_clone_763:
  %t281 = bitcast i8* %t269 to { i8*, i64, i64 }*
  %t282 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t281, i32 0, i32 0
  %t283 = load i8*, i8** %t282
  %t284 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t281, i32 0, i32 1
  %t285 = load i64, i64* %t284
  %t286 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t281, i32 0, i32 2
  %t287 = load i64, i64* %t286
  %t288 = bitcast void (i8*)* @list_release_u8 to i8*
  %t289 = call i8* @star_rc_alloc(i64 24, i8* %t288)
  %t290 = bitcast i8* %t289 to { i8*, i64, i64 }*
  %t291 = mul i64 %t287, %t268
  %t292 = call i8* @malloc(i64 %t291)
  %t293 = bitcast i8* %t292 to i8*
  %t294 = icmp sgt i64 %t285, 0
  br i1 %t294, label %list_cow_copy_764, label %list_cow_after_copy_765
list_cow_copy_764:
  %t295 = mul i64 %t285, %t268
  %t296 = bitcast i8* %t283 to i8*
  call i8* @memcpy(i8* %t292, i8* %t296, i64 %t295)
  br label %list_cow_after_copy_765
list_cow_after_copy_765:
  %t297 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t290, i32 0, i32 0
  store i8* %t293, i8** %t297
  %t298 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t290, i32 0, i32 1
  store i64 %t285, i64* %t298
  %t299 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t290, i32 0, i32 2
  store i64 %t287, i64* %t299
  call void @star_rc_release(i8* %t269)
  store i8* %t289, i8** %t4
  br label %list_cow_done_762
list_cow_done_762:
  %t300 = load i8*, i8** %t4
  %t301 = bitcast i8* %t300 to { i8*, i64, i64 }*
  %t302 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t301, i32 0, i32 0
  %t303 = load i8*, i8** %t302
  %t304 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t301, i32 0, i32 1
  %t305 = load i64, i64* %t304
  %t306 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t301, i32 0, i32 2
  %t307 = load i32, i32* %t78
  %t308 = trunc i32 %t307 to i8
  %t309 = load i64, i64* %t306
  %t310 = load i8*, i8** %t302
  %t311 = load i64, i64* %t304
  %t312 = icmp sge i64 %t311, %t309
  br i1 %t312, label %list_push_grow_766, label %list_push_store_767
list_push_grow_766:
  %t313 = mul i64 %t309, 2
  %t314 = icmp sgt i64 %t313, 0
  %t315 = select i1 %t314, i64 %t313, i64 1
  %t316 = getelementptr i8, i8* null, i32 1
  %t317 = ptrtoint i8* %t316 to i64
  %t318 = mul i64 %t315, %t317
  %t319 = call i8* @malloc(i64 %t318)
  %t320 = bitcast i8* %t319 to i8*
  %t321 = icmp sgt i64 %t309, 0
  br i1 %t321, label %list_push_copy_768, label %list_push_after_copy_769
list_push_copy_768:
  %t322 = mul i64 %t311, %t317
  %t323 = bitcast i8* %t310 to i8*
  call i8* @memcpy(i8* %t319, i8* %t323, i64 %t322)
  call void @free(i8* %t323)
  br label %list_push_after_copy_769
list_push_after_copy_769:
  store i8* %t320, i8** %t302
  store i64 %t315, i64* %t306
  br label %list_push_store_767
list_push_store_767:
  %t324 = load i8*, i8** %t302
  %t325 = getelementptr inbounds i8, i8* %t324, i64 %t311
  store i8 %t308, i8* %t325
  %t326 = add i64 %t311, 1
  store i64 %t326, i64* %t304
  %t327 = getelementptr i8, i8* null, i32 1
  %t328 = ptrtoint i8* %t327 to i64
  %t329 = load i8*, i8** %t4
  %t330 = icmp eq i8* %t329, null
  br i1 %t330, label %list_cow_alloc_770, label %list_cow_check_771
list_cow_alloc_770:
  %t331 = bitcast void (i8*)* @list_release_u8 to i8*
  %t332 = call i8* @star_rc_alloc(i64 24, i8* %t331)
  %t333 = bitcast i8* %t332 to { i8*, i64, i64 }*
  %t334 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t333, i32 0, i32 0
  store i8* null, i8** %t334
  %t335 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t333, i32 0, i32 1
  store i64 0, i64* %t335
  %t336 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t333, i32 0, i32 2
  store i64 0, i64* %t336
  store i8* %t332, i8** %t4
  br label %list_cow_done_772
list_cow_check_771:
  %t337 = getelementptr inbounds i8, i8* %t329, i64 -16
  %t338 = bitcast i8* %t337 to i64*
  %t339 = load atomic i64, i64* %t338 seq_cst, align 8
  %t340 = icmp eq i64 %t339, 1
  br i1 %t340, label %list_cow_done_772, label %list_cow_clone_773
list_cow_clone_773:
  %t341 = bitcast i8* %t329 to { i8*, i64, i64 }*
  %t342 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t341, i32 0, i32 0
  %t343 = load i8*, i8** %t342
  %t344 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t341, i32 0, i32 1
  %t345 = load i64, i64* %t344
  %t346 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t341, i32 0, i32 2
  %t347 = load i64, i64* %t346
  %t348 = bitcast void (i8*)* @list_release_u8 to i8*
  %t349 = call i8* @star_rc_alloc(i64 24, i8* %t348)
  %t350 = bitcast i8* %t349 to { i8*, i64, i64 }*
  %t351 = mul i64 %t347, %t328
  %t352 = call i8* @malloc(i64 %t351)
  %t353 = bitcast i8* %t352 to i8*
  %t354 = icmp sgt i64 %t345, 0
  br i1 %t354, label %list_cow_copy_774, label %list_cow_after_copy_775
list_cow_copy_774:
  %t355 = mul i64 %t345, %t328
  %t356 = bitcast i8* %t343 to i8*
  call i8* @memcpy(i8* %t352, i8* %t356, i64 %t355)
  br label %list_cow_after_copy_775
list_cow_after_copy_775:
  %t357 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t350, i32 0, i32 0
  store i8* %t353, i8** %t357
  %t358 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t350, i32 0, i32 1
  store i64 %t345, i64* %t358
  %t359 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t350, i32 0, i32 2
  store i64 %t347, i64* %t359
  call void @star_rc_release(i8* %t329)
  store i8* %t349, i8** %t4
  br label %list_cow_done_772
list_cow_done_772:
  %t360 = load i8*, i8** %t4
  %t361 = bitcast i8* %t360 to { i8*, i64, i64 }*
  %t362 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t361, i32 0, i32 0
  %t363 = load i8*, i8** %t362
  %t364 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t361, i32 0, i32 1
  %t365 = load i64, i64* %t364
  %t366 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t361, i32 0, i32 2
  %t367 = trunc i32 255 to i8
  %t368 = load i64, i64* %t366
  %t369 = load i8*, i8** %t362
  %t370 = load i64, i64* %t364
  %t371 = icmp sge i64 %t370, %t368
  br i1 %t371, label %list_push_grow_776, label %list_push_store_777
list_push_grow_776:
  %t372 = mul i64 %t368, 2
  %t373 = icmp sgt i64 %t372, 0
  %t374 = select i1 %t373, i64 %t372, i64 1
  %t375 = getelementptr i8, i8* null, i32 1
  %t376 = ptrtoint i8* %t375 to i64
  %t377 = mul i64 %t374, %t376
  %t378 = call i8* @malloc(i64 %t377)
  %t379 = bitcast i8* %t378 to i8*
  %t380 = icmp sgt i64 %t368, 0
  br i1 %t380, label %list_push_copy_778, label %list_push_after_copy_779
list_push_copy_778:
  %t381 = mul i64 %t370, %t376
  %t382 = bitcast i8* %t369 to i8*
  call i8* @memcpy(i8* %t378, i8* %t382, i64 %t381)
  call void @free(i8* %t382)
  br label %list_push_after_copy_779
list_push_after_copy_779:
  store i8* %t379, i8** %t362
  store i64 %t374, i64* %t366
  br label %list_push_store_777
list_push_store_777:
  %t383 = load i8*, i8** %t362
  %t384 = getelementptr inbounds i8, i8* %t383, i64 %t370
  store i8 %t367, i8* %t384
  %t385 = add i64 %t370, 1
  store i64 %t385, i64* %t364
  %t386 = load i32, i32* %t144
  %t387 = add i32 %t386, 1
  store i32 %t387, i32* %t144
  br label %while_cond_736
while_else_738:
  br label %while_end_739
while_end_739:
  %t388 = load i32, i32* %t73
  %t389 = add i32 %t388, 1
  store i32 %t389, i32* %t73
  br label %while_cond_721
while_else_723:
  br label %while_end_724
while_end_724:
  %t391 = load float, float* %t2
  %t392 = call float @llvm.cos.f32(float %t391)
  store float %t392, float* %t390
  %t394 = load float, float* %t2
  %t395 = call float @llvm.sin.f32(float %t394)
  store float %t395, float* %t393
  %t397 = load float, float* %t2
  %t398 = call float @llvm.sin.f32(float %t397)
  %t399 = fsub float 0.0, %t398
  %t400 = fmul float %t399, 0x3FE51EB860000000
  store float %t400, float* %t396
  %t402 = load float, float* %t2
  %t403 = call float @llvm.cos.f32(float %t402)
  %t404 = fmul float %t403, 0x3FE51EB860000000
  store float %t404, float* %t401
  store i32 0, i32* %t405
  br label %while_cond_780
while_cond_780:
  %t406 = load i32, i32* %t405
  %t407 = icmp slt i32 %t406, 320
  br i1 %t407, label %while_body_781, label %while_else_782
while_body_781:
  %t409 = load i32, i32* %t405
  %t410 = sitofp i32 %t409 to float
  %t411 = fmul float 0x4000000000000000, %t410
  %t412 = sitofp i32 320 to float
  %t413 = fdiv float %t411, %t412
  %t414 = fsub float %t413, 0x3FF0000000000000
  store float %t414, float* %t408
  %t416 = load i8*, i8** %t3
  %t417 = load i8*, i8** %t3
  call void @star_rc_retain(i8* %t417)
  %t418 = load float, float* %t0
  %t419 = load float, float* %t1
  %t420 = load float, float* %t390
  %t421 = load float, float* %t393
  %t422 = load float, float* %t396
  %t423 = load float, float* %t401
  %t424 = load float, float* %t408
  %t425 = call { float, i32, float, i32 } @cast_ray(i8* %t416, float %t418, float %t419, float %t420, float %t421, float %t422, float %t423, float %t424)
  store { float, i32, float, i32 } %t425, { float, i32, float, i32 }* %t415
  %t427 = getelementptr inbounds { float, i32, float, i32 }, { float, i32, float, i32 }* %t415, i32 0, i32 0
  %t428 = load float, float* %t427
  store float %t428, float* %t426
  %t430 = getelementptr inbounds { float, i32, float, i32 }, { float, i32, float, i32 }* %t415, i32 0, i32 1
  %t431 = load i32, i32* %t430
  store i32 %t431, i32* %t429
  %t433 = getelementptr inbounds { float, i32, float, i32 }, { float, i32, float, i32 }* %t415, i32 0, i32 2
  %t434 = load float, float* %t433
  store float %t434, float* %t432
  %t435 = getelementptr float, float* null, i32 1
  %t436 = ptrtoint float* %t435 to i64
  %t437 = load i8*, i8** %t5
  %t438 = icmp eq i8* %t437, null
  br i1 %t438, label %list_cow_alloc_784, label %list_cow_check_785
list_cow_alloc_784:
  %t439 = bitcast void (i8*)* @list_release_f32 to i8*
  %t440 = call i8* @star_rc_alloc(i64 24, i8* %t439)
  %t441 = bitcast i8* %t440 to { float*, i64, i64 }*
  %t442 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t441, i32 0, i32 0
  store float* null, float** %t442
  %t443 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t441, i32 0, i32 1
  store i64 0, i64* %t443
  %t444 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t441, i32 0, i32 2
  store i64 0, i64* %t444
  store i8* %t440, i8** %t5
  br label %list_cow_done_786
list_cow_check_785:
  %t445 = getelementptr inbounds i8, i8* %t437, i64 -16
  %t446 = bitcast i8* %t445 to i64*
  %t447 = load atomic i64, i64* %t446 seq_cst, align 8
  %t448 = icmp eq i64 %t447, 1
  br i1 %t448, label %list_cow_done_786, label %list_cow_clone_787
list_cow_clone_787:
  %t449 = bitcast i8* %t437 to { float*, i64, i64 }*
  %t450 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t449, i32 0, i32 0
  %t451 = load float*, float** %t450
  %t452 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t449, i32 0, i32 1
  %t453 = load i64, i64* %t452
  %t454 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t449, i32 0, i32 2
  %t455 = load i64, i64* %t454
  %t456 = bitcast void (i8*)* @list_release_f32 to i8*
  %t457 = call i8* @star_rc_alloc(i64 24, i8* %t456)
  %t458 = bitcast i8* %t457 to { float*, i64, i64 }*
  %t459 = mul i64 %t455, %t436
  %t460 = call i8* @malloc(i64 %t459)
  %t461 = bitcast i8* %t460 to float*
  %t462 = icmp sgt i64 %t453, 0
  br i1 %t462, label %list_cow_copy_788, label %list_cow_after_copy_789
list_cow_copy_788:
  %t463 = mul i64 %t453, %t436
  %t464 = bitcast float* %t451 to i8*
  call i8* @memcpy(i8* %t460, i8* %t464, i64 %t463)
  br label %list_cow_after_copy_789
list_cow_after_copy_789:
  %t465 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t458, i32 0, i32 0
  store float* %t461, float** %t465
  %t466 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t458, i32 0, i32 1
  store i64 %t453, i64* %t466
  %t467 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t458, i32 0, i32 2
  store i64 %t455, i64* %t467
  call void @star_rc_release(i8* %t437)
  store i8* %t457, i8** %t5
  br label %list_cow_done_786
list_cow_done_786:
  %t468 = load i8*, i8** %t5
  %t469 = bitcast i8* %t468 to { float*, i64, i64 }*
  %t470 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t469, i32 0, i32 0
  %t471 = load float*, float** %t470
  %t472 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t469, i32 0, i32 1
  %t473 = load i64, i64* %t472
  %t474 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t469, i32 0, i32 2
  %t475 = load float, float* %t426
  %t476 = load i64, i64* %t474
  %t477 = load float*, float** %t470
  %t478 = load i64, i64* %t472
  %t479 = icmp sge i64 %t478, %t476
  br i1 %t479, label %list_push_grow_790, label %list_push_store_791
list_push_grow_790:
  %t480 = mul i64 %t476, 2
  %t481 = icmp sgt i64 %t480, 0
  %t482 = select i1 %t481, i64 %t480, i64 1
  %t483 = getelementptr float, float* null, i32 1
  %t484 = ptrtoint float* %t483 to i64
  %t485 = mul i64 %t482, %t484
  %t486 = call i8* @malloc(i64 %t485)
  %t487 = bitcast i8* %t486 to float*
  %t488 = icmp sgt i64 %t476, 0
  br i1 %t488, label %list_push_copy_792, label %list_push_after_copy_793
list_push_copy_792:
  %t489 = mul i64 %t478, %t484
  %t490 = bitcast float* %t477 to i8*
  call i8* @memcpy(i8* %t486, i8* %t490, i64 %t489)
  call void @free(i8* %t490)
  br label %list_push_after_copy_793
list_push_after_copy_793:
  store float* %t487, float** %t470
  store i64 %t482, i64* %t474
  br label %list_push_store_791
list_push_store_791:
  %t491 = load float*, float** %t470
  %t492 = getelementptr inbounds float, float* %t491, i64 %t478
  store float %t475, float* %t492
  %t493 = add i64 %t478, 1
  store i64 %t493, i64* %t472
  %t495 = sitofp i32 200 to float
  %t496 = load float, float* %t426
  %t497 = fdiv float %t495, %t496
  store float %t497, float* %t494
  %t499 = load float, float* %t494
  %t500 = fdiv float %t499, 0x4000000000000000
  %t501 = fsub float 0x0000000000000000, %t500
  %t502 = sitofp i32 200 to float
  %t503 = fdiv float %t502, 0x4000000000000000
  %t504 = fadd float %t501, %t503
  %t505 = call i32 @llvm.fptosi.sat.i32.f32(float %t504)
  store i32 %t505, i32* %t498
  %t507 = load float, float* %t494
  %t508 = fdiv float %t507, 0x4000000000000000
  %t509 = sitofp i32 200 to float
  %t510 = fdiv float %t509, 0x4000000000000000
  %t511 = fadd float %t508, %t510
  %t512 = call i32 @llvm.fptosi.sat.i32.f32(float %t511)
  store i32 %t512, i32* %t506
  %t514 = load float, float* %t426
  %t515 = fdiv float %t514, 0x4028000000000000
  %t516 = fsub float 0x3FF0000000000000, %t515
  %t517 = call float @llvm.maxnum.f32(float %t516, float 0x3FC3333340000000)
  %t518 = call float @llvm.minnum.f32(float %t517, float 0x3FF0000000000000)
  store float %t518, float* %t513
  %t520 = load i32, i32* %t498
  store i32 %t520, i32* %t519
  br label %while_cond_794
while_cond_794:
  %t521 = load i32, i32* %t519
  %t522 = load i32, i32* %t506
  %t523 = icmp slt i32 %t521, %t522
  br i1 %t523, label %while_body_795, label %while_else_796
while_body_795:
  %t524 = load i32, i32* %t519
  %t525 = icmp sge i32 %t524, 0
  br i1 %t525, label %logic_rhs_798, label %logic_short_799
logic_rhs_798:
  %t526 = load i32, i32* %t519
  %t527 = icmp slt i32 %t526, 200
  br label %logic_end_800
logic_short_799:
  br label %logic_end_800
logic_end_800:
  %t528 = phi i1 [ %t527, %logic_rhs_798 ], [ false, %logic_short_799 ]
  br i1 %t528, label %if_then_801, label %if_else_802
if_then_801:
  %t530 = load i32, i32* %t519
  %t531 = load i32, i32* %t498
  %t532 = sub i32 %t530, %t531
  %t533 = mul i32 %t532, 16
  %t534 = load float, float* %t494
  %t535 = call i32 @llvm.fptosi.sat.i32.f32(float %t534)
  %t536 = icmp sgt i32 %t535, 1
  %t537 = select i1 %t536, i32 %t535, i32 1
  %t538 = icmp eq i32 %t537, 0
  %t539 = icmp eq i32 %t533, -2147483648
  %t540 = icmp eq i32 %t537, -1
  %t541 = and i1 %t539, %t540
  %t542 = or i1 %t538, %t541
  br i1 %t542, label %int_div_fail_804, label %int_div_ok_805
int_div_fail_804:
  %t543 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.43, i64 0, i64 0
  call i32 @puts(i8* %t543)
  call void @exit(i32 1)
  unreachable
int_div_ok_805:
  %t544 = sdiv i32 %t533, %t537
  store i32 %t544, i32* %t529
  %t546 = load i32, i32* %t429
  %t547 = load float, float* %t432
  %t548 = load i32, i32* %t529
  %t549 = call { i32, i32, i32 } @wall_pixel(i32 %t546, float %t547, i32 %t548, i32 16)
  store { i32, i32, i32 } %t549, { i32, i32, i32 }* %t545
  %t551 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t545, i32 0, i32 0
  %t552 = load i32, i32* %t551
  %t553 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t545, i32 0, i32 1
  %t554 = load i32, i32* %t553
  %t555 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t545, i32 0, i32 2
  %t556 = load i32, i32* %t555
  %t557 = load float, float* %t513
  %t558 = call { i32, i32, i32 } @shade_color(i32 %t552, i32 %t554, i32 %t556, float %t557)
  store { i32, i32, i32 } %t558, { i32, i32, i32 }* %t550
  %t559 = getelementptr i8, i8* null, i32 1
  %t560 = ptrtoint i8* %t559 to i64
  %t561 = load i8*, i8** %t4
  %t562 = icmp eq i8* %t561, null
  br i1 %t562, label %list_cow_alloc_806, label %list_cow_check_807
list_cow_alloc_806:
  %t563 = bitcast void (i8*)* @list_release_u8 to i8*
  %t564 = call i8* @star_rc_alloc(i64 24, i8* %t563)
  %t565 = bitcast i8* %t564 to { i8*, i64, i64 }*
  %t566 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t565, i32 0, i32 0
  store i8* null, i8** %t566
  %t567 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t565, i32 0, i32 1
  store i64 0, i64* %t567
  %t568 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t565, i32 0, i32 2
  store i64 0, i64* %t568
  store i8* %t564, i8** %t4
  br label %list_cow_done_808
list_cow_check_807:
  %t569 = getelementptr inbounds i8, i8* %t561, i64 -16
  %t570 = bitcast i8* %t569 to i64*
  %t571 = load atomic i64, i64* %t570 seq_cst, align 8
  %t572 = icmp eq i64 %t571, 1
  br i1 %t572, label %list_cow_done_808, label %list_cow_clone_809
list_cow_clone_809:
  %t573 = bitcast i8* %t561 to { i8*, i64, i64 }*
  %t574 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t573, i32 0, i32 0
  %t575 = load i8*, i8** %t574
  %t576 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t573, i32 0, i32 1
  %t577 = load i64, i64* %t576
  %t578 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t573, i32 0, i32 2
  %t579 = load i64, i64* %t578
  %t580 = bitcast void (i8*)* @list_release_u8 to i8*
  %t581 = call i8* @star_rc_alloc(i64 24, i8* %t580)
  %t582 = bitcast i8* %t581 to { i8*, i64, i64 }*
  %t583 = mul i64 %t579, %t560
  %t584 = call i8* @malloc(i64 %t583)
  %t585 = bitcast i8* %t584 to i8*
  %t586 = icmp sgt i64 %t577, 0
  br i1 %t586, label %list_cow_copy_810, label %list_cow_after_copy_811
list_cow_copy_810:
  %t587 = mul i64 %t577, %t560
  %t588 = bitcast i8* %t575 to i8*
  call i8* @memcpy(i8* %t584, i8* %t588, i64 %t587)
  br label %list_cow_after_copy_811
list_cow_after_copy_811:
  %t589 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t582, i32 0, i32 0
  store i8* %t585, i8** %t589
  %t590 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t582, i32 0, i32 1
  store i64 %t577, i64* %t590
  %t591 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t582, i32 0, i32 2
  store i64 %t579, i64* %t591
  call void @star_rc_release(i8* %t561)
  store i8* %t581, i8** %t4
  br label %list_cow_done_808
list_cow_done_808:
  %t592 = load i8*, i8** %t4
  %t593 = bitcast i8* %t592 to { i8*, i64, i64 }*
  %t594 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t593, i32 0, i32 0
  %t595 = load i8*, i8** %t594
  %t596 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t593, i32 0, i32 1
  %t597 = load i64, i64* %t596
  %t598 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t593, i32 0, i32 2
  %t599 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t550, i32 0, i32 0
  %t600 = load i32, i32* %t599
  %t601 = trunc i32 %t600 to i8
  %t602 = load i64, i64* %t598
  %t603 = load i8*, i8** %t594
  %t604 = load i64, i64* %t596
  %t605 = icmp sge i64 %t604, %t602
  br i1 %t605, label %list_push_grow_812, label %list_push_store_813
list_push_grow_812:
  %t606 = mul i64 %t602, 2
  %t607 = icmp sgt i64 %t606, 0
  %t608 = select i1 %t607, i64 %t606, i64 1
  %t609 = getelementptr i8, i8* null, i32 1
  %t610 = ptrtoint i8* %t609 to i64
  %t611 = mul i64 %t608, %t610
  %t612 = call i8* @malloc(i64 %t611)
  %t613 = bitcast i8* %t612 to i8*
  %t614 = icmp sgt i64 %t602, 0
  br i1 %t614, label %list_push_copy_814, label %list_push_after_copy_815
list_push_copy_814:
  %t615 = mul i64 %t604, %t610
  %t616 = bitcast i8* %t603 to i8*
  call i8* @memcpy(i8* %t612, i8* %t616, i64 %t615)
  call void @free(i8* %t616)
  br label %list_push_after_copy_815
list_push_after_copy_815:
  store i8* %t613, i8** %t594
  store i64 %t608, i64* %t598
  br label %list_push_store_813
list_push_store_813:
  %t617 = load i8*, i8** %t594
  %t618 = getelementptr inbounds i8, i8* %t617, i64 %t604
  store i8 %t601, i8* %t618
  %t619 = add i64 %t604, 1
  store i64 %t619, i64* %t596
  %t620 = getelementptr i8, i8* null, i32 1
  %t621 = ptrtoint i8* %t620 to i64
  %t622 = load i8*, i8** %t4
  %t623 = icmp eq i8* %t622, null
  br i1 %t623, label %list_cow_alloc_816, label %list_cow_check_817
list_cow_alloc_816:
  %t624 = bitcast void (i8*)* @list_release_u8 to i8*
  %t625 = call i8* @star_rc_alloc(i64 24, i8* %t624)
  %t626 = bitcast i8* %t625 to { i8*, i64, i64 }*
  %t627 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t626, i32 0, i32 0
  store i8* null, i8** %t627
  %t628 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t626, i32 0, i32 1
  store i64 0, i64* %t628
  %t629 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t626, i32 0, i32 2
  store i64 0, i64* %t629
  store i8* %t625, i8** %t4
  br label %list_cow_done_818
list_cow_check_817:
  %t630 = getelementptr inbounds i8, i8* %t622, i64 -16
  %t631 = bitcast i8* %t630 to i64*
  %t632 = load atomic i64, i64* %t631 seq_cst, align 8
  %t633 = icmp eq i64 %t632, 1
  br i1 %t633, label %list_cow_done_818, label %list_cow_clone_819
list_cow_clone_819:
  %t634 = bitcast i8* %t622 to { i8*, i64, i64 }*
  %t635 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t634, i32 0, i32 0
  %t636 = load i8*, i8** %t635
  %t637 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t634, i32 0, i32 1
  %t638 = load i64, i64* %t637
  %t639 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t634, i32 0, i32 2
  %t640 = load i64, i64* %t639
  %t641 = bitcast void (i8*)* @list_release_u8 to i8*
  %t642 = call i8* @star_rc_alloc(i64 24, i8* %t641)
  %t643 = bitcast i8* %t642 to { i8*, i64, i64 }*
  %t644 = mul i64 %t640, %t621
  %t645 = call i8* @malloc(i64 %t644)
  %t646 = bitcast i8* %t645 to i8*
  %t647 = icmp sgt i64 %t638, 0
  br i1 %t647, label %list_cow_copy_820, label %list_cow_after_copy_821
list_cow_copy_820:
  %t648 = mul i64 %t638, %t621
  %t649 = bitcast i8* %t636 to i8*
  call i8* @memcpy(i8* %t645, i8* %t649, i64 %t648)
  br label %list_cow_after_copy_821
list_cow_after_copy_821:
  %t650 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t643, i32 0, i32 0
  store i8* %t646, i8** %t650
  %t651 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t643, i32 0, i32 1
  store i64 %t638, i64* %t651
  %t652 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t643, i32 0, i32 2
  store i64 %t640, i64* %t652
  call void @star_rc_release(i8* %t622)
  store i8* %t642, i8** %t4
  br label %list_cow_done_818
list_cow_done_818:
  %t653 = load i8*, i8** %t4
  %t654 = bitcast i8* %t653 to { i8*, i64, i64 }*
  %t655 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t654, i32 0, i32 0
  %t656 = load i8*, i8** %t655
  %t657 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t654, i32 0, i32 1
  %t658 = load i64, i64* %t657
  %t659 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t654, i32 0, i32 2
  %t660 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t550, i32 0, i32 1
  %t661 = load i32, i32* %t660
  %t662 = trunc i32 %t661 to i8
  %t663 = load i64, i64* %t659
  %t664 = load i8*, i8** %t655
  %t665 = load i64, i64* %t657
  %t666 = icmp sge i64 %t665, %t663
  br i1 %t666, label %list_push_grow_822, label %list_push_store_823
list_push_grow_822:
  %t667 = mul i64 %t663, 2
  %t668 = icmp sgt i64 %t667, 0
  %t669 = select i1 %t668, i64 %t667, i64 1
  %t670 = getelementptr i8, i8* null, i32 1
  %t671 = ptrtoint i8* %t670 to i64
  %t672 = mul i64 %t669, %t671
  %t673 = call i8* @malloc(i64 %t672)
  %t674 = bitcast i8* %t673 to i8*
  %t675 = icmp sgt i64 %t663, 0
  br i1 %t675, label %list_push_copy_824, label %list_push_after_copy_825
list_push_copy_824:
  %t676 = mul i64 %t665, %t671
  %t677 = bitcast i8* %t664 to i8*
  call i8* @memcpy(i8* %t673, i8* %t677, i64 %t676)
  call void @free(i8* %t677)
  br label %list_push_after_copy_825
list_push_after_copy_825:
  store i8* %t674, i8** %t655
  store i64 %t669, i64* %t659
  br label %list_push_store_823
list_push_store_823:
  %t678 = load i8*, i8** %t655
  %t679 = getelementptr inbounds i8, i8* %t678, i64 %t665
  store i8 %t662, i8* %t679
  %t680 = add i64 %t665, 1
  store i64 %t680, i64* %t657
  %t681 = getelementptr i8, i8* null, i32 1
  %t682 = ptrtoint i8* %t681 to i64
  %t683 = load i8*, i8** %t4
  %t684 = icmp eq i8* %t683, null
  br i1 %t684, label %list_cow_alloc_826, label %list_cow_check_827
list_cow_alloc_826:
  %t685 = bitcast void (i8*)* @list_release_u8 to i8*
  %t686 = call i8* @star_rc_alloc(i64 24, i8* %t685)
  %t687 = bitcast i8* %t686 to { i8*, i64, i64 }*
  %t688 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t687, i32 0, i32 0
  store i8* null, i8** %t688
  %t689 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t687, i32 0, i32 1
  store i64 0, i64* %t689
  %t690 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t687, i32 0, i32 2
  store i64 0, i64* %t690
  store i8* %t686, i8** %t4
  br label %list_cow_done_828
list_cow_check_827:
  %t691 = getelementptr inbounds i8, i8* %t683, i64 -16
  %t692 = bitcast i8* %t691 to i64*
  %t693 = load atomic i64, i64* %t692 seq_cst, align 8
  %t694 = icmp eq i64 %t693, 1
  br i1 %t694, label %list_cow_done_828, label %list_cow_clone_829
list_cow_clone_829:
  %t695 = bitcast i8* %t683 to { i8*, i64, i64 }*
  %t696 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t695, i32 0, i32 0
  %t697 = load i8*, i8** %t696
  %t698 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t695, i32 0, i32 1
  %t699 = load i64, i64* %t698
  %t700 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t695, i32 0, i32 2
  %t701 = load i64, i64* %t700
  %t702 = bitcast void (i8*)* @list_release_u8 to i8*
  %t703 = call i8* @star_rc_alloc(i64 24, i8* %t702)
  %t704 = bitcast i8* %t703 to { i8*, i64, i64 }*
  %t705 = mul i64 %t701, %t682
  %t706 = call i8* @malloc(i64 %t705)
  %t707 = bitcast i8* %t706 to i8*
  %t708 = icmp sgt i64 %t699, 0
  br i1 %t708, label %list_cow_copy_830, label %list_cow_after_copy_831
list_cow_copy_830:
  %t709 = mul i64 %t699, %t682
  %t710 = bitcast i8* %t697 to i8*
  call i8* @memcpy(i8* %t706, i8* %t710, i64 %t709)
  br label %list_cow_after_copy_831
list_cow_after_copy_831:
  %t711 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t704, i32 0, i32 0
  store i8* %t707, i8** %t711
  %t712 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t704, i32 0, i32 1
  store i64 %t699, i64* %t712
  %t713 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t704, i32 0, i32 2
  store i64 %t701, i64* %t713
  call void @star_rc_release(i8* %t683)
  store i8* %t703, i8** %t4
  br label %list_cow_done_828
list_cow_done_828:
  %t714 = load i8*, i8** %t4
  %t715 = bitcast i8* %t714 to { i8*, i64, i64 }*
  %t716 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t715, i32 0, i32 0
  %t717 = load i8*, i8** %t716
  %t718 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t715, i32 0, i32 1
  %t719 = load i64, i64* %t718
  %t720 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t715, i32 0, i32 2
  %t721 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t550, i32 0, i32 2
  %t722 = load i32, i32* %t721
  %t723 = trunc i32 %t722 to i8
  %t724 = load i64, i64* %t720
  %t725 = load i8*, i8** %t716
  %t726 = load i64, i64* %t718
  %t727 = icmp sge i64 %t726, %t724
  br i1 %t727, label %list_push_grow_832, label %list_push_store_833
list_push_grow_832:
  %t728 = mul i64 %t724, 2
  %t729 = icmp sgt i64 %t728, 0
  %t730 = select i1 %t729, i64 %t728, i64 1
  %t731 = getelementptr i8, i8* null, i32 1
  %t732 = ptrtoint i8* %t731 to i64
  %t733 = mul i64 %t730, %t732
  %t734 = call i8* @malloc(i64 %t733)
  %t735 = bitcast i8* %t734 to i8*
  %t736 = icmp sgt i64 %t724, 0
  br i1 %t736, label %list_push_copy_834, label %list_push_after_copy_835
list_push_copy_834:
  %t737 = mul i64 %t726, %t732
  %t738 = bitcast i8* %t725 to i8*
  call i8* @memcpy(i8* %t734, i8* %t738, i64 %t737)
  call void @free(i8* %t738)
  br label %list_push_after_copy_835
list_push_after_copy_835:
  store i8* %t735, i8** %t716
  store i64 %t730, i64* %t720
  br label %list_push_store_833
list_push_store_833:
  %t739 = load i8*, i8** %t716
  %t740 = getelementptr inbounds i8, i8* %t739, i64 %t726
  store i8 %t723, i8* %t740
  %t741 = add i64 %t726, 1
  store i64 %t741, i64* %t718
  %t742 = getelementptr i8, i8* null, i32 1
  %t743 = ptrtoint i8* %t742 to i64
  %t744 = load i8*, i8** %t4
  %t745 = icmp eq i8* %t744, null
  br i1 %t745, label %list_cow_alloc_836, label %list_cow_check_837
list_cow_alloc_836:
  %t746 = bitcast void (i8*)* @list_release_u8 to i8*
  %t747 = call i8* @star_rc_alloc(i64 24, i8* %t746)
  %t748 = bitcast i8* %t747 to { i8*, i64, i64 }*
  %t749 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t748, i32 0, i32 0
  store i8* null, i8** %t749
  %t750 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t748, i32 0, i32 1
  store i64 0, i64* %t750
  %t751 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t748, i32 0, i32 2
  store i64 0, i64* %t751
  store i8* %t747, i8** %t4
  br label %list_cow_done_838
list_cow_check_837:
  %t752 = getelementptr inbounds i8, i8* %t744, i64 -16
  %t753 = bitcast i8* %t752 to i64*
  %t754 = load atomic i64, i64* %t753 seq_cst, align 8
  %t755 = icmp eq i64 %t754, 1
  br i1 %t755, label %list_cow_done_838, label %list_cow_clone_839
list_cow_clone_839:
  %t756 = bitcast i8* %t744 to { i8*, i64, i64 }*
  %t757 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t756, i32 0, i32 0
  %t758 = load i8*, i8** %t757
  %t759 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t756, i32 0, i32 1
  %t760 = load i64, i64* %t759
  %t761 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t756, i32 0, i32 2
  %t762 = load i64, i64* %t761
  %t763 = bitcast void (i8*)* @list_release_u8 to i8*
  %t764 = call i8* @star_rc_alloc(i64 24, i8* %t763)
  %t765 = bitcast i8* %t764 to { i8*, i64, i64 }*
  %t766 = mul i64 %t762, %t743
  %t767 = call i8* @malloc(i64 %t766)
  %t768 = bitcast i8* %t767 to i8*
  %t769 = icmp sgt i64 %t760, 0
  br i1 %t769, label %list_cow_copy_840, label %list_cow_after_copy_841
list_cow_copy_840:
  %t770 = mul i64 %t760, %t743
  %t771 = bitcast i8* %t758 to i8*
  call i8* @memcpy(i8* %t767, i8* %t771, i64 %t770)
  br label %list_cow_after_copy_841
list_cow_after_copy_841:
  %t772 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t765, i32 0, i32 0
  store i8* %t768, i8** %t772
  %t773 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t765, i32 0, i32 1
  store i64 %t760, i64* %t773
  %t774 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t765, i32 0, i32 2
  store i64 %t762, i64* %t774
  call void @star_rc_release(i8* %t744)
  store i8* %t764, i8** %t4
  br label %list_cow_done_838
list_cow_done_838:
  %t775 = load i8*, i8** %t4
  %t776 = bitcast i8* %t775 to { i8*, i64, i64 }*
  %t777 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t776, i32 0, i32 0
  %t778 = load i8*, i8** %t777
  %t779 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t776, i32 0, i32 1
  %t780 = load i64, i64* %t779
  %t781 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t776, i32 0, i32 2
  %t782 = trunc i32 255 to i8
  %t783 = load i64, i64* %t781
  %t784 = load i8*, i8** %t777
  %t785 = load i64, i64* %t779
  %t786 = icmp sge i64 %t785, %t783
  br i1 %t786, label %list_push_grow_842, label %list_push_store_843
list_push_grow_842:
  %t787 = mul i64 %t783, 2
  %t788 = icmp sgt i64 %t787, 0
  %t789 = select i1 %t788, i64 %t787, i64 1
  %t790 = getelementptr i8, i8* null, i32 1
  %t791 = ptrtoint i8* %t790 to i64
  %t792 = mul i64 %t789, %t791
  %t793 = call i8* @malloc(i64 %t792)
  %t794 = bitcast i8* %t793 to i8*
  %t795 = icmp sgt i64 %t783, 0
  br i1 %t795, label %list_push_copy_844, label %list_push_after_copy_845
list_push_copy_844:
  %t796 = mul i64 %t785, %t791
  %t797 = bitcast i8* %t784 to i8*
  call i8* @memcpy(i8* %t793, i8* %t797, i64 %t796)
  call void @free(i8* %t797)
  br label %list_push_after_copy_845
list_push_after_copy_845:
  store i8* %t794, i8** %t777
  store i64 %t789, i64* %t781
  br label %list_push_store_843
list_push_store_843:
  %t798 = load i8*, i8** %t777
  %t799 = getelementptr inbounds i8, i8* %t798, i64 %t785
  store i8 %t782, i8* %t799
  %t800 = add i64 %t785, 1
  store i64 %t800, i64* %t779
  br label %if_end_803
if_else_802:
  br label %if_end_803
if_end_803:
  %t801 = load i32, i32* %t519
  %t802 = add i32 %t801, 1
  store i32 %t802, i32* %t519
  br label %while_cond_794
while_else_796:
  br label %while_end_797
while_end_797:
  %t803 = load i32, i32* %t405
  %t804 = add i32 %t803, 1
  store i32 %t804, i32* %t405
  br label %while_cond_780
while_else_782:
  br label %while_end_783
while_end_783:
  %t806 = load i8*, i8** %t4
  %t807 = load i8*, i8** %t4
  call void @star_rc_retain(i8* %t807)
  %t808 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t805, i32 0, i32 0
  store i8* %t806, i8** %t808
  %t809 = load i8*, i8** %t5
  %t810 = load i8*, i8** %t5
  call void @star_rc_retain(i8* %t810)
  %t811 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t805, i32 0, i32 1
  store i8* %t809, i8** %t811
  %t812 = load { i8*, i8* }, { i8*, i8* }* %t805
  %t813 = load i8*, i8** %t5
  call void @star_rc_release(i8* %t813)
  %t814 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t814)
  %t815 = load i8*, i8** %t3
  call void @star_rc_release(i8* %t815)
  ret { i8*, i8* } %t812
}

define i8* @render_sprites(i8* %zbuf, float %px, float %py, float %angle, i8* %enemies, i8* %projectiles, i8* %pickups, %sprites__SpriteSet %spriteset) {
entry:
  %t0 = alloca i8*
  %t1 = alloca float
  %t2 = alloca float
  %t3 = alloca float
  %t4 = alloca i8*
  %t5 = alloca i8*
  %t6 = alloca i8*
  %t7 = alloca %sprites__SpriteSet
  %t8 = alloca i8*
  %t9 = alloca i8*
  %t10 = alloca i32
  %t23 = alloca %Enemy
  %t41 = alloca float
  %t46 = alloca float
  %t51 = alloca float
  %t60 = alloca i32
  %t109 = alloca %SpriteDraw
  %t153 = alloca %Projectile
  %t171 = alloca float
  %t176 = alloca float
  %t181 = alloca float
  %t230 = alloca %SpriteDraw
  %t273 = alloca %Pickup
  %t292 = alloca float
  %t297 = alloca float
  %t302 = alloca float
  %t311 = alloca i32
  %t356 = alloca %SpriteDraw
  %t388 = alloca float
  %t391 = alloca float
  %t394 = alloca float
  %t399 = alloca float
  %t403 = alloca float
  %t412 = alloca i32
  %t425 = alloca %SpriteDraw
  %t441 = alloca float
  %t446 = alloca float
  %t451 = alloca float
  %t461 = alloca float
  %t474 = alloca float
  %t482 = alloca float
  %t487 = alloca float
  %t489 = alloca i32
  %t497 = alloca i32
  %t504 = alloca i32
  %t511 = alloca i32
  %t517 = alloca i8*
  %t532 = alloca float
  %t539 = alloca i32
  %t544 = alloca i32
  %t577 = alloca i32
  %t593 = alloca i32
  %t609 = alloca i32
  %t615 = alloca i8
  %t635 = alloca i8
  %t651 = alloca i8
  %t668 = alloca i8
  %t685 = alloca { i32, i32, i32 }
  store i8* %zbuf, i8** %t0
  store float %px, float* %t1
  store float %py, float* %t2
  store float %angle, float* %t3
  store i8* %enemies, i8** %t4
  store i8* %projectiles, i8** %t5
  store i8* %pickups, i8** %t6
  store %sprites__SpriteSet %spriteset, %sprites__SpriteSet* %t7
  store i8* null, i8** %t8
  store i8* null, i8** %t9
  store i32 0, i32* %t10
  br label %while_cond_846
while_cond_846:
  %t11 = load i32, i32* %t10
  %t12 = load i8*, i8** %t4
  %t13 = icmp eq i8* %t12, null
  br i1 %t13, label %list_read_null_850, label %list_read_real_851
list_read_null_850:
  br label %list_read_end_852
list_read_real_851:
  %t14 = bitcast i8* %t12 to { %Enemy*, i64, i64 }*
  %t15 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t14, i32 0, i32 0
  %t16 = load %Enemy*, %Enemy** %t15
  %t17 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t14, i32 0, i32 1
  %t18 = load i64, i64* %t17
  br label %list_read_end_852
list_read_end_852:
  %t19 = phi %Enemy* [ null, %list_read_null_850 ], [ %t16, %list_read_real_851 ]
  %t20 = phi i64 [ 0, %list_read_null_850 ], [ %t18, %list_read_real_851 ]
  %t21 = trunc i64 %t20 to i32
  %t22 = icmp slt i32 %t11, %t21
  br i1 %t22, label %while_body_847, label %while_else_848
while_body_847:
  %t24 = load i8*, i8** %t4
  %t25 = icmp eq i8* %t24, null
  br i1 %t25, label %list_read_null_853, label %list_read_real_854
list_read_null_853:
  br label %list_read_end_855
list_read_real_854:
  %t26 = bitcast i8* %t24 to { %Enemy*, i64, i64 }*
  %t27 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t26, i32 0, i32 0
  %t28 = load %Enemy*, %Enemy** %t27
  %t29 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t26, i32 0, i32 1
  %t30 = load i64, i64* %t29
  br label %list_read_end_855
list_read_end_855:
  %t31 = phi %Enemy* [ null, %list_read_null_853 ], [ %t28, %list_read_real_854 ]
  %t32 = phi i64 [ 0, %list_read_null_853 ], [ %t30, %list_read_real_854 ]
  %t33 = load i32, i32* %t10
  %t34 = sext i32 %t33 to i64
  %t35 = icmp ult i64 %t34, %t32
  br i1 %t35, label %list_idx_ok_856, label %list_idx_oob_857
list_idx_ok_856:
  %t36 = getelementptr inbounds %Enemy, %Enemy* %t31, i64 %t34
  %t37 = load %Enemy, %Enemy* %t36
  br label %list_idx_end_858
list_idx_oob_857:
  br label %list_idx_end_858
list_idx_end_858:
  %t38 = phi %Enemy [ %t37, %list_idx_ok_856 ], [ zeroinitializer, %list_idx_oob_857 ]
  store %Enemy %t38, %Enemy* %t23
  %t39 = getelementptr inbounds %Enemy, %Enemy* %t23, i32 0, i32 4
  %t40 = load i1, i1* %t39
  br i1 %t40, label %if_then_859, label %if_else_860
if_then_859:
  %t42 = getelementptr inbounds %Enemy, %Enemy* %t23, i32 0, i32 0
  %t43 = load float, float* %t42
  %t44 = load float, float* %t1
  %t45 = fsub float %t43, %t44
  store float %t45, float* %t41
  %t47 = getelementptr inbounds %Enemy, %Enemy* %t23, i32 0, i32 1
  %t48 = load float, float* %t47
  %t49 = load float, float* %t2
  %t50 = fsub float %t48, %t49
  store float %t50, float* %t46
  %t52 = load float, float* %t41
  %t53 = load float, float* %t41
  %t54 = fmul float %t52, %t53
  %t55 = load float, float* %t46
  %t56 = load float, float* %t46
  %t57 = fmul float %t55, %t56
  %t58 = fadd float %t54, %t57
  %t59 = call float @llvm.sqrt.f32(float %t58)
  store float %t59, float* %t51
  %t61 = getelementptr inbounds %Enemy, %Enemy* %t23, i32 0, i32 3
  %t62 = load i32, i32* %t61
  %t63 = icmp eq i32 %t62, 0
  br i1 %t63, label %if_then_862, label %if_else_863
if_then_862:
  br label %if_end_864
if_else_863:
  br label %if_end_864
if_end_864:
  %t64 = phi i32 [ 0, %if_then_862 ], [ 4, %if_else_863 ]
  store i32 %t64, i32* %t60
  %t65 = getelementptr %SpriteDraw, %SpriteDraw* null, i32 1
  %t66 = ptrtoint %SpriteDraw* %t65 to i64
  %t67 = load i8*, i8** %t9
  %t68 = icmp eq i8* %t67, null
  br i1 %t68, label %list_cow_alloc_865, label %list_cow_check_866
list_cow_alloc_865:
  %t73 = bitcast void (i8*)* @list_release_s_SpriteDraw to i8*
  %t74 = call i8* @star_rc_alloc(i64 24, i8* %t73)
  %t75 = bitcast i8* %t74 to { %SpriteDraw*, i64, i64 }*
  %t76 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t75, i32 0, i32 0
  store %SpriteDraw* null, %SpriteDraw** %t76
  %t77 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t75, i32 0, i32 1
  store i64 0, i64* %t77
  %t78 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t75, i32 0, i32 2
  store i64 0, i64* %t78
  store i8* %t74, i8** %t9
  br label %list_cow_done_867
list_cow_check_866:
  %t79 = getelementptr inbounds i8, i8* %t67, i64 -16
  %t80 = bitcast i8* %t79 to i64*
  %t81 = load atomic i64, i64* %t80 seq_cst, align 8
  %t82 = icmp eq i64 %t81, 1
  br i1 %t82, label %list_cow_done_867, label %list_cow_clone_868
list_cow_clone_868:
  %t83 = bitcast i8* %t67 to { %SpriteDraw*, i64, i64 }*
  %t84 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t83, i32 0, i32 0
  %t85 = load %SpriteDraw*, %SpriteDraw** %t84
  %t86 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t83, i32 0, i32 1
  %t87 = load i64, i64* %t86
  %t88 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t83, i32 0, i32 2
  %t89 = load i64, i64* %t88
  %t90 = bitcast void (i8*)* @list_release_s_SpriteDraw to i8*
  %t91 = call i8* @star_rc_alloc(i64 24, i8* %t90)
  %t92 = bitcast i8* %t91 to { %SpriteDraw*, i64, i64 }*
  %t93 = mul i64 %t89, %t66
  %t94 = call i8* @malloc(i64 %t93)
  %t95 = bitcast i8* %t94 to %SpriteDraw*
  %t96 = icmp sgt i64 %t87, 0
  br i1 %t96, label %list_cow_copy_869, label %list_cow_after_copy_870
list_cow_copy_869:
  %t97 = mul i64 %t87, %t66
  %t98 = bitcast %SpriteDraw* %t85 to i8*
  call i8* @memcpy(i8* %t94, i8* %t98, i64 %t97)
  br label %list_cow_after_copy_870
list_cow_after_copy_870:
  %t99 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t92, i32 0, i32 0
  store %SpriteDraw* %t95, %SpriteDraw** %t99
  %t100 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t92, i32 0, i32 1
  store i64 %t87, i64* %t100
  %t101 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t92, i32 0, i32 2
  store i64 %t89, i64* %t101
  call void @star_rc_release(i8* %t67)
  store i8* %t91, i8** %t9
  br label %list_cow_done_867
list_cow_done_867:
  %t102 = load i8*, i8** %t9
  %t103 = bitcast i8* %t102 to { %SpriteDraw*, i64, i64 }*
  %t104 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t103, i32 0, i32 0
  %t105 = load %SpriteDraw*, %SpriteDraw** %t104
  %t106 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t103, i32 0, i32 1
  %t107 = load i64, i64* %t106
  %t108 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t103, i32 0, i32 2
  %t110 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t109, i32 0, i32 0
  %t111 = load float, float* %t51
  store float %t111, float* %t110
  %t112 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t109, i32 0, i32 1
  %t113 = load i32, i32* %t60
  store i32 %t113, i32* %t112
  %t114 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t109, i32 0, i32 2
  %t115 = getelementptr inbounds %Enemy, %Enemy* %t23, i32 0, i32 0
  %t116 = load float, float* %t115
  store float %t116, float* %t114
  %t117 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t109, i32 0, i32 3
  %t118 = getelementptr inbounds %Enemy, %Enemy* %t23, i32 0, i32 1
  %t119 = load float, float* %t118
  store float %t119, float* %t117
  %t120 = load %SpriteDraw, %SpriteDraw* %t109
  %t121 = load i64, i64* %t108
  %t122 = load %SpriteDraw*, %SpriteDraw** %t104
  %t123 = load i64, i64* %t106
  %t124 = icmp sge i64 %t123, %t121
  br i1 %t124, label %list_push_grow_871, label %list_push_store_872
list_push_grow_871:
  %t125 = mul i64 %t121, 2
  %t126 = icmp sgt i64 %t125, 0
  %t127 = select i1 %t126, i64 %t125, i64 1
  %t128 = getelementptr %SpriteDraw, %SpriteDraw* null, i32 1
  %t129 = ptrtoint %SpriteDraw* %t128 to i64
  %t130 = mul i64 %t127, %t129
  %t131 = call i8* @malloc(i64 %t130)
  %t132 = bitcast i8* %t131 to %SpriteDraw*
  %t133 = icmp sgt i64 %t121, 0
  br i1 %t133, label %list_push_copy_873, label %list_push_after_copy_874
list_push_copy_873:
  %t134 = mul i64 %t123, %t129
  %t135 = bitcast %SpriteDraw* %t122 to i8*
  call i8* @memcpy(i8* %t131, i8* %t135, i64 %t134)
  call void @free(i8* %t135)
  br label %list_push_after_copy_874
list_push_after_copy_874:
  store %SpriteDraw* %t132, %SpriteDraw** %t104
  store i64 %t127, i64* %t108
  br label %list_push_store_872
list_push_store_872:
  %t136 = load %SpriteDraw*, %SpriteDraw** %t104
  %t137 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t136, i64 %t123
  store %SpriteDraw %t120, %SpriteDraw* %t137
  %t138 = add i64 %t123, 1
  store i64 %t138, i64* %t106
  br label %if_end_861
if_else_860:
  br label %if_end_861
if_end_861:
  %t139 = load i32, i32* %t10
  %t140 = add i32 %t139, 1
  store i32 %t140, i32* %t10
  br label %while_cond_846
while_else_848:
  br label %while_end_849
while_end_849:
  store i32 0, i32* %t10
  br label %while_cond_875
while_cond_875:
  %t141 = load i32, i32* %t10
  %t142 = load i8*, i8** %t5
  %t143 = icmp eq i8* %t142, null
  br i1 %t143, label %list_read_null_879, label %list_read_real_880
list_read_null_879:
  br label %list_read_end_881
list_read_real_880:
  %t144 = bitcast i8* %t142 to { %Projectile*, i64, i64 }*
  %t145 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t144, i32 0, i32 0
  %t146 = load %Projectile*, %Projectile** %t145
  %t147 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t144, i32 0, i32 1
  %t148 = load i64, i64* %t147
  br label %list_read_end_881
list_read_end_881:
  %t149 = phi %Projectile* [ null, %list_read_null_879 ], [ %t146, %list_read_real_880 ]
  %t150 = phi i64 [ 0, %list_read_null_879 ], [ %t148, %list_read_real_880 ]
  %t151 = trunc i64 %t150 to i32
  %t152 = icmp slt i32 %t141, %t151
  br i1 %t152, label %while_body_876, label %while_else_877
while_body_876:
  %t154 = load i8*, i8** %t5
  %t155 = icmp eq i8* %t154, null
  br i1 %t155, label %list_read_null_882, label %list_read_real_883
list_read_null_882:
  br label %list_read_end_884
list_read_real_883:
  %t156 = bitcast i8* %t154 to { %Projectile*, i64, i64 }*
  %t157 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t156, i32 0, i32 0
  %t158 = load %Projectile*, %Projectile** %t157
  %t159 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t156, i32 0, i32 1
  %t160 = load i64, i64* %t159
  br label %list_read_end_884
list_read_end_884:
  %t161 = phi %Projectile* [ null, %list_read_null_882 ], [ %t158, %list_read_real_883 ]
  %t162 = phi i64 [ 0, %list_read_null_882 ], [ %t160, %list_read_real_883 ]
  %t163 = load i32, i32* %t10
  %t164 = sext i32 %t163 to i64
  %t165 = icmp ult i64 %t164, %t162
  br i1 %t165, label %list_idx_ok_885, label %list_idx_oob_886
list_idx_ok_885:
  %t166 = getelementptr inbounds %Projectile, %Projectile* %t161, i64 %t164
  %t167 = load %Projectile, %Projectile* %t166
  br label %list_idx_end_887
list_idx_oob_886:
  br label %list_idx_end_887
list_idx_end_887:
  %t168 = phi %Projectile [ %t167, %list_idx_ok_885 ], [ zeroinitializer, %list_idx_oob_886 ]
  store %Projectile %t168, %Projectile* %t153
  %t169 = getelementptr inbounds %Projectile, %Projectile* %t153, i32 0, i32 5
  %t170 = load i1, i1* %t169
  br i1 %t170, label %if_then_888, label %if_else_889
if_then_888:
  %t172 = getelementptr inbounds %Projectile, %Projectile* %t153, i32 0, i32 0
  %t173 = load float, float* %t172
  %t174 = load float, float* %t1
  %t175 = fsub float %t173, %t174
  store float %t175, float* %t171
  %t177 = getelementptr inbounds %Projectile, %Projectile* %t153, i32 0, i32 1
  %t178 = load float, float* %t177
  %t179 = load float, float* %t2
  %t180 = fsub float %t178, %t179
  store float %t180, float* %t176
  %t182 = load float, float* %t171
  %t183 = load float, float* %t171
  %t184 = fmul float %t182, %t183
  %t185 = load float, float* %t176
  %t186 = load float, float* %t176
  %t187 = fmul float %t185, %t186
  %t188 = fadd float %t184, %t187
  %t189 = call float @llvm.sqrt.f32(float %t188)
  store float %t189, float* %t181
  %t190 = getelementptr %SpriteDraw, %SpriteDraw* null, i32 1
  %t191 = ptrtoint %SpriteDraw* %t190 to i64
  %t192 = load i8*, i8** %t9
  %t193 = icmp eq i8* %t192, null
  br i1 %t193, label %list_cow_alloc_891, label %list_cow_check_892
list_cow_alloc_891:
  %t194 = bitcast void (i8*)* @list_release_s_SpriteDraw to i8*
  %t195 = call i8* @star_rc_alloc(i64 24, i8* %t194)
  %t196 = bitcast i8* %t195 to { %SpriteDraw*, i64, i64 }*
  %t197 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t196, i32 0, i32 0
  store %SpriteDraw* null, %SpriteDraw** %t197
  %t198 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t196, i32 0, i32 1
  store i64 0, i64* %t198
  %t199 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t196, i32 0, i32 2
  store i64 0, i64* %t199
  store i8* %t195, i8** %t9
  br label %list_cow_done_893
list_cow_check_892:
  %t200 = getelementptr inbounds i8, i8* %t192, i64 -16
  %t201 = bitcast i8* %t200 to i64*
  %t202 = load atomic i64, i64* %t201 seq_cst, align 8
  %t203 = icmp eq i64 %t202, 1
  br i1 %t203, label %list_cow_done_893, label %list_cow_clone_894
list_cow_clone_894:
  %t204 = bitcast i8* %t192 to { %SpriteDraw*, i64, i64 }*
  %t205 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t204, i32 0, i32 0
  %t206 = load %SpriteDraw*, %SpriteDraw** %t205
  %t207 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t204, i32 0, i32 1
  %t208 = load i64, i64* %t207
  %t209 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t204, i32 0, i32 2
  %t210 = load i64, i64* %t209
  %t211 = bitcast void (i8*)* @list_release_s_SpriteDraw to i8*
  %t212 = call i8* @star_rc_alloc(i64 24, i8* %t211)
  %t213 = bitcast i8* %t212 to { %SpriteDraw*, i64, i64 }*
  %t214 = mul i64 %t210, %t191
  %t215 = call i8* @malloc(i64 %t214)
  %t216 = bitcast i8* %t215 to %SpriteDraw*
  %t217 = icmp sgt i64 %t208, 0
  br i1 %t217, label %list_cow_copy_895, label %list_cow_after_copy_896
list_cow_copy_895:
  %t218 = mul i64 %t208, %t191
  %t219 = bitcast %SpriteDraw* %t206 to i8*
  call i8* @memcpy(i8* %t215, i8* %t219, i64 %t218)
  br label %list_cow_after_copy_896
list_cow_after_copy_896:
  %t220 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t213, i32 0, i32 0
  store %SpriteDraw* %t216, %SpriteDraw** %t220
  %t221 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t213, i32 0, i32 1
  store i64 %t208, i64* %t221
  %t222 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t213, i32 0, i32 2
  store i64 %t210, i64* %t222
  call void @star_rc_release(i8* %t192)
  store i8* %t212, i8** %t9
  br label %list_cow_done_893
list_cow_done_893:
  %t223 = load i8*, i8** %t9
  %t224 = bitcast i8* %t223 to { %SpriteDraw*, i64, i64 }*
  %t225 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t224, i32 0, i32 0
  %t226 = load %SpriteDraw*, %SpriteDraw** %t225
  %t227 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t224, i32 0, i32 1
  %t228 = load i64, i64* %t227
  %t229 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t224, i32 0, i32 2
  %t231 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t230, i32 0, i32 0
  %t232 = load float, float* %t181
  store float %t232, float* %t231
  %t233 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t230, i32 0, i32 1
  store i32 1, i32* %t233
  %t234 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t230, i32 0, i32 2
  %t235 = getelementptr inbounds %Projectile, %Projectile* %t153, i32 0, i32 0
  %t236 = load float, float* %t235
  store float %t236, float* %t234
  %t237 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t230, i32 0, i32 3
  %t238 = getelementptr inbounds %Projectile, %Projectile* %t153, i32 0, i32 1
  %t239 = load float, float* %t238
  store float %t239, float* %t237
  %t240 = load %SpriteDraw, %SpriteDraw* %t230
  %t241 = load i64, i64* %t229
  %t242 = load %SpriteDraw*, %SpriteDraw** %t225
  %t243 = load i64, i64* %t227
  %t244 = icmp sge i64 %t243, %t241
  br i1 %t244, label %list_push_grow_897, label %list_push_store_898
list_push_grow_897:
  %t245 = mul i64 %t241, 2
  %t246 = icmp sgt i64 %t245, 0
  %t247 = select i1 %t246, i64 %t245, i64 1
  %t248 = getelementptr %SpriteDraw, %SpriteDraw* null, i32 1
  %t249 = ptrtoint %SpriteDraw* %t248 to i64
  %t250 = mul i64 %t247, %t249
  %t251 = call i8* @malloc(i64 %t250)
  %t252 = bitcast i8* %t251 to %SpriteDraw*
  %t253 = icmp sgt i64 %t241, 0
  br i1 %t253, label %list_push_copy_899, label %list_push_after_copy_900
list_push_copy_899:
  %t254 = mul i64 %t243, %t249
  %t255 = bitcast %SpriteDraw* %t242 to i8*
  call i8* @memcpy(i8* %t251, i8* %t255, i64 %t254)
  call void @free(i8* %t255)
  br label %list_push_after_copy_900
list_push_after_copy_900:
  store %SpriteDraw* %t252, %SpriteDraw** %t225
  store i64 %t247, i64* %t229
  br label %list_push_store_898
list_push_store_898:
  %t256 = load %SpriteDraw*, %SpriteDraw** %t225
  %t257 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t256, i64 %t243
  store %SpriteDraw %t240, %SpriteDraw* %t257
  %t258 = add i64 %t243, 1
  store i64 %t258, i64* %t227
  br label %if_end_890
if_else_889:
  br label %if_end_890
if_end_890:
  %t259 = load i32, i32* %t10
  %t260 = add i32 %t259, 1
  store i32 %t260, i32* %t10
  br label %while_cond_875
while_else_877:
  br label %while_end_878
while_end_878:
  store i32 0, i32* %t10
  br label %while_cond_901
while_cond_901:
  %t261 = load i32, i32* %t10
  %t262 = load i8*, i8** %t6
  %t263 = icmp eq i8* %t262, null
  br i1 %t263, label %list_read_null_905, label %list_read_real_906
list_read_null_905:
  br label %list_read_end_907
list_read_real_906:
  %t264 = bitcast i8* %t262 to { %Pickup*, i64, i64 }*
  %t265 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t264, i32 0, i32 0
  %t266 = load %Pickup*, %Pickup** %t265
  %t267 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t264, i32 0, i32 1
  %t268 = load i64, i64* %t267
  br label %list_read_end_907
list_read_end_907:
  %t269 = phi %Pickup* [ null, %list_read_null_905 ], [ %t266, %list_read_real_906 ]
  %t270 = phi i64 [ 0, %list_read_null_905 ], [ %t268, %list_read_real_906 ]
  %t271 = trunc i64 %t270 to i32
  %t272 = icmp slt i32 %t261, %t271
  br i1 %t272, label %while_body_902, label %while_else_903
while_body_902:
  %t274 = load i8*, i8** %t6
  %t275 = icmp eq i8* %t274, null
  br i1 %t275, label %list_read_null_908, label %list_read_real_909
list_read_null_908:
  br label %list_read_end_910
list_read_real_909:
  %t276 = bitcast i8* %t274 to { %Pickup*, i64, i64 }*
  %t277 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t276, i32 0, i32 0
  %t278 = load %Pickup*, %Pickup** %t277
  %t279 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t276, i32 0, i32 1
  %t280 = load i64, i64* %t279
  br label %list_read_end_910
list_read_end_910:
  %t281 = phi %Pickup* [ null, %list_read_null_908 ], [ %t278, %list_read_real_909 ]
  %t282 = phi i64 [ 0, %list_read_null_908 ], [ %t280, %list_read_real_909 ]
  %t283 = load i32, i32* %t10
  %t284 = sext i32 %t283 to i64
  %t285 = icmp ult i64 %t284, %t282
  br i1 %t285, label %list_idx_ok_911, label %list_idx_oob_912
list_idx_ok_911:
  %t286 = getelementptr inbounds %Pickup, %Pickup* %t281, i64 %t284
  %t287 = load %Pickup, %Pickup* %t286
  br label %list_idx_end_913
list_idx_oob_912:
  br label %list_idx_end_913
list_idx_end_913:
  %t288 = phi %Pickup [ %t287, %list_idx_ok_911 ], [ zeroinitializer, %list_idx_oob_912 ]
  store %Pickup %t288, %Pickup* %t273
  %t289 = getelementptr inbounds %Pickup, %Pickup* %t273, i32 0, i32 3
  %t290 = load i1, i1* %t289
  %t291 = xor i1 true, %t290
  br i1 %t291, label %if_then_914, label %if_else_915
if_then_914:
  %t293 = getelementptr inbounds %Pickup, %Pickup* %t273, i32 0, i32 0
  %t294 = load float, float* %t293
  %t295 = load float, float* %t1
  %t296 = fsub float %t294, %t295
  store float %t296, float* %t292
  %t298 = getelementptr inbounds %Pickup, %Pickup* %t273, i32 0, i32 1
  %t299 = load float, float* %t298
  %t300 = load float, float* %t2
  %t301 = fsub float %t299, %t300
  store float %t301, float* %t297
  %t303 = load float, float* %t292
  %t304 = load float, float* %t292
  %t305 = fmul float %t303, %t304
  %t306 = load float, float* %t297
  %t307 = load float, float* %t297
  %t308 = fmul float %t306, %t307
  %t309 = fadd float %t305, %t308
  %t310 = call float @llvm.sqrt.f32(float %t309)
  store float %t310, float* %t302
  %t312 = getelementptr inbounds %Pickup, %Pickup* %t273, i32 0, i32 2
  %t313 = load i32, i32* %t312
  %t314 = icmp eq i32 %t313, 0
  br i1 %t314, label %if_then_917, label %if_else_918
if_then_917:
  br label %if_end_919
if_else_918:
  br label %if_end_919
if_end_919:
  %t315 = phi i32 [ 2, %if_then_917 ], [ 3, %if_else_918 ]
  store i32 %t315, i32* %t311
  %t316 = getelementptr %SpriteDraw, %SpriteDraw* null, i32 1
  %t317 = ptrtoint %SpriteDraw* %t316 to i64
  %t318 = load i8*, i8** %t9
  %t319 = icmp eq i8* %t318, null
  br i1 %t319, label %list_cow_alloc_920, label %list_cow_check_921
list_cow_alloc_920:
  %t320 = bitcast void (i8*)* @list_release_s_SpriteDraw to i8*
  %t321 = call i8* @star_rc_alloc(i64 24, i8* %t320)
  %t322 = bitcast i8* %t321 to { %SpriteDraw*, i64, i64 }*
  %t323 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t322, i32 0, i32 0
  store %SpriteDraw* null, %SpriteDraw** %t323
  %t324 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t322, i32 0, i32 1
  store i64 0, i64* %t324
  %t325 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t322, i32 0, i32 2
  store i64 0, i64* %t325
  store i8* %t321, i8** %t9
  br label %list_cow_done_922
list_cow_check_921:
  %t326 = getelementptr inbounds i8, i8* %t318, i64 -16
  %t327 = bitcast i8* %t326 to i64*
  %t328 = load atomic i64, i64* %t327 seq_cst, align 8
  %t329 = icmp eq i64 %t328, 1
  br i1 %t329, label %list_cow_done_922, label %list_cow_clone_923
list_cow_clone_923:
  %t330 = bitcast i8* %t318 to { %SpriteDraw*, i64, i64 }*
  %t331 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t330, i32 0, i32 0
  %t332 = load %SpriteDraw*, %SpriteDraw** %t331
  %t333 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t330, i32 0, i32 1
  %t334 = load i64, i64* %t333
  %t335 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t330, i32 0, i32 2
  %t336 = load i64, i64* %t335
  %t337 = bitcast void (i8*)* @list_release_s_SpriteDraw to i8*
  %t338 = call i8* @star_rc_alloc(i64 24, i8* %t337)
  %t339 = bitcast i8* %t338 to { %SpriteDraw*, i64, i64 }*
  %t340 = mul i64 %t336, %t317
  %t341 = call i8* @malloc(i64 %t340)
  %t342 = bitcast i8* %t341 to %SpriteDraw*
  %t343 = icmp sgt i64 %t334, 0
  br i1 %t343, label %list_cow_copy_924, label %list_cow_after_copy_925
list_cow_copy_924:
  %t344 = mul i64 %t334, %t317
  %t345 = bitcast %SpriteDraw* %t332 to i8*
  call i8* @memcpy(i8* %t341, i8* %t345, i64 %t344)
  br label %list_cow_after_copy_925
list_cow_after_copy_925:
  %t346 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t339, i32 0, i32 0
  store %SpriteDraw* %t342, %SpriteDraw** %t346
  %t347 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t339, i32 0, i32 1
  store i64 %t334, i64* %t347
  %t348 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t339, i32 0, i32 2
  store i64 %t336, i64* %t348
  call void @star_rc_release(i8* %t318)
  store i8* %t338, i8** %t9
  br label %list_cow_done_922
list_cow_done_922:
  %t349 = load i8*, i8** %t9
  %t350 = bitcast i8* %t349 to { %SpriteDraw*, i64, i64 }*
  %t351 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t350, i32 0, i32 0
  %t352 = load %SpriteDraw*, %SpriteDraw** %t351
  %t353 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t350, i32 0, i32 1
  %t354 = load i64, i64* %t353
  %t355 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t350, i32 0, i32 2
  %t357 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t356, i32 0, i32 0
  %t358 = load float, float* %t302
  store float %t358, float* %t357
  %t359 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t356, i32 0, i32 1
  %t360 = load i32, i32* %t311
  store i32 %t360, i32* %t359
  %t361 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t356, i32 0, i32 2
  %t362 = getelementptr inbounds %Pickup, %Pickup* %t273, i32 0, i32 0
  %t363 = load float, float* %t362
  store float %t363, float* %t361
  %t364 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t356, i32 0, i32 3
  %t365 = getelementptr inbounds %Pickup, %Pickup* %t273, i32 0, i32 1
  %t366 = load float, float* %t365
  store float %t366, float* %t364
  %t367 = load %SpriteDraw, %SpriteDraw* %t356
  %t368 = load i64, i64* %t355
  %t369 = load %SpriteDraw*, %SpriteDraw** %t351
  %t370 = load i64, i64* %t353
  %t371 = icmp sge i64 %t370, %t368
  br i1 %t371, label %list_push_grow_926, label %list_push_store_927
list_push_grow_926:
  %t372 = mul i64 %t368, 2
  %t373 = icmp sgt i64 %t372, 0
  %t374 = select i1 %t373, i64 %t372, i64 1
  %t375 = getelementptr %SpriteDraw, %SpriteDraw* null, i32 1
  %t376 = ptrtoint %SpriteDraw* %t375 to i64
  %t377 = mul i64 %t374, %t376
  %t378 = call i8* @malloc(i64 %t377)
  %t379 = bitcast i8* %t378 to %SpriteDraw*
  %t380 = icmp sgt i64 %t368, 0
  br i1 %t380, label %list_push_copy_928, label %list_push_after_copy_929
list_push_copy_928:
  %t381 = mul i64 %t370, %t376
  %t382 = bitcast %SpriteDraw* %t369 to i8*
  call i8* @memcpy(i8* %t378, i8* %t382, i64 %t381)
  call void @free(i8* %t382)
  br label %list_push_after_copy_929
list_push_after_copy_929:
  store %SpriteDraw* %t379, %SpriteDraw** %t351
  store i64 %t374, i64* %t355
  br label %list_push_store_927
list_push_store_927:
  %t383 = load %SpriteDraw*, %SpriteDraw** %t351
  %t384 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t383, i64 %t370
  store %SpriteDraw %t367, %SpriteDraw* %t384
  %t385 = add i64 %t370, 1
  store i64 %t385, i64* %t353
  br label %if_end_916
if_else_915:
  br label %if_end_916
if_end_916:
  %t386 = load i32, i32* %t10
  %t387 = add i32 %t386, 1
  store i32 %t387, i32* %t10
  br label %while_cond_901
while_else_903:
  br label %while_end_904
while_end_904:
  %t389 = load float, float* %t3
  %t390 = call float @llvm.cos.f32(float %t389)
  store float %t390, float* %t388
  %t392 = load float, float* %t3
  %t393 = call float @llvm.sin.f32(float %t392)
  store float %t393, float* %t391
  %t395 = load float, float* %t3
  %t396 = call float @llvm.sin.f32(float %t395)
  %t397 = fsub float 0.0, %t396
  %t398 = fmul float %t397, 0x3FE51EB860000000
  store float %t398, float* %t394
  %t400 = load float, float* %t3
  %t401 = call float @llvm.cos.f32(float %t400)
  %t402 = fmul float %t401, 0x3FE51EB860000000
  store float %t402, float* %t399
  %t404 = load float, float* %t394
  %t405 = load float, float* %t391
  %t406 = fmul float %t404, %t405
  %t407 = load float, float* %t388
  %t408 = load float, float* %t399
  %t409 = fmul float %t407, %t408
  %t410 = fsub float %t406, %t409
  %t411 = fdiv float 0x3FF0000000000000, %t410
  store float %t411, float* %t403
  store i32 0, i32* %t412
  br label %while_cond_930
while_cond_930:
  %t413 = load i32, i32* %t412
  %t414 = load i8*, i8** %t9
  %t415 = icmp eq i8* %t414, null
  br i1 %t415, label %list_read_null_934, label %list_read_real_935
list_read_null_934:
  br label %list_read_end_936
list_read_real_935:
  %t416 = bitcast i8* %t414 to { %SpriteDraw*, i64, i64 }*
  %t417 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t416, i32 0, i32 0
  %t418 = load %SpriteDraw*, %SpriteDraw** %t417
  %t419 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t416, i32 0, i32 1
  %t420 = load i64, i64* %t419
  br label %list_read_end_936
list_read_end_936:
  %t421 = phi %SpriteDraw* [ null, %list_read_null_934 ], [ %t418, %list_read_real_935 ]
  %t422 = phi i64 [ 0, %list_read_null_934 ], [ %t420, %list_read_real_935 ]
  %t423 = trunc i64 %t422 to i32
  %t424 = icmp slt i32 %t413, %t423
  br i1 %t424, label %while_body_931, label %while_else_932
while_body_931:
  %t426 = load i8*, i8** %t9
  %t427 = icmp eq i8* %t426, null
  br i1 %t427, label %list_read_null_937, label %list_read_real_938
list_read_null_937:
  br label %list_read_end_939
list_read_real_938:
  %t428 = bitcast i8* %t426 to { %SpriteDraw*, i64, i64 }*
  %t429 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t428, i32 0, i32 0
  %t430 = load %SpriteDraw*, %SpriteDraw** %t429
  %t431 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t428, i32 0, i32 1
  %t432 = load i64, i64* %t431
  br label %list_read_end_939
list_read_end_939:
  %t433 = phi %SpriteDraw* [ null, %list_read_null_937 ], [ %t430, %list_read_real_938 ]
  %t434 = phi i64 [ 0, %list_read_null_937 ], [ %t432, %list_read_real_938 ]
  %t435 = load i32, i32* %t412
  %t436 = sext i32 %t435 to i64
  %t437 = icmp ult i64 %t436, %t434
  br i1 %t437, label %list_idx_ok_940, label %list_idx_oob_941
list_idx_ok_940:
  %t438 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t433, i64 %t436
  %t439 = load %SpriteDraw, %SpriteDraw* %t438
  br label %list_idx_end_942
list_idx_oob_941:
  br label %list_idx_end_942
list_idx_end_942:
  %t440 = phi %SpriteDraw [ %t439, %list_idx_ok_940 ], [ zeroinitializer, %list_idx_oob_941 ]
  store %SpriteDraw %t440, %SpriteDraw* %t425
  %t442 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t425, i32 0, i32 2
  %t443 = load float, float* %t442
  %t444 = load float, float* %t1
  %t445 = fsub float %t443, %t444
  store float %t445, float* %t441
  %t447 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t425, i32 0, i32 3
  %t448 = load float, float* %t447
  %t449 = load float, float* %t2
  %t450 = fsub float %t448, %t449
  store float %t450, float* %t446
  %t452 = load float, float* %t403
  %t453 = load float, float* %t391
  %t454 = load float, float* %t441
  %t455 = fmul float %t453, %t454
  %t456 = load float, float* %t388
  %t457 = load float, float* %t446
  %t458 = fmul float %t456, %t457
  %t459 = fsub float %t455, %t458
  %t460 = fmul float %t452, %t459
  store float %t460, float* %t451
  %t462 = load float, float* %t403
  %t463 = load float, float* %t399
  %t464 = load float, float* %t441
  %t465 = fmul float %t463, %t464
  %t466 = fsub float 0x0000000000000000, %t465
  %t467 = load float, float* %t394
  %t468 = load float, float* %t446
  %t469 = fmul float %t467, %t468
  %t470 = fadd float %t466, %t469
  %t471 = fmul float %t462, %t470
  store float %t471, float* %t461
  %t472 = load float, float* %t461
  %t473 = fcmp ogt float %t472, 0x3FB99999A0000000
  br i1 %t473, label %if_then_943, label %if_else_944
if_then_943:
  %t475 = sitofp i32 320 to float
  %t476 = fdiv float %t475, 0x4000000000000000
  %t477 = load float, float* %t451
  %t478 = load float, float* %t461
  %t479 = fdiv float %t477, %t478
  %t480 = fadd float 0x3FF0000000000000, %t479
  %t481 = fmul float %t476, %t480
  store float %t481, float* %t474
  %t483 = sitofp i32 200 to float
  %t484 = load float, float* %t461
  %t485 = fdiv float %t483, %t484
  %t486 = call float @llvm.fabs.f32(float %t485)
  store float %t486, float* %t482
  %t488 = load float, float* %t482
  store float %t488, float* %t487
  %t490 = load float, float* %t482
  %t491 = fdiv float %t490, 0x4000000000000000
  %t492 = fsub float 0x0000000000000000, %t491
  %t493 = sitofp i32 200 to float
  %t494 = fdiv float %t493, 0x4000000000000000
  %t495 = fadd float %t492, %t494
  %t496 = call i32 @llvm.fptosi.sat.i32.f32(float %t495)
  store i32 %t496, i32* %t489
  %t498 = load float, float* %t482
  %t499 = fdiv float %t498, 0x4000000000000000
  %t500 = sitofp i32 200 to float
  %t501 = fdiv float %t500, 0x4000000000000000
  %t502 = fadd float %t499, %t501
  %t503 = call i32 @llvm.fptosi.sat.i32.f32(float %t502)
  store i32 %t503, i32* %t497
  %t505 = load float, float* %t487
  %t506 = fdiv float %t505, 0x4000000000000000
  %t507 = fsub float 0x0000000000000000, %t506
  %t508 = load float, float* %t474
  %t509 = fadd float %t507, %t508
  %t510 = call i32 @llvm.fptosi.sat.i32.f32(float %t509)
  store i32 %t510, i32* %t504
  %t512 = load float, float* %t487
  %t513 = fdiv float %t512, 0x4000000000000000
  %t514 = load float, float* %t474
  %t515 = fadd float %t513, %t514
  %t516 = call i32 @llvm.fptosi.sat.i32.f32(float %t515)
  store i32 %t516, i32* %t511
  %t518 = load %sprites__SpriteSet, %sprites__SpriteSet* %t7
  %t519 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 0
  %t520 = load i8*, i8** %t519
  call void @star_rc_retain(i8* %t520)
  %t521 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 1
  %t522 = load i8*, i8** %t521
  call void @star_rc_retain(i8* %t522)
  %t523 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 2
  %t524 = load i8*, i8** %t523
  call void @star_rc_retain(i8* %t524)
  %t525 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 3
  %t526 = load i8*, i8** %t525
  call void @star_rc_retain(i8* %t526)
  %t527 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 4
  %t528 = load i8*, i8** %t527
  call void @star_rc_retain(i8* %t528)
  %t529 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t425, i32 0, i32 1
  %t530 = load i32, i32* %t529
  %t531 = call i8* @pick_sprite(%sprites__SpriteSet %t518, i32 %t530)
  store i8* %t531, i8** %t517
  %t533 = getelementptr inbounds %SpriteDraw, %SpriteDraw* %t425, i32 0, i32 0
  %t534 = load float, float* %t533
  %t535 = fdiv float %t534, 0x4028000000000000
  %t536 = fsub float 0x3FF0000000000000, %t535
  %t537 = call float @llvm.maxnum.f32(float %t536, float 0x3FC3333340000000)
  %t538 = call float @llvm.minnum.f32(float %t537, float 0x3FF0000000000000)
  store float %t538, float* %t532
  %t540 = load i32, i32* %t489
  store i32 %t540, i32* %t539
  br label %while_cond_946
while_cond_946:
  %t541 = load i32, i32* %t539
  %t542 = load i32, i32* %t497
  %t543 = icmp slt i32 %t541, %t542
  br i1 %t543, label %while_body_947, label %while_else_948
while_body_947:
  %t545 = load i32, i32* %t504
  store i32 %t545, i32* %t544
  br label %while_cond_950
while_cond_950:
  %t546 = load i32, i32* %t544
  %t547 = load i32, i32* %t511
  %t548 = icmp slt i32 %t546, %t547
  br i1 %t548, label %while_body_951, label %while_else_952
while_body_951:
  %t549 = load i32, i32* %t544
  %t550 = icmp sge i32 %t549, 0
  br i1 %t550, label %logic_rhs_954, label %logic_short_955
logic_rhs_954:
  %t551 = load i32, i32* %t544
  %t552 = icmp slt i32 %t551, 320
  br label %logic_end_956
logic_short_955:
  br label %logic_end_956
logic_end_956:
  %t553 = phi i1 [ %t552, %logic_rhs_954 ], [ false, %logic_short_955 ]
  br i1 %t553, label %logic_rhs_957, label %logic_short_958
logic_rhs_957:
  %t554 = load i32, i32* %t539
  %t555 = icmp sge i32 %t554, 0
  br label %logic_end_959
logic_short_958:
  br label %logic_end_959
logic_end_959:
  %t556 = phi i1 [ %t555, %logic_rhs_957 ], [ false, %logic_short_958 ]
  br i1 %t556, label %logic_rhs_960, label %logic_short_961
logic_rhs_960:
  %t557 = load i32, i32* %t539
  %t558 = icmp slt i32 %t557, 200
  br label %logic_end_962
logic_short_961:
  br label %logic_end_962
logic_end_962:
  %t559 = phi i1 [ %t558, %logic_rhs_960 ], [ false, %logic_short_961 ]
  br i1 %t559, label %if_then_963, label %if_else_964
if_then_963:
  %t560 = load float, float* %t461
  %t561 = load i8*, i8** %t0
  %t562 = icmp eq i8* %t561, null
  br i1 %t562, label %list_read_null_966, label %list_read_real_967
list_read_null_966:
  br label %list_read_end_968
list_read_real_967:
  %t563 = bitcast i8* %t561 to { float*, i64, i64 }*
  %t564 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t563, i32 0, i32 0
  %t565 = load float*, float** %t564
  %t566 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t563, i32 0, i32 1
  %t567 = load i64, i64* %t566
  br label %list_read_end_968
list_read_end_968:
  %t568 = phi float* [ null, %list_read_null_966 ], [ %t565, %list_read_real_967 ]
  %t569 = phi i64 [ 0, %list_read_null_966 ], [ %t567, %list_read_real_967 ]
  %t570 = load i32, i32* %t544
  %t571 = sext i32 %t570 to i64
  %t572 = icmp ult i64 %t571, %t569
  br i1 %t572, label %list_idx_ok_969, label %list_idx_oob_970
list_idx_ok_969:
  %t573 = getelementptr inbounds float, float* %t568, i64 %t571
  %t574 = load float, float* %t573
  br label %list_idx_end_971
list_idx_oob_970:
  br label %list_idx_end_971
list_idx_end_971:
  %t575 = phi float [ %t574, %list_idx_ok_969 ], [ 0.0, %list_idx_oob_970 ]
  %t576 = fcmp olt float %t560, %t575
  br i1 %t576, label %if_then_972, label %if_else_973
if_then_972:
  %t578 = load i32, i32* %t544
  %t579 = load i32, i32* %t504
  %t580 = sub i32 %t578, %t579
  %t581 = mul i32 %t580, 16
  %t582 = load float, float* %t487
  %t583 = call i32 @llvm.fptosi.sat.i32.f32(float %t582)
  %t584 = icmp sgt i32 %t583, 1
  %t585 = select i1 %t584, i32 %t583, i32 1
  %t586 = icmp eq i32 %t585, 0
  %t587 = icmp eq i32 %t581, -2147483648
  %t588 = icmp eq i32 %t585, -1
  %t589 = and i1 %t587, %t588
  %t590 = or i1 %t586, %t589
  br i1 %t590, label %int_div_fail_975, label %int_div_ok_976
int_div_fail_975:
  %t591 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.44, i64 0, i64 0
  call i32 @puts(i8* %t591)
  call void @exit(i32 1)
  unreachable
int_div_ok_976:
  %t592 = sdiv i32 %t581, %t585
  store i32 %t592, i32* %t577
  %t594 = load i32, i32* %t539
  %t595 = load i32, i32* %t489
  %t596 = sub i32 %t594, %t595
  %t597 = mul i32 %t596, 16
  %t598 = load float, float* %t482
  %t599 = call i32 @llvm.fptosi.sat.i32.f32(float %t598)
  %t600 = icmp sgt i32 %t599, 1
  %t601 = select i1 %t600, i32 %t599, i32 1
  %t602 = icmp eq i32 %t601, 0
  %t603 = icmp eq i32 %t597, -2147483648
  %t604 = icmp eq i32 %t601, -1
  %t605 = and i1 %t603, %t604
  %t606 = or i1 %t602, %t605
  br i1 %t606, label %int_div_fail_977, label %int_div_ok_978
int_div_fail_977:
  %t607 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.45, i64 0, i64 0
  call i32 @puts(i8* %t607)
  call void @exit(i32 1)
  unreachable
int_div_ok_978:
  %t608 = sdiv i32 %t597, %t601
  store i32 %t608, i32* %t593
  %t610 = load i32, i32* %t593
  %t611 = mul i32 %t610, 16
  %t612 = load i32, i32* %t577
  %t613 = add i32 %t611, %t612
  %t614 = mul i32 %t613, 4
  store i32 %t614, i32* %t609
  %t616 = load i8*, i8** %t517
  %t617 = icmp eq i8* %t616, null
  br i1 %t617, label %list_read_null_979, label %list_read_real_980
list_read_null_979:
  br label %list_read_end_981
list_read_real_980:
  %t618 = bitcast i8* %t616 to { i8*, i64, i64 }*
  %t619 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t618, i32 0, i32 0
  %t620 = load i8*, i8** %t619
  %t621 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t618, i32 0, i32 1
  %t622 = load i64, i64* %t621
  br label %list_read_end_981
list_read_end_981:
  %t623 = phi i8* [ null, %list_read_null_979 ], [ %t620, %list_read_real_980 ]
  %t624 = phi i64 [ 0, %list_read_null_979 ], [ %t622, %list_read_real_980 ]
  %t625 = load i32, i32* %t609
  %t626 = add i32 %t625, 3
  %t627 = sext i32 %t626 to i64
  %t628 = icmp ult i64 %t627, %t624
  br i1 %t628, label %list_idx_ok_982, label %list_idx_oob_983
list_idx_ok_982:
  %t629 = getelementptr inbounds i8, i8* %t623, i64 %t627
  %t630 = load i8, i8* %t629
  br label %list_idx_end_984
list_idx_oob_983:
  br label %list_idx_end_984
list_idx_end_984:
  %t631 = phi i8 [ %t630, %list_idx_ok_982 ], [ 0, %list_idx_oob_983 ]
  store i8 %t631, i8* %t615
  %t632 = load i8, i8* %t615
  %t633 = zext i8 %t632 to i32
  %t634 = icmp sgt i32 %t633, 0
  br i1 %t634, label %if_then_985, label %if_else_986
if_then_985:
  %t636 = load i8*, i8** %t517
  %t637 = icmp eq i8* %t636, null
  br i1 %t637, label %list_read_null_988, label %list_read_real_989
list_read_null_988:
  br label %list_read_end_990
list_read_real_989:
  %t638 = bitcast i8* %t636 to { i8*, i64, i64 }*
  %t639 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t638, i32 0, i32 0
  %t640 = load i8*, i8** %t639
  %t641 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t638, i32 0, i32 1
  %t642 = load i64, i64* %t641
  br label %list_read_end_990
list_read_end_990:
  %t643 = phi i8* [ null, %list_read_null_988 ], [ %t640, %list_read_real_989 ]
  %t644 = phi i64 [ 0, %list_read_null_988 ], [ %t642, %list_read_real_989 ]
  %t645 = load i32, i32* %t609
  %t646 = sext i32 %t645 to i64
  %t647 = icmp ult i64 %t646, %t644
  br i1 %t647, label %list_idx_ok_991, label %list_idx_oob_992
list_idx_ok_991:
  %t648 = getelementptr inbounds i8, i8* %t643, i64 %t646
  %t649 = load i8, i8* %t648
  br label %list_idx_end_993
list_idx_oob_992:
  br label %list_idx_end_993
list_idx_end_993:
  %t650 = phi i8 [ %t649, %list_idx_ok_991 ], [ 0, %list_idx_oob_992 ]
  store i8 %t650, i8* %t635
  %t652 = load i8*, i8** %t517
  %t653 = icmp eq i8* %t652, null
  br i1 %t653, label %list_read_null_994, label %list_read_real_995
list_read_null_994:
  br label %list_read_end_996
list_read_real_995:
  %t654 = bitcast i8* %t652 to { i8*, i64, i64 }*
  %t655 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t654, i32 0, i32 0
  %t656 = load i8*, i8** %t655
  %t657 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t654, i32 0, i32 1
  %t658 = load i64, i64* %t657
  br label %list_read_end_996
list_read_end_996:
  %t659 = phi i8* [ null, %list_read_null_994 ], [ %t656, %list_read_real_995 ]
  %t660 = phi i64 [ 0, %list_read_null_994 ], [ %t658, %list_read_real_995 ]
  %t661 = load i32, i32* %t609
  %t662 = add i32 %t661, 1
  %t663 = sext i32 %t662 to i64
  %t664 = icmp ult i64 %t663, %t660
  br i1 %t664, label %list_idx_ok_997, label %list_idx_oob_998
list_idx_ok_997:
  %t665 = getelementptr inbounds i8, i8* %t659, i64 %t663
  %t666 = load i8, i8* %t665
  br label %list_idx_end_999
list_idx_oob_998:
  br label %list_idx_end_999
list_idx_end_999:
  %t667 = phi i8 [ %t666, %list_idx_ok_997 ], [ 0, %list_idx_oob_998 ]
  store i8 %t667, i8* %t651
  %t669 = load i8*, i8** %t517
  %t670 = icmp eq i8* %t669, null
  br i1 %t670, label %list_read_null_1000, label %list_read_real_1001
list_read_null_1000:
  br label %list_read_end_1002
list_read_real_1001:
  %t671 = bitcast i8* %t669 to { i8*, i64, i64 }*
  %t672 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t671, i32 0, i32 0
  %t673 = load i8*, i8** %t672
  %t674 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t671, i32 0, i32 1
  %t675 = load i64, i64* %t674
  br label %list_read_end_1002
list_read_end_1002:
  %t676 = phi i8* [ null, %list_read_null_1000 ], [ %t673, %list_read_real_1001 ]
  %t677 = phi i64 [ 0, %list_read_null_1000 ], [ %t675, %list_read_real_1001 ]
  %t678 = load i32, i32* %t609
  %t679 = add i32 %t678, 2
  %t680 = sext i32 %t679 to i64
  %t681 = icmp ult i64 %t680, %t677
  br i1 %t681, label %list_idx_ok_1003, label %list_idx_oob_1004
list_idx_ok_1003:
  %t682 = getelementptr inbounds i8, i8* %t676, i64 %t680
  %t683 = load i8, i8* %t682
  br label %list_idx_end_1005
list_idx_oob_1004:
  br label %list_idx_end_1005
list_idx_end_1005:
  %t684 = phi i8 [ %t683, %list_idx_ok_1003 ], [ 0, %list_idx_oob_1004 ]
  store i8 %t684, i8* %t668
  %t686 = load i8, i8* %t635
  %t687 = zext i8 %t686 to i32
  %t688 = load i8, i8* %t651
  %t689 = zext i8 %t688 to i32
  %t690 = load i8, i8* %t668
  %t691 = zext i8 %t690 to i32
  %t692 = load float, float* %t532
  %t693 = call { i32, i32, i32 } @shade_color(i32 %t687, i32 %t689, i32 %t691, float %t692)
  store { i32, i32, i32 } %t693, { i32, i32, i32 }* %t685
  %t694 = getelementptr i8, i8* null, i32 1
  %t695 = ptrtoint i8* %t694 to i64
  %t696 = load i8*, i8** %t8
  %t697 = icmp eq i8* %t696, null
  br i1 %t697, label %list_cow_alloc_1006, label %list_cow_check_1007
list_cow_alloc_1006:
  %t698 = bitcast void (i8*)* @list_release_u8 to i8*
  %t699 = call i8* @star_rc_alloc(i64 24, i8* %t698)
  %t700 = bitcast i8* %t699 to { i8*, i64, i64 }*
  %t701 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t700, i32 0, i32 0
  store i8* null, i8** %t701
  %t702 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t700, i32 0, i32 1
  store i64 0, i64* %t702
  %t703 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t700, i32 0, i32 2
  store i64 0, i64* %t703
  store i8* %t699, i8** %t8
  br label %list_cow_done_1008
list_cow_check_1007:
  %t704 = getelementptr inbounds i8, i8* %t696, i64 -16
  %t705 = bitcast i8* %t704 to i64*
  %t706 = load atomic i64, i64* %t705 seq_cst, align 8
  %t707 = icmp eq i64 %t706, 1
  br i1 %t707, label %list_cow_done_1008, label %list_cow_clone_1009
list_cow_clone_1009:
  %t708 = bitcast i8* %t696 to { i8*, i64, i64 }*
  %t709 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t708, i32 0, i32 0
  %t710 = load i8*, i8** %t709
  %t711 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t708, i32 0, i32 1
  %t712 = load i64, i64* %t711
  %t713 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t708, i32 0, i32 2
  %t714 = load i64, i64* %t713
  %t715 = bitcast void (i8*)* @list_release_u8 to i8*
  %t716 = call i8* @star_rc_alloc(i64 24, i8* %t715)
  %t717 = bitcast i8* %t716 to { i8*, i64, i64 }*
  %t718 = mul i64 %t714, %t695
  %t719 = call i8* @malloc(i64 %t718)
  %t720 = bitcast i8* %t719 to i8*
  %t721 = icmp sgt i64 %t712, 0
  br i1 %t721, label %list_cow_copy_1010, label %list_cow_after_copy_1011
list_cow_copy_1010:
  %t722 = mul i64 %t712, %t695
  %t723 = bitcast i8* %t710 to i8*
  call i8* @memcpy(i8* %t719, i8* %t723, i64 %t722)
  br label %list_cow_after_copy_1011
list_cow_after_copy_1011:
  %t724 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t717, i32 0, i32 0
  store i8* %t720, i8** %t724
  %t725 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t717, i32 0, i32 1
  store i64 %t712, i64* %t725
  %t726 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t717, i32 0, i32 2
  store i64 %t714, i64* %t726
  call void @star_rc_release(i8* %t696)
  store i8* %t716, i8** %t8
  br label %list_cow_done_1008
list_cow_done_1008:
  %t727 = load i8*, i8** %t8
  %t728 = bitcast i8* %t727 to { i8*, i64, i64 }*
  %t729 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t728, i32 0, i32 0
  %t730 = load i8*, i8** %t729
  %t731 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t728, i32 0, i32 1
  %t732 = load i64, i64* %t731
  %t733 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t728, i32 0, i32 2
  %t734 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t685, i32 0, i32 0
  %t735 = load i32, i32* %t734
  %t736 = trunc i32 %t735 to i8
  %t737 = load i64, i64* %t733
  %t738 = load i8*, i8** %t729
  %t739 = load i64, i64* %t731
  %t740 = icmp sge i64 %t739, %t737
  br i1 %t740, label %list_push_grow_1012, label %list_push_store_1013
list_push_grow_1012:
  %t741 = mul i64 %t737, 2
  %t742 = icmp sgt i64 %t741, 0
  %t743 = select i1 %t742, i64 %t741, i64 1
  %t744 = getelementptr i8, i8* null, i32 1
  %t745 = ptrtoint i8* %t744 to i64
  %t746 = mul i64 %t743, %t745
  %t747 = call i8* @malloc(i64 %t746)
  %t748 = bitcast i8* %t747 to i8*
  %t749 = icmp sgt i64 %t737, 0
  br i1 %t749, label %list_push_copy_1014, label %list_push_after_copy_1015
list_push_copy_1014:
  %t750 = mul i64 %t739, %t745
  %t751 = bitcast i8* %t738 to i8*
  call i8* @memcpy(i8* %t747, i8* %t751, i64 %t750)
  call void @free(i8* %t751)
  br label %list_push_after_copy_1015
list_push_after_copy_1015:
  store i8* %t748, i8** %t729
  store i64 %t743, i64* %t733
  br label %list_push_store_1013
list_push_store_1013:
  %t752 = load i8*, i8** %t729
  %t753 = getelementptr inbounds i8, i8* %t752, i64 %t739
  store i8 %t736, i8* %t753
  %t754 = add i64 %t739, 1
  store i64 %t754, i64* %t731
  %t755 = getelementptr i8, i8* null, i32 1
  %t756 = ptrtoint i8* %t755 to i64
  %t757 = load i8*, i8** %t8
  %t758 = icmp eq i8* %t757, null
  br i1 %t758, label %list_cow_alloc_1016, label %list_cow_check_1017
list_cow_alloc_1016:
  %t759 = bitcast void (i8*)* @list_release_u8 to i8*
  %t760 = call i8* @star_rc_alloc(i64 24, i8* %t759)
  %t761 = bitcast i8* %t760 to { i8*, i64, i64 }*
  %t762 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t761, i32 0, i32 0
  store i8* null, i8** %t762
  %t763 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t761, i32 0, i32 1
  store i64 0, i64* %t763
  %t764 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t761, i32 0, i32 2
  store i64 0, i64* %t764
  store i8* %t760, i8** %t8
  br label %list_cow_done_1018
list_cow_check_1017:
  %t765 = getelementptr inbounds i8, i8* %t757, i64 -16
  %t766 = bitcast i8* %t765 to i64*
  %t767 = load atomic i64, i64* %t766 seq_cst, align 8
  %t768 = icmp eq i64 %t767, 1
  br i1 %t768, label %list_cow_done_1018, label %list_cow_clone_1019
list_cow_clone_1019:
  %t769 = bitcast i8* %t757 to { i8*, i64, i64 }*
  %t770 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t769, i32 0, i32 0
  %t771 = load i8*, i8** %t770
  %t772 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t769, i32 0, i32 1
  %t773 = load i64, i64* %t772
  %t774 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t769, i32 0, i32 2
  %t775 = load i64, i64* %t774
  %t776 = bitcast void (i8*)* @list_release_u8 to i8*
  %t777 = call i8* @star_rc_alloc(i64 24, i8* %t776)
  %t778 = bitcast i8* %t777 to { i8*, i64, i64 }*
  %t779 = mul i64 %t775, %t756
  %t780 = call i8* @malloc(i64 %t779)
  %t781 = bitcast i8* %t780 to i8*
  %t782 = icmp sgt i64 %t773, 0
  br i1 %t782, label %list_cow_copy_1020, label %list_cow_after_copy_1021
list_cow_copy_1020:
  %t783 = mul i64 %t773, %t756
  %t784 = bitcast i8* %t771 to i8*
  call i8* @memcpy(i8* %t780, i8* %t784, i64 %t783)
  br label %list_cow_after_copy_1021
list_cow_after_copy_1021:
  %t785 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t778, i32 0, i32 0
  store i8* %t781, i8** %t785
  %t786 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t778, i32 0, i32 1
  store i64 %t773, i64* %t786
  %t787 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t778, i32 0, i32 2
  store i64 %t775, i64* %t787
  call void @star_rc_release(i8* %t757)
  store i8* %t777, i8** %t8
  br label %list_cow_done_1018
list_cow_done_1018:
  %t788 = load i8*, i8** %t8
  %t789 = bitcast i8* %t788 to { i8*, i64, i64 }*
  %t790 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t789, i32 0, i32 0
  %t791 = load i8*, i8** %t790
  %t792 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t789, i32 0, i32 1
  %t793 = load i64, i64* %t792
  %t794 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t789, i32 0, i32 2
  %t795 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t685, i32 0, i32 1
  %t796 = load i32, i32* %t795
  %t797 = trunc i32 %t796 to i8
  %t798 = load i64, i64* %t794
  %t799 = load i8*, i8** %t790
  %t800 = load i64, i64* %t792
  %t801 = icmp sge i64 %t800, %t798
  br i1 %t801, label %list_push_grow_1022, label %list_push_store_1023
list_push_grow_1022:
  %t802 = mul i64 %t798, 2
  %t803 = icmp sgt i64 %t802, 0
  %t804 = select i1 %t803, i64 %t802, i64 1
  %t805 = getelementptr i8, i8* null, i32 1
  %t806 = ptrtoint i8* %t805 to i64
  %t807 = mul i64 %t804, %t806
  %t808 = call i8* @malloc(i64 %t807)
  %t809 = bitcast i8* %t808 to i8*
  %t810 = icmp sgt i64 %t798, 0
  br i1 %t810, label %list_push_copy_1024, label %list_push_after_copy_1025
list_push_copy_1024:
  %t811 = mul i64 %t800, %t806
  %t812 = bitcast i8* %t799 to i8*
  call i8* @memcpy(i8* %t808, i8* %t812, i64 %t811)
  call void @free(i8* %t812)
  br label %list_push_after_copy_1025
list_push_after_copy_1025:
  store i8* %t809, i8** %t790
  store i64 %t804, i64* %t794
  br label %list_push_store_1023
list_push_store_1023:
  %t813 = load i8*, i8** %t790
  %t814 = getelementptr inbounds i8, i8* %t813, i64 %t800
  store i8 %t797, i8* %t814
  %t815 = add i64 %t800, 1
  store i64 %t815, i64* %t792
  %t816 = getelementptr i8, i8* null, i32 1
  %t817 = ptrtoint i8* %t816 to i64
  %t818 = load i8*, i8** %t8
  %t819 = icmp eq i8* %t818, null
  br i1 %t819, label %list_cow_alloc_1026, label %list_cow_check_1027
list_cow_alloc_1026:
  %t820 = bitcast void (i8*)* @list_release_u8 to i8*
  %t821 = call i8* @star_rc_alloc(i64 24, i8* %t820)
  %t822 = bitcast i8* %t821 to { i8*, i64, i64 }*
  %t823 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t822, i32 0, i32 0
  store i8* null, i8** %t823
  %t824 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t822, i32 0, i32 1
  store i64 0, i64* %t824
  %t825 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t822, i32 0, i32 2
  store i64 0, i64* %t825
  store i8* %t821, i8** %t8
  br label %list_cow_done_1028
list_cow_check_1027:
  %t826 = getelementptr inbounds i8, i8* %t818, i64 -16
  %t827 = bitcast i8* %t826 to i64*
  %t828 = load atomic i64, i64* %t827 seq_cst, align 8
  %t829 = icmp eq i64 %t828, 1
  br i1 %t829, label %list_cow_done_1028, label %list_cow_clone_1029
list_cow_clone_1029:
  %t830 = bitcast i8* %t818 to { i8*, i64, i64 }*
  %t831 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t830, i32 0, i32 0
  %t832 = load i8*, i8** %t831
  %t833 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t830, i32 0, i32 1
  %t834 = load i64, i64* %t833
  %t835 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t830, i32 0, i32 2
  %t836 = load i64, i64* %t835
  %t837 = bitcast void (i8*)* @list_release_u8 to i8*
  %t838 = call i8* @star_rc_alloc(i64 24, i8* %t837)
  %t839 = bitcast i8* %t838 to { i8*, i64, i64 }*
  %t840 = mul i64 %t836, %t817
  %t841 = call i8* @malloc(i64 %t840)
  %t842 = bitcast i8* %t841 to i8*
  %t843 = icmp sgt i64 %t834, 0
  br i1 %t843, label %list_cow_copy_1030, label %list_cow_after_copy_1031
list_cow_copy_1030:
  %t844 = mul i64 %t834, %t817
  %t845 = bitcast i8* %t832 to i8*
  call i8* @memcpy(i8* %t841, i8* %t845, i64 %t844)
  br label %list_cow_after_copy_1031
list_cow_after_copy_1031:
  %t846 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t839, i32 0, i32 0
  store i8* %t842, i8** %t846
  %t847 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t839, i32 0, i32 1
  store i64 %t834, i64* %t847
  %t848 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t839, i32 0, i32 2
  store i64 %t836, i64* %t848
  call void @star_rc_release(i8* %t818)
  store i8* %t838, i8** %t8
  br label %list_cow_done_1028
list_cow_done_1028:
  %t849 = load i8*, i8** %t8
  %t850 = bitcast i8* %t849 to { i8*, i64, i64 }*
  %t851 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t850, i32 0, i32 0
  %t852 = load i8*, i8** %t851
  %t853 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t850, i32 0, i32 1
  %t854 = load i64, i64* %t853
  %t855 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t850, i32 0, i32 2
  %t856 = getelementptr inbounds { i32, i32, i32 }, { i32, i32, i32 }* %t685, i32 0, i32 2
  %t857 = load i32, i32* %t856
  %t858 = trunc i32 %t857 to i8
  %t859 = load i64, i64* %t855
  %t860 = load i8*, i8** %t851
  %t861 = load i64, i64* %t853
  %t862 = icmp sge i64 %t861, %t859
  br i1 %t862, label %list_push_grow_1032, label %list_push_store_1033
list_push_grow_1032:
  %t863 = mul i64 %t859, 2
  %t864 = icmp sgt i64 %t863, 0
  %t865 = select i1 %t864, i64 %t863, i64 1
  %t866 = getelementptr i8, i8* null, i32 1
  %t867 = ptrtoint i8* %t866 to i64
  %t868 = mul i64 %t865, %t867
  %t869 = call i8* @malloc(i64 %t868)
  %t870 = bitcast i8* %t869 to i8*
  %t871 = icmp sgt i64 %t859, 0
  br i1 %t871, label %list_push_copy_1034, label %list_push_after_copy_1035
list_push_copy_1034:
  %t872 = mul i64 %t861, %t867
  %t873 = bitcast i8* %t860 to i8*
  call i8* @memcpy(i8* %t869, i8* %t873, i64 %t872)
  call void @free(i8* %t873)
  br label %list_push_after_copy_1035
list_push_after_copy_1035:
  store i8* %t870, i8** %t851
  store i64 %t865, i64* %t855
  br label %list_push_store_1033
list_push_store_1033:
  %t874 = load i8*, i8** %t851
  %t875 = getelementptr inbounds i8, i8* %t874, i64 %t861
  store i8 %t858, i8* %t875
  %t876 = add i64 %t861, 1
  store i64 %t876, i64* %t853
  %t877 = getelementptr i8, i8* null, i32 1
  %t878 = ptrtoint i8* %t877 to i64
  %t879 = load i8*, i8** %t8
  %t880 = icmp eq i8* %t879, null
  br i1 %t880, label %list_cow_alloc_1036, label %list_cow_check_1037
list_cow_alloc_1036:
  %t881 = bitcast void (i8*)* @list_release_u8 to i8*
  %t882 = call i8* @star_rc_alloc(i64 24, i8* %t881)
  %t883 = bitcast i8* %t882 to { i8*, i64, i64 }*
  %t884 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t883, i32 0, i32 0
  store i8* null, i8** %t884
  %t885 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t883, i32 0, i32 1
  store i64 0, i64* %t885
  %t886 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t883, i32 0, i32 2
  store i64 0, i64* %t886
  store i8* %t882, i8** %t8
  br label %list_cow_done_1038
list_cow_check_1037:
  %t887 = getelementptr inbounds i8, i8* %t879, i64 -16
  %t888 = bitcast i8* %t887 to i64*
  %t889 = load atomic i64, i64* %t888 seq_cst, align 8
  %t890 = icmp eq i64 %t889, 1
  br i1 %t890, label %list_cow_done_1038, label %list_cow_clone_1039
list_cow_clone_1039:
  %t891 = bitcast i8* %t879 to { i8*, i64, i64 }*
  %t892 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t891, i32 0, i32 0
  %t893 = load i8*, i8** %t892
  %t894 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t891, i32 0, i32 1
  %t895 = load i64, i64* %t894
  %t896 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t891, i32 0, i32 2
  %t897 = load i64, i64* %t896
  %t898 = bitcast void (i8*)* @list_release_u8 to i8*
  %t899 = call i8* @star_rc_alloc(i64 24, i8* %t898)
  %t900 = bitcast i8* %t899 to { i8*, i64, i64 }*
  %t901 = mul i64 %t897, %t878
  %t902 = call i8* @malloc(i64 %t901)
  %t903 = bitcast i8* %t902 to i8*
  %t904 = icmp sgt i64 %t895, 0
  br i1 %t904, label %list_cow_copy_1040, label %list_cow_after_copy_1041
list_cow_copy_1040:
  %t905 = mul i64 %t895, %t878
  %t906 = bitcast i8* %t893 to i8*
  call i8* @memcpy(i8* %t902, i8* %t906, i64 %t905)
  br label %list_cow_after_copy_1041
list_cow_after_copy_1041:
  %t907 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t900, i32 0, i32 0
  store i8* %t903, i8** %t907
  %t908 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t900, i32 0, i32 1
  store i64 %t895, i64* %t908
  %t909 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t900, i32 0, i32 2
  store i64 %t897, i64* %t909
  call void @star_rc_release(i8* %t879)
  store i8* %t899, i8** %t8
  br label %list_cow_done_1038
list_cow_done_1038:
  %t910 = load i8*, i8** %t8
  %t911 = bitcast i8* %t910 to { i8*, i64, i64 }*
  %t912 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t911, i32 0, i32 0
  %t913 = load i8*, i8** %t912
  %t914 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t911, i32 0, i32 1
  %t915 = load i64, i64* %t914
  %t916 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t911, i32 0, i32 2
  %t917 = trunc i32 255 to i8
  %t918 = load i64, i64* %t916
  %t919 = load i8*, i8** %t912
  %t920 = load i64, i64* %t914
  %t921 = icmp sge i64 %t920, %t918
  br i1 %t921, label %list_push_grow_1042, label %list_push_store_1043
list_push_grow_1042:
  %t922 = mul i64 %t918, 2
  %t923 = icmp sgt i64 %t922, 0
  %t924 = select i1 %t923, i64 %t922, i64 1
  %t925 = getelementptr i8, i8* null, i32 1
  %t926 = ptrtoint i8* %t925 to i64
  %t927 = mul i64 %t924, %t926
  %t928 = call i8* @malloc(i64 %t927)
  %t929 = bitcast i8* %t928 to i8*
  %t930 = icmp sgt i64 %t918, 0
  br i1 %t930, label %list_push_copy_1044, label %list_push_after_copy_1045
list_push_copy_1044:
  %t931 = mul i64 %t920, %t926
  %t932 = bitcast i8* %t919 to i8*
  call i8* @memcpy(i8* %t928, i8* %t932, i64 %t931)
  call void @free(i8* %t932)
  br label %list_push_after_copy_1045
list_push_after_copy_1045:
  store i8* %t929, i8** %t912
  store i64 %t924, i64* %t916
  br label %list_push_store_1043
list_push_store_1043:
  %t933 = load i8*, i8** %t912
  %t934 = getelementptr inbounds i8, i8* %t933, i64 %t920
  store i8 %t917, i8* %t934
  %t935 = add i64 %t920, 1
  store i64 %t935, i64* %t914
  br label %if_end_987
if_else_986:
  br label %if_end_987
if_end_987:
  br label %if_end_974
if_else_973:
  br label %if_end_974
if_end_974:
  br label %if_end_965
if_else_964:
  br label %if_end_965
if_end_965:
  %t936 = load i32, i32* %t544
  %t937 = add i32 %t936, 1
  store i32 %t937, i32* %t544
  br label %while_cond_950
while_else_952:
  br label %while_end_953
while_end_953:
  %t938 = load i32, i32* %t539
  %t939 = add i32 %t938, 1
  store i32 %t939, i32* %t539
  br label %while_cond_946
while_else_948:
  br label %while_end_949
while_end_949:
  %t940 = load i8*, i8** %t517
  call void @star_rc_release(i8* %t940)
  br label %if_end_945
if_else_944:
  br label %if_end_945
if_end_945:
  %t941 = load i32, i32* %t412
  %t942 = add i32 %t941, 1
  store i32 %t942, i32* %t412
  br label %while_cond_930
while_else_932:
  br label %while_end_933
while_end_933:
  %t943 = load i8*, i8** %t8
  %t944 = load i8*, i8** %t8
  call void @star_rc_retain(i8* %t944)
  %t945 = load i8*, i8** %t9
  call void @star_rc_release(i8* %t945)
  %t946 = load i8*, i8** %t8
  call void @star_rc_release(i8* %t946)
  %t947 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 0
  %t948 = load i8*, i8** %t947
  call void @star_rc_release(i8* %t948)
  %t949 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 1
  %t950 = load i8*, i8** %t949
  call void @star_rc_release(i8* %t950)
  %t951 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 2
  %t952 = load i8*, i8** %t951
  call void @star_rc_release(i8* %t952)
  %t953 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 3
  %t954 = load i8*, i8** %t953
  call void @star_rc_release(i8* %t954)
  %t955 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t7, i32 0, i32 4
  %t956 = load i8*, i8** %t955
  call void @star_rc_release(i8* %t956)
  %t957 = load i8*, i8** %t6
  call void @star_rc_release(i8* %t957)
  %t958 = load i8*, i8** %t5
  call void @star_rc_release(i8* %t958)
  %t959 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t959)
  %t960 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t960)
  ret i8* %t943
}

define i1 @has_los(i8* %map_grid, float %x1, float %y1, float %x2, float %y2) {
entry:
  %t0 = alloca i8*
  %t1 = alloca float
  %t2 = alloca float
  %t3 = alloca float
  %t4 = alloca float
  %t5 = alloca float
  %t9 = alloca float
  %t13 = alloca float
  %t22 = alloca i32
  %t26 = alloca i32
  %t30 = alloca float
  %t36 = alloca float
  %t42 = alloca float
  store i8* %map_grid, i8** %t0
  store float %x1, float* %t1
  store float %y1, float* %t2
  store float %x2, float* %t3
  store float %y2, float* %t4
  %t6 = load float, float* %t3
  %t7 = load float, float* %t1
  %t8 = fsub float %t6, %t7
  store float %t8, float* %t5
  %t10 = load float, float* %t4
  %t11 = load float, float* %t2
  %t12 = fsub float %t10, %t11
  store float %t12, float* %t9
  %t14 = load float, float* %t5
  %t15 = load float, float* %t5
  %t16 = fmul float %t14, %t15
  %t17 = load float, float* %t9
  %t18 = load float, float* %t9
  %t19 = fmul float %t17, %t18
  %t20 = fadd float %t16, %t19
  %t21 = call float @llvm.sqrt.f32(float %t20)
  store float %t21, float* %t13
  %t23 = load float, float* %t13
  %t24 = fmul float %t23, 0x4010000000000000
  %t25 = call i32 @llvm.fptosi.sat.i32.f32(float %t24)
  store i32 %t25, i32* %t22
  store i32 1, i32* %t26
  br label %while_cond_1046
while_cond_1046:
  %t27 = load i32, i32* %t26
  %t28 = load i32, i32* %t22
  %t29 = icmp slt i32 %t27, %t28
  br i1 %t29, label %while_body_1047, label %while_else_1048
while_body_1047:
  %t31 = load i32, i32* %t26
  %t32 = sitofp i32 %t31 to float
  %t33 = load i32, i32* %t22
  %t34 = sitofp i32 %t33 to float
  %t35 = fdiv float %t32, %t34
  store float %t35, float* %t30
  %t37 = load float, float* %t1
  %t38 = load float, float* %t5
  %t39 = load float, float* %t30
  %t40 = fmul float %t38, %t39
  %t41 = fadd float %t37, %t40
  store float %t41, float* %t36
  %t43 = load float, float* %t2
  %t44 = load float, float* %t9
  %t45 = load float, float* %t30
  %t46 = fmul float %t44, %t45
  %t47 = fadd float %t43, %t46
  store float %t47, float* %t42
  %t48 = load i8*, i8** %t0
  %t49 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t49)
  %t50 = load float, float* %t36
  %t51 = call i32 @llvm.fptosi.sat.i32.f32(float %t50)
  %t52 = load float, float* %t42
  %t53 = call i32 @llvm.fptosi.sat.i32.f32(float %t52)
  %t54 = call i32 @map__cell_at(i8* %t48, i32 %t51, i32 %t53)
  %t55 = icmp sgt i32 %t54, 0
  br i1 %t55, label %if_then_1050, label %if_else_1051
if_then_1050:
  %t56 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t56)
  ret i1 false
if_else_1051:
  br label %if_end_1052
if_end_1052:
  %t57 = load i32, i32* %t26
  %t58 = add i32 %t57, 1
  store i32 %t58, i32* %t26
  br label %while_cond_1046
while_else_1048:
  br label %while_end_1049
while_end_1049:
  %t59 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t59)
  ret i1 true
}

define %Game @new_game(%map__Level %level) {
entry:
  %t0 = alloca %map__Level
  %t1 = alloca %Game
  store %map__Level %level, %map__Level* %t0
  %t2 = getelementptr inbounds %Game, %Game* %t1, i32 0, i32 0
  %t3 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 0
  %t4 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 5
  %t5 = load i32, i32* %t4
  %t6 = call float @map__cell_center_x(i32 %t5)
  store float %t6, float* %t3
  %t7 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 1
  %t8 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 5
  %t9 = load i32, i32* %t8
  %t10 = call float @map__cell_center_y(i32 %t9)
  store float %t10, float* %t7
  %t11 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 2
  store float 0x0000000000000000, float* %t11
  %t12 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 3
  store float 0x4059000000000000, float* %t12
  %t13 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 4
  store float 0x4059000000000000, float* %t13
  %t14 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 5
  store i32 0, i32* %t14
  %t15 = getelementptr inbounds %Player, %Player* %t2, i32 0, i32 6
  store i1 true, i1* %t15
  %t16 = getelementptr inbounds %Game, %Game* %t1, i32 0, i32 1
  %t17 = load %map__Level, %map__Level* %t0
  %t18 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 0
  %t19 = load i8*, i8** %t18
  call void @star_rc_retain(i8* %t19)
  %t20 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 1
  %t21 = load i8*, i8** %t20
  call void @star_rc_retain(i8* %t21)
  %t22 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 2
  %t23 = load i8*, i8** %t22
  call void @star_rc_retain(i8* %t23)
  %t24 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 3
  %t25 = load i8*, i8** %t24
  call void @star_rc_retain(i8* %t25)
  %t26 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 4
  %t27 = load i8*, i8** %t26
  call void @star_rc_retain(i8* %t27)
  %t28 = call i8* @build_enemies(%map__Level %t17)
  store i8* %t28, i8** %t16
  %t29 = getelementptr inbounds %Game, %Game* %t1, i32 0, i32 2
  store i8* null, i8** %t29
  %t30 = getelementptr inbounds %Game, %Game* %t1, i32 0, i32 3
  %t31 = load %map__Level, %map__Level* %t0
  %t32 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 0
  %t33 = load i8*, i8** %t32
  call void @star_rc_retain(i8* %t33)
  %t34 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 1
  %t35 = load i8*, i8** %t34
  call void @star_rc_retain(i8* %t35)
  %t36 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 2
  %t37 = load i8*, i8** %t36
  call void @star_rc_retain(i8* %t37)
  %t38 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 3
  %t39 = load i8*, i8** %t38
  call void @star_rc_retain(i8* %t39)
  %t40 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 4
  %t41 = load i8*, i8** %t40
  call void @star_rc_retain(i8* %t41)
  %t42 = call i8* @build_pickups(%map__Level %t31)
  store i8* %t42, i8** %t30
  %t43 = getelementptr inbounds %Game, %Game* %t1, i32 0, i32 4
  store float 0x0000000000000000, float* %t43
  %t44 = getelementptr inbounds %Game, %Game* %t1, i32 0, i32 5
  store i1 false, i1* %t44
  %t45 = getelementptr inbounds %Game, %Game* %t1, i32 0, i32 6
  store i32 0, i32* %t45
  %t46 = getelementptr inbounds %Game, %Game* %t1, i32 0, i32 7
  store i32 0, i32* %t46
  %t47 = load %Game, %Game* %t1
  %t48 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 0
  %t49 = load i8*, i8** %t48
  call void @star_rc_release(i8* %t49)
  %t50 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 1
  %t51 = load i8*, i8** %t50
  call void @star_rc_release(i8* %t51)
  %t52 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 2
  %t53 = load i8*, i8** %t52
  call void @star_rc_release(i8* %t53)
  %t54 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 3
  %t55 = load i8*, i8** %t54
  call void @star_rc_release(i8* %t55)
  %t56 = getelementptr inbounds %map__Level, %map__Level* %t0, i32 0, i32 4
  %t57 = load i8*, i8** %t56
  call void @star_rc_release(i8* %t57)
  ret %Game %t47
}

define %Game @Game__update_input(%Game* %self, float %dt, i8* %map_grid, %audio__Sounds %sounds) {
entry:
  %t0 = alloca %Game*
  %t1 = alloca float
  %t2 = alloca i8*
  %t3 = alloca %audio__Sounds
  %t4 = alloca float
  %t27 = alloca i32
  %t28 = alloca i32
  %t29 = alloca i32
  %t33 = alloca i32
  %t42 = alloca float
  %t60 = alloca float
  %t63 = alloca float
  %t69 = alloca float
  %t75 = alloca float
  %t76 = alloca float
  %t157 = alloca float
  %t178 = alloca float
  %t185 = alloca float
  %t222 = alloca i1
  %t223 = alloca i32
  %t224 = alloca i32
  %t268 = alloca float
  %t276 = alloca float
  %t330 = alloca %Projectile
  %t410 = alloca [32 x i8]
  %t412 = alloca i64
  %t434 = alloca i32
  %t435 = alloca i32
  store %Game* %self, %Game** %t0
  store float %dt, float* %t1
  store i8* %map_grid, i8** %t2
  store %audio__Sounds %sounds, %audio__Sounds* %t3
  store float 0x0000000000000000, float* %t4
  %t5 = icmp sge i32 79, 0
  %t6 = icmp slt i32 79, 512
  %t7 = and i1 %t5, %t6
  br i1 %t7, label %key_down_read_1053, label %key_down_end_1054
key_down_read_1053:
  %t8 = call i8* @SDL_GetKeyboardState(i32* null)
  %t9 = sext i32 79 to i64
  %t10 = getelementptr inbounds i8, i8* %t8, i64 %t9
  %t11 = load i8, i8* %t10
  %t12 = icmp ne i8 %t11, 0
  br label %key_down_end_1054
key_down_end_1054:
  %t13 = phi i1 [ false, %entry ], [ %t12, %key_down_read_1053 ]
  br i1 %t13, label %if_then_1055, label %if_else_1056
if_then_1055:
  %t14 = load float, float* %t4
  %t15 = fadd float %t14, 0x3FF0000000000000
  store float %t15, float* %t4
  br label %if_end_1057
if_else_1056:
  br label %if_end_1057
if_end_1057:
  %t16 = icmp sge i32 80, 0
  %t17 = icmp slt i32 80, 512
  %t18 = and i1 %t16, %t17
  br i1 %t18, label %key_down_read_1058, label %key_down_end_1059
key_down_read_1058:
  %t19 = call i8* @SDL_GetKeyboardState(i32* null)
  %t20 = sext i32 80 to i64
  %t21 = getelementptr inbounds i8, i8* %t19, i64 %t20
  %t22 = load i8, i8* %t21
  %t23 = icmp ne i8 %t22, 0
  br label %key_down_end_1059
key_down_end_1059:
  %t24 = phi i1 [ false, %if_end_1057 ], [ %t23, %key_down_read_1058 ]
  br i1 %t24, label %if_then_1060, label %if_else_1061
if_then_1060:
  %t25 = load float, float* %t4
  %t26 = fsub float %t25, 0x3FF0000000000000
  store float %t26, float* %t4
  br label %if_end_1062
if_else_1061:
  br label %if_end_1062
if_end_1062:
  %t30 = call i32 @SDL_GetMouseState(i32* %t28, i32* %t29)
  %t31 = load i32, i32* %t28
  %t32 = load i32, i32* %t29
  store i32 %t31, i32* %t27
  %t34 = load i32, i32* %t27
  %t35 = load %Game*, %Game** %t0
  %t36 = getelementptr inbounds %Game, %Game* %t35, i32 0, i32 6
  %t37 = load i32, i32* %t36
  %t38 = sub i32 %t34, %t37
  store i32 %t38, i32* %t33
  %t39 = load i32, i32* %t27
  %t40 = load %Game*, %Game** %t0
  %t41 = getelementptr inbounds %Game, %Game* %t40, i32 0, i32 6
  store i32 %t39, i32* %t41
  %t43 = load i32, i32* %t33
  %t44 = sitofp i32 %t43 to float
  %t45 = fmul float %t44, 0x3F689374C0000000
  store float %t45, float* %t42
  %t46 = load float, float* %t4
  %t47 = fmul float %t46, 0x4004000000000000
  %t48 = load float, float* %t1
  %t49 = fmul float %t47, %t48
  %t50 = load float, float* %t42
  %t51 = fadd float %t49, %t50
  %t52 = load %Game*, %Game** %t0
  %t53 = getelementptr inbounds %Game, %Game* %t52, i32 0, i32 0
  %t54 = getelementptr inbounds %Player, %Player* %t53, i32 0, i32 2
  %t55 = load float, float* %t54
  %t56 = fadd float %t55, %t51
  %t57 = load %Game*, %Game** %t0
  %t58 = getelementptr inbounds %Game, %Game* %t57, i32 0, i32 0
  %t59 = getelementptr inbounds %Player, %Player* %t58, i32 0, i32 2
  store float %t56, float* %t59
  %t61 = load float, float* %t1
  %t62 = fmul float 0x4008000000000000, %t61
  store float %t62, float* %t60
  %t64 = load %Game*, %Game** %t0
  %t65 = getelementptr inbounds %Game, %Game* %t64, i32 0, i32 0
  %t66 = getelementptr inbounds %Player, %Player* %t65, i32 0, i32 2
  %t67 = load float, float* %t66
  %t68 = call float @llvm.cos.f32(float %t67)
  store float %t68, float* %t63
  %t70 = load %Game*, %Game** %t0
  %t71 = getelementptr inbounds %Game, %Game* %t70, i32 0, i32 0
  %t72 = getelementptr inbounds %Player, %Player* %t71, i32 0, i32 2
  %t73 = load float, float* %t72
  %t74 = call float @llvm.sin.f32(float %t73)
  store float %t74, float* %t69
  store float 0x0000000000000000, float* %t75
  store float 0x0000000000000000, float* %t76
  %t77 = icmp sge i32 26, 0
  %t78 = icmp slt i32 26, 512
  %t79 = and i1 %t77, %t78
  br i1 %t79, label %key_down_read_1063, label %key_down_end_1064
key_down_read_1063:
  %t80 = call i8* @SDL_GetKeyboardState(i32* null)
  %t81 = sext i32 26 to i64
  %t82 = getelementptr inbounds i8, i8* %t80, i64 %t81
  %t83 = load i8, i8* %t82
  %t84 = icmp ne i8 %t83, 0
  br label %key_down_end_1064
key_down_end_1064:
  %t85 = phi i1 [ false, %if_end_1062 ], [ %t84, %key_down_read_1063 ]
  br i1 %t85, label %logic_short_1066, label %logic_rhs_1065
logic_rhs_1065:
  %t86 = icmp sge i32 82, 0
  %t87 = icmp slt i32 82, 512
  %t88 = and i1 %t86, %t87
  br i1 %t88, label %key_down_read_1068, label %key_down_end_1069
key_down_read_1068:
  %t89 = call i8* @SDL_GetKeyboardState(i32* null)
  %t90 = sext i32 82 to i64
  %t91 = getelementptr inbounds i8, i8* %t89, i64 %t90
  %t92 = load i8, i8* %t91
  %t93 = icmp ne i8 %t92, 0
  br label %key_down_end_1069
key_down_end_1069:
  %t94 = phi i1 [ false, %logic_rhs_1065 ], [ %t93, %key_down_read_1068 ]
  br label %logic_end_1067
logic_short_1066:
  br label %logic_end_1067
logic_end_1067:
  %t95 = phi i1 [ %t94, %key_down_end_1069 ], [ true, %logic_short_1066 ]
  br i1 %t95, label %if_then_1070, label %if_else_1071
if_then_1070:
  %t96 = load float, float* %t63
  %t97 = load float, float* %t75
  %t98 = fadd float %t97, %t96
  store float %t98, float* %t75
  %t99 = load float, float* %t69
  %t100 = load float, float* %t76
  %t101 = fadd float %t100, %t99
  store float %t101, float* %t76
  br label %if_end_1072
if_else_1071:
  br label %if_end_1072
if_end_1072:
  %t102 = icmp sge i32 22, 0
  %t103 = icmp slt i32 22, 512
  %t104 = and i1 %t102, %t103
  br i1 %t104, label %key_down_read_1073, label %key_down_end_1074
key_down_read_1073:
  %t105 = call i8* @SDL_GetKeyboardState(i32* null)
  %t106 = sext i32 22 to i64
  %t107 = getelementptr inbounds i8, i8* %t105, i64 %t106
  %t108 = load i8, i8* %t107
  %t109 = icmp ne i8 %t108, 0
  br label %key_down_end_1074
key_down_end_1074:
  %t110 = phi i1 [ false, %if_end_1072 ], [ %t109, %key_down_read_1073 ]
  br i1 %t110, label %logic_short_1076, label %logic_rhs_1075
logic_rhs_1075:
  %t111 = icmp sge i32 81, 0
  %t112 = icmp slt i32 81, 512
  %t113 = and i1 %t111, %t112
  br i1 %t113, label %key_down_read_1078, label %key_down_end_1079
key_down_read_1078:
  %t114 = call i8* @SDL_GetKeyboardState(i32* null)
  %t115 = sext i32 81 to i64
  %t116 = getelementptr inbounds i8, i8* %t114, i64 %t115
  %t117 = load i8, i8* %t116
  %t118 = icmp ne i8 %t117, 0
  br label %key_down_end_1079
key_down_end_1079:
  %t119 = phi i1 [ false, %logic_rhs_1075 ], [ %t118, %key_down_read_1078 ]
  br label %logic_end_1077
logic_short_1076:
  br label %logic_end_1077
logic_end_1077:
  %t120 = phi i1 [ %t119, %key_down_end_1079 ], [ true, %logic_short_1076 ]
  br i1 %t120, label %if_then_1080, label %if_else_1081
if_then_1080:
  %t121 = load float, float* %t63
  %t122 = load float, float* %t75
  %t123 = fsub float %t122, %t121
  store float %t123, float* %t75
  %t124 = load float, float* %t69
  %t125 = load float, float* %t76
  %t126 = fsub float %t125, %t124
  store float %t126, float* %t76
  br label %if_end_1082
if_else_1081:
  br label %if_end_1082
if_end_1082:
  %t127 = icmp sge i32 4, 0
  %t128 = icmp slt i32 4, 512
  %t129 = and i1 %t127, %t128
  br i1 %t129, label %key_down_read_1083, label %key_down_end_1084
key_down_read_1083:
  %t130 = call i8* @SDL_GetKeyboardState(i32* null)
  %t131 = sext i32 4 to i64
  %t132 = getelementptr inbounds i8, i8* %t130, i64 %t131
  %t133 = load i8, i8* %t132
  %t134 = icmp ne i8 %t133, 0
  br label %key_down_end_1084
key_down_end_1084:
  %t135 = phi i1 [ false, %if_end_1082 ], [ %t134, %key_down_read_1083 ]
  br i1 %t135, label %if_then_1085, label %if_else_1086
if_then_1085:
  %t136 = load float, float* %t69
  %t137 = load float, float* %t75
  %t138 = fadd float %t137, %t136
  store float %t138, float* %t75
  %t139 = load float, float* %t63
  %t140 = load float, float* %t76
  %t141 = fsub float %t140, %t139
  store float %t141, float* %t76
  br label %if_end_1087
if_else_1086:
  br label %if_end_1087
if_end_1087:
  %t142 = icmp sge i32 7, 0
  %t143 = icmp slt i32 7, 512
  %t144 = and i1 %t142, %t143
  br i1 %t144, label %key_down_read_1088, label %key_down_end_1089
key_down_read_1088:
  %t145 = call i8* @SDL_GetKeyboardState(i32* null)
  %t146 = sext i32 7 to i64
  %t147 = getelementptr inbounds i8, i8* %t145, i64 %t146
  %t148 = load i8, i8* %t147
  %t149 = icmp ne i8 %t148, 0
  br label %key_down_end_1089
key_down_end_1089:
  %t150 = phi i1 [ false, %if_end_1087 ], [ %t149, %key_down_read_1088 ]
  br i1 %t150, label %if_then_1090, label %if_else_1091
if_then_1090:
  %t151 = load float, float* %t69
  %t152 = load float, float* %t75
  %t153 = fsub float %t152, %t151
  store float %t153, float* %t75
  %t154 = load float, float* %t63
  %t155 = load float, float* %t76
  %t156 = fadd float %t155, %t154
  store float %t156, float* %t76
  br label %if_end_1092
if_else_1091:
  br label %if_end_1092
if_end_1092:
  %t158 = load float, float* %t75
  %t159 = load float, float* %t75
  %t160 = fmul float %t158, %t159
  %t161 = load float, float* %t76
  %t162 = load float, float* %t76
  %t163 = fmul float %t161, %t162
  %t164 = fadd float %t160, %t163
  %t165 = call float @llvm.sqrt.f32(float %t164)
  store float %t165, float* %t157
  %t166 = load float, float* %t157
  %t167 = fcmp ogt float %t166, 0x0000000000000000
  br i1 %t167, label %if_then_1093, label %if_else_1094
if_then_1093:
  %t168 = load float, float* %t75
  %t169 = load float, float* %t157
  %t170 = fdiv float %t168, %t169
  %t171 = load float, float* %t60
  %t172 = fmul float %t170, %t171
  store float %t172, float* %t75
  %t173 = load float, float* %t76
  %t174 = load float, float* %t157
  %t175 = fdiv float %t173, %t174
  %t176 = load float, float* %t60
  %t177 = fmul float %t175, %t176
  store float %t177, float* %t76
  br label %if_end_1095
if_else_1094:
  br label %if_end_1095
if_end_1095:
  %t179 = load %Game*, %Game** %t0
  %t180 = getelementptr inbounds %Game, %Game* %t179, i32 0, i32 0
  %t181 = getelementptr inbounds %Player, %Player* %t180, i32 0, i32 0
  %t182 = load float, float* %t181
  %t183 = load float, float* %t75
  %t184 = fadd float %t182, %t183
  store float %t184, float* %t178
  %t186 = load %Game*, %Game** %t0
  %t187 = getelementptr inbounds %Game, %Game* %t186, i32 0, i32 0
  %t188 = getelementptr inbounds %Player, %Player* %t187, i32 0, i32 1
  %t189 = load float, float* %t188
  %t190 = load float, float* %t76
  %t191 = fadd float %t189, %t190
  store float %t191, float* %t185
  %t192 = load i8*, i8** %t2
  %t193 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t193)
  %t194 = load float, float* %t178
  %t195 = call i32 @llvm.fptosi.sat.i32.f32(float %t194)
  %t196 = load %Game*, %Game** %t0
  %t197 = getelementptr inbounds %Game, %Game* %t196, i32 0, i32 0
  %t198 = getelementptr inbounds %Player, %Player* %t197, i32 0, i32 1
  %t199 = load float, float* %t198
  %t200 = call i32 @llvm.fptosi.sat.i32.f32(float %t199)
  %t201 = call i32 @map__cell_at(i8* %t192, i32 %t195, i32 %t200)
  %t202 = icmp eq i32 %t201, 0
  br i1 %t202, label %if_then_1096, label %if_else_1097
if_then_1096:
  %t203 = load float, float* %t178
  %t204 = load %Game*, %Game** %t0
  %t205 = getelementptr inbounds %Game, %Game* %t204, i32 0, i32 0
  %t206 = getelementptr inbounds %Player, %Player* %t205, i32 0, i32 0
  store float %t203, float* %t206
  br label %if_end_1098
if_else_1097:
  br label %if_end_1098
if_end_1098:
  %t207 = load i8*, i8** %t2
  %t208 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t208)
  %t209 = load %Game*, %Game** %t0
  %t210 = getelementptr inbounds %Game, %Game* %t209, i32 0, i32 0
  %t211 = getelementptr inbounds %Player, %Player* %t210, i32 0, i32 0
  %t212 = load float, float* %t211
  %t213 = call i32 @llvm.fptosi.sat.i32.f32(float %t212)
  %t214 = load float, float* %t185
  %t215 = call i32 @llvm.fptosi.sat.i32.f32(float %t214)
  %t216 = call i32 @map__cell_at(i8* %t207, i32 %t213, i32 %t215)
  %t217 = icmp eq i32 %t216, 0
  br i1 %t217, label %if_then_1099, label %if_else_1100
if_then_1099:
  %t218 = load float, float* %t185
  %t219 = load %Game*, %Game** %t0
  %t220 = getelementptr inbounds %Game, %Game* %t219, i32 0, i32 0
  %t221 = getelementptr inbounds %Player, %Player* %t220, i32 0, i32 1
  store float %t218, float* %t221
  br label %if_end_1101
if_else_1100:
  br label %if_end_1101
if_end_1101:
  %t225 = call i32 @SDL_GetMouseState(i32* %t223, i32* %t224)
  %t226 = load i32, i32* %t223
  %t227 = load i32, i32* %t224
  %t228 = sub i32 1, 1
  %t229 = and i32 %t228, 31
  %t230 = shl i32 1, %t229
  %t231 = and i32 %t225, %t230
  %t232 = icmp ne i32 %t231, 0
  br i1 %t232, label %logic_short_1103, label %logic_rhs_1102
logic_rhs_1102:
  %t233 = icmp sge i32 44, 0
  %t234 = icmp slt i32 44, 512
  %t235 = and i1 %t233, %t234
  br i1 %t235, label %key_down_read_1105, label %key_down_end_1106
key_down_read_1105:
  %t236 = call i8* @SDL_GetKeyboardState(i32* null)
  %t237 = sext i32 44 to i64
  %t238 = getelementptr inbounds i8, i8* %t236, i64 %t237
  %t239 = load i8, i8* %t238
  %t240 = icmp ne i8 %t239, 0
  br label %key_down_end_1106
key_down_end_1106:
  %t241 = phi i1 [ false, %logic_rhs_1102 ], [ %t240, %key_down_read_1105 ]
  br label %logic_end_1104
logic_short_1103:
  br label %logic_end_1104
logic_end_1104:
  %t242 = phi i1 [ %t241, %key_down_end_1106 ], [ true, %logic_short_1103 ]
  store i1 %t242, i1* %t222
  %t243 = load i1, i1* %t222
  br i1 %t243, label %logic_rhs_1107, label %logic_short_1108
logic_rhs_1107:
  %t244 = load %Game*, %Game** %t0
  %t245 = getelementptr inbounds %Game, %Game* %t244, i32 0, i32 5
  %t246 = load i1, i1* %t245
  %t247 = xor i1 true, %t246
  br label %logic_end_1109
logic_short_1108:
  br label %logic_end_1109
logic_end_1109:
  %t248 = phi i1 [ %t247, %logic_rhs_1107 ], [ false, %logic_short_1108 ]
  br i1 %t248, label %logic_rhs_1110, label %logic_short_1111
logic_rhs_1110:
  %t249 = load %Game*, %Game** %t0
  %t250 = getelementptr inbounds %Game, %Game* %t249, i32 0, i32 0
  %t251 = getelementptr inbounds %Player, %Player* %t250, i32 0, i32 6
  %t252 = load i1, i1* %t251
  br label %logic_end_1112
logic_short_1111:
  br label %logic_end_1112
logic_end_1112:
  %t253 = phi i1 [ %t252, %logic_rhs_1110 ], [ false, %logic_short_1111 ]
  br i1 %t253, label %logic_rhs_1113, label %logic_short_1114
logic_rhs_1113:
  %t254 = load %Game*, %Game** %t0
  %t255 = getelementptr inbounds %Game, %Game* %t254, i32 0, i32 0
  %t256 = getelementptr inbounds %Player, %Player* %t255, i32 0, i32 4
  %t257 = load float, float* %t256
  %t258 = fcmp oge float %t257, 0x4014000000000000
  br label %logic_end_1115
logic_short_1114:
  br label %logic_end_1115
logic_end_1115:
  %t259 = phi i1 [ %t258, %logic_rhs_1113 ], [ false, %logic_short_1114 ]
  br i1 %t259, label %if_then_1116, label %if_else_1117
if_then_1116:
  %t260 = load %Game*, %Game** %t0
  %t261 = getelementptr inbounds %Game, %Game* %t260, i32 0, i32 0
  %t262 = getelementptr inbounds %Player, %Player* %t261, i32 0, i32 4
  %t263 = load float, float* %t262
  %t264 = fsub float %t263, 0x4014000000000000
  %t265 = load %Game*, %Game** %t0
  %t266 = getelementptr inbounds %Game, %Game* %t265, i32 0, i32 0
  %t267 = getelementptr inbounds %Player, %Player* %t266, i32 0, i32 4
  store float %t264, float* %t267
  %t269 = load %Game*, %Game** %t0
  %t270 = getelementptr inbounds %Game, %Game* %t269, i32 0, i32 0
  %t271 = getelementptr inbounds %Player, %Player* %t270, i32 0, i32 0
  %t272 = load float, float* %t271
  %t273 = load float, float* %t63
  %t274 = fmul float %t273, 0x3FE0000000000000
  %t275 = fadd float %t272, %t274
  store float %t275, float* %t268
  %t277 = load %Game*, %Game** %t0
  %t278 = getelementptr inbounds %Game, %Game* %t277, i32 0, i32 0
  %t279 = getelementptr inbounds %Player, %Player* %t278, i32 0, i32 1
  %t280 = load float, float* %t279
  %t281 = load float, float* %t69
  %t282 = fmul float %t281, 0x3FE0000000000000
  %t283 = fadd float %t280, %t282
  store float %t283, float* %t276
  %t284 = load %Game*, %Game** %t0
  %t285 = getelementptr inbounds %Game, %Game* %t284, i32 0, i32 2
  %t286 = getelementptr %Projectile, %Projectile* null, i32 1
  %t287 = ptrtoint %Projectile* %t286 to i64
  %t288 = load i8*, i8** %t285
  %t289 = icmp eq i8* %t288, null
  br i1 %t289, label %list_cow_alloc_1119, label %list_cow_check_1120
list_cow_alloc_1119:
  %t294 = bitcast void (i8*)* @list_release_s_Projectile to i8*
  %t295 = call i8* @star_rc_alloc(i64 24, i8* %t294)
  %t296 = bitcast i8* %t295 to { %Projectile*, i64, i64 }*
  %t297 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t296, i32 0, i32 0
  store %Projectile* null, %Projectile** %t297
  %t298 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t296, i32 0, i32 1
  store i64 0, i64* %t298
  %t299 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t296, i32 0, i32 2
  store i64 0, i64* %t299
  store i8* %t295, i8** %t285
  br label %list_cow_done_1121
list_cow_check_1120:
  %t300 = getelementptr inbounds i8, i8* %t288, i64 -16
  %t301 = bitcast i8* %t300 to i64*
  %t302 = load atomic i64, i64* %t301 seq_cst, align 8
  %t303 = icmp eq i64 %t302, 1
  br i1 %t303, label %list_cow_done_1121, label %list_cow_clone_1122
list_cow_clone_1122:
  %t304 = bitcast i8* %t288 to { %Projectile*, i64, i64 }*
  %t305 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t304, i32 0, i32 0
  %t306 = load %Projectile*, %Projectile** %t305
  %t307 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t304, i32 0, i32 1
  %t308 = load i64, i64* %t307
  %t309 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t304, i32 0, i32 2
  %t310 = load i64, i64* %t309
  %t311 = bitcast void (i8*)* @list_release_s_Projectile to i8*
  %t312 = call i8* @star_rc_alloc(i64 24, i8* %t311)
  %t313 = bitcast i8* %t312 to { %Projectile*, i64, i64 }*
  %t314 = mul i64 %t310, %t287
  %t315 = call i8* @malloc(i64 %t314)
  %t316 = bitcast i8* %t315 to %Projectile*
  %t317 = icmp sgt i64 %t308, 0
  br i1 %t317, label %list_cow_copy_1123, label %list_cow_after_copy_1124
list_cow_copy_1123:
  %t318 = mul i64 %t308, %t287
  %t319 = bitcast %Projectile* %t306 to i8*
  call i8* @memcpy(i8* %t315, i8* %t319, i64 %t318)
  br label %list_cow_after_copy_1124
list_cow_after_copy_1124:
  %t320 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t313, i32 0, i32 0
  store %Projectile* %t316, %Projectile** %t320
  %t321 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t313, i32 0, i32 1
  store i64 %t308, i64* %t321
  %t322 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t313, i32 0, i32 2
  store i64 %t310, i64* %t322
  call void @star_rc_release(i8* %t288)
  store i8* %t312, i8** %t285
  br label %list_cow_done_1121
list_cow_done_1121:
  %t323 = load i8*, i8** %t285
  %t324 = bitcast i8* %t323 to { %Projectile*, i64, i64 }*
  %t325 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t324, i32 0, i32 0
  %t326 = load %Projectile*, %Projectile** %t325
  %t327 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t324, i32 0, i32 1
  %t328 = load i64, i64* %t327
  %t329 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t324, i32 0, i32 2
  %t331 = getelementptr inbounds %Projectile, %Projectile* %t330, i32 0, i32 0
  %t332 = load float, float* %t268
  store float %t332, float* %t331
  %t333 = getelementptr inbounds %Projectile, %Projectile* %t330, i32 0, i32 1
  %t334 = load float, float* %t276
  store float %t334, float* %t333
  %t335 = getelementptr inbounds %Projectile, %Projectile* %t330, i32 0, i32 2
  %t336 = load float, float* %t63
  %t337 = fmul float %t336, 0x4020000000000000
  store float %t337, float* %t335
  %t338 = getelementptr inbounds %Projectile, %Projectile* %t330, i32 0, i32 3
  %t339 = load float, float* %t69
  %t340 = fmul float %t339, 0x4020000000000000
  store float %t340, float* %t338
  %t341 = getelementptr inbounds %Projectile, %Projectile* %t330, i32 0, i32 4
  store i1 true, i1* %t341
  %t342 = getelementptr inbounds %Projectile, %Projectile* %t330, i32 0, i32 5
  store i1 true, i1* %t342
  %t343 = load %Projectile, %Projectile* %t330
  %t344 = load i64, i64* %t329
  %t345 = load %Projectile*, %Projectile** %t325
  %t346 = load i64, i64* %t327
  %t347 = icmp sge i64 %t346, %t344
  br i1 %t347, label %list_push_grow_1125, label %list_push_store_1126
list_push_grow_1125:
  %t348 = mul i64 %t344, 2
  %t349 = icmp sgt i64 %t348, 0
  %t350 = select i1 %t349, i64 %t348, i64 1
  %t351 = getelementptr %Projectile, %Projectile* null, i32 1
  %t352 = ptrtoint %Projectile* %t351 to i64
  %t353 = mul i64 %t350, %t352
  %t354 = call i8* @malloc(i64 %t353)
  %t355 = bitcast i8* %t354 to %Projectile*
  %t356 = icmp sgt i64 %t344, 0
  br i1 %t356, label %list_push_copy_1127, label %list_push_after_copy_1128
list_push_copy_1127:
  %t357 = mul i64 %t346, %t352
  %t358 = bitcast %Projectile* %t345 to i8*
  call i8* @memcpy(i8* %t354, i8* %t358, i64 %t357)
  call void @free(i8* %t358)
  br label %list_push_after_copy_1128
list_push_after_copy_1128:
  store %Projectile* %t355, %Projectile** %t325
  store i64 %t350, i64* %t329
  br label %list_push_store_1126
list_push_store_1126:
  %t359 = load %Projectile*, %Projectile** %t325
  %t360 = getelementptr inbounds %Projectile, %Projectile* %t359, i64 %t346
  store %Projectile %t343, %Projectile* %t360
  %t361 = add i64 %t346, 1
  store i64 %t361, i64* %t327
  %t362 = load %Game*, %Game** %t0
  %t363 = getelementptr inbounds %Game, %Game* %t362, i32 0, i32 4
  store float 0x3FC3333340000000, float* %t363
  %t364 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t3, i32 0, i32 0
  %t365 = load i8*, i8** %t364
  %t366 = icmp eq i8* %t365, null
  %t367 = xor i1 true, %t366
  br i1 %t367, label %if_then_1129, label %if_else_1130
if_then_1129:
  %t368 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t3, i32 0, i32 0
  %t369 = load i8*, i8** %t368
  %t370 = icmp eq i8* %t369, null
  br i1 %t370, label %sound_null_handle_1132, label %sound_handle_ok_1133
sound_null_handle_1132:
  %t371 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.46, i64 0, i64 0
  call i32 @puts(i8* %t371)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_1133:
  %t407 = load i32, i32* @star.audio.device
  %t408 = icmp ne i32 %t407, 0
  br i1 %t408, label %audio_dev_ok_1138, label %audio_dev_init_1137
audio_dev_init_1137:
  %t409 = call i32 @SDL_Init(i32 16)
  %t411 = getelementptr inbounds [32 x i8], [32 x i8]* %t410, i64 0, i64 0
  store i64 0, i64* %t412
  br label %ht_fill8_cond_1139
ht_fill8_cond_1139:
  %t413 = load i64, i64* %t412
  %t414 = icmp slt i64 %t413, 32
  br i1 %t414, label %ht_fill8_body_1140, label %ht_fill8_end_1141
ht_fill8_body_1140:
  %t415 = getelementptr inbounds i8, i8* %t411, i64 %t413
  store i8 0, i8* %t415
  %t416 = add i64 %t413, 1
  store i64 %t416, i64* %t412
  br label %ht_fill8_cond_1139
ht_fill8_end_1141:
  %t417 = bitcast i8* %t411 to i32*
  store i32 44100, i32* %t417
  %t418 = getelementptr inbounds i8, i8* %t411, i64 4
  %t419 = bitcast i8* %t418 to i16*
  store i16 32784, i16* %t419
  %t420 = getelementptr inbounds i8, i8* %t411, i64 6
  store i8 2, i8* %t420
  %t421 = getelementptr inbounds i8, i8* %t411, i64 8
  %t422 = bitcast i8* %t421 to i16*
  store i16 1024, i16* %t422
  %t423 = getelementptr inbounds i8, i8* %t411, i64 16
  %t424 = bitcast i8* %t423 to i8**
  %t425 = bitcast void (i8*, i8*, i32)* @star.audio.mix_callback to i8*
  store i8* %t425, i8** %t424
  %t426 = call i32 @SDL_OpenAudioDevice(i8* null, i32 0, i8* %t411, i8* null, i32 0)
  %t427 = icmp ne i32 %t426, 0
  br i1 %t427, label %audio_open_ok_1142, label %audio_dev_ok_1138
audio_open_ok_1142:
  store i32 %t426, i32* @star.audio.device
  call void @SDL_PauseAudioDevice(i32 %t426, i32 0)
  br label %audio_dev_ok_1138
audio_dev_ok_1138:
  %t428 = bitcast i8* %t369 to i64*
  %t429 = load i64, i64* %t428
  %t430 = getelementptr inbounds i8, i8* %t369, i64 8
  %t431 = bitcast i8* %t430 to i8**
  %t432 = load i8*, i8** %t431
  %t433 = getelementptr inbounds i8, i8* %t432, i64 44
  store i32 -1, i32* %t434
  store i32 1, i32* %t435
  br label %sound_play_scan_cond_1143
sound_play_scan_cond_1143:
  %t436 = load i32, i32* %t435
  %t437 = icmp sge i32 %t436, 16
  br i1 %t437, label %sound_play_scan_end_1147, label %sound_play_scan_check_1144
sound_play_scan_check_1144:
  %t438 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t436
  %t439 = load i8, i8* %t438
  %t440 = icmp eq i8 %t439, 0
  br i1 %t440, label %sound_play_scan_found_1145, label %sound_play_scan_body_1146
sound_play_scan_found_1145:
  store i32 %t436, i32* %t434
  br label %sound_play_scan_end_1147
sound_play_scan_body_1146:
  %t441 = add i32 %t436, 1
  store i32 %t441, i32* %t435
  br label %sound_play_scan_cond_1143
sound_play_scan_end_1147:
  %t442 = load i32, i32* %t434
  %t443 = icmp sge i32 %t442, 0
  br i1 %t443, label %sound_play_do_1148, label %sound_play_after_1149
sound_play_do_1148:
  %t444 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t442
  store i8* %t433, i8** %t444
  %t445 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_len, i32 0, i32 %t442
  store i64 %t429, i64* %t445
  %t446 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_pos, i32 0, i32 %t442
  store i64 0, i64* %t446
  %t447 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 %t442
  store i8 0, i8* %t447
  %t448 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t442
  store i8 1, i8* %t448
  br label %sound_play_after_1149
sound_play_after_1149:
  br label %if_end_1131
if_else_1130:
  br label %if_end_1131
if_end_1131:
  br label %if_end_1118
if_else_1117:
  br label %if_end_1118
if_end_1118:
  %t449 = load i1, i1* %t222
  %t450 = load %Game*, %Game** %t0
  %t451 = getelementptr inbounds %Game, %Game* %t450, i32 0, i32 5
  store i1 %t449, i1* %t451
  %t452 = load %Game*, %Game** %t0
  %t453 = getelementptr inbounds %Game, %Game* %t452, i32 0, i32 4
  %t454 = load float, float* %t453
  %t455 = fcmp ogt float %t454, 0x0000000000000000
  br i1 %t455, label %if_then_1150, label %if_else_1151
if_then_1150:
  %t456 = load float, float* %t1
  %t457 = load %Game*, %Game** %t0
  %t458 = getelementptr inbounds %Game, %Game* %t457, i32 0, i32 4
  %t459 = load float, float* %t458
  %t460 = fsub float %t459, %t456
  %t461 = load %Game*, %Game** %t0
  %t462 = getelementptr inbounds %Game, %Game* %t461, i32 0, i32 4
  store float %t460, float* %t462
  br label %if_end_1152
if_else_1151:
  br label %if_end_1152
if_end_1152:
  %t463 = load %Game*, %Game** %t0
  %t464 = load %Game, %Game* %t463
  %t465 = getelementptr inbounds %Game, %Game* %t463, i32 0, i32 1
  %t466 = load i8*, i8** %t465
  call void @star_rc_retain(i8* %t466)
  %t467 = getelementptr inbounds %Game, %Game* %t463, i32 0, i32 2
  %t468 = load i8*, i8** %t467
  call void @star_rc_retain(i8* %t468)
  %t469 = getelementptr inbounds %Game, %Game* %t463, i32 0, i32 3
  %t470 = load i8*, i8** %t469
  call void @star_rc_retain(i8* %t470)
  %t471 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t471)
  ret %Game %t464
}

define %Game @Game__update_enemies(%Game* %self, float %dt, i8* %map_grid) {
entry:
  %t0 = alloca %Game*
  %t1 = alloca float
  %t2 = alloca i8*
  %t3 = alloca i8*
  %t4 = alloca i32
  %t19 = alloca %Enemy
  %t39 = alloca float
  %t47 = alloca float
  %t55 = alloca float
  %t66 = alloca float
  %t71 = alloca float
  %t75 = alloca float
  %t84 = alloca float
  %t146 = alloca float
  %t156 = alloca float
  %t208 = alloca %Projectile
  store %Game* %self, %Game** %t0
  store float %dt, float* %t1
  store i8* %map_grid, i8** %t2
  store i8* null, i8** %t3
  store i32 0, i32* %t4
  br label %while_cond_1153
while_cond_1153:
  %t5 = load i32, i32* %t4
  %t6 = load %Game*, %Game** %t0
  %t7 = getelementptr inbounds %Game, %Game* %t6, i32 0, i32 1
  %t8 = load i8*, i8** %t7
  %t9 = icmp eq i8* %t8, null
  br i1 %t9, label %list_read_null_1157, label %list_read_real_1158
list_read_null_1157:
  br label %list_read_end_1159
list_read_real_1158:
  %t10 = bitcast i8* %t8 to { %Enemy*, i64, i64 }*
  %t11 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t10, i32 0, i32 0
  %t12 = load %Enemy*, %Enemy** %t11
  %t13 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t10, i32 0, i32 1
  %t14 = load i64, i64* %t13
  br label %list_read_end_1159
list_read_end_1159:
  %t15 = phi %Enemy* [ null, %list_read_null_1157 ], [ %t12, %list_read_real_1158 ]
  %t16 = phi i64 [ 0, %list_read_null_1157 ], [ %t14, %list_read_real_1158 ]
  %t17 = trunc i64 %t16 to i32
  %t18 = icmp slt i32 %t5, %t17
  br i1 %t18, label %while_body_1154, label %while_else_1155
while_body_1154:
  %t20 = load %Game*, %Game** %t0
  %t21 = getelementptr inbounds %Game, %Game* %t20, i32 0, i32 1
  %t22 = load i8*, i8** %t21
  %t23 = icmp eq i8* %t22, null
  br i1 %t23, label %list_read_null_1160, label %list_read_real_1161
list_read_null_1160:
  br label %list_read_end_1162
list_read_real_1161:
  %t24 = bitcast i8* %t22 to { %Enemy*, i64, i64 }*
  %t25 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t24, i32 0, i32 0
  %t26 = load %Enemy*, %Enemy** %t25
  %t27 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t24, i32 0, i32 1
  %t28 = load i64, i64* %t27
  br label %list_read_end_1162
list_read_end_1162:
  %t29 = phi %Enemy* [ null, %list_read_null_1160 ], [ %t26, %list_read_real_1161 ]
  %t30 = phi i64 [ 0, %list_read_null_1160 ], [ %t28, %list_read_real_1161 ]
  %t31 = load i32, i32* %t4
  %t32 = sext i32 %t31 to i64
  %t33 = icmp ult i64 %t32, %t30
  br i1 %t33, label %list_idx_ok_1163, label %list_idx_oob_1164
list_idx_ok_1163:
  %t34 = getelementptr inbounds %Enemy, %Enemy* %t29, i64 %t32
  %t35 = load %Enemy, %Enemy* %t34
  br label %list_idx_end_1165
list_idx_oob_1164:
  br label %list_idx_end_1165
list_idx_end_1165:
  %t36 = phi %Enemy [ %t35, %list_idx_ok_1163 ], [ zeroinitializer, %list_idx_oob_1164 ]
  store %Enemy %t36, %Enemy* %t19
  %t37 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 4
  %t38 = load i1, i1* %t37
  br i1 %t38, label %if_then_1166, label %if_else_1167
if_then_1166:
  %t40 = load %Game*, %Game** %t0
  %t41 = getelementptr inbounds %Game, %Game* %t40, i32 0, i32 0
  %t42 = getelementptr inbounds %Player, %Player* %t41, i32 0, i32 0
  %t43 = load float, float* %t42
  %t44 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  %t45 = load float, float* %t44
  %t46 = fsub float %t43, %t45
  store float %t46, float* %t39
  %t48 = load %Game*, %Game** %t0
  %t49 = getelementptr inbounds %Game, %Game* %t48, i32 0, i32 0
  %t50 = getelementptr inbounds %Player, %Player* %t49, i32 0, i32 1
  %t51 = load float, float* %t50
  %t52 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 1
  %t53 = load float, float* %t52
  %t54 = fsub float %t51, %t53
  store float %t54, float* %t47
  %t56 = load float, float* %t39
  %t57 = load float, float* %t39
  %t58 = fmul float %t56, %t57
  %t59 = load float, float* %t47
  %t60 = load float, float* %t47
  %t61 = fmul float %t59, %t60
  %t62 = fadd float %t58, %t61
  %t63 = call float @llvm.sqrt.f32(float %t62)
  store float %t63, float* %t55
  %t64 = load float, float* %t55
  %t65 = fcmp ogt float %t64, 0x3FB99999A0000000
  br i1 %t65, label %if_then_1169, label %if_else_1170
if_then_1169:
  %t67 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 3
  %t68 = load i32, i32* %t67
  %t69 = icmp eq i32 %t68, 0
  br i1 %t69, label %if_then_1172, label %if_else_1173
if_then_1172:
  br label %if_end_1174
if_else_1173:
  br label %if_end_1174
if_end_1174:
  %t70 = phi float [ 0x3FF8000000000000, %if_then_1172 ], [ 0x3FE99999A0000000, %if_else_1173 ]
  store float %t70, float* %t66
  %t72 = load float, float* %t66
  %t73 = load float, float* %t1
  %t74 = fmul float %t72, %t73
  store float %t74, float* %t71
  %t76 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  %t77 = load float, float* %t76
  %t78 = load float, float* %t39
  %t79 = load float, float* %t55
  %t80 = fdiv float %t78, %t79
  %t81 = load float, float* %t71
  %t82 = fmul float %t80, %t81
  %t83 = fadd float %t77, %t82
  store float %t83, float* %t75
  %t85 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 1
  %t86 = load float, float* %t85
  %t87 = load float, float* %t47
  %t88 = load float, float* %t55
  %t89 = fdiv float %t87, %t88
  %t90 = load float, float* %t71
  %t91 = fmul float %t89, %t90
  %t92 = fadd float %t86, %t91
  store float %t92, float* %t84
  %t93 = load i8*, i8** %t2
  %t94 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t94)
  %t95 = load float, float* %t75
  %t96 = call i32 @llvm.fptosi.sat.i32.f32(float %t95)
  %t97 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 1
  %t98 = load float, float* %t97
  %t99 = call i32 @llvm.fptosi.sat.i32.f32(float %t98)
  %t100 = call i32 @map__cell_at(i8* %t93, i32 %t96, i32 %t99)
  %t101 = icmp eq i32 %t100, 0
  br i1 %t101, label %if_then_1175, label %if_else_1176
if_then_1175:
  %t102 = load float, float* %t75
  %t103 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  store float %t102, float* %t103
  br label %if_end_1177
if_else_1176:
  br label %if_end_1177
if_end_1177:
  %t104 = load i8*, i8** %t2
  %t105 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t105)
  %t106 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  %t107 = load float, float* %t106
  %t108 = call i32 @llvm.fptosi.sat.i32.f32(float %t107)
  %t109 = load float, float* %t84
  %t110 = call i32 @llvm.fptosi.sat.i32.f32(float %t109)
  %t111 = call i32 @map__cell_at(i8* %t104, i32 %t108, i32 %t110)
  %t112 = icmp eq i32 %t111, 0
  br i1 %t112, label %if_then_1178, label %if_else_1179
if_then_1178:
  %t113 = load float, float* %t84
  %t114 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 1
  store float %t113, float* %t114
  br label %if_end_1180
if_else_1179:
  br label %if_end_1180
if_end_1180:
  br label %if_end_1171
if_else_1170:
  br label %if_end_1171
if_end_1171:
  %t115 = load float, float* %t1
  %t116 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 5
  %t117 = load float, float* %t116
  %t118 = fsub float %t117, %t115
  %t119 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 5
  store float %t118, float* %t119
  %t120 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 3
  %t121 = load i32, i32* %t120
  %t122 = icmp eq i32 %t121, 0
  br i1 %t122, label %logic_rhs_1181, label %logic_short_1182
logic_rhs_1181:
  %t123 = load float, float* %t55
  %t124 = fcmp olt float %t123, 0x4018000000000000
  br label %logic_end_1183
logic_short_1182:
  br label %logic_end_1183
logic_end_1183:
  %t125 = phi i1 [ %t124, %logic_rhs_1181 ], [ false, %logic_short_1182 ]
  br i1 %t125, label %logic_rhs_1184, label %logic_short_1185
logic_rhs_1184:
  %t126 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 5
  %t127 = load float, float* %t126
  %t128 = fcmp ole float %t127, 0x0000000000000000
  br label %logic_end_1186
logic_short_1185:
  br label %logic_end_1186
logic_end_1186:
  %t129 = phi i1 [ %t128, %logic_rhs_1184 ], [ false, %logic_short_1185 ]
  br i1 %t129, label %logic_rhs_1187, label %logic_short_1188
logic_rhs_1187:
  %t130 = load i8*, i8** %t2
  %t131 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t131)
  %t132 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  %t133 = load float, float* %t132
  %t134 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 1
  %t135 = load float, float* %t134
  %t136 = load %Game*, %Game** %t0
  %t137 = getelementptr inbounds %Game, %Game* %t136, i32 0, i32 0
  %t138 = getelementptr inbounds %Player, %Player* %t137, i32 0, i32 0
  %t139 = load float, float* %t138
  %t140 = load %Game*, %Game** %t0
  %t141 = getelementptr inbounds %Game, %Game* %t140, i32 0, i32 0
  %t142 = getelementptr inbounds %Player, %Player* %t141, i32 0, i32 1
  %t143 = load float, float* %t142
  %t144 = call i1 @has_los(i8* %t130, float %t133, float %t135, float %t139, float %t143)
  br label %logic_end_1189
logic_short_1188:
  br label %logic_end_1189
logic_end_1189:
  %t145 = phi i1 [ %t144, %logic_rhs_1187 ], [ false, %logic_short_1188 ]
  br i1 %t145, label %if_then_1190, label %if_else_1191
if_then_1190:
  %t147 = load %Game*, %Game** %t0
  %t148 = getelementptr inbounds %Game, %Game* %t147, i32 0, i32 0
  %t149 = getelementptr inbounds %Player, %Player* %t148, i32 0, i32 0
  %t150 = load float, float* %t149
  %t151 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  %t152 = load float, float* %t151
  %t153 = fsub float %t150, %t152
  %t154 = load float, float* %t55
  %t155 = fdiv float %t153, %t154
  store float %t155, float* %t146
  %t157 = load %Game*, %Game** %t0
  %t158 = getelementptr inbounds %Game, %Game* %t157, i32 0, i32 0
  %t159 = getelementptr inbounds %Player, %Player* %t158, i32 0, i32 1
  %t160 = load float, float* %t159
  %t161 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 1
  %t162 = load float, float* %t161
  %t163 = fsub float %t160, %t162
  %t164 = load float, float* %t55
  %t165 = fdiv float %t163, %t164
  store float %t165, float* %t156
  %t166 = load %Game*, %Game** %t0
  %t167 = getelementptr inbounds %Game, %Game* %t166, i32 0, i32 2
  %t168 = getelementptr %Projectile, %Projectile* null, i32 1
  %t169 = ptrtoint %Projectile* %t168 to i64
  %t170 = load i8*, i8** %t167
  %t171 = icmp eq i8* %t170, null
  br i1 %t171, label %list_cow_alloc_1193, label %list_cow_check_1194
list_cow_alloc_1193:
  %t172 = bitcast void (i8*)* @list_release_s_Projectile to i8*
  %t173 = call i8* @star_rc_alloc(i64 24, i8* %t172)
  %t174 = bitcast i8* %t173 to { %Projectile*, i64, i64 }*
  %t175 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t174, i32 0, i32 0
  store %Projectile* null, %Projectile** %t175
  %t176 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t174, i32 0, i32 1
  store i64 0, i64* %t176
  %t177 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t174, i32 0, i32 2
  store i64 0, i64* %t177
  store i8* %t173, i8** %t167
  br label %list_cow_done_1195
list_cow_check_1194:
  %t178 = getelementptr inbounds i8, i8* %t170, i64 -16
  %t179 = bitcast i8* %t178 to i64*
  %t180 = load atomic i64, i64* %t179 seq_cst, align 8
  %t181 = icmp eq i64 %t180, 1
  br i1 %t181, label %list_cow_done_1195, label %list_cow_clone_1196
list_cow_clone_1196:
  %t182 = bitcast i8* %t170 to { %Projectile*, i64, i64 }*
  %t183 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t182, i32 0, i32 0
  %t184 = load %Projectile*, %Projectile** %t183
  %t185 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t182, i32 0, i32 1
  %t186 = load i64, i64* %t185
  %t187 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t182, i32 0, i32 2
  %t188 = load i64, i64* %t187
  %t189 = bitcast void (i8*)* @list_release_s_Projectile to i8*
  %t190 = call i8* @star_rc_alloc(i64 24, i8* %t189)
  %t191 = bitcast i8* %t190 to { %Projectile*, i64, i64 }*
  %t192 = mul i64 %t188, %t169
  %t193 = call i8* @malloc(i64 %t192)
  %t194 = bitcast i8* %t193 to %Projectile*
  %t195 = icmp sgt i64 %t186, 0
  br i1 %t195, label %list_cow_copy_1197, label %list_cow_after_copy_1198
list_cow_copy_1197:
  %t196 = mul i64 %t186, %t169
  %t197 = bitcast %Projectile* %t184 to i8*
  call i8* @memcpy(i8* %t193, i8* %t197, i64 %t196)
  br label %list_cow_after_copy_1198
list_cow_after_copy_1198:
  %t198 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t191, i32 0, i32 0
  store %Projectile* %t194, %Projectile** %t198
  %t199 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t191, i32 0, i32 1
  store i64 %t186, i64* %t199
  %t200 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t191, i32 0, i32 2
  store i64 %t188, i64* %t200
  call void @star_rc_release(i8* %t170)
  store i8* %t190, i8** %t167
  br label %list_cow_done_1195
list_cow_done_1195:
  %t201 = load i8*, i8** %t167
  %t202 = bitcast i8* %t201 to { %Projectile*, i64, i64 }*
  %t203 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t202, i32 0, i32 0
  %t204 = load %Projectile*, %Projectile** %t203
  %t205 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t202, i32 0, i32 1
  %t206 = load i64, i64* %t205
  %t207 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t202, i32 0, i32 2
  %t209 = getelementptr inbounds %Projectile, %Projectile* %t208, i32 0, i32 0
  %t210 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 0
  %t211 = load float, float* %t210
  store float %t211, float* %t209
  %t212 = getelementptr inbounds %Projectile, %Projectile* %t208, i32 0, i32 1
  %t213 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 1
  %t214 = load float, float* %t213
  store float %t214, float* %t212
  %t215 = getelementptr inbounds %Projectile, %Projectile* %t208, i32 0, i32 2
  %t216 = load float, float* %t146
  %t217 = fmul float %t216, 0x4010000000000000
  store float %t217, float* %t215
  %t218 = getelementptr inbounds %Projectile, %Projectile* %t208, i32 0, i32 3
  %t219 = load float, float* %t156
  %t220 = fmul float %t219, 0x4010000000000000
  store float %t220, float* %t218
  %t221 = getelementptr inbounds %Projectile, %Projectile* %t208, i32 0, i32 4
  store i1 false, i1* %t221
  %t222 = getelementptr inbounds %Projectile, %Projectile* %t208, i32 0, i32 5
  store i1 true, i1* %t222
  %t223 = load %Projectile, %Projectile* %t208
  %t224 = load i64, i64* %t207
  %t225 = load %Projectile*, %Projectile** %t203
  %t226 = load i64, i64* %t205
  %t227 = icmp sge i64 %t226, %t224
  br i1 %t227, label %list_push_grow_1199, label %list_push_store_1200
list_push_grow_1199:
  %t228 = mul i64 %t224, 2
  %t229 = icmp sgt i64 %t228, 0
  %t230 = select i1 %t229, i64 %t228, i64 1
  %t231 = getelementptr %Projectile, %Projectile* null, i32 1
  %t232 = ptrtoint %Projectile* %t231 to i64
  %t233 = mul i64 %t230, %t232
  %t234 = call i8* @malloc(i64 %t233)
  %t235 = bitcast i8* %t234 to %Projectile*
  %t236 = icmp sgt i64 %t224, 0
  br i1 %t236, label %list_push_copy_1201, label %list_push_after_copy_1202
list_push_copy_1201:
  %t237 = mul i64 %t226, %t232
  %t238 = bitcast %Projectile* %t225 to i8*
  call i8* @memcpy(i8* %t234, i8* %t238, i64 %t237)
  call void @free(i8* %t238)
  br label %list_push_after_copy_1202
list_push_after_copy_1202:
  store %Projectile* %t235, %Projectile** %t203
  store i64 %t230, i64* %t207
  br label %list_push_store_1200
list_push_store_1200:
  %t239 = load %Projectile*, %Projectile** %t203
  %t240 = getelementptr inbounds %Projectile, %Projectile* %t239, i64 %t226
  store %Projectile %t223, %Projectile* %t240
  %t241 = add i64 %t226, 1
  store i64 %t241, i64* %t205
  %t242 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 5
  store float 0x4000000000000000, float* %t242
  br label %if_end_1192
if_else_1191:
  br label %if_end_1192
if_end_1192:
  %t243 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 3
  %t244 = load i32, i32* %t243
  %t245 = icmp eq i32 %t244, 1
  br i1 %t245, label %logic_rhs_1203, label %logic_short_1204
logic_rhs_1203:
  %t246 = load float, float* %t55
  %t247 = fcmp olt float %t246, 0x3FF8000000000000
  br label %logic_end_1205
logic_short_1204:
  br label %logic_end_1205
logic_end_1205:
  %t248 = phi i1 [ %t247, %logic_rhs_1203 ], [ false, %logic_short_1204 ]
  br i1 %t248, label %logic_rhs_1206, label %logic_short_1207
logic_rhs_1206:
  %t249 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 5
  %t250 = load float, float* %t249
  %t251 = fcmp ole float %t250, 0x0000000000000000
  br label %logic_end_1208
logic_short_1207:
  br label %logic_end_1208
logic_end_1208:
  %t252 = phi i1 [ %t251, %logic_rhs_1206 ], [ false, %logic_short_1207 ]
  br i1 %t252, label %if_then_1209, label %if_else_1210
if_then_1209:
  %t253 = load %Game*, %Game** %t0
  %t254 = getelementptr inbounds %Game, %Game* %t253, i32 0, i32 0
  %t255 = getelementptr inbounds %Player, %Player* %t254, i32 0, i32 3
  %t256 = load float, float* %t255
  %t257 = fsub float %t256, 0x4024000000000000
  %t258 = load %Game*, %Game** %t0
  %t259 = getelementptr inbounds %Game, %Game* %t258, i32 0, i32 0
  %t260 = getelementptr inbounds %Player, %Player* %t259, i32 0, i32 3
  store float %t257, float* %t260
  %t261 = load %Game*, %Game** %t0
  %t262 = getelementptr inbounds %Game, %Game* %t261, i32 0, i32 0
  %t263 = getelementptr inbounds %Player, %Player* %t262, i32 0, i32 3
  %t264 = load float, float* %t263
  %t265 = fcmp ole float %t264, 0x0000000000000000
  br i1 %t265, label %if_then_1212, label %if_else_1213
if_then_1212:
  %t266 = load %Game*, %Game** %t0
  %t267 = getelementptr inbounds %Game, %Game* %t266, i32 0, i32 0
  %t268 = getelementptr inbounds %Player, %Player* %t267, i32 0, i32 3
  store float 0x0000000000000000, float* %t268
  %t269 = load %Game*, %Game** %t0
  %t270 = getelementptr inbounds %Game, %Game* %t269, i32 0, i32 0
  %t271 = getelementptr inbounds %Player, %Player* %t270, i32 0, i32 6
  store i1 false, i1* %t271
  br label %if_end_1214
if_else_1213:
  br label %if_end_1214
if_end_1214:
  %t272 = getelementptr inbounds %Enemy, %Enemy* %t19, i32 0, i32 5
  store float 0x3FF0000000000000, float* %t272
  br label %if_end_1211
if_else_1210:
  br label %if_end_1211
if_end_1211:
  br label %if_end_1168
if_else_1167:
  br label %if_end_1168
if_end_1168:
  %t273 = getelementptr %Enemy, %Enemy* null, i32 1
  %t274 = ptrtoint %Enemy* %t273 to i64
  %t275 = load i8*, i8** %t3
  %t276 = icmp eq i8* %t275, null
  br i1 %t276, label %list_cow_alloc_1215, label %list_cow_check_1216
list_cow_alloc_1215:
  %t277 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t278 = call i8* @star_rc_alloc(i64 24, i8* %t277)
  %t279 = bitcast i8* %t278 to { %Enemy*, i64, i64 }*
  %t280 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t279, i32 0, i32 0
  store %Enemy* null, %Enemy** %t280
  %t281 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t279, i32 0, i32 1
  store i64 0, i64* %t281
  %t282 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t279, i32 0, i32 2
  store i64 0, i64* %t282
  store i8* %t278, i8** %t3
  br label %list_cow_done_1217
list_cow_check_1216:
  %t283 = getelementptr inbounds i8, i8* %t275, i64 -16
  %t284 = bitcast i8* %t283 to i64*
  %t285 = load atomic i64, i64* %t284 seq_cst, align 8
  %t286 = icmp eq i64 %t285, 1
  br i1 %t286, label %list_cow_done_1217, label %list_cow_clone_1218
list_cow_clone_1218:
  %t287 = bitcast i8* %t275 to { %Enemy*, i64, i64 }*
  %t288 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t287, i32 0, i32 0
  %t289 = load %Enemy*, %Enemy** %t288
  %t290 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t287, i32 0, i32 1
  %t291 = load i64, i64* %t290
  %t292 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t287, i32 0, i32 2
  %t293 = load i64, i64* %t292
  %t294 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t295 = call i8* @star_rc_alloc(i64 24, i8* %t294)
  %t296 = bitcast i8* %t295 to { %Enemy*, i64, i64 }*
  %t297 = mul i64 %t293, %t274
  %t298 = call i8* @malloc(i64 %t297)
  %t299 = bitcast i8* %t298 to %Enemy*
  %t300 = icmp sgt i64 %t291, 0
  br i1 %t300, label %list_cow_copy_1219, label %list_cow_after_copy_1220
list_cow_copy_1219:
  %t301 = mul i64 %t291, %t274
  %t302 = bitcast %Enemy* %t289 to i8*
  call i8* @memcpy(i8* %t298, i8* %t302, i64 %t301)
  br label %list_cow_after_copy_1220
list_cow_after_copy_1220:
  %t303 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t296, i32 0, i32 0
  store %Enemy* %t299, %Enemy** %t303
  %t304 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t296, i32 0, i32 1
  store i64 %t291, i64* %t304
  %t305 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t296, i32 0, i32 2
  store i64 %t293, i64* %t305
  call void @star_rc_release(i8* %t275)
  store i8* %t295, i8** %t3
  br label %list_cow_done_1217
list_cow_done_1217:
  %t306 = load i8*, i8** %t3
  %t307 = bitcast i8* %t306 to { %Enemy*, i64, i64 }*
  %t308 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t307, i32 0, i32 0
  %t309 = load %Enemy*, %Enemy** %t308
  %t310 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t307, i32 0, i32 1
  %t311 = load i64, i64* %t310
  %t312 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t307, i32 0, i32 2
  %t313 = load %Enemy, %Enemy* %t19
  %t314 = load i64, i64* %t312
  %t315 = load %Enemy*, %Enemy** %t308
  %t316 = load i64, i64* %t310
  %t317 = icmp sge i64 %t316, %t314
  br i1 %t317, label %list_push_grow_1221, label %list_push_store_1222
list_push_grow_1221:
  %t318 = mul i64 %t314, 2
  %t319 = icmp sgt i64 %t318, 0
  %t320 = select i1 %t319, i64 %t318, i64 1
  %t321 = getelementptr %Enemy, %Enemy* null, i32 1
  %t322 = ptrtoint %Enemy* %t321 to i64
  %t323 = mul i64 %t320, %t322
  %t324 = call i8* @malloc(i64 %t323)
  %t325 = bitcast i8* %t324 to %Enemy*
  %t326 = icmp sgt i64 %t314, 0
  br i1 %t326, label %list_push_copy_1223, label %list_push_after_copy_1224
list_push_copy_1223:
  %t327 = mul i64 %t316, %t322
  %t328 = bitcast %Enemy* %t315 to i8*
  call i8* @memcpy(i8* %t324, i8* %t328, i64 %t327)
  call void @free(i8* %t328)
  br label %list_push_after_copy_1224
list_push_after_copy_1224:
  store %Enemy* %t325, %Enemy** %t308
  store i64 %t320, i64* %t312
  br label %list_push_store_1222
list_push_store_1222:
  %t329 = load %Enemy*, %Enemy** %t308
  %t330 = getelementptr inbounds %Enemy, %Enemy* %t329, i64 %t316
  store %Enemy %t313, %Enemy* %t330
  %t331 = add i64 %t316, 1
  store i64 %t331, i64* %t310
  %t332 = load i32, i32* %t4
  %t333 = add i32 %t332, 1
  store i32 %t333, i32* %t4
  br label %while_cond_1153
while_else_1155:
  br label %while_end_1156
while_end_1156:
  %t334 = load i8*, i8** %t3
  %t335 = load i8*, i8** %t3
  call void @star_rc_retain(i8* %t335)
  %t336 = load %Game*, %Game** %t0
  %t337 = getelementptr inbounds %Game, %Game* %t336, i32 0, i32 1
  %t338 = load i8*, i8** %t337
  call void @star_rc_release(i8* %t338)
  store i8* %t334, i8** %t337
  %t339 = load %Game*, %Game** %t0
  %t340 = load %Game, %Game* %t339
  %t341 = getelementptr inbounds %Game, %Game* %t339, i32 0, i32 1
  %t342 = load i8*, i8** %t341
  call void @star_rc_retain(i8* %t342)
  %t343 = getelementptr inbounds %Game, %Game* %t339, i32 0, i32 2
  %t344 = load i8*, i8** %t343
  call void @star_rc_retain(i8* %t344)
  %t345 = getelementptr inbounds %Game, %Game* %t339, i32 0, i32 3
  %t346 = load i8*, i8** %t345
  call void @star_rc_retain(i8* %t346)
  %t347 = load i8*, i8** %t3
  call void @star_rc_release(i8* %t347)
  %t348 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t348)
  ret %Game %t340
}

define %Game @Game__update_projectiles(%Game* %self, float %dt, i8* %map_grid) {
entry:
  %t0 = alloca %Game*
  %t1 = alloca float
  %t2 = alloca i8*
  %t3 = alloca i8*
  %t4 = alloca i8*
  %t5 = alloca i32
  %t20 = alloca %Projectile
  %t69 = alloca i32
  %t84 = alloca %Enemy
  %t104 = alloca float
  %t110 = alloca float
  %t125 = alloca %Enemy
  %t209 = alloca float
  %t217 = alloca float
  %t315 = alloca i32
  %t330 = alloca %Enemy
  store %Game* %self, %Game** %t0
  store float %dt, float* %t1
  store i8* %map_grid, i8** %t2
  store i8* null, i8** %t3
  store i8* null, i8** %t4
  store i32 0, i32* %t5
  br label %while_cond_1225
while_cond_1225:
  %t6 = load i32, i32* %t5
  %t7 = load %Game*, %Game** %t0
  %t8 = getelementptr inbounds %Game, %Game* %t7, i32 0, i32 2
  %t9 = load i8*, i8** %t8
  %t10 = icmp eq i8* %t9, null
  br i1 %t10, label %list_read_null_1229, label %list_read_real_1230
list_read_null_1229:
  br label %list_read_end_1231
list_read_real_1230:
  %t11 = bitcast i8* %t9 to { %Projectile*, i64, i64 }*
  %t12 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t11, i32 0, i32 0
  %t13 = load %Projectile*, %Projectile** %t12
  %t14 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t11, i32 0, i32 1
  %t15 = load i64, i64* %t14
  br label %list_read_end_1231
list_read_end_1231:
  %t16 = phi %Projectile* [ null, %list_read_null_1229 ], [ %t13, %list_read_real_1230 ]
  %t17 = phi i64 [ 0, %list_read_null_1229 ], [ %t15, %list_read_real_1230 ]
  %t18 = trunc i64 %t17 to i32
  %t19 = icmp slt i32 %t6, %t18
  br i1 %t19, label %while_body_1226, label %while_else_1227
while_body_1226:
  %t21 = load %Game*, %Game** %t0
  %t22 = getelementptr inbounds %Game, %Game* %t21, i32 0, i32 2
  %t23 = load i8*, i8** %t22
  %t24 = icmp eq i8* %t23, null
  br i1 %t24, label %list_read_null_1232, label %list_read_real_1233
list_read_null_1232:
  br label %list_read_end_1234
list_read_real_1233:
  %t25 = bitcast i8* %t23 to { %Projectile*, i64, i64 }*
  %t26 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t25, i32 0, i32 0
  %t27 = load %Projectile*, %Projectile** %t26
  %t28 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t25, i32 0, i32 1
  %t29 = load i64, i64* %t28
  br label %list_read_end_1234
list_read_end_1234:
  %t30 = phi %Projectile* [ null, %list_read_null_1232 ], [ %t27, %list_read_real_1233 ]
  %t31 = phi i64 [ 0, %list_read_null_1232 ], [ %t29, %list_read_real_1233 ]
  %t32 = load i32, i32* %t5
  %t33 = sext i32 %t32 to i64
  %t34 = icmp ult i64 %t33, %t31
  br i1 %t34, label %list_idx_ok_1235, label %list_idx_oob_1236
list_idx_ok_1235:
  %t35 = getelementptr inbounds %Projectile, %Projectile* %t30, i64 %t33
  %t36 = load %Projectile, %Projectile* %t35
  br label %list_idx_end_1237
list_idx_oob_1236:
  br label %list_idx_end_1237
list_idx_end_1237:
  %t37 = phi %Projectile [ %t36, %list_idx_ok_1235 ], [ zeroinitializer, %list_idx_oob_1236 ]
  store %Projectile %t37, %Projectile* %t20
  %t38 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 5
  %t39 = load i1, i1* %t38
  br i1 %t39, label %if_then_1238, label %if_else_1239
if_then_1238:
  %t40 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 2
  %t41 = load float, float* %t40
  %t42 = load float, float* %t1
  %t43 = fmul float %t41, %t42
  %t44 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 0
  %t45 = load float, float* %t44
  %t46 = fadd float %t45, %t43
  %t47 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 0
  store float %t46, float* %t47
  %t48 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 3
  %t49 = load float, float* %t48
  %t50 = load float, float* %t1
  %t51 = fmul float %t49, %t50
  %t52 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 1
  %t53 = load float, float* %t52
  %t54 = fadd float %t53, %t51
  %t55 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 1
  store float %t54, float* %t55
  %t56 = load i8*, i8** %t2
  %t57 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t57)
  %t58 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 0
  %t59 = load float, float* %t58
  %t60 = call i32 @llvm.fptosi.sat.i32.f32(float %t59)
  %t61 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 1
  %t62 = load float, float* %t61
  %t63 = call i32 @llvm.fptosi.sat.i32.f32(float %t62)
  %t64 = call i32 @map__cell_at(i8* %t56, i32 %t60, i32 %t63)
  %t65 = icmp sgt i32 %t64, 0
  br i1 %t65, label %if_then_1241, label %if_else_1242
if_then_1241:
  %t66 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 5
  store i1 false, i1* %t66
  br label %if_end_1243
if_else_1242:
  %t67 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 4
  %t68 = load i1, i1* %t67
  br i1 %t68, label %if_then_1244, label %if_else_1245
if_then_1244:
  store i32 0, i32* %t69
  br label %while_cond_1247
while_cond_1247:
  %t70 = load i32, i32* %t69
  %t71 = load %Game*, %Game** %t0
  %t72 = getelementptr inbounds %Game, %Game* %t71, i32 0, i32 1
  %t73 = load i8*, i8** %t72
  %t74 = icmp eq i8* %t73, null
  br i1 %t74, label %list_read_null_1251, label %list_read_real_1252
list_read_null_1251:
  br label %list_read_end_1253
list_read_real_1252:
  %t75 = bitcast i8* %t73 to { %Enemy*, i64, i64 }*
  %t76 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t75, i32 0, i32 0
  %t77 = load %Enemy*, %Enemy** %t76
  %t78 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t75, i32 0, i32 1
  %t79 = load i64, i64* %t78
  br label %list_read_end_1253
list_read_end_1253:
  %t80 = phi %Enemy* [ null, %list_read_null_1251 ], [ %t77, %list_read_real_1252 ]
  %t81 = phi i64 [ 0, %list_read_null_1251 ], [ %t79, %list_read_real_1252 ]
  %t82 = trunc i64 %t81 to i32
  %t83 = icmp slt i32 %t70, %t82
  br i1 %t83, label %while_body_1248, label %while_else_1249
while_body_1248:
  %t85 = load %Game*, %Game** %t0
  %t86 = getelementptr inbounds %Game, %Game* %t85, i32 0, i32 1
  %t87 = load i8*, i8** %t86
  %t88 = icmp eq i8* %t87, null
  br i1 %t88, label %list_read_null_1254, label %list_read_real_1255
list_read_null_1254:
  br label %list_read_end_1256
list_read_real_1255:
  %t89 = bitcast i8* %t87 to { %Enemy*, i64, i64 }*
  %t90 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t89, i32 0, i32 0
  %t91 = load %Enemy*, %Enemy** %t90
  %t92 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t89, i32 0, i32 1
  %t93 = load i64, i64* %t92
  br label %list_read_end_1256
list_read_end_1256:
  %t94 = phi %Enemy* [ null, %list_read_null_1254 ], [ %t91, %list_read_real_1255 ]
  %t95 = phi i64 [ 0, %list_read_null_1254 ], [ %t93, %list_read_real_1255 ]
  %t96 = load i32, i32* %t69
  %t97 = sext i32 %t96 to i64
  %t98 = icmp ult i64 %t97, %t95
  br i1 %t98, label %list_idx_ok_1257, label %list_idx_oob_1258
list_idx_ok_1257:
  %t99 = getelementptr inbounds %Enemy, %Enemy* %t94, i64 %t97
  %t100 = load %Enemy, %Enemy* %t99
  br label %list_idx_end_1259
list_idx_oob_1258:
  br label %list_idx_end_1259
list_idx_end_1259:
  %t101 = phi %Enemy [ %t100, %list_idx_ok_1257 ], [ zeroinitializer, %list_idx_oob_1258 ]
  store %Enemy %t101, %Enemy* %t84
  %t102 = getelementptr inbounds %Enemy, %Enemy* %t84, i32 0, i32 4
  %t103 = load i1, i1* %t102
  br i1 %t103, label %if_then_1260, label %if_else_1261
if_then_1260:
  %t105 = getelementptr inbounds %Enemy, %Enemy* %t84, i32 0, i32 0
  %t106 = load float, float* %t105
  %t107 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 0
  %t108 = load float, float* %t107
  %t109 = fsub float %t106, %t108
  store float %t109, float* %t104
  %t111 = getelementptr inbounds %Enemy, %Enemy* %t84, i32 0, i32 1
  %t112 = load float, float* %t111
  %t113 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 1
  %t114 = load float, float* %t113
  %t115 = fsub float %t112, %t114
  store float %t115, float* %t110
  %t116 = load float, float* %t104
  %t117 = load float, float* %t104
  %t118 = fmul float %t116, %t117
  %t119 = load float, float* %t110
  %t120 = load float, float* %t110
  %t121 = fmul float %t119, %t120
  %t122 = fadd float %t118, %t121
  %t123 = call float @llvm.sqrt.f32(float %t122)
  %t124 = fcmp olt float %t123, 0x3FD99999A0000000
  br i1 %t124, label %if_then_1263, label %if_else_1264
if_then_1263:
  %t126 = load %Enemy, %Enemy* %t84
  store %Enemy %t126, %Enemy* %t125
  %t127 = getelementptr inbounds %Enemy, %Enemy* %t125, i32 0, i32 2
  %t128 = load float, float* %t127
  %t129 = fsub float %t128, 0x4024000000000000
  %t130 = getelementptr inbounds %Enemy, %Enemy* %t125, i32 0, i32 2
  store float %t129, float* %t130
  %t131 = getelementptr inbounds %Enemy, %Enemy* %t125, i32 0, i32 2
  %t132 = load float, float* %t131
  %t133 = fcmp ole float %t132, 0x0000000000000000
  br i1 %t133, label %if_then_1266, label %if_else_1267
if_then_1266:
  %t134 = getelementptr inbounds %Enemy, %Enemy* %t125, i32 0, i32 4
  store i1 false, i1* %t134
  %t135 = getelementptr inbounds %Enemy, %Enemy* %t125, i32 0, i32 3
  %t136 = load i32, i32* %t135
  %t137 = icmp eq i32 %t136, 0
  br i1 %t137, label %if_then_1269, label %if_else_1270
if_then_1269:
  br label %if_end_1271
if_else_1270:
  br label %if_end_1271
if_end_1271:
  %t138 = phi i32 [ 10, %if_then_1269 ], [ 25, %if_else_1270 ]
  %t139 = load %Game*, %Game** %t0
  %t140 = getelementptr inbounds %Game, %Game* %t139, i32 0, i32 0
  %t141 = getelementptr inbounds %Player, %Player* %t140, i32 0, i32 5
  %t142 = load i32, i32* %t141
  %t143 = add i32 %t142, %t138
  %t144 = load %Game*, %Game** %t0
  %t145 = getelementptr inbounds %Game, %Game* %t144, i32 0, i32 0
  %t146 = getelementptr inbounds %Player, %Player* %t145, i32 0, i32 5
  store i32 %t143, i32* %t146
  br label %if_end_1268
if_else_1267:
  br label %if_end_1268
if_end_1268:
  %t147 = getelementptr %Enemy, %Enemy* null, i32 1
  %t148 = ptrtoint %Enemy* %t147 to i64
  %t149 = load i8*, i8** %t4
  %t150 = icmp eq i8* %t149, null
  br i1 %t150, label %list_cow_alloc_1272, label %list_cow_check_1273
list_cow_alloc_1272:
  %t151 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t152 = call i8* @star_rc_alloc(i64 24, i8* %t151)
  %t153 = bitcast i8* %t152 to { %Enemy*, i64, i64 }*
  %t154 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t153, i32 0, i32 0
  store %Enemy* null, %Enemy** %t154
  %t155 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t153, i32 0, i32 1
  store i64 0, i64* %t155
  %t156 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t153, i32 0, i32 2
  store i64 0, i64* %t156
  store i8* %t152, i8** %t4
  br label %list_cow_done_1274
list_cow_check_1273:
  %t157 = getelementptr inbounds i8, i8* %t149, i64 -16
  %t158 = bitcast i8* %t157 to i64*
  %t159 = load atomic i64, i64* %t158 seq_cst, align 8
  %t160 = icmp eq i64 %t159, 1
  br i1 %t160, label %list_cow_done_1274, label %list_cow_clone_1275
list_cow_clone_1275:
  %t161 = bitcast i8* %t149 to { %Enemy*, i64, i64 }*
  %t162 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t161, i32 0, i32 0
  %t163 = load %Enemy*, %Enemy** %t162
  %t164 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t161, i32 0, i32 1
  %t165 = load i64, i64* %t164
  %t166 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t161, i32 0, i32 2
  %t167 = load i64, i64* %t166
  %t168 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t169 = call i8* @star_rc_alloc(i64 24, i8* %t168)
  %t170 = bitcast i8* %t169 to { %Enemy*, i64, i64 }*
  %t171 = mul i64 %t167, %t148
  %t172 = call i8* @malloc(i64 %t171)
  %t173 = bitcast i8* %t172 to %Enemy*
  %t174 = icmp sgt i64 %t165, 0
  br i1 %t174, label %list_cow_copy_1276, label %list_cow_after_copy_1277
list_cow_copy_1276:
  %t175 = mul i64 %t165, %t148
  %t176 = bitcast %Enemy* %t163 to i8*
  call i8* @memcpy(i8* %t172, i8* %t176, i64 %t175)
  br label %list_cow_after_copy_1277
list_cow_after_copy_1277:
  %t177 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t170, i32 0, i32 0
  store %Enemy* %t173, %Enemy** %t177
  %t178 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t170, i32 0, i32 1
  store i64 %t165, i64* %t178
  %t179 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t170, i32 0, i32 2
  store i64 %t167, i64* %t179
  call void @star_rc_release(i8* %t149)
  store i8* %t169, i8** %t4
  br label %list_cow_done_1274
list_cow_done_1274:
  %t180 = load i8*, i8** %t4
  %t181 = bitcast i8* %t180 to { %Enemy*, i64, i64 }*
  %t182 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t181, i32 0, i32 0
  %t183 = load %Enemy*, %Enemy** %t182
  %t184 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t181, i32 0, i32 1
  %t185 = load i64, i64* %t184
  %t186 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t181, i32 0, i32 2
  %t187 = load %Enemy, %Enemy* %t125
  %t188 = load i64, i64* %t186
  %t189 = load %Enemy*, %Enemy** %t182
  %t190 = load i64, i64* %t184
  %t191 = icmp sge i64 %t190, %t188
  br i1 %t191, label %list_push_grow_1278, label %list_push_store_1279
list_push_grow_1278:
  %t192 = mul i64 %t188, 2
  %t193 = icmp sgt i64 %t192, 0
  %t194 = select i1 %t193, i64 %t192, i64 1
  %t195 = getelementptr %Enemy, %Enemy* null, i32 1
  %t196 = ptrtoint %Enemy* %t195 to i64
  %t197 = mul i64 %t194, %t196
  %t198 = call i8* @malloc(i64 %t197)
  %t199 = bitcast i8* %t198 to %Enemy*
  %t200 = icmp sgt i64 %t188, 0
  br i1 %t200, label %list_push_copy_1280, label %list_push_after_copy_1281
list_push_copy_1280:
  %t201 = mul i64 %t190, %t196
  %t202 = bitcast %Enemy* %t189 to i8*
  call i8* @memcpy(i8* %t198, i8* %t202, i64 %t201)
  call void @free(i8* %t202)
  br label %list_push_after_copy_1281
list_push_after_copy_1281:
  store %Enemy* %t199, %Enemy** %t182
  store i64 %t194, i64* %t186
  br label %list_push_store_1279
list_push_store_1279:
  %t203 = load %Enemy*, %Enemy** %t182
  %t204 = getelementptr inbounds %Enemy, %Enemy* %t203, i64 %t190
  store %Enemy %t187, %Enemy* %t204
  %t205 = add i64 %t190, 1
  store i64 %t205, i64* %t184
  %t206 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 5
  store i1 false, i1* %t206
  br label %while_end_1250
if_else_1264:
  br label %if_end_1265
if_end_1265:
  br label %if_end_1262
if_else_1261:
  br label %if_end_1262
if_end_1262:
  %t207 = load i32, i32* %t69
  %t208 = add i32 %t207, 1
  store i32 %t208, i32* %t69
  br label %while_cond_1247
while_else_1249:
  br label %while_end_1250
while_end_1250:
  br label %if_end_1246
if_else_1245:
  %t210 = load %Game*, %Game** %t0
  %t211 = getelementptr inbounds %Game, %Game* %t210, i32 0, i32 0
  %t212 = getelementptr inbounds %Player, %Player* %t211, i32 0, i32 0
  %t213 = load float, float* %t212
  %t214 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 0
  %t215 = load float, float* %t214
  %t216 = fsub float %t213, %t215
  store float %t216, float* %t209
  %t218 = load %Game*, %Game** %t0
  %t219 = getelementptr inbounds %Game, %Game* %t218, i32 0, i32 0
  %t220 = getelementptr inbounds %Player, %Player* %t219, i32 0, i32 1
  %t221 = load float, float* %t220
  %t222 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 1
  %t223 = load float, float* %t222
  %t224 = fsub float %t221, %t223
  store float %t224, float* %t217
  %t225 = load float, float* %t209
  %t226 = load float, float* %t209
  %t227 = fmul float %t225, %t226
  %t228 = load float, float* %t217
  %t229 = load float, float* %t217
  %t230 = fmul float %t228, %t229
  %t231 = fadd float %t227, %t230
  %t232 = call float @llvm.sqrt.f32(float %t231)
  %t233 = fcmp olt float %t232, 0x3FD99999A0000000
  br i1 %t233, label %if_then_1282, label %if_else_1283
if_then_1282:
  %t234 = load %Game*, %Game** %t0
  %t235 = getelementptr inbounds %Game, %Game* %t234, i32 0, i32 0
  %t236 = getelementptr inbounds %Player, %Player* %t235, i32 0, i32 3
  %t237 = load float, float* %t236
  %t238 = fsub float %t237, 0x4014000000000000
  %t239 = load %Game*, %Game** %t0
  %t240 = getelementptr inbounds %Game, %Game* %t239, i32 0, i32 0
  %t241 = getelementptr inbounds %Player, %Player* %t240, i32 0, i32 3
  store float %t238, float* %t241
  %t242 = load %Game*, %Game** %t0
  %t243 = getelementptr inbounds %Game, %Game* %t242, i32 0, i32 0
  %t244 = getelementptr inbounds %Player, %Player* %t243, i32 0, i32 3
  %t245 = load float, float* %t244
  %t246 = fcmp ole float %t245, 0x0000000000000000
  br i1 %t246, label %if_then_1285, label %if_else_1286
if_then_1285:
  %t247 = load %Game*, %Game** %t0
  %t248 = getelementptr inbounds %Game, %Game* %t247, i32 0, i32 0
  %t249 = getelementptr inbounds %Player, %Player* %t248, i32 0, i32 3
  store float 0x0000000000000000, float* %t249
  %t250 = load %Game*, %Game** %t0
  %t251 = getelementptr inbounds %Game, %Game* %t250, i32 0, i32 0
  %t252 = getelementptr inbounds %Player, %Player* %t251, i32 0, i32 6
  store i1 false, i1* %t252
  br label %if_end_1287
if_else_1286:
  br label %if_end_1287
if_end_1287:
  %t253 = getelementptr inbounds %Projectile, %Projectile* %t20, i32 0, i32 5
  store i1 false, i1* %t253
  br label %if_end_1284
if_else_1283:
  br label %if_end_1284
if_end_1284:
  br label %if_end_1246
if_end_1246:
  br label %if_end_1243
if_end_1243:
  br label %if_end_1240
if_else_1239:
  br label %if_end_1240
if_end_1240:
  %t254 = getelementptr %Projectile, %Projectile* null, i32 1
  %t255 = ptrtoint %Projectile* %t254 to i64
  %t256 = load i8*, i8** %t3
  %t257 = icmp eq i8* %t256, null
  br i1 %t257, label %list_cow_alloc_1288, label %list_cow_check_1289
list_cow_alloc_1288:
  %t258 = bitcast void (i8*)* @list_release_s_Projectile to i8*
  %t259 = call i8* @star_rc_alloc(i64 24, i8* %t258)
  %t260 = bitcast i8* %t259 to { %Projectile*, i64, i64 }*
  %t261 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t260, i32 0, i32 0
  store %Projectile* null, %Projectile** %t261
  %t262 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t260, i32 0, i32 1
  store i64 0, i64* %t262
  %t263 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t260, i32 0, i32 2
  store i64 0, i64* %t263
  store i8* %t259, i8** %t3
  br label %list_cow_done_1290
list_cow_check_1289:
  %t264 = getelementptr inbounds i8, i8* %t256, i64 -16
  %t265 = bitcast i8* %t264 to i64*
  %t266 = load atomic i64, i64* %t265 seq_cst, align 8
  %t267 = icmp eq i64 %t266, 1
  br i1 %t267, label %list_cow_done_1290, label %list_cow_clone_1291
list_cow_clone_1291:
  %t268 = bitcast i8* %t256 to { %Projectile*, i64, i64 }*
  %t269 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t268, i32 0, i32 0
  %t270 = load %Projectile*, %Projectile** %t269
  %t271 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t268, i32 0, i32 1
  %t272 = load i64, i64* %t271
  %t273 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t268, i32 0, i32 2
  %t274 = load i64, i64* %t273
  %t275 = bitcast void (i8*)* @list_release_s_Projectile to i8*
  %t276 = call i8* @star_rc_alloc(i64 24, i8* %t275)
  %t277 = bitcast i8* %t276 to { %Projectile*, i64, i64 }*
  %t278 = mul i64 %t274, %t255
  %t279 = call i8* @malloc(i64 %t278)
  %t280 = bitcast i8* %t279 to %Projectile*
  %t281 = icmp sgt i64 %t272, 0
  br i1 %t281, label %list_cow_copy_1292, label %list_cow_after_copy_1293
list_cow_copy_1292:
  %t282 = mul i64 %t272, %t255
  %t283 = bitcast %Projectile* %t270 to i8*
  call i8* @memcpy(i8* %t279, i8* %t283, i64 %t282)
  br label %list_cow_after_copy_1293
list_cow_after_copy_1293:
  %t284 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t277, i32 0, i32 0
  store %Projectile* %t280, %Projectile** %t284
  %t285 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t277, i32 0, i32 1
  store i64 %t272, i64* %t285
  %t286 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t277, i32 0, i32 2
  store i64 %t274, i64* %t286
  call void @star_rc_release(i8* %t256)
  store i8* %t276, i8** %t3
  br label %list_cow_done_1290
list_cow_done_1290:
  %t287 = load i8*, i8** %t3
  %t288 = bitcast i8* %t287 to { %Projectile*, i64, i64 }*
  %t289 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t288, i32 0, i32 0
  %t290 = load %Projectile*, %Projectile** %t289
  %t291 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t288, i32 0, i32 1
  %t292 = load i64, i64* %t291
  %t293 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t288, i32 0, i32 2
  %t294 = load %Projectile, %Projectile* %t20
  %t295 = load i64, i64* %t293
  %t296 = load %Projectile*, %Projectile** %t289
  %t297 = load i64, i64* %t291
  %t298 = icmp sge i64 %t297, %t295
  br i1 %t298, label %list_push_grow_1294, label %list_push_store_1295
list_push_grow_1294:
  %t299 = mul i64 %t295, 2
  %t300 = icmp sgt i64 %t299, 0
  %t301 = select i1 %t300, i64 %t299, i64 1
  %t302 = getelementptr %Projectile, %Projectile* null, i32 1
  %t303 = ptrtoint %Projectile* %t302 to i64
  %t304 = mul i64 %t301, %t303
  %t305 = call i8* @malloc(i64 %t304)
  %t306 = bitcast i8* %t305 to %Projectile*
  %t307 = icmp sgt i64 %t295, 0
  br i1 %t307, label %list_push_copy_1296, label %list_push_after_copy_1297
list_push_copy_1296:
  %t308 = mul i64 %t297, %t303
  %t309 = bitcast %Projectile* %t296 to i8*
  call i8* @memcpy(i8* %t305, i8* %t309, i64 %t308)
  call void @free(i8* %t309)
  br label %list_push_after_copy_1297
list_push_after_copy_1297:
  store %Projectile* %t306, %Projectile** %t289
  store i64 %t301, i64* %t293
  br label %list_push_store_1295
list_push_store_1295:
  %t310 = load %Projectile*, %Projectile** %t289
  %t311 = getelementptr inbounds %Projectile, %Projectile* %t310, i64 %t297
  store %Projectile %t294, %Projectile* %t311
  %t312 = add i64 %t297, 1
  store i64 %t312, i64* %t291
  %t313 = load i32, i32* %t5
  %t314 = add i32 %t313, 1
  store i32 %t314, i32* %t5
  br label %while_cond_1225
while_else_1227:
  br label %while_end_1228
while_end_1228:
  store i32 0, i32* %t315
  br label %while_cond_1298
while_cond_1298:
  %t316 = load i32, i32* %t315
  %t317 = load %Game*, %Game** %t0
  %t318 = getelementptr inbounds %Game, %Game* %t317, i32 0, i32 1
  %t319 = load i8*, i8** %t318
  %t320 = icmp eq i8* %t319, null
  br i1 %t320, label %list_read_null_1302, label %list_read_real_1303
list_read_null_1302:
  br label %list_read_end_1304
list_read_real_1303:
  %t321 = bitcast i8* %t319 to { %Enemy*, i64, i64 }*
  %t322 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t321, i32 0, i32 0
  %t323 = load %Enemy*, %Enemy** %t322
  %t324 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t321, i32 0, i32 1
  %t325 = load i64, i64* %t324
  br label %list_read_end_1304
list_read_end_1304:
  %t326 = phi %Enemy* [ null, %list_read_null_1302 ], [ %t323, %list_read_real_1303 ]
  %t327 = phi i64 [ 0, %list_read_null_1302 ], [ %t325, %list_read_real_1303 ]
  %t328 = trunc i64 %t327 to i32
  %t329 = icmp slt i32 %t316, %t328
  br i1 %t329, label %while_body_1299, label %while_else_1300
while_body_1299:
  %t331 = load %Game*, %Game** %t0
  %t332 = getelementptr inbounds %Game, %Game* %t331, i32 0, i32 1
  %t333 = load i8*, i8** %t332
  %t334 = icmp eq i8* %t333, null
  br i1 %t334, label %list_read_null_1305, label %list_read_real_1306
list_read_null_1305:
  br label %list_read_end_1307
list_read_real_1306:
  %t335 = bitcast i8* %t333 to { %Enemy*, i64, i64 }*
  %t336 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t335, i32 0, i32 0
  %t337 = load %Enemy*, %Enemy** %t336
  %t338 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t335, i32 0, i32 1
  %t339 = load i64, i64* %t338
  br label %list_read_end_1307
list_read_end_1307:
  %t340 = phi %Enemy* [ null, %list_read_null_1305 ], [ %t337, %list_read_real_1306 ]
  %t341 = phi i64 [ 0, %list_read_null_1305 ], [ %t339, %list_read_real_1306 ]
  %t342 = load i32, i32* %t315
  %t343 = sext i32 %t342 to i64
  %t344 = icmp ult i64 %t343, %t341
  br i1 %t344, label %list_idx_ok_1308, label %list_idx_oob_1309
list_idx_ok_1308:
  %t345 = getelementptr inbounds %Enemy, %Enemy* %t340, i64 %t343
  %t346 = load %Enemy, %Enemy* %t345
  br label %list_idx_end_1310
list_idx_oob_1309:
  br label %list_idx_end_1310
list_idx_end_1310:
  %t347 = phi %Enemy [ %t346, %list_idx_ok_1308 ], [ zeroinitializer, %list_idx_oob_1309 ]
  store %Enemy %t347, %Enemy* %t330
  %t348 = getelementptr inbounds %Enemy, %Enemy* %t330, i32 0, i32 4
  %t349 = load i1, i1* %t348
  br i1 %t349, label %if_then_1311, label %if_else_1312
if_then_1311:
  %t350 = getelementptr %Enemy, %Enemy* null, i32 1
  %t351 = ptrtoint %Enemy* %t350 to i64
  %t352 = load i8*, i8** %t4
  %t353 = icmp eq i8* %t352, null
  br i1 %t353, label %list_cow_alloc_1314, label %list_cow_check_1315
list_cow_alloc_1314:
  %t354 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t355 = call i8* @star_rc_alloc(i64 24, i8* %t354)
  %t356 = bitcast i8* %t355 to { %Enemy*, i64, i64 }*
  %t357 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t356, i32 0, i32 0
  store %Enemy* null, %Enemy** %t357
  %t358 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t356, i32 0, i32 1
  store i64 0, i64* %t358
  %t359 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t356, i32 0, i32 2
  store i64 0, i64* %t359
  store i8* %t355, i8** %t4
  br label %list_cow_done_1316
list_cow_check_1315:
  %t360 = getelementptr inbounds i8, i8* %t352, i64 -16
  %t361 = bitcast i8* %t360 to i64*
  %t362 = load atomic i64, i64* %t361 seq_cst, align 8
  %t363 = icmp eq i64 %t362, 1
  br i1 %t363, label %list_cow_done_1316, label %list_cow_clone_1317
list_cow_clone_1317:
  %t364 = bitcast i8* %t352 to { %Enemy*, i64, i64 }*
  %t365 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t364, i32 0, i32 0
  %t366 = load %Enemy*, %Enemy** %t365
  %t367 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t364, i32 0, i32 1
  %t368 = load i64, i64* %t367
  %t369 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t364, i32 0, i32 2
  %t370 = load i64, i64* %t369
  %t371 = bitcast void (i8*)* @list_release_s_Enemy to i8*
  %t372 = call i8* @star_rc_alloc(i64 24, i8* %t371)
  %t373 = bitcast i8* %t372 to { %Enemy*, i64, i64 }*
  %t374 = mul i64 %t370, %t351
  %t375 = call i8* @malloc(i64 %t374)
  %t376 = bitcast i8* %t375 to %Enemy*
  %t377 = icmp sgt i64 %t368, 0
  br i1 %t377, label %list_cow_copy_1318, label %list_cow_after_copy_1319
list_cow_copy_1318:
  %t378 = mul i64 %t368, %t351
  %t379 = bitcast %Enemy* %t366 to i8*
  call i8* @memcpy(i8* %t375, i8* %t379, i64 %t378)
  br label %list_cow_after_copy_1319
list_cow_after_copy_1319:
  %t380 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t373, i32 0, i32 0
  store %Enemy* %t376, %Enemy** %t380
  %t381 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t373, i32 0, i32 1
  store i64 %t368, i64* %t381
  %t382 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t373, i32 0, i32 2
  store i64 %t370, i64* %t382
  call void @star_rc_release(i8* %t352)
  store i8* %t372, i8** %t4
  br label %list_cow_done_1316
list_cow_done_1316:
  %t383 = load i8*, i8** %t4
  %t384 = bitcast i8* %t383 to { %Enemy*, i64, i64 }*
  %t385 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t384, i32 0, i32 0
  %t386 = load %Enemy*, %Enemy** %t385
  %t387 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t384, i32 0, i32 1
  %t388 = load i64, i64* %t387
  %t389 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t384, i32 0, i32 2
  %t390 = load %Enemy, %Enemy* %t330
  %t391 = load i64, i64* %t389
  %t392 = load %Enemy*, %Enemy** %t385
  %t393 = load i64, i64* %t387
  %t394 = icmp sge i64 %t393, %t391
  br i1 %t394, label %list_push_grow_1320, label %list_push_store_1321
list_push_grow_1320:
  %t395 = mul i64 %t391, 2
  %t396 = icmp sgt i64 %t395, 0
  %t397 = select i1 %t396, i64 %t395, i64 1
  %t398 = getelementptr %Enemy, %Enemy* null, i32 1
  %t399 = ptrtoint %Enemy* %t398 to i64
  %t400 = mul i64 %t397, %t399
  %t401 = call i8* @malloc(i64 %t400)
  %t402 = bitcast i8* %t401 to %Enemy*
  %t403 = icmp sgt i64 %t391, 0
  br i1 %t403, label %list_push_copy_1322, label %list_push_after_copy_1323
list_push_copy_1322:
  %t404 = mul i64 %t393, %t399
  %t405 = bitcast %Enemy* %t392 to i8*
  call i8* @memcpy(i8* %t401, i8* %t405, i64 %t404)
  call void @free(i8* %t405)
  br label %list_push_after_copy_1323
list_push_after_copy_1323:
  store %Enemy* %t402, %Enemy** %t385
  store i64 %t397, i64* %t389
  br label %list_push_store_1321
list_push_store_1321:
  %t406 = load %Enemy*, %Enemy** %t385
  %t407 = getelementptr inbounds %Enemy, %Enemy* %t406, i64 %t393
  store %Enemy %t390, %Enemy* %t407
  %t408 = add i64 %t393, 1
  store i64 %t408, i64* %t387
  br label %if_end_1313
if_else_1312:
  br label %if_end_1313
if_end_1313:
  %t409 = load i32, i32* %t315
  %t410 = add i32 %t409, 1
  store i32 %t410, i32* %t315
  br label %while_cond_1298
while_else_1300:
  br label %while_end_1301
while_end_1301:
  %t411 = load i8*, i8** %t3
  %t412 = load i8*, i8** %t3
  call void @star_rc_retain(i8* %t412)
  %t413 = load %Game*, %Game** %t0
  %t414 = getelementptr inbounds %Game, %Game* %t413, i32 0, i32 2
  %t415 = load i8*, i8** %t414
  call void @star_rc_release(i8* %t415)
  store i8* %t411, i8** %t414
  %t416 = load i8*, i8** %t4
  %t417 = load i8*, i8** %t4
  call void @star_rc_retain(i8* %t417)
  %t418 = load %Game*, %Game** %t0
  %t419 = getelementptr inbounds %Game, %Game* %t418, i32 0, i32 1
  %t420 = load i8*, i8** %t419
  call void @star_rc_release(i8* %t420)
  store i8* %t416, i8** %t419
  %t421 = load %Game*, %Game** %t0
  %t422 = load %Game, %Game* %t421
  %t423 = getelementptr inbounds %Game, %Game* %t421, i32 0, i32 1
  %t424 = load i8*, i8** %t423
  call void @star_rc_retain(i8* %t424)
  %t425 = getelementptr inbounds %Game, %Game* %t421, i32 0, i32 2
  %t426 = load i8*, i8** %t425
  call void @star_rc_retain(i8* %t426)
  %t427 = getelementptr inbounds %Game, %Game* %t421, i32 0, i32 3
  %t428 = load i8*, i8** %t427
  call void @star_rc_retain(i8* %t428)
  %t429 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t429)
  %t430 = load i8*, i8** %t3
  call void @star_rc_release(i8* %t430)
  %t431 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t431)
  ret %Game %t422
}

define %Game @Game__update_pickups(%Game* %self) {
entry:
  %t0 = alloca %Game*
  %t1 = alloca i8*
  %t2 = alloca i32
  %t17 = alloca %Pickup
  %t38 = alloca float
  %t46 = alloca float
  store %Game* %self, %Game** %t0
  store i8* null, i8** %t1
  store i32 0, i32* %t2
  br label %while_cond_1324
while_cond_1324:
  %t3 = load i32, i32* %t2
  %t4 = load %Game*, %Game** %t0
  %t5 = getelementptr inbounds %Game, %Game* %t4, i32 0, i32 3
  %t6 = load i8*, i8** %t5
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %list_read_null_1328, label %list_read_real_1329
list_read_null_1328:
  br label %list_read_end_1330
list_read_real_1329:
  %t8 = bitcast i8* %t6 to { %Pickup*, i64, i64 }*
  %t9 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t8, i32 0, i32 0
  %t10 = load %Pickup*, %Pickup** %t9
  %t11 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t8, i32 0, i32 1
  %t12 = load i64, i64* %t11
  br label %list_read_end_1330
list_read_end_1330:
  %t13 = phi %Pickup* [ null, %list_read_null_1328 ], [ %t10, %list_read_real_1329 ]
  %t14 = phi i64 [ 0, %list_read_null_1328 ], [ %t12, %list_read_real_1329 ]
  %t15 = trunc i64 %t14 to i32
  %t16 = icmp slt i32 %t3, %t15
  br i1 %t16, label %while_body_1325, label %while_else_1326
while_body_1325:
  %t18 = load %Game*, %Game** %t0
  %t19 = getelementptr inbounds %Game, %Game* %t18, i32 0, i32 3
  %t20 = load i8*, i8** %t19
  %t21 = icmp eq i8* %t20, null
  br i1 %t21, label %list_read_null_1331, label %list_read_real_1332
list_read_null_1331:
  br label %list_read_end_1333
list_read_real_1332:
  %t22 = bitcast i8* %t20 to { %Pickup*, i64, i64 }*
  %t23 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t22, i32 0, i32 0
  %t24 = load %Pickup*, %Pickup** %t23
  %t25 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t22, i32 0, i32 1
  %t26 = load i64, i64* %t25
  br label %list_read_end_1333
list_read_end_1333:
  %t27 = phi %Pickup* [ null, %list_read_null_1331 ], [ %t24, %list_read_real_1332 ]
  %t28 = phi i64 [ 0, %list_read_null_1331 ], [ %t26, %list_read_real_1332 ]
  %t29 = load i32, i32* %t2
  %t30 = sext i32 %t29 to i64
  %t31 = icmp ult i64 %t30, %t28
  br i1 %t31, label %list_idx_ok_1334, label %list_idx_oob_1335
list_idx_ok_1334:
  %t32 = getelementptr inbounds %Pickup, %Pickup* %t27, i64 %t30
  %t33 = load %Pickup, %Pickup* %t32
  br label %list_idx_end_1336
list_idx_oob_1335:
  br label %list_idx_end_1336
list_idx_end_1336:
  %t34 = phi %Pickup [ %t33, %list_idx_ok_1334 ], [ zeroinitializer, %list_idx_oob_1335 ]
  store %Pickup %t34, %Pickup* %t17
  %t35 = getelementptr inbounds %Pickup, %Pickup* %t17, i32 0, i32 3
  %t36 = load i1, i1* %t35
  %t37 = xor i1 true, %t36
  br i1 %t37, label %if_then_1337, label %if_else_1338
if_then_1337:
  %t39 = load %Game*, %Game** %t0
  %t40 = getelementptr inbounds %Game, %Game* %t39, i32 0, i32 0
  %t41 = getelementptr inbounds %Player, %Player* %t40, i32 0, i32 0
  %t42 = load float, float* %t41
  %t43 = getelementptr inbounds %Pickup, %Pickup* %t17, i32 0, i32 0
  %t44 = load float, float* %t43
  %t45 = fsub float %t42, %t44
  store float %t45, float* %t38
  %t47 = load %Game*, %Game** %t0
  %t48 = getelementptr inbounds %Game, %Game* %t47, i32 0, i32 0
  %t49 = getelementptr inbounds %Player, %Player* %t48, i32 0, i32 1
  %t50 = load float, float* %t49
  %t51 = getelementptr inbounds %Pickup, %Pickup* %t17, i32 0, i32 1
  %t52 = load float, float* %t51
  %t53 = fsub float %t50, %t52
  store float %t53, float* %t46
  %t54 = load float, float* %t38
  %t55 = load float, float* %t38
  %t56 = fmul float %t54, %t55
  %t57 = load float, float* %t46
  %t58 = load float, float* %t46
  %t59 = fmul float %t57, %t58
  %t60 = fadd float %t56, %t59
  %t61 = call float @llvm.sqrt.f32(float %t60)
  %t62 = fcmp olt float %t61, 0x3FE0000000000000
  br i1 %t62, label %if_then_1340, label %if_else_1341
if_then_1340:
  %t63 = getelementptr inbounds %Pickup, %Pickup* %t17, i32 0, i32 3
  store i1 true, i1* %t63
  %t64 = getelementptr inbounds %Pickup, %Pickup* %t17, i32 0, i32 2
  %t65 = load i32, i32* %t64
  %t66 = icmp eq i32 %t65, 0
  br i1 %t66, label %if_then_1343, label %if_else_1344
if_then_1343:
  %t67 = load %Game*, %Game** %t0
  %t68 = getelementptr inbounds %Game, %Game* %t67, i32 0, i32 0
  %t69 = getelementptr inbounds %Player, %Player* %t68, i32 0, i32 3
  %t70 = load float, float* %t69
  %t71 = fadd float %t70, 0x4039000000000000
  %t72 = call float @llvm.maxnum.f32(float %t71, float 0x0000000000000000)
  %t73 = call float @llvm.minnum.f32(float %t72, float 0x4059000000000000)
  %t74 = load %Game*, %Game** %t0
  %t75 = getelementptr inbounds %Game, %Game* %t74, i32 0, i32 0
  %t76 = getelementptr inbounds %Player, %Player* %t75, i32 0, i32 3
  store float %t73, float* %t76
  br label %if_end_1345
if_else_1344:
  %t77 = load %Game*, %Game** %t0
  %t78 = getelementptr inbounds %Game, %Game* %t77, i32 0, i32 0
  %t79 = getelementptr inbounds %Player, %Player* %t78, i32 0, i32 4
  %t80 = load float, float* %t79
  %t81 = fadd float %t80, 0x4049000000000000
  %t82 = call float @llvm.maxnum.f32(float %t81, float 0x0000000000000000)
  %t83 = call float @llvm.minnum.f32(float %t82, float 0x4059000000000000)
  %t84 = load %Game*, %Game** %t0
  %t85 = getelementptr inbounds %Game, %Game* %t84, i32 0, i32 0
  %t86 = getelementptr inbounds %Player, %Player* %t85, i32 0, i32 4
  store float %t83, float* %t86
  br label %if_end_1345
if_end_1345:
  br label %if_end_1342
if_else_1341:
  br label %if_end_1342
if_end_1342:
  br label %if_end_1339
if_else_1338:
  br label %if_end_1339
if_end_1339:
  %t87 = getelementptr %Pickup, %Pickup* null, i32 1
  %t88 = ptrtoint %Pickup* %t87 to i64
  %t89 = load i8*, i8** %t1
  %t90 = icmp eq i8* %t89, null
  br i1 %t90, label %list_cow_alloc_1346, label %list_cow_check_1347
list_cow_alloc_1346:
  %t91 = bitcast void (i8*)* @list_release_s_Pickup to i8*
  %t92 = call i8* @star_rc_alloc(i64 24, i8* %t91)
  %t93 = bitcast i8* %t92 to { %Pickup*, i64, i64 }*
  %t94 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t93, i32 0, i32 0
  store %Pickup* null, %Pickup** %t94
  %t95 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t93, i32 0, i32 1
  store i64 0, i64* %t95
  %t96 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t93, i32 0, i32 2
  store i64 0, i64* %t96
  store i8* %t92, i8** %t1
  br label %list_cow_done_1348
list_cow_check_1347:
  %t97 = getelementptr inbounds i8, i8* %t89, i64 -16
  %t98 = bitcast i8* %t97 to i64*
  %t99 = load atomic i64, i64* %t98 seq_cst, align 8
  %t100 = icmp eq i64 %t99, 1
  br i1 %t100, label %list_cow_done_1348, label %list_cow_clone_1349
list_cow_clone_1349:
  %t101 = bitcast i8* %t89 to { %Pickup*, i64, i64 }*
  %t102 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t101, i32 0, i32 0
  %t103 = load %Pickup*, %Pickup** %t102
  %t104 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t101, i32 0, i32 1
  %t105 = load i64, i64* %t104
  %t106 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t101, i32 0, i32 2
  %t107 = load i64, i64* %t106
  %t108 = bitcast void (i8*)* @list_release_s_Pickup to i8*
  %t109 = call i8* @star_rc_alloc(i64 24, i8* %t108)
  %t110 = bitcast i8* %t109 to { %Pickup*, i64, i64 }*
  %t111 = mul i64 %t107, %t88
  %t112 = call i8* @malloc(i64 %t111)
  %t113 = bitcast i8* %t112 to %Pickup*
  %t114 = icmp sgt i64 %t105, 0
  br i1 %t114, label %list_cow_copy_1350, label %list_cow_after_copy_1351
list_cow_copy_1350:
  %t115 = mul i64 %t105, %t88
  %t116 = bitcast %Pickup* %t103 to i8*
  call i8* @memcpy(i8* %t112, i8* %t116, i64 %t115)
  br label %list_cow_after_copy_1351
list_cow_after_copy_1351:
  %t117 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t110, i32 0, i32 0
  store %Pickup* %t113, %Pickup** %t117
  %t118 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t110, i32 0, i32 1
  store i64 %t105, i64* %t118
  %t119 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t110, i32 0, i32 2
  store i64 %t107, i64* %t119
  call void @star_rc_release(i8* %t89)
  store i8* %t109, i8** %t1
  br label %list_cow_done_1348
list_cow_done_1348:
  %t120 = load i8*, i8** %t1
  %t121 = bitcast i8* %t120 to { %Pickup*, i64, i64 }*
  %t122 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t121, i32 0, i32 0
  %t123 = load %Pickup*, %Pickup** %t122
  %t124 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t121, i32 0, i32 1
  %t125 = load i64, i64* %t124
  %t126 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t121, i32 0, i32 2
  %t127 = load %Pickup, %Pickup* %t17
  %t128 = load i64, i64* %t126
  %t129 = load %Pickup*, %Pickup** %t122
  %t130 = load i64, i64* %t124
  %t131 = icmp sge i64 %t130, %t128
  br i1 %t131, label %list_push_grow_1352, label %list_push_store_1353
list_push_grow_1352:
  %t132 = mul i64 %t128, 2
  %t133 = icmp sgt i64 %t132, 0
  %t134 = select i1 %t133, i64 %t132, i64 1
  %t135 = getelementptr %Pickup, %Pickup* null, i32 1
  %t136 = ptrtoint %Pickup* %t135 to i64
  %t137 = mul i64 %t134, %t136
  %t138 = call i8* @malloc(i64 %t137)
  %t139 = bitcast i8* %t138 to %Pickup*
  %t140 = icmp sgt i64 %t128, 0
  br i1 %t140, label %list_push_copy_1354, label %list_push_after_copy_1355
list_push_copy_1354:
  %t141 = mul i64 %t130, %t136
  %t142 = bitcast %Pickup* %t129 to i8*
  call i8* @memcpy(i8* %t138, i8* %t142, i64 %t141)
  call void @free(i8* %t142)
  br label %list_push_after_copy_1355
list_push_after_copy_1355:
  store %Pickup* %t139, %Pickup** %t122
  store i64 %t134, i64* %t126
  br label %list_push_store_1353
list_push_store_1353:
  %t143 = load %Pickup*, %Pickup** %t122
  %t144 = getelementptr inbounds %Pickup, %Pickup* %t143, i64 %t130
  store %Pickup %t127, %Pickup* %t144
  %t145 = add i64 %t130, 1
  store i64 %t145, i64* %t124
  %t146 = load i32, i32* %t2
  %t147 = add i32 %t146, 1
  store i32 %t147, i32* %t2
  br label %while_cond_1324
while_else_1326:
  br label %while_end_1327
while_end_1327:
  %t148 = load i8*, i8** %t1
  %t149 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t149)
  %t150 = load %Game*, %Game** %t0
  %t151 = getelementptr inbounds %Game, %Game* %t150, i32 0, i32 3
  %t152 = load i8*, i8** %t151
  call void @star_rc_release(i8* %t152)
  store i8* %t148, i8** %t151
  %t153 = load %Game*, %Game** %t0
  %t154 = load %Game, %Game* %t153
  %t155 = getelementptr inbounds %Game, %Game* %t153, i32 0, i32 1
  %t156 = load i8*, i8** %t155
  call void @star_rc_retain(i8* %t156)
  %t157 = getelementptr inbounds %Game, %Game* %t153, i32 0, i32 2
  %t158 = load i8*, i8** %t157
  call void @star_rc_retain(i8* %t158)
  %t159 = getelementptr inbounds %Game, %Game* %t153, i32 0, i32 3
  %t160 = load i8*, i8** %t159
  call void @star_rc_retain(i8* %t160)
  %t161 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t161)
  ret %Game %t154
}

define %Game @Game__update(%Game* %self, float %dt, i8* %map_grid, %audio__Sounds %sounds) {
entry:
  %t0 = alloca %Game*
  %t1 = alloca float
  %t2 = alloca i8*
  %t3 = alloca %audio__Sounds
  store %Game* %self, %Game** %t0
  store float %dt, float* %t1
  store i8* %map_grid, i8** %t2
  store %audio__Sounds %sounds, %audio__Sounds* %t3
  %t4 = load %Game*, %Game** %t0
  %t5 = load float, float* %t1
  %t6 = load i8*, i8** %t2
  %t7 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t7)
  %t8 = load %audio__Sounds, %audio__Sounds* %t3
  %t9 = call %Game @Game__update_input(%Game* %t4, float %t5, i8* %t6, %audio__Sounds %t8)
  %t10 = load %Game*, %Game** %t0
  %t11 = getelementptr inbounds %Game, %Game* %t10, i32 0, i32 1
  %t12 = load i8*, i8** %t11
  call void @star_rc_release(i8* %t12)
  %t13 = getelementptr inbounds %Game, %Game* %t10, i32 0, i32 2
  %t14 = load i8*, i8** %t13
  call void @star_rc_release(i8* %t14)
  %t15 = getelementptr inbounds %Game, %Game* %t10, i32 0, i32 3
  %t16 = load i8*, i8** %t15
  call void @star_rc_release(i8* %t16)
  store %Game %t9, %Game* %t10
  %t17 = load %Game*, %Game** %t0
  %t18 = load float, float* %t1
  %t19 = load i8*, i8** %t2
  %t20 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t20)
  %t21 = call %Game @Game__update_enemies(%Game* %t17, float %t18, i8* %t19)
  %t22 = load %Game*, %Game** %t0
  %t23 = getelementptr inbounds %Game, %Game* %t22, i32 0, i32 1
  %t24 = load i8*, i8** %t23
  call void @star_rc_release(i8* %t24)
  %t25 = getelementptr inbounds %Game, %Game* %t22, i32 0, i32 2
  %t26 = load i8*, i8** %t25
  call void @star_rc_release(i8* %t26)
  %t27 = getelementptr inbounds %Game, %Game* %t22, i32 0, i32 3
  %t28 = load i8*, i8** %t27
  call void @star_rc_release(i8* %t28)
  store %Game %t21, %Game* %t22
  %t29 = load %Game*, %Game** %t0
  %t30 = load float, float* %t1
  %t31 = load i8*, i8** %t2
  %t32 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t32)
  %t33 = call %Game @Game__update_projectiles(%Game* %t29, float %t30, i8* %t31)
  %t34 = load %Game*, %Game** %t0
  %t35 = getelementptr inbounds %Game, %Game* %t34, i32 0, i32 1
  %t36 = load i8*, i8** %t35
  call void @star_rc_release(i8* %t36)
  %t37 = getelementptr inbounds %Game, %Game* %t34, i32 0, i32 2
  %t38 = load i8*, i8** %t37
  call void @star_rc_release(i8* %t38)
  %t39 = getelementptr inbounds %Game, %Game* %t34, i32 0, i32 3
  %t40 = load i8*, i8** %t39
  call void @star_rc_release(i8* %t40)
  store %Game %t33, %Game* %t34
  %t41 = load %Game*, %Game** %t0
  %t42 = call %Game @Game__update_pickups(%Game* %t41)
  %t43 = load %Game*, %Game** %t0
  %t44 = getelementptr inbounds %Game, %Game* %t43, i32 0, i32 1
  %t45 = load i8*, i8** %t44
  call void @star_rc_release(i8* %t45)
  %t46 = getelementptr inbounds %Game, %Game* %t43, i32 0, i32 2
  %t47 = load i8*, i8** %t46
  call void @star_rc_release(i8* %t47)
  %t48 = getelementptr inbounds %Game, %Game* %t43, i32 0, i32 3
  %t49 = load i8*, i8** %t48
  call void @star_rc_release(i8* %t49)
  store %Game %t42, %Game* %t43
  %t50 = load %Game*, %Game** %t0
  %t51 = load %Game, %Game* %t50
  %t52 = getelementptr inbounds %Game, %Game* %t50, i32 0, i32 1
  %t53 = load i8*, i8** %t52
  call void @star_rc_retain(i8* %t53)
  %t54 = getelementptr inbounds %Game, %Game* %t50, i32 0, i32 2
  %t55 = load i8*, i8** %t54
  call void @star_rc_retain(i8* %t55)
  %t56 = getelementptr inbounds %Game, %Game* %t50, i32 0, i32 3
  %t57 = load i8*, i8** %t56
  call void @star_rc_retain(i8* %t57)
  %t58 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t58)
  ret %Game %t51
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t17 = alloca i8*
  %t19 = alloca %map__Level
  %t21 = alloca %sprites__SpriteSet
  %t23 = alloca %audio__Sounds
  %t36 = alloca [32 x i8]
  %t38 = alloca i64
  %t65 = alloca i8*
  %t66 = alloca i32
  %t132 = alloca %Game
  %t145 = alloca i32
  %t146 = alloca i32
  %t156 = alloca i1
  %t157 = alloca [56 x i8]
  %t174 = alloca i32
  %t176 = alloca float
  %t200 = alloca { i8*, i8* }
  %t218 = alloca i8*
  %t279 = alloca [16 x i8]
  %t342 = alloca i32
  %t343 = alloca i32
  %t344 = alloca i64
  %t368 = alloca i32
  %t376 = alloca i32
  %t389 = alloca [16 x i8]
  %t457 = alloca i32
  %t458 = alloca i32
  %t459 = alloca i64
  %t483 = alloca i32
  %t491 = alloca i32
  %t504 = alloca [16 x i8]
  %t571 = alloca i32
  %t572 = alloca i32
  %t573 = alloca i64
  %t597 = alloca i32
  %t605 = alloca i32
  %t618 = alloca [16 x i8]
  %t680 = alloca i32
  %t681 = alloca i32
  %t682 = alloca i64
  %t706 = alloca i32
  %t714 = alloca i32
  %t727 = alloca [16 x i8]
  %t741 = alloca i32
  %t750 = alloca i32
  %t788 = alloca [16 x i8]
  %t826 = alloca [16 x i8]
  %t835 = alloca i32
  %t872 = alloca [16 x i8]
  %t910 = alloca [16 x i8]
  %t923 = alloca i8*
  %t925 = alloca { i32, i32 }
  %t948 = alloca i32
  %t949 = alloca i32
  %t950 = alloca i32
  %t951 = alloca i64
  %t975 = alloca { i32, i32 }
  %t1048 = alloca i32
  %t1049 = alloca i32
  %t1050 = alloca i64
  %t1074 = alloca i32
  %t1082 = alloca i32
  %t1095 = alloca [16 x i8]
  %t1109 = alloca i8*
  %t1111 = alloca { i32, i32 }
  %t1134 = alloca i32
  %t1135 = alloca i32
  %t1136 = alloca i32
  %t1137 = alloca i64
  %t1161 = alloca { i32, i32 }
  %t1235 = alloca i32
  %t1236 = alloca i32
  %t1237 = alloca i64
  %t1261 = alloca i32
  %t1269 = alloca i32
  %t1282 = alloca [16 x i8]
  %t1323 = alloca i32
  %t1324 = alloca i32
  %t1345 = alloca i64
  %t1360 = alloca i32
  %t1381 = alloca i32
  %t1402 = alloca i32
  %t1423 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.47, i64 0, i32 2, i64 0
  %t4 = mul i32 320, 2
  %t5 = mul i32 200, 2
  %t6 = call i32 @SDL_Init(i32 32)
  %t7 = icmp ne i32 %t6, 0
  br i1 %t7, label %sdl_init_fail_1356, label %sdl_init_ok_1357
sdl_init_fail_1356:
  call void @star_rc_release(i8* %t3)
  br label %window_create_end_1358
sdl_init_ok_1357:
  %t8 = call i8* @SDL_CreateWindow(i8* %t3, i32 536805376, i32 536805376, i32 %t4, i32 %t5, i32 0)
  call void @star_rc_release(i8* %t3)
  %t9 = icmp eq i8* %t8, null
  br i1 %t9, label %sdl_window_fail_1359, label %sdl_window_ok_1360
sdl_window_fail_1359:
  br label %window_create_end_1358
sdl_window_ok_1360:
  %t10 = call i8* @SDL_CreateRenderer(i8* %t8, i32 -1, i32 0)
  %t11 = icmp eq i8* %t10, null
  br i1 %t11, label %sdl_renderer_fail_1361, label %sdl_renderer_ok_1362
sdl_renderer_fail_1361:
  call void @SDL_DestroyWindow(i8* %t8)
  br label %window_create_end_1358
sdl_renderer_ok_1362:
  br label %window_create_end_1358
window_create_end_1358:
  %t12 = phi i8* [ null, %sdl_init_fail_1356 ], [ null, %sdl_window_fail_1359 ], [ null, %sdl_renderer_fail_1361 ], [ %t8, %sdl_renderer_ok_1362 ]
  store i8* %t12, i8** %t2
  %t13 = load i8*, i8** %t2
  %t14 = icmp eq i8* %t13, null
  br i1 %t14, label %if_then_1363, label %if_else_1364
if_then_1363:
  %t15 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.48, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t15)
  call void @star_rc_release(i8* %t15)
  %t16 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.49, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16)
  ret i32 0
if_else_1364:
  br label %if_end_1365
if_end_1365:
  %t18 = getelementptr inbounds [417 x i8], [417 x i8]* @.str.50, i64 0, i64 0
  store i8* %t18, i8** %t17
  %t20 = call %map__Level @map__parse_level()
  store %map__Level %t20, %map__Level* %t19
  %t22 = call %sprites__SpriteSet @sprites__make_sprites()
  store %sprites__SpriteSet %t22, %sprites__SpriteSet* %t21
  %t24 = call %audio__Sounds @audio__make_sounds()
  store %audio__Sounds %t24, %audio__Sounds* %t23
  %t25 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t23, i32 0, i32 3
  %t26 = load i8*, i8** %t25
  %t27 = icmp eq i8* %t26, null
  %t28 = xor i1 true, %t27
  br i1 %t28, label %if_then_1366, label %if_else_1367
if_then_1366:
  %t29 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t23, i32 0, i32 3
  %t30 = load i8*, i8** %t29
  %t31 = icmp eq i8* %t30, null
  br i1 %t31, label %sound_null_handle_1369, label %sound_handle_ok_1370
sound_null_handle_1369:
  %t32 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.51, i64 0, i64 0
  call i32 @puts(i8* %t32)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_1370:
  %t33 = load i32, i32* @star.audio.device
  %t34 = icmp ne i32 %t33, 0
  br i1 %t34, label %audio_dev_ok_1372, label %audio_dev_init_1371
audio_dev_init_1371:
  %t35 = call i32 @SDL_Init(i32 16)
  %t37 = getelementptr inbounds [32 x i8], [32 x i8]* %t36, i64 0, i64 0
  store i64 0, i64* %t38
  br label %ht_fill8_cond_1373
ht_fill8_cond_1373:
  %t39 = load i64, i64* %t38
  %t40 = icmp slt i64 %t39, 32
  br i1 %t40, label %ht_fill8_body_1374, label %ht_fill8_end_1375
ht_fill8_body_1374:
  %t41 = getelementptr inbounds i8, i8* %t37, i64 %t39
  store i8 0, i8* %t41
  %t42 = add i64 %t39, 1
  store i64 %t42, i64* %t38
  br label %ht_fill8_cond_1373
ht_fill8_end_1375:
  %t43 = bitcast i8* %t37 to i32*
  store i32 44100, i32* %t43
  %t44 = getelementptr inbounds i8, i8* %t37, i64 4
  %t45 = bitcast i8* %t44 to i16*
  store i16 32784, i16* %t45
  %t46 = getelementptr inbounds i8, i8* %t37, i64 6
  store i8 2, i8* %t46
  %t47 = getelementptr inbounds i8, i8* %t37, i64 8
  %t48 = bitcast i8* %t47 to i16*
  store i16 1024, i16* %t48
  %t49 = getelementptr inbounds i8, i8* %t37, i64 16
  %t50 = bitcast i8* %t49 to i8**
  %t51 = bitcast void (i8*, i8*, i32)* @star.audio.mix_callback to i8*
  store i8* %t51, i8** %t50
  %t52 = call i32 @SDL_OpenAudioDevice(i8* null, i32 0, i8* %t37, i8* null, i32 0)
  %t53 = icmp ne i32 %t52, 0
  br i1 %t53, label %audio_open_ok_1376, label %audio_dev_ok_1372
audio_open_ok_1376:
  store i32 %t52, i32* @star.audio.device
  call void @SDL_PauseAudioDevice(i32 %t52, i32 0)
  br label %audio_dev_ok_1372
audio_dev_ok_1372:
  %t54 = bitcast i8* %t30 to i64*
  %t55 = load i64, i64* %t54
  %t56 = getelementptr inbounds i8, i8* %t30, i64 8
  %t57 = bitcast i8* %t56 to i8**
  %t58 = load i8*, i8** %t57
  %t59 = getelementptr inbounds i8, i8* %t58, i64 44
  %t60 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 0
  store i8* %t59, i8** %t60
  %t61 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_len, i32 0, i32 0
  store i64 %t55, i64* %t61
  %t62 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_pos, i32 0, i32 0
  store i64 0, i64* %t62
  %t63 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 0
  store i8 1, i8* %t63
  %t64 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 0
  store i8 1, i8* %t64
  br label %if_end_1368
if_else_1367:
  br label %if_end_1368
if_end_1368:
  store i8* null, i8** %t65
  store i32 0, i32* %t66
  br label %while_cond_1377
while_cond_1377:
  %t67 = load i32, i32* %t66
  %t68 = mul i32 320, 200
  %t69 = mul i32 %t68, 4
  %t70 = icmp slt i32 %t67, %t69
  br i1 %t70, label %while_body_1378, label %while_else_1379
while_body_1378:
  %t71 = getelementptr i8, i8* null, i32 1
  %t72 = ptrtoint i8* %t71 to i64
  %t73 = load i8*, i8** %t65
  %t74 = icmp eq i8* %t73, null
  br i1 %t74, label %list_cow_alloc_1381, label %list_cow_check_1382
list_cow_alloc_1381:
  %t75 = bitcast void (i8*)* @list_release_u8 to i8*
  %t76 = call i8* @star_rc_alloc(i64 24, i8* %t75)
  %t77 = bitcast i8* %t76 to { i8*, i64, i64 }*
  %t78 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t77, i32 0, i32 0
  store i8* null, i8** %t78
  %t79 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t77, i32 0, i32 1
  store i64 0, i64* %t79
  %t80 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t77, i32 0, i32 2
  store i64 0, i64* %t80
  store i8* %t76, i8** %t65
  br label %list_cow_done_1383
list_cow_check_1382:
  %t81 = getelementptr inbounds i8, i8* %t73, i64 -16
  %t82 = bitcast i8* %t81 to i64*
  %t83 = load atomic i64, i64* %t82 seq_cst, align 8
  %t84 = icmp eq i64 %t83, 1
  br i1 %t84, label %list_cow_done_1383, label %list_cow_clone_1384
list_cow_clone_1384:
  %t85 = bitcast i8* %t73 to { i8*, i64, i64 }*
  %t86 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t85, i32 0, i32 0
  %t87 = load i8*, i8** %t86
  %t88 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t85, i32 0, i32 1
  %t89 = load i64, i64* %t88
  %t90 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t85, i32 0, i32 2
  %t91 = load i64, i64* %t90
  %t92 = bitcast void (i8*)* @list_release_u8 to i8*
  %t93 = call i8* @star_rc_alloc(i64 24, i8* %t92)
  %t94 = bitcast i8* %t93 to { i8*, i64, i64 }*
  %t95 = mul i64 %t91, %t72
  %t96 = call i8* @malloc(i64 %t95)
  %t97 = bitcast i8* %t96 to i8*
  %t98 = icmp sgt i64 %t89, 0
  br i1 %t98, label %list_cow_copy_1385, label %list_cow_after_copy_1386
list_cow_copy_1385:
  %t99 = mul i64 %t89, %t72
  %t100 = bitcast i8* %t87 to i8*
  call i8* @memcpy(i8* %t96, i8* %t100, i64 %t99)
  br label %list_cow_after_copy_1386
list_cow_after_copy_1386:
  %t101 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t94, i32 0, i32 0
  store i8* %t97, i8** %t101
  %t102 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t94, i32 0, i32 1
  store i64 %t89, i64* %t102
  %t103 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t94, i32 0, i32 2
  store i64 %t91, i64* %t103
  call void @star_rc_release(i8* %t73)
  store i8* %t93, i8** %t65
  br label %list_cow_done_1383
list_cow_done_1383:
  %t104 = load i8*, i8** %t65
  %t105 = bitcast i8* %t104 to { i8*, i64, i64 }*
  %t106 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t105, i32 0, i32 0
  %t107 = load i8*, i8** %t106
  %t108 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t105, i32 0, i32 1
  %t109 = load i64, i64* %t108
  %t110 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t105, i32 0, i32 2
  %t111 = trunc i32 0 to i8
  %t112 = load i64, i64* %t110
  %t113 = load i8*, i8** %t106
  %t114 = load i64, i64* %t108
  %t115 = icmp sge i64 %t114, %t112
  br i1 %t115, label %list_push_grow_1387, label %list_push_store_1388
list_push_grow_1387:
  %t116 = mul i64 %t112, 2
  %t117 = icmp sgt i64 %t116, 0
  %t118 = select i1 %t117, i64 %t116, i64 1
  %t119 = getelementptr i8, i8* null, i32 1
  %t120 = ptrtoint i8* %t119 to i64
  %t121 = mul i64 %t118, %t120
  %t122 = call i8* @malloc(i64 %t121)
  %t123 = bitcast i8* %t122 to i8*
  %t124 = icmp sgt i64 %t112, 0
  br i1 %t124, label %list_push_copy_1389, label %list_push_after_copy_1390
list_push_copy_1389:
  %t125 = mul i64 %t114, %t120
  %t126 = bitcast i8* %t113 to i8*
  call i8* @memcpy(i8* %t122, i8* %t126, i64 %t125)
  call void @free(i8* %t126)
  br label %list_push_after_copy_1390
list_push_after_copy_1390:
  store i8* %t123, i8** %t106
  store i64 %t118, i64* %t110
  br label %list_push_store_1388
list_push_store_1388:
  %t127 = load i8*, i8** %t106
  %t128 = getelementptr inbounds i8, i8* %t127, i64 %t114
  store i8 %t111, i8* %t128
  %t129 = add i64 %t114, 1
  store i64 %t129, i64* %t108
  %t130 = load i32, i32* %t66
  %t131 = add i32 %t130, 1
  store i32 %t131, i32* %t66
  br label %while_cond_1377
while_else_1379:
  br label %while_end_1380
while_end_1380:
  %t133 = load %map__Level, %map__Level* %t19
  %t134 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 0
  %t135 = load i8*, i8** %t134
  call void @star_rc_retain(i8* %t135)
  %t136 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 1
  %t137 = load i8*, i8** %t136
  call void @star_rc_retain(i8* %t137)
  %t138 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 2
  %t139 = load i8*, i8** %t138
  call void @star_rc_retain(i8* %t139)
  %t140 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 3
  %t141 = load i8*, i8** %t140
  call void @star_rc_retain(i8* %t141)
  %t142 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 4
  %t143 = load i8*, i8** %t142
  call void @star_rc_retain(i8* %t143)
  %t144 = call %Game @new_game(%map__Level %t133)
  store %Game %t144, %Game* %t132
  %t147 = call i32 @SDL_GetMouseState(i32* %t145, i32* %t146)
  %t148 = load i32, i32* %t145
  %t149 = load i32, i32* %t146
  %t150 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 6
  store i32 %t148, i32* %t150
  %t151 = call i32 @SDL_GetTicks()
  %t152 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 7
  store i32 %t151, i32* %t152
  br label %while_cond_1391
while_cond_1391:
  br i1 true, label %while_body_1392, label %while_else_1393
while_body_1392:
  %t153 = load i8*, i8** %t2
  %t154 = icmp eq i8* %t153, null
  br i1 %t154, label %sdl_null_window_1395, label %sdl_window_handle_ok_1396
sdl_null_window_1395:
  %t155 = getelementptr inbounds [85 x i8], [85 x i8]* @.str.52, i64 0, i64 0
  call i32 @puts(i8* %t155)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1396:
  store i1 false, i1* %t156
  %t158 = getelementptr inbounds [56 x i8], [56 x i8]* %t157, i64 0, i64 0
  br label %sdl_poll_cond_1397
sdl_poll_cond_1397:
  %t159 = call i32 @SDL_PollEvent(i8* %t158)
  %t160 = icmp ne i32 %t159, 0
  br i1 %t160, label %sdl_poll_body_1398, label %sdl_poll_end_1400
sdl_poll_body_1398:
  %t161 = bitcast i8* %t158 to i32*
  %t162 = load i32, i32* %t161
  %t163 = icmp eq i32 %t162, 256
  br i1 %t163, label %sdl_poll_set_quit_1399, label %sdl_poll_cond_1397
sdl_poll_set_quit_1399:
  store i1 true, i1* %t156
  br label %sdl_poll_cond_1397
sdl_poll_end_1400:
  %t164 = load i1, i1* %t156
  br i1 %t164, label %if_then_1401, label %if_else_1402
if_then_1401:
  br label %while_end_1394
if_else_1402:
  br label %if_end_1403
if_end_1403:
  %t165 = icmp sge i32 41, 0
  %t166 = icmp slt i32 41, 512
  %t167 = and i1 %t165, %t166
  br i1 %t167, label %key_down_read_1404, label %key_down_end_1405
key_down_read_1404:
  %t168 = call i8* @SDL_GetKeyboardState(i32* null)
  %t169 = sext i32 41 to i64
  %t170 = getelementptr inbounds i8, i8* %t168, i64 %t169
  %t171 = load i8, i8* %t170
  %t172 = icmp ne i8 %t171, 0
  br label %key_down_end_1405
key_down_end_1405:
  %t173 = phi i1 [ false, %if_end_1403 ], [ %t172, %key_down_read_1404 ]
  br i1 %t173, label %if_then_1406, label %if_else_1407
if_then_1406:
  br label %while_end_1394
if_else_1407:
  br label %if_end_1408
if_end_1408:
  %t175 = call i32 @SDL_GetTicks()
  store i32 %t175, i32* %t174
  %t177 = load i32, i32* %t174
  %t178 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 7
  %t179 = load i32, i32* %t178
  %t180 = sub i32 %t177, %t179
  %t181 = sitofp i32 %t180 to float
  %t182 = fdiv float %t181, 0x408F400000000000
  store float %t182, float* %t176
  %t183 = load i32, i32* %t174
  %t184 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 7
  store i32 %t183, i32* %t184
  %t185 = load float, float* %t176
  %t186 = call float @llvm.maxnum.f32(float %t185, float 0x0000000000000000)
  %t187 = call float @llvm.minnum.f32(float %t186, float 0x3FA99999A0000000)
  store float %t187, float* %t176
  %t188 = load float, float* %t176
  %t189 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 0
  %t190 = load i8*, i8** %t189
  %t191 = load i8*, i8** %t189
  call void @star_rc_retain(i8* %t191)
  %t192 = load %audio__Sounds, %audio__Sounds* %t23
  %t193 = call %Game @Game__update(%Game* %t132, float %t188, i8* %t190, %audio__Sounds %t192)
  %t194 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 1
  %t195 = load i8*, i8** %t194
  call void @star_rc_release(i8* %t195)
  %t196 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 2
  %t197 = load i8*, i8** %t196
  call void @star_rc_release(i8* %t197)
  %t198 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 3
  %t199 = load i8*, i8** %t198
  call void @star_rc_release(i8* %t199)
  store %Game %t193, %Game* %t132
  %t201 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t202 = getelementptr inbounds %Player, %Player* %t201, i32 0, i32 0
  %t203 = load float, float* %t202
  %t204 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t205 = getelementptr inbounds %Player, %Player* %t204, i32 0, i32 1
  %t206 = load float, float* %t205
  %t207 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t208 = getelementptr inbounds %Player, %Player* %t207, i32 0, i32 2
  %t209 = load float, float* %t208
  %t210 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 0
  %t211 = load i8*, i8** %t210
  %t212 = load i8*, i8** %t210
  call void @star_rc_retain(i8* %t212)
  %t213 = call { i8*, i8* } @render_walls(float %t203, float %t206, float %t209, i8* %t211)
  store { i8*, i8* } %t213, { i8*, i8* }* %t200
  %t214 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t200, i32 0, i32 0
  %t215 = load i8*, i8** %t214
  %t216 = load i8*, i8** %t214
  call void @star_rc_retain(i8* %t216)
  %t217 = load i8*, i8** %t65
  call void @star_rc_release(i8* %t217)
  store i8* %t215, i8** %t65
  %t219 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t200, i32 0, i32 1
  %t220 = load i8*, i8** %t219
  %t221 = load i8*, i8** %t219
  call void @star_rc_retain(i8* %t221)
  store i8* %t220, i8** %t218
  %t222 = load i8*, i8** %t218
  %t223 = load i8*, i8** %t218
  call void @star_rc_retain(i8* %t223)
  %t224 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t225 = getelementptr inbounds %Player, %Player* %t224, i32 0, i32 0
  %t226 = load float, float* %t225
  %t227 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t228 = getelementptr inbounds %Player, %Player* %t227, i32 0, i32 1
  %t229 = load float, float* %t228
  %t230 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t231 = getelementptr inbounds %Player, %Player* %t230, i32 0, i32 2
  %t232 = load float, float* %t231
  %t233 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 1
  %t234 = load i8*, i8** %t233
  %t235 = load i8*, i8** %t233
  call void @star_rc_retain(i8* %t235)
  %t236 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 2
  %t237 = load i8*, i8** %t236
  %t238 = load i8*, i8** %t236
  call void @star_rc_retain(i8* %t238)
  %t239 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 3
  %t240 = load i8*, i8** %t239
  %t241 = load i8*, i8** %t239
  call void @star_rc_retain(i8* %t241)
  %t242 = load %sprites__SpriteSet, %sprites__SpriteSet* %t21
  %t243 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 0
  %t244 = load i8*, i8** %t243
  call void @star_rc_retain(i8* %t244)
  %t245 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 1
  %t246 = load i8*, i8** %t245
  call void @star_rc_retain(i8* %t246)
  %t247 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 2
  %t248 = load i8*, i8** %t247
  call void @star_rc_retain(i8* %t248)
  %t249 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 3
  %t250 = load i8*, i8** %t249
  call void @star_rc_retain(i8* %t250)
  %t251 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 4
  %t252 = load i8*, i8** %t251
  call void @star_rc_retain(i8* %t252)
  %t253 = call i8* @render_sprites(i8* %t222, float %t226, float %t229, float %t232, i8* %t234, i8* %t237, i8* %t240, %sprites__SpriteSet %t242)
  %t254 = load i8*, i8** %t65
  call void @star_rc_release(i8* %t254)
  store i8* %t253, i8** %t65
  %t255 = load i8*, i8** %t2
  %t256 = icmp eq i8* %t255, null
  br i1 %t256, label %sdl_null_window_1409, label %sdl_window_handle_ok_1410
sdl_null_window_1409:
  %t257 = getelementptr inbounds [77 x i8], [77 x i8]* @.str.53, i64 0, i64 0
  call i32 @puts(i8* %t257)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1410:
  %t258 = call i8* @SDL_GetRenderer(i8* %t255)
  %t259 = load i8*, i8** %t65
  %t260 = icmp eq i8* %t259, null
  br i1 %t260, label %list_read_null_1411, label %list_read_real_1412
list_read_null_1411:
  br label %list_read_end_1413
list_read_real_1412:
  %t261 = bitcast i8* %t259 to { i8*, i64, i64 }*
  %t262 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t261, i32 0, i32 0
  %t263 = load i8*, i8** %t262
  %t264 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t261, i32 0, i32 1
  %t265 = load i64, i64* %t264
  br label %list_read_end_1413
list_read_end_1413:
  %t266 = phi i8* [ null, %list_read_null_1411 ], [ %t263, %list_read_real_1412 ]
  %t267 = phi i64 [ 0, %list_read_null_1411 ], [ %t265, %list_read_real_1412 ]
  %t268 = sext i32 320 to i64
  %t269 = sext i32 200 to i64
  %t270 = mul i64 %t268, %t269
  %t271 = mul i64 %t270, 4
  %t272 = icmp ult i64 %t267, %t271
  br i1 %t272, label %sdl_pixel_buffer_too_small_1414, label %sdl_pixel_buffer_ok_1415
sdl_pixel_buffer_too_small_1414:
  %t273 = getelementptr inbounds [105 x i8], [105 x i8]* @.str.54, i64 0, i64 0
  call i32 @puts(i8* %t273)
  call void @exit(i32 1)
  unreachable
sdl_pixel_buffer_ok_1415:
  %t274 = mul i32 320, 2
  %t275 = mul i32 200, 2
  %t276 = call i8* @SDL_CreateTexture(i8* %t258, i32 376840196, i32 0, i32 320, i32 200)
  %t277 = icmp eq i8* %t276, null
  br i1 %t277, label %draw_pixels_skip_1416, label %draw_pixels_ok_1417
draw_pixels_skip_1416:
  br label %draw_pixels_end_1418
draw_pixels_ok_1417:
  %t278 = mul i32 320, 4
  call i32 @SDL_UpdateTexture(i8* %t276, i8* null, i8* %t266, i32 %t278)
  %t280 = getelementptr inbounds [16 x i8], [16 x i8]* %t279, i64 0, i64 0
  %t281 = bitcast i8* %t280 to i32*
  store i32 0, i32* %t281
  %t282 = getelementptr inbounds i8, i8* %t280, i64 4
  %t283 = bitcast i8* %t282 to i32*
  store i32 0, i32* %t283
  %t284 = getelementptr inbounds i8, i8* %t280, i64 8
  %t285 = bitcast i8* %t284 to i32*
  store i32 %t274, i32* %t285
  %t286 = getelementptr inbounds i8, i8* %t280, i64 12
  %t287 = bitcast i8* %t286 to i32*
  store i32 %t275, i32* %t287
  call i32 @SDL_RenderCopy(i8* %t258, i8* %t276, i8* null, i8* %t280)
  call void @SDL_DestroyTexture(i8* %t276)
  br label %draw_pixels_end_1418
draw_pixels_end_1418:
  %t288 = load i8*, i8** %t2
  %t289 = icmp eq i8* %t288, null
  br i1 %t289, label %sdl_null_window_1419, label %sdl_window_handle_ok_1420
sdl_null_window_1419:
  %t290 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.55, i64 0, i64 0
  call i32 @puts(i8* %t290)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1420:
  %t291 = load i8*, i8** %t17
  %t292 = icmp eq i8* %t291, null
  br i1 %t292, label %font_null_handle_1421, label %font_handle_ok_1422
font_null_handle_1421:
  %t293 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.56, i64 0, i64 0
  call i32 @puts(i8* %t293)
  call void @exit(i32 1)
  unreachable
font_handle_ok_1422:
  %t294 = call i8* @SDL_GetRenderer(i8* %t288)
  %t295 = and i32 240, 255
  %t296 = and i32 60, 255
  %t297 = shl i32 %t296, 8
  %t298 = or i32 %t295, %t297
  %t299 = and i32 60, 255
  %t300 = shl i32 %t299, 16
  %t301 = or i32 %t298, %t300
  %t302 = and i32 255, 255
  %t303 = shl i32 %t302, 24
  %t304 = or i32 %t301, %t303
  %t305 = and i32 %t304, 255
  %t306 = trunc i32 %t305 to i8
  %t307 = lshr i32 %t304, 8
  %t308 = and i32 %t307, 255
  %t309 = trunc i32 %t308 to i8
  %t310 = lshr i32 %t304, 16
  %t311 = and i32 %t310, 255
  %t312 = trunc i32 %t311 to i8
  %t313 = lshr i32 %t304, 24
  %t314 = and i32 %t313, 255
  %t315 = trunc i32 %t314 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t294, i8 %t306, i8 %t309, i8 %t312, i8 %t315)
  %t316 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t317 = getelementptr inbounds %Player, %Player* %t316, i32 0, i32 3
  %t318 = load float, float* %t317
  %t319 = call i32 @llvm.fptosi.sat.i32.f32(float %t318)
  %t320 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t321 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t320, i32 %t319)
  %t322 = add i32 %t321, 1
  %t323 = sext i32 %t322 to i64
  %t324 = call i8* @star_rc_alloc(i64 %t323, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t324, i64 %t323, i8* %t320, i32 %t319)
  %t325 = icmp sgt i32 2, 0
  %t326 = select i1 %t325, i32 2, i32 1
  %t327 = load i8, i8* %t291
  %t328 = zext i8 %t327 to i32
  %t329 = getelementptr inbounds i8, i8* %t291, i64 1
  %t330 = load i8, i8* %t329
  %t331 = zext i8 %t330 to i32
  %t332 = getelementptr inbounds i8, i8* %t291, i64 2
  %t333 = load i8, i8* %t332
  %t334 = zext i8 %t333 to i32
  %t335 = getelementptr inbounds i8, i8* %t291, i64 3
  %t336 = load i8, i8* %t335
  %t337 = zext i8 %t336 to i32
  %t338 = add i32 %t328, 1
  %t339 = mul i32 %t338, %t326
  %t340 = add i32 %t331, 1
  %t341 = mul i32 %t340, %t326
  store i32 8, i32* %t342
  store i32 8, i32* %t343
  store i64 0, i64* %t344
  br label %draw_text_cond_1423
draw_text_cond_1423:
  %t345 = load i64, i64* %t344
  %t346 = getelementptr inbounds i8, i8* %t324, i64 %t345
  %t347 = load i8, i8* %t346
  %t348 = icmp eq i8 %t347, 0
  br i1 %t348, label %draw_text_end_1429, label %draw_text_body_1424
draw_text_body_1424:
  %t349 = zext i8 %t347 to i32
  %t350 = icmp eq i32 %t349, 10
  br i1 %t350, label %draw_text_newline_1425, label %draw_text_glyph_1426
draw_text_newline_1425:
  store i32 8, i32* %t342
  %t351 = load i32, i32* %t343
  %t352 = add i32 %t351, %t341
  store i32 %t352, i32* %t343
  %t353 = add i64 %t345, 1
  store i64 %t353, i64* %t344
  br label %draw_text_cond_1423
draw_text_glyph_1426:
  %t354 = icmp sge i32 %t349, 97
  %t355 = icmp sle i32 %t349, 122
  %t356 = and i1 %t354, %t355
  %t357 = sub i32 %t349, 32
  %t358 = select i1 %t356, i32 %t357, i32 %t349
  %t359 = sub i32 %t358, %t334
  %t360 = icmp sge i32 %t359, 0
  %t361 = icmp slt i32 %t359, %t337
  %t362 = and i1 %t360, %t361
  br i1 %t362, label %draw_text_draw_glyph_1427, label %draw_text_advance_1428
draw_text_draw_glyph_1427:
  %t363 = mul i32 %t359, %t331
  %t364 = add i32 %t363, 4
  %t365 = sext i32 %t364 to i64
  %t366 = load i32, i32* %t342
  %t367 = load i32, i32* %t343
  store i32 0, i32* %t368
  br label %draw_text_row_cond_1430
draw_text_row_cond_1430:
  %t369 = load i32, i32* %t368
  %t370 = icmp slt i32 %t369, %t331
  br i1 %t370, label %draw_text_row_body_1431, label %draw_text_row_end_1432
draw_text_row_body_1431:
  %t371 = sext i32 %t369 to i64
  %t372 = add i64 %t365, %t371
  %t373 = getelementptr inbounds i8, i8* %t291, i64 %t372
  %t374 = load i8, i8* %t373
  %t375 = zext i8 %t374 to i32
  store i32 0, i32* %t376
  br label %draw_text_col_cond_1433
draw_text_col_cond_1433:
  %t377 = load i32, i32* %t376
  %t378 = icmp slt i32 %t377, %t328
  br i1 %t378, label %draw_text_col_body_1434, label %draw_text_col_end_1435
draw_text_col_body_1434:
  %t379 = sub i32 %t328, 1
  %t380 = sub i32 %t379, %t377
  %t381 = and i32 %t380, 31
  %t382 = lshr i32 %t375, %t381
  %t383 = and i32 %t382, 1
  %t384 = icmp ne i32 %t383, 0
  br i1 %t384, label %draw_text_pixel_1436, label %draw_text_after_pixel_1437
draw_text_pixel_1436:
  %t385 = mul i32 %t377, %t326
  %t386 = add i32 %t366, %t385
  %t387 = mul i32 %t369, %t326
  %t388 = add i32 %t367, %t387
  %t390 = getelementptr inbounds [16 x i8], [16 x i8]* %t389, i64 0, i64 0
  %t391 = bitcast i8* %t390 to i32*
  store i32 %t386, i32* %t391
  %t392 = getelementptr inbounds i8, i8* %t390, i64 4
  %t393 = bitcast i8* %t392 to i32*
  store i32 %t388, i32* %t393
  %t394 = getelementptr inbounds i8, i8* %t390, i64 8
  %t395 = bitcast i8* %t394 to i32*
  store i32 %t326, i32* %t395
  %t396 = getelementptr inbounds i8, i8* %t390, i64 12
  %t397 = bitcast i8* %t396 to i32*
  store i32 %t326, i32* %t397
  call i32 @SDL_RenderFillRect(i8* %t294, i8* %t390)
  br label %draw_text_after_pixel_1437
draw_text_after_pixel_1437:
  %t398 = add i32 %t377, 1
  store i32 %t398, i32* %t376
  br label %draw_text_col_cond_1433
draw_text_col_end_1435:
  %t399 = add i32 %t369, 1
  store i32 %t399, i32* %t368
  br label %draw_text_row_cond_1430
draw_text_row_end_1432:
  br label %draw_text_advance_1428
draw_text_advance_1428:
  %t400 = load i32, i32* %t342
  %t401 = add i32 %t400, %t339
  store i32 %t401, i32* %t342
  %t402 = add i64 %t345, 1
  store i64 %t402, i64* %t344
  br label %draw_text_cond_1423
draw_text_end_1429:
  call void @star_rc_release(i8* %t324)
  %t403 = load i8*, i8** %t2
  %t404 = icmp eq i8* %t403, null
  br i1 %t404, label %sdl_null_window_1438, label %sdl_window_handle_ok_1439
sdl_null_window_1438:
  %t405 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.58, i64 0, i64 0
  call i32 @puts(i8* %t405)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1439:
  %t406 = load i8*, i8** %t17
  %t407 = icmp eq i8* %t406, null
  br i1 %t407, label %font_null_handle_1440, label %font_handle_ok_1441
font_null_handle_1440:
  %t408 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.59, i64 0, i64 0
  call i32 @puts(i8* %t408)
  call void @exit(i32 1)
  unreachable
font_handle_ok_1441:
  %t409 = call i8* @SDL_GetRenderer(i8* %t403)
  %t410 = and i32 60, 255
  %t411 = and i32 120, 255
  %t412 = shl i32 %t411, 8
  %t413 = or i32 %t410, %t412
  %t414 = and i32 240, 255
  %t415 = shl i32 %t414, 16
  %t416 = or i32 %t413, %t415
  %t417 = and i32 255, 255
  %t418 = shl i32 %t417, 24
  %t419 = or i32 %t416, %t418
  %t420 = and i32 %t419, 255
  %t421 = trunc i32 %t420 to i8
  %t422 = lshr i32 %t419, 8
  %t423 = and i32 %t422, 255
  %t424 = trunc i32 %t423 to i8
  %t425 = lshr i32 %t419, 16
  %t426 = and i32 %t425, 255
  %t427 = trunc i32 %t426 to i8
  %t428 = lshr i32 %t419, 24
  %t429 = and i32 %t428, 255
  %t430 = trunc i32 %t429 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t409, i8 %t421, i8 %t424, i8 %t427, i8 %t430)
  %t431 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t432 = getelementptr inbounds %Player, %Player* %t431, i32 0, i32 4
  %t433 = load float, float* %t432
  %t434 = call i32 @llvm.fptosi.sat.i32.f32(float %t433)
  %t435 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.60, i64 0, i64 0
  %t436 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t435, i32 %t434)
  %t437 = add i32 %t436, 1
  %t438 = sext i32 %t437 to i64
  %t439 = call i8* @star_rc_alloc(i64 %t438, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t439, i64 %t438, i8* %t435, i32 %t434)
  %t440 = icmp sgt i32 2, 0
  %t441 = select i1 %t440, i32 2, i32 1
  %t442 = load i8, i8* %t406
  %t443 = zext i8 %t442 to i32
  %t444 = getelementptr inbounds i8, i8* %t406, i64 1
  %t445 = load i8, i8* %t444
  %t446 = zext i8 %t445 to i32
  %t447 = getelementptr inbounds i8, i8* %t406, i64 2
  %t448 = load i8, i8* %t447
  %t449 = zext i8 %t448 to i32
  %t450 = getelementptr inbounds i8, i8* %t406, i64 3
  %t451 = load i8, i8* %t450
  %t452 = zext i8 %t451 to i32
  %t453 = add i32 %t443, 1
  %t454 = mul i32 %t453, %t441
  %t455 = add i32 %t446, 1
  %t456 = mul i32 %t455, %t441
  store i32 8, i32* %t457
  store i32 28, i32* %t458
  store i64 0, i64* %t459
  br label %draw_text_cond_1442
draw_text_cond_1442:
  %t460 = load i64, i64* %t459
  %t461 = getelementptr inbounds i8, i8* %t439, i64 %t460
  %t462 = load i8, i8* %t461
  %t463 = icmp eq i8 %t462, 0
  br i1 %t463, label %draw_text_end_1448, label %draw_text_body_1443
draw_text_body_1443:
  %t464 = zext i8 %t462 to i32
  %t465 = icmp eq i32 %t464, 10
  br i1 %t465, label %draw_text_newline_1444, label %draw_text_glyph_1445
draw_text_newline_1444:
  store i32 8, i32* %t457
  %t466 = load i32, i32* %t458
  %t467 = add i32 %t466, %t456
  store i32 %t467, i32* %t458
  %t468 = add i64 %t460, 1
  store i64 %t468, i64* %t459
  br label %draw_text_cond_1442
draw_text_glyph_1445:
  %t469 = icmp sge i32 %t464, 97
  %t470 = icmp sle i32 %t464, 122
  %t471 = and i1 %t469, %t470
  %t472 = sub i32 %t464, 32
  %t473 = select i1 %t471, i32 %t472, i32 %t464
  %t474 = sub i32 %t473, %t449
  %t475 = icmp sge i32 %t474, 0
  %t476 = icmp slt i32 %t474, %t452
  %t477 = and i1 %t475, %t476
  br i1 %t477, label %draw_text_draw_glyph_1446, label %draw_text_advance_1447
draw_text_draw_glyph_1446:
  %t478 = mul i32 %t474, %t446
  %t479 = add i32 %t478, 4
  %t480 = sext i32 %t479 to i64
  %t481 = load i32, i32* %t457
  %t482 = load i32, i32* %t458
  store i32 0, i32* %t483
  br label %draw_text_row_cond_1449
draw_text_row_cond_1449:
  %t484 = load i32, i32* %t483
  %t485 = icmp slt i32 %t484, %t446
  br i1 %t485, label %draw_text_row_body_1450, label %draw_text_row_end_1451
draw_text_row_body_1450:
  %t486 = sext i32 %t484 to i64
  %t487 = add i64 %t480, %t486
  %t488 = getelementptr inbounds i8, i8* %t406, i64 %t487
  %t489 = load i8, i8* %t488
  %t490 = zext i8 %t489 to i32
  store i32 0, i32* %t491
  br label %draw_text_col_cond_1452
draw_text_col_cond_1452:
  %t492 = load i32, i32* %t491
  %t493 = icmp slt i32 %t492, %t443
  br i1 %t493, label %draw_text_col_body_1453, label %draw_text_col_end_1454
draw_text_col_body_1453:
  %t494 = sub i32 %t443, 1
  %t495 = sub i32 %t494, %t492
  %t496 = and i32 %t495, 31
  %t497 = lshr i32 %t490, %t496
  %t498 = and i32 %t497, 1
  %t499 = icmp ne i32 %t498, 0
  br i1 %t499, label %draw_text_pixel_1455, label %draw_text_after_pixel_1456
draw_text_pixel_1455:
  %t500 = mul i32 %t492, %t441
  %t501 = add i32 %t481, %t500
  %t502 = mul i32 %t484, %t441
  %t503 = add i32 %t482, %t502
  %t505 = getelementptr inbounds [16 x i8], [16 x i8]* %t504, i64 0, i64 0
  %t506 = bitcast i8* %t505 to i32*
  store i32 %t501, i32* %t506
  %t507 = getelementptr inbounds i8, i8* %t505, i64 4
  %t508 = bitcast i8* %t507 to i32*
  store i32 %t503, i32* %t508
  %t509 = getelementptr inbounds i8, i8* %t505, i64 8
  %t510 = bitcast i8* %t509 to i32*
  store i32 %t441, i32* %t510
  %t511 = getelementptr inbounds i8, i8* %t505, i64 12
  %t512 = bitcast i8* %t511 to i32*
  store i32 %t441, i32* %t512
  call i32 @SDL_RenderFillRect(i8* %t409, i8* %t505)
  br label %draw_text_after_pixel_1456
draw_text_after_pixel_1456:
  %t513 = add i32 %t492, 1
  store i32 %t513, i32* %t491
  br label %draw_text_col_cond_1452
draw_text_col_end_1454:
  %t514 = add i32 %t484, 1
  store i32 %t514, i32* %t483
  br label %draw_text_row_cond_1449
draw_text_row_end_1451:
  br label %draw_text_advance_1447
draw_text_advance_1447:
  %t515 = load i32, i32* %t457
  %t516 = add i32 %t515, %t454
  store i32 %t516, i32* %t457
  %t517 = add i64 %t460, 1
  store i64 %t517, i64* %t459
  br label %draw_text_cond_1442
draw_text_end_1448:
  call void @star_rc_release(i8* %t439)
  %t518 = load i8*, i8** %t2
  %t519 = icmp eq i8* %t518, null
  br i1 %t519, label %sdl_null_window_1457, label %sdl_window_handle_ok_1458
sdl_null_window_1457:
  %t520 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.61, i64 0, i64 0
  call i32 @puts(i8* %t520)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1458:
  %t521 = load i8*, i8** %t17
  %t522 = icmp eq i8* %t521, null
  br i1 %t522, label %font_null_handle_1459, label %font_handle_ok_1460
font_null_handle_1459:
  %t523 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.62, i64 0, i64 0
  call i32 @puts(i8* %t523)
  call void @exit(i32 1)
  unreachable
font_handle_ok_1460:
  %t524 = call i8* @SDL_GetRenderer(i8* %t518)
  %t525 = and i32 240, 255
  %t526 = and i32 240, 255
  %t527 = shl i32 %t526, 8
  %t528 = or i32 %t525, %t527
  %t529 = and i32 240, 255
  %t530 = shl i32 %t529, 16
  %t531 = or i32 %t528, %t530
  %t532 = and i32 255, 255
  %t533 = shl i32 %t532, 24
  %t534 = or i32 %t531, %t533
  %t535 = and i32 %t534, 255
  %t536 = trunc i32 %t535 to i8
  %t537 = lshr i32 %t534, 8
  %t538 = and i32 %t537, 255
  %t539 = trunc i32 %t538 to i8
  %t540 = lshr i32 %t534, 16
  %t541 = and i32 %t540, 255
  %t542 = trunc i32 %t541 to i8
  %t543 = lshr i32 %t534, 24
  %t544 = and i32 %t543, 255
  %t545 = trunc i32 %t544 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t524, i8 %t536, i8 %t539, i8 %t542, i8 %t545)
  %t546 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t547 = getelementptr inbounds %Player, %Player* %t546, i32 0, i32 5
  %t548 = load i32, i32* %t547
  %t549 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.63, i64 0, i64 0
  %t550 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t549, i32 %t548)
  %t551 = add i32 %t550, 1
  %t552 = sext i32 %t551 to i64
  %t553 = call i8* @star_rc_alloc(i64 %t552, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t553, i64 %t552, i8* %t549, i32 %t548)
  %t554 = icmp sgt i32 2, 0
  %t555 = select i1 %t554, i32 2, i32 1
  %t556 = load i8, i8* %t521
  %t557 = zext i8 %t556 to i32
  %t558 = getelementptr inbounds i8, i8* %t521, i64 1
  %t559 = load i8, i8* %t558
  %t560 = zext i8 %t559 to i32
  %t561 = getelementptr inbounds i8, i8* %t521, i64 2
  %t562 = load i8, i8* %t561
  %t563 = zext i8 %t562 to i32
  %t564 = getelementptr inbounds i8, i8* %t521, i64 3
  %t565 = load i8, i8* %t564
  %t566 = zext i8 %t565 to i32
  %t567 = add i32 %t557, 1
  %t568 = mul i32 %t567, %t555
  %t569 = add i32 %t560, 1
  %t570 = mul i32 %t569, %t555
  store i32 8, i32* %t571
  store i32 48, i32* %t572
  store i64 0, i64* %t573
  br label %draw_text_cond_1461
draw_text_cond_1461:
  %t574 = load i64, i64* %t573
  %t575 = getelementptr inbounds i8, i8* %t553, i64 %t574
  %t576 = load i8, i8* %t575
  %t577 = icmp eq i8 %t576, 0
  br i1 %t577, label %draw_text_end_1467, label %draw_text_body_1462
draw_text_body_1462:
  %t578 = zext i8 %t576 to i32
  %t579 = icmp eq i32 %t578, 10
  br i1 %t579, label %draw_text_newline_1463, label %draw_text_glyph_1464
draw_text_newline_1463:
  store i32 8, i32* %t571
  %t580 = load i32, i32* %t572
  %t581 = add i32 %t580, %t570
  store i32 %t581, i32* %t572
  %t582 = add i64 %t574, 1
  store i64 %t582, i64* %t573
  br label %draw_text_cond_1461
draw_text_glyph_1464:
  %t583 = icmp sge i32 %t578, 97
  %t584 = icmp sle i32 %t578, 122
  %t585 = and i1 %t583, %t584
  %t586 = sub i32 %t578, 32
  %t587 = select i1 %t585, i32 %t586, i32 %t578
  %t588 = sub i32 %t587, %t563
  %t589 = icmp sge i32 %t588, 0
  %t590 = icmp slt i32 %t588, %t566
  %t591 = and i1 %t589, %t590
  br i1 %t591, label %draw_text_draw_glyph_1465, label %draw_text_advance_1466
draw_text_draw_glyph_1465:
  %t592 = mul i32 %t588, %t560
  %t593 = add i32 %t592, 4
  %t594 = sext i32 %t593 to i64
  %t595 = load i32, i32* %t571
  %t596 = load i32, i32* %t572
  store i32 0, i32* %t597
  br label %draw_text_row_cond_1468
draw_text_row_cond_1468:
  %t598 = load i32, i32* %t597
  %t599 = icmp slt i32 %t598, %t560
  br i1 %t599, label %draw_text_row_body_1469, label %draw_text_row_end_1470
draw_text_row_body_1469:
  %t600 = sext i32 %t598 to i64
  %t601 = add i64 %t594, %t600
  %t602 = getelementptr inbounds i8, i8* %t521, i64 %t601
  %t603 = load i8, i8* %t602
  %t604 = zext i8 %t603 to i32
  store i32 0, i32* %t605
  br label %draw_text_col_cond_1471
draw_text_col_cond_1471:
  %t606 = load i32, i32* %t605
  %t607 = icmp slt i32 %t606, %t557
  br i1 %t607, label %draw_text_col_body_1472, label %draw_text_col_end_1473
draw_text_col_body_1472:
  %t608 = sub i32 %t557, 1
  %t609 = sub i32 %t608, %t606
  %t610 = and i32 %t609, 31
  %t611 = lshr i32 %t604, %t610
  %t612 = and i32 %t611, 1
  %t613 = icmp ne i32 %t612, 0
  br i1 %t613, label %draw_text_pixel_1474, label %draw_text_after_pixel_1475
draw_text_pixel_1474:
  %t614 = mul i32 %t606, %t555
  %t615 = add i32 %t595, %t614
  %t616 = mul i32 %t598, %t555
  %t617 = add i32 %t596, %t616
  %t619 = getelementptr inbounds [16 x i8], [16 x i8]* %t618, i64 0, i64 0
  %t620 = bitcast i8* %t619 to i32*
  store i32 %t615, i32* %t620
  %t621 = getelementptr inbounds i8, i8* %t619, i64 4
  %t622 = bitcast i8* %t621 to i32*
  store i32 %t617, i32* %t622
  %t623 = getelementptr inbounds i8, i8* %t619, i64 8
  %t624 = bitcast i8* %t623 to i32*
  store i32 %t555, i32* %t624
  %t625 = getelementptr inbounds i8, i8* %t619, i64 12
  %t626 = bitcast i8* %t625 to i32*
  store i32 %t555, i32* %t626
  call i32 @SDL_RenderFillRect(i8* %t524, i8* %t619)
  br label %draw_text_after_pixel_1475
draw_text_after_pixel_1475:
  %t627 = add i32 %t606, 1
  store i32 %t627, i32* %t605
  br label %draw_text_col_cond_1471
draw_text_col_end_1473:
  %t628 = add i32 %t598, 1
  store i32 %t628, i32* %t597
  br label %draw_text_row_cond_1468
draw_text_row_end_1470:
  br label %draw_text_advance_1466
draw_text_advance_1466:
  %t629 = load i32, i32* %t571
  %t630 = add i32 %t629, %t568
  store i32 %t630, i32* %t571
  %t631 = add i64 %t574, 1
  store i64 %t631, i64* %t573
  br label %draw_text_cond_1461
draw_text_end_1467:
  call void @star_rc_release(i8* %t553)
  %t632 = load i8*, i8** %t2
  %t633 = icmp eq i8* %t632, null
  br i1 %t633, label %sdl_null_window_1476, label %sdl_window_handle_ok_1477
sdl_null_window_1476:
  %t634 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.64, i64 0, i64 0
  call i32 @puts(i8* %t634)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1477:
  %t635 = load i8*, i8** %t17
  %t636 = icmp eq i8* %t635, null
  br i1 %t636, label %font_null_handle_1478, label %font_handle_ok_1479
font_null_handle_1478:
  %t637 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.65, i64 0, i64 0
  call i32 @puts(i8* %t637)
  call void @exit(i32 1)
  unreachable
font_handle_ok_1479:
  %t638 = call i8* @SDL_GetRenderer(i8* %t632)
  %t639 = and i32 160, 255
  %t640 = and i32 160, 255
  %t641 = shl i32 %t640, 8
  %t642 = or i32 %t639, %t641
  %t643 = and i32 160, 255
  %t644 = shl i32 %t643, 16
  %t645 = or i32 %t642, %t644
  %t646 = and i32 255, 255
  %t647 = shl i32 %t646, 24
  %t648 = or i32 %t645, %t647
  %t649 = and i32 %t648, 255
  %t650 = trunc i32 %t649 to i8
  %t651 = lshr i32 %t648, 8
  %t652 = and i32 %t651, 255
  %t653 = trunc i32 %t652 to i8
  %t654 = lshr i32 %t648, 16
  %t655 = and i32 %t654, 255
  %t656 = trunc i32 %t655 to i8
  %t657 = lshr i32 %t648, 24
  %t658 = and i32 %t657, 255
  %t659 = trunc i32 %t658 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t638, i8 %t650, i8 %t653, i8 %t656, i8 %t659)
  %t660 = getelementptr inbounds { i64, i8*, [33 x i8] }, { i64, i8*, [33 x i8] }* @.str.66, i64 0, i32 2, i64 0
  %t661 = mul i32 200, 2
  %t662 = sub i32 %t661, 20
  %t663 = icmp sgt i32 1, 0
  %t664 = select i1 %t663, i32 1, i32 1
  %t665 = load i8, i8* %t635
  %t666 = zext i8 %t665 to i32
  %t667 = getelementptr inbounds i8, i8* %t635, i64 1
  %t668 = load i8, i8* %t667
  %t669 = zext i8 %t668 to i32
  %t670 = getelementptr inbounds i8, i8* %t635, i64 2
  %t671 = load i8, i8* %t670
  %t672 = zext i8 %t671 to i32
  %t673 = getelementptr inbounds i8, i8* %t635, i64 3
  %t674 = load i8, i8* %t673
  %t675 = zext i8 %t674 to i32
  %t676 = add i32 %t666, 1
  %t677 = mul i32 %t676, %t664
  %t678 = add i32 %t669, 1
  %t679 = mul i32 %t678, %t664
  store i32 8, i32* %t680
  store i32 %t662, i32* %t681
  store i64 0, i64* %t682
  br label %draw_text_cond_1480
draw_text_cond_1480:
  %t683 = load i64, i64* %t682
  %t684 = getelementptr inbounds i8, i8* %t660, i64 %t683
  %t685 = load i8, i8* %t684
  %t686 = icmp eq i8 %t685, 0
  br i1 %t686, label %draw_text_end_1486, label %draw_text_body_1481
draw_text_body_1481:
  %t687 = zext i8 %t685 to i32
  %t688 = icmp eq i32 %t687, 10
  br i1 %t688, label %draw_text_newline_1482, label %draw_text_glyph_1483
draw_text_newline_1482:
  store i32 8, i32* %t680
  %t689 = load i32, i32* %t681
  %t690 = add i32 %t689, %t679
  store i32 %t690, i32* %t681
  %t691 = add i64 %t683, 1
  store i64 %t691, i64* %t682
  br label %draw_text_cond_1480
draw_text_glyph_1483:
  %t692 = icmp sge i32 %t687, 97
  %t693 = icmp sle i32 %t687, 122
  %t694 = and i1 %t692, %t693
  %t695 = sub i32 %t687, 32
  %t696 = select i1 %t694, i32 %t695, i32 %t687
  %t697 = sub i32 %t696, %t672
  %t698 = icmp sge i32 %t697, 0
  %t699 = icmp slt i32 %t697, %t675
  %t700 = and i1 %t698, %t699
  br i1 %t700, label %draw_text_draw_glyph_1484, label %draw_text_advance_1485
draw_text_draw_glyph_1484:
  %t701 = mul i32 %t697, %t669
  %t702 = add i32 %t701, 4
  %t703 = sext i32 %t702 to i64
  %t704 = load i32, i32* %t680
  %t705 = load i32, i32* %t681
  store i32 0, i32* %t706
  br label %draw_text_row_cond_1487
draw_text_row_cond_1487:
  %t707 = load i32, i32* %t706
  %t708 = icmp slt i32 %t707, %t669
  br i1 %t708, label %draw_text_row_body_1488, label %draw_text_row_end_1489
draw_text_row_body_1488:
  %t709 = sext i32 %t707 to i64
  %t710 = add i64 %t703, %t709
  %t711 = getelementptr inbounds i8, i8* %t635, i64 %t710
  %t712 = load i8, i8* %t711
  %t713 = zext i8 %t712 to i32
  store i32 0, i32* %t714
  br label %draw_text_col_cond_1490
draw_text_col_cond_1490:
  %t715 = load i32, i32* %t714
  %t716 = icmp slt i32 %t715, %t666
  br i1 %t716, label %draw_text_col_body_1491, label %draw_text_col_end_1492
draw_text_col_body_1491:
  %t717 = sub i32 %t666, 1
  %t718 = sub i32 %t717, %t715
  %t719 = and i32 %t718, 31
  %t720 = lshr i32 %t713, %t719
  %t721 = and i32 %t720, 1
  %t722 = icmp ne i32 %t721, 0
  br i1 %t722, label %draw_text_pixel_1493, label %draw_text_after_pixel_1494
draw_text_pixel_1493:
  %t723 = mul i32 %t715, %t664
  %t724 = add i32 %t704, %t723
  %t725 = mul i32 %t707, %t664
  %t726 = add i32 %t705, %t725
  %t728 = getelementptr inbounds [16 x i8], [16 x i8]* %t727, i64 0, i64 0
  %t729 = bitcast i8* %t728 to i32*
  store i32 %t724, i32* %t729
  %t730 = getelementptr inbounds i8, i8* %t728, i64 4
  %t731 = bitcast i8* %t730 to i32*
  store i32 %t726, i32* %t731
  %t732 = getelementptr inbounds i8, i8* %t728, i64 8
  %t733 = bitcast i8* %t732 to i32*
  store i32 %t664, i32* %t733
  %t734 = getelementptr inbounds i8, i8* %t728, i64 12
  %t735 = bitcast i8* %t734 to i32*
  store i32 %t664, i32* %t735
  call i32 @SDL_RenderFillRect(i8* %t638, i8* %t728)
  br label %draw_text_after_pixel_1494
draw_text_after_pixel_1494:
  %t736 = add i32 %t715, 1
  store i32 %t736, i32* %t714
  br label %draw_text_col_cond_1490
draw_text_col_end_1492:
  %t737 = add i32 %t707, 1
  store i32 %t737, i32* %t706
  br label %draw_text_row_cond_1487
draw_text_row_end_1489:
  br label %draw_text_advance_1485
draw_text_advance_1485:
  %t738 = load i32, i32* %t680
  %t739 = add i32 %t738, %t677
  store i32 %t739, i32* %t680
  %t740 = add i64 %t683, 1
  store i64 %t740, i64* %t682
  br label %draw_text_cond_1480
draw_text_end_1486:
  call void @star_rc_release(i8* %t660)
  %t742 = mul i32 320, 2
  %t743 = icmp eq i32 2, 0
  %t744 = icmp eq i32 %t742, -2147483648
  %t745 = icmp eq i32 2, -1
  %t746 = and i1 %t744, %t745
  %t747 = or i1 %t743, %t746
  br i1 %t747, label %int_div_fail_1495, label %int_div_ok_1496
int_div_fail_1495:
  %t748 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.67, i64 0, i64 0
  call i32 @puts(i8* %t748)
  call void @exit(i32 1)
  unreachable
int_div_ok_1496:
  %t749 = sdiv i32 %t742, 2
  store i32 %t749, i32* %t741
  %t751 = mul i32 200, 2
  %t752 = icmp eq i32 2, 0
  %t753 = icmp eq i32 %t751, -2147483648
  %t754 = icmp eq i32 2, -1
  %t755 = and i1 %t753, %t754
  %t756 = or i1 %t752, %t755
  br i1 %t756, label %int_div_fail_1497, label %int_div_ok_1498
int_div_fail_1497:
  %t757 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.68, i64 0, i64 0
  call i32 @puts(i8* %t757)
  call void @exit(i32 1)
  unreachable
int_div_ok_1498:
  %t758 = sdiv i32 %t751, 2
  store i32 %t758, i32* %t750
  %t759 = load i8*, i8** %t2
  %t760 = icmp eq i8* %t759, null
  br i1 %t760, label %sdl_null_window_1499, label %sdl_window_handle_ok_1500
sdl_null_window_1499:
  %t761 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.69, i64 0, i64 0
  call i32 @puts(i8* %t761)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1500:
  %t762 = call i8* @SDL_GetRenderer(i8* %t759)
  %t763 = load i32, i32* %t741
  %t764 = sub i32 %t763, 4
  %t765 = load i32, i32* %t750
  %t766 = sub i32 %t765, 1
  %t767 = and i32 255, 255
  %t768 = and i32 255, 255
  %t769 = shl i32 %t768, 8
  %t770 = or i32 %t767, %t769
  %t771 = and i32 255, 255
  %t772 = shl i32 %t771, 16
  %t773 = or i32 %t770, %t772
  %t774 = and i32 255, 255
  %t775 = shl i32 %t774, 24
  %t776 = or i32 %t773, %t775
  %t777 = and i32 %t776, 255
  %t778 = trunc i32 %t777 to i8
  %t779 = lshr i32 %t776, 8
  %t780 = and i32 %t779, 255
  %t781 = trunc i32 %t780 to i8
  %t782 = lshr i32 %t776, 16
  %t783 = and i32 %t782, 255
  %t784 = trunc i32 %t783 to i8
  %t785 = lshr i32 %t776, 24
  %t786 = and i32 %t785, 255
  %t787 = trunc i32 %t786 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t762, i8 %t778, i8 %t781, i8 %t784, i8 %t787)
  %t789 = getelementptr inbounds [16 x i8], [16 x i8]* %t788, i64 0, i64 0
  %t790 = bitcast i8* %t789 to i32*
  store i32 %t764, i32* %t790
  %t791 = getelementptr inbounds i8, i8* %t789, i64 4
  %t792 = bitcast i8* %t791 to i32*
  store i32 %t766, i32* %t792
  %t793 = getelementptr inbounds i8, i8* %t789, i64 8
  %t794 = bitcast i8* %t793 to i32*
  store i32 8, i32* %t794
  %t795 = getelementptr inbounds i8, i8* %t789, i64 12
  %t796 = bitcast i8* %t795 to i32*
  store i32 2, i32* %t796
  call i32 @SDL_RenderFillRect(i8* %t762, i8* %t789)
  %t797 = load i8*, i8** %t2
  %t798 = icmp eq i8* %t797, null
  br i1 %t798, label %sdl_null_window_1501, label %sdl_window_handle_ok_1502
sdl_null_window_1501:
  %t799 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.70, i64 0, i64 0
  call i32 @puts(i8* %t799)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1502:
  %t800 = call i8* @SDL_GetRenderer(i8* %t797)
  %t801 = load i32, i32* %t741
  %t802 = sub i32 %t801, 1
  %t803 = load i32, i32* %t750
  %t804 = sub i32 %t803, 4
  %t805 = and i32 255, 255
  %t806 = and i32 255, 255
  %t807 = shl i32 %t806, 8
  %t808 = or i32 %t805, %t807
  %t809 = and i32 255, 255
  %t810 = shl i32 %t809, 16
  %t811 = or i32 %t808, %t810
  %t812 = and i32 255, 255
  %t813 = shl i32 %t812, 24
  %t814 = or i32 %t811, %t813
  %t815 = and i32 %t814, 255
  %t816 = trunc i32 %t815 to i8
  %t817 = lshr i32 %t814, 8
  %t818 = and i32 %t817, 255
  %t819 = trunc i32 %t818 to i8
  %t820 = lshr i32 %t814, 16
  %t821 = and i32 %t820, 255
  %t822 = trunc i32 %t821 to i8
  %t823 = lshr i32 %t814, 24
  %t824 = and i32 %t823, 255
  %t825 = trunc i32 %t824 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t800, i8 %t816, i8 %t819, i8 %t822, i8 %t825)
  %t827 = getelementptr inbounds [16 x i8], [16 x i8]* %t826, i64 0, i64 0
  %t828 = bitcast i8* %t827 to i32*
  store i32 %t802, i32* %t828
  %t829 = getelementptr inbounds i8, i8* %t827, i64 4
  %t830 = bitcast i8* %t829 to i32*
  store i32 %t804, i32* %t830
  %t831 = getelementptr inbounds i8, i8* %t827, i64 8
  %t832 = bitcast i8* %t831 to i32*
  store i32 2, i32* %t832
  %t833 = getelementptr inbounds i8, i8* %t827, i64 12
  %t834 = bitcast i8* %t833 to i32*
  store i32 8, i32* %t834
  call i32 @SDL_RenderFillRect(i8* %t800, i8* %t827)
  %t836 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 4
  %t837 = load float, float* %t836
  %t838 = fcmp ogt float %t837, 0x0000000000000000
  br i1 %t838, label %if_then_1503, label %if_else_1504
if_then_1503:
  %t839 = mul i32 200, 2
  %t840 = sub i32 %t839, 60
  br label %if_end_1505
if_else_1504:
  %t841 = mul i32 200, 2
  %t842 = sub i32 %t841, 50
  br label %if_end_1505
if_end_1505:
  %t843 = phi i32 [ %t840, %if_then_1503 ], [ %t842, %if_else_1504 ]
  store i32 %t843, i32* %t835
  %t844 = load i8*, i8** %t2
  %t845 = icmp eq i8* %t844, null
  br i1 %t845, label %sdl_null_window_1506, label %sdl_window_handle_ok_1507
sdl_null_window_1506:
  %t846 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.71, i64 0, i64 0
  call i32 @puts(i8* %t846)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1507:
  %t847 = call i8* @SDL_GetRenderer(i8* %t844)
  %t848 = load i32, i32* %t741
  %t849 = sub i32 %t848, 30
  %t850 = load i32, i32* %t835
  %t851 = and i32 120, 255
  %t852 = and i32 100, 255
  %t853 = shl i32 %t852, 8
  %t854 = or i32 %t851, %t853
  %t855 = and i32 80, 255
  %t856 = shl i32 %t855, 16
  %t857 = or i32 %t854, %t856
  %t858 = and i32 255, 255
  %t859 = shl i32 %t858, 24
  %t860 = or i32 %t857, %t859
  %t861 = and i32 %t860, 255
  %t862 = trunc i32 %t861 to i8
  %t863 = lshr i32 %t860, 8
  %t864 = and i32 %t863, 255
  %t865 = trunc i32 %t864 to i8
  %t866 = lshr i32 %t860, 16
  %t867 = and i32 %t866, 255
  %t868 = trunc i32 %t867 to i8
  %t869 = lshr i32 %t860, 24
  %t870 = and i32 %t869, 255
  %t871 = trunc i32 %t870 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t847, i8 %t862, i8 %t865, i8 %t868, i8 %t871)
  %t873 = getelementptr inbounds [16 x i8], [16 x i8]* %t872, i64 0, i64 0
  %t874 = bitcast i8* %t873 to i32*
  store i32 %t849, i32* %t874
  %t875 = getelementptr inbounds i8, i8* %t873, i64 4
  %t876 = bitcast i8* %t875 to i32*
  store i32 %t850, i32* %t876
  %t877 = getelementptr inbounds i8, i8* %t873, i64 8
  %t878 = bitcast i8* %t877 to i32*
  store i32 60, i32* %t878
  %t879 = getelementptr inbounds i8, i8* %t873, i64 12
  %t880 = bitcast i8* %t879 to i32*
  store i32 40, i32* %t880
  call i32 @SDL_RenderFillRect(i8* %t847, i8* %t873)
  %t881 = load i8*, i8** %t2
  %t882 = icmp eq i8* %t881, null
  br i1 %t882, label %sdl_null_window_1508, label %sdl_window_handle_ok_1509
sdl_null_window_1508:
  %t883 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.72, i64 0, i64 0
  call i32 @puts(i8* %t883)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1509:
  %t884 = call i8* @SDL_GetRenderer(i8* %t881)
  %t885 = load i32, i32* %t741
  %t886 = sub i32 %t885, 8
  %t887 = load i32, i32* %t835
  %t888 = add i32 %t887, 8
  %t889 = and i32 200, 255
  %t890 = and i32 180, 255
  %t891 = shl i32 %t890, 8
  %t892 = or i32 %t889, %t891
  %t893 = and i32 120, 255
  %t894 = shl i32 %t893, 16
  %t895 = or i32 %t892, %t894
  %t896 = and i32 255, 255
  %t897 = shl i32 %t896, 24
  %t898 = or i32 %t895, %t897
  %t899 = and i32 %t898, 255
  %t900 = trunc i32 %t899 to i8
  %t901 = lshr i32 %t898, 8
  %t902 = and i32 %t901, 255
  %t903 = trunc i32 %t902 to i8
  %t904 = lshr i32 %t898, 16
  %t905 = and i32 %t904, 255
  %t906 = trunc i32 %t905 to i8
  %t907 = lshr i32 %t898, 24
  %t908 = and i32 %t907, 255
  %t909 = trunc i32 %t908 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t884, i8 %t900, i8 %t903, i8 %t906, i8 %t909)
  %t911 = getelementptr inbounds [16 x i8], [16 x i8]* %t910, i64 0, i64 0
  %t912 = bitcast i8* %t911 to i32*
  store i32 %t886, i32* %t912
  %t913 = getelementptr inbounds i8, i8* %t911, i64 4
  %t914 = bitcast i8* %t913 to i32*
  store i32 %t888, i32* %t914
  %t915 = getelementptr inbounds i8, i8* %t911, i64 8
  %t916 = bitcast i8* %t915 to i32*
  store i32 16, i32* %t916
  %t917 = getelementptr inbounds i8, i8* %t911, i64 12
  %t918 = bitcast i8* %t917 to i32*
  store i32 24, i32* %t918
  call i32 @SDL_RenderFillRect(i8* %t884, i8* %t911)
  %t919 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 0
  %t920 = getelementptr inbounds %Player, %Player* %t919, i32 0, i32 6
  %t921 = load i1, i1* %t920
  %t922 = xor i1 true, %t921
  br i1 %t922, label %if_then_1510, label %if_else_1511
if_then_1510:
  %t924 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.73, i64 0, i32 2, i64 0
  store i8* %t924, i8** %t923
  %t926 = load i8*, i8** %t17
  %t927 = icmp eq i8* %t926, null
  br i1 %t927, label %font_null_handle_1513, label %font_handle_ok_1514
font_null_handle_1513:
  %t928 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.74, i64 0, i64 0
  call i32 @puts(i8* %t928)
  call void @exit(i32 1)
  unreachable
font_handle_ok_1514:
  %t929 = load i8*, i8** %t923
  %t930 = load i8*, i8** %t923
  call void @star_rc_retain(i8* %t930)
  %t931 = icmp sgt i32 3, 0
  %t932 = select i1 %t931, i32 3, i32 1
  %t933 = load i8, i8* %t926
  %t934 = zext i8 %t933 to i32
  %t935 = getelementptr inbounds i8, i8* %t926, i64 1
  %t936 = load i8, i8* %t935
  %t937 = zext i8 %t936 to i32
  %t938 = getelementptr inbounds i8, i8* %t926, i64 2
  %t939 = load i8, i8* %t938
  %t940 = zext i8 %t939 to i32
  %t941 = getelementptr inbounds i8, i8* %t926, i64 3
  %t942 = load i8, i8* %t941
  %t943 = zext i8 %t942 to i32
  %t944 = add i32 %t934, 1
  %t945 = mul i32 %t944, %t932
  %t946 = add i32 %t937, 1
  %t947 = mul i32 %t946, %t932
  store i32 0, i32* %t948
  store i32 0, i32* %t949
  store i32 1, i32* %t950
  store i64 0, i64* %t951
  br label %measure_text_cond_1515
measure_text_cond_1515:
  %t952 = load i64, i64* %t951
  %t953 = getelementptr inbounds i8, i8* %t929, i64 %t952
  %t954 = load i8, i8* %t953
  %t955 = icmp eq i8 %t954, 0
  br i1 %t955, label %measure_text_end_1519, label %measure_text_body_1516
measure_text_body_1516:
  %t956 = zext i8 %t954 to i32
  %t957 = icmp eq i32 %t956, 10
  br i1 %t957, label %measure_text_newline_1517, label %measure_text_advance_1518
measure_text_newline_1517:
  %t958 = load i32, i32* %t948
  %t959 = load i32, i32* %t949
  %t960 = icmp sgt i32 %t958, %t959
  %t961 = select i1 %t960, i32 %t958, i32 %t959
  store i32 %t961, i32* %t949
  store i32 0, i32* %t948
  %t962 = load i32, i32* %t950
  %t963 = add i32 %t962, 1
  store i32 %t963, i32* %t950
  %t964 = add i64 %t952, 1
  store i64 %t964, i64* %t951
  br label %measure_text_cond_1515
measure_text_advance_1518:
  %t965 = load i32, i32* %t948
  %t966 = add i32 %t965, %t945
  store i32 %t966, i32* %t948
  %t967 = add i64 %t952, 1
  store i64 %t967, i64* %t951
  br label %measure_text_cond_1515
measure_text_end_1519:
  call void @star_rc_release(i8* %t929)
  %t968 = load i32, i32* %t948
  %t969 = load i32, i32* %t949
  %t970 = icmp sgt i32 %t968, %t969
  %t971 = select i1 %t970, i32 %t968, i32 %t969
  %t972 = load i32, i32* %t950
  %t973 = mul i32 %t972, %t947
  %t974 = sub i32 %t973, %t932
  %t976 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t975, i32 0, i32 0
  store i32 %t971, i32* %t976
  %t977 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t975, i32 0, i32 1
  store i32 %t974, i32* %t977
  %t978 = load { i32, i32 }, { i32, i32 }* %t975
  store { i32, i32 } %t978, { i32, i32 }* %t925
  %t979 = load i8*, i8** %t2
  %t980 = icmp eq i8* %t979, null
  br i1 %t980, label %sdl_null_window_1520, label %sdl_window_handle_ok_1521
sdl_null_window_1520:
  %t981 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.75, i64 0, i64 0
  call i32 @puts(i8* %t981)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1521:
  %t982 = load i8*, i8** %t17
  %t983 = icmp eq i8* %t982, null
  br i1 %t983, label %font_null_handle_1522, label %font_handle_ok_1523
font_null_handle_1522:
  %t984 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.76, i64 0, i64 0
  call i32 @puts(i8* %t984)
  call void @exit(i32 1)
  unreachable
font_handle_ok_1523:
  %t985 = call i8* @SDL_GetRenderer(i8* %t979)
  %t986 = and i32 240, 255
  %t987 = and i32 40, 255
  %t988 = shl i32 %t987, 8
  %t989 = or i32 %t986, %t988
  %t990 = and i32 40, 255
  %t991 = shl i32 %t990, 16
  %t992 = or i32 %t989, %t991
  %t993 = and i32 255, 255
  %t994 = shl i32 %t993, 24
  %t995 = or i32 %t992, %t994
  %t996 = and i32 %t995, 255
  %t997 = trunc i32 %t996 to i8
  %t998 = lshr i32 %t995, 8
  %t999 = and i32 %t998, 255
  %t1000 = trunc i32 %t999 to i8
  %t1001 = lshr i32 %t995, 16
  %t1002 = and i32 %t1001, 255
  %t1003 = trunc i32 %t1002 to i8
  %t1004 = lshr i32 %t995, 24
  %t1005 = and i32 %t1004, 255
  %t1006 = trunc i32 %t1005 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t985, i8 %t997, i8 %t1000, i8 %t1003, i8 %t1006)
  %t1007 = load i8*, i8** %t923
  %t1008 = load i8*, i8** %t923
  call void @star_rc_retain(i8* %t1008)
  %t1009 = mul i32 320, 2
  %t1010 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t925, i32 0, i32 0
  %t1011 = load i32, i32* %t1010
  %t1012 = sub i32 %t1009, %t1011
  %t1013 = icmp eq i32 2, 0
  %t1014 = icmp eq i32 %t1012, -2147483648
  %t1015 = icmp eq i32 2, -1
  %t1016 = and i1 %t1014, %t1015
  %t1017 = or i1 %t1013, %t1016
  br i1 %t1017, label %int_div_fail_1524, label %int_div_ok_1525
int_div_fail_1524:
  %t1018 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.77, i64 0, i64 0
  call i32 @puts(i8* %t1018)
  call void @exit(i32 1)
  unreachable
int_div_ok_1525:
  %t1019 = sdiv i32 %t1012, 2
  %t1020 = mul i32 200, 2
  %t1021 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t925, i32 0, i32 1
  %t1022 = load i32, i32* %t1021
  %t1023 = sub i32 %t1020, %t1022
  %t1024 = icmp eq i32 2, 0
  %t1025 = icmp eq i32 %t1023, -2147483648
  %t1026 = icmp eq i32 2, -1
  %t1027 = and i1 %t1025, %t1026
  %t1028 = or i1 %t1024, %t1027
  br i1 %t1028, label %int_div_fail_1526, label %int_div_ok_1527
int_div_fail_1526:
  %t1029 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.78, i64 0, i64 0
  call i32 @puts(i8* %t1029)
  call void @exit(i32 1)
  unreachable
int_div_ok_1527:
  %t1030 = sdiv i32 %t1023, 2
  %t1031 = icmp sgt i32 3, 0
  %t1032 = select i1 %t1031, i32 3, i32 1
  %t1033 = load i8, i8* %t982
  %t1034 = zext i8 %t1033 to i32
  %t1035 = getelementptr inbounds i8, i8* %t982, i64 1
  %t1036 = load i8, i8* %t1035
  %t1037 = zext i8 %t1036 to i32
  %t1038 = getelementptr inbounds i8, i8* %t982, i64 2
  %t1039 = load i8, i8* %t1038
  %t1040 = zext i8 %t1039 to i32
  %t1041 = getelementptr inbounds i8, i8* %t982, i64 3
  %t1042 = load i8, i8* %t1041
  %t1043 = zext i8 %t1042 to i32
  %t1044 = add i32 %t1034, 1
  %t1045 = mul i32 %t1044, %t1032
  %t1046 = add i32 %t1037, 1
  %t1047 = mul i32 %t1046, %t1032
  store i32 %t1019, i32* %t1048
  store i32 %t1030, i32* %t1049
  store i64 0, i64* %t1050
  br label %draw_text_cond_1528
draw_text_cond_1528:
  %t1051 = load i64, i64* %t1050
  %t1052 = getelementptr inbounds i8, i8* %t1007, i64 %t1051
  %t1053 = load i8, i8* %t1052
  %t1054 = icmp eq i8 %t1053, 0
  br i1 %t1054, label %draw_text_end_1534, label %draw_text_body_1529
draw_text_body_1529:
  %t1055 = zext i8 %t1053 to i32
  %t1056 = icmp eq i32 %t1055, 10
  br i1 %t1056, label %draw_text_newline_1530, label %draw_text_glyph_1531
draw_text_newline_1530:
  store i32 %t1019, i32* %t1048
  %t1057 = load i32, i32* %t1049
  %t1058 = add i32 %t1057, %t1047
  store i32 %t1058, i32* %t1049
  %t1059 = add i64 %t1051, 1
  store i64 %t1059, i64* %t1050
  br label %draw_text_cond_1528
draw_text_glyph_1531:
  %t1060 = icmp sge i32 %t1055, 97
  %t1061 = icmp sle i32 %t1055, 122
  %t1062 = and i1 %t1060, %t1061
  %t1063 = sub i32 %t1055, 32
  %t1064 = select i1 %t1062, i32 %t1063, i32 %t1055
  %t1065 = sub i32 %t1064, %t1040
  %t1066 = icmp sge i32 %t1065, 0
  %t1067 = icmp slt i32 %t1065, %t1043
  %t1068 = and i1 %t1066, %t1067
  br i1 %t1068, label %draw_text_draw_glyph_1532, label %draw_text_advance_1533
draw_text_draw_glyph_1532:
  %t1069 = mul i32 %t1065, %t1037
  %t1070 = add i32 %t1069, 4
  %t1071 = sext i32 %t1070 to i64
  %t1072 = load i32, i32* %t1048
  %t1073 = load i32, i32* %t1049
  store i32 0, i32* %t1074
  br label %draw_text_row_cond_1535
draw_text_row_cond_1535:
  %t1075 = load i32, i32* %t1074
  %t1076 = icmp slt i32 %t1075, %t1037
  br i1 %t1076, label %draw_text_row_body_1536, label %draw_text_row_end_1537
draw_text_row_body_1536:
  %t1077 = sext i32 %t1075 to i64
  %t1078 = add i64 %t1071, %t1077
  %t1079 = getelementptr inbounds i8, i8* %t982, i64 %t1078
  %t1080 = load i8, i8* %t1079
  %t1081 = zext i8 %t1080 to i32
  store i32 0, i32* %t1082
  br label %draw_text_col_cond_1538
draw_text_col_cond_1538:
  %t1083 = load i32, i32* %t1082
  %t1084 = icmp slt i32 %t1083, %t1034
  br i1 %t1084, label %draw_text_col_body_1539, label %draw_text_col_end_1540
draw_text_col_body_1539:
  %t1085 = sub i32 %t1034, 1
  %t1086 = sub i32 %t1085, %t1083
  %t1087 = and i32 %t1086, 31
  %t1088 = lshr i32 %t1081, %t1087
  %t1089 = and i32 %t1088, 1
  %t1090 = icmp ne i32 %t1089, 0
  br i1 %t1090, label %draw_text_pixel_1541, label %draw_text_after_pixel_1542
draw_text_pixel_1541:
  %t1091 = mul i32 %t1083, %t1032
  %t1092 = add i32 %t1072, %t1091
  %t1093 = mul i32 %t1075, %t1032
  %t1094 = add i32 %t1073, %t1093
  %t1096 = getelementptr inbounds [16 x i8], [16 x i8]* %t1095, i64 0, i64 0
  %t1097 = bitcast i8* %t1096 to i32*
  store i32 %t1092, i32* %t1097
  %t1098 = getelementptr inbounds i8, i8* %t1096, i64 4
  %t1099 = bitcast i8* %t1098 to i32*
  store i32 %t1094, i32* %t1099
  %t1100 = getelementptr inbounds i8, i8* %t1096, i64 8
  %t1101 = bitcast i8* %t1100 to i32*
  store i32 %t1032, i32* %t1101
  %t1102 = getelementptr inbounds i8, i8* %t1096, i64 12
  %t1103 = bitcast i8* %t1102 to i32*
  store i32 %t1032, i32* %t1103
  call i32 @SDL_RenderFillRect(i8* %t985, i8* %t1096)
  br label %draw_text_after_pixel_1542
draw_text_after_pixel_1542:
  %t1104 = add i32 %t1083, 1
  store i32 %t1104, i32* %t1082
  br label %draw_text_col_cond_1538
draw_text_col_end_1540:
  %t1105 = add i32 %t1075, 1
  store i32 %t1105, i32* %t1074
  br label %draw_text_row_cond_1535
draw_text_row_end_1537:
  br label %draw_text_advance_1533
draw_text_advance_1533:
  %t1106 = load i32, i32* %t1048
  %t1107 = add i32 %t1106, %t1045
  store i32 %t1107, i32* %t1048
  %t1108 = add i64 %t1051, 1
  store i64 %t1108, i64* %t1050
  br label %draw_text_cond_1528
draw_text_end_1534:
  call void @star_rc_release(i8* %t1007)
  %t1110 = getelementptr inbounds { i64, i8*, [19 x i8] }, { i64, i8*, [19 x i8] }* @.str.79, i64 0, i32 2, i64 0
  store i8* %t1110, i8** %t1109
  %t1112 = load i8*, i8** %t17
  %t1113 = icmp eq i8* %t1112, null
  br i1 %t1113, label %font_null_handle_1543, label %font_handle_ok_1544
font_null_handle_1543:
  %t1114 = getelementptr inbounds [76 x i8], [76 x i8]* @.str.80, i64 0, i64 0
  call i32 @puts(i8* %t1114)
  call void @exit(i32 1)
  unreachable
font_handle_ok_1544:
  %t1115 = load i8*, i8** %t1109
  %t1116 = load i8*, i8** %t1109
  call void @star_rc_retain(i8* %t1116)
  %t1117 = icmp sgt i32 2, 0
  %t1118 = select i1 %t1117, i32 2, i32 1
  %t1119 = load i8, i8* %t1112
  %t1120 = zext i8 %t1119 to i32
  %t1121 = getelementptr inbounds i8, i8* %t1112, i64 1
  %t1122 = load i8, i8* %t1121
  %t1123 = zext i8 %t1122 to i32
  %t1124 = getelementptr inbounds i8, i8* %t1112, i64 2
  %t1125 = load i8, i8* %t1124
  %t1126 = zext i8 %t1125 to i32
  %t1127 = getelementptr inbounds i8, i8* %t1112, i64 3
  %t1128 = load i8, i8* %t1127
  %t1129 = zext i8 %t1128 to i32
  %t1130 = add i32 %t1120, 1
  %t1131 = mul i32 %t1130, %t1118
  %t1132 = add i32 %t1123, 1
  %t1133 = mul i32 %t1132, %t1118
  store i32 0, i32* %t1134
  store i32 0, i32* %t1135
  store i32 1, i32* %t1136
  store i64 0, i64* %t1137
  br label %measure_text_cond_1545
measure_text_cond_1545:
  %t1138 = load i64, i64* %t1137
  %t1139 = getelementptr inbounds i8, i8* %t1115, i64 %t1138
  %t1140 = load i8, i8* %t1139
  %t1141 = icmp eq i8 %t1140, 0
  br i1 %t1141, label %measure_text_end_1549, label %measure_text_body_1546
measure_text_body_1546:
  %t1142 = zext i8 %t1140 to i32
  %t1143 = icmp eq i32 %t1142, 10
  br i1 %t1143, label %measure_text_newline_1547, label %measure_text_advance_1548
measure_text_newline_1547:
  %t1144 = load i32, i32* %t1134
  %t1145 = load i32, i32* %t1135
  %t1146 = icmp sgt i32 %t1144, %t1145
  %t1147 = select i1 %t1146, i32 %t1144, i32 %t1145
  store i32 %t1147, i32* %t1135
  store i32 0, i32* %t1134
  %t1148 = load i32, i32* %t1136
  %t1149 = add i32 %t1148, 1
  store i32 %t1149, i32* %t1136
  %t1150 = add i64 %t1138, 1
  store i64 %t1150, i64* %t1137
  br label %measure_text_cond_1545
measure_text_advance_1548:
  %t1151 = load i32, i32* %t1134
  %t1152 = add i32 %t1151, %t1131
  store i32 %t1152, i32* %t1134
  %t1153 = add i64 %t1138, 1
  store i64 %t1153, i64* %t1137
  br label %measure_text_cond_1545
measure_text_end_1549:
  call void @star_rc_release(i8* %t1115)
  %t1154 = load i32, i32* %t1134
  %t1155 = load i32, i32* %t1135
  %t1156 = icmp sgt i32 %t1154, %t1155
  %t1157 = select i1 %t1156, i32 %t1154, i32 %t1155
  %t1158 = load i32, i32* %t1136
  %t1159 = mul i32 %t1158, %t1133
  %t1160 = sub i32 %t1159, %t1118
  %t1162 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1161, i32 0, i32 0
  store i32 %t1157, i32* %t1162
  %t1163 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1161, i32 0, i32 1
  store i32 %t1160, i32* %t1163
  %t1164 = load { i32, i32 }, { i32, i32 }* %t1161
  store { i32, i32 } %t1164, { i32, i32 }* %t1111
  %t1165 = load i8*, i8** %t2
  %t1166 = icmp eq i8* %t1165, null
  br i1 %t1166, label %sdl_null_window_1550, label %sdl_window_handle_ok_1551
sdl_null_window_1550:
  %t1167 = getelementptr inbounds [75 x i8], [75 x i8]* @.str.81, i64 0, i64 0
  call i32 @puts(i8* %t1167)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1551:
  %t1168 = load i8*, i8** %t17
  %t1169 = icmp eq i8* %t1168, null
  br i1 %t1169, label %font_null_handle_1552, label %font_handle_ok_1553
font_null_handle_1552:
  %t1170 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.82, i64 0, i64 0
  call i32 @puts(i8* %t1170)
  call void @exit(i32 1)
  unreachable
font_handle_ok_1553:
  %t1171 = call i8* @SDL_GetRenderer(i8* %t1165)
  %t1172 = and i32 240, 255
  %t1173 = and i32 240, 255
  %t1174 = shl i32 %t1173, 8
  %t1175 = or i32 %t1172, %t1174
  %t1176 = and i32 240, 255
  %t1177 = shl i32 %t1176, 16
  %t1178 = or i32 %t1175, %t1177
  %t1179 = and i32 255, 255
  %t1180 = shl i32 %t1179, 24
  %t1181 = or i32 %t1178, %t1180
  %t1182 = and i32 %t1181, 255
  %t1183 = trunc i32 %t1182 to i8
  %t1184 = lshr i32 %t1181, 8
  %t1185 = and i32 %t1184, 255
  %t1186 = trunc i32 %t1185 to i8
  %t1187 = lshr i32 %t1181, 16
  %t1188 = and i32 %t1187, 255
  %t1189 = trunc i32 %t1188 to i8
  %t1190 = lshr i32 %t1181, 24
  %t1191 = and i32 %t1190, 255
  %t1192 = trunc i32 %t1191 to i8
  call i32 @SDL_SetRenderDrawColor(i8* %t1171, i8 %t1183, i8 %t1186, i8 %t1189, i8 %t1192)
  %t1193 = load i8*, i8** %t1109
  %t1194 = load i8*, i8** %t1109
  call void @star_rc_retain(i8* %t1194)
  %t1195 = mul i32 320, 2
  %t1196 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1111, i32 0, i32 0
  %t1197 = load i32, i32* %t1196
  %t1198 = sub i32 %t1195, %t1197
  %t1199 = icmp eq i32 2, 0
  %t1200 = icmp eq i32 %t1198, -2147483648
  %t1201 = icmp eq i32 2, -1
  %t1202 = and i1 %t1200, %t1201
  %t1203 = or i1 %t1199, %t1202
  br i1 %t1203, label %int_div_fail_1554, label %int_div_ok_1555
int_div_fail_1554:
  %t1204 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.83, i64 0, i64 0
  call i32 @puts(i8* %t1204)
  call void @exit(i32 1)
  unreachable
int_div_ok_1555:
  %t1205 = sdiv i32 %t1198, 2
  %t1206 = mul i32 200, 2
  %t1207 = getelementptr inbounds { i32, i32 }, { i32, i32 }* %t1111, i32 0, i32 1
  %t1208 = load i32, i32* %t1207
  %t1209 = sub i32 %t1206, %t1208
  %t1210 = icmp eq i32 2, 0
  %t1211 = icmp eq i32 %t1209, -2147483648
  %t1212 = icmp eq i32 2, -1
  %t1213 = and i1 %t1211, %t1212
  %t1214 = or i1 %t1210, %t1213
  br i1 %t1214, label %int_div_fail_1556, label %int_div_ok_1557
int_div_fail_1556:
  %t1215 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.84, i64 0, i64 0
  call i32 @puts(i8* %t1215)
  call void @exit(i32 1)
  unreachable
int_div_ok_1557:
  %t1216 = sdiv i32 %t1209, 2
  %t1217 = add i32 %t1216, 30
  %t1218 = icmp sgt i32 2, 0
  %t1219 = select i1 %t1218, i32 2, i32 1
  %t1220 = load i8, i8* %t1168
  %t1221 = zext i8 %t1220 to i32
  %t1222 = getelementptr inbounds i8, i8* %t1168, i64 1
  %t1223 = load i8, i8* %t1222
  %t1224 = zext i8 %t1223 to i32
  %t1225 = getelementptr inbounds i8, i8* %t1168, i64 2
  %t1226 = load i8, i8* %t1225
  %t1227 = zext i8 %t1226 to i32
  %t1228 = getelementptr inbounds i8, i8* %t1168, i64 3
  %t1229 = load i8, i8* %t1228
  %t1230 = zext i8 %t1229 to i32
  %t1231 = add i32 %t1221, 1
  %t1232 = mul i32 %t1231, %t1219
  %t1233 = add i32 %t1224, 1
  %t1234 = mul i32 %t1233, %t1219
  store i32 %t1205, i32* %t1235
  store i32 %t1217, i32* %t1236
  store i64 0, i64* %t1237
  br label %draw_text_cond_1558
draw_text_cond_1558:
  %t1238 = load i64, i64* %t1237
  %t1239 = getelementptr inbounds i8, i8* %t1193, i64 %t1238
  %t1240 = load i8, i8* %t1239
  %t1241 = icmp eq i8 %t1240, 0
  br i1 %t1241, label %draw_text_end_1564, label %draw_text_body_1559
draw_text_body_1559:
  %t1242 = zext i8 %t1240 to i32
  %t1243 = icmp eq i32 %t1242, 10
  br i1 %t1243, label %draw_text_newline_1560, label %draw_text_glyph_1561
draw_text_newline_1560:
  store i32 %t1205, i32* %t1235
  %t1244 = load i32, i32* %t1236
  %t1245 = add i32 %t1244, %t1234
  store i32 %t1245, i32* %t1236
  %t1246 = add i64 %t1238, 1
  store i64 %t1246, i64* %t1237
  br label %draw_text_cond_1558
draw_text_glyph_1561:
  %t1247 = icmp sge i32 %t1242, 97
  %t1248 = icmp sle i32 %t1242, 122
  %t1249 = and i1 %t1247, %t1248
  %t1250 = sub i32 %t1242, 32
  %t1251 = select i1 %t1249, i32 %t1250, i32 %t1242
  %t1252 = sub i32 %t1251, %t1227
  %t1253 = icmp sge i32 %t1252, 0
  %t1254 = icmp slt i32 %t1252, %t1230
  %t1255 = and i1 %t1253, %t1254
  br i1 %t1255, label %draw_text_draw_glyph_1562, label %draw_text_advance_1563
draw_text_draw_glyph_1562:
  %t1256 = mul i32 %t1252, %t1224
  %t1257 = add i32 %t1256, 4
  %t1258 = sext i32 %t1257 to i64
  %t1259 = load i32, i32* %t1235
  %t1260 = load i32, i32* %t1236
  store i32 0, i32* %t1261
  br label %draw_text_row_cond_1565
draw_text_row_cond_1565:
  %t1262 = load i32, i32* %t1261
  %t1263 = icmp slt i32 %t1262, %t1224
  br i1 %t1263, label %draw_text_row_body_1566, label %draw_text_row_end_1567
draw_text_row_body_1566:
  %t1264 = sext i32 %t1262 to i64
  %t1265 = add i64 %t1258, %t1264
  %t1266 = getelementptr inbounds i8, i8* %t1168, i64 %t1265
  %t1267 = load i8, i8* %t1266
  %t1268 = zext i8 %t1267 to i32
  store i32 0, i32* %t1269
  br label %draw_text_col_cond_1568
draw_text_col_cond_1568:
  %t1270 = load i32, i32* %t1269
  %t1271 = icmp slt i32 %t1270, %t1221
  br i1 %t1271, label %draw_text_col_body_1569, label %draw_text_col_end_1570
draw_text_col_body_1569:
  %t1272 = sub i32 %t1221, 1
  %t1273 = sub i32 %t1272, %t1270
  %t1274 = and i32 %t1273, 31
  %t1275 = lshr i32 %t1268, %t1274
  %t1276 = and i32 %t1275, 1
  %t1277 = icmp ne i32 %t1276, 0
  br i1 %t1277, label %draw_text_pixel_1571, label %draw_text_after_pixel_1572
draw_text_pixel_1571:
  %t1278 = mul i32 %t1270, %t1219
  %t1279 = add i32 %t1259, %t1278
  %t1280 = mul i32 %t1262, %t1219
  %t1281 = add i32 %t1260, %t1280
  %t1283 = getelementptr inbounds [16 x i8], [16 x i8]* %t1282, i64 0, i64 0
  %t1284 = bitcast i8* %t1283 to i32*
  store i32 %t1279, i32* %t1284
  %t1285 = getelementptr inbounds i8, i8* %t1283, i64 4
  %t1286 = bitcast i8* %t1285 to i32*
  store i32 %t1281, i32* %t1286
  %t1287 = getelementptr inbounds i8, i8* %t1283, i64 8
  %t1288 = bitcast i8* %t1287 to i32*
  store i32 %t1219, i32* %t1288
  %t1289 = getelementptr inbounds i8, i8* %t1283, i64 12
  %t1290 = bitcast i8* %t1289 to i32*
  store i32 %t1219, i32* %t1290
  call i32 @SDL_RenderFillRect(i8* %t1171, i8* %t1283)
  br label %draw_text_after_pixel_1572
draw_text_after_pixel_1572:
  %t1291 = add i32 %t1270, 1
  store i32 %t1291, i32* %t1269
  br label %draw_text_col_cond_1568
draw_text_col_end_1570:
  %t1292 = add i32 %t1262, 1
  store i32 %t1292, i32* %t1261
  br label %draw_text_row_cond_1565
draw_text_row_end_1567:
  br label %draw_text_advance_1563
draw_text_advance_1563:
  %t1293 = load i32, i32* %t1235
  %t1294 = add i32 %t1293, %t1232
  store i32 %t1294, i32* %t1235
  %t1295 = add i64 %t1238, 1
  store i64 %t1295, i64* %t1237
  br label %draw_text_cond_1558
draw_text_end_1564:
  call void @star_rc_release(i8* %t1193)
  %t1296 = icmp sge i32 21, 0
  %t1297 = icmp slt i32 21, 512
  %t1298 = and i1 %t1296, %t1297
  br i1 %t1298, label %key_down_read_1573, label %key_down_end_1574
key_down_read_1573:
  %t1299 = call i8* @SDL_GetKeyboardState(i32* null)
  %t1300 = sext i32 21 to i64
  %t1301 = getelementptr inbounds i8, i8* %t1299, i64 %t1300
  %t1302 = load i8, i8* %t1301
  %t1303 = icmp ne i8 %t1302, 0
  br label %key_down_end_1574
key_down_end_1574:
  %t1304 = phi i1 [ false, %draw_text_end_1564 ], [ %t1303, %key_down_read_1573 ]
  br i1 %t1304, label %if_then_1575, label %if_else_1576
if_then_1575:
  %t1305 = load %map__Level, %map__Level* %t19
  %t1306 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 0
  %t1307 = load i8*, i8** %t1306
  call void @star_rc_retain(i8* %t1307)
  %t1308 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 1
  %t1309 = load i8*, i8** %t1308
  call void @star_rc_retain(i8* %t1309)
  %t1310 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 2
  %t1311 = load i8*, i8** %t1310
  call void @star_rc_retain(i8* %t1311)
  %t1312 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 3
  %t1313 = load i8*, i8** %t1312
  call void @star_rc_retain(i8* %t1313)
  %t1314 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 4
  %t1315 = load i8*, i8** %t1314
  call void @star_rc_retain(i8* %t1315)
  %t1316 = call %Game @new_game(%map__Level %t1305)
  %t1317 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 1
  %t1318 = load i8*, i8** %t1317
  call void @star_rc_release(i8* %t1318)
  %t1319 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 2
  %t1320 = load i8*, i8** %t1319
  call void @star_rc_release(i8* %t1320)
  %t1321 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 3
  %t1322 = load i8*, i8** %t1321
  call void @star_rc_release(i8* %t1322)
  store %Game %t1316, %Game* %t132
  %t1325 = call i32 @SDL_GetMouseState(i32* %t1323, i32* %t1324)
  %t1326 = load i32, i32* %t1323
  %t1327 = load i32, i32* %t1324
  %t1328 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 6
  store i32 %t1326, i32* %t1328
  %t1329 = call i32 @SDL_GetTicks()
  %t1330 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 7
  store i32 %t1329, i32* %t1330
  br label %if_end_1577
if_else_1576:
  br label %if_end_1577
if_end_1577:
  %t1331 = load i8*, i8** %t1109
  call void @star_rc_release(i8* %t1331)
  %t1332 = load i8*, i8** %t923
  call void @star_rc_release(i8* %t1332)
  br label %if_end_1512
if_else_1511:
  br label %if_end_1512
if_end_1512:
  %t1333 = load i8*, i8** %t2
  %t1334 = icmp eq i8* %t1333, null
  br i1 %t1334, label %sdl_null_window_1578, label %sdl_window_handle_ok_1579
sdl_null_window_1578:
  %t1335 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.85, i64 0, i64 0
  call i32 @puts(i8* %t1335)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1579:
  %t1336 = call i8* @SDL_GetRenderer(i8* %t1333)
  call void @SDL_RenderPresent(i8* %t1336)
  %t1337 = icmp slt i32 16, 0
  %t1338 = select i1 %t1337, i32 0, i32 16
  call void @SDL_Delay(i32 %t1338)
  %t1339 = load i8*, i8** %t218
  call void @star_rc_release(i8* %t1339)
  %t1340 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t200, i32 0, i32 0
  %t1341 = load i8*, i8** %t1340
  call void @star_rc_release(i8* %t1341)
  %t1342 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %t200, i32 0, i32 1
  %t1343 = load i8*, i8** %t1342
  call void @star_rc_release(i8* %t1343)
  br label %while_cond_1391
while_else_1393:
  br label %while_end_1394
while_end_1394:
  %t1344 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 0
  store i64 0, i64* %t1345
  br label %ht_fill8_cond_1580
ht_fill8_cond_1580:
  %t1346 = load i64, i64* %t1345
  %t1347 = icmp slt i64 %t1346, 16
  br i1 %t1347, label %ht_fill8_body_1581, label %ht_fill8_end_1582
ht_fill8_body_1581:
  %t1348 = getelementptr inbounds i8, i8* %t1344, i64 %t1346
  store i8 0, i8* %t1348
  %t1349 = add i64 %t1346, 1
  store i64 %t1349, i64* %t1345
  br label %ht_fill8_cond_1580
ht_fill8_end_1582:
  %t1350 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t23, i32 0, i32 0
  %t1351 = load i8*, i8** %t1350
  %t1352 = icmp eq i8* %t1351, null
  br i1 %t1352, label %sound_null_handle_1583, label %sound_handle_ok_1584
sound_null_handle_1583:
  %t1353 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.86, i64 0, i64 0
  call i32 @puts(i8* %t1353)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_1584:
  %t1354 = bitcast i8* %t1351 to i64*
  %t1355 = load i64, i64* %t1354
  %t1356 = getelementptr inbounds i8, i8* %t1351, i64 8
  %t1357 = bitcast i8* %t1356 to i8**
  %t1358 = load i8*, i8** %t1357
  %t1359 = getelementptr inbounds i8, i8* %t1358, i64 44
  store i32 0, i32* %t1360
  br label %sound_free_scan_cond_1585
sound_free_scan_cond_1585:
  %t1361 = load i32, i32* %t1360
  %t1362 = icmp sge i32 %t1361, 16
  br i1 %t1362, label %sound_free_scan_end_1589, label %sound_free_scan_check_1586
sound_free_scan_check_1586:
  %t1363 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t1361
  %t1364 = load i8*, i8** %t1363
  %t1365 = icmp eq i8* %t1364, %t1359
  br i1 %t1365, label %sound_free_scan_match_1587, label %sound_free_scan_next_1588
sound_free_scan_match_1587:
  %t1366 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t1361
  store i8 0, i8* %t1366
  br label %sound_free_scan_next_1588
sound_free_scan_next_1588:
  %t1367 = add i32 %t1361, 1
  store i32 %t1367, i32* %t1360
  br label %sound_free_scan_cond_1585
sound_free_scan_end_1589:
  %t1368 = getelementptr inbounds i8, i8* %t1351, i64 8
  %t1369 = bitcast i8* %t1368 to i8**
  %t1370 = load i8*, i8** %t1369
  call void @free(i8* %t1370)
  call void @free(i8* %t1351)
  %t1371 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t23, i32 0, i32 1
  %t1372 = load i8*, i8** %t1371
  %t1373 = icmp eq i8* %t1372, null
  br i1 %t1373, label %sound_null_handle_1590, label %sound_handle_ok_1591
sound_null_handle_1590:
  %t1374 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.87, i64 0, i64 0
  call i32 @puts(i8* %t1374)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_1591:
  %t1375 = bitcast i8* %t1372 to i64*
  %t1376 = load i64, i64* %t1375
  %t1377 = getelementptr inbounds i8, i8* %t1372, i64 8
  %t1378 = bitcast i8* %t1377 to i8**
  %t1379 = load i8*, i8** %t1378
  %t1380 = getelementptr inbounds i8, i8* %t1379, i64 44
  store i32 0, i32* %t1381
  br label %sound_free_scan_cond_1592
sound_free_scan_cond_1592:
  %t1382 = load i32, i32* %t1381
  %t1383 = icmp sge i32 %t1382, 16
  br i1 %t1383, label %sound_free_scan_end_1596, label %sound_free_scan_check_1593
sound_free_scan_check_1593:
  %t1384 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t1382
  %t1385 = load i8*, i8** %t1384
  %t1386 = icmp eq i8* %t1385, %t1380
  br i1 %t1386, label %sound_free_scan_match_1594, label %sound_free_scan_next_1595
sound_free_scan_match_1594:
  %t1387 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t1382
  store i8 0, i8* %t1387
  br label %sound_free_scan_next_1595
sound_free_scan_next_1595:
  %t1388 = add i32 %t1382, 1
  store i32 %t1388, i32* %t1381
  br label %sound_free_scan_cond_1592
sound_free_scan_end_1596:
  %t1389 = getelementptr inbounds i8, i8* %t1372, i64 8
  %t1390 = bitcast i8* %t1389 to i8**
  %t1391 = load i8*, i8** %t1390
  call void @free(i8* %t1391)
  call void @free(i8* %t1372)
  %t1392 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t23, i32 0, i32 2
  %t1393 = load i8*, i8** %t1392
  %t1394 = icmp eq i8* %t1393, null
  br i1 %t1394, label %sound_null_handle_1597, label %sound_handle_ok_1598
sound_null_handle_1597:
  %t1395 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.88, i64 0, i64 0
  call i32 @puts(i8* %t1395)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_1598:
  %t1396 = bitcast i8* %t1393 to i64*
  %t1397 = load i64, i64* %t1396
  %t1398 = getelementptr inbounds i8, i8* %t1393, i64 8
  %t1399 = bitcast i8* %t1398 to i8**
  %t1400 = load i8*, i8** %t1399
  %t1401 = getelementptr inbounds i8, i8* %t1400, i64 44
  store i32 0, i32* %t1402
  br label %sound_free_scan_cond_1599
sound_free_scan_cond_1599:
  %t1403 = load i32, i32* %t1402
  %t1404 = icmp sge i32 %t1403, 16
  br i1 %t1404, label %sound_free_scan_end_1603, label %sound_free_scan_check_1600
sound_free_scan_check_1600:
  %t1405 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t1403
  %t1406 = load i8*, i8** %t1405
  %t1407 = icmp eq i8* %t1406, %t1401
  br i1 %t1407, label %sound_free_scan_match_1601, label %sound_free_scan_next_1602
sound_free_scan_match_1601:
  %t1408 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t1403
  store i8 0, i8* %t1408
  br label %sound_free_scan_next_1602
sound_free_scan_next_1602:
  %t1409 = add i32 %t1403, 1
  store i32 %t1409, i32* %t1402
  br label %sound_free_scan_cond_1599
sound_free_scan_end_1603:
  %t1410 = getelementptr inbounds i8, i8* %t1393, i64 8
  %t1411 = bitcast i8* %t1410 to i8**
  %t1412 = load i8*, i8** %t1411
  call void @free(i8* %t1412)
  call void @free(i8* %t1393)
  %t1413 = getelementptr inbounds %audio__Sounds, %audio__Sounds* %t23, i32 0, i32 3
  %t1414 = load i8*, i8** %t1413
  %t1415 = icmp eq i8* %t1414, null
  br i1 %t1415, label %sound_null_handle_1604, label %sound_handle_ok_1605
sound_null_handle_1604:
  %t1416 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.89, i64 0, i64 0
  call i32 @puts(i8* %t1416)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_1605:
  %t1417 = bitcast i8* %t1414 to i64*
  %t1418 = load i64, i64* %t1417
  %t1419 = getelementptr inbounds i8, i8* %t1414, i64 8
  %t1420 = bitcast i8* %t1419 to i8**
  %t1421 = load i8*, i8** %t1420
  %t1422 = getelementptr inbounds i8, i8* %t1421, i64 44
  store i32 0, i32* %t1423
  br label %sound_free_scan_cond_1606
sound_free_scan_cond_1606:
  %t1424 = load i32, i32* %t1423
  %t1425 = icmp sge i32 %t1424, 16
  br i1 %t1425, label %sound_free_scan_end_1610, label %sound_free_scan_check_1607
sound_free_scan_check_1607:
  %t1426 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t1424
  %t1427 = load i8*, i8** %t1426
  %t1428 = icmp eq i8* %t1427, %t1422
  br i1 %t1428, label %sound_free_scan_match_1608, label %sound_free_scan_next_1609
sound_free_scan_match_1608:
  %t1429 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t1424
  store i8 0, i8* %t1429
  br label %sound_free_scan_next_1609
sound_free_scan_next_1609:
  %t1430 = add i32 %t1424, 1
  store i32 %t1430, i32* %t1423
  br label %sound_free_scan_cond_1606
sound_free_scan_end_1610:
  %t1431 = getelementptr inbounds i8, i8* %t1414, i64 8
  %t1432 = bitcast i8* %t1431 to i8**
  %t1433 = load i8*, i8** %t1432
  call void @free(i8* %t1433)
  call void @free(i8* %t1414)
  %t1434 = load i8*, i8** %t2
  %t1435 = icmp eq i8* %t1434, null
  br i1 %t1435, label %sdl_null_window_1611, label %sdl_window_handle_ok_1612
sdl_null_window_1611:
  %t1436 = getelementptr inbounds [80 x i8], [80 x i8]* @.str.90, i64 0, i64 0
  call i32 @puts(i8* %t1436)
  call void @exit(i32 1)
  unreachable
sdl_window_handle_ok_1612:
  %t1437 = call i8* @SDL_GetRenderer(i8* %t1434)
  call void @SDL_DestroyRenderer(i8* %t1437)
  call void @SDL_DestroyWindow(i8* %t1434)
  store i8* null, i8** %t2
  %t1438 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 1
  %t1439 = load i8*, i8** %t1438
  call void @star_rc_release(i8* %t1439)
  %t1440 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 2
  %t1441 = load i8*, i8** %t1440
  call void @star_rc_release(i8* %t1441)
  %t1442 = getelementptr inbounds %Game, %Game* %t132, i32 0, i32 3
  %t1443 = load i8*, i8** %t1442
  call void @star_rc_release(i8* %t1443)
  %t1444 = load i8*, i8** %t65
  call void @star_rc_release(i8* %t1444)
  %t1445 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 0
  %t1446 = load i8*, i8** %t1445
  call void @star_rc_release(i8* %t1446)
  %t1447 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 1
  %t1448 = load i8*, i8** %t1447
  call void @star_rc_release(i8* %t1448)
  %t1449 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 2
  %t1450 = load i8*, i8** %t1449
  call void @star_rc_release(i8* %t1450)
  %t1451 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 3
  %t1452 = load i8*, i8** %t1451
  call void @star_rc_release(i8* %t1452)
  %t1453 = getelementptr inbounds %sprites__SpriteSet, %sprites__SpriteSet* %t21, i32 0, i32 4
  %t1454 = load i8*, i8** %t1453
  call void @star_rc_release(i8* %t1454)
  %t1455 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 0
  %t1456 = load i8*, i8** %t1455
  call void @star_rc_release(i8* %t1456)
  %t1457 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 1
  %t1458 = load i8*, i8** %t1457
  call void @star_rc_release(i8* %t1458)
  %t1459 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 2
  %t1460 = load i8*, i8** %t1459
  call void @star_rc_release(i8* %t1460)
  %t1461 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 3
  %t1462 = load i8*, i8** %t1461
  call void @star_rc_release(i8* %t1462)
  %t1463 = getelementptr inbounds %map__Level, %map__Level* %t19, i32 0, i32 4
  %t1464 = load i8*, i8** %t1463
  call void @star_rc_release(i8* %t1464)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t86 = alloca i64
  %t81 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t82 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t81, i32 0, i32 0
  %t83 = load i8**, i8*** %t82
  %t84 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t81, i32 0, i32 1
  %t85 = load i64, i64* %t84
  store i64 0, i64* %t86
  br label %list_release_cond_18
list_release_cond_18:
  %t87 = load i64, i64* %t86
  %t88 = icmp slt i64 %t87, %t85
  br i1 %t88, label %list_release_body_19, label %list_release_end_20
list_release_body_19:
  %t89 = getelementptr inbounds i8*, i8** %t83, i64 %t87
  %t90 = load i8*, i8** %t89
  call void @star_rc_release(i8* %t90)
  %t91 = add i64 %t87, 1
  store i64 %t91, i64* %t86
  br label %list_release_cond_18
list_release_end_20:
  %t92 = bitcast i8** %t83 to i8*
  call void @free(i8* %t92)
  ret void
}


define void @list_release_u8(i8* %objp) {
entry:
  %t135 = bitcast i8* %objp to { i8*, i64, i64 }*
  %t136 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t135, i32 0, i32 0
  %t137 = load i8*, i8** %t136
  %t138 = bitcast i8* %t137 to i8*
  call void @free(i8* %t138)
  ret void
}


define void @list_release_i32(i8* %objp) {
entry:
  %t176 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t177 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t176, i32 0, i32 0
  %t178 = load i32*, i32** %t177
  %t179 = bitcast i32* %t178 to i8*
  call void @free(i8* %t179)
  ret void
}


define void @list_release_s_Enemy(i8* %objp) {
entry:
  %t37 = bitcast i8* %objp to { %Enemy*, i64, i64 }*
  %t38 = getelementptr inbounds { %Enemy*, i64, i64 }, { %Enemy*, i64, i64 }* %t37, i32 0, i32 0
  %t39 = load %Enemy*, %Enemy** %t38
  %t40 = bitcast %Enemy* %t39 to i8*
  call void @free(i8* %t40)
  ret void
}


define void @list_release_s_Pickup(i8* %objp) {
entry:
  %t37 = bitcast i8* %objp to { %Pickup*, i64, i64 }*
  %t38 = getelementptr inbounds { %Pickup*, i64, i64 }, { %Pickup*, i64, i64 }* %t37, i32 0, i32 0
  %t39 = load %Pickup*, %Pickup** %t38
  %t40 = bitcast %Pickup* %t39 to i8*
  call void @free(i8* %t40)
  ret void
}


define void @list_release_f32(i8* %objp) {
entry:
  %t13 = bitcast i8* %objp to { float*, i64, i64 }*
  %t14 = getelementptr inbounds { float*, i64, i64 }, { float*, i64, i64 }* %t13, i32 0, i32 0
  %t15 = load float*, float** %t14
  %t16 = bitcast float* %t15 to i8*
  call void @free(i8* %t16)
  ret void
}


define void @list_release_s_SpriteDraw(i8* %objp) {
entry:
  %t69 = bitcast i8* %objp to { %SpriteDraw*, i64, i64 }*
  %t70 = getelementptr inbounds { %SpriteDraw*, i64, i64 }, { %SpriteDraw*, i64, i64 }* %t69, i32 0, i32 0
  %t71 = load %SpriteDraw*, %SpriteDraw** %t70
  %t72 = bitcast %SpriteDraw* %t71 to i8*
  call void @free(i8* %t72)
  ret void
}


define void @list_release_s_Projectile(i8* %objp) {
entry:
  %t290 = bitcast i8* %objp to { %Projectile*, i64, i64 }*
  %t291 = getelementptr inbounds { %Projectile*, i64, i64 }, { %Projectile*, i64, i64 }* %t290, i32 0, i32 0
  %t292 = load %Projectile*, %Projectile** %t291
  %t293 = bitcast %Projectile* %t292 to i8*
  call void @free(i8* %t293)
  ret void
}


@star.audio.device = global i32 0
@star.audio.chan_base = global [16 x i8*] zeroinitializer
@star.audio.chan_len = global [16 x i64] zeroinitializer
@star.audio.chan_pos = global [16 x i64] zeroinitializer
@star.audio.chan_playing = global [16 x i8] zeroinitializer
@star.audio.chan_loop = global [16 x i8] zeroinitializer

define void @star.audio.mix_callback(i8* %userdata, i8* %stream, i32 %len) {
entry:
  %t372 = alloca i32
  %t374 = alloca i64
  store i32 0, i32* %t372
  %t373 = sext i32 %len to i64
  store i64 0, i64* %t374
  br label %ht_fill8_cond_1134
ht_fill8_cond_1134:
  %t375 = load i64, i64* %t374
  %t376 = icmp slt i64 %t375, %t373
  br i1 %t376, label %ht_fill8_body_1135, label %ht_fill8_end_1136
ht_fill8_body_1135:
  %t377 = getelementptr inbounds i8, i8* %stream, i64 %t375
  store i8 0, i8* %t377
  %t378 = add i64 %t375, 1
  store i64 %t378, i64* %t374
  br label %ht_fill8_cond_1134
ht_fill8_end_1136:
  br label %chan_cond
chan_cond:
  %t379 = load i32, i32* %t372
  %t380 = icmp sge i32 %t379, 16
  br i1 %t380, label %exit, label %chan_body
chan_body:
  %t381 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t379
  %t382 = load i8, i8* %t381
  %t383 = icmp ne i8 %t382, 0
  br i1 %t383, label %chan_mix, label %chan_latch
chan_mix:
  %t384 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_pos, i32 0, i32 %t379
  %t385 = load i64, i64* %t384
  %t386 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_len, i32 0, i32 %t379
  %t387 = load i64, i64* %t386
  %t388 = sub i64 %t387, %t385
  %t389 = icmp sle i64 %t388, 0
  br i1 %t389, label %chan_checkloop, label %chan_have
chan_checkloop:
  %t390 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 %t379
  %t391 = load i8, i8* %t390
  %t392 = icmp ne i8 %t391, 0
  br i1 %t392, label %chan_have, label %chan_stop
chan_stop:
  store i8 0, i8* %t381
  br label %chan_latch
chan_have:
  %t393 = phi i64 [ %t385, %chan_mix ], [ 0, %chan_checkloop ]
  %t394 = phi i64 [ %t388, %chan_mix ], [ %t387, %chan_checkloop ]
  %t395 = icmp slt i64 %t394, %t373
  %t396 = select i1 %t395, i64 %t394, i64 %t373
  %t397 = trunc i64 %t396 to i32
  %t398 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t379
  %t399 = load i8*, i8** %t398
  %t400 = getelementptr inbounds i8, i8* %t399, i64 %t393
  call void @SDL_MixAudioFormat(i8* %stream, i8* %t400, i16 32784, i32 %t397, i32 128)
  %t401 = add i64 %t393, %t396
  store i64 %t401, i64* %t384
  %t402 = icmp sge i64 %t401, %t387
  br i1 %t402, label %chan_checkdone, label %chan_latch
chan_checkdone:
  %t403 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 %t379
  %t404 = load i8, i8* %t403
  %t405 = icmp ne i8 %t404, 0
  br i1 %t405, label %chan_wrap, label %chan_finish
chan_wrap:
  store i64 0, i64* %t384
  br label %chan_latch
chan_finish:
  store i8 0, i8* %t381
  br label %chan_latch
chan_latch:
  %t406 = add i32 %t379, 1
  store i32 %t406, i32* %t372
  br label %chan_cond
exit:
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [258 x i8] } { i64 -1, i8* null, [258 x i8] c"BBBBBBBBBBBBBBBB\0AB..............B\0AB....m......h.B\0AB.P..........B\0AB......G..E..B\0AB..E...G......B\0AB......GGGG..B\0AB..............B\0AB..B..B..B..B.B\0AB..B..B..B..B.B\0AB..............B\0AB..h....m.....B\0AB......BBBB...B\0AB..E.....B..X.B\0AB..........h..B\0ABBBBBBBBBBBBBBBB\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\0A\00" }
@.str.2 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.3 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\0A\00" }
@.str.5 = private unnamed_addr constant { i64, i8*, [272 x i8] } { i64 -1, i8* null, [272 x i8] c"................\0A................\0A......RRRR......\0A.....RRRRRR.....\0A....RRRRRRRR....\0A....rRRRRRRr....\0A....rRRRRRRr....\0A.....rRRRRr.....\0A......rRRr......\0A......rYYr......\0A......rYYr......\0A.......rr.......\0A......r..r......\0A.....r....r.....\0A................\0A................\00" }
@.str.6 = private unnamed_addr constant { i64, i8*, [272 x i8] } { i64 -1, i8* null, [272 x i8] c"................\0A................\0A......BBBB......\0A.....BBBBBB.....\0A....BBBBBBBB....\0A....bBBBBBBb....\0A....bBBBBBBb....\0A.....bBBBBb.....\0A......bBBb......\0A......bWWb......\0A......bWWb......\0A.......bb.......\0A......b..b......\0A.....b....b.....\0A................\0A................\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [272 x i8] } { i64 -1, i8* null, [272 x i8] c"................\0A................\0A................\0A................\0A......GGGG......\0A.....GGGGGG.....\0A....GGGGGGGG....\0A....gGGGGGGg....\0A....gGGGGGGg....\0A.....gGGGGg.....\0A......gGGg......\0A.......gg.......\0A................\0A................\0A................\0A................\00" }
@.str.8 = private unnamed_addr constant { i64, i8*, [272 x i8] } { i64 -1, i8* null, [272 x i8] c"................\0A................\0A................\0A................\0A......CCCC......\0A.....CCCCCC.....\0A....CCCCCCCC....\0A....cCCCCCCc....\0A....cCCCCCCc....\0A.....cCCCCc.....\0A......cCCc......\0A.......cc.......\0A................\0A................\0A................\0A................\00" }
@.str.9 = private unnamed_addr constant { i64, i8*, [272 x i8] } { i64 -1, i8* null, [272 x i8] c"................\0A................\0A................\0A................\0A................\0A................\0A......OOOO......\0A.....OYYYYO.....\0A.....OYYYYO.....\0A......OOOO......\0A................\0A................\0A................\0A................\0A................\0A................\00" }
@.str.10 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"w\00" }
@.str.11 = private unnamed_addr constant [80 x i8] c"star runtime error: file_write_bytes(..) called with a null/closed file handle\0A\00"
@.str.12 = private unnamed_addr constant [80 x i8] c"star runtime error: file_write_bytes(..) called with a null/closed file handle\0A\00"
@.str.13 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.14 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.15 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.16 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.17 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.18 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"heresy_zap.wav\00" }
@.str.19 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"heresy_growl.wav\00" }
@.str.20 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"heresy_pickup.wav\00" }
@.str.21 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"heresy_drone.wav\00" }
@.str.22 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"heresy_zap.wav\00" }
@.str.23 = private unnamed_addr constant [3 x i8] c"rb\00"
@.str.24 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"heresy_growl.wav\00" }
@.str.25 = private unnamed_addr constant [3 x i8] c"rb\00"
@.str.26 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"heresy_pickup.wav\00" }
@.str.27 = private unnamed_addr constant [3 x i8] c"rb\00"
@.str.28 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"heresy_drone.wav\00" }
@.str.29 = private unnamed_addr constant [3 x i8] c"rb\00"
@.str.30 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.31 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.32 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.33 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.34 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.35 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.36 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.37 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.38 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.39 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.40 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.41 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.42 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.43 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.44 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.45 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.46 = private unnamed_addr constant [74 x i8] c"star runtime error: sound_play(..) called with a null/freed sound handle\0A\00"
@.str.47 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"Heresy\00" }
@.str.48 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"window_create failed\00" }
@.str.49 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.50 = private unnamed_addr constant [417 x i8] c"\05\07\20\3B\00\00\00\00\00\00\00\04\04\04\04\04\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\04\04\00\00\00\00\00\02\04\08\08\08\04\02\08\04\02\02\02\04\08\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\04\08\00\00\00\1F\00\00\00\00\00\00\00\00\04\04\01\02\04\04\08\10\10\0E\11\13\15\19\11\0E\04\0C\04\04\04\04\0E\0E\11\01\02\04\08\1F\0E\11\01\06\01\11\0E\02\06\0A\12\1F\02\02\1F\10\1E\01\01\11\0E\06\08\10\1E\11\11\0E\1F\01\02\04\08\08\08\0E\11\11\0E\11\11\0E\0E\11\11\0F\01\02\0C\00\04\00\00\04\00\00\00\04\00\00\04\08\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0E\11\01\02\04\00\04\00\00\00\00\00\00\00\04\0A\11\11\1F\11\11\1E\11\11\1E\11\11\1E\0E\11\10\10\10\11\0E\1C\12\11\11\11\12\1C\1F\10\10\1E\10\10\1F\1F\10\10\1E\10\10\10\0E\11\10\17\11\11\0E\11\11\11\1F\11\11\11\0E\04\04\04\04\04\0E\07\02\02\02\02\12\0C\11\12\14\18\14\12\11\10\10\10\10\10\10\1F\11\1B\15\11\11\11\11\11\19\15\13\11\11\11\0E\11\11\11\11\11\0E\1E\11\11\1E\10\10\10\0E\11\11\11\15\12\0D\1E\11\11\1E\14\12\11\0F\10\10\0E\01\01\1E\1F\04\04\04\04\04\04\11\11\11\11\11\11\0E\11\11\11\11\11\0A\04\11\11\11\15\15\1B\11\11\11\0A\04\0A\11\11\11\11\0A\04\04\04\04\1F\01\02\04\08\10\1F"
@.str.51 = private unnamed_addr constant [74 x i8] c"star runtime error: music_play(..) called with a null/freed sound handle\0A\00"
@.str.52 = private unnamed_addr constant [85 x i8] c"star runtime error: window_should_close(..) called with a null/closed window handle\0A\00"
@.str.53 = private unnamed_addr constant [77 x i8] c"star runtime error: draw_pixels(..) called with a null/closed window handle\0A\00"
@.str.54 = private unnamed_addr constant [105 x i8] c"star runtime error: draw_pixels(..) called with a `pixels` buffer smaller than width * height * 4 bytes\0A\00"
@.str.55 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.56 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.57 = private unnamed_addr constant [6 x i8] c"HP %d\00"
@.str.58 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.59 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.60 = private unnamed_addr constant [6 x i8] c"MP %d\00"
@.str.61 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.62 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.63 = private unnamed_addr constant [9 x i8] c"SCORE %d\00"
@.str.64 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.65 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.66 = private unnamed_addr constant { i64, i8*, [33 x i8] } { i64 -1, i8* null, [33 x i8] c"WASD MOVE  MOUSE AIM  CLICK FIRE\00" }
@.str.67 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.68 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.69 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.70 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.71 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.72 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_rect(..) called with a null/closed window handle\0A\00"
@.str.73 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"YOU DIED\00" }
@.str.74 = private unnamed_addr constant [76 x i8] c"star runtime error: measure_text(..) called with a null/closed font handle\0A\00"
@.str.75 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.76 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.77 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.78 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.79 = private unnamed_addr constant { i64, i8*, [19 x i8] } { i64 -1, i8* null, [19 x i8] c"PRESS R TO RESTART\00" }
@.str.80 = private unnamed_addr constant [76 x i8] c"star runtime error: measure_text(..) called with a null/closed font handle\0A\00"
@.str.81 = private unnamed_addr constant [75 x i8] c"star runtime error: draw_text(..) called with a null/closed window handle\0A\00"
@.str.82 = private unnamed_addr constant [73 x i8] c"star runtime error: draw_text(..) called with a null/closed font handle\0A\00"
@.str.83 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.84 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `/` by zero (or `i32::MIN / -1` overflow)\0A\00"
@.str.85 = private unnamed_addr constant [73 x i8] c"star runtime error: present(..) called with a null/closed window handle\0A\00"
@.str.86 = private unnamed_addr constant [74 x i8] c"star runtime error: sound_free(..) called with a null/freed sound handle\0A\00"
@.str.87 = private unnamed_addr constant [74 x i8] c"star runtime error: sound_free(..) called with a null/freed sound handle\0A\00"
@.str.88 = private unnamed_addr constant [74 x i8] c"star runtime error: sound_free(..) called with a null/freed sound handle\0A\00"
@.str.89 = private unnamed_addr constant [74 x i8] c"star runtime error: sound_free(..) called with a null/freed sound handle\0A\00"
@.str.90 = private unnamed_addr constant [80 x i8] c"star runtime error: window_destroy(..) called with a null/closed window handle\0A\00"
