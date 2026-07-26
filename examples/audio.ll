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

%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t108 = alloca [32 x i8]
  %t110 = alloca i64
  %t132 = alloca i32
  %t133 = alloca i32
  %t157 = alloca [32 x i8]
  %t159 = alloca i64
  %t196 = alloca [32 x i8]
  %t198 = alloca i64
  %t220 = alloca i32
  %t221 = alloca i32
  %t239 = alloca i64
  %t253 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [25 x i8] }, { i64, i8*, [25 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t4 = getelementptr inbounds [3 x i8], [3 x i8]* @.str.1, i64 0, i64 0
  %t5 = call i8* @fopen(i8* %t3, i8* %t4)
  call void @star_rc_release(i8* %t3)
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %sound_load_open_fail_0, label %sound_load_open_ok_1
sound_load_open_fail_0:
  br label %sound_load_end_2
sound_load_open_ok_1:
  call i32 @fseek(i8* %t5, i32 0, i32 2)
  %t7 = call i32 @ftell(i8* %t5)
  call i32 @fseek(i8* %t5, i32 0, i32 0)
  %t8 = icmp sge i32 %t7, 44
  br i1 %t8, label %sound_load_read_4, label %sound_load_too_small_3
sound_load_too_small_3:
  call i32 @fclose(i8* %t5)
  br label %sound_load_end_2
sound_load_read_4:
  %t9 = sext i32 %t7 to i64
  %t10 = call i8* @malloc(i64 %t9)
  %t11 = call i64 @fread(i8* %t10, i64 1, i64 %t9, i8* %t5)
  call i32 @fclose(i8* %t5)
  %t12 = icmp eq i64 %t11, %t9
  br i1 %t12, label %sound_load_validate_6, label %sound_load_short_read_5
sound_load_short_read_5:
  call void @free(i8* %t10)
  br label %sound_load_end_2
sound_load_validate_6:
  %t13 = getelementptr inbounds i8, i8* %t10, i64 0
  %t14 = bitcast i8* %t13 to i32*
  %t15 = load i32, i32* %t14
  %t16 = icmp eq i32 %t15, 1179011410
  %t17 = getelementptr inbounds i8, i8* %t10, i64 8
  %t18 = bitcast i8* %t17 to i32*
  %t19 = load i32, i32* %t18
  %t20 = icmp eq i32 %t19, 1163280727
  %t21 = getelementptr inbounds i8, i8* %t10, i64 12
  %t22 = bitcast i8* %t21 to i32*
  %t23 = load i32, i32* %t22
  %t24 = icmp eq i32 %t23, 544501094
  %t25 = getelementptr inbounds i8, i8* %t10, i64 16
  %t26 = bitcast i8* %t25 to i32*
  %t27 = load i32, i32* %t26
  %t28 = icmp eq i32 %t27, 16
  %t29 = getelementptr inbounds i8, i8* %t10, i64 20
  %t30 = bitcast i8* %t29 to i32*
  %t31 = load i32, i32* %t30
  %t32 = icmp eq i32 %t31, 131073
  %t33 = getelementptr inbounds i8, i8* %t10, i64 24
  %t34 = bitcast i8* %t33 to i32*
  %t35 = load i32, i32* %t34
  %t36 = icmp eq i32 %t35, 44100
  %t37 = getelementptr inbounds i8, i8* %t10, i64 34
  %t38 = bitcast i8* %t37 to i16*
  %t39 = load i16, i16* %t38
  %t40 = icmp eq i16 %t39, 16
  %t41 = getelementptr inbounds i8, i8* %t10, i64 36
  %t42 = bitcast i8* %t41 to i32*
  %t43 = load i32, i32* %t42
  %t44 = icmp eq i32 %t43, 1635017060
  %t45 = and i1 %t16, %t20
  %t46 = and i1 %t45, %t24
  %t47 = and i1 %t46, %t28
  %t48 = and i1 %t47, %t32
  %t49 = and i1 %t48, %t36
  %t50 = and i1 %t49, %t40
  %t51 = and i1 %t50, %t44
  br i1 %t51, label %sound_load_valid_8, label %sound_load_invalid_7
sound_load_invalid_7:
  call void @free(i8* %t10)
  br label %sound_load_end_2
sound_load_valid_8:
  %t52 = getelementptr inbounds i8, i8* %t10, i64 40
  %t53 = bitcast i8* %t52 to i32*
  %t54 = load i32, i32* %t53
  %t55 = zext i32 %t54 to i64
  %t56 = call i8* @malloc(i64 16)
  %t57 = bitcast i8* %t56 to i64*
  store i64 %t55, i64* %t57
  %t58 = getelementptr inbounds i8, i8* %t56, i64 8
  %t59 = bitcast i8* %t58 to i8**
  store i8* %t10, i8** %t59
  br label %sound_load_end_2
sound_load_end_2:
  %t60 = phi i8* [ null, %sound_load_open_fail_0 ], [ null, %sound_load_too_small_3 ], [ null, %sound_load_short_read_5 ], [ null, %sound_load_invalid_7 ], [ %t56, %sound_load_valid_8 ]
  store i8* %t60, i8** %t2
  %t61 = load i8*, i8** %t2
  %t62 = icmp eq i8* %t61, null
  br i1 %t62, label %if_then_9, label %if_else_10
if_then_9:
  %t63 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.2, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t63)
  call i32 (i8*, ...) @printf(i8* %t63)
  %t64 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t64)
  ret i32 0
if_else_10:
  br label %if_end_11
if_end_11:
  %t65 = getelementptr inbounds { i64, i8*, [32 x i8] }, { i64, i8*, [32 x i8] }* @.str.4, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t65)
  call i32 (i8*, ...) @printf(i8* %t65)
  %t66 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t66)
  %t67 = load i8*, i8** %t2
  %t68 = icmp eq i8* %t67, null
  br i1 %t68, label %sound_null_handle_12, label %sound_handle_ok_13
sound_null_handle_12:
  %t69 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.6, i64 0, i64 0
  call i32 @puts(i8* %t69)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_13:
  %t105 = load i32, i32* @star.audio.device
  %t106 = icmp ne i32 %t105, 0
  br i1 %t106, label %audio_dev_ok_18, label %audio_dev_init_17
audio_dev_init_17:
  %t107 = call i32 @SDL_Init(i32 16)
  %t109 = getelementptr inbounds [32 x i8], [32 x i8]* %t108, i64 0, i64 0
  store i64 0, i64* %t110
  br label %ht_fill8_cond_19
ht_fill8_cond_19:
  %t111 = load i64, i64* %t110
  %t112 = icmp slt i64 %t111, 32
  br i1 %t112, label %ht_fill8_body_20, label %ht_fill8_end_21
ht_fill8_body_20:
  %t113 = getelementptr inbounds i8, i8* %t109, i64 %t111
  store i8 0, i8* %t113
  %t114 = add i64 %t111, 1
  store i64 %t114, i64* %t110
  br label %ht_fill8_cond_19
ht_fill8_end_21:
  %t115 = bitcast i8* %t109 to i32*
  store i32 44100, i32* %t115
  %t116 = getelementptr inbounds i8, i8* %t109, i64 4
  %t117 = bitcast i8* %t116 to i16*
  store i16 32784, i16* %t117
  %t118 = getelementptr inbounds i8, i8* %t109, i64 6
  store i8 2, i8* %t118
  %t119 = getelementptr inbounds i8, i8* %t109, i64 8
  %t120 = bitcast i8* %t119 to i16*
  store i16 1024, i16* %t120
  %t121 = getelementptr inbounds i8, i8* %t109, i64 16
  %t122 = bitcast i8* %t121 to i8**
  %t123 = bitcast void (i8*, i8*, i32)* @star.audio.mix_callback to i8*
  store i8* %t123, i8** %t122
  %t124 = call i32 @SDL_OpenAudioDevice(i8* null, i32 0, i8* %t109, i8* null, i32 0)
  %t125 = icmp ne i32 %t124, 0
  br i1 %t125, label %audio_open_ok_22, label %audio_dev_ok_18
audio_open_ok_22:
  store i32 %t124, i32* @star.audio.device
  call void @SDL_PauseAudioDevice(i32 %t124, i32 0)
  br label %audio_dev_ok_18
audio_dev_ok_18:
  %t126 = bitcast i8* %t67 to i64*
  %t127 = load i64, i64* %t126
  %t128 = getelementptr inbounds i8, i8* %t67, i64 8
  %t129 = bitcast i8* %t128 to i8**
  %t130 = load i8*, i8** %t129
  %t131 = getelementptr inbounds i8, i8* %t130, i64 44
  store i32 -1, i32* %t132
  store i32 1, i32* %t133
  br label %sound_play_scan_cond_23
sound_play_scan_cond_23:
  %t134 = load i32, i32* %t133
  %t135 = icmp sge i32 %t134, 16
  br i1 %t135, label %sound_play_scan_end_27, label %sound_play_scan_check_24
sound_play_scan_check_24:
  %t136 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t134
  %t137 = load i8, i8* %t136
  %t138 = icmp eq i8 %t137, 0
  br i1 %t138, label %sound_play_scan_found_25, label %sound_play_scan_body_26
sound_play_scan_found_25:
  store i32 %t134, i32* %t132
  br label %sound_play_scan_end_27
sound_play_scan_body_26:
  %t139 = add i32 %t134, 1
  store i32 %t139, i32* %t133
  br label %sound_play_scan_cond_23
sound_play_scan_end_27:
  %t140 = load i32, i32* %t132
  %t141 = icmp sge i32 %t140, 0
  br i1 %t141, label %sound_play_do_28, label %sound_play_after_29
sound_play_do_28:
  %t142 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t140
  store i8* %t131, i8** %t142
  %t143 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_len, i32 0, i32 %t140
  store i64 %t127, i64* %t143
  %t144 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_pos, i32 0, i32 %t140
  store i64 0, i64* %t144
  %t145 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 %t140
  store i8 0, i8* %t145
  %t146 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t140
  store i8 1, i8* %t146
  br label %sound_play_after_29
sound_play_after_29:
  %t147 = icmp slt i32 400, 0
  %t148 = select i1 %t147, i32 0, i32 400
  call void @SDL_Delay(i32 %t148)
  %t149 = getelementptr inbounds { i64, i8*, [42 x i8] }, { i64, i8*, [42 x i8] }* @.str.7, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t149)
  call i32 (i8*, ...) @printf(i8* %t149)
  %t150 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t150)
  %t151 = load i8*, i8** %t2
  %t152 = icmp eq i8* %t151, null
  br i1 %t152, label %sound_null_handle_30, label %sound_handle_ok_31
sound_null_handle_30:
  %t153 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t153)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_31:
  %t154 = load i32, i32* @star.audio.device
  %t155 = icmp ne i32 %t154, 0
  br i1 %t155, label %audio_dev_ok_33, label %audio_dev_init_32
audio_dev_init_32:
  %t156 = call i32 @SDL_Init(i32 16)
  %t158 = getelementptr inbounds [32 x i8], [32 x i8]* %t157, i64 0, i64 0
  store i64 0, i64* %t159
  br label %ht_fill8_cond_34
ht_fill8_cond_34:
  %t160 = load i64, i64* %t159
  %t161 = icmp slt i64 %t160, 32
  br i1 %t161, label %ht_fill8_body_35, label %ht_fill8_end_36
ht_fill8_body_35:
  %t162 = getelementptr inbounds i8, i8* %t158, i64 %t160
  store i8 0, i8* %t162
  %t163 = add i64 %t160, 1
  store i64 %t163, i64* %t159
  br label %ht_fill8_cond_34
ht_fill8_end_36:
  %t164 = bitcast i8* %t158 to i32*
  store i32 44100, i32* %t164
  %t165 = getelementptr inbounds i8, i8* %t158, i64 4
  %t166 = bitcast i8* %t165 to i16*
  store i16 32784, i16* %t166
  %t167 = getelementptr inbounds i8, i8* %t158, i64 6
  store i8 2, i8* %t167
  %t168 = getelementptr inbounds i8, i8* %t158, i64 8
  %t169 = bitcast i8* %t168 to i16*
  store i16 1024, i16* %t169
  %t170 = getelementptr inbounds i8, i8* %t158, i64 16
  %t171 = bitcast i8* %t170 to i8**
  %t172 = bitcast void (i8*, i8*, i32)* @star.audio.mix_callback to i8*
  store i8* %t172, i8** %t171
  %t173 = call i32 @SDL_OpenAudioDevice(i8* null, i32 0, i8* %t158, i8* null, i32 0)
  %t174 = icmp ne i32 %t173, 0
  br i1 %t174, label %audio_open_ok_37, label %audio_dev_ok_33
audio_open_ok_37:
  store i32 %t173, i32* @star.audio.device
  call void @SDL_PauseAudioDevice(i32 %t173, i32 0)
  br label %audio_dev_ok_33
audio_dev_ok_33:
  %t175 = bitcast i8* %t151 to i64*
  %t176 = load i64, i64* %t175
  %t177 = getelementptr inbounds i8, i8* %t151, i64 8
  %t178 = bitcast i8* %t177 to i8**
  %t179 = load i8*, i8** %t178
  %t180 = getelementptr inbounds i8, i8* %t179, i64 44
  %t181 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 0
  store i8* %t180, i8** %t181
  %t182 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_len, i32 0, i32 0
  store i64 %t176, i64* %t182
  %t183 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_pos, i32 0, i32 0
  store i64 0, i64* %t183
  %t184 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 0
  store i8 1, i8* %t184
  %t185 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 0
  store i8 1, i8* %t185
  %t186 = icmp slt i32 800, 0
  %t187 = select i1 %t186, i32 0, i32 800
  call void @SDL_Delay(i32 %t187)
  %t188 = getelementptr inbounds { i64, i8*, [60 x i8] }, { i64, i8*, [60 x i8] }* @.str.10, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t188)
  call i32 (i8*, ...) @printf(i8* %t188)
  %t189 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t189)
  %t190 = load i8*, i8** %t2
  %t191 = icmp eq i8* %t190, null
  br i1 %t191, label %sound_null_handle_38, label %sound_handle_ok_39
sound_null_handle_38:
  %t192 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.12, i64 0, i64 0
  call i32 @puts(i8* %t192)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_39:
  %t193 = load i32, i32* @star.audio.device
  %t194 = icmp ne i32 %t193, 0
  br i1 %t194, label %audio_dev_ok_41, label %audio_dev_init_40
audio_dev_init_40:
  %t195 = call i32 @SDL_Init(i32 16)
  %t197 = getelementptr inbounds [32 x i8], [32 x i8]* %t196, i64 0, i64 0
  store i64 0, i64* %t198
  br label %ht_fill8_cond_42
ht_fill8_cond_42:
  %t199 = load i64, i64* %t198
  %t200 = icmp slt i64 %t199, 32
  br i1 %t200, label %ht_fill8_body_43, label %ht_fill8_end_44
ht_fill8_body_43:
  %t201 = getelementptr inbounds i8, i8* %t197, i64 %t199
  store i8 0, i8* %t201
  %t202 = add i64 %t199, 1
  store i64 %t202, i64* %t198
  br label %ht_fill8_cond_42
ht_fill8_end_44:
  %t203 = bitcast i8* %t197 to i32*
  store i32 44100, i32* %t203
  %t204 = getelementptr inbounds i8, i8* %t197, i64 4
  %t205 = bitcast i8* %t204 to i16*
  store i16 32784, i16* %t205
  %t206 = getelementptr inbounds i8, i8* %t197, i64 6
  store i8 2, i8* %t206
  %t207 = getelementptr inbounds i8, i8* %t197, i64 8
  %t208 = bitcast i8* %t207 to i16*
  store i16 1024, i16* %t208
  %t209 = getelementptr inbounds i8, i8* %t197, i64 16
  %t210 = bitcast i8* %t209 to i8**
  %t211 = bitcast void (i8*, i8*, i32)* @star.audio.mix_callback to i8*
  store i8* %t211, i8** %t210
  %t212 = call i32 @SDL_OpenAudioDevice(i8* null, i32 0, i8* %t197, i8* null, i32 0)
  %t213 = icmp ne i32 %t212, 0
  br i1 %t213, label %audio_open_ok_45, label %audio_dev_ok_41
audio_open_ok_45:
  store i32 %t212, i32* @star.audio.device
  call void @SDL_PauseAudioDevice(i32 %t212, i32 0)
  br label %audio_dev_ok_41
audio_dev_ok_41:
  %t214 = bitcast i8* %t190 to i64*
  %t215 = load i64, i64* %t214
  %t216 = getelementptr inbounds i8, i8* %t190, i64 8
  %t217 = bitcast i8* %t216 to i8**
  %t218 = load i8*, i8** %t217
  %t219 = getelementptr inbounds i8, i8* %t218, i64 44
  store i32 -1, i32* %t220
  store i32 1, i32* %t221
  br label %sound_play_scan_cond_46
sound_play_scan_cond_46:
  %t222 = load i32, i32* %t221
  %t223 = icmp sge i32 %t222, 16
  br i1 %t223, label %sound_play_scan_end_50, label %sound_play_scan_check_47
sound_play_scan_check_47:
  %t224 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t222
  %t225 = load i8, i8* %t224
  %t226 = icmp eq i8 %t225, 0
  br i1 %t226, label %sound_play_scan_found_48, label %sound_play_scan_body_49
sound_play_scan_found_48:
  store i32 %t222, i32* %t220
  br label %sound_play_scan_end_50
sound_play_scan_body_49:
  %t227 = add i32 %t222, 1
  store i32 %t227, i32* %t221
  br label %sound_play_scan_cond_46
sound_play_scan_end_50:
  %t228 = load i32, i32* %t220
  %t229 = icmp sge i32 %t228, 0
  br i1 %t229, label %sound_play_do_51, label %sound_play_after_52
sound_play_do_51:
  %t230 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t228
  store i8* %t219, i8** %t230
  %t231 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_len, i32 0, i32 %t228
  store i64 %t215, i64* %t231
  %t232 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_pos, i32 0, i32 %t228
  store i64 0, i64* %t232
  %t233 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 %t228
  store i8 0, i8* %t233
  %t234 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t228
  store i8 1, i8* %t234
  br label %sound_play_after_52
sound_play_after_52:
  %t235 = icmp slt i32 400, 0
  %t236 = select i1 %t235, i32 0, i32 400
  call void @SDL_Delay(i32 %t236)
  %t237 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 0
  store i8 0, i8* %t237
  %t238 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 0
  store i64 0, i64* %t239
  br label %ht_fill8_cond_53
ht_fill8_cond_53:
  %t240 = load i64, i64* %t239
  %t241 = icmp slt i64 %t240, 16
  br i1 %t241, label %ht_fill8_body_54, label %ht_fill8_end_55
ht_fill8_body_54:
  %t242 = getelementptr inbounds i8, i8* %t238, i64 %t240
  store i8 0, i8* %t242
  %t243 = add i64 %t240, 1
  store i64 %t243, i64* %t239
  br label %ht_fill8_cond_53
ht_fill8_end_55:
  %t244 = load i8*, i8** %t2
  %t245 = icmp eq i8* %t244, null
  br i1 %t245, label %sound_null_handle_56, label %sound_handle_ok_57
sound_null_handle_56:
  %t246 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.13, i64 0, i64 0
  call i32 @puts(i8* %t246)
  call void @exit(i32 1)
  unreachable
sound_handle_ok_57:
  %t247 = bitcast i8* %t244 to i64*
  %t248 = load i64, i64* %t247
  %t249 = getelementptr inbounds i8, i8* %t244, i64 8
  %t250 = bitcast i8* %t249 to i8**
  %t251 = load i8*, i8** %t250
  %t252 = getelementptr inbounds i8, i8* %t251, i64 44
  store i32 0, i32* %t253
  br label %sound_free_scan_cond_58
sound_free_scan_cond_58:
  %t254 = load i32, i32* %t253
  %t255 = icmp sge i32 %t254, 16
  br i1 %t255, label %sound_free_scan_end_62, label %sound_free_scan_check_59
sound_free_scan_check_59:
  %t256 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t254
  %t257 = load i8*, i8** %t256
  %t258 = icmp eq i8* %t257, %t252
  br i1 %t258, label %sound_free_scan_match_60, label %sound_free_scan_next_61
sound_free_scan_match_60:
  %t259 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t254
  store i8 0, i8* %t259
  br label %sound_free_scan_next_61
sound_free_scan_next_61:
  %t260 = add i32 %t254, 1
  store i32 %t260, i32* %t253
  br label %sound_free_scan_cond_58
sound_free_scan_end_62:
  %t261 = getelementptr inbounds i8, i8* %t244, i64 8
  %t262 = bitcast i8* %t261 to i8**
  %t263 = load i8*, i8** %t262
  call void @free(i8* %t263)
  call void @free(i8* %t244)
  store i8* null, i8** %t2
  %t264 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t264)
  call i32 (i8*, ...) @printf(i8* %t264)
  %t265 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t265)
  ret i32 0
}


; par/swarm worker functions
@star.audio.device = global i32 0
@star.audio.chan_base = global [16 x i8*] zeroinitializer
@star.audio.chan_len = global [16 x i64] zeroinitializer
@star.audio.chan_pos = global [16 x i64] zeroinitializer
@star.audio.chan_playing = global [16 x i8] zeroinitializer
@star.audio.chan_loop = global [16 x i8] zeroinitializer

define void @star.audio.mix_callback(i8* %userdata, i8* %stream, i32 %len) {
entry:
  %t70 = alloca i32
  %t72 = alloca i64
  store i32 0, i32* %t70
  %t71 = sext i32 %len to i64
  store i64 0, i64* %t72
  br label %ht_fill8_cond_14
ht_fill8_cond_14:
  %t73 = load i64, i64* %t72
  %t74 = icmp slt i64 %t73, %t71
  br i1 %t74, label %ht_fill8_body_15, label %ht_fill8_end_16
ht_fill8_body_15:
  %t75 = getelementptr inbounds i8, i8* %stream, i64 %t73
  store i8 0, i8* %t75
  %t76 = add i64 %t73, 1
  store i64 %t76, i64* %t72
  br label %ht_fill8_cond_14
ht_fill8_end_16:
  br label %chan_cond
chan_cond:
  %t77 = load i32, i32* %t70
  %t78 = icmp sge i32 %t77, 16
  br i1 %t78, label %exit, label %chan_body
chan_body:
  %t79 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_playing, i32 0, i32 %t77
  %t80 = load i8, i8* %t79
  %t81 = icmp ne i8 %t80, 0
  br i1 %t81, label %chan_mix, label %chan_latch
chan_mix:
  %t82 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_pos, i32 0, i32 %t77
  %t83 = load i64, i64* %t82
  %t84 = getelementptr inbounds [16 x i64], [16 x i64]* @star.audio.chan_len, i32 0, i32 %t77
  %t85 = load i64, i64* %t84
  %t86 = sub i64 %t85, %t83
  %t87 = icmp sle i64 %t86, 0
  br i1 %t87, label %chan_checkloop, label %chan_have
chan_checkloop:
  %t88 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 %t77
  %t89 = load i8, i8* %t88
  %t90 = icmp ne i8 %t89, 0
  br i1 %t90, label %chan_have, label %chan_stop
chan_stop:
  store i8 0, i8* %t79
  br label %chan_latch
chan_have:
  %t91 = phi i64 [ %t83, %chan_mix ], [ 0, %chan_checkloop ]
  %t92 = phi i64 [ %t86, %chan_mix ], [ %t85, %chan_checkloop ]
  %t93 = icmp slt i64 %t92, %t71
  %t94 = select i1 %t93, i64 %t92, i64 %t71
  %t95 = trunc i64 %t94 to i32
  %t96 = getelementptr inbounds [16 x i8*], [16 x i8*]* @star.audio.chan_base, i32 0, i32 %t77
  %t97 = load i8*, i8** %t96
  %t98 = getelementptr inbounds i8, i8* %t97, i64 %t91
  call void @SDL_MixAudioFormat(i8* %stream, i8* %t98, i16 32784, i32 %t95, i32 128)
  %t99 = add i64 %t91, %t94
  store i64 %t99, i64* %t82
  %t100 = icmp sge i64 %t99, %t85
  br i1 %t100, label %chan_checkdone, label %chan_latch
chan_checkdone:
  %t101 = getelementptr inbounds [16 x i8], [16 x i8]* @star.audio.chan_loop, i32 0, i32 %t77
  %t102 = load i8, i8* %t101
  %t103 = icmp ne i8 %t102, 0
  br i1 %t103, label %chan_wrap, label %chan_finish
chan_wrap:
  store i64 0, i64* %t82
  br label %chan_latch
chan_finish:
  store i8 0, i8* %t79
  br label %chan_latch
chan_latch:
  %t104 = add i32 %t77, 1
  store i32 %t104, i32* %t70
  br label %chan_cond
exit:
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [25 x i8] } { i64 -1, i8* null, [25 x i8] c"examples/assets/beep.wav\00" }
@.str.1 = private unnamed_addr constant [3 x i8] c"rb\00"
@.str.2 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"sound_load failed\00" }
@.str.3 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.4 = private unnamed_addr constant { i64, i8*, [32 x i8] } { i64 -1, i8* null, [32 x i8] c"playing a one-shot sound effect\00" }
@.str.5 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.6 = private unnamed_addr constant [74 x i8] c"star runtime error: sound_play(..) called with a null/freed sound handle\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [42 x i8] } { i64 -1, i8* null, [42 x i8] c"looping the same clip as background music\00" }
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.9 = private unnamed_addr constant [74 x i8] c"star runtime error: music_play(..) called with a null/freed sound handle\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [60 x i8] } { i64 -1, i8* null, [60 x i8] c"layering a second one-shot sound effect on top of the music\00" }
@.str.11 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.12 = private unnamed_addr constant [74 x i8] c"star runtime error: sound_play(..) called with a null/freed sound handle\0A\00"
@.str.13 = private unnamed_addr constant [74 x i8] c"star runtime error: sound_free(..) called with a null/freed sound handle\0A\00"
@.str.14 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"done\00" }
@.str.15 = private unnamed_addr constant [2 x i8] c"\0A\00"
