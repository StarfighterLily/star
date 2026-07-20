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

%Point = type { i32, i32 }
%Rect = type { float, float, float, float }
%Aabb2 = type { <2 x float>, <2 x float> }
%Aabb3 = type { <3 x float>, <3 x float> }
%Transform = type { <3 x float>, <4 x float>, <3 x float> }
%Ray = type { <3 x float>, <3 x float> }
%Plane = type { <3 x float>, float }
%Frustum = type { [6 x %Plane] }
define i32 @sum_list(i8* %nums) {
entry:
  %t0 = alloca i8*
  %t1 = alloca i32
  %t2 = alloca i32
  store i8* %nums, i8** %t0
  store i32 0, i32* %t1
  store i32 0, i32* %t2
  br label %while_cond_0
while_cond_0:
  %t3 = load i32, i32* %t2
  %t4 = load i8*, i8** %t0
  %t5 = icmp eq i8* %t4, null
  br i1 %t5, label %list_read_null_4, label %list_read_real_5
list_read_null_4:
  br label %list_read_end_6
list_read_real_5:
  %t6 = bitcast i8* %t4 to { i32*, i64, i64 }*
  %t7 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t6, i32 0, i32 0
  %t8 = load i32*, i32** %t7
  %t9 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t6, i32 0, i32 1
  %t10 = load i64, i64* %t9
  br label %list_read_end_6
list_read_end_6:
  %t11 = phi i32* [ null, %list_read_null_4 ], [ %t8, %list_read_real_5 ]
  %t12 = phi i64 [ 0, %list_read_null_4 ], [ %t10, %list_read_real_5 ]
  %t13 = trunc i64 %t12 to i32
  %t14 = icmp slt i32 %t3, %t13
  br i1 %t14, label %while_body_1, label %while_else_2
while_body_1:
  %t15 = load i8*, i8** %t0
  %t16 = icmp eq i8* %t15, null
  br i1 %t16, label %list_read_null_7, label %list_read_real_8
list_read_null_7:
  br label %list_read_end_9
list_read_real_8:
  %t17 = bitcast i8* %t15 to { i32*, i64, i64 }*
  %t18 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 0
  %t19 = load i32*, i32** %t18
  %t20 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 1
  %t21 = load i64, i64* %t20
  br label %list_read_end_9
list_read_end_9:
  %t22 = phi i32* [ null, %list_read_null_7 ], [ %t19, %list_read_real_8 ]
  %t23 = phi i64 [ 0, %list_read_null_7 ], [ %t21, %list_read_real_8 ]
  %t24 = load i32, i32* %t2
  %t25 = sext i32 %t24 to i64
  %t26 = icmp ult i64 %t25, %t23
  br i1 %t26, label %list_idx_ok_10, label %list_idx_oob_11
list_idx_ok_10:
  %t27 = getelementptr inbounds i32, i32* %t22, i64 %t25
  %t28 = load i32, i32* %t27
  br label %list_idx_end_12
list_idx_oob_11:
  br label %list_idx_end_12
list_idx_end_12:
  %t29 = phi i32 [ %t28, %list_idx_ok_10 ], [ 0, %list_idx_oob_11 ]
  %t30 = load i32, i32* %t1
  %t31 = add i32 %t30, %t29
  store i32 %t31, i32* %t1
  %t32 = load i32, i32* %t2
  %t33 = add i32 %t32, 1
  store i32 %t33, i32* %t2
  br label %while_cond_0
while_else_2:
  br label %while_end_3
while_end_3:
  %t34 = load i32, i32* %t1
  %t35 = load i8*, i8** %t0
  call void @star_rc_release(i8* %t35)
  ret i32 %t34
}

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %t2 = alloca i8*
  %t169 = alloca i32
  %t249 = alloca i32
  %t313 = alloca i8*
  %t325 = alloca i32
  %t374 = alloca i32
  %t391 = alloca i8*
  %t392 = alloca i32
  %t497 = alloca i8*
  %t555 = alloca i8*
  %t561 = alloca %Point
  %t566 = alloca %Point
  %t581 = alloca %Point
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr i32, i32* null, i32 1
  %t4 = ptrtoint i32* %t3 to i64
  %t5 = mul i64 %t4, 3
  %t6 = call i8* @malloc(i64 %t5)
  %t7 = bitcast i8* %t6 to i32*
  %t8 = getelementptr inbounds i32, i32* %t7, i64 0
  store i32 1, i32* %t8
  %t9 = getelementptr inbounds i32, i32* %t7, i64 1
  store i32 2, i32* %t9
  %t10 = getelementptr inbounds i32, i32* %t7, i64 2
  store i32 3, i32* %t10
  %t15 = bitcast void (i8*)* @list_release_i32 to i8*
  %t16 = call i8* @star_rc_alloc(i64 24, i8* %t15)
  %t17 = bitcast i8* %t16 to { i32*, i64, i64 }*
  %t18 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 0
  store i32* %t7, i32** %t18
  %t19 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 1
  store i64 3, i64* %t19
  %t20 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t17, i32 0, i32 2
  store i64 3, i64* %t20
  store i8* %t16, i8** %t2
  %t21 = load i8*, i8** %t2
  %t22 = icmp eq i8* %t21, null
  br i1 %t22, label %list_read_null_13, label %list_read_real_14
list_read_null_13:
  br label %list_read_end_15
list_read_real_14:
  %t23 = bitcast i8* %t21 to { i32*, i64, i64 }*
  %t24 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t23, i32 0, i32 0
  %t25 = load i32*, i32** %t24
  %t26 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t23, i32 0, i32 1
  %t27 = load i64, i64* %t26
  br label %list_read_end_15
list_read_end_15:
  %t28 = phi i32* [ null, %list_read_null_13 ], [ %t25, %list_read_real_14 ]
  %t29 = phi i64 [ 0, %list_read_null_13 ], [ %t27, %list_read_real_14 ]
  %t30 = trunc i64 %t29 to i32
  %t31 = getelementptr inbounds [18 x i8], [18 x i8]* @.str.0, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t31, i32 %t30)
  %t32 = getelementptr i32, i32* null, i32 1
  %t33 = ptrtoint i32* %t32 to i64
  %t34 = load i8*, i8** %t2
  %t35 = icmp eq i8* %t34, null
  br i1 %t35, label %list_cow_alloc_16, label %list_cow_check_17
list_cow_alloc_16:
  %t36 = bitcast void (i8*)* @list_release_i32 to i8*
  %t37 = call i8* @star_rc_alloc(i64 24, i8* %t36)
  %t38 = bitcast i8* %t37 to { i32*, i64, i64 }*
  %t39 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t38, i32 0, i32 0
  store i32* null, i32** %t39
  %t40 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t38, i32 0, i32 1
  store i64 0, i64* %t40
  %t41 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t38, i32 0, i32 2
  store i64 0, i64* %t41
  store i8* %t37, i8** %t2
  br label %list_cow_done_18
list_cow_check_17:
  %t42 = getelementptr inbounds i8, i8* %t34, i64 -16
  %t43 = bitcast i8* %t42 to i64*
  %t44 = load atomic i64, i64* %t43 seq_cst, align 8
  %t45 = icmp eq i64 %t44, 1
  br i1 %t45, label %list_cow_done_18, label %list_cow_clone_19
list_cow_clone_19:
  %t46 = bitcast i8* %t34 to { i32*, i64, i64 }*
  %t47 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t46, i32 0, i32 0
  %t48 = load i32*, i32** %t47
  %t49 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t46, i32 0, i32 1
  %t50 = load i64, i64* %t49
  %t51 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t46, i32 0, i32 2
  %t52 = load i64, i64* %t51
  %t53 = bitcast void (i8*)* @list_release_i32 to i8*
  %t54 = call i8* @star_rc_alloc(i64 24, i8* %t53)
  %t55 = bitcast i8* %t54 to { i32*, i64, i64 }*
  %t56 = mul i64 %t52, %t33
  %t57 = call i8* @malloc(i64 %t56)
  %t58 = bitcast i8* %t57 to i32*
  %t59 = icmp sgt i64 %t50, 0
  br i1 %t59, label %list_cow_copy_20, label %list_cow_after_copy_21
list_cow_copy_20:
  %t60 = mul i64 %t50, %t33
  %t61 = bitcast i32* %t48 to i8*
  call i8* @memcpy(i8* %t57, i8* %t61, i64 %t60)
  br label %list_cow_after_copy_21
list_cow_after_copy_21:
  %t62 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t55, i32 0, i32 0
  store i32* %t58, i32** %t62
  %t63 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t55, i32 0, i32 1
  store i64 %t50, i64* %t63
  %t64 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t55, i32 0, i32 2
  store i64 %t52, i64* %t64
  call void @star_rc_release(i8* %t34)
  store i8* %t54, i8** %t2
  br label %list_cow_done_18
list_cow_done_18:
  %t65 = load i8*, i8** %t2
  %t66 = bitcast i8* %t65 to { i32*, i64, i64 }*
  %t67 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t66, i32 0, i32 0
  %t68 = load i32*, i32** %t67
  %t69 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t66, i32 0, i32 1
  %t70 = load i64, i64* %t69
  %t71 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t66, i32 0, i32 2
  %t72 = load i64, i64* %t71
  %t73 = load i32*, i32** %t67
  %t74 = load i64, i64* %t69
  %t75 = icmp sge i64 %t74, %t72
  br i1 %t75, label %list_push_grow_22, label %list_push_store_23
list_push_grow_22:
  %t76 = mul i64 %t72, 2
  %t77 = icmp sgt i64 %t76, 0
  %t78 = select i1 %t77, i64 %t76, i64 1
  %t79 = getelementptr i32, i32* null, i32 1
  %t80 = ptrtoint i32* %t79 to i64
  %t81 = mul i64 %t78, %t80
  %t82 = call i8* @malloc(i64 %t81)
  %t83 = bitcast i8* %t82 to i32*
  %t84 = icmp sgt i64 %t72, 0
  br i1 %t84, label %list_push_copy_24, label %list_push_after_copy_25
list_push_copy_24:
  %t85 = mul i64 %t74, %t80
  %t86 = bitcast i32* %t73 to i8*
  call i8* @memcpy(i8* %t82, i8* %t86, i64 %t85)
  call void @free(i8* %t86)
  br label %list_push_after_copy_25
list_push_after_copy_25:
  store i32* %t83, i32** %t67
  store i64 %t78, i64* %t71
  br label %list_push_store_23
list_push_store_23:
  %t87 = load i32*, i32** %t67
  %t88 = getelementptr inbounds i32, i32* %t87, i64 %t74
  store i32 4, i32* %t88
  %t89 = add i64 %t74, 1
  store i64 %t89, i64* %t69
  %t90 = getelementptr i32, i32* null, i32 1
  %t91 = ptrtoint i32* %t90 to i64
  %t92 = load i8*, i8** %t2
  %t93 = icmp eq i8* %t92, null
  br i1 %t93, label %list_cow_alloc_26, label %list_cow_check_27
list_cow_alloc_26:
  %t94 = bitcast void (i8*)* @list_release_i32 to i8*
  %t95 = call i8* @star_rc_alloc(i64 24, i8* %t94)
  %t96 = bitcast i8* %t95 to { i32*, i64, i64 }*
  %t97 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t96, i32 0, i32 0
  store i32* null, i32** %t97
  %t98 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t96, i32 0, i32 1
  store i64 0, i64* %t98
  %t99 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t96, i32 0, i32 2
  store i64 0, i64* %t99
  store i8* %t95, i8** %t2
  br label %list_cow_done_28
list_cow_check_27:
  %t100 = getelementptr inbounds i8, i8* %t92, i64 -16
  %t101 = bitcast i8* %t100 to i64*
  %t102 = load atomic i64, i64* %t101 seq_cst, align 8
  %t103 = icmp eq i64 %t102, 1
  br i1 %t103, label %list_cow_done_28, label %list_cow_clone_29
list_cow_clone_29:
  %t104 = bitcast i8* %t92 to { i32*, i64, i64 }*
  %t105 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t104, i32 0, i32 0
  %t106 = load i32*, i32** %t105
  %t107 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t104, i32 0, i32 1
  %t108 = load i64, i64* %t107
  %t109 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t104, i32 0, i32 2
  %t110 = load i64, i64* %t109
  %t111 = bitcast void (i8*)* @list_release_i32 to i8*
  %t112 = call i8* @star_rc_alloc(i64 24, i8* %t111)
  %t113 = bitcast i8* %t112 to { i32*, i64, i64 }*
  %t114 = mul i64 %t110, %t91
  %t115 = call i8* @malloc(i64 %t114)
  %t116 = bitcast i8* %t115 to i32*
  %t117 = icmp sgt i64 %t108, 0
  br i1 %t117, label %list_cow_copy_30, label %list_cow_after_copy_31
list_cow_copy_30:
  %t118 = mul i64 %t108, %t91
  %t119 = bitcast i32* %t106 to i8*
  call i8* @memcpy(i8* %t115, i8* %t119, i64 %t118)
  br label %list_cow_after_copy_31
list_cow_after_copy_31:
  %t120 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t113, i32 0, i32 0
  store i32* %t116, i32** %t120
  %t121 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t113, i32 0, i32 1
  store i64 %t108, i64* %t121
  %t122 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t113, i32 0, i32 2
  store i64 %t110, i64* %t122
  call void @star_rc_release(i8* %t92)
  store i8* %t112, i8** %t2
  br label %list_cow_done_28
list_cow_done_28:
  %t123 = load i8*, i8** %t2
  %t124 = bitcast i8* %t123 to { i32*, i64, i64 }*
  %t125 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t124, i32 0, i32 0
  %t126 = load i32*, i32** %t125
  %t127 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t124, i32 0, i32 1
  %t128 = load i64, i64* %t127
  %t129 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t124, i32 0, i32 2
  %t130 = load i64, i64* %t129
  %t131 = load i32*, i32** %t125
  %t132 = load i64, i64* %t127
  %t133 = icmp sge i64 %t132, %t130
  br i1 %t133, label %list_push_grow_32, label %list_push_store_33
list_push_grow_32:
  %t134 = mul i64 %t130, 2
  %t135 = icmp sgt i64 %t134, 0
  %t136 = select i1 %t135, i64 %t134, i64 1
  %t137 = getelementptr i32, i32* null, i32 1
  %t138 = ptrtoint i32* %t137 to i64
  %t139 = mul i64 %t136, %t138
  %t140 = call i8* @malloc(i64 %t139)
  %t141 = bitcast i8* %t140 to i32*
  %t142 = icmp sgt i64 %t130, 0
  br i1 %t142, label %list_push_copy_34, label %list_push_after_copy_35
list_push_copy_34:
  %t143 = mul i64 %t132, %t138
  %t144 = bitcast i32* %t131 to i8*
  call i8* @memcpy(i8* %t140, i8* %t144, i64 %t143)
  call void @free(i8* %t144)
  br label %list_push_after_copy_35
list_push_after_copy_35:
  store i32* %t141, i32** %t125
  store i64 %t136, i64* %t129
  br label %list_push_store_33
list_push_store_33:
  %t145 = load i32*, i32** %t125
  %t146 = getelementptr inbounds i32, i32* %t145, i64 %t132
  store i32 5, i32* %t146
  %t147 = add i64 %t132, 1
  store i64 %t147, i64* %t127
  %t148 = load i8*, i8** %t2
  %t149 = icmp eq i8* %t148, null
  br i1 %t149, label %list_read_null_36, label %list_read_real_37
list_read_null_36:
  br label %list_read_end_38
list_read_real_37:
  %t150 = bitcast i8* %t148 to { i32*, i64, i64 }*
  %t151 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t150, i32 0, i32 0
  %t152 = load i32*, i32** %t151
  %t153 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t150, i32 0, i32 1
  %t154 = load i64, i64* %t153
  br label %list_read_end_38
list_read_end_38:
  %t155 = phi i32* [ null, %list_read_null_36 ], [ %t152, %list_read_real_37 ]
  %t156 = phi i64 [ 0, %list_read_null_36 ], [ %t154, %list_read_real_37 ]
  %t157 = trunc i64 %t156 to i32
  %t158 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.1, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t158, i32 %t157)
  %t159 = load i8*, i8** %t2
  %t160 = icmp eq i8* %t159, null
  br i1 %t160, label %list_read_null_39, label %list_read_real_40
list_read_null_39:
  br label %list_read_end_41
list_read_real_40:
  %t161 = bitcast i8* %t159 to { i32*, i64, i64 }*
  %t162 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t161, i32 0, i32 0
  %t163 = load i32*, i32** %t162
  %t164 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t161, i32 0, i32 1
  %t165 = load i64, i64* %t164
  br label %list_read_end_41
list_read_end_41:
  %t166 = phi i32* [ null, %list_read_null_39 ], [ %t163, %list_read_real_40 ]
  %t167 = phi i64 [ 0, %list_read_null_39 ], [ %t165, %list_read_real_40 ]
  %t168 = trunc i64 %t167 to i32
  store i32 0, i32* %t169
  br label %for_cond_42
for_cond_42:
  %t170 = load i32, i32* %t169
  %t171 = icmp slt i32 %t170, %t168
  br i1 %t171, label %for_body_43, label %for_end_45
for_body_43:
  %t172 = load i32, i32* %t169
  %t173 = load i8*, i8** %t2
  %t174 = icmp eq i8* %t173, null
  br i1 %t174, label %list_read_null_46, label %list_read_real_47
list_read_null_46:
  br label %list_read_end_48
list_read_real_47:
  %t175 = bitcast i8* %t173 to { i32*, i64, i64 }*
  %t176 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t175, i32 0, i32 0
  %t177 = load i32*, i32** %t176
  %t178 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t175, i32 0, i32 1
  %t179 = load i64, i64* %t178
  br label %list_read_end_48
list_read_end_48:
  %t180 = phi i32* [ null, %list_read_null_46 ], [ %t177, %list_read_real_47 ]
  %t181 = phi i64 [ 0, %list_read_null_46 ], [ %t179, %list_read_real_47 ]
  %t182 = load i32, i32* %t169
  %t183 = sext i32 %t182 to i64
  %t184 = icmp ult i64 %t183, %t181
  br i1 %t184, label %list_idx_ok_49, label %list_idx_oob_50
list_idx_ok_49:
  %t185 = getelementptr inbounds i32, i32* %t180, i64 %t183
  %t186 = load i32, i32* %t185
  br label %list_idx_end_51
list_idx_oob_50:
  br label %list_idx_end_51
list_idx_end_51:
  %t187 = phi i32 [ %t186, %list_idx_ok_49 ], [ 0, %list_idx_oob_50 ]
  %t188 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.2, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t188, i32 %t172, i32 %t187)
  br label %for_step_44
for_step_44:
  %t189 = load i32, i32* %t169
  %t190 = add i32 %t189, 1
  store i32 %t190, i32* %t169
  br label %for_cond_42
for_end_45:
  %t191 = getelementptr i32, i32* null, i32 1
  %t192 = ptrtoint i32* %t191 to i64
  %t193 = load i8*, i8** %t2
  %t194 = icmp eq i8* %t193, null
  br i1 %t194, label %list_cow_alloc_52, label %list_cow_check_53
list_cow_alloc_52:
  %t195 = bitcast void (i8*)* @list_release_i32 to i8*
  %t196 = call i8* @star_rc_alloc(i64 24, i8* %t195)
  %t197 = bitcast i8* %t196 to { i32*, i64, i64 }*
  %t198 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t197, i32 0, i32 0
  store i32* null, i32** %t198
  %t199 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t197, i32 0, i32 1
  store i64 0, i64* %t199
  %t200 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t197, i32 0, i32 2
  store i64 0, i64* %t200
  store i8* %t196, i8** %t2
  br label %list_cow_done_54
list_cow_check_53:
  %t201 = getelementptr inbounds i8, i8* %t193, i64 -16
  %t202 = bitcast i8* %t201 to i64*
  %t203 = load atomic i64, i64* %t202 seq_cst, align 8
  %t204 = icmp eq i64 %t203, 1
  br i1 %t204, label %list_cow_done_54, label %list_cow_clone_55
list_cow_clone_55:
  %t205 = bitcast i8* %t193 to { i32*, i64, i64 }*
  %t206 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t205, i32 0, i32 0
  %t207 = load i32*, i32** %t206
  %t208 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t205, i32 0, i32 1
  %t209 = load i64, i64* %t208
  %t210 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t205, i32 0, i32 2
  %t211 = load i64, i64* %t210
  %t212 = bitcast void (i8*)* @list_release_i32 to i8*
  %t213 = call i8* @star_rc_alloc(i64 24, i8* %t212)
  %t214 = bitcast i8* %t213 to { i32*, i64, i64 }*
  %t215 = mul i64 %t211, %t192
  %t216 = call i8* @malloc(i64 %t215)
  %t217 = bitcast i8* %t216 to i32*
  %t218 = icmp sgt i64 %t209, 0
  br i1 %t218, label %list_cow_copy_56, label %list_cow_after_copy_57
list_cow_copy_56:
  %t219 = mul i64 %t209, %t192
  %t220 = bitcast i32* %t207 to i8*
  call i8* @memcpy(i8* %t216, i8* %t220, i64 %t219)
  br label %list_cow_after_copy_57
list_cow_after_copy_57:
  %t221 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t214, i32 0, i32 0
  store i32* %t217, i32** %t221
  %t222 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t214, i32 0, i32 1
  store i64 %t209, i64* %t222
  %t223 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t214, i32 0, i32 2
  store i64 %t211, i64* %t223
  call void @star_rc_release(i8* %t193)
  store i8* %t213, i8** %t2
  br label %list_cow_done_54
list_cow_done_54:
  %t224 = load i8*, i8** %t2
  %t225 = bitcast i8* %t224 to { i32*, i64, i64 }*
  %t226 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t225, i32 0, i32 0
  %t227 = load i32*, i32** %t226
  %t228 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t225, i32 0, i32 1
  %t229 = load i64, i64* %t228
  %t230 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t225, i32 0, i32 2
  %t231 = sext i32 0 to i64
  %t232 = icmp ult i64 %t231, %t229
  br i1 %t232, label %list_set_do_58, label %list_set_oob_59
list_set_do_58:
  %t233 = getelementptr inbounds i32, i32* %t227, i64 %t231
  store i32 100, i32* %t233
  br label %list_set_end_60
list_set_oob_59:
  br label %list_set_end_60
list_set_end_60:
  %t234 = load i8*, i8** %t2
  %t235 = icmp eq i8* %t234, null
  br i1 %t235, label %list_read_null_61, label %list_read_real_62
list_read_null_61:
  br label %list_read_end_63
list_read_real_62:
  %t236 = bitcast i8* %t234 to { i32*, i64, i64 }*
  %t237 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t236, i32 0, i32 0
  %t238 = load i32*, i32** %t237
  %t239 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t236, i32 0, i32 1
  %t240 = load i64, i64* %t239
  br label %list_read_end_63
list_read_end_63:
  %t241 = phi i32* [ null, %list_read_null_61 ], [ %t238, %list_read_real_62 ]
  %t242 = phi i64 [ 0, %list_read_null_61 ], [ %t240, %list_read_real_62 ]
  %t243 = sext i32 0 to i64
  %t244 = icmp ult i64 %t243, %t242
  br i1 %t244, label %list_idx_ok_64, label %list_idx_oob_65
list_idx_ok_64:
  %t245 = getelementptr inbounds i32, i32* %t241, i64 %t243
  %t246 = load i32, i32* %t245
  br label %list_idx_end_66
list_idx_oob_65:
  br label %list_idx_end_66
list_idx_end_66:
  %t247 = phi i32 [ %t246, %list_idx_ok_64 ], [ 0, %list_idx_oob_65 ]
  %t248 = getelementptr inbounds [24 x i8], [24 x i8]* @.str.3, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t248, i32 %t247)
  %t250 = getelementptr i32, i32* null, i32 1
  %t251 = ptrtoint i32* %t250 to i64
  %t252 = load i8*, i8** %t2
  %t253 = icmp eq i8* %t252, null
  br i1 %t253, label %list_cow_alloc_67, label %list_cow_check_68
list_cow_alloc_67:
  %t254 = bitcast void (i8*)* @list_release_i32 to i8*
  %t255 = call i8* @star_rc_alloc(i64 24, i8* %t254)
  %t256 = bitcast i8* %t255 to { i32*, i64, i64 }*
  %t257 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t256, i32 0, i32 0
  store i32* null, i32** %t257
  %t258 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t256, i32 0, i32 1
  store i64 0, i64* %t258
  %t259 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t256, i32 0, i32 2
  store i64 0, i64* %t259
  store i8* %t255, i8** %t2
  br label %list_cow_done_69
list_cow_check_68:
  %t260 = getelementptr inbounds i8, i8* %t252, i64 -16
  %t261 = bitcast i8* %t260 to i64*
  %t262 = load atomic i64, i64* %t261 seq_cst, align 8
  %t263 = icmp eq i64 %t262, 1
  br i1 %t263, label %list_cow_done_69, label %list_cow_clone_70
list_cow_clone_70:
  %t264 = bitcast i8* %t252 to { i32*, i64, i64 }*
  %t265 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t264, i32 0, i32 0
  %t266 = load i32*, i32** %t265
  %t267 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t264, i32 0, i32 1
  %t268 = load i64, i64* %t267
  %t269 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t264, i32 0, i32 2
  %t270 = load i64, i64* %t269
  %t271 = bitcast void (i8*)* @list_release_i32 to i8*
  %t272 = call i8* @star_rc_alloc(i64 24, i8* %t271)
  %t273 = bitcast i8* %t272 to { i32*, i64, i64 }*
  %t274 = mul i64 %t270, %t251
  %t275 = call i8* @malloc(i64 %t274)
  %t276 = bitcast i8* %t275 to i32*
  %t277 = icmp sgt i64 %t268, 0
  br i1 %t277, label %list_cow_copy_71, label %list_cow_after_copy_72
list_cow_copy_71:
  %t278 = mul i64 %t268, %t251
  %t279 = bitcast i32* %t266 to i8*
  call i8* @memcpy(i8* %t275, i8* %t279, i64 %t278)
  br label %list_cow_after_copy_72
list_cow_after_copy_72:
  %t280 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t273, i32 0, i32 0
  store i32* %t276, i32** %t280
  %t281 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t273, i32 0, i32 1
  store i64 %t268, i64* %t281
  %t282 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t273, i32 0, i32 2
  store i64 %t270, i64* %t282
  call void @star_rc_release(i8* %t252)
  store i8* %t272, i8** %t2
  br label %list_cow_done_69
list_cow_done_69:
  %t283 = load i8*, i8** %t2
  %t284 = bitcast i8* %t283 to { i32*, i64, i64 }*
  %t285 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t284, i32 0, i32 0
  %t286 = load i32*, i32** %t285
  %t287 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t284, i32 0, i32 1
  %t288 = load i64, i64* %t287
  %t289 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t284, i32 0, i32 2
  %t290 = icmp eq i64 %t288, 0
  br i1 %t290, label %list_pop_empty_73, label %list_pop_nonempty_74
list_pop_nonempty_74:
  %t291 = sub i64 %t288, 1
  store i64 %t291, i64* %t287
  %t292 = load i32*, i32** %t285
  %t293 = getelementptr inbounds i32, i32* %t292, i64 %t291
  %t294 = load i32, i32* %t293
  br label %list_pop_end_75
list_pop_empty_73:
  br label %list_pop_end_75
list_pop_end_75:
  %t295 = phi i32 [ %t294, %list_pop_nonempty_74 ], [ 0, %list_pop_empty_73 ]
  store i32 %t295, i32* %t249
  %t296 = load i32, i32* %t249
  %t297 = getelementptr inbounds [13 x i8], [13 x i8]* @.str.4, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t297, i32 %t296)
  %t298 = load i8*, i8** %t2
  %t299 = icmp eq i8* %t298, null
  br i1 %t299, label %list_read_null_76, label %list_read_real_77
list_read_null_76:
  br label %list_read_end_78
list_read_real_77:
  %t300 = bitcast i8* %t298 to { i32*, i64, i64 }*
  %t301 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t300, i32 0, i32 0
  %t302 = load i32*, i32** %t301
  %t303 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t300, i32 0, i32 1
  %t304 = load i64, i64* %t303
  br label %list_read_end_78
list_read_end_78:
  %t305 = phi i32* [ null, %list_read_null_76 ], [ %t302, %list_read_real_77 ]
  %t306 = phi i64 [ 0, %list_read_null_76 ], [ %t304, %list_read_real_77 ]
  %t307 = trunc i64 %t306 to i32
  %t308 = getelementptr inbounds [20 x i8], [20 x i8]* @.str.5, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t308, i32 %t307)
  %t309 = load i8*, i8** %t2
  %t310 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t310)
  %t311 = call i32 @sum_list(i8* %t309)
  %t312 = getelementptr inbounds [23 x i8], [23 x i8]* @.str.6, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t312, i32 %t311)
  store i8* null, i8** %t313
  %t314 = load i8*, i8** %t313
  %t315 = icmp eq i8* %t314, null
  br i1 %t315, label %list_read_null_79, label %list_read_real_80
list_read_null_79:
  br label %list_read_end_81
list_read_real_80:
  %t316 = bitcast i8* %t314 to { i32*, i64, i64 }*
  %t317 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t316, i32 0, i32 0
  %t318 = load i32*, i32** %t317
  %t319 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t316, i32 0, i32 1
  %t320 = load i64, i64* %t319
  br label %list_read_end_81
list_read_end_81:
  %t321 = phi i32* [ null, %list_read_null_79 ], [ %t318, %list_read_real_80 ]
  %t322 = phi i64 [ 0, %list_read_null_79 ], [ %t320, %list_read_real_80 ]
  %t323 = trunc i64 %t322 to i32
  %t324 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t324, i32 %t323)
  %t326 = getelementptr i32, i32* null, i32 1
  %t327 = ptrtoint i32* %t326 to i64
  %t328 = load i8*, i8** %t313
  %t329 = icmp eq i8* %t328, null
  br i1 %t329, label %list_cow_alloc_82, label %list_cow_check_83
list_cow_alloc_82:
  %t330 = bitcast void (i8*)* @list_release_i32 to i8*
  %t331 = call i8* @star_rc_alloc(i64 24, i8* %t330)
  %t332 = bitcast i8* %t331 to { i32*, i64, i64 }*
  %t333 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t332, i32 0, i32 0
  store i32* null, i32** %t333
  %t334 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t332, i32 0, i32 1
  store i64 0, i64* %t334
  %t335 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t332, i32 0, i32 2
  store i64 0, i64* %t335
  store i8* %t331, i8** %t313
  br label %list_cow_done_84
list_cow_check_83:
  %t336 = getelementptr inbounds i8, i8* %t328, i64 -16
  %t337 = bitcast i8* %t336 to i64*
  %t338 = load atomic i64, i64* %t337 seq_cst, align 8
  %t339 = icmp eq i64 %t338, 1
  br i1 %t339, label %list_cow_done_84, label %list_cow_clone_85
list_cow_clone_85:
  %t340 = bitcast i8* %t328 to { i32*, i64, i64 }*
  %t341 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t340, i32 0, i32 0
  %t342 = load i32*, i32** %t341
  %t343 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t340, i32 0, i32 1
  %t344 = load i64, i64* %t343
  %t345 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t340, i32 0, i32 2
  %t346 = load i64, i64* %t345
  %t347 = bitcast void (i8*)* @list_release_i32 to i8*
  %t348 = call i8* @star_rc_alloc(i64 24, i8* %t347)
  %t349 = bitcast i8* %t348 to { i32*, i64, i64 }*
  %t350 = mul i64 %t346, %t327
  %t351 = call i8* @malloc(i64 %t350)
  %t352 = bitcast i8* %t351 to i32*
  %t353 = icmp sgt i64 %t344, 0
  br i1 %t353, label %list_cow_copy_86, label %list_cow_after_copy_87
list_cow_copy_86:
  %t354 = mul i64 %t344, %t327
  %t355 = bitcast i32* %t342 to i8*
  call i8* @memcpy(i8* %t351, i8* %t355, i64 %t354)
  br label %list_cow_after_copy_87
list_cow_after_copy_87:
  %t356 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t349, i32 0, i32 0
  store i32* %t352, i32** %t356
  %t357 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t349, i32 0, i32 1
  store i64 %t344, i64* %t357
  %t358 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t349, i32 0, i32 2
  store i64 %t346, i64* %t358
  call void @star_rc_release(i8* %t328)
  store i8* %t348, i8** %t313
  br label %list_cow_done_84
list_cow_done_84:
  %t359 = load i8*, i8** %t313
  %t360 = bitcast i8* %t359 to { i32*, i64, i64 }*
  %t361 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t360, i32 0, i32 0
  %t362 = load i32*, i32** %t361
  %t363 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t360, i32 0, i32 1
  %t364 = load i64, i64* %t363
  %t365 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t360, i32 0, i32 2
  %t366 = icmp eq i64 %t364, 0
  br i1 %t366, label %list_pop_empty_88, label %list_pop_nonempty_89
list_pop_nonempty_89:
  %t367 = sub i64 %t364, 1
  store i64 %t367, i64* %t363
  %t368 = load i32*, i32** %t361
  %t369 = getelementptr inbounds i32, i32* %t368, i64 %t367
  %t370 = load i32, i32* %t369
  br label %list_pop_end_90
list_pop_empty_88:
  br label %list_pop_end_90
list_pop_end_90:
  %t371 = phi i32 [ %t370, %list_pop_nonempty_89 ], [ 0, %list_pop_empty_88 ]
  store i32 %t371, i32* %t325
  %t372 = load i32, i32* %t325
  %t373 = getelementptr inbounds [21 x i8], [21 x i8]* @.str.8, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t373, i32 %t372)
  %t375 = load i8*, i8** %t313
  %t376 = icmp eq i8* %t375, null
  br i1 %t376, label %list_read_null_91, label %list_read_real_92
list_read_null_91:
  br label %list_read_end_93
list_read_real_92:
  %t377 = bitcast i8* %t375 to { i32*, i64, i64 }*
  %t378 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t377, i32 0, i32 0
  %t379 = load i32*, i32** %t378
  %t380 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t377, i32 0, i32 1
  %t381 = load i64, i64* %t380
  br label %list_read_end_93
list_read_end_93:
  %t382 = phi i32* [ null, %list_read_null_91 ], [ %t379, %list_read_real_92 ]
  %t383 = phi i64 [ 0, %list_read_null_91 ], [ %t381, %list_read_real_92 ]
  %t384 = sext i32 0 to i64
  %t385 = icmp ult i64 %t384, %t383
  br i1 %t385, label %list_idx_ok_94, label %list_idx_oob_95
list_idx_ok_94:
  %t386 = getelementptr inbounds i32, i32* %t382, i64 %t384
  %t387 = load i32, i32* %t386
  br label %list_idx_end_96
list_idx_oob_95:
  br label %list_idx_end_96
list_idx_end_96:
  %t388 = phi i32 [ %t387, %list_idx_ok_94 ], [ 0, %list_idx_oob_95 ]
  store i32 %t388, i32* %t374
  %t389 = load i32, i32* %t374
  %t390 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.9, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t390, i32 %t389)
  store i8* null, i8** %t391
  store i32 0, i32* %t392
  br label %while_cond_97
while_cond_97:
  %t393 = load i32, i32* %t392
  %t394 = icmp slt i32 %t393, 20
  br i1 %t394, label %while_body_98, label %while_else_99
while_body_98:
  %t395 = getelementptr i32, i32* null, i32 1
  %t396 = ptrtoint i32* %t395 to i64
  %t397 = load i8*, i8** %t391
  %t398 = icmp eq i8* %t397, null
  br i1 %t398, label %list_cow_alloc_101, label %list_cow_check_102
list_cow_alloc_101:
  %t399 = bitcast void (i8*)* @list_release_i32 to i8*
  %t400 = call i8* @star_rc_alloc(i64 24, i8* %t399)
  %t401 = bitcast i8* %t400 to { i32*, i64, i64 }*
  %t402 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t401, i32 0, i32 0
  store i32* null, i32** %t402
  %t403 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t401, i32 0, i32 1
  store i64 0, i64* %t403
  %t404 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t401, i32 0, i32 2
  store i64 0, i64* %t404
  store i8* %t400, i8** %t391
  br label %list_cow_done_103
list_cow_check_102:
  %t405 = getelementptr inbounds i8, i8* %t397, i64 -16
  %t406 = bitcast i8* %t405 to i64*
  %t407 = load atomic i64, i64* %t406 seq_cst, align 8
  %t408 = icmp eq i64 %t407, 1
  br i1 %t408, label %list_cow_done_103, label %list_cow_clone_104
list_cow_clone_104:
  %t409 = bitcast i8* %t397 to { i32*, i64, i64 }*
  %t410 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t409, i32 0, i32 0
  %t411 = load i32*, i32** %t410
  %t412 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t409, i32 0, i32 1
  %t413 = load i64, i64* %t412
  %t414 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t409, i32 0, i32 2
  %t415 = load i64, i64* %t414
  %t416 = bitcast void (i8*)* @list_release_i32 to i8*
  %t417 = call i8* @star_rc_alloc(i64 24, i8* %t416)
  %t418 = bitcast i8* %t417 to { i32*, i64, i64 }*
  %t419 = mul i64 %t415, %t396
  %t420 = call i8* @malloc(i64 %t419)
  %t421 = bitcast i8* %t420 to i32*
  %t422 = icmp sgt i64 %t413, 0
  br i1 %t422, label %list_cow_copy_105, label %list_cow_after_copy_106
list_cow_copy_105:
  %t423 = mul i64 %t413, %t396
  %t424 = bitcast i32* %t411 to i8*
  call i8* @memcpy(i8* %t420, i8* %t424, i64 %t423)
  br label %list_cow_after_copy_106
list_cow_after_copy_106:
  %t425 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t418, i32 0, i32 0
  store i32* %t421, i32** %t425
  %t426 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t418, i32 0, i32 1
  store i64 %t413, i64* %t426
  %t427 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t418, i32 0, i32 2
  store i64 %t415, i64* %t427
  call void @star_rc_release(i8* %t397)
  store i8* %t417, i8** %t391
  br label %list_cow_done_103
list_cow_done_103:
  %t428 = load i8*, i8** %t391
  %t429 = bitcast i8* %t428 to { i32*, i64, i64 }*
  %t430 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t429, i32 0, i32 0
  %t431 = load i32*, i32** %t430
  %t432 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t429, i32 0, i32 1
  %t433 = load i64, i64* %t432
  %t434 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t429, i32 0, i32 2
  %t435 = load i32, i32* %t392
  %t436 = load i64, i64* %t434
  %t437 = load i32*, i32** %t430
  %t438 = load i64, i64* %t432
  %t439 = icmp sge i64 %t438, %t436
  br i1 %t439, label %list_push_grow_107, label %list_push_store_108
list_push_grow_107:
  %t440 = mul i64 %t436, 2
  %t441 = icmp sgt i64 %t440, 0
  %t442 = select i1 %t441, i64 %t440, i64 1
  %t443 = getelementptr i32, i32* null, i32 1
  %t444 = ptrtoint i32* %t443 to i64
  %t445 = mul i64 %t442, %t444
  %t446 = call i8* @malloc(i64 %t445)
  %t447 = bitcast i8* %t446 to i32*
  %t448 = icmp sgt i64 %t436, 0
  br i1 %t448, label %list_push_copy_109, label %list_push_after_copy_110
list_push_copy_109:
  %t449 = mul i64 %t438, %t444
  %t450 = bitcast i32* %t437 to i8*
  call i8* @memcpy(i8* %t446, i8* %t450, i64 %t449)
  call void @free(i8* %t450)
  br label %list_push_after_copy_110
list_push_after_copy_110:
  store i32* %t447, i32** %t430
  store i64 %t442, i64* %t434
  br label %list_push_store_108
list_push_store_108:
  %t451 = load i32*, i32** %t430
  %t452 = getelementptr inbounds i32, i32* %t451, i64 %t438
  store i32 %t435, i32* %t452
  %t453 = add i64 %t438, 1
  store i64 %t453, i64* %t432
  %t454 = load i32, i32* %t392
  %t455 = add i32 %t454, 1
  store i32 %t455, i32* %t392
  br label %while_cond_97
while_else_99:
  br label %while_end_100
while_end_100:
  %t456 = load i8*, i8** %t391
  %t457 = icmp eq i8* %t456, null
  br i1 %t457, label %list_read_null_111, label %list_read_real_112
list_read_null_111:
  br label %list_read_end_113
list_read_real_112:
  %t458 = bitcast i8* %t456 to { i32*, i64, i64 }*
  %t459 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t458, i32 0, i32 0
  %t460 = load i32*, i32** %t459
  %t461 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t458, i32 0, i32 1
  %t462 = load i64, i64* %t461
  br label %list_read_end_113
list_read_end_113:
  %t463 = phi i32* [ null, %list_read_null_111 ], [ %t460, %list_read_real_112 ]
  %t464 = phi i64 [ 0, %list_read_null_111 ], [ %t462, %list_read_real_112 ]
  %t465 = trunc i64 %t464 to i32
  %t466 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.10, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t466, i32 %t465)
  %t467 = load i8*, i8** %t391
  %t468 = icmp eq i8* %t467, null
  br i1 %t468, label %list_read_null_114, label %list_read_real_115
list_read_null_114:
  br label %list_read_end_116
list_read_real_115:
  %t469 = bitcast i8* %t467 to { i32*, i64, i64 }*
  %t470 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t469, i32 0, i32 0
  %t471 = load i32*, i32** %t470
  %t472 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t469, i32 0, i32 1
  %t473 = load i64, i64* %t472
  br label %list_read_end_116
list_read_end_116:
  %t474 = phi i32* [ null, %list_read_null_114 ], [ %t471, %list_read_real_115 ]
  %t475 = phi i64 [ 0, %list_read_null_114 ], [ %t473, %list_read_real_115 ]
  %t476 = sext i32 19 to i64
  %t477 = icmp ult i64 %t476, %t475
  br i1 %t477, label %list_idx_ok_117, label %list_idx_oob_118
list_idx_ok_117:
  %t478 = getelementptr inbounds i32, i32* %t474, i64 %t476
  %t479 = load i32, i32* %t478
  br label %list_idx_end_119
list_idx_oob_118:
  br label %list_idx_end_119
list_idx_end_119:
  %t480 = phi i32 [ %t479, %list_idx_ok_117 ], [ 0, %list_idx_oob_118 ]
  %t481 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.11, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t481, i32 %t480)
  %t482 = load i8*, i8** %t391
  %t483 = icmp eq i8* %t482, null
  br i1 %t483, label %list_read_null_120, label %list_read_real_121
list_read_null_120:
  br label %list_read_end_122
list_read_real_121:
  %t484 = bitcast i8* %t482 to { i32*, i64, i64 }*
  %t485 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 0
  %t486 = load i32*, i32** %t485
  %t487 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t484, i32 0, i32 1
  %t488 = load i64, i64* %t487
  br label %list_read_end_122
list_read_end_122:
  %t489 = phi i32* [ null, %list_read_null_120 ], [ %t486, %list_read_real_121 ]
  %t490 = phi i64 [ 0, %list_read_null_120 ], [ %t488, %list_read_real_121 ]
  %t491 = sext i32 0 to i64
  %t492 = icmp ult i64 %t491, %t490
  br i1 %t492, label %list_idx_ok_123, label %list_idx_oob_124
list_idx_ok_123:
  %t493 = getelementptr inbounds i32, i32* %t489, i64 %t491
  %t494 = load i32, i32* %t493
  br label %list_idx_end_125
list_idx_oob_124:
  br label %list_idx_end_125
list_idx_end_125:
  %t495 = phi i32 [ %t494, %list_idx_ok_123 ], [ 0, %list_idx_oob_124 ]
  %t496 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.12, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t496, i32 %t495)
  %t498 = getelementptr i8*, i8** null, i32 1
  %t499 = ptrtoint i8** %t498 to i64
  %t500 = mul i64 %t499, 3
  %t501 = call i8* @malloc(i64 %t500)
  %t502 = bitcast i8* %t501 to i8**
  %t503 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.13, i64 0, i32 2, i64 0
  %t504 = getelementptr inbounds i8*, i8** %t502, i64 0
  store i8* %t503, i8** %t504
  %t505 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.14, i64 0, i32 2, i64 0
  %t506 = getelementptr inbounds i8*, i8** %t502, i64 1
  store i8* %t505, i8** %t506
  %t507 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t508 = getelementptr inbounds i8*, i8** %t502, i64 2
  store i8* %t507, i8** %t508
  %t521 = bitcast void (i8*)* @list_release_str to i8*
  %t522 = call i8* @star_rc_alloc(i64 24, i8* %t521)
  %t523 = bitcast i8* %t522 to { i8**, i64, i64 }*
  %t524 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t523, i32 0, i32 0
  store i8** %t502, i8*** %t524
  %t525 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t523, i32 0, i32 1
  store i64 3, i64* %t525
  %t526 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t523, i32 0, i32 2
  store i64 3, i64* %t526
  store i8* %t522, i8** %t497
  %t527 = load i8*, i8** %t497
  %t528 = icmp eq i8* %t527, null
  br i1 %t528, label %list_read_null_129, label %list_read_real_130
list_read_null_129:
  br label %list_read_end_131
list_read_real_130:
  %t529 = bitcast i8* %t527 to { i8**, i64, i64 }*
  %t530 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t529, i32 0, i32 0
  %t531 = load i8**, i8*** %t530
  %t532 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t529, i32 0, i32 1
  %t533 = load i64, i64* %t532
  br label %list_read_end_131
list_read_end_131:
  %t534 = phi i8** [ null, %list_read_null_129 ], [ %t531, %list_read_real_130 ]
  %t535 = phi i64 [ 0, %list_read_null_129 ], [ %t533, %list_read_real_130 ]
  %t536 = trunc i64 %t535 to i32
  %t537 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.16, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t537, i32 %t536)
  %t538 = load i8*, i8** %t497
  %t539 = icmp eq i8* %t538, null
  br i1 %t539, label %list_read_null_132, label %list_read_real_133
list_read_null_132:
  br label %list_read_end_134
list_read_real_133:
  %t540 = bitcast i8* %t538 to { i8**, i64, i64 }*
  %t541 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t540, i32 0, i32 0
  %t542 = load i8**, i8*** %t541
  %t543 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t540, i32 0, i32 1
  %t544 = load i64, i64* %t543
  br label %list_read_end_134
list_read_end_134:
  %t545 = phi i8** [ null, %list_read_null_132 ], [ %t542, %list_read_real_133 ]
  %t546 = phi i64 [ 0, %list_read_null_132 ], [ %t544, %list_read_real_133 ]
  %t547 = sext i32 1 to i64
  %t548 = icmp ult i64 %t547, %t546
  br i1 %t548, label %list_idx_ok_135, label %list_idx_oob_136
list_idx_ok_135:
  %t549 = getelementptr inbounds i8*, i8** %t545, i64 %t547
  %t550 = load i8*, i8** %t549
  %t551 = load i8*, i8** %t549
  call void @star_rc_retain(i8* %t551)
  br label %list_idx_end_137
list_idx_oob_136:
  %t552 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t552
  br label %list_idx_end_137
list_idx_end_137:
  %t553 = phi i8* [ %t550, %list_idx_ok_135 ], [ %t552, %list_idx_oob_136 ]
  call void @star_rc_release(i8* %t553)
  %t554 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t554, i8* %t553)
  %t556 = getelementptr %Point, %Point* null, i32 1
  %t557 = ptrtoint %Point* %t556 to i64
  %t558 = mul i64 %t557, 2
  %t559 = call i8* @malloc(i64 %t558)
  %t560 = bitcast i8* %t559 to %Point*
  %t562 = getelementptr inbounds %Point, %Point* %t561, i32 0, i32 0
  store i32 1, i32* %t562
  %t563 = getelementptr inbounds %Point, %Point* %t561, i32 0, i32 1
  store i32 2, i32* %t563
  %t564 = load %Point, %Point* %t561
  %t565 = getelementptr inbounds %Point, %Point* %t560, i64 0
  store %Point %t564, %Point* %t565
  %t567 = getelementptr inbounds %Point, %Point* %t566, i32 0, i32 0
  store i32 3, i32* %t567
  %t568 = getelementptr inbounds %Point, %Point* %t566, i32 0, i32 1
  store i32 4, i32* %t568
  %t569 = load %Point, %Point* %t566
  %t570 = getelementptr inbounds %Point, %Point* %t560, i64 1
  store %Point %t569, %Point* %t570
  %t575 = bitcast void (i8*)* @list_release_s_Point to i8*
  %t576 = call i8* @star_rc_alloc(i64 24, i8* %t575)
  %t577 = bitcast i8* %t576 to { %Point*, i64, i64 }*
  %t578 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t577, i32 0, i32 0
  store %Point* %t560, %Point** %t578
  %t579 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t577, i32 0, i32 1
  store i64 2, i64* %t579
  %t580 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t577, i32 0, i32 2
  store i64 2, i64* %t580
  store i8* %t576, i8** %t555
  %t582 = load i8*, i8** %t555
  %t583 = icmp eq i8* %t582, null
  br i1 %t583, label %list_read_null_138, label %list_read_real_139
list_read_null_138:
  br label %list_read_end_140
list_read_real_139:
  %t584 = bitcast i8* %t582 to { %Point*, i64, i64 }*
  %t585 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t584, i32 0, i32 0
  %t586 = load %Point*, %Point** %t585
  %t587 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t584, i32 0, i32 1
  %t588 = load i64, i64* %t587
  br label %list_read_end_140
list_read_end_140:
  %t589 = phi %Point* [ null, %list_read_null_138 ], [ %t586, %list_read_real_139 ]
  %t590 = phi i64 [ 0, %list_read_null_138 ], [ %t588, %list_read_real_139 ]
  %t591 = sext i32 1 to i64
  %t592 = icmp ult i64 %t591, %t590
  br i1 %t592, label %list_idx_ok_141, label %list_idx_oob_142
list_idx_ok_141:
  %t593 = getelementptr inbounds %Point, %Point* %t589, i64 %t591
  %t594 = load %Point, %Point* %t593
  br label %list_idx_end_143
list_idx_oob_142:
  br label %list_idx_end_143
list_idx_end_143:
  %t595 = phi %Point [ %t594, %list_idx_ok_141 ], [ zeroinitializer, %list_idx_oob_142 ]
  store %Point %t595, %Point* %t581
  %t596 = getelementptr inbounds %Point, %Point* %t581, i32 0, i32 0
  %t597 = load i32, i32* %t596
  %t598 = getelementptr inbounds %Point, %Point* %t581, i32 0, i32 1
  %t599 = load i32, i32* %t598
  %t600 = getelementptr inbounds [22 x i8], [22 x i8]* @.str.18, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t600, i32 %t597, i32 %t599)
  %t601 = load i8*, i8** %t555
  call void @star_rc_release(i8* %t601)
  %t602 = load i8*, i8** %t497
  call void @star_rc_release(i8* %t602)
  %t603 = load i8*, i8** %t391
  call void @star_rc_release(i8* %t603)
  %t604 = load i8*, i8** %t313
  call void @star_rc_release(i8* %t604)
  %t605 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t605)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_i32(i8* %objp) {
entry:
  %t11 = bitcast i8* %objp to { i32*, i64, i64 }*
  %t12 = getelementptr inbounds { i32*, i64, i64 }, { i32*, i64, i64 }* %t11, i32 0, i32 0
  %t13 = load i32*, i32** %t12
  %t14 = bitcast i32* %t13 to i8*
  call void @free(i8* %t14)
  ret void
}


define void @list_release_str(i8* %objp) {
entry:
  %t514 = alloca i64
  %t509 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t510 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t509, i32 0, i32 0
  %t511 = load i8**, i8*** %t510
  %t512 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t509, i32 0, i32 1
  %t513 = load i64, i64* %t512
  store i64 0, i64* %t514
  br label %list_release_cond_126
list_release_cond_126:
  %t515 = load i64, i64* %t514
  %t516 = icmp slt i64 %t515, %t513
  br i1 %t516, label %list_release_body_127, label %list_release_end_128
list_release_body_127:
  %t517 = getelementptr inbounds i8*, i8** %t511, i64 %t515
  %t518 = load i8*, i8** %t517
  call void @star_rc_release(i8* %t518)
  %t519 = add i64 %t515, 1
  store i64 %t519, i64* %t514
  br label %list_release_cond_126
list_release_end_128:
  %t520 = bitcast i8** %t511 to i8*
  call void @free(i8* %t520)
  ret void
}


define void @list_release_s_Point(i8* %objp) {
entry:
  %t571 = bitcast i8* %objp to { %Point*, i64, i64 }*
  %t572 = getelementptr inbounds { %Point*, i64, i64 }, { %Point*, i64, i64 }* %t571, i32 0, i32 0
  %t573 = load %Point*, %Point** %t572
  %t574 = bitcast %Point* %t573 to i8*
  call void @free(i8* %t574)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant [18 x i8] c"initial len = %d\0A\00"
@.str.1 = private unnamed_addr constant [21 x i8] c"after push len = %d\0A\00"
@.str.2 = private unnamed_addr constant [15 x i8] c"nums[%d] = %d\0A\00"
@.str.3 = private unnamed_addr constant [24 x i8] c"nums[0] after set = %d\0A\00"
@.str.4 = private unnamed_addr constant [13 x i8] c"popped = %d\0A\00"
@.str.5 = private unnamed_addr constant [20 x i8] c"len after pop = %d\0A\00"
@.str.6 = private unnamed_addr constant [23 x i8] c"sum via function = %d\0A\00"
@.str.7 = private unnamed_addr constant [16 x i8] c"empty len = %d\0A\00"
@.str.8 = private unnamed_addr constant [21 x i8] c"pop from empty = %d\0A\00"
@.str.9 = private unnamed_addr constant [16 x i8] c"index oob = %d\0A\00"
@.str.10 = private unnamed_addr constant [16 x i8] c"grown len = %d\0A\00"
@.str.11 = private unnamed_addr constant [16 x i8] c"grown[19] = %d\0A\00"
@.str.12 = private unnamed_addr constant [15 x i8] c"grown[0] = %d\0A\00"
@.str.13 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"alpha\00" }
@.str.14 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"beta\00" }
@.str.15 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"gamma\00" }
@.str.16 = private unnamed_addr constant [16 x i8] c"words len = %d\0A\00"
@.str.17 = private unnamed_addr constant [15 x i8] c"words[1] = %s\0A\00"
@.str.18 = private unnamed_addr constant [22 x i8] c"points[1] = (%d, %d)\0A\00"
