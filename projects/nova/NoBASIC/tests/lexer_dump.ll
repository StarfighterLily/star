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

%lex__tok__Token = type { i32, i8*, double, i1, i8*, i32, i32 }
declare double @atof(i8*)
declare i32 @strtol(i8*, i8*, i32)
%lex__LexError = type { i8*, i8*, i32, i32 }
%lex__Lexer = type { i8*, i8*, i8*, i32, i32, i32, i32, i32, i32, i8*, i1, i8*, i32, i32 }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
%Option__lex__tok__TokenType = type { i32, [1 x i64] }
%Result__List_lex__tok__Token__lex__LexError = type { i32, [3 x i64] }
define i8* @lex__tok__build_keywords() {
entry:
  %t0 = alloca i8*
  %t68 = alloca i64
  %t121 = alloca i64
  %t129 = alloca i64
  %t155 = alloca i64
  %t156 = alloca i64
  %t182 = alloca i64
  %t183 = alloca i64
  %t184 = alloca i1
  %t185 = alloca i64
  %t186 = alloca i64
  %t187 = alloca i1
  %t206 = alloca i8*
  %t265 = alloca i64
  %t318 = alloca i64
  %t326 = alloca i64
  %t338 = alloca i64
  %t339 = alloca i64
  %t363 = alloca i64
  %t364 = alloca i64
  %t365 = alloca i1
  %t366 = alloca i64
  %t367 = alloca i64
  %t368 = alloca i1
  %t387 = alloca i8*
  %t446 = alloca i64
  %t499 = alloca i64
  %t507 = alloca i64
  %t519 = alloca i64
  %t520 = alloca i64
  %t544 = alloca i64
  %t545 = alloca i64
  %t546 = alloca i1
  %t547 = alloca i64
  %t548 = alloca i64
  %t549 = alloca i1
  %t568 = alloca i8*
  %t627 = alloca i64
  %t680 = alloca i64
  %t688 = alloca i64
  %t700 = alloca i64
  %t701 = alloca i64
  %t725 = alloca i64
  %t726 = alloca i64
  %t727 = alloca i1
  %t728 = alloca i64
  %t729 = alloca i64
  %t730 = alloca i1
  %t749 = alloca i8*
  %t808 = alloca i64
  %t861 = alloca i64
  %t869 = alloca i64
  %t881 = alloca i64
  %t882 = alloca i64
  %t906 = alloca i64
  %t907 = alloca i64
  %t908 = alloca i1
  %t909 = alloca i64
  %t910 = alloca i64
  %t911 = alloca i1
  %t930 = alloca i8*
  %t989 = alloca i64
  %t1042 = alloca i64
  %t1050 = alloca i64
  %t1062 = alloca i64
  %t1063 = alloca i64
  %t1087 = alloca i64
  %t1088 = alloca i64
  %t1089 = alloca i1
  %t1090 = alloca i64
  %t1091 = alloca i64
  %t1092 = alloca i1
  %t1111 = alloca i8*
  %t1170 = alloca i64
  %t1223 = alloca i64
  %t1231 = alloca i64
  %t1243 = alloca i64
  %t1244 = alloca i64
  %t1268 = alloca i64
  %t1269 = alloca i64
  %t1270 = alloca i1
  %t1271 = alloca i64
  %t1272 = alloca i64
  %t1273 = alloca i1
  %t1292 = alloca i8*
  %t1351 = alloca i64
  %t1404 = alloca i64
  %t1412 = alloca i64
  %t1424 = alloca i64
  %t1425 = alloca i64
  %t1449 = alloca i64
  %t1450 = alloca i64
  %t1451 = alloca i1
  %t1452 = alloca i64
  %t1453 = alloca i64
  %t1454 = alloca i1
  %t1473 = alloca i8*
  %t1532 = alloca i64
  %t1585 = alloca i64
  %t1593 = alloca i64
  %t1605 = alloca i64
  %t1606 = alloca i64
  %t1630 = alloca i64
  %t1631 = alloca i64
  %t1632 = alloca i1
  %t1633 = alloca i64
  %t1634 = alloca i64
  %t1635 = alloca i1
  %t1654 = alloca i8*
  %t1713 = alloca i64
  %t1766 = alloca i64
  %t1774 = alloca i64
  %t1786 = alloca i64
  %t1787 = alloca i64
  %t1811 = alloca i64
  %t1812 = alloca i64
  %t1813 = alloca i1
  %t1814 = alloca i64
  %t1815 = alloca i64
  %t1816 = alloca i1
  %t1835 = alloca i8*
  %t1894 = alloca i64
  %t1947 = alloca i64
  %t1955 = alloca i64
  %t1967 = alloca i64
  %t1968 = alloca i64
  %t1992 = alloca i64
  %t1993 = alloca i64
  %t1994 = alloca i1
  %t1995 = alloca i64
  %t1996 = alloca i64
  %t1997 = alloca i1
  %t2016 = alloca i8*
  %t2075 = alloca i64
  %t2128 = alloca i64
  %t2136 = alloca i64
  %t2148 = alloca i64
  %t2149 = alloca i64
  %t2173 = alloca i64
  %t2174 = alloca i64
  %t2175 = alloca i1
  %t2176 = alloca i64
  %t2177 = alloca i64
  %t2178 = alloca i1
  %t2197 = alloca i8*
  %t2256 = alloca i64
  %t2309 = alloca i64
  %t2317 = alloca i64
  %t2329 = alloca i64
  %t2330 = alloca i64
  %t2354 = alloca i64
  %t2355 = alloca i64
  %t2356 = alloca i1
  %t2357 = alloca i64
  %t2358 = alloca i64
  %t2359 = alloca i1
  %t2378 = alloca i8*
  %t2437 = alloca i64
  %t2490 = alloca i64
  %t2498 = alloca i64
  %t2510 = alloca i64
  %t2511 = alloca i64
  %t2535 = alloca i64
  %t2536 = alloca i64
  %t2537 = alloca i1
  %t2538 = alloca i64
  %t2539 = alloca i64
  %t2540 = alloca i1
  %t2559 = alloca i8*
  %t2618 = alloca i64
  %t2671 = alloca i64
  %t2679 = alloca i64
  %t2691 = alloca i64
  %t2692 = alloca i64
  %t2716 = alloca i64
  %t2717 = alloca i64
  %t2718 = alloca i1
  %t2719 = alloca i64
  %t2720 = alloca i64
  %t2721 = alloca i1
  %t2740 = alloca i8*
  %t2799 = alloca i64
  %t2852 = alloca i64
  %t2860 = alloca i64
  %t2872 = alloca i64
  %t2873 = alloca i64
  %t2897 = alloca i64
  %t2898 = alloca i64
  %t2899 = alloca i1
  %t2900 = alloca i64
  %t2901 = alloca i64
  %t2902 = alloca i1
  %t2921 = alloca i8*
  %t2980 = alloca i64
  %t3033 = alloca i64
  %t3041 = alloca i64
  %t3053 = alloca i64
  %t3054 = alloca i64
  %t3078 = alloca i64
  %t3079 = alloca i64
  %t3080 = alloca i1
  %t3081 = alloca i64
  %t3082 = alloca i64
  %t3083 = alloca i1
  %t3102 = alloca i8*
  %t3161 = alloca i64
  %t3214 = alloca i64
  %t3222 = alloca i64
  %t3234 = alloca i64
  %t3235 = alloca i64
  %t3259 = alloca i64
  %t3260 = alloca i64
  %t3261 = alloca i1
  %t3262 = alloca i64
  %t3263 = alloca i64
  %t3264 = alloca i1
  %t3283 = alloca i8*
  %t3342 = alloca i64
  %t3395 = alloca i64
  %t3403 = alloca i64
  %t3415 = alloca i64
  %t3416 = alloca i64
  %t3440 = alloca i64
  %t3441 = alloca i64
  %t3442 = alloca i1
  %t3443 = alloca i64
  %t3444 = alloca i64
  %t3445 = alloca i1
  %t3464 = alloca i8*
  %t3523 = alloca i64
  %t3576 = alloca i64
  %t3584 = alloca i64
  %t3596 = alloca i64
  %t3597 = alloca i64
  %t3621 = alloca i64
  %t3622 = alloca i64
  %t3623 = alloca i1
  %t3624 = alloca i64
  %t3625 = alloca i64
  %t3626 = alloca i1
  %t3645 = alloca i8*
  %t3704 = alloca i64
  %t3757 = alloca i64
  %t3765 = alloca i64
  %t3777 = alloca i64
  %t3778 = alloca i64
  %t3802 = alloca i64
  %t3803 = alloca i64
  %t3804 = alloca i1
  %t3805 = alloca i64
  %t3806 = alloca i64
  %t3807 = alloca i1
  %t3826 = alloca i8*
  %t3885 = alloca i64
  %t3938 = alloca i64
  %t3946 = alloca i64
  %t3958 = alloca i64
  %t3959 = alloca i64
  %t3983 = alloca i64
  %t3984 = alloca i64
  %t3985 = alloca i1
  %t3986 = alloca i64
  %t3987 = alloca i64
  %t3988 = alloca i1
  %t4007 = alloca i8*
  %t4066 = alloca i64
  %t4119 = alloca i64
  %t4127 = alloca i64
  %t4139 = alloca i64
  %t4140 = alloca i64
  %t4164 = alloca i64
  %t4165 = alloca i64
  %t4166 = alloca i1
  %t4167 = alloca i64
  %t4168 = alloca i64
  %t4169 = alloca i1
  %t4188 = alloca i8*
  %t4247 = alloca i64
  %t4300 = alloca i64
  %t4308 = alloca i64
  %t4320 = alloca i64
  %t4321 = alloca i64
  %t4345 = alloca i64
  %t4346 = alloca i64
  %t4347 = alloca i1
  %t4348 = alloca i64
  %t4349 = alloca i64
  %t4350 = alloca i1
  %t4369 = alloca i8*
  %t4428 = alloca i64
  %t4481 = alloca i64
  %t4489 = alloca i64
  %t4501 = alloca i64
  %t4502 = alloca i64
  %t4526 = alloca i64
  %t4527 = alloca i64
  %t4528 = alloca i1
  %t4529 = alloca i64
  %t4530 = alloca i64
  %t4531 = alloca i1
  %t4550 = alloca i8*
  %t4609 = alloca i64
  %t4662 = alloca i64
  %t4670 = alloca i64
  %t4682 = alloca i64
  %t4683 = alloca i64
  %t4707 = alloca i64
  %t4708 = alloca i64
  %t4709 = alloca i1
  %t4710 = alloca i64
  %t4711 = alloca i64
  %t4712 = alloca i1
  %t4731 = alloca i8*
  %t4790 = alloca i64
  %t4843 = alloca i64
  %t4851 = alloca i64
  %t4863 = alloca i64
  %t4864 = alloca i64
  %t4888 = alloca i64
  %t4889 = alloca i64
  %t4890 = alloca i1
  %t4891 = alloca i64
  %t4892 = alloca i64
  %t4893 = alloca i1
  %t4912 = alloca i8*
  %t4971 = alloca i64
  %t5024 = alloca i64
  %t5032 = alloca i64
  %t5044 = alloca i64
  %t5045 = alloca i64
  %t5069 = alloca i64
  %t5070 = alloca i64
  %t5071 = alloca i1
  %t5072 = alloca i64
  %t5073 = alloca i64
  %t5074 = alloca i1
  %t5093 = alloca i8*
  %t5152 = alloca i64
  %t5205 = alloca i64
  %t5213 = alloca i64
  %t5225 = alloca i64
  %t5226 = alloca i64
  %t5250 = alloca i64
  %t5251 = alloca i64
  %t5252 = alloca i1
  %t5253 = alloca i64
  %t5254 = alloca i64
  %t5255 = alloca i1
  %t5274 = alloca i8*
  %t5333 = alloca i64
  %t5386 = alloca i64
  %t5394 = alloca i64
  %t5406 = alloca i64
  %t5407 = alloca i64
  %t5431 = alloca i64
  %t5432 = alloca i64
  %t5433 = alloca i1
  %t5434 = alloca i64
  %t5435 = alloca i64
  %t5436 = alloca i1
  %t5455 = alloca i8*
  %t5514 = alloca i64
  %t5567 = alloca i64
  %t5575 = alloca i64
  %t5587 = alloca i64
  %t5588 = alloca i64
  %t5612 = alloca i64
  %t5613 = alloca i64
  %t5614 = alloca i1
  %t5615 = alloca i64
  %t5616 = alloca i64
  %t5617 = alloca i1
  %t5636 = alloca i8*
  %t5695 = alloca i64
  %t5748 = alloca i64
  %t5756 = alloca i64
  %t5768 = alloca i64
  %t5769 = alloca i64
  %t5793 = alloca i64
  %t5794 = alloca i64
  %t5795 = alloca i1
  %t5796 = alloca i64
  %t5797 = alloca i64
  %t5798 = alloca i1
  %t5817 = alloca i8*
  %t5876 = alloca i64
  %t5929 = alloca i64
  %t5937 = alloca i64
  %t5949 = alloca i64
  %t5950 = alloca i64
  %t5974 = alloca i64
  %t5975 = alloca i64
  %t5976 = alloca i1
  %t5977 = alloca i64
  %t5978 = alloca i64
  %t5979 = alloca i1
  %t5998 = alloca i8*
  %t6057 = alloca i64
  %t6110 = alloca i64
  %t6118 = alloca i64
  %t6130 = alloca i64
  %t6131 = alloca i64
  %t6155 = alloca i64
  %t6156 = alloca i64
  %t6157 = alloca i1
  %t6158 = alloca i64
  %t6159 = alloca i64
  %t6160 = alloca i1
  %t6179 = alloca i8*
  %t6238 = alloca i64
  %t6291 = alloca i64
  %t6299 = alloca i64
  %t6311 = alloca i64
  %t6312 = alloca i64
  %t6336 = alloca i64
  %t6337 = alloca i64
  %t6338 = alloca i1
  %t6339 = alloca i64
  %t6340 = alloca i64
  %t6341 = alloca i1
  %t6360 = alloca i8*
  %t6419 = alloca i64
  %t6472 = alloca i64
  %t6480 = alloca i64
  %t6492 = alloca i64
  %t6493 = alloca i64
  %t6517 = alloca i64
  %t6518 = alloca i64
  %t6519 = alloca i1
  %t6520 = alloca i64
  %t6521 = alloca i64
  %t6522 = alloca i1
  %t6541 = alloca i8*
  %t6600 = alloca i64
  %t6653 = alloca i64
  %t6661 = alloca i64
  %t6673 = alloca i64
  %t6674 = alloca i64
  %t6698 = alloca i64
  %t6699 = alloca i64
  %t6700 = alloca i1
  %t6701 = alloca i64
  %t6702 = alloca i64
  %t6703 = alloca i1
  %t6722 = alloca i8*
  %t6781 = alloca i64
  %t6834 = alloca i64
  %t6842 = alloca i64
  %t6854 = alloca i64
  %t6855 = alloca i64
  %t6879 = alloca i64
  %t6880 = alloca i64
  %t6881 = alloca i1
  %t6882 = alloca i64
  %t6883 = alloca i64
  %t6884 = alloca i1
  %t6903 = alloca i8*
  %t6962 = alloca i64
  %t7015 = alloca i64
  %t7023 = alloca i64
  %t7035 = alloca i64
  %t7036 = alloca i64
  %t7060 = alloca i64
  %t7061 = alloca i64
  %t7062 = alloca i1
  %t7063 = alloca i64
  %t7064 = alloca i64
  %t7065 = alloca i1
  %t7084 = alloca i8*
  %t7143 = alloca i64
  %t7196 = alloca i64
  %t7204 = alloca i64
  %t7216 = alloca i64
  %t7217 = alloca i64
  %t7241 = alloca i64
  %t7242 = alloca i64
  %t7243 = alloca i1
  %t7244 = alloca i64
  %t7245 = alloca i64
  %t7246 = alloca i1
  %t7265 = alloca i8*
  %t7324 = alloca i64
  %t7377 = alloca i64
  %t7385 = alloca i64
  %t7397 = alloca i64
  %t7398 = alloca i64
  %t7422 = alloca i64
  %t7423 = alloca i64
  %t7424 = alloca i1
  %t7425 = alloca i64
  %t7426 = alloca i64
  %t7427 = alloca i1
  %t7446 = alloca i8*
  %t7505 = alloca i64
  %t7558 = alloca i64
  %t7566 = alloca i64
  %t7578 = alloca i64
  %t7579 = alloca i64
  %t7603 = alloca i64
  %t7604 = alloca i64
  %t7605 = alloca i1
  %t7606 = alloca i64
  %t7607 = alloca i64
  %t7608 = alloca i1
  %t7627 = alloca i8*
  %t7686 = alloca i64
  %t7739 = alloca i64
  %t7747 = alloca i64
  %t7759 = alloca i64
  %t7760 = alloca i64
  %t7784 = alloca i64
  %t7785 = alloca i64
  %t7786 = alloca i1
  %t7787 = alloca i64
  %t7788 = alloca i64
  %t7789 = alloca i1
  %t7808 = alloca i8*
  %t7867 = alloca i64
  %t7920 = alloca i64
  %t7928 = alloca i64
  %t7940 = alloca i64
  %t7941 = alloca i64
  %t7965 = alloca i64
  %t7966 = alloca i64
  %t7967 = alloca i1
  %t7968 = alloca i64
  %t7969 = alloca i64
  %t7970 = alloca i1
  %t7989 = alloca i8*
  %t8048 = alloca i64
  %t8101 = alloca i64
  %t8109 = alloca i64
  %t8121 = alloca i64
  %t8122 = alloca i64
  %t8146 = alloca i64
  %t8147 = alloca i64
  %t8148 = alloca i1
  %t8149 = alloca i64
  %t8150 = alloca i64
  %t8151 = alloca i1
  %t8170 = alloca i8*
  %t8229 = alloca i64
  %t8282 = alloca i64
  %t8290 = alloca i64
  %t8302 = alloca i64
  %t8303 = alloca i64
  %t8327 = alloca i64
  %t8328 = alloca i64
  %t8329 = alloca i1
  %t8330 = alloca i64
  %t8331 = alloca i64
  %t8332 = alloca i1
  %t8351 = alloca i8*
  %t8410 = alloca i64
  %t8463 = alloca i64
  %t8471 = alloca i64
  %t8483 = alloca i64
  %t8484 = alloca i64
  %t8508 = alloca i64
  %t8509 = alloca i64
  %t8510 = alloca i1
  %t8511 = alloca i64
  %t8512 = alloca i64
  %t8513 = alloca i1
  %t8532 = alloca i8*
  %t8591 = alloca i64
  %t8644 = alloca i64
  %t8652 = alloca i64
  %t8664 = alloca i64
  %t8665 = alloca i64
  %t8689 = alloca i64
  %t8690 = alloca i64
  %t8691 = alloca i1
  %t8692 = alloca i64
  %t8693 = alloca i64
  %t8694 = alloca i1
  %t8713 = alloca i8*
  store i8* null, i8** %t0
  %t1 = getelementptr i8*, i8** null, i32 1
  %t2 = ptrtoint i8** %t1 to i64
  %t3 = getelementptr i32, i32* null, i32 1
  %t4 = ptrtoint i32* %t3 to i64
  %t5 = load i8*, i8** %t0
  %t6 = icmp eq i8* %t5, null
  br i1 %t6, label %map_cow_alloc_0, label %map_cow_check_1
map_cow_alloc_0:
  %t27 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t28 = call i8* @star_rc_alloc(i64 48, i8* %t27)
  %t29 = bitcast i8* %t28 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t30 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t29, i32 0, i32 0
  store i8** null, i8*** %t30
  %t31 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t29, i32 0, i32 1
  store i32* null, i32** %t31
  %t32 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t29, i32 0, i32 2
  store i8* null, i8** %t32
  %t33 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t29, i32 0, i32 3
  store i64 0, i64* %t33
  %t34 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t29, i32 0, i32 4
  store i64 0, i64* %t34
  %t35 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t29, i32 0, i32 5
  store i64 0, i64* %t35
  store i8* %t28, i8** %t0
  br label %map_cow_done_2
map_cow_check_1:
  %t36 = getelementptr inbounds i8, i8* %t5, i64 -16
  %t37 = bitcast i8* %t36 to i64*
  %t38 = load atomic i64, i64* %t37 seq_cst, align 8
  %t39 = icmp eq i64 %t38, 1
  br i1 %t39, label %map_cow_done_2, label %map_cow_clone_8
map_cow_clone_8:
  %t40 = bitcast i8* %t5 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t41 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t40, i32 0, i32 0
  %t42 = load i8**, i8*** %t41
  %t43 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t40, i32 0, i32 1
  %t44 = load i32*, i32** %t43
  %t45 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t40, i32 0, i32 2
  %t46 = load i8*, i8** %t45
  %t47 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t40, i32 0, i32 3
  %t48 = load i64, i64* %t47
  %t49 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t40, i32 0, i32 4
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t40, i32 0, i32 5
  %t52 = load i64, i64* %t51
  %t53 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t54 = call i8* @star_rc_alloc(i64 48, i8* %t53)
  %t55 = bitcast i8* %t54 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t56 = mul i64 %t50, %t2
  %t57 = call i8* @malloc(i64 %t56)
  %t58 = bitcast i8* %t57 to i8**
  %t59 = mul i64 %t50, %t4
  %t60 = call i8* @malloc(i64 %t59)
  %t61 = bitcast i8* %t60 to i32*
  %t62 = call i8* @malloc(i64 %t50)
  %t63 = icmp sgt i64 %t50, 0
  br i1 %t63, label %map_cow_copy_9, label %map_cow_after_copy_10
map_cow_copy_9:
  %t64 = mul i64 %t50, %t2
  %t65 = bitcast i8** %t42 to i8*
  call i8* @memcpy(i8* %t57, i8* %t65, i64 %t64)
  %t66 = mul i64 %t50, %t4
  %t67 = bitcast i32* %t44 to i8*
  call i8* @memcpy(i8* %t60, i8* %t67, i64 %t66)
  call i8* @memcpy(i8* %t62, i8* %t46, i64 %t50)
  store i64 0, i64* %t68
  br label %map_cow_retain_cond_11
map_cow_retain_cond_11:
  %t69 = load i64, i64* %t68
  %t70 = icmp slt i64 %t69, %t50
  br i1 %t70, label %map_cow_retain_body_12, label %map_cow_retain_end_15
map_cow_retain_body_12:
  %t71 = getelementptr inbounds i8, i8* %t62, i64 %t69
  %t72 = load i8, i8* %t71
  %t73 = icmp eq i8 %t72, 1
  br i1 %t73, label %map_cow_retain_occ_13, label %map_cow_retain_next_14
map_cow_retain_occ_13:
  %t74 = getelementptr inbounds i8*, i8** %t58, i64 %t69
  %t75 = load i8*, i8** %t74
  call void @star_rc_retain(i8* %t75)
  br label %map_cow_retain_next_14
map_cow_retain_next_14:
  %t76 = add i64 %t69, 1
  store i64 %t76, i64* %t68
  br label %map_cow_retain_cond_11
map_cow_retain_end_15:
  br label %map_cow_after_copy_10
map_cow_after_copy_10:
  %t77 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t55, i32 0, i32 0
  store i8** %t58, i8*** %t77
  %t78 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t55, i32 0, i32 1
  store i32* %t61, i32** %t78
  %t79 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t55, i32 0, i32 2
  store i8* %t62, i8** %t79
  %t80 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t55, i32 0, i32 3
  store i64 %t48, i64* %t80
  %t81 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t55, i32 0, i32 4
  store i64 %t50, i64* %t81
  %t82 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t55, i32 0, i32 5
  store i64 %t52, i64* %t82
  call void @star_rc_release(i8* %t5)
  store i8* %t54, i8** %t0
  br label %map_cow_done_2
map_cow_done_2:
  %t83 = load i8*, i8** %t0
  %t84 = bitcast i8* %t83 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t85 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t84, i32 0, i32 0
  %t86 = load i8**, i8*** %t85
  %t87 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t84, i32 0, i32 1
  %t88 = load i32*, i32** %t87
  %t89 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t84, i32 0, i32 2
  %t90 = load i8*, i8** %t89
  %t91 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t84, i32 0, i32 3
  %t92 = load i64, i64* %t91
  %t93 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t84, i32 0, i32 4
  %t94 = load i64, i64* %t93
  %t95 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t84, i32 0, i32 5
  %t96 = load i64, i64* %t95
  %t97 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t98 = load i64, i64* %t91
  %t99 = load i64, i64* %t93
  %t100 = load i64, i64* %t95
  %t101 = add i64 %t98, %t100
  %t102 = add i64 %t101, 1
  %t103 = mul i64 %t102, 4
  %t104 = mul i64 %t99, 3
  %t105 = icmp sgt i64 %t103, %t104
  br i1 %t105, label %map_insert_grow_16, label %map_insert_after_grow_17
map_insert_grow_16:
  %t106 = getelementptr i8*, i8** null, i32 1
  %t107 = ptrtoint i8** %t106 to i64
  %t108 = getelementptr i32, i32* null, i32 1
  %t109 = ptrtoint i32* %t108 to i64
  %t110 = mul i64 %t99, 2
  %t111 = icmp sgt i64 %t110, 0
  %t112 = select i1 %t111, i64 %t110, i64 8
  %t113 = sub i64 %t112, 1
  %t114 = mul i64 %t112, %t107
  %t115 = call i8* @malloc(i64 %t114)
  %t116 = bitcast i8* %t115 to i8**
  %t117 = mul i64 %t112, %t109
  %t118 = call i8* @malloc(i64 %t117)
  %t119 = bitcast i8* %t118 to i32*
  %t120 = call i8* @malloc(i64 %t112)
  store i64 0, i64* %t121
  br label %ht_fill8_cond_18
ht_fill8_cond_18:
  %t122 = load i64, i64* %t121
  %t123 = icmp slt i64 %t122, %t112
  br i1 %t123, label %ht_fill8_body_19, label %ht_fill8_end_20
ht_fill8_body_19:
  %t124 = getelementptr inbounds i8, i8* %t120, i64 %t122
  store i8 0, i8* %t124
  %t125 = add i64 %t122, 1
  store i64 %t125, i64* %t121
  br label %ht_fill8_cond_18
ht_fill8_end_20:
  %t126 = load i8**, i8*** %t85
  %t127 = load i32*, i32** %t87
  %t128 = load i8*, i8** %t89
  store i64 0, i64* %t129
  br label %map_grow_cond_21
map_grow_cond_21:
  %t130 = load i64, i64* %t129
  %t131 = icmp slt i64 %t130, %t99
  br i1 %t131, label %map_grow_body_22, label %map_grow_end_25
map_grow_body_22:
  %t132 = getelementptr inbounds i8, i8* %t128, i64 %t130
  %t133 = load i8, i8* %t132
  %t134 = icmp eq i8 %t133, 1
  br i1 %t134, label %map_grow_occ_23, label %map_grow_next_24
map_grow_occ_23:
  %t135 = getelementptr inbounds i8*, i8** %t126, i64 %t130
  %t136 = load i8*, i8** %t135
  %t137 = getelementptr inbounds i32, i32* %t127, i64 %t130
  %t138 = load i32, i32* %t137
  %t153 = call i64 @hash_str(i8* %t136)
  %t154 = and i64 %t153, %t113
  store i64 0, i64* %t155
  store i64 %t154, i64* %t156
  br label %ht_fe_cond_29
ht_fe_cond_29:
  %t157 = load i64, i64* %t155
  %t158 = icmp slt i64 %t157, %t112
  br i1 %t158, label %ht_fe_body_30, label %ht_fe_end_32
ht_fe_body_30:
  %t159 = load i64, i64* %t156
  %t160 = getelementptr inbounds i8, i8* %t120, i64 %t159
  %t161 = load i8, i8* %t160
  %t162 = icmp eq i8 %t161, 0
  br i1 %t162, label %ht_fe_end_32, label %ht_fe_next_31
ht_fe_next_31:
  %t163 = add i64 %t159, 1
  %t164 = and i64 %t163, %t113
  store i64 %t164, i64* %t156
  %t165 = add i64 %t157, 1
  store i64 %t165, i64* %t155
  br label %ht_fe_cond_29
ht_fe_end_32:
  %t166 = load i64, i64* %t156
  %t167 = getelementptr inbounds i8, i8* %t120, i64 %t166
  store i8 1, i8* %t167
  %t168 = getelementptr inbounds i8*, i8** %t116, i64 %t166
  store i8* %t136, i8** %t168
  %t169 = getelementptr inbounds i32, i32* %t119, i64 %t166
  store i32 %t138, i32* %t169
  br label %map_grow_next_24
map_grow_next_24:
  %t170 = add i64 %t130, 1
  store i64 %t170, i64* %t129
  br label %map_grow_cond_21
map_grow_end_25:
  %t171 = bitcast i8** %t126 to i8*
  call void @free(i8* %t171)
  %t172 = bitcast i32* %t127 to i8*
  call void @free(i8* %t172)
  call void @free(i8* %t128)
  store i8** %t116, i8*** %t85
  store i32* %t119, i32** %t87
  store i8* %t120, i8** %t89
  store i64 %t112, i64* %t93
  store i64 0, i64* %t95
  br label %map_insert_after_grow_17
map_insert_after_grow_17:
  %t173 = load i8**, i8*** %t85
  %t174 = load i32*, i32** %t87
  %t175 = load i8*, i8** %t89
  %t176 = load i64, i64* %t93
  %t177 = sub i64 %t176, 1
  %t178 = call i64 @hash_str(i8* %t97)
  %t179 = and i64 %t178, %t177
  store i64 0, i64* %t182
  store i64 %t179, i64* %t183
  store i1 false, i1* %t184
  store i64 -1, i64* %t185
  store i64 -1, i64* %t186
  store i1 false, i1* %t187
  br label %ht_probe_cond_33
ht_probe_cond_33:
  %t188 = load i64, i64* %t182
  %t189 = icmp slt i64 %t188, %t176
  br i1 %t189, label %ht_probe_body_34, label %ht_probe_end_44
ht_probe_body_34:
  %t190 = load i64, i64* %t183
  %t191 = getelementptr inbounds i8, i8* %t175, i64 %t190
  %t192 = load i8, i8* %t191
  %t193 = icmp eq i8 %t192, 0
  br i1 %t193, label %ht_probe_on_empty_36, label %ht_probe_check_occ_35
ht_probe_check_occ_35:
  %t194 = icmp eq i8 %t192, 1
  br i1 %t194, label %ht_probe_on_occ_39, label %ht_probe_on_tomb_41
ht_probe_on_empty_36:
  %t195 = load i1, i1* %t187
  br i1 %t195, label %ht_probe_after_islot_empty_38, label %ht_probe_set_islot_empty_37
ht_probe_set_islot_empty_37:
  store i64 %t190, i64* %t186
  store i1 true, i1* %t187
  br label %ht_probe_after_islot_empty_38
ht_probe_after_islot_empty_38:
  br label %ht_probe_end_44
ht_probe_on_occ_39:
  %t196 = getelementptr inbounds i8*, i8** %t173, i64 %t190
  %t197 = load i8*, i8** %t196
  %t198 = call i1 @eq_str(i8* %t197, i8* %t97)
  br i1 %t198, label %ht_probe_on_match_40, label %ht_probe_next_43
ht_probe_on_match_40:
  store i1 true, i1* %t184
  store i64 %t190, i64* %t185
  br label %ht_probe_end_44
ht_probe_on_tomb_41:
  %t199 = load i1, i1* %t187
  br i1 %t199, label %ht_probe_next_43, label %ht_probe_set_islot_tomb_42
ht_probe_set_islot_tomb_42:
  store i64 %t190, i64* %t186
  store i1 true, i1* %t187
  br label %ht_probe_next_43
ht_probe_next_43:
  %t200 = add i64 %t190, 1
  %t201 = and i64 %t200, %t177
  store i64 %t201, i64* %t183
  %t202 = add i64 %t188, 1
  store i64 %t202, i64* %t182
  br label %ht_probe_cond_33
ht_probe_end_44:
  %t203 = load i1, i1* %t184
  %t204 = load i64, i64* %t185
  %t205 = load i64, i64* %t186
  br i1 %t203, label %map_insert_overwrite_45, label %map_insert_new_46
map_insert_overwrite_45:
  store i8* %t97, i8** %t206
  %t207 = load i8*, i8** %t206
  call void @star_rc_release(i8* %t207)
  %t208 = getelementptr inbounds i32, i32* %t174, i64 %t204
  store i32 0, i32* %t208
  br label %map_insert_after_47
map_insert_new_46:
  %t209 = getelementptr inbounds i8, i8* %t175, i64 %t205
  %t210 = load i8, i8* %t209
  %t211 = icmp eq i8 %t210, 2
  br i1 %t211, label %map_insert_dec_tomb_48, label %map_insert_store_49
map_insert_dec_tomb_48:
  %t212 = load i64, i64* %t95
  %t213 = sub i64 %t212, 1
  store i64 %t213, i64* %t95
  br label %map_insert_store_49
map_insert_store_49:
  store i8 1, i8* %t209
  %t214 = getelementptr inbounds i8*, i8** %t173, i64 %t205
  store i8* %t97, i8** %t214
  %t215 = getelementptr inbounds i32, i32* %t174, i64 %t205
  store i32 0, i32* %t215
  %t216 = load i64, i64* %t91
  %t217 = add i64 %t216, 1
  store i64 %t217, i64* %t91
  br label %map_insert_after_47
map_insert_after_47:
  %t218 = getelementptr i8*, i8** null, i32 1
  %t219 = ptrtoint i8** %t218 to i64
  %t220 = getelementptr i32, i32* null, i32 1
  %t221 = ptrtoint i32* %t220 to i64
  %t222 = load i8*, i8** %t0
  %t223 = icmp eq i8* %t222, null
  br i1 %t223, label %map_cow_alloc_50, label %map_cow_check_51
map_cow_alloc_50:
  %t224 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t225 = call i8* @star_rc_alloc(i64 48, i8* %t224)
  %t226 = bitcast i8* %t225 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t227 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t226, i32 0, i32 0
  store i8** null, i8*** %t227
  %t228 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t226, i32 0, i32 1
  store i32* null, i32** %t228
  %t229 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t226, i32 0, i32 2
  store i8* null, i8** %t229
  %t230 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t226, i32 0, i32 3
  store i64 0, i64* %t230
  %t231 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t226, i32 0, i32 4
  store i64 0, i64* %t231
  %t232 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t226, i32 0, i32 5
  store i64 0, i64* %t232
  store i8* %t225, i8** %t0
  br label %map_cow_done_52
map_cow_check_51:
  %t233 = getelementptr inbounds i8, i8* %t222, i64 -16
  %t234 = bitcast i8* %t233 to i64*
  %t235 = load atomic i64, i64* %t234 seq_cst, align 8
  %t236 = icmp eq i64 %t235, 1
  br i1 %t236, label %map_cow_done_52, label %map_cow_clone_53
map_cow_clone_53:
  %t237 = bitcast i8* %t222 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t238 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t237, i32 0, i32 0
  %t239 = load i8**, i8*** %t238
  %t240 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t237, i32 0, i32 1
  %t241 = load i32*, i32** %t240
  %t242 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t237, i32 0, i32 2
  %t243 = load i8*, i8** %t242
  %t244 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t237, i32 0, i32 3
  %t245 = load i64, i64* %t244
  %t246 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t237, i32 0, i32 4
  %t247 = load i64, i64* %t246
  %t248 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t237, i32 0, i32 5
  %t249 = load i64, i64* %t248
  %t250 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t251 = call i8* @star_rc_alloc(i64 48, i8* %t250)
  %t252 = bitcast i8* %t251 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t253 = mul i64 %t247, %t219
  %t254 = call i8* @malloc(i64 %t253)
  %t255 = bitcast i8* %t254 to i8**
  %t256 = mul i64 %t247, %t221
  %t257 = call i8* @malloc(i64 %t256)
  %t258 = bitcast i8* %t257 to i32*
  %t259 = call i8* @malloc(i64 %t247)
  %t260 = icmp sgt i64 %t247, 0
  br i1 %t260, label %map_cow_copy_54, label %map_cow_after_copy_55
map_cow_copy_54:
  %t261 = mul i64 %t247, %t219
  %t262 = bitcast i8** %t239 to i8*
  call i8* @memcpy(i8* %t254, i8* %t262, i64 %t261)
  %t263 = mul i64 %t247, %t221
  %t264 = bitcast i32* %t241 to i8*
  call i8* @memcpy(i8* %t257, i8* %t264, i64 %t263)
  call i8* @memcpy(i8* %t259, i8* %t243, i64 %t247)
  store i64 0, i64* %t265
  br label %map_cow_retain_cond_56
map_cow_retain_cond_56:
  %t266 = load i64, i64* %t265
  %t267 = icmp slt i64 %t266, %t247
  br i1 %t267, label %map_cow_retain_body_57, label %map_cow_retain_end_60
map_cow_retain_body_57:
  %t268 = getelementptr inbounds i8, i8* %t259, i64 %t266
  %t269 = load i8, i8* %t268
  %t270 = icmp eq i8 %t269, 1
  br i1 %t270, label %map_cow_retain_occ_58, label %map_cow_retain_next_59
map_cow_retain_occ_58:
  %t271 = getelementptr inbounds i8*, i8** %t255, i64 %t266
  %t272 = load i8*, i8** %t271
  call void @star_rc_retain(i8* %t272)
  br label %map_cow_retain_next_59
map_cow_retain_next_59:
  %t273 = add i64 %t266, 1
  store i64 %t273, i64* %t265
  br label %map_cow_retain_cond_56
map_cow_retain_end_60:
  br label %map_cow_after_copy_55
map_cow_after_copy_55:
  %t274 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t252, i32 0, i32 0
  store i8** %t255, i8*** %t274
  %t275 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t252, i32 0, i32 1
  store i32* %t258, i32** %t275
  %t276 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t252, i32 0, i32 2
  store i8* %t259, i8** %t276
  %t277 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t252, i32 0, i32 3
  store i64 %t245, i64* %t277
  %t278 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t252, i32 0, i32 4
  store i64 %t247, i64* %t278
  %t279 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t252, i32 0, i32 5
  store i64 %t249, i64* %t279
  call void @star_rc_release(i8* %t222)
  store i8* %t251, i8** %t0
  br label %map_cow_done_52
map_cow_done_52:
  %t280 = load i8*, i8** %t0
  %t281 = bitcast i8* %t280 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t282 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t281, i32 0, i32 0
  %t283 = load i8**, i8*** %t282
  %t284 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t281, i32 0, i32 1
  %t285 = load i32*, i32** %t284
  %t286 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t281, i32 0, i32 2
  %t287 = load i8*, i8** %t286
  %t288 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t281, i32 0, i32 3
  %t289 = load i64, i64* %t288
  %t290 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t281, i32 0, i32 4
  %t291 = load i64, i64* %t290
  %t292 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t281, i32 0, i32 5
  %t293 = load i64, i64* %t292
  %t294 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t295 = load i64, i64* %t288
  %t296 = load i64, i64* %t290
  %t297 = load i64, i64* %t292
  %t298 = add i64 %t295, %t297
  %t299 = add i64 %t298, 1
  %t300 = mul i64 %t299, 4
  %t301 = mul i64 %t296, 3
  %t302 = icmp sgt i64 %t300, %t301
  br i1 %t302, label %map_insert_grow_61, label %map_insert_after_grow_62
map_insert_grow_61:
  %t303 = getelementptr i8*, i8** null, i32 1
  %t304 = ptrtoint i8** %t303 to i64
  %t305 = getelementptr i32, i32* null, i32 1
  %t306 = ptrtoint i32* %t305 to i64
  %t307 = mul i64 %t296, 2
  %t308 = icmp sgt i64 %t307, 0
  %t309 = select i1 %t308, i64 %t307, i64 8
  %t310 = sub i64 %t309, 1
  %t311 = mul i64 %t309, %t304
  %t312 = call i8* @malloc(i64 %t311)
  %t313 = bitcast i8* %t312 to i8**
  %t314 = mul i64 %t309, %t306
  %t315 = call i8* @malloc(i64 %t314)
  %t316 = bitcast i8* %t315 to i32*
  %t317 = call i8* @malloc(i64 %t309)
  store i64 0, i64* %t318
  br label %ht_fill8_cond_63
ht_fill8_cond_63:
  %t319 = load i64, i64* %t318
  %t320 = icmp slt i64 %t319, %t309
  br i1 %t320, label %ht_fill8_body_64, label %ht_fill8_end_65
ht_fill8_body_64:
  %t321 = getelementptr inbounds i8, i8* %t317, i64 %t319
  store i8 0, i8* %t321
  %t322 = add i64 %t319, 1
  store i64 %t322, i64* %t318
  br label %ht_fill8_cond_63
ht_fill8_end_65:
  %t323 = load i8**, i8*** %t282
  %t324 = load i32*, i32** %t284
  %t325 = load i8*, i8** %t286
  store i64 0, i64* %t326
  br label %map_grow_cond_66
map_grow_cond_66:
  %t327 = load i64, i64* %t326
  %t328 = icmp slt i64 %t327, %t296
  br i1 %t328, label %map_grow_body_67, label %map_grow_end_70
map_grow_body_67:
  %t329 = getelementptr inbounds i8, i8* %t325, i64 %t327
  %t330 = load i8, i8* %t329
  %t331 = icmp eq i8 %t330, 1
  br i1 %t331, label %map_grow_occ_68, label %map_grow_next_69
map_grow_occ_68:
  %t332 = getelementptr inbounds i8*, i8** %t323, i64 %t327
  %t333 = load i8*, i8** %t332
  %t334 = getelementptr inbounds i32, i32* %t324, i64 %t327
  %t335 = load i32, i32* %t334
  %t336 = call i64 @hash_str(i8* %t333)
  %t337 = and i64 %t336, %t310
  store i64 0, i64* %t338
  store i64 %t337, i64* %t339
  br label %ht_fe_cond_71
ht_fe_cond_71:
  %t340 = load i64, i64* %t338
  %t341 = icmp slt i64 %t340, %t309
  br i1 %t341, label %ht_fe_body_72, label %ht_fe_end_74
ht_fe_body_72:
  %t342 = load i64, i64* %t339
  %t343 = getelementptr inbounds i8, i8* %t317, i64 %t342
  %t344 = load i8, i8* %t343
  %t345 = icmp eq i8 %t344, 0
  br i1 %t345, label %ht_fe_end_74, label %ht_fe_next_73
ht_fe_next_73:
  %t346 = add i64 %t342, 1
  %t347 = and i64 %t346, %t310
  store i64 %t347, i64* %t339
  %t348 = add i64 %t340, 1
  store i64 %t348, i64* %t338
  br label %ht_fe_cond_71
ht_fe_end_74:
  %t349 = load i64, i64* %t339
  %t350 = getelementptr inbounds i8, i8* %t317, i64 %t349
  store i8 1, i8* %t350
  %t351 = getelementptr inbounds i8*, i8** %t313, i64 %t349
  store i8* %t333, i8** %t351
  %t352 = getelementptr inbounds i32, i32* %t316, i64 %t349
  store i32 %t335, i32* %t352
  br label %map_grow_next_69
map_grow_next_69:
  %t353 = add i64 %t327, 1
  store i64 %t353, i64* %t326
  br label %map_grow_cond_66
map_grow_end_70:
  %t354 = bitcast i8** %t323 to i8*
  call void @free(i8* %t354)
  %t355 = bitcast i32* %t324 to i8*
  call void @free(i8* %t355)
  call void @free(i8* %t325)
  store i8** %t313, i8*** %t282
  store i32* %t316, i32** %t284
  store i8* %t317, i8** %t286
  store i64 %t309, i64* %t290
  store i64 0, i64* %t292
  br label %map_insert_after_grow_62
map_insert_after_grow_62:
  %t356 = load i8**, i8*** %t282
  %t357 = load i32*, i32** %t284
  %t358 = load i8*, i8** %t286
  %t359 = load i64, i64* %t290
  %t360 = sub i64 %t359, 1
  %t361 = call i64 @hash_str(i8* %t294)
  %t362 = and i64 %t361, %t360
  store i64 0, i64* %t363
  store i64 %t362, i64* %t364
  store i1 false, i1* %t365
  store i64 -1, i64* %t366
  store i64 -1, i64* %t367
  store i1 false, i1* %t368
  br label %ht_probe_cond_75
ht_probe_cond_75:
  %t369 = load i64, i64* %t363
  %t370 = icmp slt i64 %t369, %t359
  br i1 %t370, label %ht_probe_body_76, label %ht_probe_end_86
ht_probe_body_76:
  %t371 = load i64, i64* %t364
  %t372 = getelementptr inbounds i8, i8* %t358, i64 %t371
  %t373 = load i8, i8* %t372
  %t374 = icmp eq i8 %t373, 0
  br i1 %t374, label %ht_probe_on_empty_78, label %ht_probe_check_occ_77
ht_probe_check_occ_77:
  %t375 = icmp eq i8 %t373, 1
  br i1 %t375, label %ht_probe_on_occ_81, label %ht_probe_on_tomb_83
ht_probe_on_empty_78:
  %t376 = load i1, i1* %t368
  br i1 %t376, label %ht_probe_after_islot_empty_80, label %ht_probe_set_islot_empty_79
ht_probe_set_islot_empty_79:
  store i64 %t371, i64* %t367
  store i1 true, i1* %t368
  br label %ht_probe_after_islot_empty_80
ht_probe_after_islot_empty_80:
  br label %ht_probe_end_86
ht_probe_on_occ_81:
  %t377 = getelementptr inbounds i8*, i8** %t356, i64 %t371
  %t378 = load i8*, i8** %t377
  %t379 = call i1 @eq_str(i8* %t378, i8* %t294)
  br i1 %t379, label %ht_probe_on_match_82, label %ht_probe_next_85
ht_probe_on_match_82:
  store i1 true, i1* %t365
  store i64 %t371, i64* %t366
  br label %ht_probe_end_86
ht_probe_on_tomb_83:
  %t380 = load i1, i1* %t368
  br i1 %t380, label %ht_probe_next_85, label %ht_probe_set_islot_tomb_84
ht_probe_set_islot_tomb_84:
  store i64 %t371, i64* %t367
  store i1 true, i1* %t368
  br label %ht_probe_next_85
ht_probe_next_85:
  %t381 = add i64 %t371, 1
  %t382 = and i64 %t381, %t360
  store i64 %t382, i64* %t364
  %t383 = add i64 %t369, 1
  store i64 %t383, i64* %t363
  br label %ht_probe_cond_75
ht_probe_end_86:
  %t384 = load i1, i1* %t365
  %t385 = load i64, i64* %t366
  %t386 = load i64, i64* %t367
  br i1 %t384, label %map_insert_overwrite_87, label %map_insert_new_88
map_insert_overwrite_87:
  store i8* %t294, i8** %t387
  %t388 = load i8*, i8** %t387
  call void @star_rc_release(i8* %t388)
  %t389 = getelementptr inbounds i32, i32* %t357, i64 %t385
  store i32 1, i32* %t389
  br label %map_insert_after_89
map_insert_new_88:
  %t390 = getelementptr inbounds i8, i8* %t358, i64 %t386
  %t391 = load i8, i8* %t390
  %t392 = icmp eq i8 %t391, 2
  br i1 %t392, label %map_insert_dec_tomb_90, label %map_insert_store_91
map_insert_dec_tomb_90:
  %t393 = load i64, i64* %t292
  %t394 = sub i64 %t393, 1
  store i64 %t394, i64* %t292
  br label %map_insert_store_91
map_insert_store_91:
  store i8 1, i8* %t390
  %t395 = getelementptr inbounds i8*, i8** %t356, i64 %t386
  store i8* %t294, i8** %t395
  %t396 = getelementptr inbounds i32, i32* %t357, i64 %t386
  store i32 1, i32* %t396
  %t397 = load i64, i64* %t288
  %t398 = add i64 %t397, 1
  store i64 %t398, i64* %t288
  br label %map_insert_after_89
map_insert_after_89:
  %t399 = getelementptr i8*, i8** null, i32 1
  %t400 = ptrtoint i8** %t399 to i64
  %t401 = getelementptr i32, i32* null, i32 1
  %t402 = ptrtoint i32* %t401 to i64
  %t403 = load i8*, i8** %t0
  %t404 = icmp eq i8* %t403, null
  br i1 %t404, label %map_cow_alloc_92, label %map_cow_check_93
map_cow_alloc_92:
  %t405 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t406 = call i8* @star_rc_alloc(i64 48, i8* %t405)
  %t407 = bitcast i8* %t406 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t408 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t407, i32 0, i32 0
  store i8** null, i8*** %t408
  %t409 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t407, i32 0, i32 1
  store i32* null, i32** %t409
  %t410 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t407, i32 0, i32 2
  store i8* null, i8** %t410
  %t411 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t407, i32 0, i32 3
  store i64 0, i64* %t411
  %t412 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t407, i32 0, i32 4
  store i64 0, i64* %t412
  %t413 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t407, i32 0, i32 5
  store i64 0, i64* %t413
  store i8* %t406, i8** %t0
  br label %map_cow_done_94
map_cow_check_93:
  %t414 = getelementptr inbounds i8, i8* %t403, i64 -16
  %t415 = bitcast i8* %t414 to i64*
  %t416 = load atomic i64, i64* %t415 seq_cst, align 8
  %t417 = icmp eq i64 %t416, 1
  br i1 %t417, label %map_cow_done_94, label %map_cow_clone_95
map_cow_clone_95:
  %t418 = bitcast i8* %t403 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t419 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t418, i32 0, i32 0
  %t420 = load i8**, i8*** %t419
  %t421 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t418, i32 0, i32 1
  %t422 = load i32*, i32** %t421
  %t423 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t418, i32 0, i32 2
  %t424 = load i8*, i8** %t423
  %t425 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t418, i32 0, i32 3
  %t426 = load i64, i64* %t425
  %t427 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t418, i32 0, i32 4
  %t428 = load i64, i64* %t427
  %t429 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t418, i32 0, i32 5
  %t430 = load i64, i64* %t429
  %t431 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t432 = call i8* @star_rc_alloc(i64 48, i8* %t431)
  %t433 = bitcast i8* %t432 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t434 = mul i64 %t428, %t400
  %t435 = call i8* @malloc(i64 %t434)
  %t436 = bitcast i8* %t435 to i8**
  %t437 = mul i64 %t428, %t402
  %t438 = call i8* @malloc(i64 %t437)
  %t439 = bitcast i8* %t438 to i32*
  %t440 = call i8* @malloc(i64 %t428)
  %t441 = icmp sgt i64 %t428, 0
  br i1 %t441, label %map_cow_copy_96, label %map_cow_after_copy_97
map_cow_copy_96:
  %t442 = mul i64 %t428, %t400
  %t443 = bitcast i8** %t420 to i8*
  call i8* @memcpy(i8* %t435, i8* %t443, i64 %t442)
  %t444 = mul i64 %t428, %t402
  %t445 = bitcast i32* %t422 to i8*
  call i8* @memcpy(i8* %t438, i8* %t445, i64 %t444)
  call i8* @memcpy(i8* %t440, i8* %t424, i64 %t428)
  store i64 0, i64* %t446
  br label %map_cow_retain_cond_98
map_cow_retain_cond_98:
  %t447 = load i64, i64* %t446
  %t448 = icmp slt i64 %t447, %t428
  br i1 %t448, label %map_cow_retain_body_99, label %map_cow_retain_end_102
map_cow_retain_body_99:
  %t449 = getelementptr inbounds i8, i8* %t440, i64 %t447
  %t450 = load i8, i8* %t449
  %t451 = icmp eq i8 %t450, 1
  br i1 %t451, label %map_cow_retain_occ_100, label %map_cow_retain_next_101
map_cow_retain_occ_100:
  %t452 = getelementptr inbounds i8*, i8** %t436, i64 %t447
  %t453 = load i8*, i8** %t452
  call void @star_rc_retain(i8* %t453)
  br label %map_cow_retain_next_101
map_cow_retain_next_101:
  %t454 = add i64 %t447, 1
  store i64 %t454, i64* %t446
  br label %map_cow_retain_cond_98
map_cow_retain_end_102:
  br label %map_cow_after_copy_97
map_cow_after_copy_97:
  %t455 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t433, i32 0, i32 0
  store i8** %t436, i8*** %t455
  %t456 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t433, i32 0, i32 1
  store i32* %t439, i32** %t456
  %t457 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t433, i32 0, i32 2
  store i8* %t440, i8** %t457
  %t458 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t433, i32 0, i32 3
  store i64 %t426, i64* %t458
  %t459 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t433, i32 0, i32 4
  store i64 %t428, i64* %t459
  %t460 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t433, i32 0, i32 5
  store i64 %t430, i64* %t460
  call void @star_rc_release(i8* %t403)
  store i8* %t432, i8** %t0
  br label %map_cow_done_94
map_cow_done_94:
  %t461 = load i8*, i8** %t0
  %t462 = bitcast i8* %t461 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t463 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t462, i32 0, i32 0
  %t464 = load i8**, i8*** %t463
  %t465 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t462, i32 0, i32 1
  %t466 = load i32*, i32** %t465
  %t467 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t462, i32 0, i32 2
  %t468 = load i8*, i8** %t467
  %t469 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t462, i32 0, i32 3
  %t470 = load i64, i64* %t469
  %t471 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t462, i32 0, i32 4
  %t472 = load i64, i64* %t471
  %t473 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t462, i32 0, i32 5
  %t474 = load i64, i64* %t473
  %t475 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t476 = load i64, i64* %t469
  %t477 = load i64, i64* %t471
  %t478 = load i64, i64* %t473
  %t479 = add i64 %t476, %t478
  %t480 = add i64 %t479, 1
  %t481 = mul i64 %t480, 4
  %t482 = mul i64 %t477, 3
  %t483 = icmp sgt i64 %t481, %t482
  br i1 %t483, label %map_insert_grow_103, label %map_insert_after_grow_104
map_insert_grow_103:
  %t484 = getelementptr i8*, i8** null, i32 1
  %t485 = ptrtoint i8** %t484 to i64
  %t486 = getelementptr i32, i32* null, i32 1
  %t487 = ptrtoint i32* %t486 to i64
  %t488 = mul i64 %t477, 2
  %t489 = icmp sgt i64 %t488, 0
  %t490 = select i1 %t489, i64 %t488, i64 8
  %t491 = sub i64 %t490, 1
  %t492 = mul i64 %t490, %t485
  %t493 = call i8* @malloc(i64 %t492)
  %t494 = bitcast i8* %t493 to i8**
  %t495 = mul i64 %t490, %t487
  %t496 = call i8* @malloc(i64 %t495)
  %t497 = bitcast i8* %t496 to i32*
  %t498 = call i8* @malloc(i64 %t490)
  store i64 0, i64* %t499
  br label %ht_fill8_cond_105
ht_fill8_cond_105:
  %t500 = load i64, i64* %t499
  %t501 = icmp slt i64 %t500, %t490
  br i1 %t501, label %ht_fill8_body_106, label %ht_fill8_end_107
ht_fill8_body_106:
  %t502 = getelementptr inbounds i8, i8* %t498, i64 %t500
  store i8 0, i8* %t502
  %t503 = add i64 %t500, 1
  store i64 %t503, i64* %t499
  br label %ht_fill8_cond_105
ht_fill8_end_107:
  %t504 = load i8**, i8*** %t463
  %t505 = load i32*, i32** %t465
  %t506 = load i8*, i8** %t467
  store i64 0, i64* %t507
  br label %map_grow_cond_108
map_grow_cond_108:
  %t508 = load i64, i64* %t507
  %t509 = icmp slt i64 %t508, %t477
  br i1 %t509, label %map_grow_body_109, label %map_grow_end_112
map_grow_body_109:
  %t510 = getelementptr inbounds i8, i8* %t506, i64 %t508
  %t511 = load i8, i8* %t510
  %t512 = icmp eq i8 %t511, 1
  br i1 %t512, label %map_grow_occ_110, label %map_grow_next_111
map_grow_occ_110:
  %t513 = getelementptr inbounds i8*, i8** %t504, i64 %t508
  %t514 = load i8*, i8** %t513
  %t515 = getelementptr inbounds i32, i32* %t505, i64 %t508
  %t516 = load i32, i32* %t515
  %t517 = call i64 @hash_str(i8* %t514)
  %t518 = and i64 %t517, %t491
  store i64 0, i64* %t519
  store i64 %t518, i64* %t520
  br label %ht_fe_cond_113
ht_fe_cond_113:
  %t521 = load i64, i64* %t519
  %t522 = icmp slt i64 %t521, %t490
  br i1 %t522, label %ht_fe_body_114, label %ht_fe_end_116
ht_fe_body_114:
  %t523 = load i64, i64* %t520
  %t524 = getelementptr inbounds i8, i8* %t498, i64 %t523
  %t525 = load i8, i8* %t524
  %t526 = icmp eq i8 %t525, 0
  br i1 %t526, label %ht_fe_end_116, label %ht_fe_next_115
ht_fe_next_115:
  %t527 = add i64 %t523, 1
  %t528 = and i64 %t527, %t491
  store i64 %t528, i64* %t520
  %t529 = add i64 %t521, 1
  store i64 %t529, i64* %t519
  br label %ht_fe_cond_113
ht_fe_end_116:
  %t530 = load i64, i64* %t520
  %t531 = getelementptr inbounds i8, i8* %t498, i64 %t530
  store i8 1, i8* %t531
  %t532 = getelementptr inbounds i8*, i8** %t494, i64 %t530
  store i8* %t514, i8** %t532
  %t533 = getelementptr inbounds i32, i32* %t497, i64 %t530
  store i32 %t516, i32* %t533
  br label %map_grow_next_111
map_grow_next_111:
  %t534 = add i64 %t508, 1
  store i64 %t534, i64* %t507
  br label %map_grow_cond_108
map_grow_end_112:
  %t535 = bitcast i8** %t504 to i8*
  call void @free(i8* %t535)
  %t536 = bitcast i32* %t505 to i8*
  call void @free(i8* %t536)
  call void @free(i8* %t506)
  store i8** %t494, i8*** %t463
  store i32* %t497, i32** %t465
  store i8* %t498, i8** %t467
  store i64 %t490, i64* %t471
  store i64 0, i64* %t473
  br label %map_insert_after_grow_104
map_insert_after_grow_104:
  %t537 = load i8**, i8*** %t463
  %t538 = load i32*, i32** %t465
  %t539 = load i8*, i8** %t467
  %t540 = load i64, i64* %t471
  %t541 = sub i64 %t540, 1
  %t542 = call i64 @hash_str(i8* %t475)
  %t543 = and i64 %t542, %t541
  store i64 0, i64* %t544
  store i64 %t543, i64* %t545
  store i1 false, i1* %t546
  store i64 -1, i64* %t547
  store i64 -1, i64* %t548
  store i1 false, i1* %t549
  br label %ht_probe_cond_117
ht_probe_cond_117:
  %t550 = load i64, i64* %t544
  %t551 = icmp slt i64 %t550, %t540
  br i1 %t551, label %ht_probe_body_118, label %ht_probe_end_128
ht_probe_body_118:
  %t552 = load i64, i64* %t545
  %t553 = getelementptr inbounds i8, i8* %t539, i64 %t552
  %t554 = load i8, i8* %t553
  %t555 = icmp eq i8 %t554, 0
  br i1 %t555, label %ht_probe_on_empty_120, label %ht_probe_check_occ_119
ht_probe_check_occ_119:
  %t556 = icmp eq i8 %t554, 1
  br i1 %t556, label %ht_probe_on_occ_123, label %ht_probe_on_tomb_125
ht_probe_on_empty_120:
  %t557 = load i1, i1* %t549
  br i1 %t557, label %ht_probe_after_islot_empty_122, label %ht_probe_set_islot_empty_121
ht_probe_set_islot_empty_121:
  store i64 %t552, i64* %t548
  store i1 true, i1* %t549
  br label %ht_probe_after_islot_empty_122
ht_probe_after_islot_empty_122:
  br label %ht_probe_end_128
ht_probe_on_occ_123:
  %t558 = getelementptr inbounds i8*, i8** %t537, i64 %t552
  %t559 = load i8*, i8** %t558
  %t560 = call i1 @eq_str(i8* %t559, i8* %t475)
  br i1 %t560, label %ht_probe_on_match_124, label %ht_probe_next_127
ht_probe_on_match_124:
  store i1 true, i1* %t546
  store i64 %t552, i64* %t547
  br label %ht_probe_end_128
ht_probe_on_tomb_125:
  %t561 = load i1, i1* %t549
  br i1 %t561, label %ht_probe_next_127, label %ht_probe_set_islot_tomb_126
ht_probe_set_islot_tomb_126:
  store i64 %t552, i64* %t548
  store i1 true, i1* %t549
  br label %ht_probe_next_127
ht_probe_next_127:
  %t562 = add i64 %t552, 1
  %t563 = and i64 %t562, %t541
  store i64 %t563, i64* %t545
  %t564 = add i64 %t550, 1
  store i64 %t564, i64* %t544
  br label %ht_probe_cond_117
ht_probe_end_128:
  %t565 = load i1, i1* %t546
  %t566 = load i64, i64* %t547
  %t567 = load i64, i64* %t548
  br i1 %t565, label %map_insert_overwrite_129, label %map_insert_new_130
map_insert_overwrite_129:
  store i8* %t475, i8** %t568
  %t569 = load i8*, i8** %t568
  call void @star_rc_release(i8* %t569)
  %t570 = getelementptr inbounds i32, i32* %t538, i64 %t566
  store i32 2, i32* %t570
  br label %map_insert_after_131
map_insert_new_130:
  %t571 = getelementptr inbounds i8, i8* %t539, i64 %t567
  %t572 = load i8, i8* %t571
  %t573 = icmp eq i8 %t572, 2
  br i1 %t573, label %map_insert_dec_tomb_132, label %map_insert_store_133
map_insert_dec_tomb_132:
  %t574 = load i64, i64* %t473
  %t575 = sub i64 %t574, 1
  store i64 %t575, i64* %t473
  br label %map_insert_store_133
map_insert_store_133:
  store i8 1, i8* %t571
  %t576 = getelementptr inbounds i8*, i8** %t537, i64 %t567
  store i8* %t475, i8** %t576
  %t577 = getelementptr inbounds i32, i32* %t538, i64 %t567
  store i32 2, i32* %t577
  %t578 = load i64, i64* %t469
  %t579 = add i64 %t578, 1
  store i64 %t579, i64* %t469
  br label %map_insert_after_131
map_insert_after_131:
  %t580 = getelementptr i8*, i8** null, i32 1
  %t581 = ptrtoint i8** %t580 to i64
  %t582 = getelementptr i32, i32* null, i32 1
  %t583 = ptrtoint i32* %t582 to i64
  %t584 = load i8*, i8** %t0
  %t585 = icmp eq i8* %t584, null
  br i1 %t585, label %map_cow_alloc_134, label %map_cow_check_135
map_cow_alloc_134:
  %t586 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t587 = call i8* @star_rc_alloc(i64 48, i8* %t586)
  %t588 = bitcast i8* %t587 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t589 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t588, i32 0, i32 0
  store i8** null, i8*** %t589
  %t590 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t588, i32 0, i32 1
  store i32* null, i32** %t590
  %t591 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t588, i32 0, i32 2
  store i8* null, i8** %t591
  %t592 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t588, i32 0, i32 3
  store i64 0, i64* %t592
  %t593 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t588, i32 0, i32 4
  store i64 0, i64* %t593
  %t594 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t588, i32 0, i32 5
  store i64 0, i64* %t594
  store i8* %t587, i8** %t0
  br label %map_cow_done_136
map_cow_check_135:
  %t595 = getelementptr inbounds i8, i8* %t584, i64 -16
  %t596 = bitcast i8* %t595 to i64*
  %t597 = load atomic i64, i64* %t596 seq_cst, align 8
  %t598 = icmp eq i64 %t597, 1
  br i1 %t598, label %map_cow_done_136, label %map_cow_clone_137
map_cow_clone_137:
  %t599 = bitcast i8* %t584 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t600 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t599, i32 0, i32 0
  %t601 = load i8**, i8*** %t600
  %t602 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t599, i32 0, i32 1
  %t603 = load i32*, i32** %t602
  %t604 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t599, i32 0, i32 2
  %t605 = load i8*, i8** %t604
  %t606 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t599, i32 0, i32 3
  %t607 = load i64, i64* %t606
  %t608 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t599, i32 0, i32 4
  %t609 = load i64, i64* %t608
  %t610 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t599, i32 0, i32 5
  %t611 = load i64, i64* %t610
  %t612 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t613 = call i8* @star_rc_alloc(i64 48, i8* %t612)
  %t614 = bitcast i8* %t613 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t615 = mul i64 %t609, %t581
  %t616 = call i8* @malloc(i64 %t615)
  %t617 = bitcast i8* %t616 to i8**
  %t618 = mul i64 %t609, %t583
  %t619 = call i8* @malloc(i64 %t618)
  %t620 = bitcast i8* %t619 to i32*
  %t621 = call i8* @malloc(i64 %t609)
  %t622 = icmp sgt i64 %t609, 0
  br i1 %t622, label %map_cow_copy_138, label %map_cow_after_copy_139
map_cow_copy_138:
  %t623 = mul i64 %t609, %t581
  %t624 = bitcast i8** %t601 to i8*
  call i8* @memcpy(i8* %t616, i8* %t624, i64 %t623)
  %t625 = mul i64 %t609, %t583
  %t626 = bitcast i32* %t603 to i8*
  call i8* @memcpy(i8* %t619, i8* %t626, i64 %t625)
  call i8* @memcpy(i8* %t621, i8* %t605, i64 %t609)
  store i64 0, i64* %t627
  br label %map_cow_retain_cond_140
map_cow_retain_cond_140:
  %t628 = load i64, i64* %t627
  %t629 = icmp slt i64 %t628, %t609
  br i1 %t629, label %map_cow_retain_body_141, label %map_cow_retain_end_144
map_cow_retain_body_141:
  %t630 = getelementptr inbounds i8, i8* %t621, i64 %t628
  %t631 = load i8, i8* %t630
  %t632 = icmp eq i8 %t631, 1
  br i1 %t632, label %map_cow_retain_occ_142, label %map_cow_retain_next_143
map_cow_retain_occ_142:
  %t633 = getelementptr inbounds i8*, i8** %t617, i64 %t628
  %t634 = load i8*, i8** %t633
  call void @star_rc_retain(i8* %t634)
  br label %map_cow_retain_next_143
map_cow_retain_next_143:
  %t635 = add i64 %t628, 1
  store i64 %t635, i64* %t627
  br label %map_cow_retain_cond_140
map_cow_retain_end_144:
  br label %map_cow_after_copy_139
map_cow_after_copy_139:
  %t636 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t614, i32 0, i32 0
  store i8** %t617, i8*** %t636
  %t637 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t614, i32 0, i32 1
  store i32* %t620, i32** %t637
  %t638 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t614, i32 0, i32 2
  store i8* %t621, i8** %t638
  %t639 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t614, i32 0, i32 3
  store i64 %t607, i64* %t639
  %t640 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t614, i32 0, i32 4
  store i64 %t609, i64* %t640
  %t641 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t614, i32 0, i32 5
  store i64 %t611, i64* %t641
  call void @star_rc_release(i8* %t584)
  store i8* %t613, i8** %t0
  br label %map_cow_done_136
map_cow_done_136:
  %t642 = load i8*, i8** %t0
  %t643 = bitcast i8* %t642 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t644 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t643, i32 0, i32 0
  %t645 = load i8**, i8*** %t644
  %t646 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t643, i32 0, i32 1
  %t647 = load i32*, i32** %t646
  %t648 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t643, i32 0, i32 2
  %t649 = load i8*, i8** %t648
  %t650 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t643, i32 0, i32 3
  %t651 = load i64, i64* %t650
  %t652 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t643, i32 0, i32 4
  %t653 = load i64, i64* %t652
  %t654 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t643, i32 0, i32 5
  %t655 = load i64, i64* %t654
  %t656 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t657 = load i64, i64* %t650
  %t658 = load i64, i64* %t652
  %t659 = load i64, i64* %t654
  %t660 = add i64 %t657, %t659
  %t661 = add i64 %t660, 1
  %t662 = mul i64 %t661, 4
  %t663 = mul i64 %t658, 3
  %t664 = icmp sgt i64 %t662, %t663
  br i1 %t664, label %map_insert_grow_145, label %map_insert_after_grow_146
map_insert_grow_145:
  %t665 = getelementptr i8*, i8** null, i32 1
  %t666 = ptrtoint i8** %t665 to i64
  %t667 = getelementptr i32, i32* null, i32 1
  %t668 = ptrtoint i32* %t667 to i64
  %t669 = mul i64 %t658, 2
  %t670 = icmp sgt i64 %t669, 0
  %t671 = select i1 %t670, i64 %t669, i64 8
  %t672 = sub i64 %t671, 1
  %t673 = mul i64 %t671, %t666
  %t674 = call i8* @malloc(i64 %t673)
  %t675 = bitcast i8* %t674 to i8**
  %t676 = mul i64 %t671, %t668
  %t677 = call i8* @malloc(i64 %t676)
  %t678 = bitcast i8* %t677 to i32*
  %t679 = call i8* @malloc(i64 %t671)
  store i64 0, i64* %t680
  br label %ht_fill8_cond_147
ht_fill8_cond_147:
  %t681 = load i64, i64* %t680
  %t682 = icmp slt i64 %t681, %t671
  br i1 %t682, label %ht_fill8_body_148, label %ht_fill8_end_149
ht_fill8_body_148:
  %t683 = getelementptr inbounds i8, i8* %t679, i64 %t681
  store i8 0, i8* %t683
  %t684 = add i64 %t681, 1
  store i64 %t684, i64* %t680
  br label %ht_fill8_cond_147
ht_fill8_end_149:
  %t685 = load i8**, i8*** %t644
  %t686 = load i32*, i32** %t646
  %t687 = load i8*, i8** %t648
  store i64 0, i64* %t688
  br label %map_grow_cond_150
map_grow_cond_150:
  %t689 = load i64, i64* %t688
  %t690 = icmp slt i64 %t689, %t658
  br i1 %t690, label %map_grow_body_151, label %map_grow_end_154
map_grow_body_151:
  %t691 = getelementptr inbounds i8, i8* %t687, i64 %t689
  %t692 = load i8, i8* %t691
  %t693 = icmp eq i8 %t692, 1
  br i1 %t693, label %map_grow_occ_152, label %map_grow_next_153
map_grow_occ_152:
  %t694 = getelementptr inbounds i8*, i8** %t685, i64 %t689
  %t695 = load i8*, i8** %t694
  %t696 = getelementptr inbounds i32, i32* %t686, i64 %t689
  %t697 = load i32, i32* %t696
  %t698 = call i64 @hash_str(i8* %t695)
  %t699 = and i64 %t698, %t672
  store i64 0, i64* %t700
  store i64 %t699, i64* %t701
  br label %ht_fe_cond_155
ht_fe_cond_155:
  %t702 = load i64, i64* %t700
  %t703 = icmp slt i64 %t702, %t671
  br i1 %t703, label %ht_fe_body_156, label %ht_fe_end_158
ht_fe_body_156:
  %t704 = load i64, i64* %t701
  %t705 = getelementptr inbounds i8, i8* %t679, i64 %t704
  %t706 = load i8, i8* %t705
  %t707 = icmp eq i8 %t706, 0
  br i1 %t707, label %ht_fe_end_158, label %ht_fe_next_157
ht_fe_next_157:
  %t708 = add i64 %t704, 1
  %t709 = and i64 %t708, %t672
  store i64 %t709, i64* %t701
  %t710 = add i64 %t702, 1
  store i64 %t710, i64* %t700
  br label %ht_fe_cond_155
ht_fe_end_158:
  %t711 = load i64, i64* %t701
  %t712 = getelementptr inbounds i8, i8* %t679, i64 %t711
  store i8 1, i8* %t712
  %t713 = getelementptr inbounds i8*, i8** %t675, i64 %t711
  store i8* %t695, i8** %t713
  %t714 = getelementptr inbounds i32, i32* %t678, i64 %t711
  store i32 %t697, i32* %t714
  br label %map_grow_next_153
map_grow_next_153:
  %t715 = add i64 %t689, 1
  store i64 %t715, i64* %t688
  br label %map_grow_cond_150
map_grow_end_154:
  %t716 = bitcast i8** %t685 to i8*
  call void @free(i8* %t716)
  %t717 = bitcast i32* %t686 to i8*
  call void @free(i8* %t717)
  call void @free(i8* %t687)
  store i8** %t675, i8*** %t644
  store i32* %t678, i32** %t646
  store i8* %t679, i8** %t648
  store i64 %t671, i64* %t652
  store i64 0, i64* %t654
  br label %map_insert_after_grow_146
map_insert_after_grow_146:
  %t718 = load i8**, i8*** %t644
  %t719 = load i32*, i32** %t646
  %t720 = load i8*, i8** %t648
  %t721 = load i64, i64* %t652
  %t722 = sub i64 %t721, 1
  %t723 = call i64 @hash_str(i8* %t656)
  %t724 = and i64 %t723, %t722
  store i64 0, i64* %t725
  store i64 %t724, i64* %t726
  store i1 false, i1* %t727
  store i64 -1, i64* %t728
  store i64 -1, i64* %t729
  store i1 false, i1* %t730
  br label %ht_probe_cond_159
ht_probe_cond_159:
  %t731 = load i64, i64* %t725
  %t732 = icmp slt i64 %t731, %t721
  br i1 %t732, label %ht_probe_body_160, label %ht_probe_end_170
ht_probe_body_160:
  %t733 = load i64, i64* %t726
  %t734 = getelementptr inbounds i8, i8* %t720, i64 %t733
  %t735 = load i8, i8* %t734
  %t736 = icmp eq i8 %t735, 0
  br i1 %t736, label %ht_probe_on_empty_162, label %ht_probe_check_occ_161
ht_probe_check_occ_161:
  %t737 = icmp eq i8 %t735, 1
  br i1 %t737, label %ht_probe_on_occ_165, label %ht_probe_on_tomb_167
ht_probe_on_empty_162:
  %t738 = load i1, i1* %t730
  br i1 %t738, label %ht_probe_after_islot_empty_164, label %ht_probe_set_islot_empty_163
ht_probe_set_islot_empty_163:
  store i64 %t733, i64* %t729
  store i1 true, i1* %t730
  br label %ht_probe_after_islot_empty_164
ht_probe_after_islot_empty_164:
  br label %ht_probe_end_170
ht_probe_on_occ_165:
  %t739 = getelementptr inbounds i8*, i8** %t718, i64 %t733
  %t740 = load i8*, i8** %t739
  %t741 = call i1 @eq_str(i8* %t740, i8* %t656)
  br i1 %t741, label %ht_probe_on_match_166, label %ht_probe_next_169
ht_probe_on_match_166:
  store i1 true, i1* %t727
  store i64 %t733, i64* %t728
  br label %ht_probe_end_170
ht_probe_on_tomb_167:
  %t742 = load i1, i1* %t730
  br i1 %t742, label %ht_probe_next_169, label %ht_probe_set_islot_tomb_168
ht_probe_set_islot_tomb_168:
  store i64 %t733, i64* %t729
  store i1 true, i1* %t730
  br label %ht_probe_next_169
ht_probe_next_169:
  %t743 = add i64 %t733, 1
  %t744 = and i64 %t743, %t722
  store i64 %t744, i64* %t726
  %t745 = add i64 %t731, 1
  store i64 %t745, i64* %t725
  br label %ht_probe_cond_159
ht_probe_end_170:
  %t746 = load i1, i1* %t727
  %t747 = load i64, i64* %t728
  %t748 = load i64, i64* %t729
  br i1 %t746, label %map_insert_overwrite_171, label %map_insert_new_172
map_insert_overwrite_171:
  store i8* %t656, i8** %t749
  %t750 = load i8*, i8** %t749
  call void @star_rc_release(i8* %t750)
  %t751 = getelementptr inbounds i32, i32* %t719, i64 %t747
  store i32 3, i32* %t751
  br label %map_insert_after_173
map_insert_new_172:
  %t752 = getelementptr inbounds i8, i8* %t720, i64 %t748
  %t753 = load i8, i8* %t752
  %t754 = icmp eq i8 %t753, 2
  br i1 %t754, label %map_insert_dec_tomb_174, label %map_insert_store_175
map_insert_dec_tomb_174:
  %t755 = load i64, i64* %t654
  %t756 = sub i64 %t755, 1
  store i64 %t756, i64* %t654
  br label %map_insert_store_175
map_insert_store_175:
  store i8 1, i8* %t752
  %t757 = getelementptr inbounds i8*, i8** %t718, i64 %t748
  store i8* %t656, i8** %t757
  %t758 = getelementptr inbounds i32, i32* %t719, i64 %t748
  store i32 3, i32* %t758
  %t759 = load i64, i64* %t650
  %t760 = add i64 %t759, 1
  store i64 %t760, i64* %t650
  br label %map_insert_after_173
map_insert_after_173:
  %t761 = getelementptr i8*, i8** null, i32 1
  %t762 = ptrtoint i8** %t761 to i64
  %t763 = getelementptr i32, i32* null, i32 1
  %t764 = ptrtoint i32* %t763 to i64
  %t765 = load i8*, i8** %t0
  %t766 = icmp eq i8* %t765, null
  br i1 %t766, label %map_cow_alloc_176, label %map_cow_check_177
map_cow_alloc_176:
  %t767 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t768 = call i8* @star_rc_alloc(i64 48, i8* %t767)
  %t769 = bitcast i8* %t768 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t770 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t769, i32 0, i32 0
  store i8** null, i8*** %t770
  %t771 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t769, i32 0, i32 1
  store i32* null, i32** %t771
  %t772 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t769, i32 0, i32 2
  store i8* null, i8** %t772
  %t773 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t769, i32 0, i32 3
  store i64 0, i64* %t773
  %t774 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t769, i32 0, i32 4
  store i64 0, i64* %t774
  %t775 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t769, i32 0, i32 5
  store i64 0, i64* %t775
  store i8* %t768, i8** %t0
  br label %map_cow_done_178
map_cow_check_177:
  %t776 = getelementptr inbounds i8, i8* %t765, i64 -16
  %t777 = bitcast i8* %t776 to i64*
  %t778 = load atomic i64, i64* %t777 seq_cst, align 8
  %t779 = icmp eq i64 %t778, 1
  br i1 %t779, label %map_cow_done_178, label %map_cow_clone_179
map_cow_clone_179:
  %t780 = bitcast i8* %t765 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t781 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t780, i32 0, i32 0
  %t782 = load i8**, i8*** %t781
  %t783 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t780, i32 0, i32 1
  %t784 = load i32*, i32** %t783
  %t785 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t780, i32 0, i32 2
  %t786 = load i8*, i8** %t785
  %t787 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t780, i32 0, i32 3
  %t788 = load i64, i64* %t787
  %t789 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t780, i32 0, i32 4
  %t790 = load i64, i64* %t789
  %t791 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t780, i32 0, i32 5
  %t792 = load i64, i64* %t791
  %t793 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t794 = call i8* @star_rc_alloc(i64 48, i8* %t793)
  %t795 = bitcast i8* %t794 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t796 = mul i64 %t790, %t762
  %t797 = call i8* @malloc(i64 %t796)
  %t798 = bitcast i8* %t797 to i8**
  %t799 = mul i64 %t790, %t764
  %t800 = call i8* @malloc(i64 %t799)
  %t801 = bitcast i8* %t800 to i32*
  %t802 = call i8* @malloc(i64 %t790)
  %t803 = icmp sgt i64 %t790, 0
  br i1 %t803, label %map_cow_copy_180, label %map_cow_after_copy_181
map_cow_copy_180:
  %t804 = mul i64 %t790, %t762
  %t805 = bitcast i8** %t782 to i8*
  call i8* @memcpy(i8* %t797, i8* %t805, i64 %t804)
  %t806 = mul i64 %t790, %t764
  %t807 = bitcast i32* %t784 to i8*
  call i8* @memcpy(i8* %t800, i8* %t807, i64 %t806)
  call i8* @memcpy(i8* %t802, i8* %t786, i64 %t790)
  store i64 0, i64* %t808
  br label %map_cow_retain_cond_182
map_cow_retain_cond_182:
  %t809 = load i64, i64* %t808
  %t810 = icmp slt i64 %t809, %t790
  br i1 %t810, label %map_cow_retain_body_183, label %map_cow_retain_end_186
map_cow_retain_body_183:
  %t811 = getelementptr inbounds i8, i8* %t802, i64 %t809
  %t812 = load i8, i8* %t811
  %t813 = icmp eq i8 %t812, 1
  br i1 %t813, label %map_cow_retain_occ_184, label %map_cow_retain_next_185
map_cow_retain_occ_184:
  %t814 = getelementptr inbounds i8*, i8** %t798, i64 %t809
  %t815 = load i8*, i8** %t814
  call void @star_rc_retain(i8* %t815)
  br label %map_cow_retain_next_185
map_cow_retain_next_185:
  %t816 = add i64 %t809, 1
  store i64 %t816, i64* %t808
  br label %map_cow_retain_cond_182
map_cow_retain_end_186:
  br label %map_cow_after_copy_181
map_cow_after_copy_181:
  %t817 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t795, i32 0, i32 0
  store i8** %t798, i8*** %t817
  %t818 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t795, i32 0, i32 1
  store i32* %t801, i32** %t818
  %t819 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t795, i32 0, i32 2
  store i8* %t802, i8** %t819
  %t820 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t795, i32 0, i32 3
  store i64 %t788, i64* %t820
  %t821 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t795, i32 0, i32 4
  store i64 %t790, i64* %t821
  %t822 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t795, i32 0, i32 5
  store i64 %t792, i64* %t822
  call void @star_rc_release(i8* %t765)
  store i8* %t794, i8** %t0
  br label %map_cow_done_178
map_cow_done_178:
  %t823 = load i8*, i8** %t0
  %t824 = bitcast i8* %t823 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t825 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t824, i32 0, i32 0
  %t826 = load i8**, i8*** %t825
  %t827 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t824, i32 0, i32 1
  %t828 = load i32*, i32** %t827
  %t829 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t824, i32 0, i32 2
  %t830 = load i8*, i8** %t829
  %t831 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t824, i32 0, i32 3
  %t832 = load i64, i64* %t831
  %t833 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t824, i32 0, i32 4
  %t834 = load i64, i64* %t833
  %t835 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t824, i32 0, i32 5
  %t836 = load i64, i64* %t835
  %t837 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.4, i64 0, i32 2, i64 0
  %t838 = load i64, i64* %t831
  %t839 = load i64, i64* %t833
  %t840 = load i64, i64* %t835
  %t841 = add i64 %t838, %t840
  %t842 = add i64 %t841, 1
  %t843 = mul i64 %t842, 4
  %t844 = mul i64 %t839, 3
  %t845 = icmp sgt i64 %t843, %t844
  br i1 %t845, label %map_insert_grow_187, label %map_insert_after_grow_188
map_insert_grow_187:
  %t846 = getelementptr i8*, i8** null, i32 1
  %t847 = ptrtoint i8** %t846 to i64
  %t848 = getelementptr i32, i32* null, i32 1
  %t849 = ptrtoint i32* %t848 to i64
  %t850 = mul i64 %t839, 2
  %t851 = icmp sgt i64 %t850, 0
  %t852 = select i1 %t851, i64 %t850, i64 8
  %t853 = sub i64 %t852, 1
  %t854 = mul i64 %t852, %t847
  %t855 = call i8* @malloc(i64 %t854)
  %t856 = bitcast i8* %t855 to i8**
  %t857 = mul i64 %t852, %t849
  %t858 = call i8* @malloc(i64 %t857)
  %t859 = bitcast i8* %t858 to i32*
  %t860 = call i8* @malloc(i64 %t852)
  store i64 0, i64* %t861
  br label %ht_fill8_cond_189
ht_fill8_cond_189:
  %t862 = load i64, i64* %t861
  %t863 = icmp slt i64 %t862, %t852
  br i1 %t863, label %ht_fill8_body_190, label %ht_fill8_end_191
ht_fill8_body_190:
  %t864 = getelementptr inbounds i8, i8* %t860, i64 %t862
  store i8 0, i8* %t864
  %t865 = add i64 %t862, 1
  store i64 %t865, i64* %t861
  br label %ht_fill8_cond_189
ht_fill8_end_191:
  %t866 = load i8**, i8*** %t825
  %t867 = load i32*, i32** %t827
  %t868 = load i8*, i8** %t829
  store i64 0, i64* %t869
  br label %map_grow_cond_192
map_grow_cond_192:
  %t870 = load i64, i64* %t869
  %t871 = icmp slt i64 %t870, %t839
  br i1 %t871, label %map_grow_body_193, label %map_grow_end_196
map_grow_body_193:
  %t872 = getelementptr inbounds i8, i8* %t868, i64 %t870
  %t873 = load i8, i8* %t872
  %t874 = icmp eq i8 %t873, 1
  br i1 %t874, label %map_grow_occ_194, label %map_grow_next_195
map_grow_occ_194:
  %t875 = getelementptr inbounds i8*, i8** %t866, i64 %t870
  %t876 = load i8*, i8** %t875
  %t877 = getelementptr inbounds i32, i32* %t867, i64 %t870
  %t878 = load i32, i32* %t877
  %t879 = call i64 @hash_str(i8* %t876)
  %t880 = and i64 %t879, %t853
  store i64 0, i64* %t881
  store i64 %t880, i64* %t882
  br label %ht_fe_cond_197
ht_fe_cond_197:
  %t883 = load i64, i64* %t881
  %t884 = icmp slt i64 %t883, %t852
  br i1 %t884, label %ht_fe_body_198, label %ht_fe_end_200
ht_fe_body_198:
  %t885 = load i64, i64* %t882
  %t886 = getelementptr inbounds i8, i8* %t860, i64 %t885
  %t887 = load i8, i8* %t886
  %t888 = icmp eq i8 %t887, 0
  br i1 %t888, label %ht_fe_end_200, label %ht_fe_next_199
ht_fe_next_199:
  %t889 = add i64 %t885, 1
  %t890 = and i64 %t889, %t853
  store i64 %t890, i64* %t882
  %t891 = add i64 %t883, 1
  store i64 %t891, i64* %t881
  br label %ht_fe_cond_197
ht_fe_end_200:
  %t892 = load i64, i64* %t882
  %t893 = getelementptr inbounds i8, i8* %t860, i64 %t892
  store i8 1, i8* %t893
  %t894 = getelementptr inbounds i8*, i8** %t856, i64 %t892
  store i8* %t876, i8** %t894
  %t895 = getelementptr inbounds i32, i32* %t859, i64 %t892
  store i32 %t878, i32* %t895
  br label %map_grow_next_195
map_grow_next_195:
  %t896 = add i64 %t870, 1
  store i64 %t896, i64* %t869
  br label %map_grow_cond_192
map_grow_end_196:
  %t897 = bitcast i8** %t866 to i8*
  call void @free(i8* %t897)
  %t898 = bitcast i32* %t867 to i8*
  call void @free(i8* %t898)
  call void @free(i8* %t868)
  store i8** %t856, i8*** %t825
  store i32* %t859, i32** %t827
  store i8* %t860, i8** %t829
  store i64 %t852, i64* %t833
  store i64 0, i64* %t835
  br label %map_insert_after_grow_188
map_insert_after_grow_188:
  %t899 = load i8**, i8*** %t825
  %t900 = load i32*, i32** %t827
  %t901 = load i8*, i8** %t829
  %t902 = load i64, i64* %t833
  %t903 = sub i64 %t902, 1
  %t904 = call i64 @hash_str(i8* %t837)
  %t905 = and i64 %t904, %t903
  store i64 0, i64* %t906
  store i64 %t905, i64* %t907
  store i1 false, i1* %t908
  store i64 -1, i64* %t909
  store i64 -1, i64* %t910
  store i1 false, i1* %t911
  br label %ht_probe_cond_201
ht_probe_cond_201:
  %t912 = load i64, i64* %t906
  %t913 = icmp slt i64 %t912, %t902
  br i1 %t913, label %ht_probe_body_202, label %ht_probe_end_212
ht_probe_body_202:
  %t914 = load i64, i64* %t907
  %t915 = getelementptr inbounds i8, i8* %t901, i64 %t914
  %t916 = load i8, i8* %t915
  %t917 = icmp eq i8 %t916, 0
  br i1 %t917, label %ht_probe_on_empty_204, label %ht_probe_check_occ_203
ht_probe_check_occ_203:
  %t918 = icmp eq i8 %t916, 1
  br i1 %t918, label %ht_probe_on_occ_207, label %ht_probe_on_tomb_209
ht_probe_on_empty_204:
  %t919 = load i1, i1* %t911
  br i1 %t919, label %ht_probe_after_islot_empty_206, label %ht_probe_set_islot_empty_205
ht_probe_set_islot_empty_205:
  store i64 %t914, i64* %t910
  store i1 true, i1* %t911
  br label %ht_probe_after_islot_empty_206
ht_probe_after_islot_empty_206:
  br label %ht_probe_end_212
ht_probe_on_occ_207:
  %t920 = getelementptr inbounds i8*, i8** %t899, i64 %t914
  %t921 = load i8*, i8** %t920
  %t922 = call i1 @eq_str(i8* %t921, i8* %t837)
  br i1 %t922, label %ht_probe_on_match_208, label %ht_probe_next_211
ht_probe_on_match_208:
  store i1 true, i1* %t908
  store i64 %t914, i64* %t909
  br label %ht_probe_end_212
ht_probe_on_tomb_209:
  %t923 = load i1, i1* %t911
  br i1 %t923, label %ht_probe_next_211, label %ht_probe_set_islot_tomb_210
ht_probe_set_islot_tomb_210:
  store i64 %t914, i64* %t910
  store i1 true, i1* %t911
  br label %ht_probe_next_211
ht_probe_next_211:
  %t924 = add i64 %t914, 1
  %t925 = and i64 %t924, %t903
  store i64 %t925, i64* %t907
  %t926 = add i64 %t912, 1
  store i64 %t926, i64* %t906
  br label %ht_probe_cond_201
ht_probe_end_212:
  %t927 = load i1, i1* %t908
  %t928 = load i64, i64* %t909
  %t929 = load i64, i64* %t910
  br i1 %t927, label %map_insert_overwrite_213, label %map_insert_new_214
map_insert_overwrite_213:
  store i8* %t837, i8** %t930
  %t931 = load i8*, i8** %t930
  call void @star_rc_release(i8* %t931)
  %t932 = getelementptr inbounds i32, i32* %t900, i64 %t928
  store i32 4, i32* %t932
  br label %map_insert_after_215
map_insert_new_214:
  %t933 = getelementptr inbounds i8, i8* %t901, i64 %t929
  %t934 = load i8, i8* %t933
  %t935 = icmp eq i8 %t934, 2
  br i1 %t935, label %map_insert_dec_tomb_216, label %map_insert_store_217
map_insert_dec_tomb_216:
  %t936 = load i64, i64* %t835
  %t937 = sub i64 %t936, 1
  store i64 %t937, i64* %t835
  br label %map_insert_store_217
map_insert_store_217:
  store i8 1, i8* %t933
  %t938 = getelementptr inbounds i8*, i8** %t899, i64 %t929
  store i8* %t837, i8** %t938
  %t939 = getelementptr inbounds i32, i32* %t900, i64 %t929
  store i32 4, i32* %t939
  %t940 = load i64, i64* %t831
  %t941 = add i64 %t940, 1
  store i64 %t941, i64* %t831
  br label %map_insert_after_215
map_insert_after_215:
  %t942 = getelementptr i8*, i8** null, i32 1
  %t943 = ptrtoint i8** %t942 to i64
  %t944 = getelementptr i32, i32* null, i32 1
  %t945 = ptrtoint i32* %t944 to i64
  %t946 = load i8*, i8** %t0
  %t947 = icmp eq i8* %t946, null
  br i1 %t947, label %map_cow_alloc_218, label %map_cow_check_219
map_cow_alloc_218:
  %t948 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t949 = call i8* @star_rc_alloc(i64 48, i8* %t948)
  %t950 = bitcast i8* %t949 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t951 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t950, i32 0, i32 0
  store i8** null, i8*** %t951
  %t952 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t950, i32 0, i32 1
  store i32* null, i32** %t952
  %t953 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t950, i32 0, i32 2
  store i8* null, i8** %t953
  %t954 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t950, i32 0, i32 3
  store i64 0, i64* %t954
  %t955 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t950, i32 0, i32 4
  store i64 0, i64* %t955
  %t956 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t950, i32 0, i32 5
  store i64 0, i64* %t956
  store i8* %t949, i8** %t0
  br label %map_cow_done_220
map_cow_check_219:
  %t957 = getelementptr inbounds i8, i8* %t946, i64 -16
  %t958 = bitcast i8* %t957 to i64*
  %t959 = load atomic i64, i64* %t958 seq_cst, align 8
  %t960 = icmp eq i64 %t959, 1
  br i1 %t960, label %map_cow_done_220, label %map_cow_clone_221
map_cow_clone_221:
  %t961 = bitcast i8* %t946 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t962 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t961, i32 0, i32 0
  %t963 = load i8**, i8*** %t962
  %t964 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t961, i32 0, i32 1
  %t965 = load i32*, i32** %t964
  %t966 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t961, i32 0, i32 2
  %t967 = load i8*, i8** %t966
  %t968 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t961, i32 0, i32 3
  %t969 = load i64, i64* %t968
  %t970 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t961, i32 0, i32 4
  %t971 = load i64, i64* %t970
  %t972 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t961, i32 0, i32 5
  %t973 = load i64, i64* %t972
  %t974 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t975 = call i8* @star_rc_alloc(i64 48, i8* %t974)
  %t976 = bitcast i8* %t975 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t977 = mul i64 %t971, %t943
  %t978 = call i8* @malloc(i64 %t977)
  %t979 = bitcast i8* %t978 to i8**
  %t980 = mul i64 %t971, %t945
  %t981 = call i8* @malloc(i64 %t980)
  %t982 = bitcast i8* %t981 to i32*
  %t983 = call i8* @malloc(i64 %t971)
  %t984 = icmp sgt i64 %t971, 0
  br i1 %t984, label %map_cow_copy_222, label %map_cow_after_copy_223
map_cow_copy_222:
  %t985 = mul i64 %t971, %t943
  %t986 = bitcast i8** %t963 to i8*
  call i8* @memcpy(i8* %t978, i8* %t986, i64 %t985)
  %t987 = mul i64 %t971, %t945
  %t988 = bitcast i32* %t965 to i8*
  call i8* @memcpy(i8* %t981, i8* %t988, i64 %t987)
  call i8* @memcpy(i8* %t983, i8* %t967, i64 %t971)
  store i64 0, i64* %t989
  br label %map_cow_retain_cond_224
map_cow_retain_cond_224:
  %t990 = load i64, i64* %t989
  %t991 = icmp slt i64 %t990, %t971
  br i1 %t991, label %map_cow_retain_body_225, label %map_cow_retain_end_228
map_cow_retain_body_225:
  %t992 = getelementptr inbounds i8, i8* %t983, i64 %t990
  %t993 = load i8, i8* %t992
  %t994 = icmp eq i8 %t993, 1
  br i1 %t994, label %map_cow_retain_occ_226, label %map_cow_retain_next_227
map_cow_retain_occ_226:
  %t995 = getelementptr inbounds i8*, i8** %t979, i64 %t990
  %t996 = load i8*, i8** %t995
  call void @star_rc_retain(i8* %t996)
  br label %map_cow_retain_next_227
map_cow_retain_next_227:
  %t997 = add i64 %t990, 1
  store i64 %t997, i64* %t989
  br label %map_cow_retain_cond_224
map_cow_retain_end_228:
  br label %map_cow_after_copy_223
map_cow_after_copy_223:
  %t998 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t976, i32 0, i32 0
  store i8** %t979, i8*** %t998
  %t999 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t976, i32 0, i32 1
  store i32* %t982, i32** %t999
  %t1000 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t976, i32 0, i32 2
  store i8* %t983, i8** %t1000
  %t1001 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t976, i32 0, i32 3
  store i64 %t969, i64* %t1001
  %t1002 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t976, i32 0, i32 4
  store i64 %t971, i64* %t1002
  %t1003 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t976, i32 0, i32 5
  store i64 %t973, i64* %t1003
  call void @star_rc_release(i8* %t946)
  store i8* %t975, i8** %t0
  br label %map_cow_done_220
map_cow_done_220:
  %t1004 = load i8*, i8** %t0
  %t1005 = bitcast i8* %t1004 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1006 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1005, i32 0, i32 0
  %t1007 = load i8**, i8*** %t1006
  %t1008 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1005, i32 0, i32 1
  %t1009 = load i32*, i32** %t1008
  %t1010 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1005, i32 0, i32 2
  %t1011 = load i8*, i8** %t1010
  %t1012 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1005, i32 0, i32 3
  %t1013 = load i64, i64* %t1012
  %t1014 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1005, i32 0, i32 4
  %t1015 = load i64, i64* %t1014
  %t1016 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1005, i32 0, i32 5
  %t1017 = load i64, i64* %t1016
  %t1018 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.5, i64 0, i32 2, i64 0
  %t1019 = load i64, i64* %t1012
  %t1020 = load i64, i64* %t1014
  %t1021 = load i64, i64* %t1016
  %t1022 = add i64 %t1019, %t1021
  %t1023 = add i64 %t1022, 1
  %t1024 = mul i64 %t1023, 4
  %t1025 = mul i64 %t1020, 3
  %t1026 = icmp sgt i64 %t1024, %t1025
  br i1 %t1026, label %map_insert_grow_229, label %map_insert_after_grow_230
map_insert_grow_229:
  %t1027 = getelementptr i8*, i8** null, i32 1
  %t1028 = ptrtoint i8** %t1027 to i64
  %t1029 = getelementptr i32, i32* null, i32 1
  %t1030 = ptrtoint i32* %t1029 to i64
  %t1031 = mul i64 %t1020, 2
  %t1032 = icmp sgt i64 %t1031, 0
  %t1033 = select i1 %t1032, i64 %t1031, i64 8
  %t1034 = sub i64 %t1033, 1
  %t1035 = mul i64 %t1033, %t1028
  %t1036 = call i8* @malloc(i64 %t1035)
  %t1037 = bitcast i8* %t1036 to i8**
  %t1038 = mul i64 %t1033, %t1030
  %t1039 = call i8* @malloc(i64 %t1038)
  %t1040 = bitcast i8* %t1039 to i32*
  %t1041 = call i8* @malloc(i64 %t1033)
  store i64 0, i64* %t1042
  br label %ht_fill8_cond_231
ht_fill8_cond_231:
  %t1043 = load i64, i64* %t1042
  %t1044 = icmp slt i64 %t1043, %t1033
  br i1 %t1044, label %ht_fill8_body_232, label %ht_fill8_end_233
ht_fill8_body_232:
  %t1045 = getelementptr inbounds i8, i8* %t1041, i64 %t1043
  store i8 0, i8* %t1045
  %t1046 = add i64 %t1043, 1
  store i64 %t1046, i64* %t1042
  br label %ht_fill8_cond_231
ht_fill8_end_233:
  %t1047 = load i8**, i8*** %t1006
  %t1048 = load i32*, i32** %t1008
  %t1049 = load i8*, i8** %t1010
  store i64 0, i64* %t1050
  br label %map_grow_cond_234
map_grow_cond_234:
  %t1051 = load i64, i64* %t1050
  %t1052 = icmp slt i64 %t1051, %t1020
  br i1 %t1052, label %map_grow_body_235, label %map_grow_end_238
map_grow_body_235:
  %t1053 = getelementptr inbounds i8, i8* %t1049, i64 %t1051
  %t1054 = load i8, i8* %t1053
  %t1055 = icmp eq i8 %t1054, 1
  br i1 %t1055, label %map_grow_occ_236, label %map_grow_next_237
map_grow_occ_236:
  %t1056 = getelementptr inbounds i8*, i8** %t1047, i64 %t1051
  %t1057 = load i8*, i8** %t1056
  %t1058 = getelementptr inbounds i32, i32* %t1048, i64 %t1051
  %t1059 = load i32, i32* %t1058
  %t1060 = call i64 @hash_str(i8* %t1057)
  %t1061 = and i64 %t1060, %t1034
  store i64 0, i64* %t1062
  store i64 %t1061, i64* %t1063
  br label %ht_fe_cond_239
ht_fe_cond_239:
  %t1064 = load i64, i64* %t1062
  %t1065 = icmp slt i64 %t1064, %t1033
  br i1 %t1065, label %ht_fe_body_240, label %ht_fe_end_242
ht_fe_body_240:
  %t1066 = load i64, i64* %t1063
  %t1067 = getelementptr inbounds i8, i8* %t1041, i64 %t1066
  %t1068 = load i8, i8* %t1067
  %t1069 = icmp eq i8 %t1068, 0
  br i1 %t1069, label %ht_fe_end_242, label %ht_fe_next_241
ht_fe_next_241:
  %t1070 = add i64 %t1066, 1
  %t1071 = and i64 %t1070, %t1034
  store i64 %t1071, i64* %t1063
  %t1072 = add i64 %t1064, 1
  store i64 %t1072, i64* %t1062
  br label %ht_fe_cond_239
ht_fe_end_242:
  %t1073 = load i64, i64* %t1063
  %t1074 = getelementptr inbounds i8, i8* %t1041, i64 %t1073
  store i8 1, i8* %t1074
  %t1075 = getelementptr inbounds i8*, i8** %t1037, i64 %t1073
  store i8* %t1057, i8** %t1075
  %t1076 = getelementptr inbounds i32, i32* %t1040, i64 %t1073
  store i32 %t1059, i32* %t1076
  br label %map_grow_next_237
map_grow_next_237:
  %t1077 = add i64 %t1051, 1
  store i64 %t1077, i64* %t1050
  br label %map_grow_cond_234
map_grow_end_238:
  %t1078 = bitcast i8** %t1047 to i8*
  call void @free(i8* %t1078)
  %t1079 = bitcast i32* %t1048 to i8*
  call void @free(i8* %t1079)
  call void @free(i8* %t1049)
  store i8** %t1037, i8*** %t1006
  store i32* %t1040, i32** %t1008
  store i8* %t1041, i8** %t1010
  store i64 %t1033, i64* %t1014
  store i64 0, i64* %t1016
  br label %map_insert_after_grow_230
map_insert_after_grow_230:
  %t1080 = load i8**, i8*** %t1006
  %t1081 = load i32*, i32** %t1008
  %t1082 = load i8*, i8** %t1010
  %t1083 = load i64, i64* %t1014
  %t1084 = sub i64 %t1083, 1
  %t1085 = call i64 @hash_str(i8* %t1018)
  %t1086 = and i64 %t1085, %t1084
  store i64 0, i64* %t1087
  store i64 %t1086, i64* %t1088
  store i1 false, i1* %t1089
  store i64 -1, i64* %t1090
  store i64 -1, i64* %t1091
  store i1 false, i1* %t1092
  br label %ht_probe_cond_243
ht_probe_cond_243:
  %t1093 = load i64, i64* %t1087
  %t1094 = icmp slt i64 %t1093, %t1083
  br i1 %t1094, label %ht_probe_body_244, label %ht_probe_end_254
ht_probe_body_244:
  %t1095 = load i64, i64* %t1088
  %t1096 = getelementptr inbounds i8, i8* %t1082, i64 %t1095
  %t1097 = load i8, i8* %t1096
  %t1098 = icmp eq i8 %t1097, 0
  br i1 %t1098, label %ht_probe_on_empty_246, label %ht_probe_check_occ_245
ht_probe_check_occ_245:
  %t1099 = icmp eq i8 %t1097, 1
  br i1 %t1099, label %ht_probe_on_occ_249, label %ht_probe_on_tomb_251
ht_probe_on_empty_246:
  %t1100 = load i1, i1* %t1092
  br i1 %t1100, label %ht_probe_after_islot_empty_248, label %ht_probe_set_islot_empty_247
ht_probe_set_islot_empty_247:
  store i64 %t1095, i64* %t1091
  store i1 true, i1* %t1092
  br label %ht_probe_after_islot_empty_248
ht_probe_after_islot_empty_248:
  br label %ht_probe_end_254
ht_probe_on_occ_249:
  %t1101 = getelementptr inbounds i8*, i8** %t1080, i64 %t1095
  %t1102 = load i8*, i8** %t1101
  %t1103 = call i1 @eq_str(i8* %t1102, i8* %t1018)
  br i1 %t1103, label %ht_probe_on_match_250, label %ht_probe_next_253
ht_probe_on_match_250:
  store i1 true, i1* %t1089
  store i64 %t1095, i64* %t1090
  br label %ht_probe_end_254
ht_probe_on_tomb_251:
  %t1104 = load i1, i1* %t1092
  br i1 %t1104, label %ht_probe_next_253, label %ht_probe_set_islot_tomb_252
ht_probe_set_islot_tomb_252:
  store i64 %t1095, i64* %t1091
  store i1 true, i1* %t1092
  br label %ht_probe_next_253
ht_probe_next_253:
  %t1105 = add i64 %t1095, 1
  %t1106 = and i64 %t1105, %t1084
  store i64 %t1106, i64* %t1088
  %t1107 = add i64 %t1093, 1
  store i64 %t1107, i64* %t1087
  br label %ht_probe_cond_243
ht_probe_end_254:
  %t1108 = load i1, i1* %t1089
  %t1109 = load i64, i64* %t1090
  %t1110 = load i64, i64* %t1091
  br i1 %t1108, label %map_insert_overwrite_255, label %map_insert_new_256
map_insert_overwrite_255:
  store i8* %t1018, i8** %t1111
  %t1112 = load i8*, i8** %t1111
  call void @star_rc_release(i8* %t1112)
  %t1113 = getelementptr inbounds i32, i32* %t1081, i64 %t1109
  store i32 5, i32* %t1113
  br label %map_insert_after_257
map_insert_new_256:
  %t1114 = getelementptr inbounds i8, i8* %t1082, i64 %t1110
  %t1115 = load i8, i8* %t1114
  %t1116 = icmp eq i8 %t1115, 2
  br i1 %t1116, label %map_insert_dec_tomb_258, label %map_insert_store_259
map_insert_dec_tomb_258:
  %t1117 = load i64, i64* %t1016
  %t1118 = sub i64 %t1117, 1
  store i64 %t1118, i64* %t1016
  br label %map_insert_store_259
map_insert_store_259:
  store i8 1, i8* %t1114
  %t1119 = getelementptr inbounds i8*, i8** %t1080, i64 %t1110
  store i8* %t1018, i8** %t1119
  %t1120 = getelementptr inbounds i32, i32* %t1081, i64 %t1110
  store i32 5, i32* %t1120
  %t1121 = load i64, i64* %t1012
  %t1122 = add i64 %t1121, 1
  store i64 %t1122, i64* %t1012
  br label %map_insert_after_257
map_insert_after_257:
  %t1123 = getelementptr i8*, i8** null, i32 1
  %t1124 = ptrtoint i8** %t1123 to i64
  %t1125 = getelementptr i32, i32* null, i32 1
  %t1126 = ptrtoint i32* %t1125 to i64
  %t1127 = load i8*, i8** %t0
  %t1128 = icmp eq i8* %t1127, null
  br i1 %t1128, label %map_cow_alloc_260, label %map_cow_check_261
map_cow_alloc_260:
  %t1129 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1130 = call i8* @star_rc_alloc(i64 48, i8* %t1129)
  %t1131 = bitcast i8* %t1130 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1132 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1131, i32 0, i32 0
  store i8** null, i8*** %t1132
  %t1133 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1131, i32 0, i32 1
  store i32* null, i32** %t1133
  %t1134 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1131, i32 0, i32 2
  store i8* null, i8** %t1134
  %t1135 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1131, i32 0, i32 3
  store i64 0, i64* %t1135
  %t1136 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1131, i32 0, i32 4
  store i64 0, i64* %t1136
  %t1137 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1131, i32 0, i32 5
  store i64 0, i64* %t1137
  store i8* %t1130, i8** %t0
  br label %map_cow_done_262
map_cow_check_261:
  %t1138 = getelementptr inbounds i8, i8* %t1127, i64 -16
  %t1139 = bitcast i8* %t1138 to i64*
  %t1140 = load atomic i64, i64* %t1139 seq_cst, align 8
  %t1141 = icmp eq i64 %t1140, 1
  br i1 %t1141, label %map_cow_done_262, label %map_cow_clone_263
map_cow_clone_263:
  %t1142 = bitcast i8* %t1127 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1143 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1142, i32 0, i32 0
  %t1144 = load i8**, i8*** %t1143
  %t1145 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1142, i32 0, i32 1
  %t1146 = load i32*, i32** %t1145
  %t1147 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1142, i32 0, i32 2
  %t1148 = load i8*, i8** %t1147
  %t1149 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1142, i32 0, i32 3
  %t1150 = load i64, i64* %t1149
  %t1151 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1142, i32 0, i32 4
  %t1152 = load i64, i64* %t1151
  %t1153 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1142, i32 0, i32 5
  %t1154 = load i64, i64* %t1153
  %t1155 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1156 = call i8* @star_rc_alloc(i64 48, i8* %t1155)
  %t1157 = bitcast i8* %t1156 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1158 = mul i64 %t1152, %t1124
  %t1159 = call i8* @malloc(i64 %t1158)
  %t1160 = bitcast i8* %t1159 to i8**
  %t1161 = mul i64 %t1152, %t1126
  %t1162 = call i8* @malloc(i64 %t1161)
  %t1163 = bitcast i8* %t1162 to i32*
  %t1164 = call i8* @malloc(i64 %t1152)
  %t1165 = icmp sgt i64 %t1152, 0
  br i1 %t1165, label %map_cow_copy_264, label %map_cow_after_copy_265
map_cow_copy_264:
  %t1166 = mul i64 %t1152, %t1124
  %t1167 = bitcast i8** %t1144 to i8*
  call i8* @memcpy(i8* %t1159, i8* %t1167, i64 %t1166)
  %t1168 = mul i64 %t1152, %t1126
  %t1169 = bitcast i32* %t1146 to i8*
  call i8* @memcpy(i8* %t1162, i8* %t1169, i64 %t1168)
  call i8* @memcpy(i8* %t1164, i8* %t1148, i64 %t1152)
  store i64 0, i64* %t1170
  br label %map_cow_retain_cond_266
map_cow_retain_cond_266:
  %t1171 = load i64, i64* %t1170
  %t1172 = icmp slt i64 %t1171, %t1152
  br i1 %t1172, label %map_cow_retain_body_267, label %map_cow_retain_end_270
map_cow_retain_body_267:
  %t1173 = getelementptr inbounds i8, i8* %t1164, i64 %t1171
  %t1174 = load i8, i8* %t1173
  %t1175 = icmp eq i8 %t1174, 1
  br i1 %t1175, label %map_cow_retain_occ_268, label %map_cow_retain_next_269
map_cow_retain_occ_268:
  %t1176 = getelementptr inbounds i8*, i8** %t1160, i64 %t1171
  %t1177 = load i8*, i8** %t1176
  call void @star_rc_retain(i8* %t1177)
  br label %map_cow_retain_next_269
map_cow_retain_next_269:
  %t1178 = add i64 %t1171, 1
  store i64 %t1178, i64* %t1170
  br label %map_cow_retain_cond_266
map_cow_retain_end_270:
  br label %map_cow_after_copy_265
map_cow_after_copy_265:
  %t1179 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1157, i32 0, i32 0
  store i8** %t1160, i8*** %t1179
  %t1180 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1157, i32 0, i32 1
  store i32* %t1163, i32** %t1180
  %t1181 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1157, i32 0, i32 2
  store i8* %t1164, i8** %t1181
  %t1182 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1157, i32 0, i32 3
  store i64 %t1150, i64* %t1182
  %t1183 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1157, i32 0, i32 4
  store i64 %t1152, i64* %t1183
  %t1184 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1157, i32 0, i32 5
  store i64 %t1154, i64* %t1184
  call void @star_rc_release(i8* %t1127)
  store i8* %t1156, i8** %t0
  br label %map_cow_done_262
map_cow_done_262:
  %t1185 = load i8*, i8** %t0
  %t1186 = bitcast i8* %t1185 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1187 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1186, i32 0, i32 0
  %t1188 = load i8**, i8*** %t1187
  %t1189 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1186, i32 0, i32 1
  %t1190 = load i32*, i32** %t1189
  %t1191 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1186, i32 0, i32 2
  %t1192 = load i8*, i8** %t1191
  %t1193 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1186, i32 0, i32 3
  %t1194 = load i64, i64* %t1193
  %t1195 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1186, i32 0, i32 4
  %t1196 = load i64, i64* %t1195
  %t1197 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1186, i32 0, i32 5
  %t1198 = load i64, i64* %t1197
  %t1199 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.6, i64 0, i32 2, i64 0
  %t1200 = load i64, i64* %t1193
  %t1201 = load i64, i64* %t1195
  %t1202 = load i64, i64* %t1197
  %t1203 = add i64 %t1200, %t1202
  %t1204 = add i64 %t1203, 1
  %t1205 = mul i64 %t1204, 4
  %t1206 = mul i64 %t1201, 3
  %t1207 = icmp sgt i64 %t1205, %t1206
  br i1 %t1207, label %map_insert_grow_271, label %map_insert_after_grow_272
map_insert_grow_271:
  %t1208 = getelementptr i8*, i8** null, i32 1
  %t1209 = ptrtoint i8** %t1208 to i64
  %t1210 = getelementptr i32, i32* null, i32 1
  %t1211 = ptrtoint i32* %t1210 to i64
  %t1212 = mul i64 %t1201, 2
  %t1213 = icmp sgt i64 %t1212, 0
  %t1214 = select i1 %t1213, i64 %t1212, i64 8
  %t1215 = sub i64 %t1214, 1
  %t1216 = mul i64 %t1214, %t1209
  %t1217 = call i8* @malloc(i64 %t1216)
  %t1218 = bitcast i8* %t1217 to i8**
  %t1219 = mul i64 %t1214, %t1211
  %t1220 = call i8* @malloc(i64 %t1219)
  %t1221 = bitcast i8* %t1220 to i32*
  %t1222 = call i8* @malloc(i64 %t1214)
  store i64 0, i64* %t1223
  br label %ht_fill8_cond_273
ht_fill8_cond_273:
  %t1224 = load i64, i64* %t1223
  %t1225 = icmp slt i64 %t1224, %t1214
  br i1 %t1225, label %ht_fill8_body_274, label %ht_fill8_end_275
ht_fill8_body_274:
  %t1226 = getelementptr inbounds i8, i8* %t1222, i64 %t1224
  store i8 0, i8* %t1226
  %t1227 = add i64 %t1224, 1
  store i64 %t1227, i64* %t1223
  br label %ht_fill8_cond_273
ht_fill8_end_275:
  %t1228 = load i8**, i8*** %t1187
  %t1229 = load i32*, i32** %t1189
  %t1230 = load i8*, i8** %t1191
  store i64 0, i64* %t1231
  br label %map_grow_cond_276
map_grow_cond_276:
  %t1232 = load i64, i64* %t1231
  %t1233 = icmp slt i64 %t1232, %t1201
  br i1 %t1233, label %map_grow_body_277, label %map_grow_end_280
map_grow_body_277:
  %t1234 = getelementptr inbounds i8, i8* %t1230, i64 %t1232
  %t1235 = load i8, i8* %t1234
  %t1236 = icmp eq i8 %t1235, 1
  br i1 %t1236, label %map_grow_occ_278, label %map_grow_next_279
map_grow_occ_278:
  %t1237 = getelementptr inbounds i8*, i8** %t1228, i64 %t1232
  %t1238 = load i8*, i8** %t1237
  %t1239 = getelementptr inbounds i32, i32* %t1229, i64 %t1232
  %t1240 = load i32, i32* %t1239
  %t1241 = call i64 @hash_str(i8* %t1238)
  %t1242 = and i64 %t1241, %t1215
  store i64 0, i64* %t1243
  store i64 %t1242, i64* %t1244
  br label %ht_fe_cond_281
ht_fe_cond_281:
  %t1245 = load i64, i64* %t1243
  %t1246 = icmp slt i64 %t1245, %t1214
  br i1 %t1246, label %ht_fe_body_282, label %ht_fe_end_284
ht_fe_body_282:
  %t1247 = load i64, i64* %t1244
  %t1248 = getelementptr inbounds i8, i8* %t1222, i64 %t1247
  %t1249 = load i8, i8* %t1248
  %t1250 = icmp eq i8 %t1249, 0
  br i1 %t1250, label %ht_fe_end_284, label %ht_fe_next_283
ht_fe_next_283:
  %t1251 = add i64 %t1247, 1
  %t1252 = and i64 %t1251, %t1215
  store i64 %t1252, i64* %t1244
  %t1253 = add i64 %t1245, 1
  store i64 %t1253, i64* %t1243
  br label %ht_fe_cond_281
ht_fe_end_284:
  %t1254 = load i64, i64* %t1244
  %t1255 = getelementptr inbounds i8, i8* %t1222, i64 %t1254
  store i8 1, i8* %t1255
  %t1256 = getelementptr inbounds i8*, i8** %t1218, i64 %t1254
  store i8* %t1238, i8** %t1256
  %t1257 = getelementptr inbounds i32, i32* %t1221, i64 %t1254
  store i32 %t1240, i32* %t1257
  br label %map_grow_next_279
map_grow_next_279:
  %t1258 = add i64 %t1232, 1
  store i64 %t1258, i64* %t1231
  br label %map_grow_cond_276
map_grow_end_280:
  %t1259 = bitcast i8** %t1228 to i8*
  call void @free(i8* %t1259)
  %t1260 = bitcast i32* %t1229 to i8*
  call void @free(i8* %t1260)
  call void @free(i8* %t1230)
  store i8** %t1218, i8*** %t1187
  store i32* %t1221, i32** %t1189
  store i8* %t1222, i8** %t1191
  store i64 %t1214, i64* %t1195
  store i64 0, i64* %t1197
  br label %map_insert_after_grow_272
map_insert_after_grow_272:
  %t1261 = load i8**, i8*** %t1187
  %t1262 = load i32*, i32** %t1189
  %t1263 = load i8*, i8** %t1191
  %t1264 = load i64, i64* %t1195
  %t1265 = sub i64 %t1264, 1
  %t1266 = call i64 @hash_str(i8* %t1199)
  %t1267 = and i64 %t1266, %t1265
  store i64 0, i64* %t1268
  store i64 %t1267, i64* %t1269
  store i1 false, i1* %t1270
  store i64 -1, i64* %t1271
  store i64 -1, i64* %t1272
  store i1 false, i1* %t1273
  br label %ht_probe_cond_285
ht_probe_cond_285:
  %t1274 = load i64, i64* %t1268
  %t1275 = icmp slt i64 %t1274, %t1264
  br i1 %t1275, label %ht_probe_body_286, label %ht_probe_end_296
ht_probe_body_286:
  %t1276 = load i64, i64* %t1269
  %t1277 = getelementptr inbounds i8, i8* %t1263, i64 %t1276
  %t1278 = load i8, i8* %t1277
  %t1279 = icmp eq i8 %t1278, 0
  br i1 %t1279, label %ht_probe_on_empty_288, label %ht_probe_check_occ_287
ht_probe_check_occ_287:
  %t1280 = icmp eq i8 %t1278, 1
  br i1 %t1280, label %ht_probe_on_occ_291, label %ht_probe_on_tomb_293
ht_probe_on_empty_288:
  %t1281 = load i1, i1* %t1273
  br i1 %t1281, label %ht_probe_after_islot_empty_290, label %ht_probe_set_islot_empty_289
ht_probe_set_islot_empty_289:
  store i64 %t1276, i64* %t1272
  store i1 true, i1* %t1273
  br label %ht_probe_after_islot_empty_290
ht_probe_after_islot_empty_290:
  br label %ht_probe_end_296
ht_probe_on_occ_291:
  %t1282 = getelementptr inbounds i8*, i8** %t1261, i64 %t1276
  %t1283 = load i8*, i8** %t1282
  %t1284 = call i1 @eq_str(i8* %t1283, i8* %t1199)
  br i1 %t1284, label %ht_probe_on_match_292, label %ht_probe_next_295
ht_probe_on_match_292:
  store i1 true, i1* %t1270
  store i64 %t1276, i64* %t1271
  br label %ht_probe_end_296
ht_probe_on_tomb_293:
  %t1285 = load i1, i1* %t1273
  br i1 %t1285, label %ht_probe_next_295, label %ht_probe_set_islot_tomb_294
ht_probe_set_islot_tomb_294:
  store i64 %t1276, i64* %t1272
  store i1 true, i1* %t1273
  br label %ht_probe_next_295
ht_probe_next_295:
  %t1286 = add i64 %t1276, 1
  %t1287 = and i64 %t1286, %t1265
  store i64 %t1287, i64* %t1269
  %t1288 = add i64 %t1274, 1
  store i64 %t1288, i64* %t1268
  br label %ht_probe_cond_285
ht_probe_end_296:
  %t1289 = load i1, i1* %t1270
  %t1290 = load i64, i64* %t1271
  %t1291 = load i64, i64* %t1272
  br i1 %t1289, label %map_insert_overwrite_297, label %map_insert_new_298
map_insert_overwrite_297:
  store i8* %t1199, i8** %t1292
  %t1293 = load i8*, i8** %t1292
  call void @star_rc_release(i8* %t1293)
  %t1294 = getelementptr inbounds i32, i32* %t1262, i64 %t1290
  store i32 6, i32* %t1294
  br label %map_insert_after_299
map_insert_new_298:
  %t1295 = getelementptr inbounds i8, i8* %t1263, i64 %t1291
  %t1296 = load i8, i8* %t1295
  %t1297 = icmp eq i8 %t1296, 2
  br i1 %t1297, label %map_insert_dec_tomb_300, label %map_insert_store_301
map_insert_dec_tomb_300:
  %t1298 = load i64, i64* %t1197
  %t1299 = sub i64 %t1298, 1
  store i64 %t1299, i64* %t1197
  br label %map_insert_store_301
map_insert_store_301:
  store i8 1, i8* %t1295
  %t1300 = getelementptr inbounds i8*, i8** %t1261, i64 %t1291
  store i8* %t1199, i8** %t1300
  %t1301 = getelementptr inbounds i32, i32* %t1262, i64 %t1291
  store i32 6, i32* %t1301
  %t1302 = load i64, i64* %t1193
  %t1303 = add i64 %t1302, 1
  store i64 %t1303, i64* %t1193
  br label %map_insert_after_299
map_insert_after_299:
  %t1304 = getelementptr i8*, i8** null, i32 1
  %t1305 = ptrtoint i8** %t1304 to i64
  %t1306 = getelementptr i32, i32* null, i32 1
  %t1307 = ptrtoint i32* %t1306 to i64
  %t1308 = load i8*, i8** %t0
  %t1309 = icmp eq i8* %t1308, null
  br i1 %t1309, label %map_cow_alloc_302, label %map_cow_check_303
map_cow_alloc_302:
  %t1310 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1311 = call i8* @star_rc_alloc(i64 48, i8* %t1310)
  %t1312 = bitcast i8* %t1311 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1313 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1312, i32 0, i32 0
  store i8** null, i8*** %t1313
  %t1314 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1312, i32 0, i32 1
  store i32* null, i32** %t1314
  %t1315 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1312, i32 0, i32 2
  store i8* null, i8** %t1315
  %t1316 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1312, i32 0, i32 3
  store i64 0, i64* %t1316
  %t1317 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1312, i32 0, i32 4
  store i64 0, i64* %t1317
  %t1318 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1312, i32 0, i32 5
  store i64 0, i64* %t1318
  store i8* %t1311, i8** %t0
  br label %map_cow_done_304
map_cow_check_303:
  %t1319 = getelementptr inbounds i8, i8* %t1308, i64 -16
  %t1320 = bitcast i8* %t1319 to i64*
  %t1321 = load atomic i64, i64* %t1320 seq_cst, align 8
  %t1322 = icmp eq i64 %t1321, 1
  br i1 %t1322, label %map_cow_done_304, label %map_cow_clone_305
map_cow_clone_305:
  %t1323 = bitcast i8* %t1308 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1324 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1323, i32 0, i32 0
  %t1325 = load i8**, i8*** %t1324
  %t1326 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1323, i32 0, i32 1
  %t1327 = load i32*, i32** %t1326
  %t1328 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1323, i32 0, i32 2
  %t1329 = load i8*, i8** %t1328
  %t1330 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1323, i32 0, i32 3
  %t1331 = load i64, i64* %t1330
  %t1332 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1323, i32 0, i32 4
  %t1333 = load i64, i64* %t1332
  %t1334 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1323, i32 0, i32 5
  %t1335 = load i64, i64* %t1334
  %t1336 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1337 = call i8* @star_rc_alloc(i64 48, i8* %t1336)
  %t1338 = bitcast i8* %t1337 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1339 = mul i64 %t1333, %t1305
  %t1340 = call i8* @malloc(i64 %t1339)
  %t1341 = bitcast i8* %t1340 to i8**
  %t1342 = mul i64 %t1333, %t1307
  %t1343 = call i8* @malloc(i64 %t1342)
  %t1344 = bitcast i8* %t1343 to i32*
  %t1345 = call i8* @malloc(i64 %t1333)
  %t1346 = icmp sgt i64 %t1333, 0
  br i1 %t1346, label %map_cow_copy_306, label %map_cow_after_copy_307
map_cow_copy_306:
  %t1347 = mul i64 %t1333, %t1305
  %t1348 = bitcast i8** %t1325 to i8*
  call i8* @memcpy(i8* %t1340, i8* %t1348, i64 %t1347)
  %t1349 = mul i64 %t1333, %t1307
  %t1350 = bitcast i32* %t1327 to i8*
  call i8* @memcpy(i8* %t1343, i8* %t1350, i64 %t1349)
  call i8* @memcpy(i8* %t1345, i8* %t1329, i64 %t1333)
  store i64 0, i64* %t1351
  br label %map_cow_retain_cond_308
map_cow_retain_cond_308:
  %t1352 = load i64, i64* %t1351
  %t1353 = icmp slt i64 %t1352, %t1333
  br i1 %t1353, label %map_cow_retain_body_309, label %map_cow_retain_end_312
map_cow_retain_body_309:
  %t1354 = getelementptr inbounds i8, i8* %t1345, i64 %t1352
  %t1355 = load i8, i8* %t1354
  %t1356 = icmp eq i8 %t1355, 1
  br i1 %t1356, label %map_cow_retain_occ_310, label %map_cow_retain_next_311
map_cow_retain_occ_310:
  %t1357 = getelementptr inbounds i8*, i8** %t1341, i64 %t1352
  %t1358 = load i8*, i8** %t1357
  call void @star_rc_retain(i8* %t1358)
  br label %map_cow_retain_next_311
map_cow_retain_next_311:
  %t1359 = add i64 %t1352, 1
  store i64 %t1359, i64* %t1351
  br label %map_cow_retain_cond_308
map_cow_retain_end_312:
  br label %map_cow_after_copy_307
map_cow_after_copy_307:
  %t1360 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1338, i32 0, i32 0
  store i8** %t1341, i8*** %t1360
  %t1361 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1338, i32 0, i32 1
  store i32* %t1344, i32** %t1361
  %t1362 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1338, i32 0, i32 2
  store i8* %t1345, i8** %t1362
  %t1363 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1338, i32 0, i32 3
  store i64 %t1331, i64* %t1363
  %t1364 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1338, i32 0, i32 4
  store i64 %t1333, i64* %t1364
  %t1365 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1338, i32 0, i32 5
  store i64 %t1335, i64* %t1365
  call void @star_rc_release(i8* %t1308)
  store i8* %t1337, i8** %t0
  br label %map_cow_done_304
map_cow_done_304:
  %t1366 = load i8*, i8** %t0
  %t1367 = bitcast i8* %t1366 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1368 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1367, i32 0, i32 0
  %t1369 = load i8**, i8*** %t1368
  %t1370 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1367, i32 0, i32 1
  %t1371 = load i32*, i32** %t1370
  %t1372 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1367, i32 0, i32 2
  %t1373 = load i8*, i8** %t1372
  %t1374 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1367, i32 0, i32 3
  %t1375 = load i64, i64* %t1374
  %t1376 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1367, i32 0, i32 4
  %t1377 = load i64, i64* %t1376
  %t1378 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1367, i32 0, i32 5
  %t1379 = load i64, i64* %t1378
  %t1380 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t1381 = load i64, i64* %t1374
  %t1382 = load i64, i64* %t1376
  %t1383 = load i64, i64* %t1378
  %t1384 = add i64 %t1381, %t1383
  %t1385 = add i64 %t1384, 1
  %t1386 = mul i64 %t1385, 4
  %t1387 = mul i64 %t1382, 3
  %t1388 = icmp sgt i64 %t1386, %t1387
  br i1 %t1388, label %map_insert_grow_313, label %map_insert_after_grow_314
map_insert_grow_313:
  %t1389 = getelementptr i8*, i8** null, i32 1
  %t1390 = ptrtoint i8** %t1389 to i64
  %t1391 = getelementptr i32, i32* null, i32 1
  %t1392 = ptrtoint i32* %t1391 to i64
  %t1393 = mul i64 %t1382, 2
  %t1394 = icmp sgt i64 %t1393, 0
  %t1395 = select i1 %t1394, i64 %t1393, i64 8
  %t1396 = sub i64 %t1395, 1
  %t1397 = mul i64 %t1395, %t1390
  %t1398 = call i8* @malloc(i64 %t1397)
  %t1399 = bitcast i8* %t1398 to i8**
  %t1400 = mul i64 %t1395, %t1392
  %t1401 = call i8* @malloc(i64 %t1400)
  %t1402 = bitcast i8* %t1401 to i32*
  %t1403 = call i8* @malloc(i64 %t1395)
  store i64 0, i64* %t1404
  br label %ht_fill8_cond_315
ht_fill8_cond_315:
  %t1405 = load i64, i64* %t1404
  %t1406 = icmp slt i64 %t1405, %t1395
  br i1 %t1406, label %ht_fill8_body_316, label %ht_fill8_end_317
ht_fill8_body_316:
  %t1407 = getelementptr inbounds i8, i8* %t1403, i64 %t1405
  store i8 0, i8* %t1407
  %t1408 = add i64 %t1405, 1
  store i64 %t1408, i64* %t1404
  br label %ht_fill8_cond_315
ht_fill8_end_317:
  %t1409 = load i8**, i8*** %t1368
  %t1410 = load i32*, i32** %t1370
  %t1411 = load i8*, i8** %t1372
  store i64 0, i64* %t1412
  br label %map_grow_cond_318
map_grow_cond_318:
  %t1413 = load i64, i64* %t1412
  %t1414 = icmp slt i64 %t1413, %t1382
  br i1 %t1414, label %map_grow_body_319, label %map_grow_end_322
map_grow_body_319:
  %t1415 = getelementptr inbounds i8, i8* %t1411, i64 %t1413
  %t1416 = load i8, i8* %t1415
  %t1417 = icmp eq i8 %t1416, 1
  br i1 %t1417, label %map_grow_occ_320, label %map_grow_next_321
map_grow_occ_320:
  %t1418 = getelementptr inbounds i8*, i8** %t1409, i64 %t1413
  %t1419 = load i8*, i8** %t1418
  %t1420 = getelementptr inbounds i32, i32* %t1410, i64 %t1413
  %t1421 = load i32, i32* %t1420
  %t1422 = call i64 @hash_str(i8* %t1419)
  %t1423 = and i64 %t1422, %t1396
  store i64 0, i64* %t1424
  store i64 %t1423, i64* %t1425
  br label %ht_fe_cond_323
ht_fe_cond_323:
  %t1426 = load i64, i64* %t1424
  %t1427 = icmp slt i64 %t1426, %t1395
  br i1 %t1427, label %ht_fe_body_324, label %ht_fe_end_326
ht_fe_body_324:
  %t1428 = load i64, i64* %t1425
  %t1429 = getelementptr inbounds i8, i8* %t1403, i64 %t1428
  %t1430 = load i8, i8* %t1429
  %t1431 = icmp eq i8 %t1430, 0
  br i1 %t1431, label %ht_fe_end_326, label %ht_fe_next_325
ht_fe_next_325:
  %t1432 = add i64 %t1428, 1
  %t1433 = and i64 %t1432, %t1396
  store i64 %t1433, i64* %t1425
  %t1434 = add i64 %t1426, 1
  store i64 %t1434, i64* %t1424
  br label %ht_fe_cond_323
ht_fe_end_326:
  %t1435 = load i64, i64* %t1425
  %t1436 = getelementptr inbounds i8, i8* %t1403, i64 %t1435
  store i8 1, i8* %t1436
  %t1437 = getelementptr inbounds i8*, i8** %t1399, i64 %t1435
  store i8* %t1419, i8** %t1437
  %t1438 = getelementptr inbounds i32, i32* %t1402, i64 %t1435
  store i32 %t1421, i32* %t1438
  br label %map_grow_next_321
map_grow_next_321:
  %t1439 = add i64 %t1413, 1
  store i64 %t1439, i64* %t1412
  br label %map_grow_cond_318
map_grow_end_322:
  %t1440 = bitcast i8** %t1409 to i8*
  call void @free(i8* %t1440)
  %t1441 = bitcast i32* %t1410 to i8*
  call void @free(i8* %t1441)
  call void @free(i8* %t1411)
  store i8** %t1399, i8*** %t1368
  store i32* %t1402, i32** %t1370
  store i8* %t1403, i8** %t1372
  store i64 %t1395, i64* %t1376
  store i64 0, i64* %t1378
  br label %map_insert_after_grow_314
map_insert_after_grow_314:
  %t1442 = load i8**, i8*** %t1368
  %t1443 = load i32*, i32** %t1370
  %t1444 = load i8*, i8** %t1372
  %t1445 = load i64, i64* %t1376
  %t1446 = sub i64 %t1445, 1
  %t1447 = call i64 @hash_str(i8* %t1380)
  %t1448 = and i64 %t1447, %t1446
  store i64 0, i64* %t1449
  store i64 %t1448, i64* %t1450
  store i1 false, i1* %t1451
  store i64 -1, i64* %t1452
  store i64 -1, i64* %t1453
  store i1 false, i1* %t1454
  br label %ht_probe_cond_327
ht_probe_cond_327:
  %t1455 = load i64, i64* %t1449
  %t1456 = icmp slt i64 %t1455, %t1445
  br i1 %t1456, label %ht_probe_body_328, label %ht_probe_end_338
ht_probe_body_328:
  %t1457 = load i64, i64* %t1450
  %t1458 = getelementptr inbounds i8, i8* %t1444, i64 %t1457
  %t1459 = load i8, i8* %t1458
  %t1460 = icmp eq i8 %t1459, 0
  br i1 %t1460, label %ht_probe_on_empty_330, label %ht_probe_check_occ_329
ht_probe_check_occ_329:
  %t1461 = icmp eq i8 %t1459, 1
  br i1 %t1461, label %ht_probe_on_occ_333, label %ht_probe_on_tomb_335
ht_probe_on_empty_330:
  %t1462 = load i1, i1* %t1454
  br i1 %t1462, label %ht_probe_after_islot_empty_332, label %ht_probe_set_islot_empty_331
ht_probe_set_islot_empty_331:
  store i64 %t1457, i64* %t1453
  store i1 true, i1* %t1454
  br label %ht_probe_after_islot_empty_332
ht_probe_after_islot_empty_332:
  br label %ht_probe_end_338
ht_probe_on_occ_333:
  %t1463 = getelementptr inbounds i8*, i8** %t1442, i64 %t1457
  %t1464 = load i8*, i8** %t1463
  %t1465 = call i1 @eq_str(i8* %t1464, i8* %t1380)
  br i1 %t1465, label %ht_probe_on_match_334, label %ht_probe_next_337
ht_probe_on_match_334:
  store i1 true, i1* %t1451
  store i64 %t1457, i64* %t1452
  br label %ht_probe_end_338
ht_probe_on_tomb_335:
  %t1466 = load i1, i1* %t1454
  br i1 %t1466, label %ht_probe_next_337, label %ht_probe_set_islot_tomb_336
ht_probe_set_islot_tomb_336:
  store i64 %t1457, i64* %t1453
  store i1 true, i1* %t1454
  br label %ht_probe_next_337
ht_probe_next_337:
  %t1467 = add i64 %t1457, 1
  %t1468 = and i64 %t1467, %t1446
  store i64 %t1468, i64* %t1450
  %t1469 = add i64 %t1455, 1
  store i64 %t1469, i64* %t1449
  br label %ht_probe_cond_327
ht_probe_end_338:
  %t1470 = load i1, i1* %t1451
  %t1471 = load i64, i64* %t1452
  %t1472 = load i64, i64* %t1453
  br i1 %t1470, label %map_insert_overwrite_339, label %map_insert_new_340
map_insert_overwrite_339:
  store i8* %t1380, i8** %t1473
  %t1474 = load i8*, i8** %t1473
  call void @star_rc_release(i8* %t1474)
  %t1475 = getelementptr inbounds i32, i32* %t1443, i64 %t1471
  store i32 7, i32* %t1475
  br label %map_insert_after_341
map_insert_new_340:
  %t1476 = getelementptr inbounds i8, i8* %t1444, i64 %t1472
  %t1477 = load i8, i8* %t1476
  %t1478 = icmp eq i8 %t1477, 2
  br i1 %t1478, label %map_insert_dec_tomb_342, label %map_insert_store_343
map_insert_dec_tomb_342:
  %t1479 = load i64, i64* %t1378
  %t1480 = sub i64 %t1479, 1
  store i64 %t1480, i64* %t1378
  br label %map_insert_store_343
map_insert_store_343:
  store i8 1, i8* %t1476
  %t1481 = getelementptr inbounds i8*, i8** %t1442, i64 %t1472
  store i8* %t1380, i8** %t1481
  %t1482 = getelementptr inbounds i32, i32* %t1443, i64 %t1472
  store i32 7, i32* %t1482
  %t1483 = load i64, i64* %t1374
  %t1484 = add i64 %t1483, 1
  store i64 %t1484, i64* %t1374
  br label %map_insert_after_341
map_insert_after_341:
  %t1485 = getelementptr i8*, i8** null, i32 1
  %t1486 = ptrtoint i8** %t1485 to i64
  %t1487 = getelementptr i32, i32* null, i32 1
  %t1488 = ptrtoint i32* %t1487 to i64
  %t1489 = load i8*, i8** %t0
  %t1490 = icmp eq i8* %t1489, null
  br i1 %t1490, label %map_cow_alloc_344, label %map_cow_check_345
map_cow_alloc_344:
  %t1491 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1492 = call i8* @star_rc_alloc(i64 48, i8* %t1491)
  %t1493 = bitcast i8* %t1492 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1494 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1493, i32 0, i32 0
  store i8** null, i8*** %t1494
  %t1495 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1493, i32 0, i32 1
  store i32* null, i32** %t1495
  %t1496 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1493, i32 0, i32 2
  store i8* null, i8** %t1496
  %t1497 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1493, i32 0, i32 3
  store i64 0, i64* %t1497
  %t1498 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1493, i32 0, i32 4
  store i64 0, i64* %t1498
  %t1499 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1493, i32 0, i32 5
  store i64 0, i64* %t1499
  store i8* %t1492, i8** %t0
  br label %map_cow_done_346
map_cow_check_345:
  %t1500 = getelementptr inbounds i8, i8* %t1489, i64 -16
  %t1501 = bitcast i8* %t1500 to i64*
  %t1502 = load atomic i64, i64* %t1501 seq_cst, align 8
  %t1503 = icmp eq i64 %t1502, 1
  br i1 %t1503, label %map_cow_done_346, label %map_cow_clone_347
map_cow_clone_347:
  %t1504 = bitcast i8* %t1489 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1505 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1504, i32 0, i32 0
  %t1506 = load i8**, i8*** %t1505
  %t1507 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1504, i32 0, i32 1
  %t1508 = load i32*, i32** %t1507
  %t1509 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1504, i32 0, i32 2
  %t1510 = load i8*, i8** %t1509
  %t1511 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1504, i32 0, i32 3
  %t1512 = load i64, i64* %t1511
  %t1513 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1504, i32 0, i32 4
  %t1514 = load i64, i64* %t1513
  %t1515 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1504, i32 0, i32 5
  %t1516 = load i64, i64* %t1515
  %t1517 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1518 = call i8* @star_rc_alloc(i64 48, i8* %t1517)
  %t1519 = bitcast i8* %t1518 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1520 = mul i64 %t1514, %t1486
  %t1521 = call i8* @malloc(i64 %t1520)
  %t1522 = bitcast i8* %t1521 to i8**
  %t1523 = mul i64 %t1514, %t1488
  %t1524 = call i8* @malloc(i64 %t1523)
  %t1525 = bitcast i8* %t1524 to i32*
  %t1526 = call i8* @malloc(i64 %t1514)
  %t1527 = icmp sgt i64 %t1514, 0
  br i1 %t1527, label %map_cow_copy_348, label %map_cow_after_copy_349
map_cow_copy_348:
  %t1528 = mul i64 %t1514, %t1486
  %t1529 = bitcast i8** %t1506 to i8*
  call i8* @memcpy(i8* %t1521, i8* %t1529, i64 %t1528)
  %t1530 = mul i64 %t1514, %t1488
  %t1531 = bitcast i32* %t1508 to i8*
  call i8* @memcpy(i8* %t1524, i8* %t1531, i64 %t1530)
  call i8* @memcpy(i8* %t1526, i8* %t1510, i64 %t1514)
  store i64 0, i64* %t1532
  br label %map_cow_retain_cond_350
map_cow_retain_cond_350:
  %t1533 = load i64, i64* %t1532
  %t1534 = icmp slt i64 %t1533, %t1514
  br i1 %t1534, label %map_cow_retain_body_351, label %map_cow_retain_end_354
map_cow_retain_body_351:
  %t1535 = getelementptr inbounds i8, i8* %t1526, i64 %t1533
  %t1536 = load i8, i8* %t1535
  %t1537 = icmp eq i8 %t1536, 1
  br i1 %t1537, label %map_cow_retain_occ_352, label %map_cow_retain_next_353
map_cow_retain_occ_352:
  %t1538 = getelementptr inbounds i8*, i8** %t1522, i64 %t1533
  %t1539 = load i8*, i8** %t1538
  call void @star_rc_retain(i8* %t1539)
  br label %map_cow_retain_next_353
map_cow_retain_next_353:
  %t1540 = add i64 %t1533, 1
  store i64 %t1540, i64* %t1532
  br label %map_cow_retain_cond_350
map_cow_retain_end_354:
  br label %map_cow_after_copy_349
map_cow_after_copy_349:
  %t1541 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1519, i32 0, i32 0
  store i8** %t1522, i8*** %t1541
  %t1542 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1519, i32 0, i32 1
  store i32* %t1525, i32** %t1542
  %t1543 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1519, i32 0, i32 2
  store i8* %t1526, i8** %t1543
  %t1544 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1519, i32 0, i32 3
  store i64 %t1512, i64* %t1544
  %t1545 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1519, i32 0, i32 4
  store i64 %t1514, i64* %t1545
  %t1546 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1519, i32 0, i32 5
  store i64 %t1516, i64* %t1546
  call void @star_rc_release(i8* %t1489)
  store i8* %t1518, i8** %t0
  br label %map_cow_done_346
map_cow_done_346:
  %t1547 = load i8*, i8** %t0
  %t1548 = bitcast i8* %t1547 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1549 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1548, i32 0, i32 0
  %t1550 = load i8**, i8*** %t1549
  %t1551 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1548, i32 0, i32 1
  %t1552 = load i32*, i32** %t1551
  %t1553 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1548, i32 0, i32 2
  %t1554 = load i8*, i8** %t1553
  %t1555 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1548, i32 0, i32 3
  %t1556 = load i64, i64* %t1555
  %t1557 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1548, i32 0, i32 4
  %t1558 = load i64, i64* %t1557
  %t1559 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1548, i32 0, i32 5
  %t1560 = load i64, i64* %t1559
  %t1561 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.8, i64 0, i32 2, i64 0
  %t1562 = load i64, i64* %t1555
  %t1563 = load i64, i64* %t1557
  %t1564 = load i64, i64* %t1559
  %t1565 = add i64 %t1562, %t1564
  %t1566 = add i64 %t1565, 1
  %t1567 = mul i64 %t1566, 4
  %t1568 = mul i64 %t1563, 3
  %t1569 = icmp sgt i64 %t1567, %t1568
  br i1 %t1569, label %map_insert_grow_355, label %map_insert_after_grow_356
map_insert_grow_355:
  %t1570 = getelementptr i8*, i8** null, i32 1
  %t1571 = ptrtoint i8** %t1570 to i64
  %t1572 = getelementptr i32, i32* null, i32 1
  %t1573 = ptrtoint i32* %t1572 to i64
  %t1574 = mul i64 %t1563, 2
  %t1575 = icmp sgt i64 %t1574, 0
  %t1576 = select i1 %t1575, i64 %t1574, i64 8
  %t1577 = sub i64 %t1576, 1
  %t1578 = mul i64 %t1576, %t1571
  %t1579 = call i8* @malloc(i64 %t1578)
  %t1580 = bitcast i8* %t1579 to i8**
  %t1581 = mul i64 %t1576, %t1573
  %t1582 = call i8* @malloc(i64 %t1581)
  %t1583 = bitcast i8* %t1582 to i32*
  %t1584 = call i8* @malloc(i64 %t1576)
  store i64 0, i64* %t1585
  br label %ht_fill8_cond_357
ht_fill8_cond_357:
  %t1586 = load i64, i64* %t1585
  %t1587 = icmp slt i64 %t1586, %t1576
  br i1 %t1587, label %ht_fill8_body_358, label %ht_fill8_end_359
ht_fill8_body_358:
  %t1588 = getelementptr inbounds i8, i8* %t1584, i64 %t1586
  store i8 0, i8* %t1588
  %t1589 = add i64 %t1586, 1
  store i64 %t1589, i64* %t1585
  br label %ht_fill8_cond_357
ht_fill8_end_359:
  %t1590 = load i8**, i8*** %t1549
  %t1591 = load i32*, i32** %t1551
  %t1592 = load i8*, i8** %t1553
  store i64 0, i64* %t1593
  br label %map_grow_cond_360
map_grow_cond_360:
  %t1594 = load i64, i64* %t1593
  %t1595 = icmp slt i64 %t1594, %t1563
  br i1 %t1595, label %map_grow_body_361, label %map_grow_end_364
map_grow_body_361:
  %t1596 = getelementptr inbounds i8, i8* %t1592, i64 %t1594
  %t1597 = load i8, i8* %t1596
  %t1598 = icmp eq i8 %t1597, 1
  br i1 %t1598, label %map_grow_occ_362, label %map_grow_next_363
map_grow_occ_362:
  %t1599 = getelementptr inbounds i8*, i8** %t1590, i64 %t1594
  %t1600 = load i8*, i8** %t1599
  %t1601 = getelementptr inbounds i32, i32* %t1591, i64 %t1594
  %t1602 = load i32, i32* %t1601
  %t1603 = call i64 @hash_str(i8* %t1600)
  %t1604 = and i64 %t1603, %t1577
  store i64 0, i64* %t1605
  store i64 %t1604, i64* %t1606
  br label %ht_fe_cond_365
ht_fe_cond_365:
  %t1607 = load i64, i64* %t1605
  %t1608 = icmp slt i64 %t1607, %t1576
  br i1 %t1608, label %ht_fe_body_366, label %ht_fe_end_368
ht_fe_body_366:
  %t1609 = load i64, i64* %t1606
  %t1610 = getelementptr inbounds i8, i8* %t1584, i64 %t1609
  %t1611 = load i8, i8* %t1610
  %t1612 = icmp eq i8 %t1611, 0
  br i1 %t1612, label %ht_fe_end_368, label %ht_fe_next_367
ht_fe_next_367:
  %t1613 = add i64 %t1609, 1
  %t1614 = and i64 %t1613, %t1577
  store i64 %t1614, i64* %t1606
  %t1615 = add i64 %t1607, 1
  store i64 %t1615, i64* %t1605
  br label %ht_fe_cond_365
ht_fe_end_368:
  %t1616 = load i64, i64* %t1606
  %t1617 = getelementptr inbounds i8, i8* %t1584, i64 %t1616
  store i8 1, i8* %t1617
  %t1618 = getelementptr inbounds i8*, i8** %t1580, i64 %t1616
  store i8* %t1600, i8** %t1618
  %t1619 = getelementptr inbounds i32, i32* %t1583, i64 %t1616
  store i32 %t1602, i32* %t1619
  br label %map_grow_next_363
map_grow_next_363:
  %t1620 = add i64 %t1594, 1
  store i64 %t1620, i64* %t1593
  br label %map_grow_cond_360
map_grow_end_364:
  %t1621 = bitcast i8** %t1590 to i8*
  call void @free(i8* %t1621)
  %t1622 = bitcast i32* %t1591 to i8*
  call void @free(i8* %t1622)
  call void @free(i8* %t1592)
  store i8** %t1580, i8*** %t1549
  store i32* %t1583, i32** %t1551
  store i8* %t1584, i8** %t1553
  store i64 %t1576, i64* %t1557
  store i64 0, i64* %t1559
  br label %map_insert_after_grow_356
map_insert_after_grow_356:
  %t1623 = load i8**, i8*** %t1549
  %t1624 = load i32*, i32** %t1551
  %t1625 = load i8*, i8** %t1553
  %t1626 = load i64, i64* %t1557
  %t1627 = sub i64 %t1626, 1
  %t1628 = call i64 @hash_str(i8* %t1561)
  %t1629 = and i64 %t1628, %t1627
  store i64 0, i64* %t1630
  store i64 %t1629, i64* %t1631
  store i1 false, i1* %t1632
  store i64 -1, i64* %t1633
  store i64 -1, i64* %t1634
  store i1 false, i1* %t1635
  br label %ht_probe_cond_369
ht_probe_cond_369:
  %t1636 = load i64, i64* %t1630
  %t1637 = icmp slt i64 %t1636, %t1626
  br i1 %t1637, label %ht_probe_body_370, label %ht_probe_end_380
ht_probe_body_370:
  %t1638 = load i64, i64* %t1631
  %t1639 = getelementptr inbounds i8, i8* %t1625, i64 %t1638
  %t1640 = load i8, i8* %t1639
  %t1641 = icmp eq i8 %t1640, 0
  br i1 %t1641, label %ht_probe_on_empty_372, label %ht_probe_check_occ_371
ht_probe_check_occ_371:
  %t1642 = icmp eq i8 %t1640, 1
  br i1 %t1642, label %ht_probe_on_occ_375, label %ht_probe_on_tomb_377
ht_probe_on_empty_372:
  %t1643 = load i1, i1* %t1635
  br i1 %t1643, label %ht_probe_after_islot_empty_374, label %ht_probe_set_islot_empty_373
ht_probe_set_islot_empty_373:
  store i64 %t1638, i64* %t1634
  store i1 true, i1* %t1635
  br label %ht_probe_after_islot_empty_374
ht_probe_after_islot_empty_374:
  br label %ht_probe_end_380
ht_probe_on_occ_375:
  %t1644 = getelementptr inbounds i8*, i8** %t1623, i64 %t1638
  %t1645 = load i8*, i8** %t1644
  %t1646 = call i1 @eq_str(i8* %t1645, i8* %t1561)
  br i1 %t1646, label %ht_probe_on_match_376, label %ht_probe_next_379
ht_probe_on_match_376:
  store i1 true, i1* %t1632
  store i64 %t1638, i64* %t1633
  br label %ht_probe_end_380
ht_probe_on_tomb_377:
  %t1647 = load i1, i1* %t1635
  br i1 %t1647, label %ht_probe_next_379, label %ht_probe_set_islot_tomb_378
ht_probe_set_islot_tomb_378:
  store i64 %t1638, i64* %t1634
  store i1 true, i1* %t1635
  br label %ht_probe_next_379
ht_probe_next_379:
  %t1648 = add i64 %t1638, 1
  %t1649 = and i64 %t1648, %t1627
  store i64 %t1649, i64* %t1631
  %t1650 = add i64 %t1636, 1
  store i64 %t1650, i64* %t1630
  br label %ht_probe_cond_369
ht_probe_end_380:
  %t1651 = load i1, i1* %t1632
  %t1652 = load i64, i64* %t1633
  %t1653 = load i64, i64* %t1634
  br i1 %t1651, label %map_insert_overwrite_381, label %map_insert_new_382
map_insert_overwrite_381:
  store i8* %t1561, i8** %t1654
  %t1655 = load i8*, i8** %t1654
  call void @star_rc_release(i8* %t1655)
  %t1656 = getelementptr inbounds i32, i32* %t1624, i64 %t1652
  store i32 8, i32* %t1656
  br label %map_insert_after_383
map_insert_new_382:
  %t1657 = getelementptr inbounds i8, i8* %t1625, i64 %t1653
  %t1658 = load i8, i8* %t1657
  %t1659 = icmp eq i8 %t1658, 2
  br i1 %t1659, label %map_insert_dec_tomb_384, label %map_insert_store_385
map_insert_dec_tomb_384:
  %t1660 = load i64, i64* %t1559
  %t1661 = sub i64 %t1660, 1
  store i64 %t1661, i64* %t1559
  br label %map_insert_store_385
map_insert_store_385:
  store i8 1, i8* %t1657
  %t1662 = getelementptr inbounds i8*, i8** %t1623, i64 %t1653
  store i8* %t1561, i8** %t1662
  %t1663 = getelementptr inbounds i32, i32* %t1624, i64 %t1653
  store i32 8, i32* %t1663
  %t1664 = load i64, i64* %t1555
  %t1665 = add i64 %t1664, 1
  store i64 %t1665, i64* %t1555
  br label %map_insert_after_383
map_insert_after_383:
  %t1666 = getelementptr i8*, i8** null, i32 1
  %t1667 = ptrtoint i8** %t1666 to i64
  %t1668 = getelementptr i32, i32* null, i32 1
  %t1669 = ptrtoint i32* %t1668 to i64
  %t1670 = load i8*, i8** %t0
  %t1671 = icmp eq i8* %t1670, null
  br i1 %t1671, label %map_cow_alloc_386, label %map_cow_check_387
map_cow_alloc_386:
  %t1672 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1673 = call i8* @star_rc_alloc(i64 48, i8* %t1672)
  %t1674 = bitcast i8* %t1673 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1675 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1674, i32 0, i32 0
  store i8** null, i8*** %t1675
  %t1676 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1674, i32 0, i32 1
  store i32* null, i32** %t1676
  %t1677 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1674, i32 0, i32 2
  store i8* null, i8** %t1677
  %t1678 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1674, i32 0, i32 3
  store i64 0, i64* %t1678
  %t1679 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1674, i32 0, i32 4
  store i64 0, i64* %t1679
  %t1680 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1674, i32 0, i32 5
  store i64 0, i64* %t1680
  store i8* %t1673, i8** %t0
  br label %map_cow_done_388
map_cow_check_387:
  %t1681 = getelementptr inbounds i8, i8* %t1670, i64 -16
  %t1682 = bitcast i8* %t1681 to i64*
  %t1683 = load atomic i64, i64* %t1682 seq_cst, align 8
  %t1684 = icmp eq i64 %t1683, 1
  br i1 %t1684, label %map_cow_done_388, label %map_cow_clone_389
map_cow_clone_389:
  %t1685 = bitcast i8* %t1670 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1686 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1685, i32 0, i32 0
  %t1687 = load i8**, i8*** %t1686
  %t1688 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1685, i32 0, i32 1
  %t1689 = load i32*, i32** %t1688
  %t1690 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1685, i32 0, i32 2
  %t1691 = load i8*, i8** %t1690
  %t1692 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1685, i32 0, i32 3
  %t1693 = load i64, i64* %t1692
  %t1694 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1685, i32 0, i32 4
  %t1695 = load i64, i64* %t1694
  %t1696 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1685, i32 0, i32 5
  %t1697 = load i64, i64* %t1696
  %t1698 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1699 = call i8* @star_rc_alloc(i64 48, i8* %t1698)
  %t1700 = bitcast i8* %t1699 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1701 = mul i64 %t1695, %t1667
  %t1702 = call i8* @malloc(i64 %t1701)
  %t1703 = bitcast i8* %t1702 to i8**
  %t1704 = mul i64 %t1695, %t1669
  %t1705 = call i8* @malloc(i64 %t1704)
  %t1706 = bitcast i8* %t1705 to i32*
  %t1707 = call i8* @malloc(i64 %t1695)
  %t1708 = icmp sgt i64 %t1695, 0
  br i1 %t1708, label %map_cow_copy_390, label %map_cow_after_copy_391
map_cow_copy_390:
  %t1709 = mul i64 %t1695, %t1667
  %t1710 = bitcast i8** %t1687 to i8*
  call i8* @memcpy(i8* %t1702, i8* %t1710, i64 %t1709)
  %t1711 = mul i64 %t1695, %t1669
  %t1712 = bitcast i32* %t1689 to i8*
  call i8* @memcpy(i8* %t1705, i8* %t1712, i64 %t1711)
  call i8* @memcpy(i8* %t1707, i8* %t1691, i64 %t1695)
  store i64 0, i64* %t1713
  br label %map_cow_retain_cond_392
map_cow_retain_cond_392:
  %t1714 = load i64, i64* %t1713
  %t1715 = icmp slt i64 %t1714, %t1695
  br i1 %t1715, label %map_cow_retain_body_393, label %map_cow_retain_end_396
map_cow_retain_body_393:
  %t1716 = getelementptr inbounds i8, i8* %t1707, i64 %t1714
  %t1717 = load i8, i8* %t1716
  %t1718 = icmp eq i8 %t1717, 1
  br i1 %t1718, label %map_cow_retain_occ_394, label %map_cow_retain_next_395
map_cow_retain_occ_394:
  %t1719 = getelementptr inbounds i8*, i8** %t1703, i64 %t1714
  %t1720 = load i8*, i8** %t1719
  call void @star_rc_retain(i8* %t1720)
  br label %map_cow_retain_next_395
map_cow_retain_next_395:
  %t1721 = add i64 %t1714, 1
  store i64 %t1721, i64* %t1713
  br label %map_cow_retain_cond_392
map_cow_retain_end_396:
  br label %map_cow_after_copy_391
map_cow_after_copy_391:
  %t1722 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1700, i32 0, i32 0
  store i8** %t1703, i8*** %t1722
  %t1723 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1700, i32 0, i32 1
  store i32* %t1706, i32** %t1723
  %t1724 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1700, i32 0, i32 2
  store i8* %t1707, i8** %t1724
  %t1725 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1700, i32 0, i32 3
  store i64 %t1693, i64* %t1725
  %t1726 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1700, i32 0, i32 4
  store i64 %t1695, i64* %t1726
  %t1727 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1700, i32 0, i32 5
  store i64 %t1697, i64* %t1727
  call void @star_rc_release(i8* %t1670)
  store i8* %t1699, i8** %t0
  br label %map_cow_done_388
map_cow_done_388:
  %t1728 = load i8*, i8** %t0
  %t1729 = bitcast i8* %t1728 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1730 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1729, i32 0, i32 0
  %t1731 = load i8**, i8*** %t1730
  %t1732 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1729, i32 0, i32 1
  %t1733 = load i32*, i32** %t1732
  %t1734 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1729, i32 0, i32 2
  %t1735 = load i8*, i8** %t1734
  %t1736 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1729, i32 0, i32 3
  %t1737 = load i64, i64* %t1736
  %t1738 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1729, i32 0, i32 4
  %t1739 = load i64, i64* %t1738
  %t1740 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1729, i32 0, i32 5
  %t1741 = load i64, i64* %t1740
  %t1742 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t1743 = load i64, i64* %t1736
  %t1744 = load i64, i64* %t1738
  %t1745 = load i64, i64* %t1740
  %t1746 = add i64 %t1743, %t1745
  %t1747 = add i64 %t1746, 1
  %t1748 = mul i64 %t1747, 4
  %t1749 = mul i64 %t1744, 3
  %t1750 = icmp sgt i64 %t1748, %t1749
  br i1 %t1750, label %map_insert_grow_397, label %map_insert_after_grow_398
map_insert_grow_397:
  %t1751 = getelementptr i8*, i8** null, i32 1
  %t1752 = ptrtoint i8** %t1751 to i64
  %t1753 = getelementptr i32, i32* null, i32 1
  %t1754 = ptrtoint i32* %t1753 to i64
  %t1755 = mul i64 %t1744, 2
  %t1756 = icmp sgt i64 %t1755, 0
  %t1757 = select i1 %t1756, i64 %t1755, i64 8
  %t1758 = sub i64 %t1757, 1
  %t1759 = mul i64 %t1757, %t1752
  %t1760 = call i8* @malloc(i64 %t1759)
  %t1761 = bitcast i8* %t1760 to i8**
  %t1762 = mul i64 %t1757, %t1754
  %t1763 = call i8* @malloc(i64 %t1762)
  %t1764 = bitcast i8* %t1763 to i32*
  %t1765 = call i8* @malloc(i64 %t1757)
  store i64 0, i64* %t1766
  br label %ht_fill8_cond_399
ht_fill8_cond_399:
  %t1767 = load i64, i64* %t1766
  %t1768 = icmp slt i64 %t1767, %t1757
  br i1 %t1768, label %ht_fill8_body_400, label %ht_fill8_end_401
ht_fill8_body_400:
  %t1769 = getelementptr inbounds i8, i8* %t1765, i64 %t1767
  store i8 0, i8* %t1769
  %t1770 = add i64 %t1767, 1
  store i64 %t1770, i64* %t1766
  br label %ht_fill8_cond_399
ht_fill8_end_401:
  %t1771 = load i8**, i8*** %t1730
  %t1772 = load i32*, i32** %t1732
  %t1773 = load i8*, i8** %t1734
  store i64 0, i64* %t1774
  br label %map_grow_cond_402
map_grow_cond_402:
  %t1775 = load i64, i64* %t1774
  %t1776 = icmp slt i64 %t1775, %t1744
  br i1 %t1776, label %map_grow_body_403, label %map_grow_end_406
map_grow_body_403:
  %t1777 = getelementptr inbounds i8, i8* %t1773, i64 %t1775
  %t1778 = load i8, i8* %t1777
  %t1779 = icmp eq i8 %t1778, 1
  br i1 %t1779, label %map_grow_occ_404, label %map_grow_next_405
map_grow_occ_404:
  %t1780 = getelementptr inbounds i8*, i8** %t1771, i64 %t1775
  %t1781 = load i8*, i8** %t1780
  %t1782 = getelementptr inbounds i32, i32* %t1772, i64 %t1775
  %t1783 = load i32, i32* %t1782
  %t1784 = call i64 @hash_str(i8* %t1781)
  %t1785 = and i64 %t1784, %t1758
  store i64 0, i64* %t1786
  store i64 %t1785, i64* %t1787
  br label %ht_fe_cond_407
ht_fe_cond_407:
  %t1788 = load i64, i64* %t1786
  %t1789 = icmp slt i64 %t1788, %t1757
  br i1 %t1789, label %ht_fe_body_408, label %ht_fe_end_410
ht_fe_body_408:
  %t1790 = load i64, i64* %t1787
  %t1791 = getelementptr inbounds i8, i8* %t1765, i64 %t1790
  %t1792 = load i8, i8* %t1791
  %t1793 = icmp eq i8 %t1792, 0
  br i1 %t1793, label %ht_fe_end_410, label %ht_fe_next_409
ht_fe_next_409:
  %t1794 = add i64 %t1790, 1
  %t1795 = and i64 %t1794, %t1758
  store i64 %t1795, i64* %t1787
  %t1796 = add i64 %t1788, 1
  store i64 %t1796, i64* %t1786
  br label %ht_fe_cond_407
ht_fe_end_410:
  %t1797 = load i64, i64* %t1787
  %t1798 = getelementptr inbounds i8, i8* %t1765, i64 %t1797
  store i8 1, i8* %t1798
  %t1799 = getelementptr inbounds i8*, i8** %t1761, i64 %t1797
  store i8* %t1781, i8** %t1799
  %t1800 = getelementptr inbounds i32, i32* %t1764, i64 %t1797
  store i32 %t1783, i32* %t1800
  br label %map_grow_next_405
map_grow_next_405:
  %t1801 = add i64 %t1775, 1
  store i64 %t1801, i64* %t1774
  br label %map_grow_cond_402
map_grow_end_406:
  %t1802 = bitcast i8** %t1771 to i8*
  call void @free(i8* %t1802)
  %t1803 = bitcast i32* %t1772 to i8*
  call void @free(i8* %t1803)
  call void @free(i8* %t1773)
  store i8** %t1761, i8*** %t1730
  store i32* %t1764, i32** %t1732
  store i8* %t1765, i8** %t1734
  store i64 %t1757, i64* %t1738
  store i64 0, i64* %t1740
  br label %map_insert_after_grow_398
map_insert_after_grow_398:
  %t1804 = load i8**, i8*** %t1730
  %t1805 = load i32*, i32** %t1732
  %t1806 = load i8*, i8** %t1734
  %t1807 = load i64, i64* %t1738
  %t1808 = sub i64 %t1807, 1
  %t1809 = call i64 @hash_str(i8* %t1742)
  %t1810 = and i64 %t1809, %t1808
  store i64 0, i64* %t1811
  store i64 %t1810, i64* %t1812
  store i1 false, i1* %t1813
  store i64 -1, i64* %t1814
  store i64 -1, i64* %t1815
  store i1 false, i1* %t1816
  br label %ht_probe_cond_411
ht_probe_cond_411:
  %t1817 = load i64, i64* %t1811
  %t1818 = icmp slt i64 %t1817, %t1807
  br i1 %t1818, label %ht_probe_body_412, label %ht_probe_end_422
ht_probe_body_412:
  %t1819 = load i64, i64* %t1812
  %t1820 = getelementptr inbounds i8, i8* %t1806, i64 %t1819
  %t1821 = load i8, i8* %t1820
  %t1822 = icmp eq i8 %t1821, 0
  br i1 %t1822, label %ht_probe_on_empty_414, label %ht_probe_check_occ_413
ht_probe_check_occ_413:
  %t1823 = icmp eq i8 %t1821, 1
  br i1 %t1823, label %ht_probe_on_occ_417, label %ht_probe_on_tomb_419
ht_probe_on_empty_414:
  %t1824 = load i1, i1* %t1816
  br i1 %t1824, label %ht_probe_after_islot_empty_416, label %ht_probe_set_islot_empty_415
ht_probe_set_islot_empty_415:
  store i64 %t1819, i64* %t1815
  store i1 true, i1* %t1816
  br label %ht_probe_after_islot_empty_416
ht_probe_after_islot_empty_416:
  br label %ht_probe_end_422
ht_probe_on_occ_417:
  %t1825 = getelementptr inbounds i8*, i8** %t1804, i64 %t1819
  %t1826 = load i8*, i8** %t1825
  %t1827 = call i1 @eq_str(i8* %t1826, i8* %t1742)
  br i1 %t1827, label %ht_probe_on_match_418, label %ht_probe_next_421
ht_probe_on_match_418:
  store i1 true, i1* %t1813
  store i64 %t1819, i64* %t1814
  br label %ht_probe_end_422
ht_probe_on_tomb_419:
  %t1828 = load i1, i1* %t1816
  br i1 %t1828, label %ht_probe_next_421, label %ht_probe_set_islot_tomb_420
ht_probe_set_islot_tomb_420:
  store i64 %t1819, i64* %t1815
  store i1 true, i1* %t1816
  br label %ht_probe_next_421
ht_probe_next_421:
  %t1829 = add i64 %t1819, 1
  %t1830 = and i64 %t1829, %t1808
  store i64 %t1830, i64* %t1812
  %t1831 = add i64 %t1817, 1
  store i64 %t1831, i64* %t1811
  br label %ht_probe_cond_411
ht_probe_end_422:
  %t1832 = load i1, i1* %t1813
  %t1833 = load i64, i64* %t1814
  %t1834 = load i64, i64* %t1815
  br i1 %t1832, label %map_insert_overwrite_423, label %map_insert_new_424
map_insert_overwrite_423:
  store i8* %t1742, i8** %t1835
  %t1836 = load i8*, i8** %t1835
  call void @star_rc_release(i8* %t1836)
  %t1837 = getelementptr inbounds i32, i32* %t1805, i64 %t1833
  store i32 9, i32* %t1837
  br label %map_insert_after_425
map_insert_new_424:
  %t1838 = getelementptr inbounds i8, i8* %t1806, i64 %t1834
  %t1839 = load i8, i8* %t1838
  %t1840 = icmp eq i8 %t1839, 2
  br i1 %t1840, label %map_insert_dec_tomb_426, label %map_insert_store_427
map_insert_dec_tomb_426:
  %t1841 = load i64, i64* %t1740
  %t1842 = sub i64 %t1841, 1
  store i64 %t1842, i64* %t1740
  br label %map_insert_store_427
map_insert_store_427:
  store i8 1, i8* %t1838
  %t1843 = getelementptr inbounds i8*, i8** %t1804, i64 %t1834
  store i8* %t1742, i8** %t1843
  %t1844 = getelementptr inbounds i32, i32* %t1805, i64 %t1834
  store i32 9, i32* %t1844
  %t1845 = load i64, i64* %t1736
  %t1846 = add i64 %t1845, 1
  store i64 %t1846, i64* %t1736
  br label %map_insert_after_425
map_insert_after_425:
  %t1847 = getelementptr i8*, i8** null, i32 1
  %t1848 = ptrtoint i8** %t1847 to i64
  %t1849 = getelementptr i32, i32* null, i32 1
  %t1850 = ptrtoint i32* %t1849 to i64
  %t1851 = load i8*, i8** %t0
  %t1852 = icmp eq i8* %t1851, null
  br i1 %t1852, label %map_cow_alloc_428, label %map_cow_check_429
map_cow_alloc_428:
  %t1853 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1854 = call i8* @star_rc_alloc(i64 48, i8* %t1853)
  %t1855 = bitcast i8* %t1854 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1856 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1855, i32 0, i32 0
  store i8** null, i8*** %t1856
  %t1857 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1855, i32 0, i32 1
  store i32* null, i32** %t1857
  %t1858 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1855, i32 0, i32 2
  store i8* null, i8** %t1858
  %t1859 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1855, i32 0, i32 3
  store i64 0, i64* %t1859
  %t1860 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1855, i32 0, i32 4
  store i64 0, i64* %t1860
  %t1861 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1855, i32 0, i32 5
  store i64 0, i64* %t1861
  store i8* %t1854, i8** %t0
  br label %map_cow_done_430
map_cow_check_429:
  %t1862 = getelementptr inbounds i8, i8* %t1851, i64 -16
  %t1863 = bitcast i8* %t1862 to i64*
  %t1864 = load atomic i64, i64* %t1863 seq_cst, align 8
  %t1865 = icmp eq i64 %t1864, 1
  br i1 %t1865, label %map_cow_done_430, label %map_cow_clone_431
map_cow_clone_431:
  %t1866 = bitcast i8* %t1851 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1867 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1866, i32 0, i32 0
  %t1868 = load i8**, i8*** %t1867
  %t1869 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1866, i32 0, i32 1
  %t1870 = load i32*, i32** %t1869
  %t1871 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1866, i32 0, i32 2
  %t1872 = load i8*, i8** %t1871
  %t1873 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1866, i32 0, i32 3
  %t1874 = load i64, i64* %t1873
  %t1875 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1866, i32 0, i32 4
  %t1876 = load i64, i64* %t1875
  %t1877 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1866, i32 0, i32 5
  %t1878 = load i64, i64* %t1877
  %t1879 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t1880 = call i8* @star_rc_alloc(i64 48, i8* %t1879)
  %t1881 = bitcast i8* %t1880 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1882 = mul i64 %t1876, %t1848
  %t1883 = call i8* @malloc(i64 %t1882)
  %t1884 = bitcast i8* %t1883 to i8**
  %t1885 = mul i64 %t1876, %t1850
  %t1886 = call i8* @malloc(i64 %t1885)
  %t1887 = bitcast i8* %t1886 to i32*
  %t1888 = call i8* @malloc(i64 %t1876)
  %t1889 = icmp sgt i64 %t1876, 0
  br i1 %t1889, label %map_cow_copy_432, label %map_cow_after_copy_433
map_cow_copy_432:
  %t1890 = mul i64 %t1876, %t1848
  %t1891 = bitcast i8** %t1868 to i8*
  call i8* @memcpy(i8* %t1883, i8* %t1891, i64 %t1890)
  %t1892 = mul i64 %t1876, %t1850
  %t1893 = bitcast i32* %t1870 to i8*
  call i8* @memcpy(i8* %t1886, i8* %t1893, i64 %t1892)
  call i8* @memcpy(i8* %t1888, i8* %t1872, i64 %t1876)
  store i64 0, i64* %t1894
  br label %map_cow_retain_cond_434
map_cow_retain_cond_434:
  %t1895 = load i64, i64* %t1894
  %t1896 = icmp slt i64 %t1895, %t1876
  br i1 %t1896, label %map_cow_retain_body_435, label %map_cow_retain_end_438
map_cow_retain_body_435:
  %t1897 = getelementptr inbounds i8, i8* %t1888, i64 %t1895
  %t1898 = load i8, i8* %t1897
  %t1899 = icmp eq i8 %t1898, 1
  br i1 %t1899, label %map_cow_retain_occ_436, label %map_cow_retain_next_437
map_cow_retain_occ_436:
  %t1900 = getelementptr inbounds i8*, i8** %t1884, i64 %t1895
  %t1901 = load i8*, i8** %t1900
  call void @star_rc_retain(i8* %t1901)
  br label %map_cow_retain_next_437
map_cow_retain_next_437:
  %t1902 = add i64 %t1895, 1
  store i64 %t1902, i64* %t1894
  br label %map_cow_retain_cond_434
map_cow_retain_end_438:
  br label %map_cow_after_copy_433
map_cow_after_copy_433:
  %t1903 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1881, i32 0, i32 0
  store i8** %t1884, i8*** %t1903
  %t1904 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1881, i32 0, i32 1
  store i32* %t1887, i32** %t1904
  %t1905 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1881, i32 0, i32 2
  store i8* %t1888, i8** %t1905
  %t1906 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1881, i32 0, i32 3
  store i64 %t1874, i64* %t1906
  %t1907 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1881, i32 0, i32 4
  store i64 %t1876, i64* %t1907
  %t1908 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1881, i32 0, i32 5
  store i64 %t1878, i64* %t1908
  call void @star_rc_release(i8* %t1851)
  store i8* %t1880, i8** %t0
  br label %map_cow_done_430
map_cow_done_430:
  %t1909 = load i8*, i8** %t0
  %t1910 = bitcast i8* %t1909 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1911 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1910, i32 0, i32 0
  %t1912 = load i8**, i8*** %t1911
  %t1913 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1910, i32 0, i32 1
  %t1914 = load i32*, i32** %t1913
  %t1915 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1910, i32 0, i32 2
  %t1916 = load i8*, i8** %t1915
  %t1917 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1910, i32 0, i32 3
  %t1918 = load i64, i64* %t1917
  %t1919 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1910, i32 0, i32 4
  %t1920 = load i64, i64* %t1919
  %t1921 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1910, i32 0, i32 5
  %t1922 = load i64, i64* %t1921
  %t1923 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.10, i64 0, i32 2, i64 0
  %t1924 = load i64, i64* %t1917
  %t1925 = load i64, i64* %t1919
  %t1926 = load i64, i64* %t1921
  %t1927 = add i64 %t1924, %t1926
  %t1928 = add i64 %t1927, 1
  %t1929 = mul i64 %t1928, 4
  %t1930 = mul i64 %t1925, 3
  %t1931 = icmp sgt i64 %t1929, %t1930
  br i1 %t1931, label %map_insert_grow_439, label %map_insert_after_grow_440
map_insert_grow_439:
  %t1932 = getelementptr i8*, i8** null, i32 1
  %t1933 = ptrtoint i8** %t1932 to i64
  %t1934 = getelementptr i32, i32* null, i32 1
  %t1935 = ptrtoint i32* %t1934 to i64
  %t1936 = mul i64 %t1925, 2
  %t1937 = icmp sgt i64 %t1936, 0
  %t1938 = select i1 %t1937, i64 %t1936, i64 8
  %t1939 = sub i64 %t1938, 1
  %t1940 = mul i64 %t1938, %t1933
  %t1941 = call i8* @malloc(i64 %t1940)
  %t1942 = bitcast i8* %t1941 to i8**
  %t1943 = mul i64 %t1938, %t1935
  %t1944 = call i8* @malloc(i64 %t1943)
  %t1945 = bitcast i8* %t1944 to i32*
  %t1946 = call i8* @malloc(i64 %t1938)
  store i64 0, i64* %t1947
  br label %ht_fill8_cond_441
ht_fill8_cond_441:
  %t1948 = load i64, i64* %t1947
  %t1949 = icmp slt i64 %t1948, %t1938
  br i1 %t1949, label %ht_fill8_body_442, label %ht_fill8_end_443
ht_fill8_body_442:
  %t1950 = getelementptr inbounds i8, i8* %t1946, i64 %t1948
  store i8 0, i8* %t1950
  %t1951 = add i64 %t1948, 1
  store i64 %t1951, i64* %t1947
  br label %ht_fill8_cond_441
ht_fill8_end_443:
  %t1952 = load i8**, i8*** %t1911
  %t1953 = load i32*, i32** %t1913
  %t1954 = load i8*, i8** %t1915
  store i64 0, i64* %t1955
  br label %map_grow_cond_444
map_grow_cond_444:
  %t1956 = load i64, i64* %t1955
  %t1957 = icmp slt i64 %t1956, %t1925
  br i1 %t1957, label %map_grow_body_445, label %map_grow_end_448
map_grow_body_445:
  %t1958 = getelementptr inbounds i8, i8* %t1954, i64 %t1956
  %t1959 = load i8, i8* %t1958
  %t1960 = icmp eq i8 %t1959, 1
  br i1 %t1960, label %map_grow_occ_446, label %map_grow_next_447
map_grow_occ_446:
  %t1961 = getelementptr inbounds i8*, i8** %t1952, i64 %t1956
  %t1962 = load i8*, i8** %t1961
  %t1963 = getelementptr inbounds i32, i32* %t1953, i64 %t1956
  %t1964 = load i32, i32* %t1963
  %t1965 = call i64 @hash_str(i8* %t1962)
  %t1966 = and i64 %t1965, %t1939
  store i64 0, i64* %t1967
  store i64 %t1966, i64* %t1968
  br label %ht_fe_cond_449
ht_fe_cond_449:
  %t1969 = load i64, i64* %t1967
  %t1970 = icmp slt i64 %t1969, %t1938
  br i1 %t1970, label %ht_fe_body_450, label %ht_fe_end_452
ht_fe_body_450:
  %t1971 = load i64, i64* %t1968
  %t1972 = getelementptr inbounds i8, i8* %t1946, i64 %t1971
  %t1973 = load i8, i8* %t1972
  %t1974 = icmp eq i8 %t1973, 0
  br i1 %t1974, label %ht_fe_end_452, label %ht_fe_next_451
ht_fe_next_451:
  %t1975 = add i64 %t1971, 1
  %t1976 = and i64 %t1975, %t1939
  store i64 %t1976, i64* %t1968
  %t1977 = add i64 %t1969, 1
  store i64 %t1977, i64* %t1967
  br label %ht_fe_cond_449
ht_fe_end_452:
  %t1978 = load i64, i64* %t1968
  %t1979 = getelementptr inbounds i8, i8* %t1946, i64 %t1978
  store i8 1, i8* %t1979
  %t1980 = getelementptr inbounds i8*, i8** %t1942, i64 %t1978
  store i8* %t1962, i8** %t1980
  %t1981 = getelementptr inbounds i32, i32* %t1945, i64 %t1978
  store i32 %t1964, i32* %t1981
  br label %map_grow_next_447
map_grow_next_447:
  %t1982 = add i64 %t1956, 1
  store i64 %t1982, i64* %t1955
  br label %map_grow_cond_444
map_grow_end_448:
  %t1983 = bitcast i8** %t1952 to i8*
  call void @free(i8* %t1983)
  %t1984 = bitcast i32* %t1953 to i8*
  call void @free(i8* %t1984)
  call void @free(i8* %t1954)
  store i8** %t1942, i8*** %t1911
  store i32* %t1945, i32** %t1913
  store i8* %t1946, i8** %t1915
  store i64 %t1938, i64* %t1919
  store i64 0, i64* %t1921
  br label %map_insert_after_grow_440
map_insert_after_grow_440:
  %t1985 = load i8**, i8*** %t1911
  %t1986 = load i32*, i32** %t1913
  %t1987 = load i8*, i8** %t1915
  %t1988 = load i64, i64* %t1919
  %t1989 = sub i64 %t1988, 1
  %t1990 = call i64 @hash_str(i8* %t1923)
  %t1991 = and i64 %t1990, %t1989
  store i64 0, i64* %t1992
  store i64 %t1991, i64* %t1993
  store i1 false, i1* %t1994
  store i64 -1, i64* %t1995
  store i64 -1, i64* %t1996
  store i1 false, i1* %t1997
  br label %ht_probe_cond_453
ht_probe_cond_453:
  %t1998 = load i64, i64* %t1992
  %t1999 = icmp slt i64 %t1998, %t1988
  br i1 %t1999, label %ht_probe_body_454, label %ht_probe_end_464
ht_probe_body_454:
  %t2000 = load i64, i64* %t1993
  %t2001 = getelementptr inbounds i8, i8* %t1987, i64 %t2000
  %t2002 = load i8, i8* %t2001
  %t2003 = icmp eq i8 %t2002, 0
  br i1 %t2003, label %ht_probe_on_empty_456, label %ht_probe_check_occ_455
ht_probe_check_occ_455:
  %t2004 = icmp eq i8 %t2002, 1
  br i1 %t2004, label %ht_probe_on_occ_459, label %ht_probe_on_tomb_461
ht_probe_on_empty_456:
  %t2005 = load i1, i1* %t1997
  br i1 %t2005, label %ht_probe_after_islot_empty_458, label %ht_probe_set_islot_empty_457
ht_probe_set_islot_empty_457:
  store i64 %t2000, i64* %t1996
  store i1 true, i1* %t1997
  br label %ht_probe_after_islot_empty_458
ht_probe_after_islot_empty_458:
  br label %ht_probe_end_464
ht_probe_on_occ_459:
  %t2006 = getelementptr inbounds i8*, i8** %t1985, i64 %t2000
  %t2007 = load i8*, i8** %t2006
  %t2008 = call i1 @eq_str(i8* %t2007, i8* %t1923)
  br i1 %t2008, label %ht_probe_on_match_460, label %ht_probe_next_463
ht_probe_on_match_460:
  store i1 true, i1* %t1994
  store i64 %t2000, i64* %t1995
  br label %ht_probe_end_464
ht_probe_on_tomb_461:
  %t2009 = load i1, i1* %t1997
  br i1 %t2009, label %ht_probe_next_463, label %ht_probe_set_islot_tomb_462
ht_probe_set_islot_tomb_462:
  store i64 %t2000, i64* %t1996
  store i1 true, i1* %t1997
  br label %ht_probe_next_463
ht_probe_next_463:
  %t2010 = add i64 %t2000, 1
  %t2011 = and i64 %t2010, %t1989
  store i64 %t2011, i64* %t1993
  %t2012 = add i64 %t1998, 1
  store i64 %t2012, i64* %t1992
  br label %ht_probe_cond_453
ht_probe_end_464:
  %t2013 = load i1, i1* %t1994
  %t2014 = load i64, i64* %t1995
  %t2015 = load i64, i64* %t1996
  br i1 %t2013, label %map_insert_overwrite_465, label %map_insert_new_466
map_insert_overwrite_465:
  store i8* %t1923, i8** %t2016
  %t2017 = load i8*, i8** %t2016
  call void @star_rc_release(i8* %t2017)
  %t2018 = getelementptr inbounds i32, i32* %t1986, i64 %t2014
  store i32 10, i32* %t2018
  br label %map_insert_after_467
map_insert_new_466:
  %t2019 = getelementptr inbounds i8, i8* %t1987, i64 %t2015
  %t2020 = load i8, i8* %t2019
  %t2021 = icmp eq i8 %t2020, 2
  br i1 %t2021, label %map_insert_dec_tomb_468, label %map_insert_store_469
map_insert_dec_tomb_468:
  %t2022 = load i64, i64* %t1921
  %t2023 = sub i64 %t2022, 1
  store i64 %t2023, i64* %t1921
  br label %map_insert_store_469
map_insert_store_469:
  store i8 1, i8* %t2019
  %t2024 = getelementptr inbounds i8*, i8** %t1985, i64 %t2015
  store i8* %t1923, i8** %t2024
  %t2025 = getelementptr inbounds i32, i32* %t1986, i64 %t2015
  store i32 10, i32* %t2025
  %t2026 = load i64, i64* %t1917
  %t2027 = add i64 %t2026, 1
  store i64 %t2027, i64* %t1917
  br label %map_insert_after_467
map_insert_after_467:
  %t2028 = getelementptr i8*, i8** null, i32 1
  %t2029 = ptrtoint i8** %t2028 to i64
  %t2030 = getelementptr i32, i32* null, i32 1
  %t2031 = ptrtoint i32* %t2030 to i64
  %t2032 = load i8*, i8** %t0
  %t2033 = icmp eq i8* %t2032, null
  br i1 %t2033, label %map_cow_alloc_470, label %map_cow_check_471
map_cow_alloc_470:
  %t2034 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2035 = call i8* @star_rc_alloc(i64 48, i8* %t2034)
  %t2036 = bitcast i8* %t2035 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2037 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2036, i32 0, i32 0
  store i8** null, i8*** %t2037
  %t2038 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2036, i32 0, i32 1
  store i32* null, i32** %t2038
  %t2039 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2036, i32 0, i32 2
  store i8* null, i8** %t2039
  %t2040 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2036, i32 0, i32 3
  store i64 0, i64* %t2040
  %t2041 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2036, i32 0, i32 4
  store i64 0, i64* %t2041
  %t2042 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2036, i32 0, i32 5
  store i64 0, i64* %t2042
  store i8* %t2035, i8** %t0
  br label %map_cow_done_472
map_cow_check_471:
  %t2043 = getelementptr inbounds i8, i8* %t2032, i64 -16
  %t2044 = bitcast i8* %t2043 to i64*
  %t2045 = load atomic i64, i64* %t2044 seq_cst, align 8
  %t2046 = icmp eq i64 %t2045, 1
  br i1 %t2046, label %map_cow_done_472, label %map_cow_clone_473
map_cow_clone_473:
  %t2047 = bitcast i8* %t2032 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2048 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2047, i32 0, i32 0
  %t2049 = load i8**, i8*** %t2048
  %t2050 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2047, i32 0, i32 1
  %t2051 = load i32*, i32** %t2050
  %t2052 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2047, i32 0, i32 2
  %t2053 = load i8*, i8** %t2052
  %t2054 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2047, i32 0, i32 3
  %t2055 = load i64, i64* %t2054
  %t2056 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2047, i32 0, i32 4
  %t2057 = load i64, i64* %t2056
  %t2058 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2047, i32 0, i32 5
  %t2059 = load i64, i64* %t2058
  %t2060 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2061 = call i8* @star_rc_alloc(i64 48, i8* %t2060)
  %t2062 = bitcast i8* %t2061 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2063 = mul i64 %t2057, %t2029
  %t2064 = call i8* @malloc(i64 %t2063)
  %t2065 = bitcast i8* %t2064 to i8**
  %t2066 = mul i64 %t2057, %t2031
  %t2067 = call i8* @malloc(i64 %t2066)
  %t2068 = bitcast i8* %t2067 to i32*
  %t2069 = call i8* @malloc(i64 %t2057)
  %t2070 = icmp sgt i64 %t2057, 0
  br i1 %t2070, label %map_cow_copy_474, label %map_cow_after_copy_475
map_cow_copy_474:
  %t2071 = mul i64 %t2057, %t2029
  %t2072 = bitcast i8** %t2049 to i8*
  call i8* @memcpy(i8* %t2064, i8* %t2072, i64 %t2071)
  %t2073 = mul i64 %t2057, %t2031
  %t2074 = bitcast i32* %t2051 to i8*
  call i8* @memcpy(i8* %t2067, i8* %t2074, i64 %t2073)
  call i8* @memcpy(i8* %t2069, i8* %t2053, i64 %t2057)
  store i64 0, i64* %t2075
  br label %map_cow_retain_cond_476
map_cow_retain_cond_476:
  %t2076 = load i64, i64* %t2075
  %t2077 = icmp slt i64 %t2076, %t2057
  br i1 %t2077, label %map_cow_retain_body_477, label %map_cow_retain_end_480
map_cow_retain_body_477:
  %t2078 = getelementptr inbounds i8, i8* %t2069, i64 %t2076
  %t2079 = load i8, i8* %t2078
  %t2080 = icmp eq i8 %t2079, 1
  br i1 %t2080, label %map_cow_retain_occ_478, label %map_cow_retain_next_479
map_cow_retain_occ_478:
  %t2081 = getelementptr inbounds i8*, i8** %t2065, i64 %t2076
  %t2082 = load i8*, i8** %t2081
  call void @star_rc_retain(i8* %t2082)
  br label %map_cow_retain_next_479
map_cow_retain_next_479:
  %t2083 = add i64 %t2076, 1
  store i64 %t2083, i64* %t2075
  br label %map_cow_retain_cond_476
map_cow_retain_end_480:
  br label %map_cow_after_copy_475
map_cow_after_copy_475:
  %t2084 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2062, i32 0, i32 0
  store i8** %t2065, i8*** %t2084
  %t2085 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2062, i32 0, i32 1
  store i32* %t2068, i32** %t2085
  %t2086 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2062, i32 0, i32 2
  store i8* %t2069, i8** %t2086
  %t2087 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2062, i32 0, i32 3
  store i64 %t2055, i64* %t2087
  %t2088 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2062, i32 0, i32 4
  store i64 %t2057, i64* %t2088
  %t2089 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2062, i32 0, i32 5
  store i64 %t2059, i64* %t2089
  call void @star_rc_release(i8* %t2032)
  store i8* %t2061, i8** %t0
  br label %map_cow_done_472
map_cow_done_472:
  %t2090 = load i8*, i8** %t0
  %t2091 = bitcast i8* %t2090 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2092 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2091, i32 0, i32 0
  %t2093 = load i8**, i8*** %t2092
  %t2094 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2091, i32 0, i32 1
  %t2095 = load i32*, i32** %t2094
  %t2096 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2091, i32 0, i32 2
  %t2097 = load i8*, i8** %t2096
  %t2098 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2091, i32 0, i32 3
  %t2099 = load i64, i64* %t2098
  %t2100 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2091, i32 0, i32 4
  %t2101 = load i64, i64* %t2100
  %t2102 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2091, i32 0, i32 5
  %t2103 = load i64, i64* %t2102
  %t2104 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t2105 = load i64, i64* %t2098
  %t2106 = load i64, i64* %t2100
  %t2107 = load i64, i64* %t2102
  %t2108 = add i64 %t2105, %t2107
  %t2109 = add i64 %t2108, 1
  %t2110 = mul i64 %t2109, 4
  %t2111 = mul i64 %t2106, 3
  %t2112 = icmp sgt i64 %t2110, %t2111
  br i1 %t2112, label %map_insert_grow_481, label %map_insert_after_grow_482
map_insert_grow_481:
  %t2113 = getelementptr i8*, i8** null, i32 1
  %t2114 = ptrtoint i8** %t2113 to i64
  %t2115 = getelementptr i32, i32* null, i32 1
  %t2116 = ptrtoint i32* %t2115 to i64
  %t2117 = mul i64 %t2106, 2
  %t2118 = icmp sgt i64 %t2117, 0
  %t2119 = select i1 %t2118, i64 %t2117, i64 8
  %t2120 = sub i64 %t2119, 1
  %t2121 = mul i64 %t2119, %t2114
  %t2122 = call i8* @malloc(i64 %t2121)
  %t2123 = bitcast i8* %t2122 to i8**
  %t2124 = mul i64 %t2119, %t2116
  %t2125 = call i8* @malloc(i64 %t2124)
  %t2126 = bitcast i8* %t2125 to i32*
  %t2127 = call i8* @malloc(i64 %t2119)
  store i64 0, i64* %t2128
  br label %ht_fill8_cond_483
ht_fill8_cond_483:
  %t2129 = load i64, i64* %t2128
  %t2130 = icmp slt i64 %t2129, %t2119
  br i1 %t2130, label %ht_fill8_body_484, label %ht_fill8_end_485
ht_fill8_body_484:
  %t2131 = getelementptr inbounds i8, i8* %t2127, i64 %t2129
  store i8 0, i8* %t2131
  %t2132 = add i64 %t2129, 1
  store i64 %t2132, i64* %t2128
  br label %ht_fill8_cond_483
ht_fill8_end_485:
  %t2133 = load i8**, i8*** %t2092
  %t2134 = load i32*, i32** %t2094
  %t2135 = load i8*, i8** %t2096
  store i64 0, i64* %t2136
  br label %map_grow_cond_486
map_grow_cond_486:
  %t2137 = load i64, i64* %t2136
  %t2138 = icmp slt i64 %t2137, %t2106
  br i1 %t2138, label %map_grow_body_487, label %map_grow_end_490
map_grow_body_487:
  %t2139 = getelementptr inbounds i8, i8* %t2135, i64 %t2137
  %t2140 = load i8, i8* %t2139
  %t2141 = icmp eq i8 %t2140, 1
  br i1 %t2141, label %map_grow_occ_488, label %map_grow_next_489
map_grow_occ_488:
  %t2142 = getelementptr inbounds i8*, i8** %t2133, i64 %t2137
  %t2143 = load i8*, i8** %t2142
  %t2144 = getelementptr inbounds i32, i32* %t2134, i64 %t2137
  %t2145 = load i32, i32* %t2144
  %t2146 = call i64 @hash_str(i8* %t2143)
  %t2147 = and i64 %t2146, %t2120
  store i64 0, i64* %t2148
  store i64 %t2147, i64* %t2149
  br label %ht_fe_cond_491
ht_fe_cond_491:
  %t2150 = load i64, i64* %t2148
  %t2151 = icmp slt i64 %t2150, %t2119
  br i1 %t2151, label %ht_fe_body_492, label %ht_fe_end_494
ht_fe_body_492:
  %t2152 = load i64, i64* %t2149
  %t2153 = getelementptr inbounds i8, i8* %t2127, i64 %t2152
  %t2154 = load i8, i8* %t2153
  %t2155 = icmp eq i8 %t2154, 0
  br i1 %t2155, label %ht_fe_end_494, label %ht_fe_next_493
ht_fe_next_493:
  %t2156 = add i64 %t2152, 1
  %t2157 = and i64 %t2156, %t2120
  store i64 %t2157, i64* %t2149
  %t2158 = add i64 %t2150, 1
  store i64 %t2158, i64* %t2148
  br label %ht_fe_cond_491
ht_fe_end_494:
  %t2159 = load i64, i64* %t2149
  %t2160 = getelementptr inbounds i8, i8* %t2127, i64 %t2159
  store i8 1, i8* %t2160
  %t2161 = getelementptr inbounds i8*, i8** %t2123, i64 %t2159
  store i8* %t2143, i8** %t2161
  %t2162 = getelementptr inbounds i32, i32* %t2126, i64 %t2159
  store i32 %t2145, i32* %t2162
  br label %map_grow_next_489
map_grow_next_489:
  %t2163 = add i64 %t2137, 1
  store i64 %t2163, i64* %t2136
  br label %map_grow_cond_486
map_grow_end_490:
  %t2164 = bitcast i8** %t2133 to i8*
  call void @free(i8* %t2164)
  %t2165 = bitcast i32* %t2134 to i8*
  call void @free(i8* %t2165)
  call void @free(i8* %t2135)
  store i8** %t2123, i8*** %t2092
  store i32* %t2126, i32** %t2094
  store i8* %t2127, i8** %t2096
  store i64 %t2119, i64* %t2100
  store i64 0, i64* %t2102
  br label %map_insert_after_grow_482
map_insert_after_grow_482:
  %t2166 = load i8**, i8*** %t2092
  %t2167 = load i32*, i32** %t2094
  %t2168 = load i8*, i8** %t2096
  %t2169 = load i64, i64* %t2100
  %t2170 = sub i64 %t2169, 1
  %t2171 = call i64 @hash_str(i8* %t2104)
  %t2172 = and i64 %t2171, %t2170
  store i64 0, i64* %t2173
  store i64 %t2172, i64* %t2174
  store i1 false, i1* %t2175
  store i64 -1, i64* %t2176
  store i64 -1, i64* %t2177
  store i1 false, i1* %t2178
  br label %ht_probe_cond_495
ht_probe_cond_495:
  %t2179 = load i64, i64* %t2173
  %t2180 = icmp slt i64 %t2179, %t2169
  br i1 %t2180, label %ht_probe_body_496, label %ht_probe_end_506
ht_probe_body_496:
  %t2181 = load i64, i64* %t2174
  %t2182 = getelementptr inbounds i8, i8* %t2168, i64 %t2181
  %t2183 = load i8, i8* %t2182
  %t2184 = icmp eq i8 %t2183, 0
  br i1 %t2184, label %ht_probe_on_empty_498, label %ht_probe_check_occ_497
ht_probe_check_occ_497:
  %t2185 = icmp eq i8 %t2183, 1
  br i1 %t2185, label %ht_probe_on_occ_501, label %ht_probe_on_tomb_503
ht_probe_on_empty_498:
  %t2186 = load i1, i1* %t2178
  br i1 %t2186, label %ht_probe_after_islot_empty_500, label %ht_probe_set_islot_empty_499
ht_probe_set_islot_empty_499:
  store i64 %t2181, i64* %t2177
  store i1 true, i1* %t2178
  br label %ht_probe_after_islot_empty_500
ht_probe_after_islot_empty_500:
  br label %ht_probe_end_506
ht_probe_on_occ_501:
  %t2187 = getelementptr inbounds i8*, i8** %t2166, i64 %t2181
  %t2188 = load i8*, i8** %t2187
  %t2189 = call i1 @eq_str(i8* %t2188, i8* %t2104)
  br i1 %t2189, label %ht_probe_on_match_502, label %ht_probe_next_505
ht_probe_on_match_502:
  store i1 true, i1* %t2175
  store i64 %t2181, i64* %t2176
  br label %ht_probe_end_506
ht_probe_on_tomb_503:
  %t2190 = load i1, i1* %t2178
  br i1 %t2190, label %ht_probe_next_505, label %ht_probe_set_islot_tomb_504
ht_probe_set_islot_tomb_504:
  store i64 %t2181, i64* %t2177
  store i1 true, i1* %t2178
  br label %ht_probe_next_505
ht_probe_next_505:
  %t2191 = add i64 %t2181, 1
  %t2192 = and i64 %t2191, %t2170
  store i64 %t2192, i64* %t2174
  %t2193 = add i64 %t2179, 1
  store i64 %t2193, i64* %t2173
  br label %ht_probe_cond_495
ht_probe_end_506:
  %t2194 = load i1, i1* %t2175
  %t2195 = load i64, i64* %t2176
  %t2196 = load i64, i64* %t2177
  br i1 %t2194, label %map_insert_overwrite_507, label %map_insert_new_508
map_insert_overwrite_507:
  store i8* %t2104, i8** %t2197
  %t2198 = load i8*, i8** %t2197
  call void @star_rc_release(i8* %t2198)
  %t2199 = getelementptr inbounds i32, i32* %t2167, i64 %t2195
  store i32 11, i32* %t2199
  br label %map_insert_after_509
map_insert_new_508:
  %t2200 = getelementptr inbounds i8, i8* %t2168, i64 %t2196
  %t2201 = load i8, i8* %t2200
  %t2202 = icmp eq i8 %t2201, 2
  br i1 %t2202, label %map_insert_dec_tomb_510, label %map_insert_store_511
map_insert_dec_tomb_510:
  %t2203 = load i64, i64* %t2102
  %t2204 = sub i64 %t2203, 1
  store i64 %t2204, i64* %t2102
  br label %map_insert_store_511
map_insert_store_511:
  store i8 1, i8* %t2200
  %t2205 = getelementptr inbounds i8*, i8** %t2166, i64 %t2196
  store i8* %t2104, i8** %t2205
  %t2206 = getelementptr inbounds i32, i32* %t2167, i64 %t2196
  store i32 11, i32* %t2206
  %t2207 = load i64, i64* %t2098
  %t2208 = add i64 %t2207, 1
  store i64 %t2208, i64* %t2098
  br label %map_insert_after_509
map_insert_after_509:
  %t2209 = getelementptr i8*, i8** null, i32 1
  %t2210 = ptrtoint i8** %t2209 to i64
  %t2211 = getelementptr i32, i32* null, i32 1
  %t2212 = ptrtoint i32* %t2211 to i64
  %t2213 = load i8*, i8** %t0
  %t2214 = icmp eq i8* %t2213, null
  br i1 %t2214, label %map_cow_alloc_512, label %map_cow_check_513
map_cow_alloc_512:
  %t2215 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2216 = call i8* @star_rc_alloc(i64 48, i8* %t2215)
  %t2217 = bitcast i8* %t2216 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2218 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2217, i32 0, i32 0
  store i8** null, i8*** %t2218
  %t2219 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2217, i32 0, i32 1
  store i32* null, i32** %t2219
  %t2220 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2217, i32 0, i32 2
  store i8* null, i8** %t2220
  %t2221 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2217, i32 0, i32 3
  store i64 0, i64* %t2221
  %t2222 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2217, i32 0, i32 4
  store i64 0, i64* %t2222
  %t2223 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2217, i32 0, i32 5
  store i64 0, i64* %t2223
  store i8* %t2216, i8** %t0
  br label %map_cow_done_514
map_cow_check_513:
  %t2224 = getelementptr inbounds i8, i8* %t2213, i64 -16
  %t2225 = bitcast i8* %t2224 to i64*
  %t2226 = load atomic i64, i64* %t2225 seq_cst, align 8
  %t2227 = icmp eq i64 %t2226, 1
  br i1 %t2227, label %map_cow_done_514, label %map_cow_clone_515
map_cow_clone_515:
  %t2228 = bitcast i8* %t2213 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2229 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2228, i32 0, i32 0
  %t2230 = load i8**, i8*** %t2229
  %t2231 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2228, i32 0, i32 1
  %t2232 = load i32*, i32** %t2231
  %t2233 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2228, i32 0, i32 2
  %t2234 = load i8*, i8** %t2233
  %t2235 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2228, i32 0, i32 3
  %t2236 = load i64, i64* %t2235
  %t2237 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2228, i32 0, i32 4
  %t2238 = load i64, i64* %t2237
  %t2239 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2228, i32 0, i32 5
  %t2240 = load i64, i64* %t2239
  %t2241 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2242 = call i8* @star_rc_alloc(i64 48, i8* %t2241)
  %t2243 = bitcast i8* %t2242 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2244 = mul i64 %t2238, %t2210
  %t2245 = call i8* @malloc(i64 %t2244)
  %t2246 = bitcast i8* %t2245 to i8**
  %t2247 = mul i64 %t2238, %t2212
  %t2248 = call i8* @malloc(i64 %t2247)
  %t2249 = bitcast i8* %t2248 to i32*
  %t2250 = call i8* @malloc(i64 %t2238)
  %t2251 = icmp sgt i64 %t2238, 0
  br i1 %t2251, label %map_cow_copy_516, label %map_cow_after_copy_517
map_cow_copy_516:
  %t2252 = mul i64 %t2238, %t2210
  %t2253 = bitcast i8** %t2230 to i8*
  call i8* @memcpy(i8* %t2245, i8* %t2253, i64 %t2252)
  %t2254 = mul i64 %t2238, %t2212
  %t2255 = bitcast i32* %t2232 to i8*
  call i8* @memcpy(i8* %t2248, i8* %t2255, i64 %t2254)
  call i8* @memcpy(i8* %t2250, i8* %t2234, i64 %t2238)
  store i64 0, i64* %t2256
  br label %map_cow_retain_cond_518
map_cow_retain_cond_518:
  %t2257 = load i64, i64* %t2256
  %t2258 = icmp slt i64 %t2257, %t2238
  br i1 %t2258, label %map_cow_retain_body_519, label %map_cow_retain_end_522
map_cow_retain_body_519:
  %t2259 = getelementptr inbounds i8, i8* %t2250, i64 %t2257
  %t2260 = load i8, i8* %t2259
  %t2261 = icmp eq i8 %t2260, 1
  br i1 %t2261, label %map_cow_retain_occ_520, label %map_cow_retain_next_521
map_cow_retain_occ_520:
  %t2262 = getelementptr inbounds i8*, i8** %t2246, i64 %t2257
  %t2263 = load i8*, i8** %t2262
  call void @star_rc_retain(i8* %t2263)
  br label %map_cow_retain_next_521
map_cow_retain_next_521:
  %t2264 = add i64 %t2257, 1
  store i64 %t2264, i64* %t2256
  br label %map_cow_retain_cond_518
map_cow_retain_end_522:
  br label %map_cow_after_copy_517
map_cow_after_copy_517:
  %t2265 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 0
  store i8** %t2246, i8*** %t2265
  %t2266 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 1
  store i32* %t2249, i32** %t2266
  %t2267 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 2
  store i8* %t2250, i8** %t2267
  %t2268 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 3
  store i64 %t2236, i64* %t2268
  %t2269 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 4
  store i64 %t2238, i64* %t2269
  %t2270 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 5
  store i64 %t2240, i64* %t2270
  call void @star_rc_release(i8* %t2213)
  store i8* %t2242, i8** %t0
  br label %map_cow_done_514
map_cow_done_514:
  %t2271 = load i8*, i8** %t0
  %t2272 = bitcast i8* %t2271 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2273 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2272, i32 0, i32 0
  %t2274 = load i8**, i8*** %t2273
  %t2275 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2272, i32 0, i32 1
  %t2276 = load i32*, i32** %t2275
  %t2277 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2272, i32 0, i32 2
  %t2278 = load i8*, i8** %t2277
  %t2279 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2272, i32 0, i32 3
  %t2280 = load i64, i64* %t2279
  %t2281 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2272, i32 0, i32 4
  %t2282 = load i64, i64* %t2281
  %t2283 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2272, i32 0, i32 5
  %t2284 = load i64, i64* %t2283
  %t2285 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.12, i64 0, i32 2, i64 0
  %t2286 = load i64, i64* %t2279
  %t2287 = load i64, i64* %t2281
  %t2288 = load i64, i64* %t2283
  %t2289 = add i64 %t2286, %t2288
  %t2290 = add i64 %t2289, 1
  %t2291 = mul i64 %t2290, 4
  %t2292 = mul i64 %t2287, 3
  %t2293 = icmp sgt i64 %t2291, %t2292
  br i1 %t2293, label %map_insert_grow_523, label %map_insert_after_grow_524
map_insert_grow_523:
  %t2294 = getelementptr i8*, i8** null, i32 1
  %t2295 = ptrtoint i8** %t2294 to i64
  %t2296 = getelementptr i32, i32* null, i32 1
  %t2297 = ptrtoint i32* %t2296 to i64
  %t2298 = mul i64 %t2287, 2
  %t2299 = icmp sgt i64 %t2298, 0
  %t2300 = select i1 %t2299, i64 %t2298, i64 8
  %t2301 = sub i64 %t2300, 1
  %t2302 = mul i64 %t2300, %t2295
  %t2303 = call i8* @malloc(i64 %t2302)
  %t2304 = bitcast i8* %t2303 to i8**
  %t2305 = mul i64 %t2300, %t2297
  %t2306 = call i8* @malloc(i64 %t2305)
  %t2307 = bitcast i8* %t2306 to i32*
  %t2308 = call i8* @malloc(i64 %t2300)
  store i64 0, i64* %t2309
  br label %ht_fill8_cond_525
ht_fill8_cond_525:
  %t2310 = load i64, i64* %t2309
  %t2311 = icmp slt i64 %t2310, %t2300
  br i1 %t2311, label %ht_fill8_body_526, label %ht_fill8_end_527
ht_fill8_body_526:
  %t2312 = getelementptr inbounds i8, i8* %t2308, i64 %t2310
  store i8 0, i8* %t2312
  %t2313 = add i64 %t2310, 1
  store i64 %t2313, i64* %t2309
  br label %ht_fill8_cond_525
ht_fill8_end_527:
  %t2314 = load i8**, i8*** %t2273
  %t2315 = load i32*, i32** %t2275
  %t2316 = load i8*, i8** %t2277
  store i64 0, i64* %t2317
  br label %map_grow_cond_528
map_grow_cond_528:
  %t2318 = load i64, i64* %t2317
  %t2319 = icmp slt i64 %t2318, %t2287
  br i1 %t2319, label %map_grow_body_529, label %map_grow_end_532
map_grow_body_529:
  %t2320 = getelementptr inbounds i8, i8* %t2316, i64 %t2318
  %t2321 = load i8, i8* %t2320
  %t2322 = icmp eq i8 %t2321, 1
  br i1 %t2322, label %map_grow_occ_530, label %map_grow_next_531
map_grow_occ_530:
  %t2323 = getelementptr inbounds i8*, i8** %t2314, i64 %t2318
  %t2324 = load i8*, i8** %t2323
  %t2325 = getelementptr inbounds i32, i32* %t2315, i64 %t2318
  %t2326 = load i32, i32* %t2325
  %t2327 = call i64 @hash_str(i8* %t2324)
  %t2328 = and i64 %t2327, %t2301
  store i64 0, i64* %t2329
  store i64 %t2328, i64* %t2330
  br label %ht_fe_cond_533
ht_fe_cond_533:
  %t2331 = load i64, i64* %t2329
  %t2332 = icmp slt i64 %t2331, %t2300
  br i1 %t2332, label %ht_fe_body_534, label %ht_fe_end_536
ht_fe_body_534:
  %t2333 = load i64, i64* %t2330
  %t2334 = getelementptr inbounds i8, i8* %t2308, i64 %t2333
  %t2335 = load i8, i8* %t2334
  %t2336 = icmp eq i8 %t2335, 0
  br i1 %t2336, label %ht_fe_end_536, label %ht_fe_next_535
ht_fe_next_535:
  %t2337 = add i64 %t2333, 1
  %t2338 = and i64 %t2337, %t2301
  store i64 %t2338, i64* %t2330
  %t2339 = add i64 %t2331, 1
  store i64 %t2339, i64* %t2329
  br label %ht_fe_cond_533
ht_fe_end_536:
  %t2340 = load i64, i64* %t2330
  %t2341 = getelementptr inbounds i8, i8* %t2308, i64 %t2340
  store i8 1, i8* %t2341
  %t2342 = getelementptr inbounds i8*, i8** %t2304, i64 %t2340
  store i8* %t2324, i8** %t2342
  %t2343 = getelementptr inbounds i32, i32* %t2307, i64 %t2340
  store i32 %t2326, i32* %t2343
  br label %map_grow_next_531
map_grow_next_531:
  %t2344 = add i64 %t2318, 1
  store i64 %t2344, i64* %t2317
  br label %map_grow_cond_528
map_grow_end_532:
  %t2345 = bitcast i8** %t2314 to i8*
  call void @free(i8* %t2345)
  %t2346 = bitcast i32* %t2315 to i8*
  call void @free(i8* %t2346)
  call void @free(i8* %t2316)
  store i8** %t2304, i8*** %t2273
  store i32* %t2307, i32** %t2275
  store i8* %t2308, i8** %t2277
  store i64 %t2300, i64* %t2281
  store i64 0, i64* %t2283
  br label %map_insert_after_grow_524
map_insert_after_grow_524:
  %t2347 = load i8**, i8*** %t2273
  %t2348 = load i32*, i32** %t2275
  %t2349 = load i8*, i8** %t2277
  %t2350 = load i64, i64* %t2281
  %t2351 = sub i64 %t2350, 1
  %t2352 = call i64 @hash_str(i8* %t2285)
  %t2353 = and i64 %t2352, %t2351
  store i64 0, i64* %t2354
  store i64 %t2353, i64* %t2355
  store i1 false, i1* %t2356
  store i64 -1, i64* %t2357
  store i64 -1, i64* %t2358
  store i1 false, i1* %t2359
  br label %ht_probe_cond_537
ht_probe_cond_537:
  %t2360 = load i64, i64* %t2354
  %t2361 = icmp slt i64 %t2360, %t2350
  br i1 %t2361, label %ht_probe_body_538, label %ht_probe_end_548
ht_probe_body_538:
  %t2362 = load i64, i64* %t2355
  %t2363 = getelementptr inbounds i8, i8* %t2349, i64 %t2362
  %t2364 = load i8, i8* %t2363
  %t2365 = icmp eq i8 %t2364, 0
  br i1 %t2365, label %ht_probe_on_empty_540, label %ht_probe_check_occ_539
ht_probe_check_occ_539:
  %t2366 = icmp eq i8 %t2364, 1
  br i1 %t2366, label %ht_probe_on_occ_543, label %ht_probe_on_tomb_545
ht_probe_on_empty_540:
  %t2367 = load i1, i1* %t2359
  br i1 %t2367, label %ht_probe_after_islot_empty_542, label %ht_probe_set_islot_empty_541
ht_probe_set_islot_empty_541:
  store i64 %t2362, i64* %t2358
  store i1 true, i1* %t2359
  br label %ht_probe_after_islot_empty_542
ht_probe_after_islot_empty_542:
  br label %ht_probe_end_548
ht_probe_on_occ_543:
  %t2368 = getelementptr inbounds i8*, i8** %t2347, i64 %t2362
  %t2369 = load i8*, i8** %t2368
  %t2370 = call i1 @eq_str(i8* %t2369, i8* %t2285)
  br i1 %t2370, label %ht_probe_on_match_544, label %ht_probe_next_547
ht_probe_on_match_544:
  store i1 true, i1* %t2356
  store i64 %t2362, i64* %t2357
  br label %ht_probe_end_548
ht_probe_on_tomb_545:
  %t2371 = load i1, i1* %t2359
  br i1 %t2371, label %ht_probe_next_547, label %ht_probe_set_islot_tomb_546
ht_probe_set_islot_tomb_546:
  store i64 %t2362, i64* %t2358
  store i1 true, i1* %t2359
  br label %ht_probe_next_547
ht_probe_next_547:
  %t2372 = add i64 %t2362, 1
  %t2373 = and i64 %t2372, %t2351
  store i64 %t2373, i64* %t2355
  %t2374 = add i64 %t2360, 1
  store i64 %t2374, i64* %t2354
  br label %ht_probe_cond_537
ht_probe_end_548:
  %t2375 = load i1, i1* %t2356
  %t2376 = load i64, i64* %t2357
  %t2377 = load i64, i64* %t2358
  br i1 %t2375, label %map_insert_overwrite_549, label %map_insert_new_550
map_insert_overwrite_549:
  store i8* %t2285, i8** %t2378
  %t2379 = load i8*, i8** %t2378
  call void @star_rc_release(i8* %t2379)
  %t2380 = getelementptr inbounds i32, i32* %t2348, i64 %t2376
  store i32 12, i32* %t2380
  br label %map_insert_after_551
map_insert_new_550:
  %t2381 = getelementptr inbounds i8, i8* %t2349, i64 %t2377
  %t2382 = load i8, i8* %t2381
  %t2383 = icmp eq i8 %t2382, 2
  br i1 %t2383, label %map_insert_dec_tomb_552, label %map_insert_store_553
map_insert_dec_tomb_552:
  %t2384 = load i64, i64* %t2283
  %t2385 = sub i64 %t2384, 1
  store i64 %t2385, i64* %t2283
  br label %map_insert_store_553
map_insert_store_553:
  store i8 1, i8* %t2381
  %t2386 = getelementptr inbounds i8*, i8** %t2347, i64 %t2377
  store i8* %t2285, i8** %t2386
  %t2387 = getelementptr inbounds i32, i32* %t2348, i64 %t2377
  store i32 12, i32* %t2387
  %t2388 = load i64, i64* %t2279
  %t2389 = add i64 %t2388, 1
  store i64 %t2389, i64* %t2279
  br label %map_insert_after_551
map_insert_after_551:
  %t2390 = getelementptr i8*, i8** null, i32 1
  %t2391 = ptrtoint i8** %t2390 to i64
  %t2392 = getelementptr i32, i32* null, i32 1
  %t2393 = ptrtoint i32* %t2392 to i64
  %t2394 = load i8*, i8** %t0
  %t2395 = icmp eq i8* %t2394, null
  br i1 %t2395, label %map_cow_alloc_554, label %map_cow_check_555
map_cow_alloc_554:
  %t2396 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2397 = call i8* @star_rc_alloc(i64 48, i8* %t2396)
  %t2398 = bitcast i8* %t2397 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2399 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2398, i32 0, i32 0
  store i8** null, i8*** %t2399
  %t2400 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2398, i32 0, i32 1
  store i32* null, i32** %t2400
  %t2401 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2398, i32 0, i32 2
  store i8* null, i8** %t2401
  %t2402 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2398, i32 0, i32 3
  store i64 0, i64* %t2402
  %t2403 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2398, i32 0, i32 4
  store i64 0, i64* %t2403
  %t2404 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2398, i32 0, i32 5
  store i64 0, i64* %t2404
  store i8* %t2397, i8** %t0
  br label %map_cow_done_556
map_cow_check_555:
  %t2405 = getelementptr inbounds i8, i8* %t2394, i64 -16
  %t2406 = bitcast i8* %t2405 to i64*
  %t2407 = load atomic i64, i64* %t2406 seq_cst, align 8
  %t2408 = icmp eq i64 %t2407, 1
  br i1 %t2408, label %map_cow_done_556, label %map_cow_clone_557
map_cow_clone_557:
  %t2409 = bitcast i8* %t2394 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2410 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2409, i32 0, i32 0
  %t2411 = load i8**, i8*** %t2410
  %t2412 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2409, i32 0, i32 1
  %t2413 = load i32*, i32** %t2412
  %t2414 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2409, i32 0, i32 2
  %t2415 = load i8*, i8** %t2414
  %t2416 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2409, i32 0, i32 3
  %t2417 = load i64, i64* %t2416
  %t2418 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2409, i32 0, i32 4
  %t2419 = load i64, i64* %t2418
  %t2420 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2409, i32 0, i32 5
  %t2421 = load i64, i64* %t2420
  %t2422 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2423 = call i8* @star_rc_alloc(i64 48, i8* %t2422)
  %t2424 = bitcast i8* %t2423 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2425 = mul i64 %t2419, %t2391
  %t2426 = call i8* @malloc(i64 %t2425)
  %t2427 = bitcast i8* %t2426 to i8**
  %t2428 = mul i64 %t2419, %t2393
  %t2429 = call i8* @malloc(i64 %t2428)
  %t2430 = bitcast i8* %t2429 to i32*
  %t2431 = call i8* @malloc(i64 %t2419)
  %t2432 = icmp sgt i64 %t2419, 0
  br i1 %t2432, label %map_cow_copy_558, label %map_cow_after_copy_559
map_cow_copy_558:
  %t2433 = mul i64 %t2419, %t2391
  %t2434 = bitcast i8** %t2411 to i8*
  call i8* @memcpy(i8* %t2426, i8* %t2434, i64 %t2433)
  %t2435 = mul i64 %t2419, %t2393
  %t2436 = bitcast i32* %t2413 to i8*
  call i8* @memcpy(i8* %t2429, i8* %t2436, i64 %t2435)
  call i8* @memcpy(i8* %t2431, i8* %t2415, i64 %t2419)
  store i64 0, i64* %t2437
  br label %map_cow_retain_cond_560
map_cow_retain_cond_560:
  %t2438 = load i64, i64* %t2437
  %t2439 = icmp slt i64 %t2438, %t2419
  br i1 %t2439, label %map_cow_retain_body_561, label %map_cow_retain_end_564
map_cow_retain_body_561:
  %t2440 = getelementptr inbounds i8, i8* %t2431, i64 %t2438
  %t2441 = load i8, i8* %t2440
  %t2442 = icmp eq i8 %t2441, 1
  br i1 %t2442, label %map_cow_retain_occ_562, label %map_cow_retain_next_563
map_cow_retain_occ_562:
  %t2443 = getelementptr inbounds i8*, i8** %t2427, i64 %t2438
  %t2444 = load i8*, i8** %t2443
  call void @star_rc_retain(i8* %t2444)
  br label %map_cow_retain_next_563
map_cow_retain_next_563:
  %t2445 = add i64 %t2438, 1
  store i64 %t2445, i64* %t2437
  br label %map_cow_retain_cond_560
map_cow_retain_end_564:
  br label %map_cow_after_copy_559
map_cow_after_copy_559:
  %t2446 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2424, i32 0, i32 0
  store i8** %t2427, i8*** %t2446
  %t2447 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2424, i32 0, i32 1
  store i32* %t2430, i32** %t2447
  %t2448 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2424, i32 0, i32 2
  store i8* %t2431, i8** %t2448
  %t2449 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2424, i32 0, i32 3
  store i64 %t2417, i64* %t2449
  %t2450 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2424, i32 0, i32 4
  store i64 %t2419, i64* %t2450
  %t2451 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2424, i32 0, i32 5
  store i64 %t2421, i64* %t2451
  call void @star_rc_release(i8* %t2394)
  store i8* %t2423, i8** %t0
  br label %map_cow_done_556
map_cow_done_556:
  %t2452 = load i8*, i8** %t0
  %t2453 = bitcast i8* %t2452 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2454 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2453, i32 0, i32 0
  %t2455 = load i8**, i8*** %t2454
  %t2456 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2453, i32 0, i32 1
  %t2457 = load i32*, i32** %t2456
  %t2458 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2453, i32 0, i32 2
  %t2459 = load i8*, i8** %t2458
  %t2460 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2453, i32 0, i32 3
  %t2461 = load i64, i64* %t2460
  %t2462 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2453, i32 0, i32 4
  %t2463 = load i64, i64* %t2462
  %t2464 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2453, i32 0, i32 5
  %t2465 = load i64, i64* %t2464
  %t2466 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t2467 = load i64, i64* %t2460
  %t2468 = load i64, i64* %t2462
  %t2469 = load i64, i64* %t2464
  %t2470 = add i64 %t2467, %t2469
  %t2471 = add i64 %t2470, 1
  %t2472 = mul i64 %t2471, 4
  %t2473 = mul i64 %t2468, 3
  %t2474 = icmp sgt i64 %t2472, %t2473
  br i1 %t2474, label %map_insert_grow_565, label %map_insert_after_grow_566
map_insert_grow_565:
  %t2475 = getelementptr i8*, i8** null, i32 1
  %t2476 = ptrtoint i8** %t2475 to i64
  %t2477 = getelementptr i32, i32* null, i32 1
  %t2478 = ptrtoint i32* %t2477 to i64
  %t2479 = mul i64 %t2468, 2
  %t2480 = icmp sgt i64 %t2479, 0
  %t2481 = select i1 %t2480, i64 %t2479, i64 8
  %t2482 = sub i64 %t2481, 1
  %t2483 = mul i64 %t2481, %t2476
  %t2484 = call i8* @malloc(i64 %t2483)
  %t2485 = bitcast i8* %t2484 to i8**
  %t2486 = mul i64 %t2481, %t2478
  %t2487 = call i8* @malloc(i64 %t2486)
  %t2488 = bitcast i8* %t2487 to i32*
  %t2489 = call i8* @malloc(i64 %t2481)
  store i64 0, i64* %t2490
  br label %ht_fill8_cond_567
ht_fill8_cond_567:
  %t2491 = load i64, i64* %t2490
  %t2492 = icmp slt i64 %t2491, %t2481
  br i1 %t2492, label %ht_fill8_body_568, label %ht_fill8_end_569
ht_fill8_body_568:
  %t2493 = getelementptr inbounds i8, i8* %t2489, i64 %t2491
  store i8 0, i8* %t2493
  %t2494 = add i64 %t2491, 1
  store i64 %t2494, i64* %t2490
  br label %ht_fill8_cond_567
ht_fill8_end_569:
  %t2495 = load i8**, i8*** %t2454
  %t2496 = load i32*, i32** %t2456
  %t2497 = load i8*, i8** %t2458
  store i64 0, i64* %t2498
  br label %map_grow_cond_570
map_grow_cond_570:
  %t2499 = load i64, i64* %t2498
  %t2500 = icmp slt i64 %t2499, %t2468
  br i1 %t2500, label %map_grow_body_571, label %map_grow_end_574
map_grow_body_571:
  %t2501 = getelementptr inbounds i8, i8* %t2497, i64 %t2499
  %t2502 = load i8, i8* %t2501
  %t2503 = icmp eq i8 %t2502, 1
  br i1 %t2503, label %map_grow_occ_572, label %map_grow_next_573
map_grow_occ_572:
  %t2504 = getelementptr inbounds i8*, i8** %t2495, i64 %t2499
  %t2505 = load i8*, i8** %t2504
  %t2506 = getelementptr inbounds i32, i32* %t2496, i64 %t2499
  %t2507 = load i32, i32* %t2506
  %t2508 = call i64 @hash_str(i8* %t2505)
  %t2509 = and i64 %t2508, %t2482
  store i64 0, i64* %t2510
  store i64 %t2509, i64* %t2511
  br label %ht_fe_cond_575
ht_fe_cond_575:
  %t2512 = load i64, i64* %t2510
  %t2513 = icmp slt i64 %t2512, %t2481
  br i1 %t2513, label %ht_fe_body_576, label %ht_fe_end_578
ht_fe_body_576:
  %t2514 = load i64, i64* %t2511
  %t2515 = getelementptr inbounds i8, i8* %t2489, i64 %t2514
  %t2516 = load i8, i8* %t2515
  %t2517 = icmp eq i8 %t2516, 0
  br i1 %t2517, label %ht_fe_end_578, label %ht_fe_next_577
ht_fe_next_577:
  %t2518 = add i64 %t2514, 1
  %t2519 = and i64 %t2518, %t2482
  store i64 %t2519, i64* %t2511
  %t2520 = add i64 %t2512, 1
  store i64 %t2520, i64* %t2510
  br label %ht_fe_cond_575
ht_fe_end_578:
  %t2521 = load i64, i64* %t2511
  %t2522 = getelementptr inbounds i8, i8* %t2489, i64 %t2521
  store i8 1, i8* %t2522
  %t2523 = getelementptr inbounds i8*, i8** %t2485, i64 %t2521
  store i8* %t2505, i8** %t2523
  %t2524 = getelementptr inbounds i32, i32* %t2488, i64 %t2521
  store i32 %t2507, i32* %t2524
  br label %map_grow_next_573
map_grow_next_573:
  %t2525 = add i64 %t2499, 1
  store i64 %t2525, i64* %t2498
  br label %map_grow_cond_570
map_grow_end_574:
  %t2526 = bitcast i8** %t2495 to i8*
  call void @free(i8* %t2526)
  %t2527 = bitcast i32* %t2496 to i8*
  call void @free(i8* %t2527)
  call void @free(i8* %t2497)
  store i8** %t2485, i8*** %t2454
  store i32* %t2488, i32** %t2456
  store i8* %t2489, i8** %t2458
  store i64 %t2481, i64* %t2462
  store i64 0, i64* %t2464
  br label %map_insert_after_grow_566
map_insert_after_grow_566:
  %t2528 = load i8**, i8*** %t2454
  %t2529 = load i32*, i32** %t2456
  %t2530 = load i8*, i8** %t2458
  %t2531 = load i64, i64* %t2462
  %t2532 = sub i64 %t2531, 1
  %t2533 = call i64 @hash_str(i8* %t2466)
  %t2534 = and i64 %t2533, %t2532
  store i64 0, i64* %t2535
  store i64 %t2534, i64* %t2536
  store i1 false, i1* %t2537
  store i64 -1, i64* %t2538
  store i64 -1, i64* %t2539
  store i1 false, i1* %t2540
  br label %ht_probe_cond_579
ht_probe_cond_579:
  %t2541 = load i64, i64* %t2535
  %t2542 = icmp slt i64 %t2541, %t2531
  br i1 %t2542, label %ht_probe_body_580, label %ht_probe_end_590
ht_probe_body_580:
  %t2543 = load i64, i64* %t2536
  %t2544 = getelementptr inbounds i8, i8* %t2530, i64 %t2543
  %t2545 = load i8, i8* %t2544
  %t2546 = icmp eq i8 %t2545, 0
  br i1 %t2546, label %ht_probe_on_empty_582, label %ht_probe_check_occ_581
ht_probe_check_occ_581:
  %t2547 = icmp eq i8 %t2545, 1
  br i1 %t2547, label %ht_probe_on_occ_585, label %ht_probe_on_tomb_587
ht_probe_on_empty_582:
  %t2548 = load i1, i1* %t2540
  br i1 %t2548, label %ht_probe_after_islot_empty_584, label %ht_probe_set_islot_empty_583
ht_probe_set_islot_empty_583:
  store i64 %t2543, i64* %t2539
  store i1 true, i1* %t2540
  br label %ht_probe_after_islot_empty_584
ht_probe_after_islot_empty_584:
  br label %ht_probe_end_590
ht_probe_on_occ_585:
  %t2549 = getelementptr inbounds i8*, i8** %t2528, i64 %t2543
  %t2550 = load i8*, i8** %t2549
  %t2551 = call i1 @eq_str(i8* %t2550, i8* %t2466)
  br i1 %t2551, label %ht_probe_on_match_586, label %ht_probe_next_589
ht_probe_on_match_586:
  store i1 true, i1* %t2537
  store i64 %t2543, i64* %t2538
  br label %ht_probe_end_590
ht_probe_on_tomb_587:
  %t2552 = load i1, i1* %t2540
  br i1 %t2552, label %ht_probe_next_589, label %ht_probe_set_islot_tomb_588
ht_probe_set_islot_tomb_588:
  store i64 %t2543, i64* %t2539
  store i1 true, i1* %t2540
  br label %ht_probe_next_589
ht_probe_next_589:
  %t2553 = add i64 %t2543, 1
  %t2554 = and i64 %t2553, %t2532
  store i64 %t2554, i64* %t2536
  %t2555 = add i64 %t2541, 1
  store i64 %t2555, i64* %t2535
  br label %ht_probe_cond_579
ht_probe_end_590:
  %t2556 = load i1, i1* %t2537
  %t2557 = load i64, i64* %t2538
  %t2558 = load i64, i64* %t2539
  br i1 %t2556, label %map_insert_overwrite_591, label %map_insert_new_592
map_insert_overwrite_591:
  store i8* %t2466, i8** %t2559
  %t2560 = load i8*, i8** %t2559
  call void @star_rc_release(i8* %t2560)
  %t2561 = getelementptr inbounds i32, i32* %t2529, i64 %t2557
  store i32 13, i32* %t2561
  br label %map_insert_after_593
map_insert_new_592:
  %t2562 = getelementptr inbounds i8, i8* %t2530, i64 %t2558
  %t2563 = load i8, i8* %t2562
  %t2564 = icmp eq i8 %t2563, 2
  br i1 %t2564, label %map_insert_dec_tomb_594, label %map_insert_store_595
map_insert_dec_tomb_594:
  %t2565 = load i64, i64* %t2464
  %t2566 = sub i64 %t2565, 1
  store i64 %t2566, i64* %t2464
  br label %map_insert_store_595
map_insert_store_595:
  store i8 1, i8* %t2562
  %t2567 = getelementptr inbounds i8*, i8** %t2528, i64 %t2558
  store i8* %t2466, i8** %t2567
  %t2568 = getelementptr inbounds i32, i32* %t2529, i64 %t2558
  store i32 13, i32* %t2568
  %t2569 = load i64, i64* %t2460
  %t2570 = add i64 %t2569, 1
  store i64 %t2570, i64* %t2460
  br label %map_insert_after_593
map_insert_after_593:
  %t2571 = getelementptr i8*, i8** null, i32 1
  %t2572 = ptrtoint i8** %t2571 to i64
  %t2573 = getelementptr i32, i32* null, i32 1
  %t2574 = ptrtoint i32* %t2573 to i64
  %t2575 = load i8*, i8** %t0
  %t2576 = icmp eq i8* %t2575, null
  br i1 %t2576, label %map_cow_alloc_596, label %map_cow_check_597
map_cow_alloc_596:
  %t2577 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2578 = call i8* @star_rc_alloc(i64 48, i8* %t2577)
  %t2579 = bitcast i8* %t2578 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2580 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2579, i32 0, i32 0
  store i8** null, i8*** %t2580
  %t2581 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2579, i32 0, i32 1
  store i32* null, i32** %t2581
  %t2582 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2579, i32 0, i32 2
  store i8* null, i8** %t2582
  %t2583 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2579, i32 0, i32 3
  store i64 0, i64* %t2583
  %t2584 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2579, i32 0, i32 4
  store i64 0, i64* %t2584
  %t2585 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2579, i32 0, i32 5
  store i64 0, i64* %t2585
  store i8* %t2578, i8** %t0
  br label %map_cow_done_598
map_cow_check_597:
  %t2586 = getelementptr inbounds i8, i8* %t2575, i64 -16
  %t2587 = bitcast i8* %t2586 to i64*
  %t2588 = load atomic i64, i64* %t2587 seq_cst, align 8
  %t2589 = icmp eq i64 %t2588, 1
  br i1 %t2589, label %map_cow_done_598, label %map_cow_clone_599
map_cow_clone_599:
  %t2590 = bitcast i8* %t2575 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2591 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2590, i32 0, i32 0
  %t2592 = load i8**, i8*** %t2591
  %t2593 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2590, i32 0, i32 1
  %t2594 = load i32*, i32** %t2593
  %t2595 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2590, i32 0, i32 2
  %t2596 = load i8*, i8** %t2595
  %t2597 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2590, i32 0, i32 3
  %t2598 = load i64, i64* %t2597
  %t2599 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2590, i32 0, i32 4
  %t2600 = load i64, i64* %t2599
  %t2601 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2590, i32 0, i32 5
  %t2602 = load i64, i64* %t2601
  %t2603 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2604 = call i8* @star_rc_alloc(i64 48, i8* %t2603)
  %t2605 = bitcast i8* %t2604 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2606 = mul i64 %t2600, %t2572
  %t2607 = call i8* @malloc(i64 %t2606)
  %t2608 = bitcast i8* %t2607 to i8**
  %t2609 = mul i64 %t2600, %t2574
  %t2610 = call i8* @malloc(i64 %t2609)
  %t2611 = bitcast i8* %t2610 to i32*
  %t2612 = call i8* @malloc(i64 %t2600)
  %t2613 = icmp sgt i64 %t2600, 0
  br i1 %t2613, label %map_cow_copy_600, label %map_cow_after_copy_601
map_cow_copy_600:
  %t2614 = mul i64 %t2600, %t2572
  %t2615 = bitcast i8** %t2592 to i8*
  call i8* @memcpy(i8* %t2607, i8* %t2615, i64 %t2614)
  %t2616 = mul i64 %t2600, %t2574
  %t2617 = bitcast i32* %t2594 to i8*
  call i8* @memcpy(i8* %t2610, i8* %t2617, i64 %t2616)
  call i8* @memcpy(i8* %t2612, i8* %t2596, i64 %t2600)
  store i64 0, i64* %t2618
  br label %map_cow_retain_cond_602
map_cow_retain_cond_602:
  %t2619 = load i64, i64* %t2618
  %t2620 = icmp slt i64 %t2619, %t2600
  br i1 %t2620, label %map_cow_retain_body_603, label %map_cow_retain_end_606
map_cow_retain_body_603:
  %t2621 = getelementptr inbounds i8, i8* %t2612, i64 %t2619
  %t2622 = load i8, i8* %t2621
  %t2623 = icmp eq i8 %t2622, 1
  br i1 %t2623, label %map_cow_retain_occ_604, label %map_cow_retain_next_605
map_cow_retain_occ_604:
  %t2624 = getelementptr inbounds i8*, i8** %t2608, i64 %t2619
  %t2625 = load i8*, i8** %t2624
  call void @star_rc_retain(i8* %t2625)
  br label %map_cow_retain_next_605
map_cow_retain_next_605:
  %t2626 = add i64 %t2619, 1
  store i64 %t2626, i64* %t2618
  br label %map_cow_retain_cond_602
map_cow_retain_end_606:
  br label %map_cow_after_copy_601
map_cow_after_copy_601:
  %t2627 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2605, i32 0, i32 0
  store i8** %t2608, i8*** %t2627
  %t2628 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2605, i32 0, i32 1
  store i32* %t2611, i32** %t2628
  %t2629 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2605, i32 0, i32 2
  store i8* %t2612, i8** %t2629
  %t2630 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2605, i32 0, i32 3
  store i64 %t2598, i64* %t2630
  %t2631 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2605, i32 0, i32 4
  store i64 %t2600, i64* %t2631
  %t2632 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2605, i32 0, i32 5
  store i64 %t2602, i64* %t2632
  call void @star_rc_release(i8* %t2575)
  store i8* %t2604, i8** %t0
  br label %map_cow_done_598
map_cow_done_598:
  %t2633 = load i8*, i8** %t0
  %t2634 = bitcast i8* %t2633 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2635 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2634, i32 0, i32 0
  %t2636 = load i8**, i8*** %t2635
  %t2637 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2634, i32 0, i32 1
  %t2638 = load i32*, i32** %t2637
  %t2639 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2634, i32 0, i32 2
  %t2640 = load i8*, i8** %t2639
  %t2641 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2634, i32 0, i32 3
  %t2642 = load i64, i64* %t2641
  %t2643 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2634, i32 0, i32 4
  %t2644 = load i64, i64* %t2643
  %t2645 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2634, i32 0, i32 5
  %t2646 = load i64, i64* %t2645
  %t2647 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t2648 = load i64, i64* %t2641
  %t2649 = load i64, i64* %t2643
  %t2650 = load i64, i64* %t2645
  %t2651 = add i64 %t2648, %t2650
  %t2652 = add i64 %t2651, 1
  %t2653 = mul i64 %t2652, 4
  %t2654 = mul i64 %t2649, 3
  %t2655 = icmp sgt i64 %t2653, %t2654
  br i1 %t2655, label %map_insert_grow_607, label %map_insert_after_grow_608
map_insert_grow_607:
  %t2656 = getelementptr i8*, i8** null, i32 1
  %t2657 = ptrtoint i8** %t2656 to i64
  %t2658 = getelementptr i32, i32* null, i32 1
  %t2659 = ptrtoint i32* %t2658 to i64
  %t2660 = mul i64 %t2649, 2
  %t2661 = icmp sgt i64 %t2660, 0
  %t2662 = select i1 %t2661, i64 %t2660, i64 8
  %t2663 = sub i64 %t2662, 1
  %t2664 = mul i64 %t2662, %t2657
  %t2665 = call i8* @malloc(i64 %t2664)
  %t2666 = bitcast i8* %t2665 to i8**
  %t2667 = mul i64 %t2662, %t2659
  %t2668 = call i8* @malloc(i64 %t2667)
  %t2669 = bitcast i8* %t2668 to i32*
  %t2670 = call i8* @malloc(i64 %t2662)
  store i64 0, i64* %t2671
  br label %ht_fill8_cond_609
ht_fill8_cond_609:
  %t2672 = load i64, i64* %t2671
  %t2673 = icmp slt i64 %t2672, %t2662
  br i1 %t2673, label %ht_fill8_body_610, label %ht_fill8_end_611
ht_fill8_body_610:
  %t2674 = getelementptr inbounds i8, i8* %t2670, i64 %t2672
  store i8 0, i8* %t2674
  %t2675 = add i64 %t2672, 1
  store i64 %t2675, i64* %t2671
  br label %ht_fill8_cond_609
ht_fill8_end_611:
  %t2676 = load i8**, i8*** %t2635
  %t2677 = load i32*, i32** %t2637
  %t2678 = load i8*, i8** %t2639
  store i64 0, i64* %t2679
  br label %map_grow_cond_612
map_grow_cond_612:
  %t2680 = load i64, i64* %t2679
  %t2681 = icmp slt i64 %t2680, %t2649
  br i1 %t2681, label %map_grow_body_613, label %map_grow_end_616
map_grow_body_613:
  %t2682 = getelementptr inbounds i8, i8* %t2678, i64 %t2680
  %t2683 = load i8, i8* %t2682
  %t2684 = icmp eq i8 %t2683, 1
  br i1 %t2684, label %map_grow_occ_614, label %map_grow_next_615
map_grow_occ_614:
  %t2685 = getelementptr inbounds i8*, i8** %t2676, i64 %t2680
  %t2686 = load i8*, i8** %t2685
  %t2687 = getelementptr inbounds i32, i32* %t2677, i64 %t2680
  %t2688 = load i32, i32* %t2687
  %t2689 = call i64 @hash_str(i8* %t2686)
  %t2690 = and i64 %t2689, %t2663
  store i64 0, i64* %t2691
  store i64 %t2690, i64* %t2692
  br label %ht_fe_cond_617
ht_fe_cond_617:
  %t2693 = load i64, i64* %t2691
  %t2694 = icmp slt i64 %t2693, %t2662
  br i1 %t2694, label %ht_fe_body_618, label %ht_fe_end_620
ht_fe_body_618:
  %t2695 = load i64, i64* %t2692
  %t2696 = getelementptr inbounds i8, i8* %t2670, i64 %t2695
  %t2697 = load i8, i8* %t2696
  %t2698 = icmp eq i8 %t2697, 0
  br i1 %t2698, label %ht_fe_end_620, label %ht_fe_next_619
ht_fe_next_619:
  %t2699 = add i64 %t2695, 1
  %t2700 = and i64 %t2699, %t2663
  store i64 %t2700, i64* %t2692
  %t2701 = add i64 %t2693, 1
  store i64 %t2701, i64* %t2691
  br label %ht_fe_cond_617
ht_fe_end_620:
  %t2702 = load i64, i64* %t2692
  %t2703 = getelementptr inbounds i8, i8* %t2670, i64 %t2702
  store i8 1, i8* %t2703
  %t2704 = getelementptr inbounds i8*, i8** %t2666, i64 %t2702
  store i8* %t2686, i8** %t2704
  %t2705 = getelementptr inbounds i32, i32* %t2669, i64 %t2702
  store i32 %t2688, i32* %t2705
  br label %map_grow_next_615
map_grow_next_615:
  %t2706 = add i64 %t2680, 1
  store i64 %t2706, i64* %t2679
  br label %map_grow_cond_612
map_grow_end_616:
  %t2707 = bitcast i8** %t2676 to i8*
  call void @free(i8* %t2707)
  %t2708 = bitcast i32* %t2677 to i8*
  call void @free(i8* %t2708)
  call void @free(i8* %t2678)
  store i8** %t2666, i8*** %t2635
  store i32* %t2669, i32** %t2637
  store i8* %t2670, i8** %t2639
  store i64 %t2662, i64* %t2643
  store i64 0, i64* %t2645
  br label %map_insert_after_grow_608
map_insert_after_grow_608:
  %t2709 = load i8**, i8*** %t2635
  %t2710 = load i32*, i32** %t2637
  %t2711 = load i8*, i8** %t2639
  %t2712 = load i64, i64* %t2643
  %t2713 = sub i64 %t2712, 1
  %t2714 = call i64 @hash_str(i8* %t2647)
  %t2715 = and i64 %t2714, %t2713
  store i64 0, i64* %t2716
  store i64 %t2715, i64* %t2717
  store i1 false, i1* %t2718
  store i64 -1, i64* %t2719
  store i64 -1, i64* %t2720
  store i1 false, i1* %t2721
  br label %ht_probe_cond_621
ht_probe_cond_621:
  %t2722 = load i64, i64* %t2716
  %t2723 = icmp slt i64 %t2722, %t2712
  br i1 %t2723, label %ht_probe_body_622, label %ht_probe_end_632
ht_probe_body_622:
  %t2724 = load i64, i64* %t2717
  %t2725 = getelementptr inbounds i8, i8* %t2711, i64 %t2724
  %t2726 = load i8, i8* %t2725
  %t2727 = icmp eq i8 %t2726, 0
  br i1 %t2727, label %ht_probe_on_empty_624, label %ht_probe_check_occ_623
ht_probe_check_occ_623:
  %t2728 = icmp eq i8 %t2726, 1
  br i1 %t2728, label %ht_probe_on_occ_627, label %ht_probe_on_tomb_629
ht_probe_on_empty_624:
  %t2729 = load i1, i1* %t2721
  br i1 %t2729, label %ht_probe_after_islot_empty_626, label %ht_probe_set_islot_empty_625
ht_probe_set_islot_empty_625:
  store i64 %t2724, i64* %t2720
  store i1 true, i1* %t2721
  br label %ht_probe_after_islot_empty_626
ht_probe_after_islot_empty_626:
  br label %ht_probe_end_632
ht_probe_on_occ_627:
  %t2730 = getelementptr inbounds i8*, i8** %t2709, i64 %t2724
  %t2731 = load i8*, i8** %t2730
  %t2732 = call i1 @eq_str(i8* %t2731, i8* %t2647)
  br i1 %t2732, label %ht_probe_on_match_628, label %ht_probe_next_631
ht_probe_on_match_628:
  store i1 true, i1* %t2718
  store i64 %t2724, i64* %t2719
  br label %ht_probe_end_632
ht_probe_on_tomb_629:
  %t2733 = load i1, i1* %t2721
  br i1 %t2733, label %ht_probe_next_631, label %ht_probe_set_islot_tomb_630
ht_probe_set_islot_tomb_630:
  store i64 %t2724, i64* %t2720
  store i1 true, i1* %t2721
  br label %ht_probe_next_631
ht_probe_next_631:
  %t2734 = add i64 %t2724, 1
  %t2735 = and i64 %t2734, %t2713
  store i64 %t2735, i64* %t2717
  %t2736 = add i64 %t2722, 1
  store i64 %t2736, i64* %t2716
  br label %ht_probe_cond_621
ht_probe_end_632:
  %t2737 = load i1, i1* %t2718
  %t2738 = load i64, i64* %t2719
  %t2739 = load i64, i64* %t2720
  br i1 %t2737, label %map_insert_overwrite_633, label %map_insert_new_634
map_insert_overwrite_633:
  store i8* %t2647, i8** %t2740
  %t2741 = load i8*, i8** %t2740
  call void @star_rc_release(i8* %t2741)
  %t2742 = getelementptr inbounds i32, i32* %t2710, i64 %t2738
  store i32 14, i32* %t2742
  br label %map_insert_after_635
map_insert_new_634:
  %t2743 = getelementptr inbounds i8, i8* %t2711, i64 %t2739
  %t2744 = load i8, i8* %t2743
  %t2745 = icmp eq i8 %t2744, 2
  br i1 %t2745, label %map_insert_dec_tomb_636, label %map_insert_store_637
map_insert_dec_tomb_636:
  %t2746 = load i64, i64* %t2645
  %t2747 = sub i64 %t2746, 1
  store i64 %t2747, i64* %t2645
  br label %map_insert_store_637
map_insert_store_637:
  store i8 1, i8* %t2743
  %t2748 = getelementptr inbounds i8*, i8** %t2709, i64 %t2739
  store i8* %t2647, i8** %t2748
  %t2749 = getelementptr inbounds i32, i32* %t2710, i64 %t2739
  store i32 14, i32* %t2749
  %t2750 = load i64, i64* %t2641
  %t2751 = add i64 %t2750, 1
  store i64 %t2751, i64* %t2641
  br label %map_insert_after_635
map_insert_after_635:
  %t2752 = getelementptr i8*, i8** null, i32 1
  %t2753 = ptrtoint i8** %t2752 to i64
  %t2754 = getelementptr i32, i32* null, i32 1
  %t2755 = ptrtoint i32* %t2754 to i64
  %t2756 = load i8*, i8** %t0
  %t2757 = icmp eq i8* %t2756, null
  br i1 %t2757, label %map_cow_alloc_638, label %map_cow_check_639
map_cow_alloc_638:
  %t2758 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2759 = call i8* @star_rc_alloc(i64 48, i8* %t2758)
  %t2760 = bitcast i8* %t2759 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2761 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2760, i32 0, i32 0
  store i8** null, i8*** %t2761
  %t2762 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2760, i32 0, i32 1
  store i32* null, i32** %t2762
  %t2763 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2760, i32 0, i32 2
  store i8* null, i8** %t2763
  %t2764 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2760, i32 0, i32 3
  store i64 0, i64* %t2764
  %t2765 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2760, i32 0, i32 4
  store i64 0, i64* %t2765
  %t2766 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2760, i32 0, i32 5
  store i64 0, i64* %t2766
  store i8* %t2759, i8** %t0
  br label %map_cow_done_640
map_cow_check_639:
  %t2767 = getelementptr inbounds i8, i8* %t2756, i64 -16
  %t2768 = bitcast i8* %t2767 to i64*
  %t2769 = load atomic i64, i64* %t2768 seq_cst, align 8
  %t2770 = icmp eq i64 %t2769, 1
  br i1 %t2770, label %map_cow_done_640, label %map_cow_clone_641
map_cow_clone_641:
  %t2771 = bitcast i8* %t2756 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2772 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2771, i32 0, i32 0
  %t2773 = load i8**, i8*** %t2772
  %t2774 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2771, i32 0, i32 1
  %t2775 = load i32*, i32** %t2774
  %t2776 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2771, i32 0, i32 2
  %t2777 = load i8*, i8** %t2776
  %t2778 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2771, i32 0, i32 3
  %t2779 = load i64, i64* %t2778
  %t2780 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2771, i32 0, i32 4
  %t2781 = load i64, i64* %t2780
  %t2782 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2771, i32 0, i32 5
  %t2783 = load i64, i64* %t2782
  %t2784 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2785 = call i8* @star_rc_alloc(i64 48, i8* %t2784)
  %t2786 = bitcast i8* %t2785 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2787 = mul i64 %t2781, %t2753
  %t2788 = call i8* @malloc(i64 %t2787)
  %t2789 = bitcast i8* %t2788 to i8**
  %t2790 = mul i64 %t2781, %t2755
  %t2791 = call i8* @malloc(i64 %t2790)
  %t2792 = bitcast i8* %t2791 to i32*
  %t2793 = call i8* @malloc(i64 %t2781)
  %t2794 = icmp sgt i64 %t2781, 0
  br i1 %t2794, label %map_cow_copy_642, label %map_cow_after_copy_643
map_cow_copy_642:
  %t2795 = mul i64 %t2781, %t2753
  %t2796 = bitcast i8** %t2773 to i8*
  call i8* @memcpy(i8* %t2788, i8* %t2796, i64 %t2795)
  %t2797 = mul i64 %t2781, %t2755
  %t2798 = bitcast i32* %t2775 to i8*
  call i8* @memcpy(i8* %t2791, i8* %t2798, i64 %t2797)
  call i8* @memcpy(i8* %t2793, i8* %t2777, i64 %t2781)
  store i64 0, i64* %t2799
  br label %map_cow_retain_cond_644
map_cow_retain_cond_644:
  %t2800 = load i64, i64* %t2799
  %t2801 = icmp slt i64 %t2800, %t2781
  br i1 %t2801, label %map_cow_retain_body_645, label %map_cow_retain_end_648
map_cow_retain_body_645:
  %t2802 = getelementptr inbounds i8, i8* %t2793, i64 %t2800
  %t2803 = load i8, i8* %t2802
  %t2804 = icmp eq i8 %t2803, 1
  br i1 %t2804, label %map_cow_retain_occ_646, label %map_cow_retain_next_647
map_cow_retain_occ_646:
  %t2805 = getelementptr inbounds i8*, i8** %t2789, i64 %t2800
  %t2806 = load i8*, i8** %t2805
  call void @star_rc_retain(i8* %t2806)
  br label %map_cow_retain_next_647
map_cow_retain_next_647:
  %t2807 = add i64 %t2800, 1
  store i64 %t2807, i64* %t2799
  br label %map_cow_retain_cond_644
map_cow_retain_end_648:
  br label %map_cow_after_copy_643
map_cow_after_copy_643:
  %t2808 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2786, i32 0, i32 0
  store i8** %t2789, i8*** %t2808
  %t2809 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2786, i32 0, i32 1
  store i32* %t2792, i32** %t2809
  %t2810 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2786, i32 0, i32 2
  store i8* %t2793, i8** %t2810
  %t2811 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2786, i32 0, i32 3
  store i64 %t2779, i64* %t2811
  %t2812 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2786, i32 0, i32 4
  store i64 %t2781, i64* %t2812
  %t2813 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2786, i32 0, i32 5
  store i64 %t2783, i64* %t2813
  call void @star_rc_release(i8* %t2756)
  store i8* %t2785, i8** %t0
  br label %map_cow_done_640
map_cow_done_640:
  %t2814 = load i8*, i8** %t0
  %t2815 = bitcast i8* %t2814 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2816 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2815, i32 0, i32 0
  %t2817 = load i8**, i8*** %t2816
  %t2818 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2815, i32 0, i32 1
  %t2819 = load i32*, i32** %t2818
  %t2820 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2815, i32 0, i32 2
  %t2821 = load i8*, i8** %t2820
  %t2822 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2815, i32 0, i32 3
  %t2823 = load i64, i64* %t2822
  %t2824 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2815, i32 0, i32 4
  %t2825 = load i64, i64* %t2824
  %t2826 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2815, i32 0, i32 5
  %t2827 = load i64, i64* %t2826
  %t2828 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t2829 = load i64, i64* %t2822
  %t2830 = load i64, i64* %t2824
  %t2831 = load i64, i64* %t2826
  %t2832 = add i64 %t2829, %t2831
  %t2833 = add i64 %t2832, 1
  %t2834 = mul i64 %t2833, 4
  %t2835 = mul i64 %t2830, 3
  %t2836 = icmp sgt i64 %t2834, %t2835
  br i1 %t2836, label %map_insert_grow_649, label %map_insert_after_grow_650
map_insert_grow_649:
  %t2837 = getelementptr i8*, i8** null, i32 1
  %t2838 = ptrtoint i8** %t2837 to i64
  %t2839 = getelementptr i32, i32* null, i32 1
  %t2840 = ptrtoint i32* %t2839 to i64
  %t2841 = mul i64 %t2830, 2
  %t2842 = icmp sgt i64 %t2841, 0
  %t2843 = select i1 %t2842, i64 %t2841, i64 8
  %t2844 = sub i64 %t2843, 1
  %t2845 = mul i64 %t2843, %t2838
  %t2846 = call i8* @malloc(i64 %t2845)
  %t2847 = bitcast i8* %t2846 to i8**
  %t2848 = mul i64 %t2843, %t2840
  %t2849 = call i8* @malloc(i64 %t2848)
  %t2850 = bitcast i8* %t2849 to i32*
  %t2851 = call i8* @malloc(i64 %t2843)
  store i64 0, i64* %t2852
  br label %ht_fill8_cond_651
ht_fill8_cond_651:
  %t2853 = load i64, i64* %t2852
  %t2854 = icmp slt i64 %t2853, %t2843
  br i1 %t2854, label %ht_fill8_body_652, label %ht_fill8_end_653
ht_fill8_body_652:
  %t2855 = getelementptr inbounds i8, i8* %t2851, i64 %t2853
  store i8 0, i8* %t2855
  %t2856 = add i64 %t2853, 1
  store i64 %t2856, i64* %t2852
  br label %ht_fill8_cond_651
ht_fill8_end_653:
  %t2857 = load i8**, i8*** %t2816
  %t2858 = load i32*, i32** %t2818
  %t2859 = load i8*, i8** %t2820
  store i64 0, i64* %t2860
  br label %map_grow_cond_654
map_grow_cond_654:
  %t2861 = load i64, i64* %t2860
  %t2862 = icmp slt i64 %t2861, %t2830
  br i1 %t2862, label %map_grow_body_655, label %map_grow_end_658
map_grow_body_655:
  %t2863 = getelementptr inbounds i8, i8* %t2859, i64 %t2861
  %t2864 = load i8, i8* %t2863
  %t2865 = icmp eq i8 %t2864, 1
  br i1 %t2865, label %map_grow_occ_656, label %map_grow_next_657
map_grow_occ_656:
  %t2866 = getelementptr inbounds i8*, i8** %t2857, i64 %t2861
  %t2867 = load i8*, i8** %t2866
  %t2868 = getelementptr inbounds i32, i32* %t2858, i64 %t2861
  %t2869 = load i32, i32* %t2868
  %t2870 = call i64 @hash_str(i8* %t2867)
  %t2871 = and i64 %t2870, %t2844
  store i64 0, i64* %t2872
  store i64 %t2871, i64* %t2873
  br label %ht_fe_cond_659
ht_fe_cond_659:
  %t2874 = load i64, i64* %t2872
  %t2875 = icmp slt i64 %t2874, %t2843
  br i1 %t2875, label %ht_fe_body_660, label %ht_fe_end_662
ht_fe_body_660:
  %t2876 = load i64, i64* %t2873
  %t2877 = getelementptr inbounds i8, i8* %t2851, i64 %t2876
  %t2878 = load i8, i8* %t2877
  %t2879 = icmp eq i8 %t2878, 0
  br i1 %t2879, label %ht_fe_end_662, label %ht_fe_next_661
ht_fe_next_661:
  %t2880 = add i64 %t2876, 1
  %t2881 = and i64 %t2880, %t2844
  store i64 %t2881, i64* %t2873
  %t2882 = add i64 %t2874, 1
  store i64 %t2882, i64* %t2872
  br label %ht_fe_cond_659
ht_fe_end_662:
  %t2883 = load i64, i64* %t2873
  %t2884 = getelementptr inbounds i8, i8* %t2851, i64 %t2883
  store i8 1, i8* %t2884
  %t2885 = getelementptr inbounds i8*, i8** %t2847, i64 %t2883
  store i8* %t2867, i8** %t2885
  %t2886 = getelementptr inbounds i32, i32* %t2850, i64 %t2883
  store i32 %t2869, i32* %t2886
  br label %map_grow_next_657
map_grow_next_657:
  %t2887 = add i64 %t2861, 1
  store i64 %t2887, i64* %t2860
  br label %map_grow_cond_654
map_grow_end_658:
  %t2888 = bitcast i8** %t2857 to i8*
  call void @free(i8* %t2888)
  %t2889 = bitcast i32* %t2858 to i8*
  call void @free(i8* %t2889)
  call void @free(i8* %t2859)
  store i8** %t2847, i8*** %t2816
  store i32* %t2850, i32** %t2818
  store i8* %t2851, i8** %t2820
  store i64 %t2843, i64* %t2824
  store i64 0, i64* %t2826
  br label %map_insert_after_grow_650
map_insert_after_grow_650:
  %t2890 = load i8**, i8*** %t2816
  %t2891 = load i32*, i32** %t2818
  %t2892 = load i8*, i8** %t2820
  %t2893 = load i64, i64* %t2824
  %t2894 = sub i64 %t2893, 1
  %t2895 = call i64 @hash_str(i8* %t2828)
  %t2896 = and i64 %t2895, %t2894
  store i64 0, i64* %t2897
  store i64 %t2896, i64* %t2898
  store i1 false, i1* %t2899
  store i64 -1, i64* %t2900
  store i64 -1, i64* %t2901
  store i1 false, i1* %t2902
  br label %ht_probe_cond_663
ht_probe_cond_663:
  %t2903 = load i64, i64* %t2897
  %t2904 = icmp slt i64 %t2903, %t2893
  br i1 %t2904, label %ht_probe_body_664, label %ht_probe_end_674
ht_probe_body_664:
  %t2905 = load i64, i64* %t2898
  %t2906 = getelementptr inbounds i8, i8* %t2892, i64 %t2905
  %t2907 = load i8, i8* %t2906
  %t2908 = icmp eq i8 %t2907, 0
  br i1 %t2908, label %ht_probe_on_empty_666, label %ht_probe_check_occ_665
ht_probe_check_occ_665:
  %t2909 = icmp eq i8 %t2907, 1
  br i1 %t2909, label %ht_probe_on_occ_669, label %ht_probe_on_tomb_671
ht_probe_on_empty_666:
  %t2910 = load i1, i1* %t2902
  br i1 %t2910, label %ht_probe_after_islot_empty_668, label %ht_probe_set_islot_empty_667
ht_probe_set_islot_empty_667:
  store i64 %t2905, i64* %t2901
  store i1 true, i1* %t2902
  br label %ht_probe_after_islot_empty_668
ht_probe_after_islot_empty_668:
  br label %ht_probe_end_674
ht_probe_on_occ_669:
  %t2911 = getelementptr inbounds i8*, i8** %t2890, i64 %t2905
  %t2912 = load i8*, i8** %t2911
  %t2913 = call i1 @eq_str(i8* %t2912, i8* %t2828)
  br i1 %t2913, label %ht_probe_on_match_670, label %ht_probe_next_673
ht_probe_on_match_670:
  store i1 true, i1* %t2899
  store i64 %t2905, i64* %t2900
  br label %ht_probe_end_674
ht_probe_on_tomb_671:
  %t2914 = load i1, i1* %t2902
  br i1 %t2914, label %ht_probe_next_673, label %ht_probe_set_islot_tomb_672
ht_probe_set_islot_tomb_672:
  store i64 %t2905, i64* %t2901
  store i1 true, i1* %t2902
  br label %ht_probe_next_673
ht_probe_next_673:
  %t2915 = add i64 %t2905, 1
  %t2916 = and i64 %t2915, %t2894
  store i64 %t2916, i64* %t2898
  %t2917 = add i64 %t2903, 1
  store i64 %t2917, i64* %t2897
  br label %ht_probe_cond_663
ht_probe_end_674:
  %t2918 = load i1, i1* %t2899
  %t2919 = load i64, i64* %t2900
  %t2920 = load i64, i64* %t2901
  br i1 %t2918, label %map_insert_overwrite_675, label %map_insert_new_676
map_insert_overwrite_675:
  store i8* %t2828, i8** %t2921
  %t2922 = load i8*, i8** %t2921
  call void @star_rc_release(i8* %t2922)
  %t2923 = getelementptr inbounds i32, i32* %t2891, i64 %t2919
  store i32 15, i32* %t2923
  br label %map_insert_after_677
map_insert_new_676:
  %t2924 = getelementptr inbounds i8, i8* %t2892, i64 %t2920
  %t2925 = load i8, i8* %t2924
  %t2926 = icmp eq i8 %t2925, 2
  br i1 %t2926, label %map_insert_dec_tomb_678, label %map_insert_store_679
map_insert_dec_tomb_678:
  %t2927 = load i64, i64* %t2826
  %t2928 = sub i64 %t2927, 1
  store i64 %t2928, i64* %t2826
  br label %map_insert_store_679
map_insert_store_679:
  store i8 1, i8* %t2924
  %t2929 = getelementptr inbounds i8*, i8** %t2890, i64 %t2920
  store i8* %t2828, i8** %t2929
  %t2930 = getelementptr inbounds i32, i32* %t2891, i64 %t2920
  store i32 15, i32* %t2930
  %t2931 = load i64, i64* %t2822
  %t2932 = add i64 %t2931, 1
  store i64 %t2932, i64* %t2822
  br label %map_insert_after_677
map_insert_after_677:
  %t2933 = getelementptr i8*, i8** null, i32 1
  %t2934 = ptrtoint i8** %t2933 to i64
  %t2935 = getelementptr i32, i32* null, i32 1
  %t2936 = ptrtoint i32* %t2935 to i64
  %t2937 = load i8*, i8** %t0
  %t2938 = icmp eq i8* %t2937, null
  br i1 %t2938, label %map_cow_alloc_680, label %map_cow_check_681
map_cow_alloc_680:
  %t2939 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2940 = call i8* @star_rc_alloc(i64 48, i8* %t2939)
  %t2941 = bitcast i8* %t2940 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2942 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2941, i32 0, i32 0
  store i8** null, i8*** %t2942
  %t2943 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2941, i32 0, i32 1
  store i32* null, i32** %t2943
  %t2944 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2941, i32 0, i32 2
  store i8* null, i8** %t2944
  %t2945 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2941, i32 0, i32 3
  store i64 0, i64* %t2945
  %t2946 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2941, i32 0, i32 4
  store i64 0, i64* %t2946
  %t2947 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2941, i32 0, i32 5
  store i64 0, i64* %t2947
  store i8* %t2940, i8** %t0
  br label %map_cow_done_682
map_cow_check_681:
  %t2948 = getelementptr inbounds i8, i8* %t2937, i64 -16
  %t2949 = bitcast i8* %t2948 to i64*
  %t2950 = load atomic i64, i64* %t2949 seq_cst, align 8
  %t2951 = icmp eq i64 %t2950, 1
  br i1 %t2951, label %map_cow_done_682, label %map_cow_clone_683
map_cow_clone_683:
  %t2952 = bitcast i8* %t2937 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2953 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2952, i32 0, i32 0
  %t2954 = load i8**, i8*** %t2953
  %t2955 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2952, i32 0, i32 1
  %t2956 = load i32*, i32** %t2955
  %t2957 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2952, i32 0, i32 2
  %t2958 = load i8*, i8** %t2957
  %t2959 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2952, i32 0, i32 3
  %t2960 = load i64, i64* %t2959
  %t2961 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2952, i32 0, i32 4
  %t2962 = load i64, i64* %t2961
  %t2963 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2952, i32 0, i32 5
  %t2964 = load i64, i64* %t2963
  %t2965 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t2966 = call i8* @star_rc_alloc(i64 48, i8* %t2965)
  %t2967 = bitcast i8* %t2966 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2968 = mul i64 %t2962, %t2934
  %t2969 = call i8* @malloc(i64 %t2968)
  %t2970 = bitcast i8* %t2969 to i8**
  %t2971 = mul i64 %t2962, %t2936
  %t2972 = call i8* @malloc(i64 %t2971)
  %t2973 = bitcast i8* %t2972 to i32*
  %t2974 = call i8* @malloc(i64 %t2962)
  %t2975 = icmp sgt i64 %t2962, 0
  br i1 %t2975, label %map_cow_copy_684, label %map_cow_after_copy_685
map_cow_copy_684:
  %t2976 = mul i64 %t2962, %t2934
  %t2977 = bitcast i8** %t2954 to i8*
  call i8* @memcpy(i8* %t2969, i8* %t2977, i64 %t2976)
  %t2978 = mul i64 %t2962, %t2936
  %t2979 = bitcast i32* %t2956 to i8*
  call i8* @memcpy(i8* %t2972, i8* %t2979, i64 %t2978)
  call i8* @memcpy(i8* %t2974, i8* %t2958, i64 %t2962)
  store i64 0, i64* %t2980
  br label %map_cow_retain_cond_686
map_cow_retain_cond_686:
  %t2981 = load i64, i64* %t2980
  %t2982 = icmp slt i64 %t2981, %t2962
  br i1 %t2982, label %map_cow_retain_body_687, label %map_cow_retain_end_690
map_cow_retain_body_687:
  %t2983 = getelementptr inbounds i8, i8* %t2974, i64 %t2981
  %t2984 = load i8, i8* %t2983
  %t2985 = icmp eq i8 %t2984, 1
  br i1 %t2985, label %map_cow_retain_occ_688, label %map_cow_retain_next_689
map_cow_retain_occ_688:
  %t2986 = getelementptr inbounds i8*, i8** %t2970, i64 %t2981
  %t2987 = load i8*, i8** %t2986
  call void @star_rc_retain(i8* %t2987)
  br label %map_cow_retain_next_689
map_cow_retain_next_689:
  %t2988 = add i64 %t2981, 1
  store i64 %t2988, i64* %t2980
  br label %map_cow_retain_cond_686
map_cow_retain_end_690:
  br label %map_cow_after_copy_685
map_cow_after_copy_685:
  %t2989 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2967, i32 0, i32 0
  store i8** %t2970, i8*** %t2989
  %t2990 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2967, i32 0, i32 1
  store i32* %t2973, i32** %t2990
  %t2991 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2967, i32 0, i32 2
  store i8* %t2974, i8** %t2991
  %t2992 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2967, i32 0, i32 3
  store i64 %t2960, i64* %t2992
  %t2993 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2967, i32 0, i32 4
  store i64 %t2962, i64* %t2993
  %t2994 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2967, i32 0, i32 5
  store i64 %t2964, i64* %t2994
  call void @star_rc_release(i8* %t2937)
  store i8* %t2966, i8** %t0
  br label %map_cow_done_682
map_cow_done_682:
  %t2995 = load i8*, i8** %t0
  %t2996 = bitcast i8* %t2995 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t2997 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2996, i32 0, i32 0
  %t2998 = load i8**, i8*** %t2997
  %t2999 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2996, i32 0, i32 1
  %t3000 = load i32*, i32** %t2999
  %t3001 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2996, i32 0, i32 2
  %t3002 = load i8*, i8** %t3001
  %t3003 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2996, i32 0, i32 3
  %t3004 = load i64, i64* %t3003
  %t3005 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2996, i32 0, i32 4
  %t3006 = load i64, i64* %t3005
  %t3007 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t2996, i32 0, i32 5
  %t3008 = load i64, i64* %t3007
  %t3009 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.16, i64 0, i32 2, i64 0
  %t3010 = load i64, i64* %t3003
  %t3011 = load i64, i64* %t3005
  %t3012 = load i64, i64* %t3007
  %t3013 = add i64 %t3010, %t3012
  %t3014 = add i64 %t3013, 1
  %t3015 = mul i64 %t3014, 4
  %t3016 = mul i64 %t3011, 3
  %t3017 = icmp sgt i64 %t3015, %t3016
  br i1 %t3017, label %map_insert_grow_691, label %map_insert_after_grow_692
map_insert_grow_691:
  %t3018 = getelementptr i8*, i8** null, i32 1
  %t3019 = ptrtoint i8** %t3018 to i64
  %t3020 = getelementptr i32, i32* null, i32 1
  %t3021 = ptrtoint i32* %t3020 to i64
  %t3022 = mul i64 %t3011, 2
  %t3023 = icmp sgt i64 %t3022, 0
  %t3024 = select i1 %t3023, i64 %t3022, i64 8
  %t3025 = sub i64 %t3024, 1
  %t3026 = mul i64 %t3024, %t3019
  %t3027 = call i8* @malloc(i64 %t3026)
  %t3028 = bitcast i8* %t3027 to i8**
  %t3029 = mul i64 %t3024, %t3021
  %t3030 = call i8* @malloc(i64 %t3029)
  %t3031 = bitcast i8* %t3030 to i32*
  %t3032 = call i8* @malloc(i64 %t3024)
  store i64 0, i64* %t3033
  br label %ht_fill8_cond_693
ht_fill8_cond_693:
  %t3034 = load i64, i64* %t3033
  %t3035 = icmp slt i64 %t3034, %t3024
  br i1 %t3035, label %ht_fill8_body_694, label %ht_fill8_end_695
ht_fill8_body_694:
  %t3036 = getelementptr inbounds i8, i8* %t3032, i64 %t3034
  store i8 0, i8* %t3036
  %t3037 = add i64 %t3034, 1
  store i64 %t3037, i64* %t3033
  br label %ht_fill8_cond_693
ht_fill8_end_695:
  %t3038 = load i8**, i8*** %t2997
  %t3039 = load i32*, i32** %t2999
  %t3040 = load i8*, i8** %t3001
  store i64 0, i64* %t3041
  br label %map_grow_cond_696
map_grow_cond_696:
  %t3042 = load i64, i64* %t3041
  %t3043 = icmp slt i64 %t3042, %t3011
  br i1 %t3043, label %map_grow_body_697, label %map_grow_end_700
map_grow_body_697:
  %t3044 = getelementptr inbounds i8, i8* %t3040, i64 %t3042
  %t3045 = load i8, i8* %t3044
  %t3046 = icmp eq i8 %t3045, 1
  br i1 %t3046, label %map_grow_occ_698, label %map_grow_next_699
map_grow_occ_698:
  %t3047 = getelementptr inbounds i8*, i8** %t3038, i64 %t3042
  %t3048 = load i8*, i8** %t3047
  %t3049 = getelementptr inbounds i32, i32* %t3039, i64 %t3042
  %t3050 = load i32, i32* %t3049
  %t3051 = call i64 @hash_str(i8* %t3048)
  %t3052 = and i64 %t3051, %t3025
  store i64 0, i64* %t3053
  store i64 %t3052, i64* %t3054
  br label %ht_fe_cond_701
ht_fe_cond_701:
  %t3055 = load i64, i64* %t3053
  %t3056 = icmp slt i64 %t3055, %t3024
  br i1 %t3056, label %ht_fe_body_702, label %ht_fe_end_704
ht_fe_body_702:
  %t3057 = load i64, i64* %t3054
  %t3058 = getelementptr inbounds i8, i8* %t3032, i64 %t3057
  %t3059 = load i8, i8* %t3058
  %t3060 = icmp eq i8 %t3059, 0
  br i1 %t3060, label %ht_fe_end_704, label %ht_fe_next_703
ht_fe_next_703:
  %t3061 = add i64 %t3057, 1
  %t3062 = and i64 %t3061, %t3025
  store i64 %t3062, i64* %t3054
  %t3063 = add i64 %t3055, 1
  store i64 %t3063, i64* %t3053
  br label %ht_fe_cond_701
ht_fe_end_704:
  %t3064 = load i64, i64* %t3054
  %t3065 = getelementptr inbounds i8, i8* %t3032, i64 %t3064
  store i8 1, i8* %t3065
  %t3066 = getelementptr inbounds i8*, i8** %t3028, i64 %t3064
  store i8* %t3048, i8** %t3066
  %t3067 = getelementptr inbounds i32, i32* %t3031, i64 %t3064
  store i32 %t3050, i32* %t3067
  br label %map_grow_next_699
map_grow_next_699:
  %t3068 = add i64 %t3042, 1
  store i64 %t3068, i64* %t3041
  br label %map_grow_cond_696
map_grow_end_700:
  %t3069 = bitcast i8** %t3038 to i8*
  call void @free(i8* %t3069)
  %t3070 = bitcast i32* %t3039 to i8*
  call void @free(i8* %t3070)
  call void @free(i8* %t3040)
  store i8** %t3028, i8*** %t2997
  store i32* %t3031, i32** %t2999
  store i8* %t3032, i8** %t3001
  store i64 %t3024, i64* %t3005
  store i64 0, i64* %t3007
  br label %map_insert_after_grow_692
map_insert_after_grow_692:
  %t3071 = load i8**, i8*** %t2997
  %t3072 = load i32*, i32** %t2999
  %t3073 = load i8*, i8** %t3001
  %t3074 = load i64, i64* %t3005
  %t3075 = sub i64 %t3074, 1
  %t3076 = call i64 @hash_str(i8* %t3009)
  %t3077 = and i64 %t3076, %t3075
  store i64 0, i64* %t3078
  store i64 %t3077, i64* %t3079
  store i1 false, i1* %t3080
  store i64 -1, i64* %t3081
  store i64 -1, i64* %t3082
  store i1 false, i1* %t3083
  br label %ht_probe_cond_705
ht_probe_cond_705:
  %t3084 = load i64, i64* %t3078
  %t3085 = icmp slt i64 %t3084, %t3074
  br i1 %t3085, label %ht_probe_body_706, label %ht_probe_end_716
ht_probe_body_706:
  %t3086 = load i64, i64* %t3079
  %t3087 = getelementptr inbounds i8, i8* %t3073, i64 %t3086
  %t3088 = load i8, i8* %t3087
  %t3089 = icmp eq i8 %t3088, 0
  br i1 %t3089, label %ht_probe_on_empty_708, label %ht_probe_check_occ_707
ht_probe_check_occ_707:
  %t3090 = icmp eq i8 %t3088, 1
  br i1 %t3090, label %ht_probe_on_occ_711, label %ht_probe_on_tomb_713
ht_probe_on_empty_708:
  %t3091 = load i1, i1* %t3083
  br i1 %t3091, label %ht_probe_after_islot_empty_710, label %ht_probe_set_islot_empty_709
ht_probe_set_islot_empty_709:
  store i64 %t3086, i64* %t3082
  store i1 true, i1* %t3083
  br label %ht_probe_after_islot_empty_710
ht_probe_after_islot_empty_710:
  br label %ht_probe_end_716
ht_probe_on_occ_711:
  %t3092 = getelementptr inbounds i8*, i8** %t3071, i64 %t3086
  %t3093 = load i8*, i8** %t3092
  %t3094 = call i1 @eq_str(i8* %t3093, i8* %t3009)
  br i1 %t3094, label %ht_probe_on_match_712, label %ht_probe_next_715
ht_probe_on_match_712:
  store i1 true, i1* %t3080
  store i64 %t3086, i64* %t3081
  br label %ht_probe_end_716
ht_probe_on_tomb_713:
  %t3095 = load i1, i1* %t3083
  br i1 %t3095, label %ht_probe_next_715, label %ht_probe_set_islot_tomb_714
ht_probe_set_islot_tomb_714:
  store i64 %t3086, i64* %t3082
  store i1 true, i1* %t3083
  br label %ht_probe_next_715
ht_probe_next_715:
  %t3096 = add i64 %t3086, 1
  %t3097 = and i64 %t3096, %t3075
  store i64 %t3097, i64* %t3079
  %t3098 = add i64 %t3084, 1
  store i64 %t3098, i64* %t3078
  br label %ht_probe_cond_705
ht_probe_end_716:
  %t3099 = load i1, i1* %t3080
  %t3100 = load i64, i64* %t3081
  %t3101 = load i64, i64* %t3082
  br i1 %t3099, label %map_insert_overwrite_717, label %map_insert_new_718
map_insert_overwrite_717:
  store i8* %t3009, i8** %t3102
  %t3103 = load i8*, i8** %t3102
  call void @star_rc_release(i8* %t3103)
  %t3104 = getelementptr inbounds i32, i32* %t3072, i64 %t3100
  store i32 16, i32* %t3104
  br label %map_insert_after_719
map_insert_new_718:
  %t3105 = getelementptr inbounds i8, i8* %t3073, i64 %t3101
  %t3106 = load i8, i8* %t3105
  %t3107 = icmp eq i8 %t3106, 2
  br i1 %t3107, label %map_insert_dec_tomb_720, label %map_insert_store_721
map_insert_dec_tomb_720:
  %t3108 = load i64, i64* %t3007
  %t3109 = sub i64 %t3108, 1
  store i64 %t3109, i64* %t3007
  br label %map_insert_store_721
map_insert_store_721:
  store i8 1, i8* %t3105
  %t3110 = getelementptr inbounds i8*, i8** %t3071, i64 %t3101
  store i8* %t3009, i8** %t3110
  %t3111 = getelementptr inbounds i32, i32* %t3072, i64 %t3101
  store i32 16, i32* %t3111
  %t3112 = load i64, i64* %t3003
  %t3113 = add i64 %t3112, 1
  store i64 %t3113, i64* %t3003
  br label %map_insert_after_719
map_insert_after_719:
  %t3114 = getelementptr i8*, i8** null, i32 1
  %t3115 = ptrtoint i8** %t3114 to i64
  %t3116 = getelementptr i32, i32* null, i32 1
  %t3117 = ptrtoint i32* %t3116 to i64
  %t3118 = load i8*, i8** %t0
  %t3119 = icmp eq i8* %t3118, null
  br i1 %t3119, label %map_cow_alloc_722, label %map_cow_check_723
map_cow_alloc_722:
  %t3120 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3121 = call i8* @star_rc_alloc(i64 48, i8* %t3120)
  %t3122 = bitcast i8* %t3121 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3123 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3122, i32 0, i32 0
  store i8** null, i8*** %t3123
  %t3124 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3122, i32 0, i32 1
  store i32* null, i32** %t3124
  %t3125 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3122, i32 0, i32 2
  store i8* null, i8** %t3125
  %t3126 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3122, i32 0, i32 3
  store i64 0, i64* %t3126
  %t3127 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3122, i32 0, i32 4
  store i64 0, i64* %t3127
  %t3128 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3122, i32 0, i32 5
  store i64 0, i64* %t3128
  store i8* %t3121, i8** %t0
  br label %map_cow_done_724
map_cow_check_723:
  %t3129 = getelementptr inbounds i8, i8* %t3118, i64 -16
  %t3130 = bitcast i8* %t3129 to i64*
  %t3131 = load atomic i64, i64* %t3130 seq_cst, align 8
  %t3132 = icmp eq i64 %t3131, 1
  br i1 %t3132, label %map_cow_done_724, label %map_cow_clone_725
map_cow_clone_725:
  %t3133 = bitcast i8* %t3118 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3134 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3133, i32 0, i32 0
  %t3135 = load i8**, i8*** %t3134
  %t3136 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3133, i32 0, i32 1
  %t3137 = load i32*, i32** %t3136
  %t3138 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3133, i32 0, i32 2
  %t3139 = load i8*, i8** %t3138
  %t3140 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3133, i32 0, i32 3
  %t3141 = load i64, i64* %t3140
  %t3142 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3133, i32 0, i32 4
  %t3143 = load i64, i64* %t3142
  %t3144 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3133, i32 0, i32 5
  %t3145 = load i64, i64* %t3144
  %t3146 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3147 = call i8* @star_rc_alloc(i64 48, i8* %t3146)
  %t3148 = bitcast i8* %t3147 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3149 = mul i64 %t3143, %t3115
  %t3150 = call i8* @malloc(i64 %t3149)
  %t3151 = bitcast i8* %t3150 to i8**
  %t3152 = mul i64 %t3143, %t3117
  %t3153 = call i8* @malloc(i64 %t3152)
  %t3154 = bitcast i8* %t3153 to i32*
  %t3155 = call i8* @malloc(i64 %t3143)
  %t3156 = icmp sgt i64 %t3143, 0
  br i1 %t3156, label %map_cow_copy_726, label %map_cow_after_copy_727
map_cow_copy_726:
  %t3157 = mul i64 %t3143, %t3115
  %t3158 = bitcast i8** %t3135 to i8*
  call i8* @memcpy(i8* %t3150, i8* %t3158, i64 %t3157)
  %t3159 = mul i64 %t3143, %t3117
  %t3160 = bitcast i32* %t3137 to i8*
  call i8* @memcpy(i8* %t3153, i8* %t3160, i64 %t3159)
  call i8* @memcpy(i8* %t3155, i8* %t3139, i64 %t3143)
  store i64 0, i64* %t3161
  br label %map_cow_retain_cond_728
map_cow_retain_cond_728:
  %t3162 = load i64, i64* %t3161
  %t3163 = icmp slt i64 %t3162, %t3143
  br i1 %t3163, label %map_cow_retain_body_729, label %map_cow_retain_end_732
map_cow_retain_body_729:
  %t3164 = getelementptr inbounds i8, i8* %t3155, i64 %t3162
  %t3165 = load i8, i8* %t3164
  %t3166 = icmp eq i8 %t3165, 1
  br i1 %t3166, label %map_cow_retain_occ_730, label %map_cow_retain_next_731
map_cow_retain_occ_730:
  %t3167 = getelementptr inbounds i8*, i8** %t3151, i64 %t3162
  %t3168 = load i8*, i8** %t3167
  call void @star_rc_retain(i8* %t3168)
  br label %map_cow_retain_next_731
map_cow_retain_next_731:
  %t3169 = add i64 %t3162, 1
  store i64 %t3169, i64* %t3161
  br label %map_cow_retain_cond_728
map_cow_retain_end_732:
  br label %map_cow_after_copy_727
map_cow_after_copy_727:
  %t3170 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3148, i32 0, i32 0
  store i8** %t3151, i8*** %t3170
  %t3171 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3148, i32 0, i32 1
  store i32* %t3154, i32** %t3171
  %t3172 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3148, i32 0, i32 2
  store i8* %t3155, i8** %t3172
  %t3173 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3148, i32 0, i32 3
  store i64 %t3141, i64* %t3173
  %t3174 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3148, i32 0, i32 4
  store i64 %t3143, i64* %t3174
  %t3175 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3148, i32 0, i32 5
  store i64 %t3145, i64* %t3175
  call void @star_rc_release(i8* %t3118)
  store i8* %t3147, i8** %t0
  br label %map_cow_done_724
map_cow_done_724:
  %t3176 = load i8*, i8** %t0
  %t3177 = bitcast i8* %t3176 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3178 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3177, i32 0, i32 0
  %t3179 = load i8**, i8*** %t3178
  %t3180 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3177, i32 0, i32 1
  %t3181 = load i32*, i32** %t3180
  %t3182 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3177, i32 0, i32 2
  %t3183 = load i8*, i8** %t3182
  %t3184 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3177, i32 0, i32 3
  %t3185 = load i64, i64* %t3184
  %t3186 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3177, i32 0, i32 4
  %t3187 = load i64, i64* %t3186
  %t3188 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3177, i32 0, i32 5
  %t3189 = load i64, i64* %t3188
  %t3190 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.17, i64 0, i32 2, i64 0
  %t3191 = load i64, i64* %t3184
  %t3192 = load i64, i64* %t3186
  %t3193 = load i64, i64* %t3188
  %t3194 = add i64 %t3191, %t3193
  %t3195 = add i64 %t3194, 1
  %t3196 = mul i64 %t3195, 4
  %t3197 = mul i64 %t3192, 3
  %t3198 = icmp sgt i64 %t3196, %t3197
  br i1 %t3198, label %map_insert_grow_733, label %map_insert_after_grow_734
map_insert_grow_733:
  %t3199 = getelementptr i8*, i8** null, i32 1
  %t3200 = ptrtoint i8** %t3199 to i64
  %t3201 = getelementptr i32, i32* null, i32 1
  %t3202 = ptrtoint i32* %t3201 to i64
  %t3203 = mul i64 %t3192, 2
  %t3204 = icmp sgt i64 %t3203, 0
  %t3205 = select i1 %t3204, i64 %t3203, i64 8
  %t3206 = sub i64 %t3205, 1
  %t3207 = mul i64 %t3205, %t3200
  %t3208 = call i8* @malloc(i64 %t3207)
  %t3209 = bitcast i8* %t3208 to i8**
  %t3210 = mul i64 %t3205, %t3202
  %t3211 = call i8* @malloc(i64 %t3210)
  %t3212 = bitcast i8* %t3211 to i32*
  %t3213 = call i8* @malloc(i64 %t3205)
  store i64 0, i64* %t3214
  br label %ht_fill8_cond_735
ht_fill8_cond_735:
  %t3215 = load i64, i64* %t3214
  %t3216 = icmp slt i64 %t3215, %t3205
  br i1 %t3216, label %ht_fill8_body_736, label %ht_fill8_end_737
ht_fill8_body_736:
  %t3217 = getelementptr inbounds i8, i8* %t3213, i64 %t3215
  store i8 0, i8* %t3217
  %t3218 = add i64 %t3215, 1
  store i64 %t3218, i64* %t3214
  br label %ht_fill8_cond_735
ht_fill8_end_737:
  %t3219 = load i8**, i8*** %t3178
  %t3220 = load i32*, i32** %t3180
  %t3221 = load i8*, i8** %t3182
  store i64 0, i64* %t3222
  br label %map_grow_cond_738
map_grow_cond_738:
  %t3223 = load i64, i64* %t3222
  %t3224 = icmp slt i64 %t3223, %t3192
  br i1 %t3224, label %map_grow_body_739, label %map_grow_end_742
map_grow_body_739:
  %t3225 = getelementptr inbounds i8, i8* %t3221, i64 %t3223
  %t3226 = load i8, i8* %t3225
  %t3227 = icmp eq i8 %t3226, 1
  br i1 %t3227, label %map_grow_occ_740, label %map_grow_next_741
map_grow_occ_740:
  %t3228 = getelementptr inbounds i8*, i8** %t3219, i64 %t3223
  %t3229 = load i8*, i8** %t3228
  %t3230 = getelementptr inbounds i32, i32* %t3220, i64 %t3223
  %t3231 = load i32, i32* %t3230
  %t3232 = call i64 @hash_str(i8* %t3229)
  %t3233 = and i64 %t3232, %t3206
  store i64 0, i64* %t3234
  store i64 %t3233, i64* %t3235
  br label %ht_fe_cond_743
ht_fe_cond_743:
  %t3236 = load i64, i64* %t3234
  %t3237 = icmp slt i64 %t3236, %t3205
  br i1 %t3237, label %ht_fe_body_744, label %ht_fe_end_746
ht_fe_body_744:
  %t3238 = load i64, i64* %t3235
  %t3239 = getelementptr inbounds i8, i8* %t3213, i64 %t3238
  %t3240 = load i8, i8* %t3239
  %t3241 = icmp eq i8 %t3240, 0
  br i1 %t3241, label %ht_fe_end_746, label %ht_fe_next_745
ht_fe_next_745:
  %t3242 = add i64 %t3238, 1
  %t3243 = and i64 %t3242, %t3206
  store i64 %t3243, i64* %t3235
  %t3244 = add i64 %t3236, 1
  store i64 %t3244, i64* %t3234
  br label %ht_fe_cond_743
ht_fe_end_746:
  %t3245 = load i64, i64* %t3235
  %t3246 = getelementptr inbounds i8, i8* %t3213, i64 %t3245
  store i8 1, i8* %t3246
  %t3247 = getelementptr inbounds i8*, i8** %t3209, i64 %t3245
  store i8* %t3229, i8** %t3247
  %t3248 = getelementptr inbounds i32, i32* %t3212, i64 %t3245
  store i32 %t3231, i32* %t3248
  br label %map_grow_next_741
map_grow_next_741:
  %t3249 = add i64 %t3223, 1
  store i64 %t3249, i64* %t3222
  br label %map_grow_cond_738
map_grow_end_742:
  %t3250 = bitcast i8** %t3219 to i8*
  call void @free(i8* %t3250)
  %t3251 = bitcast i32* %t3220 to i8*
  call void @free(i8* %t3251)
  call void @free(i8* %t3221)
  store i8** %t3209, i8*** %t3178
  store i32* %t3212, i32** %t3180
  store i8* %t3213, i8** %t3182
  store i64 %t3205, i64* %t3186
  store i64 0, i64* %t3188
  br label %map_insert_after_grow_734
map_insert_after_grow_734:
  %t3252 = load i8**, i8*** %t3178
  %t3253 = load i32*, i32** %t3180
  %t3254 = load i8*, i8** %t3182
  %t3255 = load i64, i64* %t3186
  %t3256 = sub i64 %t3255, 1
  %t3257 = call i64 @hash_str(i8* %t3190)
  %t3258 = and i64 %t3257, %t3256
  store i64 0, i64* %t3259
  store i64 %t3258, i64* %t3260
  store i1 false, i1* %t3261
  store i64 -1, i64* %t3262
  store i64 -1, i64* %t3263
  store i1 false, i1* %t3264
  br label %ht_probe_cond_747
ht_probe_cond_747:
  %t3265 = load i64, i64* %t3259
  %t3266 = icmp slt i64 %t3265, %t3255
  br i1 %t3266, label %ht_probe_body_748, label %ht_probe_end_758
ht_probe_body_748:
  %t3267 = load i64, i64* %t3260
  %t3268 = getelementptr inbounds i8, i8* %t3254, i64 %t3267
  %t3269 = load i8, i8* %t3268
  %t3270 = icmp eq i8 %t3269, 0
  br i1 %t3270, label %ht_probe_on_empty_750, label %ht_probe_check_occ_749
ht_probe_check_occ_749:
  %t3271 = icmp eq i8 %t3269, 1
  br i1 %t3271, label %ht_probe_on_occ_753, label %ht_probe_on_tomb_755
ht_probe_on_empty_750:
  %t3272 = load i1, i1* %t3264
  br i1 %t3272, label %ht_probe_after_islot_empty_752, label %ht_probe_set_islot_empty_751
ht_probe_set_islot_empty_751:
  store i64 %t3267, i64* %t3263
  store i1 true, i1* %t3264
  br label %ht_probe_after_islot_empty_752
ht_probe_after_islot_empty_752:
  br label %ht_probe_end_758
ht_probe_on_occ_753:
  %t3273 = getelementptr inbounds i8*, i8** %t3252, i64 %t3267
  %t3274 = load i8*, i8** %t3273
  %t3275 = call i1 @eq_str(i8* %t3274, i8* %t3190)
  br i1 %t3275, label %ht_probe_on_match_754, label %ht_probe_next_757
ht_probe_on_match_754:
  store i1 true, i1* %t3261
  store i64 %t3267, i64* %t3262
  br label %ht_probe_end_758
ht_probe_on_tomb_755:
  %t3276 = load i1, i1* %t3264
  br i1 %t3276, label %ht_probe_next_757, label %ht_probe_set_islot_tomb_756
ht_probe_set_islot_tomb_756:
  store i64 %t3267, i64* %t3263
  store i1 true, i1* %t3264
  br label %ht_probe_next_757
ht_probe_next_757:
  %t3277 = add i64 %t3267, 1
  %t3278 = and i64 %t3277, %t3256
  store i64 %t3278, i64* %t3260
  %t3279 = add i64 %t3265, 1
  store i64 %t3279, i64* %t3259
  br label %ht_probe_cond_747
ht_probe_end_758:
  %t3280 = load i1, i1* %t3261
  %t3281 = load i64, i64* %t3262
  %t3282 = load i64, i64* %t3263
  br i1 %t3280, label %map_insert_overwrite_759, label %map_insert_new_760
map_insert_overwrite_759:
  store i8* %t3190, i8** %t3283
  %t3284 = load i8*, i8** %t3283
  call void @star_rc_release(i8* %t3284)
  %t3285 = getelementptr inbounds i32, i32* %t3253, i64 %t3281
  store i32 17, i32* %t3285
  br label %map_insert_after_761
map_insert_new_760:
  %t3286 = getelementptr inbounds i8, i8* %t3254, i64 %t3282
  %t3287 = load i8, i8* %t3286
  %t3288 = icmp eq i8 %t3287, 2
  br i1 %t3288, label %map_insert_dec_tomb_762, label %map_insert_store_763
map_insert_dec_tomb_762:
  %t3289 = load i64, i64* %t3188
  %t3290 = sub i64 %t3289, 1
  store i64 %t3290, i64* %t3188
  br label %map_insert_store_763
map_insert_store_763:
  store i8 1, i8* %t3286
  %t3291 = getelementptr inbounds i8*, i8** %t3252, i64 %t3282
  store i8* %t3190, i8** %t3291
  %t3292 = getelementptr inbounds i32, i32* %t3253, i64 %t3282
  store i32 17, i32* %t3292
  %t3293 = load i64, i64* %t3184
  %t3294 = add i64 %t3293, 1
  store i64 %t3294, i64* %t3184
  br label %map_insert_after_761
map_insert_after_761:
  %t3295 = getelementptr i8*, i8** null, i32 1
  %t3296 = ptrtoint i8** %t3295 to i64
  %t3297 = getelementptr i32, i32* null, i32 1
  %t3298 = ptrtoint i32* %t3297 to i64
  %t3299 = load i8*, i8** %t0
  %t3300 = icmp eq i8* %t3299, null
  br i1 %t3300, label %map_cow_alloc_764, label %map_cow_check_765
map_cow_alloc_764:
  %t3301 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3302 = call i8* @star_rc_alloc(i64 48, i8* %t3301)
  %t3303 = bitcast i8* %t3302 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3304 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3303, i32 0, i32 0
  store i8** null, i8*** %t3304
  %t3305 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3303, i32 0, i32 1
  store i32* null, i32** %t3305
  %t3306 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3303, i32 0, i32 2
  store i8* null, i8** %t3306
  %t3307 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3303, i32 0, i32 3
  store i64 0, i64* %t3307
  %t3308 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3303, i32 0, i32 4
  store i64 0, i64* %t3308
  %t3309 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3303, i32 0, i32 5
  store i64 0, i64* %t3309
  store i8* %t3302, i8** %t0
  br label %map_cow_done_766
map_cow_check_765:
  %t3310 = getelementptr inbounds i8, i8* %t3299, i64 -16
  %t3311 = bitcast i8* %t3310 to i64*
  %t3312 = load atomic i64, i64* %t3311 seq_cst, align 8
  %t3313 = icmp eq i64 %t3312, 1
  br i1 %t3313, label %map_cow_done_766, label %map_cow_clone_767
map_cow_clone_767:
  %t3314 = bitcast i8* %t3299 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3315 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3314, i32 0, i32 0
  %t3316 = load i8**, i8*** %t3315
  %t3317 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3314, i32 0, i32 1
  %t3318 = load i32*, i32** %t3317
  %t3319 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3314, i32 0, i32 2
  %t3320 = load i8*, i8** %t3319
  %t3321 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3314, i32 0, i32 3
  %t3322 = load i64, i64* %t3321
  %t3323 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3314, i32 0, i32 4
  %t3324 = load i64, i64* %t3323
  %t3325 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3314, i32 0, i32 5
  %t3326 = load i64, i64* %t3325
  %t3327 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3328 = call i8* @star_rc_alloc(i64 48, i8* %t3327)
  %t3329 = bitcast i8* %t3328 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3330 = mul i64 %t3324, %t3296
  %t3331 = call i8* @malloc(i64 %t3330)
  %t3332 = bitcast i8* %t3331 to i8**
  %t3333 = mul i64 %t3324, %t3298
  %t3334 = call i8* @malloc(i64 %t3333)
  %t3335 = bitcast i8* %t3334 to i32*
  %t3336 = call i8* @malloc(i64 %t3324)
  %t3337 = icmp sgt i64 %t3324, 0
  br i1 %t3337, label %map_cow_copy_768, label %map_cow_after_copy_769
map_cow_copy_768:
  %t3338 = mul i64 %t3324, %t3296
  %t3339 = bitcast i8** %t3316 to i8*
  call i8* @memcpy(i8* %t3331, i8* %t3339, i64 %t3338)
  %t3340 = mul i64 %t3324, %t3298
  %t3341 = bitcast i32* %t3318 to i8*
  call i8* @memcpy(i8* %t3334, i8* %t3341, i64 %t3340)
  call i8* @memcpy(i8* %t3336, i8* %t3320, i64 %t3324)
  store i64 0, i64* %t3342
  br label %map_cow_retain_cond_770
map_cow_retain_cond_770:
  %t3343 = load i64, i64* %t3342
  %t3344 = icmp slt i64 %t3343, %t3324
  br i1 %t3344, label %map_cow_retain_body_771, label %map_cow_retain_end_774
map_cow_retain_body_771:
  %t3345 = getelementptr inbounds i8, i8* %t3336, i64 %t3343
  %t3346 = load i8, i8* %t3345
  %t3347 = icmp eq i8 %t3346, 1
  br i1 %t3347, label %map_cow_retain_occ_772, label %map_cow_retain_next_773
map_cow_retain_occ_772:
  %t3348 = getelementptr inbounds i8*, i8** %t3332, i64 %t3343
  %t3349 = load i8*, i8** %t3348
  call void @star_rc_retain(i8* %t3349)
  br label %map_cow_retain_next_773
map_cow_retain_next_773:
  %t3350 = add i64 %t3343, 1
  store i64 %t3350, i64* %t3342
  br label %map_cow_retain_cond_770
map_cow_retain_end_774:
  br label %map_cow_after_copy_769
map_cow_after_copy_769:
  %t3351 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3329, i32 0, i32 0
  store i8** %t3332, i8*** %t3351
  %t3352 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3329, i32 0, i32 1
  store i32* %t3335, i32** %t3352
  %t3353 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3329, i32 0, i32 2
  store i8* %t3336, i8** %t3353
  %t3354 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3329, i32 0, i32 3
  store i64 %t3322, i64* %t3354
  %t3355 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3329, i32 0, i32 4
  store i64 %t3324, i64* %t3355
  %t3356 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3329, i32 0, i32 5
  store i64 %t3326, i64* %t3356
  call void @star_rc_release(i8* %t3299)
  store i8* %t3328, i8** %t0
  br label %map_cow_done_766
map_cow_done_766:
  %t3357 = load i8*, i8** %t0
  %t3358 = bitcast i8* %t3357 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3359 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3358, i32 0, i32 0
  %t3360 = load i8**, i8*** %t3359
  %t3361 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3358, i32 0, i32 1
  %t3362 = load i32*, i32** %t3361
  %t3363 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3358, i32 0, i32 2
  %t3364 = load i8*, i8** %t3363
  %t3365 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3358, i32 0, i32 3
  %t3366 = load i64, i64* %t3365
  %t3367 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3358, i32 0, i32 4
  %t3368 = load i64, i64* %t3367
  %t3369 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3358, i32 0, i32 5
  %t3370 = load i64, i64* %t3369
  %t3371 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.18, i64 0, i32 2, i64 0
  %t3372 = load i64, i64* %t3365
  %t3373 = load i64, i64* %t3367
  %t3374 = load i64, i64* %t3369
  %t3375 = add i64 %t3372, %t3374
  %t3376 = add i64 %t3375, 1
  %t3377 = mul i64 %t3376, 4
  %t3378 = mul i64 %t3373, 3
  %t3379 = icmp sgt i64 %t3377, %t3378
  br i1 %t3379, label %map_insert_grow_775, label %map_insert_after_grow_776
map_insert_grow_775:
  %t3380 = getelementptr i8*, i8** null, i32 1
  %t3381 = ptrtoint i8** %t3380 to i64
  %t3382 = getelementptr i32, i32* null, i32 1
  %t3383 = ptrtoint i32* %t3382 to i64
  %t3384 = mul i64 %t3373, 2
  %t3385 = icmp sgt i64 %t3384, 0
  %t3386 = select i1 %t3385, i64 %t3384, i64 8
  %t3387 = sub i64 %t3386, 1
  %t3388 = mul i64 %t3386, %t3381
  %t3389 = call i8* @malloc(i64 %t3388)
  %t3390 = bitcast i8* %t3389 to i8**
  %t3391 = mul i64 %t3386, %t3383
  %t3392 = call i8* @malloc(i64 %t3391)
  %t3393 = bitcast i8* %t3392 to i32*
  %t3394 = call i8* @malloc(i64 %t3386)
  store i64 0, i64* %t3395
  br label %ht_fill8_cond_777
ht_fill8_cond_777:
  %t3396 = load i64, i64* %t3395
  %t3397 = icmp slt i64 %t3396, %t3386
  br i1 %t3397, label %ht_fill8_body_778, label %ht_fill8_end_779
ht_fill8_body_778:
  %t3398 = getelementptr inbounds i8, i8* %t3394, i64 %t3396
  store i8 0, i8* %t3398
  %t3399 = add i64 %t3396, 1
  store i64 %t3399, i64* %t3395
  br label %ht_fill8_cond_777
ht_fill8_end_779:
  %t3400 = load i8**, i8*** %t3359
  %t3401 = load i32*, i32** %t3361
  %t3402 = load i8*, i8** %t3363
  store i64 0, i64* %t3403
  br label %map_grow_cond_780
map_grow_cond_780:
  %t3404 = load i64, i64* %t3403
  %t3405 = icmp slt i64 %t3404, %t3373
  br i1 %t3405, label %map_grow_body_781, label %map_grow_end_784
map_grow_body_781:
  %t3406 = getelementptr inbounds i8, i8* %t3402, i64 %t3404
  %t3407 = load i8, i8* %t3406
  %t3408 = icmp eq i8 %t3407, 1
  br i1 %t3408, label %map_grow_occ_782, label %map_grow_next_783
map_grow_occ_782:
  %t3409 = getelementptr inbounds i8*, i8** %t3400, i64 %t3404
  %t3410 = load i8*, i8** %t3409
  %t3411 = getelementptr inbounds i32, i32* %t3401, i64 %t3404
  %t3412 = load i32, i32* %t3411
  %t3413 = call i64 @hash_str(i8* %t3410)
  %t3414 = and i64 %t3413, %t3387
  store i64 0, i64* %t3415
  store i64 %t3414, i64* %t3416
  br label %ht_fe_cond_785
ht_fe_cond_785:
  %t3417 = load i64, i64* %t3415
  %t3418 = icmp slt i64 %t3417, %t3386
  br i1 %t3418, label %ht_fe_body_786, label %ht_fe_end_788
ht_fe_body_786:
  %t3419 = load i64, i64* %t3416
  %t3420 = getelementptr inbounds i8, i8* %t3394, i64 %t3419
  %t3421 = load i8, i8* %t3420
  %t3422 = icmp eq i8 %t3421, 0
  br i1 %t3422, label %ht_fe_end_788, label %ht_fe_next_787
ht_fe_next_787:
  %t3423 = add i64 %t3419, 1
  %t3424 = and i64 %t3423, %t3387
  store i64 %t3424, i64* %t3416
  %t3425 = add i64 %t3417, 1
  store i64 %t3425, i64* %t3415
  br label %ht_fe_cond_785
ht_fe_end_788:
  %t3426 = load i64, i64* %t3416
  %t3427 = getelementptr inbounds i8, i8* %t3394, i64 %t3426
  store i8 1, i8* %t3427
  %t3428 = getelementptr inbounds i8*, i8** %t3390, i64 %t3426
  store i8* %t3410, i8** %t3428
  %t3429 = getelementptr inbounds i32, i32* %t3393, i64 %t3426
  store i32 %t3412, i32* %t3429
  br label %map_grow_next_783
map_grow_next_783:
  %t3430 = add i64 %t3404, 1
  store i64 %t3430, i64* %t3403
  br label %map_grow_cond_780
map_grow_end_784:
  %t3431 = bitcast i8** %t3400 to i8*
  call void @free(i8* %t3431)
  %t3432 = bitcast i32* %t3401 to i8*
  call void @free(i8* %t3432)
  call void @free(i8* %t3402)
  store i8** %t3390, i8*** %t3359
  store i32* %t3393, i32** %t3361
  store i8* %t3394, i8** %t3363
  store i64 %t3386, i64* %t3367
  store i64 0, i64* %t3369
  br label %map_insert_after_grow_776
map_insert_after_grow_776:
  %t3433 = load i8**, i8*** %t3359
  %t3434 = load i32*, i32** %t3361
  %t3435 = load i8*, i8** %t3363
  %t3436 = load i64, i64* %t3367
  %t3437 = sub i64 %t3436, 1
  %t3438 = call i64 @hash_str(i8* %t3371)
  %t3439 = and i64 %t3438, %t3437
  store i64 0, i64* %t3440
  store i64 %t3439, i64* %t3441
  store i1 false, i1* %t3442
  store i64 -1, i64* %t3443
  store i64 -1, i64* %t3444
  store i1 false, i1* %t3445
  br label %ht_probe_cond_789
ht_probe_cond_789:
  %t3446 = load i64, i64* %t3440
  %t3447 = icmp slt i64 %t3446, %t3436
  br i1 %t3447, label %ht_probe_body_790, label %ht_probe_end_800
ht_probe_body_790:
  %t3448 = load i64, i64* %t3441
  %t3449 = getelementptr inbounds i8, i8* %t3435, i64 %t3448
  %t3450 = load i8, i8* %t3449
  %t3451 = icmp eq i8 %t3450, 0
  br i1 %t3451, label %ht_probe_on_empty_792, label %ht_probe_check_occ_791
ht_probe_check_occ_791:
  %t3452 = icmp eq i8 %t3450, 1
  br i1 %t3452, label %ht_probe_on_occ_795, label %ht_probe_on_tomb_797
ht_probe_on_empty_792:
  %t3453 = load i1, i1* %t3445
  br i1 %t3453, label %ht_probe_after_islot_empty_794, label %ht_probe_set_islot_empty_793
ht_probe_set_islot_empty_793:
  store i64 %t3448, i64* %t3444
  store i1 true, i1* %t3445
  br label %ht_probe_after_islot_empty_794
ht_probe_after_islot_empty_794:
  br label %ht_probe_end_800
ht_probe_on_occ_795:
  %t3454 = getelementptr inbounds i8*, i8** %t3433, i64 %t3448
  %t3455 = load i8*, i8** %t3454
  %t3456 = call i1 @eq_str(i8* %t3455, i8* %t3371)
  br i1 %t3456, label %ht_probe_on_match_796, label %ht_probe_next_799
ht_probe_on_match_796:
  store i1 true, i1* %t3442
  store i64 %t3448, i64* %t3443
  br label %ht_probe_end_800
ht_probe_on_tomb_797:
  %t3457 = load i1, i1* %t3445
  br i1 %t3457, label %ht_probe_next_799, label %ht_probe_set_islot_tomb_798
ht_probe_set_islot_tomb_798:
  store i64 %t3448, i64* %t3444
  store i1 true, i1* %t3445
  br label %ht_probe_next_799
ht_probe_next_799:
  %t3458 = add i64 %t3448, 1
  %t3459 = and i64 %t3458, %t3437
  store i64 %t3459, i64* %t3441
  %t3460 = add i64 %t3446, 1
  store i64 %t3460, i64* %t3440
  br label %ht_probe_cond_789
ht_probe_end_800:
  %t3461 = load i1, i1* %t3442
  %t3462 = load i64, i64* %t3443
  %t3463 = load i64, i64* %t3444
  br i1 %t3461, label %map_insert_overwrite_801, label %map_insert_new_802
map_insert_overwrite_801:
  store i8* %t3371, i8** %t3464
  %t3465 = load i8*, i8** %t3464
  call void @star_rc_release(i8* %t3465)
  %t3466 = getelementptr inbounds i32, i32* %t3434, i64 %t3462
  store i32 21, i32* %t3466
  br label %map_insert_after_803
map_insert_new_802:
  %t3467 = getelementptr inbounds i8, i8* %t3435, i64 %t3463
  %t3468 = load i8, i8* %t3467
  %t3469 = icmp eq i8 %t3468, 2
  br i1 %t3469, label %map_insert_dec_tomb_804, label %map_insert_store_805
map_insert_dec_tomb_804:
  %t3470 = load i64, i64* %t3369
  %t3471 = sub i64 %t3470, 1
  store i64 %t3471, i64* %t3369
  br label %map_insert_store_805
map_insert_store_805:
  store i8 1, i8* %t3467
  %t3472 = getelementptr inbounds i8*, i8** %t3433, i64 %t3463
  store i8* %t3371, i8** %t3472
  %t3473 = getelementptr inbounds i32, i32* %t3434, i64 %t3463
  store i32 21, i32* %t3473
  %t3474 = load i64, i64* %t3365
  %t3475 = add i64 %t3474, 1
  store i64 %t3475, i64* %t3365
  br label %map_insert_after_803
map_insert_after_803:
  %t3476 = getelementptr i8*, i8** null, i32 1
  %t3477 = ptrtoint i8** %t3476 to i64
  %t3478 = getelementptr i32, i32* null, i32 1
  %t3479 = ptrtoint i32* %t3478 to i64
  %t3480 = load i8*, i8** %t0
  %t3481 = icmp eq i8* %t3480, null
  br i1 %t3481, label %map_cow_alloc_806, label %map_cow_check_807
map_cow_alloc_806:
  %t3482 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3483 = call i8* @star_rc_alloc(i64 48, i8* %t3482)
  %t3484 = bitcast i8* %t3483 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3485 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3484, i32 0, i32 0
  store i8** null, i8*** %t3485
  %t3486 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3484, i32 0, i32 1
  store i32* null, i32** %t3486
  %t3487 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3484, i32 0, i32 2
  store i8* null, i8** %t3487
  %t3488 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3484, i32 0, i32 3
  store i64 0, i64* %t3488
  %t3489 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3484, i32 0, i32 4
  store i64 0, i64* %t3489
  %t3490 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3484, i32 0, i32 5
  store i64 0, i64* %t3490
  store i8* %t3483, i8** %t0
  br label %map_cow_done_808
map_cow_check_807:
  %t3491 = getelementptr inbounds i8, i8* %t3480, i64 -16
  %t3492 = bitcast i8* %t3491 to i64*
  %t3493 = load atomic i64, i64* %t3492 seq_cst, align 8
  %t3494 = icmp eq i64 %t3493, 1
  br i1 %t3494, label %map_cow_done_808, label %map_cow_clone_809
map_cow_clone_809:
  %t3495 = bitcast i8* %t3480 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3496 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3495, i32 0, i32 0
  %t3497 = load i8**, i8*** %t3496
  %t3498 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3495, i32 0, i32 1
  %t3499 = load i32*, i32** %t3498
  %t3500 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3495, i32 0, i32 2
  %t3501 = load i8*, i8** %t3500
  %t3502 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3495, i32 0, i32 3
  %t3503 = load i64, i64* %t3502
  %t3504 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3495, i32 0, i32 4
  %t3505 = load i64, i64* %t3504
  %t3506 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3495, i32 0, i32 5
  %t3507 = load i64, i64* %t3506
  %t3508 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3509 = call i8* @star_rc_alloc(i64 48, i8* %t3508)
  %t3510 = bitcast i8* %t3509 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3511 = mul i64 %t3505, %t3477
  %t3512 = call i8* @malloc(i64 %t3511)
  %t3513 = bitcast i8* %t3512 to i8**
  %t3514 = mul i64 %t3505, %t3479
  %t3515 = call i8* @malloc(i64 %t3514)
  %t3516 = bitcast i8* %t3515 to i32*
  %t3517 = call i8* @malloc(i64 %t3505)
  %t3518 = icmp sgt i64 %t3505, 0
  br i1 %t3518, label %map_cow_copy_810, label %map_cow_after_copy_811
map_cow_copy_810:
  %t3519 = mul i64 %t3505, %t3477
  %t3520 = bitcast i8** %t3497 to i8*
  call i8* @memcpy(i8* %t3512, i8* %t3520, i64 %t3519)
  %t3521 = mul i64 %t3505, %t3479
  %t3522 = bitcast i32* %t3499 to i8*
  call i8* @memcpy(i8* %t3515, i8* %t3522, i64 %t3521)
  call i8* @memcpy(i8* %t3517, i8* %t3501, i64 %t3505)
  store i64 0, i64* %t3523
  br label %map_cow_retain_cond_812
map_cow_retain_cond_812:
  %t3524 = load i64, i64* %t3523
  %t3525 = icmp slt i64 %t3524, %t3505
  br i1 %t3525, label %map_cow_retain_body_813, label %map_cow_retain_end_816
map_cow_retain_body_813:
  %t3526 = getelementptr inbounds i8, i8* %t3517, i64 %t3524
  %t3527 = load i8, i8* %t3526
  %t3528 = icmp eq i8 %t3527, 1
  br i1 %t3528, label %map_cow_retain_occ_814, label %map_cow_retain_next_815
map_cow_retain_occ_814:
  %t3529 = getelementptr inbounds i8*, i8** %t3513, i64 %t3524
  %t3530 = load i8*, i8** %t3529
  call void @star_rc_retain(i8* %t3530)
  br label %map_cow_retain_next_815
map_cow_retain_next_815:
  %t3531 = add i64 %t3524, 1
  store i64 %t3531, i64* %t3523
  br label %map_cow_retain_cond_812
map_cow_retain_end_816:
  br label %map_cow_after_copy_811
map_cow_after_copy_811:
  %t3532 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3510, i32 0, i32 0
  store i8** %t3513, i8*** %t3532
  %t3533 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3510, i32 0, i32 1
  store i32* %t3516, i32** %t3533
  %t3534 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3510, i32 0, i32 2
  store i8* %t3517, i8** %t3534
  %t3535 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3510, i32 0, i32 3
  store i64 %t3503, i64* %t3535
  %t3536 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3510, i32 0, i32 4
  store i64 %t3505, i64* %t3536
  %t3537 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3510, i32 0, i32 5
  store i64 %t3507, i64* %t3537
  call void @star_rc_release(i8* %t3480)
  store i8* %t3509, i8** %t0
  br label %map_cow_done_808
map_cow_done_808:
  %t3538 = load i8*, i8** %t0
  %t3539 = bitcast i8* %t3538 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3540 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3539, i32 0, i32 0
  %t3541 = load i8**, i8*** %t3540
  %t3542 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3539, i32 0, i32 1
  %t3543 = load i32*, i32** %t3542
  %t3544 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3539, i32 0, i32 2
  %t3545 = load i8*, i8** %t3544
  %t3546 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3539, i32 0, i32 3
  %t3547 = load i64, i64* %t3546
  %t3548 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3539, i32 0, i32 4
  %t3549 = load i64, i64* %t3548
  %t3550 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3539, i32 0, i32 5
  %t3551 = load i64, i64* %t3550
  %t3552 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.19, i64 0, i32 2, i64 0
  %t3553 = load i64, i64* %t3546
  %t3554 = load i64, i64* %t3548
  %t3555 = load i64, i64* %t3550
  %t3556 = add i64 %t3553, %t3555
  %t3557 = add i64 %t3556, 1
  %t3558 = mul i64 %t3557, 4
  %t3559 = mul i64 %t3554, 3
  %t3560 = icmp sgt i64 %t3558, %t3559
  br i1 %t3560, label %map_insert_grow_817, label %map_insert_after_grow_818
map_insert_grow_817:
  %t3561 = getelementptr i8*, i8** null, i32 1
  %t3562 = ptrtoint i8** %t3561 to i64
  %t3563 = getelementptr i32, i32* null, i32 1
  %t3564 = ptrtoint i32* %t3563 to i64
  %t3565 = mul i64 %t3554, 2
  %t3566 = icmp sgt i64 %t3565, 0
  %t3567 = select i1 %t3566, i64 %t3565, i64 8
  %t3568 = sub i64 %t3567, 1
  %t3569 = mul i64 %t3567, %t3562
  %t3570 = call i8* @malloc(i64 %t3569)
  %t3571 = bitcast i8* %t3570 to i8**
  %t3572 = mul i64 %t3567, %t3564
  %t3573 = call i8* @malloc(i64 %t3572)
  %t3574 = bitcast i8* %t3573 to i32*
  %t3575 = call i8* @malloc(i64 %t3567)
  store i64 0, i64* %t3576
  br label %ht_fill8_cond_819
ht_fill8_cond_819:
  %t3577 = load i64, i64* %t3576
  %t3578 = icmp slt i64 %t3577, %t3567
  br i1 %t3578, label %ht_fill8_body_820, label %ht_fill8_end_821
ht_fill8_body_820:
  %t3579 = getelementptr inbounds i8, i8* %t3575, i64 %t3577
  store i8 0, i8* %t3579
  %t3580 = add i64 %t3577, 1
  store i64 %t3580, i64* %t3576
  br label %ht_fill8_cond_819
ht_fill8_end_821:
  %t3581 = load i8**, i8*** %t3540
  %t3582 = load i32*, i32** %t3542
  %t3583 = load i8*, i8** %t3544
  store i64 0, i64* %t3584
  br label %map_grow_cond_822
map_grow_cond_822:
  %t3585 = load i64, i64* %t3584
  %t3586 = icmp slt i64 %t3585, %t3554
  br i1 %t3586, label %map_grow_body_823, label %map_grow_end_826
map_grow_body_823:
  %t3587 = getelementptr inbounds i8, i8* %t3583, i64 %t3585
  %t3588 = load i8, i8* %t3587
  %t3589 = icmp eq i8 %t3588, 1
  br i1 %t3589, label %map_grow_occ_824, label %map_grow_next_825
map_grow_occ_824:
  %t3590 = getelementptr inbounds i8*, i8** %t3581, i64 %t3585
  %t3591 = load i8*, i8** %t3590
  %t3592 = getelementptr inbounds i32, i32* %t3582, i64 %t3585
  %t3593 = load i32, i32* %t3592
  %t3594 = call i64 @hash_str(i8* %t3591)
  %t3595 = and i64 %t3594, %t3568
  store i64 0, i64* %t3596
  store i64 %t3595, i64* %t3597
  br label %ht_fe_cond_827
ht_fe_cond_827:
  %t3598 = load i64, i64* %t3596
  %t3599 = icmp slt i64 %t3598, %t3567
  br i1 %t3599, label %ht_fe_body_828, label %ht_fe_end_830
ht_fe_body_828:
  %t3600 = load i64, i64* %t3597
  %t3601 = getelementptr inbounds i8, i8* %t3575, i64 %t3600
  %t3602 = load i8, i8* %t3601
  %t3603 = icmp eq i8 %t3602, 0
  br i1 %t3603, label %ht_fe_end_830, label %ht_fe_next_829
ht_fe_next_829:
  %t3604 = add i64 %t3600, 1
  %t3605 = and i64 %t3604, %t3568
  store i64 %t3605, i64* %t3597
  %t3606 = add i64 %t3598, 1
  store i64 %t3606, i64* %t3596
  br label %ht_fe_cond_827
ht_fe_end_830:
  %t3607 = load i64, i64* %t3597
  %t3608 = getelementptr inbounds i8, i8* %t3575, i64 %t3607
  store i8 1, i8* %t3608
  %t3609 = getelementptr inbounds i8*, i8** %t3571, i64 %t3607
  store i8* %t3591, i8** %t3609
  %t3610 = getelementptr inbounds i32, i32* %t3574, i64 %t3607
  store i32 %t3593, i32* %t3610
  br label %map_grow_next_825
map_grow_next_825:
  %t3611 = add i64 %t3585, 1
  store i64 %t3611, i64* %t3584
  br label %map_grow_cond_822
map_grow_end_826:
  %t3612 = bitcast i8** %t3581 to i8*
  call void @free(i8* %t3612)
  %t3613 = bitcast i32* %t3582 to i8*
  call void @free(i8* %t3613)
  call void @free(i8* %t3583)
  store i8** %t3571, i8*** %t3540
  store i32* %t3574, i32** %t3542
  store i8* %t3575, i8** %t3544
  store i64 %t3567, i64* %t3548
  store i64 0, i64* %t3550
  br label %map_insert_after_grow_818
map_insert_after_grow_818:
  %t3614 = load i8**, i8*** %t3540
  %t3615 = load i32*, i32** %t3542
  %t3616 = load i8*, i8** %t3544
  %t3617 = load i64, i64* %t3548
  %t3618 = sub i64 %t3617, 1
  %t3619 = call i64 @hash_str(i8* %t3552)
  %t3620 = and i64 %t3619, %t3618
  store i64 0, i64* %t3621
  store i64 %t3620, i64* %t3622
  store i1 false, i1* %t3623
  store i64 -1, i64* %t3624
  store i64 -1, i64* %t3625
  store i1 false, i1* %t3626
  br label %ht_probe_cond_831
ht_probe_cond_831:
  %t3627 = load i64, i64* %t3621
  %t3628 = icmp slt i64 %t3627, %t3617
  br i1 %t3628, label %ht_probe_body_832, label %ht_probe_end_842
ht_probe_body_832:
  %t3629 = load i64, i64* %t3622
  %t3630 = getelementptr inbounds i8, i8* %t3616, i64 %t3629
  %t3631 = load i8, i8* %t3630
  %t3632 = icmp eq i8 %t3631, 0
  br i1 %t3632, label %ht_probe_on_empty_834, label %ht_probe_check_occ_833
ht_probe_check_occ_833:
  %t3633 = icmp eq i8 %t3631, 1
  br i1 %t3633, label %ht_probe_on_occ_837, label %ht_probe_on_tomb_839
ht_probe_on_empty_834:
  %t3634 = load i1, i1* %t3626
  br i1 %t3634, label %ht_probe_after_islot_empty_836, label %ht_probe_set_islot_empty_835
ht_probe_set_islot_empty_835:
  store i64 %t3629, i64* %t3625
  store i1 true, i1* %t3626
  br label %ht_probe_after_islot_empty_836
ht_probe_after_islot_empty_836:
  br label %ht_probe_end_842
ht_probe_on_occ_837:
  %t3635 = getelementptr inbounds i8*, i8** %t3614, i64 %t3629
  %t3636 = load i8*, i8** %t3635
  %t3637 = call i1 @eq_str(i8* %t3636, i8* %t3552)
  br i1 %t3637, label %ht_probe_on_match_838, label %ht_probe_next_841
ht_probe_on_match_838:
  store i1 true, i1* %t3623
  store i64 %t3629, i64* %t3624
  br label %ht_probe_end_842
ht_probe_on_tomb_839:
  %t3638 = load i1, i1* %t3626
  br i1 %t3638, label %ht_probe_next_841, label %ht_probe_set_islot_tomb_840
ht_probe_set_islot_tomb_840:
  store i64 %t3629, i64* %t3625
  store i1 true, i1* %t3626
  br label %ht_probe_next_841
ht_probe_next_841:
  %t3639 = add i64 %t3629, 1
  %t3640 = and i64 %t3639, %t3618
  store i64 %t3640, i64* %t3622
  %t3641 = add i64 %t3627, 1
  store i64 %t3641, i64* %t3621
  br label %ht_probe_cond_831
ht_probe_end_842:
  %t3642 = load i1, i1* %t3623
  %t3643 = load i64, i64* %t3624
  %t3644 = load i64, i64* %t3625
  br i1 %t3642, label %map_insert_overwrite_843, label %map_insert_new_844
map_insert_overwrite_843:
  store i8* %t3552, i8** %t3645
  %t3646 = load i8*, i8** %t3645
  call void @star_rc_release(i8* %t3646)
  %t3647 = getelementptr inbounds i32, i32* %t3615, i64 %t3643
  store i32 22, i32* %t3647
  br label %map_insert_after_845
map_insert_new_844:
  %t3648 = getelementptr inbounds i8, i8* %t3616, i64 %t3644
  %t3649 = load i8, i8* %t3648
  %t3650 = icmp eq i8 %t3649, 2
  br i1 %t3650, label %map_insert_dec_tomb_846, label %map_insert_store_847
map_insert_dec_tomb_846:
  %t3651 = load i64, i64* %t3550
  %t3652 = sub i64 %t3651, 1
  store i64 %t3652, i64* %t3550
  br label %map_insert_store_847
map_insert_store_847:
  store i8 1, i8* %t3648
  %t3653 = getelementptr inbounds i8*, i8** %t3614, i64 %t3644
  store i8* %t3552, i8** %t3653
  %t3654 = getelementptr inbounds i32, i32* %t3615, i64 %t3644
  store i32 22, i32* %t3654
  %t3655 = load i64, i64* %t3546
  %t3656 = add i64 %t3655, 1
  store i64 %t3656, i64* %t3546
  br label %map_insert_after_845
map_insert_after_845:
  %t3657 = getelementptr i8*, i8** null, i32 1
  %t3658 = ptrtoint i8** %t3657 to i64
  %t3659 = getelementptr i32, i32* null, i32 1
  %t3660 = ptrtoint i32* %t3659 to i64
  %t3661 = load i8*, i8** %t0
  %t3662 = icmp eq i8* %t3661, null
  br i1 %t3662, label %map_cow_alloc_848, label %map_cow_check_849
map_cow_alloc_848:
  %t3663 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3664 = call i8* @star_rc_alloc(i64 48, i8* %t3663)
  %t3665 = bitcast i8* %t3664 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3666 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3665, i32 0, i32 0
  store i8** null, i8*** %t3666
  %t3667 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3665, i32 0, i32 1
  store i32* null, i32** %t3667
  %t3668 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3665, i32 0, i32 2
  store i8* null, i8** %t3668
  %t3669 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3665, i32 0, i32 3
  store i64 0, i64* %t3669
  %t3670 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3665, i32 0, i32 4
  store i64 0, i64* %t3670
  %t3671 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3665, i32 0, i32 5
  store i64 0, i64* %t3671
  store i8* %t3664, i8** %t0
  br label %map_cow_done_850
map_cow_check_849:
  %t3672 = getelementptr inbounds i8, i8* %t3661, i64 -16
  %t3673 = bitcast i8* %t3672 to i64*
  %t3674 = load atomic i64, i64* %t3673 seq_cst, align 8
  %t3675 = icmp eq i64 %t3674, 1
  br i1 %t3675, label %map_cow_done_850, label %map_cow_clone_851
map_cow_clone_851:
  %t3676 = bitcast i8* %t3661 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3677 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3676, i32 0, i32 0
  %t3678 = load i8**, i8*** %t3677
  %t3679 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3676, i32 0, i32 1
  %t3680 = load i32*, i32** %t3679
  %t3681 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3676, i32 0, i32 2
  %t3682 = load i8*, i8** %t3681
  %t3683 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3676, i32 0, i32 3
  %t3684 = load i64, i64* %t3683
  %t3685 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3676, i32 0, i32 4
  %t3686 = load i64, i64* %t3685
  %t3687 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3676, i32 0, i32 5
  %t3688 = load i64, i64* %t3687
  %t3689 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3690 = call i8* @star_rc_alloc(i64 48, i8* %t3689)
  %t3691 = bitcast i8* %t3690 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3692 = mul i64 %t3686, %t3658
  %t3693 = call i8* @malloc(i64 %t3692)
  %t3694 = bitcast i8* %t3693 to i8**
  %t3695 = mul i64 %t3686, %t3660
  %t3696 = call i8* @malloc(i64 %t3695)
  %t3697 = bitcast i8* %t3696 to i32*
  %t3698 = call i8* @malloc(i64 %t3686)
  %t3699 = icmp sgt i64 %t3686, 0
  br i1 %t3699, label %map_cow_copy_852, label %map_cow_after_copy_853
map_cow_copy_852:
  %t3700 = mul i64 %t3686, %t3658
  %t3701 = bitcast i8** %t3678 to i8*
  call i8* @memcpy(i8* %t3693, i8* %t3701, i64 %t3700)
  %t3702 = mul i64 %t3686, %t3660
  %t3703 = bitcast i32* %t3680 to i8*
  call i8* @memcpy(i8* %t3696, i8* %t3703, i64 %t3702)
  call i8* @memcpy(i8* %t3698, i8* %t3682, i64 %t3686)
  store i64 0, i64* %t3704
  br label %map_cow_retain_cond_854
map_cow_retain_cond_854:
  %t3705 = load i64, i64* %t3704
  %t3706 = icmp slt i64 %t3705, %t3686
  br i1 %t3706, label %map_cow_retain_body_855, label %map_cow_retain_end_858
map_cow_retain_body_855:
  %t3707 = getelementptr inbounds i8, i8* %t3698, i64 %t3705
  %t3708 = load i8, i8* %t3707
  %t3709 = icmp eq i8 %t3708, 1
  br i1 %t3709, label %map_cow_retain_occ_856, label %map_cow_retain_next_857
map_cow_retain_occ_856:
  %t3710 = getelementptr inbounds i8*, i8** %t3694, i64 %t3705
  %t3711 = load i8*, i8** %t3710
  call void @star_rc_retain(i8* %t3711)
  br label %map_cow_retain_next_857
map_cow_retain_next_857:
  %t3712 = add i64 %t3705, 1
  store i64 %t3712, i64* %t3704
  br label %map_cow_retain_cond_854
map_cow_retain_end_858:
  br label %map_cow_after_copy_853
map_cow_after_copy_853:
  %t3713 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3691, i32 0, i32 0
  store i8** %t3694, i8*** %t3713
  %t3714 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3691, i32 0, i32 1
  store i32* %t3697, i32** %t3714
  %t3715 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3691, i32 0, i32 2
  store i8* %t3698, i8** %t3715
  %t3716 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3691, i32 0, i32 3
  store i64 %t3684, i64* %t3716
  %t3717 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3691, i32 0, i32 4
  store i64 %t3686, i64* %t3717
  %t3718 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3691, i32 0, i32 5
  store i64 %t3688, i64* %t3718
  call void @star_rc_release(i8* %t3661)
  store i8* %t3690, i8** %t0
  br label %map_cow_done_850
map_cow_done_850:
  %t3719 = load i8*, i8** %t0
  %t3720 = bitcast i8* %t3719 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3721 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3720, i32 0, i32 0
  %t3722 = load i8**, i8*** %t3721
  %t3723 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3720, i32 0, i32 1
  %t3724 = load i32*, i32** %t3723
  %t3725 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3720, i32 0, i32 2
  %t3726 = load i8*, i8** %t3725
  %t3727 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3720, i32 0, i32 3
  %t3728 = load i64, i64* %t3727
  %t3729 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3720, i32 0, i32 4
  %t3730 = load i64, i64* %t3729
  %t3731 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3720, i32 0, i32 5
  %t3732 = load i64, i64* %t3731
  %t3733 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t3734 = load i64, i64* %t3727
  %t3735 = load i64, i64* %t3729
  %t3736 = load i64, i64* %t3731
  %t3737 = add i64 %t3734, %t3736
  %t3738 = add i64 %t3737, 1
  %t3739 = mul i64 %t3738, 4
  %t3740 = mul i64 %t3735, 3
  %t3741 = icmp sgt i64 %t3739, %t3740
  br i1 %t3741, label %map_insert_grow_859, label %map_insert_after_grow_860
map_insert_grow_859:
  %t3742 = getelementptr i8*, i8** null, i32 1
  %t3743 = ptrtoint i8** %t3742 to i64
  %t3744 = getelementptr i32, i32* null, i32 1
  %t3745 = ptrtoint i32* %t3744 to i64
  %t3746 = mul i64 %t3735, 2
  %t3747 = icmp sgt i64 %t3746, 0
  %t3748 = select i1 %t3747, i64 %t3746, i64 8
  %t3749 = sub i64 %t3748, 1
  %t3750 = mul i64 %t3748, %t3743
  %t3751 = call i8* @malloc(i64 %t3750)
  %t3752 = bitcast i8* %t3751 to i8**
  %t3753 = mul i64 %t3748, %t3745
  %t3754 = call i8* @malloc(i64 %t3753)
  %t3755 = bitcast i8* %t3754 to i32*
  %t3756 = call i8* @malloc(i64 %t3748)
  store i64 0, i64* %t3757
  br label %ht_fill8_cond_861
ht_fill8_cond_861:
  %t3758 = load i64, i64* %t3757
  %t3759 = icmp slt i64 %t3758, %t3748
  br i1 %t3759, label %ht_fill8_body_862, label %ht_fill8_end_863
ht_fill8_body_862:
  %t3760 = getelementptr inbounds i8, i8* %t3756, i64 %t3758
  store i8 0, i8* %t3760
  %t3761 = add i64 %t3758, 1
  store i64 %t3761, i64* %t3757
  br label %ht_fill8_cond_861
ht_fill8_end_863:
  %t3762 = load i8**, i8*** %t3721
  %t3763 = load i32*, i32** %t3723
  %t3764 = load i8*, i8** %t3725
  store i64 0, i64* %t3765
  br label %map_grow_cond_864
map_grow_cond_864:
  %t3766 = load i64, i64* %t3765
  %t3767 = icmp slt i64 %t3766, %t3735
  br i1 %t3767, label %map_grow_body_865, label %map_grow_end_868
map_grow_body_865:
  %t3768 = getelementptr inbounds i8, i8* %t3764, i64 %t3766
  %t3769 = load i8, i8* %t3768
  %t3770 = icmp eq i8 %t3769, 1
  br i1 %t3770, label %map_grow_occ_866, label %map_grow_next_867
map_grow_occ_866:
  %t3771 = getelementptr inbounds i8*, i8** %t3762, i64 %t3766
  %t3772 = load i8*, i8** %t3771
  %t3773 = getelementptr inbounds i32, i32* %t3763, i64 %t3766
  %t3774 = load i32, i32* %t3773
  %t3775 = call i64 @hash_str(i8* %t3772)
  %t3776 = and i64 %t3775, %t3749
  store i64 0, i64* %t3777
  store i64 %t3776, i64* %t3778
  br label %ht_fe_cond_869
ht_fe_cond_869:
  %t3779 = load i64, i64* %t3777
  %t3780 = icmp slt i64 %t3779, %t3748
  br i1 %t3780, label %ht_fe_body_870, label %ht_fe_end_872
ht_fe_body_870:
  %t3781 = load i64, i64* %t3778
  %t3782 = getelementptr inbounds i8, i8* %t3756, i64 %t3781
  %t3783 = load i8, i8* %t3782
  %t3784 = icmp eq i8 %t3783, 0
  br i1 %t3784, label %ht_fe_end_872, label %ht_fe_next_871
ht_fe_next_871:
  %t3785 = add i64 %t3781, 1
  %t3786 = and i64 %t3785, %t3749
  store i64 %t3786, i64* %t3778
  %t3787 = add i64 %t3779, 1
  store i64 %t3787, i64* %t3777
  br label %ht_fe_cond_869
ht_fe_end_872:
  %t3788 = load i64, i64* %t3778
  %t3789 = getelementptr inbounds i8, i8* %t3756, i64 %t3788
  store i8 1, i8* %t3789
  %t3790 = getelementptr inbounds i8*, i8** %t3752, i64 %t3788
  store i8* %t3772, i8** %t3790
  %t3791 = getelementptr inbounds i32, i32* %t3755, i64 %t3788
  store i32 %t3774, i32* %t3791
  br label %map_grow_next_867
map_grow_next_867:
  %t3792 = add i64 %t3766, 1
  store i64 %t3792, i64* %t3765
  br label %map_grow_cond_864
map_grow_end_868:
  %t3793 = bitcast i8** %t3762 to i8*
  call void @free(i8* %t3793)
  %t3794 = bitcast i32* %t3763 to i8*
  call void @free(i8* %t3794)
  call void @free(i8* %t3764)
  store i8** %t3752, i8*** %t3721
  store i32* %t3755, i32** %t3723
  store i8* %t3756, i8** %t3725
  store i64 %t3748, i64* %t3729
  store i64 0, i64* %t3731
  br label %map_insert_after_grow_860
map_insert_after_grow_860:
  %t3795 = load i8**, i8*** %t3721
  %t3796 = load i32*, i32** %t3723
  %t3797 = load i8*, i8** %t3725
  %t3798 = load i64, i64* %t3729
  %t3799 = sub i64 %t3798, 1
  %t3800 = call i64 @hash_str(i8* %t3733)
  %t3801 = and i64 %t3800, %t3799
  store i64 0, i64* %t3802
  store i64 %t3801, i64* %t3803
  store i1 false, i1* %t3804
  store i64 -1, i64* %t3805
  store i64 -1, i64* %t3806
  store i1 false, i1* %t3807
  br label %ht_probe_cond_873
ht_probe_cond_873:
  %t3808 = load i64, i64* %t3802
  %t3809 = icmp slt i64 %t3808, %t3798
  br i1 %t3809, label %ht_probe_body_874, label %ht_probe_end_884
ht_probe_body_874:
  %t3810 = load i64, i64* %t3803
  %t3811 = getelementptr inbounds i8, i8* %t3797, i64 %t3810
  %t3812 = load i8, i8* %t3811
  %t3813 = icmp eq i8 %t3812, 0
  br i1 %t3813, label %ht_probe_on_empty_876, label %ht_probe_check_occ_875
ht_probe_check_occ_875:
  %t3814 = icmp eq i8 %t3812, 1
  br i1 %t3814, label %ht_probe_on_occ_879, label %ht_probe_on_tomb_881
ht_probe_on_empty_876:
  %t3815 = load i1, i1* %t3807
  br i1 %t3815, label %ht_probe_after_islot_empty_878, label %ht_probe_set_islot_empty_877
ht_probe_set_islot_empty_877:
  store i64 %t3810, i64* %t3806
  store i1 true, i1* %t3807
  br label %ht_probe_after_islot_empty_878
ht_probe_after_islot_empty_878:
  br label %ht_probe_end_884
ht_probe_on_occ_879:
  %t3816 = getelementptr inbounds i8*, i8** %t3795, i64 %t3810
  %t3817 = load i8*, i8** %t3816
  %t3818 = call i1 @eq_str(i8* %t3817, i8* %t3733)
  br i1 %t3818, label %ht_probe_on_match_880, label %ht_probe_next_883
ht_probe_on_match_880:
  store i1 true, i1* %t3804
  store i64 %t3810, i64* %t3805
  br label %ht_probe_end_884
ht_probe_on_tomb_881:
  %t3819 = load i1, i1* %t3807
  br i1 %t3819, label %ht_probe_next_883, label %ht_probe_set_islot_tomb_882
ht_probe_set_islot_tomb_882:
  store i64 %t3810, i64* %t3806
  store i1 true, i1* %t3807
  br label %ht_probe_next_883
ht_probe_next_883:
  %t3820 = add i64 %t3810, 1
  %t3821 = and i64 %t3820, %t3799
  store i64 %t3821, i64* %t3803
  %t3822 = add i64 %t3808, 1
  store i64 %t3822, i64* %t3802
  br label %ht_probe_cond_873
ht_probe_end_884:
  %t3823 = load i1, i1* %t3804
  %t3824 = load i64, i64* %t3805
  %t3825 = load i64, i64* %t3806
  br i1 %t3823, label %map_insert_overwrite_885, label %map_insert_new_886
map_insert_overwrite_885:
  store i8* %t3733, i8** %t3826
  %t3827 = load i8*, i8** %t3826
  call void @star_rc_release(i8* %t3827)
  %t3828 = getelementptr inbounds i32, i32* %t3796, i64 %t3824
  store i32 23, i32* %t3828
  br label %map_insert_after_887
map_insert_new_886:
  %t3829 = getelementptr inbounds i8, i8* %t3797, i64 %t3825
  %t3830 = load i8, i8* %t3829
  %t3831 = icmp eq i8 %t3830, 2
  br i1 %t3831, label %map_insert_dec_tomb_888, label %map_insert_store_889
map_insert_dec_tomb_888:
  %t3832 = load i64, i64* %t3731
  %t3833 = sub i64 %t3832, 1
  store i64 %t3833, i64* %t3731
  br label %map_insert_store_889
map_insert_store_889:
  store i8 1, i8* %t3829
  %t3834 = getelementptr inbounds i8*, i8** %t3795, i64 %t3825
  store i8* %t3733, i8** %t3834
  %t3835 = getelementptr inbounds i32, i32* %t3796, i64 %t3825
  store i32 23, i32* %t3835
  %t3836 = load i64, i64* %t3727
  %t3837 = add i64 %t3836, 1
  store i64 %t3837, i64* %t3727
  br label %map_insert_after_887
map_insert_after_887:
  %t3838 = getelementptr i8*, i8** null, i32 1
  %t3839 = ptrtoint i8** %t3838 to i64
  %t3840 = getelementptr i32, i32* null, i32 1
  %t3841 = ptrtoint i32* %t3840 to i64
  %t3842 = load i8*, i8** %t0
  %t3843 = icmp eq i8* %t3842, null
  br i1 %t3843, label %map_cow_alloc_890, label %map_cow_check_891
map_cow_alloc_890:
  %t3844 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3845 = call i8* @star_rc_alloc(i64 48, i8* %t3844)
  %t3846 = bitcast i8* %t3845 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3847 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3846, i32 0, i32 0
  store i8** null, i8*** %t3847
  %t3848 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3846, i32 0, i32 1
  store i32* null, i32** %t3848
  %t3849 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3846, i32 0, i32 2
  store i8* null, i8** %t3849
  %t3850 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3846, i32 0, i32 3
  store i64 0, i64* %t3850
  %t3851 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3846, i32 0, i32 4
  store i64 0, i64* %t3851
  %t3852 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3846, i32 0, i32 5
  store i64 0, i64* %t3852
  store i8* %t3845, i8** %t0
  br label %map_cow_done_892
map_cow_check_891:
  %t3853 = getelementptr inbounds i8, i8* %t3842, i64 -16
  %t3854 = bitcast i8* %t3853 to i64*
  %t3855 = load atomic i64, i64* %t3854 seq_cst, align 8
  %t3856 = icmp eq i64 %t3855, 1
  br i1 %t3856, label %map_cow_done_892, label %map_cow_clone_893
map_cow_clone_893:
  %t3857 = bitcast i8* %t3842 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3858 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3857, i32 0, i32 0
  %t3859 = load i8**, i8*** %t3858
  %t3860 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3857, i32 0, i32 1
  %t3861 = load i32*, i32** %t3860
  %t3862 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3857, i32 0, i32 2
  %t3863 = load i8*, i8** %t3862
  %t3864 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3857, i32 0, i32 3
  %t3865 = load i64, i64* %t3864
  %t3866 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3857, i32 0, i32 4
  %t3867 = load i64, i64* %t3866
  %t3868 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3857, i32 0, i32 5
  %t3869 = load i64, i64* %t3868
  %t3870 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t3871 = call i8* @star_rc_alloc(i64 48, i8* %t3870)
  %t3872 = bitcast i8* %t3871 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3873 = mul i64 %t3867, %t3839
  %t3874 = call i8* @malloc(i64 %t3873)
  %t3875 = bitcast i8* %t3874 to i8**
  %t3876 = mul i64 %t3867, %t3841
  %t3877 = call i8* @malloc(i64 %t3876)
  %t3878 = bitcast i8* %t3877 to i32*
  %t3879 = call i8* @malloc(i64 %t3867)
  %t3880 = icmp sgt i64 %t3867, 0
  br i1 %t3880, label %map_cow_copy_894, label %map_cow_after_copy_895
map_cow_copy_894:
  %t3881 = mul i64 %t3867, %t3839
  %t3882 = bitcast i8** %t3859 to i8*
  call i8* @memcpy(i8* %t3874, i8* %t3882, i64 %t3881)
  %t3883 = mul i64 %t3867, %t3841
  %t3884 = bitcast i32* %t3861 to i8*
  call i8* @memcpy(i8* %t3877, i8* %t3884, i64 %t3883)
  call i8* @memcpy(i8* %t3879, i8* %t3863, i64 %t3867)
  store i64 0, i64* %t3885
  br label %map_cow_retain_cond_896
map_cow_retain_cond_896:
  %t3886 = load i64, i64* %t3885
  %t3887 = icmp slt i64 %t3886, %t3867
  br i1 %t3887, label %map_cow_retain_body_897, label %map_cow_retain_end_900
map_cow_retain_body_897:
  %t3888 = getelementptr inbounds i8, i8* %t3879, i64 %t3886
  %t3889 = load i8, i8* %t3888
  %t3890 = icmp eq i8 %t3889, 1
  br i1 %t3890, label %map_cow_retain_occ_898, label %map_cow_retain_next_899
map_cow_retain_occ_898:
  %t3891 = getelementptr inbounds i8*, i8** %t3875, i64 %t3886
  %t3892 = load i8*, i8** %t3891
  call void @star_rc_retain(i8* %t3892)
  br label %map_cow_retain_next_899
map_cow_retain_next_899:
  %t3893 = add i64 %t3886, 1
  store i64 %t3893, i64* %t3885
  br label %map_cow_retain_cond_896
map_cow_retain_end_900:
  br label %map_cow_after_copy_895
map_cow_after_copy_895:
  %t3894 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3872, i32 0, i32 0
  store i8** %t3875, i8*** %t3894
  %t3895 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3872, i32 0, i32 1
  store i32* %t3878, i32** %t3895
  %t3896 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3872, i32 0, i32 2
  store i8* %t3879, i8** %t3896
  %t3897 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3872, i32 0, i32 3
  store i64 %t3865, i64* %t3897
  %t3898 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3872, i32 0, i32 4
  store i64 %t3867, i64* %t3898
  %t3899 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3872, i32 0, i32 5
  store i64 %t3869, i64* %t3899
  call void @star_rc_release(i8* %t3842)
  store i8* %t3871, i8** %t0
  br label %map_cow_done_892
map_cow_done_892:
  %t3900 = load i8*, i8** %t0
  %t3901 = bitcast i8* %t3900 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t3902 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3901, i32 0, i32 0
  %t3903 = load i8**, i8*** %t3902
  %t3904 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3901, i32 0, i32 1
  %t3905 = load i32*, i32** %t3904
  %t3906 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3901, i32 0, i32 2
  %t3907 = load i8*, i8** %t3906
  %t3908 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3901, i32 0, i32 3
  %t3909 = load i64, i64* %t3908
  %t3910 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3901, i32 0, i32 4
  %t3911 = load i64, i64* %t3910
  %t3912 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t3901, i32 0, i32 5
  %t3913 = load i64, i64* %t3912
  %t3914 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t3915 = load i64, i64* %t3908
  %t3916 = load i64, i64* %t3910
  %t3917 = load i64, i64* %t3912
  %t3918 = add i64 %t3915, %t3917
  %t3919 = add i64 %t3918, 1
  %t3920 = mul i64 %t3919, 4
  %t3921 = mul i64 %t3916, 3
  %t3922 = icmp sgt i64 %t3920, %t3921
  br i1 %t3922, label %map_insert_grow_901, label %map_insert_after_grow_902
map_insert_grow_901:
  %t3923 = getelementptr i8*, i8** null, i32 1
  %t3924 = ptrtoint i8** %t3923 to i64
  %t3925 = getelementptr i32, i32* null, i32 1
  %t3926 = ptrtoint i32* %t3925 to i64
  %t3927 = mul i64 %t3916, 2
  %t3928 = icmp sgt i64 %t3927, 0
  %t3929 = select i1 %t3928, i64 %t3927, i64 8
  %t3930 = sub i64 %t3929, 1
  %t3931 = mul i64 %t3929, %t3924
  %t3932 = call i8* @malloc(i64 %t3931)
  %t3933 = bitcast i8* %t3932 to i8**
  %t3934 = mul i64 %t3929, %t3926
  %t3935 = call i8* @malloc(i64 %t3934)
  %t3936 = bitcast i8* %t3935 to i32*
  %t3937 = call i8* @malloc(i64 %t3929)
  store i64 0, i64* %t3938
  br label %ht_fill8_cond_903
ht_fill8_cond_903:
  %t3939 = load i64, i64* %t3938
  %t3940 = icmp slt i64 %t3939, %t3929
  br i1 %t3940, label %ht_fill8_body_904, label %ht_fill8_end_905
ht_fill8_body_904:
  %t3941 = getelementptr inbounds i8, i8* %t3937, i64 %t3939
  store i8 0, i8* %t3941
  %t3942 = add i64 %t3939, 1
  store i64 %t3942, i64* %t3938
  br label %ht_fill8_cond_903
ht_fill8_end_905:
  %t3943 = load i8**, i8*** %t3902
  %t3944 = load i32*, i32** %t3904
  %t3945 = load i8*, i8** %t3906
  store i64 0, i64* %t3946
  br label %map_grow_cond_906
map_grow_cond_906:
  %t3947 = load i64, i64* %t3946
  %t3948 = icmp slt i64 %t3947, %t3916
  br i1 %t3948, label %map_grow_body_907, label %map_grow_end_910
map_grow_body_907:
  %t3949 = getelementptr inbounds i8, i8* %t3945, i64 %t3947
  %t3950 = load i8, i8* %t3949
  %t3951 = icmp eq i8 %t3950, 1
  br i1 %t3951, label %map_grow_occ_908, label %map_grow_next_909
map_grow_occ_908:
  %t3952 = getelementptr inbounds i8*, i8** %t3943, i64 %t3947
  %t3953 = load i8*, i8** %t3952
  %t3954 = getelementptr inbounds i32, i32* %t3944, i64 %t3947
  %t3955 = load i32, i32* %t3954
  %t3956 = call i64 @hash_str(i8* %t3953)
  %t3957 = and i64 %t3956, %t3930
  store i64 0, i64* %t3958
  store i64 %t3957, i64* %t3959
  br label %ht_fe_cond_911
ht_fe_cond_911:
  %t3960 = load i64, i64* %t3958
  %t3961 = icmp slt i64 %t3960, %t3929
  br i1 %t3961, label %ht_fe_body_912, label %ht_fe_end_914
ht_fe_body_912:
  %t3962 = load i64, i64* %t3959
  %t3963 = getelementptr inbounds i8, i8* %t3937, i64 %t3962
  %t3964 = load i8, i8* %t3963
  %t3965 = icmp eq i8 %t3964, 0
  br i1 %t3965, label %ht_fe_end_914, label %ht_fe_next_913
ht_fe_next_913:
  %t3966 = add i64 %t3962, 1
  %t3967 = and i64 %t3966, %t3930
  store i64 %t3967, i64* %t3959
  %t3968 = add i64 %t3960, 1
  store i64 %t3968, i64* %t3958
  br label %ht_fe_cond_911
ht_fe_end_914:
  %t3969 = load i64, i64* %t3959
  %t3970 = getelementptr inbounds i8, i8* %t3937, i64 %t3969
  store i8 1, i8* %t3970
  %t3971 = getelementptr inbounds i8*, i8** %t3933, i64 %t3969
  store i8* %t3953, i8** %t3971
  %t3972 = getelementptr inbounds i32, i32* %t3936, i64 %t3969
  store i32 %t3955, i32* %t3972
  br label %map_grow_next_909
map_grow_next_909:
  %t3973 = add i64 %t3947, 1
  store i64 %t3973, i64* %t3946
  br label %map_grow_cond_906
map_grow_end_910:
  %t3974 = bitcast i8** %t3943 to i8*
  call void @free(i8* %t3974)
  %t3975 = bitcast i32* %t3944 to i8*
  call void @free(i8* %t3975)
  call void @free(i8* %t3945)
  store i8** %t3933, i8*** %t3902
  store i32* %t3936, i32** %t3904
  store i8* %t3937, i8** %t3906
  store i64 %t3929, i64* %t3910
  store i64 0, i64* %t3912
  br label %map_insert_after_grow_902
map_insert_after_grow_902:
  %t3976 = load i8**, i8*** %t3902
  %t3977 = load i32*, i32** %t3904
  %t3978 = load i8*, i8** %t3906
  %t3979 = load i64, i64* %t3910
  %t3980 = sub i64 %t3979, 1
  %t3981 = call i64 @hash_str(i8* %t3914)
  %t3982 = and i64 %t3981, %t3980
  store i64 0, i64* %t3983
  store i64 %t3982, i64* %t3984
  store i1 false, i1* %t3985
  store i64 -1, i64* %t3986
  store i64 -1, i64* %t3987
  store i1 false, i1* %t3988
  br label %ht_probe_cond_915
ht_probe_cond_915:
  %t3989 = load i64, i64* %t3983
  %t3990 = icmp slt i64 %t3989, %t3979
  br i1 %t3990, label %ht_probe_body_916, label %ht_probe_end_926
ht_probe_body_916:
  %t3991 = load i64, i64* %t3984
  %t3992 = getelementptr inbounds i8, i8* %t3978, i64 %t3991
  %t3993 = load i8, i8* %t3992
  %t3994 = icmp eq i8 %t3993, 0
  br i1 %t3994, label %ht_probe_on_empty_918, label %ht_probe_check_occ_917
ht_probe_check_occ_917:
  %t3995 = icmp eq i8 %t3993, 1
  br i1 %t3995, label %ht_probe_on_occ_921, label %ht_probe_on_tomb_923
ht_probe_on_empty_918:
  %t3996 = load i1, i1* %t3988
  br i1 %t3996, label %ht_probe_after_islot_empty_920, label %ht_probe_set_islot_empty_919
ht_probe_set_islot_empty_919:
  store i64 %t3991, i64* %t3987
  store i1 true, i1* %t3988
  br label %ht_probe_after_islot_empty_920
ht_probe_after_islot_empty_920:
  br label %ht_probe_end_926
ht_probe_on_occ_921:
  %t3997 = getelementptr inbounds i8*, i8** %t3976, i64 %t3991
  %t3998 = load i8*, i8** %t3997
  %t3999 = call i1 @eq_str(i8* %t3998, i8* %t3914)
  br i1 %t3999, label %ht_probe_on_match_922, label %ht_probe_next_925
ht_probe_on_match_922:
  store i1 true, i1* %t3985
  store i64 %t3991, i64* %t3986
  br label %ht_probe_end_926
ht_probe_on_tomb_923:
  %t4000 = load i1, i1* %t3988
  br i1 %t4000, label %ht_probe_next_925, label %ht_probe_set_islot_tomb_924
ht_probe_set_islot_tomb_924:
  store i64 %t3991, i64* %t3987
  store i1 true, i1* %t3988
  br label %ht_probe_next_925
ht_probe_next_925:
  %t4001 = add i64 %t3991, 1
  %t4002 = and i64 %t4001, %t3980
  store i64 %t4002, i64* %t3984
  %t4003 = add i64 %t3989, 1
  store i64 %t4003, i64* %t3983
  br label %ht_probe_cond_915
ht_probe_end_926:
  %t4004 = load i1, i1* %t3985
  %t4005 = load i64, i64* %t3986
  %t4006 = load i64, i64* %t3987
  br i1 %t4004, label %map_insert_overwrite_927, label %map_insert_new_928
map_insert_overwrite_927:
  store i8* %t3914, i8** %t4007
  %t4008 = load i8*, i8** %t4007
  call void @star_rc_release(i8* %t4008)
  %t4009 = getelementptr inbounds i32, i32* %t3977, i64 %t4005
  store i32 24, i32* %t4009
  br label %map_insert_after_929
map_insert_new_928:
  %t4010 = getelementptr inbounds i8, i8* %t3978, i64 %t4006
  %t4011 = load i8, i8* %t4010
  %t4012 = icmp eq i8 %t4011, 2
  br i1 %t4012, label %map_insert_dec_tomb_930, label %map_insert_store_931
map_insert_dec_tomb_930:
  %t4013 = load i64, i64* %t3912
  %t4014 = sub i64 %t4013, 1
  store i64 %t4014, i64* %t3912
  br label %map_insert_store_931
map_insert_store_931:
  store i8 1, i8* %t4010
  %t4015 = getelementptr inbounds i8*, i8** %t3976, i64 %t4006
  store i8* %t3914, i8** %t4015
  %t4016 = getelementptr inbounds i32, i32* %t3977, i64 %t4006
  store i32 24, i32* %t4016
  %t4017 = load i64, i64* %t3908
  %t4018 = add i64 %t4017, 1
  store i64 %t4018, i64* %t3908
  br label %map_insert_after_929
map_insert_after_929:
  %t4019 = getelementptr i8*, i8** null, i32 1
  %t4020 = ptrtoint i8** %t4019 to i64
  %t4021 = getelementptr i32, i32* null, i32 1
  %t4022 = ptrtoint i32* %t4021 to i64
  %t4023 = load i8*, i8** %t0
  %t4024 = icmp eq i8* %t4023, null
  br i1 %t4024, label %map_cow_alloc_932, label %map_cow_check_933
map_cow_alloc_932:
  %t4025 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4026 = call i8* @star_rc_alloc(i64 48, i8* %t4025)
  %t4027 = bitcast i8* %t4026 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4028 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4027, i32 0, i32 0
  store i8** null, i8*** %t4028
  %t4029 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4027, i32 0, i32 1
  store i32* null, i32** %t4029
  %t4030 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4027, i32 0, i32 2
  store i8* null, i8** %t4030
  %t4031 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4027, i32 0, i32 3
  store i64 0, i64* %t4031
  %t4032 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4027, i32 0, i32 4
  store i64 0, i64* %t4032
  %t4033 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4027, i32 0, i32 5
  store i64 0, i64* %t4033
  store i8* %t4026, i8** %t0
  br label %map_cow_done_934
map_cow_check_933:
  %t4034 = getelementptr inbounds i8, i8* %t4023, i64 -16
  %t4035 = bitcast i8* %t4034 to i64*
  %t4036 = load atomic i64, i64* %t4035 seq_cst, align 8
  %t4037 = icmp eq i64 %t4036, 1
  br i1 %t4037, label %map_cow_done_934, label %map_cow_clone_935
map_cow_clone_935:
  %t4038 = bitcast i8* %t4023 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4039 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4038, i32 0, i32 0
  %t4040 = load i8**, i8*** %t4039
  %t4041 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4038, i32 0, i32 1
  %t4042 = load i32*, i32** %t4041
  %t4043 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4038, i32 0, i32 2
  %t4044 = load i8*, i8** %t4043
  %t4045 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4038, i32 0, i32 3
  %t4046 = load i64, i64* %t4045
  %t4047 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4038, i32 0, i32 4
  %t4048 = load i64, i64* %t4047
  %t4049 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4038, i32 0, i32 5
  %t4050 = load i64, i64* %t4049
  %t4051 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4052 = call i8* @star_rc_alloc(i64 48, i8* %t4051)
  %t4053 = bitcast i8* %t4052 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4054 = mul i64 %t4048, %t4020
  %t4055 = call i8* @malloc(i64 %t4054)
  %t4056 = bitcast i8* %t4055 to i8**
  %t4057 = mul i64 %t4048, %t4022
  %t4058 = call i8* @malloc(i64 %t4057)
  %t4059 = bitcast i8* %t4058 to i32*
  %t4060 = call i8* @malloc(i64 %t4048)
  %t4061 = icmp sgt i64 %t4048, 0
  br i1 %t4061, label %map_cow_copy_936, label %map_cow_after_copy_937
map_cow_copy_936:
  %t4062 = mul i64 %t4048, %t4020
  %t4063 = bitcast i8** %t4040 to i8*
  call i8* @memcpy(i8* %t4055, i8* %t4063, i64 %t4062)
  %t4064 = mul i64 %t4048, %t4022
  %t4065 = bitcast i32* %t4042 to i8*
  call i8* @memcpy(i8* %t4058, i8* %t4065, i64 %t4064)
  call i8* @memcpy(i8* %t4060, i8* %t4044, i64 %t4048)
  store i64 0, i64* %t4066
  br label %map_cow_retain_cond_938
map_cow_retain_cond_938:
  %t4067 = load i64, i64* %t4066
  %t4068 = icmp slt i64 %t4067, %t4048
  br i1 %t4068, label %map_cow_retain_body_939, label %map_cow_retain_end_942
map_cow_retain_body_939:
  %t4069 = getelementptr inbounds i8, i8* %t4060, i64 %t4067
  %t4070 = load i8, i8* %t4069
  %t4071 = icmp eq i8 %t4070, 1
  br i1 %t4071, label %map_cow_retain_occ_940, label %map_cow_retain_next_941
map_cow_retain_occ_940:
  %t4072 = getelementptr inbounds i8*, i8** %t4056, i64 %t4067
  %t4073 = load i8*, i8** %t4072
  call void @star_rc_retain(i8* %t4073)
  br label %map_cow_retain_next_941
map_cow_retain_next_941:
  %t4074 = add i64 %t4067, 1
  store i64 %t4074, i64* %t4066
  br label %map_cow_retain_cond_938
map_cow_retain_end_942:
  br label %map_cow_after_copy_937
map_cow_after_copy_937:
  %t4075 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4053, i32 0, i32 0
  store i8** %t4056, i8*** %t4075
  %t4076 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4053, i32 0, i32 1
  store i32* %t4059, i32** %t4076
  %t4077 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4053, i32 0, i32 2
  store i8* %t4060, i8** %t4077
  %t4078 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4053, i32 0, i32 3
  store i64 %t4046, i64* %t4078
  %t4079 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4053, i32 0, i32 4
  store i64 %t4048, i64* %t4079
  %t4080 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4053, i32 0, i32 5
  store i64 %t4050, i64* %t4080
  call void @star_rc_release(i8* %t4023)
  store i8* %t4052, i8** %t0
  br label %map_cow_done_934
map_cow_done_934:
  %t4081 = load i8*, i8** %t0
  %t4082 = bitcast i8* %t4081 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4083 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4082, i32 0, i32 0
  %t4084 = load i8**, i8*** %t4083
  %t4085 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4082, i32 0, i32 1
  %t4086 = load i32*, i32** %t4085
  %t4087 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4082, i32 0, i32 2
  %t4088 = load i8*, i8** %t4087
  %t4089 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4082, i32 0, i32 3
  %t4090 = load i64, i64* %t4089
  %t4091 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4082, i32 0, i32 4
  %t4092 = load i64, i64* %t4091
  %t4093 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4082, i32 0, i32 5
  %t4094 = load i64, i64* %t4093
  %t4095 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.22, i64 0, i32 2, i64 0
  %t4096 = load i64, i64* %t4089
  %t4097 = load i64, i64* %t4091
  %t4098 = load i64, i64* %t4093
  %t4099 = add i64 %t4096, %t4098
  %t4100 = add i64 %t4099, 1
  %t4101 = mul i64 %t4100, 4
  %t4102 = mul i64 %t4097, 3
  %t4103 = icmp sgt i64 %t4101, %t4102
  br i1 %t4103, label %map_insert_grow_943, label %map_insert_after_grow_944
map_insert_grow_943:
  %t4104 = getelementptr i8*, i8** null, i32 1
  %t4105 = ptrtoint i8** %t4104 to i64
  %t4106 = getelementptr i32, i32* null, i32 1
  %t4107 = ptrtoint i32* %t4106 to i64
  %t4108 = mul i64 %t4097, 2
  %t4109 = icmp sgt i64 %t4108, 0
  %t4110 = select i1 %t4109, i64 %t4108, i64 8
  %t4111 = sub i64 %t4110, 1
  %t4112 = mul i64 %t4110, %t4105
  %t4113 = call i8* @malloc(i64 %t4112)
  %t4114 = bitcast i8* %t4113 to i8**
  %t4115 = mul i64 %t4110, %t4107
  %t4116 = call i8* @malloc(i64 %t4115)
  %t4117 = bitcast i8* %t4116 to i32*
  %t4118 = call i8* @malloc(i64 %t4110)
  store i64 0, i64* %t4119
  br label %ht_fill8_cond_945
ht_fill8_cond_945:
  %t4120 = load i64, i64* %t4119
  %t4121 = icmp slt i64 %t4120, %t4110
  br i1 %t4121, label %ht_fill8_body_946, label %ht_fill8_end_947
ht_fill8_body_946:
  %t4122 = getelementptr inbounds i8, i8* %t4118, i64 %t4120
  store i8 0, i8* %t4122
  %t4123 = add i64 %t4120, 1
  store i64 %t4123, i64* %t4119
  br label %ht_fill8_cond_945
ht_fill8_end_947:
  %t4124 = load i8**, i8*** %t4083
  %t4125 = load i32*, i32** %t4085
  %t4126 = load i8*, i8** %t4087
  store i64 0, i64* %t4127
  br label %map_grow_cond_948
map_grow_cond_948:
  %t4128 = load i64, i64* %t4127
  %t4129 = icmp slt i64 %t4128, %t4097
  br i1 %t4129, label %map_grow_body_949, label %map_grow_end_952
map_grow_body_949:
  %t4130 = getelementptr inbounds i8, i8* %t4126, i64 %t4128
  %t4131 = load i8, i8* %t4130
  %t4132 = icmp eq i8 %t4131, 1
  br i1 %t4132, label %map_grow_occ_950, label %map_grow_next_951
map_grow_occ_950:
  %t4133 = getelementptr inbounds i8*, i8** %t4124, i64 %t4128
  %t4134 = load i8*, i8** %t4133
  %t4135 = getelementptr inbounds i32, i32* %t4125, i64 %t4128
  %t4136 = load i32, i32* %t4135
  %t4137 = call i64 @hash_str(i8* %t4134)
  %t4138 = and i64 %t4137, %t4111
  store i64 0, i64* %t4139
  store i64 %t4138, i64* %t4140
  br label %ht_fe_cond_953
ht_fe_cond_953:
  %t4141 = load i64, i64* %t4139
  %t4142 = icmp slt i64 %t4141, %t4110
  br i1 %t4142, label %ht_fe_body_954, label %ht_fe_end_956
ht_fe_body_954:
  %t4143 = load i64, i64* %t4140
  %t4144 = getelementptr inbounds i8, i8* %t4118, i64 %t4143
  %t4145 = load i8, i8* %t4144
  %t4146 = icmp eq i8 %t4145, 0
  br i1 %t4146, label %ht_fe_end_956, label %ht_fe_next_955
ht_fe_next_955:
  %t4147 = add i64 %t4143, 1
  %t4148 = and i64 %t4147, %t4111
  store i64 %t4148, i64* %t4140
  %t4149 = add i64 %t4141, 1
  store i64 %t4149, i64* %t4139
  br label %ht_fe_cond_953
ht_fe_end_956:
  %t4150 = load i64, i64* %t4140
  %t4151 = getelementptr inbounds i8, i8* %t4118, i64 %t4150
  store i8 1, i8* %t4151
  %t4152 = getelementptr inbounds i8*, i8** %t4114, i64 %t4150
  store i8* %t4134, i8** %t4152
  %t4153 = getelementptr inbounds i32, i32* %t4117, i64 %t4150
  store i32 %t4136, i32* %t4153
  br label %map_grow_next_951
map_grow_next_951:
  %t4154 = add i64 %t4128, 1
  store i64 %t4154, i64* %t4127
  br label %map_grow_cond_948
map_grow_end_952:
  %t4155 = bitcast i8** %t4124 to i8*
  call void @free(i8* %t4155)
  %t4156 = bitcast i32* %t4125 to i8*
  call void @free(i8* %t4156)
  call void @free(i8* %t4126)
  store i8** %t4114, i8*** %t4083
  store i32* %t4117, i32** %t4085
  store i8* %t4118, i8** %t4087
  store i64 %t4110, i64* %t4091
  store i64 0, i64* %t4093
  br label %map_insert_after_grow_944
map_insert_after_grow_944:
  %t4157 = load i8**, i8*** %t4083
  %t4158 = load i32*, i32** %t4085
  %t4159 = load i8*, i8** %t4087
  %t4160 = load i64, i64* %t4091
  %t4161 = sub i64 %t4160, 1
  %t4162 = call i64 @hash_str(i8* %t4095)
  %t4163 = and i64 %t4162, %t4161
  store i64 0, i64* %t4164
  store i64 %t4163, i64* %t4165
  store i1 false, i1* %t4166
  store i64 -1, i64* %t4167
  store i64 -1, i64* %t4168
  store i1 false, i1* %t4169
  br label %ht_probe_cond_957
ht_probe_cond_957:
  %t4170 = load i64, i64* %t4164
  %t4171 = icmp slt i64 %t4170, %t4160
  br i1 %t4171, label %ht_probe_body_958, label %ht_probe_end_968
ht_probe_body_958:
  %t4172 = load i64, i64* %t4165
  %t4173 = getelementptr inbounds i8, i8* %t4159, i64 %t4172
  %t4174 = load i8, i8* %t4173
  %t4175 = icmp eq i8 %t4174, 0
  br i1 %t4175, label %ht_probe_on_empty_960, label %ht_probe_check_occ_959
ht_probe_check_occ_959:
  %t4176 = icmp eq i8 %t4174, 1
  br i1 %t4176, label %ht_probe_on_occ_963, label %ht_probe_on_tomb_965
ht_probe_on_empty_960:
  %t4177 = load i1, i1* %t4169
  br i1 %t4177, label %ht_probe_after_islot_empty_962, label %ht_probe_set_islot_empty_961
ht_probe_set_islot_empty_961:
  store i64 %t4172, i64* %t4168
  store i1 true, i1* %t4169
  br label %ht_probe_after_islot_empty_962
ht_probe_after_islot_empty_962:
  br label %ht_probe_end_968
ht_probe_on_occ_963:
  %t4178 = getelementptr inbounds i8*, i8** %t4157, i64 %t4172
  %t4179 = load i8*, i8** %t4178
  %t4180 = call i1 @eq_str(i8* %t4179, i8* %t4095)
  br i1 %t4180, label %ht_probe_on_match_964, label %ht_probe_next_967
ht_probe_on_match_964:
  store i1 true, i1* %t4166
  store i64 %t4172, i64* %t4167
  br label %ht_probe_end_968
ht_probe_on_tomb_965:
  %t4181 = load i1, i1* %t4169
  br i1 %t4181, label %ht_probe_next_967, label %ht_probe_set_islot_tomb_966
ht_probe_set_islot_tomb_966:
  store i64 %t4172, i64* %t4168
  store i1 true, i1* %t4169
  br label %ht_probe_next_967
ht_probe_next_967:
  %t4182 = add i64 %t4172, 1
  %t4183 = and i64 %t4182, %t4161
  store i64 %t4183, i64* %t4165
  %t4184 = add i64 %t4170, 1
  store i64 %t4184, i64* %t4164
  br label %ht_probe_cond_957
ht_probe_end_968:
  %t4185 = load i1, i1* %t4166
  %t4186 = load i64, i64* %t4167
  %t4187 = load i64, i64* %t4168
  br i1 %t4185, label %map_insert_overwrite_969, label %map_insert_new_970
map_insert_overwrite_969:
  store i8* %t4095, i8** %t4188
  %t4189 = load i8*, i8** %t4188
  call void @star_rc_release(i8* %t4189)
  %t4190 = getelementptr inbounds i32, i32* %t4158, i64 %t4186
  store i32 18, i32* %t4190
  br label %map_insert_after_971
map_insert_new_970:
  %t4191 = getelementptr inbounds i8, i8* %t4159, i64 %t4187
  %t4192 = load i8, i8* %t4191
  %t4193 = icmp eq i8 %t4192, 2
  br i1 %t4193, label %map_insert_dec_tomb_972, label %map_insert_store_973
map_insert_dec_tomb_972:
  %t4194 = load i64, i64* %t4093
  %t4195 = sub i64 %t4194, 1
  store i64 %t4195, i64* %t4093
  br label %map_insert_store_973
map_insert_store_973:
  store i8 1, i8* %t4191
  %t4196 = getelementptr inbounds i8*, i8** %t4157, i64 %t4187
  store i8* %t4095, i8** %t4196
  %t4197 = getelementptr inbounds i32, i32* %t4158, i64 %t4187
  store i32 18, i32* %t4197
  %t4198 = load i64, i64* %t4089
  %t4199 = add i64 %t4198, 1
  store i64 %t4199, i64* %t4089
  br label %map_insert_after_971
map_insert_after_971:
  %t4200 = getelementptr i8*, i8** null, i32 1
  %t4201 = ptrtoint i8** %t4200 to i64
  %t4202 = getelementptr i32, i32* null, i32 1
  %t4203 = ptrtoint i32* %t4202 to i64
  %t4204 = load i8*, i8** %t0
  %t4205 = icmp eq i8* %t4204, null
  br i1 %t4205, label %map_cow_alloc_974, label %map_cow_check_975
map_cow_alloc_974:
  %t4206 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4207 = call i8* @star_rc_alloc(i64 48, i8* %t4206)
  %t4208 = bitcast i8* %t4207 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4209 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4208, i32 0, i32 0
  store i8** null, i8*** %t4209
  %t4210 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4208, i32 0, i32 1
  store i32* null, i32** %t4210
  %t4211 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4208, i32 0, i32 2
  store i8* null, i8** %t4211
  %t4212 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4208, i32 0, i32 3
  store i64 0, i64* %t4212
  %t4213 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4208, i32 0, i32 4
  store i64 0, i64* %t4213
  %t4214 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4208, i32 0, i32 5
  store i64 0, i64* %t4214
  store i8* %t4207, i8** %t0
  br label %map_cow_done_976
map_cow_check_975:
  %t4215 = getelementptr inbounds i8, i8* %t4204, i64 -16
  %t4216 = bitcast i8* %t4215 to i64*
  %t4217 = load atomic i64, i64* %t4216 seq_cst, align 8
  %t4218 = icmp eq i64 %t4217, 1
  br i1 %t4218, label %map_cow_done_976, label %map_cow_clone_977
map_cow_clone_977:
  %t4219 = bitcast i8* %t4204 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4220 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4219, i32 0, i32 0
  %t4221 = load i8**, i8*** %t4220
  %t4222 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4219, i32 0, i32 1
  %t4223 = load i32*, i32** %t4222
  %t4224 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4219, i32 0, i32 2
  %t4225 = load i8*, i8** %t4224
  %t4226 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4219, i32 0, i32 3
  %t4227 = load i64, i64* %t4226
  %t4228 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4219, i32 0, i32 4
  %t4229 = load i64, i64* %t4228
  %t4230 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4219, i32 0, i32 5
  %t4231 = load i64, i64* %t4230
  %t4232 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4233 = call i8* @star_rc_alloc(i64 48, i8* %t4232)
  %t4234 = bitcast i8* %t4233 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4235 = mul i64 %t4229, %t4201
  %t4236 = call i8* @malloc(i64 %t4235)
  %t4237 = bitcast i8* %t4236 to i8**
  %t4238 = mul i64 %t4229, %t4203
  %t4239 = call i8* @malloc(i64 %t4238)
  %t4240 = bitcast i8* %t4239 to i32*
  %t4241 = call i8* @malloc(i64 %t4229)
  %t4242 = icmp sgt i64 %t4229, 0
  br i1 %t4242, label %map_cow_copy_978, label %map_cow_after_copy_979
map_cow_copy_978:
  %t4243 = mul i64 %t4229, %t4201
  %t4244 = bitcast i8** %t4221 to i8*
  call i8* @memcpy(i8* %t4236, i8* %t4244, i64 %t4243)
  %t4245 = mul i64 %t4229, %t4203
  %t4246 = bitcast i32* %t4223 to i8*
  call i8* @memcpy(i8* %t4239, i8* %t4246, i64 %t4245)
  call i8* @memcpy(i8* %t4241, i8* %t4225, i64 %t4229)
  store i64 0, i64* %t4247
  br label %map_cow_retain_cond_980
map_cow_retain_cond_980:
  %t4248 = load i64, i64* %t4247
  %t4249 = icmp slt i64 %t4248, %t4229
  br i1 %t4249, label %map_cow_retain_body_981, label %map_cow_retain_end_984
map_cow_retain_body_981:
  %t4250 = getelementptr inbounds i8, i8* %t4241, i64 %t4248
  %t4251 = load i8, i8* %t4250
  %t4252 = icmp eq i8 %t4251, 1
  br i1 %t4252, label %map_cow_retain_occ_982, label %map_cow_retain_next_983
map_cow_retain_occ_982:
  %t4253 = getelementptr inbounds i8*, i8** %t4237, i64 %t4248
  %t4254 = load i8*, i8** %t4253
  call void @star_rc_retain(i8* %t4254)
  br label %map_cow_retain_next_983
map_cow_retain_next_983:
  %t4255 = add i64 %t4248, 1
  store i64 %t4255, i64* %t4247
  br label %map_cow_retain_cond_980
map_cow_retain_end_984:
  br label %map_cow_after_copy_979
map_cow_after_copy_979:
  %t4256 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4234, i32 0, i32 0
  store i8** %t4237, i8*** %t4256
  %t4257 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4234, i32 0, i32 1
  store i32* %t4240, i32** %t4257
  %t4258 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4234, i32 0, i32 2
  store i8* %t4241, i8** %t4258
  %t4259 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4234, i32 0, i32 3
  store i64 %t4227, i64* %t4259
  %t4260 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4234, i32 0, i32 4
  store i64 %t4229, i64* %t4260
  %t4261 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4234, i32 0, i32 5
  store i64 %t4231, i64* %t4261
  call void @star_rc_release(i8* %t4204)
  store i8* %t4233, i8** %t0
  br label %map_cow_done_976
map_cow_done_976:
  %t4262 = load i8*, i8** %t0
  %t4263 = bitcast i8* %t4262 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4264 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4263, i32 0, i32 0
  %t4265 = load i8**, i8*** %t4264
  %t4266 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4263, i32 0, i32 1
  %t4267 = load i32*, i32** %t4266
  %t4268 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4263, i32 0, i32 2
  %t4269 = load i8*, i8** %t4268
  %t4270 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4263, i32 0, i32 3
  %t4271 = load i64, i64* %t4270
  %t4272 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4263, i32 0, i32 4
  %t4273 = load i64, i64* %t4272
  %t4274 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4263, i32 0, i32 5
  %t4275 = load i64, i64* %t4274
  %t4276 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.23, i64 0, i32 2, i64 0
  %t4277 = load i64, i64* %t4270
  %t4278 = load i64, i64* %t4272
  %t4279 = load i64, i64* %t4274
  %t4280 = add i64 %t4277, %t4279
  %t4281 = add i64 %t4280, 1
  %t4282 = mul i64 %t4281, 4
  %t4283 = mul i64 %t4278, 3
  %t4284 = icmp sgt i64 %t4282, %t4283
  br i1 %t4284, label %map_insert_grow_985, label %map_insert_after_grow_986
map_insert_grow_985:
  %t4285 = getelementptr i8*, i8** null, i32 1
  %t4286 = ptrtoint i8** %t4285 to i64
  %t4287 = getelementptr i32, i32* null, i32 1
  %t4288 = ptrtoint i32* %t4287 to i64
  %t4289 = mul i64 %t4278, 2
  %t4290 = icmp sgt i64 %t4289, 0
  %t4291 = select i1 %t4290, i64 %t4289, i64 8
  %t4292 = sub i64 %t4291, 1
  %t4293 = mul i64 %t4291, %t4286
  %t4294 = call i8* @malloc(i64 %t4293)
  %t4295 = bitcast i8* %t4294 to i8**
  %t4296 = mul i64 %t4291, %t4288
  %t4297 = call i8* @malloc(i64 %t4296)
  %t4298 = bitcast i8* %t4297 to i32*
  %t4299 = call i8* @malloc(i64 %t4291)
  store i64 0, i64* %t4300
  br label %ht_fill8_cond_987
ht_fill8_cond_987:
  %t4301 = load i64, i64* %t4300
  %t4302 = icmp slt i64 %t4301, %t4291
  br i1 %t4302, label %ht_fill8_body_988, label %ht_fill8_end_989
ht_fill8_body_988:
  %t4303 = getelementptr inbounds i8, i8* %t4299, i64 %t4301
  store i8 0, i8* %t4303
  %t4304 = add i64 %t4301, 1
  store i64 %t4304, i64* %t4300
  br label %ht_fill8_cond_987
ht_fill8_end_989:
  %t4305 = load i8**, i8*** %t4264
  %t4306 = load i32*, i32** %t4266
  %t4307 = load i8*, i8** %t4268
  store i64 0, i64* %t4308
  br label %map_grow_cond_990
map_grow_cond_990:
  %t4309 = load i64, i64* %t4308
  %t4310 = icmp slt i64 %t4309, %t4278
  br i1 %t4310, label %map_grow_body_991, label %map_grow_end_994
map_grow_body_991:
  %t4311 = getelementptr inbounds i8, i8* %t4307, i64 %t4309
  %t4312 = load i8, i8* %t4311
  %t4313 = icmp eq i8 %t4312, 1
  br i1 %t4313, label %map_grow_occ_992, label %map_grow_next_993
map_grow_occ_992:
  %t4314 = getelementptr inbounds i8*, i8** %t4305, i64 %t4309
  %t4315 = load i8*, i8** %t4314
  %t4316 = getelementptr inbounds i32, i32* %t4306, i64 %t4309
  %t4317 = load i32, i32* %t4316
  %t4318 = call i64 @hash_str(i8* %t4315)
  %t4319 = and i64 %t4318, %t4292
  store i64 0, i64* %t4320
  store i64 %t4319, i64* %t4321
  br label %ht_fe_cond_995
ht_fe_cond_995:
  %t4322 = load i64, i64* %t4320
  %t4323 = icmp slt i64 %t4322, %t4291
  br i1 %t4323, label %ht_fe_body_996, label %ht_fe_end_998
ht_fe_body_996:
  %t4324 = load i64, i64* %t4321
  %t4325 = getelementptr inbounds i8, i8* %t4299, i64 %t4324
  %t4326 = load i8, i8* %t4325
  %t4327 = icmp eq i8 %t4326, 0
  br i1 %t4327, label %ht_fe_end_998, label %ht_fe_next_997
ht_fe_next_997:
  %t4328 = add i64 %t4324, 1
  %t4329 = and i64 %t4328, %t4292
  store i64 %t4329, i64* %t4321
  %t4330 = add i64 %t4322, 1
  store i64 %t4330, i64* %t4320
  br label %ht_fe_cond_995
ht_fe_end_998:
  %t4331 = load i64, i64* %t4321
  %t4332 = getelementptr inbounds i8, i8* %t4299, i64 %t4331
  store i8 1, i8* %t4332
  %t4333 = getelementptr inbounds i8*, i8** %t4295, i64 %t4331
  store i8* %t4315, i8** %t4333
  %t4334 = getelementptr inbounds i32, i32* %t4298, i64 %t4331
  store i32 %t4317, i32* %t4334
  br label %map_grow_next_993
map_grow_next_993:
  %t4335 = add i64 %t4309, 1
  store i64 %t4335, i64* %t4308
  br label %map_grow_cond_990
map_grow_end_994:
  %t4336 = bitcast i8** %t4305 to i8*
  call void @free(i8* %t4336)
  %t4337 = bitcast i32* %t4306 to i8*
  call void @free(i8* %t4337)
  call void @free(i8* %t4307)
  store i8** %t4295, i8*** %t4264
  store i32* %t4298, i32** %t4266
  store i8* %t4299, i8** %t4268
  store i64 %t4291, i64* %t4272
  store i64 0, i64* %t4274
  br label %map_insert_after_grow_986
map_insert_after_grow_986:
  %t4338 = load i8**, i8*** %t4264
  %t4339 = load i32*, i32** %t4266
  %t4340 = load i8*, i8** %t4268
  %t4341 = load i64, i64* %t4272
  %t4342 = sub i64 %t4341, 1
  %t4343 = call i64 @hash_str(i8* %t4276)
  %t4344 = and i64 %t4343, %t4342
  store i64 0, i64* %t4345
  store i64 %t4344, i64* %t4346
  store i1 false, i1* %t4347
  store i64 -1, i64* %t4348
  store i64 -1, i64* %t4349
  store i1 false, i1* %t4350
  br label %ht_probe_cond_999
ht_probe_cond_999:
  %t4351 = load i64, i64* %t4345
  %t4352 = icmp slt i64 %t4351, %t4341
  br i1 %t4352, label %ht_probe_body_1000, label %ht_probe_end_1010
ht_probe_body_1000:
  %t4353 = load i64, i64* %t4346
  %t4354 = getelementptr inbounds i8, i8* %t4340, i64 %t4353
  %t4355 = load i8, i8* %t4354
  %t4356 = icmp eq i8 %t4355, 0
  br i1 %t4356, label %ht_probe_on_empty_1002, label %ht_probe_check_occ_1001
ht_probe_check_occ_1001:
  %t4357 = icmp eq i8 %t4355, 1
  br i1 %t4357, label %ht_probe_on_occ_1005, label %ht_probe_on_tomb_1007
ht_probe_on_empty_1002:
  %t4358 = load i1, i1* %t4350
  br i1 %t4358, label %ht_probe_after_islot_empty_1004, label %ht_probe_set_islot_empty_1003
ht_probe_set_islot_empty_1003:
  store i64 %t4353, i64* %t4349
  store i1 true, i1* %t4350
  br label %ht_probe_after_islot_empty_1004
ht_probe_after_islot_empty_1004:
  br label %ht_probe_end_1010
ht_probe_on_occ_1005:
  %t4359 = getelementptr inbounds i8*, i8** %t4338, i64 %t4353
  %t4360 = load i8*, i8** %t4359
  %t4361 = call i1 @eq_str(i8* %t4360, i8* %t4276)
  br i1 %t4361, label %ht_probe_on_match_1006, label %ht_probe_next_1009
ht_probe_on_match_1006:
  store i1 true, i1* %t4347
  store i64 %t4353, i64* %t4348
  br label %ht_probe_end_1010
ht_probe_on_tomb_1007:
  %t4362 = load i1, i1* %t4350
  br i1 %t4362, label %ht_probe_next_1009, label %ht_probe_set_islot_tomb_1008
ht_probe_set_islot_tomb_1008:
  store i64 %t4353, i64* %t4349
  store i1 true, i1* %t4350
  br label %ht_probe_next_1009
ht_probe_next_1009:
  %t4363 = add i64 %t4353, 1
  %t4364 = and i64 %t4363, %t4342
  store i64 %t4364, i64* %t4346
  %t4365 = add i64 %t4351, 1
  store i64 %t4365, i64* %t4345
  br label %ht_probe_cond_999
ht_probe_end_1010:
  %t4366 = load i1, i1* %t4347
  %t4367 = load i64, i64* %t4348
  %t4368 = load i64, i64* %t4349
  br i1 %t4366, label %map_insert_overwrite_1011, label %map_insert_new_1012
map_insert_overwrite_1011:
  store i8* %t4276, i8** %t4369
  %t4370 = load i8*, i8** %t4369
  call void @star_rc_release(i8* %t4370)
  %t4371 = getelementptr inbounds i32, i32* %t4339, i64 %t4367
  store i32 19, i32* %t4371
  br label %map_insert_after_1013
map_insert_new_1012:
  %t4372 = getelementptr inbounds i8, i8* %t4340, i64 %t4368
  %t4373 = load i8, i8* %t4372
  %t4374 = icmp eq i8 %t4373, 2
  br i1 %t4374, label %map_insert_dec_tomb_1014, label %map_insert_store_1015
map_insert_dec_tomb_1014:
  %t4375 = load i64, i64* %t4274
  %t4376 = sub i64 %t4375, 1
  store i64 %t4376, i64* %t4274
  br label %map_insert_store_1015
map_insert_store_1015:
  store i8 1, i8* %t4372
  %t4377 = getelementptr inbounds i8*, i8** %t4338, i64 %t4368
  store i8* %t4276, i8** %t4377
  %t4378 = getelementptr inbounds i32, i32* %t4339, i64 %t4368
  store i32 19, i32* %t4378
  %t4379 = load i64, i64* %t4270
  %t4380 = add i64 %t4379, 1
  store i64 %t4380, i64* %t4270
  br label %map_insert_after_1013
map_insert_after_1013:
  %t4381 = getelementptr i8*, i8** null, i32 1
  %t4382 = ptrtoint i8** %t4381 to i64
  %t4383 = getelementptr i32, i32* null, i32 1
  %t4384 = ptrtoint i32* %t4383 to i64
  %t4385 = load i8*, i8** %t0
  %t4386 = icmp eq i8* %t4385, null
  br i1 %t4386, label %map_cow_alloc_1016, label %map_cow_check_1017
map_cow_alloc_1016:
  %t4387 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4388 = call i8* @star_rc_alloc(i64 48, i8* %t4387)
  %t4389 = bitcast i8* %t4388 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4390 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4389, i32 0, i32 0
  store i8** null, i8*** %t4390
  %t4391 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4389, i32 0, i32 1
  store i32* null, i32** %t4391
  %t4392 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4389, i32 0, i32 2
  store i8* null, i8** %t4392
  %t4393 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4389, i32 0, i32 3
  store i64 0, i64* %t4393
  %t4394 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4389, i32 0, i32 4
  store i64 0, i64* %t4394
  %t4395 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4389, i32 0, i32 5
  store i64 0, i64* %t4395
  store i8* %t4388, i8** %t0
  br label %map_cow_done_1018
map_cow_check_1017:
  %t4396 = getelementptr inbounds i8, i8* %t4385, i64 -16
  %t4397 = bitcast i8* %t4396 to i64*
  %t4398 = load atomic i64, i64* %t4397 seq_cst, align 8
  %t4399 = icmp eq i64 %t4398, 1
  br i1 %t4399, label %map_cow_done_1018, label %map_cow_clone_1019
map_cow_clone_1019:
  %t4400 = bitcast i8* %t4385 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4401 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4400, i32 0, i32 0
  %t4402 = load i8**, i8*** %t4401
  %t4403 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4400, i32 0, i32 1
  %t4404 = load i32*, i32** %t4403
  %t4405 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4400, i32 0, i32 2
  %t4406 = load i8*, i8** %t4405
  %t4407 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4400, i32 0, i32 3
  %t4408 = load i64, i64* %t4407
  %t4409 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4400, i32 0, i32 4
  %t4410 = load i64, i64* %t4409
  %t4411 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4400, i32 0, i32 5
  %t4412 = load i64, i64* %t4411
  %t4413 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4414 = call i8* @star_rc_alloc(i64 48, i8* %t4413)
  %t4415 = bitcast i8* %t4414 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4416 = mul i64 %t4410, %t4382
  %t4417 = call i8* @malloc(i64 %t4416)
  %t4418 = bitcast i8* %t4417 to i8**
  %t4419 = mul i64 %t4410, %t4384
  %t4420 = call i8* @malloc(i64 %t4419)
  %t4421 = bitcast i8* %t4420 to i32*
  %t4422 = call i8* @malloc(i64 %t4410)
  %t4423 = icmp sgt i64 %t4410, 0
  br i1 %t4423, label %map_cow_copy_1020, label %map_cow_after_copy_1021
map_cow_copy_1020:
  %t4424 = mul i64 %t4410, %t4382
  %t4425 = bitcast i8** %t4402 to i8*
  call i8* @memcpy(i8* %t4417, i8* %t4425, i64 %t4424)
  %t4426 = mul i64 %t4410, %t4384
  %t4427 = bitcast i32* %t4404 to i8*
  call i8* @memcpy(i8* %t4420, i8* %t4427, i64 %t4426)
  call i8* @memcpy(i8* %t4422, i8* %t4406, i64 %t4410)
  store i64 0, i64* %t4428
  br label %map_cow_retain_cond_1022
map_cow_retain_cond_1022:
  %t4429 = load i64, i64* %t4428
  %t4430 = icmp slt i64 %t4429, %t4410
  br i1 %t4430, label %map_cow_retain_body_1023, label %map_cow_retain_end_1026
map_cow_retain_body_1023:
  %t4431 = getelementptr inbounds i8, i8* %t4422, i64 %t4429
  %t4432 = load i8, i8* %t4431
  %t4433 = icmp eq i8 %t4432, 1
  br i1 %t4433, label %map_cow_retain_occ_1024, label %map_cow_retain_next_1025
map_cow_retain_occ_1024:
  %t4434 = getelementptr inbounds i8*, i8** %t4418, i64 %t4429
  %t4435 = load i8*, i8** %t4434
  call void @star_rc_retain(i8* %t4435)
  br label %map_cow_retain_next_1025
map_cow_retain_next_1025:
  %t4436 = add i64 %t4429, 1
  store i64 %t4436, i64* %t4428
  br label %map_cow_retain_cond_1022
map_cow_retain_end_1026:
  br label %map_cow_after_copy_1021
map_cow_after_copy_1021:
  %t4437 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4415, i32 0, i32 0
  store i8** %t4418, i8*** %t4437
  %t4438 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4415, i32 0, i32 1
  store i32* %t4421, i32** %t4438
  %t4439 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4415, i32 0, i32 2
  store i8* %t4422, i8** %t4439
  %t4440 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4415, i32 0, i32 3
  store i64 %t4408, i64* %t4440
  %t4441 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4415, i32 0, i32 4
  store i64 %t4410, i64* %t4441
  %t4442 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4415, i32 0, i32 5
  store i64 %t4412, i64* %t4442
  call void @star_rc_release(i8* %t4385)
  store i8* %t4414, i8** %t0
  br label %map_cow_done_1018
map_cow_done_1018:
  %t4443 = load i8*, i8** %t0
  %t4444 = bitcast i8* %t4443 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4445 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4444, i32 0, i32 0
  %t4446 = load i8**, i8*** %t4445
  %t4447 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4444, i32 0, i32 1
  %t4448 = load i32*, i32** %t4447
  %t4449 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4444, i32 0, i32 2
  %t4450 = load i8*, i8** %t4449
  %t4451 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4444, i32 0, i32 3
  %t4452 = load i64, i64* %t4451
  %t4453 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4444, i32 0, i32 4
  %t4454 = load i64, i64* %t4453
  %t4455 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4444, i32 0, i32 5
  %t4456 = load i64, i64* %t4455
  %t4457 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t4458 = load i64, i64* %t4451
  %t4459 = load i64, i64* %t4453
  %t4460 = load i64, i64* %t4455
  %t4461 = add i64 %t4458, %t4460
  %t4462 = add i64 %t4461, 1
  %t4463 = mul i64 %t4462, 4
  %t4464 = mul i64 %t4459, 3
  %t4465 = icmp sgt i64 %t4463, %t4464
  br i1 %t4465, label %map_insert_grow_1027, label %map_insert_after_grow_1028
map_insert_grow_1027:
  %t4466 = getelementptr i8*, i8** null, i32 1
  %t4467 = ptrtoint i8** %t4466 to i64
  %t4468 = getelementptr i32, i32* null, i32 1
  %t4469 = ptrtoint i32* %t4468 to i64
  %t4470 = mul i64 %t4459, 2
  %t4471 = icmp sgt i64 %t4470, 0
  %t4472 = select i1 %t4471, i64 %t4470, i64 8
  %t4473 = sub i64 %t4472, 1
  %t4474 = mul i64 %t4472, %t4467
  %t4475 = call i8* @malloc(i64 %t4474)
  %t4476 = bitcast i8* %t4475 to i8**
  %t4477 = mul i64 %t4472, %t4469
  %t4478 = call i8* @malloc(i64 %t4477)
  %t4479 = bitcast i8* %t4478 to i32*
  %t4480 = call i8* @malloc(i64 %t4472)
  store i64 0, i64* %t4481
  br label %ht_fill8_cond_1029
ht_fill8_cond_1029:
  %t4482 = load i64, i64* %t4481
  %t4483 = icmp slt i64 %t4482, %t4472
  br i1 %t4483, label %ht_fill8_body_1030, label %ht_fill8_end_1031
ht_fill8_body_1030:
  %t4484 = getelementptr inbounds i8, i8* %t4480, i64 %t4482
  store i8 0, i8* %t4484
  %t4485 = add i64 %t4482, 1
  store i64 %t4485, i64* %t4481
  br label %ht_fill8_cond_1029
ht_fill8_end_1031:
  %t4486 = load i8**, i8*** %t4445
  %t4487 = load i32*, i32** %t4447
  %t4488 = load i8*, i8** %t4449
  store i64 0, i64* %t4489
  br label %map_grow_cond_1032
map_grow_cond_1032:
  %t4490 = load i64, i64* %t4489
  %t4491 = icmp slt i64 %t4490, %t4459
  br i1 %t4491, label %map_grow_body_1033, label %map_grow_end_1036
map_grow_body_1033:
  %t4492 = getelementptr inbounds i8, i8* %t4488, i64 %t4490
  %t4493 = load i8, i8* %t4492
  %t4494 = icmp eq i8 %t4493, 1
  br i1 %t4494, label %map_grow_occ_1034, label %map_grow_next_1035
map_grow_occ_1034:
  %t4495 = getelementptr inbounds i8*, i8** %t4486, i64 %t4490
  %t4496 = load i8*, i8** %t4495
  %t4497 = getelementptr inbounds i32, i32* %t4487, i64 %t4490
  %t4498 = load i32, i32* %t4497
  %t4499 = call i64 @hash_str(i8* %t4496)
  %t4500 = and i64 %t4499, %t4473
  store i64 0, i64* %t4501
  store i64 %t4500, i64* %t4502
  br label %ht_fe_cond_1037
ht_fe_cond_1037:
  %t4503 = load i64, i64* %t4501
  %t4504 = icmp slt i64 %t4503, %t4472
  br i1 %t4504, label %ht_fe_body_1038, label %ht_fe_end_1040
ht_fe_body_1038:
  %t4505 = load i64, i64* %t4502
  %t4506 = getelementptr inbounds i8, i8* %t4480, i64 %t4505
  %t4507 = load i8, i8* %t4506
  %t4508 = icmp eq i8 %t4507, 0
  br i1 %t4508, label %ht_fe_end_1040, label %ht_fe_next_1039
ht_fe_next_1039:
  %t4509 = add i64 %t4505, 1
  %t4510 = and i64 %t4509, %t4473
  store i64 %t4510, i64* %t4502
  %t4511 = add i64 %t4503, 1
  store i64 %t4511, i64* %t4501
  br label %ht_fe_cond_1037
ht_fe_end_1040:
  %t4512 = load i64, i64* %t4502
  %t4513 = getelementptr inbounds i8, i8* %t4480, i64 %t4512
  store i8 1, i8* %t4513
  %t4514 = getelementptr inbounds i8*, i8** %t4476, i64 %t4512
  store i8* %t4496, i8** %t4514
  %t4515 = getelementptr inbounds i32, i32* %t4479, i64 %t4512
  store i32 %t4498, i32* %t4515
  br label %map_grow_next_1035
map_grow_next_1035:
  %t4516 = add i64 %t4490, 1
  store i64 %t4516, i64* %t4489
  br label %map_grow_cond_1032
map_grow_end_1036:
  %t4517 = bitcast i8** %t4486 to i8*
  call void @free(i8* %t4517)
  %t4518 = bitcast i32* %t4487 to i8*
  call void @free(i8* %t4518)
  call void @free(i8* %t4488)
  store i8** %t4476, i8*** %t4445
  store i32* %t4479, i32** %t4447
  store i8* %t4480, i8** %t4449
  store i64 %t4472, i64* %t4453
  store i64 0, i64* %t4455
  br label %map_insert_after_grow_1028
map_insert_after_grow_1028:
  %t4519 = load i8**, i8*** %t4445
  %t4520 = load i32*, i32** %t4447
  %t4521 = load i8*, i8** %t4449
  %t4522 = load i64, i64* %t4453
  %t4523 = sub i64 %t4522, 1
  %t4524 = call i64 @hash_str(i8* %t4457)
  %t4525 = and i64 %t4524, %t4523
  store i64 0, i64* %t4526
  store i64 %t4525, i64* %t4527
  store i1 false, i1* %t4528
  store i64 -1, i64* %t4529
  store i64 -1, i64* %t4530
  store i1 false, i1* %t4531
  br label %ht_probe_cond_1041
ht_probe_cond_1041:
  %t4532 = load i64, i64* %t4526
  %t4533 = icmp slt i64 %t4532, %t4522
  br i1 %t4533, label %ht_probe_body_1042, label %ht_probe_end_1052
ht_probe_body_1042:
  %t4534 = load i64, i64* %t4527
  %t4535 = getelementptr inbounds i8, i8* %t4521, i64 %t4534
  %t4536 = load i8, i8* %t4535
  %t4537 = icmp eq i8 %t4536, 0
  br i1 %t4537, label %ht_probe_on_empty_1044, label %ht_probe_check_occ_1043
ht_probe_check_occ_1043:
  %t4538 = icmp eq i8 %t4536, 1
  br i1 %t4538, label %ht_probe_on_occ_1047, label %ht_probe_on_tomb_1049
ht_probe_on_empty_1044:
  %t4539 = load i1, i1* %t4531
  br i1 %t4539, label %ht_probe_after_islot_empty_1046, label %ht_probe_set_islot_empty_1045
ht_probe_set_islot_empty_1045:
  store i64 %t4534, i64* %t4530
  store i1 true, i1* %t4531
  br label %ht_probe_after_islot_empty_1046
ht_probe_after_islot_empty_1046:
  br label %ht_probe_end_1052
ht_probe_on_occ_1047:
  %t4540 = getelementptr inbounds i8*, i8** %t4519, i64 %t4534
  %t4541 = load i8*, i8** %t4540
  %t4542 = call i1 @eq_str(i8* %t4541, i8* %t4457)
  br i1 %t4542, label %ht_probe_on_match_1048, label %ht_probe_next_1051
ht_probe_on_match_1048:
  store i1 true, i1* %t4528
  store i64 %t4534, i64* %t4529
  br label %ht_probe_end_1052
ht_probe_on_tomb_1049:
  %t4543 = load i1, i1* %t4531
  br i1 %t4543, label %ht_probe_next_1051, label %ht_probe_set_islot_tomb_1050
ht_probe_set_islot_tomb_1050:
  store i64 %t4534, i64* %t4530
  store i1 true, i1* %t4531
  br label %ht_probe_next_1051
ht_probe_next_1051:
  %t4544 = add i64 %t4534, 1
  %t4545 = and i64 %t4544, %t4523
  store i64 %t4545, i64* %t4527
  %t4546 = add i64 %t4532, 1
  store i64 %t4546, i64* %t4526
  br label %ht_probe_cond_1041
ht_probe_end_1052:
  %t4547 = load i1, i1* %t4528
  %t4548 = load i64, i64* %t4529
  %t4549 = load i64, i64* %t4530
  br i1 %t4547, label %map_insert_overwrite_1053, label %map_insert_new_1054
map_insert_overwrite_1053:
  store i8* %t4457, i8** %t4550
  %t4551 = load i8*, i8** %t4550
  call void @star_rc_release(i8* %t4551)
  %t4552 = getelementptr inbounds i32, i32* %t4520, i64 %t4548
  store i32 20, i32* %t4552
  br label %map_insert_after_1055
map_insert_new_1054:
  %t4553 = getelementptr inbounds i8, i8* %t4521, i64 %t4549
  %t4554 = load i8, i8* %t4553
  %t4555 = icmp eq i8 %t4554, 2
  br i1 %t4555, label %map_insert_dec_tomb_1056, label %map_insert_store_1057
map_insert_dec_tomb_1056:
  %t4556 = load i64, i64* %t4455
  %t4557 = sub i64 %t4556, 1
  store i64 %t4557, i64* %t4455
  br label %map_insert_store_1057
map_insert_store_1057:
  store i8 1, i8* %t4553
  %t4558 = getelementptr inbounds i8*, i8** %t4519, i64 %t4549
  store i8* %t4457, i8** %t4558
  %t4559 = getelementptr inbounds i32, i32* %t4520, i64 %t4549
  store i32 20, i32* %t4559
  %t4560 = load i64, i64* %t4451
  %t4561 = add i64 %t4560, 1
  store i64 %t4561, i64* %t4451
  br label %map_insert_after_1055
map_insert_after_1055:
  %t4562 = getelementptr i8*, i8** null, i32 1
  %t4563 = ptrtoint i8** %t4562 to i64
  %t4564 = getelementptr i32, i32* null, i32 1
  %t4565 = ptrtoint i32* %t4564 to i64
  %t4566 = load i8*, i8** %t0
  %t4567 = icmp eq i8* %t4566, null
  br i1 %t4567, label %map_cow_alloc_1058, label %map_cow_check_1059
map_cow_alloc_1058:
  %t4568 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4569 = call i8* @star_rc_alloc(i64 48, i8* %t4568)
  %t4570 = bitcast i8* %t4569 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4571 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4570, i32 0, i32 0
  store i8** null, i8*** %t4571
  %t4572 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4570, i32 0, i32 1
  store i32* null, i32** %t4572
  %t4573 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4570, i32 0, i32 2
  store i8* null, i8** %t4573
  %t4574 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4570, i32 0, i32 3
  store i64 0, i64* %t4574
  %t4575 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4570, i32 0, i32 4
  store i64 0, i64* %t4575
  %t4576 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4570, i32 0, i32 5
  store i64 0, i64* %t4576
  store i8* %t4569, i8** %t0
  br label %map_cow_done_1060
map_cow_check_1059:
  %t4577 = getelementptr inbounds i8, i8* %t4566, i64 -16
  %t4578 = bitcast i8* %t4577 to i64*
  %t4579 = load atomic i64, i64* %t4578 seq_cst, align 8
  %t4580 = icmp eq i64 %t4579, 1
  br i1 %t4580, label %map_cow_done_1060, label %map_cow_clone_1061
map_cow_clone_1061:
  %t4581 = bitcast i8* %t4566 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4582 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4581, i32 0, i32 0
  %t4583 = load i8**, i8*** %t4582
  %t4584 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4581, i32 0, i32 1
  %t4585 = load i32*, i32** %t4584
  %t4586 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4581, i32 0, i32 2
  %t4587 = load i8*, i8** %t4586
  %t4588 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4581, i32 0, i32 3
  %t4589 = load i64, i64* %t4588
  %t4590 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4581, i32 0, i32 4
  %t4591 = load i64, i64* %t4590
  %t4592 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4581, i32 0, i32 5
  %t4593 = load i64, i64* %t4592
  %t4594 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4595 = call i8* @star_rc_alloc(i64 48, i8* %t4594)
  %t4596 = bitcast i8* %t4595 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4597 = mul i64 %t4591, %t4563
  %t4598 = call i8* @malloc(i64 %t4597)
  %t4599 = bitcast i8* %t4598 to i8**
  %t4600 = mul i64 %t4591, %t4565
  %t4601 = call i8* @malloc(i64 %t4600)
  %t4602 = bitcast i8* %t4601 to i32*
  %t4603 = call i8* @malloc(i64 %t4591)
  %t4604 = icmp sgt i64 %t4591, 0
  br i1 %t4604, label %map_cow_copy_1062, label %map_cow_after_copy_1063
map_cow_copy_1062:
  %t4605 = mul i64 %t4591, %t4563
  %t4606 = bitcast i8** %t4583 to i8*
  call i8* @memcpy(i8* %t4598, i8* %t4606, i64 %t4605)
  %t4607 = mul i64 %t4591, %t4565
  %t4608 = bitcast i32* %t4585 to i8*
  call i8* @memcpy(i8* %t4601, i8* %t4608, i64 %t4607)
  call i8* @memcpy(i8* %t4603, i8* %t4587, i64 %t4591)
  store i64 0, i64* %t4609
  br label %map_cow_retain_cond_1064
map_cow_retain_cond_1064:
  %t4610 = load i64, i64* %t4609
  %t4611 = icmp slt i64 %t4610, %t4591
  br i1 %t4611, label %map_cow_retain_body_1065, label %map_cow_retain_end_1068
map_cow_retain_body_1065:
  %t4612 = getelementptr inbounds i8, i8* %t4603, i64 %t4610
  %t4613 = load i8, i8* %t4612
  %t4614 = icmp eq i8 %t4613, 1
  br i1 %t4614, label %map_cow_retain_occ_1066, label %map_cow_retain_next_1067
map_cow_retain_occ_1066:
  %t4615 = getelementptr inbounds i8*, i8** %t4599, i64 %t4610
  %t4616 = load i8*, i8** %t4615
  call void @star_rc_retain(i8* %t4616)
  br label %map_cow_retain_next_1067
map_cow_retain_next_1067:
  %t4617 = add i64 %t4610, 1
  store i64 %t4617, i64* %t4609
  br label %map_cow_retain_cond_1064
map_cow_retain_end_1068:
  br label %map_cow_after_copy_1063
map_cow_after_copy_1063:
  %t4618 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4596, i32 0, i32 0
  store i8** %t4599, i8*** %t4618
  %t4619 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4596, i32 0, i32 1
  store i32* %t4602, i32** %t4619
  %t4620 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4596, i32 0, i32 2
  store i8* %t4603, i8** %t4620
  %t4621 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4596, i32 0, i32 3
  store i64 %t4589, i64* %t4621
  %t4622 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4596, i32 0, i32 4
  store i64 %t4591, i64* %t4622
  %t4623 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4596, i32 0, i32 5
  store i64 %t4593, i64* %t4623
  call void @star_rc_release(i8* %t4566)
  store i8* %t4595, i8** %t0
  br label %map_cow_done_1060
map_cow_done_1060:
  %t4624 = load i8*, i8** %t0
  %t4625 = bitcast i8* %t4624 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4626 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4625, i32 0, i32 0
  %t4627 = load i8**, i8*** %t4626
  %t4628 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4625, i32 0, i32 1
  %t4629 = load i32*, i32** %t4628
  %t4630 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4625, i32 0, i32 2
  %t4631 = load i8*, i8** %t4630
  %t4632 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4625, i32 0, i32 3
  %t4633 = load i64, i64* %t4632
  %t4634 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4625, i32 0, i32 4
  %t4635 = load i64, i64* %t4634
  %t4636 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4625, i32 0, i32 5
  %t4637 = load i64, i64* %t4636
  %t4638 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.25, i64 0, i32 2, i64 0
  %t4639 = load i64, i64* %t4632
  %t4640 = load i64, i64* %t4634
  %t4641 = load i64, i64* %t4636
  %t4642 = add i64 %t4639, %t4641
  %t4643 = add i64 %t4642, 1
  %t4644 = mul i64 %t4643, 4
  %t4645 = mul i64 %t4640, 3
  %t4646 = icmp sgt i64 %t4644, %t4645
  br i1 %t4646, label %map_insert_grow_1069, label %map_insert_after_grow_1070
map_insert_grow_1069:
  %t4647 = getelementptr i8*, i8** null, i32 1
  %t4648 = ptrtoint i8** %t4647 to i64
  %t4649 = getelementptr i32, i32* null, i32 1
  %t4650 = ptrtoint i32* %t4649 to i64
  %t4651 = mul i64 %t4640, 2
  %t4652 = icmp sgt i64 %t4651, 0
  %t4653 = select i1 %t4652, i64 %t4651, i64 8
  %t4654 = sub i64 %t4653, 1
  %t4655 = mul i64 %t4653, %t4648
  %t4656 = call i8* @malloc(i64 %t4655)
  %t4657 = bitcast i8* %t4656 to i8**
  %t4658 = mul i64 %t4653, %t4650
  %t4659 = call i8* @malloc(i64 %t4658)
  %t4660 = bitcast i8* %t4659 to i32*
  %t4661 = call i8* @malloc(i64 %t4653)
  store i64 0, i64* %t4662
  br label %ht_fill8_cond_1071
ht_fill8_cond_1071:
  %t4663 = load i64, i64* %t4662
  %t4664 = icmp slt i64 %t4663, %t4653
  br i1 %t4664, label %ht_fill8_body_1072, label %ht_fill8_end_1073
ht_fill8_body_1072:
  %t4665 = getelementptr inbounds i8, i8* %t4661, i64 %t4663
  store i8 0, i8* %t4665
  %t4666 = add i64 %t4663, 1
  store i64 %t4666, i64* %t4662
  br label %ht_fill8_cond_1071
ht_fill8_end_1073:
  %t4667 = load i8**, i8*** %t4626
  %t4668 = load i32*, i32** %t4628
  %t4669 = load i8*, i8** %t4630
  store i64 0, i64* %t4670
  br label %map_grow_cond_1074
map_grow_cond_1074:
  %t4671 = load i64, i64* %t4670
  %t4672 = icmp slt i64 %t4671, %t4640
  br i1 %t4672, label %map_grow_body_1075, label %map_grow_end_1078
map_grow_body_1075:
  %t4673 = getelementptr inbounds i8, i8* %t4669, i64 %t4671
  %t4674 = load i8, i8* %t4673
  %t4675 = icmp eq i8 %t4674, 1
  br i1 %t4675, label %map_grow_occ_1076, label %map_grow_next_1077
map_grow_occ_1076:
  %t4676 = getelementptr inbounds i8*, i8** %t4667, i64 %t4671
  %t4677 = load i8*, i8** %t4676
  %t4678 = getelementptr inbounds i32, i32* %t4668, i64 %t4671
  %t4679 = load i32, i32* %t4678
  %t4680 = call i64 @hash_str(i8* %t4677)
  %t4681 = and i64 %t4680, %t4654
  store i64 0, i64* %t4682
  store i64 %t4681, i64* %t4683
  br label %ht_fe_cond_1079
ht_fe_cond_1079:
  %t4684 = load i64, i64* %t4682
  %t4685 = icmp slt i64 %t4684, %t4653
  br i1 %t4685, label %ht_fe_body_1080, label %ht_fe_end_1082
ht_fe_body_1080:
  %t4686 = load i64, i64* %t4683
  %t4687 = getelementptr inbounds i8, i8* %t4661, i64 %t4686
  %t4688 = load i8, i8* %t4687
  %t4689 = icmp eq i8 %t4688, 0
  br i1 %t4689, label %ht_fe_end_1082, label %ht_fe_next_1081
ht_fe_next_1081:
  %t4690 = add i64 %t4686, 1
  %t4691 = and i64 %t4690, %t4654
  store i64 %t4691, i64* %t4683
  %t4692 = add i64 %t4684, 1
  store i64 %t4692, i64* %t4682
  br label %ht_fe_cond_1079
ht_fe_end_1082:
  %t4693 = load i64, i64* %t4683
  %t4694 = getelementptr inbounds i8, i8* %t4661, i64 %t4693
  store i8 1, i8* %t4694
  %t4695 = getelementptr inbounds i8*, i8** %t4657, i64 %t4693
  store i8* %t4677, i8** %t4695
  %t4696 = getelementptr inbounds i32, i32* %t4660, i64 %t4693
  store i32 %t4679, i32* %t4696
  br label %map_grow_next_1077
map_grow_next_1077:
  %t4697 = add i64 %t4671, 1
  store i64 %t4697, i64* %t4670
  br label %map_grow_cond_1074
map_grow_end_1078:
  %t4698 = bitcast i8** %t4667 to i8*
  call void @free(i8* %t4698)
  %t4699 = bitcast i32* %t4668 to i8*
  call void @free(i8* %t4699)
  call void @free(i8* %t4669)
  store i8** %t4657, i8*** %t4626
  store i32* %t4660, i32** %t4628
  store i8* %t4661, i8** %t4630
  store i64 %t4653, i64* %t4634
  store i64 0, i64* %t4636
  br label %map_insert_after_grow_1070
map_insert_after_grow_1070:
  %t4700 = load i8**, i8*** %t4626
  %t4701 = load i32*, i32** %t4628
  %t4702 = load i8*, i8** %t4630
  %t4703 = load i64, i64* %t4634
  %t4704 = sub i64 %t4703, 1
  %t4705 = call i64 @hash_str(i8* %t4638)
  %t4706 = and i64 %t4705, %t4704
  store i64 0, i64* %t4707
  store i64 %t4706, i64* %t4708
  store i1 false, i1* %t4709
  store i64 -1, i64* %t4710
  store i64 -1, i64* %t4711
  store i1 false, i1* %t4712
  br label %ht_probe_cond_1083
ht_probe_cond_1083:
  %t4713 = load i64, i64* %t4707
  %t4714 = icmp slt i64 %t4713, %t4703
  br i1 %t4714, label %ht_probe_body_1084, label %ht_probe_end_1094
ht_probe_body_1084:
  %t4715 = load i64, i64* %t4708
  %t4716 = getelementptr inbounds i8, i8* %t4702, i64 %t4715
  %t4717 = load i8, i8* %t4716
  %t4718 = icmp eq i8 %t4717, 0
  br i1 %t4718, label %ht_probe_on_empty_1086, label %ht_probe_check_occ_1085
ht_probe_check_occ_1085:
  %t4719 = icmp eq i8 %t4717, 1
  br i1 %t4719, label %ht_probe_on_occ_1089, label %ht_probe_on_tomb_1091
ht_probe_on_empty_1086:
  %t4720 = load i1, i1* %t4712
  br i1 %t4720, label %ht_probe_after_islot_empty_1088, label %ht_probe_set_islot_empty_1087
ht_probe_set_islot_empty_1087:
  store i64 %t4715, i64* %t4711
  store i1 true, i1* %t4712
  br label %ht_probe_after_islot_empty_1088
ht_probe_after_islot_empty_1088:
  br label %ht_probe_end_1094
ht_probe_on_occ_1089:
  %t4721 = getelementptr inbounds i8*, i8** %t4700, i64 %t4715
  %t4722 = load i8*, i8** %t4721
  %t4723 = call i1 @eq_str(i8* %t4722, i8* %t4638)
  br i1 %t4723, label %ht_probe_on_match_1090, label %ht_probe_next_1093
ht_probe_on_match_1090:
  store i1 true, i1* %t4709
  store i64 %t4715, i64* %t4710
  br label %ht_probe_end_1094
ht_probe_on_tomb_1091:
  %t4724 = load i1, i1* %t4712
  br i1 %t4724, label %ht_probe_next_1093, label %ht_probe_set_islot_tomb_1092
ht_probe_set_islot_tomb_1092:
  store i64 %t4715, i64* %t4711
  store i1 true, i1* %t4712
  br label %ht_probe_next_1093
ht_probe_next_1093:
  %t4725 = add i64 %t4715, 1
  %t4726 = and i64 %t4725, %t4704
  store i64 %t4726, i64* %t4708
  %t4727 = add i64 %t4713, 1
  store i64 %t4727, i64* %t4707
  br label %ht_probe_cond_1083
ht_probe_end_1094:
  %t4728 = load i1, i1* %t4709
  %t4729 = load i64, i64* %t4710
  %t4730 = load i64, i64* %t4711
  br i1 %t4728, label %map_insert_overwrite_1095, label %map_insert_new_1096
map_insert_overwrite_1095:
  store i8* %t4638, i8** %t4731
  %t4732 = load i8*, i8** %t4731
  call void @star_rc_release(i8* %t4732)
  %t4733 = getelementptr inbounds i32, i32* %t4701, i64 %t4729
  store i32 25, i32* %t4733
  br label %map_insert_after_1097
map_insert_new_1096:
  %t4734 = getelementptr inbounds i8, i8* %t4702, i64 %t4730
  %t4735 = load i8, i8* %t4734
  %t4736 = icmp eq i8 %t4735, 2
  br i1 %t4736, label %map_insert_dec_tomb_1098, label %map_insert_store_1099
map_insert_dec_tomb_1098:
  %t4737 = load i64, i64* %t4636
  %t4738 = sub i64 %t4737, 1
  store i64 %t4738, i64* %t4636
  br label %map_insert_store_1099
map_insert_store_1099:
  store i8 1, i8* %t4734
  %t4739 = getelementptr inbounds i8*, i8** %t4700, i64 %t4730
  store i8* %t4638, i8** %t4739
  %t4740 = getelementptr inbounds i32, i32* %t4701, i64 %t4730
  store i32 25, i32* %t4740
  %t4741 = load i64, i64* %t4632
  %t4742 = add i64 %t4741, 1
  store i64 %t4742, i64* %t4632
  br label %map_insert_after_1097
map_insert_after_1097:
  %t4743 = getelementptr i8*, i8** null, i32 1
  %t4744 = ptrtoint i8** %t4743 to i64
  %t4745 = getelementptr i32, i32* null, i32 1
  %t4746 = ptrtoint i32* %t4745 to i64
  %t4747 = load i8*, i8** %t0
  %t4748 = icmp eq i8* %t4747, null
  br i1 %t4748, label %map_cow_alloc_1100, label %map_cow_check_1101
map_cow_alloc_1100:
  %t4749 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4750 = call i8* @star_rc_alloc(i64 48, i8* %t4749)
  %t4751 = bitcast i8* %t4750 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4752 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4751, i32 0, i32 0
  store i8** null, i8*** %t4752
  %t4753 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4751, i32 0, i32 1
  store i32* null, i32** %t4753
  %t4754 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4751, i32 0, i32 2
  store i8* null, i8** %t4754
  %t4755 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4751, i32 0, i32 3
  store i64 0, i64* %t4755
  %t4756 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4751, i32 0, i32 4
  store i64 0, i64* %t4756
  %t4757 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4751, i32 0, i32 5
  store i64 0, i64* %t4757
  store i8* %t4750, i8** %t0
  br label %map_cow_done_1102
map_cow_check_1101:
  %t4758 = getelementptr inbounds i8, i8* %t4747, i64 -16
  %t4759 = bitcast i8* %t4758 to i64*
  %t4760 = load atomic i64, i64* %t4759 seq_cst, align 8
  %t4761 = icmp eq i64 %t4760, 1
  br i1 %t4761, label %map_cow_done_1102, label %map_cow_clone_1103
map_cow_clone_1103:
  %t4762 = bitcast i8* %t4747 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4763 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4762, i32 0, i32 0
  %t4764 = load i8**, i8*** %t4763
  %t4765 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4762, i32 0, i32 1
  %t4766 = load i32*, i32** %t4765
  %t4767 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4762, i32 0, i32 2
  %t4768 = load i8*, i8** %t4767
  %t4769 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4762, i32 0, i32 3
  %t4770 = load i64, i64* %t4769
  %t4771 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4762, i32 0, i32 4
  %t4772 = load i64, i64* %t4771
  %t4773 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4762, i32 0, i32 5
  %t4774 = load i64, i64* %t4773
  %t4775 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4776 = call i8* @star_rc_alloc(i64 48, i8* %t4775)
  %t4777 = bitcast i8* %t4776 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4778 = mul i64 %t4772, %t4744
  %t4779 = call i8* @malloc(i64 %t4778)
  %t4780 = bitcast i8* %t4779 to i8**
  %t4781 = mul i64 %t4772, %t4746
  %t4782 = call i8* @malloc(i64 %t4781)
  %t4783 = bitcast i8* %t4782 to i32*
  %t4784 = call i8* @malloc(i64 %t4772)
  %t4785 = icmp sgt i64 %t4772, 0
  br i1 %t4785, label %map_cow_copy_1104, label %map_cow_after_copy_1105
map_cow_copy_1104:
  %t4786 = mul i64 %t4772, %t4744
  %t4787 = bitcast i8** %t4764 to i8*
  call i8* @memcpy(i8* %t4779, i8* %t4787, i64 %t4786)
  %t4788 = mul i64 %t4772, %t4746
  %t4789 = bitcast i32* %t4766 to i8*
  call i8* @memcpy(i8* %t4782, i8* %t4789, i64 %t4788)
  call i8* @memcpy(i8* %t4784, i8* %t4768, i64 %t4772)
  store i64 0, i64* %t4790
  br label %map_cow_retain_cond_1106
map_cow_retain_cond_1106:
  %t4791 = load i64, i64* %t4790
  %t4792 = icmp slt i64 %t4791, %t4772
  br i1 %t4792, label %map_cow_retain_body_1107, label %map_cow_retain_end_1110
map_cow_retain_body_1107:
  %t4793 = getelementptr inbounds i8, i8* %t4784, i64 %t4791
  %t4794 = load i8, i8* %t4793
  %t4795 = icmp eq i8 %t4794, 1
  br i1 %t4795, label %map_cow_retain_occ_1108, label %map_cow_retain_next_1109
map_cow_retain_occ_1108:
  %t4796 = getelementptr inbounds i8*, i8** %t4780, i64 %t4791
  %t4797 = load i8*, i8** %t4796
  call void @star_rc_retain(i8* %t4797)
  br label %map_cow_retain_next_1109
map_cow_retain_next_1109:
  %t4798 = add i64 %t4791, 1
  store i64 %t4798, i64* %t4790
  br label %map_cow_retain_cond_1106
map_cow_retain_end_1110:
  br label %map_cow_after_copy_1105
map_cow_after_copy_1105:
  %t4799 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4777, i32 0, i32 0
  store i8** %t4780, i8*** %t4799
  %t4800 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4777, i32 0, i32 1
  store i32* %t4783, i32** %t4800
  %t4801 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4777, i32 0, i32 2
  store i8* %t4784, i8** %t4801
  %t4802 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4777, i32 0, i32 3
  store i64 %t4770, i64* %t4802
  %t4803 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4777, i32 0, i32 4
  store i64 %t4772, i64* %t4803
  %t4804 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4777, i32 0, i32 5
  store i64 %t4774, i64* %t4804
  call void @star_rc_release(i8* %t4747)
  store i8* %t4776, i8** %t0
  br label %map_cow_done_1102
map_cow_done_1102:
  %t4805 = load i8*, i8** %t0
  %t4806 = bitcast i8* %t4805 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4807 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4806, i32 0, i32 0
  %t4808 = load i8**, i8*** %t4807
  %t4809 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4806, i32 0, i32 1
  %t4810 = load i32*, i32** %t4809
  %t4811 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4806, i32 0, i32 2
  %t4812 = load i8*, i8** %t4811
  %t4813 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4806, i32 0, i32 3
  %t4814 = load i64, i64* %t4813
  %t4815 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4806, i32 0, i32 4
  %t4816 = load i64, i64* %t4815
  %t4817 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4806, i32 0, i32 5
  %t4818 = load i64, i64* %t4817
  %t4819 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.26, i64 0, i32 2, i64 0
  %t4820 = load i64, i64* %t4813
  %t4821 = load i64, i64* %t4815
  %t4822 = load i64, i64* %t4817
  %t4823 = add i64 %t4820, %t4822
  %t4824 = add i64 %t4823, 1
  %t4825 = mul i64 %t4824, 4
  %t4826 = mul i64 %t4821, 3
  %t4827 = icmp sgt i64 %t4825, %t4826
  br i1 %t4827, label %map_insert_grow_1111, label %map_insert_after_grow_1112
map_insert_grow_1111:
  %t4828 = getelementptr i8*, i8** null, i32 1
  %t4829 = ptrtoint i8** %t4828 to i64
  %t4830 = getelementptr i32, i32* null, i32 1
  %t4831 = ptrtoint i32* %t4830 to i64
  %t4832 = mul i64 %t4821, 2
  %t4833 = icmp sgt i64 %t4832, 0
  %t4834 = select i1 %t4833, i64 %t4832, i64 8
  %t4835 = sub i64 %t4834, 1
  %t4836 = mul i64 %t4834, %t4829
  %t4837 = call i8* @malloc(i64 %t4836)
  %t4838 = bitcast i8* %t4837 to i8**
  %t4839 = mul i64 %t4834, %t4831
  %t4840 = call i8* @malloc(i64 %t4839)
  %t4841 = bitcast i8* %t4840 to i32*
  %t4842 = call i8* @malloc(i64 %t4834)
  store i64 0, i64* %t4843
  br label %ht_fill8_cond_1113
ht_fill8_cond_1113:
  %t4844 = load i64, i64* %t4843
  %t4845 = icmp slt i64 %t4844, %t4834
  br i1 %t4845, label %ht_fill8_body_1114, label %ht_fill8_end_1115
ht_fill8_body_1114:
  %t4846 = getelementptr inbounds i8, i8* %t4842, i64 %t4844
  store i8 0, i8* %t4846
  %t4847 = add i64 %t4844, 1
  store i64 %t4847, i64* %t4843
  br label %ht_fill8_cond_1113
ht_fill8_end_1115:
  %t4848 = load i8**, i8*** %t4807
  %t4849 = load i32*, i32** %t4809
  %t4850 = load i8*, i8** %t4811
  store i64 0, i64* %t4851
  br label %map_grow_cond_1116
map_grow_cond_1116:
  %t4852 = load i64, i64* %t4851
  %t4853 = icmp slt i64 %t4852, %t4821
  br i1 %t4853, label %map_grow_body_1117, label %map_grow_end_1120
map_grow_body_1117:
  %t4854 = getelementptr inbounds i8, i8* %t4850, i64 %t4852
  %t4855 = load i8, i8* %t4854
  %t4856 = icmp eq i8 %t4855, 1
  br i1 %t4856, label %map_grow_occ_1118, label %map_grow_next_1119
map_grow_occ_1118:
  %t4857 = getelementptr inbounds i8*, i8** %t4848, i64 %t4852
  %t4858 = load i8*, i8** %t4857
  %t4859 = getelementptr inbounds i32, i32* %t4849, i64 %t4852
  %t4860 = load i32, i32* %t4859
  %t4861 = call i64 @hash_str(i8* %t4858)
  %t4862 = and i64 %t4861, %t4835
  store i64 0, i64* %t4863
  store i64 %t4862, i64* %t4864
  br label %ht_fe_cond_1121
ht_fe_cond_1121:
  %t4865 = load i64, i64* %t4863
  %t4866 = icmp slt i64 %t4865, %t4834
  br i1 %t4866, label %ht_fe_body_1122, label %ht_fe_end_1124
ht_fe_body_1122:
  %t4867 = load i64, i64* %t4864
  %t4868 = getelementptr inbounds i8, i8* %t4842, i64 %t4867
  %t4869 = load i8, i8* %t4868
  %t4870 = icmp eq i8 %t4869, 0
  br i1 %t4870, label %ht_fe_end_1124, label %ht_fe_next_1123
ht_fe_next_1123:
  %t4871 = add i64 %t4867, 1
  %t4872 = and i64 %t4871, %t4835
  store i64 %t4872, i64* %t4864
  %t4873 = add i64 %t4865, 1
  store i64 %t4873, i64* %t4863
  br label %ht_fe_cond_1121
ht_fe_end_1124:
  %t4874 = load i64, i64* %t4864
  %t4875 = getelementptr inbounds i8, i8* %t4842, i64 %t4874
  store i8 1, i8* %t4875
  %t4876 = getelementptr inbounds i8*, i8** %t4838, i64 %t4874
  store i8* %t4858, i8** %t4876
  %t4877 = getelementptr inbounds i32, i32* %t4841, i64 %t4874
  store i32 %t4860, i32* %t4877
  br label %map_grow_next_1119
map_grow_next_1119:
  %t4878 = add i64 %t4852, 1
  store i64 %t4878, i64* %t4851
  br label %map_grow_cond_1116
map_grow_end_1120:
  %t4879 = bitcast i8** %t4848 to i8*
  call void @free(i8* %t4879)
  %t4880 = bitcast i32* %t4849 to i8*
  call void @free(i8* %t4880)
  call void @free(i8* %t4850)
  store i8** %t4838, i8*** %t4807
  store i32* %t4841, i32** %t4809
  store i8* %t4842, i8** %t4811
  store i64 %t4834, i64* %t4815
  store i64 0, i64* %t4817
  br label %map_insert_after_grow_1112
map_insert_after_grow_1112:
  %t4881 = load i8**, i8*** %t4807
  %t4882 = load i32*, i32** %t4809
  %t4883 = load i8*, i8** %t4811
  %t4884 = load i64, i64* %t4815
  %t4885 = sub i64 %t4884, 1
  %t4886 = call i64 @hash_str(i8* %t4819)
  %t4887 = and i64 %t4886, %t4885
  store i64 0, i64* %t4888
  store i64 %t4887, i64* %t4889
  store i1 false, i1* %t4890
  store i64 -1, i64* %t4891
  store i64 -1, i64* %t4892
  store i1 false, i1* %t4893
  br label %ht_probe_cond_1125
ht_probe_cond_1125:
  %t4894 = load i64, i64* %t4888
  %t4895 = icmp slt i64 %t4894, %t4884
  br i1 %t4895, label %ht_probe_body_1126, label %ht_probe_end_1136
ht_probe_body_1126:
  %t4896 = load i64, i64* %t4889
  %t4897 = getelementptr inbounds i8, i8* %t4883, i64 %t4896
  %t4898 = load i8, i8* %t4897
  %t4899 = icmp eq i8 %t4898, 0
  br i1 %t4899, label %ht_probe_on_empty_1128, label %ht_probe_check_occ_1127
ht_probe_check_occ_1127:
  %t4900 = icmp eq i8 %t4898, 1
  br i1 %t4900, label %ht_probe_on_occ_1131, label %ht_probe_on_tomb_1133
ht_probe_on_empty_1128:
  %t4901 = load i1, i1* %t4893
  br i1 %t4901, label %ht_probe_after_islot_empty_1130, label %ht_probe_set_islot_empty_1129
ht_probe_set_islot_empty_1129:
  store i64 %t4896, i64* %t4892
  store i1 true, i1* %t4893
  br label %ht_probe_after_islot_empty_1130
ht_probe_after_islot_empty_1130:
  br label %ht_probe_end_1136
ht_probe_on_occ_1131:
  %t4902 = getelementptr inbounds i8*, i8** %t4881, i64 %t4896
  %t4903 = load i8*, i8** %t4902
  %t4904 = call i1 @eq_str(i8* %t4903, i8* %t4819)
  br i1 %t4904, label %ht_probe_on_match_1132, label %ht_probe_next_1135
ht_probe_on_match_1132:
  store i1 true, i1* %t4890
  store i64 %t4896, i64* %t4891
  br label %ht_probe_end_1136
ht_probe_on_tomb_1133:
  %t4905 = load i1, i1* %t4893
  br i1 %t4905, label %ht_probe_next_1135, label %ht_probe_set_islot_tomb_1134
ht_probe_set_islot_tomb_1134:
  store i64 %t4896, i64* %t4892
  store i1 true, i1* %t4893
  br label %ht_probe_next_1135
ht_probe_next_1135:
  %t4906 = add i64 %t4896, 1
  %t4907 = and i64 %t4906, %t4885
  store i64 %t4907, i64* %t4889
  %t4908 = add i64 %t4894, 1
  store i64 %t4908, i64* %t4888
  br label %ht_probe_cond_1125
ht_probe_end_1136:
  %t4909 = load i1, i1* %t4890
  %t4910 = load i64, i64* %t4891
  %t4911 = load i64, i64* %t4892
  br i1 %t4909, label %map_insert_overwrite_1137, label %map_insert_new_1138
map_insert_overwrite_1137:
  store i8* %t4819, i8** %t4912
  %t4913 = load i8*, i8** %t4912
  call void @star_rc_release(i8* %t4913)
  %t4914 = getelementptr inbounds i32, i32* %t4882, i64 %t4910
  store i32 26, i32* %t4914
  br label %map_insert_after_1139
map_insert_new_1138:
  %t4915 = getelementptr inbounds i8, i8* %t4883, i64 %t4911
  %t4916 = load i8, i8* %t4915
  %t4917 = icmp eq i8 %t4916, 2
  br i1 %t4917, label %map_insert_dec_tomb_1140, label %map_insert_store_1141
map_insert_dec_tomb_1140:
  %t4918 = load i64, i64* %t4817
  %t4919 = sub i64 %t4918, 1
  store i64 %t4919, i64* %t4817
  br label %map_insert_store_1141
map_insert_store_1141:
  store i8 1, i8* %t4915
  %t4920 = getelementptr inbounds i8*, i8** %t4881, i64 %t4911
  store i8* %t4819, i8** %t4920
  %t4921 = getelementptr inbounds i32, i32* %t4882, i64 %t4911
  store i32 26, i32* %t4921
  %t4922 = load i64, i64* %t4813
  %t4923 = add i64 %t4922, 1
  store i64 %t4923, i64* %t4813
  br label %map_insert_after_1139
map_insert_after_1139:
  %t4924 = getelementptr i8*, i8** null, i32 1
  %t4925 = ptrtoint i8** %t4924 to i64
  %t4926 = getelementptr i32, i32* null, i32 1
  %t4927 = ptrtoint i32* %t4926 to i64
  %t4928 = load i8*, i8** %t0
  %t4929 = icmp eq i8* %t4928, null
  br i1 %t4929, label %map_cow_alloc_1142, label %map_cow_check_1143
map_cow_alloc_1142:
  %t4930 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4931 = call i8* @star_rc_alloc(i64 48, i8* %t4930)
  %t4932 = bitcast i8* %t4931 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4933 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4932, i32 0, i32 0
  store i8** null, i8*** %t4933
  %t4934 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4932, i32 0, i32 1
  store i32* null, i32** %t4934
  %t4935 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4932, i32 0, i32 2
  store i8* null, i8** %t4935
  %t4936 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4932, i32 0, i32 3
  store i64 0, i64* %t4936
  %t4937 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4932, i32 0, i32 4
  store i64 0, i64* %t4937
  %t4938 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4932, i32 0, i32 5
  store i64 0, i64* %t4938
  store i8* %t4931, i8** %t0
  br label %map_cow_done_1144
map_cow_check_1143:
  %t4939 = getelementptr inbounds i8, i8* %t4928, i64 -16
  %t4940 = bitcast i8* %t4939 to i64*
  %t4941 = load atomic i64, i64* %t4940 seq_cst, align 8
  %t4942 = icmp eq i64 %t4941, 1
  br i1 %t4942, label %map_cow_done_1144, label %map_cow_clone_1145
map_cow_clone_1145:
  %t4943 = bitcast i8* %t4928 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4944 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4943, i32 0, i32 0
  %t4945 = load i8**, i8*** %t4944
  %t4946 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4943, i32 0, i32 1
  %t4947 = load i32*, i32** %t4946
  %t4948 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4943, i32 0, i32 2
  %t4949 = load i8*, i8** %t4948
  %t4950 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4943, i32 0, i32 3
  %t4951 = load i64, i64* %t4950
  %t4952 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4943, i32 0, i32 4
  %t4953 = load i64, i64* %t4952
  %t4954 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4943, i32 0, i32 5
  %t4955 = load i64, i64* %t4954
  %t4956 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t4957 = call i8* @star_rc_alloc(i64 48, i8* %t4956)
  %t4958 = bitcast i8* %t4957 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4959 = mul i64 %t4953, %t4925
  %t4960 = call i8* @malloc(i64 %t4959)
  %t4961 = bitcast i8* %t4960 to i8**
  %t4962 = mul i64 %t4953, %t4927
  %t4963 = call i8* @malloc(i64 %t4962)
  %t4964 = bitcast i8* %t4963 to i32*
  %t4965 = call i8* @malloc(i64 %t4953)
  %t4966 = icmp sgt i64 %t4953, 0
  br i1 %t4966, label %map_cow_copy_1146, label %map_cow_after_copy_1147
map_cow_copy_1146:
  %t4967 = mul i64 %t4953, %t4925
  %t4968 = bitcast i8** %t4945 to i8*
  call i8* @memcpy(i8* %t4960, i8* %t4968, i64 %t4967)
  %t4969 = mul i64 %t4953, %t4927
  %t4970 = bitcast i32* %t4947 to i8*
  call i8* @memcpy(i8* %t4963, i8* %t4970, i64 %t4969)
  call i8* @memcpy(i8* %t4965, i8* %t4949, i64 %t4953)
  store i64 0, i64* %t4971
  br label %map_cow_retain_cond_1148
map_cow_retain_cond_1148:
  %t4972 = load i64, i64* %t4971
  %t4973 = icmp slt i64 %t4972, %t4953
  br i1 %t4973, label %map_cow_retain_body_1149, label %map_cow_retain_end_1152
map_cow_retain_body_1149:
  %t4974 = getelementptr inbounds i8, i8* %t4965, i64 %t4972
  %t4975 = load i8, i8* %t4974
  %t4976 = icmp eq i8 %t4975, 1
  br i1 %t4976, label %map_cow_retain_occ_1150, label %map_cow_retain_next_1151
map_cow_retain_occ_1150:
  %t4977 = getelementptr inbounds i8*, i8** %t4961, i64 %t4972
  %t4978 = load i8*, i8** %t4977
  call void @star_rc_retain(i8* %t4978)
  br label %map_cow_retain_next_1151
map_cow_retain_next_1151:
  %t4979 = add i64 %t4972, 1
  store i64 %t4979, i64* %t4971
  br label %map_cow_retain_cond_1148
map_cow_retain_end_1152:
  br label %map_cow_after_copy_1147
map_cow_after_copy_1147:
  %t4980 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4958, i32 0, i32 0
  store i8** %t4961, i8*** %t4980
  %t4981 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4958, i32 0, i32 1
  store i32* %t4964, i32** %t4981
  %t4982 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4958, i32 0, i32 2
  store i8* %t4965, i8** %t4982
  %t4983 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4958, i32 0, i32 3
  store i64 %t4951, i64* %t4983
  %t4984 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4958, i32 0, i32 4
  store i64 %t4953, i64* %t4984
  %t4985 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4958, i32 0, i32 5
  store i64 %t4955, i64* %t4985
  call void @star_rc_release(i8* %t4928)
  store i8* %t4957, i8** %t0
  br label %map_cow_done_1144
map_cow_done_1144:
  %t4986 = load i8*, i8** %t0
  %t4987 = bitcast i8* %t4986 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t4988 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4987, i32 0, i32 0
  %t4989 = load i8**, i8*** %t4988
  %t4990 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4987, i32 0, i32 1
  %t4991 = load i32*, i32** %t4990
  %t4992 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4987, i32 0, i32 2
  %t4993 = load i8*, i8** %t4992
  %t4994 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4987, i32 0, i32 3
  %t4995 = load i64, i64* %t4994
  %t4996 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4987, i32 0, i32 4
  %t4997 = load i64, i64* %t4996
  %t4998 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t4987, i32 0, i32 5
  %t4999 = load i64, i64* %t4998
  %t5000 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.27, i64 0, i32 2, i64 0
  %t5001 = load i64, i64* %t4994
  %t5002 = load i64, i64* %t4996
  %t5003 = load i64, i64* %t4998
  %t5004 = add i64 %t5001, %t5003
  %t5005 = add i64 %t5004, 1
  %t5006 = mul i64 %t5005, 4
  %t5007 = mul i64 %t5002, 3
  %t5008 = icmp sgt i64 %t5006, %t5007
  br i1 %t5008, label %map_insert_grow_1153, label %map_insert_after_grow_1154
map_insert_grow_1153:
  %t5009 = getelementptr i8*, i8** null, i32 1
  %t5010 = ptrtoint i8** %t5009 to i64
  %t5011 = getelementptr i32, i32* null, i32 1
  %t5012 = ptrtoint i32* %t5011 to i64
  %t5013 = mul i64 %t5002, 2
  %t5014 = icmp sgt i64 %t5013, 0
  %t5015 = select i1 %t5014, i64 %t5013, i64 8
  %t5016 = sub i64 %t5015, 1
  %t5017 = mul i64 %t5015, %t5010
  %t5018 = call i8* @malloc(i64 %t5017)
  %t5019 = bitcast i8* %t5018 to i8**
  %t5020 = mul i64 %t5015, %t5012
  %t5021 = call i8* @malloc(i64 %t5020)
  %t5022 = bitcast i8* %t5021 to i32*
  %t5023 = call i8* @malloc(i64 %t5015)
  store i64 0, i64* %t5024
  br label %ht_fill8_cond_1155
ht_fill8_cond_1155:
  %t5025 = load i64, i64* %t5024
  %t5026 = icmp slt i64 %t5025, %t5015
  br i1 %t5026, label %ht_fill8_body_1156, label %ht_fill8_end_1157
ht_fill8_body_1156:
  %t5027 = getelementptr inbounds i8, i8* %t5023, i64 %t5025
  store i8 0, i8* %t5027
  %t5028 = add i64 %t5025, 1
  store i64 %t5028, i64* %t5024
  br label %ht_fill8_cond_1155
ht_fill8_end_1157:
  %t5029 = load i8**, i8*** %t4988
  %t5030 = load i32*, i32** %t4990
  %t5031 = load i8*, i8** %t4992
  store i64 0, i64* %t5032
  br label %map_grow_cond_1158
map_grow_cond_1158:
  %t5033 = load i64, i64* %t5032
  %t5034 = icmp slt i64 %t5033, %t5002
  br i1 %t5034, label %map_grow_body_1159, label %map_grow_end_1162
map_grow_body_1159:
  %t5035 = getelementptr inbounds i8, i8* %t5031, i64 %t5033
  %t5036 = load i8, i8* %t5035
  %t5037 = icmp eq i8 %t5036, 1
  br i1 %t5037, label %map_grow_occ_1160, label %map_grow_next_1161
map_grow_occ_1160:
  %t5038 = getelementptr inbounds i8*, i8** %t5029, i64 %t5033
  %t5039 = load i8*, i8** %t5038
  %t5040 = getelementptr inbounds i32, i32* %t5030, i64 %t5033
  %t5041 = load i32, i32* %t5040
  %t5042 = call i64 @hash_str(i8* %t5039)
  %t5043 = and i64 %t5042, %t5016
  store i64 0, i64* %t5044
  store i64 %t5043, i64* %t5045
  br label %ht_fe_cond_1163
ht_fe_cond_1163:
  %t5046 = load i64, i64* %t5044
  %t5047 = icmp slt i64 %t5046, %t5015
  br i1 %t5047, label %ht_fe_body_1164, label %ht_fe_end_1166
ht_fe_body_1164:
  %t5048 = load i64, i64* %t5045
  %t5049 = getelementptr inbounds i8, i8* %t5023, i64 %t5048
  %t5050 = load i8, i8* %t5049
  %t5051 = icmp eq i8 %t5050, 0
  br i1 %t5051, label %ht_fe_end_1166, label %ht_fe_next_1165
ht_fe_next_1165:
  %t5052 = add i64 %t5048, 1
  %t5053 = and i64 %t5052, %t5016
  store i64 %t5053, i64* %t5045
  %t5054 = add i64 %t5046, 1
  store i64 %t5054, i64* %t5044
  br label %ht_fe_cond_1163
ht_fe_end_1166:
  %t5055 = load i64, i64* %t5045
  %t5056 = getelementptr inbounds i8, i8* %t5023, i64 %t5055
  store i8 1, i8* %t5056
  %t5057 = getelementptr inbounds i8*, i8** %t5019, i64 %t5055
  store i8* %t5039, i8** %t5057
  %t5058 = getelementptr inbounds i32, i32* %t5022, i64 %t5055
  store i32 %t5041, i32* %t5058
  br label %map_grow_next_1161
map_grow_next_1161:
  %t5059 = add i64 %t5033, 1
  store i64 %t5059, i64* %t5032
  br label %map_grow_cond_1158
map_grow_end_1162:
  %t5060 = bitcast i8** %t5029 to i8*
  call void @free(i8* %t5060)
  %t5061 = bitcast i32* %t5030 to i8*
  call void @free(i8* %t5061)
  call void @free(i8* %t5031)
  store i8** %t5019, i8*** %t4988
  store i32* %t5022, i32** %t4990
  store i8* %t5023, i8** %t4992
  store i64 %t5015, i64* %t4996
  store i64 0, i64* %t4998
  br label %map_insert_after_grow_1154
map_insert_after_grow_1154:
  %t5062 = load i8**, i8*** %t4988
  %t5063 = load i32*, i32** %t4990
  %t5064 = load i8*, i8** %t4992
  %t5065 = load i64, i64* %t4996
  %t5066 = sub i64 %t5065, 1
  %t5067 = call i64 @hash_str(i8* %t5000)
  %t5068 = and i64 %t5067, %t5066
  store i64 0, i64* %t5069
  store i64 %t5068, i64* %t5070
  store i1 false, i1* %t5071
  store i64 -1, i64* %t5072
  store i64 -1, i64* %t5073
  store i1 false, i1* %t5074
  br label %ht_probe_cond_1167
ht_probe_cond_1167:
  %t5075 = load i64, i64* %t5069
  %t5076 = icmp slt i64 %t5075, %t5065
  br i1 %t5076, label %ht_probe_body_1168, label %ht_probe_end_1178
ht_probe_body_1168:
  %t5077 = load i64, i64* %t5070
  %t5078 = getelementptr inbounds i8, i8* %t5064, i64 %t5077
  %t5079 = load i8, i8* %t5078
  %t5080 = icmp eq i8 %t5079, 0
  br i1 %t5080, label %ht_probe_on_empty_1170, label %ht_probe_check_occ_1169
ht_probe_check_occ_1169:
  %t5081 = icmp eq i8 %t5079, 1
  br i1 %t5081, label %ht_probe_on_occ_1173, label %ht_probe_on_tomb_1175
ht_probe_on_empty_1170:
  %t5082 = load i1, i1* %t5074
  br i1 %t5082, label %ht_probe_after_islot_empty_1172, label %ht_probe_set_islot_empty_1171
ht_probe_set_islot_empty_1171:
  store i64 %t5077, i64* %t5073
  store i1 true, i1* %t5074
  br label %ht_probe_after_islot_empty_1172
ht_probe_after_islot_empty_1172:
  br label %ht_probe_end_1178
ht_probe_on_occ_1173:
  %t5083 = getelementptr inbounds i8*, i8** %t5062, i64 %t5077
  %t5084 = load i8*, i8** %t5083
  %t5085 = call i1 @eq_str(i8* %t5084, i8* %t5000)
  br i1 %t5085, label %ht_probe_on_match_1174, label %ht_probe_next_1177
ht_probe_on_match_1174:
  store i1 true, i1* %t5071
  store i64 %t5077, i64* %t5072
  br label %ht_probe_end_1178
ht_probe_on_tomb_1175:
  %t5086 = load i1, i1* %t5074
  br i1 %t5086, label %ht_probe_next_1177, label %ht_probe_set_islot_tomb_1176
ht_probe_set_islot_tomb_1176:
  store i64 %t5077, i64* %t5073
  store i1 true, i1* %t5074
  br label %ht_probe_next_1177
ht_probe_next_1177:
  %t5087 = add i64 %t5077, 1
  %t5088 = and i64 %t5087, %t5066
  store i64 %t5088, i64* %t5070
  %t5089 = add i64 %t5075, 1
  store i64 %t5089, i64* %t5069
  br label %ht_probe_cond_1167
ht_probe_end_1178:
  %t5090 = load i1, i1* %t5071
  %t5091 = load i64, i64* %t5072
  %t5092 = load i64, i64* %t5073
  br i1 %t5090, label %map_insert_overwrite_1179, label %map_insert_new_1180
map_insert_overwrite_1179:
  store i8* %t5000, i8** %t5093
  %t5094 = load i8*, i8** %t5093
  call void @star_rc_release(i8* %t5094)
  %t5095 = getelementptr inbounds i32, i32* %t5063, i64 %t5091
  store i32 27, i32* %t5095
  br label %map_insert_after_1181
map_insert_new_1180:
  %t5096 = getelementptr inbounds i8, i8* %t5064, i64 %t5092
  %t5097 = load i8, i8* %t5096
  %t5098 = icmp eq i8 %t5097, 2
  br i1 %t5098, label %map_insert_dec_tomb_1182, label %map_insert_store_1183
map_insert_dec_tomb_1182:
  %t5099 = load i64, i64* %t4998
  %t5100 = sub i64 %t5099, 1
  store i64 %t5100, i64* %t4998
  br label %map_insert_store_1183
map_insert_store_1183:
  store i8 1, i8* %t5096
  %t5101 = getelementptr inbounds i8*, i8** %t5062, i64 %t5092
  store i8* %t5000, i8** %t5101
  %t5102 = getelementptr inbounds i32, i32* %t5063, i64 %t5092
  store i32 27, i32* %t5102
  %t5103 = load i64, i64* %t4994
  %t5104 = add i64 %t5103, 1
  store i64 %t5104, i64* %t4994
  br label %map_insert_after_1181
map_insert_after_1181:
  %t5105 = getelementptr i8*, i8** null, i32 1
  %t5106 = ptrtoint i8** %t5105 to i64
  %t5107 = getelementptr i32, i32* null, i32 1
  %t5108 = ptrtoint i32* %t5107 to i64
  %t5109 = load i8*, i8** %t0
  %t5110 = icmp eq i8* %t5109, null
  br i1 %t5110, label %map_cow_alloc_1184, label %map_cow_check_1185
map_cow_alloc_1184:
  %t5111 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5112 = call i8* @star_rc_alloc(i64 48, i8* %t5111)
  %t5113 = bitcast i8* %t5112 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5114 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5113, i32 0, i32 0
  store i8** null, i8*** %t5114
  %t5115 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5113, i32 0, i32 1
  store i32* null, i32** %t5115
  %t5116 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5113, i32 0, i32 2
  store i8* null, i8** %t5116
  %t5117 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5113, i32 0, i32 3
  store i64 0, i64* %t5117
  %t5118 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5113, i32 0, i32 4
  store i64 0, i64* %t5118
  %t5119 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5113, i32 0, i32 5
  store i64 0, i64* %t5119
  store i8* %t5112, i8** %t0
  br label %map_cow_done_1186
map_cow_check_1185:
  %t5120 = getelementptr inbounds i8, i8* %t5109, i64 -16
  %t5121 = bitcast i8* %t5120 to i64*
  %t5122 = load atomic i64, i64* %t5121 seq_cst, align 8
  %t5123 = icmp eq i64 %t5122, 1
  br i1 %t5123, label %map_cow_done_1186, label %map_cow_clone_1187
map_cow_clone_1187:
  %t5124 = bitcast i8* %t5109 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5125 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5124, i32 0, i32 0
  %t5126 = load i8**, i8*** %t5125
  %t5127 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5124, i32 0, i32 1
  %t5128 = load i32*, i32** %t5127
  %t5129 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5124, i32 0, i32 2
  %t5130 = load i8*, i8** %t5129
  %t5131 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5124, i32 0, i32 3
  %t5132 = load i64, i64* %t5131
  %t5133 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5124, i32 0, i32 4
  %t5134 = load i64, i64* %t5133
  %t5135 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5124, i32 0, i32 5
  %t5136 = load i64, i64* %t5135
  %t5137 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5138 = call i8* @star_rc_alloc(i64 48, i8* %t5137)
  %t5139 = bitcast i8* %t5138 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5140 = mul i64 %t5134, %t5106
  %t5141 = call i8* @malloc(i64 %t5140)
  %t5142 = bitcast i8* %t5141 to i8**
  %t5143 = mul i64 %t5134, %t5108
  %t5144 = call i8* @malloc(i64 %t5143)
  %t5145 = bitcast i8* %t5144 to i32*
  %t5146 = call i8* @malloc(i64 %t5134)
  %t5147 = icmp sgt i64 %t5134, 0
  br i1 %t5147, label %map_cow_copy_1188, label %map_cow_after_copy_1189
map_cow_copy_1188:
  %t5148 = mul i64 %t5134, %t5106
  %t5149 = bitcast i8** %t5126 to i8*
  call i8* @memcpy(i8* %t5141, i8* %t5149, i64 %t5148)
  %t5150 = mul i64 %t5134, %t5108
  %t5151 = bitcast i32* %t5128 to i8*
  call i8* @memcpy(i8* %t5144, i8* %t5151, i64 %t5150)
  call i8* @memcpy(i8* %t5146, i8* %t5130, i64 %t5134)
  store i64 0, i64* %t5152
  br label %map_cow_retain_cond_1190
map_cow_retain_cond_1190:
  %t5153 = load i64, i64* %t5152
  %t5154 = icmp slt i64 %t5153, %t5134
  br i1 %t5154, label %map_cow_retain_body_1191, label %map_cow_retain_end_1194
map_cow_retain_body_1191:
  %t5155 = getelementptr inbounds i8, i8* %t5146, i64 %t5153
  %t5156 = load i8, i8* %t5155
  %t5157 = icmp eq i8 %t5156, 1
  br i1 %t5157, label %map_cow_retain_occ_1192, label %map_cow_retain_next_1193
map_cow_retain_occ_1192:
  %t5158 = getelementptr inbounds i8*, i8** %t5142, i64 %t5153
  %t5159 = load i8*, i8** %t5158
  call void @star_rc_retain(i8* %t5159)
  br label %map_cow_retain_next_1193
map_cow_retain_next_1193:
  %t5160 = add i64 %t5153, 1
  store i64 %t5160, i64* %t5152
  br label %map_cow_retain_cond_1190
map_cow_retain_end_1194:
  br label %map_cow_after_copy_1189
map_cow_after_copy_1189:
  %t5161 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5139, i32 0, i32 0
  store i8** %t5142, i8*** %t5161
  %t5162 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5139, i32 0, i32 1
  store i32* %t5145, i32** %t5162
  %t5163 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5139, i32 0, i32 2
  store i8* %t5146, i8** %t5163
  %t5164 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5139, i32 0, i32 3
  store i64 %t5132, i64* %t5164
  %t5165 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5139, i32 0, i32 4
  store i64 %t5134, i64* %t5165
  %t5166 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5139, i32 0, i32 5
  store i64 %t5136, i64* %t5166
  call void @star_rc_release(i8* %t5109)
  store i8* %t5138, i8** %t0
  br label %map_cow_done_1186
map_cow_done_1186:
  %t5167 = load i8*, i8** %t0
  %t5168 = bitcast i8* %t5167 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5169 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5168, i32 0, i32 0
  %t5170 = load i8**, i8*** %t5169
  %t5171 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5168, i32 0, i32 1
  %t5172 = load i32*, i32** %t5171
  %t5173 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5168, i32 0, i32 2
  %t5174 = load i8*, i8** %t5173
  %t5175 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5168, i32 0, i32 3
  %t5176 = load i64, i64* %t5175
  %t5177 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5168, i32 0, i32 4
  %t5178 = load i64, i64* %t5177
  %t5179 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5168, i32 0, i32 5
  %t5180 = load i64, i64* %t5179
  %t5181 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.28, i64 0, i32 2, i64 0
  %t5182 = load i64, i64* %t5175
  %t5183 = load i64, i64* %t5177
  %t5184 = load i64, i64* %t5179
  %t5185 = add i64 %t5182, %t5184
  %t5186 = add i64 %t5185, 1
  %t5187 = mul i64 %t5186, 4
  %t5188 = mul i64 %t5183, 3
  %t5189 = icmp sgt i64 %t5187, %t5188
  br i1 %t5189, label %map_insert_grow_1195, label %map_insert_after_grow_1196
map_insert_grow_1195:
  %t5190 = getelementptr i8*, i8** null, i32 1
  %t5191 = ptrtoint i8** %t5190 to i64
  %t5192 = getelementptr i32, i32* null, i32 1
  %t5193 = ptrtoint i32* %t5192 to i64
  %t5194 = mul i64 %t5183, 2
  %t5195 = icmp sgt i64 %t5194, 0
  %t5196 = select i1 %t5195, i64 %t5194, i64 8
  %t5197 = sub i64 %t5196, 1
  %t5198 = mul i64 %t5196, %t5191
  %t5199 = call i8* @malloc(i64 %t5198)
  %t5200 = bitcast i8* %t5199 to i8**
  %t5201 = mul i64 %t5196, %t5193
  %t5202 = call i8* @malloc(i64 %t5201)
  %t5203 = bitcast i8* %t5202 to i32*
  %t5204 = call i8* @malloc(i64 %t5196)
  store i64 0, i64* %t5205
  br label %ht_fill8_cond_1197
ht_fill8_cond_1197:
  %t5206 = load i64, i64* %t5205
  %t5207 = icmp slt i64 %t5206, %t5196
  br i1 %t5207, label %ht_fill8_body_1198, label %ht_fill8_end_1199
ht_fill8_body_1198:
  %t5208 = getelementptr inbounds i8, i8* %t5204, i64 %t5206
  store i8 0, i8* %t5208
  %t5209 = add i64 %t5206, 1
  store i64 %t5209, i64* %t5205
  br label %ht_fill8_cond_1197
ht_fill8_end_1199:
  %t5210 = load i8**, i8*** %t5169
  %t5211 = load i32*, i32** %t5171
  %t5212 = load i8*, i8** %t5173
  store i64 0, i64* %t5213
  br label %map_grow_cond_1200
map_grow_cond_1200:
  %t5214 = load i64, i64* %t5213
  %t5215 = icmp slt i64 %t5214, %t5183
  br i1 %t5215, label %map_grow_body_1201, label %map_grow_end_1204
map_grow_body_1201:
  %t5216 = getelementptr inbounds i8, i8* %t5212, i64 %t5214
  %t5217 = load i8, i8* %t5216
  %t5218 = icmp eq i8 %t5217, 1
  br i1 %t5218, label %map_grow_occ_1202, label %map_grow_next_1203
map_grow_occ_1202:
  %t5219 = getelementptr inbounds i8*, i8** %t5210, i64 %t5214
  %t5220 = load i8*, i8** %t5219
  %t5221 = getelementptr inbounds i32, i32* %t5211, i64 %t5214
  %t5222 = load i32, i32* %t5221
  %t5223 = call i64 @hash_str(i8* %t5220)
  %t5224 = and i64 %t5223, %t5197
  store i64 0, i64* %t5225
  store i64 %t5224, i64* %t5226
  br label %ht_fe_cond_1205
ht_fe_cond_1205:
  %t5227 = load i64, i64* %t5225
  %t5228 = icmp slt i64 %t5227, %t5196
  br i1 %t5228, label %ht_fe_body_1206, label %ht_fe_end_1208
ht_fe_body_1206:
  %t5229 = load i64, i64* %t5226
  %t5230 = getelementptr inbounds i8, i8* %t5204, i64 %t5229
  %t5231 = load i8, i8* %t5230
  %t5232 = icmp eq i8 %t5231, 0
  br i1 %t5232, label %ht_fe_end_1208, label %ht_fe_next_1207
ht_fe_next_1207:
  %t5233 = add i64 %t5229, 1
  %t5234 = and i64 %t5233, %t5197
  store i64 %t5234, i64* %t5226
  %t5235 = add i64 %t5227, 1
  store i64 %t5235, i64* %t5225
  br label %ht_fe_cond_1205
ht_fe_end_1208:
  %t5236 = load i64, i64* %t5226
  %t5237 = getelementptr inbounds i8, i8* %t5204, i64 %t5236
  store i8 1, i8* %t5237
  %t5238 = getelementptr inbounds i8*, i8** %t5200, i64 %t5236
  store i8* %t5220, i8** %t5238
  %t5239 = getelementptr inbounds i32, i32* %t5203, i64 %t5236
  store i32 %t5222, i32* %t5239
  br label %map_grow_next_1203
map_grow_next_1203:
  %t5240 = add i64 %t5214, 1
  store i64 %t5240, i64* %t5213
  br label %map_grow_cond_1200
map_grow_end_1204:
  %t5241 = bitcast i8** %t5210 to i8*
  call void @free(i8* %t5241)
  %t5242 = bitcast i32* %t5211 to i8*
  call void @free(i8* %t5242)
  call void @free(i8* %t5212)
  store i8** %t5200, i8*** %t5169
  store i32* %t5203, i32** %t5171
  store i8* %t5204, i8** %t5173
  store i64 %t5196, i64* %t5177
  store i64 0, i64* %t5179
  br label %map_insert_after_grow_1196
map_insert_after_grow_1196:
  %t5243 = load i8**, i8*** %t5169
  %t5244 = load i32*, i32** %t5171
  %t5245 = load i8*, i8** %t5173
  %t5246 = load i64, i64* %t5177
  %t5247 = sub i64 %t5246, 1
  %t5248 = call i64 @hash_str(i8* %t5181)
  %t5249 = and i64 %t5248, %t5247
  store i64 0, i64* %t5250
  store i64 %t5249, i64* %t5251
  store i1 false, i1* %t5252
  store i64 -1, i64* %t5253
  store i64 -1, i64* %t5254
  store i1 false, i1* %t5255
  br label %ht_probe_cond_1209
ht_probe_cond_1209:
  %t5256 = load i64, i64* %t5250
  %t5257 = icmp slt i64 %t5256, %t5246
  br i1 %t5257, label %ht_probe_body_1210, label %ht_probe_end_1220
ht_probe_body_1210:
  %t5258 = load i64, i64* %t5251
  %t5259 = getelementptr inbounds i8, i8* %t5245, i64 %t5258
  %t5260 = load i8, i8* %t5259
  %t5261 = icmp eq i8 %t5260, 0
  br i1 %t5261, label %ht_probe_on_empty_1212, label %ht_probe_check_occ_1211
ht_probe_check_occ_1211:
  %t5262 = icmp eq i8 %t5260, 1
  br i1 %t5262, label %ht_probe_on_occ_1215, label %ht_probe_on_tomb_1217
ht_probe_on_empty_1212:
  %t5263 = load i1, i1* %t5255
  br i1 %t5263, label %ht_probe_after_islot_empty_1214, label %ht_probe_set_islot_empty_1213
ht_probe_set_islot_empty_1213:
  store i64 %t5258, i64* %t5254
  store i1 true, i1* %t5255
  br label %ht_probe_after_islot_empty_1214
ht_probe_after_islot_empty_1214:
  br label %ht_probe_end_1220
ht_probe_on_occ_1215:
  %t5264 = getelementptr inbounds i8*, i8** %t5243, i64 %t5258
  %t5265 = load i8*, i8** %t5264
  %t5266 = call i1 @eq_str(i8* %t5265, i8* %t5181)
  br i1 %t5266, label %ht_probe_on_match_1216, label %ht_probe_next_1219
ht_probe_on_match_1216:
  store i1 true, i1* %t5252
  store i64 %t5258, i64* %t5253
  br label %ht_probe_end_1220
ht_probe_on_tomb_1217:
  %t5267 = load i1, i1* %t5255
  br i1 %t5267, label %ht_probe_next_1219, label %ht_probe_set_islot_tomb_1218
ht_probe_set_islot_tomb_1218:
  store i64 %t5258, i64* %t5254
  store i1 true, i1* %t5255
  br label %ht_probe_next_1219
ht_probe_next_1219:
  %t5268 = add i64 %t5258, 1
  %t5269 = and i64 %t5268, %t5247
  store i64 %t5269, i64* %t5251
  %t5270 = add i64 %t5256, 1
  store i64 %t5270, i64* %t5250
  br label %ht_probe_cond_1209
ht_probe_end_1220:
  %t5271 = load i1, i1* %t5252
  %t5272 = load i64, i64* %t5253
  %t5273 = load i64, i64* %t5254
  br i1 %t5271, label %map_insert_overwrite_1221, label %map_insert_new_1222
map_insert_overwrite_1221:
  store i8* %t5181, i8** %t5274
  %t5275 = load i8*, i8** %t5274
  call void @star_rc_release(i8* %t5275)
  %t5276 = getelementptr inbounds i32, i32* %t5244, i64 %t5272
  store i32 28, i32* %t5276
  br label %map_insert_after_1223
map_insert_new_1222:
  %t5277 = getelementptr inbounds i8, i8* %t5245, i64 %t5273
  %t5278 = load i8, i8* %t5277
  %t5279 = icmp eq i8 %t5278, 2
  br i1 %t5279, label %map_insert_dec_tomb_1224, label %map_insert_store_1225
map_insert_dec_tomb_1224:
  %t5280 = load i64, i64* %t5179
  %t5281 = sub i64 %t5280, 1
  store i64 %t5281, i64* %t5179
  br label %map_insert_store_1225
map_insert_store_1225:
  store i8 1, i8* %t5277
  %t5282 = getelementptr inbounds i8*, i8** %t5243, i64 %t5273
  store i8* %t5181, i8** %t5282
  %t5283 = getelementptr inbounds i32, i32* %t5244, i64 %t5273
  store i32 28, i32* %t5283
  %t5284 = load i64, i64* %t5175
  %t5285 = add i64 %t5284, 1
  store i64 %t5285, i64* %t5175
  br label %map_insert_after_1223
map_insert_after_1223:
  %t5286 = getelementptr i8*, i8** null, i32 1
  %t5287 = ptrtoint i8** %t5286 to i64
  %t5288 = getelementptr i32, i32* null, i32 1
  %t5289 = ptrtoint i32* %t5288 to i64
  %t5290 = load i8*, i8** %t0
  %t5291 = icmp eq i8* %t5290, null
  br i1 %t5291, label %map_cow_alloc_1226, label %map_cow_check_1227
map_cow_alloc_1226:
  %t5292 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5293 = call i8* @star_rc_alloc(i64 48, i8* %t5292)
  %t5294 = bitcast i8* %t5293 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5295 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5294, i32 0, i32 0
  store i8** null, i8*** %t5295
  %t5296 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5294, i32 0, i32 1
  store i32* null, i32** %t5296
  %t5297 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5294, i32 0, i32 2
  store i8* null, i8** %t5297
  %t5298 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5294, i32 0, i32 3
  store i64 0, i64* %t5298
  %t5299 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5294, i32 0, i32 4
  store i64 0, i64* %t5299
  %t5300 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5294, i32 0, i32 5
  store i64 0, i64* %t5300
  store i8* %t5293, i8** %t0
  br label %map_cow_done_1228
map_cow_check_1227:
  %t5301 = getelementptr inbounds i8, i8* %t5290, i64 -16
  %t5302 = bitcast i8* %t5301 to i64*
  %t5303 = load atomic i64, i64* %t5302 seq_cst, align 8
  %t5304 = icmp eq i64 %t5303, 1
  br i1 %t5304, label %map_cow_done_1228, label %map_cow_clone_1229
map_cow_clone_1229:
  %t5305 = bitcast i8* %t5290 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5306 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5305, i32 0, i32 0
  %t5307 = load i8**, i8*** %t5306
  %t5308 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5305, i32 0, i32 1
  %t5309 = load i32*, i32** %t5308
  %t5310 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5305, i32 0, i32 2
  %t5311 = load i8*, i8** %t5310
  %t5312 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5305, i32 0, i32 3
  %t5313 = load i64, i64* %t5312
  %t5314 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5305, i32 0, i32 4
  %t5315 = load i64, i64* %t5314
  %t5316 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5305, i32 0, i32 5
  %t5317 = load i64, i64* %t5316
  %t5318 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5319 = call i8* @star_rc_alloc(i64 48, i8* %t5318)
  %t5320 = bitcast i8* %t5319 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5321 = mul i64 %t5315, %t5287
  %t5322 = call i8* @malloc(i64 %t5321)
  %t5323 = bitcast i8* %t5322 to i8**
  %t5324 = mul i64 %t5315, %t5289
  %t5325 = call i8* @malloc(i64 %t5324)
  %t5326 = bitcast i8* %t5325 to i32*
  %t5327 = call i8* @malloc(i64 %t5315)
  %t5328 = icmp sgt i64 %t5315, 0
  br i1 %t5328, label %map_cow_copy_1230, label %map_cow_after_copy_1231
map_cow_copy_1230:
  %t5329 = mul i64 %t5315, %t5287
  %t5330 = bitcast i8** %t5307 to i8*
  call i8* @memcpy(i8* %t5322, i8* %t5330, i64 %t5329)
  %t5331 = mul i64 %t5315, %t5289
  %t5332 = bitcast i32* %t5309 to i8*
  call i8* @memcpy(i8* %t5325, i8* %t5332, i64 %t5331)
  call i8* @memcpy(i8* %t5327, i8* %t5311, i64 %t5315)
  store i64 0, i64* %t5333
  br label %map_cow_retain_cond_1232
map_cow_retain_cond_1232:
  %t5334 = load i64, i64* %t5333
  %t5335 = icmp slt i64 %t5334, %t5315
  br i1 %t5335, label %map_cow_retain_body_1233, label %map_cow_retain_end_1236
map_cow_retain_body_1233:
  %t5336 = getelementptr inbounds i8, i8* %t5327, i64 %t5334
  %t5337 = load i8, i8* %t5336
  %t5338 = icmp eq i8 %t5337, 1
  br i1 %t5338, label %map_cow_retain_occ_1234, label %map_cow_retain_next_1235
map_cow_retain_occ_1234:
  %t5339 = getelementptr inbounds i8*, i8** %t5323, i64 %t5334
  %t5340 = load i8*, i8** %t5339
  call void @star_rc_retain(i8* %t5340)
  br label %map_cow_retain_next_1235
map_cow_retain_next_1235:
  %t5341 = add i64 %t5334, 1
  store i64 %t5341, i64* %t5333
  br label %map_cow_retain_cond_1232
map_cow_retain_end_1236:
  br label %map_cow_after_copy_1231
map_cow_after_copy_1231:
  %t5342 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5320, i32 0, i32 0
  store i8** %t5323, i8*** %t5342
  %t5343 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5320, i32 0, i32 1
  store i32* %t5326, i32** %t5343
  %t5344 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5320, i32 0, i32 2
  store i8* %t5327, i8** %t5344
  %t5345 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5320, i32 0, i32 3
  store i64 %t5313, i64* %t5345
  %t5346 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5320, i32 0, i32 4
  store i64 %t5315, i64* %t5346
  %t5347 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5320, i32 0, i32 5
  store i64 %t5317, i64* %t5347
  call void @star_rc_release(i8* %t5290)
  store i8* %t5319, i8** %t0
  br label %map_cow_done_1228
map_cow_done_1228:
  %t5348 = load i8*, i8** %t0
  %t5349 = bitcast i8* %t5348 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5350 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5349, i32 0, i32 0
  %t5351 = load i8**, i8*** %t5350
  %t5352 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5349, i32 0, i32 1
  %t5353 = load i32*, i32** %t5352
  %t5354 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5349, i32 0, i32 2
  %t5355 = load i8*, i8** %t5354
  %t5356 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5349, i32 0, i32 3
  %t5357 = load i64, i64* %t5356
  %t5358 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5349, i32 0, i32 4
  %t5359 = load i64, i64* %t5358
  %t5360 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5349, i32 0, i32 5
  %t5361 = load i64, i64* %t5360
  %t5362 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.29, i64 0, i32 2, i64 0
  %t5363 = load i64, i64* %t5356
  %t5364 = load i64, i64* %t5358
  %t5365 = load i64, i64* %t5360
  %t5366 = add i64 %t5363, %t5365
  %t5367 = add i64 %t5366, 1
  %t5368 = mul i64 %t5367, 4
  %t5369 = mul i64 %t5364, 3
  %t5370 = icmp sgt i64 %t5368, %t5369
  br i1 %t5370, label %map_insert_grow_1237, label %map_insert_after_grow_1238
map_insert_grow_1237:
  %t5371 = getelementptr i8*, i8** null, i32 1
  %t5372 = ptrtoint i8** %t5371 to i64
  %t5373 = getelementptr i32, i32* null, i32 1
  %t5374 = ptrtoint i32* %t5373 to i64
  %t5375 = mul i64 %t5364, 2
  %t5376 = icmp sgt i64 %t5375, 0
  %t5377 = select i1 %t5376, i64 %t5375, i64 8
  %t5378 = sub i64 %t5377, 1
  %t5379 = mul i64 %t5377, %t5372
  %t5380 = call i8* @malloc(i64 %t5379)
  %t5381 = bitcast i8* %t5380 to i8**
  %t5382 = mul i64 %t5377, %t5374
  %t5383 = call i8* @malloc(i64 %t5382)
  %t5384 = bitcast i8* %t5383 to i32*
  %t5385 = call i8* @malloc(i64 %t5377)
  store i64 0, i64* %t5386
  br label %ht_fill8_cond_1239
ht_fill8_cond_1239:
  %t5387 = load i64, i64* %t5386
  %t5388 = icmp slt i64 %t5387, %t5377
  br i1 %t5388, label %ht_fill8_body_1240, label %ht_fill8_end_1241
ht_fill8_body_1240:
  %t5389 = getelementptr inbounds i8, i8* %t5385, i64 %t5387
  store i8 0, i8* %t5389
  %t5390 = add i64 %t5387, 1
  store i64 %t5390, i64* %t5386
  br label %ht_fill8_cond_1239
ht_fill8_end_1241:
  %t5391 = load i8**, i8*** %t5350
  %t5392 = load i32*, i32** %t5352
  %t5393 = load i8*, i8** %t5354
  store i64 0, i64* %t5394
  br label %map_grow_cond_1242
map_grow_cond_1242:
  %t5395 = load i64, i64* %t5394
  %t5396 = icmp slt i64 %t5395, %t5364
  br i1 %t5396, label %map_grow_body_1243, label %map_grow_end_1246
map_grow_body_1243:
  %t5397 = getelementptr inbounds i8, i8* %t5393, i64 %t5395
  %t5398 = load i8, i8* %t5397
  %t5399 = icmp eq i8 %t5398, 1
  br i1 %t5399, label %map_grow_occ_1244, label %map_grow_next_1245
map_grow_occ_1244:
  %t5400 = getelementptr inbounds i8*, i8** %t5391, i64 %t5395
  %t5401 = load i8*, i8** %t5400
  %t5402 = getelementptr inbounds i32, i32* %t5392, i64 %t5395
  %t5403 = load i32, i32* %t5402
  %t5404 = call i64 @hash_str(i8* %t5401)
  %t5405 = and i64 %t5404, %t5378
  store i64 0, i64* %t5406
  store i64 %t5405, i64* %t5407
  br label %ht_fe_cond_1247
ht_fe_cond_1247:
  %t5408 = load i64, i64* %t5406
  %t5409 = icmp slt i64 %t5408, %t5377
  br i1 %t5409, label %ht_fe_body_1248, label %ht_fe_end_1250
ht_fe_body_1248:
  %t5410 = load i64, i64* %t5407
  %t5411 = getelementptr inbounds i8, i8* %t5385, i64 %t5410
  %t5412 = load i8, i8* %t5411
  %t5413 = icmp eq i8 %t5412, 0
  br i1 %t5413, label %ht_fe_end_1250, label %ht_fe_next_1249
ht_fe_next_1249:
  %t5414 = add i64 %t5410, 1
  %t5415 = and i64 %t5414, %t5378
  store i64 %t5415, i64* %t5407
  %t5416 = add i64 %t5408, 1
  store i64 %t5416, i64* %t5406
  br label %ht_fe_cond_1247
ht_fe_end_1250:
  %t5417 = load i64, i64* %t5407
  %t5418 = getelementptr inbounds i8, i8* %t5385, i64 %t5417
  store i8 1, i8* %t5418
  %t5419 = getelementptr inbounds i8*, i8** %t5381, i64 %t5417
  store i8* %t5401, i8** %t5419
  %t5420 = getelementptr inbounds i32, i32* %t5384, i64 %t5417
  store i32 %t5403, i32* %t5420
  br label %map_grow_next_1245
map_grow_next_1245:
  %t5421 = add i64 %t5395, 1
  store i64 %t5421, i64* %t5394
  br label %map_grow_cond_1242
map_grow_end_1246:
  %t5422 = bitcast i8** %t5391 to i8*
  call void @free(i8* %t5422)
  %t5423 = bitcast i32* %t5392 to i8*
  call void @free(i8* %t5423)
  call void @free(i8* %t5393)
  store i8** %t5381, i8*** %t5350
  store i32* %t5384, i32** %t5352
  store i8* %t5385, i8** %t5354
  store i64 %t5377, i64* %t5358
  store i64 0, i64* %t5360
  br label %map_insert_after_grow_1238
map_insert_after_grow_1238:
  %t5424 = load i8**, i8*** %t5350
  %t5425 = load i32*, i32** %t5352
  %t5426 = load i8*, i8** %t5354
  %t5427 = load i64, i64* %t5358
  %t5428 = sub i64 %t5427, 1
  %t5429 = call i64 @hash_str(i8* %t5362)
  %t5430 = and i64 %t5429, %t5428
  store i64 0, i64* %t5431
  store i64 %t5430, i64* %t5432
  store i1 false, i1* %t5433
  store i64 -1, i64* %t5434
  store i64 -1, i64* %t5435
  store i1 false, i1* %t5436
  br label %ht_probe_cond_1251
ht_probe_cond_1251:
  %t5437 = load i64, i64* %t5431
  %t5438 = icmp slt i64 %t5437, %t5427
  br i1 %t5438, label %ht_probe_body_1252, label %ht_probe_end_1262
ht_probe_body_1252:
  %t5439 = load i64, i64* %t5432
  %t5440 = getelementptr inbounds i8, i8* %t5426, i64 %t5439
  %t5441 = load i8, i8* %t5440
  %t5442 = icmp eq i8 %t5441, 0
  br i1 %t5442, label %ht_probe_on_empty_1254, label %ht_probe_check_occ_1253
ht_probe_check_occ_1253:
  %t5443 = icmp eq i8 %t5441, 1
  br i1 %t5443, label %ht_probe_on_occ_1257, label %ht_probe_on_tomb_1259
ht_probe_on_empty_1254:
  %t5444 = load i1, i1* %t5436
  br i1 %t5444, label %ht_probe_after_islot_empty_1256, label %ht_probe_set_islot_empty_1255
ht_probe_set_islot_empty_1255:
  store i64 %t5439, i64* %t5435
  store i1 true, i1* %t5436
  br label %ht_probe_after_islot_empty_1256
ht_probe_after_islot_empty_1256:
  br label %ht_probe_end_1262
ht_probe_on_occ_1257:
  %t5445 = getelementptr inbounds i8*, i8** %t5424, i64 %t5439
  %t5446 = load i8*, i8** %t5445
  %t5447 = call i1 @eq_str(i8* %t5446, i8* %t5362)
  br i1 %t5447, label %ht_probe_on_match_1258, label %ht_probe_next_1261
ht_probe_on_match_1258:
  store i1 true, i1* %t5433
  store i64 %t5439, i64* %t5434
  br label %ht_probe_end_1262
ht_probe_on_tomb_1259:
  %t5448 = load i1, i1* %t5436
  br i1 %t5448, label %ht_probe_next_1261, label %ht_probe_set_islot_tomb_1260
ht_probe_set_islot_tomb_1260:
  store i64 %t5439, i64* %t5435
  store i1 true, i1* %t5436
  br label %ht_probe_next_1261
ht_probe_next_1261:
  %t5449 = add i64 %t5439, 1
  %t5450 = and i64 %t5449, %t5428
  store i64 %t5450, i64* %t5432
  %t5451 = add i64 %t5437, 1
  store i64 %t5451, i64* %t5431
  br label %ht_probe_cond_1251
ht_probe_end_1262:
  %t5452 = load i1, i1* %t5433
  %t5453 = load i64, i64* %t5434
  %t5454 = load i64, i64* %t5435
  br i1 %t5452, label %map_insert_overwrite_1263, label %map_insert_new_1264
map_insert_overwrite_1263:
  store i8* %t5362, i8** %t5455
  %t5456 = load i8*, i8** %t5455
  call void @star_rc_release(i8* %t5456)
  %t5457 = getelementptr inbounds i32, i32* %t5425, i64 %t5453
  store i32 29, i32* %t5457
  br label %map_insert_after_1265
map_insert_new_1264:
  %t5458 = getelementptr inbounds i8, i8* %t5426, i64 %t5454
  %t5459 = load i8, i8* %t5458
  %t5460 = icmp eq i8 %t5459, 2
  br i1 %t5460, label %map_insert_dec_tomb_1266, label %map_insert_store_1267
map_insert_dec_tomb_1266:
  %t5461 = load i64, i64* %t5360
  %t5462 = sub i64 %t5461, 1
  store i64 %t5462, i64* %t5360
  br label %map_insert_store_1267
map_insert_store_1267:
  store i8 1, i8* %t5458
  %t5463 = getelementptr inbounds i8*, i8** %t5424, i64 %t5454
  store i8* %t5362, i8** %t5463
  %t5464 = getelementptr inbounds i32, i32* %t5425, i64 %t5454
  store i32 29, i32* %t5464
  %t5465 = load i64, i64* %t5356
  %t5466 = add i64 %t5465, 1
  store i64 %t5466, i64* %t5356
  br label %map_insert_after_1265
map_insert_after_1265:
  %t5467 = getelementptr i8*, i8** null, i32 1
  %t5468 = ptrtoint i8** %t5467 to i64
  %t5469 = getelementptr i32, i32* null, i32 1
  %t5470 = ptrtoint i32* %t5469 to i64
  %t5471 = load i8*, i8** %t0
  %t5472 = icmp eq i8* %t5471, null
  br i1 %t5472, label %map_cow_alloc_1268, label %map_cow_check_1269
map_cow_alloc_1268:
  %t5473 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5474 = call i8* @star_rc_alloc(i64 48, i8* %t5473)
  %t5475 = bitcast i8* %t5474 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5476 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5475, i32 0, i32 0
  store i8** null, i8*** %t5476
  %t5477 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5475, i32 0, i32 1
  store i32* null, i32** %t5477
  %t5478 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5475, i32 0, i32 2
  store i8* null, i8** %t5478
  %t5479 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5475, i32 0, i32 3
  store i64 0, i64* %t5479
  %t5480 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5475, i32 0, i32 4
  store i64 0, i64* %t5480
  %t5481 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5475, i32 0, i32 5
  store i64 0, i64* %t5481
  store i8* %t5474, i8** %t0
  br label %map_cow_done_1270
map_cow_check_1269:
  %t5482 = getelementptr inbounds i8, i8* %t5471, i64 -16
  %t5483 = bitcast i8* %t5482 to i64*
  %t5484 = load atomic i64, i64* %t5483 seq_cst, align 8
  %t5485 = icmp eq i64 %t5484, 1
  br i1 %t5485, label %map_cow_done_1270, label %map_cow_clone_1271
map_cow_clone_1271:
  %t5486 = bitcast i8* %t5471 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5487 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5486, i32 0, i32 0
  %t5488 = load i8**, i8*** %t5487
  %t5489 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5486, i32 0, i32 1
  %t5490 = load i32*, i32** %t5489
  %t5491 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5486, i32 0, i32 2
  %t5492 = load i8*, i8** %t5491
  %t5493 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5486, i32 0, i32 3
  %t5494 = load i64, i64* %t5493
  %t5495 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5486, i32 0, i32 4
  %t5496 = load i64, i64* %t5495
  %t5497 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5486, i32 0, i32 5
  %t5498 = load i64, i64* %t5497
  %t5499 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5500 = call i8* @star_rc_alloc(i64 48, i8* %t5499)
  %t5501 = bitcast i8* %t5500 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5502 = mul i64 %t5496, %t5468
  %t5503 = call i8* @malloc(i64 %t5502)
  %t5504 = bitcast i8* %t5503 to i8**
  %t5505 = mul i64 %t5496, %t5470
  %t5506 = call i8* @malloc(i64 %t5505)
  %t5507 = bitcast i8* %t5506 to i32*
  %t5508 = call i8* @malloc(i64 %t5496)
  %t5509 = icmp sgt i64 %t5496, 0
  br i1 %t5509, label %map_cow_copy_1272, label %map_cow_after_copy_1273
map_cow_copy_1272:
  %t5510 = mul i64 %t5496, %t5468
  %t5511 = bitcast i8** %t5488 to i8*
  call i8* @memcpy(i8* %t5503, i8* %t5511, i64 %t5510)
  %t5512 = mul i64 %t5496, %t5470
  %t5513 = bitcast i32* %t5490 to i8*
  call i8* @memcpy(i8* %t5506, i8* %t5513, i64 %t5512)
  call i8* @memcpy(i8* %t5508, i8* %t5492, i64 %t5496)
  store i64 0, i64* %t5514
  br label %map_cow_retain_cond_1274
map_cow_retain_cond_1274:
  %t5515 = load i64, i64* %t5514
  %t5516 = icmp slt i64 %t5515, %t5496
  br i1 %t5516, label %map_cow_retain_body_1275, label %map_cow_retain_end_1278
map_cow_retain_body_1275:
  %t5517 = getelementptr inbounds i8, i8* %t5508, i64 %t5515
  %t5518 = load i8, i8* %t5517
  %t5519 = icmp eq i8 %t5518, 1
  br i1 %t5519, label %map_cow_retain_occ_1276, label %map_cow_retain_next_1277
map_cow_retain_occ_1276:
  %t5520 = getelementptr inbounds i8*, i8** %t5504, i64 %t5515
  %t5521 = load i8*, i8** %t5520
  call void @star_rc_retain(i8* %t5521)
  br label %map_cow_retain_next_1277
map_cow_retain_next_1277:
  %t5522 = add i64 %t5515, 1
  store i64 %t5522, i64* %t5514
  br label %map_cow_retain_cond_1274
map_cow_retain_end_1278:
  br label %map_cow_after_copy_1273
map_cow_after_copy_1273:
  %t5523 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5501, i32 0, i32 0
  store i8** %t5504, i8*** %t5523
  %t5524 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5501, i32 0, i32 1
  store i32* %t5507, i32** %t5524
  %t5525 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5501, i32 0, i32 2
  store i8* %t5508, i8** %t5525
  %t5526 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5501, i32 0, i32 3
  store i64 %t5494, i64* %t5526
  %t5527 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5501, i32 0, i32 4
  store i64 %t5496, i64* %t5527
  %t5528 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5501, i32 0, i32 5
  store i64 %t5498, i64* %t5528
  call void @star_rc_release(i8* %t5471)
  store i8* %t5500, i8** %t0
  br label %map_cow_done_1270
map_cow_done_1270:
  %t5529 = load i8*, i8** %t0
  %t5530 = bitcast i8* %t5529 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5531 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5530, i32 0, i32 0
  %t5532 = load i8**, i8*** %t5531
  %t5533 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5530, i32 0, i32 1
  %t5534 = load i32*, i32** %t5533
  %t5535 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5530, i32 0, i32 2
  %t5536 = load i8*, i8** %t5535
  %t5537 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5530, i32 0, i32 3
  %t5538 = load i64, i64* %t5537
  %t5539 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5530, i32 0, i32 4
  %t5540 = load i64, i64* %t5539
  %t5541 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5530, i32 0, i32 5
  %t5542 = load i64, i64* %t5541
  %t5543 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.30, i64 0, i32 2, i64 0
  %t5544 = load i64, i64* %t5537
  %t5545 = load i64, i64* %t5539
  %t5546 = load i64, i64* %t5541
  %t5547 = add i64 %t5544, %t5546
  %t5548 = add i64 %t5547, 1
  %t5549 = mul i64 %t5548, 4
  %t5550 = mul i64 %t5545, 3
  %t5551 = icmp sgt i64 %t5549, %t5550
  br i1 %t5551, label %map_insert_grow_1279, label %map_insert_after_grow_1280
map_insert_grow_1279:
  %t5552 = getelementptr i8*, i8** null, i32 1
  %t5553 = ptrtoint i8** %t5552 to i64
  %t5554 = getelementptr i32, i32* null, i32 1
  %t5555 = ptrtoint i32* %t5554 to i64
  %t5556 = mul i64 %t5545, 2
  %t5557 = icmp sgt i64 %t5556, 0
  %t5558 = select i1 %t5557, i64 %t5556, i64 8
  %t5559 = sub i64 %t5558, 1
  %t5560 = mul i64 %t5558, %t5553
  %t5561 = call i8* @malloc(i64 %t5560)
  %t5562 = bitcast i8* %t5561 to i8**
  %t5563 = mul i64 %t5558, %t5555
  %t5564 = call i8* @malloc(i64 %t5563)
  %t5565 = bitcast i8* %t5564 to i32*
  %t5566 = call i8* @malloc(i64 %t5558)
  store i64 0, i64* %t5567
  br label %ht_fill8_cond_1281
ht_fill8_cond_1281:
  %t5568 = load i64, i64* %t5567
  %t5569 = icmp slt i64 %t5568, %t5558
  br i1 %t5569, label %ht_fill8_body_1282, label %ht_fill8_end_1283
ht_fill8_body_1282:
  %t5570 = getelementptr inbounds i8, i8* %t5566, i64 %t5568
  store i8 0, i8* %t5570
  %t5571 = add i64 %t5568, 1
  store i64 %t5571, i64* %t5567
  br label %ht_fill8_cond_1281
ht_fill8_end_1283:
  %t5572 = load i8**, i8*** %t5531
  %t5573 = load i32*, i32** %t5533
  %t5574 = load i8*, i8** %t5535
  store i64 0, i64* %t5575
  br label %map_grow_cond_1284
map_grow_cond_1284:
  %t5576 = load i64, i64* %t5575
  %t5577 = icmp slt i64 %t5576, %t5545
  br i1 %t5577, label %map_grow_body_1285, label %map_grow_end_1288
map_grow_body_1285:
  %t5578 = getelementptr inbounds i8, i8* %t5574, i64 %t5576
  %t5579 = load i8, i8* %t5578
  %t5580 = icmp eq i8 %t5579, 1
  br i1 %t5580, label %map_grow_occ_1286, label %map_grow_next_1287
map_grow_occ_1286:
  %t5581 = getelementptr inbounds i8*, i8** %t5572, i64 %t5576
  %t5582 = load i8*, i8** %t5581
  %t5583 = getelementptr inbounds i32, i32* %t5573, i64 %t5576
  %t5584 = load i32, i32* %t5583
  %t5585 = call i64 @hash_str(i8* %t5582)
  %t5586 = and i64 %t5585, %t5559
  store i64 0, i64* %t5587
  store i64 %t5586, i64* %t5588
  br label %ht_fe_cond_1289
ht_fe_cond_1289:
  %t5589 = load i64, i64* %t5587
  %t5590 = icmp slt i64 %t5589, %t5558
  br i1 %t5590, label %ht_fe_body_1290, label %ht_fe_end_1292
ht_fe_body_1290:
  %t5591 = load i64, i64* %t5588
  %t5592 = getelementptr inbounds i8, i8* %t5566, i64 %t5591
  %t5593 = load i8, i8* %t5592
  %t5594 = icmp eq i8 %t5593, 0
  br i1 %t5594, label %ht_fe_end_1292, label %ht_fe_next_1291
ht_fe_next_1291:
  %t5595 = add i64 %t5591, 1
  %t5596 = and i64 %t5595, %t5559
  store i64 %t5596, i64* %t5588
  %t5597 = add i64 %t5589, 1
  store i64 %t5597, i64* %t5587
  br label %ht_fe_cond_1289
ht_fe_end_1292:
  %t5598 = load i64, i64* %t5588
  %t5599 = getelementptr inbounds i8, i8* %t5566, i64 %t5598
  store i8 1, i8* %t5599
  %t5600 = getelementptr inbounds i8*, i8** %t5562, i64 %t5598
  store i8* %t5582, i8** %t5600
  %t5601 = getelementptr inbounds i32, i32* %t5565, i64 %t5598
  store i32 %t5584, i32* %t5601
  br label %map_grow_next_1287
map_grow_next_1287:
  %t5602 = add i64 %t5576, 1
  store i64 %t5602, i64* %t5575
  br label %map_grow_cond_1284
map_grow_end_1288:
  %t5603 = bitcast i8** %t5572 to i8*
  call void @free(i8* %t5603)
  %t5604 = bitcast i32* %t5573 to i8*
  call void @free(i8* %t5604)
  call void @free(i8* %t5574)
  store i8** %t5562, i8*** %t5531
  store i32* %t5565, i32** %t5533
  store i8* %t5566, i8** %t5535
  store i64 %t5558, i64* %t5539
  store i64 0, i64* %t5541
  br label %map_insert_after_grow_1280
map_insert_after_grow_1280:
  %t5605 = load i8**, i8*** %t5531
  %t5606 = load i32*, i32** %t5533
  %t5607 = load i8*, i8** %t5535
  %t5608 = load i64, i64* %t5539
  %t5609 = sub i64 %t5608, 1
  %t5610 = call i64 @hash_str(i8* %t5543)
  %t5611 = and i64 %t5610, %t5609
  store i64 0, i64* %t5612
  store i64 %t5611, i64* %t5613
  store i1 false, i1* %t5614
  store i64 -1, i64* %t5615
  store i64 -1, i64* %t5616
  store i1 false, i1* %t5617
  br label %ht_probe_cond_1293
ht_probe_cond_1293:
  %t5618 = load i64, i64* %t5612
  %t5619 = icmp slt i64 %t5618, %t5608
  br i1 %t5619, label %ht_probe_body_1294, label %ht_probe_end_1304
ht_probe_body_1294:
  %t5620 = load i64, i64* %t5613
  %t5621 = getelementptr inbounds i8, i8* %t5607, i64 %t5620
  %t5622 = load i8, i8* %t5621
  %t5623 = icmp eq i8 %t5622, 0
  br i1 %t5623, label %ht_probe_on_empty_1296, label %ht_probe_check_occ_1295
ht_probe_check_occ_1295:
  %t5624 = icmp eq i8 %t5622, 1
  br i1 %t5624, label %ht_probe_on_occ_1299, label %ht_probe_on_tomb_1301
ht_probe_on_empty_1296:
  %t5625 = load i1, i1* %t5617
  br i1 %t5625, label %ht_probe_after_islot_empty_1298, label %ht_probe_set_islot_empty_1297
ht_probe_set_islot_empty_1297:
  store i64 %t5620, i64* %t5616
  store i1 true, i1* %t5617
  br label %ht_probe_after_islot_empty_1298
ht_probe_after_islot_empty_1298:
  br label %ht_probe_end_1304
ht_probe_on_occ_1299:
  %t5626 = getelementptr inbounds i8*, i8** %t5605, i64 %t5620
  %t5627 = load i8*, i8** %t5626
  %t5628 = call i1 @eq_str(i8* %t5627, i8* %t5543)
  br i1 %t5628, label %ht_probe_on_match_1300, label %ht_probe_next_1303
ht_probe_on_match_1300:
  store i1 true, i1* %t5614
  store i64 %t5620, i64* %t5615
  br label %ht_probe_end_1304
ht_probe_on_tomb_1301:
  %t5629 = load i1, i1* %t5617
  br i1 %t5629, label %ht_probe_next_1303, label %ht_probe_set_islot_tomb_1302
ht_probe_set_islot_tomb_1302:
  store i64 %t5620, i64* %t5616
  store i1 true, i1* %t5617
  br label %ht_probe_next_1303
ht_probe_next_1303:
  %t5630 = add i64 %t5620, 1
  %t5631 = and i64 %t5630, %t5609
  store i64 %t5631, i64* %t5613
  %t5632 = add i64 %t5618, 1
  store i64 %t5632, i64* %t5612
  br label %ht_probe_cond_1293
ht_probe_end_1304:
  %t5633 = load i1, i1* %t5614
  %t5634 = load i64, i64* %t5615
  %t5635 = load i64, i64* %t5616
  br i1 %t5633, label %map_insert_overwrite_1305, label %map_insert_new_1306
map_insert_overwrite_1305:
  store i8* %t5543, i8** %t5636
  %t5637 = load i8*, i8** %t5636
  call void @star_rc_release(i8* %t5637)
  %t5638 = getelementptr inbounds i32, i32* %t5606, i64 %t5634
  store i32 30, i32* %t5638
  br label %map_insert_after_1307
map_insert_new_1306:
  %t5639 = getelementptr inbounds i8, i8* %t5607, i64 %t5635
  %t5640 = load i8, i8* %t5639
  %t5641 = icmp eq i8 %t5640, 2
  br i1 %t5641, label %map_insert_dec_tomb_1308, label %map_insert_store_1309
map_insert_dec_tomb_1308:
  %t5642 = load i64, i64* %t5541
  %t5643 = sub i64 %t5642, 1
  store i64 %t5643, i64* %t5541
  br label %map_insert_store_1309
map_insert_store_1309:
  store i8 1, i8* %t5639
  %t5644 = getelementptr inbounds i8*, i8** %t5605, i64 %t5635
  store i8* %t5543, i8** %t5644
  %t5645 = getelementptr inbounds i32, i32* %t5606, i64 %t5635
  store i32 30, i32* %t5645
  %t5646 = load i64, i64* %t5537
  %t5647 = add i64 %t5646, 1
  store i64 %t5647, i64* %t5537
  br label %map_insert_after_1307
map_insert_after_1307:
  %t5648 = getelementptr i8*, i8** null, i32 1
  %t5649 = ptrtoint i8** %t5648 to i64
  %t5650 = getelementptr i32, i32* null, i32 1
  %t5651 = ptrtoint i32* %t5650 to i64
  %t5652 = load i8*, i8** %t0
  %t5653 = icmp eq i8* %t5652, null
  br i1 %t5653, label %map_cow_alloc_1310, label %map_cow_check_1311
map_cow_alloc_1310:
  %t5654 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5655 = call i8* @star_rc_alloc(i64 48, i8* %t5654)
  %t5656 = bitcast i8* %t5655 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5657 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5656, i32 0, i32 0
  store i8** null, i8*** %t5657
  %t5658 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5656, i32 0, i32 1
  store i32* null, i32** %t5658
  %t5659 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5656, i32 0, i32 2
  store i8* null, i8** %t5659
  %t5660 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5656, i32 0, i32 3
  store i64 0, i64* %t5660
  %t5661 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5656, i32 0, i32 4
  store i64 0, i64* %t5661
  %t5662 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5656, i32 0, i32 5
  store i64 0, i64* %t5662
  store i8* %t5655, i8** %t0
  br label %map_cow_done_1312
map_cow_check_1311:
  %t5663 = getelementptr inbounds i8, i8* %t5652, i64 -16
  %t5664 = bitcast i8* %t5663 to i64*
  %t5665 = load atomic i64, i64* %t5664 seq_cst, align 8
  %t5666 = icmp eq i64 %t5665, 1
  br i1 %t5666, label %map_cow_done_1312, label %map_cow_clone_1313
map_cow_clone_1313:
  %t5667 = bitcast i8* %t5652 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5668 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5667, i32 0, i32 0
  %t5669 = load i8**, i8*** %t5668
  %t5670 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5667, i32 0, i32 1
  %t5671 = load i32*, i32** %t5670
  %t5672 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5667, i32 0, i32 2
  %t5673 = load i8*, i8** %t5672
  %t5674 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5667, i32 0, i32 3
  %t5675 = load i64, i64* %t5674
  %t5676 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5667, i32 0, i32 4
  %t5677 = load i64, i64* %t5676
  %t5678 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5667, i32 0, i32 5
  %t5679 = load i64, i64* %t5678
  %t5680 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5681 = call i8* @star_rc_alloc(i64 48, i8* %t5680)
  %t5682 = bitcast i8* %t5681 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5683 = mul i64 %t5677, %t5649
  %t5684 = call i8* @malloc(i64 %t5683)
  %t5685 = bitcast i8* %t5684 to i8**
  %t5686 = mul i64 %t5677, %t5651
  %t5687 = call i8* @malloc(i64 %t5686)
  %t5688 = bitcast i8* %t5687 to i32*
  %t5689 = call i8* @malloc(i64 %t5677)
  %t5690 = icmp sgt i64 %t5677, 0
  br i1 %t5690, label %map_cow_copy_1314, label %map_cow_after_copy_1315
map_cow_copy_1314:
  %t5691 = mul i64 %t5677, %t5649
  %t5692 = bitcast i8** %t5669 to i8*
  call i8* @memcpy(i8* %t5684, i8* %t5692, i64 %t5691)
  %t5693 = mul i64 %t5677, %t5651
  %t5694 = bitcast i32* %t5671 to i8*
  call i8* @memcpy(i8* %t5687, i8* %t5694, i64 %t5693)
  call i8* @memcpy(i8* %t5689, i8* %t5673, i64 %t5677)
  store i64 0, i64* %t5695
  br label %map_cow_retain_cond_1316
map_cow_retain_cond_1316:
  %t5696 = load i64, i64* %t5695
  %t5697 = icmp slt i64 %t5696, %t5677
  br i1 %t5697, label %map_cow_retain_body_1317, label %map_cow_retain_end_1320
map_cow_retain_body_1317:
  %t5698 = getelementptr inbounds i8, i8* %t5689, i64 %t5696
  %t5699 = load i8, i8* %t5698
  %t5700 = icmp eq i8 %t5699, 1
  br i1 %t5700, label %map_cow_retain_occ_1318, label %map_cow_retain_next_1319
map_cow_retain_occ_1318:
  %t5701 = getelementptr inbounds i8*, i8** %t5685, i64 %t5696
  %t5702 = load i8*, i8** %t5701
  call void @star_rc_retain(i8* %t5702)
  br label %map_cow_retain_next_1319
map_cow_retain_next_1319:
  %t5703 = add i64 %t5696, 1
  store i64 %t5703, i64* %t5695
  br label %map_cow_retain_cond_1316
map_cow_retain_end_1320:
  br label %map_cow_after_copy_1315
map_cow_after_copy_1315:
  %t5704 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5682, i32 0, i32 0
  store i8** %t5685, i8*** %t5704
  %t5705 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5682, i32 0, i32 1
  store i32* %t5688, i32** %t5705
  %t5706 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5682, i32 0, i32 2
  store i8* %t5689, i8** %t5706
  %t5707 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5682, i32 0, i32 3
  store i64 %t5675, i64* %t5707
  %t5708 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5682, i32 0, i32 4
  store i64 %t5677, i64* %t5708
  %t5709 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5682, i32 0, i32 5
  store i64 %t5679, i64* %t5709
  call void @star_rc_release(i8* %t5652)
  store i8* %t5681, i8** %t0
  br label %map_cow_done_1312
map_cow_done_1312:
  %t5710 = load i8*, i8** %t0
  %t5711 = bitcast i8* %t5710 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5712 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5711, i32 0, i32 0
  %t5713 = load i8**, i8*** %t5712
  %t5714 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5711, i32 0, i32 1
  %t5715 = load i32*, i32** %t5714
  %t5716 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5711, i32 0, i32 2
  %t5717 = load i8*, i8** %t5716
  %t5718 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5711, i32 0, i32 3
  %t5719 = load i64, i64* %t5718
  %t5720 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5711, i32 0, i32 4
  %t5721 = load i64, i64* %t5720
  %t5722 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5711, i32 0, i32 5
  %t5723 = load i64, i64* %t5722
  %t5724 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.31, i64 0, i32 2, i64 0
  %t5725 = load i64, i64* %t5718
  %t5726 = load i64, i64* %t5720
  %t5727 = load i64, i64* %t5722
  %t5728 = add i64 %t5725, %t5727
  %t5729 = add i64 %t5728, 1
  %t5730 = mul i64 %t5729, 4
  %t5731 = mul i64 %t5726, 3
  %t5732 = icmp sgt i64 %t5730, %t5731
  br i1 %t5732, label %map_insert_grow_1321, label %map_insert_after_grow_1322
map_insert_grow_1321:
  %t5733 = getelementptr i8*, i8** null, i32 1
  %t5734 = ptrtoint i8** %t5733 to i64
  %t5735 = getelementptr i32, i32* null, i32 1
  %t5736 = ptrtoint i32* %t5735 to i64
  %t5737 = mul i64 %t5726, 2
  %t5738 = icmp sgt i64 %t5737, 0
  %t5739 = select i1 %t5738, i64 %t5737, i64 8
  %t5740 = sub i64 %t5739, 1
  %t5741 = mul i64 %t5739, %t5734
  %t5742 = call i8* @malloc(i64 %t5741)
  %t5743 = bitcast i8* %t5742 to i8**
  %t5744 = mul i64 %t5739, %t5736
  %t5745 = call i8* @malloc(i64 %t5744)
  %t5746 = bitcast i8* %t5745 to i32*
  %t5747 = call i8* @malloc(i64 %t5739)
  store i64 0, i64* %t5748
  br label %ht_fill8_cond_1323
ht_fill8_cond_1323:
  %t5749 = load i64, i64* %t5748
  %t5750 = icmp slt i64 %t5749, %t5739
  br i1 %t5750, label %ht_fill8_body_1324, label %ht_fill8_end_1325
ht_fill8_body_1324:
  %t5751 = getelementptr inbounds i8, i8* %t5747, i64 %t5749
  store i8 0, i8* %t5751
  %t5752 = add i64 %t5749, 1
  store i64 %t5752, i64* %t5748
  br label %ht_fill8_cond_1323
ht_fill8_end_1325:
  %t5753 = load i8**, i8*** %t5712
  %t5754 = load i32*, i32** %t5714
  %t5755 = load i8*, i8** %t5716
  store i64 0, i64* %t5756
  br label %map_grow_cond_1326
map_grow_cond_1326:
  %t5757 = load i64, i64* %t5756
  %t5758 = icmp slt i64 %t5757, %t5726
  br i1 %t5758, label %map_grow_body_1327, label %map_grow_end_1330
map_grow_body_1327:
  %t5759 = getelementptr inbounds i8, i8* %t5755, i64 %t5757
  %t5760 = load i8, i8* %t5759
  %t5761 = icmp eq i8 %t5760, 1
  br i1 %t5761, label %map_grow_occ_1328, label %map_grow_next_1329
map_grow_occ_1328:
  %t5762 = getelementptr inbounds i8*, i8** %t5753, i64 %t5757
  %t5763 = load i8*, i8** %t5762
  %t5764 = getelementptr inbounds i32, i32* %t5754, i64 %t5757
  %t5765 = load i32, i32* %t5764
  %t5766 = call i64 @hash_str(i8* %t5763)
  %t5767 = and i64 %t5766, %t5740
  store i64 0, i64* %t5768
  store i64 %t5767, i64* %t5769
  br label %ht_fe_cond_1331
ht_fe_cond_1331:
  %t5770 = load i64, i64* %t5768
  %t5771 = icmp slt i64 %t5770, %t5739
  br i1 %t5771, label %ht_fe_body_1332, label %ht_fe_end_1334
ht_fe_body_1332:
  %t5772 = load i64, i64* %t5769
  %t5773 = getelementptr inbounds i8, i8* %t5747, i64 %t5772
  %t5774 = load i8, i8* %t5773
  %t5775 = icmp eq i8 %t5774, 0
  br i1 %t5775, label %ht_fe_end_1334, label %ht_fe_next_1333
ht_fe_next_1333:
  %t5776 = add i64 %t5772, 1
  %t5777 = and i64 %t5776, %t5740
  store i64 %t5777, i64* %t5769
  %t5778 = add i64 %t5770, 1
  store i64 %t5778, i64* %t5768
  br label %ht_fe_cond_1331
ht_fe_end_1334:
  %t5779 = load i64, i64* %t5769
  %t5780 = getelementptr inbounds i8, i8* %t5747, i64 %t5779
  store i8 1, i8* %t5780
  %t5781 = getelementptr inbounds i8*, i8** %t5743, i64 %t5779
  store i8* %t5763, i8** %t5781
  %t5782 = getelementptr inbounds i32, i32* %t5746, i64 %t5779
  store i32 %t5765, i32* %t5782
  br label %map_grow_next_1329
map_grow_next_1329:
  %t5783 = add i64 %t5757, 1
  store i64 %t5783, i64* %t5756
  br label %map_grow_cond_1326
map_grow_end_1330:
  %t5784 = bitcast i8** %t5753 to i8*
  call void @free(i8* %t5784)
  %t5785 = bitcast i32* %t5754 to i8*
  call void @free(i8* %t5785)
  call void @free(i8* %t5755)
  store i8** %t5743, i8*** %t5712
  store i32* %t5746, i32** %t5714
  store i8* %t5747, i8** %t5716
  store i64 %t5739, i64* %t5720
  store i64 0, i64* %t5722
  br label %map_insert_after_grow_1322
map_insert_after_grow_1322:
  %t5786 = load i8**, i8*** %t5712
  %t5787 = load i32*, i32** %t5714
  %t5788 = load i8*, i8** %t5716
  %t5789 = load i64, i64* %t5720
  %t5790 = sub i64 %t5789, 1
  %t5791 = call i64 @hash_str(i8* %t5724)
  %t5792 = and i64 %t5791, %t5790
  store i64 0, i64* %t5793
  store i64 %t5792, i64* %t5794
  store i1 false, i1* %t5795
  store i64 -1, i64* %t5796
  store i64 -1, i64* %t5797
  store i1 false, i1* %t5798
  br label %ht_probe_cond_1335
ht_probe_cond_1335:
  %t5799 = load i64, i64* %t5793
  %t5800 = icmp slt i64 %t5799, %t5789
  br i1 %t5800, label %ht_probe_body_1336, label %ht_probe_end_1346
ht_probe_body_1336:
  %t5801 = load i64, i64* %t5794
  %t5802 = getelementptr inbounds i8, i8* %t5788, i64 %t5801
  %t5803 = load i8, i8* %t5802
  %t5804 = icmp eq i8 %t5803, 0
  br i1 %t5804, label %ht_probe_on_empty_1338, label %ht_probe_check_occ_1337
ht_probe_check_occ_1337:
  %t5805 = icmp eq i8 %t5803, 1
  br i1 %t5805, label %ht_probe_on_occ_1341, label %ht_probe_on_tomb_1343
ht_probe_on_empty_1338:
  %t5806 = load i1, i1* %t5798
  br i1 %t5806, label %ht_probe_after_islot_empty_1340, label %ht_probe_set_islot_empty_1339
ht_probe_set_islot_empty_1339:
  store i64 %t5801, i64* %t5797
  store i1 true, i1* %t5798
  br label %ht_probe_after_islot_empty_1340
ht_probe_after_islot_empty_1340:
  br label %ht_probe_end_1346
ht_probe_on_occ_1341:
  %t5807 = getelementptr inbounds i8*, i8** %t5786, i64 %t5801
  %t5808 = load i8*, i8** %t5807
  %t5809 = call i1 @eq_str(i8* %t5808, i8* %t5724)
  br i1 %t5809, label %ht_probe_on_match_1342, label %ht_probe_next_1345
ht_probe_on_match_1342:
  store i1 true, i1* %t5795
  store i64 %t5801, i64* %t5796
  br label %ht_probe_end_1346
ht_probe_on_tomb_1343:
  %t5810 = load i1, i1* %t5798
  br i1 %t5810, label %ht_probe_next_1345, label %ht_probe_set_islot_tomb_1344
ht_probe_set_islot_tomb_1344:
  store i64 %t5801, i64* %t5797
  store i1 true, i1* %t5798
  br label %ht_probe_next_1345
ht_probe_next_1345:
  %t5811 = add i64 %t5801, 1
  %t5812 = and i64 %t5811, %t5790
  store i64 %t5812, i64* %t5794
  %t5813 = add i64 %t5799, 1
  store i64 %t5813, i64* %t5793
  br label %ht_probe_cond_1335
ht_probe_end_1346:
  %t5814 = load i1, i1* %t5795
  %t5815 = load i64, i64* %t5796
  %t5816 = load i64, i64* %t5797
  br i1 %t5814, label %map_insert_overwrite_1347, label %map_insert_new_1348
map_insert_overwrite_1347:
  store i8* %t5724, i8** %t5817
  %t5818 = load i8*, i8** %t5817
  call void @star_rc_release(i8* %t5818)
  %t5819 = getelementptr inbounds i32, i32* %t5787, i64 %t5815
  store i32 31, i32* %t5819
  br label %map_insert_after_1349
map_insert_new_1348:
  %t5820 = getelementptr inbounds i8, i8* %t5788, i64 %t5816
  %t5821 = load i8, i8* %t5820
  %t5822 = icmp eq i8 %t5821, 2
  br i1 %t5822, label %map_insert_dec_tomb_1350, label %map_insert_store_1351
map_insert_dec_tomb_1350:
  %t5823 = load i64, i64* %t5722
  %t5824 = sub i64 %t5823, 1
  store i64 %t5824, i64* %t5722
  br label %map_insert_store_1351
map_insert_store_1351:
  store i8 1, i8* %t5820
  %t5825 = getelementptr inbounds i8*, i8** %t5786, i64 %t5816
  store i8* %t5724, i8** %t5825
  %t5826 = getelementptr inbounds i32, i32* %t5787, i64 %t5816
  store i32 31, i32* %t5826
  %t5827 = load i64, i64* %t5718
  %t5828 = add i64 %t5827, 1
  store i64 %t5828, i64* %t5718
  br label %map_insert_after_1349
map_insert_after_1349:
  %t5829 = getelementptr i8*, i8** null, i32 1
  %t5830 = ptrtoint i8** %t5829 to i64
  %t5831 = getelementptr i32, i32* null, i32 1
  %t5832 = ptrtoint i32* %t5831 to i64
  %t5833 = load i8*, i8** %t0
  %t5834 = icmp eq i8* %t5833, null
  br i1 %t5834, label %map_cow_alloc_1352, label %map_cow_check_1353
map_cow_alloc_1352:
  %t5835 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5836 = call i8* @star_rc_alloc(i64 48, i8* %t5835)
  %t5837 = bitcast i8* %t5836 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5838 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5837, i32 0, i32 0
  store i8** null, i8*** %t5838
  %t5839 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5837, i32 0, i32 1
  store i32* null, i32** %t5839
  %t5840 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5837, i32 0, i32 2
  store i8* null, i8** %t5840
  %t5841 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5837, i32 0, i32 3
  store i64 0, i64* %t5841
  %t5842 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5837, i32 0, i32 4
  store i64 0, i64* %t5842
  %t5843 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5837, i32 0, i32 5
  store i64 0, i64* %t5843
  store i8* %t5836, i8** %t0
  br label %map_cow_done_1354
map_cow_check_1353:
  %t5844 = getelementptr inbounds i8, i8* %t5833, i64 -16
  %t5845 = bitcast i8* %t5844 to i64*
  %t5846 = load atomic i64, i64* %t5845 seq_cst, align 8
  %t5847 = icmp eq i64 %t5846, 1
  br i1 %t5847, label %map_cow_done_1354, label %map_cow_clone_1355
map_cow_clone_1355:
  %t5848 = bitcast i8* %t5833 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5849 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5848, i32 0, i32 0
  %t5850 = load i8**, i8*** %t5849
  %t5851 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5848, i32 0, i32 1
  %t5852 = load i32*, i32** %t5851
  %t5853 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5848, i32 0, i32 2
  %t5854 = load i8*, i8** %t5853
  %t5855 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5848, i32 0, i32 3
  %t5856 = load i64, i64* %t5855
  %t5857 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5848, i32 0, i32 4
  %t5858 = load i64, i64* %t5857
  %t5859 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5848, i32 0, i32 5
  %t5860 = load i64, i64* %t5859
  %t5861 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t5862 = call i8* @star_rc_alloc(i64 48, i8* %t5861)
  %t5863 = bitcast i8* %t5862 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5864 = mul i64 %t5858, %t5830
  %t5865 = call i8* @malloc(i64 %t5864)
  %t5866 = bitcast i8* %t5865 to i8**
  %t5867 = mul i64 %t5858, %t5832
  %t5868 = call i8* @malloc(i64 %t5867)
  %t5869 = bitcast i8* %t5868 to i32*
  %t5870 = call i8* @malloc(i64 %t5858)
  %t5871 = icmp sgt i64 %t5858, 0
  br i1 %t5871, label %map_cow_copy_1356, label %map_cow_after_copy_1357
map_cow_copy_1356:
  %t5872 = mul i64 %t5858, %t5830
  %t5873 = bitcast i8** %t5850 to i8*
  call i8* @memcpy(i8* %t5865, i8* %t5873, i64 %t5872)
  %t5874 = mul i64 %t5858, %t5832
  %t5875 = bitcast i32* %t5852 to i8*
  call i8* @memcpy(i8* %t5868, i8* %t5875, i64 %t5874)
  call i8* @memcpy(i8* %t5870, i8* %t5854, i64 %t5858)
  store i64 0, i64* %t5876
  br label %map_cow_retain_cond_1358
map_cow_retain_cond_1358:
  %t5877 = load i64, i64* %t5876
  %t5878 = icmp slt i64 %t5877, %t5858
  br i1 %t5878, label %map_cow_retain_body_1359, label %map_cow_retain_end_1362
map_cow_retain_body_1359:
  %t5879 = getelementptr inbounds i8, i8* %t5870, i64 %t5877
  %t5880 = load i8, i8* %t5879
  %t5881 = icmp eq i8 %t5880, 1
  br i1 %t5881, label %map_cow_retain_occ_1360, label %map_cow_retain_next_1361
map_cow_retain_occ_1360:
  %t5882 = getelementptr inbounds i8*, i8** %t5866, i64 %t5877
  %t5883 = load i8*, i8** %t5882
  call void @star_rc_retain(i8* %t5883)
  br label %map_cow_retain_next_1361
map_cow_retain_next_1361:
  %t5884 = add i64 %t5877, 1
  store i64 %t5884, i64* %t5876
  br label %map_cow_retain_cond_1358
map_cow_retain_end_1362:
  br label %map_cow_after_copy_1357
map_cow_after_copy_1357:
  %t5885 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5863, i32 0, i32 0
  store i8** %t5866, i8*** %t5885
  %t5886 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5863, i32 0, i32 1
  store i32* %t5869, i32** %t5886
  %t5887 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5863, i32 0, i32 2
  store i8* %t5870, i8** %t5887
  %t5888 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5863, i32 0, i32 3
  store i64 %t5856, i64* %t5888
  %t5889 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5863, i32 0, i32 4
  store i64 %t5858, i64* %t5889
  %t5890 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5863, i32 0, i32 5
  store i64 %t5860, i64* %t5890
  call void @star_rc_release(i8* %t5833)
  store i8* %t5862, i8** %t0
  br label %map_cow_done_1354
map_cow_done_1354:
  %t5891 = load i8*, i8** %t0
  %t5892 = bitcast i8* %t5891 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t5893 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5892, i32 0, i32 0
  %t5894 = load i8**, i8*** %t5893
  %t5895 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5892, i32 0, i32 1
  %t5896 = load i32*, i32** %t5895
  %t5897 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5892, i32 0, i32 2
  %t5898 = load i8*, i8** %t5897
  %t5899 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5892, i32 0, i32 3
  %t5900 = load i64, i64* %t5899
  %t5901 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5892, i32 0, i32 4
  %t5902 = load i64, i64* %t5901
  %t5903 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t5892, i32 0, i32 5
  %t5904 = load i64, i64* %t5903
  %t5905 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.32, i64 0, i32 2, i64 0
  %t5906 = load i64, i64* %t5899
  %t5907 = load i64, i64* %t5901
  %t5908 = load i64, i64* %t5903
  %t5909 = add i64 %t5906, %t5908
  %t5910 = add i64 %t5909, 1
  %t5911 = mul i64 %t5910, 4
  %t5912 = mul i64 %t5907, 3
  %t5913 = icmp sgt i64 %t5911, %t5912
  br i1 %t5913, label %map_insert_grow_1363, label %map_insert_after_grow_1364
map_insert_grow_1363:
  %t5914 = getelementptr i8*, i8** null, i32 1
  %t5915 = ptrtoint i8** %t5914 to i64
  %t5916 = getelementptr i32, i32* null, i32 1
  %t5917 = ptrtoint i32* %t5916 to i64
  %t5918 = mul i64 %t5907, 2
  %t5919 = icmp sgt i64 %t5918, 0
  %t5920 = select i1 %t5919, i64 %t5918, i64 8
  %t5921 = sub i64 %t5920, 1
  %t5922 = mul i64 %t5920, %t5915
  %t5923 = call i8* @malloc(i64 %t5922)
  %t5924 = bitcast i8* %t5923 to i8**
  %t5925 = mul i64 %t5920, %t5917
  %t5926 = call i8* @malloc(i64 %t5925)
  %t5927 = bitcast i8* %t5926 to i32*
  %t5928 = call i8* @malloc(i64 %t5920)
  store i64 0, i64* %t5929
  br label %ht_fill8_cond_1365
ht_fill8_cond_1365:
  %t5930 = load i64, i64* %t5929
  %t5931 = icmp slt i64 %t5930, %t5920
  br i1 %t5931, label %ht_fill8_body_1366, label %ht_fill8_end_1367
ht_fill8_body_1366:
  %t5932 = getelementptr inbounds i8, i8* %t5928, i64 %t5930
  store i8 0, i8* %t5932
  %t5933 = add i64 %t5930, 1
  store i64 %t5933, i64* %t5929
  br label %ht_fill8_cond_1365
ht_fill8_end_1367:
  %t5934 = load i8**, i8*** %t5893
  %t5935 = load i32*, i32** %t5895
  %t5936 = load i8*, i8** %t5897
  store i64 0, i64* %t5937
  br label %map_grow_cond_1368
map_grow_cond_1368:
  %t5938 = load i64, i64* %t5937
  %t5939 = icmp slt i64 %t5938, %t5907
  br i1 %t5939, label %map_grow_body_1369, label %map_grow_end_1372
map_grow_body_1369:
  %t5940 = getelementptr inbounds i8, i8* %t5936, i64 %t5938
  %t5941 = load i8, i8* %t5940
  %t5942 = icmp eq i8 %t5941, 1
  br i1 %t5942, label %map_grow_occ_1370, label %map_grow_next_1371
map_grow_occ_1370:
  %t5943 = getelementptr inbounds i8*, i8** %t5934, i64 %t5938
  %t5944 = load i8*, i8** %t5943
  %t5945 = getelementptr inbounds i32, i32* %t5935, i64 %t5938
  %t5946 = load i32, i32* %t5945
  %t5947 = call i64 @hash_str(i8* %t5944)
  %t5948 = and i64 %t5947, %t5921
  store i64 0, i64* %t5949
  store i64 %t5948, i64* %t5950
  br label %ht_fe_cond_1373
ht_fe_cond_1373:
  %t5951 = load i64, i64* %t5949
  %t5952 = icmp slt i64 %t5951, %t5920
  br i1 %t5952, label %ht_fe_body_1374, label %ht_fe_end_1376
ht_fe_body_1374:
  %t5953 = load i64, i64* %t5950
  %t5954 = getelementptr inbounds i8, i8* %t5928, i64 %t5953
  %t5955 = load i8, i8* %t5954
  %t5956 = icmp eq i8 %t5955, 0
  br i1 %t5956, label %ht_fe_end_1376, label %ht_fe_next_1375
ht_fe_next_1375:
  %t5957 = add i64 %t5953, 1
  %t5958 = and i64 %t5957, %t5921
  store i64 %t5958, i64* %t5950
  %t5959 = add i64 %t5951, 1
  store i64 %t5959, i64* %t5949
  br label %ht_fe_cond_1373
ht_fe_end_1376:
  %t5960 = load i64, i64* %t5950
  %t5961 = getelementptr inbounds i8, i8* %t5928, i64 %t5960
  store i8 1, i8* %t5961
  %t5962 = getelementptr inbounds i8*, i8** %t5924, i64 %t5960
  store i8* %t5944, i8** %t5962
  %t5963 = getelementptr inbounds i32, i32* %t5927, i64 %t5960
  store i32 %t5946, i32* %t5963
  br label %map_grow_next_1371
map_grow_next_1371:
  %t5964 = add i64 %t5938, 1
  store i64 %t5964, i64* %t5937
  br label %map_grow_cond_1368
map_grow_end_1372:
  %t5965 = bitcast i8** %t5934 to i8*
  call void @free(i8* %t5965)
  %t5966 = bitcast i32* %t5935 to i8*
  call void @free(i8* %t5966)
  call void @free(i8* %t5936)
  store i8** %t5924, i8*** %t5893
  store i32* %t5927, i32** %t5895
  store i8* %t5928, i8** %t5897
  store i64 %t5920, i64* %t5901
  store i64 0, i64* %t5903
  br label %map_insert_after_grow_1364
map_insert_after_grow_1364:
  %t5967 = load i8**, i8*** %t5893
  %t5968 = load i32*, i32** %t5895
  %t5969 = load i8*, i8** %t5897
  %t5970 = load i64, i64* %t5901
  %t5971 = sub i64 %t5970, 1
  %t5972 = call i64 @hash_str(i8* %t5905)
  %t5973 = and i64 %t5972, %t5971
  store i64 0, i64* %t5974
  store i64 %t5973, i64* %t5975
  store i1 false, i1* %t5976
  store i64 -1, i64* %t5977
  store i64 -1, i64* %t5978
  store i1 false, i1* %t5979
  br label %ht_probe_cond_1377
ht_probe_cond_1377:
  %t5980 = load i64, i64* %t5974
  %t5981 = icmp slt i64 %t5980, %t5970
  br i1 %t5981, label %ht_probe_body_1378, label %ht_probe_end_1388
ht_probe_body_1378:
  %t5982 = load i64, i64* %t5975
  %t5983 = getelementptr inbounds i8, i8* %t5969, i64 %t5982
  %t5984 = load i8, i8* %t5983
  %t5985 = icmp eq i8 %t5984, 0
  br i1 %t5985, label %ht_probe_on_empty_1380, label %ht_probe_check_occ_1379
ht_probe_check_occ_1379:
  %t5986 = icmp eq i8 %t5984, 1
  br i1 %t5986, label %ht_probe_on_occ_1383, label %ht_probe_on_tomb_1385
ht_probe_on_empty_1380:
  %t5987 = load i1, i1* %t5979
  br i1 %t5987, label %ht_probe_after_islot_empty_1382, label %ht_probe_set_islot_empty_1381
ht_probe_set_islot_empty_1381:
  store i64 %t5982, i64* %t5978
  store i1 true, i1* %t5979
  br label %ht_probe_after_islot_empty_1382
ht_probe_after_islot_empty_1382:
  br label %ht_probe_end_1388
ht_probe_on_occ_1383:
  %t5988 = getelementptr inbounds i8*, i8** %t5967, i64 %t5982
  %t5989 = load i8*, i8** %t5988
  %t5990 = call i1 @eq_str(i8* %t5989, i8* %t5905)
  br i1 %t5990, label %ht_probe_on_match_1384, label %ht_probe_next_1387
ht_probe_on_match_1384:
  store i1 true, i1* %t5976
  store i64 %t5982, i64* %t5977
  br label %ht_probe_end_1388
ht_probe_on_tomb_1385:
  %t5991 = load i1, i1* %t5979
  br i1 %t5991, label %ht_probe_next_1387, label %ht_probe_set_islot_tomb_1386
ht_probe_set_islot_tomb_1386:
  store i64 %t5982, i64* %t5978
  store i1 true, i1* %t5979
  br label %ht_probe_next_1387
ht_probe_next_1387:
  %t5992 = add i64 %t5982, 1
  %t5993 = and i64 %t5992, %t5971
  store i64 %t5993, i64* %t5975
  %t5994 = add i64 %t5980, 1
  store i64 %t5994, i64* %t5974
  br label %ht_probe_cond_1377
ht_probe_end_1388:
  %t5995 = load i1, i1* %t5976
  %t5996 = load i64, i64* %t5977
  %t5997 = load i64, i64* %t5978
  br i1 %t5995, label %map_insert_overwrite_1389, label %map_insert_new_1390
map_insert_overwrite_1389:
  store i8* %t5905, i8** %t5998
  %t5999 = load i8*, i8** %t5998
  call void @star_rc_release(i8* %t5999)
  %t6000 = getelementptr inbounds i32, i32* %t5968, i64 %t5996
  store i32 32, i32* %t6000
  br label %map_insert_after_1391
map_insert_new_1390:
  %t6001 = getelementptr inbounds i8, i8* %t5969, i64 %t5997
  %t6002 = load i8, i8* %t6001
  %t6003 = icmp eq i8 %t6002, 2
  br i1 %t6003, label %map_insert_dec_tomb_1392, label %map_insert_store_1393
map_insert_dec_tomb_1392:
  %t6004 = load i64, i64* %t5903
  %t6005 = sub i64 %t6004, 1
  store i64 %t6005, i64* %t5903
  br label %map_insert_store_1393
map_insert_store_1393:
  store i8 1, i8* %t6001
  %t6006 = getelementptr inbounds i8*, i8** %t5967, i64 %t5997
  store i8* %t5905, i8** %t6006
  %t6007 = getelementptr inbounds i32, i32* %t5968, i64 %t5997
  store i32 32, i32* %t6007
  %t6008 = load i64, i64* %t5899
  %t6009 = add i64 %t6008, 1
  store i64 %t6009, i64* %t5899
  br label %map_insert_after_1391
map_insert_after_1391:
  %t6010 = getelementptr i8*, i8** null, i32 1
  %t6011 = ptrtoint i8** %t6010 to i64
  %t6012 = getelementptr i32, i32* null, i32 1
  %t6013 = ptrtoint i32* %t6012 to i64
  %t6014 = load i8*, i8** %t0
  %t6015 = icmp eq i8* %t6014, null
  br i1 %t6015, label %map_cow_alloc_1394, label %map_cow_check_1395
map_cow_alloc_1394:
  %t6016 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6017 = call i8* @star_rc_alloc(i64 48, i8* %t6016)
  %t6018 = bitcast i8* %t6017 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6019 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6018, i32 0, i32 0
  store i8** null, i8*** %t6019
  %t6020 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6018, i32 0, i32 1
  store i32* null, i32** %t6020
  %t6021 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6018, i32 0, i32 2
  store i8* null, i8** %t6021
  %t6022 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6018, i32 0, i32 3
  store i64 0, i64* %t6022
  %t6023 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6018, i32 0, i32 4
  store i64 0, i64* %t6023
  %t6024 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6018, i32 0, i32 5
  store i64 0, i64* %t6024
  store i8* %t6017, i8** %t0
  br label %map_cow_done_1396
map_cow_check_1395:
  %t6025 = getelementptr inbounds i8, i8* %t6014, i64 -16
  %t6026 = bitcast i8* %t6025 to i64*
  %t6027 = load atomic i64, i64* %t6026 seq_cst, align 8
  %t6028 = icmp eq i64 %t6027, 1
  br i1 %t6028, label %map_cow_done_1396, label %map_cow_clone_1397
map_cow_clone_1397:
  %t6029 = bitcast i8* %t6014 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6030 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6029, i32 0, i32 0
  %t6031 = load i8**, i8*** %t6030
  %t6032 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6029, i32 0, i32 1
  %t6033 = load i32*, i32** %t6032
  %t6034 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6029, i32 0, i32 2
  %t6035 = load i8*, i8** %t6034
  %t6036 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6029, i32 0, i32 3
  %t6037 = load i64, i64* %t6036
  %t6038 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6029, i32 0, i32 4
  %t6039 = load i64, i64* %t6038
  %t6040 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6029, i32 0, i32 5
  %t6041 = load i64, i64* %t6040
  %t6042 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6043 = call i8* @star_rc_alloc(i64 48, i8* %t6042)
  %t6044 = bitcast i8* %t6043 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6045 = mul i64 %t6039, %t6011
  %t6046 = call i8* @malloc(i64 %t6045)
  %t6047 = bitcast i8* %t6046 to i8**
  %t6048 = mul i64 %t6039, %t6013
  %t6049 = call i8* @malloc(i64 %t6048)
  %t6050 = bitcast i8* %t6049 to i32*
  %t6051 = call i8* @malloc(i64 %t6039)
  %t6052 = icmp sgt i64 %t6039, 0
  br i1 %t6052, label %map_cow_copy_1398, label %map_cow_after_copy_1399
map_cow_copy_1398:
  %t6053 = mul i64 %t6039, %t6011
  %t6054 = bitcast i8** %t6031 to i8*
  call i8* @memcpy(i8* %t6046, i8* %t6054, i64 %t6053)
  %t6055 = mul i64 %t6039, %t6013
  %t6056 = bitcast i32* %t6033 to i8*
  call i8* @memcpy(i8* %t6049, i8* %t6056, i64 %t6055)
  call i8* @memcpy(i8* %t6051, i8* %t6035, i64 %t6039)
  store i64 0, i64* %t6057
  br label %map_cow_retain_cond_1400
map_cow_retain_cond_1400:
  %t6058 = load i64, i64* %t6057
  %t6059 = icmp slt i64 %t6058, %t6039
  br i1 %t6059, label %map_cow_retain_body_1401, label %map_cow_retain_end_1404
map_cow_retain_body_1401:
  %t6060 = getelementptr inbounds i8, i8* %t6051, i64 %t6058
  %t6061 = load i8, i8* %t6060
  %t6062 = icmp eq i8 %t6061, 1
  br i1 %t6062, label %map_cow_retain_occ_1402, label %map_cow_retain_next_1403
map_cow_retain_occ_1402:
  %t6063 = getelementptr inbounds i8*, i8** %t6047, i64 %t6058
  %t6064 = load i8*, i8** %t6063
  call void @star_rc_retain(i8* %t6064)
  br label %map_cow_retain_next_1403
map_cow_retain_next_1403:
  %t6065 = add i64 %t6058, 1
  store i64 %t6065, i64* %t6057
  br label %map_cow_retain_cond_1400
map_cow_retain_end_1404:
  br label %map_cow_after_copy_1399
map_cow_after_copy_1399:
  %t6066 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6044, i32 0, i32 0
  store i8** %t6047, i8*** %t6066
  %t6067 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6044, i32 0, i32 1
  store i32* %t6050, i32** %t6067
  %t6068 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6044, i32 0, i32 2
  store i8* %t6051, i8** %t6068
  %t6069 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6044, i32 0, i32 3
  store i64 %t6037, i64* %t6069
  %t6070 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6044, i32 0, i32 4
  store i64 %t6039, i64* %t6070
  %t6071 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6044, i32 0, i32 5
  store i64 %t6041, i64* %t6071
  call void @star_rc_release(i8* %t6014)
  store i8* %t6043, i8** %t0
  br label %map_cow_done_1396
map_cow_done_1396:
  %t6072 = load i8*, i8** %t0
  %t6073 = bitcast i8* %t6072 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6074 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6073, i32 0, i32 0
  %t6075 = load i8**, i8*** %t6074
  %t6076 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6073, i32 0, i32 1
  %t6077 = load i32*, i32** %t6076
  %t6078 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6073, i32 0, i32 2
  %t6079 = load i8*, i8** %t6078
  %t6080 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6073, i32 0, i32 3
  %t6081 = load i64, i64* %t6080
  %t6082 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6073, i32 0, i32 4
  %t6083 = load i64, i64* %t6082
  %t6084 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6073, i32 0, i32 5
  %t6085 = load i64, i64* %t6084
  %t6086 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.33, i64 0, i32 2, i64 0
  %t6087 = load i64, i64* %t6080
  %t6088 = load i64, i64* %t6082
  %t6089 = load i64, i64* %t6084
  %t6090 = add i64 %t6087, %t6089
  %t6091 = add i64 %t6090, 1
  %t6092 = mul i64 %t6091, 4
  %t6093 = mul i64 %t6088, 3
  %t6094 = icmp sgt i64 %t6092, %t6093
  br i1 %t6094, label %map_insert_grow_1405, label %map_insert_after_grow_1406
map_insert_grow_1405:
  %t6095 = getelementptr i8*, i8** null, i32 1
  %t6096 = ptrtoint i8** %t6095 to i64
  %t6097 = getelementptr i32, i32* null, i32 1
  %t6098 = ptrtoint i32* %t6097 to i64
  %t6099 = mul i64 %t6088, 2
  %t6100 = icmp sgt i64 %t6099, 0
  %t6101 = select i1 %t6100, i64 %t6099, i64 8
  %t6102 = sub i64 %t6101, 1
  %t6103 = mul i64 %t6101, %t6096
  %t6104 = call i8* @malloc(i64 %t6103)
  %t6105 = bitcast i8* %t6104 to i8**
  %t6106 = mul i64 %t6101, %t6098
  %t6107 = call i8* @malloc(i64 %t6106)
  %t6108 = bitcast i8* %t6107 to i32*
  %t6109 = call i8* @malloc(i64 %t6101)
  store i64 0, i64* %t6110
  br label %ht_fill8_cond_1407
ht_fill8_cond_1407:
  %t6111 = load i64, i64* %t6110
  %t6112 = icmp slt i64 %t6111, %t6101
  br i1 %t6112, label %ht_fill8_body_1408, label %ht_fill8_end_1409
ht_fill8_body_1408:
  %t6113 = getelementptr inbounds i8, i8* %t6109, i64 %t6111
  store i8 0, i8* %t6113
  %t6114 = add i64 %t6111, 1
  store i64 %t6114, i64* %t6110
  br label %ht_fill8_cond_1407
ht_fill8_end_1409:
  %t6115 = load i8**, i8*** %t6074
  %t6116 = load i32*, i32** %t6076
  %t6117 = load i8*, i8** %t6078
  store i64 0, i64* %t6118
  br label %map_grow_cond_1410
map_grow_cond_1410:
  %t6119 = load i64, i64* %t6118
  %t6120 = icmp slt i64 %t6119, %t6088
  br i1 %t6120, label %map_grow_body_1411, label %map_grow_end_1414
map_grow_body_1411:
  %t6121 = getelementptr inbounds i8, i8* %t6117, i64 %t6119
  %t6122 = load i8, i8* %t6121
  %t6123 = icmp eq i8 %t6122, 1
  br i1 %t6123, label %map_grow_occ_1412, label %map_grow_next_1413
map_grow_occ_1412:
  %t6124 = getelementptr inbounds i8*, i8** %t6115, i64 %t6119
  %t6125 = load i8*, i8** %t6124
  %t6126 = getelementptr inbounds i32, i32* %t6116, i64 %t6119
  %t6127 = load i32, i32* %t6126
  %t6128 = call i64 @hash_str(i8* %t6125)
  %t6129 = and i64 %t6128, %t6102
  store i64 0, i64* %t6130
  store i64 %t6129, i64* %t6131
  br label %ht_fe_cond_1415
ht_fe_cond_1415:
  %t6132 = load i64, i64* %t6130
  %t6133 = icmp slt i64 %t6132, %t6101
  br i1 %t6133, label %ht_fe_body_1416, label %ht_fe_end_1418
ht_fe_body_1416:
  %t6134 = load i64, i64* %t6131
  %t6135 = getelementptr inbounds i8, i8* %t6109, i64 %t6134
  %t6136 = load i8, i8* %t6135
  %t6137 = icmp eq i8 %t6136, 0
  br i1 %t6137, label %ht_fe_end_1418, label %ht_fe_next_1417
ht_fe_next_1417:
  %t6138 = add i64 %t6134, 1
  %t6139 = and i64 %t6138, %t6102
  store i64 %t6139, i64* %t6131
  %t6140 = add i64 %t6132, 1
  store i64 %t6140, i64* %t6130
  br label %ht_fe_cond_1415
ht_fe_end_1418:
  %t6141 = load i64, i64* %t6131
  %t6142 = getelementptr inbounds i8, i8* %t6109, i64 %t6141
  store i8 1, i8* %t6142
  %t6143 = getelementptr inbounds i8*, i8** %t6105, i64 %t6141
  store i8* %t6125, i8** %t6143
  %t6144 = getelementptr inbounds i32, i32* %t6108, i64 %t6141
  store i32 %t6127, i32* %t6144
  br label %map_grow_next_1413
map_grow_next_1413:
  %t6145 = add i64 %t6119, 1
  store i64 %t6145, i64* %t6118
  br label %map_grow_cond_1410
map_grow_end_1414:
  %t6146 = bitcast i8** %t6115 to i8*
  call void @free(i8* %t6146)
  %t6147 = bitcast i32* %t6116 to i8*
  call void @free(i8* %t6147)
  call void @free(i8* %t6117)
  store i8** %t6105, i8*** %t6074
  store i32* %t6108, i32** %t6076
  store i8* %t6109, i8** %t6078
  store i64 %t6101, i64* %t6082
  store i64 0, i64* %t6084
  br label %map_insert_after_grow_1406
map_insert_after_grow_1406:
  %t6148 = load i8**, i8*** %t6074
  %t6149 = load i32*, i32** %t6076
  %t6150 = load i8*, i8** %t6078
  %t6151 = load i64, i64* %t6082
  %t6152 = sub i64 %t6151, 1
  %t6153 = call i64 @hash_str(i8* %t6086)
  %t6154 = and i64 %t6153, %t6152
  store i64 0, i64* %t6155
  store i64 %t6154, i64* %t6156
  store i1 false, i1* %t6157
  store i64 -1, i64* %t6158
  store i64 -1, i64* %t6159
  store i1 false, i1* %t6160
  br label %ht_probe_cond_1419
ht_probe_cond_1419:
  %t6161 = load i64, i64* %t6155
  %t6162 = icmp slt i64 %t6161, %t6151
  br i1 %t6162, label %ht_probe_body_1420, label %ht_probe_end_1430
ht_probe_body_1420:
  %t6163 = load i64, i64* %t6156
  %t6164 = getelementptr inbounds i8, i8* %t6150, i64 %t6163
  %t6165 = load i8, i8* %t6164
  %t6166 = icmp eq i8 %t6165, 0
  br i1 %t6166, label %ht_probe_on_empty_1422, label %ht_probe_check_occ_1421
ht_probe_check_occ_1421:
  %t6167 = icmp eq i8 %t6165, 1
  br i1 %t6167, label %ht_probe_on_occ_1425, label %ht_probe_on_tomb_1427
ht_probe_on_empty_1422:
  %t6168 = load i1, i1* %t6160
  br i1 %t6168, label %ht_probe_after_islot_empty_1424, label %ht_probe_set_islot_empty_1423
ht_probe_set_islot_empty_1423:
  store i64 %t6163, i64* %t6159
  store i1 true, i1* %t6160
  br label %ht_probe_after_islot_empty_1424
ht_probe_after_islot_empty_1424:
  br label %ht_probe_end_1430
ht_probe_on_occ_1425:
  %t6169 = getelementptr inbounds i8*, i8** %t6148, i64 %t6163
  %t6170 = load i8*, i8** %t6169
  %t6171 = call i1 @eq_str(i8* %t6170, i8* %t6086)
  br i1 %t6171, label %ht_probe_on_match_1426, label %ht_probe_next_1429
ht_probe_on_match_1426:
  store i1 true, i1* %t6157
  store i64 %t6163, i64* %t6158
  br label %ht_probe_end_1430
ht_probe_on_tomb_1427:
  %t6172 = load i1, i1* %t6160
  br i1 %t6172, label %ht_probe_next_1429, label %ht_probe_set_islot_tomb_1428
ht_probe_set_islot_tomb_1428:
  store i64 %t6163, i64* %t6159
  store i1 true, i1* %t6160
  br label %ht_probe_next_1429
ht_probe_next_1429:
  %t6173 = add i64 %t6163, 1
  %t6174 = and i64 %t6173, %t6152
  store i64 %t6174, i64* %t6156
  %t6175 = add i64 %t6161, 1
  store i64 %t6175, i64* %t6155
  br label %ht_probe_cond_1419
ht_probe_end_1430:
  %t6176 = load i1, i1* %t6157
  %t6177 = load i64, i64* %t6158
  %t6178 = load i64, i64* %t6159
  br i1 %t6176, label %map_insert_overwrite_1431, label %map_insert_new_1432
map_insert_overwrite_1431:
  store i8* %t6086, i8** %t6179
  %t6180 = load i8*, i8** %t6179
  call void @star_rc_release(i8* %t6180)
  %t6181 = getelementptr inbounds i32, i32* %t6149, i64 %t6177
  store i32 33, i32* %t6181
  br label %map_insert_after_1433
map_insert_new_1432:
  %t6182 = getelementptr inbounds i8, i8* %t6150, i64 %t6178
  %t6183 = load i8, i8* %t6182
  %t6184 = icmp eq i8 %t6183, 2
  br i1 %t6184, label %map_insert_dec_tomb_1434, label %map_insert_store_1435
map_insert_dec_tomb_1434:
  %t6185 = load i64, i64* %t6084
  %t6186 = sub i64 %t6185, 1
  store i64 %t6186, i64* %t6084
  br label %map_insert_store_1435
map_insert_store_1435:
  store i8 1, i8* %t6182
  %t6187 = getelementptr inbounds i8*, i8** %t6148, i64 %t6178
  store i8* %t6086, i8** %t6187
  %t6188 = getelementptr inbounds i32, i32* %t6149, i64 %t6178
  store i32 33, i32* %t6188
  %t6189 = load i64, i64* %t6080
  %t6190 = add i64 %t6189, 1
  store i64 %t6190, i64* %t6080
  br label %map_insert_after_1433
map_insert_after_1433:
  %t6191 = getelementptr i8*, i8** null, i32 1
  %t6192 = ptrtoint i8** %t6191 to i64
  %t6193 = getelementptr i32, i32* null, i32 1
  %t6194 = ptrtoint i32* %t6193 to i64
  %t6195 = load i8*, i8** %t0
  %t6196 = icmp eq i8* %t6195, null
  br i1 %t6196, label %map_cow_alloc_1436, label %map_cow_check_1437
map_cow_alloc_1436:
  %t6197 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6198 = call i8* @star_rc_alloc(i64 48, i8* %t6197)
  %t6199 = bitcast i8* %t6198 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6200 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6199, i32 0, i32 0
  store i8** null, i8*** %t6200
  %t6201 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6199, i32 0, i32 1
  store i32* null, i32** %t6201
  %t6202 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6199, i32 0, i32 2
  store i8* null, i8** %t6202
  %t6203 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6199, i32 0, i32 3
  store i64 0, i64* %t6203
  %t6204 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6199, i32 0, i32 4
  store i64 0, i64* %t6204
  %t6205 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6199, i32 0, i32 5
  store i64 0, i64* %t6205
  store i8* %t6198, i8** %t0
  br label %map_cow_done_1438
map_cow_check_1437:
  %t6206 = getelementptr inbounds i8, i8* %t6195, i64 -16
  %t6207 = bitcast i8* %t6206 to i64*
  %t6208 = load atomic i64, i64* %t6207 seq_cst, align 8
  %t6209 = icmp eq i64 %t6208, 1
  br i1 %t6209, label %map_cow_done_1438, label %map_cow_clone_1439
map_cow_clone_1439:
  %t6210 = bitcast i8* %t6195 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6211 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6210, i32 0, i32 0
  %t6212 = load i8**, i8*** %t6211
  %t6213 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6210, i32 0, i32 1
  %t6214 = load i32*, i32** %t6213
  %t6215 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6210, i32 0, i32 2
  %t6216 = load i8*, i8** %t6215
  %t6217 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6210, i32 0, i32 3
  %t6218 = load i64, i64* %t6217
  %t6219 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6210, i32 0, i32 4
  %t6220 = load i64, i64* %t6219
  %t6221 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6210, i32 0, i32 5
  %t6222 = load i64, i64* %t6221
  %t6223 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6224 = call i8* @star_rc_alloc(i64 48, i8* %t6223)
  %t6225 = bitcast i8* %t6224 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6226 = mul i64 %t6220, %t6192
  %t6227 = call i8* @malloc(i64 %t6226)
  %t6228 = bitcast i8* %t6227 to i8**
  %t6229 = mul i64 %t6220, %t6194
  %t6230 = call i8* @malloc(i64 %t6229)
  %t6231 = bitcast i8* %t6230 to i32*
  %t6232 = call i8* @malloc(i64 %t6220)
  %t6233 = icmp sgt i64 %t6220, 0
  br i1 %t6233, label %map_cow_copy_1440, label %map_cow_after_copy_1441
map_cow_copy_1440:
  %t6234 = mul i64 %t6220, %t6192
  %t6235 = bitcast i8** %t6212 to i8*
  call i8* @memcpy(i8* %t6227, i8* %t6235, i64 %t6234)
  %t6236 = mul i64 %t6220, %t6194
  %t6237 = bitcast i32* %t6214 to i8*
  call i8* @memcpy(i8* %t6230, i8* %t6237, i64 %t6236)
  call i8* @memcpy(i8* %t6232, i8* %t6216, i64 %t6220)
  store i64 0, i64* %t6238
  br label %map_cow_retain_cond_1442
map_cow_retain_cond_1442:
  %t6239 = load i64, i64* %t6238
  %t6240 = icmp slt i64 %t6239, %t6220
  br i1 %t6240, label %map_cow_retain_body_1443, label %map_cow_retain_end_1446
map_cow_retain_body_1443:
  %t6241 = getelementptr inbounds i8, i8* %t6232, i64 %t6239
  %t6242 = load i8, i8* %t6241
  %t6243 = icmp eq i8 %t6242, 1
  br i1 %t6243, label %map_cow_retain_occ_1444, label %map_cow_retain_next_1445
map_cow_retain_occ_1444:
  %t6244 = getelementptr inbounds i8*, i8** %t6228, i64 %t6239
  %t6245 = load i8*, i8** %t6244
  call void @star_rc_retain(i8* %t6245)
  br label %map_cow_retain_next_1445
map_cow_retain_next_1445:
  %t6246 = add i64 %t6239, 1
  store i64 %t6246, i64* %t6238
  br label %map_cow_retain_cond_1442
map_cow_retain_end_1446:
  br label %map_cow_after_copy_1441
map_cow_after_copy_1441:
  %t6247 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6225, i32 0, i32 0
  store i8** %t6228, i8*** %t6247
  %t6248 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6225, i32 0, i32 1
  store i32* %t6231, i32** %t6248
  %t6249 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6225, i32 0, i32 2
  store i8* %t6232, i8** %t6249
  %t6250 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6225, i32 0, i32 3
  store i64 %t6218, i64* %t6250
  %t6251 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6225, i32 0, i32 4
  store i64 %t6220, i64* %t6251
  %t6252 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6225, i32 0, i32 5
  store i64 %t6222, i64* %t6252
  call void @star_rc_release(i8* %t6195)
  store i8* %t6224, i8** %t0
  br label %map_cow_done_1438
map_cow_done_1438:
  %t6253 = load i8*, i8** %t0
  %t6254 = bitcast i8* %t6253 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6255 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6254, i32 0, i32 0
  %t6256 = load i8**, i8*** %t6255
  %t6257 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6254, i32 0, i32 1
  %t6258 = load i32*, i32** %t6257
  %t6259 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6254, i32 0, i32 2
  %t6260 = load i8*, i8** %t6259
  %t6261 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6254, i32 0, i32 3
  %t6262 = load i64, i64* %t6261
  %t6263 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6254, i32 0, i32 4
  %t6264 = load i64, i64* %t6263
  %t6265 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6254, i32 0, i32 5
  %t6266 = load i64, i64* %t6265
  %t6267 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.34, i64 0, i32 2, i64 0
  %t6268 = load i64, i64* %t6261
  %t6269 = load i64, i64* %t6263
  %t6270 = load i64, i64* %t6265
  %t6271 = add i64 %t6268, %t6270
  %t6272 = add i64 %t6271, 1
  %t6273 = mul i64 %t6272, 4
  %t6274 = mul i64 %t6269, 3
  %t6275 = icmp sgt i64 %t6273, %t6274
  br i1 %t6275, label %map_insert_grow_1447, label %map_insert_after_grow_1448
map_insert_grow_1447:
  %t6276 = getelementptr i8*, i8** null, i32 1
  %t6277 = ptrtoint i8** %t6276 to i64
  %t6278 = getelementptr i32, i32* null, i32 1
  %t6279 = ptrtoint i32* %t6278 to i64
  %t6280 = mul i64 %t6269, 2
  %t6281 = icmp sgt i64 %t6280, 0
  %t6282 = select i1 %t6281, i64 %t6280, i64 8
  %t6283 = sub i64 %t6282, 1
  %t6284 = mul i64 %t6282, %t6277
  %t6285 = call i8* @malloc(i64 %t6284)
  %t6286 = bitcast i8* %t6285 to i8**
  %t6287 = mul i64 %t6282, %t6279
  %t6288 = call i8* @malloc(i64 %t6287)
  %t6289 = bitcast i8* %t6288 to i32*
  %t6290 = call i8* @malloc(i64 %t6282)
  store i64 0, i64* %t6291
  br label %ht_fill8_cond_1449
ht_fill8_cond_1449:
  %t6292 = load i64, i64* %t6291
  %t6293 = icmp slt i64 %t6292, %t6282
  br i1 %t6293, label %ht_fill8_body_1450, label %ht_fill8_end_1451
ht_fill8_body_1450:
  %t6294 = getelementptr inbounds i8, i8* %t6290, i64 %t6292
  store i8 0, i8* %t6294
  %t6295 = add i64 %t6292, 1
  store i64 %t6295, i64* %t6291
  br label %ht_fill8_cond_1449
ht_fill8_end_1451:
  %t6296 = load i8**, i8*** %t6255
  %t6297 = load i32*, i32** %t6257
  %t6298 = load i8*, i8** %t6259
  store i64 0, i64* %t6299
  br label %map_grow_cond_1452
map_grow_cond_1452:
  %t6300 = load i64, i64* %t6299
  %t6301 = icmp slt i64 %t6300, %t6269
  br i1 %t6301, label %map_grow_body_1453, label %map_grow_end_1456
map_grow_body_1453:
  %t6302 = getelementptr inbounds i8, i8* %t6298, i64 %t6300
  %t6303 = load i8, i8* %t6302
  %t6304 = icmp eq i8 %t6303, 1
  br i1 %t6304, label %map_grow_occ_1454, label %map_grow_next_1455
map_grow_occ_1454:
  %t6305 = getelementptr inbounds i8*, i8** %t6296, i64 %t6300
  %t6306 = load i8*, i8** %t6305
  %t6307 = getelementptr inbounds i32, i32* %t6297, i64 %t6300
  %t6308 = load i32, i32* %t6307
  %t6309 = call i64 @hash_str(i8* %t6306)
  %t6310 = and i64 %t6309, %t6283
  store i64 0, i64* %t6311
  store i64 %t6310, i64* %t6312
  br label %ht_fe_cond_1457
ht_fe_cond_1457:
  %t6313 = load i64, i64* %t6311
  %t6314 = icmp slt i64 %t6313, %t6282
  br i1 %t6314, label %ht_fe_body_1458, label %ht_fe_end_1460
ht_fe_body_1458:
  %t6315 = load i64, i64* %t6312
  %t6316 = getelementptr inbounds i8, i8* %t6290, i64 %t6315
  %t6317 = load i8, i8* %t6316
  %t6318 = icmp eq i8 %t6317, 0
  br i1 %t6318, label %ht_fe_end_1460, label %ht_fe_next_1459
ht_fe_next_1459:
  %t6319 = add i64 %t6315, 1
  %t6320 = and i64 %t6319, %t6283
  store i64 %t6320, i64* %t6312
  %t6321 = add i64 %t6313, 1
  store i64 %t6321, i64* %t6311
  br label %ht_fe_cond_1457
ht_fe_end_1460:
  %t6322 = load i64, i64* %t6312
  %t6323 = getelementptr inbounds i8, i8* %t6290, i64 %t6322
  store i8 1, i8* %t6323
  %t6324 = getelementptr inbounds i8*, i8** %t6286, i64 %t6322
  store i8* %t6306, i8** %t6324
  %t6325 = getelementptr inbounds i32, i32* %t6289, i64 %t6322
  store i32 %t6308, i32* %t6325
  br label %map_grow_next_1455
map_grow_next_1455:
  %t6326 = add i64 %t6300, 1
  store i64 %t6326, i64* %t6299
  br label %map_grow_cond_1452
map_grow_end_1456:
  %t6327 = bitcast i8** %t6296 to i8*
  call void @free(i8* %t6327)
  %t6328 = bitcast i32* %t6297 to i8*
  call void @free(i8* %t6328)
  call void @free(i8* %t6298)
  store i8** %t6286, i8*** %t6255
  store i32* %t6289, i32** %t6257
  store i8* %t6290, i8** %t6259
  store i64 %t6282, i64* %t6263
  store i64 0, i64* %t6265
  br label %map_insert_after_grow_1448
map_insert_after_grow_1448:
  %t6329 = load i8**, i8*** %t6255
  %t6330 = load i32*, i32** %t6257
  %t6331 = load i8*, i8** %t6259
  %t6332 = load i64, i64* %t6263
  %t6333 = sub i64 %t6332, 1
  %t6334 = call i64 @hash_str(i8* %t6267)
  %t6335 = and i64 %t6334, %t6333
  store i64 0, i64* %t6336
  store i64 %t6335, i64* %t6337
  store i1 false, i1* %t6338
  store i64 -1, i64* %t6339
  store i64 -1, i64* %t6340
  store i1 false, i1* %t6341
  br label %ht_probe_cond_1461
ht_probe_cond_1461:
  %t6342 = load i64, i64* %t6336
  %t6343 = icmp slt i64 %t6342, %t6332
  br i1 %t6343, label %ht_probe_body_1462, label %ht_probe_end_1472
ht_probe_body_1462:
  %t6344 = load i64, i64* %t6337
  %t6345 = getelementptr inbounds i8, i8* %t6331, i64 %t6344
  %t6346 = load i8, i8* %t6345
  %t6347 = icmp eq i8 %t6346, 0
  br i1 %t6347, label %ht_probe_on_empty_1464, label %ht_probe_check_occ_1463
ht_probe_check_occ_1463:
  %t6348 = icmp eq i8 %t6346, 1
  br i1 %t6348, label %ht_probe_on_occ_1467, label %ht_probe_on_tomb_1469
ht_probe_on_empty_1464:
  %t6349 = load i1, i1* %t6341
  br i1 %t6349, label %ht_probe_after_islot_empty_1466, label %ht_probe_set_islot_empty_1465
ht_probe_set_islot_empty_1465:
  store i64 %t6344, i64* %t6340
  store i1 true, i1* %t6341
  br label %ht_probe_after_islot_empty_1466
ht_probe_after_islot_empty_1466:
  br label %ht_probe_end_1472
ht_probe_on_occ_1467:
  %t6350 = getelementptr inbounds i8*, i8** %t6329, i64 %t6344
  %t6351 = load i8*, i8** %t6350
  %t6352 = call i1 @eq_str(i8* %t6351, i8* %t6267)
  br i1 %t6352, label %ht_probe_on_match_1468, label %ht_probe_next_1471
ht_probe_on_match_1468:
  store i1 true, i1* %t6338
  store i64 %t6344, i64* %t6339
  br label %ht_probe_end_1472
ht_probe_on_tomb_1469:
  %t6353 = load i1, i1* %t6341
  br i1 %t6353, label %ht_probe_next_1471, label %ht_probe_set_islot_tomb_1470
ht_probe_set_islot_tomb_1470:
  store i64 %t6344, i64* %t6340
  store i1 true, i1* %t6341
  br label %ht_probe_next_1471
ht_probe_next_1471:
  %t6354 = add i64 %t6344, 1
  %t6355 = and i64 %t6354, %t6333
  store i64 %t6355, i64* %t6337
  %t6356 = add i64 %t6342, 1
  store i64 %t6356, i64* %t6336
  br label %ht_probe_cond_1461
ht_probe_end_1472:
  %t6357 = load i1, i1* %t6338
  %t6358 = load i64, i64* %t6339
  %t6359 = load i64, i64* %t6340
  br i1 %t6357, label %map_insert_overwrite_1473, label %map_insert_new_1474
map_insert_overwrite_1473:
  store i8* %t6267, i8** %t6360
  %t6361 = load i8*, i8** %t6360
  call void @star_rc_release(i8* %t6361)
  %t6362 = getelementptr inbounds i32, i32* %t6330, i64 %t6358
  store i32 34, i32* %t6362
  br label %map_insert_after_1475
map_insert_new_1474:
  %t6363 = getelementptr inbounds i8, i8* %t6331, i64 %t6359
  %t6364 = load i8, i8* %t6363
  %t6365 = icmp eq i8 %t6364, 2
  br i1 %t6365, label %map_insert_dec_tomb_1476, label %map_insert_store_1477
map_insert_dec_tomb_1476:
  %t6366 = load i64, i64* %t6265
  %t6367 = sub i64 %t6366, 1
  store i64 %t6367, i64* %t6265
  br label %map_insert_store_1477
map_insert_store_1477:
  store i8 1, i8* %t6363
  %t6368 = getelementptr inbounds i8*, i8** %t6329, i64 %t6359
  store i8* %t6267, i8** %t6368
  %t6369 = getelementptr inbounds i32, i32* %t6330, i64 %t6359
  store i32 34, i32* %t6369
  %t6370 = load i64, i64* %t6261
  %t6371 = add i64 %t6370, 1
  store i64 %t6371, i64* %t6261
  br label %map_insert_after_1475
map_insert_after_1475:
  %t6372 = getelementptr i8*, i8** null, i32 1
  %t6373 = ptrtoint i8** %t6372 to i64
  %t6374 = getelementptr i32, i32* null, i32 1
  %t6375 = ptrtoint i32* %t6374 to i64
  %t6376 = load i8*, i8** %t0
  %t6377 = icmp eq i8* %t6376, null
  br i1 %t6377, label %map_cow_alloc_1478, label %map_cow_check_1479
map_cow_alloc_1478:
  %t6378 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6379 = call i8* @star_rc_alloc(i64 48, i8* %t6378)
  %t6380 = bitcast i8* %t6379 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6381 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6380, i32 0, i32 0
  store i8** null, i8*** %t6381
  %t6382 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6380, i32 0, i32 1
  store i32* null, i32** %t6382
  %t6383 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6380, i32 0, i32 2
  store i8* null, i8** %t6383
  %t6384 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6380, i32 0, i32 3
  store i64 0, i64* %t6384
  %t6385 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6380, i32 0, i32 4
  store i64 0, i64* %t6385
  %t6386 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6380, i32 0, i32 5
  store i64 0, i64* %t6386
  store i8* %t6379, i8** %t0
  br label %map_cow_done_1480
map_cow_check_1479:
  %t6387 = getelementptr inbounds i8, i8* %t6376, i64 -16
  %t6388 = bitcast i8* %t6387 to i64*
  %t6389 = load atomic i64, i64* %t6388 seq_cst, align 8
  %t6390 = icmp eq i64 %t6389, 1
  br i1 %t6390, label %map_cow_done_1480, label %map_cow_clone_1481
map_cow_clone_1481:
  %t6391 = bitcast i8* %t6376 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6392 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6391, i32 0, i32 0
  %t6393 = load i8**, i8*** %t6392
  %t6394 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6391, i32 0, i32 1
  %t6395 = load i32*, i32** %t6394
  %t6396 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6391, i32 0, i32 2
  %t6397 = load i8*, i8** %t6396
  %t6398 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6391, i32 0, i32 3
  %t6399 = load i64, i64* %t6398
  %t6400 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6391, i32 0, i32 4
  %t6401 = load i64, i64* %t6400
  %t6402 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6391, i32 0, i32 5
  %t6403 = load i64, i64* %t6402
  %t6404 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6405 = call i8* @star_rc_alloc(i64 48, i8* %t6404)
  %t6406 = bitcast i8* %t6405 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6407 = mul i64 %t6401, %t6373
  %t6408 = call i8* @malloc(i64 %t6407)
  %t6409 = bitcast i8* %t6408 to i8**
  %t6410 = mul i64 %t6401, %t6375
  %t6411 = call i8* @malloc(i64 %t6410)
  %t6412 = bitcast i8* %t6411 to i32*
  %t6413 = call i8* @malloc(i64 %t6401)
  %t6414 = icmp sgt i64 %t6401, 0
  br i1 %t6414, label %map_cow_copy_1482, label %map_cow_after_copy_1483
map_cow_copy_1482:
  %t6415 = mul i64 %t6401, %t6373
  %t6416 = bitcast i8** %t6393 to i8*
  call i8* @memcpy(i8* %t6408, i8* %t6416, i64 %t6415)
  %t6417 = mul i64 %t6401, %t6375
  %t6418 = bitcast i32* %t6395 to i8*
  call i8* @memcpy(i8* %t6411, i8* %t6418, i64 %t6417)
  call i8* @memcpy(i8* %t6413, i8* %t6397, i64 %t6401)
  store i64 0, i64* %t6419
  br label %map_cow_retain_cond_1484
map_cow_retain_cond_1484:
  %t6420 = load i64, i64* %t6419
  %t6421 = icmp slt i64 %t6420, %t6401
  br i1 %t6421, label %map_cow_retain_body_1485, label %map_cow_retain_end_1488
map_cow_retain_body_1485:
  %t6422 = getelementptr inbounds i8, i8* %t6413, i64 %t6420
  %t6423 = load i8, i8* %t6422
  %t6424 = icmp eq i8 %t6423, 1
  br i1 %t6424, label %map_cow_retain_occ_1486, label %map_cow_retain_next_1487
map_cow_retain_occ_1486:
  %t6425 = getelementptr inbounds i8*, i8** %t6409, i64 %t6420
  %t6426 = load i8*, i8** %t6425
  call void @star_rc_retain(i8* %t6426)
  br label %map_cow_retain_next_1487
map_cow_retain_next_1487:
  %t6427 = add i64 %t6420, 1
  store i64 %t6427, i64* %t6419
  br label %map_cow_retain_cond_1484
map_cow_retain_end_1488:
  br label %map_cow_after_copy_1483
map_cow_after_copy_1483:
  %t6428 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6406, i32 0, i32 0
  store i8** %t6409, i8*** %t6428
  %t6429 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6406, i32 0, i32 1
  store i32* %t6412, i32** %t6429
  %t6430 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6406, i32 0, i32 2
  store i8* %t6413, i8** %t6430
  %t6431 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6406, i32 0, i32 3
  store i64 %t6399, i64* %t6431
  %t6432 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6406, i32 0, i32 4
  store i64 %t6401, i64* %t6432
  %t6433 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6406, i32 0, i32 5
  store i64 %t6403, i64* %t6433
  call void @star_rc_release(i8* %t6376)
  store i8* %t6405, i8** %t0
  br label %map_cow_done_1480
map_cow_done_1480:
  %t6434 = load i8*, i8** %t0
  %t6435 = bitcast i8* %t6434 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6436 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6435, i32 0, i32 0
  %t6437 = load i8**, i8*** %t6436
  %t6438 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6435, i32 0, i32 1
  %t6439 = load i32*, i32** %t6438
  %t6440 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6435, i32 0, i32 2
  %t6441 = load i8*, i8** %t6440
  %t6442 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6435, i32 0, i32 3
  %t6443 = load i64, i64* %t6442
  %t6444 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6435, i32 0, i32 4
  %t6445 = load i64, i64* %t6444
  %t6446 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6435, i32 0, i32 5
  %t6447 = load i64, i64* %t6446
  %t6448 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.35, i64 0, i32 2, i64 0
  %t6449 = load i64, i64* %t6442
  %t6450 = load i64, i64* %t6444
  %t6451 = load i64, i64* %t6446
  %t6452 = add i64 %t6449, %t6451
  %t6453 = add i64 %t6452, 1
  %t6454 = mul i64 %t6453, 4
  %t6455 = mul i64 %t6450, 3
  %t6456 = icmp sgt i64 %t6454, %t6455
  br i1 %t6456, label %map_insert_grow_1489, label %map_insert_after_grow_1490
map_insert_grow_1489:
  %t6457 = getelementptr i8*, i8** null, i32 1
  %t6458 = ptrtoint i8** %t6457 to i64
  %t6459 = getelementptr i32, i32* null, i32 1
  %t6460 = ptrtoint i32* %t6459 to i64
  %t6461 = mul i64 %t6450, 2
  %t6462 = icmp sgt i64 %t6461, 0
  %t6463 = select i1 %t6462, i64 %t6461, i64 8
  %t6464 = sub i64 %t6463, 1
  %t6465 = mul i64 %t6463, %t6458
  %t6466 = call i8* @malloc(i64 %t6465)
  %t6467 = bitcast i8* %t6466 to i8**
  %t6468 = mul i64 %t6463, %t6460
  %t6469 = call i8* @malloc(i64 %t6468)
  %t6470 = bitcast i8* %t6469 to i32*
  %t6471 = call i8* @malloc(i64 %t6463)
  store i64 0, i64* %t6472
  br label %ht_fill8_cond_1491
ht_fill8_cond_1491:
  %t6473 = load i64, i64* %t6472
  %t6474 = icmp slt i64 %t6473, %t6463
  br i1 %t6474, label %ht_fill8_body_1492, label %ht_fill8_end_1493
ht_fill8_body_1492:
  %t6475 = getelementptr inbounds i8, i8* %t6471, i64 %t6473
  store i8 0, i8* %t6475
  %t6476 = add i64 %t6473, 1
  store i64 %t6476, i64* %t6472
  br label %ht_fill8_cond_1491
ht_fill8_end_1493:
  %t6477 = load i8**, i8*** %t6436
  %t6478 = load i32*, i32** %t6438
  %t6479 = load i8*, i8** %t6440
  store i64 0, i64* %t6480
  br label %map_grow_cond_1494
map_grow_cond_1494:
  %t6481 = load i64, i64* %t6480
  %t6482 = icmp slt i64 %t6481, %t6450
  br i1 %t6482, label %map_grow_body_1495, label %map_grow_end_1498
map_grow_body_1495:
  %t6483 = getelementptr inbounds i8, i8* %t6479, i64 %t6481
  %t6484 = load i8, i8* %t6483
  %t6485 = icmp eq i8 %t6484, 1
  br i1 %t6485, label %map_grow_occ_1496, label %map_grow_next_1497
map_grow_occ_1496:
  %t6486 = getelementptr inbounds i8*, i8** %t6477, i64 %t6481
  %t6487 = load i8*, i8** %t6486
  %t6488 = getelementptr inbounds i32, i32* %t6478, i64 %t6481
  %t6489 = load i32, i32* %t6488
  %t6490 = call i64 @hash_str(i8* %t6487)
  %t6491 = and i64 %t6490, %t6464
  store i64 0, i64* %t6492
  store i64 %t6491, i64* %t6493
  br label %ht_fe_cond_1499
ht_fe_cond_1499:
  %t6494 = load i64, i64* %t6492
  %t6495 = icmp slt i64 %t6494, %t6463
  br i1 %t6495, label %ht_fe_body_1500, label %ht_fe_end_1502
ht_fe_body_1500:
  %t6496 = load i64, i64* %t6493
  %t6497 = getelementptr inbounds i8, i8* %t6471, i64 %t6496
  %t6498 = load i8, i8* %t6497
  %t6499 = icmp eq i8 %t6498, 0
  br i1 %t6499, label %ht_fe_end_1502, label %ht_fe_next_1501
ht_fe_next_1501:
  %t6500 = add i64 %t6496, 1
  %t6501 = and i64 %t6500, %t6464
  store i64 %t6501, i64* %t6493
  %t6502 = add i64 %t6494, 1
  store i64 %t6502, i64* %t6492
  br label %ht_fe_cond_1499
ht_fe_end_1502:
  %t6503 = load i64, i64* %t6493
  %t6504 = getelementptr inbounds i8, i8* %t6471, i64 %t6503
  store i8 1, i8* %t6504
  %t6505 = getelementptr inbounds i8*, i8** %t6467, i64 %t6503
  store i8* %t6487, i8** %t6505
  %t6506 = getelementptr inbounds i32, i32* %t6470, i64 %t6503
  store i32 %t6489, i32* %t6506
  br label %map_grow_next_1497
map_grow_next_1497:
  %t6507 = add i64 %t6481, 1
  store i64 %t6507, i64* %t6480
  br label %map_grow_cond_1494
map_grow_end_1498:
  %t6508 = bitcast i8** %t6477 to i8*
  call void @free(i8* %t6508)
  %t6509 = bitcast i32* %t6478 to i8*
  call void @free(i8* %t6509)
  call void @free(i8* %t6479)
  store i8** %t6467, i8*** %t6436
  store i32* %t6470, i32** %t6438
  store i8* %t6471, i8** %t6440
  store i64 %t6463, i64* %t6444
  store i64 0, i64* %t6446
  br label %map_insert_after_grow_1490
map_insert_after_grow_1490:
  %t6510 = load i8**, i8*** %t6436
  %t6511 = load i32*, i32** %t6438
  %t6512 = load i8*, i8** %t6440
  %t6513 = load i64, i64* %t6444
  %t6514 = sub i64 %t6513, 1
  %t6515 = call i64 @hash_str(i8* %t6448)
  %t6516 = and i64 %t6515, %t6514
  store i64 0, i64* %t6517
  store i64 %t6516, i64* %t6518
  store i1 false, i1* %t6519
  store i64 -1, i64* %t6520
  store i64 -1, i64* %t6521
  store i1 false, i1* %t6522
  br label %ht_probe_cond_1503
ht_probe_cond_1503:
  %t6523 = load i64, i64* %t6517
  %t6524 = icmp slt i64 %t6523, %t6513
  br i1 %t6524, label %ht_probe_body_1504, label %ht_probe_end_1514
ht_probe_body_1504:
  %t6525 = load i64, i64* %t6518
  %t6526 = getelementptr inbounds i8, i8* %t6512, i64 %t6525
  %t6527 = load i8, i8* %t6526
  %t6528 = icmp eq i8 %t6527, 0
  br i1 %t6528, label %ht_probe_on_empty_1506, label %ht_probe_check_occ_1505
ht_probe_check_occ_1505:
  %t6529 = icmp eq i8 %t6527, 1
  br i1 %t6529, label %ht_probe_on_occ_1509, label %ht_probe_on_tomb_1511
ht_probe_on_empty_1506:
  %t6530 = load i1, i1* %t6522
  br i1 %t6530, label %ht_probe_after_islot_empty_1508, label %ht_probe_set_islot_empty_1507
ht_probe_set_islot_empty_1507:
  store i64 %t6525, i64* %t6521
  store i1 true, i1* %t6522
  br label %ht_probe_after_islot_empty_1508
ht_probe_after_islot_empty_1508:
  br label %ht_probe_end_1514
ht_probe_on_occ_1509:
  %t6531 = getelementptr inbounds i8*, i8** %t6510, i64 %t6525
  %t6532 = load i8*, i8** %t6531
  %t6533 = call i1 @eq_str(i8* %t6532, i8* %t6448)
  br i1 %t6533, label %ht_probe_on_match_1510, label %ht_probe_next_1513
ht_probe_on_match_1510:
  store i1 true, i1* %t6519
  store i64 %t6525, i64* %t6520
  br label %ht_probe_end_1514
ht_probe_on_tomb_1511:
  %t6534 = load i1, i1* %t6522
  br i1 %t6534, label %ht_probe_next_1513, label %ht_probe_set_islot_tomb_1512
ht_probe_set_islot_tomb_1512:
  store i64 %t6525, i64* %t6521
  store i1 true, i1* %t6522
  br label %ht_probe_next_1513
ht_probe_next_1513:
  %t6535 = add i64 %t6525, 1
  %t6536 = and i64 %t6535, %t6514
  store i64 %t6536, i64* %t6518
  %t6537 = add i64 %t6523, 1
  store i64 %t6537, i64* %t6517
  br label %ht_probe_cond_1503
ht_probe_end_1514:
  %t6538 = load i1, i1* %t6519
  %t6539 = load i64, i64* %t6520
  %t6540 = load i64, i64* %t6521
  br i1 %t6538, label %map_insert_overwrite_1515, label %map_insert_new_1516
map_insert_overwrite_1515:
  store i8* %t6448, i8** %t6541
  %t6542 = load i8*, i8** %t6541
  call void @star_rc_release(i8* %t6542)
  %t6543 = getelementptr inbounds i32, i32* %t6511, i64 %t6539
  store i32 35, i32* %t6543
  br label %map_insert_after_1517
map_insert_new_1516:
  %t6544 = getelementptr inbounds i8, i8* %t6512, i64 %t6540
  %t6545 = load i8, i8* %t6544
  %t6546 = icmp eq i8 %t6545, 2
  br i1 %t6546, label %map_insert_dec_tomb_1518, label %map_insert_store_1519
map_insert_dec_tomb_1518:
  %t6547 = load i64, i64* %t6446
  %t6548 = sub i64 %t6547, 1
  store i64 %t6548, i64* %t6446
  br label %map_insert_store_1519
map_insert_store_1519:
  store i8 1, i8* %t6544
  %t6549 = getelementptr inbounds i8*, i8** %t6510, i64 %t6540
  store i8* %t6448, i8** %t6549
  %t6550 = getelementptr inbounds i32, i32* %t6511, i64 %t6540
  store i32 35, i32* %t6550
  %t6551 = load i64, i64* %t6442
  %t6552 = add i64 %t6551, 1
  store i64 %t6552, i64* %t6442
  br label %map_insert_after_1517
map_insert_after_1517:
  %t6553 = getelementptr i8*, i8** null, i32 1
  %t6554 = ptrtoint i8** %t6553 to i64
  %t6555 = getelementptr i32, i32* null, i32 1
  %t6556 = ptrtoint i32* %t6555 to i64
  %t6557 = load i8*, i8** %t0
  %t6558 = icmp eq i8* %t6557, null
  br i1 %t6558, label %map_cow_alloc_1520, label %map_cow_check_1521
map_cow_alloc_1520:
  %t6559 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6560 = call i8* @star_rc_alloc(i64 48, i8* %t6559)
  %t6561 = bitcast i8* %t6560 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6562 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6561, i32 0, i32 0
  store i8** null, i8*** %t6562
  %t6563 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6561, i32 0, i32 1
  store i32* null, i32** %t6563
  %t6564 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6561, i32 0, i32 2
  store i8* null, i8** %t6564
  %t6565 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6561, i32 0, i32 3
  store i64 0, i64* %t6565
  %t6566 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6561, i32 0, i32 4
  store i64 0, i64* %t6566
  %t6567 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6561, i32 0, i32 5
  store i64 0, i64* %t6567
  store i8* %t6560, i8** %t0
  br label %map_cow_done_1522
map_cow_check_1521:
  %t6568 = getelementptr inbounds i8, i8* %t6557, i64 -16
  %t6569 = bitcast i8* %t6568 to i64*
  %t6570 = load atomic i64, i64* %t6569 seq_cst, align 8
  %t6571 = icmp eq i64 %t6570, 1
  br i1 %t6571, label %map_cow_done_1522, label %map_cow_clone_1523
map_cow_clone_1523:
  %t6572 = bitcast i8* %t6557 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6573 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6572, i32 0, i32 0
  %t6574 = load i8**, i8*** %t6573
  %t6575 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6572, i32 0, i32 1
  %t6576 = load i32*, i32** %t6575
  %t6577 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6572, i32 0, i32 2
  %t6578 = load i8*, i8** %t6577
  %t6579 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6572, i32 0, i32 3
  %t6580 = load i64, i64* %t6579
  %t6581 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6572, i32 0, i32 4
  %t6582 = load i64, i64* %t6581
  %t6583 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6572, i32 0, i32 5
  %t6584 = load i64, i64* %t6583
  %t6585 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6586 = call i8* @star_rc_alloc(i64 48, i8* %t6585)
  %t6587 = bitcast i8* %t6586 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6588 = mul i64 %t6582, %t6554
  %t6589 = call i8* @malloc(i64 %t6588)
  %t6590 = bitcast i8* %t6589 to i8**
  %t6591 = mul i64 %t6582, %t6556
  %t6592 = call i8* @malloc(i64 %t6591)
  %t6593 = bitcast i8* %t6592 to i32*
  %t6594 = call i8* @malloc(i64 %t6582)
  %t6595 = icmp sgt i64 %t6582, 0
  br i1 %t6595, label %map_cow_copy_1524, label %map_cow_after_copy_1525
map_cow_copy_1524:
  %t6596 = mul i64 %t6582, %t6554
  %t6597 = bitcast i8** %t6574 to i8*
  call i8* @memcpy(i8* %t6589, i8* %t6597, i64 %t6596)
  %t6598 = mul i64 %t6582, %t6556
  %t6599 = bitcast i32* %t6576 to i8*
  call i8* @memcpy(i8* %t6592, i8* %t6599, i64 %t6598)
  call i8* @memcpy(i8* %t6594, i8* %t6578, i64 %t6582)
  store i64 0, i64* %t6600
  br label %map_cow_retain_cond_1526
map_cow_retain_cond_1526:
  %t6601 = load i64, i64* %t6600
  %t6602 = icmp slt i64 %t6601, %t6582
  br i1 %t6602, label %map_cow_retain_body_1527, label %map_cow_retain_end_1530
map_cow_retain_body_1527:
  %t6603 = getelementptr inbounds i8, i8* %t6594, i64 %t6601
  %t6604 = load i8, i8* %t6603
  %t6605 = icmp eq i8 %t6604, 1
  br i1 %t6605, label %map_cow_retain_occ_1528, label %map_cow_retain_next_1529
map_cow_retain_occ_1528:
  %t6606 = getelementptr inbounds i8*, i8** %t6590, i64 %t6601
  %t6607 = load i8*, i8** %t6606
  call void @star_rc_retain(i8* %t6607)
  br label %map_cow_retain_next_1529
map_cow_retain_next_1529:
  %t6608 = add i64 %t6601, 1
  store i64 %t6608, i64* %t6600
  br label %map_cow_retain_cond_1526
map_cow_retain_end_1530:
  br label %map_cow_after_copy_1525
map_cow_after_copy_1525:
  %t6609 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6587, i32 0, i32 0
  store i8** %t6590, i8*** %t6609
  %t6610 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6587, i32 0, i32 1
  store i32* %t6593, i32** %t6610
  %t6611 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6587, i32 0, i32 2
  store i8* %t6594, i8** %t6611
  %t6612 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6587, i32 0, i32 3
  store i64 %t6580, i64* %t6612
  %t6613 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6587, i32 0, i32 4
  store i64 %t6582, i64* %t6613
  %t6614 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6587, i32 0, i32 5
  store i64 %t6584, i64* %t6614
  call void @star_rc_release(i8* %t6557)
  store i8* %t6586, i8** %t0
  br label %map_cow_done_1522
map_cow_done_1522:
  %t6615 = load i8*, i8** %t0
  %t6616 = bitcast i8* %t6615 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6617 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6616, i32 0, i32 0
  %t6618 = load i8**, i8*** %t6617
  %t6619 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6616, i32 0, i32 1
  %t6620 = load i32*, i32** %t6619
  %t6621 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6616, i32 0, i32 2
  %t6622 = load i8*, i8** %t6621
  %t6623 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6616, i32 0, i32 3
  %t6624 = load i64, i64* %t6623
  %t6625 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6616, i32 0, i32 4
  %t6626 = load i64, i64* %t6625
  %t6627 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6616, i32 0, i32 5
  %t6628 = load i64, i64* %t6627
  %t6629 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.36, i64 0, i32 2, i64 0
  %t6630 = load i64, i64* %t6623
  %t6631 = load i64, i64* %t6625
  %t6632 = load i64, i64* %t6627
  %t6633 = add i64 %t6630, %t6632
  %t6634 = add i64 %t6633, 1
  %t6635 = mul i64 %t6634, 4
  %t6636 = mul i64 %t6631, 3
  %t6637 = icmp sgt i64 %t6635, %t6636
  br i1 %t6637, label %map_insert_grow_1531, label %map_insert_after_grow_1532
map_insert_grow_1531:
  %t6638 = getelementptr i8*, i8** null, i32 1
  %t6639 = ptrtoint i8** %t6638 to i64
  %t6640 = getelementptr i32, i32* null, i32 1
  %t6641 = ptrtoint i32* %t6640 to i64
  %t6642 = mul i64 %t6631, 2
  %t6643 = icmp sgt i64 %t6642, 0
  %t6644 = select i1 %t6643, i64 %t6642, i64 8
  %t6645 = sub i64 %t6644, 1
  %t6646 = mul i64 %t6644, %t6639
  %t6647 = call i8* @malloc(i64 %t6646)
  %t6648 = bitcast i8* %t6647 to i8**
  %t6649 = mul i64 %t6644, %t6641
  %t6650 = call i8* @malloc(i64 %t6649)
  %t6651 = bitcast i8* %t6650 to i32*
  %t6652 = call i8* @malloc(i64 %t6644)
  store i64 0, i64* %t6653
  br label %ht_fill8_cond_1533
ht_fill8_cond_1533:
  %t6654 = load i64, i64* %t6653
  %t6655 = icmp slt i64 %t6654, %t6644
  br i1 %t6655, label %ht_fill8_body_1534, label %ht_fill8_end_1535
ht_fill8_body_1534:
  %t6656 = getelementptr inbounds i8, i8* %t6652, i64 %t6654
  store i8 0, i8* %t6656
  %t6657 = add i64 %t6654, 1
  store i64 %t6657, i64* %t6653
  br label %ht_fill8_cond_1533
ht_fill8_end_1535:
  %t6658 = load i8**, i8*** %t6617
  %t6659 = load i32*, i32** %t6619
  %t6660 = load i8*, i8** %t6621
  store i64 0, i64* %t6661
  br label %map_grow_cond_1536
map_grow_cond_1536:
  %t6662 = load i64, i64* %t6661
  %t6663 = icmp slt i64 %t6662, %t6631
  br i1 %t6663, label %map_grow_body_1537, label %map_grow_end_1540
map_grow_body_1537:
  %t6664 = getelementptr inbounds i8, i8* %t6660, i64 %t6662
  %t6665 = load i8, i8* %t6664
  %t6666 = icmp eq i8 %t6665, 1
  br i1 %t6666, label %map_grow_occ_1538, label %map_grow_next_1539
map_grow_occ_1538:
  %t6667 = getelementptr inbounds i8*, i8** %t6658, i64 %t6662
  %t6668 = load i8*, i8** %t6667
  %t6669 = getelementptr inbounds i32, i32* %t6659, i64 %t6662
  %t6670 = load i32, i32* %t6669
  %t6671 = call i64 @hash_str(i8* %t6668)
  %t6672 = and i64 %t6671, %t6645
  store i64 0, i64* %t6673
  store i64 %t6672, i64* %t6674
  br label %ht_fe_cond_1541
ht_fe_cond_1541:
  %t6675 = load i64, i64* %t6673
  %t6676 = icmp slt i64 %t6675, %t6644
  br i1 %t6676, label %ht_fe_body_1542, label %ht_fe_end_1544
ht_fe_body_1542:
  %t6677 = load i64, i64* %t6674
  %t6678 = getelementptr inbounds i8, i8* %t6652, i64 %t6677
  %t6679 = load i8, i8* %t6678
  %t6680 = icmp eq i8 %t6679, 0
  br i1 %t6680, label %ht_fe_end_1544, label %ht_fe_next_1543
ht_fe_next_1543:
  %t6681 = add i64 %t6677, 1
  %t6682 = and i64 %t6681, %t6645
  store i64 %t6682, i64* %t6674
  %t6683 = add i64 %t6675, 1
  store i64 %t6683, i64* %t6673
  br label %ht_fe_cond_1541
ht_fe_end_1544:
  %t6684 = load i64, i64* %t6674
  %t6685 = getelementptr inbounds i8, i8* %t6652, i64 %t6684
  store i8 1, i8* %t6685
  %t6686 = getelementptr inbounds i8*, i8** %t6648, i64 %t6684
  store i8* %t6668, i8** %t6686
  %t6687 = getelementptr inbounds i32, i32* %t6651, i64 %t6684
  store i32 %t6670, i32* %t6687
  br label %map_grow_next_1539
map_grow_next_1539:
  %t6688 = add i64 %t6662, 1
  store i64 %t6688, i64* %t6661
  br label %map_grow_cond_1536
map_grow_end_1540:
  %t6689 = bitcast i8** %t6658 to i8*
  call void @free(i8* %t6689)
  %t6690 = bitcast i32* %t6659 to i8*
  call void @free(i8* %t6690)
  call void @free(i8* %t6660)
  store i8** %t6648, i8*** %t6617
  store i32* %t6651, i32** %t6619
  store i8* %t6652, i8** %t6621
  store i64 %t6644, i64* %t6625
  store i64 0, i64* %t6627
  br label %map_insert_after_grow_1532
map_insert_after_grow_1532:
  %t6691 = load i8**, i8*** %t6617
  %t6692 = load i32*, i32** %t6619
  %t6693 = load i8*, i8** %t6621
  %t6694 = load i64, i64* %t6625
  %t6695 = sub i64 %t6694, 1
  %t6696 = call i64 @hash_str(i8* %t6629)
  %t6697 = and i64 %t6696, %t6695
  store i64 0, i64* %t6698
  store i64 %t6697, i64* %t6699
  store i1 false, i1* %t6700
  store i64 -1, i64* %t6701
  store i64 -1, i64* %t6702
  store i1 false, i1* %t6703
  br label %ht_probe_cond_1545
ht_probe_cond_1545:
  %t6704 = load i64, i64* %t6698
  %t6705 = icmp slt i64 %t6704, %t6694
  br i1 %t6705, label %ht_probe_body_1546, label %ht_probe_end_1556
ht_probe_body_1546:
  %t6706 = load i64, i64* %t6699
  %t6707 = getelementptr inbounds i8, i8* %t6693, i64 %t6706
  %t6708 = load i8, i8* %t6707
  %t6709 = icmp eq i8 %t6708, 0
  br i1 %t6709, label %ht_probe_on_empty_1548, label %ht_probe_check_occ_1547
ht_probe_check_occ_1547:
  %t6710 = icmp eq i8 %t6708, 1
  br i1 %t6710, label %ht_probe_on_occ_1551, label %ht_probe_on_tomb_1553
ht_probe_on_empty_1548:
  %t6711 = load i1, i1* %t6703
  br i1 %t6711, label %ht_probe_after_islot_empty_1550, label %ht_probe_set_islot_empty_1549
ht_probe_set_islot_empty_1549:
  store i64 %t6706, i64* %t6702
  store i1 true, i1* %t6703
  br label %ht_probe_after_islot_empty_1550
ht_probe_after_islot_empty_1550:
  br label %ht_probe_end_1556
ht_probe_on_occ_1551:
  %t6712 = getelementptr inbounds i8*, i8** %t6691, i64 %t6706
  %t6713 = load i8*, i8** %t6712
  %t6714 = call i1 @eq_str(i8* %t6713, i8* %t6629)
  br i1 %t6714, label %ht_probe_on_match_1552, label %ht_probe_next_1555
ht_probe_on_match_1552:
  store i1 true, i1* %t6700
  store i64 %t6706, i64* %t6701
  br label %ht_probe_end_1556
ht_probe_on_tomb_1553:
  %t6715 = load i1, i1* %t6703
  br i1 %t6715, label %ht_probe_next_1555, label %ht_probe_set_islot_tomb_1554
ht_probe_set_islot_tomb_1554:
  store i64 %t6706, i64* %t6702
  store i1 true, i1* %t6703
  br label %ht_probe_next_1555
ht_probe_next_1555:
  %t6716 = add i64 %t6706, 1
  %t6717 = and i64 %t6716, %t6695
  store i64 %t6717, i64* %t6699
  %t6718 = add i64 %t6704, 1
  store i64 %t6718, i64* %t6698
  br label %ht_probe_cond_1545
ht_probe_end_1556:
  %t6719 = load i1, i1* %t6700
  %t6720 = load i64, i64* %t6701
  %t6721 = load i64, i64* %t6702
  br i1 %t6719, label %map_insert_overwrite_1557, label %map_insert_new_1558
map_insert_overwrite_1557:
  store i8* %t6629, i8** %t6722
  %t6723 = load i8*, i8** %t6722
  call void @star_rc_release(i8* %t6723)
  %t6724 = getelementptr inbounds i32, i32* %t6692, i64 %t6720
  store i32 36, i32* %t6724
  br label %map_insert_after_1559
map_insert_new_1558:
  %t6725 = getelementptr inbounds i8, i8* %t6693, i64 %t6721
  %t6726 = load i8, i8* %t6725
  %t6727 = icmp eq i8 %t6726, 2
  br i1 %t6727, label %map_insert_dec_tomb_1560, label %map_insert_store_1561
map_insert_dec_tomb_1560:
  %t6728 = load i64, i64* %t6627
  %t6729 = sub i64 %t6728, 1
  store i64 %t6729, i64* %t6627
  br label %map_insert_store_1561
map_insert_store_1561:
  store i8 1, i8* %t6725
  %t6730 = getelementptr inbounds i8*, i8** %t6691, i64 %t6721
  store i8* %t6629, i8** %t6730
  %t6731 = getelementptr inbounds i32, i32* %t6692, i64 %t6721
  store i32 36, i32* %t6731
  %t6732 = load i64, i64* %t6623
  %t6733 = add i64 %t6732, 1
  store i64 %t6733, i64* %t6623
  br label %map_insert_after_1559
map_insert_after_1559:
  %t6734 = getelementptr i8*, i8** null, i32 1
  %t6735 = ptrtoint i8** %t6734 to i64
  %t6736 = getelementptr i32, i32* null, i32 1
  %t6737 = ptrtoint i32* %t6736 to i64
  %t6738 = load i8*, i8** %t0
  %t6739 = icmp eq i8* %t6738, null
  br i1 %t6739, label %map_cow_alloc_1562, label %map_cow_check_1563
map_cow_alloc_1562:
  %t6740 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6741 = call i8* @star_rc_alloc(i64 48, i8* %t6740)
  %t6742 = bitcast i8* %t6741 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6743 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6742, i32 0, i32 0
  store i8** null, i8*** %t6743
  %t6744 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6742, i32 0, i32 1
  store i32* null, i32** %t6744
  %t6745 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6742, i32 0, i32 2
  store i8* null, i8** %t6745
  %t6746 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6742, i32 0, i32 3
  store i64 0, i64* %t6746
  %t6747 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6742, i32 0, i32 4
  store i64 0, i64* %t6747
  %t6748 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6742, i32 0, i32 5
  store i64 0, i64* %t6748
  store i8* %t6741, i8** %t0
  br label %map_cow_done_1564
map_cow_check_1563:
  %t6749 = getelementptr inbounds i8, i8* %t6738, i64 -16
  %t6750 = bitcast i8* %t6749 to i64*
  %t6751 = load atomic i64, i64* %t6750 seq_cst, align 8
  %t6752 = icmp eq i64 %t6751, 1
  br i1 %t6752, label %map_cow_done_1564, label %map_cow_clone_1565
map_cow_clone_1565:
  %t6753 = bitcast i8* %t6738 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6754 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6753, i32 0, i32 0
  %t6755 = load i8**, i8*** %t6754
  %t6756 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6753, i32 0, i32 1
  %t6757 = load i32*, i32** %t6756
  %t6758 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6753, i32 0, i32 2
  %t6759 = load i8*, i8** %t6758
  %t6760 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6753, i32 0, i32 3
  %t6761 = load i64, i64* %t6760
  %t6762 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6753, i32 0, i32 4
  %t6763 = load i64, i64* %t6762
  %t6764 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6753, i32 0, i32 5
  %t6765 = load i64, i64* %t6764
  %t6766 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6767 = call i8* @star_rc_alloc(i64 48, i8* %t6766)
  %t6768 = bitcast i8* %t6767 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6769 = mul i64 %t6763, %t6735
  %t6770 = call i8* @malloc(i64 %t6769)
  %t6771 = bitcast i8* %t6770 to i8**
  %t6772 = mul i64 %t6763, %t6737
  %t6773 = call i8* @malloc(i64 %t6772)
  %t6774 = bitcast i8* %t6773 to i32*
  %t6775 = call i8* @malloc(i64 %t6763)
  %t6776 = icmp sgt i64 %t6763, 0
  br i1 %t6776, label %map_cow_copy_1566, label %map_cow_after_copy_1567
map_cow_copy_1566:
  %t6777 = mul i64 %t6763, %t6735
  %t6778 = bitcast i8** %t6755 to i8*
  call i8* @memcpy(i8* %t6770, i8* %t6778, i64 %t6777)
  %t6779 = mul i64 %t6763, %t6737
  %t6780 = bitcast i32* %t6757 to i8*
  call i8* @memcpy(i8* %t6773, i8* %t6780, i64 %t6779)
  call i8* @memcpy(i8* %t6775, i8* %t6759, i64 %t6763)
  store i64 0, i64* %t6781
  br label %map_cow_retain_cond_1568
map_cow_retain_cond_1568:
  %t6782 = load i64, i64* %t6781
  %t6783 = icmp slt i64 %t6782, %t6763
  br i1 %t6783, label %map_cow_retain_body_1569, label %map_cow_retain_end_1572
map_cow_retain_body_1569:
  %t6784 = getelementptr inbounds i8, i8* %t6775, i64 %t6782
  %t6785 = load i8, i8* %t6784
  %t6786 = icmp eq i8 %t6785, 1
  br i1 %t6786, label %map_cow_retain_occ_1570, label %map_cow_retain_next_1571
map_cow_retain_occ_1570:
  %t6787 = getelementptr inbounds i8*, i8** %t6771, i64 %t6782
  %t6788 = load i8*, i8** %t6787
  call void @star_rc_retain(i8* %t6788)
  br label %map_cow_retain_next_1571
map_cow_retain_next_1571:
  %t6789 = add i64 %t6782, 1
  store i64 %t6789, i64* %t6781
  br label %map_cow_retain_cond_1568
map_cow_retain_end_1572:
  br label %map_cow_after_copy_1567
map_cow_after_copy_1567:
  %t6790 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6768, i32 0, i32 0
  store i8** %t6771, i8*** %t6790
  %t6791 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6768, i32 0, i32 1
  store i32* %t6774, i32** %t6791
  %t6792 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6768, i32 0, i32 2
  store i8* %t6775, i8** %t6792
  %t6793 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6768, i32 0, i32 3
  store i64 %t6761, i64* %t6793
  %t6794 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6768, i32 0, i32 4
  store i64 %t6763, i64* %t6794
  %t6795 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6768, i32 0, i32 5
  store i64 %t6765, i64* %t6795
  call void @star_rc_release(i8* %t6738)
  store i8* %t6767, i8** %t0
  br label %map_cow_done_1564
map_cow_done_1564:
  %t6796 = load i8*, i8** %t0
  %t6797 = bitcast i8* %t6796 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6798 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6797, i32 0, i32 0
  %t6799 = load i8**, i8*** %t6798
  %t6800 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6797, i32 0, i32 1
  %t6801 = load i32*, i32** %t6800
  %t6802 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6797, i32 0, i32 2
  %t6803 = load i8*, i8** %t6802
  %t6804 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6797, i32 0, i32 3
  %t6805 = load i64, i64* %t6804
  %t6806 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6797, i32 0, i32 4
  %t6807 = load i64, i64* %t6806
  %t6808 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6797, i32 0, i32 5
  %t6809 = load i64, i64* %t6808
  %t6810 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.37, i64 0, i32 2, i64 0
  %t6811 = load i64, i64* %t6804
  %t6812 = load i64, i64* %t6806
  %t6813 = load i64, i64* %t6808
  %t6814 = add i64 %t6811, %t6813
  %t6815 = add i64 %t6814, 1
  %t6816 = mul i64 %t6815, 4
  %t6817 = mul i64 %t6812, 3
  %t6818 = icmp sgt i64 %t6816, %t6817
  br i1 %t6818, label %map_insert_grow_1573, label %map_insert_after_grow_1574
map_insert_grow_1573:
  %t6819 = getelementptr i8*, i8** null, i32 1
  %t6820 = ptrtoint i8** %t6819 to i64
  %t6821 = getelementptr i32, i32* null, i32 1
  %t6822 = ptrtoint i32* %t6821 to i64
  %t6823 = mul i64 %t6812, 2
  %t6824 = icmp sgt i64 %t6823, 0
  %t6825 = select i1 %t6824, i64 %t6823, i64 8
  %t6826 = sub i64 %t6825, 1
  %t6827 = mul i64 %t6825, %t6820
  %t6828 = call i8* @malloc(i64 %t6827)
  %t6829 = bitcast i8* %t6828 to i8**
  %t6830 = mul i64 %t6825, %t6822
  %t6831 = call i8* @malloc(i64 %t6830)
  %t6832 = bitcast i8* %t6831 to i32*
  %t6833 = call i8* @malloc(i64 %t6825)
  store i64 0, i64* %t6834
  br label %ht_fill8_cond_1575
ht_fill8_cond_1575:
  %t6835 = load i64, i64* %t6834
  %t6836 = icmp slt i64 %t6835, %t6825
  br i1 %t6836, label %ht_fill8_body_1576, label %ht_fill8_end_1577
ht_fill8_body_1576:
  %t6837 = getelementptr inbounds i8, i8* %t6833, i64 %t6835
  store i8 0, i8* %t6837
  %t6838 = add i64 %t6835, 1
  store i64 %t6838, i64* %t6834
  br label %ht_fill8_cond_1575
ht_fill8_end_1577:
  %t6839 = load i8**, i8*** %t6798
  %t6840 = load i32*, i32** %t6800
  %t6841 = load i8*, i8** %t6802
  store i64 0, i64* %t6842
  br label %map_grow_cond_1578
map_grow_cond_1578:
  %t6843 = load i64, i64* %t6842
  %t6844 = icmp slt i64 %t6843, %t6812
  br i1 %t6844, label %map_grow_body_1579, label %map_grow_end_1582
map_grow_body_1579:
  %t6845 = getelementptr inbounds i8, i8* %t6841, i64 %t6843
  %t6846 = load i8, i8* %t6845
  %t6847 = icmp eq i8 %t6846, 1
  br i1 %t6847, label %map_grow_occ_1580, label %map_grow_next_1581
map_grow_occ_1580:
  %t6848 = getelementptr inbounds i8*, i8** %t6839, i64 %t6843
  %t6849 = load i8*, i8** %t6848
  %t6850 = getelementptr inbounds i32, i32* %t6840, i64 %t6843
  %t6851 = load i32, i32* %t6850
  %t6852 = call i64 @hash_str(i8* %t6849)
  %t6853 = and i64 %t6852, %t6826
  store i64 0, i64* %t6854
  store i64 %t6853, i64* %t6855
  br label %ht_fe_cond_1583
ht_fe_cond_1583:
  %t6856 = load i64, i64* %t6854
  %t6857 = icmp slt i64 %t6856, %t6825
  br i1 %t6857, label %ht_fe_body_1584, label %ht_fe_end_1586
ht_fe_body_1584:
  %t6858 = load i64, i64* %t6855
  %t6859 = getelementptr inbounds i8, i8* %t6833, i64 %t6858
  %t6860 = load i8, i8* %t6859
  %t6861 = icmp eq i8 %t6860, 0
  br i1 %t6861, label %ht_fe_end_1586, label %ht_fe_next_1585
ht_fe_next_1585:
  %t6862 = add i64 %t6858, 1
  %t6863 = and i64 %t6862, %t6826
  store i64 %t6863, i64* %t6855
  %t6864 = add i64 %t6856, 1
  store i64 %t6864, i64* %t6854
  br label %ht_fe_cond_1583
ht_fe_end_1586:
  %t6865 = load i64, i64* %t6855
  %t6866 = getelementptr inbounds i8, i8* %t6833, i64 %t6865
  store i8 1, i8* %t6866
  %t6867 = getelementptr inbounds i8*, i8** %t6829, i64 %t6865
  store i8* %t6849, i8** %t6867
  %t6868 = getelementptr inbounds i32, i32* %t6832, i64 %t6865
  store i32 %t6851, i32* %t6868
  br label %map_grow_next_1581
map_grow_next_1581:
  %t6869 = add i64 %t6843, 1
  store i64 %t6869, i64* %t6842
  br label %map_grow_cond_1578
map_grow_end_1582:
  %t6870 = bitcast i8** %t6839 to i8*
  call void @free(i8* %t6870)
  %t6871 = bitcast i32* %t6840 to i8*
  call void @free(i8* %t6871)
  call void @free(i8* %t6841)
  store i8** %t6829, i8*** %t6798
  store i32* %t6832, i32** %t6800
  store i8* %t6833, i8** %t6802
  store i64 %t6825, i64* %t6806
  store i64 0, i64* %t6808
  br label %map_insert_after_grow_1574
map_insert_after_grow_1574:
  %t6872 = load i8**, i8*** %t6798
  %t6873 = load i32*, i32** %t6800
  %t6874 = load i8*, i8** %t6802
  %t6875 = load i64, i64* %t6806
  %t6876 = sub i64 %t6875, 1
  %t6877 = call i64 @hash_str(i8* %t6810)
  %t6878 = and i64 %t6877, %t6876
  store i64 0, i64* %t6879
  store i64 %t6878, i64* %t6880
  store i1 false, i1* %t6881
  store i64 -1, i64* %t6882
  store i64 -1, i64* %t6883
  store i1 false, i1* %t6884
  br label %ht_probe_cond_1587
ht_probe_cond_1587:
  %t6885 = load i64, i64* %t6879
  %t6886 = icmp slt i64 %t6885, %t6875
  br i1 %t6886, label %ht_probe_body_1588, label %ht_probe_end_1598
ht_probe_body_1588:
  %t6887 = load i64, i64* %t6880
  %t6888 = getelementptr inbounds i8, i8* %t6874, i64 %t6887
  %t6889 = load i8, i8* %t6888
  %t6890 = icmp eq i8 %t6889, 0
  br i1 %t6890, label %ht_probe_on_empty_1590, label %ht_probe_check_occ_1589
ht_probe_check_occ_1589:
  %t6891 = icmp eq i8 %t6889, 1
  br i1 %t6891, label %ht_probe_on_occ_1593, label %ht_probe_on_tomb_1595
ht_probe_on_empty_1590:
  %t6892 = load i1, i1* %t6884
  br i1 %t6892, label %ht_probe_after_islot_empty_1592, label %ht_probe_set_islot_empty_1591
ht_probe_set_islot_empty_1591:
  store i64 %t6887, i64* %t6883
  store i1 true, i1* %t6884
  br label %ht_probe_after_islot_empty_1592
ht_probe_after_islot_empty_1592:
  br label %ht_probe_end_1598
ht_probe_on_occ_1593:
  %t6893 = getelementptr inbounds i8*, i8** %t6872, i64 %t6887
  %t6894 = load i8*, i8** %t6893
  %t6895 = call i1 @eq_str(i8* %t6894, i8* %t6810)
  br i1 %t6895, label %ht_probe_on_match_1594, label %ht_probe_next_1597
ht_probe_on_match_1594:
  store i1 true, i1* %t6881
  store i64 %t6887, i64* %t6882
  br label %ht_probe_end_1598
ht_probe_on_tomb_1595:
  %t6896 = load i1, i1* %t6884
  br i1 %t6896, label %ht_probe_next_1597, label %ht_probe_set_islot_tomb_1596
ht_probe_set_islot_tomb_1596:
  store i64 %t6887, i64* %t6883
  store i1 true, i1* %t6884
  br label %ht_probe_next_1597
ht_probe_next_1597:
  %t6897 = add i64 %t6887, 1
  %t6898 = and i64 %t6897, %t6876
  store i64 %t6898, i64* %t6880
  %t6899 = add i64 %t6885, 1
  store i64 %t6899, i64* %t6879
  br label %ht_probe_cond_1587
ht_probe_end_1598:
  %t6900 = load i1, i1* %t6881
  %t6901 = load i64, i64* %t6882
  %t6902 = load i64, i64* %t6883
  br i1 %t6900, label %map_insert_overwrite_1599, label %map_insert_new_1600
map_insert_overwrite_1599:
  store i8* %t6810, i8** %t6903
  %t6904 = load i8*, i8** %t6903
  call void @star_rc_release(i8* %t6904)
  %t6905 = getelementptr inbounds i32, i32* %t6873, i64 %t6901
  store i32 37, i32* %t6905
  br label %map_insert_after_1601
map_insert_new_1600:
  %t6906 = getelementptr inbounds i8, i8* %t6874, i64 %t6902
  %t6907 = load i8, i8* %t6906
  %t6908 = icmp eq i8 %t6907, 2
  br i1 %t6908, label %map_insert_dec_tomb_1602, label %map_insert_store_1603
map_insert_dec_tomb_1602:
  %t6909 = load i64, i64* %t6808
  %t6910 = sub i64 %t6909, 1
  store i64 %t6910, i64* %t6808
  br label %map_insert_store_1603
map_insert_store_1603:
  store i8 1, i8* %t6906
  %t6911 = getelementptr inbounds i8*, i8** %t6872, i64 %t6902
  store i8* %t6810, i8** %t6911
  %t6912 = getelementptr inbounds i32, i32* %t6873, i64 %t6902
  store i32 37, i32* %t6912
  %t6913 = load i64, i64* %t6804
  %t6914 = add i64 %t6913, 1
  store i64 %t6914, i64* %t6804
  br label %map_insert_after_1601
map_insert_after_1601:
  %t6915 = getelementptr i8*, i8** null, i32 1
  %t6916 = ptrtoint i8** %t6915 to i64
  %t6917 = getelementptr i32, i32* null, i32 1
  %t6918 = ptrtoint i32* %t6917 to i64
  %t6919 = load i8*, i8** %t0
  %t6920 = icmp eq i8* %t6919, null
  br i1 %t6920, label %map_cow_alloc_1604, label %map_cow_check_1605
map_cow_alloc_1604:
  %t6921 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6922 = call i8* @star_rc_alloc(i64 48, i8* %t6921)
  %t6923 = bitcast i8* %t6922 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6924 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6923, i32 0, i32 0
  store i8** null, i8*** %t6924
  %t6925 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6923, i32 0, i32 1
  store i32* null, i32** %t6925
  %t6926 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6923, i32 0, i32 2
  store i8* null, i8** %t6926
  %t6927 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6923, i32 0, i32 3
  store i64 0, i64* %t6927
  %t6928 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6923, i32 0, i32 4
  store i64 0, i64* %t6928
  %t6929 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6923, i32 0, i32 5
  store i64 0, i64* %t6929
  store i8* %t6922, i8** %t0
  br label %map_cow_done_1606
map_cow_check_1605:
  %t6930 = getelementptr inbounds i8, i8* %t6919, i64 -16
  %t6931 = bitcast i8* %t6930 to i64*
  %t6932 = load atomic i64, i64* %t6931 seq_cst, align 8
  %t6933 = icmp eq i64 %t6932, 1
  br i1 %t6933, label %map_cow_done_1606, label %map_cow_clone_1607
map_cow_clone_1607:
  %t6934 = bitcast i8* %t6919 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6935 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6934, i32 0, i32 0
  %t6936 = load i8**, i8*** %t6935
  %t6937 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6934, i32 0, i32 1
  %t6938 = load i32*, i32** %t6937
  %t6939 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6934, i32 0, i32 2
  %t6940 = load i8*, i8** %t6939
  %t6941 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6934, i32 0, i32 3
  %t6942 = load i64, i64* %t6941
  %t6943 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6934, i32 0, i32 4
  %t6944 = load i64, i64* %t6943
  %t6945 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6934, i32 0, i32 5
  %t6946 = load i64, i64* %t6945
  %t6947 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t6948 = call i8* @star_rc_alloc(i64 48, i8* %t6947)
  %t6949 = bitcast i8* %t6948 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6950 = mul i64 %t6944, %t6916
  %t6951 = call i8* @malloc(i64 %t6950)
  %t6952 = bitcast i8* %t6951 to i8**
  %t6953 = mul i64 %t6944, %t6918
  %t6954 = call i8* @malloc(i64 %t6953)
  %t6955 = bitcast i8* %t6954 to i32*
  %t6956 = call i8* @malloc(i64 %t6944)
  %t6957 = icmp sgt i64 %t6944, 0
  br i1 %t6957, label %map_cow_copy_1608, label %map_cow_after_copy_1609
map_cow_copy_1608:
  %t6958 = mul i64 %t6944, %t6916
  %t6959 = bitcast i8** %t6936 to i8*
  call i8* @memcpy(i8* %t6951, i8* %t6959, i64 %t6958)
  %t6960 = mul i64 %t6944, %t6918
  %t6961 = bitcast i32* %t6938 to i8*
  call i8* @memcpy(i8* %t6954, i8* %t6961, i64 %t6960)
  call i8* @memcpy(i8* %t6956, i8* %t6940, i64 %t6944)
  store i64 0, i64* %t6962
  br label %map_cow_retain_cond_1610
map_cow_retain_cond_1610:
  %t6963 = load i64, i64* %t6962
  %t6964 = icmp slt i64 %t6963, %t6944
  br i1 %t6964, label %map_cow_retain_body_1611, label %map_cow_retain_end_1614
map_cow_retain_body_1611:
  %t6965 = getelementptr inbounds i8, i8* %t6956, i64 %t6963
  %t6966 = load i8, i8* %t6965
  %t6967 = icmp eq i8 %t6966, 1
  br i1 %t6967, label %map_cow_retain_occ_1612, label %map_cow_retain_next_1613
map_cow_retain_occ_1612:
  %t6968 = getelementptr inbounds i8*, i8** %t6952, i64 %t6963
  %t6969 = load i8*, i8** %t6968
  call void @star_rc_retain(i8* %t6969)
  br label %map_cow_retain_next_1613
map_cow_retain_next_1613:
  %t6970 = add i64 %t6963, 1
  store i64 %t6970, i64* %t6962
  br label %map_cow_retain_cond_1610
map_cow_retain_end_1614:
  br label %map_cow_after_copy_1609
map_cow_after_copy_1609:
  %t6971 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6949, i32 0, i32 0
  store i8** %t6952, i8*** %t6971
  %t6972 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6949, i32 0, i32 1
  store i32* %t6955, i32** %t6972
  %t6973 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6949, i32 0, i32 2
  store i8* %t6956, i8** %t6973
  %t6974 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6949, i32 0, i32 3
  store i64 %t6942, i64* %t6974
  %t6975 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6949, i32 0, i32 4
  store i64 %t6944, i64* %t6975
  %t6976 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6949, i32 0, i32 5
  store i64 %t6946, i64* %t6976
  call void @star_rc_release(i8* %t6919)
  store i8* %t6948, i8** %t0
  br label %map_cow_done_1606
map_cow_done_1606:
  %t6977 = load i8*, i8** %t0
  %t6978 = bitcast i8* %t6977 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t6979 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6978, i32 0, i32 0
  %t6980 = load i8**, i8*** %t6979
  %t6981 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6978, i32 0, i32 1
  %t6982 = load i32*, i32** %t6981
  %t6983 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6978, i32 0, i32 2
  %t6984 = load i8*, i8** %t6983
  %t6985 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6978, i32 0, i32 3
  %t6986 = load i64, i64* %t6985
  %t6987 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6978, i32 0, i32 4
  %t6988 = load i64, i64* %t6987
  %t6989 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6978, i32 0, i32 5
  %t6990 = load i64, i64* %t6989
  %t6991 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.38, i64 0, i32 2, i64 0
  %t6992 = load i64, i64* %t6985
  %t6993 = load i64, i64* %t6987
  %t6994 = load i64, i64* %t6989
  %t6995 = add i64 %t6992, %t6994
  %t6996 = add i64 %t6995, 1
  %t6997 = mul i64 %t6996, 4
  %t6998 = mul i64 %t6993, 3
  %t6999 = icmp sgt i64 %t6997, %t6998
  br i1 %t6999, label %map_insert_grow_1615, label %map_insert_after_grow_1616
map_insert_grow_1615:
  %t7000 = getelementptr i8*, i8** null, i32 1
  %t7001 = ptrtoint i8** %t7000 to i64
  %t7002 = getelementptr i32, i32* null, i32 1
  %t7003 = ptrtoint i32* %t7002 to i64
  %t7004 = mul i64 %t6993, 2
  %t7005 = icmp sgt i64 %t7004, 0
  %t7006 = select i1 %t7005, i64 %t7004, i64 8
  %t7007 = sub i64 %t7006, 1
  %t7008 = mul i64 %t7006, %t7001
  %t7009 = call i8* @malloc(i64 %t7008)
  %t7010 = bitcast i8* %t7009 to i8**
  %t7011 = mul i64 %t7006, %t7003
  %t7012 = call i8* @malloc(i64 %t7011)
  %t7013 = bitcast i8* %t7012 to i32*
  %t7014 = call i8* @malloc(i64 %t7006)
  store i64 0, i64* %t7015
  br label %ht_fill8_cond_1617
ht_fill8_cond_1617:
  %t7016 = load i64, i64* %t7015
  %t7017 = icmp slt i64 %t7016, %t7006
  br i1 %t7017, label %ht_fill8_body_1618, label %ht_fill8_end_1619
ht_fill8_body_1618:
  %t7018 = getelementptr inbounds i8, i8* %t7014, i64 %t7016
  store i8 0, i8* %t7018
  %t7019 = add i64 %t7016, 1
  store i64 %t7019, i64* %t7015
  br label %ht_fill8_cond_1617
ht_fill8_end_1619:
  %t7020 = load i8**, i8*** %t6979
  %t7021 = load i32*, i32** %t6981
  %t7022 = load i8*, i8** %t6983
  store i64 0, i64* %t7023
  br label %map_grow_cond_1620
map_grow_cond_1620:
  %t7024 = load i64, i64* %t7023
  %t7025 = icmp slt i64 %t7024, %t6993
  br i1 %t7025, label %map_grow_body_1621, label %map_grow_end_1624
map_grow_body_1621:
  %t7026 = getelementptr inbounds i8, i8* %t7022, i64 %t7024
  %t7027 = load i8, i8* %t7026
  %t7028 = icmp eq i8 %t7027, 1
  br i1 %t7028, label %map_grow_occ_1622, label %map_grow_next_1623
map_grow_occ_1622:
  %t7029 = getelementptr inbounds i8*, i8** %t7020, i64 %t7024
  %t7030 = load i8*, i8** %t7029
  %t7031 = getelementptr inbounds i32, i32* %t7021, i64 %t7024
  %t7032 = load i32, i32* %t7031
  %t7033 = call i64 @hash_str(i8* %t7030)
  %t7034 = and i64 %t7033, %t7007
  store i64 0, i64* %t7035
  store i64 %t7034, i64* %t7036
  br label %ht_fe_cond_1625
ht_fe_cond_1625:
  %t7037 = load i64, i64* %t7035
  %t7038 = icmp slt i64 %t7037, %t7006
  br i1 %t7038, label %ht_fe_body_1626, label %ht_fe_end_1628
ht_fe_body_1626:
  %t7039 = load i64, i64* %t7036
  %t7040 = getelementptr inbounds i8, i8* %t7014, i64 %t7039
  %t7041 = load i8, i8* %t7040
  %t7042 = icmp eq i8 %t7041, 0
  br i1 %t7042, label %ht_fe_end_1628, label %ht_fe_next_1627
ht_fe_next_1627:
  %t7043 = add i64 %t7039, 1
  %t7044 = and i64 %t7043, %t7007
  store i64 %t7044, i64* %t7036
  %t7045 = add i64 %t7037, 1
  store i64 %t7045, i64* %t7035
  br label %ht_fe_cond_1625
ht_fe_end_1628:
  %t7046 = load i64, i64* %t7036
  %t7047 = getelementptr inbounds i8, i8* %t7014, i64 %t7046
  store i8 1, i8* %t7047
  %t7048 = getelementptr inbounds i8*, i8** %t7010, i64 %t7046
  store i8* %t7030, i8** %t7048
  %t7049 = getelementptr inbounds i32, i32* %t7013, i64 %t7046
  store i32 %t7032, i32* %t7049
  br label %map_grow_next_1623
map_grow_next_1623:
  %t7050 = add i64 %t7024, 1
  store i64 %t7050, i64* %t7023
  br label %map_grow_cond_1620
map_grow_end_1624:
  %t7051 = bitcast i8** %t7020 to i8*
  call void @free(i8* %t7051)
  %t7052 = bitcast i32* %t7021 to i8*
  call void @free(i8* %t7052)
  call void @free(i8* %t7022)
  store i8** %t7010, i8*** %t6979
  store i32* %t7013, i32** %t6981
  store i8* %t7014, i8** %t6983
  store i64 %t7006, i64* %t6987
  store i64 0, i64* %t6989
  br label %map_insert_after_grow_1616
map_insert_after_grow_1616:
  %t7053 = load i8**, i8*** %t6979
  %t7054 = load i32*, i32** %t6981
  %t7055 = load i8*, i8** %t6983
  %t7056 = load i64, i64* %t6987
  %t7057 = sub i64 %t7056, 1
  %t7058 = call i64 @hash_str(i8* %t6991)
  %t7059 = and i64 %t7058, %t7057
  store i64 0, i64* %t7060
  store i64 %t7059, i64* %t7061
  store i1 false, i1* %t7062
  store i64 -1, i64* %t7063
  store i64 -1, i64* %t7064
  store i1 false, i1* %t7065
  br label %ht_probe_cond_1629
ht_probe_cond_1629:
  %t7066 = load i64, i64* %t7060
  %t7067 = icmp slt i64 %t7066, %t7056
  br i1 %t7067, label %ht_probe_body_1630, label %ht_probe_end_1640
ht_probe_body_1630:
  %t7068 = load i64, i64* %t7061
  %t7069 = getelementptr inbounds i8, i8* %t7055, i64 %t7068
  %t7070 = load i8, i8* %t7069
  %t7071 = icmp eq i8 %t7070, 0
  br i1 %t7071, label %ht_probe_on_empty_1632, label %ht_probe_check_occ_1631
ht_probe_check_occ_1631:
  %t7072 = icmp eq i8 %t7070, 1
  br i1 %t7072, label %ht_probe_on_occ_1635, label %ht_probe_on_tomb_1637
ht_probe_on_empty_1632:
  %t7073 = load i1, i1* %t7065
  br i1 %t7073, label %ht_probe_after_islot_empty_1634, label %ht_probe_set_islot_empty_1633
ht_probe_set_islot_empty_1633:
  store i64 %t7068, i64* %t7064
  store i1 true, i1* %t7065
  br label %ht_probe_after_islot_empty_1634
ht_probe_after_islot_empty_1634:
  br label %ht_probe_end_1640
ht_probe_on_occ_1635:
  %t7074 = getelementptr inbounds i8*, i8** %t7053, i64 %t7068
  %t7075 = load i8*, i8** %t7074
  %t7076 = call i1 @eq_str(i8* %t7075, i8* %t6991)
  br i1 %t7076, label %ht_probe_on_match_1636, label %ht_probe_next_1639
ht_probe_on_match_1636:
  store i1 true, i1* %t7062
  store i64 %t7068, i64* %t7063
  br label %ht_probe_end_1640
ht_probe_on_tomb_1637:
  %t7077 = load i1, i1* %t7065
  br i1 %t7077, label %ht_probe_next_1639, label %ht_probe_set_islot_tomb_1638
ht_probe_set_islot_tomb_1638:
  store i64 %t7068, i64* %t7064
  store i1 true, i1* %t7065
  br label %ht_probe_next_1639
ht_probe_next_1639:
  %t7078 = add i64 %t7068, 1
  %t7079 = and i64 %t7078, %t7057
  store i64 %t7079, i64* %t7061
  %t7080 = add i64 %t7066, 1
  store i64 %t7080, i64* %t7060
  br label %ht_probe_cond_1629
ht_probe_end_1640:
  %t7081 = load i1, i1* %t7062
  %t7082 = load i64, i64* %t7063
  %t7083 = load i64, i64* %t7064
  br i1 %t7081, label %map_insert_overwrite_1641, label %map_insert_new_1642
map_insert_overwrite_1641:
  store i8* %t6991, i8** %t7084
  %t7085 = load i8*, i8** %t7084
  call void @star_rc_release(i8* %t7085)
  %t7086 = getelementptr inbounds i32, i32* %t7054, i64 %t7082
  store i32 38, i32* %t7086
  br label %map_insert_after_1643
map_insert_new_1642:
  %t7087 = getelementptr inbounds i8, i8* %t7055, i64 %t7083
  %t7088 = load i8, i8* %t7087
  %t7089 = icmp eq i8 %t7088, 2
  br i1 %t7089, label %map_insert_dec_tomb_1644, label %map_insert_store_1645
map_insert_dec_tomb_1644:
  %t7090 = load i64, i64* %t6989
  %t7091 = sub i64 %t7090, 1
  store i64 %t7091, i64* %t6989
  br label %map_insert_store_1645
map_insert_store_1645:
  store i8 1, i8* %t7087
  %t7092 = getelementptr inbounds i8*, i8** %t7053, i64 %t7083
  store i8* %t6991, i8** %t7092
  %t7093 = getelementptr inbounds i32, i32* %t7054, i64 %t7083
  store i32 38, i32* %t7093
  %t7094 = load i64, i64* %t6985
  %t7095 = add i64 %t7094, 1
  store i64 %t7095, i64* %t6985
  br label %map_insert_after_1643
map_insert_after_1643:
  %t7096 = getelementptr i8*, i8** null, i32 1
  %t7097 = ptrtoint i8** %t7096 to i64
  %t7098 = getelementptr i32, i32* null, i32 1
  %t7099 = ptrtoint i32* %t7098 to i64
  %t7100 = load i8*, i8** %t0
  %t7101 = icmp eq i8* %t7100, null
  br i1 %t7101, label %map_cow_alloc_1646, label %map_cow_check_1647
map_cow_alloc_1646:
  %t7102 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7103 = call i8* @star_rc_alloc(i64 48, i8* %t7102)
  %t7104 = bitcast i8* %t7103 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7105 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7104, i32 0, i32 0
  store i8** null, i8*** %t7105
  %t7106 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7104, i32 0, i32 1
  store i32* null, i32** %t7106
  %t7107 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7104, i32 0, i32 2
  store i8* null, i8** %t7107
  %t7108 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7104, i32 0, i32 3
  store i64 0, i64* %t7108
  %t7109 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7104, i32 0, i32 4
  store i64 0, i64* %t7109
  %t7110 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7104, i32 0, i32 5
  store i64 0, i64* %t7110
  store i8* %t7103, i8** %t0
  br label %map_cow_done_1648
map_cow_check_1647:
  %t7111 = getelementptr inbounds i8, i8* %t7100, i64 -16
  %t7112 = bitcast i8* %t7111 to i64*
  %t7113 = load atomic i64, i64* %t7112 seq_cst, align 8
  %t7114 = icmp eq i64 %t7113, 1
  br i1 %t7114, label %map_cow_done_1648, label %map_cow_clone_1649
map_cow_clone_1649:
  %t7115 = bitcast i8* %t7100 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7116 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7115, i32 0, i32 0
  %t7117 = load i8**, i8*** %t7116
  %t7118 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7115, i32 0, i32 1
  %t7119 = load i32*, i32** %t7118
  %t7120 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7115, i32 0, i32 2
  %t7121 = load i8*, i8** %t7120
  %t7122 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7115, i32 0, i32 3
  %t7123 = load i64, i64* %t7122
  %t7124 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7115, i32 0, i32 4
  %t7125 = load i64, i64* %t7124
  %t7126 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7115, i32 0, i32 5
  %t7127 = load i64, i64* %t7126
  %t7128 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7129 = call i8* @star_rc_alloc(i64 48, i8* %t7128)
  %t7130 = bitcast i8* %t7129 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7131 = mul i64 %t7125, %t7097
  %t7132 = call i8* @malloc(i64 %t7131)
  %t7133 = bitcast i8* %t7132 to i8**
  %t7134 = mul i64 %t7125, %t7099
  %t7135 = call i8* @malloc(i64 %t7134)
  %t7136 = bitcast i8* %t7135 to i32*
  %t7137 = call i8* @malloc(i64 %t7125)
  %t7138 = icmp sgt i64 %t7125, 0
  br i1 %t7138, label %map_cow_copy_1650, label %map_cow_after_copy_1651
map_cow_copy_1650:
  %t7139 = mul i64 %t7125, %t7097
  %t7140 = bitcast i8** %t7117 to i8*
  call i8* @memcpy(i8* %t7132, i8* %t7140, i64 %t7139)
  %t7141 = mul i64 %t7125, %t7099
  %t7142 = bitcast i32* %t7119 to i8*
  call i8* @memcpy(i8* %t7135, i8* %t7142, i64 %t7141)
  call i8* @memcpy(i8* %t7137, i8* %t7121, i64 %t7125)
  store i64 0, i64* %t7143
  br label %map_cow_retain_cond_1652
map_cow_retain_cond_1652:
  %t7144 = load i64, i64* %t7143
  %t7145 = icmp slt i64 %t7144, %t7125
  br i1 %t7145, label %map_cow_retain_body_1653, label %map_cow_retain_end_1656
map_cow_retain_body_1653:
  %t7146 = getelementptr inbounds i8, i8* %t7137, i64 %t7144
  %t7147 = load i8, i8* %t7146
  %t7148 = icmp eq i8 %t7147, 1
  br i1 %t7148, label %map_cow_retain_occ_1654, label %map_cow_retain_next_1655
map_cow_retain_occ_1654:
  %t7149 = getelementptr inbounds i8*, i8** %t7133, i64 %t7144
  %t7150 = load i8*, i8** %t7149
  call void @star_rc_retain(i8* %t7150)
  br label %map_cow_retain_next_1655
map_cow_retain_next_1655:
  %t7151 = add i64 %t7144, 1
  store i64 %t7151, i64* %t7143
  br label %map_cow_retain_cond_1652
map_cow_retain_end_1656:
  br label %map_cow_after_copy_1651
map_cow_after_copy_1651:
  %t7152 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7130, i32 0, i32 0
  store i8** %t7133, i8*** %t7152
  %t7153 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7130, i32 0, i32 1
  store i32* %t7136, i32** %t7153
  %t7154 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7130, i32 0, i32 2
  store i8* %t7137, i8** %t7154
  %t7155 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7130, i32 0, i32 3
  store i64 %t7123, i64* %t7155
  %t7156 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7130, i32 0, i32 4
  store i64 %t7125, i64* %t7156
  %t7157 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7130, i32 0, i32 5
  store i64 %t7127, i64* %t7157
  call void @star_rc_release(i8* %t7100)
  store i8* %t7129, i8** %t0
  br label %map_cow_done_1648
map_cow_done_1648:
  %t7158 = load i8*, i8** %t0
  %t7159 = bitcast i8* %t7158 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7160 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7159, i32 0, i32 0
  %t7161 = load i8**, i8*** %t7160
  %t7162 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7159, i32 0, i32 1
  %t7163 = load i32*, i32** %t7162
  %t7164 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7159, i32 0, i32 2
  %t7165 = load i8*, i8** %t7164
  %t7166 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7159, i32 0, i32 3
  %t7167 = load i64, i64* %t7166
  %t7168 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7159, i32 0, i32 4
  %t7169 = load i64, i64* %t7168
  %t7170 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7159, i32 0, i32 5
  %t7171 = load i64, i64* %t7170
  %t7172 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.39, i64 0, i32 2, i64 0
  %t7173 = load i64, i64* %t7166
  %t7174 = load i64, i64* %t7168
  %t7175 = load i64, i64* %t7170
  %t7176 = add i64 %t7173, %t7175
  %t7177 = add i64 %t7176, 1
  %t7178 = mul i64 %t7177, 4
  %t7179 = mul i64 %t7174, 3
  %t7180 = icmp sgt i64 %t7178, %t7179
  br i1 %t7180, label %map_insert_grow_1657, label %map_insert_after_grow_1658
map_insert_grow_1657:
  %t7181 = getelementptr i8*, i8** null, i32 1
  %t7182 = ptrtoint i8** %t7181 to i64
  %t7183 = getelementptr i32, i32* null, i32 1
  %t7184 = ptrtoint i32* %t7183 to i64
  %t7185 = mul i64 %t7174, 2
  %t7186 = icmp sgt i64 %t7185, 0
  %t7187 = select i1 %t7186, i64 %t7185, i64 8
  %t7188 = sub i64 %t7187, 1
  %t7189 = mul i64 %t7187, %t7182
  %t7190 = call i8* @malloc(i64 %t7189)
  %t7191 = bitcast i8* %t7190 to i8**
  %t7192 = mul i64 %t7187, %t7184
  %t7193 = call i8* @malloc(i64 %t7192)
  %t7194 = bitcast i8* %t7193 to i32*
  %t7195 = call i8* @malloc(i64 %t7187)
  store i64 0, i64* %t7196
  br label %ht_fill8_cond_1659
ht_fill8_cond_1659:
  %t7197 = load i64, i64* %t7196
  %t7198 = icmp slt i64 %t7197, %t7187
  br i1 %t7198, label %ht_fill8_body_1660, label %ht_fill8_end_1661
ht_fill8_body_1660:
  %t7199 = getelementptr inbounds i8, i8* %t7195, i64 %t7197
  store i8 0, i8* %t7199
  %t7200 = add i64 %t7197, 1
  store i64 %t7200, i64* %t7196
  br label %ht_fill8_cond_1659
ht_fill8_end_1661:
  %t7201 = load i8**, i8*** %t7160
  %t7202 = load i32*, i32** %t7162
  %t7203 = load i8*, i8** %t7164
  store i64 0, i64* %t7204
  br label %map_grow_cond_1662
map_grow_cond_1662:
  %t7205 = load i64, i64* %t7204
  %t7206 = icmp slt i64 %t7205, %t7174
  br i1 %t7206, label %map_grow_body_1663, label %map_grow_end_1666
map_grow_body_1663:
  %t7207 = getelementptr inbounds i8, i8* %t7203, i64 %t7205
  %t7208 = load i8, i8* %t7207
  %t7209 = icmp eq i8 %t7208, 1
  br i1 %t7209, label %map_grow_occ_1664, label %map_grow_next_1665
map_grow_occ_1664:
  %t7210 = getelementptr inbounds i8*, i8** %t7201, i64 %t7205
  %t7211 = load i8*, i8** %t7210
  %t7212 = getelementptr inbounds i32, i32* %t7202, i64 %t7205
  %t7213 = load i32, i32* %t7212
  %t7214 = call i64 @hash_str(i8* %t7211)
  %t7215 = and i64 %t7214, %t7188
  store i64 0, i64* %t7216
  store i64 %t7215, i64* %t7217
  br label %ht_fe_cond_1667
ht_fe_cond_1667:
  %t7218 = load i64, i64* %t7216
  %t7219 = icmp slt i64 %t7218, %t7187
  br i1 %t7219, label %ht_fe_body_1668, label %ht_fe_end_1670
ht_fe_body_1668:
  %t7220 = load i64, i64* %t7217
  %t7221 = getelementptr inbounds i8, i8* %t7195, i64 %t7220
  %t7222 = load i8, i8* %t7221
  %t7223 = icmp eq i8 %t7222, 0
  br i1 %t7223, label %ht_fe_end_1670, label %ht_fe_next_1669
ht_fe_next_1669:
  %t7224 = add i64 %t7220, 1
  %t7225 = and i64 %t7224, %t7188
  store i64 %t7225, i64* %t7217
  %t7226 = add i64 %t7218, 1
  store i64 %t7226, i64* %t7216
  br label %ht_fe_cond_1667
ht_fe_end_1670:
  %t7227 = load i64, i64* %t7217
  %t7228 = getelementptr inbounds i8, i8* %t7195, i64 %t7227
  store i8 1, i8* %t7228
  %t7229 = getelementptr inbounds i8*, i8** %t7191, i64 %t7227
  store i8* %t7211, i8** %t7229
  %t7230 = getelementptr inbounds i32, i32* %t7194, i64 %t7227
  store i32 %t7213, i32* %t7230
  br label %map_grow_next_1665
map_grow_next_1665:
  %t7231 = add i64 %t7205, 1
  store i64 %t7231, i64* %t7204
  br label %map_grow_cond_1662
map_grow_end_1666:
  %t7232 = bitcast i8** %t7201 to i8*
  call void @free(i8* %t7232)
  %t7233 = bitcast i32* %t7202 to i8*
  call void @free(i8* %t7233)
  call void @free(i8* %t7203)
  store i8** %t7191, i8*** %t7160
  store i32* %t7194, i32** %t7162
  store i8* %t7195, i8** %t7164
  store i64 %t7187, i64* %t7168
  store i64 0, i64* %t7170
  br label %map_insert_after_grow_1658
map_insert_after_grow_1658:
  %t7234 = load i8**, i8*** %t7160
  %t7235 = load i32*, i32** %t7162
  %t7236 = load i8*, i8** %t7164
  %t7237 = load i64, i64* %t7168
  %t7238 = sub i64 %t7237, 1
  %t7239 = call i64 @hash_str(i8* %t7172)
  %t7240 = and i64 %t7239, %t7238
  store i64 0, i64* %t7241
  store i64 %t7240, i64* %t7242
  store i1 false, i1* %t7243
  store i64 -1, i64* %t7244
  store i64 -1, i64* %t7245
  store i1 false, i1* %t7246
  br label %ht_probe_cond_1671
ht_probe_cond_1671:
  %t7247 = load i64, i64* %t7241
  %t7248 = icmp slt i64 %t7247, %t7237
  br i1 %t7248, label %ht_probe_body_1672, label %ht_probe_end_1682
ht_probe_body_1672:
  %t7249 = load i64, i64* %t7242
  %t7250 = getelementptr inbounds i8, i8* %t7236, i64 %t7249
  %t7251 = load i8, i8* %t7250
  %t7252 = icmp eq i8 %t7251, 0
  br i1 %t7252, label %ht_probe_on_empty_1674, label %ht_probe_check_occ_1673
ht_probe_check_occ_1673:
  %t7253 = icmp eq i8 %t7251, 1
  br i1 %t7253, label %ht_probe_on_occ_1677, label %ht_probe_on_tomb_1679
ht_probe_on_empty_1674:
  %t7254 = load i1, i1* %t7246
  br i1 %t7254, label %ht_probe_after_islot_empty_1676, label %ht_probe_set_islot_empty_1675
ht_probe_set_islot_empty_1675:
  store i64 %t7249, i64* %t7245
  store i1 true, i1* %t7246
  br label %ht_probe_after_islot_empty_1676
ht_probe_after_islot_empty_1676:
  br label %ht_probe_end_1682
ht_probe_on_occ_1677:
  %t7255 = getelementptr inbounds i8*, i8** %t7234, i64 %t7249
  %t7256 = load i8*, i8** %t7255
  %t7257 = call i1 @eq_str(i8* %t7256, i8* %t7172)
  br i1 %t7257, label %ht_probe_on_match_1678, label %ht_probe_next_1681
ht_probe_on_match_1678:
  store i1 true, i1* %t7243
  store i64 %t7249, i64* %t7244
  br label %ht_probe_end_1682
ht_probe_on_tomb_1679:
  %t7258 = load i1, i1* %t7246
  br i1 %t7258, label %ht_probe_next_1681, label %ht_probe_set_islot_tomb_1680
ht_probe_set_islot_tomb_1680:
  store i64 %t7249, i64* %t7245
  store i1 true, i1* %t7246
  br label %ht_probe_next_1681
ht_probe_next_1681:
  %t7259 = add i64 %t7249, 1
  %t7260 = and i64 %t7259, %t7238
  store i64 %t7260, i64* %t7242
  %t7261 = add i64 %t7247, 1
  store i64 %t7261, i64* %t7241
  br label %ht_probe_cond_1671
ht_probe_end_1682:
  %t7262 = load i1, i1* %t7243
  %t7263 = load i64, i64* %t7244
  %t7264 = load i64, i64* %t7245
  br i1 %t7262, label %map_insert_overwrite_1683, label %map_insert_new_1684
map_insert_overwrite_1683:
  store i8* %t7172, i8** %t7265
  %t7266 = load i8*, i8** %t7265
  call void @star_rc_release(i8* %t7266)
  %t7267 = getelementptr inbounds i32, i32* %t7235, i64 %t7263
  store i32 39, i32* %t7267
  br label %map_insert_after_1685
map_insert_new_1684:
  %t7268 = getelementptr inbounds i8, i8* %t7236, i64 %t7264
  %t7269 = load i8, i8* %t7268
  %t7270 = icmp eq i8 %t7269, 2
  br i1 %t7270, label %map_insert_dec_tomb_1686, label %map_insert_store_1687
map_insert_dec_tomb_1686:
  %t7271 = load i64, i64* %t7170
  %t7272 = sub i64 %t7271, 1
  store i64 %t7272, i64* %t7170
  br label %map_insert_store_1687
map_insert_store_1687:
  store i8 1, i8* %t7268
  %t7273 = getelementptr inbounds i8*, i8** %t7234, i64 %t7264
  store i8* %t7172, i8** %t7273
  %t7274 = getelementptr inbounds i32, i32* %t7235, i64 %t7264
  store i32 39, i32* %t7274
  %t7275 = load i64, i64* %t7166
  %t7276 = add i64 %t7275, 1
  store i64 %t7276, i64* %t7166
  br label %map_insert_after_1685
map_insert_after_1685:
  %t7277 = getelementptr i8*, i8** null, i32 1
  %t7278 = ptrtoint i8** %t7277 to i64
  %t7279 = getelementptr i32, i32* null, i32 1
  %t7280 = ptrtoint i32* %t7279 to i64
  %t7281 = load i8*, i8** %t0
  %t7282 = icmp eq i8* %t7281, null
  br i1 %t7282, label %map_cow_alloc_1688, label %map_cow_check_1689
map_cow_alloc_1688:
  %t7283 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7284 = call i8* @star_rc_alloc(i64 48, i8* %t7283)
  %t7285 = bitcast i8* %t7284 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7286 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7285, i32 0, i32 0
  store i8** null, i8*** %t7286
  %t7287 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7285, i32 0, i32 1
  store i32* null, i32** %t7287
  %t7288 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7285, i32 0, i32 2
  store i8* null, i8** %t7288
  %t7289 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7285, i32 0, i32 3
  store i64 0, i64* %t7289
  %t7290 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7285, i32 0, i32 4
  store i64 0, i64* %t7290
  %t7291 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7285, i32 0, i32 5
  store i64 0, i64* %t7291
  store i8* %t7284, i8** %t0
  br label %map_cow_done_1690
map_cow_check_1689:
  %t7292 = getelementptr inbounds i8, i8* %t7281, i64 -16
  %t7293 = bitcast i8* %t7292 to i64*
  %t7294 = load atomic i64, i64* %t7293 seq_cst, align 8
  %t7295 = icmp eq i64 %t7294, 1
  br i1 %t7295, label %map_cow_done_1690, label %map_cow_clone_1691
map_cow_clone_1691:
  %t7296 = bitcast i8* %t7281 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7297 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7296, i32 0, i32 0
  %t7298 = load i8**, i8*** %t7297
  %t7299 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7296, i32 0, i32 1
  %t7300 = load i32*, i32** %t7299
  %t7301 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7296, i32 0, i32 2
  %t7302 = load i8*, i8** %t7301
  %t7303 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7296, i32 0, i32 3
  %t7304 = load i64, i64* %t7303
  %t7305 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7296, i32 0, i32 4
  %t7306 = load i64, i64* %t7305
  %t7307 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7296, i32 0, i32 5
  %t7308 = load i64, i64* %t7307
  %t7309 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7310 = call i8* @star_rc_alloc(i64 48, i8* %t7309)
  %t7311 = bitcast i8* %t7310 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7312 = mul i64 %t7306, %t7278
  %t7313 = call i8* @malloc(i64 %t7312)
  %t7314 = bitcast i8* %t7313 to i8**
  %t7315 = mul i64 %t7306, %t7280
  %t7316 = call i8* @malloc(i64 %t7315)
  %t7317 = bitcast i8* %t7316 to i32*
  %t7318 = call i8* @malloc(i64 %t7306)
  %t7319 = icmp sgt i64 %t7306, 0
  br i1 %t7319, label %map_cow_copy_1692, label %map_cow_after_copy_1693
map_cow_copy_1692:
  %t7320 = mul i64 %t7306, %t7278
  %t7321 = bitcast i8** %t7298 to i8*
  call i8* @memcpy(i8* %t7313, i8* %t7321, i64 %t7320)
  %t7322 = mul i64 %t7306, %t7280
  %t7323 = bitcast i32* %t7300 to i8*
  call i8* @memcpy(i8* %t7316, i8* %t7323, i64 %t7322)
  call i8* @memcpy(i8* %t7318, i8* %t7302, i64 %t7306)
  store i64 0, i64* %t7324
  br label %map_cow_retain_cond_1694
map_cow_retain_cond_1694:
  %t7325 = load i64, i64* %t7324
  %t7326 = icmp slt i64 %t7325, %t7306
  br i1 %t7326, label %map_cow_retain_body_1695, label %map_cow_retain_end_1698
map_cow_retain_body_1695:
  %t7327 = getelementptr inbounds i8, i8* %t7318, i64 %t7325
  %t7328 = load i8, i8* %t7327
  %t7329 = icmp eq i8 %t7328, 1
  br i1 %t7329, label %map_cow_retain_occ_1696, label %map_cow_retain_next_1697
map_cow_retain_occ_1696:
  %t7330 = getelementptr inbounds i8*, i8** %t7314, i64 %t7325
  %t7331 = load i8*, i8** %t7330
  call void @star_rc_retain(i8* %t7331)
  br label %map_cow_retain_next_1697
map_cow_retain_next_1697:
  %t7332 = add i64 %t7325, 1
  store i64 %t7332, i64* %t7324
  br label %map_cow_retain_cond_1694
map_cow_retain_end_1698:
  br label %map_cow_after_copy_1693
map_cow_after_copy_1693:
  %t7333 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7311, i32 0, i32 0
  store i8** %t7314, i8*** %t7333
  %t7334 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7311, i32 0, i32 1
  store i32* %t7317, i32** %t7334
  %t7335 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7311, i32 0, i32 2
  store i8* %t7318, i8** %t7335
  %t7336 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7311, i32 0, i32 3
  store i64 %t7304, i64* %t7336
  %t7337 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7311, i32 0, i32 4
  store i64 %t7306, i64* %t7337
  %t7338 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7311, i32 0, i32 5
  store i64 %t7308, i64* %t7338
  call void @star_rc_release(i8* %t7281)
  store i8* %t7310, i8** %t0
  br label %map_cow_done_1690
map_cow_done_1690:
  %t7339 = load i8*, i8** %t0
  %t7340 = bitcast i8* %t7339 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7341 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7340, i32 0, i32 0
  %t7342 = load i8**, i8*** %t7341
  %t7343 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7340, i32 0, i32 1
  %t7344 = load i32*, i32** %t7343
  %t7345 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7340, i32 0, i32 2
  %t7346 = load i8*, i8** %t7345
  %t7347 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7340, i32 0, i32 3
  %t7348 = load i64, i64* %t7347
  %t7349 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7340, i32 0, i32 4
  %t7350 = load i64, i64* %t7349
  %t7351 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7340, i32 0, i32 5
  %t7352 = load i64, i64* %t7351
  %t7353 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.40, i64 0, i32 2, i64 0
  %t7354 = load i64, i64* %t7347
  %t7355 = load i64, i64* %t7349
  %t7356 = load i64, i64* %t7351
  %t7357 = add i64 %t7354, %t7356
  %t7358 = add i64 %t7357, 1
  %t7359 = mul i64 %t7358, 4
  %t7360 = mul i64 %t7355, 3
  %t7361 = icmp sgt i64 %t7359, %t7360
  br i1 %t7361, label %map_insert_grow_1699, label %map_insert_after_grow_1700
map_insert_grow_1699:
  %t7362 = getelementptr i8*, i8** null, i32 1
  %t7363 = ptrtoint i8** %t7362 to i64
  %t7364 = getelementptr i32, i32* null, i32 1
  %t7365 = ptrtoint i32* %t7364 to i64
  %t7366 = mul i64 %t7355, 2
  %t7367 = icmp sgt i64 %t7366, 0
  %t7368 = select i1 %t7367, i64 %t7366, i64 8
  %t7369 = sub i64 %t7368, 1
  %t7370 = mul i64 %t7368, %t7363
  %t7371 = call i8* @malloc(i64 %t7370)
  %t7372 = bitcast i8* %t7371 to i8**
  %t7373 = mul i64 %t7368, %t7365
  %t7374 = call i8* @malloc(i64 %t7373)
  %t7375 = bitcast i8* %t7374 to i32*
  %t7376 = call i8* @malloc(i64 %t7368)
  store i64 0, i64* %t7377
  br label %ht_fill8_cond_1701
ht_fill8_cond_1701:
  %t7378 = load i64, i64* %t7377
  %t7379 = icmp slt i64 %t7378, %t7368
  br i1 %t7379, label %ht_fill8_body_1702, label %ht_fill8_end_1703
ht_fill8_body_1702:
  %t7380 = getelementptr inbounds i8, i8* %t7376, i64 %t7378
  store i8 0, i8* %t7380
  %t7381 = add i64 %t7378, 1
  store i64 %t7381, i64* %t7377
  br label %ht_fill8_cond_1701
ht_fill8_end_1703:
  %t7382 = load i8**, i8*** %t7341
  %t7383 = load i32*, i32** %t7343
  %t7384 = load i8*, i8** %t7345
  store i64 0, i64* %t7385
  br label %map_grow_cond_1704
map_grow_cond_1704:
  %t7386 = load i64, i64* %t7385
  %t7387 = icmp slt i64 %t7386, %t7355
  br i1 %t7387, label %map_grow_body_1705, label %map_grow_end_1708
map_grow_body_1705:
  %t7388 = getelementptr inbounds i8, i8* %t7384, i64 %t7386
  %t7389 = load i8, i8* %t7388
  %t7390 = icmp eq i8 %t7389, 1
  br i1 %t7390, label %map_grow_occ_1706, label %map_grow_next_1707
map_grow_occ_1706:
  %t7391 = getelementptr inbounds i8*, i8** %t7382, i64 %t7386
  %t7392 = load i8*, i8** %t7391
  %t7393 = getelementptr inbounds i32, i32* %t7383, i64 %t7386
  %t7394 = load i32, i32* %t7393
  %t7395 = call i64 @hash_str(i8* %t7392)
  %t7396 = and i64 %t7395, %t7369
  store i64 0, i64* %t7397
  store i64 %t7396, i64* %t7398
  br label %ht_fe_cond_1709
ht_fe_cond_1709:
  %t7399 = load i64, i64* %t7397
  %t7400 = icmp slt i64 %t7399, %t7368
  br i1 %t7400, label %ht_fe_body_1710, label %ht_fe_end_1712
ht_fe_body_1710:
  %t7401 = load i64, i64* %t7398
  %t7402 = getelementptr inbounds i8, i8* %t7376, i64 %t7401
  %t7403 = load i8, i8* %t7402
  %t7404 = icmp eq i8 %t7403, 0
  br i1 %t7404, label %ht_fe_end_1712, label %ht_fe_next_1711
ht_fe_next_1711:
  %t7405 = add i64 %t7401, 1
  %t7406 = and i64 %t7405, %t7369
  store i64 %t7406, i64* %t7398
  %t7407 = add i64 %t7399, 1
  store i64 %t7407, i64* %t7397
  br label %ht_fe_cond_1709
ht_fe_end_1712:
  %t7408 = load i64, i64* %t7398
  %t7409 = getelementptr inbounds i8, i8* %t7376, i64 %t7408
  store i8 1, i8* %t7409
  %t7410 = getelementptr inbounds i8*, i8** %t7372, i64 %t7408
  store i8* %t7392, i8** %t7410
  %t7411 = getelementptr inbounds i32, i32* %t7375, i64 %t7408
  store i32 %t7394, i32* %t7411
  br label %map_grow_next_1707
map_grow_next_1707:
  %t7412 = add i64 %t7386, 1
  store i64 %t7412, i64* %t7385
  br label %map_grow_cond_1704
map_grow_end_1708:
  %t7413 = bitcast i8** %t7382 to i8*
  call void @free(i8* %t7413)
  %t7414 = bitcast i32* %t7383 to i8*
  call void @free(i8* %t7414)
  call void @free(i8* %t7384)
  store i8** %t7372, i8*** %t7341
  store i32* %t7375, i32** %t7343
  store i8* %t7376, i8** %t7345
  store i64 %t7368, i64* %t7349
  store i64 0, i64* %t7351
  br label %map_insert_after_grow_1700
map_insert_after_grow_1700:
  %t7415 = load i8**, i8*** %t7341
  %t7416 = load i32*, i32** %t7343
  %t7417 = load i8*, i8** %t7345
  %t7418 = load i64, i64* %t7349
  %t7419 = sub i64 %t7418, 1
  %t7420 = call i64 @hash_str(i8* %t7353)
  %t7421 = and i64 %t7420, %t7419
  store i64 0, i64* %t7422
  store i64 %t7421, i64* %t7423
  store i1 false, i1* %t7424
  store i64 -1, i64* %t7425
  store i64 -1, i64* %t7426
  store i1 false, i1* %t7427
  br label %ht_probe_cond_1713
ht_probe_cond_1713:
  %t7428 = load i64, i64* %t7422
  %t7429 = icmp slt i64 %t7428, %t7418
  br i1 %t7429, label %ht_probe_body_1714, label %ht_probe_end_1724
ht_probe_body_1714:
  %t7430 = load i64, i64* %t7423
  %t7431 = getelementptr inbounds i8, i8* %t7417, i64 %t7430
  %t7432 = load i8, i8* %t7431
  %t7433 = icmp eq i8 %t7432, 0
  br i1 %t7433, label %ht_probe_on_empty_1716, label %ht_probe_check_occ_1715
ht_probe_check_occ_1715:
  %t7434 = icmp eq i8 %t7432, 1
  br i1 %t7434, label %ht_probe_on_occ_1719, label %ht_probe_on_tomb_1721
ht_probe_on_empty_1716:
  %t7435 = load i1, i1* %t7427
  br i1 %t7435, label %ht_probe_after_islot_empty_1718, label %ht_probe_set_islot_empty_1717
ht_probe_set_islot_empty_1717:
  store i64 %t7430, i64* %t7426
  store i1 true, i1* %t7427
  br label %ht_probe_after_islot_empty_1718
ht_probe_after_islot_empty_1718:
  br label %ht_probe_end_1724
ht_probe_on_occ_1719:
  %t7436 = getelementptr inbounds i8*, i8** %t7415, i64 %t7430
  %t7437 = load i8*, i8** %t7436
  %t7438 = call i1 @eq_str(i8* %t7437, i8* %t7353)
  br i1 %t7438, label %ht_probe_on_match_1720, label %ht_probe_next_1723
ht_probe_on_match_1720:
  store i1 true, i1* %t7424
  store i64 %t7430, i64* %t7425
  br label %ht_probe_end_1724
ht_probe_on_tomb_1721:
  %t7439 = load i1, i1* %t7427
  br i1 %t7439, label %ht_probe_next_1723, label %ht_probe_set_islot_tomb_1722
ht_probe_set_islot_tomb_1722:
  store i64 %t7430, i64* %t7426
  store i1 true, i1* %t7427
  br label %ht_probe_next_1723
ht_probe_next_1723:
  %t7440 = add i64 %t7430, 1
  %t7441 = and i64 %t7440, %t7419
  store i64 %t7441, i64* %t7423
  %t7442 = add i64 %t7428, 1
  store i64 %t7442, i64* %t7422
  br label %ht_probe_cond_1713
ht_probe_end_1724:
  %t7443 = load i1, i1* %t7424
  %t7444 = load i64, i64* %t7425
  %t7445 = load i64, i64* %t7426
  br i1 %t7443, label %map_insert_overwrite_1725, label %map_insert_new_1726
map_insert_overwrite_1725:
  store i8* %t7353, i8** %t7446
  %t7447 = load i8*, i8** %t7446
  call void @star_rc_release(i8* %t7447)
  %t7448 = getelementptr inbounds i32, i32* %t7416, i64 %t7444
  store i32 40, i32* %t7448
  br label %map_insert_after_1727
map_insert_new_1726:
  %t7449 = getelementptr inbounds i8, i8* %t7417, i64 %t7445
  %t7450 = load i8, i8* %t7449
  %t7451 = icmp eq i8 %t7450, 2
  br i1 %t7451, label %map_insert_dec_tomb_1728, label %map_insert_store_1729
map_insert_dec_tomb_1728:
  %t7452 = load i64, i64* %t7351
  %t7453 = sub i64 %t7452, 1
  store i64 %t7453, i64* %t7351
  br label %map_insert_store_1729
map_insert_store_1729:
  store i8 1, i8* %t7449
  %t7454 = getelementptr inbounds i8*, i8** %t7415, i64 %t7445
  store i8* %t7353, i8** %t7454
  %t7455 = getelementptr inbounds i32, i32* %t7416, i64 %t7445
  store i32 40, i32* %t7455
  %t7456 = load i64, i64* %t7347
  %t7457 = add i64 %t7456, 1
  store i64 %t7457, i64* %t7347
  br label %map_insert_after_1727
map_insert_after_1727:
  %t7458 = getelementptr i8*, i8** null, i32 1
  %t7459 = ptrtoint i8** %t7458 to i64
  %t7460 = getelementptr i32, i32* null, i32 1
  %t7461 = ptrtoint i32* %t7460 to i64
  %t7462 = load i8*, i8** %t0
  %t7463 = icmp eq i8* %t7462, null
  br i1 %t7463, label %map_cow_alloc_1730, label %map_cow_check_1731
map_cow_alloc_1730:
  %t7464 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7465 = call i8* @star_rc_alloc(i64 48, i8* %t7464)
  %t7466 = bitcast i8* %t7465 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7467 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7466, i32 0, i32 0
  store i8** null, i8*** %t7467
  %t7468 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7466, i32 0, i32 1
  store i32* null, i32** %t7468
  %t7469 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7466, i32 0, i32 2
  store i8* null, i8** %t7469
  %t7470 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7466, i32 0, i32 3
  store i64 0, i64* %t7470
  %t7471 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7466, i32 0, i32 4
  store i64 0, i64* %t7471
  %t7472 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7466, i32 0, i32 5
  store i64 0, i64* %t7472
  store i8* %t7465, i8** %t0
  br label %map_cow_done_1732
map_cow_check_1731:
  %t7473 = getelementptr inbounds i8, i8* %t7462, i64 -16
  %t7474 = bitcast i8* %t7473 to i64*
  %t7475 = load atomic i64, i64* %t7474 seq_cst, align 8
  %t7476 = icmp eq i64 %t7475, 1
  br i1 %t7476, label %map_cow_done_1732, label %map_cow_clone_1733
map_cow_clone_1733:
  %t7477 = bitcast i8* %t7462 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7478 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7477, i32 0, i32 0
  %t7479 = load i8**, i8*** %t7478
  %t7480 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7477, i32 0, i32 1
  %t7481 = load i32*, i32** %t7480
  %t7482 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7477, i32 0, i32 2
  %t7483 = load i8*, i8** %t7482
  %t7484 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7477, i32 0, i32 3
  %t7485 = load i64, i64* %t7484
  %t7486 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7477, i32 0, i32 4
  %t7487 = load i64, i64* %t7486
  %t7488 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7477, i32 0, i32 5
  %t7489 = load i64, i64* %t7488
  %t7490 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7491 = call i8* @star_rc_alloc(i64 48, i8* %t7490)
  %t7492 = bitcast i8* %t7491 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7493 = mul i64 %t7487, %t7459
  %t7494 = call i8* @malloc(i64 %t7493)
  %t7495 = bitcast i8* %t7494 to i8**
  %t7496 = mul i64 %t7487, %t7461
  %t7497 = call i8* @malloc(i64 %t7496)
  %t7498 = bitcast i8* %t7497 to i32*
  %t7499 = call i8* @malloc(i64 %t7487)
  %t7500 = icmp sgt i64 %t7487, 0
  br i1 %t7500, label %map_cow_copy_1734, label %map_cow_after_copy_1735
map_cow_copy_1734:
  %t7501 = mul i64 %t7487, %t7459
  %t7502 = bitcast i8** %t7479 to i8*
  call i8* @memcpy(i8* %t7494, i8* %t7502, i64 %t7501)
  %t7503 = mul i64 %t7487, %t7461
  %t7504 = bitcast i32* %t7481 to i8*
  call i8* @memcpy(i8* %t7497, i8* %t7504, i64 %t7503)
  call i8* @memcpy(i8* %t7499, i8* %t7483, i64 %t7487)
  store i64 0, i64* %t7505
  br label %map_cow_retain_cond_1736
map_cow_retain_cond_1736:
  %t7506 = load i64, i64* %t7505
  %t7507 = icmp slt i64 %t7506, %t7487
  br i1 %t7507, label %map_cow_retain_body_1737, label %map_cow_retain_end_1740
map_cow_retain_body_1737:
  %t7508 = getelementptr inbounds i8, i8* %t7499, i64 %t7506
  %t7509 = load i8, i8* %t7508
  %t7510 = icmp eq i8 %t7509, 1
  br i1 %t7510, label %map_cow_retain_occ_1738, label %map_cow_retain_next_1739
map_cow_retain_occ_1738:
  %t7511 = getelementptr inbounds i8*, i8** %t7495, i64 %t7506
  %t7512 = load i8*, i8** %t7511
  call void @star_rc_retain(i8* %t7512)
  br label %map_cow_retain_next_1739
map_cow_retain_next_1739:
  %t7513 = add i64 %t7506, 1
  store i64 %t7513, i64* %t7505
  br label %map_cow_retain_cond_1736
map_cow_retain_end_1740:
  br label %map_cow_after_copy_1735
map_cow_after_copy_1735:
  %t7514 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7492, i32 0, i32 0
  store i8** %t7495, i8*** %t7514
  %t7515 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7492, i32 0, i32 1
  store i32* %t7498, i32** %t7515
  %t7516 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7492, i32 0, i32 2
  store i8* %t7499, i8** %t7516
  %t7517 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7492, i32 0, i32 3
  store i64 %t7485, i64* %t7517
  %t7518 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7492, i32 0, i32 4
  store i64 %t7487, i64* %t7518
  %t7519 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7492, i32 0, i32 5
  store i64 %t7489, i64* %t7519
  call void @star_rc_release(i8* %t7462)
  store i8* %t7491, i8** %t0
  br label %map_cow_done_1732
map_cow_done_1732:
  %t7520 = load i8*, i8** %t0
  %t7521 = bitcast i8* %t7520 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7522 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7521, i32 0, i32 0
  %t7523 = load i8**, i8*** %t7522
  %t7524 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7521, i32 0, i32 1
  %t7525 = load i32*, i32** %t7524
  %t7526 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7521, i32 0, i32 2
  %t7527 = load i8*, i8** %t7526
  %t7528 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7521, i32 0, i32 3
  %t7529 = load i64, i64* %t7528
  %t7530 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7521, i32 0, i32 4
  %t7531 = load i64, i64* %t7530
  %t7532 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7521, i32 0, i32 5
  %t7533 = load i64, i64* %t7532
  %t7534 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.41, i64 0, i32 2, i64 0
  %t7535 = load i64, i64* %t7528
  %t7536 = load i64, i64* %t7530
  %t7537 = load i64, i64* %t7532
  %t7538 = add i64 %t7535, %t7537
  %t7539 = add i64 %t7538, 1
  %t7540 = mul i64 %t7539, 4
  %t7541 = mul i64 %t7536, 3
  %t7542 = icmp sgt i64 %t7540, %t7541
  br i1 %t7542, label %map_insert_grow_1741, label %map_insert_after_grow_1742
map_insert_grow_1741:
  %t7543 = getelementptr i8*, i8** null, i32 1
  %t7544 = ptrtoint i8** %t7543 to i64
  %t7545 = getelementptr i32, i32* null, i32 1
  %t7546 = ptrtoint i32* %t7545 to i64
  %t7547 = mul i64 %t7536, 2
  %t7548 = icmp sgt i64 %t7547, 0
  %t7549 = select i1 %t7548, i64 %t7547, i64 8
  %t7550 = sub i64 %t7549, 1
  %t7551 = mul i64 %t7549, %t7544
  %t7552 = call i8* @malloc(i64 %t7551)
  %t7553 = bitcast i8* %t7552 to i8**
  %t7554 = mul i64 %t7549, %t7546
  %t7555 = call i8* @malloc(i64 %t7554)
  %t7556 = bitcast i8* %t7555 to i32*
  %t7557 = call i8* @malloc(i64 %t7549)
  store i64 0, i64* %t7558
  br label %ht_fill8_cond_1743
ht_fill8_cond_1743:
  %t7559 = load i64, i64* %t7558
  %t7560 = icmp slt i64 %t7559, %t7549
  br i1 %t7560, label %ht_fill8_body_1744, label %ht_fill8_end_1745
ht_fill8_body_1744:
  %t7561 = getelementptr inbounds i8, i8* %t7557, i64 %t7559
  store i8 0, i8* %t7561
  %t7562 = add i64 %t7559, 1
  store i64 %t7562, i64* %t7558
  br label %ht_fill8_cond_1743
ht_fill8_end_1745:
  %t7563 = load i8**, i8*** %t7522
  %t7564 = load i32*, i32** %t7524
  %t7565 = load i8*, i8** %t7526
  store i64 0, i64* %t7566
  br label %map_grow_cond_1746
map_grow_cond_1746:
  %t7567 = load i64, i64* %t7566
  %t7568 = icmp slt i64 %t7567, %t7536
  br i1 %t7568, label %map_grow_body_1747, label %map_grow_end_1750
map_grow_body_1747:
  %t7569 = getelementptr inbounds i8, i8* %t7565, i64 %t7567
  %t7570 = load i8, i8* %t7569
  %t7571 = icmp eq i8 %t7570, 1
  br i1 %t7571, label %map_grow_occ_1748, label %map_grow_next_1749
map_grow_occ_1748:
  %t7572 = getelementptr inbounds i8*, i8** %t7563, i64 %t7567
  %t7573 = load i8*, i8** %t7572
  %t7574 = getelementptr inbounds i32, i32* %t7564, i64 %t7567
  %t7575 = load i32, i32* %t7574
  %t7576 = call i64 @hash_str(i8* %t7573)
  %t7577 = and i64 %t7576, %t7550
  store i64 0, i64* %t7578
  store i64 %t7577, i64* %t7579
  br label %ht_fe_cond_1751
ht_fe_cond_1751:
  %t7580 = load i64, i64* %t7578
  %t7581 = icmp slt i64 %t7580, %t7549
  br i1 %t7581, label %ht_fe_body_1752, label %ht_fe_end_1754
ht_fe_body_1752:
  %t7582 = load i64, i64* %t7579
  %t7583 = getelementptr inbounds i8, i8* %t7557, i64 %t7582
  %t7584 = load i8, i8* %t7583
  %t7585 = icmp eq i8 %t7584, 0
  br i1 %t7585, label %ht_fe_end_1754, label %ht_fe_next_1753
ht_fe_next_1753:
  %t7586 = add i64 %t7582, 1
  %t7587 = and i64 %t7586, %t7550
  store i64 %t7587, i64* %t7579
  %t7588 = add i64 %t7580, 1
  store i64 %t7588, i64* %t7578
  br label %ht_fe_cond_1751
ht_fe_end_1754:
  %t7589 = load i64, i64* %t7579
  %t7590 = getelementptr inbounds i8, i8* %t7557, i64 %t7589
  store i8 1, i8* %t7590
  %t7591 = getelementptr inbounds i8*, i8** %t7553, i64 %t7589
  store i8* %t7573, i8** %t7591
  %t7592 = getelementptr inbounds i32, i32* %t7556, i64 %t7589
  store i32 %t7575, i32* %t7592
  br label %map_grow_next_1749
map_grow_next_1749:
  %t7593 = add i64 %t7567, 1
  store i64 %t7593, i64* %t7566
  br label %map_grow_cond_1746
map_grow_end_1750:
  %t7594 = bitcast i8** %t7563 to i8*
  call void @free(i8* %t7594)
  %t7595 = bitcast i32* %t7564 to i8*
  call void @free(i8* %t7595)
  call void @free(i8* %t7565)
  store i8** %t7553, i8*** %t7522
  store i32* %t7556, i32** %t7524
  store i8* %t7557, i8** %t7526
  store i64 %t7549, i64* %t7530
  store i64 0, i64* %t7532
  br label %map_insert_after_grow_1742
map_insert_after_grow_1742:
  %t7596 = load i8**, i8*** %t7522
  %t7597 = load i32*, i32** %t7524
  %t7598 = load i8*, i8** %t7526
  %t7599 = load i64, i64* %t7530
  %t7600 = sub i64 %t7599, 1
  %t7601 = call i64 @hash_str(i8* %t7534)
  %t7602 = and i64 %t7601, %t7600
  store i64 0, i64* %t7603
  store i64 %t7602, i64* %t7604
  store i1 false, i1* %t7605
  store i64 -1, i64* %t7606
  store i64 -1, i64* %t7607
  store i1 false, i1* %t7608
  br label %ht_probe_cond_1755
ht_probe_cond_1755:
  %t7609 = load i64, i64* %t7603
  %t7610 = icmp slt i64 %t7609, %t7599
  br i1 %t7610, label %ht_probe_body_1756, label %ht_probe_end_1766
ht_probe_body_1756:
  %t7611 = load i64, i64* %t7604
  %t7612 = getelementptr inbounds i8, i8* %t7598, i64 %t7611
  %t7613 = load i8, i8* %t7612
  %t7614 = icmp eq i8 %t7613, 0
  br i1 %t7614, label %ht_probe_on_empty_1758, label %ht_probe_check_occ_1757
ht_probe_check_occ_1757:
  %t7615 = icmp eq i8 %t7613, 1
  br i1 %t7615, label %ht_probe_on_occ_1761, label %ht_probe_on_tomb_1763
ht_probe_on_empty_1758:
  %t7616 = load i1, i1* %t7608
  br i1 %t7616, label %ht_probe_after_islot_empty_1760, label %ht_probe_set_islot_empty_1759
ht_probe_set_islot_empty_1759:
  store i64 %t7611, i64* %t7607
  store i1 true, i1* %t7608
  br label %ht_probe_after_islot_empty_1760
ht_probe_after_islot_empty_1760:
  br label %ht_probe_end_1766
ht_probe_on_occ_1761:
  %t7617 = getelementptr inbounds i8*, i8** %t7596, i64 %t7611
  %t7618 = load i8*, i8** %t7617
  %t7619 = call i1 @eq_str(i8* %t7618, i8* %t7534)
  br i1 %t7619, label %ht_probe_on_match_1762, label %ht_probe_next_1765
ht_probe_on_match_1762:
  store i1 true, i1* %t7605
  store i64 %t7611, i64* %t7606
  br label %ht_probe_end_1766
ht_probe_on_tomb_1763:
  %t7620 = load i1, i1* %t7608
  br i1 %t7620, label %ht_probe_next_1765, label %ht_probe_set_islot_tomb_1764
ht_probe_set_islot_tomb_1764:
  store i64 %t7611, i64* %t7607
  store i1 true, i1* %t7608
  br label %ht_probe_next_1765
ht_probe_next_1765:
  %t7621 = add i64 %t7611, 1
  %t7622 = and i64 %t7621, %t7600
  store i64 %t7622, i64* %t7604
  %t7623 = add i64 %t7609, 1
  store i64 %t7623, i64* %t7603
  br label %ht_probe_cond_1755
ht_probe_end_1766:
  %t7624 = load i1, i1* %t7605
  %t7625 = load i64, i64* %t7606
  %t7626 = load i64, i64* %t7607
  br i1 %t7624, label %map_insert_overwrite_1767, label %map_insert_new_1768
map_insert_overwrite_1767:
  store i8* %t7534, i8** %t7627
  %t7628 = load i8*, i8** %t7627
  call void @star_rc_release(i8* %t7628)
  %t7629 = getelementptr inbounds i32, i32* %t7597, i64 %t7625
  store i32 41, i32* %t7629
  br label %map_insert_after_1769
map_insert_new_1768:
  %t7630 = getelementptr inbounds i8, i8* %t7598, i64 %t7626
  %t7631 = load i8, i8* %t7630
  %t7632 = icmp eq i8 %t7631, 2
  br i1 %t7632, label %map_insert_dec_tomb_1770, label %map_insert_store_1771
map_insert_dec_tomb_1770:
  %t7633 = load i64, i64* %t7532
  %t7634 = sub i64 %t7633, 1
  store i64 %t7634, i64* %t7532
  br label %map_insert_store_1771
map_insert_store_1771:
  store i8 1, i8* %t7630
  %t7635 = getelementptr inbounds i8*, i8** %t7596, i64 %t7626
  store i8* %t7534, i8** %t7635
  %t7636 = getelementptr inbounds i32, i32* %t7597, i64 %t7626
  store i32 41, i32* %t7636
  %t7637 = load i64, i64* %t7528
  %t7638 = add i64 %t7637, 1
  store i64 %t7638, i64* %t7528
  br label %map_insert_after_1769
map_insert_after_1769:
  %t7639 = getelementptr i8*, i8** null, i32 1
  %t7640 = ptrtoint i8** %t7639 to i64
  %t7641 = getelementptr i32, i32* null, i32 1
  %t7642 = ptrtoint i32* %t7641 to i64
  %t7643 = load i8*, i8** %t0
  %t7644 = icmp eq i8* %t7643, null
  br i1 %t7644, label %map_cow_alloc_1772, label %map_cow_check_1773
map_cow_alloc_1772:
  %t7645 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7646 = call i8* @star_rc_alloc(i64 48, i8* %t7645)
  %t7647 = bitcast i8* %t7646 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7648 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7647, i32 0, i32 0
  store i8** null, i8*** %t7648
  %t7649 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7647, i32 0, i32 1
  store i32* null, i32** %t7649
  %t7650 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7647, i32 0, i32 2
  store i8* null, i8** %t7650
  %t7651 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7647, i32 0, i32 3
  store i64 0, i64* %t7651
  %t7652 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7647, i32 0, i32 4
  store i64 0, i64* %t7652
  %t7653 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7647, i32 0, i32 5
  store i64 0, i64* %t7653
  store i8* %t7646, i8** %t0
  br label %map_cow_done_1774
map_cow_check_1773:
  %t7654 = getelementptr inbounds i8, i8* %t7643, i64 -16
  %t7655 = bitcast i8* %t7654 to i64*
  %t7656 = load atomic i64, i64* %t7655 seq_cst, align 8
  %t7657 = icmp eq i64 %t7656, 1
  br i1 %t7657, label %map_cow_done_1774, label %map_cow_clone_1775
map_cow_clone_1775:
  %t7658 = bitcast i8* %t7643 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7659 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7658, i32 0, i32 0
  %t7660 = load i8**, i8*** %t7659
  %t7661 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7658, i32 0, i32 1
  %t7662 = load i32*, i32** %t7661
  %t7663 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7658, i32 0, i32 2
  %t7664 = load i8*, i8** %t7663
  %t7665 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7658, i32 0, i32 3
  %t7666 = load i64, i64* %t7665
  %t7667 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7658, i32 0, i32 4
  %t7668 = load i64, i64* %t7667
  %t7669 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7658, i32 0, i32 5
  %t7670 = load i64, i64* %t7669
  %t7671 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7672 = call i8* @star_rc_alloc(i64 48, i8* %t7671)
  %t7673 = bitcast i8* %t7672 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7674 = mul i64 %t7668, %t7640
  %t7675 = call i8* @malloc(i64 %t7674)
  %t7676 = bitcast i8* %t7675 to i8**
  %t7677 = mul i64 %t7668, %t7642
  %t7678 = call i8* @malloc(i64 %t7677)
  %t7679 = bitcast i8* %t7678 to i32*
  %t7680 = call i8* @malloc(i64 %t7668)
  %t7681 = icmp sgt i64 %t7668, 0
  br i1 %t7681, label %map_cow_copy_1776, label %map_cow_after_copy_1777
map_cow_copy_1776:
  %t7682 = mul i64 %t7668, %t7640
  %t7683 = bitcast i8** %t7660 to i8*
  call i8* @memcpy(i8* %t7675, i8* %t7683, i64 %t7682)
  %t7684 = mul i64 %t7668, %t7642
  %t7685 = bitcast i32* %t7662 to i8*
  call i8* @memcpy(i8* %t7678, i8* %t7685, i64 %t7684)
  call i8* @memcpy(i8* %t7680, i8* %t7664, i64 %t7668)
  store i64 0, i64* %t7686
  br label %map_cow_retain_cond_1778
map_cow_retain_cond_1778:
  %t7687 = load i64, i64* %t7686
  %t7688 = icmp slt i64 %t7687, %t7668
  br i1 %t7688, label %map_cow_retain_body_1779, label %map_cow_retain_end_1782
map_cow_retain_body_1779:
  %t7689 = getelementptr inbounds i8, i8* %t7680, i64 %t7687
  %t7690 = load i8, i8* %t7689
  %t7691 = icmp eq i8 %t7690, 1
  br i1 %t7691, label %map_cow_retain_occ_1780, label %map_cow_retain_next_1781
map_cow_retain_occ_1780:
  %t7692 = getelementptr inbounds i8*, i8** %t7676, i64 %t7687
  %t7693 = load i8*, i8** %t7692
  call void @star_rc_retain(i8* %t7693)
  br label %map_cow_retain_next_1781
map_cow_retain_next_1781:
  %t7694 = add i64 %t7687, 1
  store i64 %t7694, i64* %t7686
  br label %map_cow_retain_cond_1778
map_cow_retain_end_1782:
  br label %map_cow_after_copy_1777
map_cow_after_copy_1777:
  %t7695 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7673, i32 0, i32 0
  store i8** %t7676, i8*** %t7695
  %t7696 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7673, i32 0, i32 1
  store i32* %t7679, i32** %t7696
  %t7697 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7673, i32 0, i32 2
  store i8* %t7680, i8** %t7697
  %t7698 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7673, i32 0, i32 3
  store i64 %t7666, i64* %t7698
  %t7699 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7673, i32 0, i32 4
  store i64 %t7668, i64* %t7699
  %t7700 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7673, i32 0, i32 5
  store i64 %t7670, i64* %t7700
  call void @star_rc_release(i8* %t7643)
  store i8* %t7672, i8** %t0
  br label %map_cow_done_1774
map_cow_done_1774:
  %t7701 = load i8*, i8** %t0
  %t7702 = bitcast i8* %t7701 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7703 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7702, i32 0, i32 0
  %t7704 = load i8**, i8*** %t7703
  %t7705 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7702, i32 0, i32 1
  %t7706 = load i32*, i32** %t7705
  %t7707 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7702, i32 0, i32 2
  %t7708 = load i8*, i8** %t7707
  %t7709 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7702, i32 0, i32 3
  %t7710 = load i64, i64* %t7709
  %t7711 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7702, i32 0, i32 4
  %t7712 = load i64, i64* %t7711
  %t7713 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7702, i32 0, i32 5
  %t7714 = load i64, i64* %t7713
  %t7715 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.42, i64 0, i32 2, i64 0
  %t7716 = load i64, i64* %t7709
  %t7717 = load i64, i64* %t7711
  %t7718 = load i64, i64* %t7713
  %t7719 = add i64 %t7716, %t7718
  %t7720 = add i64 %t7719, 1
  %t7721 = mul i64 %t7720, 4
  %t7722 = mul i64 %t7717, 3
  %t7723 = icmp sgt i64 %t7721, %t7722
  br i1 %t7723, label %map_insert_grow_1783, label %map_insert_after_grow_1784
map_insert_grow_1783:
  %t7724 = getelementptr i8*, i8** null, i32 1
  %t7725 = ptrtoint i8** %t7724 to i64
  %t7726 = getelementptr i32, i32* null, i32 1
  %t7727 = ptrtoint i32* %t7726 to i64
  %t7728 = mul i64 %t7717, 2
  %t7729 = icmp sgt i64 %t7728, 0
  %t7730 = select i1 %t7729, i64 %t7728, i64 8
  %t7731 = sub i64 %t7730, 1
  %t7732 = mul i64 %t7730, %t7725
  %t7733 = call i8* @malloc(i64 %t7732)
  %t7734 = bitcast i8* %t7733 to i8**
  %t7735 = mul i64 %t7730, %t7727
  %t7736 = call i8* @malloc(i64 %t7735)
  %t7737 = bitcast i8* %t7736 to i32*
  %t7738 = call i8* @malloc(i64 %t7730)
  store i64 0, i64* %t7739
  br label %ht_fill8_cond_1785
ht_fill8_cond_1785:
  %t7740 = load i64, i64* %t7739
  %t7741 = icmp slt i64 %t7740, %t7730
  br i1 %t7741, label %ht_fill8_body_1786, label %ht_fill8_end_1787
ht_fill8_body_1786:
  %t7742 = getelementptr inbounds i8, i8* %t7738, i64 %t7740
  store i8 0, i8* %t7742
  %t7743 = add i64 %t7740, 1
  store i64 %t7743, i64* %t7739
  br label %ht_fill8_cond_1785
ht_fill8_end_1787:
  %t7744 = load i8**, i8*** %t7703
  %t7745 = load i32*, i32** %t7705
  %t7746 = load i8*, i8** %t7707
  store i64 0, i64* %t7747
  br label %map_grow_cond_1788
map_grow_cond_1788:
  %t7748 = load i64, i64* %t7747
  %t7749 = icmp slt i64 %t7748, %t7717
  br i1 %t7749, label %map_grow_body_1789, label %map_grow_end_1792
map_grow_body_1789:
  %t7750 = getelementptr inbounds i8, i8* %t7746, i64 %t7748
  %t7751 = load i8, i8* %t7750
  %t7752 = icmp eq i8 %t7751, 1
  br i1 %t7752, label %map_grow_occ_1790, label %map_grow_next_1791
map_grow_occ_1790:
  %t7753 = getelementptr inbounds i8*, i8** %t7744, i64 %t7748
  %t7754 = load i8*, i8** %t7753
  %t7755 = getelementptr inbounds i32, i32* %t7745, i64 %t7748
  %t7756 = load i32, i32* %t7755
  %t7757 = call i64 @hash_str(i8* %t7754)
  %t7758 = and i64 %t7757, %t7731
  store i64 0, i64* %t7759
  store i64 %t7758, i64* %t7760
  br label %ht_fe_cond_1793
ht_fe_cond_1793:
  %t7761 = load i64, i64* %t7759
  %t7762 = icmp slt i64 %t7761, %t7730
  br i1 %t7762, label %ht_fe_body_1794, label %ht_fe_end_1796
ht_fe_body_1794:
  %t7763 = load i64, i64* %t7760
  %t7764 = getelementptr inbounds i8, i8* %t7738, i64 %t7763
  %t7765 = load i8, i8* %t7764
  %t7766 = icmp eq i8 %t7765, 0
  br i1 %t7766, label %ht_fe_end_1796, label %ht_fe_next_1795
ht_fe_next_1795:
  %t7767 = add i64 %t7763, 1
  %t7768 = and i64 %t7767, %t7731
  store i64 %t7768, i64* %t7760
  %t7769 = add i64 %t7761, 1
  store i64 %t7769, i64* %t7759
  br label %ht_fe_cond_1793
ht_fe_end_1796:
  %t7770 = load i64, i64* %t7760
  %t7771 = getelementptr inbounds i8, i8* %t7738, i64 %t7770
  store i8 1, i8* %t7771
  %t7772 = getelementptr inbounds i8*, i8** %t7734, i64 %t7770
  store i8* %t7754, i8** %t7772
  %t7773 = getelementptr inbounds i32, i32* %t7737, i64 %t7770
  store i32 %t7756, i32* %t7773
  br label %map_grow_next_1791
map_grow_next_1791:
  %t7774 = add i64 %t7748, 1
  store i64 %t7774, i64* %t7747
  br label %map_grow_cond_1788
map_grow_end_1792:
  %t7775 = bitcast i8** %t7744 to i8*
  call void @free(i8* %t7775)
  %t7776 = bitcast i32* %t7745 to i8*
  call void @free(i8* %t7776)
  call void @free(i8* %t7746)
  store i8** %t7734, i8*** %t7703
  store i32* %t7737, i32** %t7705
  store i8* %t7738, i8** %t7707
  store i64 %t7730, i64* %t7711
  store i64 0, i64* %t7713
  br label %map_insert_after_grow_1784
map_insert_after_grow_1784:
  %t7777 = load i8**, i8*** %t7703
  %t7778 = load i32*, i32** %t7705
  %t7779 = load i8*, i8** %t7707
  %t7780 = load i64, i64* %t7711
  %t7781 = sub i64 %t7780, 1
  %t7782 = call i64 @hash_str(i8* %t7715)
  %t7783 = and i64 %t7782, %t7781
  store i64 0, i64* %t7784
  store i64 %t7783, i64* %t7785
  store i1 false, i1* %t7786
  store i64 -1, i64* %t7787
  store i64 -1, i64* %t7788
  store i1 false, i1* %t7789
  br label %ht_probe_cond_1797
ht_probe_cond_1797:
  %t7790 = load i64, i64* %t7784
  %t7791 = icmp slt i64 %t7790, %t7780
  br i1 %t7791, label %ht_probe_body_1798, label %ht_probe_end_1808
ht_probe_body_1798:
  %t7792 = load i64, i64* %t7785
  %t7793 = getelementptr inbounds i8, i8* %t7779, i64 %t7792
  %t7794 = load i8, i8* %t7793
  %t7795 = icmp eq i8 %t7794, 0
  br i1 %t7795, label %ht_probe_on_empty_1800, label %ht_probe_check_occ_1799
ht_probe_check_occ_1799:
  %t7796 = icmp eq i8 %t7794, 1
  br i1 %t7796, label %ht_probe_on_occ_1803, label %ht_probe_on_tomb_1805
ht_probe_on_empty_1800:
  %t7797 = load i1, i1* %t7789
  br i1 %t7797, label %ht_probe_after_islot_empty_1802, label %ht_probe_set_islot_empty_1801
ht_probe_set_islot_empty_1801:
  store i64 %t7792, i64* %t7788
  store i1 true, i1* %t7789
  br label %ht_probe_after_islot_empty_1802
ht_probe_after_islot_empty_1802:
  br label %ht_probe_end_1808
ht_probe_on_occ_1803:
  %t7798 = getelementptr inbounds i8*, i8** %t7777, i64 %t7792
  %t7799 = load i8*, i8** %t7798
  %t7800 = call i1 @eq_str(i8* %t7799, i8* %t7715)
  br i1 %t7800, label %ht_probe_on_match_1804, label %ht_probe_next_1807
ht_probe_on_match_1804:
  store i1 true, i1* %t7786
  store i64 %t7792, i64* %t7787
  br label %ht_probe_end_1808
ht_probe_on_tomb_1805:
  %t7801 = load i1, i1* %t7789
  br i1 %t7801, label %ht_probe_next_1807, label %ht_probe_set_islot_tomb_1806
ht_probe_set_islot_tomb_1806:
  store i64 %t7792, i64* %t7788
  store i1 true, i1* %t7789
  br label %ht_probe_next_1807
ht_probe_next_1807:
  %t7802 = add i64 %t7792, 1
  %t7803 = and i64 %t7802, %t7781
  store i64 %t7803, i64* %t7785
  %t7804 = add i64 %t7790, 1
  store i64 %t7804, i64* %t7784
  br label %ht_probe_cond_1797
ht_probe_end_1808:
  %t7805 = load i1, i1* %t7786
  %t7806 = load i64, i64* %t7787
  %t7807 = load i64, i64* %t7788
  br i1 %t7805, label %map_insert_overwrite_1809, label %map_insert_new_1810
map_insert_overwrite_1809:
  store i8* %t7715, i8** %t7808
  %t7809 = load i8*, i8** %t7808
  call void @star_rc_release(i8* %t7809)
  %t7810 = getelementptr inbounds i32, i32* %t7778, i64 %t7806
  store i32 42, i32* %t7810
  br label %map_insert_after_1811
map_insert_new_1810:
  %t7811 = getelementptr inbounds i8, i8* %t7779, i64 %t7807
  %t7812 = load i8, i8* %t7811
  %t7813 = icmp eq i8 %t7812, 2
  br i1 %t7813, label %map_insert_dec_tomb_1812, label %map_insert_store_1813
map_insert_dec_tomb_1812:
  %t7814 = load i64, i64* %t7713
  %t7815 = sub i64 %t7814, 1
  store i64 %t7815, i64* %t7713
  br label %map_insert_store_1813
map_insert_store_1813:
  store i8 1, i8* %t7811
  %t7816 = getelementptr inbounds i8*, i8** %t7777, i64 %t7807
  store i8* %t7715, i8** %t7816
  %t7817 = getelementptr inbounds i32, i32* %t7778, i64 %t7807
  store i32 42, i32* %t7817
  %t7818 = load i64, i64* %t7709
  %t7819 = add i64 %t7818, 1
  store i64 %t7819, i64* %t7709
  br label %map_insert_after_1811
map_insert_after_1811:
  %t7820 = getelementptr i8*, i8** null, i32 1
  %t7821 = ptrtoint i8** %t7820 to i64
  %t7822 = getelementptr i32, i32* null, i32 1
  %t7823 = ptrtoint i32* %t7822 to i64
  %t7824 = load i8*, i8** %t0
  %t7825 = icmp eq i8* %t7824, null
  br i1 %t7825, label %map_cow_alloc_1814, label %map_cow_check_1815
map_cow_alloc_1814:
  %t7826 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7827 = call i8* @star_rc_alloc(i64 48, i8* %t7826)
  %t7828 = bitcast i8* %t7827 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7829 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7828, i32 0, i32 0
  store i8** null, i8*** %t7829
  %t7830 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7828, i32 0, i32 1
  store i32* null, i32** %t7830
  %t7831 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7828, i32 0, i32 2
  store i8* null, i8** %t7831
  %t7832 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7828, i32 0, i32 3
  store i64 0, i64* %t7832
  %t7833 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7828, i32 0, i32 4
  store i64 0, i64* %t7833
  %t7834 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7828, i32 0, i32 5
  store i64 0, i64* %t7834
  store i8* %t7827, i8** %t0
  br label %map_cow_done_1816
map_cow_check_1815:
  %t7835 = getelementptr inbounds i8, i8* %t7824, i64 -16
  %t7836 = bitcast i8* %t7835 to i64*
  %t7837 = load atomic i64, i64* %t7836 seq_cst, align 8
  %t7838 = icmp eq i64 %t7837, 1
  br i1 %t7838, label %map_cow_done_1816, label %map_cow_clone_1817
map_cow_clone_1817:
  %t7839 = bitcast i8* %t7824 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7840 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7839, i32 0, i32 0
  %t7841 = load i8**, i8*** %t7840
  %t7842 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7839, i32 0, i32 1
  %t7843 = load i32*, i32** %t7842
  %t7844 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7839, i32 0, i32 2
  %t7845 = load i8*, i8** %t7844
  %t7846 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7839, i32 0, i32 3
  %t7847 = load i64, i64* %t7846
  %t7848 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7839, i32 0, i32 4
  %t7849 = load i64, i64* %t7848
  %t7850 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7839, i32 0, i32 5
  %t7851 = load i64, i64* %t7850
  %t7852 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t7853 = call i8* @star_rc_alloc(i64 48, i8* %t7852)
  %t7854 = bitcast i8* %t7853 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7855 = mul i64 %t7849, %t7821
  %t7856 = call i8* @malloc(i64 %t7855)
  %t7857 = bitcast i8* %t7856 to i8**
  %t7858 = mul i64 %t7849, %t7823
  %t7859 = call i8* @malloc(i64 %t7858)
  %t7860 = bitcast i8* %t7859 to i32*
  %t7861 = call i8* @malloc(i64 %t7849)
  %t7862 = icmp sgt i64 %t7849, 0
  br i1 %t7862, label %map_cow_copy_1818, label %map_cow_after_copy_1819
map_cow_copy_1818:
  %t7863 = mul i64 %t7849, %t7821
  %t7864 = bitcast i8** %t7841 to i8*
  call i8* @memcpy(i8* %t7856, i8* %t7864, i64 %t7863)
  %t7865 = mul i64 %t7849, %t7823
  %t7866 = bitcast i32* %t7843 to i8*
  call i8* @memcpy(i8* %t7859, i8* %t7866, i64 %t7865)
  call i8* @memcpy(i8* %t7861, i8* %t7845, i64 %t7849)
  store i64 0, i64* %t7867
  br label %map_cow_retain_cond_1820
map_cow_retain_cond_1820:
  %t7868 = load i64, i64* %t7867
  %t7869 = icmp slt i64 %t7868, %t7849
  br i1 %t7869, label %map_cow_retain_body_1821, label %map_cow_retain_end_1824
map_cow_retain_body_1821:
  %t7870 = getelementptr inbounds i8, i8* %t7861, i64 %t7868
  %t7871 = load i8, i8* %t7870
  %t7872 = icmp eq i8 %t7871, 1
  br i1 %t7872, label %map_cow_retain_occ_1822, label %map_cow_retain_next_1823
map_cow_retain_occ_1822:
  %t7873 = getelementptr inbounds i8*, i8** %t7857, i64 %t7868
  %t7874 = load i8*, i8** %t7873
  call void @star_rc_retain(i8* %t7874)
  br label %map_cow_retain_next_1823
map_cow_retain_next_1823:
  %t7875 = add i64 %t7868, 1
  store i64 %t7875, i64* %t7867
  br label %map_cow_retain_cond_1820
map_cow_retain_end_1824:
  br label %map_cow_after_copy_1819
map_cow_after_copy_1819:
  %t7876 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7854, i32 0, i32 0
  store i8** %t7857, i8*** %t7876
  %t7877 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7854, i32 0, i32 1
  store i32* %t7860, i32** %t7877
  %t7878 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7854, i32 0, i32 2
  store i8* %t7861, i8** %t7878
  %t7879 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7854, i32 0, i32 3
  store i64 %t7847, i64* %t7879
  %t7880 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7854, i32 0, i32 4
  store i64 %t7849, i64* %t7880
  %t7881 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7854, i32 0, i32 5
  store i64 %t7851, i64* %t7881
  call void @star_rc_release(i8* %t7824)
  store i8* %t7853, i8** %t0
  br label %map_cow_done_1816
map_cow_done_1816:
  %t7882 = load i8*, i8** %t0
  %t7883 = bitcast i8* %t7882 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7884 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7883, i32 0, i32 0
  %t7885 = load i8**, i8*** %t7884
  %t7886 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7883, i32 0, i32 1
  %t7887 = load i32*, i32** %t7886
  %t7888 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7883, i32 0, i32 2
  %t7889 = load i8*, i8** %t7888
  %t7890 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7883, i32 0, i32 3
  %t7891 = load i64, i64* %t7890
  %t7892 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7883, i32 0, i32 4
  %t7893 = load i64, i64* %t7892
  %t7894 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7883, i32 0, i32 5
  %t7895 = load i64, i64* %t7894
  %t7896 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.43, i64 0, i32 2, i64 0
  %t7897 = load i64, i64* %t7890
  %t7898 = load i64, i64* %t7892
  %t7899 = load i64, i64* %t7894
  %t7900 = add i64 %t7897, %t7899
  %t7901 = add i64 %t7900, 1
  %t7902 = mul i64 %t7901, 4
  %t7903 = mul i64 %t7898, 3
  %t7904 = icmp sgt i64 %t7902, %t7903
  br i1 %t7904, label %map_insert_grow_1825, label %map_insert_after_grow_1826
map_insert_grow_1825:
  %t7905 = getelementptr i8*, i8** null, i32 1
  %t7906 = ptrtoint i8** %t7905 to i64
  %t7907 = getelementptr i32, i32* null, i32 1
  %t7908 = ptrtoint i32* %t7907 to i64
  %t7909 = mul i64 %t7898, 2
  %t7910 = icmp sgt i64 %t7909, 0
  %t7911 = select i1 %t7910, i64 %t7909, i64 8
  %t7912 = sub i64 %t7911, 1
  %t7913 = mul i64 %t7911, %t7906
  %t7914 = call i8* @malloc(i64 %t7913)
  %t7915 = bitcast i8* %t7914 to i8**
  %t7916 = mul i64 %t7911, %t7908
  %t7917 = call i8* @malloc(i64 %t7916)
  %t7918 = bitcast i8* %t7917 to i32*
  %t7919 = call i8* @malloc(i64 %t7911)
  store i64 0, i64* %t7920
  br label %ht_fill8_cond_1827
ht_fill8_cond_1827:
  %t7921 = load i64, i64* %t7920
  %t7922 = icmp slt i64 %t7921, %t7911
  br i1 %t7922, label %ht_fill8_body_1828, label %ht_fill8_end_1829
ht_fill8_body_1828:
  %t7923 = getelementptr inbounds i8, i8* %t7919, i64 %t7921
  store i8 0, i8* %t7923
  %t7924 = add i64 %t7921, 1
  store i64 %t7924, i64* %t7920
  br label %ht_fill8_cond_1827
ht_fill8_end_1829:
  %t7925 = load i8**, i8*** %t7884
  %t7926 = load i32*, i32** %t7886
  %t7927 = load i8*, i8** %t7888
  store i64 0, i64* %t7928
  br label %map_grow_cond_1830
map_grow_cond_1830:
  %t7929 = load i64, i64* %t7928
  %t7930 = icmp slt i64 %t7929, %t7898
  br i1 %t7930, label %map_grow_body_1831, label %map_grow_end_1834
map_grow_body_1831:
  %t7931 = getelementptr inbounds i8, i8* %t7927, i64 %t7929
  %t7932 = load i8, i8* %t7931
  %t7933 = icmp eq i8 %t7932, 1
  br i1 %t7933, label %map_grow_occ_1832, label %map_grow_next_1833
map_grow_occ_1832:
  %t7934 = getelementptr inbounds i8*, i8** %t7925, i64 %t7929
  %t7935 = load i8*, i8** %t7934
  %t7936 = getelementptr inbounds i32, i32* %t7926, i64 %t7929
  %t7937 = load i32, i32* %t7936
  %t7938 = call i64 @hash_str(i8* %t7935)
  %t7939 = and i64 %t7938, %t7912
  store i64 0, i64* %t7940
  store i64 %t7939, i64* %t7941
  br label %ht_fe_cond_1835
ht_fe_cond_1835:
  %t7942 = load i64, i64* %t7940
  %t7943 = icmp slt i64 %t7942, %t7911
  br i1 %t7943, label %ht_fe_body_1836, label %ht_fe_end_1838
ht_fe_body_1836:
  %t7944 = load i64, i64* %t7941
  %t7945 = getelementptr inbounds i8, i8* %t7919, i64 %t7944
  %t7946 = load i8, i8* %t7945
  %t7947 = icmp eq i8 %t7946, 0
  br i1 %t7947, label %ht_fe_end_1838, label %ht_fe_next_1837
ht_fe_next_1837:
  %t7948 = add i64 %t7944, 1
  %t7949 = and i64 %t7948, %t7912
  store i64 %t7949, i64* %t7941
  %t7950 = add i64 %t7942, 1
  store i64 %t7950, i64* %t7940
  br label %ht_fe_cond_1835
ht_fe_end_1838:
  %t7951 = load i64, i64* %t7941
  %t7952 = getelementptr inbounds i8, i8* %t7919, i64 %t7951
  store i8 1, i8* %t7952
  %t7953 = getelementptr inbounds i8*, i8** %t7915, i64 %t7951
  store i8* %t7935, i8** %t7953
  %t7954 = getelementptr inbounds i32, i32* %t7918, i64 %t7951
  store i32 %t7937, i32* %t7954
  br label %map_grow_next_1833
map_grow_next_1833:
  %t7955 = add i64 %t7929, 1
  store i64 %t7955, i64* %t7928
  br label %map_grow_cond_1830
map_grow_end_1834:
  %t7956 = bitcast i8** %t7925 to i8*
  call void @free(i8* %t7956)
  %t7957 = bitcast i32* %t7926 to i8*
  call void @free(i8* %t7957)
  call void @free(i8* %t7927)
  store i8** %t7915, i8*** %t7884
  store i32* %t7918, i32** %t7886
  store i8* %t7919, i8** %t7888
  store i64 %t7911, i64* %t7892
  store i64 0, i64* %t7894
  br label %map_insert_after_grow_1826
map_insert_after_grow_1826:
  %t7958 = load i8**, i8*** %t7884
  %t7959 = load i32*, i32** %t7886
  %t7960 = load i8*, i8** %t7888
  %t7961 = load i64, i64* %t7892
  %t7962 = sub i64 %t7961, 1
  %t7963 = call i64 @hash_str(i8* %t7896)
  %t7964 = and i64 %t7963, %t7962
  store i64 0, i64* %t7965
  store i64 %t7964, i64* %t7966
  store i1 false, i1* %t7967
  store i64 -1, i64* %t7968
  store i64 -1, i64* %t7969
  store i1 false, i1* %t7970
  br label %ht_probe_cond_1839
ht_probe_cond_1839:
  %t7971 = load i64, i64* %t7965
  %t7972 = icmp slt i64 %t7971, %t7961
  br i1 %t7972, label %ht_probe_body_1840, label %ht_probe_end_1850
ht_probe_body_1840:
  %t7973 = load i64, i64* %t7966
  %t7974 = getelementptr inbounds i8, i8* %t7960, i64 %t7973
  %t7975 = load i8, i8* %t7974
  %t7976 = icmp eq i8 %t7975, 0
  br i1 %t7976, label %ht_probe_on_empty_1842, label %ht_probe_check_occ_1841
ht_probe_check_occ_1841:
  %t7977 = icmp eq i8 %t7975, 1
  br i1 %t7977, label %ht_probe_on_occ_1845, label %ht_probe_on_tomb_1847
ht_probe_on_empty_1842:
  %t7978 = load i1, i1* %t7970
  br i1 %t7978, label %ht_probe_after_islot_empty_1844, label %ht_probe_set_islot_empty_1843
ht_probe_set_islot_empty_1843:
  store i64 %t7973, i64* %t7969
  store i1 true, i1* %t7970
  br label %ht_probe_after_islot_empty_1844
ht_probe_after_islot_empty_1844:
  br label %ht_probe_end_1850
ht_probe_on_occ_1845:
  %t7979 = getelementptr inbounds i8*, i8** %t7958, i64 %t7973
  %t7980 = load i8*, i8** %t7979
  %t7981 = call i1 @eq_str(i8* %t7980, i8* %t7896)
  br i1 %t7981, label %ht_probe_on_match_1846, label %ht_probe_next_1849
ht_probe_on_match_1846:
  store i1 true, i1* %t7967
  store i64 %t7973, i64* %t7968
  br label %ht_probe_end_1850
ht_probe_on_tomb_1847:
  %t7982 = load i1, i1* %t7970
  br i1 %t7982, label %ht_probe_next_1849, label %ht_probe_set_islot_tomb_1848
ht_probe_set_islot_tomb_1848:
  store i64 %t7973, i64* %t7969
  store i1 true, i1* %t7970
  br label %ht_probe_next_1849
ht_probe_next_1849:
  %t7983 = add i64 %t7973, 1
  %t7984 = and i64 %t7983, %t7962
  store i64 %t7984, i64* %t7966
  %t7985 = add i64 %t7971, 1
  store i64 %t7985, i64* %t7965
  br label %ht_probe_cond_1839
ht_probe_end_1850:
  %t7986 = load i1, i1* %t7967
  %t7987 = load i64, i64* %t7968
  %t7988 = load i64, i64* %t7969
  br i1 %t7986, label %map_insert_overwrite_1851, label %map_insert_new_1852
map_insert_overwrite_1851:
  store i8* %t7896, i8** %t7989
  %t7990 = load i8*, i8** %t7989
  call void @star_rc_release(i8* %t7990)
  %t7991 = getelementptr inbounds i32, i32* %t7959, i64 %t7987
  store i32 43, i32* %t7991
  br label %map_insert_after_1853
map_insert_new_1852:
  %t7992 = getelementptr inbounds i8, i8* %t7960, i64 %t7988
  %t7993 = load i8, i8* %t7992
  %t7994 = icmp eq i8 %t7993, 2
  br i1 %t7994, label %map_insert_dec_tomb_1854, label %map_insert_store_1855
map_insert_dec_tomb_1854:
  %t7995 = load i64, i64* %t7894
  %t7996 = sub i64 %t7995, 1
  store i64 %t7996, i64* %t7894
  br label %map_insert_store_1855
map_insert_store_1855:
  store i8 1, i8* %t7992
  %t7997 = getelementptr inbounds i8*, i8** %t7958, i64 %t7988
  store i8* %t7896, i8** %t7997
  %t7998 = getelementptr inbounds i32, i32* %t7959, i64 %t7988
  store i32 43, i32* %t7998
  %t7999 = load i64, i64* %t7890
  %t8000 = add i64 %t7999, 1
  store i64 %t8000, i64* %t7890
  br label %map_insert_after_1853
map_insert_after_1853:
  %t8001 = getelementptr i8*, i8** null, i32 1
  %t8002 = ptrtoint i8** %t8001 to i64
  %t8003 = getelementptr i32, i32* null, i32 1
  %t8004 = ptrtoint i32* %t8003 to i64
  %t8005 = load i8*, i8** %t0
  %t8006 = icmp eq i8* %t8005, null
  br i1 %t8006, label %map_cow_alloc_1856, label %map_cow_check_1857
map_cow_alloc_1856:
  %t8007 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t8008 = call i8* @star_rc_alloc(i64 48, i8* %t8007)
  %t8009 = bitcast i8* %t8008 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8010 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8009, i32 0, i32 0
  store i8** null, i8*** %t8010
  %t8011 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8009, i32 0, i32 1
  store i32* null, i32** %t8011
  %t8012 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8009, i32 0, i32 2
  store i8* null, i8** %t8012
  %t8013 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8009, i32 0, i32 3
  store i64 0, i64* %t8013
  %t8014 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8009, i32 0, i32 4
  store i64 0, i64* %t8014
  %t8015 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8009, i32 0, i32 5
  store i64 0, i64* %t8015
  store i8* %t8008, i8** %t0
  br label %map_cow_done_1858
map_cow_check_1857:
  %t8016 = getelementptr inbounds i8, i8* %t8005, i64 -16
  %t8017 = bitcast i8* %t8016 to i64*
  %t8018 = load atomic i64, i64* %t8017 seq_cst, align 8
  %t8019 = icmp eq i64 %t8018, 1
  br i1 %t8019, label %map_cow_done_1858, label %map_cow_clone_1859
map_cow_clone_1859:
  %t8020 = bitcast i8* %t8005 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8021 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8020, i32 0, i32 0
  %t8022 = load i8**, i8*** %t8021
  %t8023 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8020, i32 0, i32 1
  %t8024 = load i32*, i32** %t8023
  %t8025 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8020, i32 0, i32 2
  %t8026 = load i8*, i8** %t8025
  %t8027 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8020, i32 0, i32 3
  %t8028 = load i64, i64* %t8027
  %t8029 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8020, i32 0, i32 4
  %t8030 = load i64, i64* %t8029
  %t8031 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8020, i32 0, i32 5
  %t8032 = load i64, i64* %t8031
  %t8033 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t8034 = call i8* @star_rc_alloc(i64 48, i8* %t8033)
  %t8035 = bitcast i8* %t8034 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8036 = mul i64 %t8030, %t8002
  %t8037 = call i8* @malloc(i64 %t8036)
  %t8038 = bitcast i8* %t8037 to i8**
  %t8039 = mul i64 %t8030, %t8004
  %t8040 = call i8* @malloc(i64 %t8039)
  %t8041 = bitcast i8* %t8040 to i32*
  %t8042 = call i8* @malloc(i64 %t8030)
  %t8043 = icmp sgt i64 %t8030, 0
  br i1 %t8043, label %map_cow_copy_1860, label %map_cow_after_copy_1861
map_cow_copy_1860:
  %t8044 = mul i64 %t8030, %t8002
  %t8045 = bitcast i8** %t8022 to i8*
  call i8* @memcpy(i8* %t8037, i8* %t8045, i64 %t8044)
  %t8046 = mul i64 %t8030, %t8004
  %t8047 = bitcast i32* %t8024 to i8*
  call i8* @memcpy(i8* %t8040, i8* %t8047, i64 %t8046)
  call i8* @memcpy(i8* %t8042, i8* %t8026, i64 %t8030)
  store i64 0, i64* %t8048
  br label %map_cow_retain_cond_1862
map_cow_retain_cond_1862:
  %t8049 = load i64, i64* %t8048
  %t8050 = icmp slt i64 %t8049, %t8030
  br i1 %t8050, label %map_cow_retain_body_1863, label %map_cow_retain_end_1866
map_cow_retain_body_1863:
  %t8051 = getelementptr inbounds i8, i8* %t8042, i64 %t8049
  %t8052 = load i8, i8* %t8051
  %t8053 = icmp eq i8 %t8052, 1
  br i1 %t8053, label %map_cow_retain_occ_1864, label %map_cow_retain_next_1865
map_cow_retain_occ_1864:
  %t8054 = getelementptr inbounds i8*, i8** %t8038, i64 %t8049
  %t8055 = load i8*, i8** %t8054
  call void @star_rc_retain(i8* %t8055)
  br label %map_cow_retain_next_1865
map_cow_retain_next_1865:
  %t8056 = add i64 %t8049, 1
  store i64 %t8056, i64* %t8048
  br label %map_cow_retain_cond_1862
map_cow_retain_end_1866:
  br label %map_cow_after_copy_1861
map_cow_after_copy_1861:
  %t8057 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8035, i32 0, i32 0
  store i8** %t8038, i8*** %t8057
  %t8058 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8035, i32 0, i32 1
  store i32* %t8041, i32** %t8058
  %t8059 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8035, i32 0, i32 2
  store i8* %t8042, i8** %t8059
  %t8060 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8035, i32 0, i32 3
  store i64 %t8028, i64* %t8060
  %t8061 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8035, i32 0, i32 4
  store i64 %t8030, i64* %t8061
  %t8062 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8035, i32 0, i32 5
  store i64 %t8032, i64* %t8062
  call void @star_rc_release(i8* %t8005)
  store i8* %t8034, i8** %t0
  br label %map_cow_done_1858
map_cow_done_1858:
  %t8063 = load i8*, i8** %t0
  %t8064 = bitcast i8* %t8063 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8065 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8064, i32 0, i32 0
  %t8066 = load i8**, i8*** %t8065
  %t8067 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8064, i32 0, i32 1
  %t8068 = load i32*, i32** %t8067
  %t8069 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8064, i32 0, i32 2
  %t8070 = load i8*, i8** %t8069
  %t8071 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8064, i32 0, i32 3
  %t8072 = load i64, i64* %t8071
  %t8073 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8064, i32 0, i32 4
  %t8074 = load i64, i64* %t8073
  %t8075 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8064, i32 0, i32 5
  %t8076 = load i64, i64* %t8075
  %t8077 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.44, i64 0, i32 2, i64 0
  %t8078 = load i64, i64* %t8071
  %t8079 = load i64, i64* %t8073
  %t8080 = load i64, i64* %t8075
  %t8081 = add i64 %t8078, %t8080
  %t8082 = add i64 %t8081, 1
  %t8083 = mul i64 %t8082, 4
  %t8084 = mul i64 %t8079, 3
  %t8085 = icmp sgt i64 %t8083, %t8084
  br i1 %t8085, label %map_insert_grow_1867, label %map_insert_after_grow_1868
map_insert_grow_1867:
  %t8086 = getelementptr i8*, i8** null, i32 1
  %t8087 = ptrtoint i8** %t8086 to i64
  %t8088 = getelementptr i32, i32* null, i32 1
  %t8089 = ptrtoint i32* %t8088 to i64
  %t8090 = mul i64 %t8079, 2
  %t8091 = icmp sgt i64 %t8090, 0
  %t8092 = select i1 %t8091, i64 %t8090, i64 8
  %t8093 = sub i64 %t8092, 1
  %t8094 = mul i64 %t8092, %t8087
  %t8095 = call i8* @malloc(i64 %t8094)
  %t8096 = bitcast i8* %t8095 to i8**
  %t8097 = mul i64 %t8092, %t8089
  %t8098 = call i8* @malloc(i64 %t8097)
  %t8099 = bitcast i8* %t8098 to i32*
  %t8100 = call i8* @malloc(i64 %t8092)
  store i64 0, i64* %t8101
  br label %ht_fill8_cond_1869
ht_fill8_cond_1869:
  %t8102 = load i64, i64* %t8101
  %t8103 = icmp slt i64 %t8102, %t8092
  br i1 %t8103, label %ht_fill8_body_1870, label %ht_fill8_end_1871
ht_fill8_body_1870:
  %t8104 = getelementptr inbounds i8, i8* %t8100, i64 %t8102
  store i8 0, i8* %t8104
  %t8105 = add i64 %t8102, 1
  store i64 %t8105, i64* %t8101
  br label %ht_fill8_cond_1869
ht_fill8_end_1871:
  %t8106 = load i8**, i8*** %t8065
  %t8107 = load i32*, i32** %t8067
  %t8108 = load i8*, i8** %t8069
  store i64 0, i64* %t8109
  br label %map_grow_cond_1872
map_grow_cond_1872:
  %t8110 = load i64, i64* %t8109
  %t8111 = icmp slt i64 %t8110, %t8079
  br i1 %t8111, label %map_grow_body_1873, label %map_grow_end_1876
map_grow_body_1873:
  %t8112 = getelementptr inbounds i8, i8* %t8108, i64 %t8110
  %t8113 = load i8, i8* %t8112
  %t8114 = icmp eq i8 %t8113, 1
  br i1 %t8114, label %map_grow_occ_1874, label %map_grow_next_1875
map_grow_occ_1874:
  %t8115 = getelementptr inbounds i8*, i8** %t8106, i64 %t8110
  %t8116 = load i8*, i8** %t8115
  %t8117 = getelementptr inbounds i32, i32* %t8107, i64 %t8110
  %t8118 = load i32, i32* %t8117
  %t8119 = call i64 @hash_str(i8* %t8116)
  %t8120 = and i64 %t8119, %t8093
  store i64 0, i64* %t8121
  store i64 %t8120, i64* %t8122
  br label %ht_fe_cond_1877
ht_fe_cond_1877:
  %t8123 = load i64, i64* %t8121
  %t8124 = icmp slt i64 %t8123, %t8092
  br i1 %t8124, label %ht_fe_body_1878, label %ht_fe_end_1880
ht_fe_body_1878:
  %t8125 = load i64, i64* %t8122
  %t8126 = getelementptr inbounds i8, i8* %t8100, i64 %t8125
  %t8127 = load i8, i8* %t8126
  %t8128 = icmp eq i8 %t8127, 0
  br i1 %t8128, label %ht_fe_end_1880, label %ht_fe_next_1879
ht_fe_next_1879:
  %t8129 = add i64 %t8125, 1
  %t8130 = and i64 %t8129, %t8093
  store i64 %t8130, i64* %t8122
  %t8131 = add i64 %t8123, 1
  store i64 %t8131, i64* %t8121
  br label %ht_fe_cond_1877
ht_fe_end_1880:
  %t8132 = load i64, i64* %t8122
  %t8133 = getelementptr inbounds i8, i8* %t8100, i64 %t8132
  store i8 1, i8* %t8133
  %t8134 = getelementptr inbounds i8*, i8** %t8096, i64 %t8132
  store i8* %t8116, i8** %t8134
  %t8135 = getelementptr inbounds i32, i32* %t8099, i64 %t8132
  store i32 %t8118, i32* %t8135
  br label %map_grow_next_1875
map_grow_next_1875:
  %t8136 = add i64 %t8110, 1
  store i64 %t8136, i64* %t8109
  br label %map_grow_cond_1872
map_grow_end_1876:
  %t8137 = bitcast i8** %t8106 to i8*
  call void @free(i8* %t8137)
  %t8138 = bitcast i32* %t8107 to i8*
  call void @free(i8* %t8138)
  call void @free(i8* %t8108)
  store i8** %t8096, i8*** %t8065
  store i32* %t8099, i32** %t8067
  store i8* %t8100, i8** %t8069
  store i64 %t8092, i64* %t8073
  store i64 0, i64* %t8075
  br label %map_insert_after_grow_1868
map_insert_after_grow_1868:
  %t8139 = load i8**, i8*** %t8065
  %t8140 = load i32*, i32** %t8067
  %t8141 = load i8*, i8** %t8069
  %t8142 = load i64, i64* %t8073
  %t8143 = sub i64 %t8142, 1
  %t8144 = call i64 @hash_str(i8* %t8077)
  %t8145 = and i64 %t8144, %t8143
  store i64 0, i64* %t8146
  store i64 %t8145, i64* %t8147
  store i1 false, i1* %t8148
  store i64 -1, i64* %t8149
  store i64 -1, i64* %t8150
  store i1 false, i1* %t8151
  br label %ht_probe_cond_1881
ht_probe_cond_1881:
  %t8152 = load i64, i64* %t8146
  %t8153 = icmp slt i64 %t8152, %t8142
  br i1 %t8153, label %ht_probe_body_1882, label %ht_probe_end_1892
ht_probe_body_1882:
  %t8154 = load i64, i64* %t8147
  %t8155 = getelementptr inbounds i8, i8* %t8141, i64 %t8154
  %t8156 = load i8, i8* %t8155
  %t8157 = icmp eq i8 %t8156, 0
  br i1 %t8157, label %ht_probe_on_empty_1884, label %ht_probe_check_occ_1883
ht_probe_check_occ_1883:
  %t8158 = icmp eq i8 %t8156, 1
  br i1 %t8158, label %ht_probe_on_occ_1887, label %ht_probe_on_tomb_1889
ht_probe_on_empty_1884:
  %t8159 = load i1, i1* %t8151
  br i1 %t8159, label %ht_probe_after_islot_empty_1886, label %ht_probe_set_islot_empty_1885
ht_probe_set_islot_empty_1885:
  store i64 %t8154, i64* %t8150
  store i1 true, i1* %t8151
  br label %ht_probe_after_islot_empty_1886
ht_probe_after_islot_empty_1886:
  br label %ht_probe_end_1892
ht_probe_on_occ_1887:
  %t8160 = getelementptr inbounds i8*, i8** %t8139, i64 %t8154
  %t8161 = load i8*, i8** %t8160
  %t8162 = call i1 @eq_str(i8* %t8161, i8* %t8077)
  br i1 %t8162, label %ht_probe_on_match_1888, label %ht_probe_next_1891
ht_probe_on_match_1888:
  store i1 true, i1* %t8148
  store i64 %t8154, i64* %t8149
  br label %ht_probe_end_1892
ht_probe_on_tomb_1889:
  %t8163 = load i1, i1* %t8151
  br i1 %t8163, label %ht_probe_next_1891, label %ht_probe_set_islot_tomb_1890
ht_probe_set_islot_tomb_1890:
  store i64 %t8154, i64* %t8150
  store i1 true, i1* %t8151
  br label %ht_probe_next_1891
ht_probe_next_1891:
  %t8164 = add i64 %t8154, 1
  %t8165 = and i64 %t8164, %t8143
  store i64 %t8165, i64* %t8147
  %t8166 = add i64 %t8152, 1
  store i64 %t8166, i64* %t8146
  br label %ht_probe_cond_1881
ht_probe_end_1892:
  %t8167 = load i1, i1* %t8148
  %t8168 = load i64, i64* %t8149
  %t8169 = load i64, i64* %t8150
  br i1 %t8167, label %map_insert_overwrite_1893, label %map_insert_new_1894
map_insert_overwrite_1893:
  store i8* %t8077, i8** %t8170
  %t8171 = load i8*, i8** %t8170
  call void @star_rc_release(i8* %t8171)
  %t8172 = getelementptr inbounds i32, i32* %t8140, i64 %t8168
  store i32 44, i32* %t8172
  br label %map_insert_after_1895
map_insert_new_1894:
  %t8173 = getelementptr inbounds i8, i8* %t8141, i64 %t8169
  %t8174 = load i8, i8* %t8173
  %t8175 = icmp eq i8 %t8174, 2
  br i1 %t8175, label %map_insert_dec_tomb_1896, label %map_insert_store_1897
map_insert_dec_tomb_1896:
  %t8176 = load i64, i64* %t8075
  %t8177 = sub i64 %t8176, 1
  store i64 %t8177, i64* %t8075
  br label %map_insert_store_1897
map_insert_store_1897:
  store i8 1, i8* %t8173
  %t8178 = getelementptr inbounds i8*, i8** %t8139, i64 %t8169
  store i8* %t8077, i8** %t8178
  %t8179 = getelementptr inbounds i32, i32* %t8140, i64 %t8169
  store i32 44, i32* %t8179
  %t8180 = load i64, i64* %t8071
  %t8181 = add i64 %t8180, 1
  store i64 %t8181, i64* %t8071
  br label %map_insert_after_1895
map_insert_after_1895:
  %t8182 = getelementptr i8*, i8** null, i32 1
  %t8183 = ptrtoint i8** %t8182 to i64
  %t8184 = getelementptr i32, i32* null, i32 1
  %t8185 = ptrtoint i32* %t8184 to i64
  %t8186 = load i8*, i8** %t0
  %t8187 = icmp eq i8* %t8186, null
  br i1 %t8187, label %map_cow_alloc_1898, label %map_cow_check_1899
map_cow_alloc_1898:
  %t8188 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t8189 = call i8* @star_rc_alloc(i64 48, i8* %t8188)
  %t8190 = bitcast i8* %t8189 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8191 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8190, i32 0, i32 0
  store i8** null, i8*** %t8191
  %t8192 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8190, i32 0, i32 1
  store i32* null, i32** %t8192
  %t8193 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8190, i32 0, i32 2
  store i8* null, i8** %t8193
  %t8194 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8190, i32 0, i32 3
  store i64 0, i64* %t8194
  %t8195 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8190, i32 0, i32 4
  store i64 0, i64* %t8195
  %t8196 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8190, i32 0, i32 5
  store i64 0, i64* %t8196
  store i8* %t8189, i8** %t0
  br label %map_cow_done_1900
map_cow_check_1899:
  %t8197 = getelementptr inbounds i8, i8* %t8186, i64 -16
  %t8198 = bitcast i8* %t8197 to i64*
  %t8199 = load atomic i64, i64* %t8198 seq_cst, align 8
  %t8200 = icmp eq i64 %t8199, 1
  br i1 %t8200, label %map_cow_done_1900, label %map_cow_clone_1901
map_cow_clone_1901:
  %t8201 = bitcast i8* %t8186 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8202 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8201, i32 0, i32 0
  %t8203 = load i8**, i8*** %t8202
  %t8204 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8201, i32 0, i32 1
  %t8205 = load i32*, i32** %t8204
  %t8206 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8201, i32 0, i32 2
  %t8207 = load i8*, i8** %t8206
  %t8208 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8201, i32 0, i32 3
  %t8209 = load i64, i64* %t8208
  %t8210 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8201, i32 0, i32 4
  %t8211 = load i64, i64* %t8210
  %t8212 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8201, i32 0, i32 5
  %t8213 = load i64, i64* %t8212
  %t8214 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t8215 = call i8* @star_rc_alloc(i64 48, i8* %t8214)
  %t8216 = bitcast i8* %t8215 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8217 = mul i64 %t8211, %t8183
  %t8218 = call i8* @malloc(i64 %t8217)
  %t8219 = bitcast i8* %t8218 to i8**
  %t8220 = mul i64 %t8211, %t8185
  %t8221 = call i8* @malloc(i64 %t8220)
  %t8222 = bitcast i8* %t8221 to i32*
  %t8223 = call i8* @malloc(i64 %t8211)
  %t8224 = icmp sgt i64 %t8211, 0
  br i1 %t8224, label %map_cow_copy_1902, label %map_cow_after_copy_1903
map_cow_copy_1902:
  %t8225 = mul i64 %t8211, %t8183
  %t8226 = bitcast i8** %t8203 to i8*
  call i8* @memcpy(i8* %t8218, i8* %t8226, i64 %t8225)
  %t8227 = mul i64 %t8211, %t8185
  %t8228 = bitcast i32* %t8205 to i8*
  call i8* @memcpy(i8* %t8221, i8* %t8228, i64 %t8227)
  call i8* @memcpy(i8* %t8223, i8* %t8207, i64 %t8211)
  store i64 0, i64* %t8229
  br label %map_cow_retain_cond_1904
map_cow_retain_cond_1904:
  %t8230 = load i64, i64* %t8229
  %t8231 = icmp slt i64 %t8230, %t8211
  br i1 %t8231, label %map_cow_retain_body_1905, label %map_cow_retain_end_1908
map_cow_retain_body_1905:
  %t8232 = getelementptr inbounds i8, i8* %t8223, i64 %t8230
  %t8233 = load i8, i8* %t8232
  %t8234 = icmp eq i8 %t8233, 1
  br i1 %t8234, label %map_cow_retain_occ_1906, label %map_cow_retain_next_1907
map_cow_retain_occ_1906:
  %t8235 = getelementptr inbounds i8*, i8** %t8219, i64 %t8230
  %t8236 = load i8*, i8** %t8235
  call void @star_rc_retain(i8* %t8236)
  br label %map_cow_retain_next_1907
map_cow_retain_next_1907:
  %t8237 = add i64 %t8230, 1
  store i64 %t8237, i64* %t8229
  br label %map_cow_retain_cond_1904
map_cow_retain_end_1908:
  br label %map_cow_after_copy_1903
map_cow_after_copy_1903:
  %t8238 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8216, i32 0, i32 0
  store i8** %t8219, i8*** %t8238
  %t8239 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8216, i32 0, i32 1
  store i32* %t8222, i32** %t8239
  %t8240 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8216, i32 0, i32 2
  store i8* %t8223, i8** %t8240
  %t8241 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8216, i32 0, i32 3
  store i64 %t8209, i64* %t8241
  %t8242 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8216, i32 0, i32 4
  store i64 %t8211, i64* %t8242
  %t8243 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8216, i32 0, i32 5
  store i64 %t8213, i64* %t8243
  call void @star_rc_release(i8* %t8186)
  store i8* %t8215, i8** %t0
  br label %map_cow_done_1900
map_cow_done_1900:
  %t8244 = load i8*, i8** %t0
  %t8245 = bitcast i8* %t8244 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8246 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8245, i32 0, i32 0
  %t8247 = load i8**, i8*** %t8246
  %t8248 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8245, i32 0, i32 1
  %t8249 = load i32*, i32** %t8248
  %t8250 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8245, i32 0, i32 2
  %t8251 = load i8*, i8** %t8250
  %t8252 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8245, i32 0, i32 3
  %t8253 = load i64, i64* %t8252
  %t8254 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8245, i32 0, i32 4
  %t8255 = load i64, i64* %t8254
  %t8256 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8245, i32 0, i32 5
  %t8257 = load i64, i64* %t8256
  %t8258 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.45, i64 0, i32 2, i64 0
  %t8259 = load i64, i64* %t8252
  %t8260 = load i64, i64* %t8254
  %t8261 = load i64, i64* %t8256
  %t8262 = add i64 %t8259, %t8261
  %t8263 = add i64 %t8262, 1
  %t8264 = mul i64 %t8263, 4
  %t8265 = mul i64 %t8260, 3
  %t8266 = icmp sgt i64 %t8264, %t8265
  br i1 %t8266, label %map_insert_grow_1909, label %map_insert_after_grow_1910
map_insert_grow_1909:
  %t8267 = getelementptr i8*, i8** null, i32 1
  %t8268 = ptrtoint i8** %t8267 to i64
  %t8269 = getelementptr i32, i32* null, i32 1
  %t8270 = ptrtoint i32* %t8269 to i64
  %t8271 = mul i64 %t8260, 2
  %t8272 = icmp sgt i64 %t8271, 0
  %t8273 = select i1 %t8272, i64 %t8271, i64 8
  %t8274 = sub i64 %t8273, 1
  %t8275 = mul i64 %t8273, %t8268
  %t8276 = call i8* @malloc(i64 %t8275)
  %t8277 = bitcast i8* %t8276 to i8**
  %t8278 = mul i64 %t8273, %t8270
  %t8279 = call i8* @malloc(i64 %t8278)
  %t8280 = bitcast i8* %t8279 to i32*
  %t8281 = call i8* @malloc(i64 %t8273)
  store i64 0, i64* %t8282
  br label %ht_fill8_cond_1911
ht_fill8_cond_1911:
  %t8283 = load i64, i64* %t8282
  %t8284 = icmp slt i64 %t8283, %t8273
  br i1 %t8284, label %ht_fill8_body_1912, label %ht_fill8_end_1913
ht_fill8_body_1912:
  %t8285 = getelementptr inbounds i8, i8* %t8281, i64 %t8283
  store i8 0, i8* %t8285
  %t8286 = add i64 %t8283, 1
  store i64 %t8286, i64* %t8282
  br label %ht_fill8_cond_1911
ht_fill8_end_1913:
  %t8287 = load i8**, i8*** %t8246
  %t8288 = load i32*, i32** %t8248
  %t8289 = load i8*, i8** %t8250
  store i64 0, i64* %t8290
  br label %map_grow_cond_1914
map_grow_cond_1914:
  %t8291 = load i64, i64* %t8290
  %t8292 = icmp slt i64 %t8291, %t8260
  br i1 %t8292, label %map_grow_body_1915, label %map_grow_end_1918
map_grow_body_1915:
  %t8293 = getelementptr inbounds i8, i8* %t8289, i64 %t8291
  %t8294 = load i8, i8* %t8293
  %t8295 = icmp eq i8 %t8294, 1
  br i1 %t8295, label %map_grow_occ_1916, label %map_grow_next_1917
map_grow_occ_1916:
  %t8296 = getelementptr inbounds i8*, i8** %t8287, i64 %t8291
  %t8297 = load i8*, i8** %t8296
  %t8298 = getelementptr inbounds i32, i32* %t8288, i64 %t8291
  %t8299 = load i32, i32* %t8298
  %t8300 = call i64 @hash_str(i8* %t8297)
  %t8301 = and i64 %t8300, %t8274
  store i64 0, i64* %t8302
  store i64 %t8301, i64* %t8303
  br label %ht_fe_cond_1919
ht_fe_cond_1919:
  %t8304 = load i64, i64* %t8302
  %t8305 = icmp slt i64 %t8304, %t8273
  br i1 %t8305, label %ht_fe_body_1920, label %ht_fe_end_1922
ht_fe_body_1920:
  %t8306 = load i64, i64* %t8303
  %t8307 = getelementptr inbounds i8, i8* %t8281, i64 %t8306
  %t8308 = load i8, i8* %t8307
  %t8309 = icmp eq i8 %t8308, 0
  br i1 %t8309, label %ht_fe_end_1922, label %ht_fe_next_1921
ht_fe_next_1921:
  %t8310 = add i64 %t8306, 1
  %t8311 = and i64 %t8310, %t8274
  store i64 %t8311, i64* %t8303
  %t8312 = add i64 %t8304, 1
  store i64 %t8312, i64* %t8302
  br label %ht_fe_cond_1919
ht_fe_end_1922:
  %t8313 = load i64, i64* %t8303
  %t8314 = getelementptr inbounds i8, i8* %t8281, i64 %t8313
  store i8 1, i8* %t8314
  %t8315 = getelementptr inbounds i8*, i8** %t8277, i64 %t8313
  store i8* %t8297, i8** %t8315
  %t8316 = getelementptr inbounds i32, i32* %t8280, i64 %t8313
  store i32 %t8299, i32* %t8316
  br label %map_grow_next_1917
map_grow_next_1917:
  %t8317 = add i64 %t8291, 1
  store i64 %t8317, i64* %t8290
  br label %map_grow_cond_1914
map_grow_end_1918:
  %t8318 = bitcast i8** %t8287 to i8*
  call void @free(i8* %t8318)
  %t8319 = bitcast i32* %t8288 to i8*
  call void @free(i8* %t8319)
  call void @free(i8* %t8289)
  store i8** %t8277, i8*** %t8246
  store i32* %t8280, i32** %t8248
  store i8* %t8281, i8** %t8250
  store i64 %t8273, i64* %t8254
  store i64 0, i64* %t8256
  br label %map_insert_after_grow_1910
map_insert_after_grow_1910:
  %t8320 = load i8**, i8*** %t8246
  %t8321 = load i32*, i32** %t8248
  %t8322 = load i8*, i8** %t8250
  %t8323 = load i64, i64* %t8254
  %t8324 = sub i64 %t8323, 1
  %t8325 = call i64 @hash_str(i8* %t8258)
  %t8326 = and i64 %t8325, %t8324
  store i64 0, i64* %t8327
  store i64 %t8326, i64* %t8328
  store i1 false, i1* %t8329
  store i64 -1, i64* %t8330
  store i64 -1, i64* %t8331
  store i1 false, i1* %t8332
  br label %ht_probe_cond_1923
ht_probe_cond_1923:
  %t8333 = load i64, i64* %t8327
  %t8334 = icmp slt i64 %t8333, %t8323
  br i1 %t8334, label %ht_probe_body_1924, label %ht_probe_end_1934
ht_probe_body_1924:
  %t8335 = load i64, i64* %t8328
  %t8336 = getelementptr inbounds i8, i8* %t8322, i64 %t8335
  %t8337 = load i8, i8* %t8336
  %t8338 = icmp eq i8 %t8337, 0
  br i1 %t8338, label %ht_probe_on_empty_1926, label %ht_probe_check_occ_1925
ht_probe_check_occ_1925:
  %t8339 = icmp eq i8 %t8337, 1
  br i1 %t8339, label %ht_probe_on_occ_1929, label %ht_probe_on_tomb_1931
ht_probe_on_empty_1926:
  %t8340 = load i1, i1* %t8332
  br i1 %t8340, label %ht_probe_after_islot_empty_1928, label %ht_probe_set_islot_empty_1927
ht_probe_set_islot_empty_1927:
  store i64 %t8335, i64* %t8331
  store i1 true, i1* %t8332
  br label %ht_probe_after_islot_empty_1928
ht_probe_after_islot_empty_1928:
  br label %ht_probe_end_1934
ht_probe_on_occ_1929:
  %t8341 = getelementptr inbounds i8*, i8** %t8320, i64 %t8335
  %t8342 = load i8*, i8** %t8341
  %t8343 = call i1 @eq_str(i8* %t8342, i8* %t8258)
  br i1 %t8343, label %ht_probe_on_match_1930, label %ht_probe_next_1933
ht_probe_on_match_1930:
  store i1 true, i1* %t8329
  store i64 %t8335, i64* %t8330
  br label %ht_probe_end_1934
ht_probe_on_tomb_1931:
  %t8344 = load i1, i1* %t8332
  br i1 %t8344, label %ht_probe_next_1933, label %ht_probe_set_islot_tomb_1932
ht_probe_set_islot_tomb_1932:
  store i64 %t8335, i64* %t8331
  store i1 true, i1* %t8332
  br label %ht_probe_next_1933
ht_probe_next_1933:
  %t8345 = add i64 %t8335, 1
  %t8346 = and i64 %t8345, %t8324
  store i64 %t8346, i64* %t8328
  %t8347 = add i64 %t8333, 1
  store i64 %t8347, i64* %t8327
  br label %ht_probe_cond_1923
ht_probe_end_1934:
  %t8348 = load i1, i1* %t8329
  %t8349 = load i64, i64* %t8330
  %t8350 = load i64, i64* %t8331
  br i1 %t8348, label %map_insert_overwrite_1935, label %map_insert_new_1936
map_insert_overwrite_1935:
  store i8* %t8258, i8** %t8351
  %t8352 = load i8*, i8** %t8351
  call void @star_rc_release(i8* %t8352)
  %t8353 = getelementptr inbounds i32, i32* %t8321, i64 %t8349
  store i32 81, i32* %t8353
  br label %map_insert_after_1937
map_insert_new_1936:
  %t8354 = getelementptr inbounds i8, i8* %t8322, i64 %t8350
  %t8355 = load i8, i8* %t8354
  %t8356 = icmp eq i8 %t8355, 2
  br i1 %t8356, label %map_insert_dec_tomb_1938, label %map_insert_store_1939
map_insert_dec_tomb_1938:
  %t8357 = load i64, i64* %t8256
  %t8358 = sub i64 %t8357, 1
  store i64 %t8358, i64* %t8256
  br label %map_insert_store_1939
map_insert_store_1939:
  store i8 1, i8* %t8354
  %t8359 = getelementptr inbounds i8*, i8** %t8320, i64 %t8350
  store i8* %t8258, i8** %t8359
  %t8360 = getelementptr inbounds i32, i32* %t8321, i64 %t8350
  store i32 81, i32* %t8360
  %t8361 = load i64, i64* %t8252
  %t8362 = add i64 %t8361, 1
  store i64 %t8362, i64* %t8252
  br label %map_insert_after_1937
map_insert_after_1937:
  %t8363 = getelementptr i8*, i8** null, i32 1
  %t8364 = ptrtoint i8** %t8363 to i64
  %t8365 = getelementptr i32, i32* null, i32 1
  %t8366 = ptrtoint i32* %t8365 to i64
  %t8367 = load i8*, i8** %t0
  %t8368 = icmp eq i8* %t8367, null
  br i1 %t8368, label %map_cow_alloc_1940, label %map_cow_check_1941
map_cow_alloc_1940:
  %t8369 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t8370 = call i8* @star_rc_alloc(i64 48, i8* %t8369)
  %t8371 = bitcast i8* %t8370 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8372 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8371, i32 0, i32 0
  store i8** null, i8*** %t8372
  %t8373 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8371, i32 0, i32 1
  store i32* null, i32** %t8373
  %t8374 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8371, i32 0, i32 2
  store i8* null, i8** %t8374
  %t8375 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8371, i32 0, i32 3
  store i64 0, i64* %t8375
  %t8376 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8371, i32 0, i32 4
  store i64 0, i64* %t8376
  %t8377 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8371, i32 0, i32 5
  store i64 0, i64* %t8377
  store i8* %t8370, i8** %t0
  br label %map_cow_done_1942
map_cow_check_1941:
  %t8378 = getelementptr inbounds i8, i8* %t8367, i64 -16
  %t8379 = bitcast i8* %t8378 to i64*
  %t8380 = load atomic i64, i64* %t8379 seq_cst, align 8
  %t8381 = icmp eq i64 %t8380, 1
  br i1 %t8381, label %map_cow_done_1942, label %map_cow_clone_1943
map_cow_clone_1943:
  %t8382 = bitcast i8* %t8367 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8383 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8382, i32 0, i32 0
  %t8384 = load i8**, i8*** %t8383
  %t8385 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8382, i32 0, i32 1
  %t8386 = load i32*, i32** %t8385
  %t8387 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8382, i32 0, i32 2
  %t8388 = load i8*, i8** %t8387
  %t8389 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8382, i32 0, i32 3
  %t8390 = load i64, i64* %t8389
  %t8391 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8382, i32 0, i32 4
  %t8392 = load i64, i64* %t8391
  %t8393 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8382, i32 0, i32 5
  %t8394 = load i64, i64* %t8393
  %t8395 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t8396 = call i8* @star_rc_alloc(i64 48, i8* %t8395)
  %t8397 = bitcast i8* %t8396 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8398 = mul i64 %t8392, %t8364
  %t8399 = call i8* @malloc(i64 %t8398)
  %t8400 = bitcast i8* %t8399 to i8**
  %t8401 = mul i64 %t8392, %t8366
  %t8402 = call i8* @malloc(i64 %t8401)
  %t8403 = bitcast i8* %t8402 to i32*
  %t8404 = call i8* @malloc(i64 %t8392)
  %t8405 = icmp sgt i64 %t8392, 0
  br i1 %t8405, label %map_cow_copy_1944, label %map_cow_after_copy_1945
map_cow_copy_1944:
  %t8406 = mul i64 %t8392, %t8364
  %t8407 = bitcast i8** %t8384 to i8*
  call i8* @memcpy(i8* %t8399, i8* %t8407, i64 %t8406)
  %t8408 = mul i64 %t8392, %t8366
  %t8409 = bitcast i32* %t8386 to i8*
  call i8* @memcpy(i8* %t8402, i8* %t8409, i64 %t8408)
  call i8* @memcpy(i8* %t8404, i8* %t8388, i64 %t8392)
  store i64 0, i64* %t8410
  br label %map_cow_retain_cond_1946
map_cow_retain_cond_1946:
  %t8411 = load i64, i64* %t8410
  %t8412 = icmp slt i64 %t8411, %t8392
  br i1 %t8412, label %map_cow_retain_body_1947, label %map_cow_retain_end_1950
map_cow_retain_body_1947:
  %t8413 = getelementptr inbounds i8, i8* %t8404, i64 %t8411
  %t8414 = load i8, i8* %t8413
  %t8415 = icmp eq i8 %t8414, 1
  br i1 %t8415, label %map_cow_retain_occ_1948, label %map_cow_retain_next_1949
map_cow_retain_occ_1948:
  %t8416 = getelementptr inbounds i8*, i8** %t8400, i64 %t8411
  %t8417 = load i8*, i8** %t8416
  call void @star_rc_retain(i8* %t8417)
  br label %map_cow_retain_next_1949
map_cow_retain_next_1949:
  %t8418 = add i64 %t8411, 1
  store i64 %t8418, i64* %t8410
  br label %map_cow_retain_cond_1946
map_cow_retain_end_1950:
  br label %map_cow_after_copy_1945
map_cow_after_copy_1945:
  %t8419 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8397, i32 0, i32 0
  store i8** %t8400, i8*** %t8419
  %t8420 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8397, i32 0, i32 1
  store i32* %t8403, i32** %t8420
  %t8421 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8397, i32 0, i32 2
  store i8* %t8404, i8** %t8421
  %t8422 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8397, i32 0, i32 3
  store i64 %t8390, i64* %t8422
  %t8423 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8397, i32 0, i32 4
  store i64 %t8392, i64* %t8423
  %t8424 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8397, i32 0, i32 5
  store i64 %t8394, i64* %t8424
  call void @star_rc_release(i8* %t8367)
  store i8* %t8396, i8** %t0
  br label %map_cow_done_1942
map_cow_done_1942:
  %t8425 = load i8*, i8** %t0
  %t8426 = bitcast i8* %t8425 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8427 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8426, i32 0, i32 0
  %t8428 = load i8**, i8*** %t8427
  %t8429 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8426, i32 0, i32 1
  %t8430 = load i32*, i32** %t8429
  %t8431 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8426, i32 0, i32 2
  %t8432 = load i8*, i8** %t8431
  %t8433 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8426, i32 0, i32 3
  %t8434 = load i64, i64* %t8433
  %t8435 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8426, i32 0, i32 4
  %t8436 = load i64, i64* %t8435
  %t8437 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8426, i32 0, i32 5
  %t8438 = load i64, i64* %t8437
  %t8439 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.46, i64 0, i32 2, i64 0
  %t8440 = load i64, i64* %t8433
  %t8441 = load i64, i64* %t8435
  %t8442 = load i64, i64* %t8437
  %t8443 = add i64 %t8440, %t8442
  %t8444 = add i64 %t8443, 1
  %t8445 = mul i64 %t8444, 4
  %t8446 = mul i64 %t8441, 3
  %t8447 = icmp sgt i64 %t8445, %t8446
  br i1 %t8447, label %map_insert_grow_1951, label %map_insert_after_grow_1952
map_insert_grow_1951:
  %t8448 = getelementptr i8*, i8** null, i32 1
  %t8449 = ptrtoint i8** %t8448 to i64
  %t8450 = getelementptr i32, i32* null, i32 1
  %t8451 = ptrtoint i32* %t8450 to i64
  %t8452 = mul i64 %t8441, 2
  %t8453 = icmp sgt i64 %t8452, 0
  %t8454 = select i1 %t8453, i64 %t8452, i64 8
  %t8455 = sub i64 %t8454, 1
  %t8456 = mul i64 %t8454, %t8449
  %t8457 = call i8* @malloc(i64 %t8456)
  %t8458 = bitcast i8* %t8457 to i8**
  %t8459 = mul i64 %t8454, %t8451
  %t8460 = call i8* @malloc(i64 %t8459)
  %t8461 = bitcast i8* %t8460 to i32*
  %t8462 = call i8* @malloc(i64 %t8454)
  store i64 0, i64* %t8463
  br label %ht_fill8_cond_1953
ht_fill8_cond_1953:
  %t8464 = load i64, i64* %t8463
  %t8465 = icmp slt i64 %t8464, %t8454
  br i1 %t8465, label %ht_fill8_body_1954, label %ht_fill8_end_1955
ht_fill8_body_1954:
  %t8466 = getelementptr inbounds i8, i8* %t8462, i64 %t8464
  store i8 0, i8* %t8466
  %t8467 = add i64 %t8464, 1
  store i64 %t8467, i64* %t8463
  br label %ht_fill8_cond_1953
ht_fill8_end_1955:
  %t8468 = load i8**, i8*** %t8427
  %t8469 = load i32*, i32** %t8429
  %t8470 = load i8*, i8** %t8431
  store i64 0, i64* %t8471
  br label %map_grow_cond_1956
map_grow_cond_1956:
  %t8472 = load i64, i64* %t8471
  %t8473 = icmp slt i64 %t8472, %t8441
  br i1 %t8473, label %map_grow_body_1957, label %map_grow_end_1960
map_grow_body_1957:
  %t8474 = getelementptr inbounds i8, i8* %t8470, i64 %t8472
  %t8475 = load i8, i8* %t8474
  %t8476 = icmp eq i8 %t8475, 1
  br i1 %t8476, label %map_grow_occ_1958, label %map_grow_next_1959
map_grow_occ_1958:
  %t8477 = getelementptr inbounds i8*, i8** %t8468, i64 %t8472
  %t8478 = load i8*, i8** %t8477
  %t8479 = getelementptr inbounds i32, i32* %t8469, i64 %t8472
  %t8480 = load i32, i32* %t8479
  %t8481 = call i64 @hash_str(i8* %t8478)
  %t8482 = and i64 %t8481, %t8455
  store i64 0, i64* %t8483
  store i64 %t8482, i64* %t8484
  br label %ht_fe_cond_1961
ht_fe_cond_1961:
  %t8485 = load i64, i64* %t8483
  %t8486 = icmp slt i64 %t8485, %t8454
  br i1 %t8486, label %ht_fe_body_1962, label %ht_fe_end_1964
ht_fe_body_1962:
  %t8487 = load i64, i64* %t8484
  %t8488 = getelementptr inbounds i8, i8* %t8462, i64 %t8487
  %t8489 = load i8, i8* %t8488
  %t8490 = icmp eq i8 %t8489, 0
  br i1 %t8490, label %ht_fe_end_1964, label %ht_fe_next_1963
ht_fe_next_1963:
  %t8491 = add i64 %t8487, 1
  %t8492 = and i64 %t8491, %t8455
  store i64 %t8492, i64* %t8484
  %t8493 = add i64 %t8485, 1
  store i64 %t8493, i64* %t8483
  br label %ht_fe_cond_1961
ht_fe_end_1964:
  %t8494 = load i64, i64* %t8484
  %t8495 = getelementptr inbounds i8, i8* %t8462, i64 %t8494
  store i8 1, i8* %t8495
  %t8496 = getelementptr inbounds i8*, i8** %t8458, i64 %t8494
  store i8* %t8478, i8** %t8496
  %t8497 = getelementptr inbounds i32, i32* %t8461, i64 %t8494
  store i32 %t8480, i32* %t8497
  br label %map_grow_next_1959
map_grow_next_1959:
  %t8498 = add i64 %t8472, 1
  store i64 %t8498, i64* %t8471
  br label %map_grow_cond_1956
map_grow_end_1960:
  %t8499 = bitcast i8** %t8468 to i8*
  call void @free(i8* %t8499)
  %t8500 = bitcast i32* %t8469 to i8*
  call void @free(i8* %t8500)
  call void @free(i8* %t8470)
  store i8** %t8458, i8*** %t8427
  store i32* %t8461, i32** %t8429
  store i8* %t8462, i8** %t8431
  store i64 %t8454, i64* %t8435
  store i64 0, i64* %t8437
  br label %map_insert_after_grow_1952
map_insert_after_grow_1952:
  %t8501 = load i8**, i8*** %t8427
  %t8502 = load i32*, i32** %t8429
  %t8503 = load i8*, i8** %t8431
  %t8504 = load i64, i64* %t8435
  %t8505 = sub i64 %t8504, 1
  %t8506 = call i64 @hash_str(i8* %t8439)
  %t8507 = and i64 %t8506, %t8505
  store i64 0, i64* %t8508
  store i64 %t8507, i64* %t8509
  store i1 false, i1* %t8510
  store i64 -1, i64* %t8511
  store i64 -1, i64* %t8512
  store i1 false, i1* %t8513
  br label %ht_probe_cond_1965
ht_probe_cond_1965:
  %t8514 = load i64, i64* %t8508
  %t8515 = icmp slt i64 %t8514, %t8504
  br i1 %t8515, label %ht_probe_body_1966, label %ht_probe_end_1976
ht_probe_body_1966:
  %t8516 = load i64, i64* %t8509
  %t8517 = getelementptr inbounds i8, i8* %t8503, i64 %t8516
  %t8518 = load i8, i8* %t8517
  %t8519 = icmp eq i8 %t8518, 0
  br i1 %t8519, label %ht_probe_on_empty_1968, label %ht_probe_check_occ_1967
ht_probe_check_occ_1967:
  %t8520 = icmp eq i8 %t8518, 1
  br i1 %t8520, label %ht_probe_on_occ_1971, label %ht_probe_on_tomb_1973
ht_probe_on_empty_1968:
  %t8521 = load i1, i1* %t8513
  br i1 %t8521, label %ht_probe_after_islot_empty_1970, label %ht_probe_set_islot_empty_1969
ht_probe_set_islot_empty_1969:
  store i64 %t8516, i64* %t8512
  store i1 true, i1* %t8513
  br label %ht_probe_after_islot_empty_1970
ht_probe_after_islot_empty_1970:
  br label %ht_probe_end_1976
ht_probe_on_occ_1971:
  %t8522 = getelementptr inbounds i8*, i8** %t8501, i64 %t8516
  %t8523 = load i8*, i8** %t8522
  %t8524 = call i1 @eq_str(i8* %t8523, i8* %t8439)
  br i1 %t8524, label %ht_probe_on_match_1972, label %ht_probe_next_1975
ht_probe_on_match_1972:
  store i1 true, i1* %t8510
  store i64 %t8516, i64* %t8511
  br label %ht_probe_end_1976
ht_probe_on_tomb_1973:
  %t8525 = load i1, i1* %t8513
  br i1 %t8525, label %ht_probe_next_1975, label %ht_probe_set_islot_tomb_1974
ht_probe_set_islot_tomb_1974:
  store i64 %t8516, i64* %t8512
  store i1 true, i1* %t8513
  br label %ht_probe_next_1975
ht_probe_next_1975:
  %t8526 = add i64 %t8516, 1
  %t8527 = and i64 %t8526, %t8505
  store i64 %t8527, i64* %t8509
  %t8528 = add i64 %t8514, 1
  store i64 %t8528, i64* %t8508
  br label %ht_probe_cond_1965
ht_probe_end_1976:
  %t8529 = load i1, i1* %t8510
  %t8530 = load i64, i64* %t8511
  %t8531 = load i64, i64* %t8512
  br i1 %t8529, label %map_insert_overwrite_1977, label %map_insert_new_1978
map_insert_overwrite_1977:
  store i8* %t8439, i8** %t8532
  %t8533 = load i8*, i8** %t8532
  call void @star_rc_release(i8* %t8533)
  %t8534 = getelementptr inbounds i32, i32* %t8502, i64 %t8530
  store i32 82, i32* %t8534
  br label %map_insert_after_1979
map_insert_new_1978:
  %t8535 = getelementptr inbounds i8, i8* %t8503, i64 %t8531
  %t8536 = load i8, i8* %t8535
  %t8537 = icmp eq i8 %t8536, 2
  br i1 %t8537, label %map_insert_dec_tomb_1980, label %map_insert_store_1981
map_insert_dec_tomb_1980:
  %t8538 = load i64, i64* %t8437
  %t8539 = sub i64 %t8538, 1
  store i64 %t8539, i64* %t8437
  br label %map_insert_store_1981
map_insert_store_1981:
  store i8 1, i8* %t8535
  %t8540 = getelementptr inbounds i8*, i8** %t8501, i64 %t8531
  store i8* %t8439, i8** %t8540
  %t8541 = getelementptr inbounds i32, i32* %t8502, i64 %t8531
  store i32 82, i32* %t8541
  %t8542 = load i64, i64* %t8433
  %t8543 = add i64 %t8542, 1
  store i64 %t8543, i64* %t8433
  br label %map_insert_after_1979
map_insert_after_1979:
  %t8544 = getelementptr i8*, i8** null, i32 1
  %t8545 = ptrtoint i8** %t8544 to i64
  %t8546 = getelementptr i32, i32* null, i32 1
  %t8547 = ptrtoint i32* %t8546 to i64
  %t8548 = load i8*, i8** %t0
  %t8549 = icmp eq i8* %t8548, null
  br i1 %t8549, label %map_cow_alloc_1982, label %map_cow_check_1983
map_cow_alloc_1982:
  %t8550 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t8551 = call i8* @star_rc_alloc(i64 48, i8* %t8550)
  %t8552 = bitcast i8* %t8551 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8553 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8552, i32 0, i32 0
  store i8** null, i8*** %t8553
  %t8554 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8552, i32 0, i32 1
  store i32* null, i32** %t8554
  %t8555 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8552, i32 0, i32 2
  store i8* null, i8** %t8555
  %t8556 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8552, i32 0, i32 3
  store i64 0, i64* %t8556
  %t8557 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8552, i32 0, i32 4
  store i64 0, i64* %t8557
  %t8558 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8552, i32 0, i32 5
  store i64 0, i64* %t8558
  store i8* %t8551, i8** %t0
  br label %map_cow_done_1984
map_cow_check_1983:
  %t8559 = getelementptr inbounds i8, i8* %t8548, i64 -16
  %t8560 = bitcast i8* %t8559 to i64*
  %t8561 = load atomic i64, i64* %t8560 seq_cst, align 8
  %t8562 = icmp eq i64 %t8561, 1
  br i1 %t8562, label %map_cow_done_1984, label %map_cow_clone_1985
map_cow_clone_1985:
  %t8563 = bitcast i8* %t8548 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8564 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8563, i32 0, i32 0
  %t8565 = load i8**, i8*** %t8564
  %t8566 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8563, i32 0, i32 1
  %t8567 = load i32*, i32** %t8566
  %t8568 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8563, i32 0, i32 2
  %t8569 = load i8*, i8** %t8568
  %t8570 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8563, i32 0, i32 3
  %t8571 = load i64, i64* %t8570
  %t8572 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8563, i32 0, i32 4
  %t8573 = load i64, i64* %t8572
  %t8574 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8563, i32 0, i32 5
  %t8575 = load i64, i64* %t8574
  %t8576 = bitcast void (i8*)* @map_release_3_stre_lex__tok__TokenType to i8*
  %t8577 = call i8* @star_rc_alloc(i64 48, i8* %t8576)
  %t8578 = bitcast i8* %t8577 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8579 = mul i64 %t8573, %t8545
  %t8580 = call i8* @malloc(i64 %t8579)
  %t8581 = bitcast i8* %t8580 to i8**
  %t8582 = mul i64 %t8573, %t8547
  %t8583 = call i8* @malloc(i64 %t8582)
  %t8584 = bitcast i8* %t8583 to i32*
  %t8585 = call i8* @malloc(i64 %t8573)
  %t8586 = icmp sgt i64 %t8573, 0
  br i1 %t8586, label %map_cow_copy_1986, label %map_cow_after_copy_1987
map_cow_copy_1986:
  %t8587 = mul i64 %t8573, %t8545
  %t8588 = bitcast i8** %t8565 to i8*
  call i8* @memcpy(i8* %t8580, i8* %t8588, i64 %t8587)
  %t8589 = mul i64 %t8573, %t8547
  %t8590 = bitcast i32* %t8567 to i8*
  call i8* @memcpy(i8* %t8583, i8* %t8590, i64 %t8589)
  call i8* @memcpy(i8* %t8585, i8* %t8569, i64 %t8573)
  store i64 0, i64* %t8591
  br label %map_cow_retain_cond_1988
map_cow_retain_cond_1988:
  %t8592 = load i64, i64* %t8591
  %t8593 = icmp slt i64 %t8592, %t8573
  br i1 %t8593, label %map_cow_retain_body_1989, label %map_cow_retain_end_1992
map_cow_retain_body_1989:
  %t8594 = getelementptr inbounds i8, i8* %t8585, i64 %t8592
  %t8595 = load i8, i8* %t8594
  %t8596 = icmp eq i8 %t8595, 1
  br i1 %t8596, label %map_cow_retain_occ_1990, label %map_cow_retain_next_1991
map_cow_retain_occ_1990:
  %t8597 = getelementptr inbounds i8*, i8** %t8581, i64 %t8592
  %t8598 = load i8*, i8** %t8597
  call void @star_rc_retain(i8* %t8598)
  br label %map_cow_retain_next_1991
map_cow_retain_next_1991:
  %t8599 = add i64 %t8592, 1
  store i64 %t8599, i64* %t8591
  br label %map_cow_retain_cond_1988
map_cow_retain_end_1992:
  br label %map_cow_after_copy_1987
map_cow_after_copy_1987:
  %t8600 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8578, i32 0, i32 0
  store i8** %t8581, i8*** %t8600
  %t8601 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8578, i32 0, i32 1
  store i32* %t8584, i32** %t8601
  %t8602 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8578, i32 0, i32 2
  store i8* %t8585, i8** %t8602
  %t8603 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8578, i32 0, i32 3
  store i64 %t8571, i64* %t8603
  %t8604 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8578, i32 0, i32 4
  store i64 %t8573, i64* %t8604
  %t8605 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8578, i32 0, i32 5
  store i64 %t8575, i64* %t8605
  call void @star_rc_release(i8* %t8548)
  store i8* %t8577, i8** %t0
  br label %map_cow_done_1984
map_cow_done_1984:
  %t8606 = load i8*, i8** %t0
  %t8607 = bitcast i8* %t8606 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8608 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8607, i32 0, i32 0
  %t8609 = load i8**, i8*** %t8608
  %t8610 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8607, i32 0, i32 1
  %t8611 = load i32*, i32** %t8610
  %t8612 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8607, i32 0, i32 2
  %t8613 = load i8*, i8** %t8612
  %t8614 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8607, i32 0, i32 3
  %t8615 = load i64, i64* %t8614
  %t8616 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8607, i32 0, i32 4
  %t8617 = load i64, i64* %t8616
  %t8618 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t8607, i32 0, i32 5
  %t8619 = load i64, i64* %t8618
  %t8620 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.47, i64 0, i32 2, i64 0
  %t8621 = load i64, i64* %t8614
  %t8622 = load i64, i64* %t8616
  %t8623 = load i64, i64* %t8618
  %t8624 = add i64 %t8621, %t8623
  %t8625 = add i64 %t8624, 1
  %t8626 = mul i64 %t8625, 4
  %t8627 = mul i64 %t8622, 3
  %t8628 = icmp sgt i64 %t8626, %t8627
  br i1 %t8628, label %map_insert_grow_1993, label %map_insert_after_grow_1994
map_insert_grow_1993:
  %t8629 = getelementptr i8*, i8** null, i32 1
  %t8630 = ptrtoint i8** %t8629 to i64
  %t8631 = getelementptr i32, i32* null, i32 1
  %t8632 = ptrtoint i32* %t8631 to i64
  %t8633 = mul i64 %t8622, 2
  %t8634 = icmp sgt i64 %t8633, 0
  %t8635 = select i1 %t8634, i64 %t8633, i64 8
  %t8636 = sub i64 %t8635, 1
  %t8637 = mul i64 %t8635, %t8630
  %t8638 = call i8* @malloc(i64 %t8637)
  %t8639 = bitcast i8* %t8638 to i8**
  %t8640 = mul i64 %t8635, %t8632
  %t8641 = call i8* @malloc(i64 %t8640)
  %t8642 = bitcast i8* %t8641 to i32*
  %t8643 = call i8* @malloc(i64 %t8635)
  store i64 0, i64* %t8644
  br label %ht_fill8_cond_1995
ht_fill8_cond_1995:
  %t8645 = load i64, i64* %t8644
  %t8646 = icmp slt i64 %t8645, %t8635
  br i1 %t8646, label %ht_fill8_body_1996, label %ht_fill8_end_1997
ht_fill8_body_1996:
  %t8647 = getelementptr inbounds i8, i8* %t8643, i64 %t8645
  store i8 0, i8* %t8647
  %t8648 = add i64 %t8645, 1
  store i64 %t8648, i64* %t8644
  br label %ht_fill8_cond_1995
ht_fill8_end_1997:
  %t8649 = load i8**, i8*** %t8608
  %t8650 = load i32*, i32** %t8610
  %t8651 = load i8*, i8** %t8612
  store i64 0, i64* %t8652
  br label %map_grow_cond_1998
map_grow_cond_1998:
  %t8653 = load i64, i64* %t8652
  %t8654 = icmp slt i64 %t8653, %t8622
  br i1 %t8654, label %map_grow_body_1999, label %map_grow_end_2002
map_grow_body_1999:
  %t8655 = getelementptr inbounds i8, i8* %t8651, i64 %t8653
  %t8656 = load i8, i8* %t8655
  %t8657 = icmp eq i8 %t8656, 1
  br i1 %t8657, label %map_grow_occ_2000, label %map_grow_next_2001
map_grow_occ_2000:
  %t8658 = getelementptr inbounds i8*, i8** %t8649, i64 %t8653
  %t8659 = load i8*, i8** %t8658
  %t8660 = getelementptr inbounds i32, i32* %t8650, i64 %t8653
  %t8661 = load i32, i32* %t8660
  %t8662 = call i64 @hash_str(i8* %t8659)
  %t8663 = and i64 %t8662, %t8636
  store i64 0, i64* %t8664
  store i64 %t8663, i64* %t8665
  br label %ht_fe_cond_2003
ht_fe_cond_2003:
  %t8666 = load i64, i64* %t8664
  %t8667 = icmp slt i64 %t8666, %t8635
  br i1 %t8667, label %ht_fe_body_2004, label %ht_fe_end_2006
ht_fe_body_2004:
  %t8668 = load i64, i64* %t8665
  %t8669 = getelementptr inbounds i8, i8* %t8643, i64 %t8668
  %t8670 = load i8, i8* %t8669
  %t8671 = icmp eq i8 %t8670, 0
  br i1 %t8671, label %ht_fe_end_2006, label %ht_fe_next_2005
ht_fe_next_2005:
  %t8672 = add i64 %t8668, 1
  %t8673 = and i64 %t8672, %t8636
  store i64 %t8673, i64* %t8665
  %t8674 = add i64 %t8666, 1
  store i64 %t8674, i64* %t8664
  br label %ht_fe_cond_2003
ht_fe_end_2006:
  %t8675 = load i64, i64* %t8665
  %t8676 = getelementptr inbounds i8, i8* %t8643, i64 %t8675
  store i8 1, i8* %t8676
  %t8677 = getelementptr inbounds i8*, i8** %t8639, i64 %t8675
  store i8* %t8659, i8** %t8677
  %t8678 = getelementptr inbounds i32, i32* %t8642, i64 %t8675
  store i32 %t8661, i32* %t8678
  br label %map_grow_next_2001
map_grow_next_2001:
  %t8679 = add i64 %t8653, 1
  store i64 %t8679, i64* %t8652
  br label %map_grow_cond_1998
map_grow_end_2002:
  %t8680 = bitcast i8** %t8649 to i8*
  call void @free(i8* %t8680)
  %t8681 = bitcast i32* %t8650 to i8*
  call void @free(i8* %t8681)
  call void @free(i8* %t8651)
  store i8** %t8639, i8*** %t8608
  store i32* %t8642, i32** %t8610
  store i8* %t8643, i8** %t8612
  store i64 %t8635, i64* %t8616
  store i64 0, i64* %t8618
  br label %map_insert_after_grow_1994
map_insert_after_grow_1994:
  %t8682 = load i8**, i8*** %t8608
  %t8683 = load i32*, i32** %t8610
  %t8684 = load i8*, i8** %t8612
  %t8685 = load i64, i64* %t8616
  %t8686 = sub i64 %t8685, 1
  %t8687 = call i64 @hash_str(i8* %t8620)
  %t8688 = and i64 %t8687, %t8686
  store i64 0, i64* %t8689
  store i64 %t8688, i64* %t8690
  store i1 false, i1* %t8691
  store i64 -1, i64* %t8692
  store i64 -1, i64* %t8693
  store i1 false, i1* %t8694
  br label %ht_probe_cond_2007
ht_probe_cond_2007:
  %t8695 = load i64, i64* %t8689
  %t8696 = icmp slt i64 %t8695, %t8685
  br i1 %t8696, label %ht_probe_body_2008, label %ht_probe_end_2018
ht_probe_body_2008:
  %t8697 = load i64, i64* %t8690
  %t8698 = getelementptr inbounds i8, i8* %t8684, i64 %t8697
  %t8699 = load i8, i8* %t8698
  %t8700 = icmp eq i8 %t8699, 0
  br i1 %t8700, label %ht_probe_on_empty_2010, label %ht_probe_check_occ_2009
ht_probe_check_occ_2009:
  %t8701 = icmp eq i8 %t8699, 1
  br i1 %t8701, label %ht_probe_on_occ_2013, label %ht_probe_on_tomb_2015
ht_probe_on_empty_2010:
  %t8702 = load i1, i1* %t8694
  br i1 %t8702, label %ht_probe_after_islot_empty_2012, label %ht_probe_set_islot_empty_2011
ht_probe_set_islot_empty_2011:
  store i64 %t8697, i64* %t8693
  store i1 true, i1* %t8694
  br label %ht_probe_after_islot_empty_2012
ht_probe_after_islot_empty_2012:
  br label %ht_probe_end_2018
ht_probe_on_occ_2013:
  %t8703 = getelementptr inbounds i8*, i8** %t8682, i64 %t8697
  %t8704 = load i8*, i8** %t8703
  %t8705 = call i1 @eq_str(i8* %t8704, i8* %t8620)
  br i1 %t8705, label %ht_probe_on_match_2014, label %ht_probe_next_2017
ht_probe_on_match_2014:
  store i1 true, i1* %t8691
  store i64 %t8697, i64* %t8692
  br label %ht_probe_end_2018
ht_probe_on_tomb_2015:
  %t8706 = load i1, i1* %t8694
  br i1 %t8706, label %ht_probe_next_2017, label %ht_probe_set_islot_tomb_2016
ht_probe_set_islot_tomb_2016:
  store i64 %t8697, i64* %t8693
  store i1 true, i1* %t8694
  br label %ht_probe_next_2017
ht_probe_next_2017:
  %t8707 = add i64 %t8697, 1
  %t8708 = and i64 %t8707, %t8686
  store i64 %t8708, i64* %t8690
  %t8709 = add i64 %t8695, 1
  store i64 %t8709, i64* %t8689
  br label %ht_probe_cond_2007
ht_probe_end_2018:
  %t8710 = load i1, i1* %t8691
  %t8711 = load i64, i64* %t8692
  %t8712 = load i64, i64* %t8693
  br i1 %t8710, label %map_insert_overwrite_2019, label %map_insert_new_2020
map_insert_overwrite_2019:
  store i8* %t8620, i8** %t8713
  %t8714 = load i8*, i8** %t8713
  call void @star_rc_release(i8* %t8714)
  %t8715 = getelementptr inbounds i32, i32* %t8683, i64 %t8711
  store i32 83, i32* %t8715
  br label %map_insert_after_2021
map_insert_new_2020:
  %t8716 = getelementptr inbounds i8, i8* %t8684, i64 %t8712
  %t8717 = load i8, i8* %t8716
  %t8718 = icmp eq i8 %t8717, 2
  br i1 %t8718, label %map_insert_dec_tomb_2022, label %map_insert_store_2023
map_insert_dec_tomb_2022:
  %t8719 = load i64, i64* %t8618
  %t8720 = sub i64 %t8719, 1
  store i64 %t8720, i64* %t8618
  br label %map_insert_store_2023
map_insert_store_2023:
  store i8 1, i8* %t8716
  %t8721 = getelementptr inbounds i8*, i8** %t8682, i64 %t8712
  store i8* %t8620, i8** %t8721
  %t8722 = getelementptr inbounds i32, i32* %t8683, i64 %t8712
  store i32 83, i32* %t8722
  %t8723 = load i64, i64* %t8614
  %t8724 = add i64 %t8723, 1
  store i64 %t8724, i64* %t8614
  br label %map_insert_after_2021
map_insert_after_2021:
  %t8725 = load i8*, i8** %t0
  %t8726 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t8726)
  %t8727 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t8727)
  ret i8* %t8725
}

define i32 @lex__tok__keyword_lookup(i8* %keywords, i8* %word) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t25 = alloca i64
  %t26 = alloca i64
  %t27 = alloca i1
  %t28 = alloca i64
  %t29 = alloca i64
  %t30 = alloca i1
  %t49 = alloca i8*
  %t53 = alloca %Option__lex__tok__TokenType
  %t59 = alloca %Option__lex__tok__TokenType
  %t63 = alloca %Option__lex__tok__TokenType
  store i8* %keywords, i8** %t0
  store i8* %word, i8** %t1
  %t2 = load i8*, i8** %t1
  %t3 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t3)
  %t4 = load i8*, i8** %t0
  %t5 = icmp eq i8* %t4, null
  br i1 %t5, label %map_read_null_2024, label %map_read_real_2025
map_read_null_2024:
  br label %map_read_end_2026
map_read_real_2025:
  %t6 = bitcast i8* %t4 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t7 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6, i32 0, i32 0
  %t8 = load i8**, i8*** %t7
  %t9 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6, i32 0, i32 1
  %t10 = load i32*, i32** %t9
  %t11 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6, i32 0, i32 2
  %t12 = load i8*, i8** %t11
  %t13 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6, i32 0, i32 3
  %t14 = load i64, i64* %t13
  %t15 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t6, i32 0, i32 4
  %t16 = load i64, i64* %t15
  br label %map_read_end_2026
map_read_end_2026:
  %t17 = phi i8** [ null, %map_read_null_2024 ], [ %t8, %map_read_real_2025 ]
  %t18 = phi i32* [ null, %map_read_null_2024 ], [ %t10, %map_read_real_2025 ]
  %t19 = phi i8* [ null, %map_read_null_2024 ], [ %t12, %map_read_real_2025 ]
  %t20 = phi i64 [ 0, %map_read_null_2024 ], [ %t14, %map_read_real_2025 ]
  %t21 = phi i64 [ 0, %map_read_null_2024 ], [ %t16, %map_read_real_2025 ]
  %t22 = sub i64 %t21, 1
  %t23 = call i64 @hash_str(i8* %t2)
  %t24 = and i64 %t23, %t22
  store i64 0, i64* %t25
  store i64 %t24, i64* %t26
  store i1 false, i1* %t27
  store i64 -1, i64* %t28
  store i64 -1, i64* %t29
  store i1 false, i1* %t30
  br label %ht_probe_cond_2027
ht_probe_cond_2027:
  %t31 = load i64, i64* %t25
  %t32 = icmp slt i64 %t31, %t21
  br i1 %t32, label %ht_probe_body_2028, label %ht_probe_end_2038
ht_probe_body_2028:
  %t33 = load i64, i64* %t26
  %t34 = getelementptr inbounds i8, i8* %t19, i64 %t33
  %t35 = load i8, i8* %t34
  %t36 = icmp eq i8 %t35, 0
  br i1 %t36, label %ht_probe_on_empty_2030, label %ht_probe_check_occ_2029
ht_probe_check_occ_2029:
  %t37 = icmp eq i8 %t35, 1
  br i1 %t37, label %ht_probe_on_occ_2033, label %ht_probe_on_tomb_2035
ht_probe_on_empty_2030:
  %t38 = load i1, i1* %t30
  br i1 %t38, label %ht_probe_after_islot_empty_2032, label %ht_probe_set_islot_empty_2031
ht_probe_set_islot_empty_2031:
  store i64 %t33, i64* %t29
  store i1 true, i1* %t30
  br label %ht_probe_after_islot_empty_2032
ht_probe_after_islot_empty_2032:
  br label %ht_probe_end_2038
ht_probe_on_occ_2033:
  %t39 = getelementptr inbounds i8*, i8** %t17, i64 %t33
  %t40 = load i8*, i8** %t39
  %t41 = call i1 @eq_str(i8* %t40, i8* %t2)
  br i1 %t41, label %ht_probe_on_match_2034, label %ht_probe_next_2037
ht_probe_on_match_2034:
  store i1 true, i1* %t27
  store i64 %t33, i64* %t28
  br label %ht_probe_end_2038
ht_probe_on_tomb_2035:
  %t42 = load i1, i1* %t30
  br i1 %t42, label %ht_probe_next_2037, label %ht_probe_set_islot_tomb_2036
ht_probe_set_islot_tomb_2036:
  store i64 %t33, i64* %t29
  store i1 true, i1* %t30
  br label %ht_probe_next_2037
ht_probe_next_2037:
  %t43 = add i64 %t33, 1
  %t44 = and i64 %t43, %t22
  store i64 %t44, i64* %t26
  %t45 = add i64 %t31, 1
  store i64 %t45, i64* %t25
  br label %ht_probe_cond_2027
ht_probe_end_2038:
  %t46 = load i1, i1* %t27
  %t47 = load i64, i64* %t28
  %t48 = load i64, i64* %t29
  store i8* %t2, i8** %t49
  %t50 = load i8*, i8** %t49
  call void @star_rc_release(i8* %t50)
  br i1 %t46, label %map_get_some_2039, label %map_get_none_2040
map_get_some_2039:
  %t51 = getelementptr inbounds i32, i32* %t18, i64 %t47
  %t52 = load i32, i32* %t51
  %t54 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t53, i32 0, i32 0
  store i32 1, i32* %t54
  %t55 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t53, i32 0, i32 1
  %t56 = bitcast [1 x i64]* %t55 to { i32 }*
  %t57 = getelementptr inbounds { i32 }, { i32 }* %t56, i32 0, i32 0
  store i32 %t52, i32* %t57
  %t58 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t53
  br label %map_get_end_2041
map_get_none_2040:
  %t60 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t59, i32 0, i32 0
  store i32 0, i32* %t60
  %t61 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t59
  br label %map_get_end_2041
map_get_end_2041:
  %t62 = phi %Option__lex__tok__TokenType [ %t58, %map_get_some_2039 ], [ %t61, %map_get_none_2040 ]
  store %Option__lex__tok__TokenType %t62, %Option__lex__tok__TokenType* %t63
  br label %match_scrutinee_65
match_scrutinee_65:
  %t69 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t63, i32 0, i32 0
  %t70 = load i32, i32* %t69
  %t68 = icmp eq i32 %t70, 1
  br i1 %t68, label %match_then_0_66, label %match_next_0_67
match_then_0_66:
  %t71 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t63, i32 0, i32 1
  %t72 = bitcast [1 x i64]* %t71 to { i32 }*
  %t73 = getelementptr inbounds { i32 }, { i32 }* %t72, i32 0, i32 0
  %t74 = load i32, i32* %t73
  br label %match_end_64
match_next_0_67:
  %t78 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t63, i32 0, i32 0
  %t79 = load i32, i32* %t78
  %t77 = icmp eq i32 %t79, 0
  br i1 %t77, label %match_then_1_75, label %match_next_1_76
match_then_1_75:
  br label %match_end_64
match_next_1_76:
  br label %match_end_64
match_end_64:
  %t80 = phi i32 [ %t74, %match_then_0_66 ], [ 97, %match_then_1_75 ], [ undef, %match_next_1_76 ]
  %t81 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t81)
  %t82 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t82)
  ret i32 %t80
}

define %Option__lex__tok__TokenType @lex__tok__single_char_token(i32 %c) {
entry:
  %t0 = alloca i32
  %t7 = alloca %Option__lex__tok__TokenType
  %t16 = alloca %Option__lex__tok__TokenType
  %t25 = alloca %Option__lex__tok__TokenType
  %t34 = alloca %Option__lex__tok__TokenType
  %t43 = alloca %Option__lex__tok__TokenType
  %t52 = alloca %Option__lex__tok__TokenType
  %t61 = alloca %Option__lex__tok__TokenType
  %t70 = alloca %Option__lex__tok__TokenType
  %t79 = alloca %Option__lex__tok__TokenType
  %t88 = alloca %Option__lex__tok__TokenType
  %t97 = alloca %Option__lex__tok__TokenType
  %t106 = alloca %Option__lex__tok__TokenType
  %t115 = alloca %Option__lex__tok__TokenType
  %t124 = alloca %Option__lex__tok__TokenType
  %t133 = alloca %Option__lex__tok__TokenType
  %t142 = alloca %Option__lex__tok__TokenType
  %t151 = alloca %Option__lex__tok__TokenType
  %t160 = alloca %Option__lex__tok__TokenType
  %t169 = alloca %Option__lex__tok__TokenType
  %t177 = alloca %Option__lex__tok__TokenType
  store i32 %c, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t6 = icmp eq i32 %t1, 43
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  %t8 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t7, i32 0, i32 0
  store i32 1, i32* %t8
  %t9 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t7, i32 0, i32 1
  %t10 = bitcast [1 x i64]* %t9 to { i32 }*
  %t11 = getelementptr inbounds { i32 }, { i32 }* %t10, i32 0, i32 0
  store i32 66, i32* %t11
  %t12 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t7
  br label %match_end_2
match_next_0_5:
  %t15 = icmp eq i32 %t1, 45
  br i1 %t15, label %match_then_1_13, label %match_next_1_14
match_then_1_13:
  %t17 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t16, i32 0, i32 0
  store i32 1, i32* %t17
  %t18 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t16, i32 0, i32 1
  %t19 = bitcast [1 x i64]* %t18 to { i32 }*
  %t20 = getelementptr inbounds { i32 }, { i32 }* %t19, i32 0, i32 0
  store i32 67, i32* %t20
  %t21 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t16
  br label %match_end_2
match_next_1_14:
  %t24 = icmp eq i32 %t1, 42
  br i1 %t24, label %match_then_2_22, label %match_next_2_23
match_then_2_22:
  %t26 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t25, i32 0, i32 0
  store i32 1, i32* %t26
  %t27 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t25, i32 0, i32 1
  %t28 = bitcast [1 x i64]* %t27 to { i32 }*
  %t29 = getelementptr inbounds { i32 }, { i32 }* %t28, i32 0, i32 0
  store i32 68, i32* %t29
  %t30 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t25
  br label %match_end_2
match_next_2_23:
  %t33 = icmp eq i32 %t1, 47
  br i1 %t33, label %match_then_3_31, label %match_next_3_32
match_then_3_31:
  %t35 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t34, i32 0, i32 0
  store i32 1, i32* %t35
  %t36 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t34, i32 0, i32 1
  %t37 = bitcast [1 x i64]* %t36 to { i32 }*
  %t38 = getelementptr inbounds { i32 }, { i32 }* %t37, i32 0, i32 0
  store i32 69, i32* %t38
  %t39 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t34
  br label %match_end_2
match_next_3_32:
  %t42 = icmp eq i32 %t1, 94
  br i1 %t42, label %match_then_4_40, label %match_next_4_41
match_then_4_40:
  %t44 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t43, i32 0, i32 0
  store i32 1, i32* %t44
  %t45 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t43, i32 0, i32 1
  %t46 = bitcast [1 x i64]* %t45 to { i32 }*
  %t47 = getelementptr inbounds { i32 }, { i32 }* %t46, i32 0, i32 0
  store i32 70, i32* %t47
  %t48 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t43
  br label %match_end_2
match_next_4_41:
  %t51 = icmp eq i32 %t1, 61
  br i1 %t51, label %match_then_5_49, label %match_next_5_50
match_then_5_49:
  %t53 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t52, i32 0, i32 0
  store i32 1, i32* %t53
  %t54 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t52, i32 0, i32 1
  %t55 = bitcast [1 x i64]* %t54 to { i32 }*
  %t56 = getelementptr inbounds { i32 }, { i32 }* %t55, i32 0, i32 0
  store i32 71, i32* %t56
  %t57 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t52
  br label %match_end_2
match_next_5_50:
  %t60 = icmp eq i32 %t1, 60
  br i1 %t60, label %match_then_6_58, label %match_next_6_59
match_then_6_58:
  %t62 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t61, i32 0, i32 0
  store i32 1, i32* %t62
  %t63 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t61, i32 0, i32 1
  %t64 = bitcast [1 x i64]* %t63 to { i32 }*
  %t65 = getelementptr inbounds { i32 }, { i32 }* %t64, i32 0, i32 0
  store i32 73, i32* %t65
  %t66 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t61
  br label %match_end_2
match_next_6_59:
  %t69 = icmp eq i32 %t1, 62
  br i1 %t69, label %match_then_7_67, label %match_next_7_68
match_then_7_67:
  %t71 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t70, i32 0, i32 0
  store i32 1, i32* %t71
  %t72 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t70, i32 0, i32 1
  %t73 = bitcast [1 x i64]* %t72 to { i32 }*
  %t74 = getelementptr inbounds { i32 }, { i32 }* %t73, i32 0, i32 0
  store i32 75, i32* %t74
  %t75 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t70
  br label %match_end_2
match_next_7_68:
  %t78 = icmp eq i32 %t1, 40
  br i1 %t78, label %match_then_8_76, label %match_next_8_77
match_then_8_76:
  %t80 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t79, i32 0, i32 0
  store i32 1, i32* %t80
  %t81 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t79, i32 0, i32 1
  %t82 = bitcast [1 x i64]* %t81 to { i32 }*
  %t83 = getelementptr inbounds { i32 }, { i32 }* %t82, i32 0, i32 0
  store i32 86, i32* %t83
  %t84 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t79
  br label %match_end_2
match_next_8_77:
  %t87 = icmp eq i32 %t1, 41
  br i1 %t87, label %match_then_9_85, label %match_next_9_86
match_then_9_85:
  %t89 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t88, i32 0, i32 0
  store i32 1, i32* %t89
  %t90 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t88, i32 0, i32 1
  %t91 = bitcast [1 x i64]* %t90 to { i32 }*
  %t92 = getelementptr inbounds { i32 }, { i32 }* %t91, i32 0, i32 0
  store i32 87, i32* %t92
  %t93 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t88
  br label %match_end_2
match_next_9_86:
  %t96 = icmp eq i32 %t1, 91
  br i1 %t96, label %match_then_10_94, label %match_next_10_95
match_then_10_94:
  %t98 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t97, i32 0, i32 0
  store i32 1, i32* %t98
  %t99 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t97, i32 0, i32 1
  %t100 = bitcast [1 x i64]* %t99 to { i32 }*
  %t101 = getelementptr inbounds { i32 }, { i32 }* %t100, i32 0, i32 0
  store i32 88, i32* %t101
  %t102 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t97
  br label %match_end_2
match_next_10_95:
  %t105 = icmp eq i32 %t1, 93
  br i1 %t105, label %match_then_11_103, label %match_next_11_104
match_then_11_103:
  %t107 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t106, i32 0, i32 0
  store i32 1, i32* %t107
  %t108 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t106, i32 0, i32 1
  %t109 = bitcast [1 x i64]* %t108 to { i32 }*
  %t110 = getelementptr inbounds { i32 }, { i32 }* %t109, i32 0, i32 0
  store i32 89, i32* %t110
  %t111 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t106
  br label %match_end_2
match_next_11_104:
  %t114 = icmp eq i32 %t1, 44
  br i1 %t114, label %match_then_12_112, label %match_next_12_113
match_then_12_112:
  %t116 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t115, i32 0, i32 0
  store i32 1, i32* %t116
  %t117 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t115, i32 0, i32 1
  %t118 = bitcast [1 x i64]* %t117 to { i32 }*
  %t119 = getelementptr inbounds { i32 }, { i32 }* %t118, i32 0, i32 0
  store i32 90, i32* %t119
  %t120 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t115
  br label %match_end_2
match_next_12_113:
  %t123 = icmp eq i32 %t1, 34
  br i1 %t123, label %match_then_13_121, label %match_next_13_122
match_then_13_121:
  %t125 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t124, i32 0, i32 0
  store i32 1, i32* %t125
  %t126 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t124, i32 0, i32 1
  %t127 = bitcast [1 x i64]* %t126 to { i32 }*
  %t128 = getelementptr inbounds { i32 }, { i32 }* %t127, i32 0, i32 0
  store i32 91, i32* %t128
  %t129 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t124
  br label %match_end_2
match_next_13_122:
  %t132 = icmp eq i32 %t1, 58
  br i1 %t132, label %match_then_14_130, label %match_next_14_131
match_then_14_130:
  %t134 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t133, i32 0, i32 0
  store i32 1, i32* %t134
  %t135 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t133, i32 0, i32 1
  %t136 = bitcast [1 x i64]* %t135 to { i32 }*
  %t137 = getelementptr inbounds { i32 }, { i32 }* %t136, i32 0, i32 0
  store i32 92, i32* %t137
  %t138 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t133
  br label %match_end_2
match_next_14_131:
  %t141 = icmp eq i32 %t1, 64
  br i1 %t141, label %match_then_15_139, label %match_next_15_140
match_then_15_139:
  %t143 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t142, i32 0, i32 0
  store i32 1, i32* %t143
  %t144 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t142, i32 0, i32 1
  %t145 = bitcast [1 x i64]* %t144 to { i32 }*
  %t146 = getelementptr inbounds { i32 }, { i32 }* %t145, i32 0, i32 0
  store i32 93, i32* %t146
  %t147 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t142
  br label %match_end_2
match_next_15_140:
  %t150 = icmp eq i32 %t1, 46
  br i1 %t150, label %match_then_16_148, label %match_next_16_149
match_then_16_148:
  %t152 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t151, i32 0, i32 0
  store i32 1, i32* %t152
  %t153 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t151, i32 0, i32 1
  %t154 = bitcast [1 x i64]* %t153 to { i32 }*
  %t155 = getelementptr inbounds { i32 }, { i32 }* %t154, i32 0, i32 0
  store i32 94, i32* %t155
  %t156 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t151
  br label %match_end_2
match_next_16_149:
  %t159 = icmp eq i32 %t1, 38
  br i1 %t159, label %match_then_17_157, label %match_next_17_158
match_then_17_157:
  %t161 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t160, i32 0, i32 0
  store i32 1, i32* %t161
  %t162 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t160, i32 0, i32 1
  %t163 = bitcast [1 x i64]* %t162 to { i32 }*
  %t164 = getelementptr inbounds { i32 }, { i32 }* %t163, i32 0, i32 0
  store i32 77, i32* %t164
  %t165 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t160
  br label %match_end_2
match_next_17_158:
  %t168 = icmp eq i32 %t1, 124
  br i1 %t168, label %match_then_18_166, label %match_next_18_167
match_then_18_166:
  %t170 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t169, i32 0, i32 0
  store i32 1, i32* %t170
  %t171 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t169, i32 0, i32 1
  %t172 = bitcast [1 x i64]* %t171 to { i32 }*
  %t173 = getelementptr inbounds { i32 }, { i32 }* %t172, i32 0, i32 0
  store i32 78, i32* %t173
  %t174 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t169
  br label %match_end_2
match_next_18_167:
  %t178 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t177, i32 0, i32 0
  store i32 0, i32* %t178
  %t179 = load %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t177
  br label %match_end_2
match_end_2:
  %t180 = phi %Option__lex__tok__TokenType [ %t12, %match_then_0_4 ], [ %t21, %match_then_1_13 ], [ %t30, %match_then_2_22 ], [ %t39, %match_then_3_31 ], [ %t48, %match_then_4_40 ], [ %t57, %match_then_5_49 ], [ %t66, %match_then_6_58 ], [ %t75, %match_then_7_67 ], [ %t84, %match_then_8_76 ], [ %t93, %match_then_9_85 ], [ %t102, %match_then_10_94 ], [ %t111, %match_then_11_103 ], [ %t120, %match_then_12_112 ], [ %t129, %match_then_13_121 ], [ %t138, %match_then_14_130 ], [ %t147, %match_then_15_139 ], [ %t156, %match_then_16_148 ], [ %t165, %match_then_17_157 ], [ %t174, %match_then_18_166 ], [ %t179, %match_next_18_167 ]
  ret %Option__lex__tok__TokenType %t180
}

define i8* @lex__tok__token_type_name(i32 %t) {
entry:
  %t0 = alloca i32
  store i32 %t, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t6 = icmp eq i32 %t1, 0
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  %t7 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.48, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_0_5:
  %t10 = icmp eq i32 %t1, 1
  br i1 %t10, label %match_then_1_8, label %match_next_1_9
match_then_1_8:
  %t11 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.49, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_1_9:
  %t14 = icmp eq i32 %t1, 2
  br i1 %t14, label %match_then_2_12, label %match_next_2_13
match_then_2_12:
  %t15 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.50, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_2_13:
  %t18 = icmp eq i32 %t1, 3
  br i1 %t18, label %match_then_3_16, label %match_next_3_17
match_then_3_16:
  %t19 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.51, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_3_17:
  %t22 = icmp eq i32 %t1, 4
  br i1 %t22, label %match_then_4_20, label %match_next_4_21
match_then_4_20:
  %t23 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.52, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_4_21:
  %t26 = icmp eq i32 %t1, 5
  br i1 %t26, label %match_then_5_24, label %match_next_5_25
match_then_5_24:
  %t27 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.53, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_5_25:
  %t30 = icmp eq i32 %t1, 6
  br i1 %t30, label %match_then_6_28, label %match_next_6_29
match_then_6_28:
  %t31 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.54, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_6_29:
  %t34 = icmp eq i32 %t1, 7
  br i1 %t34, label %match_then_7_32, label %match_next_7_33
match_then_7_32:
  %t35 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.55, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_7_33:
  %t38 = icmp eq i32 %t1, 8
  br i1 %t38, label %match_then_8_36, label %match_next_8_37
match_then_8_36:
  %t39 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.56, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_8_37:
  %t42 = icmp eq i32 %t1, 9
  br i1 %t42, label %match_then_9_40, label %match_next_9_41
match_then_9_40:
  %t43 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.57, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_9_41:
  %t46 = icmp eq i32 %t1, 10
  br i1 %t46, label %match_then_10_44, label %match_next_10_45
match_then_10_44:
  %t47 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.58, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_10_45:
  %t50 = icmp eq i32 %t1, 11
  br i1 %t50, label %match_then_11_48, label %match_next_11_49
match_then_11_48:
  %t51 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.59, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_11_49:
  %t54 = icmp eq i32 %t1, 12
  br i1 %t54, label %match_then_12_52, label %match_next_12_53
match_then_12_52:
  %t55 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.60, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_12_53:
  %t58 = icmp eq i32 %t1, 13
  br i1 %t58, label %match_then_13_56, label %match_next_13_57
match_then_13_56:
  %t59 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.61, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_13_57:
  %t62 = icmp eq i32 %t1, 14
  br i1 %t62, label %match_then_14_60, label %match_next_14_61
match_then_14_60:
  %t63 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.62, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_14_61:
  %t66 = icmp eq i32 %t1, 15
  br i1 %t66, label %match_then_15_64, label %match_next_15_65
match_then_15_64:
  %t67 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.63, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_15_65:
  %t70 = icmp eq i32 %t1, 16
  br i1 %t70, label %match_then_16_68, label %match_next_16_69
match_then_16_68:
  %t71 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.64, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_16_69:
  %t74 = icmp eq i32 %t1, 17
  br i1 %t74, label %match_then_17_72, label %match_next_17_73
match_then_17_72:
  %t75 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.65, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_17_73:
  %t78 = icmp eq i32 %t1, 18
  br i1 %t78, label %match_then_18_76, label %match_next_18_77
match_then_18_76:
  %t79 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.66, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_18_77:
  %t82 = icmp eq i32 %t1, 19
  br i1 %t82, label %match_then_19_80, label %match_next_19_81
match_then_19_80:
  %t83 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.67, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_19_81:
  %t86 = icmp eq i32 %t1, 20
  br i1 %t86, label %match_then_20_84, label %match_next_20_85
match_then_20_84:
  %t87 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.68, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_20_85:
  %t90 = icmp eq i32 %t1, 21
  br i1 %t90, label %match_then_21_88, label %match_next_21_89
match_then_21_88:
  %t91 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.69, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_21_89:
  %t94 = icmp eq i32 %t1, 22
  br i1 %t94, label %match_then_22_92, label %match_next_22_93
match_then_22_92:
  %t95 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.70, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_22_93:
  %t98 = icmp eq i32 %t1, 23
  br i1 %t98, label %match_then_23_96, label %match_next_23_97
match_then_23_96:
  %t99 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.71, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_23_97:
  %t102 = icmp eq i32 %t1, 24
  br i1 %t102, label %match_then_24_100, label %match_next_24_101
match_then_24_100:
  %t103 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.72, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_24_101:
  %t106 = icmp eq i32 %t1, 25
  br i1 %t106, label %match_then_25_104, label %match_next_25_105
match_then_25_104:
  %t107 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.73, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_25_105:
  %t110 = icmp eq i32 %t1, 26
  br i1 %t110, label %match_then_26_108, label %match_next_26_109
match_then_26_108:
  %t111 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.74, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_26_109:
  %t114 = icmp eq i32 %t1, 27
  br i1 %t114, label %match_then_27_112, label %match_next_27_113
match_then_27_112:
  %t115 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.75, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_27_113:
  %t118 = icmp eq i32 %t1, 28
  br i1 %t118, label %match_then_28_116, label %match_next_28_117
match_then_28_116:
  %t119 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.76, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_28_117:
  %t122 = icmp eq i32 %t1, 29
  br i1 %t122, label %match_then_29_120, label %match_next_29_121
match_then_29_120:
  %t123 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.77, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_29_121:
  %t126 = icmp eq i32 %t1, 30
  br i1 %t126, label %match_then_30_124, label %match_next_30_125
match_then_30_124:
  %t127 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.78, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_30_125:
  %t130 = icmp eq i32 %t1, 31
  br i1 %t130, label %match_then_31_128, label %match_next_31_129
match_then_31_128:
  %t131 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.79, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_31_129:
  %t134 = icmp eq i32 %t1, 32
  br i1 %t134, label %match_then_32_132, label %match_next_32_133
match_then_32_132:
  %t135 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.80, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_32_133:
  %t138 = icmp eq i32 %t1, 33
  br i1 %t138, label %match_then_33_136, label %match_next_33_137
match_then_33_136:
  %t139 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.81, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_33_137:
  %t142 = icmp eq i32 %t1, 34
  br i1 %t142, label %match_then_34_140, label %match_next_34_141
match_then_34_140:
  %t143 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.82, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_34_141:
  %t146 = icmp eq i32 %t1, 35
  br i1 %t146, label %match_then_35_144, label %match_next_35_145
match_then_35_144:
  %t147 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.83, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_35_145:
  %t150 = icmp eq i32 %t1, 36
  br i1 %t150, label %match_then_36_148, label %match_next_36_149
match_then_36_148:
  %t151 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.84, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_36_149:
  %t154 = icmp eq i32 %t1, 37
  br i1 %t154, label %match_then_37_152, label %match_next_37_153
match_then_37_152:
  %t155 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.85, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_37_153:
  %t158 = icmp eq i32 %t1, 38
  br i1 %t158, label %match_then_38_156, label %match_next_38_157
match_then_38_156:
  %t159 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.86, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_38_157:
  %t162 = icmp eq i32 %t1, 39
  br i1 %t162, label %match_then_39_160, label %match_next_39_161
match_then_39_160:
  %t163 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.87, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_39_161:
  %t166 = icmp eq i32 %t1, 40
  br i1 %t166, label %match_then_40_164, label %match_next_40_165
match_then_40_164:
  %t167 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.88, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_40_165:
  %t170 = icmp eq i32 %t1, 41
  br i1 %t170, label %match_then_41_168, label %match_next_41_169
match_then_41_168:
  %t171 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.89, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_41_169:
  %t174 = icmp eq i32 %t1, 42
  br i1 %t174, label %match_then_42_172, label %match_next_42_173
match_then_42_172:
  %t175 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.90, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_42_173:
  %t178 = icmp eq i32 %t1, 43
  br i1 %t178, label %match_then_43_176, label %match_next_43_177
match_then_43_176:
  %t179 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.91, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_43_177:
  %t182 = icmp eq i32 %t1, 44
  br i1 %t182, label %match_then_44_180, label %match_next_44_181
match_then_44_180:
  %t183 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.92, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_44_181:
  %t186 = icmp eq i32 %t1, 45
  br i1 %t186, label %match_then_45_184, label %match_next_45_185
match_then_45_184:
  %t187 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.93, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_45_185:
  %t190 = icmp eq i32 %t1, 46
  br i1 %t190, label %match_then_46_188, label %match_next_46_189
match_then_46_188:
  %t191 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.94, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_46_189:
  %t194 = icmp eq i32 %t1, 47
  br i1 %t194, label %match_then_47_192, label %match_next_47_193
match_then_47_192:
  %t195 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.95, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_47_193:
  %t198 = icmp eq i32 %t1, 48
  br i1 %t198, label %match_then_48_196, label %match_next_48_197
match_then_48_196:
  %t199 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.96, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_48_197:
  %t202 = icmp eq i32 %t1, 49
  br i1 %t202, label %match_then_49_200, label %match_next_49_201
match_then_49_200:
  %t203 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.97, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_49_201:
  %t206 = icmp eq i32 %t1, 50
  br i1 %t206, label %match_then_50_204, label %match_next_50_205
match_then_50_204:
  %t207 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.98, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_50_205:
  %t210 = icmp eq i32 %t1, 51
  br i1 %t210, label %match_then_51_208, label %match_next_51_209
match_then_51_208:
  %t211 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.99, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_51_209:
  %t214 = icmp eq i32 %t1, 52
  br i1 %t214, label %match_then_52_212, label %match_next_52_213
match_then_52_212:
  %t215 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.100, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_52_213:
  %t218 = icmp eq i32 %t1, 53
  br i1 %t218, label %match_then_53_216, label %match_next_53_217
match_then_53_216:
  %t219 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.101, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_53_217:
  %t222 = icmp eq i32 %t1, 54
  br i1 %t222, label %match_then_54_220, label %match_next_54_221
match_then_54_220:
  %t223 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.102, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_54_221:
  %t226 = icmp eq i32 %t1, 55
  br i1 %t226, label %match_then_55_224, label %match_next_55_225
match_then_55_224:
  %t227 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.103, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_55_225:
  %t230 = icmp eq i32 %t1, 56
  br i1 %t230, label %match_then_56_228, label %match_next_56_229
match_then_56_228:
  %t231 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.104, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_56_229:
  %t234 = icmp eq i32 %t1, 57
  br i1 %t234, label %match_then_57_232, label %match_next_57_233
match_then_57_232:
  %t235 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.105, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_57_233:
  %t238 = icmp eq i32 %t1, 58
  br i1 %t238, label %match_then_58_236, label %match_next_58_237
match_then_58_236:
  %t239 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.106, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_58_237:
  %t242 = icmp eq i32 %t1, 59
  br i1 %t242, label %match_then_59_240, label %match_next_59_241
match_then_59_240:
  %t243 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.107, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_59_241:
  %t246 = icmp eq i32 %t1, 60
  br i1 %t246, label %match_then_60_244, label %match_next_60_245
match_then_60_244:
  %t247 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.108, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_60_245:
  %t250 = icmp eq i32 %t1, 61
  br i1 %t250, label %match_then_61_248, label %match_next_61_249
match_then_61_248:
  %t251 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.109, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_61_249:
  %t254 = icmp eq i32 %t1, 62
  br i1 %t254, label %match_then_62_252, label %match_next_62_253
match_then_62_252:
  %t255 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.110, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_62_253:
  %t258 = icmp eq i32 %t1, 63
  br i1 %t258, label %match_then_63_256, label %match_next_63_257
match_then_63_256:
  %t259 = getelementptr inbounds { i64, i8*, [9 x i8] }, { i64, i8*, [9 x i8] }* @.str.111, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_63_257:
  %t262 = icmp eq i32 %t1, 64
  br i1 %t262, label %match_then_64_260, label %match_next_64_261
match_then_64_260:
  %t263 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.112, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_64_261:
  %t266 = icmp eq i32 %t1, 65
  br i1 %t266, label %match_then_65_264, label %match_next_65_265
match_then_65_264:
  %t267 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.113, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_65_265:
  %t270 = icmp eq i32 %t1, 66
  br i1 %t270, label %match_then_66_268, label %match_next_66_269
match_then_66_268:
  %t271 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.114, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_66_269:
  %t274 = icmp eq i32 %t1, 67
  br i1 %t274, label %match_then_67_272, label %match_next_67_273
match_then_67_272:
  %t275 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.115, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_67_273:
  %t278 = icmp eq i32 %t1, 68
  br i1 %t278, label %match_then_68_276, label %match_next_68_277
match_then_68_276:
  %t279 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.116, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_68_277:
  %t282 = icmp eq i32 %t1, 69
  br i1 %t282, label %match_then_69_280, label %match_next_69_281
match_then_69_280:
  %t283 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.117, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_69_281:
  %t286 = icmp eq i32 %t1, 70
  br i1 %t286, label %match_then_70_284, label %match_next_70_285
match_then_70_284:
  %t287 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.118, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_70_285:
  %t290 = icmp eq i32 %t1, 71
  br i1 %t290, label %match_then_71_288, label %match_next_71_289
match_then_71_288:
  %t291 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.119, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_71_289:
  %t294 = icmp eq i32 %t1, 72
  br i1 %t294, label %match_then_72_292, label %match_next_72_293
match_then_72_292:
  %t295 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.120, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_72_293:
  %t298 = icmp eq i32 %t1, 73
  br i1 %t298, label %match_then_73_296, label %match_next_73_297
match_then_73_296:
  %t299 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.121, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_73_297:
  %t302 = icmp eq i32 %t1, 74
  br i1 %t302, label %match_then_74_300, label %match_next_74_301
match_then_74_300:
  %t303 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.122, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_74_301:
  %t306 = icmp eq i32 %t1, 75
  br i1 %t306, label %match_then_75_304, label %match_next_75_305
match_then_75_304:
  %t307 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.123, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_75_305:
  %t310 = icmp eq i32 %t1, 76
  br i1 %t310, label %match_then_76_308, label %match_next_76_309
match_then_76_308:
  %t311 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.124, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_76_309:
  %t314 = icmp eq i32 %t1, 77
  br i1 %t314, label %match_then_77_312, label %match_next_77_313
match_then_77_312:
  %t315 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.125, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_77_313:
  %t318 = icmp eq i32 %t1, 78
  br i1 %t318, label %match_then_78_316, label %match_next_78_317
match_then_78_316:
  %t319 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.126, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_78_317:
  %t322 = icmp eq i32 %t1, 79
  br i1 %t322, label %match_then_79_320, label %match_next_79_321
match_then_79_320:
  %t323 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.127, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_79_321:
  %t326 = icmp eq i32 %t1, 80
  br i1 %t326, label %match_then_80_324, label %match_next_80_325
match_then_80_324:
  %t327 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.128, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_80_325:
  %t330 = icmp eq i32 %t1, 81
  br i1 %t330, label %match_then_81_328, label %match_next_81_329
match_then_81_328:
  %t331 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.129, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_81_329:
  %t334 = icmp eq i32 %t1, 82
  br i1 %t334, label %match_then_82_332, label %match_next_82_333
match_then_82_332:
  %t335 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.130, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_82_333:
  %t338 = icmp eq i32 %t1, 83
  br i1 %t338, label %match_then_83_336, label %match_next_83_337
match_then_83_336:
  %t339 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.131, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_83_337:
  %t342 = icmp eq i32 %t1, 84
  br i1 %t342, label %match_then_84_340, label %match_next_84_341
match_then_84_340:
  %t343 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.132, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_84_341:
  %t346 = icmp eq i32 %t1, 85
  br i1 %t346, label %match_then_85_344, label %match_next_85_345
match_then_85_344:
  %t347 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.133, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_85_345:
  %t350 = icmp eq i32 %t1, 86
  br i1 %t350, label %match_then_86_348, label %match_next_86_349
match_then_86_348:
  %t351 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.134, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_86_349:
  %t354 = icmp eq i32 %t1, 87
  br i1 %t354, label %match_then_87_352, label %match_next_87_353
match_then_87_352:
  %t355 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.135, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_87_353:
  %t358 = icmp eq i32 %t1, 88
  br i1 %t358, label %match_then_88_356, label %match_next_88_357
match_then_88_356:
  %t359 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.136, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_88_357:
  %t362 = icmp eq i32 %t1, 89
  br i1 %t362, label %match_then_89_360, label %match_next_89_361
match_then_89_360:
  %t363 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.137, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_89_361:
  %t366 = icmp eq i32 %t1, 90
  br i1 %t366, label %match_then_90_364, label %match_next_90_365
match_then_90_364:
  %t367 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.138, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_90_365:
  %t370 = icmp eq i32 %t1, 91
  br i1 %t370, label %match_then_91_368, label %match_next_91_369
match_then_91_368:
  %t371 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.139, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_91_369:
  %t374 = icmp eq i32 %t1, 92
  br i1 %t374, label %match_then_92_372, label %match_next_92_373
match_then_92_372:
  %t375 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.140, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_92_373:
  %t378 = icmp eq i32 %t1, 93
  br i1 %t378, label %match_then_93_376, label %match_next_93_377
match_then_93_376:
  %t379 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.141, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_93_377:
  %t382 = icmp eq i32 %t1, 94
  br i1 %t382, label %match_then_94_380, label %match_next_94_381
match_then_94_380:
  %t383 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.142, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_94_381:
  %t386 = icmp eq i32 %t1, 95
  br i1 %t386, label %match_then_95_384, label %match_next_95_385
match_then_95_384:
  %t387 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.143, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_95_385:
  %t390 = icmp eq i32 %t1, 96
  br i1 %t390, label %match_then_96_388, label %match_next_96_389
match_then_96_388:
  %t391 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.144, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_96_389:
  %t394 = icmp eq i32 %t1, 97
  br i1 %t394, label %match_then_97_392, label %match_next_97_393
match_then_97_392:
  %t395 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.145, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_97_393:
  %t398 = icmp eq i32 %t1, 98
  br i1 %t398, label %match_then_98_396, label %match_next_98_397
match_then_98_396:
  %t399 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.146, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_98_397:
  %t402 = icmp eq i32 %t1, 99
  br i1 %t402, label %match_then_99_400, label %match_next_99_401
match_then_99_400:
  %t403 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.147, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_99_401:
  %t406 = icmp eq i32 %t1, 100
  br i1 %t406, label %match_then_100_404, label %match_next_100_405
match_then_100_404:
  %t407 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.148, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_100_405:
  %t410 = icmp eq i32 %t1, 101
  br i1 %t410, label %match_then_101_408, label %match_next_101_409
match_then_101_408:
  %t411 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.149, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_101_409:
  br label %match_end_2
match_end_2:
  %t412 = phi i8* [ %t7, %match_then_0_4 ], [ %t11, %match_then_1_8 ], [ %t15, %match_then_2_12 ], [ %t19, %match_then_3_16 ], [ %t23, %match_then_4_20 ], [ %t27, %match_then_5_24 ], [ %t31, %match_then_6_28 ], [ %t35, %match_then_7_32 ], [ %t39, %match_then_8_36 ], [ %t43, %match_then_9_40 ], [ %t47, %match_then_10_44 ], [ %t51, %match_then_11_48 ], [ %t55, %match_then_12_52 ], [ %t59, %match_then_13_56 ], [ %t63, %match_then_14_60 ], [ %t67, %match_then_15_64 ], [ %t71, %match_then_16_68 ], [ %t75, %match_then_17_72 ], [ %t79, %match_then_18_76 ], [ %t83, %match_then_19_80 ], [ %t87, %match_then_20_84 ], [ %t91, %match_then_21_88 ], [ %t95, %match_then_22_92 ], [ %t99, %match_then_23_96 ], [ %t103, %match_then_24_100 ], [ %t107, %match_then_25_104 ], [ %t111, %match_then_26_108 ], [ %t115, %match_then_27_112 ], [ %t119, %match_then_28_116 ], [ %t123, %match_then_29_120 ], [ %t127, %match_then_30_124 ], [ %t131, %match_then_31_128 ], [ %t135, %match_then_32_132 ], [ %t139, %match_then_33_136 ], [ %t143, %match_then_34_140 ], [ %t147, %match_then_35_144 ], [ %t151, %match_then_36_148 ], [ %t155, %match_then_37_152 ], [ %t159, %match_then_38_156 ], [ %t163, %match_then_39_160 ], [ %t167, %match_then_40_164 ], [ %t171, %match_then_41_168 ], [ %t175, %match_then_42_172 ], [ %t179, %match_then_43_176 ], [ %t183, %match_then_44_180 ], [ %t187, %match_then_45_184 ], [ %t191, %match_then_46_188 ], [ %t195, %match_then_47_192 ], [ %t199, %match_then_48_196 ], [ %t203, %match_then_49_200 ], [ %t207, %match_then_50_204 ], [ %t211, %match_then_51_208 ], [ %t215, %match_then_52_212 ], [ %t219, %match_then_53_216 ], [ %t223, %match_then_54_220 ], [ %t227, %match_then_55_224 ], [ %t231, %match_then_56_228 ], [ %t235, %match_then_57_232 ], [ %t239, %match_then_58_236 ], [ %t243, %match_then_59_240 ], [ %t247, %match_then_60_244 ], [ %t251, %match_then_61_248 ], [ %t255, %match_then_62_252 ], [ %t259, %match_then_63_256 ], [ %t263, %match_then_64_260 ], [ %t267, %match_then_65_264 ], [ %t271, %match_then_66_268 ], [ %t275, %match_then_67_272 ], [ %t279, %match_then_68_276 ], [ %t283, %match_then_69_280 ], [ %t287, %match_then_70_284 ], [ %t291, %match_then_71_288 ], [ %t295, %match_then_72_292 ], [ %t299, %match_then_73_296 ], [ %t303, %match_then_74_300 ], [ %t307, %match_then_75_304 ], [ %t311, %match_then_76_308 ], [ %t315, %match_then_77_312 ], [ %t319, %match_then_78_316 ], [ %t323, %match_then_79_320 ], [ %t327, %match_then_80_324 ], [ %t331, %match_then_81_328 ], [ %t335, %match_then_82_332 ], [ %t339, %match_then_83_336 ], [ %t343, %match_then_84_340 ], [ %t347, %match_then_85_344 ], [ %t351, %match_then_86_348 ], [ %t355, %match_then_87_352 ], [ %t359, %match_then_88_356 ], [ %t363, %match_then_89_360 ], [ %t367, %match_then_90_364 ], [ %t371, %match_then_91_368 ], [ %t375, %match_then_92_372 ], [ %t379, %match_then_93_376 ], [ %t383, %match_then_94_380 ], [ %t387, %match_then_95_384 ], [ %t391, %match_then_96_388 ], [ %t395, %match_then_97_392 ], [ %t399, %match_then_98_396 ], [ %t403, %match_then_99_400 ], [ %t407, %match_then_100_404 ], [ %t411, %match_then_101_408 ], [ undef, %match_next_101_409 ]
  ret i8* %t412
}

define i8* @lex__format_lex_error(%lex__LexError %e) {
entry:
  %t0 = alloca %lex__LexError
  store %lex__LexError %e, %lex__LexError* %t0
  %t1 = getelementptr inbounds %lex__LexError, %lex__LexError* %t0, i32 0, i32 1
  %t2 = load i8*, i8** %t1
  %t3 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t3)
  %t4 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.150, i64 0, i32 2, i64 0
  %t5 = call i32 @strcmp(i8* %t2, i8* %t4)
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t4)
  %t6 = icmp eq i32 %t5, 0
  br i1 %t6, label %if_then_2042, label %if_else_2043
if_then_2042:
  %t7 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.151, i64 0, i32 2, i64 0
  %t8 = getelementptr inbounds %lex__LexError, %lex__LexError* %t0, i32 0, i32 0
  %t9 = load i8*, i8** %t8
  %t10 = load i8*, i8** %t8
  call void @star_rc_retain(i8* %t10)
  %t11 = call i32 @strlen(i8* %t7)
  %t12 = call i32 @strlen(i8* %t9)
  %t13 = add i32 %t11, %t12
  %t14 = add i32 %t13, 1
  %t15 = sext i32 %t14 to i64
  %t16 = call i8* @star_rc_alloc(i64 %t15, i8* null)
  call i8* @strcpy(i8* %t16, i8* %t7)
  call i8* @strcat(i8* %t16, i8* %t9)
  call void @star_rc_release(i8* %t7)
  call void @star_rc_release(i8* %t9)
  br label %if_end_2044
if_else_2043:
  %t17 = getelementptr inbounds %lex__LexError, %lex__LexError* %t0, i32 0, i32 1
  %t18 = load i8*, i8** %t17
  %t19 = load i8*, i8** %t17
  call void @star_rc_retain(i8* %t19)
  %t20 = getelementptr inbounds %lex__LexError, %lex__LexError* %t0, i32 0, i32 2
  %t21 = load i32, i32* %t20
  %t22 = getelementptr inbounds %lex__LexError, %lex__LexError* %t0, i32 0, i32 3
  %t23 = load i32, i32* %t22
  %t24 = getelementptr inbounds %lex__LexError, %lex__LexError* %t0, i32 0, i32 0
  %t25 = load i8*, i8** %t24
  %t26 = load i8*, i8** %t24
  call void @star_rc_retain(i8* %t26)
  %t27 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.152, i64 0, i64 0
  %t28 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t27, i8* %t18, i32 %t21, i32 %t23, i8* %t25)
  %t29 = add i32 %t28, 1
  %t30 = sext i32 %t29 to i64
  %t31 = call i8* @star_rc_alloc(i64 %t30, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t31, i64 %t30, i8* %t27, i8* %t18, i32 %t21, i32 %t23, i8* %t25)
  call void @star_rc_release(i8* %t18)
  call void @star_rc_release(i8* %t25)
  br label %if_end_2044
if_end_2044:
  %t32 = phi i8* [ %t16, %if_then_2042 ], [ %t31, %if_else_2043 ]
  %t33 = getelementptr inbounds %lex__LexError, %lex__LexError* %t0, i32 0, i32 0
  %t34 = load i8*, i8** %t33
  call void @star_rc_release(i8* %t34)
  %t35 = getelementptr inbounds %lex__LexError, %lex__LexError* %t0, i32 0, i32 1
  %t36 = load i8*, i8** %t35
  call void @star_rc_release(i8* %t36)
  ret i8* %t32
}

define i1 @lex__is_digit_byte(i32 %c) {
entry:
  %t0 = alloca i32
  store i32 %c, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp sge i32 %t1, 48
  br i1 %t2, label %logic_rhs_2045, label %logic_short_2046
logic_rhs_2045:
  %t3 = load i32, i32* %t0
  %t4 = icmp sle i32 %t3, 57
  br label %logic_end_2047
logic_short_2046:
  br label %logic_end_2047
logic_end_2047:
  %t5 = phi i1 [ %t4, %logic_rhs_2045 ], [ false, %logic_short_2046 ]
  ret i1 %t5
}

define i1 @lex__is_alpha_byte(i32 %c) {
entry:
  %t0 = alloca i32
  store i32 %c, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp sge i32 %t1, 65
  br i1 %t2, label %logic_rhs_2048, label %logic_short_2049
logic_rhs_2048:
  %t3 = load i32, i32* %t0
  %t4 = icmp sle i32 %t3, 90
  br label %logic_end_2050
logic_short_2049:
  br label %logic_end_2050
logic_end_2050:
  %t5 = phi i1 [ %t4, %logic_rhs_2048 ], [ false, %logic_short_2049 ]
  br i1 %t5, label %logic_short_2052, label %logic_rhs_2051
logic_rhs_2051:
  %t6 = load i32, i32* %t0
  %t7 = icmp sge i32 %t6, 97
  br i1 %t7, label %logic_rhs_2054, label %logic_short_2055
logic_rhs_2054:
  %t8 = load i32, i32* %t0
  %t9 = icmp sle i32 %t8, 122
  br label %logic_end_2056
logic_short_2055:
  br label %logic_end_2056
logic_end_2056:
  %t10 = phi i1 [ %t9, %logic_rhs_2054 ], [ false, %logic_short_2055 ]
  br label %logic_end_2053
logic_short_2052:
  br label %logic_end_2053
logic_end_2053:
  %t11 = phi i1 [ %t10, %logic_end_2056 ], [ true, %logic_short_2052 ]
  ret i1 %t11
}

define i1 @lex__is_alnum_byte(i32 %c) {
entry:
  %t0 = alloca i32
  store i32 %c, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = call i1 @lex__is_alpha_byte(i32 %t1)
  br i1 %t2, label %logic_short_2058, label %logic_rhs_2057
logic_rhs_2057:
  %t3 = load i32, i32* %t0
  %t4 = call i1 @lex__is_digit_byte(i32 %t3)
  br label %logic_end_2059
logic_short_2058:
  br label %logic_end_2059
logic_end_2059:
  %t5 = phi i1 [ %t4, %logic_rhs_2057 ], [ true, %logic_short_2058 ]
  ret i1 %t5
}

define i1 @lex__is_hex_digit_byte(i32 %c) {
entry:
  %t0 = alloca i32
  store i32 %c, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = call i1 @lex__is_digit_byte(i32 %t1)
  br i1 %t2, label %logic_short_2061, label %logic_rhs_2060
logic_rhs_2060:
  %t3 = load i32, i32* %t0
  %t4 = icmp sge i32 %t3, 65
  br i1 %t4, label %logic_rhs_2063, label %logic_short_2064
logic_rhs_2063:
  %t5 = load i32, i32* %t0
  %t6 = icmp sle i32 %t5, 70
  br label %logic_end_2065
logic_short_2064:
  br label %logic_end_2065
logic_end_2065:
  %t7 = phi i1 [ %t6, %logic_rhs_2063 ], [ false, %logic_short_2064 ]
  br label %logic_end_2062
logic_short_2061:
  br label %logic_end_2062
logic_end_2062:
  %t8 = phi i1 [ %t7, %logic_end_2065 ], [ true, %logic_short_2061 ]
  br i1 %t8, label %logic_short_2067, label %logic_rhs_2066
logic_rhs_2066:
  %t9 = load i32, i32* %t0
  %t10 = icmp sge i32 %t9, 97
  br i1 %t10, label %logic_rhs_2069, label %logic_short_2070
logic_rhs_2069:
  %t11 = load i32, i32* %t0
  %t12 = icmp sle i32 %t11, 102
  br label %logic_end_2071
logic_short_2070:
  br label %logic_end_2071
logic_end_2071:
  %t13 = phi i1 [ %t12, %logic_rhs_2069 ], [ false, %logic_short_2070 ]
  br label %logic_end_2068
logic_short_2067:
  br label %logic_end_2068
logic_end_2068:
  %t14 = phi i1 [ %t13, %logic_end_2071 ], [ true, %logic_short_2067 ]
  ret i1 %t14
}

define i32 @lex__to_lower_byte(i32 %c) {
entry:
  %t0 = alloca i32
  store i32 %c, i32* %t0
  %t1 = load i32, i32* %t0
  %t2 = icmp sge i32 %t1, 65
  br i1 %t2, label %logic_rhs_2072, label %logic_short_2073
logic_rhs_2072:
  %t3 = load i32, i32* %t0
  %t4 = icmp sle i32 %t3, 90
  br label %logic_end_2074
logic_short_2073:
  br label %logic_end_2074
logic_end_2074:
  %t5 = phi i1 [ %t4, %logic_rhs_2072 ], [ false, %logic_short_2073 ]
  br i1 %t5, label %if_then_2075, label %if_else_2076
if_then_2075:
  %t6 = load i32, i32* %t0
  %t7 = add i32 %t6, 32
  br label %if_end_2077
if_else_2076:
  %t8 = load i32, i32* %t0
  br label %if_end_2077
if_end_2077:
  %t9 = phi i32 [ %t7, %if_then_2075 ], [ %t8, %if_else_2076 ]
  ret i32 %t9
}

define i8* @lex__str_lower(i8* %s) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t2 = alloca i32
  %t50 = alloca i64
  %t116 = alloca i64
  %t117 = alloca i64
  %t137 = alloca i8*
  %t138 = alloca i64
  store i8* %s, i8** %t0
  store i8* null, i8** %t1
  store i32 0, i32* %t2
  br label %while_cond_2078
while_cond_2078:
  %t3 = load i32, i32* %t2
  %t4 = load i8*, i8** %t0
  %t5 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t5)
  %t6 = call i32 @strlen(i8* %t4)
  call void @star_rc_release(i8* %t4)
  %t7 = icmp slt i32 %t3, %t6
  br i1 %t7, label %while_body_2079, label %while_else_2080
while_body_2079:
  %t8 = getelementptr i8*, i8** null, i32 1
  %t9 = ptrtoint i8** %t8 to i64
  %t10 = load i8*, i8** %t1
  %t11 = icmp eq i8* %t10, null
  br i1 %t11, label %list_cow_alloc_2082, label %list_cow_check_2083
list_cow_alloc_2082:
  %t24 = bitcast void (i8*)* @list_release_str to i8*
  %t25 = call i8* @star_rc_alloc(i64 24, i8* %t24)
  %t26 = bitcast i8* %t25 to { i8**, i64, i64 }*
  %t27 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t26, i32 0, i32 0
  store i8** null, i8*** %t27
  %t28 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t26, i32 0, i32 1
  store i64 0, i64* %t28
  %t29 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t26, i32 0, i32 2
  store i64 0, i64* %t29
  store i8* %t25, i8** %t1
  br label %list_cow_done_2084
list_cow_check_2083:
  %t30 = getelementptr inbounds i8, i8* %t10, i64 -16
  %t31 = bitcast i8* %t30 to i64*
  %t32 = load atomic i64, i64* %t31 seq_cst, align 8
  %t33 = icmp eq i64 %t32, 1
  br i1 %t33, label %list_cow_done_2084, label %list_cow_clone_2088
list_cow_clone_2088:
  %t34 = bitcast i8* %t10 to { i8**, i64, i64 }*
  %t35 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t34, i32 0, i32 0
  %t36 = load i8**, i8*** %t35
  %t37 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t34, i32 0, i32 1
  %t38 = load i64, i64* %t37
  %t39 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t34, i32 0, i32 2
  %t40 = load i64, i64* %t39
  %t41 = bitcast void (i8*)* @list_release_str to i8*
  %t42 = call i8* @star_rc_alloc(i64 24, i8* %t41)
  %t43 = bitcast i8* %t42 to { i8**, i64, i64 }*
  %t44 = mul i64 %t40, %t9
  %t45 = call i8* @malloc(i64 %t44)
  %t46 = bitcast i8* %t45 to i8**
  %t47 = icmp sgt i64 %t38, 0
  br i1 %t47, label %list_cow_copy_2089, label %list_cow_after_copy_2090
list_cow_copy_2089:
  %t48 = mul i64 %t38, %t9
  %t49 = bitcast i8** %t36 to i8*
  call i8* @memcpy(i8* %t45, i8* %t49, i64 %t48)
  store i64 0, i64* %t50
  br label %list_cow_retain_cond_2091
list_cow_retain_cond_2091:
  %t51 = load i64, i64* %t50
  %t52 = icmp slt i64 %t51, %t38
  br i1 %t52, label %list_cow_retain_body_2092, label %list_cow_retain_end_2093
list_cow_retain_body_2092:
  %t53 = getelementptr inbounds i8*, i8** %t46, i64 %t51
  %t54 = load i8*, i8** %t53
  call void @star_rc_retain(i8* %t54)
  %t55 = add i64 %t51, 1
  store i64 %t55, i64* %t50
  br label %list_cow_retain_cond_2091
list_cow_retain_end_2093:
  br label %list_cow_after_copy_2090
list_cow_after_copy_2090:
  %t56 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t43, i32 0, i32 0
  store i8** %t46, i8*** %t56
  %t57 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t43, i32 0, i32 1
  store i64 %t38, i64* %t57
  %t58 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t43, i32 0, i32 2
  store i64 %t40, i64* %t58
  call void @star_rc_release(i8* %t10)
  store i8* %t42, i8** %t1
  br label %list_cow_done_2084
list_cow_done_2084:
  %t59 = load i8*, i8** %t1
  %t60 = bitcast i8* %t59 to { i8**, i64, i64 }*
  %t61 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t60, i32 0, i32 0
  %t62 = load i8**, i8*** %t61
  %t63 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t60, i32 0, i32 1
  %t64 = load i64, i64* %t63
  %t65 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t60, i32 0, i32 2
  %t66 = load i8*, i8** %t0
  %t67 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t67)
  %t68 = load i32, i32* %t2
  %t69 = sext i32 %t68 to i64
  %t70 = icmp eq i8* %t66, null
  br i1 %t70, label %str_idx_oob_2096, label %str_idx_chk_2094
str_idx_chk_2094:
  %t71 = call i32 @strlen(i8* %t66)
  %t72 = sext i32 %t71 to i64
  %t73 = icmp ult i64 %t69, %t72
  br i1 %t73, label %str_idx_ok_2095, label %str_idx_oob_2096
str_idx_ok_2095:
  %t74 = getelementptr inbounds i8, i8* %t66, i64 %t69
  %t75 = load i8, i8* %t74
  %t76 = zext i8 %t75 to i32
  br label %str_idx_end_2097
str_idx_oob_2096:
  br label %str_idx_end_2097
str_idx_end_2097:
  %t77 = phi i32 [ %t76, %str_idx_ok_2095 ], [ 0, %str_idx_oob_2096 ]
  call void @star_rc_release(i8* %t66)
  %t78 = call i32 @lex__to_lower_byte(i32 %t77)
  %t79 = trunc i32 %t78 to i8
  %t80 = call i8* @star_rc_alloc(i64 2, i8* null)
  store i8 %t79, i8* %t80
  %t81 = getelementptr inbounds i8, i8* %t80, i64 1
  store i8 0, i8* %t81
  %t82 = load i64, i64* %t65
  %t83 = load i8**, i8*** %t61
  %t84 = load i64, i64* %t63
  %t85 = icmp sge i64 %t84, %t82
  br i1 %t85, label %list_push_grow_2098, label %list_push_store_2099
list_push_grow_2098:
  %t86 = mul i64 %t82, 2
  %t87 = icmp sgt i64 %t86, 0
  %t88 = select i1 %t87, i64 %t86, i64 1
  %t89 = getelementptr i8*, i8** null, i32 1
  %t90 = ptrtoint i8** %t89 to i64
  %t91 = mul i64 %t88, %t90
  %t92 = call i8* @malloc(i64 %t91)
  %t93 = bitcast i8* %t92 to i8**
  %t94 = icmp sgt i64 %t82, 0
  br i1 %t94, label %list_push_copy_2100, label %list_push_after_copy_2101
list_push_copy_2100:
  %t95 = mul i64 %t84, %t90
  %t96 = bitcast i8** %t83 to i8*
  call i8* @memcpy(i8* %t92, i8* %t96, i64 %t95)
  call void @free(i8* %t96)
  br label %list_push_after_copy_2101
list_push_after_copy_2101:
  store i8** %t93, i8*** %t61
  store i64 %t88, i64* %t65
  br label %list_push_store_2099
list_push_store_2099:
  %t97 = load i8**, i8*** %t61
  %t98 = getelementptr inbounds i8*, i8** %t97, i64 %t84
  store i8* %t80, i8** %t98
  %t99 = add i64 %t84, 1
  store i64 %t99, i64* %t63
  %t100 = load i32, i32* %t2
  %t101 = add i32 %t100, 1
  store i32 %t101, i32* %t2
  br label %while_cond_2078
while_else_2080:
  br label %while_end_2081
while_end_2081:
  %t102 = load i8*, i8** %t1
  %t103 = icmp eq i8* %t102, null
  br i1 %t103, label %list_read_null_2102, label %list_read_real_2103
list_read_null_2102:
  br label %list_read_end_2104
list_read_real_2103:
  %t104 = bitcast i8* %t102 to { i8**, i64, i64 }*
  %t105 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t104, i32 0, i32 0
  %t106 = load i8**, i8*** %t105
  %t107 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t104, i32 0, i32 1
  %t108 = load i64, i64* %t107
  br label %list_read_end_2104
list_read_end_2104:
  %t109 = phi i8** [ null, %list_read_null_2102 ], [ %t106, %list_read_real_2103 ]
  %t110 = phi i64 [ 0, %list_read_null_2102 ], [ %t108, %list_read_real_2103 ]
  %t111 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.153, i64 0, i32 2, i64 0
  %t112 = icmp eq i8* %t111, null
  %t113 = select i1 %t112, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t111
  %t114 = call i32 @strlen(i8* %t113)
  %t115 = sext i32 %t114 to i64
  store i64 0, i64* %t116
  store i64 0, i64* %t117
  br label %join_sum_cond_2105
join_sum_cond_2105:
  %t118 = load i64, i64* %t117
  %t119 = icmp slt i64 %t118, %t110
  br i1 %t119, label %join_sum_body_2106, label %join_sum_done_2107
join_sum_body_2106:
  %t120 = getelementptr inbounds i8*, i8** %t109, i64 %t118
  %t121 = load i8*, i8** %t120
  %t122 = icmp eq i8* %t121, null
  %t123 = select i1 %t122, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t121
  %t124 = call i32 @strlen(i8* %t123)
  %t125 = sext i32 %t124 to i64
  %t126 = load i64, i64* %t116
  %t127 = add i64 %t126, %t125
  store i64 %t127, i64* %t116
  %t128 = add i64 %t118, 1
  store i64 %t128, i64* %t117
  br label %join_sum_cond_2105
join_sum_done_2107:
  %t129 = load i64, i64* %t116
  %t130 = icmp eq i64 %t110, 0
  %t131 = sub i64 %t110, 1
  %t132 = select i1 %t130, i64 0, i64 %t131
  %t133 = mul i64 %t132, %t115
  %t134 = add i64 %t129, %t133
  %t135 = add i64 %t134, 1
  %t136 = call i8* @star_rc_alloc(i64 %t135, i8* null)
  store i8* %t136, i8** %t137
  store i64 0, i64* %t138
  br label %join_build_cond_2108
join_build_cond_2108:
  %t139 = load i64, i64* %t138
  %t140 = icmp slt i64 %t139, %t110
  br i1 %t140, label %join_build_body_2109, label %join_build_done_2110
join_build_body_2109:
  %t141 = getelementptr inbounds i8*, i8** %t109, i64 %t139
  %t142 = load i8*, i8** %t141
  %t143 = icmp eq i8* %t142, null
  %t144 = select i1 %t143, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t142
  %t145 = call i32 @strlen(i8* %t144)
  %t146 = sext i32 %t145 to i64
  %t147 = load i8*, i8** %t137
  call i8* @memcpy(i8* %t147, i8* %t144, i64 %t146)
  %t148 = getelementptr inbounds i8, i8* %t147, i64 %t146
  %t149 = add i64 %t139, 1
  %t150 = icmp slt i64 %t149, %t110
  br i1 %t150, label %join_sep_2111, label %join_no_sep_2112
join_sep_2111:
  call i8* @memcpy(i8* %t148, i8* %t113, i64 %t115)
  %t151 = getelementptr inbounds i8, i8* %t148, i64 %t115
  br label %join_after_2113
join_no_sep_2112:
  br label %join_after_2113
join_after_2113:
  %t152 = phi i8* [ %t151, %join_sep_2111 ], [ %t148, %join_no_sep_2112 ]
  store i8* %t152, i8** %t137
  store i64 %t149, i64* %t138
  br label %join_build_cond_2108
join_build_done_2110:
  %t153 = load i8*, i8** %t137
  store i8 0, i8* %t153
  call void @star_rc_release(i8* %t111)
  %t154 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t154)
  %t155 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t155)
  ret i8* %t136
}

define i8* @lex__escape_char(i32 %c) {
entry:
  %t0 = alloca i32
  store i32 %c, i32* %t0
  %t1 = load i32, i32* %t0
  br label %match_scrutinee_3
match_scrutinee_3:
  %t6 = icmp eq i32 %t1, 110
  br i1 %t6, label %match_then_0_4, label %match_next_0_5
match_then_0_4:
  %t7 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.154, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_0_5:
  %t10 = icmp eq i32 %t1, 114
  br i1 %t10, label %match_then_1_8, label %match_next_1_9
match_then_1_8:
  %t11 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.155, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_1_9:
  %t14 = icmp eq i32 %t1, 116
  br i1 %t14, label %match_then_2_12, label %match_next_2_13
match_then_2_12:
  %t15 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.156, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_2_13:
  %t18 = icmp eq i32 %t1, 34
  br i1 %t18, label %match_then_3_16, label %match_next_3_17
match_then_3_16:
  %t19 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.157, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_3_17:
  %t22 = icmp eq i32 %t1, 92
  br i1 %t22, label %match_then_4_20, label %match_next_4_21
match_then_4_20:
  %t23 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.158, i64 0, i32 2, i64 0
  br label %match_end_2
match_next_4_21:
  %t26 = icmp eq i32 %t1, 48
  br i1 %t26, label %match_then_5_24, label %match_next_5_25
match_then_5_24:
  %t27 = trunc i32 0 to i8
  %t28 = call i8* @star_rc_alloc(i64 2, i8* null)
  store i8 %t27, i8* %t28
  %t29 = getelementptr inbounds i8, i8* %t28, i64 1
  store i8 0, i8* %t29
  br label %match_end_2
match_next_5_25:
  %t32 = load i32, i32* %t0
  %t33 = trunc i32 %t32 to i8
  %t34 = call i8* @star_rc_alloc(i64 2, i8* null)
  store i8 %t33, i8* %t34
  %t35 = getelementptr inbounds i8, i8* %t34, i64 1
  store i8 0, i8* %t35
  br label %match_end_2
match_end_2:
  %t36 = phi i8* [ %t7, %match_then_0_4 ], [ %t11, %match_then_1_8 ], [ %t15, %match_then_2_12 ], [ %t19, %match_then_3_16 ], [ %t23, %match_then_4_20 ], [ %t28, %match_then_5_24 ], [ %t34, %match_next_5_25 ]
  ret i8* %t36
}

define %lex__Lexer @lex__new_lexer(i8* %source, i8* %filename) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t2 = alloca %lex__Lexer
  store i8* %source, i8** %t0
  store i8* %filename, i8** %t1
  %t3 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 0
  %t4 = load i8*, i8** %t0
  %t5 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t5)
  store i8* %t4, i8** %t3
  %t6 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 1
  %t7 = load i8*, i8** %t1
  %t8 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t8)
  store i8* %t7, i8** %t6
  %t9 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 2
  %t10 = call i8* @lex__tok__build_keywords()
  store i8* %t10, i8** %t9
  %t11 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 3
  store i32 0, i32* %t11
  %t12 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 4
  store i32 1, i32* %t12
  %t13 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 5
  store i32 1, i32* %t13
  %t14 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 6
  store i32 0, i32* %t14
  %t15 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 7
  store i32 1, i32* %t15
  %t16 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 8
  store i32 1, i32* %t16
  %t17 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 9
  store i8* null, i8** %t17
  %t18 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 10
  store i1 false, i1* %t18
  %t19 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 11
  %t20 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.159, i64 0, i32 2, i64 0
  store i8* %t20, i8** %t19
  %t21 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 12
  store i32 0, i32* %t21
  %t22 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 13
  store i32 0, i32* %t22
  %t23 = load %lex__Lexer, %lex__Lexer* %t2
  %t24 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t24)
  %t25 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t25)
  ret %lex__Lexer %t23
}

define i1 @lex__Lexer__is_at_end(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  store %lex__Lexer* %self, %lex__Lexer** %t0
  %t1 = load %lex__Lexer*, %lex__Lexer** %t0
  %t2 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t1, i32 0, i32 3
  %t3 = load i32, i32* %t2
  %t4 = load %lex__Lexer*, %lex__Lexer** %t0
  %t5 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t4, i32 0, i32 0
  %t6 = load i8*, i8** %t5
  %t7 = load i8*, i8** %t5
  call void @star_rc_retain(i8* %t7)
  %t8 = call i32 @strlen(i8* %t6)
  call void @star_rc_release(i8* %t6)
  %t9 = icmp sge i32 %t3, %t8
  ret i1 %t9
}

define i32 @lex__Lexer__peek(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  store %lex__Lexer* %self, %lex__Lexer** %t0
  %t1 = load %lex__Lexer*, %lex__Lexer** %t0
  %t2 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t1)
  br i1 %t2, label %if_then_2114, label %if_else_2115
if_then_2114:
  br label %if_end_2116
if_else_2115:
  %t3 = load %lex__Lexer*, %lex__Lexer** %t0
  %t4 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t3, i32 0, i32 0
  %t5 = load i8*, i8** %t4
  %t6 = load i8*, i8** %t4
  call void @star_rc_retain(i8* %t6)
  %t7 = load %lex__Lexer*, %lex__Lexer** %t0
  %t8 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t7, i32 0, i32 3
  %t9 = load i32, i32* %t8
  %t10 = sext i32 %t9 to i64
  %t11 = icmp eq i8* %t5, null
  br i1 %t11, label %str_idx_oob_2119, label %str_idx_chk_2117
str_idx_chk_2117:
  %t12 = call i32 @strlen(i8* %t5)
  %t13 = sext i32 %t12 to i64
  %t14 = icmp ult i64 %t10, %t13
  br i1 %t14, label %str_idx_ok_2118, label %str_idx_oob_2119
str_idx_ok_2118:
  %t15 = getelementptr inbounds i8, i8* %t5, i64 %t10
  %t16 = load i8, i8* %t15
  %t17 = zext i8 %t16 to i32
  br label %str_idx_end_2120
str_idx_oob_2119:
  br label %str_idx_end_2120
str_idx_end_2120:
  %t18 = phi i32 [ %t17, %str_idx_ok_2118 ], [ 0, %str_idx_oob_2119 ]
  call void @star_rc_release(i8* %t5)
  br label %if_end_2116
if_end_2116:
  %t19 = phi i32 [ 0, %if_then_2114 ], [ %t18, %str_idx_end_2120 ]
  ret i32 %t19
}

define i32 @lex__Lexer__advance(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  %t1 = alloca i32
  store %lex__Lexer* %self, %lex__Lexer** %t0
  %t2 = load %lex__Lexer*, %lex__Lexer** %t0
  %t3 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 0
  %t4 = load i8*, i8** %t3
  %t5 = load i8*, i8** %t3
  call void @star_rc_retain(i8* %t5)
  %t6 = load %lex__Lexer*, %lex__Lexer** %t0
  %t7 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t6, i32 0, i32 3
  %t8 = load i32, i32* %t7
  %t9 = sext i32 %t8 to i64
  %t10 = icmp eq i8* %t4, null
  br i1 %t10, label %str_idx_oob_2123, label %str_idx_chk_2121
str_idx_chk_2121:
  %t11 = call i32 @strlen(i8* %t4)
  %t12 = sext i32 %t11 to i64
  %t13 = icmp ult i64 %t9, %t12
  br i1 %t13, label %str_idx_ok_2122, label %str_idx_oob_2123
str_idx_ok_2122:
  %t14 = getelementptr inbounds i8, i8* %t4, i64 %t9
  %t15 = load i8, i8* %t14
  %t16 = zext i8 %t15 to i32
  br label %str_idx_end_2124
str_idx_oob_2123:
  br label %str_idx_end_2124
str_idx_end_2124:
  %t17 = phi i32 [ %t16, %str_idx_ok_2122 ], [ 0, %str_idx_oob_2123 ]
  call void @star_rc_release(i8* %t4)
  store i32 %t17, i32* %t1
  %t18 = load %lex__Lexer*, %lex__Lexer** %t0
  %t19 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t18, i32 0, i32 3
  %t20 = load i32, i32* %t19
  %t21 = add i32 %t20, 1
  %t22 = load %lex__Lexer*, %lex__Lexer** %t0
  %t23 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t22, i32 0, i32 3
  store i32 %t21, i32* %t23
  %t24 = load %lex__Lexer*, %lex__Lexer** %t0
  %t25 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t24, i32 0, i32 5
  %t26 = load i32, i32* %t25
  %t27 = add i32 %t26, 1
  %t28 = load %lex__Lexer*, %lex__Lexer** %t0
  %t29 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t28, i32 0, i32 5
  store i32 %t27, i32* %t29
  %t30 = load i32, i32* %t1
  ret i32 %t30
}

define i1 @lex__Lexer__match_char(%lex__Lexer* %self, i32 %expected) {
entry:
  %t0 = alloca %lex__Lexer*
  %t1 = alloca i32
  store %lex__Lexer* %self, %lex__Lexer** %t0
  store i32 %expected, i32* %t1
  %t2 = load %lex__Lexer*, %lex__Lexer** %t0
  %t3 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t2)
  br i1 %t3, label %logic_short_2126, label %logic_rhs_2125
logic_rhs_2125:
  %t4 = load %lex__Lexer*, %lex__Lexer** %t0
  %t5 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t4, i32 0, i32 0
  %t6 = load i8*, i8** %t5
  %t7 = load i8*, i8** %t5
  call void @star_rc_retain(i8* %t7)
  %t8 = load %lex__Lexer*, %lex__Lexer** %t0
  %t9 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t8, i32 0, i32 3
  %t10 = load i32, i32* %t9
  %t11 = sext i32 %t10 to i64
  %t12 = icmp eq i8* %t6, null
  br i1 %t12, label %str_idx_oob_2130, label %str_idx_chk_2128
str_idx_chk_2128:
  %t13 = call i32 @strlen(i8* %t6)
  %t14 = sext i32 %t13 to i64
  %t15 = icmp ult i64 %t11, %t14
  br i1 %t15, label %str_idx_ok_2129, label %str_idx_oob_2130
str_idx_ok_2129:
  %t16 = getelementptr inbounds i8, i8* %t6, i64 %t11
  %t17 = load i8, i8* %t16
  %t18 = zext i8 %t17 to i32
  br label %str_idx_end_2131
str_idx_oob_2130:
  br label %str_idx_end_2131
str_idx_end_2131:
  %t19 = phi i32 [ %t18, %str_idx_ok_2129 ], [ 0, %str_idx_oob_2130 ]
  call void @star_rc_release(i8* %t6)
  %t20 = load i32, i32* %t1
  %t21 = icmp ne i32 %t19, %t20
  br label %logic_end_2127
logic_short_2126:
  br label %logic_end_2127
logic_end_2127:
  %t22 = phi i1 [ %t21, %str_idx_end_2131 ], [ true, %logic_short_2126 ]
  br i1 %t22, label %if_then_2132, label %if_else_2133
if_then_2132:
  br label %if_end_2134
if_else_2133:
  %t23 = load %lex__Lexer*, %lex__Lexer** %t0
  %t24 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t23, i32 0, i32 3
  %t25 = load i32, i32* %t24
  %t26 = add i32 %t25, 1
  %t27 = load %lex__Lexer*, %lex__Lexer** %t0
  %t28 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t27, i32 0, i32 3
  store i32 %t26, i32* %t28
  %t29 = load %lex__Lexer*, %lex__Lexer** %t0
  %t30 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t29, i32 0, i32 5
  %t31 = load i32, i32* %t30
  %t32 = add i32 %t31, 1
  %t33 = load %lex__Lexer*, %lex__Lexer** %t0
  %t34 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t33, i32 0, i32 5
  store i32 %t32, i32* %t34
  br label %if_end_2134
if_end_2134:
  %t35 = phi i1 [ false, %if_then_2132 ], [ true, %if_else_2133 ]
  ret i1 %t35
}

define i8* @lex__Lexer__substr(%lex__Lexer* %self, i32 %start, i32 %end) {
entry:
  %t0 = alloca %lex__Lexer*
  %t1 = alloca i32
  %t2 = alloca i32
  %t3 = alloca i8*
  %t4 = alloca i32
  %t39 = alloca i64
  %t106 = alloca i64
  %t107 = alloca i64
  %t127 = alloca i8*
  %t128 = alloca i64
  store %lex__Lexer* %self, %lex__Lexer** %t0
  store i32 %start, i32* %t1
  store i32 %end, i32* %t2
  store i8* null, i8** %t3
  %t5 = load i32, i32* %t1
  store i32 %t5, i32* %t4
  br label %while_cond_2135
while_cond_2135:
  %t6 = load i32, i32* %t4
  %t7 = load i32, i32* %t2
  %t8 = icmp slt i32 %t6, %t7
  br i1 %t8, label %while_body_2136, label %while_else_2137
while_body_2136:
  %t9 = getelementptr i8*, i8** null, i32 1
  %t10 = ptrtoint i8** %t9 to i64
  %t11 = load i8*, i8** %t3
  %t12 = icmp eq i8* %t11, null
  br i1 %t12, label %list_cow_alloc_2139, label %list_cow_check_2140
list_cow_alloc_2139:
  %t13 = bitcast void (i8*)* @list_release_str to i8*
  %t14 = call i8* @star_rc_alloc(i64 24, i8* %t13)
  %t15 = bitcast i8* %t14 to { i8**, i64, i64 }*
  %t16 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t15, i32 0, i32 0
  store i8** null, i8*** %t16
  %t17 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t15, i32 0, i32 1
  store i64 0, i64* %t17
  %t18 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t15, i32 0, i32 2
  store i64 0, i64* %t18
  store i8* %t14, i8** %t3
  br label %list_cow_done_2141
list_cow_check_2140:
  %t19 = getelementptr inbounds i8, i8* %t11, i64 -16
  %t20 = bitcast i8* %t19 to i64*
  %t21 = load atomic i64, i64* %t20 seq_cst, align 8
  %t22 = icmp eq i64 %t21, 1
  br i1 %t22, label %list_cow_done_2141, label %list_cow_clone_2142
list_cow_clone_2142:
  %t23 = bitcast i8* %t11 to { i8**, i64, i64 }*
  %t24 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t23, i32 0, i32 0
  %t25 = load i8**, i8*** %t24
  %t26 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t23, i32 0, i32 1
  %t27 = load i64, i64* %t26
  %t28 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t23, i32 0, i32 2
  %t29 = load i64, i64* %t28
  %t30 = bitcast void (i8*)* @list_release_str to i8*
  %t31 = call i8* @star_rc_alloc(i64 24, i8* %t30)
  %t32 = bitcast i8* %t31 to { i8**, i64, i64 }*
  %t33 = mul i64 %t29, %t10
  %t34 = call i8* @malloc(i64 %t33)
  %t35 = bitcast i8* %t34 to i8**
  %t36 = icmp sgt i64 %t27, 0
  br i1 %t36, label %list_cow_copy_2143, label %list_cow_after_copy_2144
list_cow_copy_2143:
  %t37 = mul i64 %t27, %t10
  %t38 = bitcast i8** %t25 to i8*
  call i8* @memcpy(i8* %t34, i8* %t38, i64 %t37)
  store i64 0, i64* %t39
  br label %list_cow_retain_cond_2145
list_cow_retain_cond_2145:
  %t40 = load i64, i64* %t39
  %t41 = icmp slt i64 %t40, %t27
  br i1 %t41, label %list_cow_retain_body_2146, label %list_cow_retain_end_2147
list_cow_retain_body_2146:
  %t42 = getelementptr inbounds i8*, i8** %t35, i64 %t40
  %t43 = load i8*, i8** %t42
  call void @star_rc_retain(i8* %t43)
  %t44 = add i64 %t40, 1
  store i64 %t44, i64* %t39
  br label %list_cow_retain_cond_2145
list_cow_retain_end_2147:
  br label %list_cow_after_copy_2144
list_cow_after_copy_2144:
  %t45 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 0
  store i8** %t35, i8*** %t45
  %t46 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 1
  store i64 %t27, i64* %t46
  %t47 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t32, i32 0, i32 2
  store i64 %t29, i64* %t47
  call void @star_rc_release(i8* %t11)
  store i8* %t31, i8** %t3
  br label %list_cow_done_2141
list_cow_done_2141:
  %t48 = load i8*, i8** %t3
  %t49 = bitcast i8* %t48 to { i8**, i64, i64 }*
  %t50 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 0
  %t51 = load i8**, i8*** %t50
  %t52 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 1
  %t53 = load i64, i64* %t52
  %t54 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t49, i32 0, i32 2
  %t55 = load %lex__Lexer*, %lex__Lexer** %t0
  %t56 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t55, i32 0, i32 0
  %t57 = load i8*, i8** %t56
  %t58 = load i8*, i8** %t56
  call void @star_rc_retain(i8* %t58)
  %t59 = load i32, i32* %t4
  %t60 = sext i32 %t59 to i64
  %t61 = icmp eq i8* %t57, null
  br i1 %t61, label %str_idx_oob_2150, label %str_idx_chk_2148
str_idx_chk_2148:
  %t62 = call i32 @strlen(i8* %t57)
  %t63 = sext i32 %t62 to i64
  %t64 = icmp ult i64 %t60, %t63
  br i1 %t64, label %str_idx_ok_2149, label %str_idx_oob_2150
str_idx_ok_2149:
  %t65 = getelementptr inbounds i8, i8* %t57, i64 %t60
  %t66 = load i8, i8* %t65
  %t67 = zext i8 %t66 to i32
  br label %str_idx_end_2151
str_idx_oob_2150:
  br label %str_idx_end_2151
str_idx_end_2151:
  %t68 = phi i32 [ %t67, %str_idx_ok_2149 ], [ 0, %str_idx_oob_2150 ]
  call void @star_rc_release(i8* %t57)
  %t69 = trunc i32 %t68 to i8
  %t70 = call i8* @star_rc_alloc(i64 2, i8* null)
  store i8 %t69, i8* %t70
  %t71 = getelementptr inbounds i8, i8* %t70, i64 1
  store i8 0, i8* %t71
  %t72 = load i64, i64* %t54
  %t73 = load i8**, i8*** %t50
  %t74 = load i64, i64* %t52
  %t75 = icmp sge i64 %t74, %t72
  br i1 %t75, label %list_push_grow_2152, label %list_push_store_2153
list_push_grow_2152:
  %t76 = mul i64 %t72, 2
  %t77 = icmp sgt i64 %t76, 0
  %t78 = select i1 %t77, i64 %t76, i64 1
  %t79 = getelementptr i8*, i8** null, i32 1
  %t80 = ptrtoint i8** %t79 to i64
  %t81 = mul i64 %t78, %t80
  %t82 = call i8* @malloc(i64 %t81)
  %t83 = bitcast i8* %t82 to i8**
  %t84 = icmp sgt i64 %t72, 0
  br i1 %t84, label %list_push_copy_2154, label %list_push_after_copy_2155
list_push_copy_2154:
  %t85 = mul i64 %t74, %t80
  %t86 = bitcast i8** %t73 to i8*
  call i8* @memcpy(i8* %t82, i8* %t86, i64 %t85)
  call void @free(i8* %t86)
  br label %list_push_after_copy_2155
list_push_after_copy_2155:
  store i8** %t83, i8*** %t50
  store i64 %t78, i64* %t54
  br label %list_push_store_2153
list_push_store_2153:
  %t87 = load i8**, i8*** %t50
  %t88 = getelementptr inbounds i8*, i8** %t87, i64 %t74
  store i8* %t70, i8** %t88
  %t89 = add i64 %t74, 1
  store i64 %t89, i64* %t52
  %t90 = load i32, i32* %t4
  %t91 = add i32 %t90, 1
  store i32 %t91, i32* %t4
  br label %while_cond_2135
while_else_2137:
  br label %while_end_2138
while_end_2138:
  %t92 = load i8*, i8** %t3
  %t93 = icmp eq i8* %t92, null
  br i1 %t93, label %list_read_null_2156, label %list_read_real_2157
list_read_null_2156:
  br label %list_read_end_2158
list_read_real_2157:
  %t94 = bitcast i8* %t92 to { i8**, i64, i64 }*
  %t95 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t94, i32 0, i32 0
  %t96 = load i8**, i8*** %t95
  %t97 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t94, i32 0, i32 1
  %t98 = load i64, i64* %t97
  br label %list_read_end_2158
list_read_end_2158:
  %t99 = phi i8** [ null, %list_read_null_2156 ], [ %t96, %list_read_real_2157 ]
  %t100 = phi i64 [ 0, %list_read_null_2156 ], [ %t98, %list_read_real_2157 ]
  %t101 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.160, i64 0, i32 2, i64 0
  %t102 = icmp eq i8* %t101, null
  %t103 = select i1 %t102, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t101
  %t104 = call i32 @strlen(i8* %t103)
  %t105 = sext i32 %t104 to i64
  store i64 0, i64* %t106
  store i64 0, i64* %t107
  br label %join_sum_cond_2159
join_sum_cond_2159:
  %t108 = load i64, i64* %t107
  %t109 = icmp slt i64 %t108, %t100
  br i1 %t109, label %join_sum_body_2160, label %join_sum_done_2161
join_sum_body_2160:
  %t110 = getelementptr inbounds i8*, i8** %t99, i64 %t108
  %t111 = load i8*, i8** %t110
  %t112 = icmp eq i8* %t111, null
  %t113 = select i1 %t112, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t111
  %t114 = call i32 @strlen(i8* %t113)
  %t115 = sext i32 %t114 to i64
  %t116 = load i64, i64* %t106
  %t117 = add i64 %t116, %t115
  store i64 %t117, i64* %t106
  %t118 = add i64 %t108, 1
  store i64 %t118, i64* %t107
  br label %join_sum_cond_2159
join_sum_done_2161:
  %t119 = load i64, i64* %t106
  %t120 = icmp eq i64 %t100, 0
  %t121 = sub i64 %t100, 1
  %t122 = select i1 %t120, i64 0, i64 %t121
  %t123 = mul i64 %t122, %t105
  %t124 = add i64 %t119, %t123
  %t125 = add i64 %t124, 1
  %t126 = call i8* @star_rc_alloc(i64 %t125, i8* null)
  store i8* %t126, i8** %t127
  store i64 0, i64* %t128
  br label %join_build_cond_2162
join_build_cond_2162:
  %t129 = load i64, i64* %t128
  %t130 = icmp slt i64 %t129, %t100
  br i1 %t130, label %join_build_body_2163, label %join_build_done_2164
join_build_body_2163:
  %t131 = getelementptr inbounds i8*, i8** %t99, i64 %t129
  %t132 = load i8*, i8** %t131
  %t133 = icmp eq i8* %t132, null
  %t134 = select i1 %t133, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t132
  %t135 = call i32 @strlen(i8* %t134)
  %t136 = sext i32 %t135 to i64
  %t137 = load i8*, i8** %t127
  call i8* @memcpy(i8* %t137, i8* %t134, i64 %t136)
  %t138 = getelementptr inbounds i8, i8* %t137, i64 %t136
  %t139 = add i64 %t129, 1
  %t140 = icmp slt i64 %t139, %t100
  br i1 %t140, label %join_sep_2165, label %join_no_sep_2166
join_sep_2165:
  call i8* @memcpy(i8* %t138, i8* %t103, i64 %t105)
  %t141 = getelementptr inbounds i8, i8* %t138, i64 %t105
  br label %join_after_2167
join_no_sep_2166:
  br label %join_after_2167
join_after_2167:
  %t142 = phi i8* [ %t141, %join_sep_2165 ], [ %t138, %join_no_sep_2166 ]
  store i8* %t142, i8** %t127
  store i64 %t139, i64* %t128
  br label %join_build_cond_2162
join_build_done_2164:
  %t143 = load i8*, i8** %t127
  store i8 0, i8* %t143
  call void @star_rc_release(i8* %t101)
  %t144 = load i8*, i8** %t3
  call void @star_rc_release(i8* %t144)
  ret i8* %t126
}

define void @lex__Lexer__fail(%lex__Lexer* %self, i8* %message, i32 %line, i32 %column) {
entry:
  %t0 = alloca %lex__Lexer*
  %t1 = alloca i8*
  %t2 = alloca i32
  %t3 = alloca i32
  store %lex__Lexer* %self, %lex__Lexer** %t0
  store i8* %message, i8** %t1
  store i32 %line, i32* %t2
  store i32 %column, i32* %t3
  %t4 = load %lex__Lexer*, %lex__Lexer** %t0
  %t5 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t4, i32 0, i32 10
  %t6 = load i1, i1* %t5
  %t7 = xor i1 true, %t6
  br i1 %t7, label %if_then_2168, label %if_else_2169
if_then_2168:
  %t8 = load %lex__Lexer*, %lex__Lexer** %t0
  %t9 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t8, i32 0, i32 10
  store i1 true, i1* %t9
  %t10 = load i8*, i8** %t1
  %t11 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t11)
  %t12 = load %lex__Lexer*, %lex__Lexer** %t0
  %t13 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t12, i32 0, i32 11
  %t14 = load i8*, i8** %t13
  call void @star_rc_release(i8* %t14)
  store i8* %t10, i8** %t13
  %t15 = load i32, i32* %t2
  %t16 = load %lex__Lexer*, %lex__Lexer** %t0
  %t17 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t16, i32 0, i32 12
  store i32 %t15, i32* %t17
  %t18 = load i32, i32* %t3
  %t19 = load %lex__Lexer*, %lex__Lexer** %t0
  %t20 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t19, i32 0, i32 13
  store i32 %t18, i32* %t20
  br label %if_end_2170
if_else_2169:
  br label %if_end_2170
if_end_2170:
  %t21 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t21)
  ret void
}

define i8* @lex__Lexer__current_lexeme(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  store %lex__Lexer* %self, %lex__Lexer** %t0
  %t1 = load %lex__Lexer*, %lex__Lexer** %t0
  %t2 = load %lex__Lexer*, %lex__Lexer** %t0
  %t3 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 6
  %t4 = load i32, i32* %t3
  %t5 = load %lex__Lexer*, %lex__Lexer** %t0
  %t6 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t5, i32 0, i32 3
  %t7 = load i32, i32* %t6
  %t8 = call i8* @lex__Lexer__substr(%lex__Lexer* %t1, i32 %t4, i32 %t7)
  ret i8* %t8
}

define void @lex__Lexer__add_token_plain(%lex__Lexer* %self, i32 %kind) {
entry:
  %t0 = alloca %lex__Lexer*
  %t1 = alloca i32
  %t2 = alloca i8*
  %t52 = alloca i64
  %t71 = alloca %lex__tok__Token
  store %lex__Lexer* %self, %lex__Lexer** %t0
  store i32 %kind, i32* %t1
  %t3 = load %lex__Lexer*, %lex__Lexer** %t0
  %t4 = call i8* @lex__Lexer__current_lexeme(%lex__Lexer* %t3)
  store i8* %t4, i8** %t2
  %t5 = load %lex__Lexer*, %lex__Lexer** %t0
  %t6 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t5, i32 0, i32 9
  %t7 = getelementptr %lex__tok__Token, %lex__tok__Token* null, i32 1
  %t8 = ptrtoint %lex__tok__Token* %t7 to i64
  %t9 = load i8*, i8** %t6
  %t10 = icmp eq i8* %t9, null
  br i1 %t10, label %list_cow_alloc_2171, label %list_cow_check_2172
list_cow_alloc_2171:
  %t26 = bitcast void (i8*)* @list_release_s_lex__tok__Token to i8*
  %t27 = call i8* @star_rc_alloc(i64 24, i8* %t26)
  %t28 = bitcast i8* %t27 to { %lex__tok__Token*, i64, i64 }*
  %t29 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t28, i32 0, i32 0
  store %lex__tok__Token* null, %lex__tok__Token** %t29
  %t30 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t28, i32 0, i32 1
  store i64 0, i64* %t30
  %t31 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t28, i32 0, i32 2
  store i64 0, i64* %t31
  store i8* %t27, i8** %t6
  br label %list_cow_done_2173
list_cow_check_2172:
  %t32 = getelementptr inbounds i8, i8* %t9, i64 -16
  %t33 = bitcast i8* %t32 to i64*
  %t34 = load atomic i64, i64* %t33 seq_cst, align 8
  %t35 = icmp eq i64 %t34, 1
  br i1 %t35, label %list_cow_done_2173, label %list_cow_clone_2177
list_cow_clone_2177:
  %t36 = bitcast i8* %t9 to { %lex__tok__Token*, i64, i64 }*
  %t37 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t36, i32 0, i32 0
  %t38 = load %lex__tok__Token*, %lex__tok__Token** %t37
  %t39 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t36, i32 0, i32 1
  %t40 = load i64, i64* %t39
  %t41 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t36, i32 0, i32 2
  %t42 = load i64, i64* %t41
  %t43 = bitcast void (i8*)* @list_release_s_lex__tok__Token to i8*
  %t44 = call i8* @star_rc_alloc(i64 24, i8* %t43)
  %t45 = bitcast i8* %t44 to { %lex__tok__Token*, i64, i64 }*
  %t46 = mul i64 %t42, %t8
  %t47 = call i8* @malloc(i64 %t46)
  %t48 = bitcast i8* %t47 to %lex__tok__Token*
  %t49 = icmp sgt i64 %t40, 0
  br i1 %t49, label %list_cow_copy_2178, label %list_cow_after_copy_2179
list_cow_copy_2178:
  %t50 = mul i64 %t40, %t8
  %t51 = bitcast %lex__tok__Token* %t38 to i8*
  call i8* @memcpy(i8* %t47, i8* %t51, i64 %t50)
  store i64 0, i64* %t52
  br label %list_cow_retain_cond_2180
list_cow_retain_cond_2180:
  %t53 = load i64, i64* %t52
  %t54 = icmp slt i64 %t53, %t40
  br i1 %t54, label %list_cow_retain_body_2181, label %list_cow_retain_end_2182
list_cow_retain_body_2181:
  %t55 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t48, i64 %t53
  %t56 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t55, i32 0, i32 1
  %t57 = load i8*, i8** %t56
  call void @star_rc_retain(i8* %t57)
  %t58 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t55, i32 0, i32 4
  %t59 = load i8*, i8** %t58
  call void @star_rc_retain(i8* %t59)
  %t60 = add i64 %t53, 1
  store i64 %t60, i64* %t52
  br label %list_cow_retain_cond_2180
list_cow_retain_end_2182:
  br label %list_cow_after_copy_2179
list_cow_after_copy_2179:
  %t61 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t45, i32 0, i32 0
  store %lex__tok__Token* %t48, %lex__tok__Token** %t61
  %t62 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t45, i32 0, i32 1
  store i64 %t40, i64* %t62
  %t63 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t45, i32 0, i32 2
  store i64 %t42, i64* %t63
  call void @star_rc_release(i8* %t9)
  store i8* %t44, i8** %t6
  br label %list_cow_done_2173
list_cow_done_2173:
  %t64 = load i8*, i8** %t6
  %t65 = bitcast i8* %t64 to { %lex__tok__Token*, i64, i64 }*
  %t66 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t65, i32 0, i32 0
  %t67 = load %lex__tok__Token*, %lex__tok__Token** %t66
  %t68 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t65, i32 0, i32 1
  %t69 = load i64, i64* %t68
  %t70 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t65, i32 0, i32 2
  %t72 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t71, i32 0, i32 0
  %t73 = load i32, i32* %t1
  store i32 %t73, i32* %t72
  %t74 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t71, i32 0, i32 1
  %t75 = load i8*, i8** %t2
  %t76 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t76)
  store i8* %t75, i8** %t74
  %t77 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t71, i32 0, i32 2
  %t78 = sitofp i32 0 to double
  store double %t78, double* %t77
  %t79 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t71, i32 0, i32 3
  store i1 false, i1* %t79
  %t80 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t71, i32 0, i32 4
  %t81 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.161, i64 0, i32 2, i64 0
  store i8* %t81, i8** %t80
  %t82 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t71, i32 0, i32 5
  %t83 = load %lex__Lexer*, %lex__Lexer** %t0
  %t84 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t83, i32 0, i32 7
  %t85 = load i32, i32* %t84
  store i32 %t85, i32* %t82
  %t86 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t71, i32 0, i32 6
  %t87 = load %lex__Lexer*, %lex__Lexer** %t0
  %t88 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t87, i32 0, i32 8
  %t89 = load i32, i32* %t88
  store i32 %t89, i32* %t86
  %t90 = load %lex__tok__Token, %lex__tok__Token* %t71
  %t91 = load i64, i64* %t70
  %t92 = load %lex__tok__Token*, %lex__tok__Token** %t66
  %t93 = load i64, i64* %t68
  %t94 = icmp sge i64 %t93, %t91
  br i1 %t94, label %list_push_grow_2183, label %list_push_store_2184
list_push_grow_2183:
  %t95 = mul i64 %t91, 2
  %t96 = icmp sgt i64 %t95, 0
  %t97 = select i1 %t96, i64 %t95, i64 1
  %t98 = getelementptr %lex__tok__Token, %lex__tok__Token* null, i32 1
  %t99 = ptrtoint %lex__tok__Token* %t98 to i64
  %t100 = mul i64 %t97, %t99
  %t101 = call i8* @malloc(i64 %t100)
  %t102 = bitcast i8* %t101 to %lex__tok__Token*
  %t103 = icmp sgt i64 %t91, 0
  br i1 %t103, label %list_push_copy_2185, label %list_push_after_copy_2186
list_push_copy_2185:
  %t104 = mul i64 %t93, %t99
  %t105 = bitcast %lex__tok__Token* %t92 to i8*
  call i8* @memcpy(i8* %t101, i8* %t105, i64 %t104)
  call void @free(i8* %t105)
  br label %list_push_after_copy_2186
list_push_after_copy_2186:
  store %lex__tok__Token* %t102, %lex__tok__Token** %t66
  store i64 %t97, i64* %t70
  br label %list_push_store_2184
list_push_store_2184:
  %t106 = load %lex__tok__Token*, %lex__tok__Token** %t66
  %t107 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t106, i64 %t93
  store %lex__tok__Token %t90, %lex__tok__Token* %t107
  %t108 = add i64 %t93, 1
  store i64 %t108, i64* %t68
  %t109 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t109)
  ret void
}

define void @lex__Lexer__add_token_num(%lex__Lexer* %self, i32 %kind, double %num_value, i1 %is_float) {
entry:
  %t0 = alloca %lex__Lexer*
  %t1 = alloca i32
  %t2 = alloca double
  %t3 = alloca i1
  %t4 = alloca i8*
  %t39 = alloca i64
  %t58 = alloca %lex__tok__Token
  store %lex__Lexer* %self, %lex__Lexer** %t0
  store i32 %kind, i32* %t1
  store double %num_value, double* %t2
  store i1 %is_float, i1* %t3
  %t5 = load %lex__Lexer*, %lex__Lexer** %t0
  %t6 = call i8* @lex__Lexer__current_lexeme(%lex__Lexer* %t5)
  store i8* %t6, i8** %t4
  %t7 = load %lex__Lexer*, %lex__Lexer** %t0
  %t8 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t7, i32 0, i32 9
  %t9 = getelementptr %lex__tok__Token, %lex__tok__Token* null, i32 1
  %t10 = ptrtoint %lex__tok__Token* %t9 to i64
  %t11 = load i8*, i8** %t8
  %t12 = icmp eq i8* %t11, null
  br i1 %t12, label %list_cow_alloc_2187, label %list_cow_check_2188
list_cow_alloc_2187:
  %t13 = bitcast void (i8*)* @list_release_s_lex__tok__Token to i8*
  %t14 = call i8* @star_rc_alloc(i64 24, i8* %t13)
  %t15 = bitcast i8* %t14 to { %lex__tok__Token*, i64, i64 }*
  %t16 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t15, i32 0, i32 0
  store %lex__tok__Token* null, %lex__tok__Token** %t16
  %t17 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t15, i32 0, i32 1
  store i64 0, i64* %t17
  %t18 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t15, i32 0, i32 2
  store i64 0, i64* %t18
  store i8* %t14, i8** %t8
  br label %list_cow_done_2189
list_cow_check_2188:
  %t19 = getelementptr inbounds i8, i8* %t11, i64 -16
  %t20 = bitcast i8* %t19 to i64*
  %t21 = load atomic i64, i64* %t20 seq_cst, align 8
  %t22 = icmp eq i64 %t21, 1
  br i1 %t22, label %list_cow_done_2189, label %list_cow_clone_2190
list_cow_clone_2190:
  %t23 = bitcast i8* %t11 to { %lex__tok__Token*, i64, i64 }*
  %t24 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t23, i32 0, i32 0
  %t25 = load %lex__tok__Token*, %lex__tok__Token** %t24
  %t26 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t23, i32 0, i32 1
  %t27 = load i64, i64* %t26
  %t28 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t23, i32 0, i32 2
  %t29 = load i64, i64* %t28
  %t30 = bitcast void (i8*)* @list_release_s_lex__tok__Token to i8*
  %t31 = call i8* @star_rc_alloc(i64 24, i8* %t30)
  %t32 = bitcast i8* %t31 to { %lex__tok__Token*, i64, i64 }*
  %t33 = mul i64 %t29, %t10
  %t34 = call i8* @malloc(i64 %t33)
  %t35 = bitcast i8* %t34 to %lex__tok__Token*
  %t36 = icmp sgt i64 %t27, 0
  br i1 %t36, label %list_cow_copy_2191, label %list_cow_after_copy_2192
list_cow_copy_2191:
  %t37 = mul i64 %t27, %t10
  %t38 = bitcast %lex__tok__Token* %t25 to i8*
  call i8* @memcpy(i8* %t34, i8* %t38, i64 %t37)
  store i64 0, i64* %t39
  br label %list_cow_retain_cond_2193
list_cow_retain_cond_2193:
  %t40 = load i64, i64* %t39
  %t41 = icmp slt i64 %t40, %t27
  br i1 %t41, label %list_cow_retain_body_2194, label %list_cow_retain_end_2195
list_cow_retain_body_2194:
  %t42 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t35, i64 %t40
  %t43 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t42, i32 0, i32 1
  %t44 = load i8*, i8** %t43
  call void @star_rc_retain(i8* %t44)
  %t45 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t42, i32 0, i32 4
  %t46 = load i8*, i8** %t45
  call void @star_rc_retain(i8* %t46)
  %t47 = add i64 %t40, 1
  store i64 %t47, i64* %t39
  br label %list_cow_retain_cond_2193
list_cow_retain_end_2195:
  br label %list_cow_after_copy_2192
list_cow_after_copy_2192:
  %t48 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t32, i32 0, i32 0
  store %lex__tok__Token* %t35, %lex__tok__Token** %t48
  %t49 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t32, i32 0, i32 1
  store i64 %t27, i64* %t49
  %t50 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t32, i32 0, i32 2
  store i64 %t29, i64* %t50
  call void @star_rc_release(i8* %t11)
  store i8* %t31, i8** %t8
  br label %list_cow_done_2189
list_cow_done_2189:
  %t51 = load i8*, i8** %t8
  %t52 = bitcast i8* %t51 to { %lex__tok__Token*, i64, i64 }*
  %t53 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t52, i32 0, i32 0
  %t54 = load %lex__tok__Token*, %lex__tok__Token** %t53
  %t55 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t52, i32 0, i32 1
  %t56 = load i64, i64* %t55
  %t57 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t52, i32 0, i32 2
  %t59 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t58, i32 0, i32 0
  %t60 = load i32, i32* %t1
  store i32 %t60, i32* %t59
  %t61 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t58, i32 0, i32 1
  %t62 = load i8*, i8** %t4
  %t63 = load i8*, i8** %t4
  call void @star_rc_retain(i8* %t63)
  store i8* %t62, i8** %t61
  %t64 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t58, i32 0, i32 2
  %t65 = load double, double* %t2
  store double %t65, double* %t64
  %t66 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t58, i32 0, i32 3
  %t67 = load i1, i1* %t3
  store i1 %t67, i1* %t66
  %t68 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t58, i32 0, i32 4
  %t69 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.162, i64 0, i32 2, i64 0
  store i8* %t69, i8** %t68
  %t70 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t58, i32 0, i32 5
  %t71 = load %lex__Lexer*, %lex__Lexer** %t0
  %t72 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t71, i32 0, i32 7
  %t73 = load i32, i32* %t72
  store i32 %t73, i32* %t70
  %t74 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t58, i32 0, i32 6
  %t75 = load %lex__Lexer*, %lex__Lexer** %t0
  %t76 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t75, i32 0, i32 8
  %t77 = load i32, i32* %t76
  store i32 %t77, i32* %t74
  %t78 = load %lex__tok__Token, %lex__tok__Token* %t58
  %t79 = load i64, i64* %t57
  %t80 = load %lex__tok__Token*, %lex__tok__Token** %t53
  %t81 = load i64, i64* %t55
  %t82 = icmp sge i64 %t81, %t79
  br i1 %t82, label %list_push_grow_2196, label %list_push_store_2197
list_push_grow_2196:
  %t83 = mul i64 %t79, 2
  %t84 = icmp sgt i64 %t83, 0
  %t85 = select i1 %t84, i64 %t83, i64 1
  %t86 = getelementptr %lex__tok__Token, %lex__tok__Token* null, i32 1
  %t87 = ptrtoint %lex__tok__Token* %t86 to i64
  %t88 = mul i64 %t85, %t87
  %t89 = call i8* @malloc(i64 %t88)
  %t90 = bitcast i8* %t89 to %lex__tok__Token*
  %t91 = icmp sgt i64 %t79, 0
  br i1 %t91, label %list_push_copy_2198, label %list_push_after_copy_2199
list_push_copy_2198:
  %t92 = mul i64 %t81, %t87
  %t93 = bitcast %lex__tok__Token* %t80 to i8*
  call i8* @memcpy(i8* %t89, i8* %t93, i64 %t92)
  call void @free(i8* %t93)
  br label %list_push_after_copy_2199
list_push_after_copy_2199:
  store %lex__tok__Token* %t90, %lex__tok__Token** %t53
  store i64 %t85, i64* %t57
  br label %list_push_store_2197
list_push_store_2197:
  %t94 = load %lex__tok__Token*, %lex__tok__Token** %t53
  %t95 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t94, i64 %t81
  store %lex__tok__Token %t78, %lex__tok__Token* %t95
  %t96 = add i64 %t81, 1
  store i64 %t96, i64* %t55
  %t97 = load i8*, i8** %t4
  call void @star_rc_release(i8* %t97)
  ret void
}

define void @lex__Lexer__add_token_str(%lex__Lexer* %self, i32 %kind, i8* %str_value) {
entry:
  %t0 = alloca %lex__Lexer*
  %t1 = alloca i32
  %t2 = alloca i8*
  %t3 = alloca i8*
  %t38 = alloca i64
  %t57 = alloca %lex__tok__Token
  store %lex__Lexer* %self, %lex__Lexer** %t0
  store i32 %kind, i32* %t1
  store i8* %str_value, i8** %t2
  %t4 = load %lex__Lexer*, %lex__Lexer** %t0
  %t5 = call i8* @lex__Lexer__current_lexeme(%lex__Lexer* %t4)
  store i8* %t5, i8** %t3
  %t6 = load %lex__Lexer*, %lex__Lexer** %t0
  %t7 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t6, i32 0, i32 9
  %t8 = getelementptr %lex__tok__Token, %lex__tok__Token* null, i32 1
  %t9 = ptrtoint %lex__tok__Token* %t8 to i64
  %t10 = load i8*, i8** %t7
  %t11 = icmp eq i8* %t10, null
  br i1 %t11, label %list_cow_alloc_2200, label %list_cow_check_2201
list_cow_alloc_2200:
  %t12 = bitcast void (i8*)* @list_release_s_lex__tok__Token to i8*
  %t13 = call i8* @star_rc_alloc(i64 24, i8* %t12)
  %t14 = bitcast i8* %t13 to { %lex__tok__Token*, i64, i64 }*
  %t15 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t14, i32 0, i32 0
  store %lex__tok__Token* null, %lex__tok__Token** %t15
  %t16 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t14, i32 0, i32 1
  store i64 0, i64* %t16
  %t17 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t14, i32 0, i32 2
  store i64 0, i64* %t17
  store i8* %t13, i8** %t7
  br label %list_cow_done_2202
list_cow_check_2201:
  %t18 = getelementptr inbounds i8, i8* %t10, i64 -16
  %t19 = bitcast i8* %t18 to i64*
  %t20 = load atomic i64, i64* %t19 seq_cst, align 8
  %t21 = icmp eq i64 %t20, 1
  br i1 %t21, label %list_cow_done_2202, label %list_cow_clone_2203
list_cow_clone_2203:
  %t22 = bitcast i8* %t10 to { %lex__tok__Token*, i64, i64 }*
  %t23 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t22, i32 0, i32 0
  %t24 = load %lex__tok__Token*, %lex__tok__Token** %t23
  %t25 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t22, i32 0, i32 1
  %t26 = load i64, i64* %t25
  %t27 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t22, i32 0, i32 2
  %t28 = load i64, i64* %t27
  %t29 = bitcast void (i8*)* @list_release_s_lex__tok__Token to i8*
  %t30 = call i8* @star_rc_alloc(i64 24, i8* %t29)
  %t31 = bitcast i8* %t30 to { %lex__tok__Token*, i64, i64 }*
  %t32 = mul i64 %t28, %t9
  %t33 = call i8* @malloc(i64 %t32)
  %t34 = bitcast i8* %t33 to %lex__tok__Token*
  %t35 = icmp sgt i64 %t26, 0
  br i1 %t35, label %list_cow_copy_2204, label %list_cow_after_copy_2205
list_cow_copy_2204:
  %t36 = mul i64 %t26, %t9
  %t37 = bitcast %lex__tok__Token* %t24 to i8*
  call i8* @memcpy(i8* %t33, i8* %t37, i64 %t36)
  store i64 0, i64* %t38
  br label %list_cow_retain_cond_2206
list_cow_retain_cond_2206:
  %t39 = load i64, i64* %t38
  %t40 = icmp slt i64 %t39, %t26
  br i1 %t40, label %list_cow_retain_body_2207, label %list_cow_retain_end_2208
list_cow_retain_body_2207:
  %t41 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t34, i64 %t39
  %t42 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t41, i32 0, i32 1
  %t43 = load i8*, i8** %t42
  call void @star_rc_retain(i8* %t43)
  %t44 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t41, i32 0, i32 4
  %t45 = load i8*, i8** %t44
  call void @star_rc_retain(i8* %t45)
  %t46 = add i64 %t39, 1
  store i64 %t46, i64* %t38
  br label %list_cow_retain_cond_2206
list_cow_retain_end_2208:
  br label %list_cow_after_copy_2205
list_cow_after_copy_2205:
  %t47 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t31, i32 0, i32 0
  store %lex__tok__Token* %t34, %lex__tok__Token** %t47
  %t48 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t31, i32 0, i32 1
  store i64 %t26, i64* %t48
  %t49 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t31, i32 0, i32 2
  store i64 %t28, i64* %t49
  call void @star_rc_release(i8* %t10)
  store i8* %t30, i8** %t7
  br label %list_cow_done_2202
list_cow_done_2202:
  %t50 = load i8*, i8** %t7
  %t51 = bitcast i8* %t50 to { %lex__tok__Token*, i64, i64 }*
  %t52 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t51, i32 0, i32 0
  %t53 = load %lex__tok__Token*, %lex__tok__Token** %t52
  %t54 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t51, i32 0, i32 1
  %t55 = load i64, i64* %t54
  %t56 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t51, i32 0, i32 2
  %t58 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t57, i32 0, i32 0
  %t59 = load i32, i32* %t1
  store i32 %t59, i32* %t58
  %t60 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t57, i32 0, i32 1
  %t61 = load i8*, i8** %t3
  %t62 = load i8*, i8** %t3
  call void @star_rc_retain(i8* %t62)
  store i8* %t61, i8** %t60
  %t63 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t57, i32 0, i32 2
  %t64 = sitofp i32 0 to double
  store double %t64, double* %t63
  %t65 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t57, i32 0, i32 3
  store i1 false, i1* %t65
  %t66 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t57, i32 0, i32 4
  %t67 = load i8*, i8** %t2
  %t68 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t68)
  store i8* %t67, i8** %t66
  %t69 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t57, i32 0, i32 5
  %t70 = load %lex__Lexer*, %lex__Lexer** %t0
  %t71 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t70, i32 0, i32 7
  %t72 = load i32, i32* %t71
  store i32 %t72, i32* %t69
  %t73 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t57, i32 0, i32 6
  %t74 = load %lex__Lexer*, %lex__Lexer** %t0
  %t75 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t74, i32 0, i32 8
  %t76 = load i32, i32* %t75
  store i32 %t76, i32* %t73
  %t77 = load %lex__tok__Token, %lex__tok__Token* %t57
  %t78 = load i64, i64* %t56
  %t79 = load %lex__tok__Token*, %lex__tok__Token** %t52
  %t80 = load i64, i64* %t54
  %t81 = icmp sge i64 %t80, %t78
  br i1 %t81, label %list_push_grow_2209, label %list_push_store_2210
list_push_grow_2209:
  %t82 = mul i64 %t78, 2
  %t83 = icmp sgt i64 %t82, 0
  %t84 = select i1 %t83, i64 %t82, i64 1
  %t85 = getelementptr %lex__tok__Token, %lex__tok__Token* null, i32 1
  %t86 = ptrtoint %lex__tok__Token* %t85 to i64
  %t87 = mul i64 %t84, %t86
  %t88 = call i8* @malloc(i64 %t87)
  %t89 = bitcast i8* %t88 to %lex__tok__Token*
  %t90 = icmp sgt i64 %t78, 0
  br i1 %t90, label %list_push_copy_2211, label %list_push_after_copy_2212
list_push_copy_2211:
  %t91 = mul i64 %t80, %t86
  %t92 = bitcast %lex__tok__Token* %t79 to i8*
  call i8* @memcpy(i8* %t88, i8* %t92, i64 %t91)
  call void @free(i8* %t92)
  br label %list_push_after_copy_2212
list_push_after_copy_2212:
  store %lex__tok__Token* %t89, %lex__tok__Token** %t52
  store i64 %t84, i64* %t56
  br label %list_push_store_2210
list_push_store_2210:
  %t93 = load %lex__tok__Token*, %lex__tok__Token** %t52
  %t94 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t93, i64 %t80
  store %lex__tok__Token %t77, %lex__tok__Token* %t94
  %t95 = add i64 %t80, 1
  store i64 %t95, i64* %t54
  %t96 = load i8*, i8** %t3
  call void @star_rc_release(i8* %t96)
  %t97 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t97)
  ret void
}

define void @lex__Lexer__scan_number(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  %t22 = alloca i32
  %t30 = alloca i32
  %t57 = alloca i8*
  %t64 = alloca i32
  %t77 = alloca i32
  %t108 = alloca i8*
  %t115 = alloca i32
  %t124 = alloca i1
  %t142 = alloca i8*
  store %lex__Lexer* %self, %lex__Lexer** %t0
  %t1 = load %lex__Lexer*, %lex__Lexer** %t0
  %t2 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t1, i32 0, i32 0
  %t3 = load i8*, i8** %t2
  %t4 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t4)
  %t5 = load %lex__Lexer*, %lex__Lexer** %t0
  %t6 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t5, i32 0, i32 6
  %t7 = load i32, i32* %t6
  %t8 = sext i32 %t7 to i64
  %t9 = icmp eq i8* %t3, null
  br i1 %t9, label %str_idx_oob_2215, label %str_idx_chk_2213
str_idx_chk_2213:
  %t10 = call i32 @strlen(i8* %t3)
  %t11 = sext i32 %t10 to i64
  %t12 = icmp ult i64 %t8, %t11
  br i1 %t12, label %str_idx_ok_2214, label %str_idx_oob_2215
str_idx_ok_2214:
  %t13 = getelementptr inbounds i8, i8* %t3, i64 %t8
  %t14 = load i8, i8* %t13
  %t15 = zext i8 %t14 to i32
  br label %str_idx_end_2216
str_idx_oob_2215:
  br label %str_idx_end_2216
str_idx_end_2216:
  %t16 = phi i32 [ %t15, %str_idx_ok_2214 ], [ 0, %str_idx_oob_2215 ]
  call void @star_rc_release(i8* %t3)
  %t17 = icmp eq i32 %t16, 48
  br i1 %t17, label %logic_rhs_2217, label %logic_short_2218
logic_rhs_2217:
  %t18 = load %lex__Lexer*, %lex__Lexer** %t0
  %t19 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t18)
  %t20 = xor i1 true, %t19
  br label %logic_end_2219
logic_short_2218:
  br label %logic_end_2219
logic_end_2219:
  %t21 = phi i1 [ %t20, %logic_rhs_2217 ], [ false, %logic_short_2218 ]
  br i1 %t21, label %if_then_2220, label %if_else_2221
if_then_2220:
  %t23 = load %lex__Lexer*, %lex__Lexer** %t0
  %t24 = call i32 @lex__Lexer__peek(%lex__Lexer* %t23)
  %t25 = call i32 @lex__to_lower_byte(i32 %t24)
  store i32 %t25, i32* %t22
  %t26 = load i32, i32* %t22
  %t27 = icmp eq i32 %t26, 120
  br i1 %t27, label %if_then_2223, label %if_else_2224
if_then_2223:
  %t28 = load %lex__Lexer*, %lex__Lexer** %t0
  %t29 = call i32 @lex__Lexer__advance(%lex__Lexer* %t28)
  %t31 = load %lex__Lexer*, %lex__Lexer** %t0
  %t32 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t31, i32 0, i32 3
  %t33 = load i32, i32* %t32
  store i32 %t33, i32* %t30
  br label %while_cond_2226
while_cond_2226:
  %t34 = load %lex__Lexer*, %lex__Lexer** %t0
  %t35 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t34)
  %t36 = xor i1 true, %t35
  br i1 %t36, label %logic_rhs_2230, label %logic_short_2231
logic_rhs_2230:
  %t37 = load %lex__Lexer*, %lex__Lexer** %t0
  %t38 = call i32 @lex__Lexer__peek(%lex__Lexer* %t37)
  %t39 = call i1 @lex__is_hex_digit_byte(i32 %t38)
  br label %logic_end_2232
logic_short_2231:
  br label %logic_end_2232
logic_end_2232:
  %t40 = phi i1 [ %t39, %logic_rhs_2230 ], [ false, %logic_short_2231 ]
  br i1 %t40, label %while_body_2227, label %while_else_2228
while_body_2227:
  %t41 = load %lex__Lexer*, %lex__Lexer** %t0
  %t42 = call i32 @lex__Lexer__advance(%lex__Lexer* %t41)
  br label %while_cond_2226
while_else_2228:
  br label %while_end_2229
while_end_2229:
  %t43 = load %lex__Lexer*, %lex__Lexer** %t0
  %t44 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t43, i32 0, i32 3
  %t45 = load i32, i32* %t44
  %t46 = load i32, i32* %t30
  %t47 = icmp eq i32 %t45, %t46
  br i1 %t47, label %if_then_2233, label %if_else_2234
if_then_2233:
  %t48 = load %lex__Lexer*, %lex__Lexer** %t0
  %t49 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.163, i64 0, i32 2, i64 0
  %t50 = load %lex__Lexer*, %lex__Lexer** %t0
  %t51 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t50, i32 0, i32 4
  %t52 = load i32, i32* %t51
  %t53 = load %lex__Lexer*, %lex__Lexer** %t0
  %t54 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t53, i32 0, i32 5
  %t55 = load i32, i32* %t54
  call void @lex__Lexer__fail(%lex__Lexer* %t48, i8* %t49, i32 %t52, i32 %t55)
  ret void
if_else_2234:
  br label %if_end_2235
if_end_2235:
  %t58 = load %lex__Lexer*, %lex__Lexer** %t0
  %t59 = load i32, i32* %t30
  %t60 = load %lex__Lexer*, %lex__Lexer** %t0
  %t61 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t60, i32 0, i32 3
  %t62 = load i32, i32* %t61
  %t63 = call i8* @lex__Lexer__substr(%lex__Lexer* %t58, i32 %t59, i32 %t62)
  store i8* %t63, i8** %t57
  %t65 = load i8*, i8** %t57
  %t66 = load i8*, i8** %t57
  call void @star_rc_retain(i8* %t66)
  %t67 = call i32 @strtol(i8* %t65, i8* null, i32 16)
  call void @star_rc_release(i8* %t65)
  store i32 %t67, i32* %t64
  %t68 = load %lex__Lexer*, %lex__Lexer** %t0
  %t69 = load i32, i32* %t64
  %t70 = sitofp i32 %t69 to double
  call void @lex__Lexer__add_token_num(%lex__Lexer* %t68, i32 95, double %t70, i1 false)
  %t72 = load i8*, i8** %t57
  call void @star_rc_release(i8* %t72)
  ret void
if_else_2224:
  %t73 = load i32, i32* %t22
  %t74 = icmp eq i32 %t73, 98
  br i1 %t74, label %if_then_2236, label %if_else_2237
if_then_2236:
  %t75 = load %lex__Lexer*, %lex__Lexer** %t0
  %t76 = call i32 @lex__Lexer__advance(%lex__Lexer* %t75)
  %t78 = load %lex__Lexer*, %lex__Lexer** %t0
  %t79 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t78, i32 0, i32 3
  %t80 = load i32, i32* %t79
  store i32 %t80, i32* %t77
  br label %while_cond_2239
while_cond_2239:
  %t81 = load %lex__Lexer*, %lex__Lexer** %t0
  %t82 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t81)
  %t83 = xor i1 true, %t82
  br i1 %t83, label %logic_rhs_2243, label %logic_short_2244
logic_rhs_2243:
  %t84 = load %lex__Lexer*, %lex__Lexer** %t0
  %t85 = call i32 @lex__Lexer__peek(%lex__Lexer* %t84)
  %t86 = icmp eq i32 %t85, 48
  br i1 %t86, label %logic_short_2247, label %logic_rhs_2246
logic_rhs_2246:
  %t87 = load %lex__Lexer*, %lex__Lexer** %t0
  %t88 = call i32 @lex__Lexer__peek(%lex__Lexer* %t87)
  %t89 = icmp eq i32 %t88, 49
  br label %logic_end_2248
logic_short_2247:
  br label %logic_end_2248
logic_end_2248:
  %t90 = phi i1 [ %t89, %logic_rhs_2246 ], [ true, %logic_short_2247 ]
  br label %logic_end_2245
logic_short_2244:
  br label %logic_end_2245
logic_end_2245:
  %t91 = phi i1 [ %t90, %logic_end_2248 ], [ false, %logic_short_2244 ]
  br i1 %t91, label %while_body_2240, label %while_else_2241
while_body_2240:
  %t92 = load %lex__Lexer*, %lex__Lexer** %t0
  %t93 = call i32 @lex__Lexer__advance(%lex__Lexer* %t92)
  br label %while_cond_2239
while_else_2241:
  br label %while_end_2242
while_end_2242:
  %t94 = load %lex__Lexer*, %lex__Lexer** %t0
  %t95 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t94, i32 0, i32 3
  %t96 = load i32, i32* %t95
  %t97 = load i32, i32* %t77
  %t98 = icmp eq i32 %t96, %t97
  br i1 %t98, label %if_then_2249, label %if_else_2250
if_then_2249:
  %t99 = load %lex__Lexer*, %lex__Lexer** %t0
  %t100 = getelementptr inbounds { i64, i8*, [22 x i8] }, { i64, i8*, [22 x i8] }* @.str.164, i64 0, i32 2, i64 0
  %t101 = load %lex__Lexer*, %lex__Lexer** %t0
  %t102 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t101, i32 0, i32 4
  %t103 = load i32, i32* %t102
  %t104 = load %lex__Lexer*, %lex__Lexer** %t0
  %t105 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t104, i32 0, i32 5
  %t106 = load i32, i32* %t105
  call void @lex__Lexer__fail(%lex__Lexer* %t99, i8* %t100, i32 %t103, i32 %t106)
  ret void
if_else_2250:
  br label %if_end_2251
if_end_2251:
  %t109 = load %lex__Lexer*, %lex__Lexer** %t0
  %t110 = load i32, i32* %t77
  %t111 = load %lex__Lexer*, %lex__Lexer** %t0
  %t112 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t111, i32 0, i32 3
  %t113 = load i32, i32* %t112
  %t114 = call i8* @lex__Lexer__substr(%lex__Lexer* %t109, i32 %t110, i32 %t113)
  store i8* %t114, i8** %t108
  %t116 = load i8*, i8** %t108
  %t117 = load i8*, i8** %t108
  call void @star_rc_retain(i8* %t117)
  %t118 = call i32 @strtol(i8* %t116, i8* null, i32 2)
  call void @star_rc_release(i8* %t116)
  store i32 %t118, i32* %t115
  %t119 = load %lex__Lexer*, %lex__Lexer** %t0
  %t120 = load i32, i32* %t115
  %t121 = sitofp i32 %t120 to double
  call void @lex__Lexer__add_token_num(%lex__Lexer* %t119, i32 95, double %t121, i1 false)
  %t123 = load i8*, i8** %t108
  call void @star_rc_release(i8* %t123)
  ret void
if_else_2237:
  br label %if_end_2238
if_end_2238:
  br label %if_end_2225
if_end_2225:
  br label %if_end_2222
if_else_2221:
  br label %if_end_2222
if_end_2222:
  store i1 false, i1* %t124
  br label %while_cond_2252
while_cond_2252:
  %t125 = load %lex__Lexer*, %lex__Lexer** %t0
  %t126 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t125)
  %t127 = xor i1 true, %t126
  br i1 %t127, label %logic_rhs_2256, label %logic_short_2257
logic_rhs_2256:
  %t128 = load %lex__Lexer*, %lex__Lexer** %t0
  %t129 = call i32 @lex__Lexer__peek(%lex__Lexer* %t128)
  %t130 = call i1 @lex__is_digit_byte(i32 %t129)
  br i1 %t130, label %logic_short_2260, label %logic_rhs_2259
logic_rhs_2259:
  %t131 = load %lex__Lexer*, %lex__Lexer** %t0
  %t132 = call i32 @lex__Lexer__peek(%lex__Lexer* %t131)
  %t133 = icmp eq i32 %t132, 46
  br label %logic_end_2261
logic_short_2260:
  br label %logic_end_2261
logic_end_2261:
  %t134 = phi i1 [ %t133, %logic_rhs_2259 ], [ true, %logic_short_2260 ]
  br label %logic_end_2258
logic_short_2257:
  br label %logic_end_2258
logic_end_2258:
  %t135 = phi i1 [ %t134, %logic_end_2261 ], [ false, %logic_short_2257 ]
  br i1 %t135, label %while_body_2253, label %while_else_2254
while_body_2253:
  %t136 = load %lex__Lexer*, %lex__Lexer** %t0
  %t137 = call i32 @lex__Lexer__peek(%lex__Lexer* %t136)
  %t138 = icmp eq i32 %t137, 46
  br i1 %t138, label %if_then_2262, label %if_else_2263
if_then_2262:
  %t139 = load i1, i1* %t124
  br i1 %t139, label %if_then_2265, label %if_else_2266
if_then_2265:
  br label %while_end_2255
if_else_2266:
  br label %if_end_2267
if_end_2267:
  store i1 true, i1* %t124
  br label %if_end_2264
if_else_2263:
  br label %if_end_2264
if_end_2264:
  %t140 = load %lex__Lexer*, %lex__Lexer** %t0
  %t141 = call i32 @lex__Lexer__advance(%lex__Lexer* %t140)
  br label %while_cond_2252
while_else_2254:
  br label %while_end_2255
while_end_2255:
  %t143 = load %lex__Lexer*, %lex__Lexer** %t0
  %t144 = load %lex__Lexer*, %lex__Lexer** %t0
  %t145 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t144, i32 0, i32 6
  %t146 = load i32, i32* %t145
  %t147 = load %lex__Lexer*, %lex__Lexer** %t0
  %t148 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t147, i32 0, i32 3
  %t149 = load i32, i32* %t148
  %t150 = call i8* @lex__Lexer__substr(%lex__Lexer* %t143, i32 %t146, i32 %t149)
  store i8* %t150, i8** %t142
  %t151 = load i1, i1* %t124
  br i1 %t151, label %if_then_2268, label %if_else_2269
if_then_2268:
  %t152 = load %lex__Lexer*, %lex__Lexer** %t0
  %t153 = load i8*, i8** %t142
  %t154 = load i8*, i8** %t142
  call void @star_rc_retain(i8* %t154)
  %t155 = call double @atof(i8* %t153)
  call void @star_rc_release(i8* %t153)
  call void @lex__Lexer__add_token_num(%lex__Lexer* %t152, i32 95, double %t155, i1 true)
  br label %if_end_2270
if_else_2269:
  %t157 = load %lex__Lexer*, %lex__Lexer** %t0
  %t158 = load i8*, i8** %t142
  %t159 = load i8*, i8** %t142
  call void @star_rc_retain(i8* %t159)
  %t160 = call i32 @atoi(i8* %t158)
  call void @star_rc_release(i8* %t158)
  %t161 = sitofp i32 %t160 to double
  call void @lex__Lexer__add_token_num(%lex__Lexer* %t157, i32 95, double %t161, i1 false)
  br label %if_end_2270
if_end_2270:
  %t163 = load i8*, i8** %t142
  call void @star_rc_release(i8* %t163)
  ret void
}

define void @lex__Lexer__scan_identifier(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  %t14 = alloca i8*
  %t18 = alloca i32
  store %lex__Lexer* %self, %lex__Lexer** %t0
  br label %while_cond_2271
while_cond_2271:
  %t1 = load %lex__Lexer*, %lex__Lexer** %t0
  %t2 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t1)
  %t3 = xor i1 true, %t2
  br i1 %t3, label %logic_rhs_2275, label %logic_short_2276
logic_rhs_2275:
  %t4 = load %lex__Lexer*, %lex__Lexer** %t0
  %t5 = call i32 @lex__Lexer__peek(%lex__Lexer* %t4)
  %t6 = call i1 @lex__is_alnum_byte(i32 %t5)
  br i1 %t6, label %logic_short_2279, label %logic_rhs_2278
logic_rhs_2278:
  %t7 = load %lex__Lexer*, %lex__Lexer** %t0
  %t8 = call i32 @lex__Lexer__peek(%lex__Lexer* %t7)
  %t9 = icmp eq i32 %t8, 95
  br label %logic_end_2280
logic_short_2279:
  br label %logic_end_2280
logic_end_2280:
  %t10 = phi i1 [ %t9, %logic_rhs_2278 ], [ true, %logic_short_2279 ]
  br label %logic_end_2277
logic_short_2276:
  br label %logic_end_2277
logic_end_2277:
  %t11 = phi i1 [ %t10, %logic_end_2280 ], [ false, %logic_short_2276 ]
  br i1 %t11, label %while_body_2272, label %while_else_2273
while_body_2272:
  %t12 = load %lex__Lexer*, %lex__Lexer** %t0
  %t13 = call i32 @lex__Lexer__advance(%lex__Lexer* %t12)
  br label %while_cond_2271
while_else_2273:
  br label %while_end_2274
while_end_2274:
  %t15 = load %lex__Lexer*, %lex__Lexer** %t0
  %t16 = call i8* @lex__Lexer__current_lexeme(%lex__Lexer* %t15)
  %t17 = call i8* @lex__str_lower(i8* %t16)
  store i8* %t17, i8** %t14
  %t19 = load %lex__Lexer*, %lex__Lexer** %t0
  %t20 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t19, i32 0, i32 2
  %t21 = load i8*, i8** %t20
  %t22 = load i8*, i8** %t20
  call void @star_rc_retain(i8* %t22)
  %t23 = load i8*, i8** %t14
  %t24 = load i8*, i8** %t14
  call void @star_rc_retain(i8* %t24)
  %t25 = call i32 @lex__tok__keyword_lookup(i8* %t21, i8* %t23)
  store i32 %t25, i32* %t18
  %t26 = load i32, i32* %t18
  %t28 = call i1 @eq_e_lex__tok__TokenType(i32 %t26, i32 42)
  br i1 %t28, label %if_then_2281, label %if_else_2282
if_then_2281:
  %t29 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__scan_asm_block(%lex__Lexer* %t29)
  br label %if_end_2283
if_else_2282:
  %t31 = load %lex__Lexer*, %lex__Lexer** %t0
  %t32 = load i32, i32* %t18
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t31, i32 %t32)
  br label %if_end_2283
if_end_2283:
  %t34 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t34)
  ret void
}

define void @lex__Lexer__scan_string(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  %t1 = alloca i32
  %t5 = alloca i8*
  %t9 = alloca i32
  %t29 = alloca i64
  %t30 = alloca i64
  %t50 = alloca i8*
  %t51 = alloca i64
  %t81 = alloca i32
  %t114 = alloca i64
  %t200 = alloca i64
  store %lex__Lexer* %self, %lex__Lexer** %t0
  %t2 = load %lex__Lexer*, %lex__Lexer** %t0
  %t3 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 4
  %t4 = load i32, i32* %t3
  store i32 %t4, i32* %t1
  store i8* null, i8** %t5
  br label %while_cond_2284
while_cond_2284:
  %t6 = load %lex__Lexer*, %lex__Lexer** %t0
  %t7 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t6)
  %t8 = xor i1 true, %t7
  br i1 %t8, label %while_body_2285, label %while_else_2286
while_body_2285:
  %t10 = load %lex__Lexer*, %lex__Lexer** %t0
  %t11 = call i32 @lex__Lexer__advance(%lex__Lexer* %t10)
  store i32 %t11, i32* %t9
  %t12 = load i32, i32* %t9
  %t13 = icmp eq i32 %t12, 34
  br i1 %t13, label %if_then_2288, label %if_else_2289
if_then_2288:
  %t14 = load %lex__Lexer*, %lex__Lexer** %t0
  %t15 = load i8*, i8** %t5
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %list_read_null_2291, label %list_read_real_2292
list_read_null_2291:
  br label %list_read_end_2293
list_read_real_2292:
  %t17 = bitcast i8* %t15 to { i8**, i64, i64 }*
  %t18 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t17, i32 0, i32 0
  %t19 = load i8**, i8*** %t18
  %t20 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t17, i32 0, i32 1
  %t21 = load i64, i64* %t20
  br label %list_read_end_2293
list_read_end_2293:
  %t22 = phi i8** [ null, %list_read_null_2291 ], [ %t19, %list_read_real_2292 ]
  %t23 = phi i64 [ 0, %list_read_null_2291 ], [ %t21, %list_read_real_2292 ]
  %t24 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.165, i64 0, i32 2, i64 0
  %t25 = icmp eq i8* %t24, null
  %t26 = select i1 %t25, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t24
  %t27 = call i32 @strlen(i8* %t26)
  %t28 = sext i32 %t27 to i64
  store i64 0, i64* %t29
  store i64 0, i64* %t30
  br label %join_sum_cond_2294
join_sum_cond_2294:
  %t31 = load i64, i64* %t30
  %t32 = icmp slt i64 %t31, %t23
  br i1 %t32, label %join_sum_body_2295, label %join_sum_done_2296
join_sum_body_2295:
  %t33 = getelementptr inbounds i8*, i8** %t22, i64 %t31
  %t34 = load i8*, i8** %t33
  %t35 = icmp eq i8* %t34, null
  %t36 = select i1 %t35, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t34
  %t37 = call i32 @strlen(i8* %t36)
  %t38 = sext i32 %t37 to i64
  %t39 = load i64, i64* %t29
  %t40 = add i64 %t39, %t38
  store i64 %t40, i64* %t29
  %t41 = add i64 %t31, 1
  store i64 %t41, i64* %t30
  br label %join_sum_cond_2294
join_sum_done_2296:
  %t42 = load i64, i64* %t29
  %t43 = icmp eq i64 %t23, 0
  %t44 = sub i64 %t23, 1
  %t45 = select i1 %t43, i64 0, i64 %t44
  %t46 = mul i64 %t45, %t28
  %t47 = add i64 %t42, %t46
  %t48 = add i64 %t47, 1
  %t49 = call i8* @star_rc_alloc(i64 %t48, i8* null)
  store i8* %t49, i8** %t50
  store i64 0, i64* %t51
  br label %join_build_cond_2297
join_build_cond_2297:
  %t52 = load i64, i64* %t51
  %t53 = icmp slt i64 %t52, %t23
  br i1 %t53, label %join_build_body_2298, label %join_build_done_2299
join_build_body_2298:
  %t54 = getelementptr inbounds i8*, i8** %t22, i64 %t52
  %t55 = load i8*, i8** %t54
  %t56 = icmp eq i8* %t55, null
  %t57 = select i1 %t56, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t55
  %t58 = call i32 @strlen(i8* %t57)
  %t59 = sext i32 %t58 to i64
  %t60 = load i8*, i8** %t50
  call i8* @memcpy(i8* %t60, i8* %t57, i64 %t59)
  %t61 = getelementptr inbounds i8, i8* %t60, i64 %t59
  %t62 = add i64 %t52, 1
  %t63 = icmp slt i64 %t62, %t23
  br i1 %t63, label %join_sep_2300, label %join_no_sep_2301
join_sep_2300:
  call i8* @memcpy(i8* %t61, i8* %t26, i64 %t28)
  %t64 = getelementptr inbounds i8, i8* %t61, i64 %t28
  br label %join_after_2302
join_no_sep_2301:
  br label %join_after_2302
join_after_2302:
  %t65 = phi i8* [ %t64, %join_sep_2300 ], [ %t61, %join_no_sep_2301 ]
  store i8* %t65, i8** %t50
  store i64 %t62, i64* %t51
  br label %join_build_cond_2297
join_build_done_2299:
  %t66 = load i8*, i8** %t50
  store i8 0, i8* %t66
  call void @star_rc_release(i8* %t24)
  call void @lex__Lexer__add_token_str(%lex__Lexer* %t14, i32 96, i8* %t49)
  %t68 = load i8*, i8** %t5
  call void @star_rc_release(i8* %t68)
  ret void
if_else_2289:
  br label %if_end_2290
if_end_2290:
  %t69 = load i32, i32* %t9
  %t70 = icmp eq i32 %t69, 92
  br i1 %t70, label %if_then_2303, label %if_else_2304
if_then_2303:
  %t71 = load %lex__Lexer*, %lex__Lexer** %t0
  %t72 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t71)
  br i1 %t72, label %if_then_2306, label %if_else_2307
if_then_2306:
  %t73 = load %lex__Lexer*, %lex__Lexer** %t0
  %t74 = getelementptr inbounds { i64, i8*, [20 x i8] }, { i64, i8*, [20 x i8] }* @.str.166, i64 0, i32 2, i64 0
  %t75 = load i32, i32* %t1
  %t76 = load %lex__Lexer*, %lex__Lexer** %t0
  %t77 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t76, i32 0, i32 5
  %t78 = load i32, i32* %t77
  call void @lex__Lexer__fail(%lex__Lexer* %t73, i8* %t74, i32 %t75, i32 %t78)
  %t80 = load i8*, i8** %t5
  call void @star_rc_release(i8* %t80)
  ret void
if_else_2307:
  br label %if_end_2308
if_end_2308:
  %t82 = load %lex__Lexer*, %lex__Lexer** %t0
  %t83 = call i32 @lex__Lexer__advance(%lex__Lexer* %t82)
  store i32 %t83, i32* %t81
  %t84 = getelementptr i8*, i8** null, i32 1
  %t85 = ptrtoint i8** %t84 to i64
  %t86 = load i8*, i8** %t5
  %t87 = icmp eq i8* %t86, null
  br i1 %t87, label %list_cow_alloc_2309, label %list_cow_check_2310
list_cow_alloc_2309:
  %t88 = bitcast void (i8*)* @list_release_str to i8*
  %t89 = call i8* @star_rc_alloc(i64 24, i8* %t88)
  %t90 = bitcast i8* %t89 to { i8**, i64, i64 }*
  %t91 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t90, i32 0, i32 0
  store i8** null, i8*** %t91
  %t92 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t90, i32 0, i32 1
  store i64 0, i64* %t92
  %t93 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t90, i32 0, i32 2
  store i64 0, i64* %t93
  store i8* %t89, i8** %t5
  br label %list_cow_done_2311
list_cow_check_2310:
  %t94 = getelementptr inbounds i8, i8* %t86, i64 -16
  %t95 = bitcast i8* %t94 to i64*
  %t96 = load atomic i64, i64* %t95 seq_cst, align 8
  %t97 = icmp eq i64 %t96, 1
  br i1 %t97, label %list_cow_done_2311, label %list_cow_clone_2312
list_cow_clone_2312:
  %t98 = bitcast i8* %t86 to { i8**, i64, i64 }*
  %t99 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t98, i32 0, i32 0
  %t100 = load i8**, i8*** %t99
  %t101 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t98, i32 0, i32 1
  %t102 = load i64, i64* %t101
  %t103 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t98, i32 0, i32 2
  %t104 = load i64, i64* %t103
  %t105 = bitcast void (i8*)* @list_release_str to i8*
  %t106 = call i8* @star_rc_alloc(i64 24, i8* %t105)
  %t107 = bitcast i8* %t106 to { i8**, i64, i64 }*
  %t108 = mul i64 %t104, %t85
  %t109 = call i8* @malloc(i64 %t108)
  %t110 = bitcast i8* %t109 to i8**
  %t111 = icmp sgt i64 %t102, 0
  br i1 %t111, label %list_cow_copy_2313, label %list_cow_after_copy_2314
list_cow_copy_2313:
  %t112 = mul i64 %t102, %t85
  %t113 = bitcast i8** %t100 to i8*
  call i8* @memcpy(i8* %t109, i8* %t113, i64 %t112)
  store i64 0, i64* %t114
  br label %list_cow_retain_cond_2315
list_cow_retain_cond_2315:
  %t115 = load i64, i64* %t114
  %t116 = icmp slt i64 %t115, %t102
  br i1 %t116, label %list_cow_retain_body_2316, label %list_cow_retain_end_2317
list_cow_retain_body_2316:
  %t117 = getelementptr inbounds i8*, i8** %t110, i64 %t115
  %t118 = load i8*, i8** %t117
  call void @star_rc_retain(i8* %t118)
  %t119 = add i64 %t115, 1
  store i64 %t119, i64* %t114
  br label %list_cow_retain_cond_2315
list_cow_retain_end_2317:
  br label %list_cow_after_copy_2314
list_cow_after_copy_2314:
  %t120 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t107, i32 0, i32 0
  store i8** %t110, i8*** %t120
  %t121 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t107, i32 0, i32 1
  store i64 %t102, i64* %t121
  %t122 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t107, i32 0, i32 2
  store i64 %t104, i64* %t122
  call void @star_rc_release(i8* %t86)
  store i8* %t106, i8** %t5
  br label %list_cow_done_2311
list_cow_done_2311:
  %t123 = load i8*, i8** %t5
  %t124 = bitcast i8* %t123 to { i8**, i64, i64 }*
  %t125 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t124, i32 0, i32 0
  %t126 = load i8**, i8*** %t125
  %t127 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t124, i32 0, i32 1
  %t128 = load i64, i64* %t127
  %t129 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t124, i32 0, i32 2
  %t130 = load i32, i32* %t81
  %t131 = call i8* @lex__escape_char(i32 %t130)
  %t132 = load i64, i64* %t129
  %t133 = load i8**, i8*** %t125
  %t134 = load i64, i64* %t127
  %t135 = icmp sge i64 %t134, %t132
  br i1 %t135, label %list_push_grow_2318, label %list_push_store_2319
list_push_grow_2318:
  %t136 = mul i64 %t132, 2
  %t137 = icmp sgt i64 %t136, 0
  %t138 = select i1 %t137, i64 %t136, i64 1
  %t139 = getelementptr i8*, i8** null, i32 1
  %t140 = ptrtoint i8** %t139 to i64
  %t141 = mul i64 %t138, %t140
  %t142 = call i8* @malloc(i64 %t141)
  %t143 = bitcast i8* %t142 to i8**
  %t144 = icmp sgt i64 %t132, 0
  br i1 %t144, label %list_push_copy_2320, label %list_push_after_copy_2321
list_push_copy_2320:
  %t145 = mul i64 %t134, %t140
  %t146 = bitcast i8** %t133 to i8*
  call i8* @memcpy(i8* %t142, i8* %t146, i64 %t145)
  call void @free(i8* %t146)
  br label %list_push_after_copy_2321
list_push_after_copy_2321:
  store i8** %t143, i8*** %t125
  store i64 %t138, i64* %t129
  br label %list_push_store_2319
list_push_store_2319:
  %t147 = load i8**, i8*** %t125
  %t148 = getelementptr inbounds i8*, i8** %t147, i64 %t134
  store i8* %t131, i8** %t148
  %t149 = add i64 %t134, 1
  store i64 %t149, i64* %t127
  %t150 = load i32, i32* %t81
  %t151 = icmp eq i32 %t150, 10
  br i1 %t151, label %if_then_2322, label %if_else_2323
if_then_2322:
  %t152 = load %lex__Lexer*, %lex__Lexer** %t0
  %t153 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t152, i32 0, i32 4
  %t154 = load i32, i32* %t153
  %t155 = add i32 %t154, 1
  %t156 = load %lex__Lexer*, %lex__Lexer** %t0
  %t157 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t156, i32 0, i32 4
  store i32 %t155, i32* %t157
  %t158 = load %lex__Lexer*, %lex__Lexer** %t0
  %t159 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t158, i32 0, i32 5
  store i32 1, i32* %t159
  br label %if_end_2324
if_else_2323:
  br label %if_end_2324
if_end_2324:
  br label %while_cond_2284
if_else_2304:
  br label %if_end_2305
if_end_2305:
  %t160 = load i32, i32* %t9
  %t161 = icmp eq i32 %t160, 10
  br i1 %t161, label %if_then_2325, label %if_else_2326
if_then_2325:
  %t162 = load %lex__Lexer*, %lex__Lexer** %t0
  %t163 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t162, i32 0, i32 4
  %t164 = load i32, i32* %t163
  %t165 = add i32 %t164, 1
  %t166 = load %lex__Lexer*, %lex__Lexer** %t0
  %t167 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t166, i32 0, i32 4
  store i32 %t165, i32* %t167
  %t168 = load %lex__Lexer*, %lex__Lexer** %t0
  %t169 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t168, i32 0, i32 5
  store i32 1, i32* %t169
  br label %if_end_2327
if_else_2326:
  br label %if_end_2327
if_end_2327:
  %t170 = getelementptr i8*, i8** null, i32 1
  %t171 = ptrtoint i8** %t170 to i64
  %t172 = load i8*, i8** %t5
  %t173 = icmp eq i8* %t172, null
  br i1 %t173, label %list_cow_alloc_2328, label %list_cow_check_2329
list_cow_alloc_2328:
  %t174 = bitcast void (i8*)* @list_release_str to i8*
  %t175 = call i8* @star_rc_alloc(i64 24, i8* %t174)
  %t176 = bitcast i8* %t175 to { i8**, i64, i64 }*
  %t177 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t176, i32 0, i32 0
  store i8** null, i8*** %t177
  %t178 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t176, i32 0, i32 1
  store i64 0, i64* %t178
  %t179 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t176, i32 0, i32 2
  store i64 0, i64* %t179
  store i8* %t175, i8** %t5
  br label %list_cow_done_2330
list_cow_check_2329:
  %t180 = getelementptr inbounds i8, i8* %t172, i64 -16
  %t181 = bitcast i8* %t180 to i64*
  %t182 = load atomic i64, i64* %t181 seq_cst, align 8
  %t183 = icmp eq i64 %t182, 1
  br i1 %t183, label %list_cow_done_2330, label %list_cow_clone_2331
list_cow_clone_2331:
  %t184 = bitcast i8* %t172 to { i8**, i64, i64 }*
  %t185 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t184, i32 0, i32 0
  %t186 = load i8**, i8*** %t185
  %t187 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t184, i32 0, i32 1
  %t188 = load i64, i64* %t187
  %t189 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t184, i32 0, i32 2
  %t190 = load i64, i64* %t189
  %t191 = bitcast void (i8*)* @list_release_str to i8*
  %t192 = call i8* @star_rc_alloc(i64 24, i8* %t191)
  %t193 = bitcast i8* %t192 to { i8**, i64, i64 }*
  %t194 = mul i64 %t190, %t171
  %t195 = call i8* @malloc(i64 %t194)
  %t196 = bitcast i8* %t195 to i8**
  %t197 = icmp sgt i64 %t188, 0
  br i1 %t197, label %list_cow_copy_2332, label %list_cow_after_copy_2333
list_cow_copy_2332:
  %t198 = mul i64 %t188, %t171
  %t199 = bitcast i8** %t186 to i8*
  call i8* @memcpy(i8* %t195, i8* %t199, i64 %t198)
  store i64 0, i64* %t200
  br label %list_cow_retain_cond_2334
list_cow_retain_cond_2334:
  %t201 = load i64, i64* %t200
  %t202 = icmp slt i64 %t201, %t188
  br i1 %t202, label %list_cow_retain_body_2335, label %list_cow_retain_end_2336
list_cow_retain_body_2335:
  %t203 = getelementptr inbounds i8*, i8** %t196, i64 %t201
  %t204 = load i8*, i8** %t203
  call void @star_rc_retain(i8* %t204)
  %t205 = add i64 %t201, 1
  store i64 %t205, i64* %t200
  br label %list_cow_retain_cond_2334
list_cow_retain_end_2336:
  br label %list_cow_after_copy_2333
list_cow_after_copy_2333:
  %t206 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t193, i32 0, i32 0
  store i8** %t196, i8*** %t206
  %t207 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t193, i32 0, i32 1
  store i64 %t188, i64* %t207
  %t208 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t193, i32 0, i32 2
  store i64 %t190, i64* %t208
  call void @star_rc_release(i8* %t172)
  store i8* %t192, i8** %t5
  br label %list_cow_done_2330
list_cow_done_2330:
  %t209 = load i8*, i8** %t5
  %t210 = bitcast i8* %t209 to { i8**, i64, i64 }*
  %t211 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t210, i32 0, i32 0
  %t212 = load i8**, i8*** %t211
  %t213 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t210, i32 0, i32 1
  %t214 = load i64, i64* %t213
  %t215 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t210, i32 0, i32 2
  %t216 = load i32, i32* %t9
  %t217 = trunc i32 %t216 to i8
  %t218 = call i8* @star_rc_alloc(i64 2, i8* null)
  store i8 %t217, i8* %t218
  %t219 = getelementptr inbounds i8, i8* %t218, i64 1
  store i8 0, i8* %t219
  %t220 = load i64, i64* %t215
  %t221 = load i8**, i8*** %t211
  %t222 = load i64, i64* %t213
  %t223 = icmp sge i64 %t222, %t220
  br i1 %t223, label %list_push_grow_2337, label %list_push_store_2338
list_push_grow_2337:
  %t224 = mul i64 %t220, 2
  %t225 = icmp sgt i64 %t224, 0
  %t226 = select i1 %t225, i64 %t224, i64 1
  %t227 = getelementptr i8*, i8** null, i32 1
  %t228 = ptrtoint i8** %t227 to i64
  %t229 = mul i64 %t226, %t228
  %t230 = call i8* @malloc(i64 %t229)
  %t231 = bitcast i8* %t230 to i8**
  %t232 = icmp sgt i64 %t220, 0
  br i1 %t232, label %list_push_copy_2339, label %list_push_after_copy_2340
list_push_copy_2339:
  %t233 = mul i64 %t222, %t228
  %t234 = bitcast i8** %t221 to i8*
  call i8* @memcpy(i8* %t230, i8* %t234, i64 %t233)
  call void @free(i8* %t234)
  br label %list_push_after_copy_2340
list_push_after_copy_2340:
  store i8** %t231, i8*** %t211
  store i64 %t226, i64* %t215
  br label %list_push_store_2338
list_push_store_2338:
  %t235 = load i8**, i8*** %t211
  %t236 = getelementptr inbounds i8*, i8** %t235, i64 %t222
  store i8* %t218, i8** %t236
  %t237 = add i64 %t222, 1
  store i64 %t237, i64* %t213
  br label %while_cond_2284
while_else_2286:
  br label %while_end_2287
while_end_2287:
  %t238 = load %lex__Lexer*, %lex__Lexer** %t0
  %t239 = getelementptr inbounds { i64, i8*, [20 x i8] }, { i64, i8*, [20 x i8] }* @.str.167, i64 0, i32 2, i64 0
  %t240 = load i32, i32* %t1
  %t241 = load %lex__Lexer*, %lex__Lexer** %t0
  %t242 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t241, i32 0, i32 5
  %t243 = load i32, i32* %t242
  call void @lex__Lexer__fail(%lex__Lexer* %t238, i8* %t239, i32 %t240, i32 %t243)
  %t245 = load i8*, i8** %t5
  call void @star_rc_release(i8* %t245)
  ret void
}

define void @lex__Lexer__scan_asm_block(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  %t3 = alloca i32
  %t39 = alloca i32
  %t53 = alloca i32
  %t57 = alloca i32
  %t61 = alloca i32
  %t65 = alloca i32
  %t82 = alloca i8*
  %t95 = alloca i8*
  %t104 = alloca i64
  %t122 = alloca i64
  store %lex__Lexer* %self, %lex__Lexer** %t0
  %t1 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t1, i32 42)
  %t4 = load %lex__Lexer*, %lex__Lexer** %t0
  %t5 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t4, i32 0, i32 4
  %t6 = load i32, i32* %t5
  store i32 %t6, i32* %t3
  br label %while_cond_2341
while_cond_2341:
  %t7 = load %lex__Lexer*, %lex__Lexer** %t0
  %t8 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t7)
  %t9 = xor i1 true, %t8
  br i1 %t9, label %logic_rhs_2345, label %logic_short_2346
logic_rhs_2345:
  %t10 = load %lex__Lexer*, %lex__Lexer** %t0
  %t11 = call i32 @lex__Lexer__peek(%lex__Lexer* %t10)
  %t12 = icmp eq i32 %t11, 32
  br i1 %t12, label %logic_short_2349, label %logic_rhs_2348
logic_rhs_2348:
  %t13 = load %lex__Lexer*, %lex__Lexer** %t0
  %t14 = call i32 @lex__Lexer__peek(%lex__Lexer* %t13)
  %t15 = icmp eq i32 %t14, 9
  br label %logic_end_2350
logic_short_2349:
  br label %logic_end_2350
logic_end_2350:
  %t16 = phi i1 [ %t15, %logic_rhs_2348 ], [ true, %logic_short_2349 ]
  br i1 %t16, label %logic_short_2352, label %logic_rhs_2351
logic_rhs_2351:
  %t17 = load %lex__Lexer*, %lex__Lexer** %t0
  %t18 = call i32 @lex__Lexer__peek(%lex__Lexer* %t17)
  %t19 = icmp eq i32 %t18, 13
  br label %logic_end_2353
logic_short_2352:
  br label %logic_end_2353
logic_end_2353:
  %t20 = phi i1 [ %t19, %logic_rhs_2351 ], [ true, %logic_short_2352 ]
  br i1 %t20, label %logic_short_2355, label %logic_rhs_2354
logic_rhs_2354:
  %t21 = load %lex__Lexer*, %lex__Lexer** %t0
  %t22 = call i32 @lex__Lexer__peek(%lex__Lexer* %t21)
  %t23 = icmp eq i32 %t22, 10
  br label %logic_end_2356
logic_short_2355:
  br label %logic_end_2356
logic_end_2356:
  %t24 = phi i1 [ %t23, %logic_rhs_2354 ], [ true, %logic_short_2355 ]
  br label %logic_end_2347
logic_short_2346:
  br label %logic_end_2347
logic_end_2347:
  %t25 = phi i1 [ %t24, %logic_end_2356 ], [ false, %logic_short_2346 ]
  br i1 %t25, label %while_body_2342, label %while_else_2343
while_body_2342:
  %t26 = load %lex__Lexer*, %lex__Lexer** %t0
  %t27 = call i32 @lex__Lexer__peek(%lex__Lexer* %t26)
  %t28 = icmp eq i32 %t27, 10
  br i1 %t28, label %if_then_2357, label %if_else_2358
if_then_2357:
  %t29 = load %lex__Lexer*, %lex__Lexer** %t0
  %t30 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t29, i32 0, i32 4
  %t31 = load i32, i32* %t30
  %t32 = add i32 %t31, 1
  %t33 = load %lex__Lexer*, %lex__Lexer** %t0
  %t34 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t33, i32 0, i32 4
  store i32 %t32, i32* %t34
  %t35 = load %lex__Lexer*, %lex__Lexer** %t0
  %t36 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t35, i32 0, i32 5
  store i32 1, i32* %t36
  br label %if_end_2359
if_else_2358:
  br label %if_end_2359
if_end_2359:
  %t37 = load %lex__Lexer*, %lex__Lexer** %t0
  %t38 = call i32 @lex__Lexer__advance(%lex__Lexer* %t37)
  br label %while_cond_2341
while_else_2343:
  br label %while_end_2344
while_end_2344:
  %t40 = load %lex__Lexer*, %lex__Lexer** %t0
  %t41 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t40, i32 0, i32 3
  %t42 = load i32, i32* %t41
  store i32 %t42, i32* %t39
  br label %while_cond_2360
while_cond_2360:
  %t43 = load %lex__Lexer*, %lex__Lexer** %t0
  %t44 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t43)
  %t45 = xor i1 true, %t44
  br i1 %t45, label %while_body_2361, label %while_else_2362
while_body_2361:
  %t46 = load %lex__Lexer*, %lex__Lexer** %t0
  %t47 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t46, i32 0, i32 10
  %t48 = load i1, i1* %t47
  br i1 %t48, label %if_then_2364, label %if_else_2365
if_then_2364:
  ret void
if_else_2365:
  br label %if_end_2366
if_end_2366:
  %t49 = load %lex__Lexer*, %lex__Lexer** %t0
  %t50 = call i32 @lex__Lexer__peek(%lex__Lexer* %t49)
  %t51 = call i32 @lex__to_lower_byte(i32 %t50)
  %t52 = icmp eq i32 %t51, 101
  br i1 %t52, label %if_then_2367, label %if_else_2368
if_then_2367:
  %t54 = load %lex__Lexer*, %lex__Lexer** %t0
  %t55 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t54, i32 0, i32 3
  %t56 = load i32, i32* %t55
  store i32 %t56, i32* %t53
  %t58 = load %lex__Lexer*, %lex__Lexer** %t0
  %t59 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t58, i32 0, i32 4
  %t60 = load i32, i32* %t59
  store i32 %t60, i32* %t57
  %t62 = load %lex__Lexer*, %lex__Lexer** %t0
  %t63 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t62, i32 0, i32 5
  %t64 = load i32, i32* %t63
  store i32 %t64, i32* %t61
  %t66 = load %lex__Lexer*, %lex__Lexer** %t0
  %t67 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t66, i32 0, i32 3
  %t68 = load i32, i32* %t67
  store i32 %t68, i32* %t65
  br label %while_cond_2370
while_cond_2370:
  %t69 = load %lex__Lexer*, %lex__Lexer** %t0
  %t70 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t69)
  %t71 = xor i1 true, %t70
  br i1 %t71, label %logic_rhs_2374, label %logic_short_2375
logic_rhs_2374:
  %t72 = load %lex__Lexer*, %lex__Lexer** %t0
  %t73 = call i32 @lex__Lexer__peek(%lex__Lexer* %t72)
  %t74 = call i1 @lex__is_alnum_byte(i32 %t73)
  br i1 %t74, label %logic_short_2378, label %logic_rhs_2377
logic_rhs_2377:
  %t75 = load %lex__Lexer*, %lex__Lexer** %t0
  %t76 = call i32 @lex__Lexer__peek(%lex__Lexer* %t75)
  %t77 = icmp eq i32 %t76, 95
  br label %logic_end_2379
logic_short_2378:
  br label %logic_end_2379
logic_end_2379:
  %t78 = phi i1 [ %t77, %logic_rhs_2377 ], [ true, %logic_short_2378 ]
  br label %logic_end_2376
logic_short_2375:
  br label %logic_end_2376
logic_end_2376:
  %t79 = phi i1 [ %t78, %logic_end_2379 ], [ false, %logic_short_2375 ]
  br i1 %t79, label %while_body_2371, label %while_else_2372
while_body_2371:
  %t80 = load %lex__Lexer*, %lex__Lexer** %t0
  %t81 = call i32 @lex__Lexer__advance(%lex__Lexer* %t80)
  br label %while_cond_2370
while_else_2372:
  br label %while_end_2373
while_end_2373:
  %t83 = load %lex__Lexer*, %lex__Lexer** %t0
  %t84 = load i32, i32* %t65
  %t85 = load %lex__Lexer*, %lex__Lexer** %t0
  %t86 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t85, i32 0, i32 3
  %t87 = load i32, i32* %t86
  %t88 = call i8* @lex__Lexer__substr(%lex__Lexer* %t83, i32 %t84, i32 %t87)
  %t89 = call i8* @lex__str_lower(i8* %t88)
  store i8* %t89, i8** %t82
  %t90 = load i8*, i8** %t82
  %t91 = load i8*, i8** %t82
  call void @star_rc_retain(i8* %t91)
  %t92 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.168, i64 0, i32 2, i64 0
  %t93 = call i32 @strcmp(i8* %t90, i8* %t92)
  call void @star_rc_release(i8* %t90)
  call void @star_rc_release(i8* %t92)
  %t94 = icmp eq i32 %t93, 0
  br i1 %t94, label %if_then_2380, label %if_else_2381
if_then_2380:
  %t96 = load %lex__Lexer*, %lex__Lexer** %t0
  %t97 = load i32, i32* %t39
  %t98 = load i32, i32* %t65
  %t99 = call i8* @lex__Lexer__substr(%lex__Lexer* %t96, i32 %t97, i32 %t98)
  %t100 = icmp eq i8* %t99, null
  %t101 = select i1 %t100, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t99
  %t102 = call i32 @strlen(i8* %t101)
  %t103 = sext i32 %t102 to i64
  store i64 0, i64* %t104
  br label %trim_start_cond_2383
trim_start_cond_2383:
  %t105 = load i64, i64* %t104
  %t106 = icmp slt i64 %t105, %t103
  br i1 %t106, label %trim_start_body_2384, label %trim_start_done_2386
trim_start_body_2384:
  %t107 = getelementptr inbounds i8, i8* %t101, i64 %t105
  %t108 = load i8, i8* %t107
  %t109 = icmp eq i8 %t108, 32
  %t110 = icmp eq i8 %t108, 9
  %t111 = or i1 %t109, %t110
  %t112 = icmp eq i8 %t108, 10
  %t113 = or i1 %t111, %t112
  %t114 = icmp eq i8 %t108, 13
  %t115 = or i1 %t113, %t114
  %t116 = icmp eq i8 %t108, 11
  %t117 = or i1 %t115, %t116
  %t118 = icmp eq i8 %t108, 12
  %t119 = or i1 %t117, %t118
  br i1 %t119, label %trim_start_incr_2385, label %trim_start_done_2386
trim_start_incr_2385:
  %t120 = add i64 %t105, 1
  store i64 %t120, i64* %t104
  br label %trim_start_cond_2383
trim_start_done_2386:
  %t121 = load i64, i64* %t104
  store i64 %t103, i64* %t122
  br label %trim_end_cond_2387
trim_end_cond_2387:
  %t123 = load i64, i64* %t122
  %t124 = icmp sgt i64 %t123, %t121
  br i1 %t124, label %trim_end_body_2388, label %trim_end_done_2390
trim_end_body_2388:
  %t125 = sub i64 %t123, 1
  %t126 = getelementptr inbounds i8, i8* %t101, i64 %t125
  %t127 = load i8, i8* %t126
  %t128 = icmp eq i8 %t127, 32
  %t129 = icmp eq i8 %t127, 9
  %t130 = or i1 %t128, %t129
  %t131 = icmp eq i8 %t127, 10
  %t132 = or i1 %t130, %t131
  %t133 = icmp eq i8 %t127, 13
  %t134 = or i1 %t132, %t133
  %t135 = icmp eq i8 %t127, 11
  %t136 = or i1 %t134, %t135
  %t137 = icmp eq i8 %t127, 12
  %t138 = or i1 %t136, %t137
  br i1 %t138, label %trim_end_decr_2389, label %trim_end_done_2390
trim_end_decr_2389:
  store i64 %t125, i64* %t122
  br label %trim_end_cond_2387
trim_end_done_2390:
  %t139 = load i64, i64* %t122
  %t140 = sub i64 %t139, %t121
  %t141 = add i64 %t140, 1
  %t142 = call i8* @star_rc_alloc(i64 %t141, i8* null)
  %t143 = getelementptr inbounds i8, i8* %t101, i64 %t121
  call i8* @memcpy(i8* %t142, i8* %t143, i64 %t140)
  %t144 = getelementptr inbounds i8, i8* %t142, i64 %t140
  store i8 0, i8* %t144
  call void @star_rc_release(i8* %t99)
  store i8* %t142, i8** %t95
  %t145 = load %lex__Lexer*, %lex__Lexer** %t0
  %t146 = load i8*, i8** %t95
  %t147 = load i8*, i8** %t95
  call void @star_rc_retain(i8* %t147)
  call void @lex__Lexer__add_token_str(%lex__Lexer* %t145, i32 98, i8* %t146)
  %t149 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t149, i32 28)
  %t151 = load i8*, i8** %t95
  call void @star_rc_release(i8* %t151)
  %t152 = load i8*, i8** %t82
  call void @star_rc_release(i8* %t152)
  ret void
if_else_2381:
  %t153 = load i32, i32* %t53
  %t154 = load %lex__Lexer*, %lex__Lexer** %t0
  %t155 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t154, i32 0, i32 3
  store i32 %t153, i32* %t155
  %t156 = load i32, i32* %t57
  %t157 = load %lex__Lexer*, %lex__Lexer** %t0
  %t158 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t157, i32 0, i32 4
  store i32 %t156, i32* %t158
  %t159 = load i32, i32* %t61
  %t160 = load %lex__Lexer*, %lex__Lexer** %t0
  %t161 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t160, i32 0, i32 5
  store i32 %t159, i32* %t161
  br label %if_end_2382
if_end_2382:
  %t162 = load i8*, i8** %t82
  call void @star_rc_release(i8* %t162)
  br label %if_end_2369
if_else_2368:
  br label %if_end_2369
if_end_2369:
  %t163 = load %lex__Lexer*, %lex__Lexer** %t0
  %t164 = call i32 @lex__Lexer__peek(%lex__Lexer* %t163)
  %t165 = icmp eq i32 %t164, 10
  br i1 %t165, label %if_then_2391, label %if_else_2392
if_then_2391:
  %t166 = load %lex__Lexer*, %lex__Lexer** %t0
  %t167 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t166, i32 0, i32 4
  %t168 = load i32, i32* %t167
  %t169 = add i32 %t168, 1
  %t170 = load %lex__Lexer*, %lex__Lexer** %t0
  %t171 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t170, i32 0, i32 4
  store i32 %t169, i32* %t171
  %t172 = load %lex__Lexer*, %lex__Lexer** %t0
  %t173 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t172, i32 0, i32 5
  store i32 1, i32* %t173
  br label %if_end_2393
if_else_2392:
  br label %if_end_2393
if_end_2393:
  %t174 = load %lex__Lexer*, %lex__Lexer** %t0
  %t175 = call i32 @lex__Lexer__advance(%lex__Lexer* %t174)
  br label %while_cond_2360
while_else_2362:
  br label %while_end_2363
while_end_2363:
  %t176 = load %lex__Lexer*, %lex__Lexer** %t0
  %t177 = getelementptr inbounds { i64, i8*, [39 x i8] }, { i64, i8*, [39 x i8] }* @.str.169, i64 0, i32 2, i64 0
  %t178 = load i32, i32* %t3
  %t179 = load %lex__Lexer*, %lex__Lexer** %t0
  %t180 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t179, i32 0, i32 5
  %t181 = load i32, i32* %t180
  call void @lex__Lexer__fail(%lex__Lexer* %t176, i8* %t177, i32 %t178, i32 %t181)
  ret void
}

define void @lex__Lexer__scan_token(%lex__Lexer* %self) {
entry:
  %t0 = alloca %lex__Lexer*
  %t16 = alloca i32
  %t88 = alloca %Option__lex__tok__TokenType
  store %lex__Lexer* %self, %lex__Lexer** %t0
  %t1 = load %lex__Lexer*, %lex__Lexer** %t0
  %t2 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t1, i32 0, i32 3
  %t3 = load i32, i32* %t2
  %t4 = load %lex__Lexer*, %lex__Lexer** %t0
  %t5 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t4, i32 0, i32 6
  store i32 %t3, i32* %t5
  %t6 = load %lex__Lexer*, %lex__Lexer** %t0
  %t7 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t6, i32 0, i32 4
  %t8 = load i32, i32* %t7
  %t9 = load %lex__Lexer*, %lex__Lexer** %t0
  %t10 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t9, i32 0, i32 7
  store i32 %t8, i32* %t10
  %t11 = load %lex__Lexer*, %lex__Lexer** %t0
  %t12 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t11, i32 0, i32 5
  %t13 = load i32, i32* %t12
  %t14 = load %lex__Lexer*, %lex__Lexer** %t0
  %t15 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t14, i32 0, i32 8
  store i32 %t13, i32* %t15
  %t17 = load %lex__Lexer*, %lex__Lexer** %t0
  %t18 = call i32 @lex__Lexer__advance(%lex__Lexer* %t17)
  store i32 %t18, i32* %t16
  %t19 = load i32, i32* %t16
  %t20 = icmp eq i32 %t19, 47
  br i1 %t20, label %logic_rhs_2394, label %logic_short_2395
logic_rhs_2394:
  %t21 = load %lex__Lexer*, %lex__Lexer** %t0
  %t22 = call i1 @lex__Lexer__match_char(%lex__Lexer* %t21, i32 47)
  br label %logic_end_2396
logic_short_2395:
  br label %logic_end_2396
logic_end_2396:
  %t23 = phi i1 [ %t22, %logic_rhs_2394 ], [ false, %logic_short_2395 ]
  br i1 %t23, label %if_then_2397, label %if_else_2398
if_then_2397:
  br label %while_cond_2400
while_cond_2400:
  %t24 = load %lex__Lexer*, %lex__Lexer** %t0
  %t25 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t24)
  %t26 = xor i1 true, %t25
  br i1 %t26, label %logic_rhs_2404, label %logic_short_2405
logic_rhs_2404:
  %t27 = load %lex__Lexer*, %lex__Lexer** %t0
  %t28 = call i32 @lex__Lexer__peek(%lex__Lexer* %t27)
  %t29 = icmp ne i32 %t28, 10
  br label %logic_end_2406
logic_short_2405:
  br label %logic_end_2406
logic_end_2406:
  %t30 = phi i1 [ %t29, %logic_rhs_2404 ], [ false, %logic_short_2405 ]
  br i1 %t30, label %while_body_2401, label %while_else_2402
while_body_2401:
  %t31 = load %lex__Lexer*, %lex__Lexer** %t0
  %t32 = call i32 @lex__Lexer__advance(%lex__Lexer* %t31)
  br label %while_cond_2400
while_else_2402:
  br label %while_end_2403
while_end_2403:
  ret void
if_else_2398:
  br label %if_end_2399
if_end_2399:
  %t33 = load i32, i32* %t16
  %t34 = icmp eq i32 %t33, 60
  br i1 %t34, label %logic_rhs_2407, label %logic_short_2408
logic_rhs_2407:
  %t35 = load %lex__Lexer*, %lex__Lexer** %t0
  %t36 = call i1 @lex__Lexer__match_char(%lex__Lexer* %t35, i32 62)
  br label %logic_end_2409
logic_short_2408:
  br label %logic_end_2409
logic_end_2409:
  %t37 = phi i1 [ %t36, %logic_rhs_2407 ], [ false, %logic_short_2408 ]
  br i1 %t37, label %if_then_2410, label %if_else_2411
if_then_2410:
  %t38 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t38, i32 72)
  ret void
if_else_2411:
  br label %if_end_2412
if_end_2412:
  %t40 = load i32, i32* %t16
  %t41 = icmp eq i32 %t40, 60
  br i1 %t41, label %logic_rhs_2413, label %logic_short_2414
logic_rhs_2413:
  %t42 = load %lex__Lexer*, %lex__Lexer** %t0
  %t43 = call i1 @lex__Lexer__match_char(%lex__Lexer* %t42, i32 61)
  br label %logic_end_2415
logic_short_2414:
  br label %logic_end_2415
logic_end_2415:
  %t44 = phi i1 [ %t43, %logic_rhs_2413 ], [ false, %logic_short_2414 ]
  br i1 %t44, label %if_then_2416, label %if_else_2417
if_then_2416:
  %t45 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t45, i32 74)
  ret void
if_else_2417:
  br label %if_end_2418
if_end_2418:
  %t47 = load i32, i32* %t16
  %t48 = icmp eq i32 %t47, 60
  br i1 %t48, label %logic_rhs_2419, label %logic_short_2420
logic_rhs_2419:
  %t49 = load %lex__Lexer*, %lex__Lexer** %t0
  %t50 = call i1 @lex__Lexer__match_char(%lex__Lexer* %t49, i32 60)
  br label %logic_end_2421
logic_short_2420:
  br label %logic_end_2421
logic_end_2421:
  %t51 = phi i1 [ %t50, %logic_rhs_2419 ], [ false, %logic_short_2420 ]
  br i1 %t51, label %if_then_2422, label %if_else_2423
if_then_2422:
  %t52 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t52, i32 79)
  ret void
if_else_2423:
  br label %if_end_2424
if_end_2424:
  %t54 = load i32, i32* %t16
  %t55 = icmp eq i32 %t54, 62
  br i1 %t55, label %logic_rhs_2425, label %logic_short_2426
logic_rhs_2425:
  %t56 = load %lex__Lexer*, %lex__Lexer** %t0
  %t57 = call i1 @lex__Lexer__match_char(%lex__Lexer* %t56, i32 61)
  br label %logic_end_2427
logic_short_2426:
  br label %logic_end_2427
logic_end_2427:
  %t58 = phi i1 [ %t57, %logic_rhs_2425 ], [ false, %logic_short_2426 ]
  br i1 %t58, label %if_then_2428, label %if_else_2429
if_then_2428:
  %t59 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t59, i32 76)
  ret void
if_else_2429:
  br label %if_end_2430
if_end_2430:
  %t61 = load i32, i32* %t16
  %t62 = icmp eq i32 %t61, 62
  br i1 %t62, label %logic_rhs_2431, label %logic_short_2432
logic_rhs_2431:
  %t63 = load %lex__Lexer*, %lex__Lexer** %t0
  %t64 = call i1 @lex__Lexer__match_char(%lex__Lexer* %t63, i32 62)
  br label %logic_end_2433
logic_short_2432:
  br label %logic_end_2433
logic_end_2433:
  %t65 = phi i1 [ %t64, %logic_rhs_2431 ], [ false, %logic_short_2432 ]
  br i1 %t65, label %if_then_2434, label %if_else_2435
if_then_2434:
  %t66 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t66, i32 80)
  ret void
if_else_2435:
  br label %if_end_2436
if_end_2436:
  %t68 = load i32, i32* %t16
  %t69 = icmp eq i32 %t68, 43
  br i1 %t69, label %logic_rhs_2437, label %logic_short_2438
logic_rhs_2437:
  %t70 = load %lex__Lexer*, %lex__Lexer** %t0
  %t71 = call i1 @lex__Lexer__match_char(%lex__Lexer* %t70, i32 43)
  br label %logic_end_2439
logic_short_2438:
  br label %logic_end_2439
logic_end_2439:
  %t72 = phi i1 [ %t71, %logic_rhs_2437 ], [ false, %logic_short_2438 ]
  br i1 %t72, label %if_then_2440, label %if_else_2441
if_then_2440:
  %t73 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t73, i32 84)
  ret void
if_else_2441:
  br label %if_end_2442
if_end_2442:
  %t75 = load i32, i32* %t16
  %t76 = icmp eq i32 %t75, 45
  br i1 %t76, label %logic_rhs_2443, label %logic_short_2444
logic_rhs_2443:
  %t77 = load %lex__Lexer*, %lex__Lexer** %t0
  %t78 = call i1 @lex__Lexer__match_char(%lex__Lexer* %t77, i32 45)
  br label %logic_end_2445
logic_short_2444:
  br label %logic_end_2445
logic_end_2445:
  %t79 = phi i1 [ %t78, %logic_rhs_2443 ], [ false, %logic_short_2444 ]
  br i1 %t79, label %if_then_2446, label %if_else_2447
if_then_2446:
  %t80 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t80, i32 85)
  ret void
if_else_2447:
  br label %if_end_2448
if_end_2448:
  %t82 = load i32, i32* %t16
  %t83 = icmp eq i32 %t82, 34
  br i1 %t83, label %if_then_2449, label %if_else_2450
if_then_2449:
  %t84 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__scan_string(%lex__Lexer* %t84)
  ret void
if_else_2450:
  br label %if_end_2451
if_end_2451:
  %t86 = load i32, i32* %t16
  %t87 = call %Option__lex__tok__TokenType @lex__tok__single_char_token(i32 %t86)
  store %Option__lex__tok__TokenType %t87, %Option__lex__tok__TokenType* %t88
  br label %match_scrutinee_90
match_scrutinee_90:
  %t94 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t88, i32 0, i32 0
  %t95 = load i32, i32* %t94
  %t93 = icmp eq i32 %t95, 1
  br i1 %t93, label %match_then_0_91, label %match_next_0_92
match_then_0_91:
  %t96 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t88, i32 0, i32 1
  %t97 = bitcast [1 x i64]* %t96 to { i32 }*
  %t98 = getelementptr inbounds { i32 }, { i32 }* %t97, i32 0, i32 0
  %t99 = load %lex__Lexer*, %lex__Lexer** %t0
  %t100 = load i32, i32* %t98
  call void @lex__Lexer__add_token_plain(%lex__Lexer* %t99, i32 %t100)
  ret void
match_next_0_92:
  %t105 = getelementptr inbounds %Option__lex__tok__TokenType, %Option__lex__tok__TokenType* %t88, i32 0, i32 0
  %t106 = load i32, i32* %t105
  %t104 = icmp eq i32 %t106, 0
  br i1 %t104, label %match_then_1_102, label %match_next_1_103
match_then_1_102:
  br label %match_end_89
match_next_1_103:
  br label %match_end_89
match_end_89:
  %t107 = phi i32 [ 0, %match_then_1_102 ], [ undef, %match_next_1_103 ]
  %t108 = load i32, i32* %t16
  %t109 = call i1 @lex__is_digit_byte(i32 %t108)
  br i1 %t109, label %if_then_2452, label %if_else_2453
if_then_2452:
  %t110 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__scan_number(%lex__Lexer* %t110)
  ret void
if_else_2453:
  %t112 = load i32, i32* %t16
  %t113 = call i1 @lex__is_alpha_byte(i32 %t112)
  br i1 %t113, label %logic_short_2456, label %logic_rhs_2455
logic_rhs_2455:
  %t114 = load i32, i32* %t16
  %t115 = icmp eq i32 %t114, 95
  br label %logic_end_2457
logic_short_2456:
  br label %logic_end_2457
logic_end_2457:
  %t116 = phi i1 [ %t115, %logic_rhs_2455 ], [ true, %logic_short_2456 ]
  br i1 %t116, label %if_then_2458, label %if_else_2459
if_then_2458:
  %t117 = load %lex__Lexer*, %lex__Lexer** %t0
  call void @lex__Lexer__scan_identifier(%lex__Lexer* %t117)
  ret void
if_else_2459:
  %t119 = load i32, i32* %t16
  %t120 = icmp eq i32 %t119, 32
  br i1 %t120, label %logic_short_2462, label %logic_rhs_2461
logic_rhs_2461:
  %t121 = load i32, i32* %t16
  %t122 = icmp eq i32 %t121, 13
  br label %logic_end_2463
logic_short_2462:
  br label %logic_end_2463
logic_end_2463:
  %t123 = phi i1 [ %t122, %logic_rhs_2461 ], [ true, %logic_short_2462 ]
  br i1 %t123, label %logic_short_2465, label %logic_rhs_2464
logic_rhs_2464:
  %t124 = load i32, i32* %t16
  %t125 = icmp eq i32 %t124, 9
  br label %logic_end_2466
logic_short_2465:
  br label %logic_end_2466
logic_end_2466:
  %t126 = phi i1 [ %t125, %logic_rhs_2464 ], [ true, %logic_short_2465 ]
  br i1 %t126, label %if_then_2467, label %if_else_2468
if_then_2467:
  ret void
if_else_2468:
  %t127 = load i32, i32* %t16
  %t128 = icmp eq i32 %t127, 10
  br i1 %t128, label %if_then_2470, label %if_else_2471
if_then_2470:
  %t129 = load %lex__Lexer*, %lex__Lexer** %t0
  %t130 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t129, i32 0, i32 4
  %t131 = load i32, i32* %t130
  %t132 = add i32 %t131, 1
  %t133 = load %lex__Lexer*, %lex__Lexer** %t0
  %t134 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t133, i32 0, i32 4
  store i32 %t132, i32* %t134
  %t135 = load %lex__Lexer*, %lex__Lexer** %t0
  %t136 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t135, i32 0, i32 5
  store i32 1, i32* %t136
  ret void
if_else_2471:
  %t137 = load %lex__Lexer*, %lex__Lexer** %t0
  %t138 = getelementptr inbounds { i64, i8*, [23 x i8] }, { i64, i8*, [23 x i8] }* @.str.170, i64 0, i32 2, i64 0
  %t139 = load i32, i32* %t16
  %t140 = trunc i32 %t139 to i8
  %t141 = call i8* @star_rc_alloc(i64 2, i8* null)
  store i8 %t140, i8* %t141
  %t142 = getelementptr inbounds i8, i8* %t141, i64 1
  store i8 0, i8* %t142
  %t143 = call i32 @strlen(i8* %t138)
  %t144 = call i32 @strlen(i8* %t141)
  %t145 = add i32 %t143, %t144
  %t146 = add i32 %t145, 1
  %t147 = sext i32 %t146 to i64
  %t148 = call i8* @star_rc_alloc(i64 %t147, i8* null)
  call i8* @strcpy(i8* %t148, i8* %t138)
  call i8* @strcat(i8* %t148, i8* %t141)
  call void @star_rc_release(i8* %t138)
  call void @star_rc_release(i8* %t141)
  %t149 = load %lex__Lexer*, %lex__Lexer** %t0
  %t150 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t149, i32 0, i32 7
  %t151 = load i32, i32* %t150
  %t152 = load %lex__Lexer*, %lex__Lexer** %t0
  %t153 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t152, i32 0, i32 8
  %t154 = load i32, i32* %t153
  call void @lex__Lexer__fail(%lex__Lexer* %t137, i8* %t148, i32 %t151, i32 %t154)
  ret void
}

define %Result__List_lex__tok__Token__lex__LexError @lex__lex(i8* %source, i8* %filename) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t2 = alloca %lex__Lexer
  %t17 = alloca %Result__List_lex__tok__Token__lex__LexError
  %t21 = alloca %lex__LexError
  %t81 = alloca i64
  %t100 = alloca %lex__tok__Token
  %t134 = alloca %Result__List_lex__tok__Token__lex__LexError
  store i8* %source, i8** %t0
  store i8* %filename, i8** %t1
  %t3 = load i8*, i8** %t0
  %t4 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t4)
  %t5 = load i8*, i8** %t1
  %t6 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t6)
  %t7 = call %lex__Lexer @lex__new_lexer(i8* %t3, i8* %t5)
  store %lex__Lexer %t7, %lex__Lexer* %t2
  br label %while_cond_2473
while_cond_2473:
  %t8 = call i1 @lex__Lexer__is_at_end(%lex__Lexer* %t2)
  %t9 = xor i1 true, %t8
  br i1 %t9, label %logic_rhs_2477, label %logic_short_2478
logic_rhs_2477:
  %t10 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 10
  %t11 = load i1, i1* %t10
  %t12 = xor i1 true, %t11
  br label %logic_end_2479
logic_short_2478:
  br label %logic_end_2479
logic_end_2479:
  %t13 = phi i1 [ %t12, %logic_rhs_2477 ], [ false, %logic_short_2478 ]
  br i1 %t13, label %while_body_2474, label %while_else_2475
while_body_2474:
  call void @lex__Lexer__scan_token(%lex__Lexer* %t2)
  br label %while_cond_2473
while_else_2475:
  br label %while_end_2476
while_end_2476:
  %t15 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 10
  %t16 = load i1, i1* %t15
  br i1 %t16, label %if_then_2480, label %if_else_2481
if_then_2480:
  %t18 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t17, i32 0, i32 0
  store i32 1, i32* %t18
  %t19 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t17, i32 0, i32 1
  %t20 = bitcast [3 x i64]* %t19 to { %lex__LexError }*
  %t22 = getelementptr inbounds %lex__LexError, %lex__LexError* %t21, i32 0, i32 0
  %t23 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 11
  %t24 = load i8*, i8** %t23
  %t25 = load i8*, i8** %t23
  call void @star_rc_retain(i8* %t25)
  store i8* %t24, i8** %t22
  %t26 = getelementptr inbounds %lex__LexError, %lex__LexError* %t21, i32 0, i32 1
  %t27 = load i8*, i8** %t1
  %t28 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t28)
  store i8* %t27, i8** %t26
  %t29 = getelementptr inbounds %lex__LexError, %lex__LexError* %t21, i32 0, i32 2
  %t30 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 12
  %t31 = load i32, i32* %t30
  store i32 %t31, i32* %t29
  %t32 = getelementptr inbounds %lex__LexError, %lex__LexError* %t21, i32 0, i32 3
  %t33 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 13
  %t34 = load i32, i32* %t33
  store i32 %t34, i32* %t32
  %t35 = load %lex__LexError, %lex__LexError* %t21
  %t36 = getelementptr inbounds { %lex__LexError }, { %lex__LexError }* %t20, i32 0, i32 0
  store %lex__LexError %t35, %lex__LexError* %t36
  %t37 = load %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t17
  %t38 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 0
  %t39 = load i8*, i8** %t38
  call void @star_rc_release(i8* %t39)
  %t40 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 1
  %t41 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t41)
  %t42 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 2
  %t43 = load i8*, i8** %t42
  call void @star_rc_release(i8* %t43)
  %t44 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 9
  %t45 = load i8*, i8** %t44
  call void @star_rc_release(i8* %t45)
  %t46 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 11
  %t47 = load i8*, i8** %t46
  call void @star_rc_release(i8* %t47)
  %t48 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t48)
  %t49 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t49)
  ret %Result__List_lex__tok__Token__lex__LexError %t37
if_else_2481:
  br label %if_end_2482
if_end_2482:
  %t50 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 9
  %t51 = getelementptr %lex__tok__Token, %lex__tok__Token* null, i32 1
  %t52 = ptrtoint %lex__tok__Token* %t51 to i64
  %t53 = load i8*, i8** %t50
  %t54 = icmp eq i8* %t53, null
  br i1 %t54, label %list_cow_alloc_2483, label %list_cow_check_2484
list_cow_alloc_2483:
  %t55 = bitcast void (i8*)* @list_release_s_lex__tok__Token to i8*
  %t56 = call i8* @star_rc_alloc(i64 24, i8* %t55)
  %t57 = bitcast i8* %t56 to { %lex__tok__Token*, i64, i64 }*
  %t58 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t57, i32 0, i32 0
  store %lex__tok__Token* null, %lex__tok__Token** %t58
  %t59 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t57, i32 0, i32 1
  store i64 0, i64* %t59
  %t60 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t57, i32 0, i32 2
  store i64 0, i64* %t60
  store i8* %t56, i8** %t50
  br label %list_cow_done_2485
list_cow_check_2484:
  %t61 = getelementptr inbounds i8, i8* %t53, i64 -16
  %t62 = bitcast i8* %t61 to i64*
  %t63 = load atomic i64, i64* %t62 seq_cst, align 8
  %t64 = icmp eq i64 %t63, 1
  br i1 %t64, label %list_cow_done_2485, label %list_cow_clone_2486
list_cow_clone_2486:
  %t65 = bitcast i8* %t53 to { %lex__tok__Token*, i64, i64 }*
  %t66 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t65, i32 0, i32 0
  %t67 = load %lex__tok__Token*, %lex__tok__Token** %t66
  %t68 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t65, i32 0, i32 1
  %t69 = load i64, i64* %t68
  %t70 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t65, i32 0, i32 2
  %t71 = load i64, i64* %t70
  %t72 = bitcast void (i8*)* @list_release_s_lex__tok__Token to i8*
  %t73 = call i8* @star_rc_alloc(i64 24, i8* %t72)
  %t74 = bitcast i8* %t73 to { %lex__tok__Token*, i64, i64 }*
  %t75 = mul i64 %t71, %t52
  %t76 = call i8* @malloc(i64 %t75)
  %t77 = bitcast i8* %t76 to %lex__tok__Token*
  %t78 = icmp sgt i64 %t69, 0
  br i1 %t78, label %list_cow_copy_2487, label %list_cow_after_copy_2488
list_cow_copy_2487:
  %t79 = mul i64 %t69, %t52
  %t80 = bitcast %lex__tok__Token* %t67 to i8*
  call i8* @memcpy(i8* %t76, i8* %t80, i64 %t79)
  store i64 0, i64* %t81
  br label %list_cow_retain_cond_2489
list_cow_retain_cond_2489:
  %t82 = load i64, i64* %t81
  %t83 = icmp slt i64 %t82, %t69
  br i1 %t83, label %list_cow_retain_body_2490, label %list_cow_retain_end_2491
list_cow_retain_body_2490:
  %t84 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t77, i64 %t82
  %t85 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t84, i32 0, i32 1
  %t86 = load i8*, i8** %t85
  call void @star_rc_retain(i8* %t86)
  %t87 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t84, i32 0, i32 4
  %t88 = load i8*, i8** %t87
  call void @star_rc_retain(i8* %t88)
  %t89 = add i64 %t82, 1
  store i64 %t89, i64* %t81
  br label %list_cow_retain_cond_2489
list_cow_retain_end_2491:
  br label %list_cow_after_copy_2488
list_cow_after_copy_2488:
  %t90 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t74, i32 0, i32 0
  store %lex__tok__Token* %t77, %lex__tok__Token** %t90
  %t91 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t74, i32 0, i32 1
  store i64 %t69, i64* %t91
  %t92 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t74, i32 0, i32 2
  store i64 %t71, i64* %t92
  call void @star_rc_release(i8* %t53)
  store i8* %t73, i8** %t50
  br label %list_cow_done_2485
list_cow_done_2485:
  %t93 = load i8*, i8** %t50
  %t94 = bitcast i8* %t93 to { %lex__tok__Token*, i64, i64 }*
  %t95 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t94, i32 0, i32 0
  %t96 = load %lex__tok__Token*, %lex__tok__Token** %t95
  %t97 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t94, i32 0, i32 1
  %t98 = load i64, i64* %t97
  %t99 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t94, i32 0, i32 2
  %t101 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t100, i32 0, i32 0
  store i32 99, i32* %t101
  %t102 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t100, i32 0, i32 1
  %t103 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.171, i64 0, i32 2, i64 0
  store i8* %t103, i8** %t102
  %t104 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t100, i32 0, i32 2
  %t105 = sitofp i32 0 to double
  store double %t105, double* %t104
  %t106 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t100, i32 0, i32 3
  store i1 false, i1* %t106
  %t107 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t100, i32 0, i32 4
  %t108 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.172, i64 0, i32 2, i64 0
  store i8* %t108, i8** %t107
  %t109 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t100, i32 0, i32 5
  %t110 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 4
  %t111 = load i32, i32* %t110
  store i32 %t111, i32* %t109
  %t112 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t100, i32 0, i32 6
  %t113 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 5
  %t114 = load i32, i32* %t113
  store i32 %t114, i32* %t112
  %t115 = load %lex__tok__Token, %lex__tok__Token* %t100
  %t116 = load i64, i64* %t99
  %t117 = load %lex__tok__Token*, %lex__tok__Token** %t95
  %t118 = load i64, i64* %t97
  %t119 = icmp sge i64 %t118, %t116
  br i1 %t119, label %list_push_grow_2492, label %list_push_store_2493
list_push_grow_2492:
  %t120 = mul i64 %t116, 2
  %t121 = icmp sgt i64 %t120, 0
  %t122 = select i1 %t121, i64 %t120, i64 1
  %t123 = getelementptr %lex__tok__Token, %lex__tok__Token* null, i32 1
  %t124 = ptrtoint %lex__tok__Token* %t123 to i64
  %t125 = mul i64 %t122, %t124
  %t126 = call i8* @malloc(i64 %t125)
  %t127 = bitcast i8* %t126 to %lex__tok__Token*
  %t128 = icmp sgt i64 %t116, 0
  br i1 %t128, label %list_push_copy_2494, label %list_push_after_copy_2495
list_push_copy_2494:
  %t129 = mul i64 %t118, %t124
  %t130 = bitcast %lex__tok__Token* %t117 to i8*
  call i8* @memcpy(i8* %t126, i8* %t130, i64 %t129)
  call void @free(i8* %t130)
  br label %list_push_after_copy_2495
list_push_after_copy_2495:
  store %lex__tok__Token* %t127, %lex__tok__Token** %t95
  store i64 %t122, i64* %t99
  br label %list_push_store_2493
list_push_store_2493:
  %t131 = load %lex__tok__Token*, %lex__tok__Token** %t95
  %t132 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t131, i64 %t118
  store %lex__tok__Token %t115, %lex__tok__Token* %t132
  %t133 = add i64 %t118, 1
  store i64 %t133, i64* %t97
  %t135 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t134, i32 0, i32 0
  store i32 0, i32* %t135
  %t136 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t134, i32 0, i32 1
  %t137 = bitcast [3 x i64]* %t136 to { i8* }*
  %t138 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 9
  %t139 = load i8*, i8** %t138
  %t140 = load i8*, i8** %t138
  call void @star_rc_retain(i8* %t140)
  %t141 = getelementptr inbounds { i8* }, { i8* }* %t137, i32 0, i32 0
  store i8* %t139, i8** %t141
  %t142 = load %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t134
  %t143 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 0
  %t144 = load i8*, i8** %t143
  call void @star_rc_release(i8* %t144)
  %t145 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 1
  %t146 = load i8*, i8** %t145
  call void @star_rc_release(i8* %t146)
  %t147 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 2
  %t148 = load i8*, i8** %t147
  call void @star_rc_release(i8* %t148)
  %t149 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 9
  %t150 = load i8*, i8** %t149
  call void @star_rc_release(i8* %t150)
  %t151 = getelementptr inbounds %lex__Lexer, %lex__Lexer* %t2, i32 0, i32 11
  %t152 = load i8*, i8** %t151
  call void @star_rc_release(i8* %t152)
  %t153 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t153)
  %t154 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t154)
  ret %Result__List_lex__tok__Token__lex__LexError %t142
}

define i8* @dump_escape(i8* %s) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i8*
  %t21 = alloca i64
  %t22 = alloca i8*
  %t37 = alloca i8*
  %t38 = alloca i8*
  %t52 = alloca i8*
  %t72 = alloca i64
  %t73 = alloca i8*
  %t88 = alloca i8*
  %t89 = alloca i8*
  %t103 = alloca i8*
  %t123 = alloca i64
  %t124 = alloca i8*
  %t139 = alloca i8*
  %t140 = alloca i8*
  %t173 = alloca i64
  %t174 = alloca i8*
  %t189 = alloca i8*
  %t190 = alloca i8*
  store i8* %s, i8** %t0
  %t2 = load i8*, i8** %t0
  %t3 = load i8*, i8** %t0
  call void @star_rc_retain(i8* %t3)
  %t4 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.173, i64 0, i32 2, i64 0
  %t5 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.174, i64 0, i32 2, i64 0
  %t6 = icmp eq i8* %t2, null
  %t7 = select i1 %t6, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t2
  %t8 = icmp eq i8* %t4, null
  %t9 = select i1 %t8, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t4
  %t10 = icmp eq i8* %t5, null
  %t11 = select i1 %t10, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t5
  %t12 = call i32 @strlen(i8* %t9)
  %t13 = sext i32 %t12 to i64
  %t14 = icmp eq i64 %t13, 0
  br i1 %t14, label %replace_empty_old_2496, label %replace_real_2497
replace_empty_old_2496:
  %t15 = call i32 @strlen(i8* %t7)
  %t16 = sext i32 %t15 to i64
  %t17 = add i64 %t16, 1
  %t18 = call i8* @star_rc_alloc(i64 %t17, i8* null)
  call i8* @strcpy(i8* %t18, i8* %t7)
  br label %replace_done_2498
replace_real_2497:
  %t19 = call i32 @strlen(i8* %t11)
  %t20 = sext i32 %t19 to i64
  store i64 0, i64* %t21
  store i8* %t7, i8** %t22
  br label %replace_count_cond_2499
replace_count_cond_2499:
  %t23 = load i8*, i8** %t22
  %t24 = call i8* @strstr(i8* %t23, i8* %t9)
  %t25 = icmp eq i8* %t24, null
  br i1 %t25, label %replace_count_done_2501, label %replace_count_body_2500
replace_count_body_2500:
  %t26 = load i64, i64* %t21
  %t27 = add i64 %t26, 1
  store i64 %t27, i64* %t21
  %t28 = getelementptr inbounds i8, i8* %t24, i64 %t13
  store i8* %t28, i8** %t22
  br label %replace_count_cond_2499
replace_count_done_2501:
  %t29 = load i64, i64* %t21
  %t30 = call i32 @strlen(i8* %t7)
  %t31 = sext i32 %t30 to i64
  %t32 = sub i64 %t20, %t13
  %t33 = mul i64 %t29, %t32
  %t34 = add i64 %t31, %t33
  %t35 = add i64 %t34, 1
  %t36 = call i8* @star_rc_alloc(i64 %t35, i8* null)
  store i8* %t7, i8** %t37
  store i8* %t36, i8** %t38
  br label %replace_build_cond_2502
replace_build_cond_2502:
  %t39 = load i8*, i8** %t37
  %t40 = call i8* @strstr(i8* %t39, i8* %t9)
  %t41 = icmp eq i8* %t40, null
  br i1 %t41, label %replace_build_done_2504, label %replace_build_body_2503
replace_build_body_2503:
  %t42 = ptrtoint i8* %t40 to i64
  %t43 = ptrtoint i8* %t39 to i64
  %t44 = sub i64 %t42, %t43
  %t45 = load i8*, i8** %t38
  call i8* @memcpy(i8* %t45, i8* %t39, i64 %t44)
  %t46 = getelementptr inbounds i8, i8* %t45, i64 %t44
  call i8* @memcpy(i8* %t46, i8* %t11, i64 %t20)
  %t47 = getelementptr inbounds i8, i8* %t46, i64 %t20
  store i8* %t47, i8** %t38
  %t48 = getelementptr inbounds i8, i8* %t40, i64 %t13
  store i8* %t48, i8** %t37
  br label %replace_build_cond_2502
replace_build_done_2504:
  %t49 = load i8*, i8** %t37
  %t50 = load i8*, i8** %t38
  call i8* @strcpy(i8* %t50, i8* %t49)
  br label %replace_done_2498
replace_done_2498:
  %t51 = phi i8* [ %t18, %replace_empty_old_2496 ], [ %t36, %replace_build_done_2504 ]
  call void @star_rc_release(i8* %t2)
  call void @star_rc_release(i8* %t4)
  call void @star_rc_release(i8* %t5)
  store i8* %t51, i8** %t1
  %t53 = load i8*, i8** %t1
  %t54 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t54)
  %t55 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.175, i64 0, i32 2, i64 0
  %t56 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.176, i64 0, i32 2, i64 0
  %t57 = icmp eq i8* %t53, null
  %t58 = select i1 %t57, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t53
  %t59 = icmp eq i8* %t55, null
  %t60 = select i1 %t59, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t55
  %t61 = icmp eq i8* %t56, null
  %t62 = select i1 %t61, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t56
  %t63 = call i32 @strlen(i8* %t60)
  %t64 = sext i32 %t63 to i64
  %t65 = icmp eq i64 %t64, 0
  br i1 %t65, label %replace_empty_old_2505, label %replace_real_2506
replace_empty_old_2505:
  %t66 = call i32 @strlen(i8* %t58)
  %t67 = sext i32 %t66 to i64
  %t68 = add i64 %t67, 1
  %t69 = call i8* @star_rc_alloc(i64 %t68, i8* null)
  call i8* @strcpy(i8* %t69, i8* %t58)
  br label %replace_done_2507
replace_real_2506:
  %t70 = call i32 @strlen(i8* %t62)
  %t71 = sext i32 %t70 to i64
  store i64 0, i64* %t72
  store i8* %t58, i8** %t73
  br label %replace_count_cond_2508
replace_count_cond_2508:
  %t74 = load i8*, i8** %t73
  %t75 = call i8* @strstr(i8* %t74, i8* %t60)
  %t76 = icmp eq i8* %t75, null
  br i1 %t76, label %replace_count_done_2510, label %replace_count_body_2509
replace_count_body_2509:
  %t77 = load i64, i64* %t72
  %t78 = add i64 %t77, 1
  store i64 %t78, i64* %t72
  %t79 = getelementptr inbounds i8, i8* %t75, i64 %t64
  store i8* %t79, i8** %t73
  br label %replace_count_cond_2508
replace_count_done_2510:
  %t80 = load i64, i64* %t72
  %t81 = call i32 @strlen(i8* %t58)
  %t82 = sext i32 %t81 to i64
  %t83 = sub i64 %t71, %t64
  %t84 = mul i64 %t80, %t83
  %t85 = add i64 %t82, %t84
  %t86 = add i64 %t85, 1
  %t87 = call i8* @star_rc_alloc(i64 %t86, i8* null)
  store i8* %t58, i8** %t88
  store i8* %t87, i8** %t89
  br label %replace_build_cond_2511
replace_build_cond_2511:
  %t90 = load i8*, i8** %t88
  %t91 = call i8* @strstr(i8* %t90, i8* %t60)
  %t92 = icmp eq i8* %t91, null
  br i1 %t92, label %replace_build_done_2513, label %replace_build_body_2512
replace_build_body_2512:
  %t93 = ptrtoint i8* %t91 to i64
  %t94 = ptrtoint i8* %t90 to i64
  %t95 = sub i64 %t93, %t94
  %t96 = load i8*, i8** %t89
  call i8* @memcpy(i8* %t96, i8* %t90, i64 %t95)
  %t97 = getelementptr inbounds i8, i8* %t96, i64 %t95
  call i8* @memcpy(i8* %t97, i8* %t62, i64 %t71)
  %t98 = getelementptr inbounds i8, i8* %t97, i64 %t71
  store i8* %t98, i8** %t89
  %t99 = getelementptr inbounds i8, i8* %t91, i64 %t64
  store i8* %t99, i8** %t88
  br label %replace_build_cond_2511
replace_build_done_2513:
  %t100 = load i8*, i8** %t88
  %t101 = load i8*, i8** %t89
  call i8* @strcpy(i8* %t101, i8* %t100)
  br label %replace_done_2507
replace_done_2507:
  %t102 = phi i8* [ %t69, %replace_empty_old_2505 ], [ %t87, %replace_build_done_2513 ]
  call void @star_rc_release(i8* %t53)
  call void @star_rc_release(i8* %t55)
  call void @star_rc_release(i8* %t56)
  store i8* %t102, i8** %t52
  %t104 = load i8*, i8** %t52
  %t105 = load i8*, i8** %t52
  call void @star_rc_retain(i8* %t105)
  %t106 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.177, i64 0, i32 2, i64 0
  %t107 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.178, i64 0, i32 2, i64 0
  %t108 = icmp eq i8* %t104, null
  %t109 = select i1 %t108, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t104
  %t110 = icmp eq i8* %t106, null
  %t111 = select i1 %t110, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t106
  %t112 = icmp eq i8* %t107, null
  %t113 = select i1 %t112, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t107
  %t114 = call i32 @strlen(i8* %t111)
  %t115 = sext i32 %t114 to i64
  %t116 = icmp eq i64 %t115, 0
  br i1 %t116, label %replace_empty_old_2514, label %replace_real_2515
replace_empty_old_2514:
  %t117 = call i32 @strlen(i8* %t109)
  %t118 = sext i32 %t117 to i64
  %t119 = add i64 %t118, 1
  %t120 = call i8* @star_rc_alloc(i64 %t119, i8* null)
  call i8* @strcpy(i8* %t120, i8* %t109)
  br label %replace_done_2516
replace_real_2515:
  %t121 = call i32 @strlen(i8* %t113)
  %t122 = sext i32 %t121 to i64
  store i64 0, i64* %t123
  store i8* %t109, i8** %t124
  br label %replace_count_cond_2517
replace_count_cond_2517:
  %t125 = load i8*, i8** %t124
  %t126 = call i8* @strstr(i8* %t125, i8* %t111)
  %t127 = icmp eq i8* %t126, null
  br i1 %t127, label %replace_count_done_2519, label %replace_count_body_2518
replace_count_body_2518:
  %t128 = load i64, i64* %t123
  %t129 = add i64 %t128, 1
  store i64 %t129, i64* %t123
  %t130 = getelementptr inbounds i8, i8* %t126, i64 %t115
  store i8* %t130, i8** %t124
  br label %replace_count_cond_2517
replace_count_done_2519:
  %t131 = load i64, i64* %t123
  %t132 = call i32 @strlen(i8* %t109)
  %t133 = sext i32 %t132 to i64
  %t134 = sub i64 %t122, %t115
  %t135 = mul i64 %t131, %t134
  %t136 = add i64 %t133, %t135
  %t137 = add i64 %t136, 1
  %t138 = call i8* @star_rc_alloc(i64 %t137, i8* null)
  store i8* %t109, i8** %t139
  store i8* %t138, i8** %t140
  br label %replace_build_cond_2520
replace_build_cond_2520:
  %t141 = load i8*, i8** %t139
  %t142 = call i8* @strstr(i8* %t141, i8* %t111)
  %t143 = icmp eq i8* %t142, null
  br i1 %t143, label %replace_build_done_2522, label %replace_build_body_2521
replace_build_body_2521:
  %t144 = ptrtoint i8* %t142 to i64
  %t145 = ptrtoint i8* %t141 to i64
  %t146 = sub i64 %t144, %t145
  %t147 = load i8*, i8** %t140
  call i8* @memcpy(i8* %t147, i8* %t141, i64 %t146)
  %t148 = getelementptr inbounds i8, i8* %t147, i64 %t146
  call i8* @memcpy(i8* %t148, i8* %t113, i64 %t122)
  %t149 = getelementptr inbounds i8, i8* %t148, i64 %t122
  store i8* %t149, i8** %t140
  %t150 = getelementptr inbounds i8, i8* %t142, i64 %t115
  store i8* %t150, i8** %t139
  br label %replace_build_cond_2520
replace_build_done_2522:
  %t151 = load i8*, i8** %t139
  %t152 = load i8*, i8** %t140
  call i8* @strcpy(i8* %t152, i8* %t151)
  br label %replace_done_2516
replace_done_2516:
  %t153 = phi i8* [ %t120, %replace_empty_old_2514 ], [ %t138, %replace_build_done_2522 ]
  call void @star_rc_release(i8* %t104)
  call void @star_rc_release(i8* %t106)
  call void @star_rc_release(i8* %t107)
  store i8* %t153, i8** %t103
  %t154 = load i8*, i8** %t103
  %t155 = load i8*, i8** %t103
  call void @star_rc_retain(i8* %t155)
  %t156 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.179, i64 0, i32 2, i64 0
  %t157 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.180, i64 0, i32 2, i64 0
  %t158 = icmp eq i8* %t154, null
  %t159 = select i1 %t158, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t154
  %t160 = icmp eq i8* %t156, null
  %t161 = select i1 %t160, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t156
  %t162 = icmp eq i8* %t157, null
  %t163 = select i1 %t162, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t157
  %t164 = call i32 @strlen(i8* %t161)
  %t165 = sext i32 %t164 to i64
  %t166 = icmp eq i64 %t165, 0
  br i1 %t166, label %replace_empty_old_2523, label %replace_real_2524
replace_empty_old_2523:
  %t167 = call i32 @strlen(i8* %t159)
  %t168 = sext i32 %t167 to i64
  %t169 = add i64 %t168, 1
  %t170 = call i8* @star_rc_alloc(i64 %t169, i8* null)
  call i8* @strcpy(i8* %t170, i8* %t159)
  br label %replace_done_2525
replace_real_2524:
  %t171 = call i32 @strlen(i8* %t163)
  %t172 = sext i32 %t171 to i64
  store i64 0, i64* %t173
  store i8* %t159, i8** %t174
  br label %replace_count_cond_2526
replace_count_cond_2526:
  %t175 = load i8*, i8** %t174
  %t176 = call i8* @strstr(i8* %t175, i8* %t161)
  %t177 = icmp eq i8* %t176, null
  br i1 %t177, label %replace_count_done_2528, label %replace_count_body_2527
replace_count_body_2527:
  %t178 = load i64, i64* %t173
  %t179 = add i64 %t178, 1
  store i64 %t179, i64* %t173
  %t180 = getelementptr inbounds i8, i8* %t176, i64 %t165
  store i8* %t180, i8** %t174
  br label %replace_count_cond_2526
replace_count_done_2528:
  %t181 = load i64, i64* %t173
  %t182 = call i32 @strlen(i8* %t159)
  %t183 = sext i32 %t182 to i64
  %t184 = sub i64 %t172, %t165
  %t185 = mul i64 %t181, %t184
  %t186 = add i64 %t183, %t185
  %t187 = add i64 %t186, 1
  %t188 = call i8* @star_rc_alloc(i64 %t187, i8* null)
  store i8* %t159, i8** %t189
  store i8* %t188, i8** %t190
  br label %replace_build_cond_2529
replace_build_cond_2529:
  %t191 = load i8*, i8** %t189
  %t192 = call i8* @strstr(i8* %t191, i8* %t161)
  %t193 = icmp eq i8* %t192, null
  br i1 %t193, label %replace_build_done_2531, label %replace_build_body_2530
replace_build_body_2530:
  %t194 = ptrtoint i8* %t192 to i64
  %t195 = ptrtoint i8* %t191 to i64
  %t196 = sub i64 %t194, %t195
  %t197 = load i8*, i8** %t190
  call i8* @memcpy(i8* %t197, i8* %t191, i64 %t196)
  %t198 = getelementptr inbounds i8, i8* %t197, i64 %t196
  call i8* @memcpy(i8* %t198, i8* %t163, i64 %t172)
  %t199 = getelementptr inbounds i8, i8* %t198, i64 %t172
  store i8* %t199, i8** %t190
  %t200 = getelementptr inbounds i8, i8* %t192, i64 %t165
  store i8* %t200, i8** %t189
  br label %replace_build_cond_2529
replace_build_done_2531:
  %t201 = load i8*, i8** %t189
  %t202 = load i8*, i8** %t190
  call i8* @strcpy(i8* %t202, i8* %t201)
  br label %replace_done_2525
replace_done_2525:
  %t203 = phi i8* [ %t170, %replace_empty_old_2523 ], [ %t188, %replace_build_done_2531 ]
  call void @star_rc_release(i8* %t154)
  call void @star_rc_release(i8* %t156)
  call void @star_rc_release(i8* %t157)
  %t204 = load i8*, i8** %t103
  call void @star_rc_release(i8* %t204)
  %t205 = load i8*, i8** %t52
  call void @star_rc_release(i8* %t205)
  %t206 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t206)
  %t207 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t207)
  ret i8* %t203
}

define i8* @format_amount(double %v) {
entry:
  %t0 = alloca double
  %t1 = alloca i8*
  %t8 = alloca double
  %t16 = alloca i64
  %t23 = alloca i64
  %t33 = alloca i64
  %t43 = alloca i8*
  store double %v, double* %t0
  %t2 = load double, double* %t0
  %t3 = sitofp i32 0 to double
  %t4 = fcmp olt double %t2, %t3
  br i1 %t4, label %if_then_2532, label %if_else_2533
if_then_2532:
  %t5 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.181, i64 0, i32 2, i64 0
  br label %if_end_2534
if_else_2533:
  %t6 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.182, i64 0, i32 2, i64 0
  br label %if_end_2534
if_end_2534:
  %t7 = phi i8* [ %t5, %if_then_2532 ], [ %t6, %if_else_2533 ]
  store i8* %t7, i8** %t1
  %t9 = load double, double* %t0
  %t10 = sitofp i32 0 to double
  %t11 = fcmp olt double %t9, %t10
  br i1 %t11, label %if_then_2535, label %if_else_2536
if_then_2535:
  %t12 = load double, double* %t0
  %t13 = fsub double 0.0, %t12
  br label %if_end_2537
if_else_2536:
  %t14 = load double, double* %t0
  br label %if_end_2537
if_end_2537:
  %t15 = phi double [ %t13, %if_then_2535 ], [ %t14, %if_else_2536 ]
  store double %t15, double* %t8
  %t17 = load double, double* %t8
  %t18 = fpext float 0x4059000000000000 to double
  %t19 = fmul double %t17, %t18
  %t20 = fpext float 0x3FE0000000000000 to double
  %t21 = fadd double %t19, %t20
  %t22 = call i64 @llvm.fptosi.sat.i64.f64(double %t21)
  store i64 %t22, i64* %t16
  %t24 = load i64, i64* %t16
  %t25 = sext i32 100 to i64
  %t26 = icmp eq i64 %t25, 0
  %t27 = icmp eq i64 %t24, -9223372036854775808
  %t28 = icmp eq i64 %t25, -1
  %t29 = and i1 %t27, %t28
  %t30 = or i1 %t26, %t29
  br i1 %t30, label %int_div_fail_2538, label %int_div_ok_2539
int_div_fail_2538:
  %t31 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.183, i64 0, i64 0
  call i32 @puts(i8* %t31)
  call void @exit(i32 1)
  unreachable
int_div_ok_2539:
  %t32 = sdiv i64 %t24, %t25
  store i64 %t32, i64* %t23
  %t34 = load i64, i64* %t16
  %t35 = sext i32 100 to i64
  %t36 = icmp eq i64 %t35, 0
  %t37 = icmp eq i64 %t34, -9223372036854775808
  %t38 = icmp eq i64 %t35, -1
  %t39 = and i1 %t37, %t38
  %t40 = or i1 %t36, %t39
  br i1 %t40, label %int_div_fail_2540, label %int_div_ok_2541
int_div_fail_2540:
  %t41 = getelementptr inbounds [69 x i8], [69 x i8]* @.str.184, i64 0, i64 0
  call i32 @puts(i8* %t41)
  call void @exit(i32 1)
  unreachable
int_div_ok_2541:
  %t42 = srem i64 %t34, %t35
  store i64 %t42, i64* %t33
  %t44 = load i64, i64* %t33
  %t45 = sext i32 10 to i64
  %t46 = icmp slt i64 %t44, %t45
  br i1 %t46, label %if_then_2542, label %if_else_2543
if_then_2542:
  %t47 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.185, i64 0, i32 2, i64 0
  %t48 = load i64, i64* %t33
  %t49 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.186, i64 0, i64 0
  %t50 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t49, i64 %t48)
  %t51 = add i32 %t50, 1
  %t52 = sext i32 %t51 to i64
  %t53 = call i8* @star_rc_alloc(i64 %t52, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t53, i64 %t52, i8* %t49, i64 %t48)
  %t54 = call i32 @strlen(i8* %t47)
  %t55 = call i32 @strlen(i8* %t53)
  %t56 = add i32 %t54, %t55
  %t57 = add i32 %t56, 1
  %t58 = sext i32 %t57 to i64
  %t59 = call i8* @star_rc_alloc(i64 %t58, i8* null)
  call i8* @strcpy(i8* %t59, i8* %t47)
  call i8* @strcat(i8* %t59, i8* %t53)
  call void @star_rc_release(i8* %t47)
  call void @star_rc_release(i8* %t53)
  br label %if_end_2544
if_else_2543:
  %t60 = load i64, i64* %t33
  %t61 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.187, i64 0, i64 0
  %t62 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t61, i64 %t60)
  %t63 = add i32 %t62, 1
  %t64 = sext i32 %t63 to i64
  %t65 = call i8* @star_rc_alloc(i64 %t64, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t65, i64 %t64, i8* %t61, i64 %t60)
  br label %if_end_2544
if_end_2544:
  %t66 = phi i8* [ %t59, %if_then_2542 ], [ %t65, %if_else_2543 ]
  store i8* %t66, i8** %t43
  %t67 = load i8*, i8** %t1
  %t68 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t68)
  %t69 = load i64, i64* %t23
  %t70 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.188, i64 0, i64 0
  %t71 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t70, i64 %t69)
  %t72 = add i32 %t71, 1
  %t73 = sext i32 %t72 to i64
  %t74 = call i8* @star_rc_alloc(i64 %t73, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t74, i64 %t73, i8* %t70, i64 %t69)
  %t75 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.189, i64 0, i32 2, i64 0
  %t76 = load i8*, i8** %t43
  %t77 = load i8*, i8** %t43
  call void @star_rc_retain(i8* %t77)
  %t78 = call i32 @strlen(i8* %t75)
  %t79 = call i32 @strlen(i8* %t76)
  %t80 = add i32 %t78, %t79
  %t81 = add i32 %t80, 1
  %t82 = sext i32 %t81 to i64
  %t83 = call i8* @star_rc_alloc(i64 %t82, i8* null)
  call i8* @strcpy(i8* %t83, i8* %t75)
  call i8* @strcat(i8* %t83, i8* %t76)
  call void @star_rc_release(i8* %t75)
  call void @star_rc_release(i8* %t76)
  %t84 = call i32 @strlen(i8* %t74)
  %t85 = call i32 @strlen(i8* %t83)
  %t86 = add i32 %t84, %t85
  %t87 = add i32 %t86, 1
  %t88 = sext i32 %t87 to i64
  %t89 = call i8* @star_rc_alloc(i64 %t88, i8* null)
  call i8* @strcpy(i8* %t89, i8* %t74)
  call i8* @strcat(i8* %t89, i8* %t83)
  call void @star_rc_release(i8* %t74)
  call void @star_rc_release(i8* %t83)
  %t90 = call i32 @strlen(i8* %t67)
  %t91 = call i32 @strlen(i8* %t89)
  %t92 = add i32 %t90, %t91
  %t93 = add i32 %t92, 1
  %t94 = sext i32 %t93 to i64
  %t95 = call i8* @star_rc_alloc(i64 %t94, i8* null)
  call i8* @strcpy(i8* %t95, i8* %t67)
  call i8* @strcat(i8* %t95, i8* %t89)
  call void @star_rc_release(i8* %t67)
  call void @star_rc_release(i8* %t89)
  %t96 = load i8*, i8** %t43
  call void @star_rc_release(i8* %t96)
  %t97 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t97)
  ret i8* %t95
}

define i8* @dump_token(%lex__tok__Token %t) {
entry:
  %t0 = alloca %lex__tok__Token
  %t1 = alloca i8*
  %t5 = alloca i8*
  %t14 = alloca i8*
  %t20 = alloca i8*
  %t25 = alloca i8*
  store %lex__tok__Token %t, %lex__tok__Token* %t0
  %t2 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 0
  %t3 = load i32, i32* %t2
  %t4 = call i8* @lex__tok__token_type_name(i32 %t3)
  store i8* %t4, i8** %t1
  %t6 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 0
  %t7 = load i32, i32* %t6
  %t8 = call i1 @eq_e_lex__tok__TokenType(i32 %t7, i32 95)
  br i1 %t8, label %if_then_2545, label %if_else_2546
if_then_2545:
  %t9 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 2
  %t10 = load double, double* %t9
  %t11 = call i8* @format_amount(double %t10)
  br label %if_end_2547
if_else_2546:
  %t12 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.190, i64 0, i32 2, i64 0
  br label %if_end_2547
if_end_2547:
  %t13 = phi i8* [ %t11, %if_then_2545 ], [ %t12, %if_else_2546 ]
  store i8* %t13, i8** %t5
  %t15 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 3
  %t16 = load i1, i1* %t15
  br i1 %t16, label %if_then_2548, label %if_else_2549
if_then_2548:
  %t17 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.191, i64 0, i32 2, i64 0
  br label %if_end_2550
if_else_2549:
  %t18 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.192, i64 0, i32 2, i64 0
  br label %if_end_2550
if_end_2550:
  %t19 = phi i8* [ %t17, %if_then_2548 ], [ %t18, %if_else_2549 ]
  store i8* %t19, i8** %t14
  %t21 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 4
  %t22 = load i8*, i8** %t21
  %t23 = load i8*, i8** %t21
  call void @star_rc_retain(i8* %t23)
  %t24 = call i8* @dump_escape(i8* %t22)
  store i8* %t24, i8** %t20
  %t26 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 1
  %t27 = load i8*, i8** %t26
  %t28 = load i8*, i8** %t26
  call void @star_rc_retain(i8* %t28)
  %t29 = call i8* @dump_escape(i8* %t27)
  store i8* %t29, i8** %t25
  %t30 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 5
  %t31 = load i32, i32* %t30
  %t32 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 6
  %t33 = load i32, i32* %t32
  %t34 = load i8*, i8** %t1
  %t35 = load i8*, i8** %t1
  call void @star_rc_retain(i8* %t35)
  %t36 = load i8*, i8** %t25
  %t37 = load i8*, i8** %t25
  call void @star_rc_retain(i8* %t37)
  %t38 = load i8*, i8** %t5
  %t39 = load i8*, i8** %t5
  call void @star_rc_retain(i8* %t39)
  %t40 = load i8*, i8** %t14
  %t41 = load i8*, i8** %t14
  call void @star_rc_retain(i8* %t41)
  %t42 = load i8*, i8** %t20
  %t43 = load i8*, i8** %t20
  call void @star_rc_retain(i8* %t43)
  %t44 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.193, i64 0, i64 0
  %t45 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t44, i32 %t31, i32 %t33, i8* %t34, i8* %t36, i8* %t38, i8* %t40, i8* %t42)
  %t46 = add i32 %t45, 1
  %t47 = sext i32 %t46 to i64
  %t48 = call i8* @star_rc_alloc(i64 %t47, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t48, i64 %t47, i8* %t44, i32 %t31, i32 %t33, i8* %t34, i8* %t36, i8* %t38, i8* %t40, i8* %t42)
  call void @star_rc_release(i8* %t34)
  call void @star_rc_release(i8* %t36)
  call void @star_rc_release(i8* %t38)
  call void @star_rc_release(i8* %t40)
  call void @star_rc_release(i8* %t42)
  %t49 = load i8*, i8** %t25
  call void @star_rc_release(i8* %t49)
  %t50 = load i8*, i8** %t20
  call void @star_rc_release(i8* %t50)
  %t51 = load i8*, i8** %t14
  call void @star_rc_release(i8* %t51)
  %t52 = load i8*, i8** %t5
  call void @star_rc_release(i8* %t52)
  %t53 = load i8*, i8** %t1
  call void @star_rc_release(i8* %t53)
  %t54 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 1
  %t55 = load i8*, i8** %t54
  call void @star_rc_release(i8* %t55)
  %t56 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t0, i32 0, i32 4
  %t57 = load i8*, i8** %t56
  call void @star_rc_release(i8* %t57)
  ret i8* %t48
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t9 = alloca i64
  %t40 = alloca i8*
  %t57 = alloca i8*
  %t83 = alloca i8*
  %t105 = alloca %Result__List_lex__tok__Token__lex__LexError
  %t116 = alloca i32
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = load i32, i32* @star.argc
  %t4 = sext i32 %t3 to i64
  %t5 = load i8**, i8*** @star.argv
  %t6 = mul i64 %t4, 8
  %t7 = call i8* @malloc(i64 %t6)
  %t8 = bitcast i8* %t7 to i8**
  store i64 0, i64* %t9
  br label %args_cond_2551
args_cond_2551:
  %t10 = load i64, i64* %t9
  %t11 = icmp slt i64 %t10, %t4
  br i1 %t11, label %args_body_2552, label %args_end_2553
args_body_2552:
  %t12 = getelementptr inbounds i8*, i8** %t5, i64 %t10
  %t13 = load i8*, i8** %t12
  %t14 = call i32 @strlen(i8* %t13)
  %t15 = add i32 %t14, 1
  %t16 = sext i32 %t15 to i64
  %t17 = call i8* @star_rc_alloc(i64 %t16, i8* null)
  call i8* @strcpy(i8* %t17, i8* %t13)
  %t18 = getelementptr inbounds i8*, i8** %t8, i64 %t10
  store i8* %t17, i8** %t18
  %t19 = add i64 %t10, 1
  store i64 %t19, i64* %t9
  br label %args_cond_2551
args_end_2553:
  %t20 = bitcast void (i8*)* @list_release_str to i8*
  %t21 = call i8* @star_rc_alloc(i64 24, i8* %t20)
  %t22 = bitcast i8* %t21 to { i8**, i64, i64 }*
  %t23 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t22, i32 0, i32 0
  store i8** %t8, i8*** %t23
  %t24 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t22, i32 0, i32 1
  store i64 %t4, i64* %t24
  %t25 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t22, i32 0, i32 2
  store i64 %t4, i64* %t25
  store i8* %t21, i8** %t2
  %t26 = load i8*, i8** %t2
  %t27 = icmp eq i8* %t26, null
  br i1 %t27, label %list_read_null_2554, label %list_read_real_2555
list_read_null_2554:
  br label %list_read_end_2556
list_read_real_2555:
  %t28 = bitcast i8* %t26 to { i8**, i64, i64 }*
  %t29 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t28, i32 0, i32 0
  %t30 = load i8**, i8*** %t29
  %t31 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t28, i32 0, i32 1
  %t32 = load i64, i64* %t31
  br label %list_read_end_2556
list_read_end_2556:
  %t33 = phi i8** [ null, %list_read_null_2554 ], [ %t30, %list_read_real_2555 ]
  %t34 = phi i64 [ 0, %list_read_null_2554 ], [ %t32, %list_read_real_2555 ]
  %t35 = trunc i64 %t34 to i32
  %t36 = icmp slt i32 %t35, 2
  br i1 %t36, label %if_then_2557, label %if_else_2558
if_then_2557:
  %t37 = getelementptr inbounds { i64, i8*, [33 x i8] }, { i64, i8*, [33 x i8] }* @.str.194, i64 0, i32 2, i64 0
  call i32 (i8*, ...) @printf(i8* %t37)
  call void @star_rc_release(i8* %t37)
  %t38 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.195, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t38)
  %t39 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t39)
  ret i32 1
if_else_2558:
  br label %if_end_2559
if_end_2559:
  %t41 = load i8*, i8** %t2
  %t42 = icmp eq i8* %t41, null
  br i1 %t42, label %list_read_null_2560, label %list_read_real_2561
list_read_null_2560:
  br label %list_read_end_2562
list_read_real_2561:
  %t43 = bitcast i8* %t41 to { i8**, i64, i64 }*
  %t44 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t43, i32 0, i32 0
  %t45 = load i8**, i8*** %t44
  %t46 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t43, i32 0, i32 1
  %t47 = load i64, i64* %t46
  br label %list_read_end_2562
list_read_end_2562:
  %t48 = phi i8** [ null, %list_read_null_2560 ], [ %t45, %list_read_real_2561 ]
  %t49 = phi i64 [ 0, %list_read_null_2560 ], [ %t47, %list_read_real_2561 ]
  %t50 = sext i32 1 to i64
  %t51 = icmp ult i64 %t50, %t49
  br i1 %t51, label %list_idx_ok_2563, label %list_idx_oob_2564
list_idx_ok_2563:
  %t52 = getelementptr inbounds i8*, i8** %t48, i64 %t50
  %t53 = load i8*, i8** %t52
  %t54 = load i8*, i8** %t52
  call void @star_rc_retain(i8* %t54)
  br label %list_idx_end_2565
list_idx_oob_2564:
  %t55 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t55
  br label %list_idx_end_2565
list_idx_end_2565:
  %t56 = phi i8* [ %t53, %list_idx_ok_2563 ], [ %t55, %list_idx_oob_2564 ]
  store i8* %t56, i8** %t40
  %t58 = load i8*, i8** %t40
  %t59 = load i8*, i8** %t40
  call void @star_rc_retain(i8* %t59)
  %t60 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.196, i64 0, i32 2, i64 0
  %t61 = call i8* @fopen(i8* %t58, i8* %t60)
  call void @star_rc_release(i8* %t58)
  call void @star_rc_release(i8* %t60)
  store i8* %t61, i8** %t57
  %t62 = load i8*, i8** %t57
  %t63 = icmp eq i8* %t62, null
  br i1 %t63, label %if_then_2566, label %if_else_2567
if_then_2566:
  %t64 = getelementptr inbounds { i64, i8*, [17 x i8] }, { i64, i8*, [17 x i8] }* @.str.197, i64 0, i32 2, i64 0
  %t65 = load i8*, i8** %t40
  %t66 = load i8*, i8** %t40
  call void @star_rc_retain(i8* %t66)
  %t67 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.198, i64 0, i32 2, i64 0
  %t68 = call i32 @strlen(i8* %t65)
  %t69 = call i32 @strlen(i8* %t67)
  %t70 = add i32 %t68, %t69
  %t71 = add i32 %t70, 1
  %t72 = sext i32 %t71 to i64
  %t73 = call i8* @star_rc_alloc(i64 %t72, i8* null)
  call i8* @strcpy(i8* %t73, i8* %t65)
  call i8* @strcat(i8* %t73, i8* %t67)
  call void @star_rc_release(i8* %t65)
  call void @star_rc_release(i8* %t67)
  %t74 = call i32 @strlen(i8* %t64)
  %t75 = call i32 @strlen(i8* %t73)
  %t76 = add i32 %t74, %t75
  %t77 = add i32 %t76, 1
  %t78 = sext i32 %t77 to i64
  %t79 = call i8* @star_rc_alloc(i64 %t78, i8* null)
  call i8* @strcpy(i8* %t79, i8* %t64)
  call i8* @strcat(i8* %t79, i8* %t73)
  call void @star_rc_release(i8* %t64)
  call void @star_rc_release(i8* %t73)
  call i32 (i8*, ...) @printf(i8* %t79)
  call void @star_rc_release(i8* %t79)
  %t80 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.199, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t80)
  %t81 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t81)
  %t82 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t82)
  ret i32 1
if_else_2567:
  br label %if_end_2568
if_end_2568:
  %t84 = load i8*, i8** %t57
  %t85 = icmp eq i8* %t84, null
  br i1 %t85, label %file_null_handle_2569, label %file_handle_ok_2570
file_null_handle_2569:
  %t86 = getelementptr inbounds [73 x i8], [73 x i8]* @.str.200, i64 0, i64 0
  call i32 @puts(i8* %t86)
  call void @exit(i32 1)
  unreachable
file_handle_ok_2570:
  %t87 = call i32 @ftell(i8* %t84)
  call i32 @fseek(i8* %t84, i32 0, i32 2)
  %t88 = call i32 @ftell(i8* %t84)
  call i32 @fseek(i8* %t84, i32 %t87, i32 0)
  %t89 = sub i32 %t88, %t87
  %t90 = sext i32 %t89 to i64
  %t91 = icmp sge i64 %t90, 0
  %t92 = select i1 %t91, i64 %t90, i64 0
  %t93 = add i64 %t92, 1
  %t94 = call i8* @star_rc_alloc(i64 %t93, i8* null)
  %t95 = call i64 @fread(i8* %t94, i64 1, i64 %t92, i8* %t84)
  %t96 = getelementptr inbounds i8, i8* %t94, i64 %t95
  store i8 0, i8* %t96
  store i8* %t94, i8** %t83
  %t97 = load i8*, i8** %t57
  %t98 = icmp eq i8* %t97, null
  br i1 %t98, label %file_null_handle_2571, label %file_handle_ok_2572
file_null_handle_2571:
  %t99 = getelementptr inbounds [74 x i8], [74 x i8]* @.str.201, i64 0, i64 0
  call i32 @puts(i8* %t99)
  call void @exit(i32 1)
  unreachable
file_handle_ok_2572:
  call i32 @fclose(i8* %t97)
  store i8* null, i8** %t57
  %t100 = load i8*, i8** %t83
  %t101 = load i8*, i8** %t83
  call void @star_rc_retain(i8* %t101)
  %t102 = load i8*, i8** %t40
  %t103 = load i8*, i8** %t40
  call void @star_rc_retain(i8* %t103)
  %t104 = call %Result__List_lex__tok__Token__lex__LexError @lex__lex(i8* %t100, i8* %t102)
  store %Result__List_lex__tok__Token__lex__LexError %t104, %Result__List_lex__tok__Token__lex__LexError* %t105
  br label %match_scrutinee_107
match_scrutinee_107:
  %t111 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t105, i32 0, i32 0
  %t112 = load i32, i32* %t111
  %t110 = icmp eq i32 %t112, 0
  br i1 %t110, label %match_then_0_108, label %match_next_0_109
match_then_0_108:
  %t113 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t105, i32 0, i32 1
  %t114 = bitcast [3 x i64]* %t113 to { i8* }*
  %t115 = getelementptr inbounds { i8* }, { i8* }* %t114, i32 0, i32 0
  store i32 0, i32* %t116
  br label %while_cond_2573
while_cond_2573:
  %t117 = load i32, i32* %t116
  %t118 = load i8*, i8** %t115
  %t119 = icmp eq i8* %t118, null
  br i1 %t119, label %list_read_null_2577, label %list_read_real_2578
list_read_null_2577:
  br label %list_read_end_2579
list_read_real_2578:
  %t120 = bitcast i8* %t118 to { %lex__tok__Token*, i64, i64 }*
  %t121 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t120, i32 0, i32 0
  %t122 = load %lex__tok__Token*, %lex__tok__Token** %t121
  %t123 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t120, i32 0, i32 1
  %t124 = load i64, i64* %t123
  br label %list_read_end_2579
list_read_end_2579:
  %t125 = phi %lex__tok__Token* [ null, %list_read_null_2577 ], [ %t122, %list_read_real_2578 ]
  %t126 = phi i64 [ 0, %list_read_null_2577 ], [ %t124, %list_read_real_2578 ]
  %t127 = trunc i64 %t126 to i32
  %t128 = icmp slt i32 %t117, %t127
  br i1 %t128, label %while_body_2574, label %while_else_2575
while_body_2574:
  %t129 = load i8*, i8** %t115
  %t130 = icmp eq i8* %t129, null
  br i1 %t130, label %list_read_null_2580, label %list_read_real_2581
list_read_null_2580:
  br label %list_read_end_2582
list_read_real_2581:
  %t131 = bitcast i8* %t129 to { %lex__tok__Token*, i64, i64 }*
  %t132 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t131, i32 0, i32 0
  %t133 = load %lex__tok__Token*, %lex__tok__Token** %t132
  %t134 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t131, i32 0, i32 1
  %t135 = load i64, i64* %t134
  br label %list_read_end_2582
list_read_end_2582:
  %t136 = phi %lex__tok__Token* [ null, %list_read_null_2580 ], [ %t133, %list_read_real_2581 ]
  %t137 = phi i64 [ 0, %list_read_null_2580 ], [ %t135, %list_read_real_2581 ]
  %t138 = load i32, i32* %t116
  %t139 = sext i32 %t138 to i64
  %t140 = icmp ult i64 %t139, %t137
  br i1 %t140, label %list_idx_ok_2583, label %list_idx_oob_2584
list_idx_ok_2583:
  %t141 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t136, i64 %t139
  %t142 = load %lex__tok__Token, %lex__tok__Token* %t141
  %t143 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t141, i32 0, i32 1
  %t144 = load i8*, i8** %t143
  call void @star_rc_retain(i8* %t144)
  %t145 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t141, i32 0, i32 4
  %t146 = load i8*, i8** %t145
  call void @star_rc_retain(i8* %t146)
  br label %list_idx_end_2585
list_idx_oob_2584:
  br label %list_idx_end_2585
list_idx_end_2585:
  %t147 = phi %lex__tok__Token [ %t142, %list_idx_ok_2583 ], [ zeroinitializer, %list_idx_oob_2584 ]
  %t148 = call i8* @dump_token(%lex__tok__Token %t147)
  call i32 (i8*, ...) @printf(i8* %t148)
  call void @star_rc_release(i8* %t148)
  %t149 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.202, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t149)
  %t150 = load i32, i32* %t116
  %t151 = add i32 %t150, 1
  store i32 %t151, i32* %t116
  br label %while_cond_2573
while_else_2575:
  br label %while_end_2576
while_end_2576:
  %t152 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t105, i32 0, i32 0
  %t153 = load i32, i32* %t152
  %t154 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t105, i32 0, i32 1
  %t155 = icmp eq i32 %t153, 0
  br i1 %t155, label %enum_rc_variant_2586, label %enum_rc_next_2587
enum_rc_variant_2586:
  %t156 = bitcast [3 x i64]* %t154 to { i8* }*
  %t157 = getelementptr inbounds { i8* }, { i8* }* %t156, i32 0, i32 0
  %t158 = load i8*, i8** %t157
  call void @star_rc_release(i8* %t158)
  br label %enum_rc_next_2587
enum_rc_next_2587:
  %t159 = icmp eq i32 %t153, 1
  br i1 %t159, label %enum_rc_variant_2588, label %enum_rc_next_2589
enum_rc_variant_2588:
  %t160 = bitcast [3 x i64]* %t154 to { %lex__LexError }*
  %t161 = getelementptr inbounds { %lex__LexError }, { %lex__LexError }* %t160, i32 0, i32 0
  %t162 = getelementptr inbounds %lex__LexError, %lex__LexError* %t161, i32 0, i32 0
  %t163 = load i8*, i8** %t162
  call void @star_rc_release(i8* %t163)
  %t164 = getelementptr inbounds %lex__LexError, %lex__LexError* %t161, i32 0, i32 1
  %t165 = load i8*, i8** %t164
  call void @star_rc_release(i8* %t165)
  br label %enum_rc_next_2589
enum_rc_next_2589:
  %t166 = load i8*, i8** %t83
  call void @star_rc_release(i8* %t166)
  %t167 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t167)
  %t168 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t168)
  ret i32 0
match_next_0_109:
  %t172 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t105, i32 0, i32 0
  %t173 = load i32, i32* %t172
  %t171 = icmp eq i32 %t173, 1
  br i1 %t171, label %match_then_1_169, label %match_next_1_170
match_then_1_169:
  %t174 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t105, i32 0, i32 1
  %t175 = bitcast [3 x i64]* %t174 to { %lex__LexError }*
  %t176 = getelementptr inbounds { %lex__LexError }, { %lex__LexError }* %t175, i32 0, i32 0
  %t177 = getelementptr inbounds { i64, i8*, [12 x i8] }, { i64, i8*, [12 x i8] }* @.str.203, i64 0, i32 2, i64 0
  %t178 = load %lex__LexError, %lex__LexError* %t176
  %t179 = getelementptr inbounds %lex__LexError, %lex__LexError* %t176, i32 0, i32 0
  %t180 = load i8*, i8** %t179
  call void @star_rc_retain(i8* %t180)
  %t181 = getelementptr inbounds %lex__LexError, %lex__LexError* %t176, i32 0, i32 1
  %t182 = load i8*, i8** %t181
  call void @star_rc_retain(i8* %t182)
  %t183 = call i8* @lex__format_lex_error(%lex__LexError %t178)
  %t184 = call i32 @strlen(i8* %t177)
  %t185 = call i32 @strlen(i8* %t183)
  %t186 = add i32 %t184, %t185
  %t187 = add i32 %t186, 1
  %t188 = sext i32 %t187 to i64
  %t189 = call i8* @star_rc_alloc(i64 %t188, i8* null)
  call i8* @strcpy(i8* %t189, i8* %t177)
  call i8* @strcat(i8* %t189, i8* %t183)
  call void @star_rc_release(i8* %t177)
  call void @star_rc_release(i8* %t183)
  call i32 (i8*, ...) @printf(i8* %t189)
  call void @star_rc_release(i8* %t189)
  %t190 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.204, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t190)
  %t191 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t105, i32 0, i32 0
  %t192 = load i32, i32* %t191
  %t193 = getelementptr inbounds %Result__List_lex__tok__Token__lex__LexError, %Result__List_lex__tok__Token__lex__LexError* %t105, i32 0, i32 1
  %t194 = icmp eq i32 %t192, 0
  br i1 %t194, label %enum_rc_variant_2590, label %enum_rc_next_2591
enum_rc_variant_2590:
  %t195 = bitcast [3 x i64]* %t193 to { i8* }*
  %t196 = getelementptr inbounds { i8* }, { i8* }* %t195, i32 0, i32 0
  %t197 = load i8*, i8** %t196
  call void @star_rc_release(i8* %t197)
  br label %enum_rc_next_2591
enum_rc_next_2591:
  %t198 = icmp eq i32 %t192, 1
  br i1 %t198, label %enum_rc_variant_2592, label %enum_rc_next_2593
enum_rc_variant_2592:
  %t199 = bitcast [3 x i64]* %t193 to { %lex__LexError }*
  %t200 = getelementptr inbounds { %lex__LexError }, { %lex__LexError }* %t199, i32 0, i32 0
  %t201 = getelementptr inbounds %lex__LexError, %lex__LexError* %t200, i32 0, i32 0
  %t202 = load i8*, i8** %t201
  call void @star_rc_release(i8* %t202)
  %t203 = getelementptr inbounds %lex__LexError, %lex__LexError* %t200, i32 0, i32 1
  %t204 = load i8*, i8** %t203
  call void @star_rc_release(i8* %t204)
  br label %enum_rc_next_2593
enum_rc_next_2593:
  %t205 = load i8*, i8** %t83
  call void @star_rc_release(i8* %t205)
  %t206 = load i8*, i8** %t40
  call void @star_rc_release(i8* %t206)
  %t207 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t207)
  ret i32 1
match_next_1_170:
  br label %match_end_106
match_end_106:
  unreachable
}


; par/swarm worker functions
define void @map_release_3_stre_lex__tok__TokenType(i8* %objp) {
entry:
  %t16 = alloca i64
  %t7 = bitcast i8* %objp to { i8**, i32*, i8*, i64, i64, i64 }*
  %t8 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7, i32 0, i32 0
  %t9 = load i8**, i8*** %t8
  %t10 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7, i32 0, i32 1
  %t11 = load i32*, i32** %t10
  %t12 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7, i32 0, i32 2
  %t13 = load i8*, i8** %t12
  %t14 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t7, i32 0, i32 4
  %t15 = load i64, i64* %t14
  store i64 0, i64* %t16
  br label %map_release_cond_3
map_release_cond_3:
  %t17 = load i64, i64* %t16
  %t18 = icmp slt i64 %t17, %t15
  br i1 %t18, label %map_release_body_4, label %map_release_end_7
map_release_body_4:
  %t19 = getelementptr inbounds i8, i8* %t13, i64 %t17
  %t20 = load i8, i8* %t19
  %t21 = icmp eq i8 %t20, 1
  br i1 %t21, label %map_release_occ_5, label %map_release_next_6
map_release_occ_5:
  %t22 = getelementptr inbounds i8*, i8** %t9, i64 %t17
  %t23 = load i8*, i8** %t22
  call void @star_rc_release(i8* %t23)
  br label %map_release_next_6
map_release_next_6:
  %t24 = add i64 %t17, 1
  store i64 %t24, i64* %t16
  br label %map_release_cond_3
map_release_end_7:
  %t25 = bitcast i8** %t9 to i8*
  call void @free(i8* %t25)
  %t26 = bitcast i32* %t11 to i8*
  call void @free(i8* %t26)
  call void @free(i8* %t13)
  ret void
}


define i64 @hash_str(i8* %v) {
entry:
  %t139 = alloca i64
  %t142 = alloca i64
  store i64 -3750763034362895579, i64* %t139
  %t140 = call i32 @strlen(i8* %v)
  %t141 = zext i32 %t140 to i64
  store i64 0, i64* %t142
  br label %hash_str_cond_26
hash_str_cond_26:
  %t143 = load i64, i64* %t142
  %t144 = icmp slt i64 %t143, %t141
  br i1 %t144, label %hash_str_body_27, label %hash_str_end_28
hash_str_body_27:
  %t145 = getelementptr inbounds i8, i8* %v, i64 %t143
  %t146 = load i8, i8* %t145
  %t147 = zext i8 %t146 to i64
  %t148 = load i64, i64* %t139
  %t149 = xor i64 %t148, %t147
  %t150 = mul i64 %t149, 1099511628211
  store i64 %t150, i64* %t139
  %t151 = add i64 %t143, 1
  store i64 %t151, i64* %t142
  br label %hash_str_cond_26
hash_str_end_28:
  %t152 = load i64, i64* %t139
  ret i64 %t152
}


define i1 @eq_str(i8* %a, i8* %b) {
entry:
  %t180 = call i32 @strcmp(i8* %a, i8* %b)
  %t181 = icmp eq i32 %t180, 0
  ret i1 %t181
}


define void @list_release_str(i8* %objp) {
entry:
  %t17 = alloca i64
  %t12 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t13 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t12, i32 0, i32 0
  %t14 = load i8**, i8*** %t13
  %t15 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t12, i32 0, i32 1
  %t16 = load i64, i64* %t15
  store i64 0, i64* %t17
  br label %list_release_cond_2085
list_release_cond_2085:
  %t18 = load i64, i64* %t17
  %t19 = icmp slt i64 %t18, %t16
  br i1 %t19, label %list_release_body_2086, label %list_release_end_2087
list_release_body_2086:
  %t20 = getelementptr inbounds i8*, i8** %t14, i64 %t18
  %t21 = load i8*, i8** %t20
  call void @star_rc_release(i8* %t21)
  %t22 = add i64 %t18, 1
  store i64 %t22, i64* %t17
  br label %list_release_cond_2085
list_release_end_2087:
  %t23 = bitcast i8** %t14 to i8*
  call void @free(i8* %t23)
  ret void
}


define void @list_release_s_lex__tok__Token(i8* %objp) {
entry:
  %t16 = alloca i64
  %t11 = bitcast i8* %objp to { %lex__tok__Token*, i64, i64 }*
  %t12 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t11, i32 0, i32 0
  %t13 = load %lex__tok__Token*, %lex__tok__Token** %t12
  %t14 = getelementptr inbounds { %lex__tok__Token*, i64, i64 }, { %lex__tok__Token*, i64, i64 }* %t11, i32 0, i32 1
  %t15 = load i64, i64* %t14
  store i64 0, i64* %t16
  br label %list_release_cond_2174
list_release_cond_2174:
  %t17 = load i64, i64* %t16
  %t18 = icmp slt i64 %t17, %t15
  br i1 %t18, label %list_release_body_2175, label %list_release_end_2176
list_release_body_2175:
  %t19 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t13, i64 %t17
  %t20 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t19, i32 0, i32 1
  %t21 = load i8*, i8** %t20
  call void @star_rc_release(i8* %t21)
  %t22 = getelementptr inbounds %lex__tok__Token, %lex__tok__Token* %t19, i32 0, i32 4
  %t23 = load i8*, i8** %t22
  call void @star_rc_release(i8* %t23)
  %t24 = add i64 %t17, 1
  store i64 %t24, i64* %t16
  br label %list_release_cond_2174
list_release_end_2176:
  %t25 = bitcast %lex__tok__Token* %t13 to i8*
  call void @free(i8* %t25)
  ret void
}


define i1 @eq_e_lex__tok__TokenType(i32 %a, i32 %b) {
entry:
  %t27 = icmp eq i32 %a, %b
  ret i1 %t27
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"clrdraw\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"pxloff\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"pxlon\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"line\00" }
@.str.4 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"circle\00" }
@.str.5 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"text\00" }
@.str.6 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"setlayer\00" }
@.str.7 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"scrroll\00" }
@.str.8 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"scrrotate\00" }
@.str.9 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"scrshift\00" }
@.str.10 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"scrflip\00" }
@.str.11 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"spriteon\00" }
@.str.12 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"spriteoff\00" }
@.str.13 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"playtone\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"playwave\00" }
@.str.15 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"stopsound\00" }
@.str.16 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"setchannel\00" }
@.str.17 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"getkey\00" }
@.str.18 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"serout\00" }
@.str.19 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"serin\00" }
@.str.20 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"serstat\00" }
@.str.21 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"serctrl\00" }
@.str.22 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"input\00" }
@.str.23 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"disp\00" }
@.str.24 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"pause\00" }
@.str.25 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"if\00" }
@.str.26 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"then\00" }
@.str.27 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"else\00" }
@.str.28 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"end\00" }
@.str.29 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"for\00" }
@.str.30 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"to\00" }
@.str.31 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"step\00" }
@.str.32 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"next\00" }
@.str.33 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"while\00" }
@.str.34 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"repeat\00" }
@.str.35 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"until\00" }
@.str.36 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"goto\00" }
@.str.37 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"dim\00" }
@.str.38 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"let\00" }
@.str.39 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"struct\00" }
@.str.40 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"global\00" }
@.str.41 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"local\00" }
@.str.42 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"asm\00" }
@.str.43 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"function\00" }
@.str.44 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"return\00" }
@.str.45 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"and\00" }
@.str.46 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"or\00" }
@.str.47 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"not\00" }
@.str.48 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"CLRDRAW\00" }
@.str.49 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"PXLOFF\00" }
@.str.50 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"PXLON\00" }
@.str.51 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"LINE\00" }
@.str.52 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"CIRCLE\00" }
@.str.53 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"TEXT\00" }
@.str.54 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"SETLAYER\00" }
@.str.55 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"SCRROLL\00" }
@.str.56 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"SCRROTATE\00" }
@.str.57 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"SCRSHIFT\00" }
@.str.58 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"SCRFLIP\00" }
@.str.59 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"SPRITEON\00" }
@.str.60 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"SPRITEOFF\00" }
@.str.61 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"PLAYTONE\00" }
@.str.62 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"PLAYWAVE\00" }
@.str.63 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"STOPSOUND\00" }
@.str.64 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"SETCHANNEL\00" }
@.str.65 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"GETKEY\00" }
@.str.66 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"INPUT\00" }
@.str.67 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"DISP\00" }
@.str.68 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"PAUSE\00" }
@.str.69 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"SEROUT\00" }
@.str.70 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"SERIN\00" }
@.str.71 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"SERSTAT\00" }
@.str.72 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"SERCTRL\00" }
@.str.73 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"IF\00" }
@.str.74 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"THEN\00" }
@.str.75 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"ELSE\00" }
@.str.76 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"END\00" }
@.str.77 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"FOR\00" }
@.str.78 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"TO\00" }
@.str.79 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"STEP\00" }
@.str.80 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"NEXT\00" }
@.str.81 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"WHILE\00" }
@.str.82 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"REPEAT\00" }
@.str.83 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"UNTIL\00" }
@.str.84 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"GOTO\00" }
@.str.85 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"DIM\00" }
@.str.86 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"LET\00" }
@.str.87 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"STRUCT\00" }
@.str.88 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"GLOBAL\00" }
@.str.89 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"LOCAL\00" }
@.str.90 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"ASM\00" }
@.str.91 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"FUNCTION\00" }
@.str.92 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"RETURN\00" }
@.str.93 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"SIN\00" }
@.str.94 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"COS\00" }
@.str.95 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"TAN\00" }
@.str.96 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"SQRT\00" }
@.str.97 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"ABS\00" }
@.str.98 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"INT\00" }
@.str.99 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"ROUND\00" }
@.str.100 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"RAND\00" }
@.str.101 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"RNDR\00" }
@.str.102 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"RANDOMIZE\00" }
@.str.103 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"LENGTH\00" }
@.str.104 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"SUB\00" }
@.str.105 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"CONCAT\00" }
@.str.106 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"SUM\00" }
@.str.107 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"MEAN\00" }
@.str.108 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"MEMREAD\00" }
@.str.109 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"MEMWRITE\00" }
@.str.110 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"INSTRING\00" }
@.str.111 = private unnamed_addr constant { i64, i8*, [9 x i8] } { i64 -1, i8* null, [9 x i8] c"UPSTRING\00" }
@.str.112 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"LOWSTRING\00" }
@.str.113 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"LENSTRING\00" }
@.str.114 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"+\00" }
@.str.115 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"-\00" }
@.str.116 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"*\00" }
@.str.117 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"/\00" }
@.str.118 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"^\00" }
@.str.119 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"=\00" }
@.str.120 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"<>\00" }
@.str.121 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"<\00" }
@.str.122 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"<=\00" }
@.str.123 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c">\00" }
@.str.124 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c">=\00" }
@.str.125 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"&\00" }
@.str.126 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"|\00" }
@.str.127 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"<<\00" }
@.str.128 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c">>\00" }
@.str.129 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"AND\00" }
@.str.130 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"OR\00" }
@.str.131 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"NOT\00" }
@.str.132 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"++\00" }
@.str.133 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"--\00" }
@.str.134 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"(\00" }
@.str.135 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c")\00" }
@.str.136 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"[\00" }
@.str.137 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"]\00" }
@.str.138 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c",\00" }
@.str.139 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\22\00" }
@.str.140 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c":\00" }
@.str.141 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"@\00" }
@.str.142 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c".\00" }
@.str.143 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"NUMBER_LITERAL\00" }
@.str.144 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"STRING_LITERAL\00" }
@.str.145 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"IDENTIFIER\00" }
@.str.146 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"ASM_BLOCK\00" }
@.str.147 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"EOF\00" }
@.str.148 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"COMMENT\00" }
@.str.149 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"WHITESPACE\00" }
@.str.150 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"<stdin>\00" }
@.str.151 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"Error: \00" }
@.str.152 = private unnamed_addr constant [38 x i8] c"Error in %s at line %d, column %d: %s\00"
@.str.153 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.154 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\0A\00" }
@.str.155 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\00" }
@.str.156 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"	\00" }
@.str.157 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\22\00" }
@.str.158 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\\\00" }
@.str.159 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.160 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.161 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.162 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.163 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"Invalid hexadecimal number\00" }
@.str.164 = private unnamed_addr constant { i64, i8*, [22 x i8] } { i64 -1, i8* null, [22 x i8] c"Invalid binary number\00" }
@.str.165 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.166 = private unnamed_addr constant { i64, i8*, [20 x i8] } { i64 -1, i8* null, [20 x i8] c"Unterminated string\00" }
@.str.167 = private unnamed_addr constant { i64, i8*, [20 x i8] } { i64 -1, i8* null, [20 x i8] c"Unterminated string\00" }
@.str.168 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"end\00" }
@.str.169 = private unnamed_addr constant { i64, i8*, [39 x i8] } { i64 -1, i8* null, [39 x i8] c"Unterminated Asm block (missing 'End')\00" }
@.str.170 = private unnamed_addr constant { i64, i8*, [23 x i8] } { i64 -1, i8* null, [23 x i8] c"Unexpected character: \00" }
@.str.171 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.172 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.173 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\\\00" }
@.str.174 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"\\\\\00" }
@.str.175 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\0A\00" }
@.str.176 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"\\n\00" }
@.str.177 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"\00" }
@.str.178 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"\\r\00" }
@.str.179 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"	\00" }
@.str.180 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"\\t\00" }
@.str.181 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"-\00" }
@.str.182 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.183 = private unnamed_addr constant [69 x i8] c"star runtime error: integer `/` by zero (or i64::MIN / -1 overflow)\0A\00"
@.str.184 = private unnamed_addr constant [69 x i8] c"star runtime error: integer `%` by zero (or i64::MIN % -1 overflow)\0A\00"
@.str.185 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"0\00" }
@.str.186 = private unnamed_addr constant [5 x i8] c"%lld\00"
@.str.187 = private unnamed_addr constant [5 x i8] c"%lld\00"
@.str.188 = private unnamed_addr constant [5 x i8] c"%lld\00"
@.str.189 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c".\00" }
@.str.190 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"0.00\00" }
@.str.191 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"1\00" }
@.str.192 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"0\00" }
@.str.193 = private unnamed_addr constant [44 x i8] c"%d:%d %s lexeme=\22%s\22 num=%s isf=%s str=\22%s\22\00"
@.str.194 = private unnamed_addr constant { i64, i8*, [33 x i8] } { i64 -1, i8* null, [33 x i8] c"usage: lexer_dump <path.nobasic>\00" }
@.str.195 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.196 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"r\00" }
@.str.197 = private unnamed_addr constant { i64, i8*, [17 x i8] } { i64 -1, i8* null, [17 x i8] c"could not open '\00" }
@.str.198 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"'\00" }
@.str.199 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.200 = private unnamed_addr constant [73 x i8] c"star runtime error: file_read(..) called with a null/closed file handle\0A\00"
@.str.201 = private unnamed_addr constant [74 x i8] c"star runtime error: file_close(..) called with a null/closed file handle\0A\00"
@.str.202 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.203 = private unnamed_addr constant { i64, i8*, [12 x i8] } { i64 -1, i8* null, [12 x i8] c"LEX ERROR: \00" }
@.str.204 = private unnamed_addr constant [2 x i8] c"\0A\00"
