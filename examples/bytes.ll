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
  %t2 = alloca i8*
  %t312 = alloca i8
  %t372 = alloca i8*
  %t437 = alloca i8*
  %t475 = alloca i8*
  %t491 = alloca i8*
  %t502 = alloca i8*
  %t585 = alloca i8*
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  store i8* null, i8** %t2
  %t3 = load i8*, i8** %t2
  %t4 = icmp eq i8* %t3, null
  br i1 %t4, label %list_read_null_0, label %list_read_real_1
list_read_null_0:
  br label %list_read_end_2
list_read_real_1:
  %t5 = bitcast i8* %t3 to { i8*, i64, i64 }*
  %t6 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t5, i32 0, i32 0
  %t7 = load i8*, i8** %t6
  %t8 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t5, i32 0, i32 1
  %t9 = load i64, i64* %t8
  br label %list_read_end_2
list_read_end_2:
  %t10 = phi i8* [ null, %list_read_null_0 ], [ %t7, %list_read_real_1 ]
  %t11 = phi i64 [ 0, %list_read_null_0 ], [ %t9, %list_read_real_1 ]
  %t12 = trunc i64 %t11 to i32
  %t13 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t13, i32 %t12)
  %t14 = getelementptr i8, i8* null, i32 1
  %t15 = ptrtoint i8* %t14 to i64
  %t16 = load i8*, i8** %t2
  %t17 = icmp eq i8* %t16, null
  br i1 %t17, label %list_cow_alloc_3, label %list_cow_check_4
list_cow_alloc_3:
  %t22 = bitcast void (i8*)* @list_release_u8 to i8*
  %t23 = call i8* @star_rc_alloc(i64 24, i8* %t22)
  %t24 = bitcast i8* %t23 to { i8*, i64, i64 }*
  %t25 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t24, i32 0, i32 0
  store i8* null, i8** %t25
  %t26 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t24, i32 0, i32 1
  store i64 0, i64* %t26
  %t27 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t24, i32 0, i32 2
  store i64 0, i64* %t27
  store i8* %t23, i8** %t2
  br label %list_cow_done_5
list_cow_check_4:
  %t28 = getelementptr inbounds i8, i8* %t16, i64 -16
  %t29 = bitcast i8* %t28 to i64*
  %t30 = load atomic i64, i64* %t29 seq_cst, align 8
  %t31 = icmp eq i64 %t30, 1
  br i1 %t31, label %list_cow_done_5, label %list_cow_clone_6
list_cow_clone_6:
  %t32 = bitcast i8* %t16 to { i8*, i64, i64 }*
  %t33 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t32, i32 0, i32 0
  %t34 = load i8*, i8** %t33
  %t35 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t32, i32 0, i32 1
  %t36 = load i64, i64* %t35
  %t37 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t32, i32 0, i32 2
  %t38 = load i64, i64* %t37
  %t39 = bitcast void (i8*)* @list_release_u8 to i8*
  %t40 = call i8* @star_rc_alloc(i64 24, i8* %t39)
  %t41 = bitcast i8* %t40 to { i8*, i64, i64 }*
  %t42 = mul i64 %t38, %t15
  %t43 = call i8* @malloc(i64 %t42)
  %t44 = bitcast i8* %t43 to i8*
  %t45 = icmp sgt i64 %t36, 0
  br i1 %t45, label %list_cow_copy_7, label %list_cow_after_copy_8
list_cow_copy_7:
  %t46 = mul i64 %t36, %t15
  %t47 = bitcast i8* %t34 to i8*
  call i8* @memcpy(i8* %t43, i8* %t47, i64 %t46)
  br label %list_cow_after_copy_8
list_cow_after_copy_8:
  %t48 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t41, i32 0, i32 0
  store i8* %t44, i8** %t48
  %t49 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t41, i32 0, i32 1
  store i64 %t36, i64* %t49
  %t50 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t41, i32 0, i32 2
  store i64 %t38, i64* %t50
  call void @star_rc_release(i8* %t16)
  store i8* %t40, i8** %t2
  br label %list_cow_done_5
list_cow_done_5:
  %t51 = load i8*, i8** %t2
  %t52 = bitcast i8* %t51 to { i8*, i64, i64 }*
  %t53 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t52, i32 0, i32 0
  %t54 = load i8*, i8** %t53
  %t55 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t52, i32 0, i32 1
  %t56 = load i64, i64* %t55
  %t57 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t52, i32 0, i32 2
  %t58 = trunc i32 72 to i8
  %t59 = load i64, i64* %t57
  %t60 = load i8*, i8** %t53
  %t61 = load i64, i64* %t55
  %t62 = icmp sge i64 %t61, %t59
  br i1 %t62, label %list_push_grow_9, label %list_push_store_10
list_push_grow_9:
  %t63 = mul i64 %t59, 2
  %t64 = icmp sgt i64 %t63, 0
  %t65 = select i1 %t64, i64 %t63, i64 1
  %t66 = getelementptr i8, i8* null, i32 1
  %t67 = ptrtoint i8* %t66 to i64
  %t68 = mul i64 %t65, %t67
  %t69 = call i8* @malloc(i64 %t68)
  %t70 = bitcast i8* %t69 to i8*
  %t71 = icmp sgt i64 %t59, 0
  br i1 %t71, label %list_push_copy_11, label %list_push_after_copy_12
list_push_copy_11:
  %t72 = mul i64 %t61, %t67
  %t73 = bitcast i8* %t60 to i8*
  call i8* @memcpy(i8* %t69, i8* %t73, i64 %t72)
  call void @free(i8* %t73)
  br label %list_push_after_copy_12
list_push_after_copy_12:
  store i8* %t70, i8** %t53
  store i64 %t65, i64* %t57
  br label %list_push_store_10
list_push_store_10:
  %t74 = load i8*, i8** %t53
  %t75 = getelementptr inbounds i8, i8* %t74, i64 %t61
  store i8 %t58, i8* %t75
  %t76 = add i64 %t61, 1
  store i64 %t76, i64* %t55
  %t77 = getelementptr i8, i8* null, i32 1
  %t78 = ptrtoint i8* %t77 to i64
  %t79 = load i8*, i8** %t2
  %t80 = icmp eq i8* %t79, null
  br i1 %t80, label %list_cow_alloc_13, label %list_cow_check_14
list_cow_alloc_13:
  %t81 = bitcast void (i8*)* @list_release_u8 to i8*
  %t82 = call i8* @star_rc_alloc(i64 24, i8* %t81)
  %t83 = bitcast i8* %t82 to { i8*, i64, i64 }*
  %t84 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t83, i32 0, i32 0
  store i8* null, i8** %t84
  %t85 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t83, i32 0, i32 1
  store i64 0, i64* %t85
  %t86 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t83, i32 0, i32 2
  store i64 0, i64* %t86
  store i8* %t82, i8** %t2
  br label %list_cow_done_15
list_cow_check_14:
  %t87 = getelementptr inbounds i8, i8* %t79, i64 -16
  %t88 = bitcast i8* %t87 to i64*
  %t89 = load atomic i64, i64* %t88 seq_cst, align 8
  %t90 = icmp eq i64 %t89, 1
  br i1 %t90, label %list_cow_done_15, label %list_cow_clone_16
list_cow_clone_16:
  %t91 = bitcast i8* %t79 to { i8*, i64, i64 }*
  %t92 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t91, i32 0, i32 0
  %t93 = load i8*, i8** %t92
  %t94 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t91, i32 0, i32 1
  %t95 = load i64, i64* %t94
  %t96 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t91, i32 0, i32 2
  %t97 = load i64, i64* %t96
  %t98 = bitcast void (i8*)* @list_release_u8 to i8*
  %t99 = call i8* @star_rc_alloc(i64 24, i8* %t98)
  %t100 = bitcast i8* %t99 to { i8*, i64, i64 }*
  %t101 = mul i64 %t97, %t78
  %t102 = call i8* @malloc(i64 %t101)
  %t103 = bitcast i8* %t102 to i8*
  %t104 = icmp sgt i64 %t95, 0
  br i1 %t104, label %list_cow_copy_17, label %list_cow_after_copy_18
list_cow_copy_17:
  %t105 = mul i64 %t95, %t78
  %t106 = bitcast i8* %t93 to i8*
  call i8* @memcpy(i8* %t102, i8* %t106, i64 %t105)
  br label %list_cow_after_copy_18
list_cow_after_copy_18:
  %t107 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t100, i32 0, i32 0
  store i8* %t103, i8** %t107
  %t108 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t100, i32 0, i32 1
  store i64 %t95, i64* %t108
  %t109 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t100, i32 0, i32 2
  store i64 %t97, i64* %t109
  call void @star_rc_release(i8* %t79)
  store i8* %t99, i8** %t2
  br label %list_cow_done_15
list_cow_done_15:
  %t110 = load i8*, i8** %t2
  %t111 = bitcast i8* %t110 to { i8*, i64, i64 }*
  %t112 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t111, i32 0, i32 0
  %t113 = load i8*, i8** %t112
  %t114 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t111, i32 0, i32 1
  %t115 = load i64, i64* %t114
  %t116 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t111, i32 0, i32 2
  %t117 = trunc i32 73 to i8
  %t118 = load i64, i64* %t116
  %t119 = load i8*, i8** %t112
  %t120 = load i64, i64* %t114
  %t121 = icmp sge i64 %t120, %t118
  br i1 %t121, label %list_push_grow_19, label %list_push_store_20
list_push_grow_19:
  %t122 = mul i64 %t118, 2
  %t123 = icmp sgt i64 %t122, 0
  %t124 = select i1 %t123, i64 %t122, i64 1
  %t125 = getelementptr i8, i8* null, i32 1
  %t126 = ptrtoint i8* %t125 to i64
  %t127 = mul i64 %t124, %t126
  %t128 = call i8* @malloc(i64 %t127)
  %t129 = bitcast i8* %t128 to i8*
  %t130 = icmp sgt i64 %t118, 0
  br i1 %t130, label %list_push_copy_21, label %list_push_after_copy_22
list_push_copy_21:
  %t131 = mul i64 %t120, %t126
  %t132 = bitcast i8* %t119 to i8*
  call i8* @memcpy(i8* %t128, i8* %t132, i64 %t131)
  call void @free(i8* %t132)
  br label %list_push_after_copy_22
list_push_after_copy_22:
  store i8* %t129, i8** %t112
  store i64 %t124, i64* %t116
  br label %list_push_store_20
list_push_store_20:
  %t133 = load i8*, i8** %t112
  %t134 = getelementptr inbounds i8, i8* %t133, i64 %t120
  store i8 %t117, i8* %t134
  %t135 = add i64 %t120, 1
  store i64 %t135, i64* %t114
  %t136 = getelementptr i8, i8* null, i32 1
  %t137 = ptrtoint i8* %t136 to i64
  %t138 = load i8*, i8** %t2
  %t139 = icmp eq i8* %t138, null
  br i1 %t139, label %list_cow_alloc_23, label %list_cow_check_24
list_cow_alloc_23:
  %t140 = bitcast void (i8*)* @list_release_u8 to i8*
  %t141 = call i8* @star_rc_alloc(i64 24, i8* %t140)
  %t142 = bitcast i8* %t141 to { i8*, i64, i64 }*
  %t143 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t142, i32 0, i32 0
  store i8* null, i8** %t143
  %t144 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t142, i32 0, i32 1
  store i64 0, i64* %t144
  %t145 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t142, i32 0, i32 2
  store i64 0, i64* %t145
  store i8* %t141, i8** %t2
  br label %list_cow_done_25
list_cow_check_24:
  %t146 = getelementptr inbounds i8, i8* %t138, i64 -16
  %t147 = bitcast i8* %t146 to i64*
  %t148 = load atomic i64, i64* %t147 seq_cst, align 8
  %t149 = icmp eq i64 %t148, 1
  br i1 %t149, label %list_cow_done_25, label %list_cow_clone_26
list_cow_clone_26:
  %t150 = bitcast i8* %t138 to { i8*, i64, i64 }*
  %t151 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t150, i32 0, i32 0
  %t152 = load i8*, i8** %t151
  %t153 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t150, i32 0, i32 1
  %t154 = load i64, i64* %t153
  %t155 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t150, i32 0, i32 2
  %t156 = load i64, i64* %t155
  %t157 = bitcast void (i8*)* @list_release_u8 to i8*
  %t158 = call i8* @star_rc_alloc(i64 24, i8* %t157)
  %t159 = bitcast i8* %t158 to { i8*, i64, i64 }*
  %t160 = mul i64 %t156, %t137
  %t161 = call i8* @malloc(i64 %t160)
  %t162 = bitcast i8* %t161 to i8*
  %t163 = icmp sgt i64 %t154, 0
  br i1 %t163, label %list_cow_copy_27, label %list_cow_after_copy_28
list_cow_copy_27:
  %t164 = mul i64 %t154, %t137
  %t165 = bitcast i8* %t152 to i8*
  call i8* @memcpy(i8* %t161, i8* %t165, i64 %t164)
  br label %list_cow_after_copy_28
list_cow_after_copy_28:
  %t166 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t159, i32 0, i32 0
  store i8* %t162, i8** %t166
  %t167 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t159, i32 0, i32 1
  store i64 %t154, i64* %t167
  %t168 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t159, i32 0, i32 2
  store i64 %t156, i64* %t168
  call void @star_rc_release(i8* %t138)
  store i8* %t158, i8** %t2
  br label %list_cow_done_25
list_cow_done_25:
  %t169 = load i8*, i8** %t2
  %t170 = bitcast i8* %t169 to { i8*, i64, i64 }*
  %t171 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t170, i32 0, i32 0
  %t172 = load i8*, i8** %t171
  %t173 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t170, i32 0, i32 1
  %t174 = load i64, i64* %t173
  %t175 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t170, i32 0, i32 2
  %t176 = trunc i32 33 to i8
  %t177 = load i64, i64* %t175
  %t178 = load i8*, i8** %t171
  %t179 = load i64, i64* %t173
  %t180 = icmp sge i64 %t179, %t177
  br i1 %t180, label %list_push_grow_29, label %list_push_store_30
list_push_grow_29:
  %t181 = mul i64 %t177, 2
  %t182 = icmp sgt i64 %t181, 0
  %t183 = select i1 %t182, i64 %t181, i64 1
  %t184 = getelementptr i8, i8* null, i32 1
  %t185 = ptrtoint i8* %t184 to i64
  %t186 = mul i64 %t183, %t185
  %t187 = call i8* @malloc(i64 %t186)
  %t188 = bitcast i8* %t187 to i8*
  %t189 = icmp sgt i64 %t177, 0
  br i1 %t189, label %list_push_copy_31, label %list_push_after_copy_32
list_push_copy_31:
  %t190 = mul i64 %t179, %t185
  %t191 = bitcast i8* %t178 to i8*
  call i8* @memcpy(i8* %t187, i8* %t191, i64 %t190)
  call void @free(i8* %t191)
  br label %list_push_after_copy_32
list_push_after_copy_32:
  store i8* %t188, i8** %t171
  store i64 %t183, i64* %t175
  br label %list_push_store_30
list_push_store_30:
  %t192 = load i8*, i8** %t171
  %t193 = getelementptr inbounds i8, i8* %t192, i64 %t179
  store i8 %t176, i8* %t193
  %t194 = add i64 %t179, 1
  store i64 %t194, i64* %t173
  %t195 = load i8*, i8** %t2
  %t196 = icmp eq i8* %t195, null
  br i1 %t196, label %list_read_null_33, label %list_read_real_34
list_read_null_33:
  br label %list_read_end_35
list_read_real_34:
  %t197 = bitcast i8* %t195 to { i8*, i64, i64 }*
  %t198 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t197, i32 0, i32 0
  %t199 = load i8*, i8** %t198
  %t200 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t197, i32 0, i32 1
  %t201 = load i64, i64* %t200
  br label %list_read_end_35
list_read_end_35:
  %t202 = phi i8* [ null, %list_read_null_33 ], [ %t199, %list_read_real_34 ]
  %t203 = phi i64 [ 0, %list_read_null_33 ], [ %t201, %list_read_real_34 ]
  %t204 = trunc i64 %t203 to i32
  %t205 = getelementptr inbounds [26 x i8], [26 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t205, i32 %t204)
  %t206 = load i8*, i8** %t2
  %t207 = icmp eq i8* %t206, null
  br i1 %t207, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t208 = bitcast i8* %t206 to { i8*, i64, i64 }*
  %t209 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t208, i32 0, i32 0
  %t210 = load i8*, i8** %t209
  %t211 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t208, i32 0, i32 1
  %t212 = load i64, i64* %t211
  br label %list_read_end_38
list_read_end_38:
  %t213 = phi i8* [ null, %list_read_null_36 ], [ %t210, %list_read_real_37 ]
  %t214 = phi i64 [ 0, %list_read_null_36 ], [ %t212, %list_read_real_37 ]
  %t215 = sext i32 0 to i64
  %t216 = icmp ult i64 %t215, %t214
  br i1 %t216, label %list_idx_ok_39, label %list_idx_oob_40
list_idx_ok_39:
  %t217 = getelementptr inbounds i8, i8* %t213, i64 %t215
  %t218 = load i8, i8* %t217
  br label %list_idx_end_41
list_idx_oob_40:
  br label %list_idx_end_41
list_idx_end_41:
  %t219 = phi i8 [ %t218, %list_idx_ok_39 ], [ 0, %list_idx_oob_40 ]
  %t220 = load i8*, i8** %t2
  %t221 = icmp eq i8* %t220, null
  br i1 %t221, label %list_read_null_42, label %list_read_real_43
list_read_null_42:
  br label %list_read_end_44
list_read_real_43:
  %t222 = bitcast i8* %t220 to { i8*, i64, i64 }*
  %t223 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t222, i32 0, i32 0
  %t224 = load i8*, i8** %t223
  %t225 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t222, i32 0, i32 1
  %t226 = load i64, i64* %t225
  br label %list_read_end_44
list_read_end_44:
  %t227 = phi i8* [ null, %list_read_null_42 ], [ %t224, %list_read_real_43 ]
  %t228 = phi i64 [ 0, %list_read_null_42 ], [ %t226, %list_read_real_43 ]
  %t229 = sext i32 1 to i64
  %t230 = icmp ult i64 %t229, %t228
  br i1 %t230, label %list_idx_ok_45, label %list_idx_oob_46
list_idx_ok_45:
  %t231 = getelementptr inbounds i8, i8* %t227, i64 %t229
  %t232 = load i8, i8* %t231
  br label %list_idx_end_47
list_idx_oob_46:
  br label %list_idx_end_47
list_idx_end_47:
  %t233 = phi i8 [ %t232, %list_idx_ok_45 ], [ 0, %list_idx_oob_46 ]
  %t234 = load i8*, i8** %t2
  %t235 = icmp eq i8* %t234, null
  br i1 %t235, label %list_read_null_48, label %list_read_real_49
list_read_null_48:
  br label %list_read_end_50
list_read_real_49:
  %t236 = bitcast i8* %t234 to { i8*, i64, i64 }*
  %t237 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t236, i32 0, i32 0
  %t238 = load i8*, i8** %t237
  %t239 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t236, i32 0, i32 1
  %t240 = load i64, i64* %t239
  br label %list_read_end_50
list_read_end_50:
  %t241 = phi i8* [ null, %list_read_null_48 ], [ %t238, %list_read_real_49 ]
  %t242 = phi i64 [ 0, %list_read_null_48 ], [ %t240, %list_read_real_49 ]
  %t243 = sext i32 2 to i64
  %t244 = icmp ult i64 %t243, %t242
  br i1 %t244, label %list_idx_ok_51, label %list_idx_oob_52
list_idx_ok_51:
  %t245 = getelementptr inbounds i8, i8* %t241, i64 %t243
  %t246 = load i8, i8* %t245
  br label %list_idx_end_53
list_idx_oob_52:
  br label %list_idx_end_53
list_idx_end_53:
  %t247 = phi i8 [ %t246, %list_idx_ok_51 ], [ 0, %list_idx_oob_52 ]
  %t248 = getelementptr inbounds [39 x i8], [39 x i8]* @.str.2, i64 0, i64 0
  %t249 = zext i8 %t219 to i32
  %t250 = zext i8 %t233 to i32
  %t251 = zext i8 %t247 to i32
  call i32 (i8*, ...) @printf(i8* %t248, i32 %t249, i32 %t250, i32 %t251)
  %t252 = trunc i32 104 to i8
  %t253 = getelementptr i8, i8* null, i32 1
  %t254 = ptrtoint i8* %t253 to i64
  %t255 = load i8*, i8** %t2
  %t256 = icmp eq i8* %t255, null
  br i1 %t256, label %list_cow_alloc_54, label %list_cow_check_55
list_cow_alloc_54:
  %t257 = bitcast void (i8*)* @list_release_u8 to i8*
  %t258 = call i8* @star_rc_alloc(i64 24, i8* %t257)
  %t259 = bitcast i8* %t258 to { i8*, i64, i64 }*
  %t260 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t259, i32 0, i32 0
  store i8* null, i8** %t260
  %t261 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t259, i32 0, i32 1
  store i64 0, i64* %t261
  %t262 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t259, i32 0, i32 2
  store i64 0, i64* %t262
  store i8* %t258, i8** %t2
  br label %list_cow_done_56
list_cow_check_55:
  %t263 = getelementptr inbounds i8, i8* %t255, i64 -16
  %t264 = bitcast i8* %t263 to i64*
  %t265 = load atomic i64, i64* %t264 seq_cst, align 8
  %t266 = icmp eq i64 %t265, 1
  br i1 %t266, label %list_cow_done_56, label %list_cow_clone_57
list_cow_clone_57:
  %t267 = bitcast i8* %t255 to { i8*, i64, i64 }*
  %t268 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t267, i32 0, i32 0
  %t269 = load i8*, i8** %t268
  %t270 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t267, i32 0, i32 1
  %t271 = load i64, i64* %t270
  %t272 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t267, i32 0, i32 2
  %t273 = load i64, i64* %t272
  %t274 = bitcast void (i8*)* @list_release_u8 to i8*
  %t275 = call i8* @star_rc_alloc(i64 24, i8* %t274)
  %t276 = bitcast i8* %t275 to { i8*, i64, i64 }*
  %t277 = mul i64 %t273, %t254
  %t278 = call i8* @malloc(i64 %t277)
  %t279 = bitcast i8* %t278 to i8*
  %t280 = icmp sgt i64 %t271, 0
  br i1 %t280, label %list_cow_copy_58, label %list_cow_after_copy_59
list_cow_copy_58:
  %t281 = mul i64 %t271, %t254
  %t282 = bitcast i8* %t269 to i8*
  call i8* @memcpy(i8* %t278, i8* %t282, i64 %t281)
  br label %list_cow_after_copy_59
list_cow_after_copy_59:
  %t283 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t276, i32 0, i32 0
  store i8* %t279, i8** %t283
  %t284 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t276, i32 0, i32 1
  store i64 %t271, i64* %t284
  %t285 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t276, i32 0, i32 2
  store i64 %t273, i64* %t285
  call void @star_rc_release(i8* %t255)
  store i8* %t275, i8** %t2
  br label %list_cow_done_56
list_cow_done_56:
  %t286 = load i8*, i8** %t2
  %t287 = bitcast i8* %t286 to { i8*, i64, i64 }*
  %t288 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t287, i32 0, i32 0
  %t289 = load i8*, i8** %t288
  %t290 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t287, i32 0, i32 1
  %t291 = load i64, i64* %t290
  %t292 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t287, i32 0, i32 2
  %t293 = sext i32 0 to i64
  %t294 = icmp ult i64 %t293, %t291
  br i1 %t294, label %list_set_do_60, label %list_set_oob_61
list_set_do_60:
  %t295 = getelementptr inbounds i8, i8* %t289, i64 %t293
  store i8 %t252, i8* %t295
  br label %list_set_end_62
list_set_oob_61:
  br label %list_set_end_62
list_set_end_62:
  %t296 = load i8*, i8** %t2
  %t297 = icmp eq i8* %t296, null
  br i1 %t297, label %list_read_null_63, label %list_read_real_64
list_read_null_63:
  br label %list_read_end_65
list_read_real_64:
  %t298 = bitcast i8* %t296 to { i8*, i64, i64 }*
  %t299 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t298, i32 0, i32 0
  %t300 = load i8*, i8** %t299
  %t301 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t298, i32 0, i32 1
  %t302 = load i64, i64* %t301
  br label %list_read_end_65
list_read_end_65:
  %t303 = phi i8* [ null, %list_read_null_63 ], [ %t300, %list_read_real_64 ]
  %t304 = phi i64 [ 0, %list_read_null_63 ], [ %t302, %list_read_real_64 ]
  %t305 = sext i32 0 to i64
  %t306 = icmp ult i64 %t305, %t304
  br i1 %t306, label %list_idx_ok_66, label %list_idx_oob_67
list_idx_ok_66:
  %t307 = getelementptr inbounds i8, i8* %t303, i64 %t305
  %t308 = load i8, i8* %t307
  br label %list_idx_end_68
list_idx_oob_67:
  br label %list_idx_end_68
list_idx_end_68:
  %t309 = phi i8 [ %t308, %list_idx_ok_66 ], [ 0, %list_idx_oob_67 ]
  %t310 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.3, i64 0, i64 0
  %t311 = zext i8 %t309 to i32
  call i32 (i8*, ...) @printf(i8* %t310, i32 %t311)
  %t313 = getelementptr i8, i8* null, i32 1
  %t314 = ptrtoint i8* %t313 to i64
  %t315 = load i8*, i8** %t2
  %t316 = icmp eq i8* %t315, null
  br i1 %t316, label %list_cow_alloc_69, label %list_cow_check_70
list_cow_alloc_69:
  %t317 = bitcast void (i8*)* @list_release_u8 to i8*
  %t318 = call i8* @star_rc_alloc(i64 24, i8* %t317)
  %t319 = bitcast i8* %t318 to { i8*, i64, i64 }*
  %t320 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t319, i32 0, i32 0
  store i8* null, i8** %t320
  %t321 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t319, i32 0, i32 1
  store i64 0, i64* %t321
  %t322 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t319, i32 0, i32 2
  store i64 0, i64* %t322
  store i8* %t318, i8** %t2
  br label %list_cow_done_71
list_cow_check_70:
  %t323 = getelementptr inbounds i8, i8* %t315, i64 -16
  %t324 = bitcast i8* %t323 to i64*
  %t325 = load atomic i64, i64* %t324 seq_cst, align 8
  %t326 = icmp eq i64 %t325, 1
  br i1 %t326, label %list_cow_done_71, label %list_cow_clone_72
list_cow_clone_72:
  %t327 = bitcast i8* %t315 to { i8*, i64, i64 }*
  %t328 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t327, i32 0, i32 0
  %t329 = load i8*, i8** %t328
  %t330 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t327, i32 0, i32 1
  %t331 = load i64, i64* %t330
  %t332 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t327, i32 0, i32 2
  %t333 = load i64, i64* %t332
  %t334 = bitcast void (i8*)* @list_release_u8 to i8*
  %t335 = call i8* @star_rc_alloc(i64 24, i8* %t334)
  %t336 = bitcast i8* %t335 to { i8*, i64, i64 }*
  %t337 = mul i64 %t333, %t314
  %t338 = call i8* @malloc(i64 %t337)
  %t339 = bitcast i8* %t338 to i8*
  %t340 = icmp sgt i64 %t331, 0
  br i1 %t340, label %list_cow_copy_73, label %list_cow_after_copy_74
list_cow_copy_73:
  %t341 = mul i64 %t331, %t314
  %t342 = bitcast i8* %t329 to i8*
  call i8* @memcpy(i8* %t338, i8* %t342, i64 %t341)
  br label %list_cow_after_copy_74
list_cow_after_copy_74:
  %t343 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t336, i32 0, i32 0
  store i8* %t339, i8** %t343
  %t344 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t336, i32 0, i32 1
  store i64 %t331, i64* %t344
  %t345 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t336, i32 0, i32 2
  store i64 %t333, i64* %t345
  call void @star_rc_release(i8* %t315)
  store i8* %t335, i8** %t2
  br label %list_cow_done_71
list_cow_done_71:
  %t346 = load i8*, i8** %t2
  %t347 = bitcast i8* %t346 to { i8*, i64, i64 }*
  %t348 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t347, i32 0, i32 0
  %t349 = load i8*, i8** %t348
  %t350 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t347, i32 0, i32 1
  %t351 = load i64, i64* %t350
  %t352 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t347, i32 0, i32 2
  %t353 = icmp eq i64 %t351, 0
  br i1 %t353, label %list_pop_empty_75, label %list_pop_nonempty_76
list_pop_nonempty_76:
  %t354 = sub i64 %t351, 1
  store i64 %t354, i64* %t350
  %t355 = load i8*, i8** %t348
  %t356 = getelementptr inbounds i8, i8* %t355, i64 %t354
  %t357 = load i8, i8* %t356
  br label %list_pop_end_77
list_pop_empty_75:
  br label %list_pop_end_77
list_pop_end_77:
  %t358 = phi i8 [ %t357, %list_pop_nonempty_76 ], [ 0, %list_pop_empty_75 ]
  store i8 %t358, i8* %t312
  %t359 = load i8, i8* %t312
  %t360 = load i8*, i8** %t2
  %t361 = icmp eq i8* %t360, null
  br i1 %t361, label %list_read_null_78, label %list_read_real_79
list_read_null_78:
  br label %list_read_end_80
list_read_real_79:
  %t362 = bitcast i8* %t360 to { i8*, i64, i64 }*
  %t363 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t362, i32 0, i32 0
  %t364 = load i8*, i8** %t363
  %t365 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t362, i32 0, i32 1
  %t366 = load i64, i64* %t365
  br label %list_read_end_80
list_read_end_80:
  %t367 = phi i8* [ null, %list_read_null_78 ], [ %t364, %list_read_real_79 ]
  %t368 = phi i64 [ 0, %list_read_null_78 ], [ %t366, %list_read_real_79 ]
  %t369 = trunc i64 %t368 to i32
  %t370 = getelementptr inbounds [27 x i8], [27 x i8]* @.str.4, i64 0, i64 0
  %t371 = zext i8 %t359 to i32
  call i32 (i8*, ...) @printf(i8* %t370, i32 %t371, i32 %t369)
  store i8* null, i8** %t372
  %t373 = getelementptr i8, i8* null, i32 1
  %t374 = ptrtoint i8* %t373 to i64
  %t375 = load i8*, i8** %t372
  %t376 = icmp eq i8* %t375, null
  br i1 %t376, label %list_cow_alloc_81, label %list_cow_check_82
list_cow_alloc_81:
  %t377 = bitcast void (i8*)* @list_release_u8 to i8*
  %t378 = call i8* @star_rc_alloc(i64 24, i8* %t377)
  %t379 = bitcast i8* %t378 to { i8*, i64, i64 }*
  %t380 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t379, i32 0, i32 0
  store i8* null, i8** %t380
  %t381 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t379, i32 0, i32 1
  store i64 0, i64* %t381
  %t382 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t379, i32 0, i32 2
  store i64 0, i64* %t382
  store i8* %t378, i8** %t372
  br label %list_cow_done_83
list_cow_check_82:
  %t383 = getelementptr inbounds i8, i8* %t375, i64 -16
  %t384 = bitcast i8* %t383 to i64*
  %t385 = load atomic i64, i64* %t384 seq_cst, align 8
  %t386 = icmp eq i64 %t385, 1
  br i1 %t386, label %list_cow_done_83, label %list_cow_clone_84
list_cow_clone_84:
  %t387 = bitcast i8* %t375 to { i8*, i64, i64 }*
  %t388 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t387, i32 0, i32 0
  %t389 = load i8*, i8** %t388
  %t390 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t387, i32 0, i32 1
  %t391 = load i64, i64* %t390
  %t392 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t387, i32 0, i32 2
  %t393 = load i64, i64* %t392
  %t394 = bitcast void (i8*)* @list_release_u8 to i8*
  %t395 = call i8* @star_rc_alloc(i64 24, i8* %t394)
  %t396 = bitcast i8* %t395 to { i8*, i64, i64 }*
  %t397 = mul i64 %t393, %t374
  %t398 = call i8* @malloc(i64 %t397)
  %t399 = bitcast i8* %t398 to i8*
  %t400 = icmp sgt i64 %t391, 0
  br i1 %t400, label %list_cow_copy_85, label %list_cow_after_copy_86
list_cow_copy_85:
  %t401 = mul i64 %t391, %t374
  %t402 = bitcast i8* %t389 to i8*
  call i8* @memcpy(i8* %t398, i8* %t402, i64 %t401)
  br label %list_cow_after_copy_86
list_cow_after_copy_86:
  %t403 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t396, i32 0, i32 0
  store i8* %t399, i8** %t403
  %t404 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t396, i32 0, i32 1
  store i64 %t391, i64* %t404
  %t405 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t396, i32 0, i32 2
  store i64 %t393, i64* %t405
  call void @star_rc_release(i8* %t375)
  store i8* %t395, i8** %t372
  br label %list_cow_done_83
list_cow_done_83:
  %t406 = load i8*, i8** %t372
  %t407 = bitcast i8* %t406 to { i8*, i64, i64 }*
  %t408 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t407, i32 0, i32 0
  %t409 = load i8*, i8** %t408
  %t410 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t407, i32 0, i32 1
  %t411 = load i64, i64* %t410
  %t412 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t407, i32 0, i32 2
  %t413 = icmp eq i64 %t411, 0
  br i1 %t413, label %list_pop_empty_87, label %list_pop_nonempty_88
list_pop_nonempty_88:
  %t414 = sub i64 %t411, 1
  store i64 %t414, i64* %t410
  %t415 = load i8*, i8** %t408
  %t416 = getelementptr inbounds i8, i8* %t415, i64 %t414
  %t417 = load i8, i8* %t416
  br label %list_pop_end_89
list_pop_empty_87:
  br label %list_pop_end_89
list_pop_end_89:
  %t418 = phi i8 [ %t417, %list_pop_nonempty_88 ], [ 0, %list_pop_empty_87 ]
  %t419 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.5, i64 0, i64 0
  %t420 = zext i8 %t418 to i32
  call i32 (i8*, ...) @printf(i8* %t419, i32 %t420)
  %t421 = load i8*, i8** %t372
  %t422 = icmp eq i8* %t421, null
  br i1 %t422, label %list_read_null_90, label %list_read_real_91
list_read_null_90:
  br label %list_read_end_92
list_read_real_91:
  %t423 = bitcast i8* %t421 to { i8*, i64, i64 }*
  %t424 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t423, i32 0, i32 0
  %t425 = load i8*, i8** %t424
  %t426 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t423, i32 0, i32 1
  %t427 = load i64, i64* %t426
  br label %list_read_end_92
list_read_end_92:
  %t428 = phi i8* [ null, %list_read_null_90 ], [ %t425, %list_read_real_91 ]
  %t429 = phi i64 [ 0, %list_read_null_90 ], [ %t427, %list_read_real_91 ]
  %t430 = sext i32 0 to i64
  %t431 = icmp ult i64 %t430, %t429
  br i1 %t431, label %list_idx_ok_93, label %list_idx_oob_94
list_idx_ok_93:
  %t432 = getelementptr inbounds i8, i8* %t428, i64 %t430
  %t433 = load i8, i8* %t432
  br label %list_idx_end_95
list_idx_oob_94:
  br label %list_idx_end_95
list_idx_end_95:
  %t434 = phi i8 [ %t433, %list_idx_ok_93 ], [ 0, %list_idx_oob_94 ]
  %t435 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.6, i64 0, i64 0
  %t436 = zext i8 %t434 to i32
  call i32 (i8*, ...) @printf(i8* %t435, i32 %t436)
  %t438 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.7, i64 0, i32 2, i64 0
  %t439 = call i32 @strlen(i8* %t438)
  %t440 = sext i32 %t439 to i64
  %t441 = call i8* @malloc(i64 %t440)
  call i8* @memcpy(i8* %t441, i8* %t438, i64 %t440)
  call void @star_rc_release(i8* %t438)
  %t442 = bitcast void (i8*)* @list_release_u8 to i8*
  %t443 = call i8* @star_rc_alloc(i64 24, i8* %t442)
  %t444 = bitcast i8* %t443 to { i8*, i64, i64 }*
  %t445 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t444, i32 0, i32 0
  store i8* %t441, i8** %t445
  %t446 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t444, i32 0, i32 1
  store i64 %t440, i64* %t446
  %t447 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t444, i32 0, i32 2
  store i64 %t440, i64* %t447
  store i8* %t443, i8** %t437
  %t448 = load i8*, i8** %t437
  %t449 = icmp eq i8* %t448, null
  br i1 %t449, label %list_read_null_96, label %list_read_real_97
list_read_null_96:
  br label %list_read_end_98
list_read_real_97:
  %t450 = bitcast i8* %t448 to { i8*, i64, i64 }*
  %t451 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t450, i32 0, i32 0
  %t452 = load i8*, i8** %t451
  %t453 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t450, i32 0, i32 1
  %t454 = load i64, i64* %t453
  br label %list_read_end_98
list_read_end_98:
  %t455 = phi i8* [ null, %list_read_null_96 ], [ %t452, %list_read_real_97 ]
  %t456 = phi i64 [ 0, %list_read_null_96 ], [ %t454, %list_read_real_97 ]
  %t457 = trunc i64 %t456 to i32
  %t458 = getelementptr inbounds [36 x i8], [36 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t458, i32 %t457)
  %t459 = load i8*, i8** %t437
  %t460 = icmp eq i8* %t459, null
  br i1 %t460, label %list_read_null_99, label %list_read_real_100
list_read_null_99:
  br label %list_read_end_101
list_read_real_100:
  %t461 = bitcast i8* %t459 to { i8*, i64, i64 }*
  %t462 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t461, i32 0, i32 0
  %t463 = load i8*, i8** %t462
  %t464 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t461, i32 0, i32 1
  %t465 = load i64, i64* %t464
  br label %list_read_end_101
list_read_end_101:
  %t466 = phi i8* [ null, %list_read_null_99 ], [ %t463, %list_read_real_100 ]
  %t467 = phi i64 [ 0, %list_read_null_99 ], [ %t465, %list_read_real_100 ]
  %t468 = sext i32 0 to i64
  %t469 = icmp ult i64 %t468, %t467
  br i1 %t469, label %list_idx_ok_102, label %list_idx_oob_103
list_idx_ok_102:
  %t470 = getelementptr inbounds i8, i8* %t466, i64 %t468
  %t471 = load i8, i8* %t470
  br label %list_idx_end_104
list_idx_oob_103:
  br label %list_idx_end_104
list_idx_end_104:
  %t472 = phi i8 [ %t471, %list_idx_ok_102 ], [ 0, %list_idx_oob_103 ]
  %t473 = getelementptr inbounds [33 x i8], [33 x i8]* @.str.9, i64 0, i64 0
  %t474 = zext i8 %t472 to i32
  call i32 (i8*, ...) @printf(i8* %t473, i32 %t474)
  %t476 = load i8*, i8** %t437
  %t477 = icmp eq i8* %t476, null
  br i1 %t477, label %list_read_null_105, label %list_read_real_106
list_read_null_105:
  br label %list_read_end_107
list_read_real_106:
  %t478 = bitcast i8* %t476 to { i8*, i64, i64 }*
  %t479 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t478, i32 0, i32 0
  %t480 = load i8*, i8** %t479
  %t481 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t478, i32 0, i32 1
  %t482 = load i64, i64* %t481
  br label %list_read_end_107
list_read_end_107:
  %t483 = phi i8* [ null, %list_read_null_105 ], [ %t480, %list_read_real_106 ]
  %t484 = phi i64 [ 0, %list_read_null_105 ], [ %t482, %list_read_real_106 ]
  %t485 = add i64 %t484, 1
  %t486 = call i8* @star_rc_alloc(i64 %t485, i8* null)
  call i8* @memcpy(i8* %t486, i8* %t483, i64 %t484)
  %t487 = getelementptr inbounds i8, i8* %t486, i64 %t484
  store i8 0, i8* %t487
  store i8* %t486, i8** %t475
  %t488 = load i8*, i8** %t475
  %t489 = load i8*, i8** %t475
  call void @star_rc_retain(i8* %t489)
  call void @star_rc_release(i8* %t488)
  %t490 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t490, i8* %t488)
  %t492 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.11, i64 0, i32 2, i64 0
  %t493 = call i32 @strlen(i8* %t492)
  %t494 = sext i32 %t493 to i64
  %t495 = call i8* @malloc(i64 %t494)
  call i8* @memcpy(i8* %t495, i8* %t492, i64 %t494)
  call void @star_rc_release(i8* %t492)
  %t496 = bitcast void (i8*)* @list_release_u8 to i8*
  %t497 = call i8* @star_rc_alloc(i64 24, i8* %t496)
  %t498 = bitcast i8* %t497 to { i8*, i64, i64 }*
  %t499 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t498, i32 0, i32 0
  store i8* %t495, i8** %t499
  %t500 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t498, i32 0, i32 1
  store i64 %t494, i64* %t500
  %t501 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t498, i32 0, i32 2
  store i64 %t494, i64* %t501
  store i8* %t497, i8** %t491
  %t503 = load i8*, i8** %t491
  %t504 = load i8*, i8** %t491
  call void @star_rc_retain(i8* %t504)
  store i8* %t503, i8** %t502
  %t505 = getelementptr i8, i8* null, i32 1
  %t506 = ptrtoint i8* %t505 to i64
  %t507 = load i8*, i8** %t491
  %t508 = icmp eq i8* %t507, null
  br i1 %t508, label %list_cow_alloc_108, label %list_cow_check_109
list_cow_alloc_108:
  %t509 = bitcast void (i8*)* @list_release_u8 to i8*
  %t510 = call i8* @star_rc_alloc(i64 24, i8* %t509)
  %t511 = bitcast i8* %t510 to { i8*, i64, i64 }*
  %t512 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t511, i32 0, i32 0
  store i8* null, i8** %t512
  %t513 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t511, i32 0, i32 1
  store i64 0, i64* %t513
  %t514 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t511, i32 0, i32 2
  store i64 0, i64* %t514
  store i8* %t510, i8** %t491
  br label %list_cow_done_110
list_cow_check_109:
  %t515 = getelementptr inbounds i8, i8* %t507, i64 -16
  %t516 = bitcast i8* %t515 to i64*
  %t517 = load atomic i64, i64* %t516 seq_cst, align 8
  %t518 = icmp eq i64 %t517, 1
  br i1 %t518, label %list_cow_done_110, label %list_cow_clone_111
list_cow_clone_111:
  %t519 = bitcast i8* %t507 to { i8*, i64, i64 }*
  %t520 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t519, i32 0, i32 0
  %t521 = load i8*, i8** %t520
  %t522 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t519, i32 0, i32 1
  %t523 = load i64, i64* %t522
  %t524 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t519, i32 0, i32 2
  %t525 = load i64, i64* %t524
  %t526 = bitcast void (i8*)* @list_release_u8 to i8*
  %t527 = call i8* @star_rc_alloc(i64 24, i8* %t526)
  %t528 = bitcast i8* %t527 to { i8*, i64, i64 }*
  %t529 = mul i64 %t525, %t506
  %t530 = call i8* @malloc(i64 %t529)
  %t531 = bitcast i8* %t530 to i8*
  %t532 = icmp sgt i64 %t523, 0
  br i1 %t532, label %list_cow_copy_112, label %list_cow_after_copy_113
list_cow_copy_112:
  %t533 = mul i64 %t523, %t506
  %t534 = bitcast i8* %t521 to i8*
  call i8* @memcpy(i8* %t530, i8* %t534, i64 %t533)
  br label %list_cow_after_copy_113
list_cow_after_copy_113:
  %t535 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t528, i32 0, i32 0
  store i8* %t531, i8** %t535
  %t536 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t528, i32 0, i32 1
  store i64 %t523, i64* %t536
  %t537 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t528, i32 0, i32 2
  store i64 %t525, i64* %t537
  call void @star_rc_release(i8* %t507)
  store i8* %t527, i8** %t491
  br label %list_cow_done_110
list_cow_done_110:
  %t538 = load i8*, i8** %t491
  %t539 = bitcast i8* %t538 to { i8*, i64, i64 }*
  %t540 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t539, i32 0, i32 0
  %t541 = load i8*, i8** %t540
  %t542 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t539, i32 0, i32 1
  %t543 = load i64, i64* %t542
  %t544 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t539, i32 0, i32 2
  %t545 = trunc i32 99 to i8
  %t546 = load i64, i64* %t544
  %t547 = load i8*, i8** %t540
  %t548 = load i64, i64* %t542
  %t549 = icmp sge i64 %t548, %t546
  br i1 %t549, label %list_push_grow_114, label %list_push_store_115
list_push_grow_114:
  %t550 = mul i64 %t546, 2
  %t551 = icmp sgt i64 %t550, 0
  %t552 = select i1 %t551, i64 %t550, i64 1
  %t553 = getelementptr i8, i8* null, i32 1
  %t554 = ptrtoint i8* %t553 to i64
  %t555 = mul i64 %t552, %t554
  %t556 = call i8* @malloc(i64 %t555)
  %t557 = bitcast i8* %t556 to i8*
  %t558 = icmp sgt i64 %t546, 0
  br i1 %t558, label %list_push_copy_116, label %list_push_after_copy_117
list_push_copy_116:
  %t559 = mul i64 %t548, %t554
  %t560 = bitcast i8* %t547 to i8*
  call i8* @memcpy(i8* %t556, i8* %t560, i64 %t559)
  call void @free(i8* %t560)
  br label %list_push_after_copy_117
list_push_after_copy_117:
  store i8* %t557, i8** %t540
  store i64 %t552, i64* %t544
  br label %list_push_store_115
list_push_store_115:
  %t561 = load i8*, i8** %t540
  %t562 = getelementptr inbounds i8, i8* %t561, i64 %t548
  store i8 %t545, i8* %t562
  %t563 = add i64 %t548, 1
  store i64 %t563, i64* %t542
  %t564 = load i8*, i8** %t491
  %t565 = icmp eq i8* %t564, null
  br i1 %t565, label %list_read_null_118, label %list_read_real_119
list_read_null_118:
  br label %list_read_end_120
list_read_real_119:
  %t566 = bitcast i8* %t564 to { i8*, i64, i64 }*
  %t567 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t566, i32 0, i32 0
  %t568 = load i8*, i8** %t567
  %t569 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t566, i32 0, i32 1
  %t570 = load i64, i64* %t569
  br label %list_read_end_120
list_read_end_120:
  %t571 = phi i8* [ null, %list_read_null_118 ], [ %t568, %list_read_real_119 ]
  %t572 = phi i64 [ 0, %list_read_null_118 ], [ %t570, %list_read_real_119 ]
  %t573 = trunc i64 %t572 to i32
  %t574 = load i8*, i8** %t502
  %t575 = icmp eq i8* %t574, null
  br i1 %t575, label %list_read_null_121, label %list_read_real_122
list_read_null_121:
  br label %list_read_end_123
list_read_real_122:
  %t576 = bitcast i8* %t574 to { i8*, i64, i64 }*
  %t577 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t576, i32 0, i32 0
  %t578 = load i8*, i8** %t577
  %t579 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t576, i32 0, i32 1
  %t580 = load i64, i64* %t579
  br label %list_read_end_123
list_read_end_123:
  %t581 = phi i8* [ null, %list_read_null_121 ], [ %t578, %list_read_real_122 ]
  %t582 = phi i64 [ 0, %list_read_null_121 ], [ %t580, %list_read_real_122 ]
  %t583 = trunc i64 %t582 to i32
  %t584 = getelementptr inbounds [28 x i8], [28 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t584, i32 %t573, i32 %t583)
  %t586 = getelementptr inbounds { i64, i8*, [1 x i8] }, { i64, i8*, [1 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t587 = call i32 @strlen(i8* %t586)
  %t588 = sext i32 %t587 to i64
  %t589 = call i8* @malloc(i64 %t588)
  call i8* @memcpy(i8* %t589, i8* %t586, i64 %t588)
  call void @star_rc_release(i8* %t586)
  %t590 = bitcast void (i8*)* @list_release_u8 to i8*
  %t591 = call i8* @star_rc_alloc(i64 24, i8* %t590)
  %t592 = bitcast i8* %t591 to { i8*, i64, i64 }*
  %t593 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t592, i32 0, i32 0
  store i8* %t589, i8** %t593
  %t594 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t592, i32 0, i32 1
  store i64 %t588, i64* %t594
  %t595 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t592, i32 0, i32 2
  store i64 %t588, i64* %t595
  store i8* %t591, i8** %t585
  %t596 = load i8*, i8** %t585
  %t597 = icmp eq i8* %t596, null
  br i1 %t597, label %list_read_null_124, label %list_read_real_125
list_read_null_124:
  br label %list_read_end_126
list_read_real_125:
  %t598 = bitcast i8* %t596 to { i8*, i64, i64 }*
  %t599 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t598, i32 0, i32 0
  %t600 = load i8*, i8** %t599
  %t601 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t598, i32 0, i32 1
  %t602 = load i64, i64* %t601
  br label %list_read_end_126
list_read_end_126:
  %t603 = phi i8* [ null, %list_read_null_124 ], [ %t600, %list_read_real_125 ]
  %t604 = phi i64 [ 0, %list_read_null_124 ], [ %t602, %list_read_real_125 ]
  %t605 = trunc i64 %t604 to i32
  %t606 = getelementptr inbounds [31 x i8], [31 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t606, i32 %t605)
  %t607 = load i8*, i8** %t585
  %t608 = icmp eq i8* %t607, null
  br i1 %t608, label %list_read_null_127, label %list_read_real_128
list_read_null_127:
  br label %list_read_end_129
list_read_real_128:
  %t609 = bitcast i8* %t607 to { i8*, i64, i64 }*
  %t610 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t609, i32 0, i32 0
  %t611 = load i8*, i8** %t610
  %t612 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t609, i32 0, i32 1
  %t613 = load i64, i64* %t612
  br label %list_read_end_129
list_read_end_129:
  %t614 = phi i8* [ null, %list_read_null_127 ], [ %t611, %list_read_real_128 ]
  %t615 = phi i64 [ 0, %list_read_null_127 ], [ %t613, %list_read_real_128 ]
  %t616 = add i64 %t615, 1
  %t617 = call i8* @star_rc_alloc(i64 %t616, i8* null)
  call i8* @memcpy(i8* %t617, i8* %t614, i64 %t615)
  %t618 = getelementptr inbounds i8, i8* %t617, i64 %t615
  store i8 0, i8* %t618
  call void @star_rc_release(i8* %t617)
  %t619 = getelementptr inbounds [30 x i8], [30 x i8]* @.str.15, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t619, i8* %t617)
  %t620 = load i8*, i8** %t585
  call void @star_rc_release(i8* %t620)
  %t621 = load i8*, i8** %t502
  call void @star_rc_release(i8* %t621)
  %t622 = load i8*, i8** %t491
  call void @star_rc_release(i8* %t622)
  %t623 = load i8*, i8** %t475
  call void @star_rc_release(i8* %t623)
  %t624 = load i8*, i8** %t437
  call void @star_rc_release(i8* %t624)
  %t625 = load i8*, i8** %t372
  call void @star_rc_release(i8* %t625)
  %t626 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t626)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_u8(i8* %objp) {
entry:
  %t18 = bitcast i8* %objp to { i8*, i64, i64 }*
  %t19 = getelementptr inbounds { i8*, i64, i64 }, { i8*, i64, i64 }* %t18, i32 0, i32 0
  %t20 = load i8*, i8** %t19
  %t21 = bitcast i8* %t20 to i8*
  call void @free(i8* %t21)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [22 x i8] c"empty buf.len() = %d\0A\00"
@.str.1 = private unnamed_addr constant [26 x i8] c"after 3 pushes, len = %d\0A\00"
@.str.2 = private unnamed_addr constant [39 x i8] c"buf[0] = %u, buf[1] = %u, buf[2] = %u\0A\00"
@.str.3 = private unnamed_addr constant [33 x i8] c"after buf[0] = 104, buf[0] = %u\0A\00"
@.str.4 = private unnamed_addr constant [27 x i8] c"popped = %u, len now = %d\0A\00"
@.str.5 = private unnamed_addr constant [18 x i8] c"empty.pop() = %u\0A\00"
@.str.6 = private unnamed_addr constant [15 x i8] c"empty[0] = %u\0A\00"
@.str.7 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"Hello\00" }
@.str.8 = private unnamed_addr constant [36 x i8] c"bytes_from_str(\22Hello\22).len() = %d\0A\00"
@.str.9 = private unnamed_addr constant [33 x i8] c"bytes_from_str(\22Hello\22)[0] = %u\0A\00"
@.str.10 = private unnamed_addr constant [16 x i8] c"round-trip: %s\0A\00"
@.str.11 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"ab\00" }
@.str.12 = private unnamed_addr constant [28 x i8] c"a.len() = %d, b.len() = %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [1 x i8] } { i64 -1, i8* null, [1 x i8] c"\00" }
@.str.14 = private unnamed_addr constant [31 x i8] c"bytes_from_str(\22\22).len() = %d\0A\00"
@.str.15 = private unnamed_addr constant [30 x i8] c"str_from_bytes(empty) = \22%s\22\0A\00"
