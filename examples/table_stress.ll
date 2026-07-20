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

%Item = type { i32, i8* }
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
  %t3 = alloca i32
  %t69 = alloca i64
  %t85 = alloca %Item
  %t156 = alloca %Item
  %t169 = alloca %Item
  %t186 = alloca %Item
  %t199 = alloca %Item
  %t216 = alloca %Item
  %t229 = alloca %Item
  %t246 = alloca %Item
  %t259 = alloca %Item
  %t263 = alloca i8*
  %t266 = alloca i32
  %t317 = alloca i64
  %t333 = alloca %Item
  %t417 = alloca %Item
  %t430 = alloca %Item
  %t447 = alloca %Item
  %t460 = alloca %Item
  %t478 = alloca %Item
  %t491 = alloca %Item
  %t508 = alloca %Item
  %t521 = alloca %Item
  %t526 = alloca i8*
  %t527 = alloca i32
  %t578 = alloca i64
  %t594 = alloca %Item
  %t645 = alloca %Item
  %t694 = alloca i64
  %t710 = alloca %Item
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i8* null, i8** %t2
  store i32 0, i32* %t3
  br label %while_cond_0
while_cond_0:
  %t4 = load i32, i32* %t3
  %t5 = icmp slt i32 %t4, 5000
  br i1 %t5, label %while_body_1, label %while_else_2
while_body_1:
  %t6 = load i8*, i8** %t2
  %t7 = icmp eq i8* %t6, null
  br i1 %t7, label %table_cow_alloc_4, label %table_cow_check_5
table_cow_alloc_4:
  %t23 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t24 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t25 = ptrtoint { i64, i64, i32*, i8** }* %t24 to i64
  %t26 = call i8* @star_rc_alloc(i64 %t25, i8* %t23)
  %t27 = bitcast i8* %t26 to { i64, i64, i32*, i8** }*
  %t28 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t27, i32 0, i32 0
  store i64 0, i64* %t28
  %t29 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t27, i32 0, i32 1
  store i64 0, i64* %t29
  %t30 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t27, i32 0, i32 2
  store i32* null, i32** %t30
  %t31 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t27, i32 0, i32 3
  store i8** null, i8*** %t31
  store i8* %t26, i8** %t2
  br label %table_cow_done_6
table_cow_check_5:
  %t32 = getelementptr inbounds i8, i8* %t6, i64 -16
  %t33 = bitcast i8* %t32 to i64*
  %t34 = load atomic i64, i64* %t33 seq_cst, align 8
  %t35 = icmp eq i64 %t34, 1
  br i1 %t35, label %table_cow_done_6, label %table_cow_clone_10
table_cow_clone_10:
  %t36 = bitcast i8* %t6 to { i64, i64, i32*, i8** }*
  %t37 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 0
  %t38 = load i64, i64* %t37
  %t39 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 1
  %t40 = load i64, i64* %t39
  %t41 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t42 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t43 = ptrtoint { i64, i64, i32*, i8** }* %t42 to i64
  %t44 = call i8* @star_rc_alloc(i64 %t43, i8* %t41)
  %t45 = bitcast i8* %t44 to { i64, i64, i32*, i8** }*
  %t46 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 0
  store i64 %t38, i64* %t46
  %t47 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 1
  store i64 %t40, i64* %t47
  %t48 = getelementptr i32, i32* null, i32 1
  %t49 = ptrtoint i32* %t48 to i64
  %t50 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 2
  %t51 = load i32*, i32** %t50
  %t52 = mul i64 %t40, %t49
  %t53 = call i8* @malloc(i64 %t52)
  %t54 = bitcast i8* %t53 to i32*
  %t55 = icmp sgt i64 %t38, 0
  br i1 %t55, label %table_cow_copy_11, label %table_cow_after_copy_12
table_cow_copy_11:
  %t56 = mul i64 %t38, %t49
  %t57 = bitcast i32* %t51 to i8*
  call i8* @memcpy(i8* %t53, i8* %t57, i64 %t56)
  br label %table_cow_after_copy_12
table_cow_after_copy_12:
  %t58 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 2
  store i32* %t54, i32** %t58
  %t59 = getelementptr i8*, i8** null, i32 1
  %t60 = ptrtoint i8** %t59 to i64
  %t61 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t36, i32 0, i32 3
  %t62 = load i8**, i8*** %t61
  %t63 = mul i64 %t40, %t60
  %t64 = call i8* @malloc(i64 %t63)
  %t65 = bitcast i8* %t64 to i8**
  %t66 = icmp sgt i64 %t38, 0
  br i1 %t66, label %table_cow_copy_13, label %table_cow_after_copy_14
table_cow_copy_13:
  %t67 = mul i64 %t38, %t60
  %t68 = bitcast i8** %t62 to i8*
  call i8* @memcpy(i8* %t64, i8* %t68, i64 %t67)
  store i64 0, i64* %t69
  br label %table_cow_retain_cond_15
table_cow_retain_cond_15:
  %t70 = load i64, i64* %t69
  %t71 = icmp slt i64 %t70, %t38
  br i1 %t71, label %table_cow_retain_body_16, label %table_cow_retain_end_17
table_cow_retain_body_16:
  %t72 = getelementptr inbounds i8*, i8** %t65, i64 %t70
  %t73 = load i8*, i8** %t72
  call void @star_rc_retain(i8* %t73)
  %t74 = add i64 %t70, 1
  store i64 %t74, i64* %t69
  br label %table_cow_retain_cond_15
table_cow_retain_end_17:
  br label %table_cow_after_copy_14
table_cow_after_copy_14:
  %t75 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t45, i32 0, i32 3
  store i8** %t65, i8*** %t75
  call void @star_rc_release(i8* %t6)
  store i8* %t44, i8** %t2
  br label %table_cow_done_6
table_cow_done_6:
  %t76 = load i8*, i8** %t2
  %t77 = bitcast i8* %t76 to { i64, i64, i32*, i8** }*
  %t78 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t77, i32 0, i32 0
  %t79 = load i64, i64* %t78
  %t80 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t77, i32 0, i32 1
  %t81 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t77, i32 0, i32 2
  %t82 = load i32*, i32** %t81
  %t83 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t77, i32 0, i32 3
  %t84 = load i8**, i8*** %t83
  %t86 = load i32, i32* %t3
  %t87 = getelementptr inbounds %Item, %Item* %t85, i32 0, i32 0
  store i32 %t86, i32* %t87
  %t88 = load i32, i32* %t3
  %t89 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.0, i64 0, i64 0
  %t90 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t89, i32 %t88)
  %t91 = add i32 %t90, 1
  %t92 = sext i32 %t91 to i64
  %t93 = call i8* @star_rc_alloc(i64 %t92, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t93, i64 %t92, i8* %t89, i32 %t88)
  %t94 = getelementptr inbounds %Item, %Item* %t85, i32 0, i32 1
  store i8* %t93, i8** %t94
  %t95 = load %Item, %Item* %t85
  %t96 = load i64, i64* %t80
  %t97 = load i64, i64* %t78
  %t98 = load i32*, i32** %t81
  %t99 = load i8**, i8*** %t83
  %t100 = icmp sge i64 %t97, %t96
  br i1 %t100, label %table_push_grow_18, label %table_push_store_19
table_push_grow_18:
  %t101 = mul i64 %t96, 2
  %t102 = icmp sgt i64 %t101, 0
  %t103 = select i1 %t102, i64 %t101, i64 1
  %t104 = getelementptr i32, i32* null, i32 1
  %t105 = ptrtoint i32* %t104 to i64
  %t106 = mul i64 %t103, %t105
  %t107 = call i8* @malloc(i64 %t106)
  %t108 = bitcast i8* %t107 to i32*
  %t109 = icmp sgt i64 %t96, 0
  br i1 %t109, label %table_push_copy_20, label %table_push_after_copy_21
table_push_copy_20:
  %t110 = mul i64 %t97, %t105
  %t111 = bitcast i32* %t98 to i8*
  call i8* @memcpy(i8* %t107, i8* %t111, i64 %t110)
  call void @free(i8* %t111)
  br label %table_push_after_copy_21
table_push_after_copy_21:
  store i32* %t108, i32** %t81
  %t112 = getelementptr i8*, i8** null, i32 1
  %t113 = ptrtoint i8** %t112 to i64
  %t114 = mul i64 %t103, %t113
  %t115 = call i8* @malloc(i64 %t114)
  %t116 = bitcast i8* %t115 to i8**
  %t117 = icmp sgt i64 %t96, 0
  br i1 %t117, label %table_push_copy_22, label %table_push_after_copy_23
table_push_copy_22:
  %t118 = mul i64 %t97, %t113
  %t119 = bitcast i8** %t99 to i8*
  call i8* @memcpy(i8* %t115, i8* %t119, i64 %t118)
  call void @free(i8* %t119)
  br label %table_push_after_copy_23
table_push_after_copy_23:
  store i8** %t116, i8*** %t83
  store i64 %t103, i64* %t80
  br label %table_push_store_19
table_push_store_19:
  %t120 = load i32*, i32** %t81
  %t121 = extractvalue %Item %t95, 0
  %t122 = getelementptr inbounds i32, i32* %t120, i64 %t97
  store i32 %t121, i32* %t122
  %t123 = load i8**, i8*** %t83
  %t124 = extractvalue %Item %t95, 1
  %t125 = getelementptr inbounds i8*, i8** %t123, i64 %t97
  store i8* %t124, i8** %t125
  %t126 = add i64 %t97, 1
  store i64 %t126, i64* %t78
  %t127 = load i32, i32* %t3
  %t128 = add i32 %t127, 1
  store i32 %t128, i32* %t3
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t129 = load i8*, i8** %t2
  %t130 = icmp eq i8* %t129, null
  br i1 %t130, label %table_read_null_24, label %table_read_real_25
table_read_null_24:
  br label %table_read_end_26
table_read_real_25:
  %t131 = bitcast i8* %t129 to { i64, i64, i32*, i8** }*
  %t132 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t131, i32 0, i32 0
  %t133 = load i64, i64* %t132
  %t134 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t131, i32 0, i32 2
  %t135 = load i32*, i32** %t134
  %t136 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t131, i32 0, i32 3
  %t137 = load i8**, i8*** %t136
  br label %table_read_end_26
table_read_end_26:
  %t138 = phi i64 [ 0, %table_read_null_24 ], [ %t133, %table_read_real_25 ]
  %t139 = phi i32* [ null, %table_read_null_24 ], [ %t135, %table_read_real_25 ]
  %t140 = phi i8** [ null, %table_read_null_24 ], [ %t137, %table_read_real_25 ]
  %t141 = trunc i64 %t138 to i32
  %t142 = getelementptr inbounds [10 x i8], [10 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t142, i32 %t141)
  %t143 = sext i32 0 to i64
  %t144 = load i8*, i8** %t2
  %t145 = icmp eq i8* %t144, null
  br i1 %t145, label %table_read_null_27, label %table_read_real_28
table_read_null_27:
  br label %table_read_end_29
table_read_real_28:
  %t146 = bitcast i8* %t144 to { i64, i64, i32*, i8** }*
  %t147 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t146, i32 0, i32 0
  %t148 = load i64, i64* %t147
  %t149 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t146, i32 0, i32 2
  %t150 = load i32*, i32** %t149
  %t151 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t146, i32 0, i32 3
  %t152 = load i8**, i8*** %t151
  br label %table_read_end_29
table_read_end_29:
  %t153 = phi i64 [ 0, %table_read_null_27 ], [ %t148, %table_read_real_28 ]
  %t154 = phi i32* [ null, %table_read_null_27 ], [ %t150, %table_read_real_28 ]
  %t155 = phi i8** [ null, %table_read_null_27 ], [ %t152, %table_read_real_28 ]
  %t157 = icmp ult i64 %t143, %t153
  br i1 %t157, label %table_idx_ok_30, label %table_idx_oob_31
table_idx_ok_30:
  %t158 = getelementptr inbounds i32, i32* %t154, i64 %t143
  %t159 = load i32, i32* %t158
  %t160 = getelementptr inbounds %Item, %Item* %t156, i32 0, i32 0
  store i32 %t159, i32* %t160
  %t161 = getelementptr inbounds i8*, i8** %t155, i64 %t143
  %t162 = load i8*, i8** %t161
  call void @star_rc_retain(i8* %t162)
  %t163 = load i8*, i8** %t161
  %t164 = getelementptr inbounds %Item, %Item* %t156, i32 0, i32 1
  store i8* %t163, i8** %t164
  br label %table_idx_end_32
table_idx_oob_31:
  %t165 = getelementptr inbounds %Item, %Item* %t156, i32 0, i32 0
  store i32 0, i32* %t165
  %t166 = getelementptr inbounds %Item, %Item* %t156, i32 0, i32 1
  %t167 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t167
  store i8* %t167, i8** %t166
  br label %table_idx_end_32
table_idx_end_32:
  %t168 = load %Item, %Item* %t156
  store %Item %t168, %Item* %t169
  %t170 = getelementptr inbounds %Item, %Item* %t169, i32 0, i32 1
  %t171 = load i8*, i8** %t170
  %t172 = load i8*, i8** %t170
  call void @star_rc_retain(i8* %t172)
  call void @star_rc_release(i8* %t171)
  %t173 = sext i32 0 to i64
  %t174 = load i8*, i8** %t2
  %t175 = icmp eq i8* %t174, null
  br i1 %t175, label %table_read_null_33, label %table_read_real_34
table_read_null_33:
  br label %table_read_end_35
table_read_real_34:
  %t176 = bitcast i8* %t174 to { i64, i64, i32*, i8** }*
  %t177 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t176, i32 0, i32 0
  %t178 = load i64, i64* %t177
  %t179 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t176, i32 0, i32 2
  %t180 = load i32*, i32** %t179
  %t181 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t176, i32 0, i32 3
  %t182 = load i8**, i8*** %t181
  br label %table_read_end_35
table_read_end_35:
  %t183 = phi i64 [ 0, %table_read_null_33 ], [ %t178, %table_read_real_34 ]
  %t184 = phi i32* [ null, %table_read_null_33 ], [ %t180, %table_read_real_34 ]
  %t185 = phi i8** [ null, %table_read_null_33 ], [ %t182, %table_read_real_34 ]
  %t187 = icmp ult i64 %t173, %t183
  br i1 %t187, label %table_idx_ok_36, label %table_idx_oob_37
table_idx_ok_36:
  %t188 = getelementptr inbounds i32, i32* %t184, i64 %t173
  %t189 = load i32, i32* %t188
  %t190 = getelementptr inbounds %Item, %Item* %t186, i32 0, i32 0
  store i32 %t189, i32* %t190
  %t191 = getelementptr inbounds i8*, i8** %t185, i64 %t173
  %t192 = load i8*, i8** %t191
  call void @star_rc_retain(i8* %t192)
  %t193 = load i8*, i8** %t191
  %t194 = getelementptr inbounds %Item, %Item* %t186, i32 0, i32 1
  store i8* %t193, i8** %t194
  br label %table_idx_end_38
table_idx_oob_37:
  %t195 = getelementptr inbounds %Item, %Item* %t186, i32 0, i32 0
  store i32 0, i32* %t195
  %t196 = getelementptr inbounds %Item, %Item* %t186, i32 0, i32 1
  %t197 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t197
  store i8* %t197, i8** %t196
  br label %table_idx_end_38
table_idx_end_38:
  %t198 = load %Item, %Item* %t186
  store %Item %t198, %Item* %t199
  %t200 = getelementptr inbounds %Item, %Item* %t199, i32 0, i32 0
  %t201 = load i32, i32* %t200
  %t202 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t202, i8* %t171, i32 %t201)
  %t203 = sext i32 4999 to i64
  %t204 = load i8*, i8** %t2
  %t205 = icmp eq i8* %t204, null
  br i1 %t205, label %table_read_null_39, label %table_read_real_40
table_read_null_39:
  br label %table_read_end_41
table_read_real_40:
  %t206 = bitcast i8* %t204 to { i64, i64, i32*, i8** }*
  %t207 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t206, i32 0, i32 0
  %t208 = load i64, i64* %t207
  %t209 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t206, i32 0, i32 2
  %t210 = load i32*, i32** %t209
  %t211 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t206, i32 0, i32 3
  %t212 = load i8**, i8*** %t211
  br label %table_read_end_41
table_read_end_41:
  %t213 = phi i64 [ 0, %table_read_null_39 ], [ %t208, %table_read_real_40 ]
  %t214 = phi i32* [ null, %table_read_null_39 ], [ %t210, %table_read_real_40 ]
  %t215 = phi i8** [ null, %table_read_null_39 ], [ %t212, %table_read_real_40 ]
  %t217 = icmp ult i64 %t203, %t213
  br i1 %t217, label %table_idx_ok_42, label %table_idx_oob_43
table_idx_ok_42:
  %t218 = getelementptr inbounds i32, i32* %t214, i64 %t203
  %t219 = load i32, i32* %t218
  %t220 = getelementptr inbounds %Item, %Item* %t216, i32 0, i32 0
  store i32 %t219, i32* %t220
  %t221 = getelementptr inbounds i8*, i8** %t215, i64 %t203
  %t222 = load i8*, i8** %t221
  call void @star_rc_retain(i8* %t222)
  %t223 = load i8*, i8** %t221
  %t224 = getelementptr inbounds %Item, %Item* %t216, i32 0, i32 1
  store i8* %t223, i8** %t224
  br label %table_idx_end_44
table_idx_oob_43:
  %t225 = getelementptr inbounds %Item, %Item* %t216, i32 0, i32 0
  store i32 0, i32* %t225
  %t226 = getelementptr inbounds %Item, %Item* %t216, i32 0, i32 1
  %t227 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t227
  store i8* %t227, i8** %t226
  br label %table_idx_end_44
table_idx_end_44:
  %t228 = load %Item, %Item* %t216
  store %Item %t228, %Item* %t229
  %t230 = getelementptr inbounds %Item, %Item* %t229, i32 0, i32 1
  %t231 = load i8*, i8** %t230
  %t232 = load i8*, i8** %t230
  call void @star_rc_retain(i8* %t232)
  call void @star_rc_release(i8* %t231)
  %t233 = sext i32 4999 to i64
  %t234 = load i8*, i8** %t2
  %t235 = icmp eq i8* %t234, null
  br i1 %t235, label %table_read_null_45, label %table_read_real_46
table_read_null_45:
  br label %table_read_end_47
table_read_real_46:
  %t236 = bitcast i8* %t234 to { i64, i64, i32*, i8** }*
  %t237 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t236, i32 0, i32 0
  %t238 = load i64, i64* %t237
  %t239 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t236, i32 0, i32 2
  %t240 = load i32*, i32** %t239
  %t241 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t236, i32 0, i32 3
  %t242 = load i8**, i8*** %t241
  br label %table_read_end_47
table_read_end_47:
  %t243 = phi i64 [ 0, %table_read_null_45 ], [ %t238, %table_read_real_46 ]
  %t244 = phi i32* [ null, %table_read_null_45 ], [ %t240, %table_read_real_46 ]
  %t245 = phi i8** [ null, %table_read_null_45 ], [ %t242, %table_read_real_46 ]
  %t247 = icmp ult i64 %t233, %t243
  br i1 %t247, label %table_idx_ok_48, label %table_idx_oob_49
table_idx_ok_48:
  %t248 = getelementptr inbounds i32, i32* %t244, i64 %t233
  %t249 = load i32, i32* %t248
  %t250 = getelementptr inbounds %Item, %Item* %t246, i32 0, i32 0
  store i32 %t249, i32* %t250
  %t251 = getelementptr inbounds i8*, i8** %t245, i64 %t233
  %t252 = load i8*, i8** %t251
  call void @star_rc_retain(i8* %t252)
  %t253 = load i8*, i8** %t251
  %t254 = getelementptr inbounds %Item, %Item* %t246, i32 0, i32 1
  store i8* %t253, i8** %t254
  br label %table_idx_end_50
table_idx_oob_49:
  %t255 = getelementptr inbounds %Item, %Item* %t246, i32 0, i32 0
  store i32 0, i32* %t255
  %t256 = getelementptr inbounds %Item, %Item* %t246, i32 0, i32 1
  %t257 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t257
  store i8* %t257, i8** %t256
  br label %table_idx_end_50
table_idx_end_50:
  %t258 = load %Item, %Item* %t246
  store %Item %t258, %Item* %t259
  %t260 = getelementptr inbounds %Item, %Item* %t259, i32 0, i32 0
  %t261 = load i32, i32* %t260
  %t262 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t262, i8* %t231, i32 %t261)
  %t264 = load i8*, i8** %t2
  %t265 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t265)
  store i8* %t264, i8** %t263
  store i32 0, i32* %t266
  br label %while_cond_51
while_cond_51:
  %t267 = load i32, i32* %t266
  %t268 = icmp slt i32 %t267, 5000
  br i1 %t268, label %while_body_52, label %while_else_53
while_body_52:
  %t269 = load i8*, i8** %t263
  %t270 = icmp eq i8* %t269, null
  br i1 %t270, label %table_cow_alloc_55, label %table_cow_check_56
table_cow_alloc_55:
  %t271 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t272 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t273 = ptrtoint { i64, i64, i32*, i8** }* %t272 to i64
  %t274 = call i8* @star_rc_alloc(i64 %t273, i8* %t271)
  %t275 = bitcast i8* %t274 to { i64, i64, i32*, i8** }*
  %t276 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t275, i32 0, i32 0
  store i64 0, i64* %t276
  %t277 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t275, i32 0, i32 1
  store i64 0, i64* %t277
  %t278 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t275, i32 0, i32 2
  store i32* null, i32** %t278
  %t279 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t275, i32 0, i32 3
  store i8** null, i8*** %t279
  store i8* %t274, i8** %t263
  br label %table_cow_done_57
table_cow_check_56:
  %t280 = getelementptr inbounds i8, i8* %t269, i64 -16
  %t281 = bitcast i8* %t280 to i64*
  %t282 = load atomic i64, i64* %t281 seq_cst, align 8
  %t283 = icmp eq i64 %t282, 1
  br i1 %t283, label %table_cow_done_57, label %table_cow_clone_58
table_cow_clone_58:
  %t284 = bitcast i8* %t269 to { i64, i64, i32*, i8** }*
  %t285 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t284, i32 0, i32 0
  %t286 = load i64, i64* %t285
  %t287 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t284, i32 0, i32 1
  %t288 = load i64, i64* %t287
  %t289 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t290 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t291 = ptrtoint { i64, i64, i32*, i8** }* %t290 to i64
  %t292 = call i8* @star_rc_alloc(i64 %t291, i8* %t289)
  %t293 = bitcast i8* %t292 to { i64, i64, i32*, i8** }*
  %t294 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t293, i32 0, i32 0
  store i64 %t286, i64* %t294
  %t295 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t293, i32 0, i32 1
  store i64 %t288, i64* %t295
  %t296 = getelementptr i32, i32* null, i32 1
  %t297 = ptrtoint i32* %t296 to i64
  %t298 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t284, i32 0, i32 2
  %t299 = load i32*, i32** %t298
  %t300 = mul i64 %t288, %t297
  %t301 = call i8* @malloc(i64 %t300)
  %t302 = bitcast i8* %t301 to i32*
  %t303 = icmp sgt i64 %t286, 0
  br i1 %t303, label %table_cow_copy_59, label %table_cow_after_copy_60
table_cow_copy_59:
  %t304 = mul i64 %t286, %t297
  %t305 = bitcast i32* %t299 to i8*
  call i8* @memcpy(i8* %t301, i8* %t305, i64 %t304)
  br label %table_cow_after_copy_60
table_cow_after_copy_60:
  %t306 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t293, i32 0, i32 2
  store i32* %t302, i32** %t306
  %t307 = getelementptr i8*, i8** null, i32 1
  %t308 = ptrtoint i8** %t307 to i64
  %t309 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t284, i32 0, i32 3
  %t310 = load i8**, i8*** %t309
  %t311 = mul i64 %t288, %t308
  %t312 = call i8* @malloc(i64 %t311)
  %t313 = bitcast i8* %t312 to i8**
  %t314 = icmp sgt i64 %t286, 0
  br i1 %t314, label %table_cow_copy_61, label %table_cow_after_copy_62
table_cow_copy_61:
  %t315 = mul i64 %t286, %t308
  %t316 = bitcast i8** %t310 to i8*
  call i8* @memcpy(i8* %t312, i8* %t316, i64 %t315)
  store i64 0, i64* %t317
  br label %table_cow_retain_cond_63
table_cow_retain_cond_63:
  %t318 = load i64, i64* %t317
  %t319 = icmp slt i64 %t318, %t286
  br i1 %t319, label %table_cow_retain_body_64, label %table_cow_retain_end_65
table_cow_retain_body_64:
  %t320 = getelementptr inbounds i8*, i8** %t313, i64 %t318
  %t321 = load i8*, i8** %t320
  call void @star_rc_retain(i8* %t321)
  %t322 = add i64 %t318, 1
  store i64 %t322, i64* %t317
  br label %table_cow_retain_cond_63
table_cow_retain_end_65:
  br label %table_cow_after_copy_62
table_cow_after_copy_62:
  %t323 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t293, i32 0, i32 3
  store i8** %t313, i8*** %t323
  call void @star_rc_release(i8* %t269)
  store i8* %t292, i8** %t263
  br label %table_cow_done_57
table_cow_done_57:
  %t324 = load i8*, i8** %t263
  %t325 = bitcast i8* %t324 to { i64, i64, i32*, i8** }*
  %t326 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t325, i32 0, i32 0
  %t327 = load i64, i64* %t326
  %t328 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t325, i32 0, i32 1
  %t329 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t325, i32 0, i32 2
  %t330 = load i32*, i32** %t329
  %t331 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t325, i32 0, i32 3
  %t332 = load i8**, i8*** %t331
  %t334 = load i32, i32* %t266
  %t335 = getelementptr inbounds %Item, %Item* %t333, i32 0, i32 0
  store i32 %t334, i32* %t335
  %t336 = load i32, i32* %t266
  %t337 = getelementptr inbounds [9 x i8], [9 x i8]* @.str.4, i64 0, i64 0
  %t338 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t337, i32 %t336)
  %t339 = add i32 %t338, 1
  %t340 = sext i32 %t339 to i64
  %t341 = call i8* @star_rc_alloc(i64 %t340, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t341, i64 %t340, i8* %t337, i32 %t336)
  %t342 = getelementptr inbounds %Item, %Item* %t333, i32 0, i32 1
  store i8* %t341, i8** %t342
  %t343 = load %Item, %Item* %t333
  %t344 = load i64, i64* %t328
  %t345 = load i64, i64* %t326
  %t346 = load i32*, i32** %t329
  %t347 = load i8**, i8*** %t331
  %t348 = icmp sge i64 %t345, %t344
  br i1 %t348, label %table_push_grow_66, label %table_push_store_67
table_push_grow_66:
  %t349 = mul i64 %t344, 2
  %t350 = icmp sgt i64 %t349, 0
  %t351 = select i1 %t350, i64 %t349, i64 1
  %t352 = getelementptr i32, i32* null, i32 1
  %t353 = ptrtoint i32* %t352 to i64
  %t354 = mul i64 %t351, %t353
  %t355 = call i8* @malloc(i64 %t354)
  %t356 = bitcast i8* %t355 to i32*
  %t357 = icmp sgt i64 %t344, 0
  br i1 %t357, label %table_push_copy_68, label %table_push_after_copy_69
table_push_copy_68:
  %t358 = mul i64 %t345, %t353
  %t359 = bitcast i32* %t346 to i8*
  call i8* @memcpy(i8* %t355, i8* %t359, i64 %t358)
  call void @free(i8* %t359)
  br label %table_push_after_copy_69
table_push_after_copy_69:
  store i32* %t356, i32** %t329
  %t360 = getelementptr i8*, i8** null, i32 1
  %t361 = ptrtoint i8** %t360 to i64
  %t362 = mul i64 %t351, %t361
  %t363 = call i8* @malloc(i64 %t362)
  %t364 = bitcast i8* %t363 to i8**
  %t365 = icmp sgt i64 %t344, 0
  br i1 %t365, label %table_push_copy_70, label %table_push_after_copy_71
table_push_copy_70:
  %t366 = mul i64 %t345, %t361
  %t367 = bitcast i8** %t347 to i8*
  call i8* @memcpy(i8* %t363, i8* %t367, i64 %t366)
  call void @free(i8* %t367)
  br label %table_push_after_copy_71
table_push_after_copy_71:
  store i8** %t364, i8*** %t331
  store i64 %t351, i64* %t328
  br label %table_push_store_67
table_push_store_67:
  %t368 = load i32*, i32** %t329
  %t369 = extractvalue %Item %t343, 0
  %t370 = getelementptr inbounds i32, i32* %t368, i64 %t345
  store i32 %t369, i32* %t370
  %t371 = load i8**, i8*** %t331
  %t372 = extractvalue %Item %t343, 1
  %t373 = getelementptr inbounds i8*, i8** %t371, i64 %t345
  store i8* %t372, i8** %t373
  %t374 = add i64 %t345, 1
  store i64 %t374, i64* %t326
  %t375 = load i32, i32* %t266
  %t376 = add i32 %t375, 1
  store i32 %t376, i32* %t266
  br label %while_cond_51
while_else_53:
  br label %while_end_54
while_end_54:
  %t377 = load i8*, i8** %t2
  %t378 = icmp eq i8* %t377, null
  br i1 %t378, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t379 = bitcast i8* %t377 to { i64, i64, i32*, i8** }*
  %t380 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 0
  %t381 = load i64, i64* %t380
  %t382 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 2
  %t383 = load i32*, i32** %t382
  %t384 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 3
  %t385 = load i8**, i8*** %t384
  br label %table_read_end_74
table_read_end_74:
  %t386 = phi i64 [ 0, %table_read_null_72 ], [ %t381, %table_read_real_73 ]
  %t387 = phi i32* [ null, %table_read_null_72 ], [ %t383, %table_read_real_73 ]
  %t388 = phi i8** [ null, %table_read_null_72 ], [ %t385, %table_read_real_73 ]
  %t389 = trunc i64 %t386 to i32
  %t390 = load i8*, i8** %t263
  %t391 = icmp eq i8* %t390, null
  br i1 %t391, label %table_read_null_75, label %table_read_real_76
table_read_null_75:
  br label %table_read_end_77
table_read_real_76:
  %t392 = bitcast i8* %t390 to { i64, i64, i32*, i8** }*
  %t393 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t392, i32 0, i32 0
  %t394 = load i64, i64* %t393
  %t395 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t392, i32 0, i32 2
  %t396 = load i32*, i32** %t395
  %t397 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t392, i32 0, i32 3
  %t398 = load i8**, i8*** %t397
  br label %table_read_end_77
table_read_end_77:
  %t399 = phi i64 [ 0, %table_read_null_75 ], [ %t394, %table_read_real_76 ]
  %t400 = phi i32* [ null, %table_read_null_75 ], [ %t396, %table_read_real_76 ]
  %t401 = phi i8** [ null, %table_read_null_75 ], [ %t398, %table_read_real_76 ]
  %t402 = trunc i64 %t399 to i32
  %t403 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t403, i32 %t389, i32 %t402)
  %t404 = sext i32 0 to i64
  %t405 = load i8*, i8** %t2
  %t406 = icmp eq i8* %t405, null
  br i1 %t406, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t407 = bitcast i8* %t405 to { i64, i64, i32*, i8** }*
  %t408 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t407, i32 0, i32 0
  %t409 = load i64, i64* %t408
  %t410 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t407, i32 0, i32 2
  %t411 = load i32*, i32** %t410
  %t412 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t407, i32 0, i32 3
  %t413 = load i8**, i8*** %t412
  br label %table_read_end_80
table_read_end_80:
  %t414 = phi i64 [ 0, %table_read_null_78 ], [ %t409, %table_read_real_79 ]
  %t415 = phi i32* [ null, %table_read_null_78 ], [ %t411, %table_read_real_79 ]
  %t416 = phi i8** [ null, %table_read_null_78 ], [ %t413, %table_read_real_79 ]
  %t418 = icmp ult i64 %t404, %t414
  br i1 %t418, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t419 = getelementptr inbounds i32, i32* %t415, i64 %t404
  %t420 = load i32, i32* %t419
  %t421 = getelementptr inbounds %Item, %Item* %t417, i32 0, i32 0
  store i32 %t420, i32* %t421
  %t422 = getelementptr inbounds i8*, i8** %t416, i64 %t404
  %t423 = load i8*, i8** %t422
  call void @star_rc_retain(i8* %t423)
  %t424 = load i8*, i8** %t422
  %t425 = getelementptr inbounds %Item, %Item* %t417, i32 0, i32 1
  store i8* %t424, i8** %t425
  br label %table_idx_end_83
table_idx_oob_82:
  %t426 = getelementptr inbounds %Item, %Item* %t417, i32 0, i32 0
  store i32 0, i32* %t426
  %t427 = getelementptr inbounds %Item, %Item* %t417, i32 0, i32 1
  %t428 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t428
  store i8* %t428, i8** %t427
  br label %table_idx_end_83
table_idx_end_83:
  %t429 = load %Item, %Item* %t417
  store %Item %t429, %Item* %t430
  %t431 = getelementptr inbounds %Item, %Item* %t430, i32 0, i32 1
  %t432 = load i8*, i8** %t431
  %t433 = load i8*, i8** %t431
  call void @star_rc_retain(i8* %t433)
  call void @star_rc_release(i8* %t432)
  %t434 = sext i32 0 to i64
  %t435 = load i8*, i8** %t263
  %t436 = icmp eq i8* %t435, null
  br i1 %t436, label %table_read_null_84, label %table_read_real_85
table_read_null_84:
  br label %table_read_end_86
table_read_real_85:
  %t437 = bitcast i8* %t435 to { i64, i64, i32*, i8** }*
  %t438 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t437, i32 0, i32 0
  %t439 = load i64, i64* %t438
  %t440 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t437, i32 0, i32 2
  %t441 = load i32*, i32** %t440
  %t442 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t437, i32 0, i32 3
  %t443 = load i8**, i8*** %t442
  br label %table_read_end_86
table_read_end_86:
  %t444 = phi i64 [ 0, %table_read_null_84 ], [ %t439, %table_read_real_85 ]
  %t445 = phi i32* [ null, %table_read_null_84 ], [ %t441, %table_read_real_85 ]
  %t446 = phi i8** [ null, %table_read_null_84 ], [ %t443, %table_read_real_85 ]
  %t448 = icmp ult i64 %t434, %t444
  br i1 %t448, label %table_idx_ok_87, label %table_idx_oob_88
table_idx_ok_87:
  %t449 = getelementptr inbounds i32, i32* %t445, i64 %t434
  %t450 = load i32, i32* %t449
  %t451 = getelementptr inbounds %Item, %Item* %t447, i32 0, i32 0
  store i32 %t450, i32* %t451
  %t452 = getelementptr inbounds i8*, i8** %t446, i64 %t434
  %t453 = load i8*, i8** %t452
  call void @star_rc_retain(i8* %t453)
  %t454 = load i8*, i8** %t452
  %t455 = getelementptr inbounds %Item, %Item* %t447, i32 0, i32 1
  store i8* %t454, i8** %t455
  br label %table_idx_end_89
table_idx_oob_88:
  %t456 = getelementptr inbounds %Item, %Item* %t447, i32 0, i32 0
  store i32 0, i32* %t456
  %t457 = getelementptr inbounds %Item, %Item* %t447, i32 0, i32 1
  %t458 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t458
  store i8* %t458, i8** %t457
  br label %table_idx_end_89
table_idx_end_89:
  %t459 = load %Item, %Item* %t447
  store %Item %t459, %Item* %t460
  %t461 = getelementptr inbounds %Item, %Item* %t460, i32 0, i32 1
  %t462 = load i8*, i8** %t461
  %t463 = load i8*, i8** %t461
  call void @star_rc_retain(i8* %t463)
  call void @star_rc_release(i8* %t462)
  %t464 = getelementptr inbounds [32 x i8], [32 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t464, i8* %t432, i8* %t462)
  %t465 = sext i32 4999 to i64
  %t466 = load i8*, i8** %t2
  %t467 = icmp eq i8* %t466, null
  br i1 %t467, label %table_read_null_90, label %table_read_real_91
table_read_null_90:
  br label %table_read_end_92
table_read_real_91:
  %t468 = bitcast i8* %t466 to { i64, i64, i32*, i8** }*
  %t469 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t468, i32 0, i32 0
  %t470 = load i64, i64* %t469
  %t471 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t468, i32 0, i32 2
  %t472 = load i32*, i32** %t471
  %t473 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t468, i32 0, i32 3
  %t474 = load i8**, i8*** %t473
  br label %table_read_end_92
table_read_end_92:
  %t475 = phi i64 [ 0, %table_read_null_90 ], [ %t470, %table_read_real_91 ]
  %t476 = phi i32* [ null, %table_read_null_90 ], [ %t472, %table_read_real_91 ]
  %t477 = phi i8** [ null, %table_read_null_90 ], [ %t474, %table_read_real_91 ]
  %t479 = icmp ult i64 %t465, %t475
  br i1 %t479, label %table_idx_ok_93, label %table_idx_oob_94
table_idx_ok_93:
  %t480 = getelementptr inbounds i32, i32* %t476, i64 %t465
  %t481 = load i32, i32* %t480
  %t482 = getelementptr inbounds %Item, %Item* %t478, i32 0, i32 0
  store i32 %t481, i32* %t482
  %t483 = getelementptr inbounds i8*, i8** %t477, i64 %t465
  %t484 = load i8*, i8** %t483
  call void @star_rc_retain(i8* %t484)
  %t485 = load i8*, i8** %t483
  %t486 = getelementptr inbounds %Item, %Item* %t478, i32 0, i32 1
  store i8* %t485, i8** %t486
  br label %table_idx_end_95
table_idx_oob_94:
  %t487 = getelementptr inbounds %Item, %Item* %t478, i32 0, i32 0
  store i32 0, i32* %t487
  %t488 = getelementptr inbounds %Item, %Item* %t478, i32 0, i32 1
  %t489 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t489
  store i8* %t489, i8** %t488
  br label %table_idx_end_95
table_idx_end_95:
  %t490 = load %Item, %Item* %t478
  store %Item %t490, %Item* %t491
  %t492 = getelementptr inbounds %Item, %Item* %t491, i32 0, i32 1
  %t493 = load i8*, i8** %t492
  %t494 = load i8*, i8** %t492
  call void @star_rc_retain(i8* %t494)
  call void @star_rc_release(i8* %t493)
  %t495 = sext i32 4999 to i64
  %t496 = load i8*, i8** %t263
  %t497 = icmp eq i8* %t496, null
  br i1 %t497, label %table_read_null_96, label %table_read_real_97
table_read_null_96:
  br label %table_read_end_98
table_read_real_97:
  %t498 = bitcast i8* %t496 to { i64, i64, i32*, i8** }*
  %t499 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t498, i32 0, i32 0
  %t500 = load i64, i64* %t499
  %t501 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t498, i32 0, i32 2
  %t502 = load i32*, i32** %t501
  %t503 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t498, i32 0, i32 3
  %t504 = load i8**, i8*** %t503
  br label %table_read_end_98
table_read_end_98:
  %t505 = phi i64 [ 0, %table_read_null_96 ], [ %t500, %table_read_real_97 ]
  %t506 = phi i32* [ null, %table_read_null_96 ], [ %t502, %table_read_real_97 ]
  %t507 = phi i8** [ null, %table_read_null_96 ], [ %t504, %table_read_real_97 ]
  %t509 = icmp ult i64 %t495, %t505
  br i1 %t509, label %table_idx_ok_99, label %table_idx_oob_100
table_idx_ok_99:
  %t510 = getelementptr inbounds i32, i32* %t506, i64 %t495
  %t511 = load i32, i32* %t510
  %t512 = getelementptr inbounds %Item, %Item* %t508, i32 0, i32 0
  store i32 %t511, i32* %t512
  %t513 = getelementptr inbounds i8*, i8** %t507, i64 %t495
  %t514 = load i8*, i8** %t513
  call void @star_rc_retain(i8* %t514)
  %t515 = load i8*, i8** %t513
  %t516 = getelementptr inbounds %Item, %Item* %t508, i32 0, i32 1
  store i8* %t515, i8** %t516
  br label %table_idx_end_101
table_idx_oob_100:
  %t517 = getelementptr inbounds %Item, %Item* %t508, i32 0, i32 0
  store i32 0, i32* %t517
  %t518 = getelementptr inbounds %Item, %Item* %t508, i32 0, i32 1
  %t519 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t519
  store i8* %t519, i8** %t518
  br label %table_idx_end_101
table_idx_end_101:
  %t520 = load %Item, %Item* %t508
  store %Item %t520, %Item* %t521
  %t522 = getelementptr inbounds %Item, %Item* %t521, i32 0, i32 1
  %t523 = load i8*, i8** %t522
  %t524 = load i8*, i8** %t522
  call void @star_rc_retain(i8* %t524)
  call void @star_rc_release(i8* %t523)
  %t525 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t525, i8* %t493, i8* %t523)
  store i8* null, i8** %t526
  store i32 0, i32* %t527
  br label %while_cond_102
while_cond_102:
  %t528 = load i32, i32* %t527
  %t529 = icmp slt i32 %t528, 3000
  br i1 %t529, label %while_body_103, label %while_else_104
while_body_103:
  %t530 = load i8*, i8** %t526
  %t531 = icmp eq i8* %t530, null
  br i1 %t531, label %table_cow_alloc_106, label %table_cow_check_107
table_cow_alloc_106:
  %t532 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t533 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t534 = ptrtoint { i64, i64, i32*, i8** }* %t533 to i64
  %t535 = call i8* @star_rc_alloc(i64 %t534, i8* %t532)
  %t536 = bitcast i8* %t535 to { i64, i64, i32*, i8** }*
  %t537 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t536, i32 0, i32 0
  store i64 0, i64* %t537
  %t538 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t536, i32 0, i32 1
  store i64 0, i64* %t538
  %t539 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t536, i32 0, i32 2
  store i32* null, i32** %t539
  %t540 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t536, i32 0, i32 3
  store i8** null, i8*** %t540
  store i8* %t535, i8** %t526
  br label %table_cow_done_108
table_cow_check_107:
  %t541 = getelementptr inbounds i8, i8* %t530, i64 -16
  %t542 = bitcast i8* %t541 to i64*
  %t543 = load atomic i64, i64* %t542 seq_cst, align 8
  %t544 = icmp eq i64 %t543, 1
  br i1 %t544, label %table_cow_done_108, label %table_cow_clone_109
table_cow_clone_109:
  %t545 = bitcast i8* %t530 to { i64, i64, i32*, i8** }*
  %t546 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t545, i32 0, i32 0
  %t547 = load i64, i64* %t546
  %t548 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t545, i32 0, i32 1
  %t549 = load i64, i64* %t548
  %t550 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t551 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t552 = ptrtoint { i64, i64, i32*, i8** }* %t551 to i64
  %t553 = call i8* @star_rc_alloc(i64 %t552, i8* %t550)
  %t554 = bitcast i8* %t553 to { i64, i64, i32*, i8** }*
  %t555 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 0
  store i64 %t547, i64* %t555
  %t556 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 1
  store i64 %t549, i64* %t556
  %t557 = getelementptr i32, i32* null, i32 1
  %t558 = ptrtoint i32* %t557 to i64
  %t559 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t545, i32 0, i32 2
  %t560 = load i32*, i32** %t559
  %t561 = mul i64 %t549, %t558
  %t562 = call i8* @malloc(i64 %t561)
  %t563 = bitcast i8* %t562 to i32*
  %t564 = icmp sgt i64 %t547, 0
  br i1 %t564, label %table_cow_copy_110, label %table_cow_after_copy_111
table_cow_copy_110:
  %t565 = mul i64 %t547, %t558
  %t566 = bitcast i32* %t560 to i8*
  call i8* @memcpy(i8* %t562, i8* %t566, i64 %t565)
  br label %table_cow_after_copy_111
table_cow_after_copy_111:
  %t567 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 2
  store i32* %t563, i32** %t567
  %t568 = getelementptr i8*, i8** null, i32 1
  %t569 = ptrtoint i8** %t568 to i64
  %t570 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t545, i32 0, i32 3
  %t571 = load i8**, i8*** %t570
  %t572 = mul i64 %t549, %t569
  %t573 = call i8* @malloc(i64 %t572)
  %t574 = bitcast i8* %t573 to i8**
  %t575 = icmp sgt i64 %t547, 0
  br i1 %t575, label %table_cow_copy_112, label %table_cow_after_copy_113
table_cow_copy_112:
  %t576 = mul i64 %t547, %t569
  %t577 = bitcast i8** %t571 to i8*
  call i8* @memcpy(i8* %t573, i8* %t577, i64 %t576)
  store i64 0, i64* %t578
  br label %table_cow_retain_cond_114
table_cow_retain_cond_114:
  %t579 = load i64, i64* %t578
  %t580 = icmp slt i64 %t579, %t547
  br i1 %t580, label %table_cow_retain_body_115, label %table_cow_retain_end_116
table_cow_retain_body_115:
  %t581 = getelementptr inbounds i8*, i8** %t574, i64 %t579
  %t582 = load i8*, i8** %t581
  call void @star_rc_retain(i8* %t582)
  %t583 = add i64 %t579, 1
  store i64 %t583, i64* %t578
  br label %table_cow_retain_cond_114
table_cow_retain_end_116:
  br label %table_cow_after_copy_113
table_cow_after_copy_113:
  %t584 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t554, i32 0, i32 3
  store i8** %t574, i8*** %t584
  call void @star_rc_release(i8* %t530)
  store i8* %t553, i8** %t526
  br label %table_cow_done_108
table_cow_done_108:
  %t585 = load i8*, i8** %t526
  %t586 = bitcast i8* %t585 to { i64, i64, i32*, i8** }*
  %t587 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t586, i32 0, i32 0
  %t588 = load i64, i64* %t587
  %t589 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t586, i32 0, i32 1
  %t590 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t586, i32 0, i32 2
  %t591 = load i32*, i32** %t590
  %t592 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t586, i32 0, i32 3
  %t593 = load i8**, i8*** %t592
  %t595 = load i32, i32* %t527
  %t596 = getelementptr inbounds %Item, %Item* %t594, i32 0, i32 0
  store i32 %t595, i32* %t596
  %t597 = load i32, i32* %t527
  %t598 = getelementptr inbounds [7 x i8], [7 x i8]* @.str.8, i64 0, i64 0
  %t599 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* null, i64 0, i8* %t598, i32 %t597)
  %t600 = add i32 %t599, 1
  %t601 = sext i32 %t600 to i64
  %t602 = call i8* @star_rc_alloc(i64 %t601, i8* null)
  call i32 (i8*, i64, i8*, ...) @snprintf(i8* %t602, i64 %t601, i8* %t598, i32 %t597)
  %t603 = getelementptr inbounds %Item, %Item* %t594, i32 0, i32 1
  store i8* %t602, i8** %t603
  %t604 = load %Item, %Item* %t594
  %t605 = load i64, i64* %t589
  %t606 = load i64, i64* %t587
  %t607 = load i32*, i32** %t590
  %t608 = load i8**, i8*** %t592
  %t609 = icmp sge i64 %t606, %t605
  br i1 %t609, label %table_push_grow_117, label %table_push_store_118
table_push_grow_117:
  %t610 = mul i64 %t605, 2
  %t611 = icmp sgt i64 %t610, 0
  %t612 = select i1 %t611, i64 %t610, i64 1
  %t613 = getelementptr i32, i32* null, i32 1
  %t614 = ptrtoint i32* %t613 to i64
  %t615 = mul i64 %t612, %t614
  %t616 = call i8* @malloc(i64 %t615)
  %t617 = bitcast i8* %t616 to i32*
  %t618 = icmp sgt i64 %t605, 0
  br i1 %t618, label %table_push_copy_119, label %table_push_after_copy_120
table_push_copy_119:
  %t619 = mul i64 %t606, %t614
  %t620 = bitcast i32* %t607 to i8*
  call i8* @memcpy(i8* %t616, i8* %t620, i64 %t619)
  call void @free(i8* %t620)
  br label %table_push_after_copy_120
table_push_after_copy_120:
  store i32* %t617, i32** %t590
  %t621 = getelementptr i8*, i8** null, i32 1
  %t622 = ptrtoint i8** %t621 to i64
  %t623 = mul i64 %t612, %t622
  %t624 = call i8* @malloc(i64 %t623)
  %t625 = bitcast i8* %t624 to i8**
  %t626 = icmp sgt i64 %t605, 0
  br i1 %t626, label %table_push_copy_121, label %table_push_after_copy_122
table_push_copy_121:
  %t627 = mul i64 %t606, %t622
  %t628 = bitcast i8** %t608 to i8*
  call i8* @memcpy(i8* %t624, i8* %t628, i64 %t627)
  call void @free(i8* %t628)
  br label %table_push_after_copy_122
table_push_after_copy_122:
  store i8** %t625, i8*** %t592
  store i64 %t612, i64* %t589
  br label %table_push_store_118
table_push_store_118:
  %t629 = load i32*, i32** %t590
  %t630 = extractvalue %Item %t604, 0
  %t631 = getelementptr inbounds i32, i32* %t629, i64 %t606
  store i32 %t630, i32* %t631
  %t632 = load i8**, i8*** %t592
  %t633 = extractvalue %Item %t604, 1
  %t634 = getelementptr inbounds i8*, i8** %t632, i64 %t606
  store i8* %t633, i8** %t634
  %t635 = add i64 %t606, 1
  store i64 %t635, i64* %t587
  %t636 = load i32, i32* %t527
  %t637 = icmp eq i32 3, 0
  %t638 = icmp eq i32 %t636, -2147483648
  %t639 = icmp eq i32 3, -1
  %t640 = and i1 %t638, %t639
  %t641 = or i1 %t637, %t640
  br i1 %t641, label %int_div_fail_123, label %int_div_ok_124
int_div_fail_123:
  %t642 = getelementptr inbounds [71 x i8], [71 x i8]* @.str.9, i64 0, i64 0
  call i32 @puts(i8* %t642)
  call void @exit(i32 1)
  unreachable
int_div_ok_124:
  %t643 = srem i32 %t636, 3
  %t644 = icmp eq i32 %t643, 0
  br i1 %t644, label %if_then_125, label %if_else_126
if_then_125:
  %t646 = load i8*, i8** %t526
  %t647 = icmp eq i8* %t646, null
  br i1 %t647, label %table_cow_alloc_128, label %table_cow_check_129
table_cow_alloc_128:
  %t648 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t649 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t650 = ptrtoint { i64, i64, i32*, i8** }* %t649 to i64
  %t651 = call i8* @star_rc_alloc(i64 %t650, i8* %t648)
  %t652 = bitcast i8* %t651 to { i64, i64, i32*, i8** }*
  %t653 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t652, i32 0, i32 0
  store i64 0, i64* %t653
  %t654 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t652, i32 0, i32 1
  store i64 0, i64* %t654
  %t655 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t652, i32 0, i32 2
  store i32* null, i32** %t655
  %t656 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t652, i32 0, i32 3
  store i8** null, i8*** %t656
  store i8* %t651, i8** %t526
  br label %table_cow_done_130
table_cow_check_129:
  %t657 = getelementptr inbounds i8, i8* %t646, i64 -16
  %t658 = bitcast i8* %t657 to i64*
  %t659 = load atomic i64, i64* %t658 seq_cst, align 8
  %t660 = icmp eq i64 %t659, 1
  br i1 %t660, label %table_cow_done_130, label %table_cow_clone_131
table_cow_clone_131:
  %t661 = bitcast i8* %t646 to { i64, i64, i32*, i8** }*
  %t662 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t661, i32 0, i32 0
  %t663 = load i64, i64* %t662
  %t664 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t661, i32 0, i32 1
  %t665 = load i64, i64* %t664
  %t666 = bitcast void (i8*)* @table_release_s_Item to i8*
  %t667 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t668 = ptrtoint { i64, i64, i32*, i8** }* %t667 to i64
  %t669 = call i8* @star_rc_alloc(i64 %t668, i8* %t666)
  %t670 = bitcast i8* %t669 to { i64, i64, i32*, i8** }*
  %t671 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 0
  store i64 %t663, i64* %t671
  %t672 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 1
  store i64 %t665, i64* %t672
  %t673 = getelementptr i32, i32* null, i32 1
  %t674 = ptrtoint i32* %t673 to i64
  %t675 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t661, i32 0, i32 2
  %t676 = load i32*, i32** %t675
  %t677 = mul i64 %t665, %t674
  %t678 = call i8* @malloc(i64 %t677)
  %t679 = bitcast i8* %t678 to i32*
  %t680 = icmp sgt i64 %t663, 0
  br i1 %t680, label %table_cow_copy_132, label %table_cow_after_copy_133
table_cow_copy_132:
  %t681 = mul i64 %t663, %t674
  %t682 = bitcast i32* %t676 to i8*
  call i8* @memcpy(i8* %t678, i8* %t682, i64 %t681)
  br label %table_cow_after_copy_133
table_cow_after_copy_133:
  %t683 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 2
  store i32* %t679, i32** %t683
  %t684 = getelementptr i8*, i8** null, i32 1
  %t685 = ptrtoint i8** %t684 to i64
  %t686 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t661, i32 0, i32 3
  %t687 = load i8**, i8*** %t686
  %t688 = mul i64 %t665, %t685
  %t689 = call i8* @malloc(i64 %t688)
  %t690 = bitcast i8* %t689 to i8**
  %t691 = icmp sgt i64 %t663, 0
  br i1 %t691, label %table_cow_copy_134, label %table_cow_after_copy_135
table_cow_copy_134:
  %t692 = mul i64 %t663, %t685
  %t693 = bitcast i8** %t687 to i8*
  call i8* @memcpy(i8* %t689, i8* %t693, i64 %t692)
  store i64 0, i64* %t694
  br label %table_cow_retain_cond_136
table_cow_retain_cond_136:
  %t695 = load i64, i64* %t694
  %t696 = icmp slt i64 %t695, %t663
  br i1 %t696, label %table_cow_retain_body_137, label %table_cow_retain_end_138
table_cow_retain_body_137:
  %t697 = getelementptr inbounds i8*, i8** %t690, i64 %t695
  %t698 = load i8*, i8** %t697
  call void @star_rc_retain(i8* %t698)
  %t699 = add i64 %t695, 1
  store i64 %t699, i64* %t694
  br label %table_cow_retain_cond_136
table_cow_retain_end_138:
  br label %table_cow_after_copy_135
table_cow_after_copy_135:
  %t700 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t670, i32 0, i32 3
  store i8** %t690, i8*** %t700
  call void @star_rc_release(i8* %t646)
  store i8* %t669, i8** %t526
  br label %table_cow_done_130
table_cow_done_130:
  %t701 = load i8*, i8** %t526
  %t702 = bitcast i8* %t701 to { i64, i64, i32*, i8** }*
  %t703 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t702, i32 0, i32 0
  %t704 = load i64, i64* %t703
  %t705 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t702, i32 0, i32 1
  %t706 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t702, i32 0, i32 2
  %t707 = load i32*, i32** %t706
  %t708 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t702, i32 0, i32 3
  %t709 = load i8**, i8*** %t708
  %t711 = icmp eq i64 %t704, 0
  br i1 %t711, label %table_pop_empty_139, label %table_pop_nonempty_140
table_pop_nonempty_140:
  %t712 = sub i64 %t704, 1
  store i64 %t712, i64* %t703
  %t713 = getelementptr inbounds i32, i32* %t707, i64 %t712
  %t714 = load i32, i32* %t713
  %t715 = getelementptr inbounds %Item, %Item* %t710, i32 0, i32 0
  store i32 %t714, i32* %t715
  %t716 = getelementptr inbounds i8*, i8** %t709, i64 %t712
  %t717 = load i8*, i8** %t716
  %t718 = getelementptr inbounds %Item, %Item* %t710, i32 0, i32 1
  store i8* %t717, i8** %t718
  br label %table_pop_end_141
table_pop_empty_139:
  %t719 = getelementptr inbounds %Item, %Item* %t710, i32 0, i32 0
  store i32 0, i32* %t719
  %t720 = getelementptr inbounds %Item, %Item* %t710, i32 0, i32 1
  %t721 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t721
  store i8* %t721, i8** %t720
  br label %table_pop_end_141
table_pop_end_141:
  %t722 = load %Item, %Item* %t710
  store %Item %t722, %Item* %t645
  %t723 = getelementptr inbounds %Item, %Item* %t645, i32 0, i32 1
  %t724 = load i8*, i8** %t723
  %t725 = load i8*, i8** %t723
  call void @star_rc_retain(i8* %t725)
  %t726 = call i32 @strlen(i8* %t724)
  call void @star_rc_release(i8* %t724)
  %t727 = icmp eq i32 %t726, 0
  br i1 %t727, label %if_then_142, label %if_else_143
if_then_142:
  %t728 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.10, i64 0, i32 2, i64 0
  call void @star_rc_release(i8* %t728)
  call i32 (i8*, ...) @printf(i8* %t728)
  %t729 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t729)
  br label %if_end_144
if_else_143:
  br label %if_end_144
if_end_144:
  %t730 = getelementptr inbounds %Item, %Item* %t645, i32 0, i32 1
  %t731 = load i8*, i8** %t730
  call void @star_rc_release(i8* %t731)
  br label %if_end_127
if_else_126:
  br label %if_end_127
if_end_127:
  %t732 = load i32, i32* %t527
  %t733 = add i32 %t732, 1
  store i32 %t733, i32* %t527
  br label %while_cond_102
while_else_104:
  br label %while_end_105
while_end_105:
  %t734 = load i8*, i8** %t526
  %t735 = icmp eq i8* %t734, null
  br i1 %t735, label %table_read_null_145, label %table_read_real_146
table_read_null_145:
  br label %table_read_end_147
table_read_real_146:
  %t736 = bitcast i8* %t734 to { i64, i64, i32*, i8** }*
  %t737 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t736, i32 0, i32 0
  %t738 = load i64, i64* %t737
  %t739 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t736, i32 0, i32 2
  %t740 = load i32*, i32** %t739
  %t741 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t736, i32 0, i32 3
  %t742 = load i8**, i8*** %t741
  br label %table_read_end_147
table_read_end_147:
  %t743 = phi i64 [ 0, %table_read_null_145 ], [ %t738, %table_read_real_146 ]
  %t744 = phi i32* [ null, %table_read_null_145 ], [ %t740, %table_read_real_146 ]
  %t745 = phi i8** [ null, %table_read_null_145 ], [ %t742, %table_read_real_146 ]
  %t746 = trunc i64 %t743 to i32
  %t747 = getelementptr inbounds [17 x i8], [17 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t747, i32 %t746)
  %t748 = load i8*, i8** %t526
  call void @star_rc_release(i8* %t748)
  %t749 = getelementptr inbounds %Item, %Item* %t521, i32 0, i32 1
  %t750 = load i8*, i8** %t749
  call void @star_rc_release(i8* %t750)
  %t751 = getelementptr inbounds %Item, %Item* %t491, i32 0, i32 1
  %t752 = load i8*, i8** %t751
  call void @star_rc_release(i8* %t752)
  %t753 = getelementptr inbounds %Item, %Item* %t460, i32 0, i32 1
  %t754 = load i8*, i8** %t753
  call void @star_rc_release(i8* %t754)
  %t755 = getelementptr inbounds %Item, %Item* %t430, i32 0, i32 1
  %t756 = load i8*, i8** %t755
  call void @star_rc_release(i8* %t756)
  %t757 = load i8*, i8** %t263
  call void @star_rc_release(i8* %t757)
  %t758 = getelementptr inbounds %Item, %Item* %t259, i32 0, i32 1
  %t759 = load i8*, i8** %t758
  call void @star_rc_release(i8* %t759)
  %t760 = getelementptr inbounds %Item, %Item* %t229, i32 0, i32 1
  %t761 = load i8*, i8** %t760
  call void @star_rc_release(i8* %t761)
  %t762 = getelementptr inbounds %Item, %Item* %t199, i32 0, i32 1
  %t763 = load i8*, i8** %t762
  call void @star_rc_release(i8* %t763)
  %t764 = getelementptr inbounds %Item, %Item* %t169, i32 0, i32 1
  %t765 = load i8*, i8** %t764
  call void @star_rc_release(i8* %t765)
  %t766 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t766)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Item(i8* %objp) {
entry:
  %t16 = alloca i64
  %t8 = bitcast i8* %objp to { i64, i64, i32*, i8** }*
  %t9 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t8, i32 0, i32 0
  %t10 = load i64, i64* %t9
  %t11 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t8, i32 0, i32 2
  %t12 = load i32*, i32** %t11
  %t13 = bitcast i32* %t12 to i8*
  call void @free(i8* %t13)
  %t14 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t8, i32 0, i32 3
  %t15 = load i8**, i8*** %t14
  store i64 0, i64* %t16
  br label %table_release_cond_7
table_release_cond_7:
  %t17 = load i64, i64* %t16
  %t18 = icmp slt i64 %t17, %t10
  br i1 %t18, label %table_release_body_8, label %table_release_end_9
table_release_body_8:
  %t19 = getelementptr inbounds i8*, i8** %t15, i64 %t17
  %t20 = load i8*, i8** %t19
  call void @star_rc_release(i8* %t20)
  %t21 = add i64 %t17, 1
  store i64 %t21, i64* %t16
  br label %table_release_cond_7
table_release_end_9:
  %t22 = bitcast i8** %t15 to i8*
  call void @free(i8* %t22)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [7 x i8] c"tag-%d\00"
@.str.1 = private unnamed_addr constant [10 x i8] c"len = %d\0A\00"
@.str.2 = private unnamed_addr constant [17 x i8] c"t[0] = %s hp=%d\0A\00"
@.str.3 = private unnamed_addr constant [20 x i8] c"t[4999] = %s hp=%d\0A\00"
@.str.4 = private unnamed_addr constant [9 x i8] c"clone-%d\00"
@.str.5 = private unnamed_addr constant [34 x i8] c"original len = %d clone len = %d\0A\00"
@.str.6 = private unnamed_addr constant [32 x i8] c"original[0] = %s clone[0] = %s\0A\00"
@.str.7 = private unnamed_addr constant [38 x i8] c"original[4999] = %s clone[4999] = %s\0A\00"
@.str.8 = private unnamed_addr constant [7 x i8] c"cyc-%d\00"
@.str.9 = private unnamed_addr constant [71 x i8] c"star runtime error: integer `%` by zero (or `i32::MIN % -1` overflow)\0A\00"
@.str.10 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"unexpected empty pop\00" }
@.str.11 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.12 = private unnamed_addr constant [17 x i8] c"cycler len = %d\0A\00"
