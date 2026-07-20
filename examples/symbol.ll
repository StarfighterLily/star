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
%Option__i32 = type { i32, [1 x i64] }
define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i64
  %t7 = alloca i64
  %t32 = alloca i64
  %t37 = alloca i64
  %t62 = alloca i64
  %t67 = alloca i64
  %t113 = alloca i64
  %t115 = alloca i64
  %t131 = alloca i64
  %t164 = alloca i8*
  %t229 = alloca i64
  %t323 = alloca i64
  %t418 = alloca i64
  %t445 = alloca i64
  %t510 = alloca i64
  %t521 = alloca %Option__i32
  %t527 = alloca %Option__i32
  %t531 = alloca %Option__i32
  %t550 = alloca i8*
  %t599 = alloca i64
  %t626 = alloca i64
  %t627 = alloca i1
  %t698 = alloca i64
  %t725 = alloca i64
  %t726 = alloca i1
  %t797 = alloca i64
  %t824 = alloca i64
  %t825 = alloca i1
  %t863 = alloca i1
  %t868 = alloca i64
  %t902 = alloca i64
  %t903 = alloca i1
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.0, i64 0, i32 2, i64 0
  %t4 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t4, i32 -1)
  %t5 = load i64, i64* @sym.len
  %t6 = load i8**, i8*** @sym.data
  store i64 0, i64* %t7
  br label %sym_find_cond_0
sym_find_cond_0:
  %t8 = load i64, i64* %t7
  %t9 = icmp slt i64 %t8, %t5
  br i1 %t9, label %sym_find_body_1, label %sym_find_end_3
sym_find_body_1:
  %t10 = getelementptr inbounds i8*, i8** %t6, i64 %t8
  %t11 = load i8*, i8** %t10
  %t12 = call i32 @strcmp(i8* %t11, i8* %t3)
  %t13 = icmp eq i32 %t12, 0
  br i1 %t13, label %sym_find_end_3, label %sym_find_next_2
sym_find_next_2:
  %t14 = add i64 %t8, 1
  store i64 %t14, i64* %t7
  br label %sym_find_cond_0
sym_find_end_3:
  %t15 = load i64, i64* %t7
  %t16 = icmp slt i64 %t15, %t5
  br i1 %t16, label %sym_found_4, label %sym_notfound_5
sym_found_4:
  call void @star_rc_release(i8* %t3)
  br label %sym_done_6
sym_notfound_5:
  %t17 = load i64, i64* @sym.cap
  %t18 = icmp sge i64 %t5, %t17
  br i1 %t18, label %sym_grow_7, label %sym_store_8
sym_grow_7:
  %t19 = mul i64 %t17, 2
  %t20 = icmp sgt i64 %t19, 0
  %t21 = select i1 %t20, i64 %t19, i64 1
  %t22 = mul i64 %t21, 8
  %t23 = call i8* @malloc(i64 %t22)
  %t24 = bitcast i8* %t23 to i8**
  %t25 = icmp sgt i64 %t17, 0
  br i1 %t25, label %sym_copy_9, label %sym_after_copy_10
sym_copy_9:
  %t26 = mul i64 %t5, 8
  %t27 = bitcast i8** %t6 to i8*
  call i8* @memcpy(i8* %t23, i8* %t27, i64 %t26)
  call void @free(i8* %t27)
  br label %sym_after_copy_10
sym_after_copy_10:
  store i8** %t24, i8*** @sym.data
  store i64 %t21, i64* @sym.cap
  br label %sym_store_8
sym_store_8:
  %t28 = load i8**, i8*** @sym.data
  %t29 = getelementptr inbounds i8*, i8** %t28, i64 %t5
  store i8* %t3, i8** %t29
  %t30 = add i64 %t5, 1
  store i64 %t30, i64* @sym.len
  br label %sym_done_6
sym_done_6:
  %t31 = phi i64 [ %t15, %sym_found_4 ], [ %t5, %sym_store_8 ]
  call i32 @ReleaseSemaphore(i8* %t4, i32 1, i32* null)
  store i64 %t31, i64* %t2
  %t33 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t34 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t34, i32 -1)
  %t35 = load i64, i64* @sym.len
  %t36 = load i8**, i8*** @sym.data
  store i64 0, i64* %t37
  br label %sym_find_cond_11
sym_find_cond_11:
  %t38 = load i64, i64* %t37
  %t39 = icmp slt i64 %t38, %t35
  br i1 %t39, label %sym_find_body_12, label %sym_find_end_14
sym_find_body_12:
  %t40 = getelementptr inbounds i8*, i8** %t36, i64 %t38
  %t41 = load i8*, i8** %t40
  %t42 = call i32 @strcmp(i8* %t41, i8* %t33)
  %t43 = icmp eq i32 %t42, 0
  br i1 %t43, label %sym_find_end_14, label %sym_find_next_13
sym_find_next_13:
  %t44 = add i64 %t38, 1
  store i64 %t44, i64* %t37
  br label %sym_find_cond_11
sym_find_end_14:
  %t45 = load i64, i64* %t37
  %t46 = icmp slt i64 %t45, %t35
  br i1 %t46, label %sym_found_15, label %sym_notfound_16
sym_found_15:
  call void @star_rc_release(i8* %t33)
  br label %sym_done_17
sym_notfound_16:
  %t47 = load i64, i64* @sym.cap
  %t48 = icmp sge i64 %t35, %t47
  br i1 %t48, label %sym_grow_18, label %sym_store_19
sym_grow_18:
  %t49 = mul i64 %t47, 2
  %t50 = icmp sgt i64 %t49, 0
  %t51 = select i1 %t50, i64 %t49, i64 1
  %t52 = mul i64 %t51, 8
  %t53 = call i8* @malloc(i64 %t52)
  %t54 = bitcast i8* %t53 to i8**
  %t55 = icmp sgt i64 %t47, 0
  br i1 %t55, label %sym_copy_20, label %sym_after_copy_21
sym_copy_20:
  %t56 = mul i64 %t35, 8
  %t57 = bitcast i8** %t36 to i8*
  call i8* @memcpy(i8* %t53, i8* %t57, i64 %t56)
  call void @free(i8* %t57)
  br label %sym_after_copy_21
sym_after_copy_21:
  store i8** %t54, i8*** @sym.data
  store i64 %t51, i64* @sym.cap
  br label %sym_store_19
sym_store_19:
  %t58 = load i8**, i8*** @sym.data
  %t59 = getelementptr inbounds i8*, i8** %t58, i64 %t35
  store i8* %t33, i8** %t59
  %t60 = add i64 %t35, 1
  store i64 %t60, i64* @sym.len
  br label %sym_done_17
sym_done_17:
  %t61 = phi i64 [ %t45, %sym_found_15 ], [ %t35, %sym_store_19 ]
  call i32 @ReleaseSemaphore(i8* %t34, i32 1, i32* null)
  store i64 %t61, i64* %t32
  %t63 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t64 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t64, i32 -1)
  %t65 = load i64, i64* @sym.len
  %t66 = load i8**, i8*** @sym.data
  store i64 0, i64* %t67
  br label %sym_find_cond_22
sym_find_cond_22:
  %t68 = load i64, i64* %t67
  %t69 = icmp slt i64 %t68, %t65
  br i1 %t69, label %sym_find_body_23, label %sym_find_end_25
sym_find_body_23:
  %t70 = getelementptr inbounds i8*, i8** %t66, i64 %t68
  %t71 = load i8*, i8** %t70
  %t72 = call i32 @strcmp(i8* %t71, i8* %t63)
  %t73 = icmp eq i32 %t72, 0
  br i1 %t73, label %sym_find_end_25, label %sym_find_next_24
sym_find_next_24:
  %t74 = add i64 %t68, 1
  store i64 %t74, i64* %t67
  br label %sym_find_cond_22
sym_find_end_25:
  %t75 = load i64, i64* %t67
  %t76 = icmp slt i64 %t75, %t65
  br i1 %t76, label %sym_found_26, label %sym_notfound_27
sym_found_26:
  call void @star_rc_release(i8* %t63)
  br label %sym_done_28
sym_notfound_27:
  %t77 = load i64, i64* @sym.cap
  %t78 = icmp sge i64 %t65, %t77
  br i1 %t78, label %sym_grow_29, label %sym_store_30
sym_grow_29:
  %t79 = mul i64 %t77, 2
  %t80 = icmp sgt i64 %t79, 0
  %t81 = select i1 %t80, i64 %t79, i64 1
  %t82 = mul i64 %t81, 8
  %t83 = call i8* @malloc(i64 %t82)
  %t84 = bitcast i8* %t83 to i8**
  %t85 = icmp sgt i64 %t77, 0
  br i1 %t85, label %sym_copy_31, label %sym_after_copy_32
sym_copy_31:
  %t86 = mul i64 %t65, 8
  %t87 = bitcast i8** %t66 to i8*
  call i8* @memcpy(i8* %t83, i8* %t87, i64 %t86)
  call void @free(i8* %t87)
  br label %sym_after_copy_32
sym_after_copy_32:
  store i8** %t84, i8*** @sym.data
  store i64 %t81, i64* @sym.cap
  br label %sym_store_30
sym_store_30:
  %t88 = load i8**, i8*** @sym.data
  %t89 = getelementptr inbounds i8*, i8** %t88, i64 %t65
  store i8* %t63, i8** %t89
  %t90 = add i64 %t65, 1
  store i64 %t90, i64* @sym.len
  br label %sym_done_28
sym_done_28:
  %t91 = phi i64 [ %t75, %sym_found_26 ], [ %t65, %sym_store_30 ]
  call i32 @ReleaseSemaphore(i8* %t64, i32 1, i32* null)
  store i64 %t91, i64* %t62
  %t92 = load i64, i64* %t2
  %t93 = load i64, i64* %t32
  %t94 = icmp eq i64 %t92, %t93
  %t95 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t96 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t97 = select i1 %t94, i8* %t95, i8* %t96
  %t98 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t98, i8* %t97)
  %t99 = load i64, i64* %t2
  %t100 = load i64, i64* %t62
  %t101 = icmp eq i64 %t99, %t100
  %t102 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.6, i64 0, i64 0
  %t103 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.7, i64 0, i64 0
  %t104 = select i1 %t101, i8* %t102, i8* %t103
  %t105 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t105, i8* %t104)
  %t106 = load i64, i64* %t2
  %t107 = load i64, i64* %t62
  %t108 = icmp ne i64 %t106, %t107
  %t109 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.9, i64 0, i64 0
  %t110 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.10, i64 0, i64 0
  %t111 = select i1 %t108, i8* %t109, i8* %t110
  %t112 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t112, i8* %t111)
  %t114 = load i64, i64* %t2
  store i64 %t114, i64* %t113
  %t116 = load i64, i64* %t62
  store i64 %t116, i64* %t115
  %t117 = load i64, i64* %t113
  %t118 = sext i32 0 to i64
  %t119 = icmp eq i64 %t117, %t118
  %t120 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.12, i64 0, i64 0
  %t121 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.13, i64 0, i64 0
  %t122 = select i1 %t119, i8* %t120, i8* %t121
  %t123 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t123, i8* %t122)
  %t124 = load i64, i64* %t115
  %t125 = sext i32 1 to i64
  %t126 = icmp eq i64 %t124, %t125
  %t127 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.15, i64 0, i64 0
  %t128 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.16, i64 0, i64 0
  %t129 = select i1 %t126, i8* %t127, i8* %t128
  %t130 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t130, i8* %t129)
  %t132 = load i64, i64* %t115
  store i64 %t132, i64* %t131
  %t133 = load i64, i64* %t131
  %t134 = load i64, i64* %t62
  %t135 = icmp eq i64 %t133, %t134
  %t136 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.18, i64 0, i64 0
  %t137 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.19, i64 0, i64 0
  %t138 = select i1 %t135, i8* %t136, i8* %t137
  %t139 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.20, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t139, i8* %t138)
  %t140 = load i64, i64* %t2
  %t141 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t141, i32 -1)
  %t142 = load i64, i64* @sym.len
  %t143 = icmp sge i64 %t140, 0
  %t144 = icmp slt i64 %t140, %t142
  %t145 = and i1 %t143, %t144
  br i1 %t145, label %sym_name_ok_33, label %sym_name_oob_34
sym_name_ok_33:
  %t146 = load i8**, i8*** @sym.data
  %t147 = getelementptr inbounds i8*, i8** %t146, i64 %t140
  %t148 = load i8*, i8** %t147
  call void @star_rc_retain(i8* %t148)
  br label %sym_name_end_35
sym_name_oob_34:
  %t149 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t149
  br label %sym_name_end_35
sym_name_end_35:
  %t150 = phi i8* [ %t148, %sym_name_ok_33 ], [ %t149, %sym_name_oob_34 ]
  call i32 @ReleaseSemaphore(i8* %t141, i32 1, i32* null)
  call void @star_rc_release(i8* %t150)
  %t151 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.21, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t151, i8* %t150)
  %t152 = load i64, i64* %t62
  %t153 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t153, i32 -1)
  %t154 = load i64, i64* @sym.len
  %t155 = icmp sge i64 %t152, 0
  %t156 = icmp slt i64 %t152, %t154
  %t157 = and i1 %t155, %t156
  br i1 %t157, label %sym_name_ok_36, label %sym_name_oob_37
sym_name_ok_36:
  %t158 = load i8**, i8*** @sym.data
  %t159 = getelementptr inbounds i8*, i8** %t158, i64 %t152
  %t160 = load i8*, i8** %t159
  call void @star_rc_retain(i8* %t160)
  br label %sym_name_end_38
sym_name_oob_37:
  %t161 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t161
  br label %sym_name_end_38
sym_name_end_38:
  %t162 = phi i8* [ %t160, %sym_name_ok_36 ], [ %t161, %sym_name_oob_37 ]
  call i32 @ReleaseSemaphore(i8* %t153, i32 1, i32* null)
  call void @star_rc_release(i8* %t162)
  %t163 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.22, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t163, i8* %t162)
  store i8* null, i8** %t164
  %t165 = getelementptr i64, i64* null, i32 1
  %t166 = ptrtoint i64* %t165 to i64
  %t167 = getelementptr i32, i32* null, i32 1
  %t168 = ptrtoint i32* %t167 to i64
  %t169 = load i8*, i8** %t164
  %t170 = icmp eq i8* %t169, null
  br i1 %t170, label %map_cow_alloc_39, label %map_cow_check_40
map_cow_alloc_39:
  %t178 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t179 = call i8* @star_rc_alloc(i64 32, i8* %t178)
  %t180 = bitcast i8* %t179 to { i64*, i32*, i64, i64 }*
  %t181 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t180, i32 0, i32 0
  store i64* null, i64** %t181
  %t182 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t180, i32 0, i32 1
  store i32* null, i32** %t182
  %t183 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t180, i32 0, i32 2
  store i64 0, i64* %t183
  %t184 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t180, i32 0, i32 3
  store i64 0, i64* %t184
  store i8* %t179, i8** %t164
  br label %map_cow_done_41
map_cow_check_40:
  %t185 = getelementptr inbounds i8, i8* %t169, i64 -16
  %t186 = bitcast i8* %t185 to i64*
  %t187 = load atomic i64, i64* %t186 seq_cst, align 8
  %t188 = icmp eq i64 %t187, 1
  br i1 %t188, label %map_cow_done_41, label %map_cow_clone_42
map_cow_clone_42:
  %t189 = bitcast i8* %t169 to { i64*, i32*, i64, i64 }*
  %t190 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t189, i32 0, i32 0
  %t191 = load i64*, i64** %t190
  %t192 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t189, i32 0, i32 1
  %t193 = load i32*, i32** %t192
  %t194 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t189, i32 0, i32 2
  %t195 = load i64, i64* %t194
  %t196 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t189, i32 0, i32 3
  %t197 = load i64, i64* %t196
  %t198 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t199 = call i8* @star_rc_alloc(i64 32, i8* %t198)
  %t200 = bitcast i8* %t199 to { i64*, i32*, i64, i64 }*
  %t201 = mul i64 %t197, %t166
  %t202 = call i8* @malloc(i64 %t201)
  %t203 = bitcast i8* %t202 to i64*
  %t204 = mul i64 %t197, %t168
  %t205 = call i8* @malloc(i64 %t204)
  %t206 = bitcast i8* %t205 to i32*
  %t207 = icmp sgt i64 %t195, 0
  br i1 %t207, label %map_cow_copy_43, label %map_cow_after_copy_44
map_cow_copy_43:
  %t208 = mul i64 %t195, %t166
  %t209 = bitcast i64* %t191 to i8*
  call i8* @memcpy(i8* %t202, i8* %t209, i64 %t208)
  %t210 = mul i64 %t195, %t168
  %t211 = bitcast i32* %t193 to i8*
  call i8* @memcpy(i8* %t205, i8* %t211, i64 %t210)
  br label %map_cow_after_copy_44
map_cow_after_copy_44:
  %t212 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t200, i32 0, i32 0
  store i64* %t203, i64** %t212
  %t213 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t200, i32 0, i32 1
  store i32* %t206, i32** %t213
  %t214 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t200, i32 0, i32 2
  store i64 %t195, i64* %t214
  %t215 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t200, i32 0, i32 3
  store i64 %t197, i64* %t215
  call void @star_rc_release(i8* %t169)
  store i8* %t199, i8** %t164
  br label %map_cow_done_41
map_cow_done_41:
  %t216 = load i8*, i8** %t164
  %t217 = bitcast i8* %t216 to { i64*, i32*, i64, i64 }*
  %t218 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t217, i32 0, i32 0
  %t219 = load i64*, i64** %t218
  %t220 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t217, i32 0, i32 1
  %t221 = load i32*, i32** %t220
  %t222 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t217, i32 0, i32 2
  %t223 = load i64, i64* %t222
  %t224 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t217, i32 0, i32 3
  %t225 = load i64, i64* %t2
  %t226 = load i64, i64* %t222
  %t227 = load i64*, i64** %t218
  store i64 0, i64* %t229
  br label %map_find_cond_45
map_find_cond_45:
  %t230 = load i64, i64* %t229
  %t231 = icmp slt i64 %t230, %t226
  br i1 %t231, label %map_find_body_46, label %map_find_end_49
map_find_body_46:
  %t232 = getelementptr inbounds i64, i64* %t227, i64 %t230
  %t233 = load i64, i64* %t232
  br label %map_find_eq_check_47
map_find_eq_check_47:
  %t234 = call i1 @eq_symbol(i64 %t233, i64 %t225)
  br i1 %t234, label %map_find_end_49, label %map_find_next_48
map_find_next_48:
  %t235 = add i64 %t230, 1
  store i64 %t235, i64* %t229
  br label %map_find_cond_45
map_find_end_49:
  %t236 = load i64, i64* %t229
  %t237 = icmp slt i64 %t236, %t226
  br i1 %t237, label %map_insert_overwrite_50, label %map_insert_new_51
map_insert_overwrite_50:
  %t238 = load i32*, i32** %t220
  %t239 = getelementptr inbounds i32, i32* %t238, i64 %t236
  store i32 100, i32* %t239
  br label %map_insert_after_52
map_insert_new_51:
  %t240 = load i64, i64* %t224
  %t241 = icmp sge i64 %t226, %t240
  br i1 %t241, label %map_insert_grow_53, label %map_insert_store_54
map_insert_grow_53:
  %t242 = mul i64 %t240, 2
  %t243 = icmp sgt i64 %t242, 0
  %t244 = select i1 %t243, i64 %t242, i64 1
  %t245 = getelementptr i64, i64* null, i32 1
  %t246 = ptrtoint i64* %t245 to i64
  %t247 = mul i64 %t244, %t246
  %t248 = call i8* @malloc(i64 %t247)
  %t249 = bitcast i8* %t248 to i64*
  %t250 = getelementptr i32, i32* null, i32 1
  %t251 = ptrtoint i32* %t250 to i64
  %t252 = mul i64 %t244, %t251
  %t253 = call i8* @malloc(i64 %t252)
  %t254 = bitcast i8* %t253 to i32*
  %t255 = icmp sgt i64 %t240, 0
  br i1 %t255, label %map_insert_copy_55, label %map_insert_after_copy_56
map_insert_copy_55:
  %t256 = load i64*, i64** %t218
  %t257 = mul i64 %t226, %t246
  %t258 = bitcast i64* %t256 to i8*
  call i8* @memcpy(i8* %t248, i8* %t258, i64 %t257)
  call void @free(i8* %t258)
  %t259 = load i32*, i32** %t220
  %t260 = mul i64 %t226, %t251
  %t261 = bitcast i32* %t259 to i8*
  call i8* @memcpy(i8* %t253, i8* %t261, i64 %t260)
  call void @free(i8* %t261)
  br label %map_insert_after_copy_56
map_insert_after_copy_56:
  store i64* %t249, i64** %t218
  store i32* %t254, i32** %t220
  store i64 %t244, i64* %t224
  br label %map_insert_store_54
map_insert_store_54:
  %t262 = load i64*, i64** %t218
  %t263 = load i32*, i32** %t220
  %t264 = getelementptr inbounds i64, i64* %t262, i64 %t226
  store i64 %t225, i64* %t264
  %t265 = getelementptr inbounds i32, i32* %t263, i64 %t226
  store i32 100, i32* %t265
  %t266 = add i64 %t226, 1
  store i64 %t266, i64* %t222
  br label %map_insert_after_52
map_insert_after_52:
  %t267 = getelementptr i64, i64* null, i32 1
  %t268 = ptrtoint i64* %t267 to i64
  %t269 = getelementptr i32, i32* null, i32 1
  %t270 = ptrtoint i32* %t269 to i64
  %t271 = load i8*, i8** %t164
  %t272 = icmp eq i8* %t271, null
  br i1 %t272, label %map_cow_alloc_57, label %map_cow_check_58
map_cow_alloc_57:
  %t273 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t274 = call i8* @star_rc_alloc(i64 32, i8* %t273)
  %t275 = bitcast i8* %t274 to { i64*, i32*, i64, i64 }*
  %t276 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t275, i32 0, i32 0
  store i64* null, i64** %t276
  %t277 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t275, i32 0, i32 1
  store i32* null, i32** %t277
  %t278 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t275, i32 0, i32 2
  store i64 0, i64* %t278
  %t279 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t275, i32 0, i32 3
  store i64 0, i64* %t279
  store i8* %t274, i8** %t164
  br label %map_cow_done_59
map_cow_check_58:
  %t280 = getelementptr inbounds i8, i8* %t271, i64 -16
  %t281 = bitcast i8* %t280 to i64*
  %t282 = load atomic i64, i64* %t281 seq_cst, align 8
  %t283 = icmp eq i64 %t282, 1
  br i1 %t283, label %map_cow_done_59, label %map_cow_clone_60
map_cow_clone_60:
  %t284 = bitcast i8* %t271 to { i64*, i32*, i64, i64 }*
  %t285 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t284, i32 0, i32 0
  %t286 = load i64*, i64** %t285
  %t287 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t284, i32 0, i32 1
  %t288 = load i32*, i32** %t287
  %t289 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t284, i32 0, i32 2
  %t290 = load i64, i64* %t289
  %t291 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t284, i32 0, i32 3
  %t292 = load i64, i64* %t291
  %t293 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t294 = call i8* @star_rc_alloc(i64 32, i8* %t293)
  %t295 = bitcast i8* %t294 to { i64*, i32*, i64, i64 }*
  %t296 = mul i64 %t292, %t268
  %t297 = call i8* @malloc(i64 %t296)
  %t298 = bitcast i8* %t297 to i64*
  %t299 = mul i64 %t292, %t270
  %t300 = call i8* @malloc(i64 %t299)
  %t301 = bitcast i8* %t300 to i32*
  %t302 = icmp sgt i64 %t290, 0
  br i1 %t302, label %map_cow_copy_61, label %map_cow_after_copy_62
map_cow_copy_61:
  %t303 = mul i64 %t290, %t268
  %t304 = bitcast i64* %t286 to i8*
  call i8* @memcpy(i8* %t297, i8* %t304, i64 %t303)
  %t305 = mul i64 %t290, %t270
  %t306 = bitcast i32* %t288 to i8*
  call i8* @memcpy(i8* %t300, i8* %t306, i64 %t305)
  br label %map_cow_after_copy_62
map_cow_after_copy_62:
  %t307 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t295, i32 0, i32 0
  store i64* %t298, i64** %t307
  %t308 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t295, i32 0, i32 1
  store i32* %t301, i32** %t308
  %t309 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t295, i32 0, i32 2
  store i64 %t290, i64* %t309
  %t310 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t295, i32 0, i32 3
  store i64 %t292, i64* %t310
  call void @star_rc_release(i8* %t271)
  store i8* %t294, i8** %t164
  br label %map_cow_done_59
map_cow_done_59:
  %t311 = load i8*, i8** %t164
  %t312 = bitcast i8* %t311 to { i64*, i32*, i64, i64 }*
  %t313 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t312, i32 0, i32 0
  %t314 = load i64*, i64** %t313
  %t315 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t312, i32 0, i32 1
  %t316 = load i32*, i32** %t315
  %t317 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t312, i32 0, i32 2
  %t318 = load i64, i64* %t317
  %t319 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t312, i32 0, i32 3
  %t320 = load i64, i64* %t62
  %t321 = load i64, i64* %t317
  %t322 = load i64*, i64** %t313
  store i64 0, i64* %t323
  br label %map_find_cond_63
map_find_cond_63:
  %t324 = load i64, i64* %t323
  %t325 = icmp slt i64 %t324, %t321
  br i1 %t325, label %map_find_body_64, label %map_find_end_67
map_find_body_64:
  %t326 = getelementptr inbounds i64, i64* %t322, i64 %t324
  %t327 = load i64, i64* %t326
  br label %map_find_eq_check_65
map_find_eq_check_65:
  %t328 = call i1 @eq_symbol(i64 %t327, i64 %t320)
  br i1 %t328, label %map_find_end_67, label %map_find_next_66
map_find_next_66:
  %t329 = add i64 %t324, 1
  store i64 %t329, i64* %t323
  br label %map_find_cond_63
map_find_end_67:
  %t330 = load i64, i64* %t323
  %t331 = icmp slt i64 %t330, %t321
  br i1 %t331, label %map_insert_overwrite_68, label %map_insert_new_69
map_insert_overwrite_68:
  %t332 = load i32*, i32** %t315
  %t333 = getelementptr inbounds i32, i32* %t332, i64 %t330
  store i32 40, i32* %t333
  br label %map_insert_after_70
map_insert_new_69:
  %t334 = load i64, i64* %t319
  %t335 = icmp sge i64 %t321, %t334
  br i1 %t335, label %map_insert_grow_71, label %map_insert_store_72
map_insert_grow_71:
  %t336 = mul i64 %t334, 2
  %t337 = icmp sgt i64 %t336, 0
  %t338 = select i1 %t337, i64 %t336, i64 1
  %t339 = getelementptr i64, i64* null, i32 1
  %t340 = ptrtoint i64* %t339 to i64
  %t341 = mul i64 %t338, %t340
  %t342 = call i8* @malloc(i64 %t341)
  %t343 = bitcast i8* %t342 to i64*
  %t344 = getelementptr i32, i32* null, i32 1
  %t345 = ptrtoint i32* %t344 to i64
  %t346 = mul i64 %t338, %t345
  %t347 = call i8* @malloc(i64 %t346)
  %t348 = bitcast i8* %t347 to i32*
  %t349 = icmp sgt i64 %t334, 0
  br i1 %t349, label %map_insert_copy_73, label %map_insert_after_copy_74
map_insert_copy_73:
  %t350 = load i64*, i64** %t313
  %t351 = mul i64 %t321, %t340
  %t352 = bitcast i64* %t350 to i8*
  call i8* @memcpy(i8* %t342, i8* %t352, i64 %t351)
  call void @free(i8* %t352)
  %t353 = load i32*, i32** %t315
  %t354 = mul i64 %t321, %t345
  %t355 = bitcast i32* %t353 to i8*
  call i8* @memcpy(i8* %t347, i8* %t355, i64 %t354)
  call void @free(i8* %t355)
  br label %map_insert_after_copy_74
map_insert_after_copy_74:
  store i64* %t343, i64** %t313
  store i32* %t348, i32** %t315
  store i64 %t338, i64* %t319
  br label %map_insert_store_72
map_insert_store_72:
  %t356 = load i64*, i64** %t313
  %t357 = load i32*, i32** %t315
  %t358 = getelementptr inbounds i64, i64* %t356, i64 %t321
  store i64 %t320, i64* %t358
  %t359 = getelementptr inbounds i32, i32* %t357, i64 %t321
  store i32 40, i32* %t359
  %t360 = add i64 %t321, 1
  store i64 %t360, i64* %t317
  br label %map_insert_after_70
map_insert_after_70:
  %t361 = getelementptr i64, i64* null, i32 1
  %t362 = ptrtoint i64* %t361 to i64
  %t363 = getelementptr i32, i32* null, i32 1
  %t364 = ptrtoint i32* %t363 to i64
  %t365 = load i8*, i8** %t164
  %t366 = icmp eq i8* %t365, null
  br i1 %t366, label %map_cow_alloc_75, label %map_cow_check_76
map_cow_alloc_75:
  %t367 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t368 = call i8* @star_rc_alloc(i64 32, i8* %t367)
  %t369 = bitcast i8* %t368 to { i64*, i32*, i64, i64 }*
  %t370 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t369, i32 0, i32 0
  store i64* null, i64** %t370
  %t371 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t369, i32 0, i32 1
  store i32* null, i32** %t371
  %t372 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t369, i32 0, i32 2
  store i64 0, i64* %t372
  %t373 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t369, i32 0, i32 3
  store i64 0, i64* %t373
  store i8* %t368, i8** %t164
  br label %map_cow_done_77
map_cow_check_76:
  %t374 = getelementptr inbounds i8, i8* %t365, i64 -16
  %t375 = bitcast i8* %t374 to i64*
  %t376 = load atomic i64, i64* %t375 seq_cst, align 8
  %t377 = icmp eq i64 %t376, 1
  br i1 %t377, label %map_cow_done_77, label %map_cow_clone_78
map_cow_clone_78:
  %t378 = bitcast i8* %t365 to { i64*, i32*, i64, i64 }*
  %t379 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t378, i32 0, i32 0
  %t380 = load i64*, i64** %t379
  %t381 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t378, i32 0, i32 1
  %t382 = load i32*, i32** %t381
  %t383 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t378, i32 0, i32 2
  %t384 = load i64, i64* %t383
  %t385 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t378, i32 0, i32 3
  %t386 = load i64, i64* %t385
  %t387 = bitcast void (i8*)* @map_release_6_symboli32 to i8*
  %t388 = call i8* @star_rc_alloc(i64 32, i8* %t387)
  %t389 = bitcast i8* %t388 to { i64*, i32*, i64, i64 }*
  %t390 = mul i64 %t386, %t362
  %t391 = call i8* @malloc(i64 %t390)
  %t392 = bitcast i8* %t391 to i64*
  %t393 = mul i64 %t386, %t364
  %t394 = call i8* @malloc(i64 %t393)
  %t395 = bitcast i8* %t394 to i32*
  %t396 = icmp sgt i64 %t384, 0
  br i1 %t396, label %map_cow_copy_79, label %map_cow_after_copy_80
map_cow_copy_79:
  %t397 = mul i64 %t384, %t362
  %t398 = bitcast i64* %t380 to i8*
  call i8* @memcpy(i8* %t391, i8* %t398, i64 %t397)
  %t399 = mul i64 %t384, %t364
  %t400 = bitcast i32* %t382 to i8*
  call i8* @memcpy(i8* %t394, i8* %t400, i64 %t399)
  br label %map_cow_after_copy_80
map_cow_after_copy_80:
  %t401 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t389, i32 0, i32 0
  store i64* %t392, i64** %t401
  %t402 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t389, i32 0, i32 1
  store i32* %t395, i32** %t402
  %t403 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t389, i32 0, i32 2
  store i64 %t384, i64* %t403
  %t404 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t389, i32 0, i32 3
  store i64 %t386, i64* %t404
  call void @star_rc_release(i8* %t365)
  store i8* %t388, i8** %t164
  br label %map_cow_done_77
map_cow_done_77:
  %t405 = load i8*, i8** %t164
  %t406 = bitcast i8* %t405 to { i64*, i32*, i64, i64 }*
  %t407 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t406, i32 0, i32 0
  %t408 = load i64*, i64** %t407
  %t409 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t406, i32 0, i32 1
  %t410 = load i32*, i32** %t409
  %t411 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t406, i32 0, i32 2
  %t412 = load i64, i64* %t411
  %t413 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t406, i32 0, i32 3
  %t414 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.23, i64 0, i32 2, i64 0
  %t415 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t415, i32 -1)
  %t416 = load i64, i64* @sym.len
  %t417 = load i8**, i8*** @sym.data
  store i64 0, i64* %t418
  br label %sym_find_cond_81
sym_find_cond_81:
  %t419 = load i64, i64* %t418
  %t420 = icmp slt i64 %t419, %t416
  br i1 %t420, label %sym_find_body_82, label %sym_find_end_84
sym_find_body_82:
  %t421 = getelementptr inbounds i8*, i8** %t417, i64 %t419
  %t422 = load i8*, i8** %t421
  %t423 = call i32 @strcmp(i8* %t422, i8* %t414)
  %t424 = icmp eq i32 %t423, 0
  br i1 %t424, label %sym_find_end_84, label %sym_find_next_83
sym_find_next_83:
  %t425 = add i64 %t419, 1
  store i64 %t425, i64* %t418
  br label %sym_find_cond_81
sym_find_end_84:
  %t426 = load i64, i64* %t418
  %t427 = icmp slt i64 %t426, %t416
  br i1 %t427, label %sym_found_85, label %sym_notfound_86
sym_found_85:
  call void @star_rc_release(i8* %t414)
  br label %sym_done_87
sym_notfound_86:
  %t428 = load i64, i64* @sym.cap
  %t429 = icmp sge i64 %t416, %t428
  br i1 %t429, label %sym_grow_88, label %sym_store_89
sym_grow_88:
  %t430 = mul i64 %t428, 2
  %t431 = icmp sgt i64 %t430, 0
  %t432 = select i1 %t431, i64 %t430, i64 1
  %t433 = mul i64 %t432, 8
  %t434 = call i8* @malloc(i64 %t433)
  %t435 = bitcast i8* %t434 to i8**
  %t436 = icmp sgt i64 %t428, 0
  br i1 %t436, label %sym_copy_90, label %sym_after_copy_91
sym_copy_90:
  %t437 = mul i64 %t416, 8
  %t438 = bitcast i8** %t417 to i8*
  call i8* @memcpy(i8* %t434, i8* %t438, i64 %t437)
  call void @free(i8* %t438)
  br label %sym_after_copy_91
sym_after_copy_91:
  store i8** %t435, i8*** @sym.data
  store i64 %t432, i64* @sym.cap
  br label %sym_store_89
sym_store_89:
  %t439 = load i8**, i8*** @sym.data
  %t440 = getelementptr inbounds i8*, i8** %t439, i64 %t416
  store i8* %t414, i8** %t440
  %t441 = add i64 %t416, 1
  store i64 %t441, i64* @sym.len
  br label %sym_done_87
sym_done_87:
  %t442 = phi i64 [ %t426, %sym_found_85 ], [ %t416, %sym_store_89 ]
  call i32 @ReleaseSemaphore(i8* %t415, i32 1, i32* null)
  %t443 = load i64, i64* %t411
  %t444 = load i64*, i64** %t407
  store i64 0, i64* %t445
  br label %map_find_cond_92
map_find_cond_92:
  %t446 = load i64, i64* %t445
  %t447 = icmp slt i64 %t446, %t443
  br i1 %t447, label %map_find_body_93, label %map_find_end_96
map_find_body_93:
  %t448 = getelementptr inbounds i64, i64* %t444, i64 %t446
  %t449 = load i64, i64* %t448
  br label %map_find_eq_check_94
map_find_eq_check_94:
  %t450 = call i1 @eq_symbol(i64 %t449, i64 %t442)
  br i1 %t450, label %map_find_end_96, label %map_find_next_95
map_find_next_95:
  %t451 = add i64 %t446, 1
  store i64 %t451, i64* %t445
  br label %map_find_cond_92
map_find_end_96:
  %t452 = load i64, i64* %t445
  %t453 = icmp slt i64 %t452, %t443
  br i1 %t453, label %map_insert_overwrite_97, label %map_insert_new_98
map_insert_overwrite_97:
  %t454 = load i32*, i32** %t409
  %t455 = getelementptr inbounds i32, i32* %t454, i64 %t452
  store i32 80, i32* %t455
  br label %map_insert_after_99
map_insert_new_98:
  %t456 = load i64, i64* %t413
  %t457 = icmp sge i64 %t443, %t456
  br i1 %t457, label %map_insert_grow_100, label %map_insert_store_101
map_insert_grow_100:
  %t458 = mul i64 %t456, 2
  %t459 = icmp sgt i64 %t458, 0
  %t460 = select i1 %t459, i64 %t458, i64 1
  %t461 = getelementptr i64, i64* null, i32 1
  %t462 = ptrtoint i64* %t461 to i64
  %t463 = mul i64 %t460, %t462
  %t464 = call i8* @malloc(i64 %t463)
  %t465 = bitcast i8* %t464 to i64*
  %t466 = getelementptr i32, i32* null, i32 1
  %t467 = ptrtoint i32* %t466 to i64
  %t468 = mul i64 %t460, %t467
  %t469 = call i8* @malloc(i64 %t468)
  %t470 = bitcast i8* %t469 to i32*
  %t471 = icmp sgt i64 %t456, 0
  br i1 %t471, label %map_insert_copy_102, label %map_insert_after_copy_103
map_insert_copy_102:
  %t472 = load i64*, i64** %t407
  %t473 = mul i64 %t443, %t462
  %t474 = bitcast i64* %t472 to i8*
  call i8* @memcpy(i8* %t464, i8* %t474, i64 %t473)
  call void @free(i8* %t474)
  %t475 = load i32*, i32** %t409
  %t476 = mul i64 %t443, %t467
  %t477 = bitcast i32* %t475 to i8*
  call i8* @memcpy(i8* %t469, i8* %t477, i64 %t476)
  call void @free(i8* %t477)
  br label %map_insert_after_copy_103
map_insert_after_copy_103:
  store i64* %t465, i64** %t407
  store i32* %t470, i32** %t409
  store i64 %t460, i64* %t413
  br label %map_insert_store_101
map_insert_store_101:
  %t478 = load i64*, i64** %t407
  %t479 = load i32*, i32** %t409
  %t480 = getelementptr inbounds i64, i64* %t478, i64 %t443
  store i64 %t442, i64* %t480
  %t481 = getelementptr inbounds i32, i32* %t479, i64 %t443
  store i32 80, i32* %t481
  %t482 = add i64 %t443, 1
  store i64 %t482, i64* %t411
  br label %map_insert_after_99
map_insert_after_99:
  %t483 = load i8*, i8** %t164
  %t484 = icmp eq i8* %t483, null
  br i1 %t484, label %map_read_null_104, label %map_read_real_105
map_read_null_104:
  br label %map_read_end_106
map_read_real_105:
  %t485 = bitcast i8* %t483 to { i64*, i32*, i64, i64 }*
  %t486 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t485, i32 0, i32 0
  %t487 = load i64*, i64** %t486
  %t488 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t485, i32 0, i32 1
  %t489 = load i32*, i32** %t488
  %t490 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t485, i32 0, i32 2
  %t491 = load i64, i64* %t490
  br label %map_read_end_106
map_read_end_106:
  %t492 = phi i64* [ null, %map_read_null_104 ], [ %t487, %map_read_real_105 ]
  %t493 = phi i32* [ null, %map_read_null_104 ], [ %t489, %map_read_real_105 ]
  %t494 = phi i64 [ 0, %map_read_null_104 ], [ %t491, %map_read_real_105 ]
  %t495 = trunc i64 %t494 to i32
  %t496 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.24, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t496, i32 %t495)
  %t497 = load i64, i64* %t2
  %t498 = load i8*, i8** %t164
  %t499 = icmp eq i8* %t498, null
  br i1 %t499, label %map_read_null_107, label %map_read_real_108
map_read_null_107:
  br label %map_read_end_109
map_read_real_108:
  %t500 = bitcast i8* %t498 to { i64*, i32*, i64, i64 }*
  %t501 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t500, i32 0, i32 0
  %t502 = load i64*, i64** %t501
  %t503 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t500, i32 0, i32 1
  %t504 = load i32*, i32** %t503
  %t505 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t500, i32 0, i32 2
  %t506 = load i64, i64* %t505
  br label %map_read_end_109
map_read_end_109:
  %t507 = phi i64* [ null, %map_read_null_107 ], [ %t502, %map_read_real_108 ]
  %t508 = phi i32* [ null, %map_read_null_107 ], [ %t504, %map_read_real_108 ]
  %t509 = phi i64 [ 0, %map_read_null_107 ], [ %t506, %map_read_real_108 ]
  store i64 0, i64* %t510
  br label %map_find_cond_110
map_find_cond_110:
  %t511 = load i64, i64* %t510
  %t512 = icmp slt i64 %t511, %t509
  br i1 %t512, label %map_find_body_111, label %map_find_end_114
map_find_body_111:
  %t513 = getelementptr inbounds i64, i64* %t507, i64 %t511
  %t514 = load i64, i64* %t513
  br label %map_find_eq_check_112
map_find_eq_check_112:
  %t515 = call i1 @eq_symbol(i64 %t514, i64 %t497)
  br i1 %t515, label %map_find_end_114, label %map_find_next_113
map_find_next_113:
  %t516 = add i64 %t511, 1
  store i64 %t516, i64* %t510
  br label %map_find_cond_110
map_find_end_114:
  %t517 = load i64, i64* %t510
  %t518 = icmp slt i64 %t517, %t509
  br i1 %t518, label %map_get_some_115, label %map_get_none_116
map_get_some_115:
  %t519 = getelementptr inbounds i32, i32* %t508, i64 %t517
  %t520 = load i32, i32* %t519
  %t522 = getelementptr inbounds %Option__i32, %Option__i32* %t521, i32 0, i32 0
  store i32 1, i32* %t522
  %t523 = getelementptr inbounds %Option__i32, %Option__i32* %t521, i32 0, i32 1
  %t524 = bitcast [1 x i64]* %t523 to { i32 }*
  %t525 = getelementptr inbounds { i32 }, { i32 }* %t524, i32 0, i32 0
  store i32 %t520, i32* %t525
  %t526 = load %Option__i32, %Option__i32* %t521
  br label %map_get_end_117
map_get_none_116:
  %t528 = getelementptr inbounds %Option__i32, %Option__i32* %t527, i32 0, i32 0
  store i32 0, i32* %t528
  %t529 = load %Option__i32, %Option__i32* %t527
  br label %map_get_end_117
map_get_end_117:
  %t530 = phi %Option__i32 [ %t526, %map_get_some_115 ], [ %t529, %map_get_none_116 ]
  store %Option__i32 %t530, %Option__i32* %t531
  br label %match_scrutinee_533
match_scrutinee_533:
  %t537 = getelementptr inbounds %Option__i32, %Option__i32* %t531, i32 0, i32 0
  %t538 = load i32, i32* %t537
  %t536 = icmp eq i32 %t538, 1
  br i1 %t536, label %match_then_0_534, label %match_next_0_535
match_then_0_534:
  %t539 = getelementptr inbounds %Option__i32, %Option__i32* %t531, i32 0, i32 1
  %t540 = bitcast [1 x i64]* %t539 to { i32 }*
  %t541 = getelementptr inbounds { i32 }, { i32 }* %t540, i32 0, i32 0
  %t542 = load i32, i32* %t541
  %t543 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.25, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t543, i32 %t542)
  br label %match_end_532
match_next_0_535:
  %t547 = getelementptr inbounds %Option__i32, %Option__i32* %t531, i32 0, i32 0
  %t548 = load i32, i32* %t547
  %t546 = icmp eq i32 %t548, 0
  br i1 %t546, label %match_then_1_544, label %match_next_1_545
match_then_1_544:
  %t549 = getelementptr inbounds { i64, i8*, [18 x i8] }, { i64, i8*, [18 x i8] }* @.str.26, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t549)
  call i32 (i8*, ...) @printf(i8* %t549)
  br label %match_end_532
match_next_1_545:
  br label %match_end_532
match_end_532:
  store i8* null, i8** %t550
  %t551 = getelementptr i64, i64* null, i32 1
  %t552 = ptrtoint i64* %t551 to i64
  %t553 = load i8*, i8** %t550
  %t554 = icmp eq i8* %t553, null
  br i1 %t554, label %set_cow_alloc_118, label %set_cow_check_119
set_cow_alloc_118:
  %t559 = bitcast void (i8*)* @set_release_symbol to i8*
  %t560 = call i8* @star_rc_alloc(i64 24, i8* %t559)
  %t561 = bitcast i8* %t560 to { i64*, i64, i64 }*
  %t562 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t561, i32 0, i32 0
  store i64* null, i64** %t562
  %t563 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t561, i32 0, i32 1
  store i64 0, i64* %t563
  %t564 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t561, i32 0, i32 2
  store i64 0, i64* %t564
  store i8* %t560, i8** %t550
  br label %set_cow_done_120
set_cow_check_119:
  %t565 = getelementptr inbounds i8, i8* %t553, i64 -16
  %t566 = bitcast i8* %t565 to i64*
  %t567 = load atomic i64, i64* %t566 seq_cst, align 8
  %t568 = icmp eq i64 %t567, 1
  br i1 %t568, label %set_cow_done_120, label %set_cow_clone_121
set_cow_clone_121:
  %t569 = bitcast i8* %t553 to { i64*, i64, i64 }*
  %t570 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t569, i32 0, i32 0
  %t571 = load i64*, i64** %t570
  %t572 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t569, i32 0, i32 1
  %t573 = load i64, i64* %t572
  %t574 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t569, i32 0, i32 2
  %t575 = load i64, i64* %t574
  %t576 = bitcast void (i8*)* @set_release_symbol to i8*
  %t577 = call i8* @star_rc_alloc(i64 24, i8* %t576)
  %t578 = bitcast i8* %t577 to { i64*, i64, i64 }*
  %t579 = mul i64 %t575, %t552
  %t580 = call i8* @malloc(i64 %t579)
  %t581 = bitcast i8* %t580 to i64*
  %t582 = icmp sgt i64 %t573, 0
  br i1 %t582, label %set_cow_copy_122, label %set_cow_after_copy_123
set_cow_copy_122:
  %t583 = mul i64 %t573, %t552
  %t584 = bitcast i64* %t571 to i8*
  call i8* @memcpy(i8* %t580, i8* %t584, i64 %t583)
  br label %set_cow_after_copy_123
set_cow_after_copy_123:
  %t585 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t578, i32 0, i32 0
  store i64* %t581, i64** %t585
  %t586 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t578, i32 0, i32 1
  store i64 %t573, i64* %t586
  %t587 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t578, i32 0, i32 2
  store i64 %t575, i64* %t587
  call void @star_rc_release(i8* %t553)
  store i8* %t577, i8** %t550
  br label %set_cow_done_120
set_cow_done_120:
  %t588 = load i8*, i8** %t550
  %t589 = bitcast i8* %t588 to { i64*, i64, i64 }*
  %t590 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t589, i32 0, i32 0
  %t591 = load i64*, i64** %t590
  %t592 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t589, i32 0, i32 1
  %t593 = load i64, i64* %t592
  %t594 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t589, i32 0, i32 2
  %t595 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.27, i64 0, i32 2, i64 0
  %t596 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t596, i32 -1)
  %t597 = load i64, i64* @sym.len
  %t598 = load i8**, i8*** @sym.data
  store i64 0, i64* %t599
  br label %sym_find_cond_124
sym_find_cond_124:
  %t600 = load i64, i64* %t599
  %t601 = icmp slt i64 %t600, %t597
  br i1 %t601, label %sym_find_body_125, label %sym_find_end_127
sym_find_body_125:
  %t602 = getelementptr inbounds i8*, i8** %t598, i64 %t600
  %t603 = load i8*, i8** %t602
  %t604 = call i32 @strcmp(i8* %t603, i8* %t595)
  %t605 = icmp eq i32 %t604, 0
  br i1 %t605, label %sym_find_end_127, label %sym_find_next_126
sym_find_next_126:
  %t606 = add i64 %t600, 1
  store i64 %t606, i64* %t599
  br label %sym_find_cond_124
sym_find_end_127:
  %t607 = load i64, i64* %t599
  %t608 = icmp slt i64 %t607, %t597
  br i1 %t608, label %sym_found_128, label %sym_notfound_129
sym_found_128:
  call void @star_rc_release(i8* %t595)
  br label %sym_done_130
sym_notfound_129:
  %t609 = load i64, i64* @sym.cap
  %t610 = icmp sge i64 %t597, %t609
  br i1 %t610, label %sym_grow_131, label %sym_store_132
sym_grow_131:
  %t611 = mul i64 %t609, 2
  %t612 = icmp sgt i64 %t611, 0
  %t613 = select i1 %t612, i64 %t611, i64 1
  %t614 = mul i64 %t613, 8
  %t615 = call i8* @malloc(i64 %t614)
  %t616 = bitcast i8* %t615 to i8**
  %t617 = icmp sgt i64 %t609, 0
  br i1 %t617, label %sym_copy_133, label %sym_after_copy_134
sym_copy_133:
  %t618 = mul i64 %t597, 8
  %t619 = bitcast i8** %t598 to i8*
  call i8* @memcpy(i8* %t615, i8* %t619, i64 %t618)
  call void @free(i8* %t619)
  br label %sym_after_copy_134
sym_after_copy_134:
  store i8** %t616, i8*** @sym.data
  store i64 %t613, i64* @sym.cap
  br label %sym_store_132
sym_store_132:
  %t620 = load i8**, i8*** @sym.data
  %t621 = getelementptr inbounds i8*, i8** %t620, i64 %t597
  store i8* %t595, i8** %t621
  %t622 = add i64 %t597, 1
  store i64 %t622, i64* @sym.len
  br label %sym_done_130
sym_done_130:
  %t623 = phi i64 [ %t607, %sym_found_128 ], [ %t597, %sym_store_132 ]
  call i32 @ReleaseSemaphore(i8* %t596, i32 1, i32* null)
  %t624 = load i64, i64* %t592
  %t625 = load i64*, i64** %t590
  store i64 0, i64* %t626
  store i1 false, i1* %t627
  br label %find_cond_135
find_cond_135:
  %t628 = load i64, i64* %t626
  %t629 = icmp slt i64 %t628, %t624
  br i1 %t629, label %find_body_136, label %find_end_139
find_body_136:
  %t630 = getelementptr inbounds i64, i64* %t625, i64 %t628
  %t631 = load i64, i64* %t630
  br label %find_eq_check_137
find_eq_check_137:
  %t632 = call i1 @eq_symbol(i64 %t631, i64 %t623)
  br i1 %t632, label %find_end_139, label %find_next_138
find_next_138:
  %t633 = add i64 %t628, 1
  store i64 %t633, i64* %t626
  br label %find_cond_135
find_end_139:
  %t634 = load i64, i64* %t626
  %t635 = icmp slt i64 %t634, %t624
  br i1 %t635, label %set_insert_already_present_140, label %set_insert_do_141
set_insert_already_present_140:
  br label %set_insert_end_142
set_insert_do_141:
  %t636 = load i64, i64* %t594
  %t637 = load i64*, i64** %t590
  %t638 = icmp sge i64 %t624, %t636
  br i1 %t638, label %set_insert_grow_143, label %set_insert_store_144
set_insert_grow_143:
  %t639 = mul i64 %t636, 2
  %t640 = icmp sgt i64 %t639, 0
  %t641 = select i1 %t640, i64 %t639, i64 1
  %t642 = getelementptr i64, i64* null, i32 1
  %t643 = ptrtoint i64* %t642 to i64
  %t644 = mul i64 %t641, %t643
  %t645 = call i8* @malloc(i64 %t644)
  %t646 = bitcast i8* %t645 to i64*
  %t647 = icmp sgt i64 %t636, 0
  br i1 %t647, label %set_insert_copy_145, label %set_insert_after_copy_146
set_insert_copy_145:
  %t648 = mul i64 %t624, %t643
  %t649 = bitcast i64* %t637 to i8*
  call i8* @memcpy(i8* %t645, i8* %t649, i64 %t648)
  call void @free(i8* %t649)
  br label %set_insert_after_copy_146
set_insert_after_copy_146:
  store i64* %t646, i64** %t590
  store i64 %t641, i64* %t594
  br label %set_insert_store_144
set_insert_store_144:
  %t650 = load i64*, i64** %t590
  %t651 = getelementptr inbounds i64, i64* %t650, i64 %t624
  store i64 %t623, i64* %t651
  %t652 = add i64 %t624, 1
  store i64 %t652, i64* %t592
  br label %set_insert_end_142
set_insert_end_142:
  %t653 = phi i1 [ false, %set_insert_already_present_140 ], [ true, %set_insert_store_144 ]
  %t654 = getelementptr i64, i64* null, i32 1
  %t655 = ptrtoint i64* %t654 to i64
  %t656 = load i8*, i8** %t550
  %t657 = icmp eq i8* %t656, null
  br i1 %t657, label %set_cow_alloc_147, label %set_cow_check_148
set_cow_alloc_147:
  %t658 = bitcast void (i8*)* @set_release_symbol to i8*
  %t659 = call i8* @star_rc_alloc(i64 24, i8* %t658)
  %t660 = bitcast i8* %t659 to { i64*, i64, i64 }*
  %t661 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t660, i32 0, i32 0
  store i64* null, i64** %t661
  %t662 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t660, i32 0, i32 1
  store i64 0, i64* %t662
  %t663 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t660, i32 0, i32 2
  store i64 0, i64* %t663
  store i8* %t659, i8** %t550
  br label %set_cow_done_149
set_cow_check_148:
  %t664 = getelementptr inbounds i8, i8* %t656, i64 -16
  %t665 = bitcast i8* %t664 to i64*
  %t666 = load atomic i64, i64* %t665 seq_cst, align 8
  %t667 = icmp eq i64 %t666, 1
  br i1 %t667, label %set_cow_done_149, label %set_cow_clone_150
set_cow_clone_150:
  %t668 = bitcast i8* %t656 to { i64*, i64, i64 }*
  %t669 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t668, i32 0, i32 0
  %t670 = load i64*, i64** %t669
  %t671 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t668, i32 0, i32 1
  %t672 = load i64, i64* %t671
  %t673 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t668, i32 0, i32 2
  %t674 = load i64, i64* %t673
  %t675 = bitcast void (i8*)* @set_release_symbol to i8*
  %t676 = call i8* @star_rc_alloc(i64 24, i8* %t675)
  %t677 = bitcast i8* %t676 to { i64*, i64, i64 }*
  %t678 = mul i64 %t674, %t655
  %t679 = call i8* @malloc(i64 %t678)
  %t680 = bitcast i8* %t679 to i64*
  %t681 = icmp sgt i64 %t672, 0
  br i1 %t681, label %set_cow_copy_151, label %set_cow_after_copy_152
set_cow_copy_151:
  %t682 = mul i64 %t672, %t655
  %t683 = bitcast i64* %t670 to i8*
  call i8* @memcpy(i8* %t679, i8* %t683, i64 %t682)
  br label %set_cow_after_copy_152
set_cow_after_copy_152:
  %t684 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 0
  store i64* %t680, i64** %t684
  %t685 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 1
  store i64 %t672, i64* %t685
  %t686 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t677, i32 0, i32 2
  store i64 %t674, i64* %t686
  call void @star_rc_release(i8* %t656)
  store i8* %t676, i8** %t550
  br label %set_cow_done_149
set_cow_done_149:
  %t687 = load i8*, i8** %t550
  %t688 = bitcast i8* %t687 to { i64*, i64, i64 }*
  %t689 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t688, i32 0, i32 0
  %t690 = load i64*, i64** %t689
  %t691 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t688, i32 0, i32 1
  %t692 = load i64, i64* %t691
  %t693 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t688, i32 0, i32 2
  %t694 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.28, i64 0, i32 2, i64 0
  %t695 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t695, i32 -1)
  %t696 = load i64, i64* @sym.len
  %t697 = load i8**, i8*** @sym.data
  store i64 0, i64* %t698
  br label %sym_find_cond_153
sym_find_cond_153:
  %t699 = load i64, i64* %t698
  %t700 = icmp slt i64 %t699, %t696
  br i1 %t700, label %sym_find_body_154, label %sym_find_end_156
sym_find_body_154:
  %t701 = getelementptr inbounds i8*, i8** %t697, i64 %t699
  %t702 = load i8*, i8** %t701
  %t703 = call i32 @strcmp(i8* %t702, i8* %t694)
  %t704 = icmp eq i32 %t703, 0
  br i1 %t704, label %sym_find_end_156, label %sym_find_next_155
sym_find_next_155:
  %t705 = add i64 %t699, 1
  store i64 %t705, i64* %t698
  br label %sym_find_cond_153
sym_find_end_156:
  %t706 = load i64, i64* %t698
  %t707 = icmp slt i64 %t706, %t696
  br i1 %t707, label %sym_found_157, label %sym_notfound_158
sym_found_157:
  call void @star_rc_release(i8* %t694)
  br label %sym_done_159
sym_notfound_158:
  %t708 = load i64, i64* @sym.cap
  %t709 = icmp sge i64 %t696, %t708
  br i1 %t709, label %sym_grow_160, label %sym_store_161
sym_grow_160:
  %t710 = mul i64 %t708, 2
  %t711 = icmp sgt i64 %t710, 0
  %t712 = select i1 %t711, i64 %t710, i64 1
  %t713 = mul i64 %t712, 8
  %t714 = call i8* @malloc(i64 %t713)
  %t715 = bitcast i8* %t714 to i8**
  %t716 = icmp sgt i64 %t708, 0
  br i1 %t716, label %sym_copy_162, label %sym_after_copy_163
sym_copy_162:
  %t717 = mul i64 %t696, 8
  %t718 = bitcast i8** %t697 to i8*
  call i8* @memcpy(i8* %t714, i8* %t718, i64 %t717)
  call void @free(i8* %t718)
  br label %sym_after_copy_163
sym_after_copy_163:
  store i8** %t715, i8*** @sym.data
  store i64 %t712, i64* @sym.cap
  br label %sym_store_161
sym_store_161:
  %t719 = load i8**, i8*** @sym.data
  %t720 = getelementptr inbounds i8*, i8** %t719, i64 %t696
  store i8* %t694, i8** %t720
  %t721 = add i64 %t696, 1
  store i64 %t721, i64* @sym.len
  br label %sym_done_159
sym_done_159:
  %t722 = phi i64 [ %t706, %sym_found_157 ], [ %t696, %sym_store_161 ]
  call i32 @ReleaseSemaphore(i8* %t695, i32 1, i32* null)
  %t723 = load i64, i64* %t691
  %t724 = load i64*, i64** %t689
  store i64 0, i64* %t725
  store i1 false, i1* %t726
  br label %find_cond_164
find_cond_164:
  %t727 = load i64, i64* %t725
  %t728 = icmp slt i64 %t727, %t723
  br i1 %t728, label %find_body_165, label %find_end_168
find_body_165:
  %t729 = getelementptr inbounds i64, i64* %t724, i64 %t727
  %t730 = load i64, i64* %t729
  br label %find_eq_check_166
find_eq_check_166:
  %t731 = call i1 @eq_symbol(i64 %t730, i64 %t722)
  br i1 %t731, label %find_end_168, label %find_next_167
find_next_167:
  %t732 = add i64 %t727, 1
  store i64 %t732, i64* %t725
  br label %find_cond_164
find_end_168:
  %t733 = load i64, i64* %t725
  %t734 = icmp slt i64 %t733, %t723
  br i1 %t734, label %set_insert_already_present_169, label %set_insert_do_170
set_insert_already_present_169:
  br label %set_insert_end_171
set_insert_do_170:
  %t735 = load i64, i64* %t693
  %t736 = load i64*, i64** %t689
  %t737 = icmp sge i64 %t723, %t735
  br i1 %t737, label %set_insert_grow_172, label %set_insert_store_173
set_insert_grow_172:
  %t738 = mul i64 %t735, 2
  %t739 = icmp sgt i64 %t738, 0
  %t740 = select i1 %t739, i64 %t738, i64 1
  %t741 = getelementptr i64, i64* null, i32 1
  %t742 = ptrtoint i64* %t741 to i64
  %t743 = mul i64 %t740, %t742
  %t744 = call i8* @malloc(i64 %t743)
  %t745 = bitcast i8* %t744 to i64*
  %t746 = icmp sgt i64 %t735, 0
  br i1 %t746, label %set_insert_copy_174, label %set_insert_after_copy_175
set_insert_copy_174:
  %t747 = mul i64 %t723, %t742
  %t748 = bitcast i64* %t736 to i8*
  call i8* @memcpy(i8* %t744, i8* %t748, i64 %t747)
  call void @free(i8* %t748)
  br label %set_insert_after_copy_175
set_insert_after_copy_175:
  store i64* %t745, i64** %t689
  store i64 %t740, i64* %t693
  br label %set_insert_store_173
set_insert_store_173:
  %t749 = load i64*, i64** %t689
  %t750 = getelementptr inbounds i64, i64* %t749, i64 %t723
  store i64 %t722, i64* %t750
  %t751 = add i64 %t723, 1
  store i64 %t751, i64* %t691
  br label %set_insert_end_171
set_insert_end_171:
  %t752 = phi i1 [ false, %set_insert_already_present_169 ], [ true, %set_insert_store_173 ]
  %t753 = getelementptr i64, i64* null, i32 1
  %t754 = ptrtoint i64* %t753 to i64
  %t755 = load i8*, i8** %t550
  %t756 = icmp eq i8* %t755, null
  br i1 %t756, label %set_cow_alloc_176, label %set_cow_check_177
set_cow_alloc_176:
  %t757 = bitcast void (i8*)* @set_release_symbol to i8*
  %t758 = call i8* @star_rc_alloc(i64 24, i8* %t757)
  %t759 = bitcast i8* %t758 to { i64*, i64, i64 }*
  %t760 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t759, i32 0, i32 0
  store i64* null, i64** %t760
  %t761 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t759, i32 0, i32 1
  store i64 0, i64* %t761
  %t762 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t759, i32 0, i32 2
  store i64 0, i64* %t762
  store i8* %t758, i8** %t550
  br label %set_cow_done_178
set_cow_check_177:
  %t763 = getelementptr inbounds i8, i8* %t755, i64 -16
  %t764 = bitcast i8* %t763 to i64*
  %t765 = load atomic i64, i64* %t764 seq_cst, align 8
  %t766 = icmp eq i64 %t765, 1
  br i1 %t766, label %set_cow_done_178, label %set_cow_clone_179
set_cow_clone_179:
  %t767 = bitcast i8* %t755 to { i64*, i64, i64 }*
  %t768 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t767, i32 0, i32 0
  %t769 = load i64*, i64** %t768
  %t770 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t767, i32 0, i32 1
  %t771 = load i64, i64* %t770
  %t772 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t767, i32 0, i32 2
  %t773 = load i64, i64* %t772
  %t774 = bitcast void (i8*)* @set_release_symbol to i8*
  %t775 = call i8* @star_rc_alloc(i64 24, i8* %t774)
  %t776 = bitcast i8* %t775 to { i64*, i64, i64 }*
  %t777 = mul i64 %t773, %t754
  %t778 = call i8* @malloc(i64 %t777)
  %t779 = bitcast i8* %t778 to i64*
  %t780 = icmp sgt i64 %t771, 0
  br i1 %t780, label %set_cow_copy_180, label %set_cow_after_copy_181
set_cow_copy_180:
  %t781 = mul i64 %t771, %t754
  %t782 = bitcast i64* %t769 to i8*
  call i8* @memcpy(i8* %t778, i8* %t782, i64 %t781)
  br label %set_cow_after_copy_181
set_cow_after_copy_181:
  %t783 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t776, i32 0, i32 0
  store i64* %t779, i64** %t783
  %t784 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t776, i32 0, i32 1
  store i64 %t771, i64* %t784
  %t785 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t776, i32 0, i32 2
  store i64 %t773, i64* %t785
  call void @star_rc_release(i8* %t755)
  store i8* %t775, i8** %t550
  br label %set_cow_done_178
set_cow_done_178:
  %t786 = load i8*, i8** %t550
  %t787 = bitcast i8* %t786 to { i64*, i64, i64 }*
  %t788 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t787, i32 0, i32 0
  %t789 = load i64*, i64** %t788
  %t790 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t787, i32 0, i32 1
  %t791 = load i64, i64* %t790
  %t792 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t787, i32 0, i32 2
  %t793 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.29, i64 0, i32 2, i64 0
  %t794 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t794, i32 -1)
  %t795 = load i64, i64* @sym.len
  %t796 = load i8**, i8*** @sym.data
  store i64 0, i64* %t797
  br label %sym_find_cond_182
sym_find_cond_182:
  %t798 = load i64, i64* %t797
  %t799 = icmp slt i64 %t798, %t795
  br i1 %t799, label %sym_find_body_183, label %sym_find_end_185
sym_find_body_183:
  %t800 = getelementptr inbounds i8*, i8** %t796, i64 %t798
  %t801 = load i8*, i8** %t800
  %t802 = call i32 @strcmp(i8* %t801, i8* %t793)
  %t803 = icmp eq i32 %t802, 0
  br i1 %t803, label %sym_find_end_185, label %sym_find_next_184
sym_find_next_184:
  %t804 = add i64 %t798, 1
  store i64 %t804, i64* %t797
  br label %sym_find_cond_182
sym_find_end_185:
  %t805 = load i64, i64* %t797
  %t806 = icmp slt i64 %t805, %t795
  br i1 %t806, label %sym_found_186, label %sym_notfound_187
sym_found_186:
  call void @star_rc_release(i8* %t793)
  br label %sym_done_188
sym_notfound_187:
  %t807 = load i64, i64* @sym.cap
  %t808 = icmp sge i64 %t795, %t807
  br i1 %t808, label %sym_grow_189, label %sym_store_190
sym_grow_189:
  %t809 = mul i64 %t807, 2
  %t810 = icmp sgt i64 %t809, 0
  %t811 = select i1 %t810, i64 %t809, i64 1
  %t812 = mul i64 %t811, 8
  %t813 = call i8* @malloc(i64 %t812)
  %t814 = bitcast i8* %t813 to i8**
  %t815 = icmp sgt i64 %t807, 0
  br i1 %t815, label %sym_copy_191, label %sym_after_copy_192
sym_copy_191:
  %t816 = mul i64 %t795, 8
  %t817 = bitcast i8** %t796 to i8*
  call i8* @memcpy(i8* %t813, i8* %t817, i64 %t816)
  call void @free(i8* %t817)
  br label %sym_after_copy_192
sym_after_copy_192:
  store i8** %t814, i8*** @sym.data
  store i64 %t811, i64* @sym.cap
  br label %sym_store_190
sym_store_190:
  %t818 = load i8**, i8*** @sym.data
  %t819 = getelementptr inbounds i8*, i8** %t818, i64 %t795
  store i8* %t793, i8** %t819
  %t820 = add i64 %t795, 1
  store i64 %t820, i64* @sym.len
  br label %sym_done_188
sym_done_188:
  %t821 = phi i64 [ %t805, %sym_found_186 ], [ %t795, %sym_store_190 ]
  call i32 @ReleaseSemaphore(i8* %t794, i32 1, i32* null)
  %t822 = load i64, i64* %t790
  %t823 = load i64*, i64** %t788
  store i64 0, i64* %t824
  store i1 false, i1* %t825
  br label %find_cond_193
find_cond_193:
  %t826 = load i64, i64* %t824
  %t827 = icmp slt i64 %t826, %t822
  br i1 %t827, label %find_body_194, label %find_end_197
find_body_194:
  %t828 = getelementptr inbounds i64, i64* %t823, i64 %t826
  %t829 = load i64, i64* %t828
  br label %find_eq_check_195
find_eq_check_195:
  %t830 = call i1 @eq_symbol(i64 %t829, i64 %t821)
  br i1 %t830, label %find_end_197, label %find_next_196
find_next_196:
  %t831 = add i64 %t826, 1
  store i64 %t831, i64* %t824
  br label %find_cond_193
find_end_197:
  %t832 = load i64, i64* %t824
  %t833 = icmp slt i64 %t832, %t822
  br i1 %t833, label %set_insert_already_present_198, label %set_insert_do_199
set_insert_already_present_198:
  br label %set_insert_end_200
set_insert_do_199:
  %t834 = load i64, i64* %t792
  %t835 = load i64*, i64** %t788
  %t836 = icmp sge i64 %t822, %t834
  br i1 %t836, label %set_insert_grow_201, label %set_insert_store_202
set_insert_grow_201:
  %t837 = mul i64 %t834, 2
  %t838 = icmp sgt i64 %t837, 0
  %t839 = select i1 %t838, i64 %t837, i64 1
  %t840 = getelementptr i64, i64* null, i32 1
  %t841 = ptrtoint i64* %t840 to i64
  %t842 = mul i64 %t839, %t841
  %t843 = call i8* @malloc(i64 %t842)
  %t844 = bitcast i8* %t843 to i64*
  %t845 = icmp sgt i64 %t834, 0
  br i1 %t845, label %set_insert_copy_203, label %set_insert_after_copy_204
set_insert_copy_203:
  %t846 = mul i64 %t822, %t841
  %t847 = bitcast i64* %t835 to i8*
  call i8* @memcpy(i8* %t843, i8* %t847, i64 %t846)
  call void @free(i8* %t847)
  br label %set_insert_after_copy_204
set_insert_after_copy_204:
  store i64* %t844, i64** %t788
  store i64 %t839, i64* %t792
  br label %set_insert_store_202
set_insert_store_202:
  %t848 = load i64*, i64** %t788
  %t849 = getelementptr inbounds i64, i64* %t848, i64 %t822
  store i64 %t821, i64* %t849
  %t850 = add i64 %t822, 1
  store i64 %t850, i64* %t790
  br label %set_insert_end_200
set_insert_end_200:
  %t851 = phi i1 [ false, %set_insert_already_present_198 ], [ true, %set_insert_store_202 ]
  %t852 = load i8*, i8** %t550
  %t853 = icmp eq i8* %t852, null
  br i1 %t853, label %set_read_null_205, label %set_read_real_206
set_read_null_205:
  br label %set_read_end_207
set_read_real_206:
  %t854 = bitcast i8* %t852 to { i64*, i64, i64 }*
  %t855 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t854, i32 0, i32 0
  %t856 = load i64*, i64** %t855
  %t857 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t854, i32 0, i32 1
  %t858 = load i64, i64* %t857
  br label %set_read_end_207
set_read_end_207:
  %t859 = phi i64* [ null, %set_read_null_205 ], [ %t856, %set_read_real_206 ]
  %t860 = phi i64 [ 0, %set_read_null_205 ], [ %t858, %set_read_real_206 ]
  %t861 = trunc i64 %t860 to i32
  %t862 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.30, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t862, i32 %t861)
  %t864 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.31, i64 0, i32 2, i64 0
  %t865 = load i8*, i8** @sym.lock
  call i32 @WaitForSingleObject(i8* %t865, i32 -1)
  %t866 = load i64, i64* @sym.len
  %t867 = load i8**, i8*** @sym.data
  store i64 0, i64* %t868
  br label %sym_find_cond_208
sym_find_cond_208:
  %t869 = load i64, i64* %t868
  %t870 = icmp slt i64 %t869, %t866
  br i1 %t870, label %sym_find_body_209, label %sym_find_end_211
sym_find_body_209:
  %t871 = getelementptr inbounds i8*, i8** %t867, i64 %t869
  %t872 = load i8*, i8** %t871
  %t873 = call i32 @strcmp(i8* %t872, i8* %t864)
  %t874 = icmp eq i32 %t873, 0
  br i1 %t874, label %sym_find_end_211, label %sym_find_next_210
sym_find_next_210:
  %t875 = add i64 %t869, 1
  store i64 %t875, i64* %t868
  br label %sym_find_cond_208
sym_find_end_211:
  %t876 = load i64, i64* %t868
  %t877 = icmp slt i64 %t876, %t866
  br i1 %t877, label %sym_found_212, label %sym_notfound_213
sym_found_212:
  call void @star_rc_release(i8* %t864)
  br label %sym_done_214
sym_notfound_213:
  %t878 = load i64, i64* @sym.cap
  %t879 = icmp sge i64 %t866, %t878
  br i1 %t879, label %sym_grow_215, label %sym_store_216
sym_grow_215:
  %t880 = mul i64 %t878, 2
  %t881 = icmp sgt i64 %t880, 0
  %t882 = select i1 %t881, i64 %t880, i64 1
  %t883 = mul i64 %t882, 8
  %t884 = call i8* @malloc(i64 %t883)
  %t885 = bitcast i8* %t884 to i8**
  %t886 = icmp sgt i64 %t878, 0
  br i1 %t886, label %sym_copy_217, label %sym_after_copy_218
sym_copy_217:
  %t887 = mul i64 %t866, 8
  %t888 = bitcast i8** %t867 to i8*
  call i8* @memcpy(i8* %t884, i8* %t888, i64 %t887)
  call void @free(i8* %t888)
  br label %sym_after_copy_218
sym_after_copy_218:
  store i8** %t885, i8*** @sym.data
  store i64 %t882, i64* @sym.cap
  br label %sym_store_216
sym_store_216:
  %t889 = load i8**, i8*** @sym.data
  %t890 = getelementptr inbounds i8*, i8** %t889, i64 %t866
  store i8* %t864, i8** %t890
  %t891 = add i64 %t866, 1
  store i64 %t891, i64* @sym.len
  br label %sym_done_214
sym_done_214:
  %t892 = phi i64 [ %t876, %sym_found_212 ], [ %t866, %sym_store_216 ]
  call i32 @ReleaseSemaphore(i8* %t865, i32 1, i32* null)
  %t893 = load i8*, i8** %t550
  %t894 = icmp eq i8* %t893, null
  br i1 %t894, label %set_read_null_219, label %set_read_real_220
set_read_null_219:
  br label %set_read_end_221
set_read_real_220:
  %t895 = bitcast i8* %t893 to { i64*, i64, i64 }*
  %t896 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t895, i32 0, i32 0
  %t897 = load i64*, i64** %t896
  %t898 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t895, i32 0, i32 1
  %t899 = load i64, i64* %t898
  br label %set_read_end_221
set_read_end_221:
  %t900 = phi i64* [ null, %set_read_null_219 ], [ %t897, %set_read_real_220 ]
  %t901 = phi i64 [ 0, %set_read_null_219 ], [ %t899, %set_read_real_220 ]
  store i64 0, i64* %t902
  store i1 false, i1* %t903
  br label %find_cond_222
find_cond_222:
  %t904 = load i64, i64* %t902
  %t905 = icmp slt i64 %t904, %t901
  br i1 %t905, label %find_body_223, label %find_end_226
find_body_223:
  %t906 = getelementptr inbounds i64, i64* %t900, i64 %t904
  %t907 = load i64, i64* %t906
  br label %find_eq_check_224
find_eq_check_224:
  %t908 = call i1 @eq_symbol(i64 %t907, i64 %t892)
  br i1 %t908, label %find_end_226, label %find_next_225
find_next_225:
  %t909 = add i64 %t904, 1
  store i64 %t909, i64* %t902
  br label %find_cond_222
find_end_226:
  %t910 = load i64, i64* %t902
  %t911 = icmp slt i64 %t910, %t901
  store i1 %t911, i1* %t863
  %t912 = load i1, i1* %t863
  %t913 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.32, i64 0, i64 0
  %t914 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.33, i64 0, i64 0
  %t915 = select i1 %t912, i8* %t913, i8* %t914
  %t916 = getelementptr inbounds [29 x i8], [29 x i8]* @.str.34, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t916, i8* %t915)
  %t917 = load i8*, i8** %t550
  call void @star_rc_release(i8* %t917)
  %t918 = load i8*, i8** %t164
  call void @star_rc_release(i8* %t918)
  ret i32 0
}


; par/swarm worker functions
define void @map_release_6_symboli32(i8* %objp) {
entry:
  %t171 = bitcast i8* %objp to { i64*, i32*, i64, i64 }*
  %t172 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t171, i32 0, i32 0
  %t173 = load i64*, i64** %t172
  %t174 = getelementptr inbounds { i64*, i32*, i64, i64 }, { i64*, i32*, i64, i64 }* %t171, i32 0, i32 1
  %t175 = load i32*, i32** %t174
  %t176 = bitcast i64* %t173 to i8*
  call void @free(i8* %t176)
  %t177 = bitcast i32* %t175 to i8*
  call void @free(i8* %t177)
  ret void
}


define i1 @eq_symbol(i64 %a, i64 %b) {
entry:
  %t228 = icmp eq i64 %a, %b
  ret i1 %t228
}


define void @set_release_symbol(i8* %objp) {
entry:
  %t555 = bitcast i8* %objp to { i64*, i64, i64 }*
  %t556 = getelementptr inbounds { i64*, i64, i64 }, { i64*, i64, i64 }* %t555, i32 0, i32 0
  %t557 = load i64*, i64** %t556
  %t558 = bitcast i64* %t557 to i8*
  call void @free(i8* %t558)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"player\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"player\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"enemy\00" }
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [44 x i8] c"Symbol(\22player\22) == Symbol(\22player\22) is %s\0A\00"
@.str.6 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.7 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.8 = private unnamed_addr constant [43 x i8] c"Symbol(\22player\22) == Symbol(\22enemy\22) is %s\0A\00"
@.str.9 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.10 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.11 = private unnamed_addr constant [43 x i8] c"Symbol(\22player\22) != Symbol(\22enemy\22) is %s\0A\00"
@.str.12 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.13 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.14 = private unnamed_addr constant [17 x i8] c"a_id == 0 is %s\0A\00"
@.str.15 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.16 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.17 = private unnamed_addr constant [17 x i8] c"c_id == 1 is %s\0A\00"
@.str.18 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.19 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.20 = private unnamed_addr constant [29 x i8] c"(c_id as Symbol) == c is %s\0A\00"
@.str.21 = private unnamed_addr constant [21 x i8] c"symbol_name(a) = %s\0A\00"
@.str.22 = private unnamed_addr constant [21 x i8] c"symbol_name(c) = %s\0A\00"
@.str.23 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"player\00" }
@.str.24 = private unnamed_addr constant [15 x i8] c"hp.len() = %d\0A\00"
@.str.25 = private unnamed_addr constant [16 x i8] c"player hp = %d\0A\00"
@.str.26 = private unnamed_addr constant { i64, i8*, [18 x i8] } { i64 -1, i8* null, [18 x i8] c"player hp missing\00" }
@.str.27 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"flying\00" }
@.str.28 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"flying\00" }
@.str.29 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"armored\00" }
@.str.30 = private unnamed_addr constant [17 x i8] c"tags.len() = %d\0A\00"
@.str.31 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"flying\00" }
@.str.32 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.33 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.34 = private unnamed_addr constant [29 x i8] c"tags.contains(flying) is %s\0A\00"
