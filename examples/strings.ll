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
  %t4 = alloca i1
  %t14 = alloca i1
  %t33 = alloca i1
  %t45 = alloca i1
  %t71 = alloca i32
  %t86 = alloca i32
  %t104 = alloca i8*
  %t106 = alloca i8*
  %t113 = alloca i64
  %t131 = alloca i64
  %t175 = alloca i64
  %t176 = alloca i8*
  %t191 = alloca i8*
  %t192 = alloca i8*
  %t225 = alloca i64
  %t226 = alloca i8*
  %t241 = alloca i8*
  %t242 = alloca i8*
  %t257 = alloca i8*
  %t259 = alloca i8*
  %t269 = alloca i8**
  %t270 = alloca i64
  %t271 = alloca i64
  %t293 = alloca i8*
  %t362 = alloca i32
  %t375 = alloca i32
  %t388 = alloca i8*
  %t427 = alloca i64
  %t428 = alloca i64
  %t448 = alloca i8*
  %t449 = alloca i64
  %t466 = alloca i8*
  %t468 = alloca i8*
  %t478 = alloca i8**
  %t479 = alloca i64
  %t480 = alloca i64
  %t502 = alloca i8*
  %t573 = alloca i64
  %t574 = alloca i64
  %t594 = alloca i8*
  %t595 = alloca i64
  store i32 %.argc, i32* @star.argc
  store i8** %.argv, i8*** @star.argv
  %t0 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t0, i8** @sym.lock
  %t1 = call i8* @CreateSemaphoreA(i8* null, i32 1, i32 1, i8* null)
  store i8* %t1, i8** @rng.lock
  %t3 = getelementptr inbounds { i64, i8*, [20 x i8] }, { i64, i8*, [20 x i8] }* @.str.0, i64 0, i32 2, i64 0
  store i8* %t3, i8** %t2
  %t5 = load i8*, i8** %t2
  %t6 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t6)
  %t7 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.1, i64 0, i32 2, i64 0
  %t8 = icmp eq i8* %t5, null
  %t9 = select i1 %t8, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t5
  %t10 = icmp eq i8* %t7, null
  %t11 = select i1 %t10, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t7
  %t12 = call i8* @strstr(i8* %t9, i8* %t11)
  %t13 = icmp ne i8* %t12, null
  call void @star_rc_release(i8* %t5)
  call void @star_rc_release(i8* %t7)
  store i1 %t13, i1* %t4
  %t15 = load i8*, i8** %t2
  %t16 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t16)
  %t17 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.2, i64 0, i32 2, i64 0
  %t18 = icmp eq i8* %t15, null
  %t19 = select i1 %t18, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t15
  %t20 = icmp eq i8* %t17, null
  %t21 = select i1 %t20, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t17
  %t22 = call i8* @strstr(i8* %t19, i8* %t21)
  %t23 = icmp ne i8* %t22, null
  call void @star_rc_release(i8* %t15)
  call void @star_rc_release(i8* %t17)
  store i1 %t23, i1* %t14
  %t24 = load i1, i1* %t4
  %t25 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.3, i64 0, i64 0
  %t26 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.4, i64 0, i64 0
  %t27 = select i1 %t24, i8* %t25, i8* %t26
  %t28 = load i1, i1* %t14
  %t29 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.5, i64 0, i64 0
  %t30 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.6, i64 0, i64 0
  %t31 = select i1 %t28, i8* %t29, i8* %t30
  %t32 = getelementptr inbounds [43 x i8], [43 x i8]* @.str.7, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t32, i8* %t27, i8* %t31)
  %t34 = load i8*, i8** %t2
  %t35 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t35)
  %t36 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.8, i64 0, i32 2, i64 0
  %t37 = icmp eq i8* %t34, null
  %t38 = select i1 %t37, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t34
  %t39 = icmp eq i8* %t36, null
  %t40 = select i1 %t39, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t36
  %t41 = call i32 @strlen(i8* %t40)
  %t42 = sext i32 %t41 to i64
  %t43 = call i32 @strncmp(i8* %t38, i8* %t40, i64 %t42)
  %t44 = icmp eq i32 %t43, 0
  call void @star_rc_release(i8* %t34)
  call void @star_rc_release(i8* %t36)
  store i1 %t44, i1* %t33
  %t46 = load i8*, i8** %t2
  %t47 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t47)
  %t48 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.9, i64 0, i32 2, i64 0
  %t49 = icmp eq i8* %t46, null
  %t50 = select i1 %t49, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t46
  %t51 = icmp eq i8* %t48, null
  %t52 = select i1 %t51, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t48
  %t53 = call i32 @strlen(i8* %t50)
  %t54 = call i32 @strlen(i8* %t52)
  %t55 = icmp ugt i32 %t54, %t53
  br i1 %t55, label %ends_with_false_1, label %ends_with_cmp_0
ends_with_cmp_0:
  %t56 = sub i32 %t53, %t54
  %t57 = sext i32 %t56 to i64
  %t58 = getelementptr inbounds i8, i8* %t50, i64 %t57
  %t59 = call i32 @strcmp(i8* %t58, i8* %t52)
  %t60 = icmp eq i32 %t59, 0
  br label %ends_with_end_2
ends_with_false_1:
  br label %ends_with_end_2
ends_with_end_2:
  %t61 = phi i1 [ %t60, %ends_with_cmp_0 ], [ false, %ends_with_false_1 ]
  call void @star_rc_release(i8* %t46)
  call void @star_rc_release(i8* %t48)
  store i1 %t61, i1* %t45
  %t62 = load i1, i1* %t33
  %t63 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.10, i64 0, i64 0
  %t64 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.11, i64 0, i64 0
  %t65 = select i1 %t62, i8* %t63, i8* %t64
  %t66 = load i1, i1* %t45
  %t67 = getelementptr inbounds [5 x i8], [5 x i8]* @.str.12, i64 0, i64 0
  %t68 = getelementptr inbounds [6 x i8], [6 x i8]* @.str.13, i64 0, i64 0
  %t69 = select i1 %t66, i8* %t67, i8* %t68
  %t70 = getelementptr inbounds [44 x i8], [44 x i8]* @.str.14, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t70, i8* %t65, i8* %t69)
  %t72 = load i8*, i8** %t2
  %t73 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t73)
  %t74 = getelementptr inbounds { i64, i8*, [6 x i8] }, { i64, i8*, [6 x i8] }* @.str.15, i64 0, i32 2, i64 0
  %t75 = icmp eq i8* %t72, null
  %t76 = select i1 %t75, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t72
  %t77 = icmp eq i8* %t74, null
  %t78 = select i1 %t77, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t74
  %t79 = call i8* @strstr(i8* %t76, i8* %t78)
  %t80 = icmp eq i8* %t79, null
  br i1 %t80, label %index_of_notfound_4, label %index_of_found_3
index_of_found_3:
  %t81 = ptrtoint i8* %t79 to i64
  %t82 = ptrtoint i8* %t76 to i64
  %t83 = sub i64 %t81, %t82
  %t84 = trunc i64 %t83 to i32
  br label %index_of_end_5
index_of_notfound_4:
  br label %index_of_end_5
index_of_end_5:
  %t85 = phi i32 [ %t84, %index_of_found_3 ], [ -1, %index_of_notfound_4 ]
  call void @star_rc_release(i8* %t72)
  call void @star_rc_release(i8* %t74)
  store i32 %t85, i32* %t71
  %t87 = load i8*, i8** %t2
  %t88 = load i8*, i8** %t2
  call void @star_rc_retain(i8* %t88)
  %t89 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.16, i64 0, i32 2, i64 0
  %t90 = icmp eq i8* %t87, null
  %t91 = select i1 %t90, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t87
  %t92 = icmp eq i8* %t89, null
  %t93 = select i1 %t92, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t89
  %t94 = call i8* @strstr(i8* %t91, i8* %t93)
  %t95 = icmp eq i8* %t94, null
  br i1 %t95, label %index_of_notfound_7, label %index_of_found_6
index_of_found_6:
  %t96 = ptrtoint i8* %t94 to i64
  %t97 = ptrtoint i8* %t91 to i64
  %t98 = sub i64 %t96, %t97
  %t99 = trunc i64 %t98 to i32
  br label %index_of_end_8
index_of_notfound_7:
  br label %index_of_end_8
index_of_end_8:
  %t100 = phi i32 [ %t99, %index_of_found_6 ], [ -1, %index_of_notfound_7 ]
  call void @star_rc_release(i8* %t87)
  call void @star_rc_release(i8* %t89)
  store i32 %t100, i32* %t86
  %t101 = load i32, i32* %t71
  %t102 = load i32, i32* %t86
  %t103 = getelementptr inbounds [45 x i8], [45 x i8]* @.str.17, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t103, i32 %t101, i32 %t102)
  %t105 = getelementptr inbounds { i64, i8*, [27 x i8] }, { i64, i8*, [27 x i8] }* @.str.18, i64 0, i32 2, i64 0
  store i8* %t105, i8** %t104
  %t107 = load i8*, i8** %t104
  %t108 = load i8*, i8** %t104
  call void @star_rc_retain(i8* %t108)
  %t109 = icmp eq i8* %t107, null
  %t110 = select i1 %t109, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t107
  %t111 = call i32 @strlen(i8* %t110)
  %t112 = sext i32 %t111 to i64
  store i64 0, i64* %t113
  br label %trim_start_cond_9
trim_start_cond_9:
  %t114 = load i64, i64* %t113
  %t115 = icmp slt i64 %t114, %t112
  br i1 %t115, label %trim_start_body_10, label %trim_start_done_12
trim_start_body_10:
  %t116 = getelementptr inbounds i8, i8* %t110, i64 %t114
  %t117 = load i8, i8* %t116
  %t118 = icmp eq i8 %t117, 32
  %t119 = icmp eq i8 %t117, 9
  %t120 = or i1 %t118, %t119
  %t121 = icmp eq i8 %t117, 10
  %t122 = or i1 %t120, %t121
  %t123 = icmp eq i8 %t117, 13
  %t124 = or i1 %t122, %t123
  %t125 = icmp eq i8 %t117, 11
  %t126 = or i1 %t124, %t125
  %t127 = icmp eq i8 %t117, 12
  %t128 = or i1 %t126, %t127
  br i1 %t128, label %trim_start_incr_11, label %trim_start_done_12
trim_start_incr_11:
  %t129 = add i64 %t114, 1
  store i64 %t129, i64* %t113
  br label %trim_start_cond_9
trim_start_done_12:
  %t130 = load i64, i64* %t113
  store i64 %t112, i64* %t131
  br label %trim_end_cond_13
trim_end_cond_13:
  %t132 = load i64, i64* %t131
  %t133 = icmp sgt i64 %t132, %t130
  br i1 %t133, label %trim_end_body_14, label %trim_end_done_16
trim_end_body_14:
  %t134 = sub i64 %t132, 1
  %t135 = getelementptr inbounds i8, i8* %t110, i64 %t134
  %t136 = load i8, i8* %t135
  %t137 = icmp eq i8 %t136, 32
  %t138 = icmp eq i8 %t136, 9
  %t139 = or i1 %t137, %t138
  %t140 = icmp eq i8 %t136, 10
  %t141 = or i1 %t139, %t140
  %t142 = icmp eq i8 %t136, 13
  %t143 = or i1 %t141, %t142
  %t144 = icmp eq i8 %t136, 11
  %t145 = or i1 %t143, %t144
  %t146 = icmp eq i8 %t136, 12
  %t147 = or i1 %t145, %t146
  br i1 %t147, label %trim_end_decr_15, label %trim_end_done_16
trim_end_decr_15:
  store i64 %t134, i64* %t131
  br label %trim_end_cond_13
trim_end_done_16:
  %t148 = load i64, i64* %t131
  %t149 = sub i64 %t148, %t130
  %t150 = add i64 %t149, 1
  %t151 = call i8* @star_rc_alloc(i64 %t150, i8* null)
  %t152 = getelementptr inbounds i8, i8* %t110, i64 %t130
  call i8* @memcpy(i8* %t151, i8* %t152, i64 %t149)
  %t153 = getelementptr inbounds i8, i8* %t151, i64 %t149
  store i8 0, i8* %t153
  call void @star_rc_release(i8* %t107)
  store i8* %t151, i8** %t106
  %t154 = load i8*, i8** %t106
  %t155 = load i8*, i8** %t106
  call void @star_rc_retain(i8* %t155)
  call void @star_rc_release(i8* %t154)
  %t156 = getelementptr inbounds [16 x i8], [16 x i8]* @.str.19, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t156, i8* %t154)
  %t157 = getelementptr inbounds { i64, i8*, [11 x i8] }, { i64, i8*, [11 x i8] }* @.str.20, i64 0, i32 2, i64 0
  %t158 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.21, i64 0, i32 2, i64 0
  %t159 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.22, i64 0, i32 2, i64 0
  %t160 = icmp eq i8* %t157, null
  %t161 = select i1 %t160, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t157
  %t162 = icmp eq i8* %t158, null
  %t163 = select i1 %t162, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t158
  %t164 = icmp eq i8* %t159, null
  %t165 = select i1 %t164, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t159
  %t166 = call i32 @strlen(i8* %t163)
  %t167 = sext i32 %t166 to i64
  %t168 = icmp eq i64 %t167, 0
  br i1 %t168, label %replace_empty_old_17, label %replace_real_18
replace_empty_old_17:
  %t169 = call i32 @strlen(i8* %t161)
  %t170 = sext i32 %t169 to i64
  %t171 = add i64 %t170, 1
  %t172 = call i8* @star_rc_alloc(i64 %t171, i8* null)
  call i8* @strcpy(i8* %t172, i8* %t161)
  br label %replace_done_19
replace_real_18:
  %t173 = call i32 @strlen(i8* %t165)
  %t174 = sext i32 %t173 to i64
  store i64 0, i64* %t175
  store i8* %t161, i8** %t176
  br label %replace_count_cond_20
replace_count_cond_20:
  %t177 = load i8*, i8** %t176
  %t178 = call i8* @strstr(i8* %t177, i8* %t163)
  %t179 = icmp eq i8* %t178, null
  br i1 %t179, label %replace_count_done_22, label %replace_count_body_21
replace_count_body_21:
  %t180 = load i64, i64* %t175
  %t181 = add i64 %t180, 1
  store i64 %t181, i64* %t175
  %t182 = getelementptr inbounds i8, i8* %t178, i64 %t167
  store i8* %t182, i8** %t176
  br label %replace_count_cond_20
replace_count_done_22:
  %t183 = load i64, i64* %t175
  %t184 = call i32 @strlen(i8* %t161)
  %t185 = sext i32 %t184 to i64
  %t186 = sub i64 %t174, %t167
  %t187 = mul i64 %t183, %t186
  %t188 = add i64 %t185, %t187
  %t189 = add i64 %t188, 1
  %t190 = call i8* @star_rc_alloc(i64 %t189, i8* null)
  store i8* %t161, i8** %t191
  store i8* %t190, i8** %t192
  br label %replace_build_cond_23
replace_build_cond_23:
  %t193 = load i8*, i8** %t191
  %t194 = call i8* @strstr(i8* %t193, i8* %t163)
  %t195 = icmp eq i8* %t194, null
  br i1 %t195, label %replace_build_done_25, label %replace_build_body_24
replace_build_body_24:
  %t196 = ptrtoint i8* %t194 to i64
  %t197 = ptrtoint i8* %t193 to i64
  %t198 = sub i64 %t196, %t197
  %t199 = load i8*, i8** %t192
  call i8* @memcpy(i8* %t199, i8* %t193, i64 %t198)
  %t200 = getelementptr inbounds i8, i8* %t199, i64 %t198
  call i8* @memcpy(i8* %t200, i8* %t165, i64 %t174)
  %t201 = getelementptr inbounds i8, i8* %t200, i64 %t174
  store i8* %t201, i8** %t192
  %t202 = getelementptr inbounds i8, i8* %t194, i64 %t167
  store i8* %t202, i8** %t191
  br label %replace_build_cond_23
replace_build_done_25:
  %t203 = load i8*, i8** %t191
  %t204 = load i8*, i8** %t192
  call i8* @strcpy(i8* %t204, i8* %t203)
  br label %replace_done_19
replace_done_19:
  %t205 = phi i8* [ %t172, %replace_empty_old_17 ], [ %t190, %replace_build_done_25 ]
  call void @star_rc_release(i8* %t157)
  call void @star_rc_release(i8* %t158)
  call void @star_rc_release(i8* %t159)
  call void @star_rc_release(i8* %t205)
  call i32 (i8*, ...) @printf(i8* %t205)
  %t206 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.23, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t206)
  %t207 = getelementptr inbounds { i64, i8*, [5 x i8] }, { i64, i8*, [5 x i8] }* @.str.24, i64 0, i32 2, i64 0
  %t208 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.25, i64 0, i32 2, i64 0
  %t209 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.26, i64 0, i32 2, i64 0
  %t210 = icmp eq i8* %t207, null
  %t211 = select i1 %t210, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t207
  %t212 = icmp eq i8* %t208, null
  %t213 = select i1 %t212, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t208
  %t214 = icmp eq i8* %t209, null
  %t215 = select i1 %t214, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t209
  %t216 = call i32 @strlen(i8* %t213)
  %t217 = sext i32 %t216 to i64
  %t218 = icmp eq i64 %t217, 0
  br i1 %t218, label %replace_empty_old_26, label %replace_real_27
replace_empty_old_26:
  %t219 = call i32 @strlen(i8* %t211)
  %t220 = sext i32 %t219 to i64
  %t221 = add i64 %t220, 1
  %t222 = call i8* @star_rc_alloc(i64 %t221, i8* null)
  call i8* @strcpy(i8* %t222, i8* %t211)
  br label %replace_done_28
replace_real_27:
  %t223 = call i32 @strlen(i8* %t215)
  %t224 = sext i32 %t223 to i64
  store i64 0, i64* %t225
  store i8* %t211, i8** %t226
  br label %replace_count_cond_29
replace_count_cond_29:
  %t227 = load i8*, i8** %t226
  %t228 = call i8* @strstr(i8* %t227, i8* %t213)
  %t229 = icmp eq i8* %t228, null
  br i1 %t229, label %replace_count_done_31, label %replace_count_body_30
replace_count_body_30:
  %t230 = load i64, i64* %t225
  %t231 = add i64 %t230, 1
  store i64 %t231, i64* %t225
  %t232 = getelementptr inbounds i8, i8* %t228, i64 %t217
  store i8* %t232, i8** %t226
  br label %replace_count_cond_29
replace_count_done_31:
  %t233 = load i64, i64* %t225
  %t234 = call i32 @strlen(i8* %t211)
  %t235 = sext i32 %t234 to i64
  %t236 = sub i64 %t224, %t217
  %t237 = mul i64 %t233, %t236
  %t238 = add i64 %t235, %t237
  %t239 = add i64 %t238, 1
  %t240 = call i8* @star_rc_alloc(i64 %t239, i8* null)
  store i8* %t211, i8** %t241
  store i8* %t240, i8** %t242
  br label %replace_build_cond_32
replace_build_cond_32:
  %t243 = load i8*, i8** %t241
  %t244 = call i8* @strstr(i8* %t243, i8* %t213)
  %t245 = icmp eq i8* %t244, null
  br i1 %t245, label %replace_build_done_34, label %replace_build_body_33
replace_build_body_33:
  %t246 = ptrtoint i8* %t244 to i64
  %t247 = ptrtoint i8* %t243 to i64
  %t248 = sub i64 %t246, %t247
  %t249 = load i8*, i8** %t242
  call i8* @memcpy(i8* %t249, i8* %t243, i64 %t248)
  %t250 = getelementptr inbounds i8, i8* %t249, i64 %t248
  call i8* @memcpy(i8* %t250, i8* %t215, i64 %t224)
  %t251 = getelementptr inbounds i8, i8* %t250, i64 %t224
  store i8* %t251, i8** %t242
  %t252 = getelementptr inbounds i8, i8* %t244, i64 %t217
  store i8* %t252, i8** %t241
  br label %replace_build_cond_32
replace_build_done_34:
  %t253 = load i8*, i8** %t241
  %t254 = load i8*, i8** %t242
  call i8* @strcpy(i8* %t254, i8* %t253)
  br label %replace_done_28
replace_done_28:
  %t255 = phi i8* [ %t222, %replace_empty_old_26 ], [ %t240, %replace_build_done_34 ]
  call void @star_rc_release(i8* %t207)
  call void @star_rc_release(i8* %t208)
  call void @star_rc_release(i8* %t209)
  call void @star_rc_release(i8* %t255)
  call i32 (i8*, ...) @printf(i8* %t255)
  %t256 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.27, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t256)
  %t258 = getelementptr inbounds { i64, i8*, [21 x i8] }, { i64, i8*, [21 x i8] }* @.str.28, i64 0, i32 2, i64 0
  store i8* %t258, i8** %t257
  %t260 = load i8*, i8** %t257
  %t261 = load i8*, i8** %t257
  call void @star_rc_retain(i8* %t261)
  %t262 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.29, i64 0, i32 2, i64 0
  %t263 = icmp eq i8* %t260, null
  %t264 = select i1 %t263, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t260
  %t265 = icmp eq i8* %t262, null
  %t266 = select i1 %t265, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t262
  %t267 = call i32 @strlen(i8* %t266)
  %t268 = sext i32 %t267 to i64
  store i8** null, i8*** %t269
  store i64 0, i64* %t270
  store i64 0, i64* %t271
  %t272 = icmp eq i64 %t268, 0
  br i1 %t272, label %split_single_35, label %split_scan_init_36
split_single_35:
  %t273 = call i32 @strlen(i8* %t264)
  %t274 = sext i32 %t273 to i64
  %t275 = add i64 %t274, 1
  %t276 = call i8* @star_rc_alloc(i64 %t275, i8* null)
  call i8* @strcpy(i8* %t276, i8* %t264)
  %t277 = load i64, i64* %t270
  %t278 = load i64, i64* %t271
  %t279 = icmp sge i64 %t277, %t278
  br i1 %t279, label %dynstr_grow_38, label %dynstr_store_39
dynstr_grow_38:
  %t280 = mul i64 %t278, 2
  %t281 = icmp sgt i64 %t280, 0
  %t282 = select i1 %t281, i64 %t280, i64 4
  %t283 = mul i64 %t282, 8
  %t284 = call i8* @malloc(i64 %t283)
  %t285 = bitcast i8* %t284 to i8**
  %t286 = icmp sgt i64 %t278, 0
  br i1 %t286, label %dynstr_copy_40, label %dynstr_after_copy_41
dynstr_copy_40:
  %t287 = load i8**, i8*** %t269
  %t288 = mul i64 %t277, 8
  %t289 = bitcast i8** %t287 to i8*
  call i8* @memcpy(i8* %t284, i8* %t289, i64 %t288)
  call void @free(i8* %t289)
  br label %dynstr_after_copy_41
dynstr_after_copy_41:
  store i8** %t285, i8*** %t269
  store i64 %t282, i64* %t271
  br label %dynstr_store_39
dynstr_store_39:
  %t290 = load i8**, i8*** %t269
  %t291 = getelementptr inbounds i8*, i8** %t290, i64 %t277
  store i8* %t276, i8** %t291
  %t292 = add i64 %t277, 1
  store i64 %t292, i64* %t270
  br label %split_finish_37
split_scan_init_36:
  store i8* %t264, i8** %t293
  br label %split_scan_cond_42
split_scan_cond_42:
  %t294 = load i8*, i8** %t293
  %t295 = call i8* @strstr(i8* %t294, i8* %t266)
  %t296 = icmp eq i8* %t295, null
  br i1 %t296, label %split_tail_44, label %split_match_43
split_match_43:
  %t297 = ptrtoint i8* %t295 to i64
  %t298 = ptrtoint i8* %t294 to i64
  %t299 = sub i64 %t297, %t298
  %t300 = add i64 %t299, 1
  %t301 = call i8* @star_rc_alloc(i64 %t300, i8* null)
  call i8* @memcpy(i8* %t301, i8* %t294, i64 %t299)
  %t302 = getelementptr inbounds i8, i8* %t301, i64 %t299
  store i8 0, i8* %t302
  %t303 = load i64, i64* %t270
  %t304 = load i64, i64* %t271
  %t305 = icmp sge i64 %t303, %t304
  br i1 %t305, label %dynstr_grow_45, label %dynstr_store_46
dynstr_grow_45:
  %t306 = mul i64 %t304, 2
  %t307 = icmp sgt i64 %t306, 0
  %t308 = select i1 %t307, i64 %t306, i64 4
  %t309 = mul i64 %t308, 8
  %t310 = call i8* @malloc(i64 %t309)
  %t311 = bitcast i8* %t310 to i8**
  %t312 = icmp sgt i64 %t304, 0
  br i1 %t312, label %dynstr_copy_47, label %dynstr_after_copy_48
dynstr_copy_47:
  %t313 = load i8**, i8*** %t269
  %t314 = mul i64 %t303, 8
  %t315 = bitcast i8** %t313 to i8*
  call i8* @memcpy(i8* %t310, i8* %t315, i64 %t314)
  call void @free(i8* %t315)
  br label %dynstr_after_copy_48
dynstr_after_copy_48:
  store i8** %t311, i8*** %t269
  store i64 %t308, i64* %t271
  br label %dynstr_store_46
dynstr_store_46:
  %t316 = load i8**, i8*** %t269
  %t317 = getelementptr inbounds i8*, i8** %t316, i64 %t303
  store i8* %t301, i8** %t317
  %t318 = add i64 %t303, 1
  store i64 %t318, i64* %t270
  %t319 = getelementptr inbounds i8, i8* %t295, i64 %t268
  store i8* %t319, i8** %t293
  br label %split_scan_cond_42
split_tail_44:
  %t320 = load i8*, i8** %t293
  %t321 = call i32 @strlen(i8* %t320)
  %t322 = sext i32 %t321 to i64
  %t323 = add i64 %t322, 1
  %t324 = call i8* @star_rc_alloc(i64 %t323, i8* null)
  call i8* @strcpy(i8* %t324, i8* %t320)
  %t325 = load i64, i64* %t270
  %t326 = load i64, i64* %t271
  %t327 = icmp sge i64 %t325, %t326
  br i1 %t327, label %dynstr_grow_49, label %dynstr_store_50
dynstr_grow_49:
  %t328 = mul i64 %t326, 2
  %t329 = icmp sgt i64 %t328, 0
  %t330 = select i1 %t329, i64 %t328, i64 4
  %t331 = mul i64 %t330, 8
  %t332 = call i8* @malloc(i64 %t331)
  %t333 = bitcast i8* %t332 to i8**
  %t334 = icmp sgt i64 %t326, 0
  br i1 %t334, label %dynstr_copy_51, label %dynstr_after_copy_52
dynstr_copy_51:
  %t335 = load i8**, i8*** %t269
  %t336 = mul i64 %t325, 8
  %t337 = bitcast i8** %t335 to i8*
  call i8* @memcpy(i8* %t332, i8* %t337, i64 %t336)
  call void @free(i8* %t337)
  br label %dynstr_after_copy_52
dynstr_after_copy_52:
  store i8** %t333, i8*** %t269
  store i64 %t330, i64* %t271
  br label %dynstr_store_50
dynstr_store_50:
  %t338 = load i8**, i8*** %t269
  %t339 = getelementptr inbounds i8*, i8** %t338, i64 %t325
  store i8* %t324, i8** %t339
  %t340 = add i64 %t325, 1
  store i64 %t340, i64* %t270
  br label %split_finish_37
split_finish_37:
  call void @star_rc_release(i8* %t260)
  call void @star_rc_release(i8* %t262)
  %t353 = bitcast void (i8*)* @list_release_str to i8*
  %t354 = call i8* @star_rc_alloc(i64 24, i8* %t353)
  %t355 = bitcast i8* %t354 to { i8**, i64, i64 }*
  %t356 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t355, i32 0, i32 0
  %t357 = load i8**, i8*** %t269
  store i8** %t357, i8*** %t356
  %t358 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t355, i32 0, i32 1
  %t359 = load i64, i64* %t270
  store i64 %t359, i64* %t358
  %t360 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t355, i32 0, i32 2
  %t361 = load i64, i64* %t271
  store i64 %t361, i64* %t360
  store i8* %t354, i8** %t259
  %t363 = load i8*, i8** %t259
  %t364 = icmp eq i8* %t363, null
  br i1 %t364, label %list_read_null_56, label %list_read_real_57
list_read_null_56:
  br label %list_read_end_58
list_read_real_57:
  %t365 = bitcast i8* %t363 to { i8**, i64, i64 }*
  %t366 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t365, i32 0, i32 0
  %t367 = load i8**, i8*** %t366
  %t368 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t365, i32 0, i32 1
  %t369 = load i64, i64* %t368
  br label %list_read_end_58
list_read_end_58:
  %t370 = phi i8** [ null, %list_read_null_56 ], [ %t367, %list_read_real_57 ]
  %t371 = phi i64 [ 0, %list_read_null_56 ], [ %t369, %list_read_real_57 ]
  %t372 = trunc i64 %t371 to i32
  store i32 %t372, i32* %t362
  %t373 = load i32, i32* %t362
  %t374 = getelementptr inbounds [57 x i8], [57 x i8]* @.str.30, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t374, i32 %t373)
  store i32 0, i32* %t375
  br label %while_cond_59
while_cond_59:
  %t376 = load i32, i32* %t375
  %t377 = load i8*, i8** %t259
  %t378 = icmp eq i8* %t377, null
  br i1 %t378, label %list_read_null_63, label %list_read_real_64
list_read_null_63:
  br label %list_read_end_65
list_read_real_64:
  %t379 = bitcast i8* %t377 to { i8**, i64, i64 }*
  %t380 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t379, i32 0, i32 0
  %t381 = load i8**, i8*** %t380
  %t382 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t379, i32 0, i32 1
  %t383 = load i64, i64* %t382
  br label %list_read_end_65
list_read_end_65:
  %t384 = phi i8** [ null, %list_read_null_63 ], [ %t381, %list_read_real_64 ]
  %t385 = phi i64 [ 0, %list_read_null_63 ], [ %t383, %list_read_real_64 ]
  %t386 = trunc i64 %t385 to i32
  %t387 = icmp slt i32 %t376, %t386
  br i1 %t387, label %while_body_60, label %while_else_61
while_body_60:
  %t389 = load i8*, i8** %t259
  %t390 = icmp eq i8* %t389, null
  br i1 %t390, label %list_read_null_66, label %list_read_real_67
list_read_null_66:
  br label %list_read_end_68
list_read_real_67:
  %t391 = bitcast i8* %t389 to { i8**, i64, i64 }*
  %t392 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t391, i32 0, i32 0
  %t393 = load i8**, i8*** %t392
  %t394 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t391, i32 0, i32 1
  %t395 = load i64, i64* %t394
  br label %list_read_end_68
list_read_end_68:
  %t396 = phi i8** [ null, %list_read_null_66 ], [ %t393, %list_read_real_67 ]
  %t397 = phi i64 [ 0, %list_read_null_66 ], [ %t395, %list_read_real_67 ]
  %t398 = load i32, i32* %t375
  %t399 = sext i32 %t398 to i64
  %t400 = icmp ult i64 %t399, %t397
  br i1 %t400, label %list_idx_ok_69, label %list_idx_oob_70
list_idx_ok_69:
  %t401 = getelementptr inbounds i8*, i8** %t396, i64 %t399
  %t402 = load i8*, i8** %t401
  %t403 = load i8*, i8** %t401
  call void @star_rc_retain(i8* %t403)
  br label %list_idx_end_71
list_idx_oob_70:
  %t404 = call i8* @star_rc_alloc(i64 1, i8* null)
  store i8 0, i8* %t404
  br label %list_idx_end_71
list_idx_end_71:
  %t405 = phi i8* [ %t402, %list_idx_ok_69 ], [ %t404, %list_idx_oob_70 ]
  store i8* %t405, i8** %t388
  %t406 = load i32, i32* %t375
  %t407 = load i8*, i8** %t388
  %t408 = load i8*, i8** %t388
  call void @star_rc_retain(i8* %t408)
  call void @star_rc_release(i8* %t407)
  %t409 = getelementptr inbounds [15 x i8], [15 x i8]* @.str.31, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t409, i32 %t406, i8* %t407)
  %t410 = load i32, i32* %t375
  %t411 = add i32 %t410, 1
  store i32 %t411, i32* %t375
  %t412 = load i8*, i8** %t388
  call void @star_rc_release(i8* %t412)
  br label %while_cond_59
while_else_61:
  br label %while_end_62
while_end_62:
  %t413 = load i8*, i8** %t259
  %t414 = icmp eq i8* %t413, null
  br i1 %t414, label %list_read_null_72, label %list_read_real_73
list_read_null_72:
  br label %list_read_end_74
list_read_real_73:
  %t415 = bitcast i8* %t413 to { i8**, i64, i64 }*
  %t416 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t415, i32 0, i32 0
  %t417 = load i8**, i8*** %t416
  %t418 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t415, i32 0, i32 1
  %t419 = load i64, i64* %t418
  br label %list_read_end_74
list_read_end_74:
  %t420 = phi i8** [ null, %list_read_null_72 ], [ %t417, %list_read_real_73 ]
  %t421 = phi i64 [ 0, %list_read_null_72 ], [ %t419, %list_read_real_73 ]
  %t422 = getelementptr inbounds { i64, i8*, [4 x i8] }, { i64, i8*, [4 x i8] }* @.str.32, i64 0, i32 2, i64 0
  %t423 = icmp eq i8* %t422, null
  %t424 = select i1 %t423, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t422
  %t425 = call i32 @strlen(i8* %t424)
  %t426 = sext i32 %t425 to i64
  store i64 0, i64* %t427
  store i64 0, i64* %t428
  br label %join_sum_cond_75
join_sum_cond_75:
  %t429 = load i64, i64* %t428
  %t430 = icmp slt i64 %t429, %t421
  br i1 %t430, label %join_sum_body_76, label %join_sum_done_77
join_sum_body_76:
  %t431 = getelementptr inbounds i8*, i8** %t420, i64 %t429
  %t432 = load i8*, i8** %t431
  %t433 = icmp eq i8* %t432, null
  %t434 = select i1 %t433, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t432
  %t435 = call i32 @strlen(i8* %t434)
  %t436 = sext i32 %t435 to i64
  %t437 = load i64, i64* %t427
  %t438 = add i64 %t437, %t436
  store i64 %t438, i64* %t427
  %t439 = add i64 %t429, 1
  store i64 %t439, i64* %t428
  br label %join_sum_cond_75
join_sum_done_77:
  %t440 = load i64, i64* %t427
  %t441 = icmp eq i64 %t421, 0
  %t442 = sub i64 %t421, 1
  %t443 = select i1 %t441, i64 0, i64 %t442
  %t444 = mul i64 %t443, %t426
  %t445 = add i64 %t440, %t444
  %t446 = add i64 %t445, 1
  %t447 = call i8* @star_rc_alloc(i64 %t446, i8* null)
  store i8* %t447, i8** %t448
  store i64 0, i64* %t449
  br label %join_build_cond_78
join_build_cond_78:
  %t450 = load i64, i64* %t449
  %t451 = icmp slt i64 %t450, %t421
  br i1 %t451, label %join_build_body_79, label %join_build_done_80
join_build_body_79:
  %t452 = getelementptr inbounds i8*, i8** %t420, i64 %t450
  %t453 = load i8*, i8** %t452
  %t454 = icmp eq i8* %t453, null
  %t455 = select i1 %t454, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t453
  %t456 = call i32 @strlen(i8* %t455)
  %t457 = sext i32 %t456 to i64
  %t458 = load i8*, i8** %t448
  call i8* @memcpy(i8* %t458, i8* %t455, i64 %t457)
  %t459 = getelementptr inbounds i8, i8* %t458, i64 %t457
  %t460 = add i64 %t450, 1
  %t461 = icmp slt i64 %t460, %t421
  br i1 %t461, label %join_sep_81, label %join_no_sep_82
join_sep_81:
  call i8* @memcpy(i8* %t459, i8* %t424, i64 %t426)
  %t462 = getelementptr inbounds i8, i8* %t459, i64 %t426
  br label %join_after_83
join_no_sep_82:
  br label %join_after_83
join_after_83:
  %t463 = phi i8* [ %t462, %join_sep_81 ], [ %t459, %join_no_sep_82 ]
  store i8* %t463, i8** %t448
  store i64 %t460, i64* %t449
  br label %join_build_cond_78
join_build_done_80:
  %t464 = load i8*, i8** %t448
  store i8 0, i8* %t464
  call void @star_rc_release(i8* %t422)
  call void @star_rc_release(i8* %t447)
  call i32 (i8*, ...) @printf(i8* %t447)
  %t465 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.33, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t465)
  %t467 = getelementptr inbounds { i64, i8*, [8 x i8] }, { i64, i8*, [8 x i8] }* @.str.34, i64 0, i32 2, i64 0
  store i8* %t467, i8** %t466
  %t469 = load i8*, i8** %t466
  %t470 = load i8*, i8** %t466
  call void @star_rc_retain(i8* %t470)
  %t471 = getelementptr inbounds { i64, i8*, [3 x i8] }, { i64, i8*, [3 x i8] }* @.str.35, i64 0, i32 2, i64 0
  %t472 = icmp eq i8* %t469, null
  %t473 = select i1 %t472, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t469
  %t474 = icmp eq i8* %t471, null
  %t475 = select i1 %t474, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t471
  %t476 = call i32 @strlen(i8* %t475)
  %t477 = sext i32 %t476 to i64
  store i8** null, i8*** %t478
  store i64 0, i64* %t479
  store i64 0, i64* %t480
  %t481 = icmp eq i64 %t477, 0
  br i1 %t481, label %split_single_84, label %split_scan_init_85
split_single_84:
  %t482 = call i32 @strlen(i8* %t473)
  %t483 = sext i32 %t482 to i64
  %t484 = add i64 %t483, 1
  %t485 = call i8* @star_rc_alloc(i64 %t484, i8* null)
  call i8* @strcpy(i8* %t485, i8* %t473)
  %t486 = load i64, i64* %t479
  %t487 = load i64, i64* %t480
  %t488 = icmp sge i64 %t486, %t487
  br i1 %t488, label %dynstr_grow_87, label %dynstr_store_88
dynstr_grow_87:
  %t489 = mul i64 %t487, 2
  %t490 = icmp sgt i64 %t489, 0
  %t491 = select i1 %t490, i64 %t489, i64 4
  %t492 = mul i64 %t491, 8
  %t493 = call i8* @malloc(i64 %t492)
  %t494 = bitcast i8* %t493 to i8**
  %t495 = icmp sgt i64 %t487, 0
  br i1 %t495, label %dynstr_copy_89, label %dynstr_after_copy_90
dynstr_copy_89:
  %t496 = load i8**, i8*** %t478
  %t497 = mul i64 %t486, 8
  %t498 = bitcast i8** %t496 to i8*
  call i8* @memcpy(i8* %t493, i8* %t498, i64 %t497)
  call void @free(i8* %t498)
  br label %dynstr_after_copy_90
dynstr_after_copy_90:
  store i8** %t494, i8*** %t478
  store i64 %t491, i64* %t480
  br label %dynstr_store_88
dynstr_store_88:
  %t499 = load i8**, i8*** %t478
  %t500 = getelementptr inbounds i8*, i8** %t499, i64 %t486
  store i8* %t485, i8** %t500
  %t501 = add i64 %t486, 1
  store i64 %t501, i64* %t479
  br label %split_finish_86
split_scan_init_85:
  store i8* %t473, i8** %t502
  br label %split_scan_cond_91
split_scan_cond_91:
  %t503 = load i8*, i8** %t502
  %t504 = call i8* @strstr(i8* %t503, i8* %t475)
  %t505 = icmp eq i8* %t504, null
  br i1 %t505, label %split_tail_93, label %split_match_92
split_match_92:
  %t506 = ptrtoint i8* %t504 to i64
  %t507 = ptrtoint i8* %t503 to i64
  %t508 = sub i64 %t506, %t507
  %t509 = add i64 %t508, 1
  %t510 = call i8* @star_rc_alloc(i64 %t509, i8* null)
  call i8* @memcpy(i8* %t510, i8* %t503, i64 %t508)
  %t511 = getelementptr inbounds i8, i8* %t510, i64 %t508
  store i8 0, i8* %t511
  %t512 = load i64, i64* %t479
  %t513 = load i64, i64* %t480
  %t514 = icmp sge i64 %t512, %t513
  br i1 %t514, label %dynstr_grow_94, label %dynstr_store_95
dynstr_grow_94:
  %t515 = mul i64 %t513, 2
  %t516 = icmp sgt i64 %t515, 0
  %t517 = select i1 %t516, i64 %t515, i64 4
  %t518 = mul i64 %t517, 8
  %t519 = call i8* @malloc(i64 %t518)
  %t520 = bitcast i8* %t519 to i8**
  %t521 = icmp sgt i64 %t513, 0
  br i1 %t521, label %dynstr_copy_96, label %dynstr_after_copy_97
dynstr_copy_96:
  %t522 = load i8**, i8*** %t478
  %t523 = mul i64 %t512, 8
  %t524 = bitcast i8** %t522 to i8*
  call i8* @memcpy(i8* %t519, i8* %t524, i64 %t523)
  call void @free(i8* %t524)
  br label %dynstr_after_copy_97
dynstr_after_copy_97:
  store i8** %t520, i8*** %t478
  store i64 %t517, i64* %t480
  br label %dynstr_store_95
dynstr_store_95:
  %t525 = load i8**, i8*** %t478
  %t526 = getelementptr inbounds i8*, i8** %t525, i64 %t512
  store i8* %t510, i8** %t526
  %t527 = add i64 %t512, 1
  store i64 %t527, i64* %t479
  %t528 = getelementptr inbounds i8, i8* %t504, i64 %t477
  store i8* %t528, i8** %t502
  br label %split_scan_cond_91
split_tail_93:
  %t529 = load i8*, i8** %t502
  %t530 = call i32 @strlen(i8* %t529)
  %t531 = sext i32 %t530 to i64
  %t532 = add i64 %t531, 1
  %t533 = call i8* @star_rc_alloc(i64 %t532, i8* null)
  call i8* @strcpy(i8* %t533, i8* %t529)
  %t534 = load i64, i64* %t479
  %t535 = load i64, i64* %t480
  %t536 = icmp sge i64 %t534, %t535
  br i1 %t536, label %dynstr_grow_98, label %dynstr_store_99
dynstr_grow_98:
  %t537 = mul i64 %t535, 2
  %t538 = icmp sgt i64 %t537, 0
  %t539 = select i1 %t538, i64 %t537, i64 4
  %t540 = mul i64 %t539, 8
  %t541 = call i8* @malloc(i64 %t540)
  %t542 = bitcast i8* %t541 to i8**
  %t543 = icmp sgt i64 %t535, 0
  br i1 %t543, label %dynstr_copy_100, label %dynstr_after_copy_101
dynstr_copy_100:
  %t544 = load i8**, i8*** %t478
  %t545 = mul i64 %t534, 8
  %t546 = bitcast i8** %t544 to i8*
  call i8* @memcpy(i8* %t541, i8* %t546, i64 %t545)
  call void @free(i8* %t546)
  br label %dynstr_after_copy_101
dynstr_after_copy_101:
  store i8** %t542, i8*** %t478
  store i64 %t539, i64* %t480
  br label %dynstr_store_99
dynstr_store_99:
  %t547 = load i8**, i8*** %t478
  %t548 = getelementptr inbounds i8*, i8** %t547, i64 %t534
  store i8* %t533, i8** %t548
  %t549 = add i64 %t534, 1
  store i64 %t549, i64* %t479
  br label %split_finish_86
split_finish_86:
  call void @star_rc_release(i8* %t469)
  call void @star_rc_release(i8* %t471)
  %t550 = bitcast void (i8*)* @list_release_str to i8*
  %t551 = call i8* @star_rc_alloc(i64 24, i8* %t550)
  %t552 = bitcast i8* %t551 to { i8**, i64, i64 }*
  %t553 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t552, i32 0, i32 0
  %t554 = load i8**, i8*** %t478
  store i8** %t554, i8*** %t553
  %t555 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t552, i32 0, i32 1
  %t556 = load i64, i64* %t479
  store i64 %t556, i64* %t555
  %t557 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t552, i32 0, i32 2
  %t558 = load i64, i64* %t480
  store i64 %t558, i64* %t557
  store i8* %t551, i8** %t468
  %t559 = load i8*, i8** %t468
  %t560 = icmp eq i8* %t559, null
  br i1 %t560, label %list_read_null_102, label %list_read_real_103
list_read_null_102:
  br label %list_read_end_104
list_read_real_103:
  %t561 = bitcast i8* %t559 to { i8**, i64, i64 }*
  %t562 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t561, i32 0, i32 0
  %t563 = load i8**, i8*** %t562
  %t564 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t561, i32 0, i32 1
  %t565 = load i64, i64* %t564
  br label %list_read_end_104
list_read_end_104:
  %t566 = phi i8** [ null, %list_read_null_102 ], [ %t563, %list_read_real_103 ]
  %t567 = phi i64 [ 0, %list_read_null_102 ], [ %t565, %list_read_real_103 ]
  %t568 = getelementptr inbounds { i64, i8*, [2 x i8] }, { i64, i8*, [2 x i8] }* @.str.36, i64 0, i32 2, i64 0
  %t569 = icmp eq i8* %t568, null
  %t570 = select i1 %t569, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t568
  %t571 = call i32 @strlen(i8* %t570)
  %t572 = sext i32 %t571 to i64
  store i64 0, i64* %t573
  store i64 0, i64* %t574
  br label %join_sum_cond_105
join_sum_cond_105:
  %t575 = load i64, i64* %t574
  %t576 = icmp slt i64 %t575, %t567
  br i1 %t576, label %join_sum_body_106, label %join_sum_done_107
join_sum_body_106:
  %t577 = getelementptr inbounds i8*, i8** %t566, i64 %t575
  %t578 = load i8*, i8** %t577
  %t579 = icmp eq i8* %t578, null
  %t580 = select i1 %t579, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t578
  %t581 = call i32 @strlen(i8* %t580)
  %t582 = sext i32 %t581 to i64
  %t583 = load i64, i64* %t573
  %t584 = add i64 %t583, %t582
  store i64 %t584, i64* %t573
  %t585 = add i64 %t575, 1
  store i64 %t585, i64* %t574
  br label %join_sum_cond_105
join_sum_done_107:
  %t586 = load i64, i64* %t573
  %t587 = icmp eq i64 %t567, 0
  %t588 = sub i64 %t567, 1
  %t589 = select i1 %t587, i64 0, i64 %t588
  %t590 = mul i64 %t589, %t572
  %t591 = add i64 %t586, %t590
  %t592 = add i64 %t591, 1
  %t593 = call i8* @star_rc_alloc(i64 %t592, i8* null)
  store i8* %t593, i8** %t594
  store i64 0, i64* %t595
  br label %join_build_cond_108
join_build_cond_108:
  %t596 = load i64, i64* %t595
  %t597 = icmp slt i64 %t596, %t567
  br i1 %t597, label %join_build_body_109, label %join_build_done_110
join_build_body_109:
  %t598 = getelementptr inbounds i8*, i8** %t566, i64 %t596
  %t599 = load i8*, i8** %t598
  %t600 = icmp eq i8* %t599, null
  %t601 = select i1 %t600, i8* getelementptr inbounds ([1 x i8], [1 x i8]* @str.empty, i64 0, i64 0), i8* %t599
  %t602 = call i32 @strlen(i8* %t601)
  %t603 = sext i32 %t602 to i64
  %t604 = load i8*, i8** %t594
  call i8* @memcpy(i8* %t604, i8* %t601, i64 %t603)
  %t605 = getelementptr inbounds i8, i8* %t604, i64 %t603
  %t606 = add i64 %t596, 1
  %t607 = icmp slt i64 %t606, %t567
  br i1 %t607, label %join_sep_111, label %join_no_sep_112
join_sep_111:
  call i8* @memcpy(i8* %t605, i8* %t570, i64 %t572)
  %t608 = getelementptr inbounds i8, i8* %t605, i64 %t572
  br label %join_after_113
join_no_sep_112:
  br label %join_after_113
join_after_113:
  %t609 = phi i8* [ %t608, %join_sep_111 ], [ %t605, %join_no_sep_112 ]
  store i8* %t609, i8** %t594
  store i64 %t606, i64* %t595
  br label %join_build_cond_108
join_build_done_110:
  %t610 = load i8*, i8** %t594
  store i8 0, i8* %t610
  call void @star_rc_release(i8* %t568)
  call void @star_rc_release(i8* %t593)
  call i32 (i8*, ...) @printf(i8* %t593)
  %t611 = getelementptr inbounds [2 x i8], [2 x i8]* @.str.37, i64 0, i64 0
  call i32 (i8*, ...) @printf(i8* %t611)
  %t612 = load i8*, i8** %t468
  call void @star_rc_release(i8* %t612)
  %t613 = load i8*, i8** %t466
  call void @star_rc_release(i8* %t613)
  %t614 = load i8*, i8** %t259
  call void @star_rc_release(i8* %t614)
  %t615 = load i8*, i8** %t257
  call void @star_rc_release(i8* %t615)
  %t616 = load i8*, i8** %t106
  call void @star_rc_release(i8* %t616)
  %t617 = load i8*, i8** %t104
  call void @star_rc_release(i8* %t617)
  %t618 = load i8*, i8** %t2
  call void @star_rc_release(i8* %t618)
  ret i32 0
}


; par/swarm worker functions
define void @list_release_str(i8* %objp) {
entry:
  %t346 = alloca i64
  %t341 = bitcast i8* %objp to { i8**, i64, i64 }*
  %t342 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t341, i32 0, i32 0
  %t343 = load i8**, i8*** %t342
  %t344 = getelementptr inbounds { i8**, i64, i64 }, { i8**, i64, i64 }* %t341, i32 0, i32 1
  %t345 = load i64, i64* %t344
  store i64 0, i64* %t346
  br label %list_release_cond_53
list_release_cond_53:
  %t347 = load i64, i64* %t346
  %t348 = icmp slt i64 %t347, %t345
  br i1 %t348, label %list_release_body_54, label %list_release_end_55
list_release_body_54:
  %t349 = getelementptr inbounds i8*, i8** %t343, i64 %t347
  %t350 = load i8*, i8** %t349
  call void @star_rc_release(i8* %t350)
  %t351 = add i64 %t347, 1
  store i64 %t351, i64* %t346
  br label %list_release_cond_53
list_release_end_55:
  %t352 = bitcast i8** %t343 to i8*
  call void @free(i8* %t352)
  ret void
}



; Global Constants
@.str.0 = private unnamed_addr constant { i64, i8*, [20 x i8] } { i64 -1, i8* null, [20 x i8] c"the quick brown fox\00" }
@.str.1 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"quick\00" }
@.str.2 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"slow\00" }
@.str.3 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.5 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.6 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.7 = private unnamed_addr constant [43 x i8] c"contains 'quick'? %s, contains 'slow'? %s\0A\00"
@.str.8 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"the\00" }
@.str.9 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c"fox\00" }
@.str.10 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.11 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.12 = private unnamed_addr constant [5 x i8] c"true\00"
@.str.13 = private unnamed_addr constant [6 x i8] c"false\00"
@.str.14 = private unnamed_addr constant [44 x i8] c"starts with 'the'? %s, ends with 'fox'? %s\0A\00"
@.str.15 = private unnamed_addr constant { i64, i8*, [6 x i8] } { i64 -1, i8* null, [6 x i8] c"brown\00" }
@.str.16 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"nope\00" }
@.str.17 = private unnamed_addr constant [45 x i8] c"index of 'brown' = %d, index of 'nope' = %d\0A\00"
@.str.18 = private unnamed_addr constant { i64, i8*, [27 x i8] } { i64 -1, i8* null, [27 x i8] c"   surrounded by spaces   \00" }
@.str.19 = private unnamed_addr constant [16 x i8] c"trimmed = '%s'\0A\00"
@.str.20 = private unnamed_addr constant { i64, i8*, [11 x i8] } { i64 -1, i8* null, [11 x i8] c"2024-01-15\00" }
@.str.21 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"-\00" }
@.str.22 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"/\00" }
@.str.23 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.24 = private unnamed_addr constant { i64, i8*, [5 x i8] } { i64 -1, i8* null, [5 x i8] c"aaaa\00" }
@.str.25 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"aa\00" }
@.str.26 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"b\00" }
@.str.27 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.28 = private unnamed_addr constant { i64, i8*, [21 x i8] } { i64 -1, i8* null, [21 x i8] c"apple,banana,,cherry\00" }
@.str.29 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c",\00" }
@.str.30 = private unnamed_addr constant [57 x i8] c"%d fields (the empty one between banana/cherry is kept)\0A\00"
@.str.31 = private unnamed_addr constant [15 x i8] c"  [%d] = '%s'\0A\00"
@.str.32 = private unnamed_addr constant { i64, i8*, [4 x i8] } { i64 -1, i8* null, [4 x i8] c" | \00" }
@.str.33 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str.34 = private unnamed_addr constant { i64, i8*, [8 x i8] } { i64 -1, i8* null, [8 x i8] c"a::b::c\00" }
@.str.35 = private unnamed_addr constant { i64, i8*, [3 x i8] } { i64 -1, i8* null, [3 x i8] c"::\00" }
@.str.36 = private unnamed_addr constant { i64, i8*, [2 x i8] } { i64 -1, i8* null, [2 x i8] c"/\00" }
@.str.37 = private unnamed_addr constant [2 x i8] c"\0A\00"
