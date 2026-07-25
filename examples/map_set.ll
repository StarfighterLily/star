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

%Point = type { i32, i32 }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
%Option__i32 = type { i32, [1 x i64] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t70 = alloca i64
  %t123 = alloca i64
  %t131 = alloca i64
  %t157 = alloca i64
  %t158 = alloca i64
  %t184 = alloca i64
  %t185 = alloca i64
  %t186 = alloca i1
  %t187 = alloca i64
  %t188 = alloca i64
  %t189 = alloca i1
  %t208 = alloca i8*
  %t267 = alloca i64
  %t320 = alloca i64
  %t328 = alloca i64
  %t340 = alloca i64
  %t341 = alloca i64
  %t365 = alloca i64
  %t366 = alloca i64
  %t367 = alloca i1
  %t368 = alloca i64
  %t369 = alloca i64
  %t370 = alloca i1
  %t389 = alloca i8*
  %t443 = alloca i64
  %t444 = alloca i64
  %t445 = alloca i1
  %t446 = alloca i64
  %t447 = alloca i64
  %t448 = alloca i1
  %t467 = alloca i8*
  %t471 = alloca %Option__i32
  %t477 = alloca %Option__i32
  %t481 = alloca %Option__i32
  %t523 = alloca i64
  %t524 = alloca i64
  %t525 = alloca i1
  %t526 = alloca i64
  %t527 = alloca i64
  %t528 = alloca i1
  %t547 = alloca i8*
  %t551 = alloca %Option__i32
  %t557 = alloca %Option__i32
  %t561 = alloca %Option__i32
  %t628 = alloca i64
  %t681 = alloca i64
  %t689 = alloca i64
  %t701 = alloca i64
  %t702 = alloca i64
  %t726 = alloca i64
  %t727 = alloca i64
  %t728 = alloca i1
  %t729 = alloca i64
  %t730 = alloca i64
  %t731 = alloca i1
  %t750 = alloca i8*
  %t804 = alloca i64
  %t805 = alloca i64
  %t806 = alloca i1
  %t807 = alloca i64
  %t808 = alloca i64
  %t809 = alloca i1
  %t828 = alloca i8*
  %t832 = alloca %Option__i32
  %t838 = alloca %Option__i32
  %t842 = alloca %Option__i32
  %t862 = alloca i8*
  %t887 = alloca i64
  %t888 = alloca i64
  %t889 = alloca i1
  %t890 = alloca i64
  %t891 = alloca i64
  %t892 = alloca i1
  %t911 = alloca i8*
  %t964 = alloca i64
  %t1001 = alloca i64
  %t1002 = alloca i64
  %t1003 = alloca i1
  %t1004 = alloca i64
  %t1005 = alloca i64
  %t1006 = alloca i1
  %t1025 = alloca i8*
  %t1036 = alloca %Option__i32
  %t1042 = alloca %Option__i32
  %t1046 = alloca %Option__i32
  %t1089 = alloca i64
  %t1090 = alloca i64
  %t1091 = alloca i1
  %t1092 = alloca i64
  %t1093 = alloca i64
  %t1094 = alloca i1
  %t1113 = alloca i8*
  %t1139 = alloca i8*
  %t1220 = alloca i64
  %t1227 = alloca i64
  %t1243 = alloca i64
  %t1244 = alloca i64
  %t1266 = alloca i64
  %t1267 = alloca i64
  %t1268 = alloca i1
  %t1269 = alloca i64
  %t1270 = alloca i64
  %t1271 = alloca i1
  %t1375 = alloca i64
  %t1382 = alloca i64
  %t1392 = alloca i64
  %t1393 = alloca i64
  %t1414 = alloca i64
  %t1415 = alloca i64
  %t1416 = alloca i1
  %t1417 = alloca i64
  %t1418 = alloca i64
  %t1419 = alloca i1
  %t1523 = alloca i64
  %t1530 = alloca i64
  %t1540 = alloca i64
  %t1541 = alloca i64
  %t1562 = alloca i64
  %t1563 = alloca i64
  %t1564 = alloca i1
  %t1565 = alloca i64
  %t1566 = alloca i64
  %t1567 = alloca i1
  %t1634 = alloca i64
  %t1635 = alloca i64
  %t1636 = alloca i1
  %t1637 = alloca i64
  %t1638 = alloca i64
  %t1639 = alloca i1
  %t1722 = alloca i64
  %t1723 = alloca i64
  %t1724 = alloca i1
  %t1725 = alloca i64
  %t1726 = alloca i64
  %t1727 = alloca i1
  %t1774 = alloca i64
  %t1775 = alloca i64
  %t1776 = alloca i1
  %t1777 = alloca i64
  %t1778 = alloca i64
  %t1779 = alloca i1
  %t1862 = alloca i64
  %t1863 = alloca i64
  %t1864 = alloca i1
  %t1865 = alloca i64
  %t1866 = alloca i64
  %t1867 = alloca i1
  %t1913 = alloca i8*
  %t1976 = alloca %Point
  %t1998 = alloca i64
  %t2005 = alloca i64
  %t2027 = alloca i64
  %t2028 = alloca i64
  %t2056 = alloca i64
  %t2057 = alloca i64
  %t2058 = alloca i1
  %t2059 = alloca i64
  %t2060 = alloca i64
  %t2061 = alloca i1
  %t2143 = alloca %Point
  %t2165 = alloca i64
  %t2172 = alloca i64
  %t2182 = alloca i64
  %t2183 = alloca i64
  %t2204 = alloca i64
  %t2205 = alloca i64
  %t2206 = alloca i1
  %t2207 = alloca i64
  %t2208 = alloca i64
  %t2209 = alloca i1
  %t2291 = alloca %Point
  %t2313 = alloca i64
  %t2320 = alloca i64
  %t2330 = alloca i64
  %t2331 = alloca i64
  %t2352 = alloca i64
  %t2353 = alloca i64
  %t2354 = alloca i1
  %t2355 = alloca i64
  %t2356 = alloca i64
  %t2357 = alloca i1
  %t2402 = alloca %Point
  %t2424 = alloca i64
  %t2425 = alloca i64
  %t2426 = alloca i1
  %t2427 = alloca i64
  %t2428 = alloca i64
  %t2429 = alloca i1
  %t2452 = alloca %Point
  %t2474 = alloca i64
  %t2475 = alloca i64
  %t2476 = alloca i1
  %t2477 = alloca i64
  %t2478 = alloca i64
  %t2479 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i8* null, i8** %t2
  %t3 = getelementptr i8*, i8** null, i32 1
  %t4 = ptrtoint i8** %t3 to i64
  %t5 = getelementptr i32, i32* null, i32 1
  %t6 = ptrtoint i32* %t5 to i64
  %t7 = load i8*, i8** %t2
  %t8 = icmp eq i8* %t7, null
  br i1 %t8, label %map_cow_alloc_0, label %map_cow_check_1
map_cow_alloc_0:
  %t29 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t30 = call i8* @star_rc_alloc(i64 48, i8* %t29)
  %t31 = bitcast i8* %t30 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t32 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t31, i32 0, i32 0
  store i8** null, i8*** %t32
  %t33 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t31, i32 0, i32 1
  store i32* null, i32** %t33
  %t34 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t31, i32 0, i32 2
  store i8* null, i8** %t34
  %t35 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t31, i32 0, i32 3
  store i64 0, i64* %t35
  %t36 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t31, i32 0, i32 4
  store i64 0, i64* %t36
  %t37 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t31, i32 0, i32 5
  store i64 0, i64* %t37
  store i8* %t30, i8** %t2
  br label %map_cow_done_2
map_cow_check_1:
  %t38 = getelementptr inbounds i8, i8* %t7, i64 -16
  %t39 = bitcast i8* %t38 to i64*
  %t40 = load atomic i64, i64* %t39 seq_cst, align 8
  %t41 = icmp eq i64 %t40, 1
  br i1 %t41, label %map_cow_done_2, label %map_cow_clone_8
map_cow_clone_8:
  %t42 = bitcast i8* %t7 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t43 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t42, i32 0, i32 0
  %t44 = load i8**, i8*** %t43
  %t45 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t42, i32 0, i32 1
  %t46 = load i32*, i32** %t45
  %t47 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t42, i32 0, i32 2
  %t48 = load i8*, i8** %t47
  %t49 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t42, i32 0, i32 3
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t42, i32 0, i32 4
  %t52 = load i64, i64* %t51
  %t53 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t42, i32 0, i32 5
  %t54 = load i64, i64* %t53
  %t55 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t56 = call i8* @star_rc_alloc(i64 48, i8* %t55)
  %t57 = bitcast i8* %t56 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t58 = mul i64 %t52, %t4
  %t59 = call i8* @malloc(i64 %t58)
  %t60 = bitcast i8* %t59 to i8**
  %t61 = mul i64 %t52, %t6
  %t62 = call i8* @malloc(i64 %t61)
  %t63 = bitcast i8* %t62 to i32*
  %t64 = call i8* @malloc(i64 %t52)
  %t65 = icmp sgt i64 %t52, 0
  br i1 %t65, label %map_cow_copy_9, label %map_cow_after_copy_10
map_cow_copy_9:
  %t66 = mul i64 %t52, %t4
  %t67 = bitcast i8** %t44 to i8*
  call i8* @memcpy(i8* %t59, i8* %t67, i64 %t66)
  %t68 = mul i64 %t52, %t6
  %t69 = bitcast i32* %t46 to i8*
  call i8* @memcpy(i8* %t62, i8* %t69, i64 %t68)
  call i8* @memcpy(i8* %t64, i8* %t48, i64 %t52)
  store i64 0, i64* %t70
  br label %map_cow_retain_cond_11
map_cow_retain_cond_11:
  %t71 = load i64, i64* %t70
  %t72 = icmp slt i64 %t71, %t52
  br i1 %t72, label %map_cow_retain_body_12, label %map_cow_retain_end_15
map_cow_retain_body_12:
  %t73 = getelementptr inbounds i8, i8* %t64, i64 %t71
  %t74 = load i8, i8* %t73
  %t75 = icmp eq i8 %t74, 1
  br i1 %t75, label %map_cow_retain_occ_13, label %map_cow_retain_next_14
map_cow_retain_occ_13:
  %t76 = getelementptr inbounds i8*, i8** %t60, i64 %t71
  %t77 = load i8*, i8** %t76
  call void @star_rc_retain(i8* %t77)
  br label %map_cow_retain_next_14
map_cow_retain_next_14:
  %t78 = add i64 %t71, 1
  store i64 %t78, i64* %t70
  br label %map_cow_retain_cond_11
map_cow_retain_end_15:
  br label %map_cow_after_copy_10
map_cow_after_copy_10:
  %t79 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t57, i32 0, i32 0
  store i8** %t60, i8*** %t79
  %t80 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t57, i32 0, i32 1
  store i32* %t63, i32** %t80
  %t81 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t57, i32 0, i32 2
  store i8* %t64, i8** %t81
  %t82 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t57, i32 0, i32 3
  store i64 %t50, i64* %t82
  %t83 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t57, i32 0, i32 4
  store i64 %t52, i64* %t83
  %t84 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t57, i32 0, i32 5
  store i64 %t54, i64* %t84
  call void @star_rc_release(i8* %t7)
  store i8* %t56, i8** %t2
  br label %map_cow_done_2
map_cow_done_2:
  %t85 = load i8*, i8** %t2
  %t86 = bitcast i8* %t85 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t87 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t86, i32 0, i32 0
  %t88 = load i8**, i8*** %t87
  %t89 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t86, i32 0, i32 1
  %t90 = load i32*, i32** %t89
  %t91 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t86, i32 0, i32 2
  %t92 = load i8*, i8** %t91
  %t93 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t86, i32 0, i32 3
  %t94 = load i64, i64* %t93
  %t95 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t86, i32 0, i32 4
  %t96 = load i64, i64* %t95
  %t97 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t86, i32 0, i32 5
  %t98 = load i64, i64* %t97
  %t99 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t100 = load i64, i64* %t93
  %t101 = load i64, i64* %t95
  %t102 = load i64, i64* %t97
  %t103 = add i64 %t100, %t102
  %t104 = add i64 %t103, 1
  %t105 = mul i64 %t104, 4
  %t106 = mul i64 %t101, 3
  %t107 = icmp sgt i64 %t105, %t106
  br i1 %t107, label %map_insert_grow_16, label %map_insert_after_grow_17
map_insert_grow_16:
  %t108 = getelementptr i8*, i8** null, i32 1
  %t109 = ptrtoint i8** %t108 to i64
  %t110 = getelementptr i32, i32* null, i32 1
  %t111 = ptrtoint i32* %t110 to i64
  %t112 = mul i64 %t101, 2
  %t113 = icmp sgt i64 %t112, 0
  %t114 = select i1 %t113, i64 %t112, i64 8
  %t115 = sub i64 %t114, 1
  %t116 = mul i64 %t114, %t109
  %t117 = call i8* @malloc(i64 %t116)
  %t118 = bitcast i8* %t117 to i8**
  %t119 = mul i64 %t114, %t111
  %t120 = call i8* @malloc(i64 %t119)
  %t121 = bitcast i8* %t120 to i32*
  %t122 = call i8* @malloc(i64 %t114)
  store i64 0, i64* %t123
  br label %ht_fill8_cond_18
ht_fill8_cond_18:
  %t124 = load i64, i64* %t123
  %t125 = icmp slt i64 %t124, %t114
  br i1 %t125, label %ht_fill8_body_19, label %ht_fill8_end_20
ht_fill8_body_19:
  %t126 = getelementptr inbounds i8, i8* %t122, i64 %t124
  store i8 0, i8* %t126
  %t127 = add i64 %t124, 1
  store i64 %t127, i64* %t123
  br label %ht_fill8_cond_18
ht_fill8_end_20:
  %t128 = load i8**, i8*** %t87
  %t129 = load i32*, i32** %t89
  %t130 = load i8*, i8** %t91
  store i64 0, i64* %t131
  br label %map_grow_cond_21
map_grow_cond_21:
  %t132 = load i64, i64* %t131
  %t133 = icmp slt i64 %t132, %t101
  br i1 %t133, label %map_grow_body_22, label %map_grow_end_25
map_grow_body_22:
  %t134 = getelementptr inbounds i8, i8* %t130, i64 %t132
  %t135 = load i8, i8* %t134
  %t136 = icmp eq i8 %t135, 1
  br i1 %t136, label %map_grow_occ_23, label %map_grow_next_24
map_grow_occ_23:
  %t137 = getelementptr inbounds i8*, i8** %t128, i64 %t132
  %t138 = load i8*, i8** %t137
  %t139 = getelementptr inbounds i32, i32* %t129, i64 %t132
  %t140 = load i32, i32* %t139
  %t155 = call i64 @hash_str(i8* %t138)
  %t156 = and i64 %t155, %t115
  store i64 0, i64* %t157
  store i64 %t156, i64* %t158
  br label %ht_fe_cond_29
ht_fe_cond_29:
  %t159 = load i64, i64* %t157
  %t160 = icmp slt i64 %t159, %t114
  br i1 %t160, label %ht_fe_body_30, label %ht_fe_end_32
ht_fe_body_30:
  %t161 = load i64, i64* %t158
  %t162 = getelementptr inbounds i8, i8* %t122, i64 %t161
  %t163 = load i8, i8* %t162
  %t164 = icmp eq i8 %t163, 0
  br i1 %t164, label %ht_fe_end_32, label %ht_fe_next_31
ht_fe_next_31:
  %t165 = add i64 %t161, 1
  %t166 = and i64 %t165, %t115
  store i64 %t166, i64* %t158
  %t167 = add i64 %t159, 1
  store i64 %t167, i64* %t157
  br label %ht_fe_cond_29
ht_fe_end_32:
  %t168 = load i64, i64* %t158
  %t169 = getelementptr inbounds i8, i8* %t122, i64 %t168
  store i8 1, i8* %t169
  %t170 = getelementptr inbounds i8*, i8** %t118, i64 %t168
  store i8* %t138, i8** %t170
  %t171 = getelementptr inbounds i32, i32* %t121, i64 %t168
  store i32 %t140, i32* %t171
  br label %map_grow_next_24
map_grow_next_24:
  %t172 = add i64 %t132, 1
  store i64 %t172, i64* %t131
  br label %map_grow_cond_21
map_grow_end_25:
  %t173 = bitcast i8** %t128 to i8*
  call void @free(i8* %t173)
  %t174 = bitcast i32* %t129 to i8*
  call void @free(i8* %t174)
  call void @free(i8* %t130)
  store i8** %t118, i8*** %t87
  store i32* %t121, i32** %t89
  store i8* %t122, i8** %t91
  store i64 %t114, i64* %t95
  store i64 0, i64* %t97
  br label %map_insert_after_grow_17
map_insert_after_grow_17:
  %t175 = load i8**, i8*** %t87
  %t176 = load i32*, i32** %t89
  %t177 = load i8*, i8** %t91
  %t178 = load i64, i64* %t95
  %t179 = sub i64 %t178, 1
  %t180 = call i64 @hash_str(i8* %t99)
  %t181 = and i64 %t180, %t179
  store i64 0, i64* %t184
  store i64 %t181, i64* %t185
  store i1 false, i1* %t186
  store i64 -1, i64* %t187
  store i64 -1, i64* %t188
  store i1 false, i1* %t189
  br label %ht_probe_cond_33
ht_probe_cond_33:
  %t190 = load i64, i64* %t184
  %t191 = icmp slt i64 %t190, %t178
  br i1 %t191, label %ht_probe_body_34, label %ht_probe_end_44
ht_probe_body_34:
  %t192 = load i64, i64* %t185
  %t193 = getelementptr inbounds i8, i8* %t177, i64 %t192
  %t194 = load i8, i8* %t193
  %t195 = icmp eq i8 %t194, 0
  br i1 %t195, label %ht_probe_on_empty_36, label %ht_probe_check_occ_35
ht_probe_check_occ_35:
  %t196 = icmp eq i8 %t194, 1
  br i1 %t196, label %ht_probe_on_occ_39, label %ht_probe_on_tomb_41
ht_probe_on_empty_36:
  %t197 = load i1, i1* %t189
  br i1 %t197, label %ht_probe_after_islot_empty_38, label %ht_probe_set_islot_empty_37
ht_probe_set_islot_empty_37:
  store i64 %t192, i64* %t188
  store i1 true, i1* %t189
  br label %ht_probe_after_islot_empty_38
ht_probe_after_islot_empty_38:
  br label %ht_probe_end_44
ht_probe_on_occ_39:
  %t198 = getelementptr inbounds i8*, i8** %t175, i64 %t192
  %t199 = load i8*, i8** %t198
  %t200 = call i1 @eq_str(i8* %t199, i8* %t99)
  br i1 %t200, label %ht_probe_on_match_40, label %ht_probe_next_43
ht_probe_on_match_40:
  store i1 true, i1* %t186
  store i64 %t192, i64* %t187
  br label %ht_probe_end_44
ht_probe_on_tomb_41:
  %t201 = load i1, i1* %t189
  br i1 %t201, label %ht_probe_next_43, label %ht_probe_set_islot_tomb_42
ht_probe_set_islot_tomb_42:
  store i64 %t192, i64* %t188
  store i1 true, i1* %t189
  br label %ht_probe_next_43
ht_probe_next_43:
  %t202 = add i64 %t192, 1
  %t203 = and i64 %t202, %t179
  store i64 %t203, i64* %t185
  %t204 = add i64 %t190, 1
  store i64 %t204, i64* %t184
  br label %ht_probe_cond_33
ht_probe_end_44:
  %t205 = load i1, i1* %t186
  %t206 = load i64, i64* %t187
  %t207 = load i64, i64* %t188
  br i1 %t205, label %map_insert_overwrite_45, label %map_insert_new_46
map_insert_overwrite_45:
  store i8* %t99, i8** %t208
  %t209 = load i8*, i8** %t208
  call void @star_rc_release(i8* %t209)
  %t210 = getelementptr inbounds i32, i32* %t176, i64 %t206
  store i32 30, i32* %t210
  br label %map_insert_after_47
map_insert_new_46:
  %t211 = getelementptr inbounds i8, i8* %t177, i64 %t207
  %t212 = load i8, i8* %t211
  %t213 = icmp eq i8 %t212, 2
  br i1 %t213, label %map_insert_dec_tomb_48, label %map_insert_store_49
map_insert_dec_tomb_48:
  %t214 = load i64, i64* %t97
  %t215 = sub i64 %t214, 1
  store i64 %t215, i64* %t97
  br label %map_insert_store_49
map_insert_store_49:
  store i8 1, i8* %t211
  %t216 = getelementptr inbounds i8*, i8** %t175, i64 %t207
  store i8* %t99, i8** %t216
  %t217 = getelementptr inbounds i32, i32* %t176, i64 %t207
  store i32 30, i32* %t217
  %t218 = load i64, i64* %t93
  %t219 = add i64 %t218, 1
  store i64 %t219, i64* %t93
  br label %map_insert_after_47
map_insert_after_47:
  %t220 = getelementptr i8*, i8** null, i32 1
  %t221 = ptrtoint i8** %t220 to i64
  %t222 = getelementptr i32, i32* null, i32 1
  %t223 = ptrtoint i32* %t222 to i64
  %t224 = load i8*, i8** %t2
  %t225 = icmp eq i8* %t224, null
  br i1 %t225, label %map_cow_alloc_50, label %map_cow_check_51
map_cow_alloc_50:
  %t226 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t227 = call i8* @star_rc_alloc(i64 48, i8* %t226)
  %t228 = bitcast i8* %t227 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t229 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t228, i32 0, i32 0
  store i8** null, i8*** %t229
  %t230 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t228, i32 0, i32 1
  store i32* null, i32** %t230
  %t231 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t228, i32 0, i32 2
  store i8* null, i8** %t231
  %t232 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t228, i32 0, i32 3
  store i64 0, i64* %t232
  %t233 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t228, i32 0, i32 4
  store i64 0, i64* %t233
  %t234 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t228, i32 0, i32 5
  store i64 0, i64* %t234
  store i8* %t227, i8** %t2
  br label %map_cow_done_52
map_cow_check_51:
  %t235 = getelementptr inbounds i8, i8* %t224, i64 -16
  %t236 = bitcast i8* %t235 to i64*
  %t237 = load atomic i64, i64* %t236 seq_cst, align 8
  %t238 = icmp eq i64 %t237, 1
  br i1 %t238, label %map_cow_done_52, label %map_cow_clone_53
map_cow_clone_53:
  %t239 = bitcast i8* %t224 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t240 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t239, i32 0, i32 0
  %t241 = load i8**, i8*** %t240
  %t242 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t239, i32 0, i32 1
  %t243 = load i32*, i32** %t242
  %t244 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t239, i32 0, i32 2
  %t245 = load i8*, i8** %t244
  %t246 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t239, i32 0, i32 3
  %t247 = load i64, i64* %t246
  %t248 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t239, i32 0, i32 4
  %t249 = load i64, i64* %t248
  %t250 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t239, i32 0, i32 5
  %t251 = load i64, i64* %t250
  %t252 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t253 = call i8* @star_rc_alloc(i64 48, i8* %t252)
  %t254 = bitcast i8* %t253 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t255 = mul i64 %t249, %t221
  %t256 = call i8* @malloc(i64 %t255)
  %t257 = bitcast i8* %t256 to i8**
  %t258 = mul i64 %t249, %t223
  %t259 = call i8* @malloc(i64 %t258)
  %t260 = bitcast i8* %t259 to i32*
  %t261 = call i8* @malloc(i64 %t249)
  %t262 = icmp sgt i64 %t249, 0
  br i1 %t262, label %map_cow_copy_54, label %map_cow_after_copy_55
map_cow_copy_54:
  %t263 = mul i64 %t249, %t221
  %t264 = bitcast i8** %t241 to i8*
  call i8* @memcpy(i8* %t256, i8* %t264, i64 %t263)
  %t265 = mul i64 %t249, %t223
  %t266 = bitcast i32* %t243 to i8*
  call i8* @memcpy(i8* %t259, i8* %t266, i64 %t265)
  call i8* @memcpy(i8* %t261, i8* %t245, i64 %t249)
  store i64 0, i64* %t267
  br label %map_cow_retain_cond_56
map_cow_retain_cond_56:
  %t268 = load i64, i64* %t267
  %t269 = icmp slt i64 %t268, %t249
  br i1 %t269, label %map_cow_retain_body_57, label %map_cow_retain_end_60
map_cow_retain_body_57:
  %t270 = getelementptr inbounds i8, i8* %t261, i64 %t268
  %t271 = load i8, i8* %t270
  %t272 = icmp eq i8 %t271, 1
  br i1 %t272, label %map_cow_retain_occ_58, label %map_cow_retain_next_59
map_cow_retain_occ_58:
  %t273 = getelementptr inbounds i8*, i8** %t257, i64 %t268
  %t274 = load i8*, i8** %t273
  call void @star_rc_retain(i8* %t274)
  br label %map_cow_retain_next_59
map_cow_retain_next_59:
  %t275 = add i64 %t268, 1
  store i64 %t275, i64* %t267
  br label %map_cow_retain_cond_56
map_cow_retain_end_60:
  br label %map_cow_after_copy_55
map_cow_after_copy_55:
  %t276 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t254, i32 0, i32 0
  store i8** %t257, i8*** %t276
  %t277 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t254, i32 0, i32 1
  store i32* %t260, i32** %t277
  %t278 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t254, i32 0, i32 2
  store i8* %t261, i8** %t278
  %t279 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t254, i32 0, i32 3
  store i64 %t247, i64* %t279
  %t280 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t254, i32 0, i32 4
  store i64 %t249, i64* %t280
  %t281 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t254, i32 0, i32 5
  store i64 %t251, i64* %t281
  call void @star_rc_release(i8* %t224)
  store i8* %t253, i8** %t2
  br label %map_cow_done_52
map_cow_done_52:
  %t282 = load i8*, i8** %t2
  %t283 = bitcast i8* %t282 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t284 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t283, i32 0, i32 0
  %t285 = load i8**, i8*** %t284
  %t286 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t283, i32 0, i32 1
  %t287 = load i32*, i32** %t286
  %t288 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t283, i32 0, i32 2
  %t289 = load i8*, i8** %t288
  %t290 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t283, i32 0, i32 3
  %t291 = load i64, i64* %t290
  %t292 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t283, i32 0, i32 4
  %t293 = load i64, i64* %t292
  %t294 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t283, i32 0, i32 5
  %t295 = load i64, i64* %t294
  %t296 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t297 = load i64, i64* %t290
  %t298 = load i64, i64* %t292
  %t299 = load i64, i64* %t294
  %t300 = add i64 %t297, %t299
  %t301 = add i64 %t300, 1
  %t302 = mul i64 %t301, 4
  %t303 = mul i64 %t298, 3
  %t304 = icmp sgt i64 %t302, %t303
  br i1 %t304, label %map_insert_grow_61, label %map_insert_after_grow_62
map_insert_grow_61:
  %t305 = getelementptr i8*, i8** null, i32 1
  %t306 = ptrtoint i8** %t305 to i64
  %t307 = getelementptr i32, i32* null, i32 1
  %t308 = ptrtoint i32* %t307 to i64
  %t309 = mul i64 %t298, 2
  %t310 = icmp sgt i64 %t309, 0
  %t311 = select i1 %t310, i64 %t309, i64 8
  %t312 = sub i64 %t311, 1
  %t313 = mul i64 %t311, %t306
  %t314 = call i8* @malloc(i64 %t313)
  %t315 = bitcast i8* %t314 to i8**
  %t316 = mul i64 %t311, %t308
  %t317 = call i8* @malloc(i64 %t316)
  %t318 = bitcast i8* %t317 to i32*
  %t319 = call i8* @malloc(i64 %t311)
  store i64 0, i64* %t320
  br label %ht_fill8_cond_63
ht_fill8_cond_63:
  %t321 = load i64, i64* %t320
  %t322 = icmp slt i64 %t321, %t311
  br i1 %t322, label %ht_fill8_body_64, label %ht_fill8_end_65
ht_fill8_body_64:
  %t323 = getelementptr inbounds i8, i8* %t319, i64 %t321
  store i8 0, i8* %t323
  %t324 = add i64 %t321, 1
  store i64 %t324, i64* %t320
  br label %ht_fill8_cond_63
ht_fill8_end_65:
  %t325 = load i8**, i8*** %t284
  %t326 = load i32*, i32** %t286
  %t327 = load i8*, i8** %t288
  store i64 0, i64* %t328
  br label %map_grow_cond_66
map_grow_cond_66:
  %t329 = load i64, i64* %t328
  %t330 = icmp slt i64 %t329, %t298
  br i1 %t330, label %map_grow_body_67, label %map_grow_end_70
map_grow_body_67:
  %t331 = getelementptr inbounds i8, i8* %t327, i64 %t329
  %t332 = load i8, i8* %t331
  %t333 = icmp eq i8 %t332, 1
  br i1 %t333, label %map_grow_occ_68, label %map_grow_next_69
map_grow_occ_68:
  %t334 = getelementptr inbounds i8*, i8** %t325, i64 %t329
  %t335 = load i8*, i8** %t334
  %t336 = getelementptr inbounds i32, i32* %t326, i64 %t329
  %t337 = load i32, i32* %t336
  %t338 = call i64 @hash_str(i8* %t335)
  %t339 = and i64 %t338, %t312
  store i64 0, i64* %t340
  store i64 %t339, i64* %t341
  br label %ht_fe_cond_71
ht_fe_cond_71:
  %t342 = load i64, i64* %t340
  %t343 = icmp slt i64 %t342, %t311
  br i1 %t343, label %ht_fe_body_72, label %ht_fe_end_74
ht_fe_body_72:
  %t344 = load i64, i64* %t341
  %t345 = getelementptr inbounds i8, i8* %t319, i64 %t344
  %t346 = load i8, i8* %t345
  %t347 = icmp eq i8 %t346, 0
  br i1 %t347, label %ht_fe_end_74, label %ht_fe_next_73
ht_fe_next_73:
  %t348 = add i64 %t344, 1
  %t349 = and i64 %t348, %t312
  store i64 %t349, i64* %t341
  %t350 = add i64 %t342, 1
  store i64 %t350, i64* %t340
  br label %ht_fe_cond_71
ht_fe_end_74:
  %t351 = load i64, i64* %t341
  %t352 = getelementptr inbounds i8, i8* %t319, i64 %t351
  store i8 1, i8* %t352
  %t353 = getelementptr inbounds i8*, i8** %t315, i64 %t351
  store i8* %t335, i8** %t353
  %t354 = getelementptr inbounds i32, i32* %t318, i64 %t351
  store i32 %t337, i32* %t354
  br label %map_grow_next_69
map_grow_next_69:
  %t355 = add i64 %t329, 1
  store i64 %t355, i64* %t328
  br label %map_grow_cond_66
map_grow_end_70:
  %t356 = bitcast i8** %t325 to i8*
  call void @free(i8* %t356)
  %t357 = bitcast i32* %t326 to i8*
  call void @free(i8* %t357)
  call void @free(i8* %t327)
  store i8** %t315, i8*** %t284
  store i32* %t318, i32** %t286
  store i8* %t319, i8** %t288
  store i64 %t311, i64* %t292
  store i64 0, i64* %t294
  br label %map_insert_after_grow_62
map_insert_after_grow_62:
  %t358 = load i8**, i8*** %t284
  %t359 = load i32*, i32** %t286
  %t360 = load i8*, i8** %t288
  %t361 = load i64, i64* %t292
  %t362 = sub i64 %t361, 1
  %t363 = call i64 @hash_str(i8* %t296)
  %t364 = and i64 %t363, %t362
  store i64 0, i64* %t365
  store i64 %t364, i64* %t366
  store i1 false, i1* %t367
  store i64 -1, i64* %t368
  store i64 -1, i64* %t369
  store i1 false, i1* %t370
  br label %ht_probe_cond_75
ht_probe_cond_75:
  %t371 = load i64, i64* %t365
  %t372 = icmp slt i64 %t371, %t361
  br i1 %t372, label %ht_probe_body_76, label %ht_probe_end_86
ht_probe_body_76:
  %t373 = load i64, i64* %t366
  %t374 = getelementptr inbounds i8, i8* %t360, i64 %t373
  %t375 = load i8, i8* %t374
  %t376 = icmp eq i8 %t375, 0
  br i1 %t376, label %ht_probe_on_empty_78, label %ht_probe_check_occ_77
ht_probe_check_occ_77:
  %t377 = icmp eq i8 %t375, 1
  br i1 %t377, label %ht_probe_on_occ_81, label %ht_probe_on_tomb_83
ht_probe_on_empty_78:
  %t378 = load i1, i1* %t370
  br i1 %t378, label %ht_probe_after_islot_empty_80, label %ht_probe_set_islot_empty_79
ht_probe_set_islot_empty_79:
  store i64 %t373, i64* %t369
  store i1 true, i1* %t370
  br label %ht_probe_after_islot_empty_80
ht_probe_after_islot_empty_80:
  br label %ht_probe_end_86
ht_probe_on_occ_81:
  %t379 = getelementptr inbounds i8*, i8** %t358, i64 %t373
  %t380 = load i8*, i8** %t379
  %t381 = call i1 @eq_str(i8* %t380, i8* %t296)
  br i1 %t381, label %ht_probe_on_match_82, label %ht_probe_next_85
ht_probe_on_match_82:
  store i1 true, i1* %t367
  store i64 %t373, i64* %t368
  br label %ht_probe_end_86
ht_probe_on_tomb_83:
  %t382 = load i1, i1* %t370
  br i1 %t382, label %ht_probe_next_85, label %ht_probe_set_islot_tomb_84
ht_probe_set_islot_tomb_84:
  store i64 %t373, i64* %t369
  store i1 true, i1* %t370
  br label %ht_probe_next_85
ht_probe_next_85:
  %t383 = add i64 %t373, 1
  %t384 = and i64 %t383, %t362
  store i64 %t384, i64* %t366
  %t385 = add i64 %t371, 1
  store i64 %t385, i64* %t365
  br label %ht_probe_cond_75
ht_probe_end_86:
  %t386 = load i1, i1* %t367
  %t387 = load i64, i64* %t368
  %t388 = load i64, i64* %t369
  br i1 %t386, label %map_insert_overwrite_87, label %map_insert_new_88
map_insert_overwrite_87:
  store i8* %t296, i8** %t389
  %t390 = load i8*, i8** %t389
  call void @star_rc_release(i8* %t390)
  %t391 = getelementptr inbounds i32, i32* %t359, i64 %t387
  store i32 25, i32* %t391
  br label %map_insert_after_89
map_insert_new_88:
  %t392 = getelementptr inbounds i8, i8* %t360, i64 %t388
  %t393 = load i8, i8* %t392
  %t394 = icmp eq i8 %t393, 2
  br i1 %t394, label %map_insert_dec_tomb_90, label %map_insert_store_91
map_insert_dec_tomb_90:
  %t395 = load i64, i64* %t294
  %t396 = sub i64 %t395, 1
  store i64 %t396, i64* %t294
  br label %map_insert_store_91
map_insert_store_91:
  store i8 1, i8* %t392
  %t397 = getelementptr inbounds i8*, i8** %t358, i64 %t388
  store i8* %t296, i8** %t397
  %t398 = getelementptr inbounds i32, i32* %t359, i64 %t388
  store i32 25, i32* %t398
  %t399 = load i64, i64* %t290
  %t400 = add i64 %t399, 1
  store i64 %t400, i64* %t290
  br label %map_insert_after_89
map_insert_after_89:
  %t401 = load i8*, i8** %t2
  %t402 = icmp eq i8* %t401, null
  br i1 %t402, label %map_read_null_92, label %map_read_real_93
map_read_null_92:
  br label %map_read_end_94
map_read_real_93:
  %t403 = bitcast i8* %t401 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t404 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t403, i32 0, i32 0
  %t405 = load i8**, i8*** %t404
  %t406 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t403, i32 0, i32 1
  %t407 = load i32*, i32** %t406
  %t408 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t403, i32 0, i32 2
  %t409 = load i8*, i8** %t408
  %t410 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t403, i32 0, i32 3
  %t411 = load i64, i64* %t410
  %t412 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t403, i32 0, i32 4
  %t413 = load i64, i64* %t412
  br label %map_read_end_94
map_read_end_94:
  %t414 = phi i8** [ null, %map_read_null_92 ], [ %t405, %map_read_real_93 ]
  %t415 = phi i32* [ null, %map_read_null_92 ], [ %t407, %map_read_real_93 ]
  %t416 = phi i8* [ null, %map_read_null_92 ], [ %t409, %map_read_real_93 ]
  %t417 = phi i64 [ 0, %map_read_null_92 ], [ %t411, %map_read_real_93 ]
  %t418 = phi i64 [ 0, %map_read_null_92 ], [ %t413, %map_read_real_93 ]
  %t419 = trunc i64 %t417 to i32
  %t420 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t420, i32 %t419)
  %t421 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t422 = load i8*, i8** %t2
  %t423 = icmp eq i8* %t422, null
  br i1 %t423, label %map_read_null_95, label %map_read_real_96
map_read_null_95:
  br label %map_read_end_97
map_read_real_96:
  %t424 = bitcast i8* %t422 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t425 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t424, i32 0, i32 0
  %t426 = load i8**, i8*** %t425
  %t427 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t424, i32 0, i32 1
  %t428 = load i32*, i32** %t427
  %t429 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t424, i32 0, i32 2
  %t430 = load i8*, i8** %t429
  %t431 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t424, i32 0, i32 3
  %t432 = load i64, i64* %t431
  %t433 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t424, i32 0, i32 4
  %t434 = load i64, i64* %t433
  br label %map_read_end_97
map_read_end_97:
  %t435 = phi i8** [ null, %map_read_null_95 ], [ %t426, %map_read_real_96 ]
  %t436 = phi i32* [ null, %map_read_null_95 ], [ %t428, %map_read_real_96 ]
  %t437 = phi i8* [ null, %map_read_null_95 ], [ %t430, %map_read_real_96 ]
  %t438 = phi i64 [ 0, %map_read_null_95 ], [ %t432, %map_read_real_96 ]
  %t439 = phi i64 [ 0, %map_read_null_95 ], [ %t434, %map_read_real_96 ]
  %t440 = sub i64 %t439, 1
  %t441 = call i64 @hash_str(i8* %t421)
  %t442 = and i64 %t441, %t440
  store i64 0, i64* %t443
  store i64 %t442, i64* %t444
  store i1 false, i1* %t445
  store i64 -1, i64* %t446
  store i64 -1, i64* %t447
  store i1 false, i1* %t448
  br label %ht_probe_cond_98
ht_probe_cond_98:
  %t449 = load i64, i64* %t443
  %t450 = icmp slt i64 %t449, %t439
  br i1 %t450, label %ht_probe_body_99, label %ht_probe_end_109
ht_probe_body_99:
  %t451 = load i64, i64* %t444
  %t452 = getelementptr inbounds i8, i8* %t437, i64 %t451
  %t453 = load i8, i8* %t452
  %t454 = icmp eq i8 %t453, 0
  br i1 %t454, label %ht_probe_on_empty_101, label %ht_probe_check_occ_100
ht_probe_check_occ_100:
  %t455 = icmp eq i8 %t453, 1
  br i1 %t455, label %ht_probe_on_occ_104, label %ht_probe_on_tomb_106
ht_probe_on_empty_101:
  %t456 = load i1, i1* %t448
  br i1 %t456, label %ht_probe_after_islot_empty_103, label %ht_probe_set_islot_empty_102
ht_probe_set_islot_empty_102:
  store i64 %t451, i64* %t447
  store i1 true, i1* %t448
  br label %ht_probe_after_islot_empty_103
ht_probe_after_islot_empty_103:
  br label %ht_probe_end_109
ht_probe_on_occ_104:
  %t457 = getelementptr inbounds i8*, i8** %t435, i64 %t451
  %t458 = load i8*, i8** %t457
  %t459 = call i1 @eq_str(i8* %t458, i8* %t421)
  br i1 %t459, label %ht_probe_on_match_105, label %ht_probe_next_108
ht_probe_on_match_105:
  store i1 true, i1* %t445
  store i64 %t451, i64* %t446
  br label %ht_probe_end_109
ht_probe_on_tomb_106:
  %t460 = load i1, i1* %t448
  br i1 %t460, label %ht_probe_next_108, label %ht_probe_set_islot_tomb_107
ht_probe_set_islot_tomb_107:
  store i64 %t451, i64* %t447
  store i1 true, i1* %t448
  br label %ht_probe_next_108
ht_probe_next_108:
  %t461 = add i64 %t451, 1
  %t462 = and i64 %t461, %t440
  store i64 %t462, i64* %t444
  %t463 = add i64 %t449, 1
  store i64 %t463, i64* %t443
  br label %ht_probe_cond_98
ht_probe_end_109:
  %t464 = load i1, i1* %t445
  %t465 = load i64, i64* %t446
  %t466 = load i64, i64* %t447
  store i8* %t421, i8** %t467
  %t468 = load i8*, i8** %t467
  call void @star_rc_release(i8* %t468)
  br i1 %t464, label %map_get_some_110, label %map_get_none_111
map_get_some_110:
  %t469 = getelementptr inbounds i32, i32* %t436, i64 %t465
  %t470 = load i32, i32* %t469
  %t472 = getelementptr inbounds %Option__i32, %Option__i32* %t471, i32 0, i32 0
  store i32 1, i32* %t472
  %t473 = getelementptr inbounds %Option__i32, %Option__i32* %t471, i32 0, i32 1
  %t474 = bitcast [1 x i64]* %t473 to { i32 }*
  %t475 = getelementptr inbounds { i32 }, { i32 }* %t474, i32 0, i32 0
  store i32 %t470, i32* %t475
  %t476 = load %Option__i32, %Option__i32* %t471
  br label %map_get_end_112
map_get_none_111:
  %t478 = getelementptr inbounds %Option__i32, %Option__i32* %t477, i32 0, i32 0
  store i32 0, i32* %t478
  %t479 = load %Option__i32, %Option__i32* %t477
  br label %map_get_end_112
map_get_end_112:
  %t480 = phi %Option__i32 [ %t476, %map_get_some_110 ], [ %t479, %map_get_none_111 ]
  store %Option__i32 %t480, %Option__i32* %t481
  br label %match_scrutinee_483
match_scrutinee_483:
  %t487 = getelementptr inbounds %Option__i32, %Option__i32* %t481, i32 0, i32 0
  %t488 = load i32, i32* %t487
  %t486 = icmp eq i32 %t488, 1
  br i1 %t486, label %match_then_0_484, label %match_next_0_485
match_then_0_484:
  %t489 = getelementptr inbounds %Option__i32, %Option__i32* %t481, i32 0, i32 1
  %t490 = bitcast [1 x i64]* %t489 to { i32 }*
  %t491 = getelementptr inbounds { i32 }, { i32 }* %t490, i32 0, i32 0
  %t492 = load i32, i32* %t491
  %t493 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t493, i32 %t492)
  br label %match_end_482
match_next_0_485:
  %t497 = getelementptr inbounds %Option__i32, %Option__i32* %t481, i32 0, i32 0
  %t498 = load i32, i32* %t497
  %t496 = icmp eq i32 %t498, 0
  br i1 %t496, label %match_then_1_494, label %match_next_1_495
match_then_1_494:
  %t499 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.5, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t499)
  call i32 (i8*, ...) @printf(i8* %t499)
  %t500 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t500)
  br label %match_end_482
match_next_1_495:
  br label %match_end_482
match_end_482:
  %t501 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t502 = load i8*, i8** %t2
  %t503 = icmp eq i8* %t502, null
  br i1 %t503, label %map_read_null_113, label %map_read_real_114
map_read_null_113:
  br label %map_read_end_115
map_read_real_114:
  %t504 = bitcast i8* %t502 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t505 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t504, i32 0, i32 0
  %t506 = load i8**, i8*** %t505
  %t507 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t504, i32 0, i32 1
  %t508 = load i32*, i32** %t507
  %t509 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t504, i32 0, i32 2
  %t510 = load i8*, i8** %t509
  %t511 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t504, i32 0, i32 3
  %t512 = load i64, i64* %t511
  %t513 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t504, i32 0, i32 4
  %t514 = load i64, i64* %t513
  br label %map_read_end_115
map_read_end_115:
  %t515 = phi i8** [ null, %map_read_null_113 ], [ %t506, %map_read_real_114 ]
  %t516 = phi i32* [ null, %map_read_null_113 ], [ %t508, %map_read_real_114 ]
  %t517 = phi i8* [ null, %map_read_null_113 ], [ %t510, %map_read_real_114 ]
  %t518 = phi i64 [ 0, %map_read_null_113 ], [ %t512, %map_read_real_114 ]
  %t519 = phi i64 [ 0, %map_read_null_113 ], [ %t514, %map_read_real_114 ]
  %t520 = sub i64 %t519, 1
  %t521 = call i64 @hash_str(i8* %t501)
  %t522 = and i64 %t521, %t520
  store i64 0, i64* %t523
  store i64 %t522, i64* %t524
  store i1 false, i1* %t525
  store i64 -1, i64* %t526
  store i64 -1, i64* %t527
  store i1 false, i1* %t528
  br label %ht_probe_cond_116
ht_probe_cond_116:
  %t529 = load i64, i64* %t523
  %t530 = icmp slt i64 %t529, %t519
  br i1 %t530, label %ht_probe_body_117, label %ht_probe_end_127
ht_probe_body_117:
  %t531 = load i64, i64* %t524
  %t532 = getelementptr inbounds i8, i8* %t517, i64 %t531
  %t533 = load i8, i8* %t532
  %t534 = icmp eq i8 %t533, 0
  br i1 %t534, label %ht_probe_on_empty_119, label %ht_probe_check_occ_118
ht_probe_check_occ_118:
  %t535 = icmp eq i8 %t533, 1
  br i1 %t535, label %ht_probe_on_occ_122, label %ht_probe_on_tomb_124
ht_probe_on_empty_119:
  %t536 = load i1, i1* %t528
  br i1 %t536, label %ht_probe_after_islot_empty_121, label %ht_probe_set_islot_empty_120
ht_probe_set_islot_empty_120:
  store i64 %t531, i64* %t527
  store i1 true, i1* %t528
  br label %ht_probe_after_islot_empty_121
ht_probe_after_islot_empty_121:
  br label %ht_probe_end_127
ht_probe_on_occ_122:
  %t537 = getelementptr inbounds i8*, i8** %t515, i64 %t531
  %t538 = load i8*, i8** %t537
  %t539 = call i1 @eq_str(i8* %t538, i8* %t501)
  br i1 %t539, label %ht_probe_on_match_123, label %ht_probe_next_126
ht_probe_on_match_123:
  store i1 true, i1* %t525
  store i64 %t531, i64* %t526
  br label %ht_probe_end_127
ht_probe_on_tomb_124:
  %t540 = load i1, i1* %t528
  br i1 %t540, label %ht_probe_next_126, label %ht_probe_set_islot_tomb_125
ht_probe_set_islot_tomb_125:
  store i64 %t531, i64* %t527
  store i1 true, i1* %t528
  br label %ht_probe_next_126
ht_probe_next_126:
  %t541 = add i64 %t531, 1
  %t542 = and i64 %t541, %t520
  store i64 %t542, i64* %t524
  %t543 = add i64 %t529, 1
  store i64 %t543, i64* %t523
  br label %ht_probe_cond_116
ht_probe_end_127:
  %t544 = load i1, i1* %t525
  %t545 = load i64, i64* %t526
  %t546 = load i64, i64* %t527
  store i8* %t501, i8** %t547
  %t548 = load i8*, i8** %t547
  call void @star_rc_release(i8* %t548)
  br i1 %t544, label %map_get_some_128, label %map_get_none_129
map_get_some_128:
  %t549 = getelementptr inbounds i32, i32* %t516, i64 %t545
  %t550 = load i32, i32* %t549
  %t552 = getelementptr inbounds %Option__i32, %Option__i32* %t551, i32 0, i32 0
  store i32 1, i32* %t552
  %t553 = getelementptr inbounds %Option__i32, %Option__i32* %t551, i32 0, i32 1
  %t554 = bitcast [1 x i64]* %t553 to { i32 }*
  %t555 = getelementptr inbounds { i32 }, { i32 }* %t554, i32 0, i32 0
  store i32 %t550, i32* %t555
  %t556 = load %Option__i32, %Option__i32* %t551
  br label %map_get_end_130
map_get_none_129:
  %t558 = getelementptr inbounds %Option__i32, %Option__i32* %t557, i32 0, i32 0
  store i32 0, i32* %t558
  %t559 = load %Option__i32, %Option__i32* %t557
  br label %map_get_end_130
map_get_end_130:
  %t560 = phi %Option__i32 [ %t556, %map_get_some_128 ], [ %t559, %map_get_none_129 ]
  store %Option__i32 %t560, %Option__i32* %t561
  br label %match_scrutinee_563
match_scrutinee_563:
  %t567 = getelementptr inbounds %Option__i32, %Option__i32* %t561, i32 0, i32 0
  %t568 = load i32, i32* %t567
  %t566 = icmp eq i32 %t568, 1
  br i1 %t566, label %match_then_0_564, label %match_next_0_565
match_then_0_564:
  %t569 = getelementptr inbounds %Option__i32, %Option__i32* %t561, i32 0, i32 1
  %t570 = bitcast [1 x i64]* %t569 to { i32 }*
  %t571 = getelementptr inbounds { i32 }, { i32 }* %t570, i32 0, i32 0
  %t572 = load i32, i32* %t571
  %t573 = getelementptr inbounds [11 x i8], [11 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t573, i32 %t572)
  br label %match_end_562
match_next_0_565:
  %t577 = getelementptr inbounds %Option__i32, %Option__i32* %t561, i32 0, i32 0
  %t578 = load i32, i32* %t577
  %t576 = icmp eq i32 %t578, 0
  br i1 %t576, label %match_then_1_574, label %match_next_1_575
match_then_1_574:
  %t579 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.9, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t579)
  call i32 (i8*, ...) @printf(i8* %t579)
  %t580 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t580)
  br label %match_end_562
match_next_1_575:
  br label %match_end_562
match_end_562:
  %t581 = getelementptr i8*, i8** null, i32 1
  %t582 = ptrtoint i8** %t581 to i64
  %t583 = getelementptr i32, i32* null, i32 1
  %t584 = ptrtoint i32* %t583 to i64
  %t585 = load i8*, i8** %t2
  %t586 = icmp eq i8* %t585, null
  br i1 %t586, label %map_cow_alloc_131, label %map_cow_check_132
map_cow_alloc_131:
  %t587 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t588 = call i8* @star_rc_alloc(i64 48, i8* %t587)
  %t589 = bitcast i8* %t588 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t590 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t589, i32 0, i32 0
  store i8** null, i8*** %t590
  %t591 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t589, i32 0, i32 1
  store i32* null, i32** %t591
  %t592 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t589, i32 0, i32 2
  store i8* null, i8** %t592
  %t593 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t589, i32 0, i32 3
  store i64 0, i64* %t593
  %t594 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t589, i32 0, i32 4
  store i64 0, i64* %t594
  %t595 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t589, i32 0, i32 5
  store i64 0, i64* %t595
  store i8* %t588, i8** %t2
  br label %map_cow_done_133
map_cow_check_132:
  %t596 = getelementptr inbounds i8, i8* %t585, i64 -16
  %t597 = bitcast i8* %t596 to i64*
  %t598 = load atomic i64, i64* %t597 seq_cst, align 8
  %t599 = icmp eq i64 %t598, 1
  br i1 %t599, label %map_cow_done_133, label %map_cow_clone_134
map_cow_clone_134:
  %t600 = bitcast i8* %t585 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t601 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t600, i32 0, i32 0
  %t602 = load i8**, i8*** %t601
  %t603 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t600, i32 0, i32 1
  %t604 = load i32*, i32** %t603
  %t605 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t600, i32 0, i32 2
  %t606 = load i8*, i8** %t605
  %t607 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t600, i32 0, i32 3
  %t608 = load i64, i64* %t607
  %t609 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t600, i32 0, i32 4
  %t610 = load i64, i64* %t609
  %t611 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t600, i32 0, i32 5
  %t612 = load i64, i64* %t611
  %t613 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t614 = call i8* @star_rc_alloc(i64 48, i8* %t613)
  %t615 = bitcast i8* %t614 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t616 = mul i64 %t610, %t582
  %t617 = call i8* @malloc(i64 %t616)
  %t618 = bitcast i8* %t617 to i8**
  %t619 = mul i64 %t610, %t584
  %t620 = call i8* @malloc(i64 %t619)
  %t621 = bitcast i8* %t620 to i32*
  %t622 = call i8* @malloc(i64 %t610)
  %t623 = icmp sgt i64 %t610, 0
  br i1 %t623, label %map_cow_copy_135, label %map_cow_after_copy_136
map_cow_copy_135:
  %t624 = mul i64 %t610, %t582
  %t625 = bitcast i8** %t602 to i8*
  call i8* @memcpy(i8* %t617, i8* %t625, i64 %t624)
  %t626 = mul i64 %t610, %t584
  %t627 = bitcast i32* %t604 to i8*
  call i8* @memcpy(i8* %t620, i8* %t627, i64 %t626)
  call i8* @memcpy(i8* %t622, i8* %t606, i64 %t610)
  store i64 0, i64* %t628
  br label %map_cow_retain_cond_137
map_cow_retain_cond_137:
  %t629 = load i64, i64* %t628
  %t630 = icmp slt i64 %t629, %t610
  br i1 %t630, label %map_cow_retain_body_138, label %map_cow_retain_end_141
map_cow_retain_body_138:
  %t631 = getelementptr inbounds i8, i8* %t622, i64 %t629
  %t632 = load i8, i8* %t631
  %t633 = icmp eq i8 %t632, 1
  br i1 %t633, label %map_cow_retain_occ_139, label %map_cow_retain_next_140
map_cow_retain_occ_139:
  %t634 = getelementptr inbounds i8*, i8** %t618, i64 %t629
  %t635 = load i8*, i8** %t634
  call void @star_rc_retain(i8* %t635)
  br label %map_cow_retain_next_140
map_cow_retain_next_140:
  %t636 = add i64 %t629, 1
  store i64 %t636, i64* %t628
  br label %map_cow_retain_cond_137
map_cow_retain_end_141:
  br label %map_cow_after_copy_136
map_cow_after_copy_136:
  %t637 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t615, i32 0, i32 0
  store i8** %t618, i8*** %t637
  %t638 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t615, i32 0, i32 1
  store i32* %t621, i32** %t638
  %t639 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t615, i32 0, i32 2
  store i8* %t622, i8** %t639
  %t640 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t615, i32 0, i32 3
  store i64 %t608, i64* %t640
  %t641 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t615, i32 0, i32 4
  store i64 %t610, i64* %t641
  %t642 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t615, i32 0, i32 5
  store i64 %t612, i64* %t642
  call void @star_rc_release(i8* %t585)
  store i8* %t614, i8** %t2
  br label %map_cow_done_133
map_cow_done_133:
  %t643 = load i8*, i8** %t2
  %t644 = bitcast i8* %t643 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t645 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t644, i32 0, i32 0
  %t646 = load i8**, i8*** %t645
  %t647 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t644, i32 0, i32 1
  %t648 = load i32*, i32** %t647
  %t649 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t644, i32 0, i32 2
  %t650 = load i8*, i8** %t649
  %t651 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t644, i32 0, i32 3
  %t652 = load i64, i64* %t651
  %t653 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t644, i32 0, i32 4
  %t654 = load i64, i64* %t653
  %t655 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t644, i32 0, i32 5
  %t656 = load i64, i64* %t655
  %t657 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t658 = load i64, i64* %t651
  %t659 = load i64, i64* %t653
  %t660 = load i64, i64* %t655
  %t661 = add i64 %t658, %t660
  %t662 = add i64 %t661, 1
  %t663 = mul i64 %t662, 4
  %t664 = mul i64 %t659, 3
  %t665 = icmp sgt i64 %t663, %t664
  br i1 %t665, label %map_insert_grow_142, label %map_insert_after_grow_143
map_insert_grow_142:
  %t666 = getelementptr i8*, i8** null, i32 1
  %t667 = ptrtoint i8** %t666 to i64
  %t668 = getelementptr i32, i32* null, i32 1
  %t669 = ptrtoint i32* %t668 to i64
  %t670 = mul i64 %t659, 2
  %t671 = icmp sgt i64 %t670, 0
  %t672 = select i1 %t671, i64 %t670, i64 8
  %t673 = sub i64 %t672, 1
  %t674 = mul i64 %t672, %t667
  %t675 = call i8* @malloc(i64 %t674)
  %t676 = bitcast i8* %t675 to i8**
  %t677 = mul i64 %t672, %t669
  %t678 = call i8* @malloc(i64 %t677)
  %t679 = bitcast i8* %t678 to i32*
  %t680 = call i8* @malloc(i64 %t672)
  store i64 0, i64* %t681
  br label %ht_fill8_cond_144
ht_fill8_cond_144:
  %t682 = load i64, i64* %t681
  %t683 = icmp slt i64 %t682, %t672
  br i1 %t683, label %ht_fill8_body_145, label %ht_fill8_end_146
ht_fill8_body_145:
  %t684 = getelementptr inbounds i8, i8* %t680, i64 %t682
  store i8 0, i8* %t684
  %t685 = add i64 %t682, 1
  store i64 %t685, i64* %t681
  br label %ht_fill8_cond_144
ht_fill8_end_146:
  %t686 = load i8**, i8*** %t645
  %t687 = load i32*, i32** %t647
  %t688 = load i8*, i8** %t649
  store i64 0, i64* %t689
  br label %map_grow_cond_147
map_grow_cond_147:
  %t690 = load i64, i64* %t689
  %t691 = icmp slt i64 %t690, %t659
  br i1 %t691, label %map_grow_body_148, label %map_grow_end_151
map_grow_body_148:
  %t692 = getelementptr inbounds i8, i8* %t688, i64 %t690
  %t693 = load i8, i8* %t692
  %t694 = icmp eq i8 %t693, 1
  br i1 %t694, label %map_grow_occ_149, label %map_grow_next_150
map_grow_occ_149:
  %t695 = getelementptr inbounds i8*, i8** %t686, i64 %t690
  %t696 = load i8*, i8** %t695
  %t697 = getelementptr inbounds i32, i32* %t687, i64 %t690
  %t698 = load i32, i32* %t697
  %t699 = call i64 @hash_str(i8* %t696)
  %t700 = and i64 %t699, %t673
  store i64 0, i64* %t701
  store i64 %t700, i64* %t702
  br label %ht_fe_cond_152
ht_fe_cond_152:
  %t703 = load i64, i64* %t701
  %t704 = icmp slt i64 %t703, %t672
  br i1 %t704, label %ht_fe_body_153, label %ht_fe_end_155
ht_fe_body_153:
  %t705 = load i64, i64* %t702
  %t706 = getelementptr inbounds i8, i8* %t680, i64 %t705
  %t707 = load i8, i8* %t706
  %t708 = icmp eq i8 %t707, 0
  br i1 %t708, label %ht_fe_end_155, label %ht_fe_next_154
ht_fe_next_154:
  %t709 = add i64 %t705, 1
  %t710 = and i64 %t709, %t673
  store i64 %t710, i64* %t702
  %t711 = add i64 %t703, 1
  store i64 %t711, i64* %t701
  br label %ht_fe_cond_152
ht_fe_end_155:
  %t712 = load i64, i64* %t702
  %t713 = getelementptr inbounds i8, i8* %t680, i64 %t712
  store i8 1, i8* %t713
  %t714 = getelementptr inbounds i8*, i8** %t676, i64 %t712
  store i8* %t696, i8** %t714
  %t715 = getelementptr inbounds i32, i32* %t679, i64 %t712
  store i32 %t698, i32* %t715
  br label %map_grow_next_150
map_grow_next_150:
  %t716 = add i64 %t690, 1
  store i64 %t716, i64* %t689
  br label %map_grow_cond_147
map_grow_end_151:
  %t717 = bitcast i8** %t686 to i8*
  call void @free(i8* %t717)
  %t718 = bitcast i32* %t687 to i8*
  call void @free(i8* %t718)
  call void @free(i8* %t688)
  store i8** %t676, i8*** %t645
  store i32* %t679, i32** %t647
  store i8* %t680, i8** %t649
  store i64 %t672, i64* %t653
  store i64 0, i64* %t655
  br label %map_insert_after_grow_143
map_insert_after_grow_143:
  %t719 = load i8**, i8*** %t645
  %t720 = load i32*, i32** %t647
  %t721 = load i8*, i8** %t649
  %t722 = load i64, i64* %t653
  %t723 = sub i64 %t722, 1
  %t724 = call i64 @hash_str(i8* %t657)
  %t725 = and i64 %t724, %t723
  store i64 0, i64* %t726
  store i64 %t725, i64* %t727
  store i1 false, i1* %t728
  store i64 -1, i64* %t729
  store i64 -1, i64* %t730
  store i1 false, i1* %t731
  br label %ht_probe_cond_156
ht_probe_cond_156:
  %t732 = load i64, i64* %t726
  %t733 = icmp slt i64 %t732, %t722
  br i1 %t733, label %ht_probe_body_157, label %ht_probe_end_167
ht_probe_body_157:
  %t734 = load i64, i64* %t727
  %t735 = getelementptr inbounds i8, i8* %t721, i64 %t734
  %t736 = load i8, i8* %t735
  %t737 = icmp eq i8 %t736, 0
  br i1 %t737, label %ht_probe_on_empty_159, label %ht_probe_check_occ_158
ht_probe_check_occ_158:
  %t738 = icmp eq i8 %t736, 1
  br i1 %t738, label %ht_probe_on_occ_162, label %ht_probe_on_tomb_164
ht_probe_on_empty_159:
  %t739 = load i1, i1* %t731
  br i1 %t739, label %ht_probe_after_islot_empty_161, label %ht_probe_set_islot_empty_160
ht_probe_set_islot_empty_160:
  store i64 %t734, i64* %t730
  store i1 true, i1* %t731
  br label %ht_probe_after_islot_empty_161
ht_probe_after_islot_empty_161:
  br label %ht_probe_end_167
ht_probe_on_occ_162:
  %t740 = getelementptr inbounds i8*, i8** %t719, i64 %t734
  %t741 = load i8*, i8** %t740
  %t742 = call i1 @eq_str(i8* %t741, i8* %t657)
  br i1 %t742, label %ht_probe_on_match_163, label %ht_probe_next_166
ht_probe_on_match_163:
  store i1 true, i1* %t728
  store i64 %t734, i64* %t729
  br label %ht_probe_end_167
ht_probe_on_tomb_164:
  %t743 = load i1, i1* %t731
  br i1 %t743, label %ht_probe_next_166, label %ht_probe_set_islot_tomb_165
ht_probe_set_islot_tomb_165:
  store i64 %t734, i64* %t730
  store i1 true, i1* %t731
  br label %ht_probe_next_166
ht_probe_next_166:
  %t744 = add i64 %t734, 1
  %t745 = and i64 %t744, %t723
  store i64 %t745, i64* %t727
  %t746 = add i64 %t732, 1
  store i64 %t746, i64* %t726
  br label %ht_probe_cond_156
ht_probe_end_167:
  %t747 = load i1, i1* %t728
  %t748 = load i64, i64* %t729
  %t749 = load i64, i64* %t730
  br i1 %t747, label %map_insert_overwrite_168, label %map_insert_new_169
map_insert_overwrite_168:
  store i8* %t657, i8** %t750
  %t751 = load i8*, i8** %t750
  call void @star_rc_release(i8* %t751)
  %t752 = getelementptr inbounds i32, i32* %t720, i64 %t748
  store i32 31, i32* %t752
  br label %map_insert_after_170
map_insert_new_169:
  %t753 = getelementptr inbounds i8, i8* %t721, i64 %t749
  %t754 = load i8, i8* %t753
  %t755 = icmp eq i8 %t754, 2
  br i1 %t755, label %map_insert_dec_tomb_171, label %map_insert_store_172
map_insert_dec_tomb_171:
  %t756 = load i64, i64* %t655
  %t757 = sub i64 %t756, 1
  store i64 %t757, i64* %t655
  br label %map_insert_store_172
map_insert_store_172:
  store i8 1, i8* %t753
  %t758 = getelementptr inbounds i8*, i8** %t719, i64 %t749
  store i8* %t657, i8** %t758
  %t759 = getelementptr inbounds i32, i32* %t720, i64 %t749
  store i32 31, i32* %t759
  %t760 = load i64, i64* %t651
  %t761 = add i64 %t760, 1
  store i64 %t761, i64* %t651
  br label %map_insert_after_170
map_insert_after_170:
  %t762 = load i8*, i8** %t2
  %t763 = icmp eq i8* %t762, null
  br i1 %t763, label %map_read_null_173, label %map_read_real_174
map_read_null_173:
  br label %map_read_end_175
map_read_real_174:
  %t764 = bitcast i8* %t762 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t765 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t764, i32 0, i32 0
  %t766 = load i8**, i8*** %t765
  %t767 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t764, i32 0, i32 1
  %t768 = load i32*, i32** %t767
  %t769 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t764, i32 0, i32 2
  %t770 = load i8*, i8** %t769
  %t771 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t764, i32 0, i32 3
  %t772 = load i64, i64* %t771
  %t773 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t764, i32 0, i32 4
  %t774 = load i64, i64* %t773
  br label %map_read_end_175
map_read_end_175:
  %t775 = phi i8** [ null, %map_read_null_173 ], [ %t766, %map_read_real_174 ]
  %t776 = phi i32* [ null, %map_read_null_173 ], [ %t768, %map_read_real_174 ]
  %t777 = phi i8* [ null, %map_read_null_173 ], [ %t770, %map_read_real_174 ]
  %t778 = phi i64 [ 0, %map_read_null_173 ], [ %t772, %map_read_real_174 ]
  %t779 = phi i64 [ 0, %map_read_null_173 ], [ %t774, %map_read_real_174 ]
  %t780 = trunc i64 %t778 to i32
  %t781 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t781, i32 %t780)
  %t782 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t783 = load i8*, i8** %t2
  %t784 = icmp eq i8* %t783, null
  br i1 %t784, label %map_read_null_176, label %map_read_real_177
map_read_null_176:
  br label %map_read_end_178
map_read_real_177:
  %t785 = bitcast i8* %t783 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t786 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t785, i32 0, i32 0
  %t787 = load i8**, i8*** %t786
  %t788 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t785, i32 0, i32 1
  %t789 = load i32*, i32** %t788
  %t790 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t785, i32 0, i32 2
  %t791 = load i8*, i8** %t790
  %t792 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t785, i32 0, i32 3
  %t793 = load i64, i64* %t792
  %t794 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t785, i32 0, i32 4
  %t795 = load i64, i64* %t794
  br label %map_read_end_178
map_read_end_178:
  %t796 = phi i8** [ null, %map_read_null_176 ], [ %t787, %map_read_real_177 ]
  %t797 = phi i32* [ null, %map_read_null_176 ], [ %t789, %map_read_real_177 ]
  %t798 = phi i8* [ null, %map_read_null_176 ], [ %t791, %map_read_real_177 ]
  %t799 = phi i64 [ 0, %map_read_null_176 ], [ %t793, %map_read_real_177 ]
  %t800 = phi i64 [ 0, %map_read_null_176 ], [ %t795, %map_read_real_177 ]
  %t801 = sub i64 %t800, 1
  %t802 = call i64 @hash_str(i8* %t782)
  %t803 = and i64 %t802, %t801
  store i64 0, i64* %t804
  store i64 %t803, i64* %t805
  store i1 false, i1* %t806
  store i64 -1, i64* %t807
  store i64 -1, i64* %t808
  store i1 false, i1* %t809
  br label %ht_probe_cond_179
ht_probe_cond_179:
  %t810 = load i64, i64* %t804
  %t811 = icmp slt i64 %t810, %t800
  br i1 %t811, label %ht_probe_body_180, label %ht_probe_end_190
ht_probe_body_180:
  %t812 = load i64, i64* %t805
  %t813 = getelementptr inbounds i8, i8* %t798, i64 %t812
  %t814 = load i8, i8* %t813
  %t815 = icmp eq i8 %t814, 0
  br i1 %t815, label %ht_probe_on_empty_182, label %ht_probe_check_occ_181
ht_probe_check_occ_181:
  %t816 = icmp eq i8 %t814, 1
  br i1 %t816, label %ht_probe_on_occ_185, label %ht_probe_on_tomb_187
ht_probe_on_empty_182:
  %t817 = load i1, i1* %t809
  br i1 %t817, label %ht_probe_after_islot_empty_184, label %ht_probe_set_islot_empty_183
ht_probe_set_islot_empty_183:
  store i64 %t812, i64* %t808
  store i1 true, i1* %t809
  br label %ht_probe_after_islot_empty_184
ht_probe_after_islot_empty_184:
  br label %ht_probe_end_190
ht_probe_on_occ_185:
  %t818 = getelementptr inbounds i8*, i8** %t796, i64 %t812
  %t819 = load i8*, i8** %t818
  %t820 = call i1 @eq_str(i8* %t819, i8* %t782)
  br i1 %t820, label %ht_probe_on_match_186, label %ht_probe_next_189
ht_probe_on_match_186:
  store i1 true, i1* %t806
  store i64 %t812, i64* %t807
  br label %ht_probe_end_190
ht_probe_on_tomb_187:
  %t821 = load i1, i1* %t809
  br i1 %t821, label %ht_probe_next_189, label %ht_probe_set_islot_tomb_188
ht_probe_set_islot_tomb_188:
  store i64 %t812, i64* %t808
  store i1 true, i1* %t809
  br label %ht_probe_next_189
ht_probe_next_189:
  %t822 = add i64 %t812, 1
  %t823 = and i64 %t822, %t801
  store i64 %t823, i64* %t805
  %t824 = add i64 %t810, 1
  store i64 %t824, i64* %t804
  br label %ht_probe_cond_179
ht_probe_end_190:
  %t825 = load i1, i1* %t806
  %t826 = load i64, i64* %t807
  %t827 = load i64, i64* %t808
  store i8* %t782, i8** %t828
  %t829 = load i8*, i8** %t828
  call void @star_rc_release(i8* %t829)
  br i1 %t825, label %map_get_some_191, label %map_get_none_192
map_get_some_191:
  %t830 = getelementptr inbounds i32, i32* %t797, i64 %t826
  %t831 = load i32, i32* %t830
  %t833 = getelementptr inbounds %Option__i32, %Option__i32* %t832, i32 0, i32 0
  store i32 1, i32* %t833
  %t834 = getelementptr inbounds %Option__i32, %Option__i32* %t832, i32 0, i32 1
  %t835 = bitcast [1 x i64]* %t834 to { i32 }*
  %t836 = getelementptr inbounds { i32 }, { i32 }* %t835, i32 0, i32 0
  store i32 %t831, i32* %t836
  %t837 = load %Option__i32, %Option__i32* %t832
  br label %map_get_end_193
map_get_none_192:
  %t839 = getelementptr inbounds %Option__i32, %Option__i32* %t838, i32 0, i32 0
  store i32 0, i32* %t839
  %t840 = load %Option__i32, %Option__i32* %t838
  br label %map_get_end_193
map_get_end_193:
  %t841 = phi %Option__i32 [ %t837, %map_get_some_191 ], [ %t840, %map_get_none_192 ]
  store %Option__i32 %t841, %Option__i32* %t842
  br label %match_scrutinee_844
match_scrutinee_844:
  %t848 = getelementptr inbounds %Option__i32, %Option__i32* %t842, i32 0, i32 0
  %t849 = load i32, i32* %t848
  %t847 = icmp eq i32 %t849, 1
  br i1 %t847, label %match_then_0_845, label %match_next_0_846
match_then_0_845:
  %t850 = getelementptr inbounds %Option__i32, %Option__i32* %t842, i32 0, i32 1
  %t851 = bitcast [1 x i64]* %t850 to { i32 }*
  %t852 = getelementptr inbounds { i32 }, { i32 }* %t851, i32 0, i32 0
  %t853 = load i32, i32* %t852
  %t854 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t854, i32 %t853)
  br label %match_end_843
match_next_0_846:
  %t858 = getelementptr inbounds %Option__i32, %Option__i32* %t842, i32 0, i32 0
  %t859 = load i32, i32* %t858
  %t857 = icmp eq i32 %t859, 0
  br i1 %t857, label %match_then_1_855, label %match_next_1_856
match_then_1_855:
  %t860 = getelementptr inbounds { i64, i8*, [15 x i8] }, { i64, i8*, [15 x i8] }* @.str.15, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t860)
  call i32 (i8*, ...) @printf(i8* %t860)
  %t861 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t861)
  br label %match_end_843
match_next_1_856:
  br label %match_end_843
match_end_843:
  %t863 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.17, i64 0, i32 2, i64 0
  store i8* %t863, i8** %t862
  %t864 = load i8*, i8** %t862
  %t865 = load i8*, i8** %t862
  call void @star_rc_retain(i8* %t865)
  %t866 = load i8*, i8** %t2
  %t867 = icmp eq i8* %t866, null
  br i1 %t867, label %map_read_null_194, label %map_read_real_195
map_read_null_194:
  br label %map_read_end_196
map_read_real_195:
  %t868 = bitcast i8* %t866 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t869 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t868, i32 0, i32 0
  %t870 = load i8**, i8*** %t869
  %t871 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t868, i32 0, i32 1
  %t872 = load i32*, i32** %t871
  %t873 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t868, i32 0, i32 2
  %t874 = load i8*, i8** %t873
  %t875 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t868, i32 0, i32 3
  %t876 = load i64, i64* %t875
  %t877 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t868, i32 0, i32 4
  %t878 = load i64, i64* %t877
  br label %map_read_end_196
map_read_end_196:
  %t879 = phi i8** [ null, %map_read_null_194 ], [ %t870, %map_read_real_195 ]
  %t880 = phi i32* [ null, %map_read_null_194 ], [ %t872, %map_read_real_195 ]
  %t881 = phi i8* [ null, %map_read_null_194 ], [ %t874, %map_read_real_195 ]
  %t882 = phi i64 [ 0, %map_read_null_194 ], [ %t876, %map_read_real_195 ]
  %t883 = phi i64 [ 0, %map_read_null_194 ], [ %t878, %map_read_real_195 ]
  %t884 = sub i64 %t883, 1
  %t885 = call i64 @hash_str(i8* %t864)
  %t886 = and i64 %t885, %t884
  store i64 0, i64* %t887
  store i64 %t886, i64* %t888
  store i1 false, i1* %t889
  store i64 -1, i64* %t890
  store i64 -1, i64* %t891
  store i1 false, i1* %t892
  br label %ht_probe_cond_197
ht_probe_cond_197:
  %t893 = load i64, i64* %t887
  %t894 = icmp slt i64 %t893, %t883
  br i1 %t894, label %ht_probe_body_198, label %ht_probe_end_208
ht_probe_body_198:
  %t895 = load i64, i64* %t888
  %t896 = getelementptr inbounds i8, i8* %t881, i64 %t895
  %t897 = load i8, i8* %t896
  %t898 = icmp eq i8 %t897, 0
  br i1 %t898, label %ht_probe_on_empty_200, label %ht_probe_check_occ_199
ht_probe_check_occ_199:
  %t899 = icmp eq i8 %t897, 1
  br i1 %t899, label %ht_probe_on_occ_203, label %ht_probe_on_tomb_205
ht_probe_on_empty_200:
  %t900 = load i1, i1* %t892
  br i1 %t900, label %ht_probe_after_islot_empty_202, label %ht_probe_set_islot_empty_201
ht_probe_set_islot_empty_201:
  store i64 %t895, i64* %t891
  store i1 true, i1* %t892
  br label %ht_probe_after_islot_empty_202
ht_probe_after_islot_empty_202:
  br label %ht_probe_end_208
ht_probe_on_occ_203:
  %t901 = getelementptr inbounds i8*, i8** %t879, i64 %t895
  %t902 = load i8*, i8** %t901
  %t903 = call i1 @eq_str(i8* %t902, i8* %t864)
  br i1 %t903, label %ht_probe_on_match_204, label %ht_probe_next_207
ht_probe_on_match_204:
  store i1 true, i1* %t889
  store i64 %t895, i64* %t890
  br label %ht_probe_end_208
ht_probe_on_tomb_205:
  %t904 = load i1, i1* %t892
  br i1 %t904, label %ht_probe_next_207, label %ht_probe_set_islot_tomb_206
ht_probe_set_islot_tomb_206:
  store i64 %t895, i64* %t891
  store i1 true, i1* %t892
  br label %ht_probe_next_207
ht_probe_next_207:
  %t905 = add i64 %t895, 1
  %t906 = and i64 %t905, %t884
  store i64 %t906, i64* %t888
  %t907 = add i64 %t893, 1
  store i64 %t907, i64* %t887
  br label %ht_probe_cond_197
ht_probe_end_208:
  %t908 = load i1, i1* %t889
  %t909 = load i64, i64* %t890
  %t910 = load i64, i64* %t891
  store i8* %t864, i8** %t911
  %t912 = load i8*, i8** %t911
  call void @star_rc_release(i8* %t912)
  %t913 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t914 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t915 = select i1 %t908, i8* %t913, i8* %t914
  %t916 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t916, i8* %t915)
  %t917 = getelementptr i8*, i8** null, i32 1
  %t918 = ptrtoint i8** %t917 to i64
  %t919 = getelementptr i32, i32* null, i32 1
  %t920 = ptrtoint i32* %t919 to i64
  %t921 = load i8*, i8** %t2
  %t922 = icmp eq i8* %t921, null
  br i1 %t922, label %map_cow_alloc_209, label %map_cow_check_210
map_cow_alloc_209:
  %t923 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t924 = call i8* @star_rc_alloc(i64 48, i8* %t923)
  %t925 = bitcast i8* %t924 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t926 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t925, i32 0, i32 0
  store i8** null, i8*** %t926
  %t927 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t925, i32 0, i32 1
  store i32* null, i32** %t927
  %t928 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t925, i32 0, i32 2
  store i8* null, i8** %t928
  %t929 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t925, i32 0, i32 3
  store i64 0, i64* %t929
  %t930 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t925, i32 0, i32 4
  store i64 0, i64* %t930
  %t931 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t925, i32 0, i32 5
  store i64 0, i64* %t931
  store i8* %t924, i8** %t2
  br label %map_cow_done_211
map_cow_check_210:
  %t932 = getelementptr inbounds i8, i8* %t921, i64 -16
  %t933 = bitcast i8* %t932 to i64*
  %t934 = load atomic i64, i64* %t933 seq_cst, align 8
  %t935 = icmp eq i64 %t934, 1
  br i1 %t935, label %map_cow_done_211, label %map_cow_clone_212
map_cow_clone_212:
  %t936 = bitcast i8* %t921 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t937 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t936, i32 0, i32 0
  %t938 = load i8**, i8*** %t937
  %t939 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t936, i32 0, i32 1
  %t940 = load i32*, i32** %t939
  %t941 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t936, i32 0, i32 2
  %t942 = load i8*, i8** %t941
  %t943 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t936, i32 0, i32 3
  %t944 = load i64, i64* %t943
  %t945 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t936, i32 0, i32 4
  %t946 = load i64, i64* %t945
  %t947 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t936, i32 0, i32 5
  %t948 = load i64, i64* %t947
  %t949 = bitcast void (i8*)* @map_release_3_stri32 to i8*
  %t950 = call i8* @star_rc_alloc(i64 48, i8* %t949)
  %t951 = bitcast i8* %t950 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t952 = mul i64 %t946, %t918
  %t953 = call i8* @malloc(i64 %t952)
  %t954 = bitcast i8* %t953 to i8**
  %t955 = mul i64 %t946, %t920
  %t956 = call i8* @malloc(i64 %t955)
  %t957 = bitcast i8* %t956 to i32*
  %t958 = call i8* @malloc(i64 %t946)
  %t959 = icmp sgt i64 %t946, 0
  br i1 %t959, label %map_cow_copy_213, label %map_cow_after_copy_214
map_cow_copy_213:
  %t960 = mul i64 %t946, %t918
  %t961 = bitcast i8** %t938 to i8*
  call i8* @memcpy(i8* %t953, i8* %t961, i64 %t960)
  %t962 = mul i64 %t946, %t920
  %t963 = bitcast i32* %t940 to i8*
  call i8* @memcpy(i8* %t956, i8* %t963, i64 %t962)
  call i8* @memcpy(i8* %t958, i8* %t942, i64 %t946)
  store i64 0, i64* %t964
  br label %map_cow_retain_cond_215
map_cow_retain_cond_215:
  %t965 = load i64, i64* %t964
  %t966 = icmp slt i64 %t965, %t946
  br i1 %t966, label %map_cow_retain_body_216, label %map_cow_retain_end_219
map_cow_retain_body_216:
  %t967 = getelementptr inbounds i8, i8* %t958, i64 %t965
  %t968 = load i8, i8* %t967
  %t969 = icmp eq i8 %t968, 1
  br i1 %t969, label %map_cow_retain_occ_217, label %map_cow_retain_next_218
map_cow_retain_occ_217:
  %t970 = getelementptr inbounds i8*, i8** %t954, i64 %t965
  %t971 = load i8*, i8** %t970
  call void @star_rc_retain(i8* %t971)
  br label %map_cow_retain_next_218
map_cow_retain_next_218:
  %t972 = add i64 %t965, 1
  store i64 %t972, i64* %t964
  br label %map_cow_retain_cond_215
map_cow_retain_end_219:
  br label %map_cow_after_copy_214
map_cow_after_copy_214:
  %t973 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t951, i32 0, i32 0
  store i8** %t954, i8*** %t973
  %t974 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t951, i32 0, i32 1
  store i32* %t957, i32** %t974
  %t975 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t951, i32 0, i32 2
  store i8* %t958, i8** %t975
  %t976 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t951, i32 0, i32 3
  store i64 %t944, i64* %t976
  %t977 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t951, i32 0, i32 4
  store i64 %t946, i64* %t977
  %t978 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t951, i32 0, i32 5
  store i64 %t948, i64* %t978
  call void @star_rc_release(i8* %t921)
  store i8* %t950, i8** %t2
  br label %map_cow_done_211
map_cow_done_211:
  %t979 = load i8*, i8** %t2
  %t980 = bitcast i8* %t979 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t981 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t980, i32 0, i32 0
  %t982 = load i8**, i8*** %t981
  %t983 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t980, i32 0, i32 1
  %t984 = load i32*, i32** %t983
  %t985 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t980, i32 0, i32 2
  %t986 = load i8*, i8** %t985
  %t987 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t980, i32 0, i32 3
  %t988 = load i64, i64* %t987
  %t989 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t980, i32 0, i32 4
  %t990 = load i64, i64* %t989
  %t991 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t980, i32 0, i32 5
  %t992 = load i64, i64* %t991
  %t993 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t994 = load i8**, i8*** %t981
  %t995 = load i32*, i32** %t983
  %t996 = load i8*, i8** %t985
  %t997 = load i64, i64* %t989
  %t998 = sub i64 %t997, 1
  %t999 = call i64 @hash_str(i8* %t993)
  %t1000 = and i64 %t999, %t998
  store i64 0, i64* %t1001
  store i64 %t1000, i64* %t1002
  store i1 false, i1* %t1003
  store i64 -1, i64* %t1004
  store i64 -1, i64* %t1005
  store i1 false, i1* %t1006
  br label %ht_probe_cond_220
ht_probe_cond_220:
  %t1007 = load i64, i64* %t1001
  %t1008 = icmp slt i64 %t1007, %t997
  br i1 %t1008, label %ht_probe_body_221, label %ht_probe_end_231
ht_probe_body_221:
  %t1009 = load i64, i64* %t1002
  %t1010 = getelementptr inbounds i8, i8* %t996, i64 %t1009
  %t1011 = load i8, i8* %t1010
  %t1012 = icmp eq i8 %t1011, 0
  br i1 %t1012, label %ht_probe_on_empty_223, label %ht_probe_check_occ_222
ht_probe_check_occ_222:
  %t1013 = icmp eq i8 %t1011, 1
  br i1 %t1013, label %ht_probe_on_occ_226, label %ht_probe_on_tomb_228
ht_probe_on_empty_223:
  %t1014 = load i1, i1* %t1006
  br i1 %t1014, label %ht_probe_after_islot_empty_225, label %ht_probe_set_islot_empty_224
ht_probe_set_islot_empty_224:
  store i64 %t1009, i64* %t1005
  store i1 true, i1* %t1006
  br label %ht_probe_after_islot_empty_225
ht_probe_after_islot_empty_225:
  br label %ht_probe_end_231
ht_probe_on_occ_226:
  %t1015 = getelementptr inbounds i8*, i8** %t994, i64 %t1009
  %t1016 = load i8*, i8** %t1015
  %t1017 = call i1 @eq_str(i8* %t1016, i8* %t993)
  br i1 %t1017, label %ht_probe_on_match_227, label %ht_probe_next_230
ht_probe_on_match_227:
  store i1 true, i1* %t1003
  store i64 %t1009, i64* %t1004
  br label %ht_probe_end_231
ht_probe_on_tomb_228:
  %t1018 = load i1, i1* %t1006
  br i1 %t1018, label %ht_probe_next_230, label %ht_probe_set_islot_tomb_229
ht_probe_set_islot_tomb_229:
  store i64 %t1009, i64* %t1005
  store i1 true, i1* %t1006
  br label %ht_probe_next_230
ht_probe_next_230:
  %t1019 = add i64 %t1009, 1
  %t1020 = and i64 %t1019, %t998
  store i64 %t1020, i64* %t1002
  %t1021 = add i64 %t1007, 1
  store i64 %t1021, i64* %t1001
  br label %ht_probe_cond_220
ht_probe_end_231:
  %t1022 = load i1, i1* %t1003
  %t1023 = load i64, i64* %t1004
  %t1024 = load i64, i64* %t1005
  store i8* %t993, i8** %t1025
  %t1026 = load i8*, i8** %t1025
  call void @star_rc_release(i8* %t1026)
  br i1 %t1022, label %map_remove_some_232, label %map_remove_none_233
map_remove_some_232:
  %t1027 = getelementptr inbounds i8*, i8** %t994, i64 %t1023
  %t1028 = getelementptr inbounds i32, i32* %t995, i64 %t1023
  %t1029 = load i32, i32* %t1028
  %t1030 = load i8*, i8** %t1027
  call void @star_rc_release(i8* %t1030)
  %t1031 = getelementptr inbounds i8, i8* %t996, i64 %t1023
  store i8 2, i8* %t1031
  %t1032 = load i64, i64* %t987
  %t1033 = sub i64 %t1032, 1
  store i64 %t1033, i64* %t987
  %t1034 = load i64, i64* %t991
  %t1035 = add i64 %t1034, 1
  store i64 %t1035, i64* %t991
  %t1037 = getelementptr inbounds %Option__i32, %Option__i32* %t1036, i32 0, i32 0
  store i32 1, i32* %t1037
  %t1038 = getelementptr inbounds %Option__i32, %Option__i32* %t1036, i32 0, i32 1
  %t1039 = bitcast [1 x i64]* %t1038 to { i32 }*
  %t1040 = getelementptr inbounds { i32 }, { i32 }* %t1039, i32 0, i32 0
  store i32 %t1029, i32* %t1040
  %t1041 = load %Option__i32, %Option__i32* %t1036
  br label %map_remove_end_234
map_remove_none_233:
  %t1043 = getelementptr inbounds %Option__i32, %Option__i32* %t1042, i32 0, i32 0
  store i32 0, i32* %t1043
  %t1044 = load %Option__i32, %Option__i32* %t1042
  br label %map_remove_end_234
map_remove_end_234:
  %t1045 = phi %Option__i32 [ %t1041, %map_remove_some_232 ], [ %t1044, %map_remove_none_233 ]
  store %Option__i32 %t1045, %Option__i32* %t1046
  br label %match_scrutinee_1048
match_scrutinee_1048:
  %t1052 = getelementptr inbounds %Option__i32, %Option__i32* %t1046, i32 0, i32 0
  %t1053 = load i32, i32* %t1052
  %t1051 = icmp eq i32 %t1053, 1
  br i1 %t1051, label %match_then_0_1049, label %match_next_0_1050
match_then_0_1049:
  %t1054 = getelementptr inbounds %Option__i32, %Option__i32* %t1046, i32 0, i32 1
  %t1055 = bitcast [1 x i64]* %t1054 to { i32 }*
  %t1056 = getelementptr inbounds { i32 }, { i32 }* %t1055, i32 0, i32 0
  %t1057 = load i32, i32* %t1056
  %t1058 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1058, i32 %t1057)
  br label %match_end_1047
match_next_0_1050:
  %t1062 = getelementptr inbounds %Option__i32, %Option__i32* %t1046, i32 0, i32 0
  %t1063 = load i32, i32* %t1062
  %t1061 = icmp eq i32 %t1063, 0
  br i1 %t1061, label %match_then_1_1059, label %match_next_1_1060
match_then_1_1059:
  %t1064 = getelementptr inbounds { i64, i8*, [13 x i8] }, { i64, i8*, [13 x i8] }* @.str.23, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t1064)
  call i32 (i8*, ...) @printf(i8* %t1064)
  %t1065 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1065)
  br label %match_end_1047
match_next_1_1060:
  br label %match_end_1047
match_end_1047:
  %t1066 = load i8*, i8** %t862
  %t1067 = load i8*, i8** %t862
  call void @star_rc_retain(i8* %t1067)
  %t1068 = load i8*, i8** %t2
  %t1069 = icmp eq i8* %t1068, null
  br i1 %t1069, label %map_read_null_235, label %map_read_real_236
map_read_null_235:
  br label %map_read_end_237
map_read_real_236:
  %t1070 = bitcast i8* %t1068 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1071 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1070, i32 0, i32 0
  %t1072 = load i8**, i8*** %t1071
  %t1073 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1070, i32 0, i32 1
  %t1074 = load i32*, i32** %t1073
  %t1075 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1070, i32 0, i32 2
  %t1076 = load i8*, i8** %t1075
  %t1077 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1070, i32 0, i32 3
  %t1078 = load i64, i64* %t1077
  %t1079 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1070, i32 0, i32 4
  %t1080 = load i64, i64* %t1079
  br label %map_read_end_237
map_read_end_237:
  %t1081 = phi i8** [ null, %map_read_null_235 ], [ %t1072, %map_read_real_236 ]
  %t1082 = phi i32* [ null, %map_read_null_235 ], [ %t1074, %map_read_real_236 ]
  %t1083 = phi i8* [ null, %map_read_null_235 ], [ %t1076, %map_read_real_236 ]
  %t1084 = phi i64 [ 0, %map_read_null_235 ], [ %t1078, %map_read_real_236 ]
  %t1085 = phi i64 [ 0, %map_read_null_235 ], [ %t1080, %map_read_real_236 ]
  %t1086 = sub i64 %t1085, 1
  %t1087 = call i64 @hash_str(i8* %t1066)
  %t1088 = and i64 %t1087, %t1086
  store i64 0, i64* %t1089
  store i64 %t1088, i64* %t1090
  store i1 false, i1* %t1091
  store i64 -1, i64* %t1092
  store i64 -1, i64* %t1093
  store i1 false, i1* %t1094
  br label %ht_probe_cond_238
ht_probe_cond_238:
  %t1095 = load i64, i64* %t1089
  %t1096 = icmp slt i64 %t1095, %t1085
  br i1 %t1096, label %ht_probe_body_239, label %ht_probe_end_249
ht_probe_body_239:
  %t1097 = load i64, i64* %t1090
  %t1098 = getelementptr inbounds i8, i8* %t1083, i64 %t1097
  %t1099 = load i8, i8* %t1098
  %t1100 = icmp eq i8 %t1099, 0
  br i1 %t1100, label %ht_probe_on_empty_241, label %ht_probe_check_occ_240
ht_probe_check_occ_240:
  %t1101 = icmp eq i8 %t1099, 1
  br i1 %t1101, label %ht_probe_on_occ_244, label %ht_probe_on_tomb_246
ht_probe_on_empty_241:
  %t1102 = load i1, i1* %t1094
  br i1 %t1102, label %ht_probe_after_islot_empty_243, label %ht_probe_set_islot_empty_242
ht_probe_set_islot_empty_242:
  store i64 %t1097, i64* %t1093
  store i1 true, i1* %t1094
  br label %ht_probe_after_islot_empty_243
ht_probe_after_islot_empty_243:
  br label %ht_probe_end_249
ht_probe_on_occ_244:
  %t1103 = getelementptr inbounds i8*, i8** %t1081, i64 %t1097
  %t1104 = load i8*, i8** %t1103
  %t1105 = call i1 @eq_str(i8* %t1104, i8* %t1066)
  br i1 %t1105, label %ht_probe_on_match_245, label %ht_probe_next_248
ht_probe_on_match_245:
  store i1 true, i1* %t1091
  store i64 %t1097, i64* %t1092
  br label %ht_probe_end_249
ht_probe_on_tomb_246:
  %t1106 = load i1, i1* %t1094
  br i1 %t1106, label %ht_probe_next_248, label %ht_probe_set_islot_tomb_247
ht_probe_set_islot_tomb_247:
  store i64 %t1097, i64* %t1093
  store i1 true, i1* %t1094
  br label %ht_probe_next_248
ht_probe_next_248:
  %t1107 = add i64 %t1097, 1
  %t1108 = and i64 %t1107, %t1086
  store i64 %t1108, i64* %t1090
  %t1109 = add i64 %t1095, 1
  store i64 %t1109, i64* %t1089
  br label %ht_probe_cond_238
ht_probe_end_249:
  %t1110 = load i1, i1* %t1091
  %t1111 = load i64, i64* %t1092
  %t1112 = load i64, i64* %t1093
  store i8* %t1066, i8** %t1113
  %t1114 = load i8*, i8** %t1113
  call void @star_rc_release(i8* %t1114)
  %t1115 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.25, i64 0, i64 0
  %t1116 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.26, i64 0, i64 0
  %t1117 = select i1 %t1110, i8* %t1115, i8* %t1116
  %t1118 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.27, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1118, i8* %t1117)
  %t1119 = load i8*, i8** %t2
  %t1120 = icmp eq i8* %t1119, null
  br i1 %t1120, label %map_read_null_250, label %map_read_real_251
map_read_null_250:
  br label %map_read_end_252
map_read_real_251:
  %t1121 = bitcast i8* %t1119 to { i8**, i32*, i8*, i64, i64, i64 }*
  %t1122 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1121, i32 0, i32 0
  %t1123 = load i8**, i8*** %t1122
  %t1124 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1121, i32 0, i32 1
  %t1125 = load i32*, i32** %t1124
  %t1126 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1121, i32 0, i32 2
  %t1127 = load i8*, i8** %t1126
  %t1128 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1121, i32 0, i32 3
  %t1129 = load i64, i64* %t1128
  %t1130 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t1121, i32 0, i32 4
  %t1131 = load i64, i64* %t1130
  br label %map_read_end_252
map_read_end_252:
  %t1132 = phi i8** [ null, %map_read_null_250 ], [ %t1123, %map_read_real_251 ]
  %t1133 = phi i32* [ null, %map_read_null_250 ], [ %t1125, %map_read_real_251 ]
  %t1134 = phi i8* [ null, %map_read_null_250 ], [ %t1127, %map_read_real_251 ]
  %t1135 = phi i64 [ 0, %map_read_null_250 ], [ %t1129, %map_read_real_251 ]
  %t1136 = phi i64 [ 0, %map_read_null_250 ], [ %t1131, %map_read_real_251 ]
  %t1137 = trunc i64 %t1135 to i32
  %t1138 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.28, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1138, i32 %t1137)
  store i8* null, i8** %t1139
  %t1140 = getelementptr i32, i32* null, i32 1
  %t1141 = ptrtoint i32* %t1140 to i64
  %t1142 = load i8*, i8** %t1139
  %t1143 = icmp eq i8* %t1142, null
  br i1 %t1143, label %set_cow_alloc_253, label %set_cow_check_254
set_cow_alloc_253:
  %t1152 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1153 = call i8* @star_rc_alloc(i64 40, i8* %t1152)
  %t1154 = bitcast i8* %t1153 to { i32*, i8*, i64, i64, i64 }*
  %t1155 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1154, i32 0, i32 0
  store i32* null, i32** %t1155
  %t1156 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1154, i32 0, i32 1
  store i8* null, i8** %t1156
  %t1157 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1154, i32 0, i32 2
  store i64 0, i64* %t1157
  %t1158 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1154, i32 0, i32 3
  store i64 0, i64* %t1158
  %t1159 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1154, i32 0, i32 4
  store i64 0, i64* %t1159
  store i8* %t1153, i8** %t1139
  br label %set_cow_done_255
set_cow_check_254:
  %t1160 = getelementptr inbounds i8, i8* %t1142, i64 -16
  %t1161 = bitcast i8* %t1160 to i64*
  %t1162 = load atomic i64, i64* %t1161 seq_cst, align 8
  %t1163 = icmp eq i64 %t1162, 1
  br i1 %t1163, label %set_cow_done_255, label %set_cow_clone_256
set_cow_clone_256:
  %t1164 = bitcast i8* %t1142 to { i32*, i8*, i64, i64, i64 }*
  %t1165 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1164, i32 0, i32 0
  %t1166 = load i32*, i32** %t1165
  %t1167 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1164, i32 0, i32 1
  %t1168 = load i8*, i8** %t1167
  %t1169 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1164, i32 0, i32 2
  %t1170 = load i64, i64* %t1169
  %t1171 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1164, i32 0, i32 3
  %t1172 = load i64, i64* %t1171
  %t1173 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1164, i32 0, i32 4
  %t1174 = load i64, i64* %t1173
  %t1175 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1176 = call i8* @star_rc_alloc(i64 40, i8* %t1175)
  %t1177 = bitcast i8* %t1176 to { i32*, i8*, i64, i64, i64 }*
  %t1178 = mul i64 %t1172, %t1141
  %t1179 = call i8* @malloc(i64 %t1178)
  %t1180 = bitcast i8* %t1179 to i32*
  %t1181 = call i8* @malloc(i64 %t1172)
  %t1182 = icmp sgt i64 %t1172, 0
  br i1 %t1182, label %set_cow_copy_257, label %set_cow_after_copy_258
set_cow_copy_257:
  %t1183 = mul i64 %t1172, %t1141
  %t1184 = bitcast i32* %t1166 to i8*
  call i8* @memcpy(i8* %t1179, i8* %t1184, i64 %t1183)
  call i8* @memcpy(i8* %t1181, i8* %t1168, i64 %t1172)
  br label %set_cow_after_copy_258
set_cow_after_copy_258:
  %t1185 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1177, i32 0, i32 0
  store i32* %t1180, i32** %t1185
  %t1186 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1177, i32 0, i32 1
  store i8* %t1181, i8** %t1186
  %t1187 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1177, i32 0, i32 2
  store i64 %t1170, i64* %t1187
  %t1188 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1177, i32 0, i32 3
  store i64 %t1172, i64* %t1188
  %t1189 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1177, i32 0, i32 4
  store i64 %t1174, i64* %t1189
  call void @star_rc_release(i8* %t1142)
  store i8* %t1176, i8** %t1139
  br label %set_cow_done_255
set_cow_done_255:
  %t1190 = load i8*, i8** %t1139
  %t1191 = bitcast i8* %t1190 to { i32*, i8*, i64, i64, i64 }*
  %t1192 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1191, i32 0, i32 0
  %t1193 = load i32*, i32** %t1192
  %t1194 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1191, i32 0, i32 1
  %t1195 = load i8*, i8** %t1194
  %t1196 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1191, i32 0, i32 2
  %t1197 = load i64, i64* %t1196
  %t1198 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1191, i32 0, i32 3
  %t1199 = load i64, i64* %t1198
  %t1200 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1191, i32 0, i32 4
  %t1201 = load i64, i64* %t1200
  %t1202 = load i64, i64* %t1196
  %t1203 = load i64, i64* %t1198
  %t1204 = load i64, i64* %t1200
  %t1205 = add i64 %t1202, %t1204
  %t1206 = add i64 %t1205, 1
  %t1207 = mul i64 %t1206, 4
  %t1208 = mul i64 %t1203, 3
  %t1209 = icmp sgt i64 %t1207, %t1208
  br i1 %t1209, label %set_insert_grow_259, label %set_insert_after_grow_260
set_insert_grow_259:
  %t1210 = getelementptr i32, i32* null, i32 1
  %t1211 = ptrtoint i32* %t1210 to i64
  %t1212 = mul i64 %t1203, 2
  %t1213 = icmp sgt i64 %t1212, 0
  %t1214 = select i1 %t1213, i64 %t1212, i64 8
  %t1215 = sub i64 %t1214, 1
  %t1216 = mul i64 %t1214, %t1211
  %t1217 = call i8* @malloc(i64 %t1216)
  %t1218 = bitcast i8* %t1217 to i32*
  %t1219 = call i8* @malloc(i64 %t1214)
  store i64 0, i64* %t1220
  br label %ht_fill8_cond_261
ht_fill8_cond_261:
  %t1221 = load i64, i64* %t1220
  %t1222 = icmp slt i64 %t1221, %t1214
  br i1 %t1222, label %ht_fill8_body_262, label %ht_fill8_end_263
ht_fill8_body_262:
  %t1223 = getelementptr inbounds i8, i8* %t1219, i64 %t1221
  store i8 0, i8* %t1223
  %t1224 = add i64 %t1221, 1
  store i64 %t1224, i64* %t1220
  br label %ht_fill8_cond_261
ht_fill8_end_263:
  %t1225 = load i32*, i32** %t1192
  %t1226 = load i8*, i8** %t1194
  store i64 0, i64* %t1227
  br label %set_grow_cond_264
set_grow_cond_264:
  %t1228 = load i64, i64* %t1227
  %t1229 = icmp slt i64 %t1228, %t1203
  br i1 %t1229, label %set_grow_body_265, label %set_grow_end_268
set_grow_body_265:
  %t1230 = getelementptr inbounds i8, i8* %t1226, i64 %t1228
  %t1231 = load i8, i8* %t1230
  %t1232 = icmp eq i8 %t1231, 1
  br i1 %t1232, label %set_grow_occ_266, label %set_grow_next_267
set_grow_occ_266:
  %t1233 = getelementptr inbounds i32, i32* %t1225, i64 %t1228
  %t1234 = load i32, i32* %t1233
  %t1241 = call i64 @hash_i32(i32 %t1234)
  %t1242 = and i64 %t1241, %t1215
  store i64 0, i64* %t1243
  store i64 %t1242, i64* %t1244
  br label %ht_fe_cond_269
ht_fe_cond_269:
  %t1245 = load i64, i64* %t1243
  %t1246 = icmp slt i64 %t1245, %t1214
  br i1 %t1246, label %ht_fe_body_270, label %ht_fe_end_272
ht_fe_body_270:
  %t1247 = load i64, i64* %t1244
  %t1248 = getelementptr inbounds i8, i8* %t1219, i64 %t1247
  %t1249 = load i8, i8* %t1248
  %t1250 = icmp eq i8 %t1249, 0
  br i1 %t1250, label %ht_fe_end_272, label %ht_fe_next_271
ht_fe_next_271:
  %t1251 = add i64 %t1247, 1
  %t1252 = and i64 %t1251, %t1215
  store i64 %t1252, i64* %t1244
  %t1253 = add i64 %t1245, 1
  store i64 %t1253, i64* %t1243
  br label %ht_fe_cond_269
ht_fe_end_272:
  %t1254 = load i64, i64* %t1244
  %t1255 = getelementptr inbounds i8, i8* %t1219, i64 %t1254
  store i8 1, i8* %t1255
  %t1256 = getelementptr inbounds i32, i32* %t1218, i64 %t1254
  store i32 %t1234, i32* %t1256
  br label %set_grow_next_267
set_grow_next_267:
  %t1257 = add i64 %t1228, 1
  store i64 %t1257, i64* %t1227
  br label %set_grow_cond_264
set_grow_end_268:
  %t1258 = bitcast i32* %t1225 to i8*
  call void @free(i8* %t1258)
  call void @free(i8* %t1226)
  store i32* %t1218, i32** %t1192
  store i8* %t1219, i8** %t1194
  store i64 %t1214, i64* %t1198
  store i64 0, i64* %t1200
  br label %set_insert_after_grow_260
set_insert_after_grow_260:
  %t1259 = load i32*, i32** %t1192
  %t1260 = load i8*, i8** %t1194
  %t1261 = load i64, i64* %t1198
  %t1262 = sub i64 %t1261, 1
  %t1263 = call i64 @hash_i32(i32 1)
  %t1264 = and i64 %t1263, %t1262
  store i64 0, i64* %t1266
  store i64 %t1264, i64* %t1267
  store i1 false, i1* %t1268
  store i64 -1, i64* %t1269
  store i64 -1, i64* %t1270
  store i1 false, i1* %t1271
  br label %ht_probe_cond_273
ht_probe_cond_273:
  %t1272 = load i64, i64* %t1266
  %t1273 = icmp slt i64 %t1272, %t1261
  br i1 %t1273, label %ht_probe_body_274, label %ht_probe_end_284
ht_probe_body_274:
  %t1274 = load i64, i64* %t1267
  %t1275 = getelementptr inbounds i8, i8* %t1260, i64 %t1274
  %t1276 = load i8, i8* %t1275
  %t1277 = icmp eq i8 %t1276, 0
  br i1 %t1277, label %ht_probe_on_empty_276, label %ht_probe_check_occ_275
ht_probe_check_occ_275:
  %t1278 = icmp eq i8 %t1276, 1
  br i1 %t1278, label %ht_probe_on_occ_279, label %ht_probe_on_tomb_281
ht_probe_on_empty_276:
  %t1279 = load i1, i1* %t1271
  br i1 %t1279, label %ht_probe_after_islot_empty_278, label %ht_probe_set_islot_empty_277
ht_probe_set_islot_empty_277:
  store i64 %t1274, i64* %t1270
  store i1 true, i1* %t1271
  br label %ht_probe_after_islot_empty_278
ht_probe_after_islot_empty_278:
  br label %ht_probe_end_284
ht_probe_on_occ_279:
  %t1280 = getelementptr inbounds i32, i32* %t1259, i64 %t1274
  %t1281 = load i32, i32* %t1280
  %t1282 = call i1 @eq_i32(i32 %t1281, i32 1)
  br i1 %t1282, label %ht_probe_on_match_280, label %ht_probe_next_283
ht_probe_on_match_280:
  store i1 true, i1* %t1268
  store i64 %t1274, i64* %t1269
  br label %ht_probe_end_284
ht_probe_on_tomb_281:
  %t1283 = load i1, i1* %t1271
  br i1 %t1283, label %ht_probe_next_283, label %ht_probe_set_islot_tomb_282
ht_probe_set_islot_tomb_282:
  store i64 %t1274, i64* %t1270
  store i1 true, i1* %t1271
  br label %ht_probe_next_283
ht_probe_next_283:
  %t1284 = add i64 %t1274, 1
  %t1285 = and i64 %t1284, %t1262
  store i64 %t1285, i64* %t1267
  %t1286 = add i64 %t1272, 1
  store i64 %t1286, i64* %t1266
  br label %ht_probe_cond_273
ht_probe_end_284:
  %t1287 = load i1, i1* %t1268
  %t1288 = load i64, i64* %t1269
  %t1289 = load i64, i64* %t1270
  %t1290 = xor i1 %t1287, true
  br i1 %t1287, label %set_insert_already_present_285, label %set_insert_do_286
set_insert_already_present_285:
  br label %set_insert_end_287
set_insert_do_286:
  %t1291 = getelementptr inbounds i8, i8* %t1260, i64 %t1289
  %t1292 = load i8, i8* %t1291
  %t1293 = icmp eq i8 %t1292, 2
  br i1 %t1293, label %set_insert_dec_tomb_288, label %set_insert_store_289
set_insert_dec_tomb_288:
  %t1294 = load i64, i64* %t1200
  %t1295 = sub i64 %t1294, 1
  store i64 %t1295, i64* %t1200
  br label %set_insert_store_289
set_insert_store_289:
  store i8 1, i8* %t1291
  %t1296 = getelementptr inbounds i32, i32* %t1259, i64 %t1289
  store i32 1, i32* %t1296
  %t1297 = load i64, i64* %t1196
  %t1298 = add i64 %t1297, 1
  store i64 %t1298, i64* %t1196
  br label %set_insert_end_287
set_insert_end_287:
  %t1299 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.29, i64 0, i64 0
  %t1300 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.30, i64 0, i64 0
  %t1301 = select i1 %t1290, i8* %t1299, i8* %t1300
  %t1302 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1302, i8* %t1301)
  %t1303 = getelementptr i32, i32* null, i32 1
  %t1304 = ptrtoint i32* %t1303 to i64
  %t1305 = load i8*, i8** %t1139
  %t1306 = icmp eq i8* %t1305, null
  br i1 %t1306, label %set_cow_alloc_290, label %set_cow_check_291
set_cow_alloc_290:
  %t1307 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1308 = call i8* @star_rc_alloc(i64 40, i8* %t1307)
  %t1309 = bitcast i8* %t1308 to { i32*, i8*, i64, i64, i64 }*
  %t1310 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1309, i32 0, i32 0
  store i32* null, i32** %t1310
  %t1311 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1309, i32 0, i32 1
  store i8* null, i8** %t1311
  %t1312 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1309, i32 0, i32 2
  store i64 0, i64* %t1312
  %t1313 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1309, i32 0, i32 3
  store i64 0, i64* %t1313
  %t1314 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1309, i32 0, i32 4
  store i64 0, i64* %t1314
  store i8* %t1308, i8** %t1139
  br label %set_cow_done_292
set_cow_check_291:
  %t1315 = getelementptr inbounds i8, i8* %t1305, i64 -16
  %t1316 = bitcast i8* %t1315 to i64*
  %t1317 = load atomic i64, i64* %t1316 seq_cst, align 8
  %t1318 = icmp eq i64 %t1317, 1
  br i1 %t1318, label %set_cow_done_292, label %set_cow_clone_293
set_cow_clone_293:
  %t1319 = bitcast i8* %t1305 to { i32*, i8*, i64, i64, i64 }*
  %t1320 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1319, i32 0, i32 0
  %t1321 = load i32*, i32** %t1320
  %t1322 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1319, i32 0, i32 1
  %t1323 = load i8*, i8** %t1322
  %t1324 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1319, i32 0, i32 2
  %t1325 = load i64, i64* %t1324
  %t1326 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1319, i32 0, i32 3
  %t1327 = load i64, i64* %t1326
  %t1328 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1319, i32 0, i32 4
  %t1329 = load i64, i64* %t1328
  %t1330 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1331 = call i8* @star_rc_alloc(i64 40, i8* %t1330)
  %t1332 = bitcast i8* %t1331 to { i32*, i8*, i64, i64, i64 }*
  %t1333 = mul i64 %t1327, %t1304
  %t1334 = call i8* @malloc(i64 %t1333)
  %t1335 = bitcast i8* %t1334 to i32*
  %t1336 = call i8* @malloc(i64 %t1327)
  %t1337 = icmp sgt i64 %t1327, 0
  br i1 %t1337, label %set_cow_copy_294, label %set_cow_after_copy_295
set_cow_copy_294:
  %t1338 = mul i64 %t1327, %t1304
  %t1339 = bitcast i32* %t1321 to i8*
  call i8* @memcpy(i8* %t1334, i8* %t1339, i64 %t1338)
  call i8* @memcpy(i8* %t1336, i8* %t1323, i64 %t1327)
  br label %set_cow_after_copy_295
set_cow_after_copy_295:
  %t1340 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1332, i32 0, i32 0
  store i32* %t1335, i32** %t1340
  %t1341 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1332, i32 0, i32 1
  store i8* %t1336, i8** %t1341
  %t1342 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1332, i32 0, i32 2
  store i64 %t1325, i64* %t1342
  %t1343 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1332, i32 0, i32 3
  store i64 %t1327, i64* %t1343
  %t1344 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1332, i32 0, i32 4
  store i64 %t1329, i64* %t1344
  call void @star_rc_release(i8* %t1305)
  store i8* %t1331, i8** %t1139
  br label %set_cow_done_292
set_cow_done_292:
  %t1345 = load i8*, i8** %t1139
  %t1346 = bitcast i8* %t1345 to { i32*, i8*, i64, i64, i64 }*
  %t1347 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1346, i32 0, i32 0
  %t1348 = load i32*, i32** %t1347
  %t1349 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1346, i32 0, i32 1
  %t1350 = load i8*, i8** %t1349
  %t1351 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1346, i32 0, i32 2
  %t1352 = load i64, i64* %t1351
  %t1353 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1346, i32 0, i32 3
  %t1354 = load i64, i64* %t1353
  %t1355 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1346, i32 0, i32 4
  %t1356 = load i64, i64* %t1355
  %t1357 = load i64, i64* %t1351
  %t1358 = load i64, i64* %t1353
  %t1359 = load i64, i64* %t1355
  %t1360 = add i64 %t1357, %t1359
  %t1361 = add i64 %t1360, 1
  %t1362 = mul i64 %t1361, 4
  %t1363 = mul i64 %t1358, 3
  %t1364 = icmp sgt i64 %t1362, %t1363
  br i1 %t1364, label %set_insert_grow_296, label %set_insert_after_grow_297
set_insert_grow_296:
  %t1365 = getelementptr i32, i32* null, i32 1
  %t1366 = ptrtoint i32* %t1365 to i64
  %t1367 = mul i64 %t1358, 2
  %t1368 = icmp sgt i64 %t1367, 0
  %t1369 = select i1 %t1368, i64 %t1367, i64 8
  %t1370 = sub i64 %t1369, 1
  %t1371 = mul i64 %t1369, %t1366
  %t1372 = call i8* @malloc(i64 %t1371)
  %t1373 = bitcast i8* %t1372 to i32*
  %t1374 = call i8* @malloc(i64 %t1369)
  store i64 0, i64* %t1375
  br label %ht_fill8_cond_298
ht_fill8_cond_298:
  %t1376 = load i64, i64* %t1375
  %t1377 = icmp slt i64 %t1376, %t1369
  br i1 %t1377, label %ht_fill8_body_299, label %ht_fill8_end_300
ht_fill8_body_299:
  %t1378 = getelementptr inbounds i8, i8* %t1374, i64 %t1376
  store i8 0, i8* %t1378
  %t1379 = add i64 %t1376, 1
  store i64 %t1379, i64* %t1375
  br label %ht_fill8_cond_298
ht_fill8_end_300:
  %t1380 = load i32*, i32** %t1347
  %t1381 = load i8*, i8** %t1349
  store i64 0, i64* %t1382
  br label %set_grow_cond_301
set_grow_cond_301:
  %t1383 = load i64, i64* %t1382
  %t1384 = icmp slt i64 %t1383, %t1358
  br i1 %t1384, label %set_grow_body_302, label %set_grow_end_305
set_grow_body_302:
  %t1385 = getelementptr inbounds i8, i8* %t1381, i64 %t1383
  %t1386 = load i8, i8* %t1385
  %t1387 = icmp eq i8 %t1386, 1
  br i1 %t1387, label %set_grow_occ_303, label %set_grow_next_304
set_grow_occ_303:
  %t1388 = getelementptr inbounds i32, i32* %t1380, i64 %t1383
  %t1389 = load i32, i32* %t1388
  %t1390 = call i64 @hash_i32(i32 %t1389)
  %t1391 = and i64 %t1390, %t1370
  store i64 0, i64* %t1392
  store i64 %t1391, i64* %t1393
  br label %ht_fe_cond_306
ht_fe_cond_306:
  %t1394 = load i64, i64* %t1392
  %t1395 = icmp slt i64 %t1394, %t1369
  br i1 %t1395, label %ht_fe_body_307, label %ht_fe_end_309
ht_fe_body_307:
  %t1396 = load i64, i64* %t1393
  %t1397 = getelementptr inbounds i8, i8* %t1374, i64 %t1396
  %t1398 = load i8, i8* %t1397
  %t1399 = icmp eq i8 %t1398, 0
  br i1 %t1399, label %ht_fe_end_309, label %ht_fe_next_308
ht_fe_next_308:
  %t1400 = add i64 %t1396, 1
  %t1401 = and i64 %t1400, %t1370
  store i64 %t1401, i64* %t1393
  %t1402 = add i64 %t1394, 1
  store i64 %t1402, i64* %t1392
  br label %ht_fe_cond_306
ht_fe_end_309:
  %t1403 = load i64, i64* %t1393
  %t1404 = getelementptr inbounds i8, i8* %t1374, i64 %t1403
  store i8 1, i8* %t1404
  %t1405 = getelementptr inbounds i32, i32* %t1373, i64 %t1403
  store i32 %t1389, i32* %t1405
  br label %set_grow_next_304
set_grow_next_304:
  %t1406 = add i64 %t1383, 1
  store i64 %t1406, i64* %t1382
  br label %set_grow_cond_301
set_grow_end_305:
  %t1407 = bitcast i32* %t1380 to i8*
  call void @free(i8* %t1407)
  call void @free(i8* %t1381)
  store i32* %t1373, i32** %t1347
  store i8* %t1374, i8** %t1349
  store i64 %t1369, i64* %t1353
  store i64 0, i64* %t1355
  br label %set_insert_after_grow_297
set_insert_after_grow_297:
  %t1408 = load i32*, i32** %t1347
  %t1409 = load i8*, i8** %t1349
  %t1410 = load i64, i64* %t1353
  %t1411 = sub i64 %t1410, 1
  %t1412 = call i64 @hash_i32(i32 2)
  %t1413 = and i64 %t1412, %t1411
  store i64 0, i64* %t1414
  store i64 %t1413, i64* %t1415
  store i1 false, i1* %t1416
  store i64 -1, i64* %t1417
  store i64 -1, i64* %t1418
  store i1 false, i1* %t1419
  br label %ht_probe_cond_310
ht_probe_cond_310:
  %t1420 = load i64, i64* %t1414
  %t1421 = icmp slt i64 %t1420, %t1410
  br i1 %t1421, label %ht_probe_body_311, label %ht_probe_end_321
ht_probe_body_311:
  %t1422 = load i64, i64* %t1415
  %t1423 = getelementptr inbounds i8, i8* %t1409, i64 %t1422
  %t1424 = load i8, i8* %t1423
  %t1425 = icmp eq i8 %t1424, 0
  br i1 %t1425, label %ht_probe_on_empty_313, label %ht_probe_check_occ_312
ht_probe_check_occ_312:
  %t1426 = icmp eq i8 %t1424, 1
  br i1 %t1426, label %ht_probe_on_occ_316, label %ht_probe_on_tomb_318
ht_probe_on_empty_313:
  %t1427 = load i1, i1* %t1419
  br i1 %t1427, label %ht_probe_after_islot_empty_315, label %ht_probe_set_islot_empty_314
ht_probe_set_islot_empty_314:
  store i64 %t1422, i64* %t1418
  store i1 true, i1* %t1419
  br label %ht_probe_after_islot_empty_315
ht_probe_after_islot_empty_315:
  br label %ht_probe_end_321
ht_probe_on_occ_316:
  %t1428 = getelementptr inbounds i32, i32* %t1408, i64 %t1422
  %t1429 = load i32, i32* %t1428
  %t1430 = call i1 @eq_i32(i32 %t1429, i32 2)
  br i1 %t1430, label %ht_probe_on_match_317, label %ht_probe_next_320
ht_probe_on_match_317:
  store i1 true, i1* %t1416
  store i64 %t1422, i64* %t1417
  br label %ht_probe_end_321
ht_probe_on_tomb_318:
  %t1431 = load i1, i1* %t1419
  br i1 %t1431, label %ht_probe_next_320, label %ht_probe_set_islot_tomb_319
ht_probe_set_islot_tomb_319:
  store i64 %t1422, i64* %t1418
  store i1 true, i1* %t1419
  br label %ht_probe_next_320
ht_probe_next_320:
  %t1432 = add i64 %t1422, 1
  %t1433 = and i64 %t1432, %t1411
  store i64 %t1433, i64* %t1415
  %t1434 = add i64 %t1420, 1
  store i64 %t1434, i64* %t1414
  br label %ht_probe_cond_310
ht_probe_end_321:
  %t1435 = load i1, i1* %t1416
  %t1436 = load i64, i64* %t1417
  %t1437 = load i64, i64* %t1418
  %t1438 = xor i1 %t1435, true
  br i1 %t1435, label %set_insert_already_present_322, label %set_insert_do_323
set_insert_already_present_322:
  br label %set_insert_end_324
set_insert_do_323:
  %t1439 = getelementptr inbounds i8, i8* %t1409, i64 %t1437
  %t1440 = load i8, i8* %t1439
  %t1441 = icmp eq i8 %t1440, 2
  br i1 %t1441, label %set_insert_dec_tomb_325, label %set_insert_store_326
set_insert_dec_tomb_325:
  %t1442 = load i64, i64* %t1355
  %t1443 = sub i64 %t1442, 1
  store i64 %t1443, i64* %t1355
  br label %set_insert_store_326
set_insert_store_326:
  store i8 1, i8* %t1439
  %t1444 = getelementptr inbounds i32, i32* %t1408, i64 %t1437
  store i32 2, i32* %t1444
  %t1445 = load i64, i64* %t1351
  %t1446 = add i64 %t1445, 1
  store i64 %t1446, i64* %t1351
  br label %set_insert_end_324
set_insert_end_324:
  %t1447 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t1448 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t1449 = select i1 %t1438, i8* %t1447, i8* %t1448
  %t1450 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1450, i8* %t1449)
  %t1451 = getelementptr i32, i32* null, i32 1
  %t1452 = ptrtoint i32* %t1451 to i64
  %t1453 = load i8*, i8** %t1139
  %t1454 = icmp eq i8* %t1453, null
  br i1 %t1454, label %set_cow_alloc_327, label %set_cow_check_328
set_cow_alloc_327:
  %t1455 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1456 = call i8* @star_rc_alloc(i64 40, i8* %t1455)
  %t1457 = bitcast i8* %t1456 to { i32*, i8*, i64, i64, i64 }*
  %t1458 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1457, i32 0, i32 0
  store i32* null, i32** %t1458
  %t1459 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1457, i32 0, i32 1
  store i8* null, i8** %t1459
  %t1460 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1457, i32 0, i32 2
  store i64 0, i64* %t1460
  %t1461 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1457, i32 0, i32 3
  store i64 0, i64* %t1461
  %t1462 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1457, i32 0, i32 4
  store i64 0, i64* %t1462
  store i8* %t1456, i8** %t1139
  br label %set_cow_done_329
set_cow_check_328:
  %t1463 = getelementptr inbounds i8, i8* %t1453, i64 -16
  %t1464 = bitcast i8* %t1463 to i64*
  %t1465 = load atomic i64, i64* %t1464 seq_cst, align 8
  %t1466 = icmp eq i64 %t1465, 1
  br i1 %t1466, label %set_cow_done_329, label %set_cow_clone_330
set_cow_clone_330:
  %t1467 = bitcast i8* %t1453 to { i32*, i8*, i64, i64, i64 }*
  %t1468 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1467, i32 0, i32 0
  %t1469 = load i32*, i32** %t1468
  %t1470 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1467, i32 0, i32 1
  %t1471 = load i8*, i8** %t1470
  %t1472 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1467, i32 0, i32 2
  %t1473 = load i64, i64* %t1472
  %t1474 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1467, i32 0, i32 3
  %t1475 = load i64, i64* %t1474
  %t1476 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1467, i32 0, i32 4
  %t1477 = load i64, i64* %t1476
  %t1478 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1479 = call i8* @star_rc_alloc(i64 40, i8* %t1478)
  %t1480 = bitcast i8* %t1479 to { i32*, i8*, i64, i64, i64 }*
  %t1481 = mul i64 %t1475, %t1452
  %t1482 = call i8* @malloc(i64 %t1481)
  %t1483 = bitcast i8* %t1482 to i32*
  %t1484 = call i8* @malloc(i64 %t1475)
  %t1485 = icmp sgt i64 %t1475, 0
  br i1 %t1485, label %set_cow_copy_331, label %set_cow_after_copy_332
set_cow_copy_331:
  %t1486 = mul i64 %t1475, %t1452
  %t1487 = bitcast i32* %t1469 to i8*
  call i8* @memcpy(i8* %t1482, i8* %t1487, i64 %t1486)
  call i8* @memcpy(i8* %t1484, i8* %t1471, i64 %t1475)
  br label %set_cow_after_copy_332
set_cow_after_copy_332:
  %t1488 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1480, i32 0, i32 0
  store i32* %t1483, i32** %t1488
  %t1489 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1480, i32 0, i32 1
  store i8* %t1484, i8** %t1489
  %t1490 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1480, i32 0, i32 2
  store i64 %t1473, i64* %t1490
  %t1491 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1480, i32 0, i32 3
  store i64 %t1475, i64* %t1491
  %t1492 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1480, i32 0, i32 4
  store i64 %t1477, i64* %t1492
  call void @star_rc_release(i8* %t1453)
  store i8* %t1479, i8** %t1139
  br label %set_cow_done_329
set_cow_done_329:
  %t1493 = load i8*, i8** %t1139
  %t1494 = bitcast i8* %t1493 to { i32*, i8*, i64, i64, i64 }*
  %t1495 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1494, i32 0, i32 0
  %t1496 = load i32*, i32** %t1495
  %t1497 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1494, i32 0, i32 1
  %t1498 = load i8*, i8** %t1497
  %t1499 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1494, i32 0, i32 2
  %t1500 = load i64, i64* %t1499
  %t1501 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1494, i32 0, i32 3
  %t1502 = load i64, i64* %t1501
  %t1503 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1494, i32 0, i32 4
  %t1504 = load i64, i64* %t1503
  %t1505 = load i64, i64* %t1499
  %t1506 = load i64, i64* %t1501
  %t1507 = load i64, i64* %t1503
  %t1508 = add i64 %t1505, %t1507
  %t1509 = add i64 %t1508, 1
  %t1510 = mul i64 %t1509, 4
  %t1511 = mul i64 %t1506, 3
  %t1512 = icmp sgt i64 %t1510, %t1511
  br i1 %t1512, label %set_insert_grow_333, label %set_insert_after_grow_334
set_insert_grow_333:
  %t1513 = getelementptr i32, i32* null, i32 1
  %t1514 = ptrtoint i32* %t1513 to i64
  %t1515 = mul i64 %t1506, 2
  %t1516 = icmp sgt i64 %t1515, 0
  %t1517 = select i1 %t1516, i64 %t1515, i64 8
  %t1518 = sub i64 %t1517, 1
  %t1519 = mul i64 %t1517, %t1514
  %t1520 = call i8* @malloc(i64 %t1519)
  %t1521 = bitcast i8* %t1520 to i32*
  %t1522 = call i8* @malloc(i64 %t1517)
  store i64 0, i64* %t1523
  br label %ht_fill8_cond_335
ht_fill8_cond_335:
  %t1524 = load i64, i64* %t1523
  %t1525 = icmp slt i64 %t1524, %t1517
  br i1 %t1525, label %ht_fill8_body_336, label %ht_fill8_end_337
ht_fill8_body_336:
  %t1526 = getelementptr inbounds i8, i8* %t1522, i64 %t1524
  store i8 0, i8* %t1526
  %t1527 = add i64 %t1524, 1
  store i64 %t1527, i64* %t1523
  br label %ht_fill8_cond_335
ht_fill8_end_337:
  %t1528 = load i32*, i32** %t1495
  %t1529 = load i8*, i8** %t1497
  store i64 0, i64* %t1530
  br label %set_grow_cond_338
set_grow_cond_338:
  %t1531 = load i64, i64* %t1530
  %t1532 = icmp slt i64 %t1531, %t1506
  br i1 %t1532, label %set_grow_body_339, label %set_grow_end_342
set_grow_body_339:
  %t1533 = getelementptr inbounds i8, i8* %t1529, i64 %t1531
  %t1534 = load i8, i8* %t1533
  %t1535 = icmp eq i8 %t1534, 1
  br i1 %t1535, label %set_grow_occ_340, label %set_grow_next_341
set_grow_occ_340:
  %t1536 = getelementptr inbounds i32, i32* %t1528, i64 %t1531
  %t1537 = load i32, i32* %t1536
  %t1538 = call i64 @hash_i32(i32 %t1537)
  %t1539 = and i64 %t1538, %t1518
  store i64 0, i64* %t1540
  store i64 %t1539, i64* %t1541
  br label %ht_fe_cond_343
ht_fe_cond_343:
  %t1542 = load i64, i64* %t1540
  %t1543 = icmp slt i64 %t1542, %t1517
  br i1 %t1543, label %ht_fe_body_344, label %ht_fe_end_346
ht_fe_body_344:
  %t1544 = load i64, i64* %t1541
  %t1545 = getelementptr inbounds i8, i8* %t1522, i64 %t1544
  %t1546 = load i8, i8* %t1545
  %t1547 = icmp eq i8 %t1546, 0
  br i1 %t1547, label %ht_fe_end_346, label %ht_fe_next_345
ht_fe_next_345:
  %t1548 = add i64 %t1544, 1
  %t1549 = and i64 %t1548, %t1518
  store i64 %t1549, i64* %t1541
  %t1550 = add i64 %t1542, 1
  store i64 %t1550, i64* %t1540
  br label %ht_fe_cond_343
ht_fe_end_346:
  %t1551 = load i64, i64* %t1541
  %t1552 = getelementptr inbounds i8, i8* %t1522, i64 %t1551
  store i8 1, i8* %t1552
  %t1553 = getelementptr inbounds i32, i32* %t1521, i64 %t1551
  store i32 %t1537, i32* %t1553
  br label %set_grow_next_341
set_grow_next_341:
  %t1554 = add i64 %t1531, 1
  store i64 %t1554, i64* %t1530
  br label %set_grow_cond_338
set_grow_end_342:
  %t1555 = bitcast i32* %t1528 to i8*
  call void @free(i8* %t1555)
  call void @free(i8* %t1529)
  store i32* %t1521, i32** %t1495
  store i8* %t1522, i8** %t1497
  store i64 %t1517, i64* %t1501
  store i64 0, i64* %t1503
  br label %set_insert_after_grow_334
set_insert_after_grow_334:
  %t1556 = load i32*, i32** %t1495
  %t1557 = load i8*, i8** %t1497
  %t1558 = load i64, i64* %t1501
  %t1559 = sub i64 %t1558, 1
  %t1560 = call i64 @hash_i32(i32 1)
  %t1561 = and i64 %t1560, %t1559
  store i64 0, i64* %t1562
  store i64 %t1561, i64* %t1563
  store i1 false, i1* %t1564
  store i64 -1, i64* %t1565
  store i64 -1, i64* %t1566
  store i1 false, i1* %t1567
  br label %ht_probe_cond_347
ht_probe_cond_347:
  %t1568 = load i64, i64* %t1562
  %t1569 = icmp slt i64 %t1568, %t1558
  br i1 %t1569, label %ht_probe_body_348, label %ht_probe_end_358
ht_probe_body_348:
  %t1570 = load i64, i64* %t1563
  %t1571 = getelementptr inbounds i8, i8* %t1557, i64 %t1570
  %t1572 = load i8, i8* %t1571
  %t1573 = icmp eq i8 %t1572, 0
  br i1 %t1573, label %ht_probe_on_empty_350, label %ht_probe_check_occ_349
ht_probe_check_occ_349:
  %t1574 = icmp eq i8 %t1572, 1
  br i1 %t1574, label %ht_probe_on_occ_353, label %ht_probe_on_tomb_355
ht_probe_on_empty_350:
  %t1575 = load i1, i1* %t1567
  br i1 %t1575, label %ht_probe_after_islot_empty_352, label %ht_probe_set_islot_empty_351
ht_probe_set_islot_empty_351:
  store i64 %t1570, i64* %t1566
  store i1 true, i1* %t1567
  br label %ht_probe_after_islot_empty_352
ht_probe_after_islot_empty_352:
  br label %ht_probe_end_358
ht_probe_on_occ_353:
  %t1576 = getelementptr inbounds i32, i32* %t1556, i64 %t1570
  %t1577 = load i32, i32* %t1576
  %t1578 = call i1 @eq_i32(i32 %t1577, i32 1)
  br i1 %t1578, label %ht_probe_on_match_354, label %ht_probe_next_357
ht_probe_on_match_354:
  store i1 true, i1* %t1564
  store i64 %t1570, i64* %t1565
  br label %ht_probe_end_358
ht_probe_on_tomb_355:
  %t1579 = load i1, i1* %t1567
  br i1 %t1579, label %ht_probe_next_357, label %ht_probe_set_islot_tomb_356
ht_probe_set_islot_tomb_356:
  store i64 %t1570, i64* %t1566
  store i1 true, i1* %t1567
  br label %ht_probe_next_357
ht_probe_next_357:
  %t1580 = add i64 %t1570, 1
  %t1581 = and i64 %t1580, %t1559
  store i64 %t1581, i64* %t1563
  %t1582 = add i64 %t1568, 1
  store i64 %t1582, i64* %t1562
  br label %ht_probe_cond_347
ht_probe_end_358:
  %t1583 = load i1, i1* %t1564
  %t1584 = load i64, i64* %t1565
  %t1585 = load i64, i64* %t1566
  %t1586 = xor i1 %t1583, true
  br i1 %t1583, label %set_insert_already_present_359, label %set_insert_do_360
set_insert_already_present_359:
  br label %set_insert_end_361
set_insert_do_360:
  %t1587 = getelementptr inbounds i8, i8* %t1557, i64 %t1585
  %t1588 = load i8, i8* %t1587
  %t1589 = icmp eq i8 %t1588, 2
  br i1 %t1589, label %set_insert_dec_tomb_362, label %set_insert_store_363
set_insert_dec_tomb_362:
  %t1590 = load i64, i64* %t1503
  %t1591 = sub i64 %t1590, 1
  store i64 %t1591, i64* %t1503
  br label %set_insert_store_363
set_insert_store_363:
  store i8 1, i8* %t1587
  %t1592 = getelementptr inbounds i32, i32* %t1556, i64 %t1585
  store i32 1, i32* %t1592
  %t1593 = load i64, i64* %t1499
  %t1594 = add i64 %t1593, 1
  store i64 %t1594, i64* %t1499
  br label %set_insert_end_361
set_insert_end_361:
  %t1595 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.35, i64 0, i64 0
  %t1596 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.36, i64 0, i64 0
  %t1597 = select i1 %t1586, i8* %t1595, i8* %t1596
  %t1598 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.37, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1598, i8* %t1597)
  %t1599 = load i8*, i8** %t1139
  %t1600 = icmp eq i8* %t1599, null
  br i1 %t1600, label %set_read_null_364, label %set_read_real_365
set_read_null_364:
  br label %set_read_end_366
set_read_real_365:
  %t1601 = bitcast i8* %t1599 to { i32*, i8*, i64, i64, i64 }*
  %t1602 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1601, i32 0, i32 0
  %t1603 = load i32*, i32** %t1602
  %t1604 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1601, i32 0, i32 1
  %t1605 = load i8*, i8** %t1604
  %t1606 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1601, i32 0, i32 2
  %t1607 = load i64, i64* %t1606
  %t1608 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1601, i32 0, i32 3
  %t1609 = load i64, i64* %t1608
  br label %set_read_end_366
set_read_end_366:
  %t1610 = phi i32* [ null, %set_read_null_364 ], [ %t1603, %set_read_real_365 ]
  %t1611 = phi i8* [ null, %set_read_null_364 ], [ %t1605, %set_read_real_365 ]
  %t1612 = phi i64 [ 0, %set_read_null_364 ], [ %t1607, %set_read_real_365 ]
  %t1613 = phi i64 [ 0, %set_read_null_364 ], [ %t1609, %set_read_real_365 ]
  %t1614 = trunc i64 %t1612 to i32
  %t1615 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.38, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1615, i32 %t1614)
  %t1616 = load i8*, i8** %t1139
  %t1617 = icmp eq i8* %t1616, null
  br i1 %t1617, label %set_read_null_367, label %set_read_real_368
set_read_null_367:
  br label %set_read_end_369
set_read_real_368:
  %t1618 = bitcast i8* %t1616 to { i32*, i8*, i64, i64, i64 }*
  %t1619 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1618, i32 0, i32 0
  %t1620 = load i32*, i32** %t1619
  %t1621 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1618, i32 0, i32 1
  %t1622 = load i8*, i8** %t1621
  %t1623 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1618, i32 0, i32 2
  %t1624 = load i64, i64* %t1623
  %t1625 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1618, i32 0, i32 3
  %t1626 = load i64, i64* %t1625
  br label %set_read_end_369
set_read_end_369:
  %t1627 = phi i32* [ null, %set_read_null_367 ], [ %t1620, %set_read_real_368 ]
  %t1628 = phi i8* [ null, %set_read_null_367 ], [ %t1622, %set_read_real_368 ]
  %t1629 = phi i64 [ 0, %set_read_null_367 ], [ %t1624, %set_read_real_368 ]
  %t1630 = phi i64 [ 0, %set_read_null_367 ], [ %t1626, %set_read_real_368 ]
  %t1631 = sub i64 %t1630, 1
  %t1632 = call i64 @hash_i32(i32 2)
  %t1633 = and i64 %t1632, %t1631
  store i64 0, i64* %t1634
  store i64 %t1633, i64* %t1635
  store i1 false, i1* %t1636
  store i64 -1, i64* %t1637
  store i64 -1, i64* %t1638
  store i1 false, i1* %t1639
  br label %ht_probe_cond_370
ht_probe_cond_370:
  %t1640 = load i64, i64* %t1634
  %t1641 = icmp slt i64 %t1640, %t1630
  br i1 %t1641, label %ht_probe_body_371, label %ht_probe_end_381
ht_probe_body_371:
  %t1642 = load i64, i64* %t1635
  %t1643 = getelementptr inbounds i8, i8* %t1628, i64 %t1642
  %t1644 = load i8, i8* %t1643
  %t1645 = icmp eq i8 %t1644, 0
  br i1 %t1645, label %ht_probe_on_empty_373, label %ht_probe_check_occ_372
ht_probe_check_occ_372:
  %t1646 = icmp eq i8 %t1644, 1
  br i1 %t1646, label %ht_probe_on_occ_376, label %ht_probe_on_tomb_378
ht_probe_on_empty_373:
  %t1647 = load i1, i1* %t1639
  br i1 %t1647, label %ht_probe_after_islot_empty_375, label %ht_probe_set_islot_empty_374
ht_probe_set_islot_empty_374:
  store i64 %t1642, i64* %t1638
  store i1 true, i1* %t1639
  br label %ht_probe_after_islot_empty_375
ht_probe_after_islot_empty_375:
  br label %ht_probe_end_381
ht_probe_on_occ_376:
  %t1648 = getelementptr inbounds i32, i32* %t1627, i64 %t1642
  %t1649 = load i32, i32* %t1648
  %t1650 = call i1 @eq_i32(i32 %t1649, i32 2)
  br i1 %t1650, label %ht_probe_on_match_377, label %ht_probe_next_380
ht_probe_on_match_377:
  store i1 true, i1* %t1636
  store i64 %t1642, i64* %t1637
  br label %ht_probe_end_381
ht_probe_on_tomb_378:
  %t1651 = load i1, i1* %t1639
  br i1 %t1651, label %ht_probe_next_380, label %ht_probe_set_islot_tomb_379
ht_probe_set_islot_tomb_379:
  store i64 %t1642, i64* %t1638
  store i1 true, i1* %t1639
  br label %ht_probe_next_380
ht_probe_next_380:
  %t1652 = add i64 %t1642, 1
  %t1653 = and i64 %t1652, %t1631
  store i64 %t1653, i64* %t1635
  %t1654 = add i64 %t1640, 1
  store i64 %t1654, i64* %t1634
  br label %ht_probe_cond_370
ht_probe_end_381:
  %t1655 = load i1, i1* %t1636
  %t1656 = load i64, i64* %t1637
  %t1657 = load i64, i64* %t1638
  %t1658 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.39, i64 0, i64 0
  %t1659 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.40, i64 0, i64 0
  %t1660 = select i1 %t1655, i8* %t1658, i8* %t1659
  %t1661 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.41, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1661, i8* %t1660)
  %t1662 = getelementptr i32, i32* null, i32 1
  %t1663 = ptrtoint i32* %t1662 to i64
  %t1664 = load i8*, i8** %t1139
  %t1665 = icmp eq i8* %t1664, null
  br i1 %t1665, label %set_cow_alloc_382, label %set_cow_check_383
set_cow_alloc_382:
  %t1666 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1667 = call i8* @star_rc_alloc(i64 40, i8* %t1666)
  %t1668 = bitcast i8* %t1667 to { i32*, i8*, i64, i64, i64 }*
  %t1669 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1668, i32 0, i32 0
  store i32* null, i32** %t1669
  %t1670 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1668, i32 0, i32 1
  store i8* null, i8** %t1670
  %t1671 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1668, i32 0, i32 2
  store i64 0, i64* %t1671
  %t1672 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1668, i32 0, i32 3
  store i64 0, i64* %t1672
  %t1673 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1668, i32 0, i32 4
  store i64 0, i64* %t1673
  store i8* %t1667, i8** %t1139
  br label %set_cow_done_384
set_cow_check_383:
  %t1674 = getelementptr inbounds i8, i8* %t1664, i64 -16
  %t1675 = bitcast i8* %t1674 to i64*
  %t1676 = load atomic i64, i64* %t1675 seq_cst, align 8
  %t1677 = icmp eq i64 %t1676, 1
  br i1 %t1677, label %set_cow_done_384, label %set_cow_clone_385
set_cow_clone_385:
  %t1678 = bitcast i8* %t1664 to { i32*, i8*, i64, i64, i64 }*
  %t1679 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1678, i32 0, i32 0
  %t1680 = load i32*, i32** %t1679
  %t1681 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1678, i32 0, i32 1
  %t1682 = load i8*, i8** %t1681
  %t1683 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1678, i32 0, i32 2
  %t1684 = load i64, i64* %t1683
  %t1685 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1678, i32 0, i32 3
  %t1686 = load i64, i64* %t1685
  %t1687 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1678, i32 0, i32 4
  %t1688 = load i64, i64* %t1687
  %t1689 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1690 = call i8* @star_rc_alloc(i64 40, i8* %t1689)
  %t1691 = bitcast i8* %t1690 to { i32*, i8*, i64, i64, i64 }*
  %t1692 = mul i64 %t1686, %t1663
  %t1693 = call i8* @malloc(i64 %t1692)
  %t1694 = bitcast i8* %t1693 to i32*
  %t1695 = call i8* @malloc(i64 %t1686)
  %t1696 = icmp sgt i64 %t1686, 0
  br i1 %t1696, label %set_cow_copy_386, label %set_cow_after_copy_387
set_cow_copy_386:
  %t1697 = mul i64 %t1686, %t1663
  %t1698 = bitcast i32* %t1680 to i8*
  call i8* @memcpy(i8* %t1693, i8* %t1698, i64 %t1697)
  call i8* @memcpy(i8* %t1695, i8* %t1682, i64 %t1686)
  br label %set_cow_after_copy_387
set_cow_after_copy_387:
  %t1699 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1691, i32 0, i32 0
  store i32* %t1694, i32** %t1699
  %t1700 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1691, i32 0, i32 1
  store i8* %t1695, i8** %t1700
  %t1701 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1691, i32 0, i32 2
  store i64 %t1684, i64* %t1701
  %t1702 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1691, i32 0, i32 3
  store i64 %t1686, i64* %t1702
  %t1703 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1691, i32 0, i32 4
  store i64 %t1688, i64* %t1703
  call void @star_rc_release(i8* %t1664)
  store i8* %t1690, i8** %t1139
  br label %set_cow_done_384
set_cow_done_384:
  %t1704 = load i8*, i8** %t1139
  %t1705 = bitcast i8* %t1704 to { i32*, i8*, i64, i64, i64 }*
  %t1706 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1705, i32 0, i32 0
  %t1707 = load i32*, i32** %t1706
  %t1708 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1705, i32 0, i32 1
  %t1709 = load i8*, i8** %t1708
  %t1710 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1705, i32 0, i32 2
  %t1711 = load i64, i64* %t1710
  %t1712 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1705, i32 0, i32 3
  %t1713 = load i64, i64* %t1712
  %t1714 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1705, i32 0, i32 4
  %t1715 = load i64, i64* %t1714
  %t1716 = load i32*, i32** %t1706
  %t1717 = load i8*, i8** %t1708
  %t1718 = load i64, i64* %t1712
  %t1719 = sub i64 %t1718, 1
  %t1720 = call i64 @hash_i32(i32 2)
  %t1721 = and i64 %t1720, %t1719
  store i64 0, i64* %t1722
  store i64 %t1721, i64* %t1723
  store i1 false, i1* %t1724
  store i64 -1, i64* %t1725
  store i64 -1, i64* %t1726
  store i1 false, i1* %t1727
  br label %ht_probe_cond_388
ht_probe_cond_388:
  %t1728 = load i64, i64* %t1722
  %t1729 = icmp slt i64 %t1728, %t1718
  br i1 %t1729, label %ht_probe_body_389, label %ht_probe_end_399
ht_probe_body_389:
  %t1730 = load i64, i64* %t1723
  %t1731 = getelementptr inbounds i8, i8* %t1717, i64 %t1730
  %t1732 = load i8, i8* %t1731
  %t1733 = icmp eq i8 %t1732, 0
  br i1 %t1733, label %ht_probe_on_empty_391, label %ht_probe_check_occ_390
ht_probe_check_occ_390:
  %t1734 = icmp eq i8 %t1732, 1
  br i1 %t1734, label %ht_probe_on_occ_394, label %ht_probe_on_tomb_396
ht_probe_on_empty_391:
  %t1735 = load i1, i1* %t1727
  br i1 %t1735, label %ht_probe_after_islot_empty_393, label %ht_probe_set_islot_empty_392
ht_probe_set_islot_empty_392:
  store i64 %t1730, i64* %t1726
  store i1 true, i1* %t1727
  br label %ht_probe_after_islot_empty_393
ht_probe_after_islot_empty_393:
  br label %ht_probe_end_399
ht_probe_on_occ_394:
  %t1736 = getelementptr inbounds i32, i32* %t1716, i64 %t1730
  %t1737 = load i32, i32* %t1736
  %t1738 = call i1 @eq_i32(i32 %t1737, i32 2)
  br i1 %t1738, label %ht_probe_on_match_395, label %ht_probe_next_398
ht_probe_on_match_395:
  store i1 true, i1* %t1724
  store i64 %t1730, i64* %t1725
  br label %ht_probe_end_399
ht_probe_on_tomb_396:
  %t1739 = load i1, i1* %t1727
  br i1 %t1739, label %ht_probe_next_398, label %ht_probe_set_islot_tomb_397
ht_probe_set_islot_tomb_397:
  store i64 %t1730, i64* %t1726
  store i1 true, i1* %t1727
  br label %ht_probe_next_398
ht_probe_next_398:
  %t1740 = add i64 %t1730, 1
  %t1741 = and i64 %t1740, %t1719
  store i64 %t1741, i64* %t1723
  %t1742 = add i64 %t1728, 1
  store i64 %t1742, i64* %t1722
  br label %ht_probe_cond_388
ht_probe_end_399:
  %t1743 = load i1, i1* %t1724
  %t1744 = load i64, i64* %t1725
  %t1745 = load i64, i64* %t1726
  br i1 %t1743, label %set_remove_do_400, label %set_remove_end_401
set_remove_do_400:
  %t1746 = getelementptr inbounds i32, i32* %t1716, i64 %t1744
  %t1747 = getelementptr inbounds i8, i8* %t1717, i64 %t1744
  store i8 2, i8* %t1747
  %t1748 = load i64, i64* %t1710
  %t1749 = sub i64 %t1748, 1
  store i64 %t1749, i64* %t1710
  %t1750 = load i64, i64* %t1714
  %t1751 = add i64 %t1750, 1
  store i64 %t1751, i64* %t1714
  br label %set_remove_end_401
set_remove_end_401:
  %t1752 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.42, i64 0, i64 0
  %t1753 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.43, i64 0, i64 0
  %t1754 = select i1 %t1743, i8* %t1752, i8* %t1753
  %t1755 = getelementptr inbounds [14 x i8], [14 x i8]* @.str.44, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1755, i8* %t1754)
  %t1756 = load i8*, i8** %t1139
  %t1757 = icmp eq i8* %t1756, null
  br i1 %t1757, label %set_read_null_402, label %set_read_real_403
set_read_null_402:
  br label %set_read_end_404
set_read_real_403:
  %t1758 = bitcast i8* %t1756 to { i32*, i8*, i64, i64, i64 }*
  %t1759 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1758, i32 0, i32 0
  %t1760 = load i32*, i32** %t1759
  %t1761 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1758, i32 0, i32 1
  %t1762 = load i8*, i8** %t1761
  %t1763 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1758, i32 0, i32 2
  %t1764 = load i64, i64* %t1763
  %t1765 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1758, i32 0, i32 3
  %t1766 = load i64, i64* %t1765
  br label %set_read_end_404
set_read_end_404:
  %t1767 = phi i32* [ null, %set_read_null_402 ], [ %t1760, %set_read_real_403 ]
  %t1768 = phi i8* [ null, %set_read_null_402 ], [ %t1762, %set_read_real_403 ]
  %t1769 = phi i64 [ 0, %set_read_null_402 ], [ %t1764, %set_read_real_403 ]
  %t1770 = phi i64 [ 0, %set_read_null_402 ], [ %t1766, %set_read_real_403 ]
  %t1771 = sub i64 %t1770, 1
  %t1772 = call i64 @hash_i32(i32 2)
  %t1773 = and i64 %t1772, %t1771
  store i64 0, i64* %t1774
  store i64 %t1773, i64* %t1775
  store i1 false, i1* %t1776
  store i64 -1, i64* %t1777
  store i64 -1, i64* %t1778
  store i1 false, i1* %t1779
  br label %ht_probe_cond_405
ht_probe_cond_405:
  %t1780 = load i64, i64* %t1774
  %t1781 = icmp slt i64 %t1780, %t1770
  br i1 %t1781, label %ht_probe_body_406, label %ht_probe_end_416
ht_probe_body_406:
  %t1782 = load i64, i64* %t1775
  %t1783 = getelementptr inbounds i8, i8* %t1768, i64 %t1782
  %t1784 = load i8, i8* %t1783
  %t1785 = icmp eq i8 %t1784, 0
  br i1 %t1785, label %ht_probe_on_empty_408, label %ht_probe_check_occ_407
ht_probe_check_occ_407:
  %t1786 = icmp eq i8 %t1784, 1
  br i1 %t1786, label %ht_probe_on_occ_411, label %ht_probe_on_tomb_413
ht_probe_on_empty_408:
  %t1787 = load i1, i1* %t1779
  br i1 %t1787, label %ht_probe_after_islot_empty_410, label %ht_probe_set_islot_empty_409
ht_probe_set_islot_empty_409:
  store i64 %t1782, i64* %t1778
  store i1 true, i1* %t1779
  br label %ht_probe_after_islot_empty_410
ht_probe_after_islot_empty_410:
  br label %ht_probe_end_416
ht_probe_on_occ_411:
  %t1788 = getelementptr inbounds i32, i32* %t1767, i64 %t1782
  %t1789 = load i32, i32* %t1788
  %t1790 = call i1 @eq_i32(i32 %t1789, i32 2)
  br i1 %t1790, label %ht_probe_on_match_412, label %ht_probe_next_415
ht_probe_on_match_412:
  store i1 true, i1* %t1776
  store i64 %t1782, i64* %t1777
  br label %ht_probe_end_416
ht_probe_on_tomb_413:
  %t1791 = load i1, i1* %t1779
  br i1 %t1791, label %ht_probe_next_415, label %ht_probe_set_islot_tomb_414
ht_probe_set_islot_tomb_414:
  store i64 %t1782, i64* %t1778
  store i1 true, i1* %t1779
  br label %ht_probe_next_415
ht_probe_next_415:
  %t1792 = add i64 %t1782, 1
  %t1793 = and i64 %t1792, %t1771
  store i64 %t1793, i64* %t1775
  %t1794 = add i64 %t1780, 1
  store i64 %t1794, i64* %t1774
  br label %ht_probe_cond_405
ht_probe_end_416:
  %t1795 = load i1, i1* %t1776
  %t1796 = load i64, i64* %t1777
  %t1797 = load i64, i64* %t1778
  %t1798 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.45, i64 0, i64 0
  %t1799 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.46, i64 0, i64 0
  %t1800 = select i1 %t1795, i8* %t1798, i8* %t1799
  %t1801 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.47, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1801, i8* %t1800)
  %t1802 = getelementptr i32, i32* null, i32 1
  %t1803 = ptrtoint i32* %t1802 to i64
  %t1804 = load i8*, i8** %t1139
  %t1805 = icmp eq i8* %t1804, null
  br i1 %t1805, label %set_cow_alloc_417, label %set_cow_check_418
set_cow_alloc_417:
  %t1806 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1807 = call i8* @star_rc_alloc(i64 40, i8* %t1806)
  %t1808 = bitcast i8* %t1807 to { i32*, i8*, i64, i64, i64 }*
  %t1809 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1808, i32 0, i32 0
  store i32* null, i32** %t1809
  %t1810 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1808, i32 0, i32 1
  store i8* null, i8** %t1810
  %t1811 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1808, i32 0, i32 2
  store i64 0, i64* %t1811
  %t1812 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1808, i32 0, i32 3
  store i64 0, i64* %t1812
  %t1813 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1808, i32 0, i32 4
  store i64 0, i64* %t1813
  store i8* %t1807, i8** %t1139
  br label %set_cow_done_419
set_cow_check_418:
  %t1814 = getelementptr inbounds i8, i8* %t1804, i64 -16
  %t1815 = bitcast i8* %t1814 to i64*
  %t1816 = load atomic i64, i64* %t1815 seq_cst, align 8
  %t1817 = icmp eq i64 %t1816, 1
  br i1 %t1817, label %set_cow_done_419, label %set_cow_clone_420
set_cow_clone_420:
  %t1818 = bitcast i8* %t1804 to { i32*, i8*, i64, i64, i64 }*
  %t1819 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1818, i32 0, i32 0
  %t1820 = load i32*, i32** %t1819
  %t1821 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1818, i32 0, i32 1
  %t1822 = load i8*, i8** %t1821
  %t1823 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1818, i32 0, i32 2
  %t1824 = load i64, i64* %t1823
  %t1825 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1818, i32 0, i32 3
  %t1826 = load i64, i64* %t1825
  %t1827 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1818, i32 0, i32 4
  %t1828 = load i64, i64* %t1827
  %t1829 = bitcast void (i8*)* @set_release_i32 to i8*
  %t1830 = call i8* @star_rc_alloc(i64 40, i8* %t1829)
  %t1831 = bitcast i8* %t1830 to { i32*, i8*, i64, i64, i64 }*
  %t1832 = mul i64 %t1826, %t1803
  %t1833 = call i8* @malloc(i64 %t1832)
  %t1834 = bitcast i8* %t1833 to i32*
  %t1835 = call i8* @malloc(i64 %t1826)
  %t1836 = icmp sgt i64 %t1826, 0
  br i1 %t1836, label %set_cow_copy_421, label %set_cow_after_copy_422
set_cow_copy_421:
  %t1837 = mul i64 %t1826, %t1803
  %t1838 = bitcast i32* %t1820 to i8*
  call i8* @memcpy(i8* %t1833, i8* %t1838, i64 %t1837)
  call i8* @memcpy(i8* %t1835, i8* %t1822, i64 %t1826)
  br label %set_cow_after_copy_422
set_cow_after_copy_422:
  %t1839 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1831, i32 0, i32 0
  store i32* %t1834, i32** %t1839
  %t1840 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1831, i32 0, i32 1
  store i8* %t1835, i8** %t1840
  %t1841 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1831, i32 0, i32 2
  store i64 %t1824, i64* %t1841
  %t1842 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1831, i32 0, i32 3
  store i64 %t1826, i64* %t1842
  %t1843 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1831, i32 0, i32 4
  store i64 %t1828, i64* %t1843
  call void @star_rc_release(i8* %t1804)
  store i8* %t1830, i8** %t1139
  br label %set_cow_done_419
set_cow_done_419:
  %t1844 = load i8*, i8** %t1139
  %t1845 = bitcast i8* %t1844 to { i32*, i8*, i64, i64, i64 }*
  %t1846 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1845, i32 0, i32 0
  %t1847 = load i32*, i32** %t1846
  %t1848 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1845, i32 0, i32 1
  %t1849 = load i8*, i8** %t1848
  %t1850 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1845, i32 0, i32 2
  %t1851 = load i64, i64* %t1850
  %t1852 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1845, i32 0, i32 3
  %t1853 = load i64, i64* %t1852
  %t1854 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1845, i32 0, i32 4
  %t1855 = load i64, i64* %t1854
  %t1856 = load i32*, i32** %t1846
  %t1857 = load i8*, i8** %t1848
  %t1858 = load i64, i64* %t1852
  %t1859 = sub i64 %t1858, 1
  %t1860 = call i64 @hash_i32(i32 2)
  %t1861 = and i64 %t1860, %t1859
  store i64 0, i64* %t1862
  store i64 %t1861, i64* %t1863
  store i1 false, i1* %t1864
  store i64 -1, i64* %t1865
  store i64 -1, i64* %t1866
  store i1 false, i1* %t1867
  br label %ht_probe_cond_423
ht_probe_cond_423:
  %t1868 = load i64, i64* %t1862
  %t1869 = icmp slt i64 %t1868, %t1858
  br i1 %t1869, label %ht_probe_body_424, label %ht_probe_end_434
ht_probe_body_424:
  %t1870 = load i64, i64* %t1863
  %t1871 = getelementptr inbounds i8, i8* %t1857, i64 %t1870
  %t1872 = load i8, i8* %t1871
  %t1873 = icmp eq i8 %t1872, 0
  br i1 %t1873, label %ht_probe_on_empty_426, label %ht_probe_check_occ_425
ht_probe_check_occ_425:
  %t1874 = icmp eq i8 %t1872, 1
  br i1 %t1874, label %ht_probe_on_occ_429, label %ht_probe_on_tomb_431
ht_probe_on_empty_426:
  %t1875 = load i1, i1* %t1867
  br i1 %t1875, label %ht_probe_after_islot_empty_428, label %ht_probe_set_islot_empty_427
ht_probe_set_islot_empty_427:
  store i64 %t1870, i64* %t1866
  store i1 true, i1* %t1867
  br label %ht_probe_after_islot_empty_428
ht_probe_after_islot_empty_428:
  br label %ht_probe_end_434
ht_probe_on_occ_429:
  %t1876 = getelementptr inbounds i32, i32* %t1856, i64 %t1870
  %t1877 = load i32, i32* %t1876
  %t1878 = call i1 @eq_i32(i32 %t1877, i32 2)
  br i1 %t1878, label %ht_probe_on_match_430, label %ht_probe_next_433
ht_probe_on_match_430:
  store i1 true, i1* %t1864
  store i64 %t1870, i64* %t1865
  br label %ht_probe_end_434
ht_probe_on_tomb_431:
  %t1879 = load i1, i1* %t1867
  br i1 %t1879, label %ht_probe_next_433, label %ht_probe_set_islot_tomb_432
ht_probe_set_islot_tomb_432:
  store i64 %t1870, i64* %t1866
  store i1 true, i1* %t1867
  br label %ht_probe_next_433
ht_probe_next_433:
  %t1880 = add i64 %t1870, 1
  %t1881 = and i64 %t1880, %t1859
  store i64 %t1881, i64* %t1863
  %t1882 = add i64 %t1868, 1
  store i64 %t1882, i64* %t1862
  br label %ht_probe_cond_423
ht_probe_end_434:
  %t1883 = load i1, i1* %t1864
  %t1884 = load i64, i64* %t1865
  %t1885 = load i64, i64* %t1866
  br i1 %t1883, label %set_remove_do_435, label %set_remove_end_436
set_remove_do_435:
  %t1886 = getelementptr inbounds i32, i32* %t1856, i64 %t1884
  %t1887 = getelementptr inbounds i8, i8* %t1857, i64 %t1884
  store i8 2, i8* %t1887
  %t1888 = load i64, i64* %t1850
  %t1889 = sub i64 %t1888, 1
  store i64 %t1889, i64* %t1850
  %t1890 = load i64, i64* %t1854
  %t1891 = add i64 %t1890, 1
  store i64 %t1891, i64* %t1854
  br label %set_remove_end_436
set_remove_end_436:
  %t1892 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.48, i64 0, i64 0
  %t1893 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.49, i64 0, i64 0
  %t1894 = select i1 %t1883, i8* %t1892, i8* %t1893
  %t1895 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.50, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1895, i8* %t1894)
  %t1896 = load i8*, i8** %t1139
  %t1897 = icmp eq i8* %t1896, null
  br i1 %t1897, label %set_read_null_437, label %set_read_real_438
set_read_null_437:
  br label %set_read_end_439
set_read_real_438:
  %t1898 = bitcast i8* %t1896 to { i32*, i8*, i64, i64, i64 }*
  %t1899 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1898, i32 0, i32 0
  %t1900 = load i32*, i32** %t1899
  %t1901 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1898, i32 0, i32 1
  %t1902 = load i8*, i8** %t1901
  %t1903 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1898, i32 0, i32 2
  %t1904 = load i64, i64* %t1903
  %t1905 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1898, i32 0, i32 3
  %t1906 = load i64, i64* %t1905
  br label %set_read_end_439
set_read_end_439:
  %t1907 = phi i32* [ null, %set_read_null_437 ], [ %t1900, %set_read_real_438 ]
  %t1908 = phi i8* [ null, %set_read_null_437 ], [ %t1902, %set_read_real_438 ]
  %t1909 = phi i64 [ 0, %set_read_null_437 ], [ %t1904, %set_read_real_438 ]
  %t1910 = phi i64 [ 0, %set_read_null_437 ], [ %t1906, %set_read_real_438 ]
  %t1911 = trunc i64 %t1909 to i32
  %t1912 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.51, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1912, i32 %t1911)
  store i8* null, i8** %t1913
  %t1914 = getelementptr %Point, %Point* null, i32 1
  %t1915 = ptrtoint %Point* %t1914 to i64
  %t1916 = load i8*, i8** %t1913
  %t1917 = icmp eq i8* %t1916, null
  br i1 %t1917, label %set_cow_alloc_440, label %set_cow_check_441
set_cow_alloc_440:
  %t1926 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1927 = call i8* @star_rc_alloc(i64 40, i8* %t1926)
  %t1928 = bitcast i8* %t1927 to { %Point*, i8*, i64, i64, i64 }*
  %t1929 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1928, i32 0, i32 0
  store %Point* null, %Point** %t1929
  %t1930 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1928, i32 0, i32 1
  store i8* null, i8** %t1930
  %t1931 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1928, i32 0, i32 2
  store i64 0, i64* %t1931
  %t1932 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1928, i32 0, i32 3
  store i64 0, i64* %t1932
  %t1933 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1928, i32 0, i32 4
  store i64 0, i64* %t1933
  store i8* %t1927, i8** %t1913
  br label %set_cow_done_442
set_cow_check_441:
  %t1934 = getelementptr inbounds i8, i8* %t1916, i64 -16
  %t1935 = bitcast i8* %t1934 to i64*
  %t1936 = load atomic i64, i64* %t1935 seq_cst, align 8
  %t1937 = icmp eq i64 %t1936, 1
  br i1 %t1937, label %set_cow_done_442, label %set_cow_clone_443
set_cow_clone_443:
  %t1938 = bitcast i8* %t1916 to { %Point*, i8*, i64, i64, i64 }*
  %t1939 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1938, i32 0, i32 0
  %t1940 = load %Point*, %Point** %t1939
  %t1941 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1938, i32 0, i32 1
  %t1942 = load i8*, i8** %t1941
  %t1943 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1938, i32 0, i32 2
  %t1944 = load i64, i64* %t1943
  %t1945 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1938, i32 0, i32 3
  %t1946 = load i64, i64* %t1945
  %t1947 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1938, i32 0, i32 4
  %t1948 = load i64, i64* %t1947
  %t1949 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t1950 = call i8* @star_rc_alloc(i64 40, i8* %t1949)
  %t1951 = bitcast i8* %t1950 to { %Point*, i8*, i64, i64, i64 }*
  %t1952 = mul i64 %t1946, %t1915
  %t1953 = call i8* @malloc(i64 %t1952)
  %t1954 = bitcast i8* %t1953 to %Point*
  %t1955 = call i8* @malloc(i64 %t1946)
  %t1956 = icmp sgt i64 %t1946, 0
  br i1 %t1956, label %set_cow_copy_444, label %set_cow_after_copy_445
set_cow_copy_444:
  %t1957 = mul i64 %t1946, %t1915
  %t1958 = bitcast %Point* %t1940 to i8*
  call i8* @memcpy(i8* %t1953, i8* %t1958, i64 %t1957)
  call i8* @memcpy(i8* %t1955, i8* %t1942, i64 %t1946)
  br label %set_cow_after_copy_445
set_cow_after_copy_445:
  %t1959 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1951, i32 0, i32 0
  store %Point* %t1954, %Point** %t1959
  %t1960 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1951, i32 0, i32 1
  store i8* %t1955, i8** %t1960
  %t1961 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1951, i32 0, i32 2
  store i64 %t1944, i64* %t1961
  %t1962 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1951, i32 0, i32 3
  store i64 %t1946, i64* %t1962
  %t1963 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1951, i32 0, i32 4
  store i64 %t1948, i64* %t1963
  call void @star_rc_release(i8* %t1916)
  store i8* %t1950, i8** %t1913
  br label %set_cow_done_442
set_cow_done_442:
  %t1964 = load i8*, i8** %t1913
  %t1965 = bitcast i8* %t1964 to { %Point*, i8*, i64, i64, i64 }*
  %t1966 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1965, i32 0, i32 0
  %t1967 = load %Point*, %Point** %t1966
  %t1968 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1965, i32 0, i32 1
  %t1969 = load i8*, i8** %t1968
  %t1970 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1965, i32 0, i32 2
  %t1971 = load i64, i64* %t1970
  %t1972 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1965, i32 0, i32 3
  %t1973 = load i64, i64* %t1972
  %t1974 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1965, i32 0, i32 4
  %t1975 = load i64, i64* %t1974
  %t1977 = getelementptr inbounds %Point, %Point* %t1976, i32 0, i32 0
  store i32 1, i32* %t1977
  %t1978 = getelementptr inbounds %Point, %Point* %t1976, i32 0, i32 1
  store i32 2, i32* %t1978
  %t1979 = load %Point, %Point* %t1976
  %t1980 = load i64, i64* %t1970
  %t1981 = load i64, i64* %t1972
  %t1982 = load i64, i64* %t1974
  %t1983 = add i64 %t1980, %t1982
  %t1984 = add i64 %t1983, 1
  %t1985 = mul i64 %t1984, 4
  %t1986 = mul i64 %t1981, 3
  %t1987 = icmp sgt i64 %t1985, %t1986
  br i1 %t1987, label %set_insert_grow_446, label %set_insert_after_grow_447
set_insert_grow_446:
  %t1988 = getelementptr %Point, %Point* null, i32 1
  %t1989 = ptrtoint %Point* %t1988 to i64
  %t1990 = mul i64 %t1981, 2
  %t1991 = icmp sgt i64 %t1990, 0
  %t1992 = select i1 %t1991, i64 %t1990, i64 8
  %t1993 = sub i64 %t1992, 1
  %t1994 = mul i64 %t1992, %t1989
  %t1995 = call i8* @malloc(i64 %t1994)
  %t1996 = bitcast i8* %t1995 to %Point*
  %t1997 = call i8* @malloc(i64 %t1992)
  store i64 0, i64* %t1998
  br label %ht_fill8_cond_448
ht_fill8_cond_448:
  %t1999 = load i64, i64* %t1998
  %t2000 = icmp slt i64 %t1999, %t1992
  br i1 %t2000, label %ht_fill8_body_449, label %ht_fill8_end_450
ht_fill8_body_449:
  %t2001 = getelementptr inbounds i8, i8* %t1997, i64 %t1999
  store i8 0, i8* %t2001
  %t2002 = add i64 %t1999, 1
  store i64 %t2002, i64* %t1998
  br label %ht_fill8_cond_448
ht_fill8_end_450:
  %t2003 = load %Point*, %Point** %t1966
  %t2004 = load i8*, i8** %t1968
  store i64 0, i64* %t2005
  br label %set_grow_cond_451
set_grow_cond_451:
  %t2006 = load i64, i64* %t2005
  %t2007 = icmp slt i64 %t2006, %t1981
  br i1 %t2007, label %set_grow_body_452, label %set_grow_end_455
set_grow_body_452:
  %t2008 = getelementptr inbounds i8, i8* %t2004, i64 %t2006
  %t2009 = load i8, i8* %t2008
  %t2010 = icmp eq i8 %t2009, 1
  br i1 %t2010, label %set_grow_occ_453, label %set_grow_next_454
set_grow_occ_453:
  %t2011 = getelementptr inbounds %Point, %Point* %t2003, i64 %t2006
  %t2012 = load %Point, %Point* %t2011
  %t2025 = call i64 @hash_s_Point(%Point %t2012)
  %t2026 = and i64 %t2025, %t1993
  store i64 0, i64* %t2027
  store i64 %t2026, i64* %t2028
  br label %ht_fe_cond_456
ht_fe_cond_456:
  %t2029 = load i64, i64* %t2027
  %t2030 = icmp slt i64 %t2029, %t1992
  br i1 %t2030, label %ht_fe_body_457, label %ht_fe_end_459
ht_fe_body_457:
  %t2031 = load i64, i64* %t2028
  %t2032 = getelementptr inbounds i8, i8* %t1997, i64 %t2031
  %t2033 = load i8, i8* %t2032
  %t2034 = icmp eq i8 %t2033, 0
  br i1 %t2034, label %ht_fe_end_459, label %ht_fe_next_458
ht_fe_next_458:
  %t2035 = add i64 %t2031, 1
  %t2036 = and i64 %t2035, %t1993
  store i64 %t2036, i64* %t2028
  %t2037 = add i64 %t2029, 1
  store i64 %t2037, i64* %t2027
  br label %ht_fe_cond_456
ht_fe_end_459:
  %t2038 = load i64, i64* %t2028
  %t2039 = getelementptr inbounds i8, i8* %t1997, i64 %t2038
  store i8 1, i8* %t2039
  %t2040 = getelementptr inbounds %Point, %Point* %t1996, i64 %t2038
  store %Point %t2012, %Point* %t2040
  br label %set_grow_next_454
set_grow_next_454:
  %t2041 = add i64 %t2006, 1
  store i64 %t2041, i64* %t2005
  br label %set_grow_cond_451
set_grow_end_455:
  %t2042 = bitcast %Point* %t2003 to i8*
  call void @free(i8* %t2042)
  call void @free(i8* %t2004)
  store %Point* %t1996, %Point** %t1966
  store i8* %t1997, i8** %t1968
  store i64 %t1992, i64* %t1972
  store i64 0, i64* %t1974
  br label %set_insert_after_grow_447
set_insert_after_grow_447:
  %t2043 = load %Point*, %Point** %t1966
  %t2044 = load i8*, i8** %t1968
  %t2045 = load i64, i64* %t1972
  %t2046 = sub i64 %t2045, 1
  %t2047 = call i64 @hash_s_Point(%Point %t1979)
  %t2048 = and i64 %t2047, %t2046
  store i64 0, i64* %t2056
  store i64 %t2048, i64* %t2057
  store i1 false, i1* %t2058
  store i64 -1, i64* %t2059
  store i64 -1, i64* %t2060
  store i1 false, i1* %t2061
  br label %ht_probe_cond_460
ht_probe_cond_460:
  %t2062 = load i64, i64* %t2056
  %t2063 = icmp slt i64 %t2062, %t2045
  br i1 %t2063, label %ht_probe_body_461, label %ht_probe_end_471
ht_probe_body_461:
  %t2064 = load i64, i64* %t2057
  %t2065 = getelementptr inbounds i8, i8* %t2044, i64 %t2064
  %t2066 = load i8, i8* %t2065
  %t2067 = icmp eq i8 %t2066, 0
  br i1 %t2067, label %ht_probe_on_empty_463, label %ht_probe_check_occ_462
ht_probe_check_occ_462:
  %t2068 = icmp eq i8 %t2066, 1
  br i1 %t2068, label %ht_probe_on_occ_466, label %ht_probe_on_tomb_468
ht_probe_on_empty_463:
  %t2069 = load i1, i1* %t2061
  br i1 %t2069, label %ht_probe_after_islot_empty_465, label %ht_probe_set_islot_empty_464
ht_probe_set_islot_empty_464:
  store i64 %t2064, i64* %t2060
  store i1 true, i1* %t2061
  br label %ht_probe_after_islot_empty_465
ht_probe_after_islot_empty_465:
  br label %ht_probe_end_471
ht_probe_on_occ_466:
  %t2070 = getelementptr inbounds %Point, %Point* %t2043, i64 %t2064
  %t2071 = load %Point, %Point* %t2070
  %t2072 = call i1 @eq_s_Point(%Point %t2071, %Point %t1979)
  br i1 %t2072, label %ht_probe_on_match_467, label %ht_probe_next_470
ht_probe_on_match_467:
  store i1 true, i1* %t2058
  store i64 %t2064, i64* %t2059
  br label %ht_probe_end_471
ht_probe_on_tomb_468:
  %t2073 = load i1, i1* %t2061
  br i1 %t2073, label %ht_probe_next_470, label %ht_probe_set_islot_tomb_469
ht_probe_set_islot_tomb_469:
  store i64 %t2064, i64* %t2060
  store i1 true, i1* %t2061
  br label %ht_probe_next_470
ht_probe_next_470:
  %t2074 = add i64 %t2064, 1
  %t2075 = and i64 %t2074, %t2046
  store i64 %t2075, i64* %t2057
  %t2076 = add i64 %t2062, 1
  store i64 %t2076, i64* %t2056
  br label %ht_probe_cond_460
ht_probe_end_471:
  %t2077 = load i1, i1* %t2058
  %t2078 = load i64, i64* %t2059
  %t2079 = load i64, i64* %t2060
  %t2080 = xor i1 %t2077, true
  br i1 %t2077, label %set_insert_already_present_472, label %set_insert_do_473
set_insert_already_present_472:
  br label %set_insert_end_474
set_insert_do_473:
  %t2081 = getelementptr inbounds i8, i8* %t2044, i64 %t2079
  %t2082 = load i8, i8* %t2081
  %t2083 = icmp eq i8 %t2082, 2
  br i1 %t2083, label %set_insert_dec_tomb_475, label %set_insert_store_476
set_insert_dec_tomb_475:
  %t2084 = load i64, i64* %t1974
  %t2085 = sub i64 %t2084, 1
  store i64 %t2085, i64* %t1974
  br label %set_insert_store_476
set_insert_store_476:
  store i8 1, i8* %t2081
  %t2086 = getelementptr inbounds %Point, %Point* %t2043, i64 %t2079
  store %Point %t1979, %Point* %t2086
  %t2087 = load i64, i64* %t1970
  %t2088 = add i64 %t2087, 1
  store i64 %t2088, i64* %t1970
  br label %set_insert_end_474
set_insert_end_474:
  %t2089 = getelementptr %Point, %Point* null, i32 1
  %t2090 = ptrtoint %Point* %t2089 to i64
  %t2091 = load i8*, i8** %t1913
  %t2092 = icmp eq i8* %t2091, null
  br i1 %t2092, label %set_cow_alloc_477, label %set_cow_check_478
set_cow_alloc_477:
  %t2093 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t2094 = call i8* @star_rc_alloc(i64 40, i8* %t2093)
  %t2095 = bitcast i8* %t2094 to { %Point*, i8*, i64, i64, i64 }*
  %t2096 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2095, i32 0, i32 0
  store %Point* null, %Point** %t2096
  %t2097 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2095, i32 0, i32 1
  store i8* null, i8** %t2097
  %t2098 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2095, i32 0, i32 2
  store i64 0, i64* %t2098
  %t2099 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2095, i32 0, i32 3
  store i64 0, i64* %t2099
  %t2100 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2095, i32 0, i32 4
  store i64 0, i64* %t2100
  store i8* %t2094, i8** %t1913
  br label %set_cow_done_479
set_cow_check_478:
  %t2101 = getelementptr inbounds i8, i8* %t2091, i64 -16
  %t2102 = bitcast i8* %t2101 to i64*
  %t2103 = load atomic i64, i64* %t2102 seq_cst, align 8
  %t2104 = icmp eq i64 %t2103, 1
  br i1 %t2104, label %set_cow_done_479, label %set_cow_clone_480
set_cow_clone_480:
  %t2105 = bitcast i8* %t2091 to { %Point*, i8*, i64, i64, i64 }*
  %t2106 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2105, i32 0, i32 0
  %t2107 = load %Point*, %Point** %t2106
  %t2108 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2105, i32 0, i32 1
  %t2109 = load i8*, i8** %t2108
  %t2110 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2105, i32 0, i32 2
  %t2111 = load i64, i64* %t2110
  %t2112 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2105, i32 0, i32 3
  %t2113 = load i64, i64* %t2112
  %t2114 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2105, i32 0, i32 4
  %t2115 = load i64, i64* %t2114
  %t2116 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t2117 = call i8* @star_rc_alloc(i64 40, i8* %t2116)
  %t2118 = bitcast i8* %t2117 to { %Point*, i8*, i64, i64, i64 }*
  %t2119 = mul i64 %t2113, %t2090
  %t2120 = call i8* @malloc(i64 %t2119)
  %t2121 = bitcast i8* %t2120 to %Point*
  %t2122 = call i8* @malloc(i64 %t2113)
  %t2123 = icmp sgt i64 %t2113, 0
  br i1 %t2123, label %set_cow_copy_481, label %set_cow_after_copy_482
set_cow_copy_481:
  %t2124 = mul i64 %t2113, %t2090
  %t2125 = bitcast %Point* %t2107 to i8*
  call i8* @memcpy(i8* %t2120, i8* %t2125, i64 %t2124)
  call i8* @memcpy(i8* %t2122, i8* %t2109, i64 %t2113)
  br label %set_cow_after_copy_482
set_cow_after_copy_482:
  %t2126 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2118, i32 0, i32 0
  store %Point* %t2121, %Point** %t2126
  %t2127 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2118, i32 0, i32 1
  store i8* %t2122, i8** %t2127
  %t2128 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2118, i32 0, i32 2
  store i64 %t2111, i64* %t2128
  %t2129 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2118, i32 0, i32 3
  store i64 %t2113, i64* %t2129
  %t2130 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2118, i32 0, i32 4
  store i64 %t2115, i64* %t2130
  call void @star_rc_release(i8* %t2091)
  store i8* %t2117, i8** %t1913
  br label %set_cow_done_479
set_cow_done_479:
  %t2131 = load i8*, i8** %t1913
  %t2132 = bitcast i8* %t2131 to { %Point*, i8*, i64, i64, i64 }*
  %t2133 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2132, i32 0, i32 0
  %t2134 = load %Point*, %Point** %t2133
  %t2135 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2132, i32 0, i32 1
  %t2136 = load i8*, i8** %t2135
  %t2137 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2132, i32 0, i32 2
  %t2138 = load i64, i64* %t2137
  %t2139 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2132, i32 0, i32 3
  %t2140 = load i64, i64* %t2139
  %t2141 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2132, i32 0, i32 4
  %t2142 = load i64, i64* %t2141
  %t2144 = getelementptr inbounds %Point, %Point* %t2143, i32 0, i32 0
  store i32 1, i32* %t2144
  %t2145 = getelementptr inbounds %Point, %Point* %t2143, i32 0, i32 1
  store i32 2, i32* %t2145
  %t2146 = load %Point, %Point* %t2143
  %t2147 = load i64, i64* %t2137
  %t2148 = load i64, i64* %t2139
  %t2149 = load i64, i64* %t2141
  %t2150 = add i64 %t2147, %t2149
  %t2151 = add i64 %t2150, 1
  %t2152 = mul i64 %t2151, 4
  %t2153 = mul i64 %t2148, 3
  %t2154 = icmp sgt i64 %t2152, %t2153
  br i1 %t2154, label %set_insert_grow_483, label %set_insert_after_grow_484
set_insert_grow_483:
  %t2155 = getelementptr %Point, %Point* null, i32 1
  %t2156 = ptrtoint %Point* %t2155 to i64
  %t2157 = mul i64 %t2148, 2
  %t2158 = icmp sgt i64 %t2157, 0
  %t2159 = select i1 %t2158, i64 %t2157, i64 8
  %t2160 = sub i64 %t2159, 1
  %t2161 = mul i64 %t2159, %t2156
  %t2162 = call i8* @malloc(i64 %t2161)
  %t2163 = bitcast i8* %t2162 to %Point*
  %t2164 = call i8* @malloc(i64 %t2159)
  store i64 0, i64* %t2165
  br label %ht_fill8_cond_485
ht_fill8_cond_485:
  %t2166 = load i64, i64* %t2165
  %t2167 = icmp slt i64 %t2166, %t2159
  br i1 %t2167, label %ht_fill8_body_486, label %ht_fill8_end_487
ht_fill8_body_486:
  %t2168 = getelementptr inbounds i8, i8* %t2164, i64 %t2166
  store i8 0, i8* %t2168
  %t2169 = add i64 %t2166, 1
  store i64 %t2169, i64* %t2165
  br label %ht_fill8_cond_485
ht_fill8_end_487:
  %t2170 = load %Point*, %Point** %t2133
  %t2171 = load i8*, i8** %t2135
  store i64 0, i64* %t2172
  br label %set_grow_cond_488
set_grow_cond_488:
  %t2173 = load i64, i64* %t2172
  %t2174 = icmp slt i64 %t2173, %t2148
  br i1 %t2174, label %set_grow_body_489, label %set_grow_end_492
set_grow_body_489:
  %t2175 = getelementptr inbounds i8, i8* %t2171, i64 %t2173
  %t2176 = load i8, i8* %t2175
  %t2177 = icmp eq i8 %t2176, 1
  br i1 %t2177, label %set_grow_occ_490, label %set_grow_next_491
set_grow_occ_490:
  %t2178 = getelementptr inbounds %Point, %Point* %t2170, i64 %t2173
  %t2179 = load %Point, %Point* %t2178
  %t2180 = call i64 @hash_s_Point(%Point %t2179)
  %t2181 = and i64 %t2180, %t2160
  store i64 0, i64* %t2182
  store i64 %t2181, i64* %t2183
  br label %ht_fe_cond_493
ht_fe_cond_493:
  %t2184 = load i64, i64* %t2182
  %t2185 = icmp slt i64 %t2184, %t2159
  br i1 %t2185, label %ht_fe_body_494, label %ht_fe_end_496
ht_fe_body_494:
  %t2186 = load i64, i64* %t2183
  %t2187 = getelementptr inbounds i8, i8* %t2164, i64 %t2186
  %t2188 = load i8, i8* %t2187
  %t2189 = icmp eq i8 %t2188, 0
  br i1 %t2189, label %ht_fe_end_496, label %ht_fe_next_495
ht_fe_next_495:
  %t2190 = add i64 %t2186, 1
  %t2191 = and i64 %t2190, %t2160
  store i64 %t2191, i64* %t2183
  %t2192 = add i64 %t2184, 1
  store i64 %t2192, i64* %t2182
  br label %ht_fe_cond_493
ht_fe_end_496:
  %t2193 = load i64, i64* %t2183
  %t2194 = getelementptr inbounds i8, i8* %t2164, i64 %t2193
  store i8 1, i8* %t2194
  %t2195 = getelementptr inbounds %Point, %Point* %t2163, i64 %t2193
  store %Point %t2179, %Point* %t2195
  br label %set_grow_next_491
set_grow_next_491:
  %t2196 = add i64 %t2173, 1
  store i64 %t2196, i64* %t2172
  br label %set_grow_cond_488
set_grow_end_492:
  %t2197 = bitcast %Point* %t2170 to i8*
  call void @free(i8* %t2197)
  call void @free(i8* %t2171)
  store %Point* %t2163, %Point** %t2133
  store i8* %t2164, i8** %t2135
  store i64 %t2159, i64* %t2139
  store i64 0, i64* %t2141
  br label %set_insert_after_grow_484
set_insert_after_grow_484:
  %t2198 = load %Point*, %Point** %t2133
  %t2199 = load i8*, i8** %t2135
  %t2200 = load i64, i64* %t2139
  %t2201 = sub i64 %t2200, 1
  %t2202 = call i64 @hash_s_Point(%Point %t2146)
  %t2203 = and i64 %t2202, %t2201
  store i64 0, i64* %t2204
  store i64 %t2203, i64* %t2205
  store i1 false, i1* %t2206
  store i64 -1, i64* %t2207
  store i64 -1, i64* %t2208
  store i1 false, i1* %t2209
  br label %ht_probe_cond_497
ht_probe_cond_497:
  %t2210 = load i64, i64* %t2204
  %t2211 = icmp slt i64 %t2210, %t2200
  br i1 %t2211, label %ht_probe_body_498, label %ht_probe_end_508
ht_probe_body_498:
  %t2212 = load i64, i64* %t2205
  %t2213 = getelementptr inbounds i8, i8* %t2199, i64 %t2212
  %t2214 = load i8, i8* %t2213
  %t2215 = icmp eq i8 %t2214, 0
  br i1 %t2215, label %ht_probe_on_empty_500, label %ht_probe_check_occ_499
ht_probe_check_occ_499:
  %t2216 = icmp eq i8 %t2214, 1
  br i1 %t2216, label %ht_probe_on_occ_503, label %ht_probe_on_tomb_505
ht_probe_on_empty_500:
  %t2217 = load i1, i1* %t2209
  br i1 %t2217, label %ht_probe_after_islot_empty_502, label %ht_probe_set_islot_empty_501
ht_probe_set_islot_empty_501:
  store i64 %t2212, i64* %t2208
  store i1 true, i1* %t2209
  br label %ht_probe_after_islot_empty_502
ht_probe_after_islot_empty_502:
  br label %ht_probe_end_508
ht_probe_on_occ_503:
  %t2218 = getelementptr inbounds %Point, %Point* %t2198, i64 %t2212
  %t2219 = load %Point, %Point* %t2218
  %t2220 = call i1 @eq_s_Point(%Point %t2219, %Point %t2146)
  br i1 %t2220, label %ht_probe_on_match_504, label %ht_probe_next_507
ht_probe_on_match_504:
  store i1 true, i1* %t2206
  store i64 %t2212, i64* %t2207
  br label %ht_probe_end_508
ht_probe_on_tomb_505:
  %t2221 = load i1, i1* %t2209
  br i1 %t2221, label %ht_probe_next_507, label %ht_probe_set_islot_tomb_506
ht_probe_set_islot_tomb_506:
  store i64 %t2212, i64* %t2208
  store i1 true, i1* %t2209
  br label %ht_probe_next_507
ht_probe_next_507:
  %t2222 = add i64 %t2212, 1
  %t2223 = and i64 %t2222, %t2201
  store i64 %t2223, i64* %t2205
  %t2224 = add i64 %t2210, 1
  store i64 %t2224, i64* %t2204
  br label %ht_probe_cond_497
ht_probe_end_508:
  %t2225 = load i1, i1* %t2206
  %t2226 = load i64, i64* %t2207
  %t2227 = load i64, i64* %t2208
  %t2228 = xor i1 %t2225, true
  br i1 %t2225, label %set_insert_already_present_509, label %set_insert_do_510
set_insert_already_present_509:
  br label %set_insert_end_511
set_insert_do_510:
  %t2229 = getelementptr inbounds i8, i8* %t2199, i64 %t2227
  %t2230 = load i8, i8* %t2229
  %t2231 = icmp eq i8 %t2230, 2
  br i1 %t2231, label %set_insert_dec_tomb_512, label %set_insert_store_513
set_insert_dec_tomb_512:
  %t2232 = load i64, i64* %t2141
  %t2233 = sub i64 %t2232, 1
  store i64 %t2233, i64* %t2141
  br label %set_insert_store_513
set_insert_store_513:
  store i8 1, i8* %t2229
  %t2234 = getelementptr inbounds %Point, %Point* %t2198, i64 %t2227
  store %Point %t2146, %Point* %t2234
  %t2235 = load i64, i64* %t2137
  %t2236 = add i64 %t2235, 1
  store i64 %t2236, i64* %t2137
  br label %set_insert_end_511
set_insert_end_511:
  %t2237 = getelementptr %Point, %Point* null, i32 1
  %t2238 = ptrtoint %Point* %t2237 to i64
  %t2239 = load i8*, i8** %t1913
  %t2240 = icmp eq i8* %t2239, null
  br i1 %t2240, label %set_cow_alloc_514, label %set_cow_check_515
set_cow_alloc_514:
  %t2241 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t2242 = call i8* @star_rc_alloc(i64 40, i8* %t2241)
  %t2243 = bitcast i8* %t2242 to { %Point*, i8*, i64, i64, i64 }*
  %t2244 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 0
  store %Point* null, %Point** %t2244
  %t2245 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 1
  store i8* null, i8** %t2245
  %t2246 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 2
  store i64 0, i64* %t2246
  %t2247 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 3
  store i64 0, i64* %t2247
  %t2248 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2243, i32 0, i32 4
  store i64 0, i64* %t2248
  store i8* %t2242, i8** %t1913
  br label %set_cow_done_516
set_cow_check_515:
  %t2249 = getelementptr inbounds i8, i8* %t2239, i64 -16
  %t2250 = bitcast i8* %t2249 to i64*
  %t2251 = load atomic i64, i64* %t2250 seq_cst, align 8
  %t2252 = icmp eq i64 %t2251, 1
  br i1 %t2252, label %set_cow_done_516, label %set_cow_clone_517
set_cow_clone_517:
  %t2253 = bitcast i8* %t2239 to { %Point*, i8*, i64, i64, i64 }*
  %t2254 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2253, i32 0, i32 0
  %t2255 = load %Point*, %Point** %t2254
  %t2256 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2253, i32 0, i32 1
  %t2257 = load i8*, i8** %t2256
  %t2258 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2253, i32 0, i32 2
  %t2259 = load i64, i64* %t2258
  %t2260 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2253, i32 0, i32 3
  %t2261 = load i64, i64* %t2260
  %t2262 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2253, i32 0, i32 4
  %t2263 = load i64, i64* %t2262
  %t2264 = bitcast void (i8*)* @set_release_s_Point to i8*
  %t2265 = call i8* @star_rc_alloc(i64 40, i8* %t2264)
  %t2266 = bitcast i8* %t2265 to { %Point*, i8*, i64, i64, i64 }*
  %t2267 = mul i64 %t2261, %t2238
  %t2268 = call i8* @malloc(i64 %t2267)
  %t2269 = bitcast i8* %t2268 to %Point*
  %t2270 = call i8* @malloc(i64 %t2261)
  %t2271 = icmp sgt i64 %t2261, 0
  br i1 %t2271, label %set_cow_copy_518, label %set_cow_after_copy_519
set_cow_copy_518:
  %t2272 = mul i64 %t2261, %t2238
  %t2273 = bitcast %Point* %t2255 to i8*
  call i8* @memcpy(i8* %t2268, i8* %t2273, i64 %t2272)
  call i8* @memcpy(i8* %t2270, i8* %t2257, i64 %t2261)
  br label %set_cow_after_copy_519
set_cow_after_copy_519:
  %t2274 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2266, i32 0, i32 0
  store %Point* %t2269, %Point** %t2274
  %t2275 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2266, i32 0, i32 1
  store i8* %t2270, i8** %t2275
  %t2276 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2266, i32 0, i32 2
  store i64 %t2259, i64* %t2276
  %t2277 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2266, i32 0, i32 3
  store i64 %t2261, i64* %t2277
  %t2278 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2266, i32 0, i32 4
  store i64 %t2263, i64* %t2278
  call void @star_rc_release(i8* %t2239)
  store i8* %t2265, i8** %t1913
  br label %set_cow_done_516
set_cow_done_516:
  %t2279 = load i8*, i8** %t1913
  %t2280 = bitcast i8* %t2279 to { %Point*, i8*, i64, i64, i64 }*
  %t2281 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2280, i32 0, i32 0
  %t2282 = load %Point*, %Point** %t2281
  %t2283 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2280, i32 0, i32 1
  %t2284 = load i8*, i8** %t2283
  %t2285 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2280, i32 0, i32 2
  %t2286 = load i64, i64* %t2285
  %t2287 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2280, i32 0, i32 3
  %t2288 = load i64, i64* %t2287
  %t2289 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2280, i32 0, i32 4
  %t2290 = load i64, i64* %t2289
  %t2292 = getelementptr inbounds %Point, %Point* %t2291, i32 0, i32 0
  store i32 3, i32* %t2292
  %t2293 = getelementptr inbounds %Point, %Point* %t2291, i32 0, i32 1
  store i32 4, i32* %t2293
  %t2294 = load %Point, %Point* %t2291
  %t2295 = load i64, i64* %t2285
  %t2296 = load i64, i64* %t2287
  %t2297 = load i64, i64* %t2289
  %t2298 = add i64 %t2295, %t2297
  %t2299 = add i64 %t2298, 1
  %t2300 = mul i64 %t2299, 4
  %t2301 = mul i64 %t2296, 3
  %t2302 = icmp sgt i64 %t2300, %t2301
  br i1 %t2302, label %set_insert_grow_520, label %set_insert_after_grow_521
set_insert_grow_520:
  %t2303 = getelementptr %Point, %Point* null, i32 1
  %t2304 = ptrtoint %Point* %t2303 to i64
  %t2305 = mul i64 %t2296, 2
  %t2306 = icmp sgt i64 %t2305, 0
  %t2307 = select i1 %t2306, i64 %t2305, i64 8
  %t2308 = sub i64 %t2307, 1
  %t2309 = mul i64 %t2307, %t2304
  %t2310 = call i8* @malloc(i64 %t2309)
  %t2311 = bitcast i8* %t2310 to %Point*
  %t2312 = call i8* @malloc(i64 %t2307)
  store i64 0, i64* %t2313
  br label %ht_fill8_cond_522
ht_fill8_cond_522:
  %t2314 = load i64, i64* %t2313
  %t2315 = icmp slt i64 %t2314, %t2307
  br i1 %t2315, label %ht_fill8_body_523, label %ht_fill8_end_524
ht_fill8_body_523:
  %t2316 = getelementptr inbounds i8, i8* %t2312, i64 %t2314
  store i8 0, i8* %t2316
  %t2317 = add i64 %t2314, 1
  store i64 %t2317, i64* %t2313
  br label %ht_fill8_cond_522
ht_fill8_end_524:
  %t2318 = load %Point*, %Point** %t2281
  %t2319 = load i8*, i8** %t2283
  store i64 0, i64* %t2320
  br label %set_grow_cond_525
set_grow_cond_525:
  %t2321 = load i64, i64* %t2320
  %t2322 = icmp slt i64 %t2321, %t2296
  br i1 %t2322, label %set_grow_body_526, label %set_grow_end_529
set_grow_body_526:
  %t2323 = getelementptr inbounds i8, i8* %t2319, i64 %t2321
  %t2324 = load i8, i8* %t2323
  %t2325 = icmp eq i8 %t2324, 1
  br i1 %t2325, label %set_grow_occ_527, label %set_grow_next_528
set_grow_occ_527:
  %t2326 = getelementptr inbounds %Point, %Point* %t2318, i64 %t2321
  %t2327 = load %Point, %Point* %t2326
  %t2328 = call i64 @hash_s_Point(%Point %t2327)
  %t2329 = and i64 %t2328, %t2308
  store i64 0, i64* %t2330
  store i64 %t2329, i64* %t2331
  br label %ht_fe_cond_530
ht_fe_cond_530:
  %t2332 = load i64, i64* %t2330
  %t2333 = icmp slt i64 %t2332, %t2307
  br i1 %t2333, label %ht_fe_body_531, label %ht_fe_end_533
ht_fe_body_531:
  %t2334 = load i64, i64* %t2331
  %t2335 = getelementptr inbounds i8, i8* %t2312, i64 %t2334
  %t2336 = load i8, i8* %t2335
  %t2337 = icmp eq i8 %t2336, 0
  br i1 %t2337, label %ht_fe_end_533, label %ht_fe_next_532
ht_fe_next_532:
  %t2338 = add i64 %t2334, 1
  %t2339 = and i64 %t2338, %t2308
  store i64 %t2339, i64* %t2331
  %t2340 = add i64 %t2332, 1
  store i64 %t2340, i64* %t2330
  br label %ht_fe_cond_530
ht_fe_end_533:
  %t2341 = load i64, i64* %t2331
  %t2342 = getelementptr inbounds i8, i8* %t2312, i64 %t2341
  store i8 1, i8* %t2342
  %t2343 = getelementptr inbounds %Point, %Point* %t2311, i64 %t2341
  store %Point %t2327, %Point* %t2343
  br label %set_grow_next_528
set_grow_next_528:
  %t2344 = add i64 %t2321, 1
  store i64 %t2344, i64* %t2320
  br label %set_grow_cond_525
set_grow_end_529:
  %t2345 = bitcast %Point* %t2318 to i8*
  call void @free(i8* %t2345)
  call void @free(i8* %t2319)
  store %Point* %t2311, %Point** %t2281
  store i8* %t2312, i8** %t2283
  store i64 %t2307, i64* %t2287
  store i64 0, i64* %t2289
  br label %set_insert_after_grow_521
set_insert_after_grow_521:
  %t2346 = load %Point*, %Point** %t2281
  %t2347 = load i8*, i8** %t2283
  %t2348 = load i64, i64* %t2287
  %t2349 = sub i64 %t2348, 1
  %t2350 = call i64 @hash_s_Point(%Point %t2294)
  %t2351 = and i64 %t2350, %t2349
  store i64 0, i64* %t2352
  store i64 %t2351, i64* %t2353
  store i1 false, i1* %t2354
  store i64 -1, i64* %t2355
  store i64 -1, i64* %t2356
  store i1 false, i1* %t2357
  br label %ht_probe_cond_534
ht_probe_cond_534:
  %t2358 = load i64, i64* %t2352
  %t2359 = icmp slt i64 %t2358, %t2348
  br i1 %t2359, label %ht_probe_body_535, label %ht_probe_end_545
ht_probe_body_535:
  %t2360 = load i64, i64* %t2353
  %t2361 = getelementptr inbounds i8, i8* %t2347, i64 %t2360
  %t2362 = load i8, i8* %t2361
  %t2363 = icmp eq i8 %t2362, 0
  br i1 %t2363, label %ht_probe_on_empty_537, label %ht_probe_check_occ_536
ht_probe_check_occ_536:
  %t2364 = icmp eq i8 %t2362, 1
  br i1 %t2364, label %ht_probe_on_occ_540, label %ht_probe_on_tomb_542
ht_probe_on_empty_537:
  %t2365 = load i1, i1* %t2357
  br i1 %t2365, label %ht_probe_after_islot_empty_539, label %ht_probe_set_islot_empty_538
ht_probe_set_islot_empty_538:
  store i64 %t2360, i64* %t2356
  store i1 true, i1* %t2357
  br label %ht_probe_after_islot_empty_539
ht_probe_after_islot_empty_539:
  br label %ht_probe_end_545
ht_probe_on_occ_540:
  %t2366 = getelementptr inbounds %Point, %Point* %t2346, i64 %t2360
  %t2367 = load %Point, %Point* %t2366
  %t2368 = call i1 @eq_s_Point(%Point %t2367, %Point %t2294)
  br i1 %t2368, label %ht_probe_on_match_541, label %ht_probe_next_544
ht_probe_on_match_541:
  store i1 true, i1* %t2354
  store i64 %t2360, i64* %t2355
  br label %ht_probe_end_545
ht_probe_on_tomb_542:
  %t2369 = load i1, i1* %t2357
  br i1 %t2369, label %ht_probe_next_544, label %ht_probe_set_islot_tomb_543
ht_probe_set_islot_tomb_543:
  store i64 %t2360, i64* %t2356
  store i1 true, i1* %t2357
  br label %ht_probe_next_544
ht_probe_next_544:
  %t2370 = add i64 %t2360, 1
  %t2371 = and i64 %t2370, %t2349
  store i64 %t2371, i64* %t2353
  %t2372 = add i64 %t2358, 1
  store i64 %t2372, i64* %t2352
  br label %ht_probe_cond_534
ht_probe_end_545:
  %t2373 = load i1, i1* %t2354
  %t2374 = load i64, i64* %t2355
  %t2375 = load i64, i64* %t2356
  %t2376 = xor i1 %t2373, true
  br i1 %t2373, label %set_insert_already_present_546, label %set_insert_do_547
set_insert_already_present_546:
  br label %set_insert_end_548
set_insert_do_547:
  %t2377 = getelementptr inbounds i8, i8* %t2347, i64 %t2375
  %t2378 = load i8, i8* %t2377
  %t2379 = icmp eq i8 %t2378, 2
  br i1 %t2379, label %set_insert_dec_tomb_549, label %set_insert_store_550
set_insert_dec_tomb_549:
  %t2380 = load i64, i64* %t2289
  %t2381 = sub i64 %t2380, 1
  store i64 %t2381, i64* %t2289
  br label %set_insert_store_550
set_insert_store_550:
  store i8 1, i8* %t2377
  %t2382 = getelementptr inbounds %Point, %Point* %t2346, i64 %t2375
  store %Point %t2294, %Point* %t2382
  %t2383 = load i64, i64* %t2285
  %t2384 = add i64 %t2383, 1
  store i64 %t2384, i64* %t2285
  br label %set_insert_end_548
set_insert_end_548:
  %t2385 = load i8*, i8** %t1913
  %t2386 = icmp eq i8* %t2385, null
  br i1 %t2386, label %set_read_null_551, label %set_read_real_552
set_read_null_551:
  br label %set_read_end_553
set_read_real_552:
  %t2387 = bitcast i8* %t2385 to { %Point*, i8*, i64, i64, i64 }*
  %t2388 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2387, i32 0, i32 0
  %t2389 = load %Point*, %Point** %t2388
  %t2390 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2387, i32 0, i32 1
  %t2391 = load i8*, i8** %t2390
  %t2392 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2387, i32 0, i32 2
  %t2393 = load i64, i64* %t2392
  %t2394 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2387, i32 0, i32 3
  %t2395 = load i64, i64* %t2394
  br label %set_read_end_553
set_read_end_553:
  %t2396 = phi %Point* [ null, %set_read_null_551 ], [ %t2389, %set_read_real_552 ]
  %t2397 = phi i8* [ null, %set_read_null_551 ], [ %t2391, %set_read_real_552 ]
  %t2398 = phi i64 [ 0, %set_read_null_551 ], [ %t2393, %set_read_real_552 ]
  %t2399 = phi i64 [ 0, %set_read_null_551 ], [ %t2395, %set_read_real_552 ]
  %t2400 = trunc i64 %t2398 to i32
  %t2401 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.52, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t2401, i32 %t2400)
  %t2403 = getelementptr inbounds %Point, %Point* %t2402, i32 0, i32 0
  store i32 1, i32* %t2403
  %t2404 = getelementptr inbounds %Point, %Point* %t2402, i32 0, i32 1
  store i32 2, i32* %t2404
  %t2405 = load %Point, %Point* %t2402
  %t2406 = load i8*, i8** %t1913
  %t2407 = icmp eq i8* %t2406, null
  br i1 %t2407, label %set_read_null_554, label %set_read_real_555
set_read_null_554:
  br label %set_read_end_556
set_read_real_555:
  %t2408 = bitcast i8* %t2406 to { %Point*, i8*, i64, i64, i64 }*
  %t2409 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2408, i32 0, i32 0
  %t2410 = load %Point*, %Point** %t2409
  %t2411 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2408, i32 0, i32 1
  %t2412 = load i8*, i8** %t2411
  %t2413 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2408, i32 0, i32 2
  %t2414 = load i64, i64* %t2413
  %t2415 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2408, i32 0, i32 3
  %t2416 = load i64, i64* %t2415
  br label %set_read_end_556
set_read_end_556:
  %t2417 = phi %Point* [ null, %set_read_null_554 ], [ %t2410, %set_read_real_555 ]
  %t2418 = phi i8* [ null, %set_read_null_554 ], [ %t2412, %set_read_real_555 ]
  %t2419 = phi i64 [ 0, %set_read_null_554 ], [ %t2414, %set_read_real_555 ]
  %t2420 = phi i64 [ 0, %set_read_null_554 ], [ %t2416, %set_read_real_555 ]
  %t2421 = sub i64 %t2420, 1
  %t2422 = call i64 @hash_s_Point(%Point %t2405)
  %t2423 = and i64 %t2422, %t2421
  store i64 0, i64* %t2424
  store i64 %t2423, i64* %t2425
  store i1 false, i1* %t2426
  store i64 -1, i64* %t2427
  store i64 -1, i64* %t2428
  store i1 false, i1* %t2429
  br label %ht_probe_cond_557
ht_probe_cond_557:
  %t2430 = load i64, i64* %t2424
  %t2431 = icmp slt i64 %t2430, %t2420
  br i1 %t2431, label %ht_probe_body_558, label %ht_probe_end_568
ht_probe_body_558:
  %t2432 = load i64, i64* %t2425
  %t2433 = getelementptr inbounds i8, i8* %t2418, i64 %t2432
  %t2434 = load i8, i8* %t2433
  %t2435 = icmp eq i8 %t2434, 0
  br i1 %t2435, label %ht_probe_on_empty_560, label %ht_probe_check_occ_559
ht_probe_check_occ_559:
  %t2436 = icmp eq i8 %t2434, 1
  br i1 %t2436, label %ht_probe_on_occ_563, label %ht_probe_on_tomb_565
ht_probe_on_empty_560:
  %t2437 = load i1, i1* %t2429
  br i1 %t2437, label %ht_probe_after_islot_empty_562, label %ht_probe_set_islot_empty_561
ht_probe_set_islot_empty_561:
  store i64 %t2432, i64* %t2428
  store i1 true, i1* %t2429
  br label %ht_probe_after_islot_empty_562
ht_probe_after_islot_empty_562:
  br label %ht_probe_end_568
ht_probe_on_occ_563:
  %t2438 = getelementptr inbounds %Point, %Point* %t2417, i64 %t2432
  %t2439 = load %Point, %Point* %t2438
  %t2440 = call i1 @eq_s_Point(%Point %t2439, %Point %t2405)
  br i1 %t2440, label %ht_probe_on_match_564, label %ht_probe_next_567
ht_probe_on_match_564:
  store i1 true, i1* %t2426
  store i64 %t2432, i64* %t2427
  br label %ht_probe_end_568
ht_probe_on_tomb_565:
  %t2441 = load i1, i1* %t2429
  br i1 %t2441, label %ht_probe_next_567, label %ht_probe_set_islot_tomb_566
ht_probe_set_islot_tomb_566:
  store i64 %t2432, i64* %t2428
  store i1 true, i1* %t2429
  br label %ht_probe_next_567
ht_probe_next_567:
  %t2442 = add i64 %t2432, 1
  %t2443 = and i64 %t2442, %t2421
  store i64 %t2443, i64* %t2425
  %t2444 = add i64 %t2430, 1
  store i64 %t2444, i64* %t2424
  br label %ht_probe_cond_557
ht_probe_end_568:
  %t2445 = load i1, i1* %t2426
  %t2446 = load i64, i64* %t2427
  %t2447 = load i64, i64* %t2428
  %t2448 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.53, i64 0, i64 0
  %t2449 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.54, i64 0, i64 0
  %t2450 = select i1 %t2445, i8* %t2448, i8* %t2449
  %t2451 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.55, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t2451, i8* %t2450)
  %t2453 = getelementptr inbounds %Point, %Point* %t2452, i32 0, i32 0
  store i32 9, i32* %t2453
  %t2454 = getelementptr inbounds %Point, %Point* %t2452, i32 0, i32 1
  store i32 9, i32* %t2454
  %t2455 = load %Point, %Point* %t2452
  %t2456 = load i8*, i8** %t1913
  %t2457 = icmp eq i8* %t2456, null
  br i1 %t2457, label %set_read_null_569, label %set_read_real_570
set_read_null_569:
  br label %set_read_end_571
set_read_real_570:
  %t2458 = bitcast i8* %t2456 to { %Point*, i8*, i64, i64, i64 }*
  %t2459 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2458, i32 0, i32 0
  %t2460 = load %Point*, %Point** %t2459
  %t2461 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2458, i32 0, i32 1
  %t2462 = load i8*, i8** %t2461
  %t2463 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2458, i32 0, i32 2
  %t2464 = load i64, i64* %t2463
  %t2465 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t2458, i32 0, i32 3
  %t2466 = load i64, i64* %t2465
  br label %set_read_end_571
set_read_end_571:
  %t2467 = phi %Point* [ null, %set_read_null_569 ], [ %t2460, %set_read_real_570 ]
  %t2468 = phi i8* [ null, %set_read_null_569 ], [ %t2462, %set_read_real_570 ]
  %t2469 = phi i64 [ 0, %set_read_null_569 ], [ %t2464, %set_read_real_570 ]
  %t2470 = phi i64 [ 0, %set_read_null_569 ], [ %t2466, %set_read_real_570 ]
  %t2471 = sub i64 %t2470, 1
  %t2472 = call i64 @hash_s_Point(%Point %t2455)
  %t2473 = and i64 %t2472, %t2471
  store i64 0, i64* %t2474
  store i64 %t2473, i64* %t2475
  store i1 false, i1* %t2476
  store i64 -1, i64* %t2477
  store i64 -1, i64* %t2478
  store i1 false, i1* %t2479
  br label %ht_probe_cond_572
ht_probe_cond_572:
  %t2480 = load i64, i64* %t2474
  %t2481 = icmp slt i64 %t2480, %t2470
  br i1 %t2481, label %ht_probe_body_573, label %ht_probe_end_583
ht_probe_body_573:
  %t2482 = load i64, i64* %t2475
  %t2483 = getelementptr inbounds i8, i8* %t2468, i64 %t2482
  %t2484 = load i8, i8* %t2483
  %t2485 = icmp eq i8 %t2484, 0
  br i1 %t2485, label %ht_probe_on_empty_575, label %ht_probe_check_occ_574
ht_probe_check_occ_574:
  %t2486 = icmp eq i8 %t2484, 1
  br i1 %t2486, label %ht_probe_on_occ_578, label %ht_probe_on_tomb_580
ht_probe_on_empty_575:
  %t2487 = load i1, i1* %t2479
  br i1 %t2487, label %ht_probe_after_islot_empty_577, label %ht_probe_set_islot_empty_576
ht_probe_set_islot_empty_576:
  store i64 %t2482, i64* %t2478
  store i1 true, i1* %t2479
  br label %ht_probe_after_islot_empty_577
ht_probe_after_islot_empty_577:
  br label %ht_probe_end_583
ht_probe_on_occ_578:
  %t2488 = getelementptr inbounds %Point, %Point* %t2467, i64 %t2482
  %t2489 = load %Point, %Point* %t2488
  %t2490 = call i1 @eq_s_Point(%Point %t2489, %Point %t2455)
  br i1 %t2490, label %ht_probe_on_match_579, label %ht_probe_next_582
ht_probe_on_match_579:
  store i1 true, i1* %t2476
  store i64 %t2482, i64* %t2477
  br label %ht_probe_end_583
ht_probe_on_tomb_580:
  %t2491 = load i1, i1* %t2479
  br i1 %t2491, label %ht_probe_next_582, label %ht_probe_set_islot_tomb_581
ht_probe_set_islot_tomb_581:
  store i64 %t2482, i64* %t2478
  store i1 true, i1* %t2479
  br label %ht_probe_next_582
ht_probe_next_582:
  %t2492 = add i64 %t2482, 1
  %t2493 = and i64 %t2492, %t2471
  store i64 %t2493, i64* %t2475
  %t2494 = add i64 %t2480, 1
  store i64 %t2494, i64* %t2474
  br label %ht_probe_cond_572
ht_probe_end_583:
  %t2495 = load i1, i1* %t2476
  %t2496 = load i64, i64* %t2477
  %t2497 = load i64, i64* %t2478
  %t2498 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.56, i64 0, i64 0
  %t2499 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.57, i64 0, i64 0
  %t2500 = select i1 %t2495, i8* %t2498, i8* %t2499
  %t2501 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.58, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t2501, i8* %t2500)
  %t2502 = load i8*, i8** %t1913
  call void @star_rc_release(i8* %t2502)
  %t2503 = load i8*, i8** %t1139
  call void @star_rc_release(i8* %t2503)
  %t2504 = load i8*, i8** %t862
  call void @star_rc_release(i8* %t2504)
  %t2505 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t2505)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_3_stri32(i8* %objp) {
entry:
  %t18 = alloca i64
  %t9 = bitcast i8* %objp to { i8**, i32*, i8*, i64, i64, i64 }*
  %t10 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t9, i32 0, i32 0
  %t11 = load i8**, i8*** %t10
  %t12 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t9, i32 0, i32 1
  %t13 = load i32*, i32** %t12
  %t14 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t9, i32 0, i32 2
  %t15 = load i8*, i8** %t14
  %t16 = getelementptr inbounds { i8**, i32*, i8*, i64, i64, i64 }, { i8**, i32*, i8*, i64, i64, i64 }* %t9, i32 0, i32 4
  %t17 = load i64, i64* %t16
  store i64 0, i64* %t18
  br label %map_release_cond_3
map_release_cond_3:
  %t19 = load i64, i64* %t18
  %t20 = icmp slt i64 %t19, %t17
  br i1 %t20, label %map_release_body_4, label %map_release_end_7
map_release_body_4:
  %t21 = getelementptr inbounds i8, i8* %t15, i64 %t19
  %t22 = load i8, i8* %t21
  %t23 = icmp eq i8 %t22, 1
  br i1 %t23, label %map_release_occ_5, label %map_release_next_6
map_release_occ_5:
  %t24 = getelementptr inbounds i8*, i8** %t11, i64 %t19
  %t25 = load i8*, i8** %t24
  call void @star_rc_release(i8* %t25)
  br label %map_release_next_6
map_release_next_6:
  %t26 = add i64 %t19, 1
  store i64 %t26, i64* %t18
  br label %map_release_cond_3
map_release_end_7:
  %t27 = bitcast i8** %t11 to i8*
  call void @free(i8* %t27)
  %t28 = bitcast i32* %t13 to i8*
  call void @free(i8* %t28)
  call void @free(i8* %t15)
  ret void
}


define i64 @hash_str(i8* %v) {
entry:
  %t141 = alloca i64
  %t144 = alloca i64
  store i64 -3750763034362895579, i64* %t141
  %t142 = call i32 @strlen(i8* %v)
  %t143 = zext i32 %t142 to i64
  store i64 0, i64* %t144
  br label %hash_str_cond_26
hash_str_cond_26:
  %t145 = load i64, i64* %t144
  %t146 = icmp slt i64 %t145, %t143
  br i1 %t146, label %hash_str_body_27, label %hash_str_end_28
hash_str_body_27:
  %t147 = getelementptr inbounds i8, i8* %v, i64 %t145
  %t148 = load i8, i8* %t147
  %t149 = zext i8 %t148 to i64
  %t150 = load i64, i64* %t141
  %t151 = xor i64 %t150, %t149
  %t152 = mul i64 %t151, 1099511628211
  store i64 %t152, i64* %t141
  %t153 = add i64 %t145, 1
  store i64 %t153, i64* %t144
  br label %hash_str_cond_26
hash_str_end_28:
  %t154 = load i64, i64* %t141
  ret i64 %t154
}


define i1 @eq_str(i8* %a, i8* %b) {
entry:
  %t182 = call i32 @strcmp(i8* %a, i8* %b)
  %t183 = icmp eq i32 %t182, 0
  ret i1 %t183
}


define void @set_release_i32(i8* %objp) {
entry:
  %t1144 = bitcast i8* %objp to { i32*, i8*, i64, i64, i64 }*
  %t1145 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1144, i32 0, i32 0
  %t1146 = load i32*, i32** %t1145
  %t1147 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1144, i32 0, i32 1
  %t1148 = load i8*, i8** %t1147
  %t1149 = getelementptr inbounds { i32*, i8*, i64, i64, i64 }, { i32*, i8*, i64, i64, i64 }* %t1144, i32 0, i32 3
  %t1150 = load i64, i64* %t1149
  %t1151 = bitcast i32* %t1146 to i8*
  call void @free(i8* %t1151)
  call void @free(i8* %t1148)
  ret void
}


define i64 @hash_i32(i32 %v) {
entry:
  %t1235 = alloca i64
  store i64 -3750763034362895579, i64* %t1235
  %t1236 = zext i32 %v to i64
  %t1237 = load i64, i64* %t1235
  %t1238 = xor i64 %t1237, %t1236
  %t1239 = mul i64 %t1238, 1099511628211
  store i64 %t1239, i64* %t1235
  %t1240 = load i64, i64* %t1235
  ret i64 %t1240
}


define i1 @eq_i32(i32 %a, i32 %b) {
entry:
  %t1265 = icmp eq i32 %a, %b
  ret i1 %t1265
}


define void @set_release_s_Point(i8* %objp) {
entry:
  %t1918 = bitcast i8* %objp to { %Point*, i8*, i64, i64, i64 }*
  %t1919 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1918, i32 0, i32 0
  %t1920 = load %Point*, %Point** %t1919
  %t1921 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1918, i32 0, i32 1
  %t1922 = load i8*, i8** %t1921
  %t1923 = getelementptr inbounds { %Point*, i8*, i64, i64, i64 }, { %Point*, i8*, i64, i64, i64 }* %t1918, i32 0, i32 3
  %t1924 = load i64, i64* %t1923
  %t1925 = bitcast %Point* %t1920 to i8*
  call void @free(i8* %t1925)
  call void @free(i8* %t1922)
  ret void
}


define i64 @hash_s_Point(%Point %v) {
entry:
  %t2013 = alloca i64
  store i64 -3750763034362895579, i64* %t2013
  %t2014 = extractvalue %Point %v, 0
  %t2015 = zext i32 %t2014 to i64
  %t2016 = load i64, i64* %t2013
  %t2017 = xor i64 %t2016, %t2015
  %t2018 = mul i64 %t2017, 1099511628211
  store i64 %t2018, i64* %t2013
  %t2019 = extractvalue %Point %v, 1
  %t2020 = zext i32 %t2019 to i64
  %t2021 = load i64, i64* %t2013
  %t2022 = xor i64 %t2021, %t2020
  %t2023 = mul i64 %t2022, 1099511628211
  store i64 %t2023, i64* %t2013
  %t2024 = load i64, i64* %t2013
  ret i64 %t2024
}


define i1 @eq_s_Point(%Point %a, %Point %b) {
entry:
  %t2049 = extractvalue %Point %a, 0
  %t2050 = extractvalue %Point %b, 0
  %t2051 = icmp eq i32 %t2049, %t2050
  %t2052 = extractvalue %Point %a, 1
  %t2053 = extractvalue %Point %b, 1
  %t2054 = icmp eq i32 %t2052, %t2053
  %t2055 = and i1 %t2051, %t2054
  ret i1 %t2055
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.2 = private unnamed_addr constant [25 x i8] c"len after 2 inserts: %d\0A\00"
@.str.3 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.4 = private unnamed_addr constant [11 x i8] c"alice: %d\0A\00"
@.str.5 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"alice: missing\00" }
@.str.6 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"carol\00" }
@.str.8 = private unnamed_addr constant [11 x i8] c"carol: %d\0A\00"
@.str.9 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"carol: missing\00" }
@.str.10 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.11 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.12 = private unnamed_addr constant [25 x i8] c"len after overwrite: %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alice\00" }
@.str.14 = private unnamed_addr constant [27 x i8] c"alice after overwrite: %d\0A\00"
@.str.15 = private unnamed_addr constant { i64, i8*, [15 x i8] } { i64 -1, i8* null, [15 x i8] c"alice: missing\00" }
@.str.16 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.17 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [18 x i8] c"contains bob: %s\0A\00"
@.str.21 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"bob\00" }
@.str.22 = private unnamed_addr constant [17 x i8] c"removed bob: %d\0A\00"
@.str.23 = private unnamed_addr constant { i64, i8*, [13 x i8] } { i64 -1, i8* null, [13 x i8] c"bob: missing\00" }
@.str.24 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.25 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.26 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.27 = private unnamed_addr constant [31 x i8] c"contains bob after remove: %s\0A\00"
@.str.28 = private unnamed_addr constant [22 x i8] c"len after remove: %d\0A\00"
@.str.29 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.30 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.31 = private unnamed_addr constant [20 x i8] c"insert 1 (new): %s\0A\00"
@.str.32 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.33 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.34 = private unnamed_addr constant [20 x i8] c"insert 2 (new): %s\0A\00"
@.str.35 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.36 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.37 = private unnamed_addr constant [20 x i8] c"insert 1 (dup): %s\0A\00"
@.str.38 = private unnamed_addr constant [13 x i8] c"set len: %d\0A\00"
@.str.39 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.40 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.41 = private unnamed_addr constant [16 x i8] c"contains 2: %s\0A\00"
@.str.42 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.43 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.44 = private unnamed_addr constant [14 x i8] c"remove 2: %s\0A\00"
@.str.45 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.46 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.47 = private unnamed_addr constant [29 x i8] c"contains 2 after remove: %s\0A\00"
@.str.48 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.49 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.50 = private unnamed_addr constant [20 x i8] c"remove 2 again: %s\0A\00"
@.str.51 = private unnamed_addr constant [27 x i8] c"set len after removes: %d\0A\00"
@.str.52 = private unnamed_addr constant [20 x i8] c"struct set len: %d\0A\00"
@.str.53 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.54 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.55 = private unnamed_addr constant [20 x i8] c"contains (1,2): %s\0A\00"
@.str.56 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.57 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.58 = private unnamed_addr constant [20 x i8] c"contains (9,9): %s\0A\00"
