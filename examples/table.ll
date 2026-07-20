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

%Enemy = type { i32, i8* }
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
  %t80 = alloca i64
  %t96 = alloca %Enemy
  %t180 = alloca i64
  %t196 = alloca %Enemy
  %t280 = alloca i64
  %t296 = alloca %Enemy
  %t359 = alloca %Enemy
  %t372 = alloca %Enemy
  %t389 = alloca %Enemy
  %t402 = alloca %Enemy
  %t419 = alloca %Enemy
  %t432 = alloca %Enemy
  %t449 = alloca %Enemy
  %t462 = alloca %Enemy
  %t466 = alloca %Enemy
  %t520 = alloca i64
  %t542 = alloca %Enemy
  %t558 = alloca %Enemy
  %t571 = alloca %Enemy
  %t588 = alloca %Enemy
  %t601 = alloca %Enemy
  %t605 = alloca %Enemy
  %t654 = alloca i64
  %t670 = alloca %Enemy
  %t716 = alloca %Enemy
  %t729 = alloca %Enemy
  %t733 = alloca i8*
  %t734 = alloca %Enemy
  %t783 = alloca i64
  %t799 = alloca %Enemy
  %t815 = alloca i8*
  %t864 = alloca i64
  %t880 = alloca %Enemy
  %t916 = alloca i8*
  %t967 = alloca i64
  %t983 = alloca %Enemy
  %t1059 = alloca %Enemy
  %t1072 = alloca %Enemy
  %t1088 = alloca %Enemy
  %t1101 = alloca %Enemy
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i8* null, i8** %t2
  %t3 = load i8*, i8** %t2
  %t4 = icmp eq i8* %t3, null
  br i1 %t4, label %table_read_null_0, label %table_read_real_1
table_read_null_0:
  br label %table_read_end_2
table_read_real_1:
  %t5 = bitcast i8* %t3 to { i64, i64, i32*, i8** }*
  %t6 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t5, i32 0, i32 0
  %t7 = load i64, i64* %t6
  %t8 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t5, i32 0, i32 2
  %t9 = load i32*, i32** %t8
  %t10 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t5, i32 0, i32 3
  %t11 = load i8**, i8*** %t10
  br label %table_read_end_2
table_read_end_2:
  %t12 = phi i64 [ 0, %table_read_null_0 ], [ %t7, %table_read_real_1 ]
  %t13 = phi i32* [ null, %table_read_null_0 ], [ %t9, %table_read_real_1 ]
  %t14 = phi i8** [ null, %table_read_null_0 ], [ %t11, %table_read_real_1 ]
  %t15 = trunc i64 %t12 to i32
  %t16 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t16, i32 %t15)
  %t17 = load i8*, i8** %t2
  %t18 = icmp eq i8* %t17, null
  br i1 %t18, label %table_cow_alloc_3, label %table_cow_check_4
table_cow_alloc_3:
  %t34 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t35 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t36 = ptrtoint { i64, i64, i32*, i8** }* %t35 to i64
  %t37 = call i8* @star_rc_alloc(i64 %t36, i8* %t34)
  %t38 = bitcast i8* %t37 to { i64, i64, i32*, i8** }*
  %t39 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t38, i32 0, i32 0
  store i64 0, i64* %t39
  %t40 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t38, i32 0, i32 1
  store i64 0, i64* %t40
  %t41 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t38, i32 0, i32 2
  store i32* null, i32** %t41
  %t42 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t38, i32 0, i32 3
  store i8** null, i8*** %t42
  store i8* %t37, i8** %t2
  br label %table_cow_done_5
table_cow_check_4:
  %t43 = getelementptr inbounds i8, i8* %t17, i64 -16
  %t44 = bitcast i8* %t43 to i64*
  %t45 = load atomic i64, i64* %t44 seq_cst, align 8
  %t46 = icmp eq i64 %t45, 1
  br i1 %t46, label %table_cow_done_5, label %table_cow_clone_9
table_cow_clone_9:
  %t47 = bitcast i8* %t17 to { i64, i64, i32*, i8** }*
  %t48 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t47, i32 0, i32 0
  %t49 = load i64, i64* %t48
  %t50 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t47, i32 0, i32 1
  %t51 = load i64, i64* %t50
  %t52 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t53 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t54 = ptrtoint { i64, i64, i32*, i8** }* %t53 to i64
  %t55 = call i8* @star_rc_alloc(i64 %t54, i8* %t52)
  %t56 = bitcast i8* %t55 to { i64, i64, i32*, i8** }*
  %t57 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t56, i32 0, i32 0
  store i64 %t49, i64* %t57
  %t58 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t56, i32 0, i32 1
  store i64 %t51, i64* %t58
  %t59 = getelementptr i32, i32* null, i32 1
  %t60 = ptrtoint i32* %t59 to i64
  %t61 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t47, i32 0, i32 2
  %t62 = load i32*, i32** %t61
  %t63 = mul i64 %t51, %t60
  %t64 = call i8* @malloc(i64 %t63)
  %t65 = bitcast i8* %t64 to i32*
  %t66 = icmp sgt i64 %t49, 0
  br i1 %t66, label %table_cow_copy_10, label %table_cow_after_copy_11
table_cow_copy_10:
  %t67 = mul i64 %t49, %t60
  %t68 = bitcast i32* %t62 to i8*
  call i8* @memcpy(i8* %t64, i8* %t68, i64 %t67)
  br label %table_cow_after_copy_11
table_cow_after_copy_11:
  %t69 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t56, i32 0, i32 2
  store i32* %t65, i32** %t69
  %t70 = getelementptr i8*, i8** null, i32 1
  %t71 = ptrtoint i8** %t70 to i64
  %t72 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t47, i32 0, i32 3
  %t73 = load i8**, i8*** %t72
  %t74 = mul i64 %t51, %t71
  %t75 = call i8* @malloc(i64 %t74)
  %t76 = bitcast i8* %t75 to i8**
  %t77 = icmp sgt i64 %t49, 0
  br i1 %t77, label %table_cow_copy_12, label %table_cow_after_copy_13
table_cow_copy_12:
  %t78 = mul i64 %t49, %t71
  %t79 = bitcast i8** %t73 to i8*
  call i8* @memcpy(i8* %t75, i8* %t79, i64 %t78)
  store i64 0, i64* %t80
  br label %table_cow_retain_cond_14
table_cow_retain_cond_14:
  %t81 = load i64, i64* %t80
  %t82 = icmp slt i64 %t81, %t49
  br i1 %t82, label %table_cow_retain_body_15, label %table_cow_retain_end_16
table_cow_retain_body_15:
  %t83 = getelementptr inbounds i8*, i8** %t76, i64 %t81
  %t84 = load i8*, i8** %t83
  call void @star_rc_retain(i8* %t84)
  %t85 = add i64 %t81, 1
  store i64 %t85, i64* %t80
  br label %table_cow_retain_cond_14
table_cow_retain_end_16:
  br label %table_cow_after_copy_13
table_cow_after_copy_13:
  %t86 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t56, i32 0, i32 3
  store i8** %t76, i8*** %t86
  call void @star_rc_release(i8* %t17)
  store i8* %t55, i8** %t2
  br label %table_cow_done_5
table_cow_done_5:
  %t87 = load i8*, i8** %t2
  %t88 = bitcast i8* %t87 to { i64, i64, i32*, i8** }*
  %t89 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t88, i32 0, i32 0
  %t90 = load i64, i64* %t89
  %t91 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t88, i32 0, i32 1
  %t92 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t88, i32 0, i32 2
  %t93 = load i32*, i32** %t92
  %t94 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t88, i32 0, i32 3
  %t95 = load i8**, i8*** %t94
  %t97 = getelementptr inbounds %Enemy, %Enemy* %t96, i32 0, i32 0
  store i32 10, i32* %t97
  %t98 = getelementptr inbounds { i64, i8*, [7 x i8] }, { i64, i8*, [7 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t99 = getelementptr inbounds %Enemy, %Enemy* %t96, i32 0, i32 1
  store i8* %t98, i8** %t99
  %t100 = load %Enemy, %Enemy* %t96
  %t101 = load i64, i64* %t91
  %t102 = load i64, i64* %t89
  %t103 = load i32*, i32** %t92
  %t104 = load i8**, i8*** %t94
  %t105 = icmp sge i64 %t102, %t101
  br i1 %t105, label %table_push_grow_17, label %table_push_store_18
table_push_grow_17:
  %t106 = mul i64 %t101, 2
  %t107 = icmp sgt i64 %t106, 0
  %t108 = select i1 %t107, i64 %t106, i64 1
  %t109 = getelementptr i32, i32* null, i32 1
  %t110 = ptrtoint i32* %t109 to i64
  %t111 = mul i64 %t108, %t110
  %t112 = call i8* @malloc(i64 %t111)
  %t113 = bitcast i8* %t112 to i32*
  %t114 = icmp sgt i64 %t101, 0
  br i1 %t114, label %table_push_copy_19, label %table_push_after_copy_20
table_push_copy_19:
  %t115 = mul i64 %t102, %t110
  %t116 = bitcast i32* %t103 to i8*
  call i8* @memcpy(i8* %t112, i8* %t116, i64 %t115)
  call void @free(i8* %t116)
  br label %table_push_after_copy_20
table_push_after_copy_20:
  store i32* %t113, i32** %t92
  %t117 = getelementptr i8*, i8** null, i32 1
  %t118 = ptrtoint i8** %t117 to i64
  %t119 = mul i64 %t108, %t118
  %t120 = call i8* @malloc(i64 %t119)
  %t121 = bitcast i8* %t120 to i8**
  %t122 = icmp sgt i64 %t101, 0
  br i1 %t122, label %table_push_copy_21, label %table_push_after_copy_22
table_push_copy_21:
  %t123 = mul i64 %t102, %t118
  %t124 = bitcast i8** %t104 to i8*
  call i8* @memcpy(i8* %t120, i8* %t124, i64 %t123)
  call void @free(i8* %t124)
  br label %table_push_after_copy_22
table_push_after_copy_22:
  store i8** %t121, i8*** %t94
  store i64 %t108, i64* %t91
  br label %table_push_store_18
table_push_store_18:
  %t125 = load i32*, i32** %t92
  %t126 = extractvalue %Enemy %t100, 0
  %t127 = getelementptr inbounds i32, i32* %t125, i64 %t102
  store i32 %t126, i32* %t127
  %t128 = load i8**, i8*** %t94
  %t129 = extractvalue %Enemy %t100, 1
  %t130 = getelementptr inbounds i8*, i8** %t128, i64 %t102
  store i8* %t129, i8** %t130
  %t131 = add i64 %t102, 1
  store i64 %t131, i64* %t89
  %t132 = load i8*, i8** %t2
  %t133 = icmp eq i8* %t132, null
  br i1 %t133, label %table_cow_alloc_23, label %table_cow_check_24
table_cow_alloc_23:
  %t134 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t135 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t136 = ptrtoint { i64, i64, i32*, i8** }* %t135 to i64
  %t137 = call i8* @star_rc_alloc(i64 %t136, i8* %t134)
  %t138 = bitcast i8* %t137 to { i64, i64, i32*, i8** }*
  %t139 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t138, i32 0, i32 0
  store i64 0, i64* %t139
  %t140 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t138, i32 0, i32 1
  store i64 0, i64* %t140
  %t141 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t138, i32 0, i32 2
  store i32* null, i32** %t141
  %t142 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t138, i32 0, i32 3
  store i8** null, i8*** %t142
  store i8* %t137, i8** %t2
  br label %table_cow_done_25
table_cow_check_24:
  %t143 = getelementptr inbounds i8, i8* %t132, i64 -16
  %t144 = bitcast i8* %t143 to i64*
  %t145 = load atomic i64, i64* %t144 seq_cst, align 8
  %t146 = icmp eq i64 %t145, 1
  br i1 %t146, label %table_cow_done_25, label %table_cow_clone_26
table_cow_clone_26:
  %t147 = bitcast i8* %t132 to { i64, i64, i32*, i8** }*
  %t148 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t147, i32 0, i32 0
  %t149 = load i64, i64* %t148
  %t150 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t147, i32 0, i32 1
  %t151 = load i64, i64* %t150
  %t152 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t153 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t154 = ptrtoint { i64, i64, i32*, i8** }* %t153 to i64
  %t155 = call i8* @star_rc_alloc(i64 %t154, i8* %t152)
  %t156 = bitcast i8* %t155 to { i64, i64, i32*, i8** }*
  %t157 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t156, i32 0, i32 0
  store i64 %t149, i64* %t157
  %t158 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t156, i32 0, i32 1
  store i64 %t151, i64* %t158
  %t159 = getelementptr i32, i32* null, i32 1
  %t160 = ptrtoint i32* %t159 to i64
  %t161 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t147, i32 0, i32 2
  %t162 = load i32*, i32** %t161
  %t163 = mul i64 %t151, %t160
  %t164 = call i8* @malloc(i64 %t163)
  %t165 = bitcast i8* %t164 to i32*
  %t166 = icmp sgt i64 %t149, 0
  br i1 %t166, label %table_cow_copy_27, label %table_cow_after_copy_28
table_cow_copy_27:
  %t167 = mul i64 %t149, %t160
  %t168 = bitcast i32* %t162 to i8*
  call i8* @memcpy(i8* %t164, i8* %t168, i64 %t167)
  br label %table_cow_after_copy_28
table_cow_after_copy_28:
  %t169 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t156, i32 0, i32 2
  store i32* %t165, i32** %t169
  %t170 = getelementptr i8*, i8** null, i32 1
  %t171 = ptrtoint i8** %t170 to i64
  %t172 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t147, i32 0, i32 3
  %t173 = load i8**, i8*** %t172
  %t174 = mul i64 %t151, %t171
  %t175 = call i8* @malloc(i64 %t174)
  %t176 = bitcast i8* %t175 to i8**
  %t177 = icmp sgt i64 %t149, 0
  br i1 %t177, label %table_cow_copy_29, label %table_cow_after_copy_30
table_cow_copy_29:
  %t178 = mul i64 %t149, %t171
  %t179 = bitcast i8** %t173 to i8*
  call i8* @memcpy(i8* %t175, i8* %t179, i64 %t178)
  store i64 0, i64* %t180
  br label %table_cow_retain_cond_31
table_cow_retain_cond_31:
  %t181 = load i64, i64* %t180
  %t182 = icmp slt i64 %t181, %t149
  br i1 %t182, label %table_cow_retain_body_32, label %table_cow_retain_end_33
table_cow_retain_body_32:
  %t183 = getelementptr inbounds i8*, i8** %t176, i64 %t181
  %t184 = load i8*, i8** %t183
  call void @star_rc_retain(i8* %t184)
  %t185 = add i64 %t181, 1
  store i64 %t185, i64* %t180
  br label %table_cow_retain_cond_31
table_cow_retain_end_33:
  br label %table_cow_after_copy_30
table_cow_after_copy_30:
  %t186 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t156, i32 0, i32 3
  store i8** %t176, i8*** %t186
  call void @star_rc_release(i8* %t132)
  store i8* %t155, i8** %t2
  br label %table_cow_done_25
table_cow_done_25:
  %t187 = load i8*, i8** %t2
  %t188 = bitcast i8* %t187 to { i64, i64, i32*, i8** }*
  %t189 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t188, i32 0, i32 0
  %t190 = load i64, i64* %t189
  %t191 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t188, i32 0, i32 1
  %t192 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t188, i32 0, i32 2
  %t193 = load i32*, i32** %t192
  %t194 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t188, i32 0, i32 3
  %t195 = load i8**, i8*** %t194
  %t197 = getelementptr inbounds %Enemy, %Enemy* %t196, i32 0, i32 0
  store i32 20, i32* %t197
  %t198 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t199 = getelementptr inbounds %Enemy, %Enemy* %t196, i32 0, i32 1
  store i8* %t198, i8** %t199
  %t200 = load %Enemy, %Enemy* %t196
  %t201 = load i64, i64* %t191
  %t202 = load i64, i64* %t189
  %t203 = load i32*, i32** %t192
  %t204 = load i8**, i8*** %t194
  %t205 = icmp sge i64 %t202, %t201
  br i1 %t205, label %table_push_grow_34, label %table_push_store_35
table_push_grow_34:
  %t206 = mul i64 %t201, 2
  %t207 = icmp sgt i64 %t206, 0
  %t208 = select i1 %t207, i64 %t206, i64 1
  %t209 = getelementptr i32, i32* null, i32 1
  %t210 = ptrtoint i32* %t209 to i64
  %t211 = mul i64 %t208, %t210
  %t212 = call i8* @malloc(i64 %t211)
  %t213 = bitcast i8* %t212 to i32*
  %t214 = icmp sgt i64 %t201, 0
  br i1 %t214, label %table_push_copy_36, label %table_push_after_copy_37
table_push_copy_36:
  %t215 = mul i64 %t202, %t210
  %t216 = bitcast i32* %t203 to i8*
  call i8* @memcpy(i8* %t212, i8* %t216, i64 %t215)
  call void @free(i8* %t216)
  br label %table_push_after_copy_37
table_push_after_copy_37:
  store i32* %t213, i32** %t192
  %t217 = getelementptr i8*, i8** null, i32 1
  %t218 = ptrtoint i8** %t217 to i64
  %t219 = mul i64 %t208, %t218
  %t220 = call i8* @malloc(i64 %t219)
  %t221 = bitcast i8* %t220 to i8**
  %t222 = icmp sgt i64 %t201, 0
  br i1 %t222, label %table_push_copy_38, label %table_push_after_copy_39
table_push_copy_38:
  %t223 = mul i64 %t202, %t218
  %t224 = bitcast i8** %t204 to i8*
  call i8* @memcpy(i8* %t220, i8* %t224, i64 %t223)
  call void @free(i8* %t224)
  br label %table_push_after_copy_39
table_push_after_copy_39:
  store i8** %t221, i8*** %t194
  store i64 %t208, i64* %t191
  br label %table_push_store_35
table_push_store_35:
  %t225 = load i32*, i32** %t192
  %t226 = extractvalue %Enemy %t200, 0
  %t227 = getelementptr inbounds i32, i32* %t225, i64 %t202
  store i32 %t226, i32* %t227
  %t228 = load i8**, i8*** %t194
  %t229 = extractvalue %Enemy %t200, 1
  %t230 = getelementptr inbounds i8*, i8** %t228, i64 %t202
  store i8* %t229, i8** %t230
  %t231 = add i64 %t202, 1
  store i64 %t231, i64* %t189
  %t232 = load i8*, i8** %t2
  %t233 = icmp eq i8* %t232, null
  br i1 %t233, label %table_cow_alloc_40, label %table_cow_check_41
table_cow_alloc_40:
  %t234 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t235 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t236 = ptrtoint { i64, i64, i32*, i8** }* %t235 to i64
  %t237 = call i8* @star_rc_alloc(i64 %t236, i8* %t234)
  %t238 = bitcast i8* %t237 to { i64, i64, i32*, i8** }*
  %t239 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t238, i32 0, i32 0
  store i64 0, i64* %t239
  %t240 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t238, i32 0, i32 1
  store i64 0, i64* %t240
  %t241 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t238, i32 0, i32 2
  store i32* null, i32** %t241
  %t242 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t238, i32 0, i32 3
  store i8** null, i8*** %t242
  store i8* %t237, i8** %t2
  br label %table_cow_done_42
table_cow_check_41:
  %t243 = getelementptr inbounds i8, i8* %t232, i64 -16
  %t244 = bitcast i8* %t243 to i64*
  %t245 = load atomic i64, i64* %t244 seq_cst, align 8
  %t246 = icmp eq i64 %t245, 1
  br i1 %t246, label %table_cow_done_42, label %table_cow_clone_43
table_cow_clone_43:
  %t247 = bitcast i8* %t232 to { i64, i64, i32*, i8** }*
  %t248 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t247, i32 0, i32 0
  %t249 = load i64, i64* %t248
  %t250 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t247, i32 0, i32 1
  %t251 = load i64, i64* %t250
  %t252 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t253 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t254 = ptrtoint { i64, i64, i32*, i8** }* %t253 to i64
  %t255 = call i8* @star_rc_alloc(i64 %t254, i8* %t252)
  %t256 = bitcast i8* %t255 to { i64, i64, i32*, i8** }*
  %t257 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t256, i32 0, i32 0
  store i64 %t249, i64* %t257
  %t258 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t256, i32 0, i32 1
  store i64 %t251, i64* %t258
  %t259 = getelementptr i32, i32* null, i32 1
  %t260 = ptrtoint i32* %t259 to i64
  %t261 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t247, i32 0, i32 2
  %t262 = load i32*, i32** %t261
  %t263 = mul i64 %t251, %t260
  %t264 = call i8* @malloc(i64 %t263)
  %t265 = bitcast i8* %t264 to i32*
  %t266 = icmp sgt i64 %t249, 0
  br i1 %t266, label %table_cow_copy_44, label %table_cow_after_copy_45
table_cow_copy_44:
  %t267 = mul i64 %t249, %t260
  %t268 = bitcast i32* %t262 to i8*
  call i8* @memcpy(i8* %t264, i8* %t268, i64 %t267)
  br label %table_cow_after_copy_45
table_cow_after_copy_45:
  %t269 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t256, i32 0, i32 2
  store i32* %t265, i32** %t269
  %t270 = getelementptr i8*, i8** null, i32 1
  %t271 = ptrtoint i8** %t270 to i64
  %t272 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t247, i32 0, i32 3
  %t273 = load i8**, i8*** %t272
  %t274 = mul i64 %t251, %t271
  %t275 = call i8* @malloc(i64 %t274)
  %t276 = bitcast i8* %t275 to i8**
  %t277 = icmp sgt i64 %t249, 0
  br i1 %t277, label %table_cow_copy_46, label %table_cow_after_copy_47
table_cow_copy_46:
  %t278 = mul i64 %t249, %t271
  %t279 = bitcast i8** %t273 to i8*
  call i8* @memcpy(i8* %t275, i8* %t279, i64 %t278)
  store i64 0, i64* %t280
  br label %table_cow_retain_cond_48
table_cow_retain_cond_48:
  %t281 = load i64, i64* %t280
  %t282 = icmp slt i64 %t281, %t249
  br i1 %t282, label %table_cow_retain_body_49, label %table_cow_retain_end_50
table_cow_retain_body_49:
  %t283 = getelementptr inbounds i8*, i8** %t276, i64 %t281
  %t284 = load i8*, i8** %t283
  call void @star_rc_retain(i8* %t284)
  %t285 = add i64 %t281, 1
  store i64 %t285, i64* %t280
  br label %table_cow_retain_cond_48
table_cow_retain_end_50:
  br label %table_cow_after_copy_47
table_cow_after_copy_47:
  %t286 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t256, i32 0, i32 3
  store i8** %t276, i8*** %t286
  call void @star_rc_release(i8* %t232)
  store i8* %t255, i8** %t2
  br label %table_cow_done_42
table_cow_done_42:
  %t287 = load i8*, i8** %t2
  %t288 = bitcast i8* %t287 to { i64, i64, i32*, i8** }*
  %t289 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t288, i32 0, i32 0
  %t290 = load i64, i64* %t289
  %t291 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t288, i32 0, i32 1
  %t292 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t288, i32 0, i32 2
  %t293 = load i32*, i32** %t292
  %t294 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t288, i32 0, i32 3
  %t295 = load i8**, i8*** %t294
  %t297 = getelementptr inbounds %Enemy, %Enemy* %t296, i32 0, i32 0
  store i32 30, i32* %t297
  %t298 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.3, i64 0, i32 2, i64 0
  %t299 = getelementptr inbounds %Enemy, %Enemy* %t296, i32 0, i32 1
  store i8* %t298, i8** %t299
  %t300 = load %Enemy, %Enemy* %t296
  %t301 = load i64, i64* %t291
  %t302 = load i64, i64* %t289
  %t303 = load i32*, i32** %t292
  %t304 = load i8**, i8*** %t294
  %t305 = icmp sge i64 %t302, %t301
  br i1 %t305, label %table_push_grow_51, label %table_push_store_52
table_push_grow_51:
  %t306 = mul i64 %t301, 2
  %t307 = icmp sgt i64 %t306, 0
  %t308 = select i1 %t307, i64 %t306, i64 1
  %t309 = getelementptr i32, i32* null, i32 1
  %t310 = ptrtoint i32* %t309 to i64
  %t311 = mul i64 %t308, %t310
  %t312 = call i8* @malloc(i64 %t311)
  %t313 = bitcast i8* %t312 to i32*
  %t314 = icmp sgt i64 %t301, 0
  br i1 %t314, label %table_push_copy_53, label %table_push_after_copy_54
table_push_copy_53:
  %t315 = mul i64 %t302, %t310
  %t316 = bitcast i32* %t303 to i8*
  call i8* @memcpy(i8* %t312, i8* %t316, i64 %t315)
  call void @free(i8* %t316)
  br label %table_push_after_copy_54
table_push_after_copy_54:
  store i32* %t313, i32** %t292
  %t317 = getelementptr i8*, i8** null, i32 1
  %t318 = ptrtoint i8** %t317 to i64
  %t319 = mul i64 %t308, %t318
  %t320 = call i8* @malloc(i64 %t319)
  %t321 = bitcast i8* %t320 to i8**
  %t322 = icmp sgt i64 %t301, 0
  br i1 %t322, label %table_push_copy_55, label %table_push_after_copy_56
table_push_copy_55:
  %t323 = mul i64 %t302, %t318
  %t324 = bitcast i8** %t304 to i8*
  call i8* @memcpy(i8* %t320, i8* %t324, i64 %t323)
  call void @free(i8* %t324)
  br label %table_push_after_copy_56
table_push_after_copy_56:
  store i8** %t321, i8*** %t294
  store i64 %t308, i64* %t291
  br label %table_push_store_52
table_push_store_52:
  %t325 = load i32*, i32** %t292
  %t326 = extractvalue %Enemy %t300, 0
  %t327 = getelementptr inbounds i32, i32* %t325, i64 %t302
  store i32 %t326, i32* %t327
  %t328 = load i8**, i8*** %t294
  %t329 = extractvalue %Enemy %t300, 1
  %t330 = getelementptr inbounds i8*, i8** %t328, i64 %t302
  store i8* %t329, i8** %t330
  %t331 = add i64 %t302, 1
  store i64 %t331, i64* %t289
  %t332 = load i8*, i8** %t2
  %t333 = icmp eq i8* %t332, null
  br i1 %t333, label %table_read_null_57, label %table_read_real_58
table_read_null_57:
  br label %table_read_end_59
table_read_real_58:
  %t334 = bitcast i8* %t332 to { i64, i64, i32*, i8** }*
  %t335 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t334, i32 0, i32 0
  %t336 = load i64, i64* %t335
  %t337 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t334, i32 0, i32 2
  %t338 = load i32*, i32** %t337
  %t339 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t334, i32 0, i32 3
  %t340 = load i8**, i8*** %t339
  br label %table_read_end_59
table_read_end_59:
  %t341 = phi i64 [ 0, %table_read_null_57 ], [ %t336, %table_read_real_58 ]
  %t342 = phi i32* [ null, %table_read_null_57 ], [ %t338, %table_read_real_58 ]
  %t343 = phi i8** [ null, %table_read_null_57 ], [ %t340, %table_read_real_58 ]
  %t344 = trunc i64 %t341 to i32
  %t345 = getelementptr inbounds [25 x i8], [25 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t345, i32 %t344)
  %t346 = sext i32 0 to i64
  %t347 = load i8*, i8** %t2
  %t348 = icmp eq i8* %t347, null
  br i1 %t348, label %table_read_null_60, label %table_read_real_61
table_read_null_60:
  br label %table_read_end_62
table_read_real_61:
  %t349 = bitcast i8* %t347 to { i64, i64, i32*, i8** }*
  %t350 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t349, i32 0, i32 0
  %t351 = load i64, i64* %t350
  %t352 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t349, i32 0, i32 2
  %t353 = load i32*, i32** %t352
  %t354 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t349, i32 0, i32 3
  %t355 = load i8**, i8*** %t354
  br label %table_read_end_62
table_read_end_62:
  %t356 = phi i64 [ 0, %table_read_null_60 ], [ %t351, %table_read_real_61 ]
  %t357 = phi i32* [ null, %table_read_null_60 ], [ %t353, %table_read_real_61 ]
  %t358 = phi i8** [ null, %table_read_null_60 ], [ %t355, %table_read_real_61 ]
  %t360 = icmp ult i64 %t346, %t356
  br i1 %t360, label %table_idx_ok_63, label %table_idx_oob_64
table_idx_ok_63:
  %t361 = getelementptr inbounds i32, i32* %t357, i64 %t346
  %t362 = load i32, i32* %t361
  %t363 = getelementptr inbounds %Enemy, %Enemy* %t359, i32 0, i32 0
  store i32 %t362, i32* %t363
  %t364 = getelementptr inbounds i8*, i8** %t358, i64 %t346
  %t365 = load i8*, i8** %t364
  call void @star_rc_retain(i8* %t365)
  %t366 = load i8*, i8** %t364
  %t367 = getelementptr inbounds %Enemy, %Enemy* %t359, i32 0, i32 1
  store i8* %t366, i8** %t367
  br label %table_idx_end_65
table_idx_oob_64:
  %t368 = getelementptr inbounds %Enemy, %Enemy* %t359, i32 0, i32 0
  store i32 0, i32* %t368
  %t369 = getelementptr inbounds %Enemy, %Enemy* %t359, i32 0, i32 1
  %t370 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t370
  store i8* %t370, i8** %t369
  br label %table_idx_end_65
table_idx_end_65:
  %t371 = load %Enemy, %Enemy* %t359
  store %Enemy %t371, %Enemy* %t372
  %t373 = getelementptr inbounds %Enemy, %Enemy* %t372, i32 0, i32 1
  %t374 = load i8*, i8** %t373
  %t375 = load i8*, i8** %t373
  call void @star_rc_retain(i8* %t375)
  call void @star_rc_release(i8* %t374)
  %t376 = sext i32 0 to i64
  %t377 = load i8*, i8** %t2
  %t378 = icmp eq i8* %t377, null
  br i1 %t378, label %table_read_null_66, label %table_read_real_67
table_read_null_66:
  br label %table_read_end_68
table_read_real_67:
  %t379 = bitcast i8* %t377 to { i64, i64, i32*, i8** }*
  %t380 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 0
  %t381 = load i64, i64* %t380
  %t382 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 2
  %t383 = load i32*, i32** %t382
  %t384 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t379, i32 0, i32 3
  %t385 = load i8**, i8*** %t384
  br label %table_read_end_68
table_read_end_68:
  %t386 = phi i64 [ 0, %table_read_null_66 ], [ %t381, %table_read_real_67 ]
  %t387 = phi i32* [ null, %table_read_null_66 ], [ %t383, %table_read_real_67 ]
  %t388 = phi i8** [ null, %table_read_null_66 ], [ %t385, %table_read_real_67 ]
  %t390 = icmp ult i64 %t376, %t386
  br i1 %t390, label %table_idx_ok_69, label %table_idx_oob_70
table_idx_ok_69:
  %t391 = getelementptr inbounds i32, i32* %t387, i64 %t376
  %t392 = load i32, i32* %t391
  %t393 = getelementptr inbounds %Enemy, %Enemy* %t389, i32 0, i32 0
  store i32 %t392, i32* %t393
  %t394 = getelementptr inbounds i8*, i8** %t388, i64 %t376
  %t395 = load i8*, i8** %t394
  call void @star_rc_retain(i8* %t395)
  %t396 = load i8*, i8** %t394
  %t397 = getelementptr inbounds %Enemy, %Enemy* %t389, i32 0, i32 1
  store i8* %t396, i8** %t397
  br label %table_idx_end_71
table_idx_oob_70:
  %t398 = getelementptr inbounds %Enemy, %Enemy* %t389, i32 0, i32 0
  store i32 0, i32* %t398
  %t399 = getelementptr inbounds %Enemy, %Enemy* %t389, i32 0, i32 1
  %t400 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t400
  store i8* %t400, i8** %t399
  br label %table_idx_end_71
table_idx_end_71:
  %t401 = load %Enemy, %Enemy* %t389
  store %Enemy %t401, %Enemy* %t402
  %t403 = getelementptr inbounds %Enemy, %Enemy* %t402, i32 0, i32 0
  %t404 = load i32, i32* %t403
  %t405 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t405, i8* %t374, i32 %t404)
  %t406 = sext i32 2 to i64
  %t407 = load i8*, i8** %t2
  %t408 = icmp eq i8* %t407, null
  br i1 %t408, label %table_read_null_72, label %table_read_real_73
table_read_null_72:
  br label %table_read_end_74
table_read_real_73:
  %t409 = bitcast i8* %t407 to { i64, i64, i32*, i8** }*
  %t410 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t409, i32 0, i32 0
  %t411 = load i64, i64* %t410
  %t412 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t409, i32 0, i32 2
  %t413 = load i32*, i32** %t412
  %t414 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t409, i32 0, i32 3
  %t415 = load i8**, i8*** %t414
  br label %table_read_end_74
table_read_end_74:
  %t416 = phi i64 [ 0, %table_read_null_72 ], [ %t411, %table_read_real_73 ]
  %t417 = phi i32* [ null, %table_read_null_72 ], [ %t413, %table_read_real_73 ]
  %t418 = phi i8** [ null, %table_read_null_72 ], [ %t415, %table_read_real_73 ]
  %t420 = icmp ult i64 %t406, %t416
  br i1 %t420, label %table_idx_ok_75, label %table_idx_oob_76
table_idx_ok_75:
  %t421 = getelementptr inbounds i32, i32* %t417, i64 %t406
  %t422 = load i32, i32* %t421
  %t423 = getelementptr inbounds %Enemy, %Enemy* %t419, i32 0, i32 0
  store i32 %t422, i32* %t423
  %t424 = getelementptr inbounds i8*, i8** %t418, i64 %t406
  %t425 = load i8*, i8** %t424
  call void @star_rc_retain(i8* %t425)
  %t426 = load i8*, i8** %t424
  %t427 = getelementptr inbounds %Enemy, %Enemy* %t419, i32 0, i32 1
  store i8* %t426, i8** %t427
  br label %table_idx_end_77
table_idx_oob_76:
  %t428 = getelementptr inbounds %Enemy, %Enemy* %t419, i32 0, i32 0
  store i32 0, i32* %t428
  %t429 = getelementptr inbounds %Enemy, %Enemy* %t419, i32 0, i32 1
  %t430 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t430
  store i8* %t430, i8** %t429
  br label %table_idx_end_77
table_idx_end_77:
  %t431 = load %Enemy, %Enemy* %t419
  store %Enemy %t431, %Enemy* %t432
  %t433 = getelementptr inbounds %Enemy, %Enemy* %t432, i32 0, i32 1
  %t434 = load i8*, i8** %t433
  %t435 = load i8*, i8** %t433
  call void @star_rc_retain(i8* %t435)
  call void @star_rc_release(i8* %t434)
  %t436 = sext i32 2 to i64
  %t437 = load i8*, i8** %t2
  %t438 = icmp eq i8* %t437, null
  br i1 %t438, label %table_read_null_78, label %table_read_real_79
table_read_null_78:
  br label %table_read_end_80
table_read_real_79:
  %t439 = bitcast i8* %t437 to { i64, i64, i32*, i8** }*
  %t440 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t439, i32 0, i32 0
  %t441 = load i64, i64* %t440
  %t442 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t439, i32 0, i32 2
  %t443 = load i32*, i32** %t442
  %t444 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t439, i32 0, i32 3
  %t445 = load i8**, i8*** %t444
  br label %table_read_end_80
table_read_end_80:
  %t446 = phi i64 [ 0, %table_read_null_78 ], [ %t441, %table_read_real_79 ]
  %t447 = phi i32* [ null, %table_read_null_78 ], [ %t443, %table_read_real_79 ]
  %t448 = phi i8** [ null, %table_read_null_78 ], [ %t445, %table_read_real_79 ]
  %t450 = icmp ult i64 %t436, %t446
  br i1 %t450, label %table_idx_ok_81, label %table_idx_oob_82
table_idx_ok_81:
  %t451 = getelementptr inbounds i32, i32* %t447, i64 %t436
  %t452 = load i32, i32* %t451
  %t453 = getelementptr inbounds %Enemy, %Enemy* %t449, i32 0, i32 0
  store i32 %t452, i32* %t453
  %t454 = getelementptr inbounds i8*, i8** %t448, i64 %t436
  %t455 = load i8*, i8** %t454
  call void @star_rc_retain(i8* %t455)
  %t456 = load i8*, i8** %t454
  %t457 = getelementptr inbounds %Enemy, %Enemy* %t449, i32 0, i32 1
  store i8* %t456, i8** %t457
  br label %table_idx_end_83
table_idx_oob_82:
  %t458 = getelementptr inbounds %Enemy, %Enemy* %t449, i32 0, i32 0
  store i32 0, i32* %t458
  %t459 = getelementptr inbounds %Enemy, %Enemy* %t449, i32 0, i32 1
  %t460 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t460
  store i8* %t460, i8** %t459
  br label %table_idx_end_83
table_idx_end_83:
  %t461 = load %Enemy, %Enemy* %t449
  store %Enemy %t461, %Enemy* %t462
  %t463 = getelementptr inbounds %Enemy, %Enemy* %t462, i32 0, i32 0
  %t464 = load i32, i32* %t463
  %t465 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t465, i8* %t434, i32 %t464)
  %t467 = getelementptr inbounds %Enemy, %Enemy* %t466, i32 0, i32 0
  store i32 99, i32* %t467
  %t468 = getelementptr inbounds { i64, i8*, [10 x i8] }, { i64, i8*, [10 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t469 = getelementptr inbounds %Enemy, %Enemy* %t466, i32 0, i32 1
  store i8* %t468, i8** %t469
  %t470 = load %Enemy, %Enemy* %t466
  %t471 = sext i32 1 to i64
  %t472 = load i8*, i8** %t2
  %t473 = icmp eq i8* %t472, null
  br i1 %t473, label %table_cow_alloc_84, label %table_cow_check_85
table_cow_alloc_84:
  %t474 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t475 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t476 = ptrtoint { i64, i64, i32*, i8** }* %t475 to i64
  %t477 = call i8* @star_rc_alloc(i64 %t476, i8* %t474)
  %t478 = bitcast i8* %t477 to { i64, i64, i32*, i8** }*
  %t479 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t478, i32 0, i32 0
  store i64 0, i64* %t479
  %t480 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t478, i32 0, i32 1
  store i64 0, i64* %t480
  %t481 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t478, i32 0, i32 2
  store i32* null, i32** %t481
  %t482 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t478, i32 0, i32 3
  store i8** null, i8*** %t482
  store i8* %t477, i8** %t2
  br label %table_cow_done_86
table_cow_check_85:
  %t483 = getelementptr inbounds i8, i8* %t472, i64 -16
  %t484 = bitcast i8* %t483 to i64*
  %t485 = load atomic i64, i64* %t484 seq_cst, align 8
  %t486 = icmp eq i64 %t485, 1
  br i1 %t486, label %table_cow_done_86, label %table_cow_clone_87
table_cow_clone_87:
  %t487 = bitcast i8* %t472 to { i64, i64, i32*, i8** }*
  %t488 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t487, i32 0, i32 0
  %t489 = load i64, i64* %t488
  %t490 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t487, i32 0, i32 1
  %t491 = load i64, i64* %t490
  %t492 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t493 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t494 = ptrtoint { i64, i64, i32*, i8** }* %t493 to i64
  %t495 = call i8* @star_rc_alloc(i64 %t494, i8* %t492)
  %t496 = bitcast i8* %t495 to { i64, i64, i32*, i8** }*
  %t497 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t496, i32 0, i32 0
  store i64 %t489, i64* %t497
  %t498 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t496, i32 0, i32 1
  store i64 %t491, i64* %t498
  %t499 = getelementptr i32, i32* null, i32 1
  %t500 = ptrtoint i32* %t499 to i64
  %t501 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t487, i32 0, i32 2
  %t502 = load i32*, i32** %t501
  %t503 = mul i64 %t491, %t500
  %t504 = call i8* @malloc(i64 %t503)
  %t505 = bitcast i8* %t504 to i32*
  %t506 = icmp sgt i64 %t489, 0
  br i1 %t506, label %table_cow_copy_88, label %table_cow_after_copy_89
table_cow_copy_88:
  %t507 = mul i64 %t489, %t500
  %t508 = bitcast i32* %t502 to i8*
  call i8* @memcpy(i8* %t504, i8* %t508, i64 %t507)
  br label %table_cow_after_copy_89
table_cow_after_copy_89:
  %t509 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t496, i32 0, i32 2
  store i32* %t505, i32** %t509
  %t510 = getelementptr i8*, i8** null, i32 1
  %t511 = ptrtoint i8** %t510 to i64
  %t512 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t487, i32 0, i32 3
  %t513 = load i8**, i8*** %t512
  %t514 = mul i64 %t491, %t511
  %t515 = call i8* @malloc(i64 %t514)
  %t516 = bitcast i8* %t515 to i8**
  %t517 = icmp sgt i64 %t489, 0
  br i1 %t517, label %table_cow_copy_90, label %table_cow_after_copy_91
table_cow_copy_90:
  %t518 = mul i64 %t489, %t511
  %t519 = bitcast i8** %t513 to i8*
  call i8* @memcpy(i8* %t515, i8* %t519, i64 %t518)
  store i64 0, i64* %t520
  br label %table_cow_retain_cond_92
table_cow_retain_cond_92:
  %t521 = load i64, i64* %t520
  %t522 = icmp slt i64 %t521, %t489
  br i1 %t522, label %table_cow_retain_body_93, label %table_cow_retain_end_94
table_cow_retain_body_93:
  %t523 = getelementptr inbounds i8*, i8** %t516, i64 %t521
  %t524 = load i8*, i8** %t523
  call void @star_rc_retain(i8* %t524)
  %t525 = add i64 %t521, 1
  store i64 %t525, i64* %t520
  br label %table_cow_retain_cond_92
table_cow_retain_end_94:
  br label %table_cow_after_copy_91
table_cow_after_copy_91:
  %t526 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t496, i32 0, i32 3
  store i8** %t516, i8*** %t526
  call void @star_rc_release(i8* %t472)
  store i8* %t495, i8** %t2
  br label %table_cow_done_86
table_cow_done_86:
  %t527 = load i8*, i8** %t2
  %t528 = bitcast i8* %t527 to { i64, i64, i32*, i8** }*
  %t529 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t528, i32 0, i32 0
  %t530 = load i64, i64* %t529
  %t531 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t528, i32 0, i32 1
  %t532 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t528, i32 0, i32 2
  %t533 = load i32*, i32** %t532
  %t534 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t528, i32 0, i32 3
  %t535 = load i8**, i8*** %t534
  %t536 = icmp ult i64 %t471, %t530
  br i1 %t536, label %table_set_do_95, label %table_set_oob_96
table_set_do_95:
  %t537 = extractvalue %Enemy %t470, 0
  %t538 = getelementptr inbounds i32, i32* %t533, i64 %t471
  store i32 %t537, i32* %t538
  %t539 = extractvalue %Enemy %t470, 1
  %t540 = getelementptr inbounds i8*, i8** %t535, i64 %t471
  %t541 = load i8*, i8** %t540
  call void @star_rc_release(i8* %t541)
  store i8* %t539, i8** %t540
  br label %table_set_end_97
table_set_oob_96:
  store %Enemy %t470, %Enemy* %t542
  %t543 = getelementptr inbounds %Enemy, %Enemy* %t542, i32 0, i32 1
  %t544 = load i8*, i8** %t543
  call void @star_rc_release(i8* %t544)
  br label %table_set_end_97
table_set_end_97:
  %t545 = sext i32 1 to i64
  %t546 = load i8*, i8** %t2
  %t547 = icmp eq i8* %t546, null
  br i1 %t547, label %table_read_null_98, label %table_read_real_99
table_read_null_98:
  br label %table_read_end_100
table_read_real_99:
  %t548 = bitcast i8* %t546 to { i64, i64, i32*, i8** }*
  %t549 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t548, i32 0, i32 0
  %t550 = load i64, i64* %t549
  %t551 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t548, i32 0, i32 2
  %t552 = load i32*, i32** %t551
  %t553 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t548, i32 0, i32 3
  %t554 = load i8**, i8*** %t553
  br label %table_read_end_100
table_read_end_100:
  %t555 = phi i64 [ 0, %table_read_null_98 ], [ %t550, %table_read_real_99 ]
  %t556 = phi i32* [ null, %table_read_null_98 ], [ %t552, %table_read_real_99 ]
  %t557 = phi i8** [ null, %table_read_null_98 ], [ %t554, %table_read_real_99 ]
  %t559 = icmp ult i64 %t545, %t555
  br i1 %t559, label %table_idx_ok_101, label %table_idx_oob_102
table_idx_ok_101:
  %t560 = getelementptr inbounds i32, i32* %t556, i64 %t545
  %t561 = load i32, i32* %t560
  %t562 = getelementptr inbounds %Enemy, %Enemy* %t558, i32 0, i32 0
  store i32 %t561, i32* %t562
  %t563 = getelementptr inbounds i8*, i8** %t557, i64 %t545
  %t564 = load i8*, i8** %t563
  call void @star_rc_retain(i8* %t564)
  %t565 = load i8*, i8** %t563
  %t566 = getelementptr inbounds %Enemy, %Enemy* %t558, i32 0, i32 1
  store i8* %t565, i8** %t566
  br label %table_idx_end_103
table_idx_oob_102:
  %t567 = getelementptr inbounds %Enemy, %Enemy* %t558, i32 0, i32 0
  store i32 0, i32* %t567
  %t568 = getelementptr inbounds %Enemy, %Enemy* %t558, i32 0, i32 1
  %t569 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t569
  store i8* %t569, i8** %t568
  br label %table_idx_end_103
table_idx_end_103:
  %t570 = load %Enemy, %Enemy* %t558
  store %Enemy %t570, %Enemy* %t571
  %t572 = getelementptr inbounds %Enemy, %Enemy* %t571, i32 0, i32 1
  %t573 = load i8*, i8** %t572
  %t574 = load i8*, i8** %t572
  call void @star_rc_retain(i8* %t574)
  call void @star_rc_release(i8* %t573)
  %t575 = sext i32 1 to i64
  %t576 = load i8*, i8** %t2
  %t577 = icmp eq i8* %t576, null
  br i1 %t577, label %table_read_null_104, label %table_read_real_105
table_read_null_104:
  br label %table_read_end_106
table_read_real_105:
  %t578 = bitcast i8* %t576 to { i64, i64, i32*, i8** }*
  %t579 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t578, i32 0, i32 0
  %t580 = load i64, i64* %t579
  %t581 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t578, i32 0, i32 2
  %t582 = load i32*, i32** %t581
  %t583 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t578, i32 0, i32 3
  %t584 = load i8**, i8*** %t583
  br label %table_read_end_106
table_read_end_106:
  %t585 = phi i64 [ 0, %table_read_null_104 ], [ %t580, %table_read_real_105 ]
  %t586 = phi i32* [ null, %table_read_null_104 ], [ %t582, %table_read_real_105 ]
  %t587 = phi i8** [ null, %table_read_null_104 ], [ %t584, %table_read_real_105 ]
  %t589 = icmp ult i64 %t575, %t585
  br i1 %t589, label %table_idx_ok_107, label %table_idx_oob_108
table_idx_ok_107:
  %t590 = getelementptr inbounds i32, i32* %t586, i64 %t575
  %t591 = load i32, i32* %t590
  %t592 = getelementptr inbounds %Enemy, %Enemy* %t588, i32 0, i32 0
  store i32 %t591, i32* %t592
  %t593 = getelementptr inbounds i8*, i8** %t587, i64 %t575
  %t594 = load i8*, i8** %t593
  call void @star_rc_retain(i8* %t594)
  %t595 = load i8*, i8** %t593
  %t596 = getelementptr inbounds %Enemy, %Enemy* %t588, i32 0, i32 1
  store i8* %t595, i8** %t596
  br label %table_idx_end_109
table_idx_oob_108:
  %t597 = getelementptr inbounds %Enemy, %Enemy* %t588, i32 0, i32 0
  store i32 0, i32* %t597
  %t598 = getelementptr inbounds %Enemy, %Enemy* %t588, i32 0, i32 1
  %t599 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t599
  store i8* %t599, i8** %t598
  br label %table_idx_end_109
table_idx_end_109:
  %t600 = load %Enemy, %Enemy* %t588
  store %Enemy %t600, %Enemy* %t601
  %t602 = getelementptr inbounds %Enemy, %Enemy* %t601, i32 0, i32 0
  %t603 = load i32, i32* %t602
  %t604 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t604, i8* %t573, i32 %t603)
  %t606 = load i8*, i8** %t2
  %t607 = icmp eq i8* %t606, null
  br i1 %t607, label %table_cow_alloc_110, label %table_cow_check_111
table_cow_alloc_110:
  %t608 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t609 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t610 = ptrtoint { i64, i64, i32*, i8** }* %t609 to i64
  %t611 = call i8* @star_rc_alloc(i64 %t610, i8* %t608)
  %t612 = bitcast i8* %t611 to { i64, i64, i32*, i8** }*
  %t613 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t612, i32 0, i32 0
  store i64 0, i64* %t613
  %t614 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t612, i32 0, i32 1
  store i64 0, i64* %t614
  %t615 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t612, i32 0, i32 2
  store i32* null, i32** %t615
  %t616 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t612, i32 0, i32 3
  store i8** null, i8*** %t616
  store i8* %t611, i8** %t2
  br label %table_cow_done_112
table_cow_check_111:
  %t617 = getelementptr inbounds i8, i8* %t606, i64 -16
  %t618 = bitcast i8* %t617 to i64*
  %t619 = load atomic i64, i64* %t618 seq_cst, align 8
  %t620 = icmp eq i64 %t619, 1
  br i1 %t620, label %table_cow_done_112, label %table_cow_clone_113
table_cow_clone_113:
  %t621 = bitcast i8* %t606 to { i64, i64, i32*, i8** }*
  %t622 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t621, i32 0, i32 0
  %t623 = load i64, i64* %t622
  %t624 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t621, i32 0, i32 1
  %t625 = load i64, i64* %t624
  %t626 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t627 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t628 = ptrtoint { i64, i64, i32*, i8** }* %t627 to i64
  %t629 = call i8* @star_rc_alloc(i64 %t628, i8* %t626)
  %t630 = bitcast i8* %t629 to { i64, i64, i32*, i8** }*
  %t631 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t630, i32 0, i32 0
  store i64 %t623, i64* %t631
  %t632 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t630, i32 0, i32 1
  store i64 %t625, i64* %t632
  %t633 = getelementptr i32, i32* null, i32 1
  %t634 = ptrtoint i32* %t633 to i64
  %t635 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t621, i32 0, i32 2
  %t636 = load i32*, i32** %t635
  %t637 = mul i64 %t625, %t634
  %t638 = call i8* @malloc(i64 %t637)
  %t639 = bitcast i8* %t638 to i32*
  %t640 = icmp sgt i64 %t623, 0
  br i1 %t640, label %table_cow_copy_114, label %table_cow_after_copy_115
table_cow_copy_114:
  %t641 = mul i64 %t623, %t634
  %t642 = bitcast i32* %t636 to i8*
  call i8* @memcpy(i8* %t638, i8* %t642, i64 %t641)
  br label %table_cow_after_copy_115
table_cow_after_copy_115:
  %t643 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t630, i32 0, i32 2
  store i32* %t639, i32** %t643
  %t644 = getelementptr i8*, i8** null, i32 1
  %t645 = ptrtoint i8** %t644 to i64
  %t646 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t621, i32 0, i32 3
  %t647 = load i8**, i8*** %t646
  %t648 = mul i64 %t625, %t645
  %t649 = call i8* @malloc(i64 %t648)
  %t650 = bitcast i8* %t649 to i8**
  %t651 = icmp sgt i64 %t623, 0
  br i1 %t651, label %table_cow_copy_116, label %table_cow_after_copy_117
table_cow_copy_116:
  %t652 = mul i64 %t623, %t645
  %t653 = bitcast i8** %t647 to i8*
  call i8* @memcpy(i8* %t649, i8* %t653, i64 %t652)
  store i64 0, i64* %t654
  br label %table_cow_retain_cond_118
table_cow_retain_cond_118:
  %t655 = load i64, i64* %t654
  %t656 = icmp slt i64 %t655, %t623
  br i1 %t656, label %table_cow_retain_body_119, label %table_cow_retain_end_120
table_cow_retain_body_119:
  %t657 = getelementptr inbounds i8*, i8** %t650, i64 %t655
  %t658 = load i8*, i8** %t657
  call void @star_rc_retain(i8* %t658)
  %t659 = add i64 %t655, 1
  store i64 %t659, i64* %t654
  br label %table_cow_retain_cond_118
table_cow_retain_end_120:
  br label %table_cow_after_copy_117
table_cow_after_copy_117:
  %t660 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t630, i32 0, i32 3
  store i8** %t650, i8*** %t660
  call void @star_rc_release(i8* %t606)
  store i8* %t629, i8** %t2
  br label %table_cow_done_112
table_cow_done_112:
  %t661 = load i8*, i8** %t2
  %t662 = bitcast i8* %t661 to { i64, i64, i32*, i8** }*
  %t663 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t662, i32 0, i32 0
  %t664 = load i64, i64* %t663
  %t665 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t662, i32 0, i32 1
  %t666 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t662, i32 0, i32 2
  %t667 = load i32*, i32** %t666
  %t668 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t662, i32 0, i32 3
  %t669 = load i8**, i8*** %t668
  %t671 = icmp eq i64 %t664, 0
  br i1 %t671, label %table_pop_empty_121, label %table_pop_nonempty_122
table_pop_nonempty_122:
  %t672 = sub i64 %t664, 1
  store i64 %t672, i64* %t663
  %t673 = getelementptr inbounds i32, i32* %t667, i64 %t672
  %t674 = load i32, i32* %t673
  %t675 = getelementptr inbounds %Enemy, %Enemy* %t670, i32 0, i32 0
  store i32 %t674, i32* %t675
  %t676 = getelementptr inbounds i8*, i8** %t669, i64 %t672
  %t677 = load i8*, i8** %t676
  %t678 = getelementptr inbounds %Enemy, %Enemy* %t670, i32 0, i32 1
  store i8* %t677, i8** %t678
  br label %table_pop_end_123
table_pop_empty_121:
  %t679 = getelementptr inbounds %Enemy, %Enemy* %t670, i32 0, i32 0
  store i32 0, i32* %t679
  %t680 = getelementptr inbounds %Enemy, %Enemy* %t670, i32 0, i32 1
  %t681 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t681
  store i8* %t681, i8** %t680
  br label %table_pop_end_123
table_pop_end_123:
  %t682 = load %Enemy, %Enemy* %t670
  store %Enemy %t682, %Enemy* %t605
  %t683 = getelementptr inbounds %Enemy, %Enemy* %t605, i32 0, i32 1
  %t684 = load i8*, i8** %t683
  %t685 = load i8*, i8** %t683
  call void @star_rc_retain(i8* %t685)
  call void @star_rc_release(i8* %t684)
  %t686 = getelementptr inbounds %Enemy, %Enemy* %t605, i32 0, i32 0
  %t687 = load i32, i32* %t686
  %t688 = getelementptr inbounds [19 x i8], [19 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t688, i8* %t684, i32 %t687)
  %t689 = load i8*, i8** %t2
  %t690 = icmp eq i8* %t689, null
  br i1 %t690, label %table_read_null_124, label %table_read_real_125
table_read_null_124:
  br label %table_read_end_126
table_read_real_125:
  %t691 = bitcast i8* %t689 to { i64, i64, i32*, i8** }*
  %t692 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t691, i32 0, i32 0
  %t693 = load i64, i64* %t692
  %t694 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t691, i32 0, i32 2
  %t695 = load i32*, i32** %t694
  %t696 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t691, i32 0, i32 3
  %t697 = load i8**, i8*** %t696
  br label %table_read_end_126
table_read_end_126:
  %t698 = phi i64 [ 0, %table_read_null_124 ], [ %t693, %table_read_real_125 ]
  %t699 = phi i32* [ null, %table_read_null_124 ], [ %t695, %table_read_real_125 ]
  %t700 = phi i8** [ null, %table_read_null_124 ], [ %t697, %table_read_real_125 ]
  %t701 = trunc i64 %t698 to i32
  %t702 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t702, i32 %t701)
  %t703 = sext i32 99 to i64
  %t704 = load i8*, i8** %t2
  %t705 = icmp eq i8* %t704, null
  br i1 %t705, label %table_read_null_127, label %table_read_real_128
table_read_null_127:
  br label %table_read_end_129
table_read_real_128:
  %t706 = bitcast i8* %t704 to { i64, i64, i32*, i8** }*
  %t707 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t706, i32 0, i32 0
  %t708 = load i64, i64* %t707
  %t709 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t706, i32 0, i32 2
  %t710 = load i32*, i32** %t709
  %t711 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t706, i32 0, i32 3
  %t712 = load i8**, i8*** %t711
  br label %table_read_end_129
table_read_end_129:
  %t713 = phi i64 [ 0, %table_read_null_127 ], [ %t708, %table_read_real_128 ]
  %t714 = phi i32* [ null, %table_read_null_127 ], [ %t710, %table_read_real_128 ]
  %t715 = phi i8** [ null, %table_read_null_127 ], [ %t712, %table_read_real_128 ]
  %t717 = icmp ult i64 %t703, %t713
  br i1 %t717, label %table_idx_ok_130, label %table_idx_oob_131
table_idx_ok_130:
  %t718 = getelementptr inbounds i32, i32* %t714, i64 %t703
  %t719 = load i32, i32* %t718
  %t720 = getelementptr inbounds %Enemy, %Enemy* %t716, i32 0, i32 0
  store i32 %t719, i32* %t720
  %t721 = getelementptr inbounds i8*, i8** %t715, i64 %t703
  %t722 = load i8*, i8** %t721
  call void @star_rc_retain(i8* %t722)
  %t723 = load i8*, i8** %t721
  %t724 = getelementptr inbounds %Enemy, %Enemy* %t716, i32 0, i32 1
  store i8* %t723, i8** %t724
  br label %table_idx_end_132
table_idx_oob_131:
  %t725 = getelementptr inbounds %Enemy, %Enemy* %t716, i32 0, i32 0
  store i32 0, i32* %t725
  %t726 = getelementptr inbounds %Enemy, %Enemy* %t716, i32 0, i32 1
  %t727 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t727
  store i8* %t727, i8** %t726
  br label %table_idx_end_132
table_idx_end_132:
  %t728 = load %Enemy, %Enemy* %t716
  store %Enemy %t728, %Enemy* %t729
  %t730 = getelementptr inbounds %Enemy, %Enemy* %t729, i32 0, i32 0
  %t731 = load i32, i32* %t730
  %t732 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t732, i32 %t731)
  store i8* null, i8** %t733
  %t735 = load i8*, i8** %t733
  %t736 = icmp eq i8* %t735, null
  br i1 %t736, label %table_cow_alloc_133, label %table_cow_check_134
table_cow_alloc_133:
  %t737 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t738 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t739 = ptrtoint { i64, i64, i32*, i8** }* %t738 to i64
  %t740 = call i8* @star_rc_alloc(i64 %t739, i8* %t737)
  %t741 = bitcast i8* %t740 to { i64, i64, i32*, i8** }*
  %t742 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t741, i32 0, i32 0
  store i64 0, i64* %t742
  %t743 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t741, i32 0, i32 1
  store i64 0, i64* %t743
  %t744 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t741, i32 0, i32 2
  store i32* null, i32** %t744
  %t745 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t741, i32 0, i32 3
  store i8** null, i8*** %t745
  store i8* %t740, i8** %t733
  br label %table_cow_done_135
table_cow_check_134:
  %t746 = getelementptr inbounds i8, i8* %t735, i64 -16
  %t747 = bitcast i8* %t746 to i64*
  %t748 = load atomic i64, i64* %t747 seq_cst, align 8
  %t749 = icmp eq i64 %t748, 1
  br i1 %t749, label %table_cow_done_135, label %table_cow_clone_136
table_cow_clone_136:
  %t750 = bitcast i8* %t735 to { i64, i64, i32*, i8** }*
  %t751 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t750, i32 0, i32 0
  %t752 = load i64, i64* %t751
  %t753 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t750, i32 0, i32 1
  %t754 = load i64, i64* %t753
  %t755 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t756 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t757 = ptrtoint { i64, i64, i32*, i8** }* %t756 to i64
  %t758 = call i8* @star_rc_alloc(i64 %t757, i8* %t755)
  %t759 = bitcast i8* %t758 to { i64, i64, i32*, i8** }*
  %t760 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t759, i32 0, i32 0
  store i64 %t752, i64* %t760
  %t761 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t759, i32 0, i32 1
  store i64 %t754, i64* %t761
  %t762 = getelementptr i32, i32* null, i32 1
  %t763 = ptrtoint i32* %t762 to i64
  %t764 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t750, i32 0, i32 2
  %t765 = load i32*, i32** %t764
  %t766 = mul i64 %t754, %t763
  %t767 = call i8* @malloc(i64 %t766)
  %t768 = bitcast i8* %t767 to i32*
  %t769 = icmp sgt i64 %t752, 0
  br i1 %t769, label %table_cow_copy_137, label %table_cow_after_copy_138
table_cow_copy_137:
  %t770 = mul i64 %t752, %t763
  %t771 = bitcast i32* %t765 to i8*
  call i8* @memcpy(i8* %t767, i8* %t771, i64 %t770)
  br label %table_cow_after_copy_138
table_cow_after_copy_138:
  %t772 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t759, i32 0, i32 2
  store i32* %t768, i32** %t772
  %t773 = getelementptr i8*, i8** null, i32 1
  %t774 = ptrtoint i8** %t773 to i64
  %t775 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t750, i32 0, i32 3
  %t776 = load i8**, i8*** %t775
  %t777 = mul i64 %t754, %t774
  %t778 = call i8* @malloc(i64 %t777)
  %t779 = bitcast i8* %t778 to i8**
  %t780 = icmp sgt i64 %t752, 0
  br i1 %t780, label %table_cow_copy_139, label %table_cow_after_copy_140
table_cow_copy_139:
  %t781 = mul i64 %t752, %t774
  %t782 = bitcast i8** %t776 to i8*
  call i8* @memcpy(i8* %t778, i8* %t782, i64 %t781)
  store i64 0, i64* %t783
  br label %table_cow_retain_cond_141
table_cow_retain_cond_141:
  %t784 = load i64, i64* %t783
  %t785 = icmp slt i64 %t784, %t752
  br i1 %t785, label %table_cow_retain_body_142, label %table_cow_retain_end_143
table_cow_retain_body_142:
  %t786 = getelementptr inbounds i8*, i8** %t779, i64 %t784
  %t787 = load i8*, i8** %t786
  call void @star_rc_retain(i8* %t787)
  %t788 = add i64 %t784, 1
  store i64 %t788, i64* %t783
  br label %table_cow_retain_cond_141
table_cow_retain_end_143:
  br label %table_cow_after_copy_140
table_cow_after_copy_140:
  %t789 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t759, i32 0, i32 3
  store i8** %t779, i8*** %t789
  call void @star_rc_release(i8* %t735)
  store i8* %t758, i8** %t733
  br label %table_cow_done_135
table_cow_done_135:
  %t790 = load i8*, i8** %t733
  %t791 = bitcast i8* %t790 to { i64, i64, i32*, i8** }*
  %t792 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t791, i32 0, i32 0
  %t793 = load i64, i64* %t792
  %t794 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t791, i32 0, i32 1
  %t795 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t791, i32 0, i32 2
  %t796 = load i32*, i32** %t795
  %t797 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t791, i32 0, i32 3
  %t798 = load i8**, i8*** %t797
  %t800 = icmp eq i64 %t793, 0
  br i1 %t800, label %table_pop_empty_144, label %table_pop_nonempty_145
table_pop_nonempty_145:
  %t801 = sub i64 %t793, 1
  store i64 %t801, i64* %t792
  %t802 = getelementptr inbounds i32, i32* %t796, i64 %t801
  %t803 = load i32, i32* %t802
  %t804 = getelementptr inbounds %Enemy, %Enemy* %t799, i32 0, i32 0
  store i32 %t803, i32* %t804
  %t805 = getelementptr inbounds i8*, i8** %t798, i64 %t801
  %t806 = load i8*, i8** %t805
  %t807 = getelementptr inbounds %Enemy, %Enemy* %t799, i32 0, i32 1
  store i8* %t806, i8** %t807
  br label %table_pop_end_146
table_pop_empty_144:
  %t808 = getelementptr inbounds %Enemy, %Enemy* %t799, i32 0, i32 0
  store i32 0, i32* %t808
  %t809 = getelementptr inbounds %Enemy, %Enemy* %t799, i32 0, i32 1
  %t810 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t810
  store i8* %t810, i8** %t809
  br label %table_pop_end_146
table_pop_end_146:
  %t811 = load %Enemy, %Enemy* %t799
  store %Enemy %t811, %Enemy* %t734
  %t812 = getelementptr inbounds %Enemy, %Enemy* %t734, i32 0, i32 0
  %t813 = load i32, i32* %t812
  %t814 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t814, i32 %t813)
  store i8* null, i8** %t815
  %t816 = load i8*, i8** %t815
  %t817 = icmp eq i8* %t816, null
  br i1 %t817, label %table_cow_alloc_147, label %table_cow_check_148
table_cow_alloc_147:
  %t818 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t819 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t820 = ptrtoint { i64, i64, i32*, i8** }* %t819 to i64
  %t821 = call i8* @star_rc_alloc(i64 %t820, i8* %t818)
  %t822 = bitcast i8* %t821 to { i64, i64, i32*, i8** }*
  %t823 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t822, i32 0, i32 0
  store i64 0, i64* %t823
  %t824 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t822, i32 0, i32 1
  store i64 0, i64* %t824
  %t825 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t822, i32 0, i32 2
  store i32* null, i32** %t825
  %t826 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t822, i32 0, i32 3
  store i8** null, i8*** %t826
  store i8* %t821, i8** %t815
  br label %table_cow_done_149
table_cow_check_148:
  %t827 = getelementptr inbounds i8, i8* %t816, i64 -16
  %t828 = bitcast i8* %t827 to i64*
  %t829 = load atomic i64, i64* %t828 seq_cst, align 8
  %t830 = icmp eq i64 %t829, 1
  br i1 %t830, label %table_cow_done_149, label %table_cow_clone_150
table_cow_clone_150:
  %t831 = bitcast i8* %t816 to { i64, i64, i32*, i8** }*
  %t832 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t831, i32 0, i32 0
  %t833 = load i64, i64* %t832
  %t834 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t831, i32 0, i32 1
  %t835 = load i64, i64* %t834
  %t836 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t837 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t838 = ptrtoint { i64, i64, i32*, i8** }* %t837 to i64
  %t839 = call i8* @star_rc_alloc(i64 %t838, i8* %t836)
  %t840 = bitcast i8* %t839 to { i64, i64, i32*, i8** }*
  %t841 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t840, i32 0, i32 0
  store i64 %t833, i64* %t841
  %t842 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t840, i32 0, i32 1
  store i64 %t835, i64* %t842
  %t843 = getelementptr i32, i32* null, i32 1
  %t844 = ptrtoint i32* %t843 to i64
  %t845 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t831, i32 0, i32 2
  %t846 = load i32*, i32** %t845
  %t847 = mul i64 %t835, %t844
  %t848 = call i8* @malloc(i64 %t847)
  %t849 = bitcast i8* %t848 to i32*
  %t850 = icmp sgt i64 %t833, 0
  br i1 %t850, label %table_cow_copy_151, label %table_cow_after_copy_152
table_cow_copy_151:
  %t851 = mul i64 %t833, %t844
  %t852 = bitcast i32* %t846 to i8*
  call i8* @memcpy(i8* %t848, i8* %t852, i64 %t851)
  br label %table_cow_after_copy_152
table_cow_after_copy_152:
  %t853 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t840, i32 0, i32 2
  store i32* %t849, i32** %t853
  %t854 = getelementptr i8*, i8** null, i32 1
  %t855 = ptrtoint i8** %t854 to i64
  %t856 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t831, i32 0, i32 3
  %t857 = load i8**, i8*** %t856
  %t858 = mul i64 %t835, %t855
  %t859 = call i8* @malloc(i64 %t858)
  %t860 = bitcast i8* %t859 to i8**
  %t861 = icmp sgt i64 %t833, 0
  br i1 %t861, label %table_cow_copy_153, label %table_cow_after_copy_154
table_cow_copy_153:
  %t862 = mul i64 %t833, %t855
  %t863 = bitcast i8** %t857 to i8*
  call i8* @memcpy(i8* %t859, i8* %t863, i64 %t862)
  store i64 0, i64* %t864
  br label %table_cow_retain_cond_155
table_cow_retain_cond_155:
  %t865 = load i64, i64* %t864
  %t866 = icmp slt i64 %t865, %t833
  br i1 %t866, label %table_cow_retain_body_156, label %table_cow_retain_end_157
table_cow_retain_body_156:
  %t867 = getelementptr inbounds i8*, i8** %t860, i64 %t865
  %t868 = load i8*, i8** %t867
  call void @star_rc_retain(i8* %t868)
  %t869 = add i64 %t865, 1
  store i64 %t869, i64* %t864
  br label %table_cow_retain_cond_155
table_cow_retain_end_157:
  br label %table_cow_after_copy_154
table_cow_after_copy_154:
  %t870 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t840, i32 0, i32 3
  store i8** %t860, i8*** %t870
  call void @star_rc_release(i8* %t816)
  store i8* %t839, i8** %t815
  br label %table_cow_done_149
table_cow_done_149:
  %t871 = load i8*, i8** %t815
  %t872 = bitcast i8* %t871 to { i64, i64, i32*, i8** }*
  %t873 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t872, i32 0, i32 0
  %t874 = load i64, i64* %t873
  %t875 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t872, i32 0, i32 1
  %t876 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t872, i32 0, i32 2
  %t877 = load i32*, i32** %t876
  %t878 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t872, i32 0, i32 3
  %t879 = load i8**, i8*** %t878
  %t881 = getelementptr inbounds %Enemy, %Enemy* %t880, i32 0, i32 0
  store i32 1, i32* %t881
  %t882 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t883 = getelementptr inbounds %Enemy, %Enemy* %t880, i32 0, i32 1
  store i8* %t882, i8** %t883
  %t884 = load %Enemy, %Enemy* %t880
  %t885 = load i64, i64* %t875
  %t886 = load i64, i64* %t873
  %t887 = load i32*, i32** %t876
  %t888 = load i8**, i8*** %t878
  %t889 = icmp sge i64 %t886, %t885
  br i1 %t889, label %table_push_grow_158, label %table_push_store_159
table_push_grow_158:
  %t890 = mul i64 %t885, 2
  %t891 = icmp sgt i64 %t890, 0
  %t892 = select i1 %t891, i64 %t890, i64 1
  %t893 = getelementptr i32, i32* null, i32 1
  %t894 = ptrtoint i32* %t893 to i64
  %t895 = mul i64 %t892, %t894
  %t896 = call i8* @malloc(i64 %t895)
  %t897 = bitcast i8* %t896 to i32*
  %t898 = icmp sgt i64 %t885, 0
  br i1 %t898, label %table_push_copy_160, label %table_push_after_copy_161
table_push_copy_160:
  %t899 = mul i64 %t886, %t894
  %t900 = bitcast i32* %t887 to i8*
  call i8* @memcpy(i8* %t896, i8* %t900, i64 %t899)
  call void @free(i8* %t900)
  br label %table_push_after_copy_161
table_push_after_copy_161:
  store i32* %t897, i32** %t876
  %t901 = getelementptr i8*, i8** null, i32 1
  %t902 = ptrtoint i8** %t901 to i64
  %t903 = mul i64 %t892, %t902
  %t904 = call i8* @malloc(i64 %t903)
  %t905 = bitcast i8* %t904 to i8**
  %t906 = icmp sgt i64 %t885, 0
  br i1 %t906, label %table_push_copy_162, label %table_push_after_copy_163
table_push_copy_162:
  %t907 = mul i64 %t886, %t902
  %t908 = bitcast i8** %t888 to i8*
  call i8* @memcpy(i8* %t904, i8* %t908, i64 %t907)
  call void @free(i8* %t908)
  br label %table_push_after_copy_163
table_push_after_copy_163:
  store i8** %t905, i8*** %t878
  store i64 %t892, i64* %t875
  br label %table_push_store_159
table_push_store_159:
  %t909 = load i32*, i32** %t876
  %t910 = extractvalue %Enemy %t884, 0
  %t911 = getelementptr inbounds i32, i32* %t909, i64 %t886
  store i32 %t910, i32* %t911
  %t912 = load i8**, i8*** %t878
  %t913 = extractvalue %Enemy %t884, 1
  %t914 = getelementptr inbounds i8*, i8** %t912, i64 %t886
  store i8* %t913, i8** %t914
  %t915 = add i64 %t886, 1
  store i64 %t915, i64* %t873
  %t917 = load i8*, i8** %t815
  %t918 = load i8*, i8** %t815
  call void @star_rc_retain(i8* %t918)
  store i8* %t917, i8** %t916
  %t919 = load i8*, i8** %t916
  %t920 = icmp eq i8* %t919, null
  br i1 %t920, label %table_cow_alloc_164, label %table_cow_check_165
table_cow_alloc_164:
  %t921 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t922 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t923 = ptrtoint { i64, i64, i32*, i8** }* %t922 to i64
  %t924 = call i8* @star_rc_alloc(i64 %t923, i8* %t921)
  %t925 = bitcast i8* %t924 to { i64, i64, i32*, i8** }*
  %t926 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t925, i32 0, i32 0
  store i64 0, i64* %t926
  %t927 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t925, i32 0, i32 1
  store i64 0, i64* %t927
  %t928 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t925, i32 0, i32 2
  store i32* null, i32** %t928
  %t929 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t925, i32 0, i32 3
  store i8** null, i8*** %t929
  store i8* %t924, i8** %t916
  br label %table_cow_done_166
table_cow_check_165:
  %t930 = getelementptr inbounds i8, i8* %t919, i64 -16
  %t931 = bitcast i8* %t930 to i64*
  %t932 = load atomic i64, i64* %t931 seq_cst, align 8
  %t933 = icmp eq i64 %t932, 1
  br i1 %t933, label %table_cow_done_166, label %table_cow_clone_167
table_cow_clone_167:
  %t934 = bitcast i8* %t919 to { i64, i64, i32*, i8** }*
  %t935 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t934, i32 0, i32 0
  %t936 = load i64, i64* %t935
  %t937 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t934, i32 0, i32 1
  %t938 = load i64, i64* %t937
  %t939 = bitcast void (i8*)* @table_release_s_Enemy to i8*
  %t940 = getelementptr { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* null, i32 1
  %t941 = ptrtoint { i64, i64, i32*, i8** }* %t940 to i64
  %t942 = call i8* @star_rc_alloc(i64 %t941, i8* %t939)
  %t943 = bitcast i8* %t942 to { i64, i64, i32*, i8** }*
  %t944 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t943, i32 0, i32 0
  store i64 %t936, i64* %t944
  %t945 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t943, i32 0, i32 1
  store i64 %t938, i64* %t945
  %t946 = getelementptr i32, i32* null, i32 1
  %t947 = ptrtoint i32* %t946 to i64
  %t948 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t934, i32 0, i32 2
  %t949 = load i32*, i32** %t948
  %t950 = mul i64 %t938, %t947
  %t951 = call i8* @malloc(i64 %t950)
  %t952 = bitcast i8* %t951 to i32*
  %t953 = icmp sgt i64 %t936, 0
  br i1 %t953, label %table_cow_copy_168, label %table_cow_after_copy_169
table_cow_copy_168:
  %t954 = mul i64 %t936, %t947
  %t955 = bitcast i32* %t949 to i8*
  call i8* @memcpy(i8* %t951, i8* %t955, i64 %t954)
  br label %table_cow_after_copy_169
table_cow_after_copy_169:
  %t956 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t943, i32 0, i32 2
  store i32* %t952, i32** %t956
  %t957 = getelementptr i8*, i8** null, i32 1
  %t958 = ptrtoint i8** %t957 to i64
  %t959 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t934, i32 0, i32 3
  %t960 = load i8**, i8*** %t959
  %t961 = mul i64 %t938, %t958
  %t962 = call i8* @malloc(i64 %t961)
  %t963 = bitcast i8* %t962 to i8**
  %t964 = icmp sgt i64 %t936, 0
  br i1 %t964, label %table_cow_copy_170, label %table_cow_after_copy_171
table_cow_copy_170:
  %t965 = mul i64 %t936, %t958
  %t966 = bitcast i8** %t960 to i8*
  call i8* @memcpy(i8* %t962, i8* %t966, i64 %t965)
  store i64 0, i64* %t967
  br label %table_cow_retain_cond_172
table_cow_retain_cond_172:
  %t968 = load i64, i64* %t967
  %t969 = icmp slt i64 %t968, %t936
  br i1 %t969, label %table_cow_retain_body_173, label %table_cow_retain_end_174
table_cow_retain_body_173:
  %t970 = getelementptr inbounds i8*, i8** %t963, i64 %t968
  %t971 = load i8*, i8** %t970
  call void @star_rc_retain(i8* %t971)
  %t972 = add i64 %t968, 1
  store i64 %t972, i64* %t967
  br label %table_cow_retain_cond_172
table_cow_retain_end_174:
  br label %table_cow_after_copy_171
table_cow_after_copy_171:
  %t973 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t943, i32 0, i32 3
  store i8** %t963, i8*** %t973
  call void @star_rc_release(i8* %t919)
  store i8* %t942, i8** %t916
  br label %table_cow_done_166
table_cow_done_166:
  %t974 = load i8*, i8** %t916
  %t975 = bitcast i8* %t974 to { i64, i64, i32*, i8** }*
  %t976 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t975, i32 0, i32 0
  %t977 = load i64, i64* %t976
  %t978 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t975, i32 0, i32 1
  %t979 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t975, i32 0, i32 2
  %t980 = load i32*, i32** %t979
  %t981 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t975, i32 0, i32 3
  %t982 = load i8**, i8*** %t981
  %t984 = getelementptr inbounds %Enemy, %Enemy* %t983, i32 0, i32 0
  store i32 2, i32* %t984
  %t985 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t986 = getelementptr inbounds %Enemy, %Enemy* %t983, i32 0, i32 1
  store i8* %t985, i8** %t986
  %t987 = load %Enemy, %Enemy* %t983
  %t988 = load i64, i64* %t978
  %t989 = load i64, i64* %t976
  %t990 = load i32*, i32** %t979
  %t991 = load i8**, i8*** %t981
  %t992 = icmp sge i64 %t989, %t988
  br i1 %t992, label %table_push_grow_175, label %table_push_store_176
table_push_grow_175:
  %t993 = mul i64 %t988, 2
  %t994 = icmp sgt i64 %t993, 0
  %t995 = select i1 %t994, i64 %t993, i64 1
  %t996 = getelementptr i32, i32* null, i32 1
  %t997 = ptrtoint i32* %t996 to i64
  %t998 = mul i64 %t995, %t997
  %t999 = call i8* @malloc(i64 %t998)
  %t1000 = bitcast i8* %t999 to i32*
  %t1001 = icmp sgt i64 %t988, 0
  br i1 %t1001, label %table_push_copy_177, label %table_push_after_copy_178
table_push_copy_177:
  %t1002 = mul i64 %t989, %t997
  %t1003 = bitcast i32* %t990 to i8*
  call i8* @memcpy(i8* %t999, i8* %t1003, i64 %t1002)
  call void @free(i8* %t1003)
  br label %table_push_after_copy_178
table_push_after_copy_178:
  store i32* %t1000, i32** %t979
  %t1004 = getelementptr i8*, i8** null, i32 1
  %t1005 = ptrtoint i8** %t1004 to i64
  %t1006 = mul i64 %t995, %t1005
  %t1007 = call i8* @malloc(i64 %t1006)
  %t1008 = bitcast i8* %t1007 to i8**
  %t1009 = icmp sgt i64 %t988, 0
  br i1 %t1009, label %table_push_copy_179, label %table_push_after_copy_180
table_push_copy_179:
  %t1010 = mul i64 %t989, %t1005
  %t1011 = bitcast i8** %t991 to i8*
  call i8* @memcpy(i8* %t1007, i8* %t1011, i64 %t1010)
  call void @free(i8* %t1011)
  br label %table_push_after_copy_180
table_push_after_copy_180:
  store i8** %t1008, i8*** %t981
  store i64 %t995, i64* %t978
  br label %table_push_store_176
table_push_store_176:
  %t1012 = load i32*, i32** %t979
  %t1013 = extractvalue %Enemy %t987, 0
  %t1014 = getelementptr inbounds i32, i32* %t1012, i64 %t989
  store i32 %t1013, i32* %t1014
  %t1015 = load i8**, i8*** %t981
  %t1016 = extractvalue %Enemy %t987, 1
  %t1017 = getelementptr inbounds i8*, i8** %t1015, i64 %t989
  store i8* %t1016, i8** %t1017
  %t1018 = add i64 %t989, 1
  store i64 %t1018, i64* %t976
  %t1019 = load i8*, i8** %t815
  %t1020 = icmp eq i8* %t1019, null
  br i1 %t1020, label %table_read_null_181, label %table_read_real_182
table_read_null_181:
  br label %table_read_end_183
table_read_real_182:
  %t1021 = bitcast i8* %t1019 to { i64, i64, i32*, i8** }*
  %t1022 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1021, i32 0, i32 0
  %t1023 = load i64, i64* %t1022
  %t1024 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1021, i32 0, i32 2
  %t1025 = load i32*, i32** %t1024
  %t1026 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1021, i32 0, i32 3
  %t1027 = load i8**, i8*** %t1026
  br label %table_read_end_183
table_read_end_183:
  %t1028 = phi i64 [ 0, %table_read_null_181 ], [ %t1023, %table_read_real_182 ]
  %t1029 = phi i32* [ null, %table_read_null_181 ], [ %t1025, %table_read_real_182 ]
  %t1030 = phi i8** [ null, %table_read_null_181 ], [ %t1027, %table_read_real_182 ]
  %t1031 = trunc i64 %t1028 to i32
  %t1032 = load i8*, i8** %t916
  %t1033 = icmp eq i8* %t1032, null
  br i1 %t1033, label %table_read_null_184, label %table_read_real_185
table_read_null_184:
  br label %table_read_end_186
table_read_real_185:
  %t1034 = bitcast i8* %t1032 to { i64, i64, i32*, i8** }*
  %t1035 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1034, i32 0, i32 0
  %t1036 = load i64, i64* %t1035
  %t1037 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1034, i32 0, i32 2
  %t1038 = load i32*, i32** %t1037
  %t1039 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1034, i32 0, i32 3
  %t1040 = load i8**, i8*** %t1039
  br label %table_read_end_186
table_read_end_186:
  %t1041 = phi i64 [ 0, %table_read_null_184 ], [ %t1036, %table_read_real_185 ]
  %t1042 = phi i32* [ null, %table_read_null_184 ], [ %t1038, %table_read_real_185 ]
  %t1043 = phi i8** [ null, %table_read_null_184 ], [ %t1040, %table_read_real_185 ]
  %t1044 = trunc i64 %t1041 to i32
  %t1045 = getelementptr inbounds [34 x i8], [34 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1045, i32 %t1031, i32 %t1044)
  %t1046 = sext i32 0 to i64
  %t1047 = load i8*, i8** %t815
  %t1048 = icmp eq i8* %t1047, null
  br i1 %t1048, label %table_read_null_187, label %table_read_real_188
table_read_null_187:
  br label %table_read_end_189
table_read_real_188:
  %t1049 = bitcast i8* %t1047 to { i64, i64, i32*, i8** }*
  %t1050 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1049, i32 0, i32 0
  %t1051 = load i64, i64* %t1050
  %t1052 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1049, i32 0, i32 2
  %t1053 = load i32*, i32** %t1052
  %t1054 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1049, i32 0, i32 3
  %t1055 = load i8**, i8*** %t1054
  br label %table_read_end_189
table_read_end_189:
  %t1056 = phi i64 [ 0, %table_read_null_187 ], [ %t1051, %table_read_real_188 ]
  %t1057 = phi i32* [ null, %table_read_null_187 ], [ %t1053, %table_read_real_188 ]
  %t1058 = phi i8** [ null, %table_read_null_187 ], [ %t1055, %table_read_real_188 ]
  %t1060 = icmp ult i64 %t1046, %t1056
  br i1 %t1060, label %table_idx_ok_190, label %table_idx_oob_191
table_idx_ok_190:
  %t1061 = getelementptr inbounds i32, i32* %t1057, i64 %t1046
  %t1062 = load i32, i32* %t1061
  %t1063 = getelementptr inbounds %Enemy, %Enemy* %t1059, i32 0, i32 0
  store i32 %t1062, i32* %t1063
  %t1064 = getelementptr inbounds i8*, i8** %t1058, i64 %t1046
  %t1065 = load i8*, i8** %t1064
  call void @star_rc_retain(i8* %t1065)
  %t1066 = load i8*, i8** %t1064
  %t1067 = getelementptr inbounds %Enemy, %Enemy* %t1059, i32 0, i32 1
  store i8* %t1066, i8** %t1067
  br label %table_idx_end_192
table_idx_oob_191:
  %t1068 = getelementptr inbounds %Enemy, %Enemy* %t1059, i32 0, i32 0
  store i32 0, i32* %t1068
  %t1069 = getelementptr inbounds %Enemy, %Enemy* %t1059, i32 0, i32 1
  %t1070 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t1070
  store i8* %t1070, i8** %t1069
  br label %table_idx_end_192
table_idx_end_192:
  %t1071 = load %Enemy, %Enemy* %t1059
  store %Enemy %t1071, %Enemy* %t1072
  %t1073 = getelementptr inbounds %Enemy, %Enemy* %t1072, i32 0, i32 0
  %t1074 = load i32, i32* %t1073
  %t1075 = sext i32 0 to i64
  %t1076 = load i8*, i8** %t916
  %t1077 = icmp eq i8* %t1076, null
  br i1 %t1077, label %table_read_null_193, label %table_read_real_194
table_read_null_193:
  br label %table_read_end_195
table_read_real_194:
  %t1078 = bitcast i8* %t1076 to { i64, i64, i32*, i8** }*
  %t1079 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1078, i32 0, i32 0
  %t1080 = load i64, i64* %t1079
  %t1081 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1078, i32 0, i32 2
  %t1082 = load i32*, i32** %t1081
  %t1083 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t1078, i32 0, i32 3
  %t1084 = load i8**, i8*** %t1083
  br label %table_read_end_195
table_read_end_195:
  %t1085 = phi i64 [ 0, %table_read_null_193 ], [ %t1080, %table_read_real_194 ]
  %t1086 = phi i32* [ null, %table_read_null_193 ], [ %t1082, %table_read_real_194 ]
  %t1087 = phi i8** [ null, %table_read_null_193 ], [ %t1084, %table_read_real_194 ]
  %t1089 = icmp ult i64 %t1075, %t1085
  br i1 %t1089, label %table_idx_ok_196, label %table_idx_oob_197
table_idx_ok_196:
  %t1090 = getelementptr inbounds i32, i32* %t1086, i64 %t1075
  %t1091 = load i32, i32* %t1090
  %t1092 = getelementptr inbounds %Enemy, %Enemy* %t1088, i32 0, i32 0
  store i32 %t1091, i32* %t1092
  %t1093 = getelementptr inbounds i8*, i8** %t1087, i64 %t1075
  %t1094 = load i8*, i8** %t1093
  call void @star_rc_retain(i8* %t1094)
  %t1095 = load i8*, i8** %t1093
  %t1096 = getelementptr inbounds %Enemy, %Enemy* %t1088, i32 0, i32 1
  store i8* %t1095, i8** %t1096
  br label %table_idx_end_198
table_idx_oob_197:
  %t1097 = getelementptr inbounds %Enemy, %Enemy* %t1088, i32 0, i32 0
  store i32 0, i32* %t1097
  %t1098 = getelementptr inbounds %Enemy, %Enemy* %t1088, i32 0, i32 1
  %t1099 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t1099
  store i8* %t1099, i8** %t1098
  br label %table_idx_end_198
table_idx_end_198:
  %t1100 = load %Enemy, %Enemy* %t1088
  store %Enemy %t1100, %Enemy* %t1101
  %t1102 = getelementptr inbounds %Enemy, %Enemy* %t1101, i32 0, i32 0
  %t1103 = load i32, i32* %t1102
  %t1104 = getelementptr inbounds [38 x i8], [38 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t1104, i32 %t1074, i32 %t1103)
  %t1105 = getelementptr inbounds %Enemy, %Enemy* %t1101, i32 0, i32 1
  %t1106 = load i8*, i8** %t1105
  call void @star_rc_release(i8* %t1106)
  %t1107 = getelementptr inbounds %Enemy, %Enemy* %t1072, i32 0, i32 1
  %t1108 = load i8*, i8** %t1107
  call void @star_rc_release(i8* %t1108)
  %t1109 = load i8*, i8** %t916
  call void @star_rc_release(i8* %t1109)
  %t1110 = load i8*, i8** %t815
  call void @star_rc_release(i8* %t1110)
  %t1111 = getelementptr inbounds %Enemy, %Enemy* %t734, i32 0, i32 1
  %t1112 = load i8*, i8** %t1111
  call void @star_rc_release(i8* %t1112)
  %t1113 = load i8*, i8** %t733
  call void @star_rc_release(i8* %t1113)
  %t1114 = getelementptr inbounds %Enemy, %Enemy* %t729, i32 0, i32 1
  %t1115 = load i8*, i8** %t1114
  call void @star_rc_release(i8* %t1115)
  %t1116 = getelementptr inbounds %Enemy, %Enemy* %t605, i32 0, i32 1
  %t1117 = load i8*, i8** %t1116
  call void @star_rc_release(i8* %t1117)
  %t1118 = getelementptr inbounds %Enemy, %Enemy* %t601, i32 0, i32 1
  %t1119 = load i8*, i8** %t1118
  call void @star_rc_release(i8* %t1119)
  %t1120 = getelementptr inbounds %Enemy, %Enemy* %t571, i32 0, i32 1
  %t1121 = load i8*, i8** %t1120
  call void @star_rc_release(i8* %t1121)
  %t1122 = getelementptr inbounds %Enemy, %Enemy* %t462, i32 0, i32 1
  %t1123 = load i8*, i8** %t1122
  call void @star_rc_release(i8* %t1123)
  %t1124 = getelementptr inbounds %Enemy, %Enemy* %t432, i32 0, i32 1
  %t1125 = load i8*, i8** %t1124
  call void @star_rc_release(i8* %t1125)
  %t1126 = getelementptr inbounds %Enemy, %Enemy* %t402, i32 0, i32 1
  %t1127 = load i8*, i8** %t1126
  call void @star_rc_release(i8* %t1127)
  %t1128 = getelementptr inbounds %Enemy, %Enemy* %t372, i32 0, i32 1
  %t1129 = load i8*, i8** %t1128
  call void @star_rc_release(i8* %t1129)
  %t1130 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t1130)
  ret i32 0
}


; par/swarm worker functions
define void @table_release_s_Enemy(i8* %objp) {
entry:
  %t27 = alloca i64
  %t19 = bitcast i8* %objp to { i64, i64, i32*, i8** }*
  %t20 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t19, i32 0, i32 0
  %t21 = load i64, i64* %t20
  %t22 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t19, i32 0, i32 2
  %t23 = load i32*, i32** %t22
  %t24 = bitcast i32* %t23 to i8*
  call void @free(i8* %t24)
  %t25 = getelementptr inbounds { i64, i64, i32*, i8** }, { i64, i64, i32*, i8** }* %t19, i32 0, i32 3
  %t26 = load i8**, i8*** %t25
  store i64 0, i64* %t27
  br label %table_release_cond_6
table_release_cond_6:
  %t28 = load i64, i64* %t27
  %t29 = icmp slt i64 %t28, %t21
  br i1 %t29, label %table_release_body_7, label %table_release_end_8
table_release_body_7:
  %t30 = getelementptr inbounds i8*, i8** %t26, i64 %t28
  %t31 = load i8*, i8** %t30
  call void @star_rc_release(i8* %t31)
  %t32 = add i64 %t28, 1
  store i64 %t32, i64* %t27
  br label %table_release_cond_6
table_release_end_8:
  %t33 = bitcast i8** %t26 to i8*
  call void @free(i8* %t33)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [16 x i8] c"empty len = %d\0A\00"
@.str.1 = private unnamed_addr constant { i64, i8*, [7 x i8] } { i64 -1, i8* null, [7 x i8] c"Goblin\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"Orc\00" }
@.str.3 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Troll\00" }
@.str.4 = private unnamed_addr constant [25 x i8] c"after 3 pushes len = %d\0A\00"
@.str.5 = private unnamed_addr constant [23 x i8] c"enemies[0] = %s hp=%d\0A\00"
@.str.6 = private unnamed_addr constant [23 x i8] c"enemies[2] = %s hp=%d\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [10 x i8] } { i64 -1, i8* null, [10 x i8] c"Orc Chief\00" }
@.str.8 = private unnamed_addr constant [33 x i8] c"enemies[1] after set = %s hp=%d\0A\00"
@.str.9 = private unnamed_addr constant [19 x i8] c"popped = %s hp=%d\0A\00"
@.str.10 = private unnamed_addr constant [20 x i8] c"len after pop = %d\0A\00"
@.str.11 = private unnamed_addr constant [21 x i8] c"enemies[99] hp = %d\0A\00"
@.str.12 = private unnamed_addr constant [24 x i8] c"pop from empty hp = %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"A\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"B\00" }
@.str.15 = private unnamed_addr constant [34 x i8] c"original len = %d clone len = %d\0A\00"
@.str.16 = private unnamed_addr constant [38 x i8] c"original[0] hp = %d clone[0] hp = %d\0A\00"
